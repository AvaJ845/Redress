"""
Multi-source ingestion engine.

The point of this file: no single source's downtime, ToS change, or schema
break should take down the whole pipeline. Each source runs independently;
a failure is logged and skipped, not fatal. Sources are combined and
deduplicated into one leads file, each record carrying full provenance
(which source(s) found it, and whether it's ground-truth or inferred).

Usage:
  python3 -m Tools.ingest.engine --query "class action settlement" --max-results 15
"""

import argparse
import json
import os
import re
import sys
from dataclasses import asdict
from typing import Dict, List

from .sources.base import Candidate, SettlementSource
from .sources.courtlistener import CourtListenerSource

# Registry of active sources. Add a new source by writing a class in
# sources/ implementing SettlementSource, then adding an instance here —
# nothing else in this file needs to change.
DEFAULT_SOURCES: List[SettlementSource] = [
    CourtListenerSource(),
    # Ground-truth sources (FTC redress announcements, SEC litigation
    # releases, state AG press feeds, claims-administrator case lists) slot
    # in here once confirmed to have a real structured/scrapeable endpoint
    # with acceptable ToS — see DATA_SOURCES.md for what's been verified
    # and what hasn't. Do not add a source here on a guess.
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default="class action settlement")
    parser.add_argument("--max-results", type=int, default=15,
                         help="Max results PER SOURCE, not total")
    parser.add_argument("--output", default=os.path.join(os.path.dirname(__file__), "..", "leads.json"))
    args = parser.parse_args()

    candidates = run(DEFAULT_SOURCES, args.query, args.max_results)

    records = []
    for c in candidates:
        record = asdict(c)
        record["status"] = "lead-needs-review" if c.requires_human_review() else "lead-ground-truth"
        del record["raw"]  # keep the output file human-reviewable, not a data dump
        records.append(record)

    output_path = os.path.abspath(args.output)
    with open(output_path, "w") as f:
        json.dump(records, f, indent=2)

    ground_truth_count = sum(1 for r in records if r["status"] == "lead-ground-truth")
    print(f"Wrote {len(records)} deduplicated leads to {output_path} "
          f"({ground_truth_count} ground-truth, {len(records) - ground_truth_count} needs review).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
