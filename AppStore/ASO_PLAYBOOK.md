# Redress — ASO Playbook

Applying ASO Playbook's three-part engine to Redress.

## 1 · Discovery — get found ✅ (built, in `METADATA.md`)

Apple indexes **App Name + Subtitle + Keywords** as one string, so every word
is spent once, keyword-first, no repeats.

- **App Store Name (≤30):** `Settlement Tracker - Redress` — leads with the
  highest-value keyword an indie can still fight for. Fighting head-on for
  `class action` / `claim` in the Name itself is a Trap: six-plus live
  competitors already own those exact words (`Claim: Class Actions`,
  `Claimly: Class Actions`, `Claim Queen: Settlement Payout`, `Settlement
  Finder - Collect`, `Payout`, `Class Action Buddy`, `Catch`).
- **Subtitle (≤30):** `Private claim deadline alerts` — all-new words vs.
  Name, and the one differentiator research found **zero** competitors
  leading with in their own App Store copy: on-device privacy.
- **Keywords (≤100):** `money,refund,payout,compensation,lawsuit,consumer,eligibility,receipt,unclaimed,class,action,docket` (**99/100, verified with `len()`, not eyeballed**)
- **Combinations harvested:** `settlement tracker`, `private claim`,
  `consumer refund`, `lawsuit payout`, `claim deadline alerts`, `class action`,
  `court docket`, `unclaimed money`.
- **2026-08-20 audit correction:** an earlier pass of this file claimed the
  keywords field was at 91/100 and that `class action` had been "folded into
  the keyword field." Both were wrong — actual length was 79/100, and
  `class`/`action` were never added anywhere (Name, Subtitle, or Keywords).
  That's the single highest-intent phrase in this whole category; leaving it
  out entirely, not just out of the Name, was a real findability defect, not
  a cosmetic one. Fixed above.
