# OB Sequence — Reconciled Spec

**Date:** 2026-06-04
**Status:** Approved (reconciles `docs/refinedonboarding.md` and `docs/superpowers/specs/2026-06-03-ob-flow-compass-review-redesign.md` against the V1 strategic model)
**Parent:** `docs/superpowers/specs/2026-06-03-v1-ob-solo-couple-strategic-model.md`

---

## Governing Principles

- **Self-only.** Every user — solo or together — collects only their own data. Partner data arrives via pairing when Partner B does their own OB.
- **Stable profile only.** OB collects who they are. Dynamic needs (situation, intent) move to session-start.
- **Short.** Ceremony is reserved for genuine identity disclosures. Factual data is collected fast with no ceremony.
- **Payoff = tear open the personalized starter deck.** The demo opens a promise; the reveal closes it.
- **One gender spin only.** `genderB/pronounsB` are populated via pairing — OB spin 2 is removed.
- **Browsing mode removed.** `AppMode` is `together` or `solo` only.
- **Pronouns** collected in profile settings post-OB, not in the OB flow.

---

## Phase Sequence

```
stat → demo → name → modeSelect → relationalContext → gender → experienceLevel → registerRead → curiosity → cornerDeckReview → starterDeckReveal → founderLetter
```

Then branch post-OB on **(mode × nmStage × hesitancy)**.

---

## Phase-by-Phase

---

### 1. Stat *(unchanged)*

**Mechanic:** existing `StatPhase`
**Job:** Set stakes before asking for anything. The opener is about the problem, not the product.
**Copy:** *"1 in 5 couples say they never talk about what they actually want."*
**Data written:** none
**Corner deck:** empty

---

### 2. Demo *(new — full spec: `2026-06-03-ob-demo-phase-design.md`)*

**Mechanic:** card deal + float + glow + dealer projected text + hold (optional)
**Job:** Proof before ask. Feel one card land before any disclosure.

Beat sheet:
1. Dealer: *"Forget the setup for a second."*
2. Dealer: *"This is what Vayl is for."* → card deals, floats, glows, holds center
3. Card (LOCKED): **"What do you want that you've never said out loud?"**
4. Held silence → dealer: *"Now picture asking them that."* … *"Feel it?"*
5. Pivot: *"That's the whole reason we're here. Let's build a deck that's yours."* → card pockets to corner deck

**Data written:** none
**Corner deck:** 1 card (the demo card pockets — first time user sees it)
**Feel note:** React prototype required before Swift — rise timing, silence beat, pivot pacing

---

### 3. Name *(unchanged)*

**Mechanic:** existing `NamePhase` — typewriter
**Job:** First personal disclosure. Earned by the demo that preceded it.
**Data written:** `displayName`
**Corner deck:** +1 (deck[1])

---

### 4. Mode Select *(updated — browsing removed)*

**Mechanic:** existing `ModeSelectPhase` — mirror deal, two cards (was three)
**Job:** Sets the structural fork for everything downstream.

Options:
- *For me* — solo; conversation with partner hasn't happened yet
- *For us* — together; both partners are in this

**Browsing removed.** `AppMode` enum needs `.browsing` case removed.
**Data written:** `appMode`
**Corner deck:** +1 (deck[2])

---

### 5. Relational Context — Age + Tenure *(new lightweight phase)*

**Mechanic:** two face-up cards dealt back-to-back, no flip ceremony, instant options — same energy as a factual intake, not an identity moment. Fast taps, no drama.

**Card A — Age** *(all modes)*
Four bracket options, one tap, pockets:
- Under 25 / 25–35 / 35–45 / 45+

**Card B — Tenure** *(together mode only — skipped entirely for solo)*
Combined stage + time framing, one tap, pockets:
- *Still figuring each other out* (under 1 year)
- *Finding our shape* (1–3 years)
- *Something's shifted* (3–7 years)
- *We've been through it* (7+ years)

**Solo users never see Card B.** Tenure for solo goes to profile settings post-OB.

**Tenure data ownership:** tenure lives at the couple level, not per-user. Written by whichever partner onboards first; Partner B's OB skips the tenure card (they confirm or see their partner's pick post-pairing). This prevents conflicting values when both partners onboard in together mode.

**Data written:** `ageRange` (new field — add to `UserProfile`), `relationshipTenure` (new field — add to `Couple`, not `UserProfile`)
**Corner deck:** no card added (factual data, no ceremony card)

---

