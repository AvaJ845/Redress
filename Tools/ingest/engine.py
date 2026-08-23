"""
Multi-source ingestion engine.

The point of this file: no single source's downtime, ToS change, or schema
break should take down the whole pipeline. Each source runs independently;
a failure is logged and skipped, not fatal. Sources are combined and
deduplicated into one leads file, each record carrying full provenance
(which source(s) found it, and whether it's ground-truth or inferred).

Leads accumulate across runs rather than being overwritten (fixed
2026-08-23, found by a direct question, not by inspection catching it
first: every run used to fully replace leads.json, so any real candidate
a human hadn't gotten to yet — Amway, Toyota, anything from CourtListener,
which is *always* needs-review by design — was silently destroyed the
next time the engine ran. CourtListener's result set and RSS feeds'
"most recent N" windows both change run to run, so nothing guaranteed a
lead would ever be seen twice. See merge_leads() below: a candidate not
re-found this run is kept, not dropped. The only way an entry should ever
leave leads.json now is a human deleting it after actually reviewing it
(promoted to a real Settlement, or confirmed not real) — never a side
effect of running the engine again.

Usage:
  python3 -m Tools.ingest.engine --query "class action settlement" --max-results 15
"""

import argparse
import json
import os
import re
import sys
from dataclasses import asdict
from datetime import datetime, timezone
from typing import Dict, List

from .sources.base import Candidate, SettlementSource
from .sources.courtlistener import CourtListenerSource
from .sources.federal_agency_rss import FEEDS as FEDERAL_FEEDS
from .sources.federal_agency_rss import FederalAgencyRSSSource
from .sources.state_ag_rss import FEEDS as AG_FEEDS
from .sources.state_ag_rss import StateAGRSSSource
from .sources.verita import VeritaSource

# Registry of active sources. Add a new source by writing a class in
# sources/ implementing SettlementSource, then adding an instance here —
# nothing else in this file needs to change.
DEFAULT_SOURCES: List[SettlementSource] = [
    CourtListenerSource(),
    *[StateAGRSSSource(state, url) for state, url in AG_FEEDS.items()],
    *[FederalAgencyRSSSource(agency, url) for agency, url in FEDERAL_FEEDS.items()],
    VeritaSource(),
    # FTC: no usable feed found (real dashboard exists but is CAPTCHA-gated).
    # SEC litigation-releases RSS: confirmed working, but tested against 50
    # real items with two keyword sets and matched zero — SEC enforcement
    # releases are fraud/insider-trading actions, not consumer settlements.
    # Not wired in on real evidence, not because it's unconfirmed.
    # NY/TX/IL AG: no discoverable RSS feed found — don't guess a URL.
    # JND/Angeion/A.B. Data/Simpluris sitemaps: confirmed to exist but are
    # general marketing sitemaps, not per-case structured data. Verita
    # (Kroll's post-rebrand site) is the exception — a dedicated
    # settlement-case post type with a real, parseable claim-deadline
    # field, confirmed 2026-08-21.
    # See DATA_SOURCES.md for the full verification record.
]


def _normalize_key(case_name: str, docket_number: str) -> str:
    """Loose dedup key: lowercase, strip punctuation/whitespace from the
    case name, paired with the docket number. Two sources describing the
    same case should collapse to one record rather than appearing twice."""
    normalized_name = re.sub(r"[^a-z0-9]+", "", case_name.lower())
    normalized_docket = re.sub(r"[^a-z0-9]+", "", (docket_number or "").lower())
    return f"{normalized_name}|{normalized_docket}"


def run(sources: List[SettlementSource], query: str, max_results_per_source: int) -> List[Candidate]:
    all_candidates: List[Candidate] = []

    for source in sources:
        try:
            results = source.fetch(query, max_results_per_source)
            print(f"[{source.name}] fetched {len(results)} candidates", file=sys.stderr)
            all_candidates.extend(results)
        except Exception as exc:
            # This is the whole point: one source breaking does not break
            # the run. Log it and move on to the next source.
            print(f"[{source.name}] FAILED, skipping: {exc}", file=sys.stderr)
            continue

    return _dedupe(all_candidates)


def _dedupe(candidates: List[Candidate]) -> List[Candidate]:
    merged: Dict[str, Candidate] = {}
    for candidate in candidates:
        key = _normalize_key(candidate.case_name, candidate.docket_number or "")
        if key not in merged:
            merged[key] = candidate
            continue
        # Same case found by more than one source: keep the higher-confidence
        # record, but note that multiple sources corroborate it.
        existing = merged[key]
        if candidate.confidence == "ground_truth" and existing.confidence != "ground_truth":
            candidate.note = (candidate.note + f" (also seen via {existing.source_name})").strip()
            merged[key] = candidate
        else:
            existing.note = (existing.note + f" (also seen via {candidate.source_name})").strip()

    return list(merged.values())


def merge_leads(existing_records: List[dict], new_records: List[dict], now_iso: str) -> List[dict]:
    """Accumulate leads across runs instead of overwriting.

    A candidate not found again this run is kept as-is, not dropped — an
    RSS feed's "most recent N" window and CourtListener's result ordering
    both shift run to run, so a lead missing from today's fetch doesn't
    mean it stopped being real, only that this run didn't happen to see
    it again. Every record gets `first_seen_at` (set once, never
    overwritten) and `last_seen_at` (bumped whenever the lead reappears),
    so a human reviewing the backlog can tell a fresh find from one
    that's been sitting unreviewed for a while.
    """
    by_key: Dict[str, dict] = {}
    for record in existing_records:
        key = _normalize_key(record.get("case_name", ""), record.get("docket_number") or "")
        by_key[key] = record

    for record in new_records:
        key = _normalize_key(record.get("case_name", ""), record.get("docket_number") or "")
        merged_record = dict(record)
        existing = by_key.get(key)
        merged_record["first_seen_at"] = existing.get("first_seen_at", now_iso) if existing else now_iso
        merged_record["last_seen_at"] = now_iso
        by_key[key] = merged_record

    return list(by_key.values())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default="class action settlement")
    parser.add_argument("--max-results", type=int, default=15,
                         help="Max results PER SOURCE, not total")
    parser.add_argument("--output", default=os.path.join(os.path.dirname(__file__), "..", "leads.json"))
    args = parser.parse_args()

    candidates = run(DEFAULT_SOURCES, args.query, args.max_results)

    new_records = []
    for c in candidates:
        record = asdict(c)
        record["status"] = "lead-needs-review" if c.requires_human_review() else "lead-ground-truth"
        del record["raw"]  # keep the output file human-reviewable, not a data dump
        new_records.append(record)

    output_path = os.path.abspath(args.output)
    existing_records: List[dict] = []
    if os.path.exists(output_path):
        try:
            with open(output_path) as f:
                existing_records = json.load(f)
        except (json.JSONDecodeError, OSError) as exc:
            print(f"Couldn't read existing {output_path}, starting a fresh backlog: {exc}", file=sys.stderr)

    now_iso = datetime.now(timezone.utc).isoformat()
    merged_records = merge_leads(existing_records, new_records, now_iso)

    with open(output_path, "w") as f:
        json.dump(merged_records, f, indent=2)

    ground_truth_count = sum(1 for r in merged_records if r["status"] == "lead-ground-truth")
    print(f"This run found {len(new_records)} leads. Backlog at {output_path} now has "
          f"{len(merged_records)} total ({ground_truth_count} ground-truth, "
          f"{len(merged_records) - ground_truth_count} needs review).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
