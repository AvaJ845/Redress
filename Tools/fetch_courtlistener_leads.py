#!/usr/bin/env python3
"""
Pulls candidate class-action dockets from the CourtListener v4 API.

This is a LEADS tool, not a publisher. Output records are NOT settlements —
a lawsuit existing does not mean a claim form is open yet, and CourtListener
has no field for "claim deadline" or "official administrator URL." Every
record this script emits is marked needs_review and must be manually
confirmed against the actual case docket / claims-administrator site before
it is ever turned into a Settlement entry in SeedSettlements.json. This
mirrors Owed's own PIPELINE.md: "a settlement is never published from an
aggregator alone."

Requirements:
  - None strictly — CourtListener's search API allows unauthenticated GET
    requests (confirmed 2026-08-21: HTTP 200, real results, no token sent).
  - Optional: a free CourtListener account + API token raises the rate
    limit (confirmed for authenticated free tier: 5 req/min, 50/hour,
    125/day — anonymous limits are unconfirmed/likely lower, so this script
    stays conservative regardless of whether a token is set).

Usage:
  python3 Tools/fetch_courtlistener_leads.py --query "class action settlement" --max-results 20
  # Optionally, for a higher rate limit:
  export COURTLISTENER_API_TOKEN="your-token-here"

Output:
  Tools/leads.json — array of lead records for a human to review.
"""

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from typing import Optional

API_BASE = "https://www.courtlistener.com/api/rest/v4"
MAX_REQUESTS_PER_RUN = 10  # well under the 50/hour free-tier cap
SECONDS_BETWEEN_REQUESTS = 3


def fetch_page(url: str, token: Optional[str]) -> dict:
    headers = {"Authorization": f"Token {token}"} if token else {}
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default="class action settlement",
                         help="Keyword search against docket case names/text")
    parser.add_argument("--max-results", type=int, default=20)
    parser.add_argument("--output", default=os.path.join(os.path.dirname(__file__), "leads.json"))
    args = parser.parse_args()

    token = os.environ.get("COURTLISTENER_API_TOKEN")
    if not token:
        print("No COURTLISTENER_API_TOKEN set — running unauthenticated (lower rate limit, still works).",
              file=sys.stderr)

    # order_by dateFiled desc: a keyword-only search is dominated by old,
    # long-closed cases (confirmed 2026-08-21 — most hits were 2005-2016),
    # which are useless as "currently open" leads. Bias toward recent filings.
    params = urllib.parse.urlencode({"q": args.query, "type": "r", "order_by": "dateFiled desc"})
    url = f"{API_BASE}/search/?{params}"

    leads = []
    requests_made = 0

    while url and len(leads) < args.max_results and requests_made < MAX_REQUESTS_PER_RUN:
        try:
            page = fetch_page(url, token)
        except Exception as exc:
            print(f"ERROR fetching {url}: {exc}", file=sys.stderr)
            break
        requests_made += 1

        for result in page.get("results", []):
            leads.append({
                "source": "courtlistener",
                "courtlistener_id": result.get("docket_id") or result.get("id"),
                "case_name": result.get("caseName") or result.get("case_name"),
                "court": result.get("court") or result.get("court_id"),
                "date_filed": result.get("dateFiled") or result.get("date_filed"),
                "docket_number": result.get("docketNumber") or result.get("docket_number"),
                "courtlistener_url": "https://www.courtlistener.com" + result.get("docket_absolute_url", ""),
                "status": "lead-needs-review",
                "note": (
                    "NOT a confirmed open settlement. A docket existing does not mean "
                    "a claim form is open. Before turning this into a Settlement record: "
                    "(1) confirm preliminary/final approval on the docket itself, "
                    "(2) find the court-appointed administrator's official claim site "
                    "(never a law-firm lead-gen page), (3) confirm the real claim deadline "
                    "and proof-of-purchase requirements there, not here."
                ),
            })
            if len(leads) >= args.max_results:
                break

        url = page.get("next")
        if url:
            time.sleep(SECONDS_BETWEEN_REQUESTS)

    with open(args.output, "w") as f:
        json.dump(leads, f, indent=2)

    print(f"Wrote {len(leads)} unreviewed leads to {args.output} ({requests_made} API requests made).")
    print("These are NOT ready to publish — see the 'note' field on each record.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
