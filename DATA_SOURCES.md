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
2. **CourtListener is confirmed usable without even a signup** — verified 2026-08-21: unauthenticated `GET` against `v4/search/` returns HTTP 200 with real data. It only gets you *candidate lawsuits*, not confirmed claimable settlements, so every record it produces is tagged `confidence: inferred` and `lead-needs-review`.
3. **Ingestion is now a multi-source engine, not a single script** — see [`Tools/ingest/`](Tools/ingest/). `engine.py` runs every registered source independently; one source failing (network error, ToS block, schema change) is logged and skipped, not fatal to the run — see `Tools/ingest/tests/test_engine.py` for the resilience tests. `sources/courtlistener.py` is the one real source wired in today. Adding a new source (once one is confirmed to actually have a usable structured feed — see round 2 research, in progress) means writing one class implementing `SettlementSource`, nothing else changes.
4. **The `confidence` field is the real distinction, not the source count.** `"ground_truth"` means the source itself is the authority (e.g. a government agency's own announcement of its own settlement) — that still needs automated field validation, but not a human judgment call about whether it's real. `"inferred"` (everything today, since no ground-truth source is wired in yet) means a human must review before it ever reaches `SeedSettlements.json`, per Owed's own guardrail: *"a settlement is never published from an aggregator alone."*
5. **To run it:** `python3 -m Tools.ingest.engine` (no token needed; set `COURTLISTENER_API_TOKEN` for a higher rate limit). Output goes to `Tools/leads.json`, gitignored, never auto-published.
6. **The placeholder seed data stays placeholder** (`isSampleData: true`) until real leads are actually reviewed and confirmed. No fabricated "real" settlement was added to close this gap artificially.
