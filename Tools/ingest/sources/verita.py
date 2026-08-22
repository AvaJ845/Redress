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
"""

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
SECONDS_BETWEEN_REQUESTS = 2
MAX_PAGES_PER_RUN = 40  # 531 total cases; the sitemap isn't ordered by recency
# (confirmed 2026-08-21 — the first 15 alphabetically-ish-ordered entries were
# all old, closed securities cases), so checking a fixed prefix each run
# would systematically miss open cases scattered elsewhere in the list.
# Random sampling each run finds them without needing persisted state.


def _fetch(url: str) -> str:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read().decode("utf-8", errors="ignore")


class VeritaSource(SettlementSource):
    name = "verita"

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
        random.shuffle(case_urls)
        candidates: List[Candidate] = []
        pages_checked = 0
        today = datetime.now(timezone.utc)

        for url in case_urls:
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
                continue

            try:
                deadline = datetime.strptime(match.group(1), "%d %b %Y").replace(tzinfo=timezone.utc)
            except ValueError:
                continue

            if deadline <= today:
                continue  # already closed, not a candidate

            slug = url.rstrip("/").rsplit("/", 1)[-1]
            case_name = slug.replace("-", " ").title()

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

        return candidates
