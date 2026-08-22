# Redress — free settlement/refund data sources (research, 2026-08-20 & 21)

## A real lead reviewed and correctly NOT promoted (2026-08-22)

The Verita engine's first live find, `Holley Securities Settlement`
(deadline 19 Nov 2026), went through the same human-review bar as Comcast.
Result: **not promoted**, and that's the review working as designed, not a
failed lead.

What was confirmed real, directly against Holley Inc.'s own SEC 10-Q
filings (not aggregator summaries): the underlying case — *City of Fort
Lauderdale General Employees' Retirement System v. Holley, Inc.*, W.D.
Kentucky, No. 1:23-cv-148-S — is genuine, reached an agreement in principle
April 21, 2026, and received **preliminary court approval August 3, 2026**.
Verita is genuinely the administrator; the stated deadline is plausible
against that timeline. This is a *securities* settlement — the class is
stockholders who held HLLY between July 21, 2021 and February 6, 2023, not
Holley product customers, an important distinction the bare case name
doesn't convey.

What could **not** be confirmed: an actual claim-form or official notice
site. Verita's `settlement-case/` page is a thin marketing index — checked
every link on it programmatically, and it's all generic site navigation
(About, Careers, Services), no case-specific submission portal anywhere.
Without a real URL a user could actually file through, promoting this
would mean shipping a "Submit" button that doesn't work — the exact
failure mode this app exists to prevent. Not added to `SeedSettlements.json`.
Revisit if a dedicated notice site for this case surfaces later.

## First real settlement promoted (2026-08-21)

`hasson-v-comcast-2023-data-breach` — the Comcast/Xfinity 2023 data breach
settlement (Hasson v. Comcast Cable Communications, LLC, No. 2:23-cv-05039-JMY,
E.D. Pa.) — is the first non-sample record in `SeedSettlements.json`
(`seedVersion: 2`). Verified directly against the official court-authorized
site (`comcastbreachsettlement.com`, Kroll Settlement Administration LLC),
not an aggregator — a real discrepancy was caught in the process: multiple
aggregator sites reported the deadline as August 14, 2026 (already past by
the time this was checked); the actual site says the deadline was extended
to **September 14, 2026**. Also caught along the way: a citation from search
results pointed at a court PDF that turned out to be for a *different* case
entirely (AT&T, not Comcast, despite both being Kroll-administered MDLs) —
caught by reading the document instead of trusting the citation.

**Technical note:** the official site is behind Cloudflare's bot-protection
challenge, which blocks plain HTTP requests (`curl`, `urllib`) with a 403 —
confirmed the hard way when the automated freshness checker (built earlier)
flagged this genuinely-live site as unreachable. Fixed by teaching the
checker to recognize a Cloudflare challenge page and report it as
"needs manual verification" rather than "broken" — see
`Tools/ingest/freshness.py`. The verification itself was done with the
actual browser tool, not by bypassing anything: Cloudflare's challenge is
specifically designed to pass real browsers through automatically and
block scripted fetches, so using a real browser is the intended path
through it, unlike the FTC CAPTCHA declined earlier in this research.

**Bottom line: no free source hands you a ready "here are open, claimable settlements" feed — and this round confirmed there's a deeper reason than just "nobody built one."** Even a state Attorney General's own official press release, which *is* genuine ground truth that a settlement happened, doesn't reliably tell you whether there's a public consumer claim form — some settlements go straight to the state treasury with no individual claims process, and press releases use nearly identical language for "we won money for consumers" and "we filed a lawsuit hoping to." A live test run caught real false positives from exactly this ambiguity (see below). Human review isn't a workaround for missing infrastructure — it's structurally required by what this data actually is.

## Verdict per source

