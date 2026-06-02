# ContextPhase — 2×3 Redesign + Detail Panel + Visual Accents

**Date:** 2026-06-01
**Phase:** OB `context` (after `experienceLevel`, before `compass`)
**File of record:** `Features/Onboarding/Phases/ContextPhase.swift` (+ new model, card-face change)

---

## 1. Overview

The ContextPhase is rebuilt around the intersection of two axes already collected
earlier in onboarding:

- **Mode** — `AppMode` (`.together` / `.solo`; `.browsing` falls back to solo)
- **Experience level** — `NMStage` (`.curious` / `.exploring` / `.experienced`)

This produces a **2×3 matrix of 6 cells**. Each cell contains **4 cards** — three
concrete situations plus one first-class **"undecided"** card.

Two UX changes ship alongside the matrix:

1. **Text comes off the card.** Cards become punchy headlines (number + title only).
   Subtitle + detail move to a dynamic bottom panel.
2. **Hybrid detail panel** — subtitle updates live as the user swipes; the full
   detail paragraph reveals only after a card is confirmed.

Plus five visual accents to activate the screen (Section 7).

---

## 2. Locked Decisions

| Decision | Choice |
|---|---|
| Card content | Number + title on the card; subtitle/detail in bottom panel |
| Detail panel | **Hybrid** — subtitle live on swipe; detail reveals on confirm |
| Card on confirm | **Stays the same size** (ring/glow signals selection) |
| `SituationalRegister` | **Derived** from the chosen context (mapping in §4); `concludeContext` signature unchanged |
| `RelationshipContext` | Grows **7 → 24 cases** |
| Browsing mode | Falls back to the **solo** option set (resolver stays total) |
| Progress line | Reuse existing `OnboardingProgressBar` |

---

## 3. Data Layer (Model)

New file: `Features/Onboarding/Models/ContextOption.swift` — pure Model, no
dependencies. The 24 options are content and must not live privately inside the View.

```swift
struct ContextOption: Identifiable {
    let id: String
    let context: RelationshipContext   // routing — 1 of 24; ALL downstream branches here
    let accent: CardAccent             // decorative only — NEVER branch on it
    let title: String                  // shown ON the card
    let subtitle: String               // bottom panel — live on swipe
    let detail: String                 // bottom panel — revealed on confirm
    var derivedRegister: SituationalRegister { /* per table in §4 */ }
}

enum CardAccent { case ember, spark, flame, inferno, nova }   // purely aesthetic

extension ContextOption {
    /// Total resolver. `.browsing` maps to the solo set.
    static func options(appMode: AppMode, stage: NMStage) -> [ContextOption]
}
```

**`RelationshipContext` — replace the 7 current cases with 24.** Verified: only
`ContextPhase.swift` references the old case names. `UserProfile`, `OnboardingData`,
`OnboardingStore`, and `VaylDirector` all store/pass the value as a `String?` rawValue
and never switch on it — so this migration breaks nothing outside the rewritten file.

```swift
enum RelationshipContext: String, Codable {
    // Solo × Curious
    case singleCurious, partneredSupportiveCurious, partneredUndisclosed, soloCuriousUndecided
    // Solo × Exploring
    case singleExploring, partneredHandsOff, multipleUndefined, soloExploringUndecided
    // Solo × Experienced
    case singleExperienced, partneredAware, soloPolyIndependent, soloExperiencedUndecided
    // Couple × Curious
    case coupleSymmetricCurious, coupleAsymmetricCurious, coupleStalledConversation, coupleCuriousUndecided
    // Couple × Exploring
    case coupleSolidifying, coupleReorienting, coupleParallelExploring, coupleExploringUndecided
    // Couple × Experienced
    case coupleFreshIntentional, coupleSkillBuilding, coupleEvolving, coupleExperiencedUndecided
}
```

**CardAccent assignment (decorative).** Per cell: position 1 → `spark`, 2 → `flame`,
3 → `inferno`, 4 (undecided) → `ember` (softest — the "landing place"). No semantic
meaning; do not branch on it anywhere.

---

## 4. Derived SituationalRegister Mapping

