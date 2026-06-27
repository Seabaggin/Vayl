# ContextPhase Redesign — Design Spec · 2026-06-20

Branch: `spec/contextphase-2x3-redesign`

## Goal

Overhaul the OB ContextPhase ("Where are you right now?") for the couples-first pivot:
reframe the solo paths around **why you're exploring alone** (not relationship structure),
give single users a custom greeting, rewrite the couple paths to the OB-voice rule, and
map everything to the emotional register. Collapse the **2×3 matrix (6 sets) → 4 sets**.

## Non-negotiable: OB voice = the individual

Every onboarding screen is completed by **one person** (two-device; each partner onboards
alone). So **all Context copy is first-person "I"** — even in couple mode. A couple-context
card is the user's own statement about their relationship ("I'm excited to explore this with
my partner"), **never "we" / "our" / "you both."** See memory `ob_voice_individual`.

## Structure: 6 sets → 4

Solo and couple each split into **Curious** vs **In it** (exploring + experienced merged —
the experienced cohort treats NM as lower-stakes, "not as big a deal"). Resolver:

```
(.solo,     .curious)                      → soloCurious
(.solo,     .exploring), (.solo,     .experienced)   → soloInIt
(.together, .curious)                      → coupleCurious
(.together, .exploring), (.together, .experienced)   → coupleInIt
```

`NMStage` is still captured at ExperienceLevel and still drives `evaluateOpenerDeckType`;
Context just stops sub-dividing exploring vs experienced.

## The four sets

Each card: title · subtitle · `context` case · register. Solo is single-anchored (last).
Detail copy written during build in the same terse, "I"-voiced register.

### Solo · Curious
| Title | Subtitle | context | register |
|---|---|---|---|
| I'm here to learn | Curious about NM — maybe just that | soloLearning | flexible |
| I don't know how to bring it up | I want to, but the conversation feels hard | soloUndisclosed | anxious |
| I want to gain clarity | Getting clear on what I want, on my own | soloSeekingClarity | flexible |
| **I'm single** *(last → greeting)* | Exploring on my own | single | excited |

### Solo · In it
| Title | Subtitle | context | register |
|---|---|---|---|
| I want to explore more intentionally | On my own terms, more deliberately | soloIntentional | excited |
| I want to expand my knowledge | Going past the basics | soloExpandKnowledge | flexible |
| I'm just checking it out | Seeing what's here, no agenda | soloCheckingOut | flexible |
| **I'm single** *(last → greeting)* | Exploring on my own | single | excited |

### Couple · Curious (new to it, higher-stakes)
| Title | Subtitle | context | register |
|---|---|---|---|
| I'm excited to explore this with my partner | Ready to dive in | coupleExcited | excited |
| I want this, but I'm nervous | Into the idea, finding my footing | coupleNervous | anxious |
| I brought this to my partner | I raised it — they're catching up | coupleInitiator | anxious |
| I'm still figuring out what I want | Open, but not sure yet | coupleFiguringOut | flexible |

### Couple · In it (comfortable, lower-stakes, goal/refinement)
| Title | Subtitle | context | register |
|---|---|---|---|
| I want to go deeper with my partner | Past the basics, into the real thing | coupleGoDeeper | excited |
| I want to get better at the hard parts | The conversations, conflict, repair | coupleGetBetter | flexible |
| Something's shifted — I want to work through it | A change I want to navigate | coupleRecalibrating | anxious |
| I want to keep it fun | Keeping the spark, no heavy agenda | coupleKeepItFun | flexible |

## RelationshipContext + derivedRegister

Replace the 24 situation-based cases with 15 reason-based cases (`single` shared across both
solo sets). `derivedRegister`:

- **anxious:** soloUndisclosed, coupleNervous, coupleInitiator, coupleRecalibrating
- **excited:** single, soloIntentional, coupleExcited, coupleGoDeeper
- **flexible:** soloLearning, soloSeekingClarity, soloExpandKnowledge, soloCheckingOut,
  coupleFiguringOut, coupleGetBetter, coupleKeepItFun

## Single greeting

On confirming the **single** card (either solo set), present a brief greeting before the
normal commit/advance:

> *"Honest moment: Vayl gets the most out of two people right now — more for solo journeys
> is on the way. But you're not locked out. Your Desire Map, a solo deck, and the Learn
> library are yours today."*

Presentation: the OB canvas forbids raw `.sheet`, so host it like `editingCredential` (at
`OnboardingCanvasWrapper`) — a small `.vaylSheet`-style card. Dismiss → proceed to
`concludeContext` / advance as normal. The greeting is informational only; it does not
change routing (single still commits `context: .single`, register `.excited`).

## Blast radius (small — verified)

Nothing branches on the specific `RelationshipContext` value:
- `evaluateOpenerDeckType()` switches on `(NMStage, SituationalRegister)` — **register is the
  behavioral contract**, and it's preserved (still anxious/excited/flexible).
- The dealer exit line uses the register (`contextResponse(for:)`).
- The stored `onboardingData.relationshipContext` rawValue is only **persisted**
  (`OnboardingStore` → `UserProfile.relationshipContext`) — never switched on.

So old persisted rawValues from prior installs are harmless (not behaviorally consumed); no
migration needed.

## What stays

- The carousel browse → tap-confirm → swipe-up-exit mechanics (`VaylCardCarousel` /
  `CarouselPhysics`), the entrance/recede choreography, and `concludeContext`.
- The Confirmation edit sheet (`CredentialEditorSheet.contextEditor`) — it renders
  `ContextOption.options(appMode:stage:)` and stores `option.context.rawValue`; works
  unchanged with the new options.

## What changes

- `ContextOption.swift` — the 4 sets + new copy + resolver + `derivedRegister`.
- `RelationshipContext` (`AppEnums.swift`) — the 15 reason-based cases.
- ContextPhase: the single-greeting hook; remove the old "last card = undecided" dimming
  (`isUndecided`) since the last card is now `single`, a real option.

## Build segments

1. **Data + routing** — `ContextOption` 4 sets, `RelationshipContext` cases,
   `derivedRegister`, resolver. Compile-verify. (No behavior change beyond the options.)
2. **Single greeting** — the sheet + confirm hook. Compile + device-feel.
3. **Polish** — remove `isUndecided` dimming; verify the edit sheet still reads/writes
   correctly with the new cases.