- **2026-08-22 audit correction (Naming Fellows-Roast):** a fresh, adversarial
  re-check — not a rubber stamp — of the two claims below found both
  overstated against real, current App Store evidence:
  1. The claim that `Settlement Tracker` was an "untouched" phrase was
     **false**. A live, rated competitor — **Claim Cash: Settlement Tracker**
     ([id6760473460](https://apps.apple.com/us/app/claim-cash-settlement-tracker/id6760473460),
     developer Eversight, 4.5★/39 ratings, Finance category, subtitle "Class
     Action Finder & Money") — already uses that exact two-word phrase as
     its own Name's lead keywords, and pairs it with the even more visceral
     word "Cash." The phrase is contested, not exclusive. It still earns its
     place in the Name (better than most rivals' brand-first pattern), but
     the earlier "untouched" framing overstated the finding and is corrected
     here rather than left standing.
  2. The Collision row's read of `Redress Pro` as merely "thematically
     adjacent" undersold a real overlap: Redress Pro's actual subtitle is
     **"Private crisis recovery kit"** — no accounts, no server uploads,
     fully local, dispute-letter drafting — i.e. it already makes almost the
     exact privacy-first/no-accounts positioning claim this project treats as
     its own unclaimed differentiator (see Discovery section above, "the one
     differentiator research found zero competitors leading with"). That
     claim is not literally zero-competitor; it's zero-competitor *in the
     class-action-settlement vertical specifically*. Worth stating precisely
     instead of broadly.
  - **Net verdict unchanged (still Approve, see below) but for a narrower
    reason:** `Redress` remains clear of any exact bare-Name collision in
    this vertical, and none of the three `Redress`-named apps found
    (`Redress Pro`, plain `Redress App` — an African clothing marketplace,
    2.5★, [id6760317256](https://apps.apple.com/ga/app/redress-app/id6760317256) —
    and `ReDress: AI Virtual Try-On`) compete for the same search intent.
    But ship this eyes-open: the word `Redress` itself is a five-letter
    formal/legal noun with no everyday-speech precedent among the 6+
    researched competitors (`Catch`, `Payout`, `Collect`, `Settlemate`,
    `ClassyAction`, `Claim Cash` — every single one is a plain verb or
    money-noun). It is legible once read, but costs a beat of
    pronunciation/definition-parsing in a search-results glance that
    "Catch" or "Payout" don't. The mitigating case, argued by the
    Technology-Evangelism Fellow in the same roast: it's the only name in
    the category that is *literally, precisely* what the product does
    ("redress" = remedy for a wrong) rather than a generic money-word —
    real brand-story material, conditional on the subtitle/onboarding doing
    the definition-work in the first three seconds, which the current
    subtitle (`Private claim deadline alerts`) does not yet do on its own.
- **Deliberately excluded:**
  - `file` / `filing` — the app never files on your behalf, only deep-links
    to the official administrator portal. Claiming otherwise would
    misrepresent the product the way Payout's growth copy does.
  - `guarantee` / `guaranteed money` — a live competitor (Settlemate) is
    currently facing false-advertising complaints over exactly this kind of
    promise. Don't invite the same scrutiny.
  - `class action` as a head-on Name phrase — folded into the keyword field
    instead of spent in the scarce 30-char Name slot.

## 1b · Findability audit — real search results, not the theory (2026-08-22)

The user's direct question: will the chosen keywords actually be *findable*
by someone searching for this kind of app? Tested against Apple's real,
live public search index (`itunes.apple.com/search`, unauthenticated,
same content real App Store search draws from) instead of reasoning about
it — 20+ real user-style queries, not the ~7 competitor names the original
Naming Council check was built around.

**The honest answer has two parts, and they point different directions:**

1. **Mechanically, yes — the words are real, correctly formatted, and match
   genuine query vocabulary.** Every word in the Keywords field returned
   relevant results when queried directly. That part of the original audit
   holds up.
2. **Competitively, "findable" is not the same question as "will rank."**
   This category is far more crowded than the original competitor list
   (7 names) captured. Querying `class action settlement`, `class action`,
   `get my money back`, `lawsuit payout`, and `claim my money` surfaces the
   same small set of incumbents over and over, several with review counts
   an unknown app cannot out-rank on launch day regardless of keyword-string
   quality: **Settlemate: Claim Savings** (72,311 ratings, 4.80★) dominates
   nearly every broad query tested; **PayMe - Claim Your Money** (35,421),
   **Payout: Claim Class Actions** (11,087), and **Collect - Settlement
   Finder** (3,456) round out the top tier. None of these three appeared
   with their real scale in the original Naming Council pass. Apple's
   ranking weighs install velocity and rating volume heavily — a perfect
   keyword string on a zero-review app does not out-rank a 72K-rated
   incumbent for the same shared term; it only guarantees the app is *in*
   the index for that term, not *near the top* of it. This is a Momentum
   problem (§4 below), not a Discovery problem, and no amount of keyword
   tuning fixes it — only real reviews, over real time, do.
   - **The one genuinely good news finding, confirmed rather than assumed:**
     the Name's actual lead phrase, `Settlement Tracker`, tested as one of
     the *least* crowded viable phrases in the category — only one real
     contested competitor (`Claim Cash: Settlement Tracker`, 39 ratings;
     see the 2026-08-22 Naming Fellows-Roast note above). The specific bet
     this project made is a genuinely better angle than the high-volume
     terms, confirmed by live query, not just reasoned inference.
   - **A real, actionable gap found and fixed:** `unclaimed money` /
     `unclaimed settlement` tested as real, on-topic, low-competition query
     vocabulary (`Trace - Unclaimed Money Finder`, 5 ratings; `US Unclaimed
     Money`, 1 rating — no dominant incumbent) that the Keywords field
     wasn't targeting at all. Meanwhile `encrypted` — a word already in the
     field — tested as pure dead weight: every real result for it was a
     messaging/storage app (Signal, MEGA, Proton Mail) with 100K–1M+
     ratings, the wrong audience entirely. Swapped one for the other at
     identical character cost (9 chars each) — see `METADATA.md` for the
     exact before/after. `receipt` and `docket` tested similarly weak
     (dominated by cashback-scanning and unrelated docket/immunization
     apps respectively) but weren't cut this pass — flagged here as the
     next candidates if the field needs more room later.
   - **A fast-moving-category signal, not a naming risk:** this same
     research turned up several very recently launched competitors with
     near-zero ratings (`Owed — Settlement Finder`, released 2026-07-30,
     dev "Raj Kumar", unrelated to this project; `ClaimNow - Settlement
     Claim`, released 2026-07-28; `TapClaim`, released 2026-07-13) — new
     entrants are appearing roughly weekly. Worth knowing the field keeps
     shifting under any keyword plan, not something to react to per-entrant.

**Bottom line for the user's question:** the keywords will be found — that
part is confirmed, not assumed. Whether Redress *surfaces* for the highest-
volume shared terms depends on review velocity post-launch far more than
on any further keyword tuning; the Momentum section (§4) is where that
actually gets solved, not here.

## 2 · The Naming Council — final verdict

| Fellow | Lean | Key finding |
|---|---|---|
| **Discoverability** | Approve *(corrected 2026-08-22)* | Name leads with `Settlement Tracker`, not the brand. Subtitle repeats zero Name words. Keywords field repeats nothing from Name/Subtitle, now genuinely at 99/100 after fixing a miscounted/missing-`class action` error (see audit note above). **`Settlement Tracker` is confirmed CONTESTED, not untouched** — live competitor Claim Cash: Settlement Tracker (4.5★/39 ratings) uses the identical phrase (see 2026-08-22 audit note) — it still earns the lead-phrase slot on Indie-Battlefield logic (better to fight a two-app field than the six-plus-app `class action`/`claim` field) but the earlier "untouched" framing was wrong and is retracted. **Caveat unchanged:** "Popularity" is inferred from competitor density, not measured Apple Search Ads volume data. |
| **Collision** | Approve *(narrowed 2026-08-22)* | `Recoup` was a **hard reject** — live App Store app "Recoup: Refund Wasted Expenses" ([id1569903003](https://apps.apple.com/jm/app/recoup-refund-wasted-expenses/id1569903003)) from a developer account literally named "Recoup" ([id1476990545](https://apps.apple.com/kg/developer/recoup/id1476990545)), doing near-identical work. `Claimly` was also a **hard reject** — multiple live class-action apps already use it exactly (`Claimly: Class Actions` [id6755642219](https://apps.apple.com/us/app/claimly-class-actions/id6755642219), `Claimly: Easy Claim Settlement` [id6755294155](https://apps.apple.com/us/app/claimly-easy-claim-settlement/id6755294155)). `Redress` is clear of any exact **Name-string** collision in this vertical — nearest neighbors are `ReDress: AI Virtual Try-On` (fashion, unrelated), a peer-to-peer `Redress App` (African clothing marketplace, 2.5★, unrelated), and `Redress Pro` (privacy-first crisis-recovery kit — **positioning overlap confirmed real, not just "thematically adjacent"**, see 2026-08-22 audit note — but still a different vertical: incident/identity-crisis response, not consumer class-action refunds, and no Name-string overlap with our full Name `Settlement Tracker - Redress`). Worth a periodic re-check as Redress Pro grows, nothing more. |
| **Portfolio** | **Approve** *(status change — see below)* | An earlier pass of this council rejected shipping this app at all, because AvaResearchLLC's other app, **Owed**, targeted the exact same category and the same keywords, including "owed" itself. **The user has since confirmed Owed is not shipping** — it's retired/reference-only. That removes the self-competition problem entirely. No other portfolio app (Top Pup, Decoder/Chunk Racer, Hummingbird, Kestrel) competes for this keyword space. Reference file `portfolio-namespaces.md` updated accordingly. |

**VERDICT: Approve.** `Settlement Tracker - Redress` clears all three Fellows.
The bundle ID, project folder, and all in-app strings have been renamed from
Recoup → Redress (`AvaResearchLLC.Redress`) and the project rebuilds clean.

## 3 · Conversion — win the tap 🔄 (mid-refresh, 2026-08-23 — see below)

- [x] **App icon** — shield + checkmark mark, **Deep Emerald → Ink
  gradient, Warm Ivory shield, Deep Emerald checkmark** (regenerated
  2026-08-23 from `Tools/make_icon.py` — the earlier teal-to-navy version
  no longer matches the brand system). Real artwork, confirmed via
  Xcode's own iPad icon auto-generation from the single 1024 source.
- [ ] **Screenshots (6.9", 1320×2868 — verified exact, not eyeballed):**
  mid-refresh against the Home-first navigation redesign and Deep
  Emerald + Warm Ivory brand system — the six captured 2026-08-21 no
  longer reflect the current app (old 4-tab nav, old teal color, and
  `01_settlements.png` is gone — Home is the new lead shot, not a
  Settlements browse list). Status as of 2026-08-23:
  1. [x] `01_home.png` — **new**, replaces the old settlements-list hero.
     "Your money." + honest count-based summary + Deadlines/New
     Settlements sections, Deep Emerald throughout.
  2. [x] `02_settlement_detail.png` — refreshed in place. Gold payout
     callout, emerald icons, same eligibility/proof/deadline/provenance
     content as before.
  3. [ ] `03_claim_detail.png` — blocked mid-capture by a simulator
     input-delivery issue unrelated to the app (tap calls stopped
     registering session-wide, not specific to any one button; confirmed
     via 30/30 passing automated tests and this exact flow working
     earlier the same session). Resume once simulator interaction is
     reliable again.
  4. [ ] `04_myclaims.png` → rename `04_claims.png` — needs the same
     started claim as #3, same blocker.
  5. [ ] `05_account_privacy.png` — not blocked, just not yet re-captured
     against the new colors/Profile-as-toolbar-sheet presentation.
  6. [ ] `06_paywall.png` — not blocked, not yet re-captured.
- [ ] **(Optional) App Preview:** 15–20s of starting a claim → adding a
  document → the deep-link handoff to the official portal. Not done.
- **Product-page A/B test (after launch):** hero screenshot order first —
  document-vault-privacy frame vs. claim-list-status frame.

## 4 · Momentum — compound ✅ built / ⏳ post-launch

- [x] **Ask at the happy moment** — `ReviewPrompt.swift` fires
  `requestReview` after a claim's status moves to `paid`, once per app
  version (`UserDefaults`-gated), never at launch. Built and tested.
- [ ] **Reply to every review** — thank the good, fix the bad. Post-launch
  operational task, not code.
- [ ] **Roadmap signal:** if repeated reviews ask for the same thing (e.g.
  more real settlements faster — see `Tools/ingest/` for the multi-source
  engine already built toward this), prioritize it and say so in a reply.
- [ ] Track keyword rank monthly; rotate the weakest hidden keyword each
  update. Post-launch.

## Status
- Discovery: **done**, paste-ready in `METADATA.md`.
- Naming Council: **Approve**, final.
- Conversion: icon **done**, screenshots **done** (real 6.9" captures,
  real data). App Preview video optional, not done.
- Momentum: review-prompt gate **built and tested**; replying + keyword
  tracking remain genuinely post-launch (need the app to actually be live).