`SituationalRegister` stays alive as a **derived** value so the existing downstream
contract holds: `VaylDirector` responsive exit line, deck-category weighting, and the
Compass "heavy context" check (`situationalRegister == .anxious`) all keep working.
Undecided cards → `.flexible` (matches the spec's "lowest-stakes, most generative" rule).

| Context | Register |
|---|---|
| singleCurious | flexible |
| partneredSupportiveCurious | flexible |
| partneredUndisclosed | **anxious** |
| soloCuriousUndecided | flexible |
| singleExploring | **excited** |
| partneredHandsOff | flexible |
| multipleUndefined | flexible |
| soloExploringUndecided | flexible |
| singleExperienced | **excited** |
| partneredAware | flexible |
| soloPolyIndependent | **excited** |
| soloExperiencedUndecided | flexible |
| coupleSymmetricCurious | flexible |
| coupleAsymmetricCurious | **anxious** |
| coupleStalledConversation | **anxious** |
| coupleCuriousUndecided | flexible |
| coupleSolidifying | **excited** |
| coupleReorienting | **anxious** |
| coupleParallelExploring | flexible |
| coupleExploringUndecided | flexible |
| coupleFreshIntentional | **excited** |
| coupleSkillBuilding | **excited** |
| coupleEvolving | **anxious** |
| coupleExperiencedUndecided | flexible |

---

## 5. Card Face (simplify)

- `VaylCardContent.context` case → signature shrinks to `.context(number:title:)`
  (drop `subtitle` / `detail`). This is a content-case change, not a shell change.
- `ContextCardFace` renders **number + title only** — title larger, vertically
  centered, so the card reads as a headline. Removes the subtitle/detail blocks and
  their `isFront`-gated reveal (that responsibility moves to the phase's bottom panel).
- All geometry remains proportional to card width (OB card-face rule). Spectrum stroke
  language unchanged.

---

## 6. Phase Layout & Interaction

Top → bottom inside `ContextPhase`:

1. **Spectrum progress line** — `OnboardingProgressBar(currentStep: physics.currentIndex + 1,
   totalSteps: options.count)`, sized small (custom `totalWidth`/`barHeight`), centered
   above the carousel. Fills the top void and grounds position. (See also §7.2.)
2. **Carousel** — `VaylCardCarousel`, cards as headlines. Card **stays the same size**
   on confirm; selection signaled by the existing spectrum ring/glow.
3. **Bottom detail panel** (hybrid):
   - **Subtitle** — keyed to `physics.currentIndex`, crossfades on each swipe (live).
   - **Detail** — hidden during browse; reveals below the subtitle only when
     `confirmedIndex != nil`.
4. **Reassurance line** — pinned to the bottom edge (existing copy logic).

Haptics: `.sensoryFeedback(.selection, trigger: physics.currentIndex)` for tactile
browse, plus existing `.impact(.light)` on confirm.

**Carried over unchanged** from the current file: entrance choreography (700ms silence
→ headline → felt recede + carousel assemble), swipe-up tug, and the exit timeline.

---

## 7. Visual Accents

All via design tokens — no raw values. Reduce-Motion fallbacks required; looping
animations wrapped in `.ambientAnimation()`.

### 7.1 Live accent glow behind hero card
A soft radial glow behind the front card, tinted by the current card's `CardAccent`,
that **crossfades as the user swipes** (driven by `physics.currentIndex`). This is the
only consumer of `CardAccent` — it makes the otherwise-decorative accent do visual work,
gives each card identity, and activates the negative space during browse. Rendered with
spectrum/`AppGlows` tokens; accent maps to a token tint, not a raw color.

### 7.2 Spectrum progress line
Reuse `OnboardingProgressBar` (already spectrum-gradient with shimmer/bloom). Drives off
`physics.currentIndex`. Replaces a plain `1 / 4` number with a viscerally short,
on-brand progress indicator.

### 7.3 Hairline divider that glows on confirm
A `.hairline()` separator between the card zone and the detail panel that lights up via
`.spectrumBorderGlow` when `confirmedIndex != nil` — visually "activates" the panel at
the exact moment the full detail reveals, reinforcing the hybrid interaction.

### 7.4 Undecided card soft treatment
The 4th (undecided) card uses a dimmed / softened stroke vs. the crisp spectrum stroke
of the other three, so it reads as a resting place rather than a lesser option. Pairs
with its `ember` accent.

### 7.5 Confirm atmosphere pulse
On confirm, a one-shot gentle pulse of the `AtmosphereView` / glow to reward the choice
before the swipe-up. Single fire, not looping.

*(Not included: neighbor-card peek.)*

---

## 8. Conclude / Downstream (unchanged contract)

On exit, the phase derives the register from the chosen option and calls the **existing**
`director.concludeContext(relationshipContext:situationalRegister:)`:

```swift
director.concludeContext(
    relationshipContext: option.context,
    situationalRegister: option.derivedRegister
)
```

No edits to `VaylDirector`, `OnboardingStore`, `OnboardingData`, or `UserProfile` — the
responsive exit line, deck weighting, and Compass derivation continue to work as-is.

---

## 9. Full Card Content

### Solo × Curious
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| single_curious | singleCurious | I'm single | NM is new territory for me | No relationship to navigate — just you and your curiosity. We'll start with the fundamentals and let you explore at your own pace. |
| partnered_supportive_curious | partneredSupportiveCurious | My partner's on board | They're supportive of me looking into this | You've opened the door — we'll help you figure out what you actually want before the bigger conversations begin. |
| partnered_undisclosed | partneredUndisclosed | I haven't brought it up | I have a partner, but the conversation hasn't happened | You're still figuring out what this means to you. We'll help you get clarity before you decide whether or how to start the conversation. |
| solo_curious_undecided | soloCuriousUndecided | None of these quite fit | My situation doesn't quite fit any of these | That's okay — most people's lives are messier than a list of options. Start here and we'll help you figure out the rest as you go. |

### Solo × Exploring
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| single_exploring | singleExploring | I'm single | Dating and still figuring out who I am in NM | You've moved past curiosity — now it's about building a real sense of your identity, boundaries, and what you want from connections. |
| partnered_hands_off | partneredHandsOff | Partnered, but here on my own | I have a partner — exploring the app on my own | Your partner is on board but this is your journey. We'll focus on your individual growth while keeping the relationship in view. |
| multiple_undefined | multipleUndefined | I have multiple partners | Here to navigate it on my own | You're holding more than one connection and steering it yourself. We'll help you navigate the balance — communication, time, and what you actually want from each. |
| solo_exploring_undecided | soloExploringUndecided | None of these quite fit | My situation is hard to pin down right now | You know you're exploring — you're just not sure which box fits. That's fine. We'll meet you where you are and let the label catch up later. |

### Solo × Experienced
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| single_experienced | singleExperienced | I'm single | Solo, and clear on who I am in NM | You've done the work. This is about staying intentional, continuing to grow, and finding the connections that fit the life you've built. |
| partnered_aware | partneredAware | I have an established partner | We're solid — this is my own space to manage it | Your partner is aware and supportive, but your NM journey is yours to navigate. We'll focus on depth, skill, and continued self-awareness. |
| solo_poly_independent | soloPolyIndependent | I have multiple partners | Solo poly — multiple relationships, no hierarchy | You move through connections on your own terms. We'll support the craft of that — communication, transitions, autonomy, and care without hierarchy. |
| solo_experienced_undecided | soloExperiencedUndecided | None of these quite fit | My structure shifts and none of these fully capture it | Experienced doesn't always mean settled. If your situation is genuinely fluid, start here — we'll build around what's true right now. |

### Couple × Curious
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| couple_symmetric_curious | coupleSymmetricCurious | We're both curious | Neither of us has done this before | You're starting from the same place, which is a real advantage. We'll build shared language and give you both room to think out loud before any decisions get made. |
| couple_asymmetric_curious | coupleAsymmetricCurious | One of us brought this up | The other is open, but still processing | The interest isn't equal yet — and that's okay. We'll help both of you find your footing without pushing anyone faster than they're ready to go. |
| couple_stalled_conversation | coupleStalledConversation | We talked, but it stalled | But the conversation never really went anywhere | Something got in the way — timing, fear, uncertainty. We'll help you pick up the thread and figure out why it stalled before trying again. |
| couple_curious_undecided | coupleCuriousUndecided | None of these quite fit | Our situation is a little bit of all of these | That's more common than you'd think. Start here — you don't need to have it figured out to begin figuring it out together. |

### Couple × Exploring
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| couple_solidifying | coupleSolidifying | We're ready to go deeper | Now we want to go deeper with intention | You've moved past curiosity — now it's about building a shared identity in NM. We'll help you name what's working, what isn't, and where you want to go. |
| couple_reorienting | coupleReorienting | Something has shifted | We're figuring out our footing again | Your dynamic has changed — a new connection, a boundary that isn't working, or just a feeling that things are off. We'll help you recalibrate together. |
| couple_parallel_exploring | coupleParallelExploring | We explore in parallel | Together, but each on our own path | You're a couple but your NM journeys run in parallel. We'll support both your individual growth and the connection that holds it all together. |
| couple_exploring_undecided | coupleExploringUndecided | None of these quite fit | We're somewhere between all of these right now | Exploring rarely looks like one clean thing. If your dynamic is layered or shifting, start here — we'll help you make sense of it as you go. |

### Couple × Experienced
| id | context | title | subtitle | detail |
|---|---|---|---|---|
| couple_fresh_intentional | coupleFreshIntentional | We know what we're doing | We want to stay intentional and keep it alive | Experience doesn't make things automatic. We'll help you stay curious about each other and your dynamic without letting it run on autopilot. |
| couple_skill_building | coupleSkillBuilding | Better at the hard stuff | Communication, conflict, care — the meta-skills | You're good at NM. Now you want to be excellent at the relationship craft underneath it — the conversations, the repairs, the emotional fluency. |
| couple_evolving | coupleEvolving | We're rethinking our structure | Expanding, reorienting, or rebuilding our dynamic | Something about how you've set this up needs to evolve. We'll help you think through what that means and how to move through it without losing what matters. |
| couple_experienced_undecided | coupleExperiencedUndecided | None of these quite fit | We just want to keep growing in whatever way fits | That's a legitimate place to be. You don't need a category — we'll focus on what's useful and let you steer. |

---

## 10. Files Touched

| File | Change |
|---|---|
| `Core/Models/Enums/AppEnums.swift` | `RelationshipContext` 7 → 24 cases |
| `Features/Onboarding/Models/ContextOption.swift` | **NEW** — model, `CardAccent`, resolver, `derivedRegister` |
| `Design/Components/Cards/VaylCardContent.swift` | `.context` case → `(number:title:)` |
| `Design/Components/Cards/CardFaces/ContextCardFace.swift` | render number + title only |
| `Features/Onboarding/Phases/ContextPhase.swift` | layout rewrite: progress line, hybrid panel, accents; remove private `ContextCardData` |

**Must NOT touch:** `VaylDirector` (`concludeContext` reused as-is), `OnboardingStore`,
`OnboardingData`, `UserProfile`, `VaylCardFace` shell, `OnboardingProgressBar`,
`VaylCardCarousel`, `CarouselPhysics`.

---

## 11. Build Segments (per project Build Protocol)

Each segment verified on device ("feel is correct"), not just "build succeeds":

1. **Data model** — `ContextOption` + `CardAccent` + 24-case `RelationshipContext` +
   resolver + `derivedRegister`. Done: all 6 cells resolve; project compiles.
2. **Card face simplification** — `.context(number:title:)`, headline rendering.
   Done: card reads as a punchy headline, no empty text blocks.
3. **Phase layout** — progress line + hybrid bottom panel wired to physics/confirm.
   Done: subtitle updates live on swipe; detail reveals on confirm; tracker fills.
4. **Visual accents** — live accent glow, hairline glow-on-confirm, undecided soft
   stroke, confirm atmosphere pulse. Done: each accent felt-correct on device.
5. **Conclude wiring** — derive register, `concludeContext` reused. Done: full flow
   advances to `.compass` with correct data written.

---

## 12. Open Questions (deferred — not blocking this build)

From the source spec; carried forward for later:

1. Does an undecided context ever prompt re-selection after N sessions, or is it
   permanent until manually updated?
2. Solo `partneredUndisclosed` → after the user has the conversation, is there a context
   migration flow?
3. Couple contexts: one shared account or two linked accounts?
4. Should `soloPolyIndependent` have a secondary clarifying question before routing?
