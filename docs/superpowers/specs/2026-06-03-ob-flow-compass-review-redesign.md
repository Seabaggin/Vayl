# OB Flow — Compass Cut + Corner Deck Review Moment

**Date:** 2026-06-03  
**Branch:** spec/contextphase-2x3-redesign  
**Status:** Approved, ready for implementation planning

---

## 1. What Changes to the Flow

### Drop Compass entirely

`CompassPhase` is removed from the OB sequence. The `NMStage × RelationshipContext` matrix already derives emotional register via `ContextOption.derivedRegister`. Agency and motivation are implicitly communicated by the (ExperienceLevel, Context) pair — collecting them again as a standalone 3-question phase adds user fatigue without meaningful new signal.

**Downstream impact:**
- Any system that currently routes on Compass data routes on `RelationshipContext` + `NMStage` instead.
- `OBPhase.compass` is removed from the phase enum.
- `CompassPhase.swift` is deleted.
- The director's `advance(to: .compass)` call in `ContextPhase.handleExit` is replaced with the new review phase.

**New flow order:**
```
stat → brand → name → gender → modeSelect → experienceLevel → context → curiosity → [REVIEW] → cardReveal → buildingPath → groundRules
```

---

## 2. The Corner Deck Review Moment

### Purpose

A single, scripted review-and-edit moment after Curiosity, before CardReveal. Replaces the former confirmation phase concept. The corner deck earns its physical presence here — it's been accumulating cards the whole flow, and this is its payoff.

### Entry — dealer copy trigger

After Curiosity exits, the director fires a dealer line before any animation begins. The copy is terse and on-brand — the energy of "let's see what we're working with." The line IS the invitation; no button or tap required. After a short beat the fan animation begins.

### Fan animation

The corner deck cards animate out from their pocket position in the corner, expanding to a readable intermediate size as they travel. They land in an **arc spread** on the table surface — center card vertical, outer cards rotated progressively outward, like a held hand of cards. All 6 cards are visible simultaneously with no card fully occluded by another. The travel + expand + settle sequence uses existing `AppAnimation` card physics tokens (`cardSlide`, `cardSettle`, `deckFan`).

### Card faces in the fan

Each card renders its **default face** — no user data mapped onto the face itself. TypewriterCardFace shows the typewriter, SlotMachineCardFace shows the settled reels, ControllerCardFace shows the controller, etc. The symbol is sufficient to identify which phase each card represents; users already associate each face with the moment they went through. The user's answer is revealed in the half-sheet, not on the card face.

Cards in the fan (one per collected phase):
1. Name → TypewriterCardFace
2. Gender/Identity → SlotMachineCardFace  
3. Mode → ControllerCardFace
4. Experience Level → (ExperienceLevel card face)
5. Context → (Context card face)
6. Curiosity → (Curiosity card face)

### Edit interaction — tap → overshoot → sheet

Tapping any card in the arc triggers:

1. **Overshoot:** The card deals off screen in the direction it's leaning — left-rotated cards exit left, right-rotated cards exit right, the center card exits up. It overshoots the screen edge.
2. **Snap back:** The card returns from the same edge and, as it settles back into position, pulls a half-sheet up from the bottom.
3. **Sheet:** Shows a lightweight picker or option list for that field only. No ceremony — just the options. User picks or edits, taps done.
4. **Dismiss:** Sheet dismisses, card re-settles smoothly back into its arc position.

Other cards in the fan remain visible and tappable during the sheet interaction.

### Cascade rule

If the user edits ExperienceLevel, the Context card receives a subtle spectrum-border badge and its label reads "REVISIT." The Context value is **not cleared** — the prior pick is preserved — but the badge signals it may no longer fit. The user can tap the Context card to re-pick via sheet or leave it as-is.

### Exit — confirm

A single swipe-up gesture (consistent with all other OB phase exits) confirms the review. All 6 cards animate back into the corner deck (pocket animation). Flow advances to CardReveal.

---

## 3. Constraints

- No new card face types — all card faces in the fan are existing implementations.
- No user data mapped onto card faces. Card faces render their default symbolic state only.
- The fan is exclusively app-driven (scripted entry). Users cannot open the corner deck fan manually at any other point in OB.
- The corner deck remains non-interactive during all active phases.
- `tableFade` and phase transitions remain owned exclusively by `VaylDirector`.
- All animations use `AppAnimation` tokens — no raw duration values.
- All colors use `AppColors` tokens — no raw colors.
- `director.advance()` is the only mechanism for phase transitions.

---

## 4. Out of Scope

- Changes to any active phase (Name, Gender, Mode, ExperienceLevel, Context, Curiosity) — those are untouched.
- Post-OB profile editing — a separate surface handles edits after onboarding completes.
- The specific dealer copy line — copy is finalized during implementation.
- Arc geometry specifics (rotation angles, card spacing) — determined during the feel-verification step on device.
