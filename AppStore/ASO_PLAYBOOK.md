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

## 3 · Conversion — win the tap ✅ (icon + screenshots done, 2026-08-21)

- [x] **App icon** — shield + checkmark mark, teal-to-navy gradient,
  generated programmatically (`Tools/make_icon.py`), legible at
  home-screen size. Not a placeholder — real artwork, confirmed via
  Xcode's own iPad icon auto-generation from the single 1024 source.
- [x] **Screenshots (6.9", 1320×2868 — verified exact, not eyeballed):**
  six real captures in `AppStore/Screenshots/6.9-inch/`, real UI with real
  data (the actual Comcast settlement, not sample content), no abstract
  art:
  1. `01_settlements.png` — Open Settlements hero
  2. `02_settlement_detail.png` — eligibility/proof/deadline + source
     provenance line ("per official settlement website, Aug 20 2026")
  3. `03_claim_detail.png` — status picker, payout tracking, notes,
     document vault (locked on Free), live deep-link to the real Kroll
     portal
  4. `04_myclaims.png` — claim list with the live status badge
  5. `05_account_privacy.png` — the privacy pledge as the trust beat
  6. `06_paywall.png` — the Free-vs-Plus comparison table
  Deviates from the originally suggested order (privacy pledge was
  planned as frame 3) because capturing in actual navigation order,
  through the real app, was more honest than staging a specific sequence.
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
