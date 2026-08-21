"""
Automated freshness/staleness re-verification for settlement records.

This is deliberately NOT a judgment call — it doesn't decide whether a
settlement is "real," only whether its administrator URL still resolves
and still looks like it's talking about claims/deadlines. That's an
objective, code-only check: no reviewer (human or AI) is needed for it,
which is exactly why it's the right thing to automate first. A claims
portal that 404s, redirects to a generic homepage, or has gone completely
silent about deadlines is worth flagging regardless of how the record was
originally sourced.

This does NOT replace review of new leads — it only re-checks records
that already made it into SeedSettlements.json, on a recurring schedule,
so a settlement that quietly closed or moved doesn't sit there stale
indefinitely with nobody noticing.
"""

import json
import re
import sys
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import List, Optional

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}

# Not a legal/content judgment — just "does this page still look like it's
# talking about claims, deadlines, or eligibility at all," as a weak signal
# that it hasn't been replaced with a generic "case closed" or parked page.
CLAIMS_CONTENT_PATTERN = re.compile(
    r"\bclaim(s)?\b|\bdeadline\b|\beligib(le|ility)\b|\bsettlement\b", re.IGNORECASE
)


@dataclass
class FreshnessResult:
    url: str
    checked_at: str
    is_reachable: bool
    status_code: Optional[int] = None
    looks_like_claims_content: Optional[bool] = None
    error: Optional[str] = None

    @property
    def needs_attention(self) -> bool:
        """True if a human should look at this — either the URL is dead,
        or it's reachable but no longer looks claims-related at all."""
        if not self.is_reachable:
            return True
        return self.looks_like_claims_content is False


def check_url_freshness(url: str, timeout: int = 15) -> FreshnessResult:
    checked_at = datetime.now(timezone.utc).isoformat()

    if not url or not url.startswith(("http://", "https://")):
        return FreshnessResult(url=url, checked_at=checked_at, is_reachable=False,
                                error="Not a valid http(s) URL")

    request = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status_code = response.status
            body = response.read(200_000).decode("utf-8", errors="ignore")
    except urllib.error.HTTPError as exc:
        return FreshnessResult(url=url, checked_at=checked_at, is_reachable=False,
                                status_code=exc.code, error=str(exc))
    except Exception as exc:
        return FreshnessResult(url=url, checked_at=checked_at, is_reachable=False,
                                error=str(exc))

    return FreshnessResult(
        url=url,
        checked_at=checked_at,
        is_reachable=200 <= status_code < 400,
        status_code=status_code,
        looks_like_claims_content=bool(CLAIMS_CONTENT_PATTERN.search(body)),
    )


def check_seed_file(path: str) -> List[dict]:
    with open(path) as f:
        settlements = json.load(f)

    results = []
    for settlement in settlements:
        url = settlement.get("administratorPortalURLString", "")
        result = check_url_freshness(url)
        results.append({
            "id": settlement.get("id"),
            "title": settlement.get("title"),
            "isSampleData": settlement.get("isSampleData", False),
            **asdict(result),
            "needs_attention": result.needs_attention,
        })
    return results


def main() -> int:
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed-file", default=None,
                         help="Path to SeedSettlements.json (default: the app's real one)")
    args = parser.parse_args()

    seed_path = args.seed_file or __file__.replace(
        "Tools/ingest/freshness.py", "Redress/Resources/SeedSettlements.json"
    )

    results = check_seed_file(seed_path)
    attention_needed = [r for r in results if r["needs_attention"]]

    for r in results:
        flag = "NEEDS ATTENTION" if r["needs_attention"] else "ok"
        print(f"[{flag}] {r['title']} — {r['url']} "
              f"(reachable={r['is_reachable']}, status={r['status_code']})", file=sys.stderr)

    if attention_needed:
        print(f"\n{len(attention_needed)} of {len(results)} settlements need attention.", file=sys.stderr)
        return 1

    print(f"\nAll {len(results)} settlements look fresh.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
