# Narrative Alignment Design
**Date:** 2026-05-28
**Approach:** B — Three anchor points

---

## Problem

"Vayl" and the card table OB are two strong ideas that haven't been explicitly connected. The name evokes a veil — something between two people that gets lifted. The OB is a dealer ritual — a table, cards, ceremony. They share the same root idea but the product doesn't yet make that connection felt.

The gap isn't in the name or the OB mechanic. It's in the copy threading between them.

---

## Approach

Three anchor points, spaced across the OB flow, each carrying a different register of the same idea. Everything between them stays untouched.

```
StatPhase       "You're not alone. And this isn't new."      [context — unchanged]
NamePhase       "Consider this your invitation."             [plant]
...phases...
FoilPhase       "It's been waiting."                         [enacted]
FounderLetter   [user-authored payoff]                       [payoff — pending]
```

### Three Registers

**Plant** — the dealer establishes, without stating, that this table exists for a reason. The user doesn't notice the idea yet; they're entering. The seed is in a single word swap, not a rewrite.

**Enacted** — the user performs the metaphor with their hands. They tear through a surface. The copy doesn't explain this — it gives the action weight. The user feels something real happened without knowing why.

**Payoff** — the founder letter names it. Everything the user just did is reframed. The word "Vayl" appears once, written by the founder, as the name of the thing that just happened. This is where the game and the name shake hands. *(User-authored — out of scope for this spec.)*

---

## Dealer Voice Principles

The dealer's register is **slightly knowing** — lines carry weight beneath their face value without performing depth. The dealer never explains the ritual. They conduct it.

Rules that follow from this:
- Surface and depth imagery is permitted; the veil metaphor is not named until the founder letter
- The word "Vayl" does not appear anywhere in the OB canvas copy
- Lines should feel like something the dealer has said before — not crafted, just true
- Silence after a physical action (FoilPhase tear) is valid copy

---

## Anchor 1 — NamePhase

**Location:** `NamePhase.swift` → `runDealerIntro()` → Line 3

**Change:** One word swap. Lines 1 and 2 are untouched.

| | Copy |
|---|---|
| Line 1 | `"The things worth learning about yourself..."` *(unchanged)* |
| Line 2 | `"they rarely surface on their own."` *(unchanged)* |
| Line 3 — before | `"Consider this your introduction."` |
| Line 3 — after | `"Consider this your invitation."` |

**Rationale:** "Introduction" says we're meeting. "Invitation" says the table is somewhere worth entering — the user was specifically asked here, not just routed. Same sentence shape, same dealer cadence, richer implication. The user won't read it as metaphor. It just lands slightly differently.

**Internal logic:** "Invitation" → "Welcome to the table" (Beat 3 greeting) now has a quiet referent. The user was invited; they've arrived.

---

## Anchor 2 — FoilPhase

**Location:** `VaylDirector.swift` → `runBuildDeckEntry()`

**Change:** Add one projected dealer line on phase entry. No post-tear copy — the animation does the work and the silence before FounderLetter is intentional.

| Moment | Copy |
|---|---|
| Phase opens | `"It's been waiting."` |
| After tear dissolves | *(silence)* |

**Rationale:** The user is about to physically tear through a surface to reveal their deck. "It's been waiting." shifts agency to what's underneath — the deck has been there all along, waiting to be uncovered. The physical act of tearing becomes the emotional act of lifting. This is the veil metaphor enacted without naming it.

**Parallel:** "they rarely surface on their own" (NamePhase) → things don't come up by themselves. "It's been waiting." → it has been there the whole time, waiting for this moment. The two lines form a quiet internal logic across the full OB arc.

**Implementation note:** Call `director.showDealerLine("It's been waiting.")` in `runBuildDeckEntry()`, after resetting `foilIntegrity` and `foilTears`. The existing `hideAfter` default (4.0s) should be sufficient — the user will begin tapping within that window.

---

## Anchor 3 — FounderLetterPhase

**Status: Pending — user-authored.**

The word "Vayl" appears here and only here. The founder letter is where the name and the ritual shake hands.

**Concept to include:** The letter should use the word "Vayl" not as the name of an app but as the name of a state — the name of what just happened. Door imagery fits: the OB built the door, the cards were the key, the letter is the moment the user looks back and understands the shape of what they walked through.

---

## What Does Not Change

All other dealer lines are intentionally left as-is:

- `"Let's get acquainted."` — NamePhase Beat 2
- `"Welcome to the table, [Name]"` — NamePhase Beat 3
- `"May I have that back?"` — NamePhase card return
- `"Let's find your place at the table."` — GenderPhase
- `"Tell me where you're at."` — ContextPhase entry
- `"Sweep away what you aren't ready for."` — CuriosityPhase entry

These are functional and consistent with the dealer's register. The three anchor points do the narrative work. Everything between them stays clean.

---

## Success Criteria

- A user who completes the OB and reads the founder letter should feel, in retrospect, that the whole experience was always building toward one idea — without being able to point to where they were told that
- No single line outside the founder letter reads as metaphor on first contact
- The dealer's voice is identical in register before and after the changes
- The word "Vayl" does not appear in any OB canvas copy prior to the founder letter
