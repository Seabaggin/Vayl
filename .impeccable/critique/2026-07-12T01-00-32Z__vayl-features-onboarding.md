---
target: Onboarding
total_score: 29
p0_count: 1
p1_count: 1
timestamp: 2026-07-12T01-00-32Z
slug: vayl-features-onboarding
---
Method: dual-agent (A: general-purpose design review · B: Explore native evidence sweep). Native SwiftUI target — web detector (detect.mjs over HTML/CSS) and browser-overlay injection are N/A; a source-level deterministic sweep substituted. No simulator driven (opt-in only, not requested).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Corner-deck "X/6" is a strong local signal, but no global "step N of ~11" — user never knows how long OB runs. |
| 2 | Match System / Real World | 4 | Dealer/table/card metaphor is coherent and sustained ("deal you in," "welcome to the table"). |
| 3 | User Control and Freedom | 1 | No back, no skip, no exit/off-ramp anywhere. Only correction is the final Confirmation edit sheet. |
| 4 | Consistency and Standards | 3 | tap-lift → swipe-up grammar rigorously unified via LiftHalo; Confirmation reverses to swipe-RIGHT at the highest-stakes commit. |
| 5 | Error Prevention | 3 | Auto-selected defaults + commit thresholds + confirm-tug; undercut by irreversible commits with no back. |
| 6 | Recognition Rather Than Recall | 4 | Cards show content; lift reveals label; Confirmation reviews all 6 credentials before commit. Exemplary. |
| 7 | Flexibility and Efficiency | 1 | No fast path. Every phase gates interaction behind a typed dealer line + read beat. Reduce Motion is the only accelerant. |
| 8 | Aesthetic and Minimalist Design | 4 | Restrained, dark, one focus per screen. |
| 9 | Error Recovery | 3 | Final-save failure surfaces "pull down to retry" and loses nothing; empty name/noun paths less guarded. |
| 10 | Help and Documentation | 3 | Gesture teaching IS the documentation (dealer lesson + decaying hint tugs). Effective. |
| **Total** | | **29/40** | **Good — solid foundation, dragged down by one root cause (locked corridor) across #3 and #7.** |

## Anti-Patterns Verdict

**Does this look AI-generated? No — the opposite.** This is top-percentile, genuinely-authored craft: a bespoke SpriteKit card-flight engine, live finger-tracking (HandBackFollow), rubber-band physics on the gender drums, a damped-oscillation shake with directional recoil in BuildDeck, holographic stat text with a one-time arrival ignition, a per-phase dealer voice with typed cadence. Comments read like a designer who tuned on device ("FEEL-GATE," "at 0.55 the oscillation read as dead air in the recording"). The real risk is the inverse of slop: **over-craft** — BuildDeck alone is ~800 lines and 25–35s of largely non-interactive theatre.

**Deterministic scan (native evidence sweep):** The token/contract discipline is remarkably clean. 9 of 12 contract categories are clean in shipping code, and the `VaylCardFace` `.drawingGroup()` contract is satisfied. Confirmed shipping violations are narrow: 3 raw color literals (`SingleGreetingSheet.swift:17` black scrim; `DemoPhase.swift:142,171` Canvas whites) and 21 copy-voice hits. The `OnboardingCanvasView` `#Preview` dev-menu (lines ~317–415) is swiftlint-acknowledged debug scaffolding and correctly excluded. No iOS-26 banned APIs, no raw presentation primitives, no ungated ambient loops, no colorScheme branches, no hardcoded hardware padding, no sub-44 tap targets.

**Where A and B agree loudest:** copy voice. Both independently flagged (a) em dashes in user-visible copy despite the locked no-em-dash rule and (b) "we/our" in ModeSelect despite the explicit "never we" OB voice contract. This is the highest-confidence, lowest-effort fix in the report.

## Overall Impression

This is a beautiful, deeply-crafted onboarding that mostly honors its own product principles — and then breaks the one that matters most for its user. The persona is defined as "bolts under pressure," yet the flow is a locked 11-phase corridor with no back, no skip, and no off-ramp, and nothing persists until the very end, so the only exit is a force-quit that erases everything. The single biggest opportunity isn't more polish; it's giving the hesitant user a visible, dignified door.

## What's Working

1. **Gesture pedagogy is a real system, not a tooltip.** `LiftHalo` is one shared affordance taught once and reused by sight; the swipe-up hint tug decays in frequency (ModeSelect frequent → ExperienceLevel `restMs: 6000`) to mirror growing familiarity. Genuine instructional design.
2. **"Discovery, not verdict" is structurally honored.** ContextPhase cards are first-person "I…" statements the user selects; CuriosityPhase distributes the user's own yes/no answers; no phase concludes an unstated trait. (One watch item: DemoPhase's verb×noun → EmotionalRegister infers a hidden register — invisible to the user today, but it sits closest to the assessment bright line.)
3. **Correction-before-commit.** ConfirmationPhase re-deals all six credentials as editable cards before the final seal — the one real safety net in an otherwise one-way flow.