### 6. Gender *(updated — one spin only)*

**Mechanic:** existing `GenderPhase` — slot machine, full ceremony (all 7 segments)
**Job:** Identity and pronouns. A genuine identity disclosure — full ceremony earned.

**Changes from current:**
- One spin only — `genderHandoffCopy` and spin 2 sequence are removed
- Phase is identical for all users — no mode-branching, no extra dealer copy
- `genderB` / `partnerGenderIdentity` / `partnerPronouns` on `UserProfile` are populated via pairing, not this phase

**Data written:** `genderIdentity`
**Corner deck:** +1 (deck[3])

---

### 7. Experience Level *(unchanged)*

**Mechanic:** existing `ExperienceLevelPhase` — Monte deal, shuffle, flip, candle face
**Job:** How familiar are they with this kind of content. Sets `NMStage` — the primary axis for deck depth and opener routing (anticipatory vs. reflective).

**NMStage cases:** `curious` / `exploring` / `experienced`

**Data written:** `nmStage`
**Corner deck:** +1 (deck[4])

**Note:** Gender (7-segment) + ExperienceLevel (Monte + candle) are two elaborate sequences back-to-back. Consider a short dealer beat between them during feel-verification — not a new phase, just breathing room.

---

### 8. Register Read *(upgraded — replaces ContextPhase)*

**Mechanic:** existing `ContextPhase` mechanic (deal face-up, table fades, carousel options, swipe up) — **copy only change**, no new component

**Job:** Direct emotional register read. Replaces the old "pick your relationship archetype" carousel (abstract self-diagnosis) with a direct question. Produces the same `situationalRegister` routing signal via a more honest, lower-friction ask.

**Question:** *"What are you hoping this gives you?"*

Options (map to `EmotionalRegister`):
- *I want to feel safer about this* → `.anxious` (reassurance-first tone)
- *I want to feel more alive* → `.excited` (expansion-first tone)
- *Somewhere in between* → `.flexible` (clarity-first)
- *Honestly, not sure yet* → `.unknown`

**Routing update required:** `evaluateOpenerDeckType()` currently reads `situationalRegister` (from old ContextPhase). Update to read from `emotionalRegister` instead, or update the register read to write to `situationalRegister`. Pick one and be explicit. `relationshipContext` field on `UserProfile` becomes unused — can be deprecated.

**Data written:** `emotionalRegister` (or `situationalRegister` — see routing update note)
**Corner deck:** +1 (deck[5])

---

### 9. Curiosity *(unchanged — trim deferred to feel pass)*

**Mechanic:** existing `CuriosityPhase` — Tinder swipe, two rounds
**Job:** Topic personalization fuel for the starter deck. Without it the deck personalizes only on demographics and experience.

Round 1: *"What keeps coming up for you?"* (present-tense active states)
Round 2: *"What are you curious about?"* (topic areas)

Output: `curiositySelections[]` — read directly by `evaluateOpenerDeckType()`

**Trim decision deferred:** keep both rounds at full card count for now. Revisit during the feel pass on device — if the phase feels like a survey after everything before it, trim round counts then.

**Data written:** `curiositySelections[]`, `openerDeckType` (assigned silently by director at round 2 exit)
**Corner deck:** +1 to complete deck[6]

---

### 10. Corner Deck Review *(from approved spec: `2026-06-03-ob-flow-compass-review-redesign.md`)*

**Mechanic:** 6-card arc fan from corner deck, tap → overshoot → sheet edit → re-settle, swipe up to pocket all back
**Job:** The corner deck's payoff. Shows what was learned; allows light edits before the reveal.

**Transition note:** this flows directly into the Starter Deck Reveal. The two ceremonies should be separated by a clear emotional gear-shift — dealer copy bridges them:

After all 6 cards pocket back → brief beat → dealer: *"[Register-responsive line]. Let's build this."* → foil materializes.

The dealer line is the gear-shift. Example (anxious register): *"Hesitant. Curious. Ready to go somewhere real. Let's build this."*

**Data written:** any edits confirmed here update `OnboardingData` before commit
**Corner deck:** empties back to pocket → foil materializes

---

### 11. Starter Deck Reveal *(upgraded from `buildDeck` + `cardReveal`)*

**Mechanic:** existing foil materialization + dealer copy + tear-to-accept sequence
**Job:** The emotional payoff. A personalized 5-card starter deck selected from real authored cards.

