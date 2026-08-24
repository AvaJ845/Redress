"""
Verita Global (formerly Kroll Settlement Administration — kccllc.com fully
redirects here post-rebrand) publishes a dedicated WordPress custom post
type for settlement cases: veritaglobal.com/mt_settlement_case-sitemap.xml,
531 real case pages confirmed 2026-08-21. Each page states its own claim
deadline in plain text ("Claim deadline: DD Mon YYYY"), directly from the
administrator itself — this is stronger ground truth than a press release
about a settlement, since Verita/Kroll IS the administrator, not just an
announcer. Confirmed both a currently-open case (deadline months in the
future) and a closed one (deadline already passed) render the same way,
so "is the deadline in the future" is a real, honest signal — not proof
of eligibility criteria or proof requirements, which still need human
review before this becomes a real Settlement record.

Coverage note (2026-08-22): an earlier version of this source drew a fresh
random sample of MAX_PAGES_PER_RUN pages out of the full 531 on every run,
with no memory between runs. That meant two problems: (1) no guarantee the
full 531 was ever covered — each run had real, nonzero odds of resampling
pages already known to be closed instead of the untouched remainder, and
(2) wasted requests re-checking pages whose status was already known. This
source now persists a small local state file (which URLs have been checked
and when) and prioritizes never-checked pages first, so repeated runs make
monotonic progress toward covering every real case instead of resampling
blind — full coverage in ceil(531/40) ≈ 14 runs instead of a probabilistic
approach that could stall well below 100% indefinitely. Once every page has
been checked at least once, the source falls back to re-checking the
oldest-checked pages, which doubles as a freshness re-verification pass.
"""

import json
import os
import random
import re
import time
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from typing import List, Optional

from .base import Candidate, SettlementSource

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}

SITEMAP_INDEX = "https://veritaglobal.com/sitemap_index.xml"
DEADLINE_PATTERN = re.compile(r"Claim deadline:\s*(\d{1,2}\s+\w+\s+\d{4})", re.IGNORECASE)
# Verified live 2026-08-23 against a real case page: the <title> tag carries
# the case name with correct capitalization ("Toyota IC Forklift Class
# Action Settlement"), unlike deriving it from the URL slug, which
# .title()-cases every word and mangles acronyms/abbreviations ("Ic" instead
# of "IC", "V" instead of "v."). Falls back to the slug if the title tag is
# ever missing, so this can't turn a real candidate into a dropped one.
TITLE_PATTERN = re.compile(r"<title>(.*?)(?:\s*\|\s*Verita Global)?</title>", re.IGNORECASE | re.DOTALL)
SECONDS_BETWEEN_REQUESTS = 2
MAX_PAGES_PER_RUN = 40  # 531 total cases; the sitemap isn't ordered by recency
# (confirmed 2026-08-21 — the first 15 alphabetically-ish-ordered entries were
# all old, closed securities cases), so checking a fixed prefix each run
# would systematically miss open cases scattered elsewhere in the list.
# Persisted per-URL state (below) is what actually guarantees full coverage
# over repeated runs; random shuffling just decides the order within each
# run's untouched pool.
DEFAULT_STATE_PATH = os.path.join(
    os.path.dirname(__file__), "..", ".state", "verita_seen.json"
)


def _fetch(url: str) -> str:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read().decode("utf-8", errors="ignore")


class VeritaSource(SettlementSource):
    name = "verita"

    def __init__(self, state_path: Optional[str] = None):
        self.state_path = state_path or DEFAULT_STATE_PATH

    def _load_state(self) -> dict:
        try:
            with open(self.state_path) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {}

    def _save_state(self, state: dict) -> None:
        os.makedirs(os.path.dirname(self.state_path), exist_ok=True)
        with open(self.state_path, "w") as f:
            json.dump(state, f, indent=2)

    def _find_settlement_sitemap_url(self) -> Optional[str]:
        index_xml = _fetch(SITEMAP_INDEX)
        root = ET.fromstring(index_xml)
        ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        for sitemap in root.findall("sm:sitemap", ns):
            loc = sitemap.findtext("sm:loc", default="", namespaces=ns)
            if "settlement_case-sitemap" in loc:
                return loc
        return None

    def _case_urls(self, sitemap_url: str) -> List[str]:
        sitemap_xml = _fetch(sitemap_url)
        root = ET.fromstring(sitemap_xml)
        ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        return [
            url.findtext("sm:loc", default="", namespaces=ns)
            for url in root.findall("sm:url", ns)
        ]

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        sitemap_url = self._find_settlement_sitemap_url()
        if not sitemap_url:
            return []

        case_urls = self._case_urls(sitemap_url)
        state = self._load_state()

        # Never-checked pages first (shuffled, so a run that hits the
        # MAX_PAGES_PER_RUN cap doesn't always take the same slice), then
        # already-checked pages ordered oldest-first once every page has
        # been seen at least once. This is what makes coverage of the full
        # sitemap monotonic across runs instead of a random resample.
        never_checked = [u for u in case_urls if u not in state]
        random.shuffle(never_checked)
        already_checked = sorted(
            (u for u in case_urls if u in state),
            key=lambda u: state[u].get("checked_at", ""),
        )
        ordered_urls = never_checked + already_checked

        candidates: List[Candidate] = []
        pages_checked = 0
        today = datetime.now(timezone.utc)
        now_iso = today.isoformat()

        for url in ordered_urls:
            if len(candidates) >= max_results or pages_checked >= MAX_PAGES_PER_RUN:
                break
            pages_checked += 1

            try:
                html = _fetch(url)
            except Exception:
                continue
            finally:
                time.sleep(SECONDS_BETWEEN_REQUESTS)

            match = DEADLINE_PATTERN.search(html)
            if not match:
                state[url] = {"checked_at": now_iso, "deadline": None}
                continue

            try:
                deadline = datetime.strptime(match.group(1), "%d %b %Y").replace(tzinfo=timezone.utc)
            except ValueError:
                state[url] = {"checked_at": now_iso, "deadline": None}
                continue

            state[url] = {"checked_at": now_iso, "deadline": match.group(1)}

            if deadline <= today:
                continue  # already closed, not a candidate

            slug = url.rstrip("/").rsplit("/", 1)[-1]
            title_match = TITLE_PATTERN.search(html)
            case_name = title_match.group(1).strip() if title_match and title_match.group(1).strip() \
                else slug.replace("-", " ").title()

            candidates.append(Candidate(
                source_name=self.name,
                source_id=slug,
                case_name=case_name,
                source_url=url,
                court=None,
                date_filed=None,
                docket_number=None,
                confidence="ground_truth",
                note=(
                    "Claim deadline stated directly by the administrator (Verita/Kroll) "
                    f"on its own case page: {match.group(1)}. This confirms the deadline "
                    "itself, but NOT eligibility criteria or proof requirements — those "
                    "still need a human to read the actual page before this becomes a "
                    "real Settlement record."
                ),
                raw={"deadline_text": match.group(1)},
            ))

        self._save_state(state)
        return candidates
