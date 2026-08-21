# Redress — free settlement/refund data sources (research, 2026-08-20)

**Bottom line: no government source offers a ready-made "open class-action settlement" feed.** This isn't a gap in the research — it's the same conclusion Owed's `PIPELINE.md` already reached, confirmed independently here. The moat in this category is human review, not infrastructure, because the data genuinely doesn't exist in curated form anywhere free.

## Verdict per source

| Source | Status | Notes |
|---|---|---|
| **CourtListener / RECAP v4 API** | **Usable, with friction** | Real, confirmed base URL `https://www.courtlistener.com/api/rest/v4/`. Free account + token, no payment, no approval wait. Docs: [wiki.free.law/c/courtlistener/help/api](https://wiki.free.law/c/courtlistener/help/api). Free-tier rate limits: 5 req/min, 50/hr, 125/day. **Gives dockets/lawsuits, not confirmed open claims** — a case existing doesn't mean a claim form is open. |
| **FTC refunds** (`ftc.gov/enforcement/refunds`) | **Not usable as a feed** | Human-readable case list only. The dashboard at `ftc.gov/ExploreData` is aggregate stats, not per-case structured data. FTC *does* have a real free developer API (`api.ftc.gov/v0`, free Data.gov key) but it covers HSR filings and Do-Not-Call complaints — **no refund/redress endpoint exists.** Scraping the refunds page is unverified-ToS territory; not recommended without separate legal review. |
| **SEC Fair Funds** | Scrape-only | Human-readable archive page, no API. `data.sec.gov`/EDGAR APIs are free and structured but cover filings, not fair-fund distributions. |
| **NAAG Multistate Settlements Database** | Scrape-only | Free to browse, searchable, no confirmed export/API. |
| **State AG consumer-protection pages** | Scrape-only, fragmented | Free but no structured feed; different format per state. |
| **PACER** | Paid | $0.10–0.12/page, capped $3/document. Its free-tier documents mostly overlap with what RECAP/CourtListener already mirrors for free. |

## What this means for Redress

1. **Don't build a live scraping pipeline against FTC/SEC/state pages yet** — ToS status is unverified and the data is aggregate/unstructured anyway. Same call Owed already made.
2. **CourtListener is the one real, free, ToS-clear option** — but it only gets you *candidate lawsuits*, not confirmed claimable settlements. [`Tools/fetch_courtlistener_leads.py`](Tools/fetch_courtlistener_leads.py) pulls candidate dockets into `Tools/leads.json`, explicitly marked `lead-needs-review` — **not** wired to `SeedSettlements.json`. A human still has to confirm the claims-administrator URL, deadline, and proof requirements per Owed's own compliance guardrail: *"a settlement is never published from an aggregator alone."*
3. **To run it:** free CourtListener account → API token → `export COURTLISTENER_API_TOKEN=...` → `python3 Tools/fetch_courtlistener_leads.py`. Not run yet in this session — no token available here.
4. **The placeholder seed data stays placeholder** (`isSampleData: true`) until real leads are actually reviewed and confirmed. No fabricated "real" settlement was added to close this gap artificially.