**Selection logic (extend `evaluateOpenerDeckType()`):**
- Keys off `NMStage` + `emotionalRegister` + `curiositySelections` + `genderIdentity`
- **NMStage-keyed opener variant:**
  - `curious` / `exploring` → anticipatory cut (existing "the-opener" cards)
  - `experienced` → reflective swap: keep evergreen relationship cards, replace the ~4 anticipatory NM-primer cards (the-opener 06/07/08/10) with retrospective equivalents (what you've renegotiated, what surprised you, a jealousy moment you navigated)
- **Solo reflection-weighted cut:** skew toward `reflect`-type and "understand yourself" cards — genuinely playable alone, never awkward
- **Same deck seeds the couple opener on pairing** — solo work carries forward

**The promise closes:** the demo asked *"What do you want that you've never said out loud?"* The reveal answers: *"Here are 5 questions that might get you there."*

**Data written:** `onboardingCompletedAt` (set by `OnboardingStore.commit()` on successful write)

---

### 12. Founder Letter *(unchanged)*

**Mechanic:** existing `FounderLetterPhase` — sheet rises, dealer letter, signature writes, swipe down
**Job:** Humanization and trust before vulnerable content. They know who built this and why.

**Together-mode addition:** at the letter's close, a beat surfaces the partner invite:
*"You said this is for your relationship. Let's bring them in."* → invite flow.

This is the specced post-OB together-mode handoff. Solo users swipe down and enter the on-ramp loop instead.

---

## Post-OB Branch

After founder letter, branch on **(mode × nmStage × hesitancy)**:

| Signal | Path |
|---|---|
| `solo` + newer/hesitant | → "Get ready to bring it up" on-ramp loop (`2026-06-03-solo-onramp-conversation-prep-design.md`) |
| `together` | → Partner invite beat (see §12 above) → Desire Map gate |
| `solo` + experienced / no hesitancy | → Standard experience; Desire Map available once paired |
| `experienced` (any mode) | → Standard experience; skip on-ramp |

**Home gate change required:** today home hard-gates behind the Desire Map. Solo users need a reachable pre-pairing surface — their starter deck is playable immediately. The home gate logic needs a solo-reachable state that doesn't depend on pairing.

---

## What Was Cut and Why

| Cut | Reason |
|---|---|
| `CompassPhase` | Three abstract calibration questions cold before any experience. Agency/motivation revealed through behavior, not self-report. Already removed in prior spec. |
| `ContextPhase` (archetype picker) | Replaced by register read — same routing output, less abstract collection mechanism. `relationshipContext` field deprecated. |
| Gender spin 2 | Self-only model. Partner self-provides via pairing. |
| `AppMode.browsing` | Removed from V1 scope. |
| Pronoun collection in OB | Profile settings post-OB. |

---

## Model Changes Required

| Change | Where |
|---|---|
| Add `ageRange` field | `UserProfile` |
| Add `relationshipTenure` field | `Couple` (couple-level, not per-user) |
| Remove `AppMode.browsing` case | `AppEnums` + everywhere it's switched on |
| Update `evaluateOpenerDeckType()` | Read `emotionalRegister` instead of `situationalRegister` |
| Deprecate `relationshipContext` on `UserProfile` | Can be nil'd — keep field for existing profiles |
| Add `OBPhase.demo` and `OBPhase.relationalContext` | `AppOBEnums` |
| Remove `OBPhase.compass` | `AppOBEnums` — already flagged in prior spec |
| Remove gender spin 2 logic from `VaylDirector` | `genderHandoffCopy`, `genderHandoffVisible`, spin 2 sequence |
| Add NMStage-keyed selection to starter deck assembly | Extend `evaluateOpenerDeckType()` |
| Home gate: add solo pre-pairing reachable state | `HomeState` enum + `HomeStore` |

---

## Verification

Per Build Protocol — feel is correct, not build succeeds:

1. **Demo phase:** React prototype for rise timing, silence beat, pivot pacing before Swift
2. **Gender without spin 2:** together-mode users see the new handoff copy and don't wait — verify on device
3. **Age/tenure back-to-back:** fast enough to feel like facts, not a form — verify timing on device
4. **Two elaborate sequences (gender + experienceLevel):** breathing room between them confirmed on device
5. **Corner deck review → starter deck reveal transition:** dealer bridge line lands correctly — feel pass
6. **Starter deck reveal:** personalization feels like *yours* — end-to-end run with multiple profile combinations
7. **Post-OB branch:** together-mode invite prompt and solo on-ramp entry both route correctly
