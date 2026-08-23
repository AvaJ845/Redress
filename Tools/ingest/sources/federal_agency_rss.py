"""
Federal agency press-release RSS feeds — same tier as the state AG feeds:
confirmed real, official, government-published, not aggregator-inferred.
"ground_truth" here means "the announcement is authentic," not "a public
consumer claim form exists" — every candidate still needs a human to find
(or confirm the absence of) an actual court-appointed administrator's
claim site before it becomes a Settlement record. Same caveat, same
reasoning as state_ag_rss.py; this file reuses its keyword filters rather
than duplicating them.

CFPB newsroom RSS — confirmed live 2026-08-22:
https://www.consumerfinance.gov/about-us/newsroom/feed/. 403s without an
`Accept-Language` header (added to the shared HEADERS in state_ag_rss.py) —
same category as Florida AG needing a real Accept header, not bot-
protection evasion; no CAPTCHA/JS challenge involved, just a WAF checking
for a standard browser header set. A live sample surfaced genuinely relevant items
on the first fetch ("CFPB Reaches Settlement with FirstCash, Inc. and Its
Subsidiaries for Military Lending Act Violations", "The CFPB Works To
Ensure Bilt Consumers Are Made Whole") — a meaningfully higher relevant-
hit rate than SEC litigation releases (0/50 real items, see
DATA_SOURCES.md), because CFPB's actual mandate is consumer financial
protection specifically, not general securities enforcement. Wired in
below.

DOJ press-release RSS (justice.gov/news/rss?type=press_release) is also
confirmed live (200) but deliberately NOT wired in yet. A live 20-item
sample was dominated by criminal prosecutions (drug trafficking, fraud,
terrorism) with real but much rarer consumer-settlement hits (a genuine
$400M TikTok/ByteDance children's-privacy settlement appeared once).
Wiring this in with the existing AG/CFPB keyword filter as-is risks
reproducing the exact false-positive pattern already found and fixed for
state AG feeds (see state_ag_rss.py's SETTLEMENT_KEYWORDS history) —
"restitution" in particular appears constantly in ordinary criminal
sentencing coverage, which isn't a filing-stage-lawsuit false positive
the existing FILING_STAGE_KEYWORDS exclusion list catches. This needs its
own filter-tuning pass against DOJ's specific vocabulary, live-tested
before it ships, not a blind copy of the AG/CFPB filter. Left out of
FEEDS below on purpose — not forgotten.
"""

from typing import List

from .base import Candidate, SettlementSource
from .state_ag_rss import FILING_STAGE_KEYWORDS, HEADERS, SETTLEMENT_KEYWORDS

import urllib.request
import xml.etree.ElementTree as ET


class FederalAgencyRSSSource(SettlementSource):
    """One instance per federal agency feed — see FEEDS below."""

    def __init__(self, agency: str, feed_url: str):
        self.agency = agency
        self.feed_url = feed_url
        self.name = f"agency_rss_{agency.lower().replace(' ', '_')}"

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        request = urllib.request.Request(self.feed_url, headers=HEADERS)
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()

        root = ET.fromstring(raw)
        candidates: List[Candidate] = []

        for item in root.findall(".//item"):
            if len(candidates) >= max_results:
                break

            title = (item.findtext("title") or "").strip()
            description = (item.findtext("description") or "")
            link = (item.findtext("link") or "").strip()
            pub_date = (item.findtext("pubDate") or "").strip()
            guid = (item.findtext("guid") or link or title).strip()

            has_settlement_language = SETTLEMENT_KEYWORDS.search(title) or SETTLEMENT_KEYWORDS.search(description)
            is_filing_stage = FILING_STAGE_KEYWORDS.search(title) or FILING_STAGE_KEYWORDS.search(description)
            if not has_settlement_language or is_filing_stage:
                continue

            candidates.append(Candidate(
                source_name=self.name,
                source_id=guid,
                case_name=title,
                source_url=link,
                court=self.agency,
                date_filed=pub_date,
                docket_number=None,
                confidence="ground_truth",
                note=(
                    f"Official {self.agency} press release — the announcement itself is "
                    "authentic. This does NOT confirm a public consumer claim form exists; "
                    "still requires finding (or confirming the absence of) an actual "
                    "administrator site, deadline, and proof requirements before publishing."
                ),
                raw={"title": title, "description": description},
            ))

        return candidates


FEEDS = {
    "CFPB": "https://www.consumerfinance.gov/about-us/newsroom/feed/",
}