## Priority Issues

**[P0] No off-ramp / no back / no skip anywhere.** *(User control + a direct product-principle breach)*
Grep-confirmed: zero skip/back/exit affordances across all phases. CLAUDE.md's own principle: "keep an honest off-ramp — 'not now' is respected… this persona bolts under pressure." Nothing persists until `finishOnboarding`, so a force-quit erases progress. For "the hesitant," a corridor with no visible door is the exact pressure that makes her bolt.
**Fix:** add a low-key always-available "not now / maybe later" dismiss, and per-phase back so a wrong Mode/Gender/Experience pick isn't stuck until the end. Persist incrementally so leaving isn't destructive.
**Command:** `/impeccable onboard`

**[P1] Copy voice violates two locked rules.** *(Voice — cross-confirmed by both assessments)*
- Em dashes in user-visible copy (19 confirmed): `Models/ContextOption.swift` (13 strings: lines 70,71,80,87,90,93,96,108,109,122,124,125,128), `FounderLetterPhase.swift:113`, `SingleGreetingSheet.swift:36,42`, `ConfirmationPhase.swift:82,228`, `ModeSelectPhase.swift:399`.
- "we/our" in OB copy (2): `ModeSelectPhase.swift:106` ("We're both here"), `:400` ("We're doing this together") — contradicts the documented "never we" voice.
- Dealer breaks its own contract: `ExperienceLevelPhase.swift:250` "Let's see where you're starting" (DealerDictionary forbids "We/Let's").
**Fix:** replace em dashes with commas/periods/colons; rewrite the "we"/"Let's" lines to first/second-person singular.
**Command:** `/impeccable clarify`

**[P2] The mode decision lacks reassurance and soft-defaults toward the harder path.** *(Emotional / persona)*
ModeSelect is THE high-stakes moment for this persona (the partner step), yet it carries no reassurance copy — unlike ContextPhase ("No judgment on any answer"). Worse, it auto-lifts the "together" card as the default, i.e. the app pre-selects the harder path for a user defined as bolting under pressure. Is defaulting still "guide by clarifying, not prompting," or is the default itself the prompt?
**Fix:** add a reassurance beat in ContextPhase's register; make "Just me for now" the neutral resting state so choosing the partner path is unmistakably the user's own reach.
**Command:** `/impeccable clarify` (copy) + design decision on the default.

**[P3] BuildDeck ceremony is long and unskippable.** *(Pacing / robustness)*
~25–35s of largely non-interactive theatre as the penultimate beat, built from many hand-tuned `Task.sleep` chains. Beautiful once; punishing for a distracted or repeat user (Casey stares at theatre she can't fast-forward).
**Fix:** offer tap-to-advance/skip on the reveal beats (6a–6e); first run stays cinematic, subsequent patience isn't assumed.
**Command:** `/impeccable animate` (add skip affordance / interruptibility)

## Persona Red Flags

**Jordan (confused first-timer):** ModeSelect cards are deliberately text-free (solo vs dual controller illustration is the only signifier) and the dealer line auto-hides on first tap — the single riskiest comprehension point in the flow. GenderPhase asks him to parse two simultaneous drums + a decline bar + a card-lift at once.

**Casey (distracted, one-handed mobile):** The "wait for the dealer to finish typing before you can act" gates are silent — she taps a dead card mid-glance and thinks it's broken. BuildDeck's ~30s unskippable 3-tap release punishes any interruption. Confirmation's swipe-RIGHT reversal re-teaches a gesture exactly when she's least attentive.

**"The hesitant" (project persona — bolts under pressure / anything test-like):** P0 is her killer — no door out of the corridor. ModeSelect defaulting to "together" reads as a nudge toward the partner step. ExperienceLevelPhase ("How much have you explored?") with graded candle tiers, plus verdict-adjacent exit lines ("You've played a few hands," "You know this game well"), can read as a test being graded — the closest the OB comes to the assessment bright line. SingleGreetingSheet's "Vayl gets the most out of two people right now" is a soft "you're second-class" at a vulnerable moment for a solo-leaning user.

## Minor Observations

- 3 raw color literals should become tokens: `SingleGreetingSheet.swift:17` (scrim), `DemoPhase.swift:142,171` (Canvas whites).
- `StatPhase.swift:513-520` has a dead `#Preview("Light")` for a dark-only V1 view — harmless, prune when convenient.
- No global progress indicator (heuristic #1): consider a subtle overall-position cue so the user can gauge remaining length.

## Questions to Consider

1. If the hesitant user's defining trait is bolting under pressure, why is the first interaction a door that only opens forward? What would OB look like if "not now" were a first-class, progress-saving outcome instead of a destructive force-quit?
2. ModeSelect auto-lifts "together." Is guiding-by-defaulting still "guide by clarifying, not prompting," or is the default the prompt? Would the eventual "yes" be more durable if solo were the resting state?
3. The dealer never stops talking, and you can't act until he's done. Is the enforced-typing pacing serving the slow/breathing/gravitational feel, or has it become the app talking *at* the user?
