# Redress — free settlement/refund data sources (research, 2026-08-20 & 21)

**Bottom line: no free source hands you a ready "here are open, claimable settlements" feed — and this round confirmed there's a deeper reason than just "nobody built one."** Even a state Attorney General's own official press release, which *is* genuine ground truth that a settlement happened, doesn't reliably tell you whether there's a public consumer claim form — some settlements go straight to the state treasury with no individual claims process, and press releases use nearly identical language for "we won money for consumers" and "we filed a lawsuit hoping to." A live test run caught real false positives from exactly this ambiguity (see below). Human review isn't a workaround for missing infrastructure — it's structurally required by what this data actually is.

## Verdict per source

| Source | Status | Notes |
|---|---|---|
| **CourtListener / RECAP v4 API** | **Usable, improved** | `https://www.courtlistener.com/api/rest/v4/`. Confirmed 2026-08-21: works fully **unauthenticated** (HTTP 200, real data) — no signup required at all; a free token only raises the rate limit. Confirmed field-scoped queries work: `q=description:"final approval"` narrows ~600K keyword matches to ~15K genuinely settlement-stage dockets — wired in as the default query. Still `confidence: inferred` — a docket existing, even one mentioning "final approval," isn't proof a claim window is open today. |
| **FTC refunds/redress** | **Not usable** | The real dashboard (`ftc.gov/ExploreData`, backed by a Tableau Public workbook) is now gated by an **AWS WAF CAPTCHA** — no reachable data without bypassing bot protection, which is off-limits. No refund/redress-specific RSS feed exists; FTC's real feed list only has general categories (press releases, data spotlights). |
| **SEC** | **Partially confirmed** | `sec.gov/news/pressreleases.rss` confirmed working (200, real RSS) — ground-truth but general SEC news, not litigation-specific. A litigation-releases RSS URL appears to exist (SEC returned a rate-limit page, not a 404) but was **not confirmed with a clean fetch** — not wired in until actually verified, not just "probably works." No Fair Fund distribution feed found. |
| **State AG press RSS — California & Florida** | **Usable, wired in** | `oag.ca.gov/news/feed` and `myfloridalegal.com/rss.xml` both confirmed real, live RSS (Florida requires a real browser `User-Agent`/`Accept` header or it 403s — not ToS evasion, just bot-detection that a normal script triggers by default). Official, ground-truth for *the announcement being real*. **Not** ground-truth for "a consumer claim form exists" — see the false-positive findings below. |
| **State AG — New York, Texas, Illinois** | **Not usable** | Checked each state's press-release page directly; no discoverable RSS/feed link on any of the three. Not wired in — no guessed URLs. |
| **Claims administrator sitemaps** (JND, Angeion, A.B. Data, Simpluris) | **Not usable** | All have a `sitemap.xml`, but every one is a general marketing sitemap (blog posts, case-study pages) — not a structured list of currently-active claims. Epiq and Rust Consulting's main domains have no sitemap/robots.txt at all (these firms typically run per-case microsites on separate domains instead). Kroll/KCC's old domain (`kccllc.com`) now fully redirects to `veritaglobal.com` post-rebrand — not re-investigated under the new name. |
| **NAAG Multistate Settlements DB, PACER** | Unchanged from round 1 | Scrape-only / paid, respectively — see prior notes. |

## What the live run actually caught — read this before trusting "ground_truth"

Wiring in the CA/FL AG feeds and running the engine for real (not hypothetically) surfaced two genuine false positives in the first pass, both fixed in [`sources/state_ag_rss.py`](Tools/ingest/sources/state_ag_rss.py):

1. **A bare "settlement" keyword matched a merger-antitrust settlement and unrelated legal news** — neither involves a consumer getting money back. Tightened the filter to require actual money-back language (`refund`, `restitution`, `money back`, `claim form`, `consumers eligible/owed`).
2. **After that fix, a lawsuit *filing* still matched** ("Files Lawsuits Against Operators of Illegal Online Casinos") because its description mentioned "restitution" as relief being *sought*, not relief already delivered. Added an explicit filing-stage exclusion list (`files lawsuit`, `sues`, `launches investigation`, etc.).

Both fixes are covered by regression tests in `Tools/ingest/tests/test_state_ag_rss.py`. After both fixes, a live run returned **zero false positives and zero AG leads** (no genuine consumer-settlement announcement happened to be in either state's feed at that moment) — that's the correct tradeoff for a `ground_truth` tier: surfacing nothing beats surfacing something confidently wrong.

## What this means for Redress

1. **The engine is multi-source and resilient, for real** — see [`Tools/ingest/`](Tools/ingest/). `engine.py` runs CourtListener + California AG + Florida AG independently; one source failing is logged and skipped, not fatal — proven by `test_one_source_failing_does_not_break_the_run`, not just claimed. Adding a source is one class implementing `SettlementSource`.
2. **`confidence: ground_truth` means "the announcement is authentic," not "ready to publish."** Every ground-truth candidate still needs a human to find (or confirm the absence of) an actual administrator site, deadline, and proof requirements — those fields don't exist in a press release regardless of how trustworthy the source is. This is intentional, not a shortcut that got missed.
3. **To run it:** `python3 -m Tools.ingest.engine` (no token/signup needed). Output goes to `Tools/leads.json`, gitignored, never auto-published.
4. **The placeholder seed data stays placeholder** (`isSampleData: true`) until a real lead is actually reviewed and confirmed against its administrator site. No fabricated "real" settlement was added to close this gap artificially.

## The non-manual-review plan (2026-08-21)

Redress never files on a user's behalf — it only surfaces information and
deep-links to the official administrator portal. That changes the failure
mode of getting something wrong: a stale deadline costs a user time, not
money or a bad submission, since the truth is on the real official site
the moment they land on it. That's still real harm worth minimizing, but
a meaningfully lower risk tier than an app that files for you — and it's
what makes automating review viable at all here.

Options considered, ranked by what's actually been built:

1. **Automated freshness re-verification — built.** [`Tools/ingest/freshness.py`](Tools/ingest/freshness.py) re-checks every settlement's administrator URL: still resolves, still looks claims-related (not a legal judgment, just "does it still mention claim/deadline/eligibility/settlement language"). Zero judgment required, so no reviewer — human or AI — is needed for it. Runs daily via [`.github/workflows/freshness-check.yml`](.github/workflows/freshness-check.yml); a failing run emails repo watchers automatically (GitHub's own scheduled-workflow-failure notification, no custom server). Verified against the real seed data: correctly flagged both placeholder `example.com` URLs as dead (404), proving it actually catches problems rather than rubber-stamping.
2. **LLM-based automated lead review — not built yet, deliberately.** Would replace the human step-for-step: read a docket/press-release, extract deadline/eligibility/administrator, flag "insufficient information" when it can't tell. Real judgment quality, genuinely non-manual — but it's a real decision (an LLM gets editorial authority over what real users see) with a real recurring cost (Anthropic API key required). Held pending that decision, not forgotten.
3. **Full source-and-date transparency in the UI** — not yet wired into the app itself. Showing "per California AG, Aug 20 2026" next to a listing shifts residual risk to informed consent instead of hidden certainty. Cheap to add once real (non-sample) data exists to show it on.
