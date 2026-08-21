"""
State Attorney General press-release RSS feeds — confirmed real, official,
government-published (not aggregator-inferred). Verified 2026-08-21:
  - California: https://oag.ca.gov/news/feed (200, real RSS, no special headers needed)
  - Florida:    https://www.myfloridalegal.com/rss.xml (200, but requires a
                 real browser User-Agent + Accept header or it 403s)
New York, Texas, and Illinois do not expose a discoverable RSS feed
(checked their press-release pages directly; no feed link found) — not
wired in, don't guess at a URL for them.

IMPORTANT CAVEAT — read before treating "ground_truth" as "ready to
publish": these feeds confirm an AG press release is authentic and the
described enforcement action really happened. They do NOT confirm a
public consumer claim form exists — some settlements go entirely to the
state treasury or a restitution fund with no individual claims process.
Every candidate from this source still needs a human to find (or confirm
the absence of) an actual court-appointed administrator's claim site,
deadline, and proof requirements before it becomes a Settlement record.
"ground_truth" here means "the announcement is real," not "safe to
auto-publish."
"""

import re
import urllib.request
import xml.etree.ElementTree as ET
from typing import List

from .base import Candidate, SettlementSource

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/rss+xml, application/xml, text/xml, */*",
}

# Bare "settlement" is too broad on its own — a live run (2026-08-21) showed
# it matching a merger-antitrust settlement and a lawsuit *filing* (not even
# a settlement), neither of which involves consumers getting money back.
# Require actual money-back-to-consumers language, not just the word
# "settlement" appearing somewhere in an AG press release.
SETTLEMENT_KEYWORDS = re.compile(
    r"\brefunds?\b|\brestitution\b|\bmoney back\b|\bclaim form\b|"
    r"consumers? (?:eligible|owed|can (?:file|claim))",
    re.IGNORECASE
)

# A press release can mention "restitution" or "refunds" as relief a lawsuit
# is SEEKING, not relief a settlement has already delivered — a live run
# (2026-08-21) matched "Files Lawsuits Against Operators of Illegal Online
# Casinos" this way. Exclude filing-stage language explicitly. This still
# isn't foolproof — it's a keyword heuristic, not classification — a human
# still has to read the headline before treating anything as real.
FILING_STAGE_KEYWORDS = re.compile(
    r"\bfiles? (?:a )?lawsuits?\b|\bfiles? suit\b|\bsues?\b|\bsuing\b|"
    r"\blaunches? (?:an )?investigation\b|\bopens? (?:an )?investigation\b|"
    r"\bannounces? investigation\b",
    re.IGNORECASE
)


class StateAGRSSSource(SettlementSource):
    """One instance per state — see FEEDS below for the registered states."""

    def __init__(self, state: str, feed_url: str):
        self.state = state
        self.feed_url = feed_url
        self.name = f"ag_rss_{state.lower()}"

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
                court=f"{self.state} Attorney General",
                date_filed=pub_date,
                docket_number=None,
                confidence="ground_truth",
                note=(
                    f"Official {self.state} AG press release — the announcement itself is "
                    "authentic. This does NOT confirm a public consumer claim form exists; "
                    "some AG settlements go to the state treasury with no individual claims "
                    "process. Still requires finding (or confirming the absence of) an actual "
                    "administrator site, deadline, and proof requirements before publishing."
                ),
                raw={"title": title, "description": description},
            ))

        return candidates


FEEDS = {
    "California": "https://oag.ca.gov/news/feed",
    "Florida": "https://www.myfloridalegal.com/rss.xml",
}
