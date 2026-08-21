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

# Confirmed live 2026-08-21 against a real 403 from comcastbreachsettlement.com.
BOT_PROTECTION_PATTERN = re.compile(
    r"Attention Required! \| Cloudflare|cf-browser-verification|Just a moment\.\.\.|"
    r"cf_chl_opt|__cf_chl_rt_tk", re.IGNORECASE
)


@dataclass
class FreshnessResult:
    url: str
    checked_at: str
    is_reachable: bool
    status_code: Optional[int] = None
    looks_like_claims_content: Optional[bool] = None
    error: Optional[str] = None
    blocked_by_bot_protection: bool = False

    @property
    def needs_attention(self) -> bool:
        """True if a human should look at this. A bot-protection block
        (Cloudflare et al.) is deliberately NOT treated the same as a dead
        link — plenty of legitimate, live claims-administrator sites (Kroll
        in particular) run Cloudflare and reject plain HTTP requests the
        same way they'd reject a scraper, even though a real browser gets
        through fine. Confirmed live 2026-08-21: comcastbreachsettlement.com
        403s this checker but is genuinely live and current when checked
        with an actual browser. Flagging it identically to a real 404 would
        make this tool cry wolf on working links."""
        if self.blocked_by_bot_protection:
            return False
        if not self.is_reachable:
            return True
        return self.looks_like_claims_content is False

    @property
    def needs_manual_verification(self) -> bool:
        """Distinct from needs_attention: we genuinely don't know the
        status, not that something looks wrong."""
        return self.blocked_by_bot_protection


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
        error_body = ""
        try:
            error_body = exc.read(200_000).decode("utf-8", errors="ignore")
        except Exception:
            pass
        blocked = exc.code == 403 and BOT_PROTECTION_PATTERN.search(error_body) is not None
        return FreshnessResult(url=url, checked_at=checked_at, is_reachable=False,
                                status_code=exc.code, error=str(exc),
                                blocked_by_bot_protection=blocked)
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
        seed_file = json.load(f)
    settlements = seed_file["settlements"] if isinstance(seed_file, dict) else seed_file

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
            "needs_manual_verification": result.needs_manual_verification,
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
    manual_check_needed = [r for r in results if r["needs_manual_verification"]]

    for r in results:
        if r["needs_attention"]:
            flag = "NEEDS ATTENTION"
        elif r["needs_manual_verification"]:
            flag = "BOT-BLOCKED, CHECK MANUALLY"
        else:
            flag = "ok"
        print(f"[{flag}] {r['title']} — {r['url']} "
              f"(reachable={r['is_reachable']}, status={r['status_code']})", file=sys.stderr)

    if manual_check_needed:
        print(f"\n{len(manual_check_needed)} settlement(s) are behind bot protection this "
              f"checker can't get through (e.g. Cloudflare) — not flagged as broken, but a "
              f"human should periodically confirm these with a real browser.", file=sys.stderr)

    if attention_needed:
        print(f"\n{len(attention_needed)} of {len(results)} settlements need attention.", file=sys.stderr)
        return 1

    print(f"\nAll {len(results)} settlements look fresh "
          f"({len(manual_check_needed)} pending manual bot-protection check).", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