| Source | Status | Notes |
|---|---|---|
| **CourtListener / RECAP v4 API** | **Usable, improved** | `https://www.courtlistener.com/api/rest/v4/`. Confirmed 2026-08-21: works fully **unauthenticated** (HTTP 200, real data) — no signup required at all; a free token only raises the rate limit. Confirmed field-scoped queries work: `q=description:"final approval"` narrows ~600K keyword matches to ~15K genuinely settlement-stage dockets — wired in as the default query. Still `confidence: inferred` — a docket existing, even one mentioning "final approval," isn't proof a claim window is open today. |
| **FTC refunds/redress** | **Not usable** | The real dashboard (`ftc.gov/ExploreData`, backed by a Tableau Public workbook) is now gated by an **AWS WAF CAPTCHA** — no reachable data without bypassing bot protection, which is off-limits. No refund/redress-specific RSS feed exists; FTC's real feed list only has general categories (press releases, data spotlights). |
| **SEC litigation-releases RSS** | **Confirmed working, deliberately not wired in** | `sec.gov/enforcement-litigation/litigation-releases/rss` — confirmed 2026-08-21 with a proper identifying `User-Agent` per SEC's own Fair Access policy (10 req/sec allowed; the earlier "rate limit" response was this environment's shared egress IP being generically throttled, not a real block). Real, live, 200. **But tested against 50 real current items with two keyword sets (generic consumer-restitution language, and SEC-specific "Fair Fund"/"harmed investors"/"disgorgement" vocabulary) — zero matches on both.** SEC litigation releases are enforcement actions against individuals/firms (fraud, insider trading, unregistered securities) — not consumer-facing settlements. Fair Fund investor-distribution notices, the SEC content that *would* be relevant, aren't published in this feed and no dedicated feed for them was found. Building an adapter for a source that tests at 0/50 real matches is worse than not building one — it's not wired in, on real evidence, not because it doesn't exist. |
| **State AG press RSS — California & Florida** | **Usable, wired in** | `oag.ca.gov/news/feed` and `myfloridalegal.com/rss.xml` both confirmed real, live RSS (Florida requires a real browser `User-Agent`/`Accept` header or it 403s — not ToS evasion, just bot-detection that a normal script triggers by default). Official, ground-truth for *the announcement being real*. **Not** ground-truth for "a consumer claim form exists" — see the false-positive findings below. |
| **State AG — New York, Texas, Illinois** | **Not usable** | Checked each state's press-release page directly; no discoverable RSS/feed link on any of the three. Not wired in — no guessed URLs. |
| **Claims administrator sitemaps** (JND, Angeion, A.B. Data, Simpluris) | **Not usable** | All have a `sitemap.xml`, but every one is a general marketing sitemap (blog posts, case-study pages) — not a structured list of currently-active claims. Epiq and Rust Consulting's main domains have no sitemap/robots.txt at all (these firms typically run per-case microsites on separate domains instead). |
| **Verita Global (Kroll's post-rebrand site)** | **Usable, wired in** | `kccllc.com` fully redirects here post-rebrand — re-investigated under the new name and it's a real find: `veritaglobal.com/mt_settlement_case-sitemap.xml` is a dedicated WordPress post type, 531 real settlement-case pages confirmed 2026-08-21. Each page states its own claim deadline directly ("Claim deadline: DD Mon YYYY") — confirmed on multiple real pages, both a currently-open case (deadline months out) and an already-closed one (deadline passed), rendering the same way. This is **stronger ground truth than a press release** — Verita/Kroll *is* the administrator, not an announcer. Live engine run found a real open case (`Holley Securities Settlement`, deadline 19 Nov 2026) on the first try after fixing a sampling issue (see below). |
| **NAAG Multistate Settlements DB, PACER** | Unchanged from round 1 | Scrape-only / paid, respectively — see prior notes. |

## What the live run actually caught — read this before trusting "ground_truth"

Wiring in the CA/FL AG feeds and running the engine for real (not hypothetically) surfaced two genuine false positives in the first pass, both fixed in [`sources/state_ag_rss.py`](Tools/ingest/sources/state_ag_rss.py):

1. **A bare "settlement" keyword matched a merger-antitrust settlement and unrelated legal news** — neither involves a consumer getting money back. Tightened the filter to require actual money-back language (`refund`, `restitution`, `money back`, `claim form`, `consumers eligible/owed`).
2. **After that fix, a lawsuit *filing* still matched** ("Files Lawsuits Against Operators of Illegal Online Casinos") because its description mentioned "restitution" as relief being *sought*, not relief already delivered. Added an explicit filing-stage exclusion list (`files lawsuit`, `sues`, `launches investigation`, etc.).

Both fixes are covered by regression tests in `Tools/ingest/tests/test_state_ag_rss.py`. After both fixes, a live run returned **zero false positives and zero AG leads** (no genuine consumer-settlement announcement happened to be in either state's feed at that moment) — that's the correct tradeoff for a `ground_truth` tier: surfacing nothing beats surfacing something confidently wrong.

**Verita, separately, caught a real sampling bug (2026-08-21):** the first live run against the real site returned zero candidates even though open cases genuinely exist. The sitemap isn't ordered by recency — the first 15 URLs checked were all old, closed securities-litigation cases (`wells-fargo-2018-securities-litigation`, `rite-aid-securities-settlement`, etc.), so a fixed-prefix scan systematically missed the open ones scattered elsewhere in the 531-case list. Fixed by randomly sampling instead of always checking the same block; the very next run found a real open case (`Holley Securities Settlement`, deadline 19 Nov 2026).

## Engine review — why isn't it pulling in more settlements? (2026-08-22)

Ran the full engine live and audited every source's actual yield rather than assuming. One real run: CourtListener 15/15, CA AG 0, FL AG 0, Verita 1/40 sampled — **16 total leads, 1 ground-truth.** Two distinct causes, not one:

1. **By design, most of what the engine finds can't be auto-published — this is the trust tradeoff working as intended, not a bug.** CourtListener's 15 results are real dockets, precision-filtered to settlement-stage language, but `confidence: inferred` always, permanently — a docket existing is never proof a claim window is open, so these can never skip human review no matter how the query is tuned. Same for AG RSS: `ground_truth` there means "the press release is authentic," not "a claim form exists." The only source producing a directly auto-usable "someone should look at this" ground-truth signal is Verita, because it's the actual administrator stating its own deadline. **The real bottleneck on how many settlements ship is human review time, not engine capacity** — this matches the Product/Momentum section of `ASO_PLAYBOOK.md`, which already flags "more real settlements faster" as the top expected review request.
2. **A real, fixable gap, found and fixed today: Verita's yield was capped by how sampling worked, not by how much real data exists.** The random-40-of-531-per-run approach (see the 2026-08-21 note above) had no memory between runs — every run resampled blind, with real odds of rechecking pages already known to be closed instead of covering new ground, so there was no guarantee the full 531 was ever seen. Fixed in [`sources/verita.py`](Tools/ingest/sources/verita.py): the source now persists per-page state (`Tools/ingest/.state/verita_seen.json`, gitignored — local run-state, not source data) and always checks never-before-seen pages first. Verified live, not just unit-tested: two consecutive runs against the real site checked 40 then a **different** 40 (80 distinct pages total, zero overlap, confirmed by reading the state file after each run) — coverage of all 531 real cases is now monotonic, reaching 100% in ~14 runs instead of drifting indefinitely. Once full coverage is reached, the same state file lets the source fall back to re-checking its oldest-checked pages, which doubles as a freshness pass on cases it already knows about.
3. **State AG RSS returning 0 both times isn't a bug** — these are the two most recent items in each feed at the moment the engine runs, and most AG press releases (of any kind) aren't consumer-refund settlements. This is a low-hit-rate-by-nature source, not a broken one; only NY/TX/IL remain unwired, and only because no discoverable feed exists for them (checked directly, not guessed).

## What this means for Redress

1. **The engine is multi-source and resilient, for real** — see [`Tools/ingest/`](Tools/ingest/). `engine.py` runs CourtListener + California/Florida AG + Verita independently; one source failing is logged and skipped, not fatal — proven by `test_one_source_failing_does_not_break_the_run`, not just claimed. Adding a source is one class implementing `SettlementSource`.
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
