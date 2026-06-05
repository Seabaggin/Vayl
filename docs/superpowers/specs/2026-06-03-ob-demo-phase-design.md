# OB Demo Phase — "What Vayl Is For"

**Date:** 2026-06-03
**Status:** Design (copy + feel need an on-device pass before Swift, per Build Protocol)
**Parent:** `docs/superpowers/specs/2026-06-03-v1-ob-solo-couple-strategic-model.md`

---

## Purpose

The proof-before-ask moment. **Position 2 in OB** (`stat → demo → name → …`), before any
disclosure. Headspace logic: don't *explain* the product — make them *feel* it land in
one beat. The demo earns every disclosure that follows by proving Vayl can put something
real in front of them before they've told it anything.

**Why this design wins** (after rejecting an animated scene as slop-risk + budget sink):
- Shows the **real artifact** — an actual glowing Vayl card — not a mockup or cartoon.
- **Punches** by making them imagine the vulnerable act (asking their partner a real
  question), which is the exact feeling the solo "get ready to bring it up" loop later
  resolves — the demo and the on-ramp **rhyme**.
- **Nothing is recorded.** Like Headspace's breath, the meta-question is a *feeling*, not
  a data grab. This is what keeps it pure as proof-before-ask.
- Built **entirely from existing mechanics — zero new art or animation.**

---

## Beat Sheet

Working copy below — wording is close; **rhythm refines on device.** The **card question
is LOCKED.**

1. **Dealer, quiet** *(ProjectedTextView)*: *"Forget the setup for a second."*
2. **Dealer:** *"This is what Vayl is for."* → **WHAM** — a card deals, floats, glows,
   holds center. *(existing card-deal physics + foil/holographic + glow.)*
3. **The card (LOCKED):** **"What do you want that you've never said out loud?"**
   — partner-directed, universal across experience levels, the most on-mission framing
   (unspoken desire is the exact thing Vayl exists to surface).
4. **Beat of silence.** Then dealer, low: *"Now picture asking them that."* … *"Feel it?"*
5. **Pivot:** *"That feeling is the whole reason we're here. Let's build a deck that's
   yours."* → the card **pockets to the corner deck** (first time the user sees it).

**Optional enhancement (decide in the feel-prototype):** a warm-hold on the card before
the pivot — press → warms → haptic → releases — a physical acknowledgment of being present
with something real. Include only if it deepens the beat without slowing it.

---

## Buildable from existing mechanics (no new art)

| Beat element | Existing mechanism |
|---|---|
| Dealer copy | `ProjectedTextView` |
| Card deal / float / settle | card physics + `AppAnimation` (`cardSlide`/`cardSettle`) / `CardFlightScene` |
| Beautiful / glowing card | `VaylCardRenderer`, `HolographicShimmer.metal`, `AppGlows` |
| Warm-hold (optional) | `sensoryFeedback(.impact)` + press state |
| Pocket to corner deck | existing card-pocket animation + `CornerDeckView` |

Implementation hooks (conceptual — defer to OB-sequence spec): a `demo` case on the OB
phase enum; entry/exit driven by `VaylDirector` (`director.advance()` only); `tableFade`
owned by the director.

---

## Constraints

- **No new art, no animated characters, no illustrated scene** — that was the slop risk
  we explicitly rejected. The punch is words + timing + the card, nothing more.
- **The card question is universal** — the demo runs before any user data exists, so it is
  not personalized (and must not be).
- **Nothing recorded** — no data written from this phase.
- All design tokens per `CLAUDE.md` (no raw colors / fonts / spacing / animation values).
- **Feel before Swift:** a React feel-prototype proves the rise timing, the silence beats,
  the (optional) warm-hold, and the pivot before any Swift is written. Build Protocol:
  "feel is correct" is done, not "build succeeds."

---

## Open items

- Final dealer-copy rhythm (on-device pass).
- Whether to include the warm-hold (feel-prototype decides).
- The card's specific visual treatment at "WHAM" (glow intensity, float arc) — feel-tuned.

## Out of scope

- Any scene / animation / depicted couple.
- Data collection or personalization of the demo card.
- Branching or choices (that's the Vayl 2.0 exploration engine).
