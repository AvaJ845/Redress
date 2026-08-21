# Redress — ASO Playbook

Applying the $50K ASO Playbook's three-part engine to Redress (renamed from
"Recoup," itself renamed from an initial "Owed" naming collision — see
project memory for the history). As an unknown solo publisher, the whole game
is **rank for terms people actually type**, then **convert the tap**, then
**compound with reviews**.

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
- **Keywords (≤100):** `money,refund,payout,compensation,lawsuit,consumer,eligibility,receipt,encrypted,class,action,docket` (**99/100, verified with `len()`, not eyeballed**)
- **Combinations harvested:** `settlement tracker`, `private claim`,
  `consumer refund`, `lawsuit payout`, `claim deadline alerts`, `class action`,
  `court docket`.
- **2026-08-20 audit correction:** an earlier pass of this file claimed the
  keywords field was at 91/100 and that `class action` had been "folded into
  the keyword field." Both were wrong — actual length was 79/100, and
  `class`/`action` were never added anywhere (Name, Subtitle, or Keywords).
  That's the single highest-intent phrase in this whole category; leaving it
  out entirely, not just out of the Name, was a real findability defect, not
  a cosmetic one. Fixed above.
- **Deliberately excluded:**
  - `file` / `filing` — the app never files on your behalf, only deep-links
    to the official administrator portal. Claiming otherwise would
    misrepresent the product the way Payout's growth copy does.
  - `guarantee` / `guaranteed money` — a live competitor (Settlemate) is
    currently facing false-advertising complaints over exactly this kind of
    promise. Don't invite the same scrutiny.
  - `class action` as a head-on Name phrase — folded into the keyword field
    instead of spent in the scarce 30-char Name slot.

## 2 · The Naming Council — final verdict

| Fellow | Lean | Key finding |
|---|---|---|
| **Discoverability** | Approve *(corrected)* | Name leads with `Settlement Tracker`, not the brand. Subtitle repeats zero Name words. Keywords field repeats nothing from Name/Subtitle, now genuinely at 99/100 after fixing a miscounted/missing-`class action` error (see audit note above). Leaning the Name into the untouched privacy angle rather than the saturated `class action`/`claim` fight is still the correct Indie-Battlefield call for the scarce 30-char slot — but that term now lives in Keywords instead of being dropped outright. **Caveat: "Popularity" here is inferred from competitor density (real, searched), not from actual Apple Search Ads / third-party keyword-volume data** — no such tool was queried. Treat the Indie-Battlefield placement as a reasoned bet, not a measured fact, until real search-volume data is checked post-launch. |
| **Collision** | Approve | `Recoup` was a **hard reject** — live App Store app "Recoup: Refund Wasted Expenses" ([id1569903003](https://apps.apple.com/jm/app/recoup-refund-wasted-expenses/id1569903003)) from a developer account literally named "Recoup" ([id1476990545](https://apps.apple.com/kg/developer/recoup/id1476990545)), doing near-identical work. `Claimly` was also a **hard reject** — multiple live class-action apps already use it exactly (`Claimly: Class Actions` [id6755642219](https://apps.apple.com/us/app/claimly-class-actions/id6755642219), `Claimly: Easy Claim Settlement` [id6755294155](https://apps.apple.com/us/app/claimly-easy-claim-settlement/id6755294155)). `Redress` is clear of exact matches — nearest neighbors are `ReDress: AI Virtual Try-On` (fashion, unrelated), a sustainability `Redress App` (unrelated), and `Redress Pro` (identity-theft/personal-crisis recovery — thematically adjacent "made whole after harm," but a different vertical and no name overlap with our full Name `Settlement Tracker - Redress`). Worth a periodic re-check as Redress Pro grows, nothing more. |
| **Portfolio** | **Approve** *(status change — see below)* | An earlier pass of this council rejected shipping this app at all, because AvaResearchLLC's other app, **Owed**, targeted the exact same category and the same keywords, including "owed" itself. **The user has since confirmed Owed is not shipping** — it's retired/reference-only. That removes the self-competition problem entirely. No other portfolio app (Top Pup, Decoder/Chunk Racer, Hummingbird, Kestrel) competes for this keyword space. Reference file `portfolio-namespaces.md` updated accordingly. |

**VERDICT: Approve.** `Settlement Tracker - Redress` clears all three Fellows.
The bundle ID, project folder, and all in-app strings have been renamed from
Recoup → Redress (`AvaResearchLLC.Redress`) and the project rebuilds clean.

## 3 · Conversion — win the tap ⏳ (icon + screenshots pending)

- [ ] **App icon** — needs a real mark; current build ships with an empty
  placeholder `AppIcon.appiconset` (compiles, but has no artwork).
- [ ] **Screenshots (6.9"):** lead with the payoff, one idea per frame, real
  captured UI, not abstract art (source deck's own A/B evidence: authentic
  beats abstract). Suggested order: claim list with live status badges →
  document vault ("stays on your device") detail → deadline-reminder detail
  → the privacy pledge as a trust beat (mirroring Kestrel's "not a forecast"
  pledge — Redress's version: "we never see your documents").
- [ ] **(Optional) App Preview:** 15–20s of starting a claim → adding a
  document → the deep-link handoff to the official portal.
- **Product-page A/B test (after launch):** hero screenshot order first —
  document-vault-privacy frame vs. claim-list-status frame.

## 4 · Momentum — compound ⏳ (post-launch)

- [ ] **Ask at the happy moment** — fire `requestReview` after a claim's
  status is manually moved to `paid`, once per app version. Never at launch
  or right after adding a document (that's mid-task, not a win).
- [ ] **Reply to every review** — thank the good, fix the bad.
- [ ] **Roadmap signal:** if repeated reviews ask for the same thing (e.g. a
  real settlement-discovery feed instead of manual/seed entries — see
  Owed's `feedctl` as prior art if that's ever revisited), build it and say
  so in a reply.
- [ ] Track keyword rank monthly; rotate the weakest hidden keyword each
  update.

## Status
- Discovery: **done**, paste-ready in `METADATA.md`.
- Naming Council: **Approve**, final.
- Conversion: icon + screenshots **pending** (need real UI captures on a
  6.9" sim).
- Momentum: review-prompt gate **not wired yet**; replying + keyword
  tracking are post-launch operations.
