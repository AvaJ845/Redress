"""
CourtListener v4 search — confirmed free, works unauthenticated (HTTP 200,
verified 2026-08-21). Gives real dockets/lawsuits, NOT confirmed open
claims — a docket existing doesn't mean a claim form is open. Always
"inferred" confidence; never auto-published.
"""

import json
import os
import time
import urllib.parse
import urllib.request
from typing import List, Optional

from .base import Candidate, SettlementSource

API_BASE = "https://www.courtlistener.com/api/rest/v4"
MAX_REQUESTS_PER_RUN = 10  # stays conservative regardless of auth state
SECONDS_BETWEEN_REQUESTS = 3


class CourtListenerSource(SettlementSource):
    name = "courtlistener"

    def __init__(self, token: Optional[str] = None):
        self.token = token or os.environ.get("COURTLISTENER_API_TOKEN")

    def _fetch_page(self, url: str) -> dict:
        headers = {"Authorization": f"Token {self.token}"} if self.token else {}
        request = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))

    def fetch(self, query: str, max_results: int) -> List[Candidate]:
        params = urllib.parse.urlencode({"q": query, "type": "r", "order_by": "dateFiled desc"})
        url = f"{API_BASE}/search/?{params}"

        candidates: List[Candidate] = []
        requests_made = 0

        while url and len(candidates) < max_results and requests_made < MAX_REQUESTS_PER_RUN:
            page = self._fetch_page(url)
            requests_made += 1

            for result in page.get("results", []):
                docket_id = result.get("docket_id") or result.get("id")
                candidates.append(Candidate(
                    source_name=self.name,
                    source_id=str(docket_id),
                    case_name=result.get("caseName") or result.get("case_name") or "",
                    source_url="https://www.courtlistener.com" + result.get("docket_absolute_url", ""),
                    court=result.get("court") or result.get("court_id"),
                    date_filed=result.get("dateFiled") or result.get("date_filed"),
                    docket_number=result.get("docketNumber") or result.get("docket_number"),
                    confidence="inferred",
                    note=(
                        "A docket existing does not mean a claim form is open. "
                        "Confirm preliminary/final approval on the docket itself, "
                        "find the court-appointed administrator's official claim site "
                        "(never a law-firm lead-gen page), and confirm the real claim "
                        "deadline and proof-of-purchase requirements there, not here."
                    ),
                    raw=result,
                ))
                if len(candidates) >= max_results:
                    break

            url = page.get("next")
            if url:
                time.sleep(SECONDS_BETWEEN_REQUESTS)

        return candidates
