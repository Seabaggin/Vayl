# Vayl Onboarding — Senior UI/UX Audit
**Auditor Role:** Senior UI/UX Designer + iOS Technical Reviewer
**Scope:** All 13 phases, StatPhase → AppArrival
**Standard:** Vayl Session Rules v2.1 + App Store Compliance

---

## How to Read This Document

Each phase gets:
- **Intent** — what the phase is supposed to do
- **Visual Checks** — design system compliance, motion, surfaces
- **Technical Checks** — architecture, store contract, accessibility
- **Flags** — blockers (🔴), warnings (🟡), questions (🔵)

Severity scale:
| Symbol | Meaning |
|--------|---------|
| 🔴 | Blocker — ships nothing until resolved |
| 🟡 | Warning — degrades experience, must resolve before beta |
| 🔵 | Open question — decision needed before implementation |

---

## Global Checks (Apply to Every Phase)

These violations are not repeated per-phase. Assume they apply everywhere until the design system is confirmed built.

### Visual — Global

| # | Check | Status |
|---|-------|--------|
| G-V1 | Every screen opens with `ZStack { AppColors.void.ignoresSafeArea() }` followed by `AtmosphereView` | 🔵 AtmosphereView not yet confirmed for OB screens |
| G-V2 | Zero raw colors — no `.red`, `Color(hex:)`, or primitive tokens in Views | 🔴 AppColors semantic token file not confirmed built |
| G-V3 | Zero raw fonts — no `.font(.title)` or `Font.system(size:)` bare calls | 🔴 AppFonts token file not confirmed built |
| G-V4 | Zero raw spacing — no `padding(16)` or `Spacer().frame(height:24)` | 🔴 AppSpacing.swift listed as "does not exist" in build state |
| G-V5 | Zero raw radius — all corner radii via `AppRadius` tokens | 🔴 AppRadius token file not confirmed built |
| G-V6 | Every card/surface uses `.glassCard()` + `.hairline(.resting)` or `.hairline(.active)` | 🔵 Confirm felt/table surfaces are excluded by design intent |
| G-V7 | All ambient looping animations wrapped in `.ambientAnimation()` — disables under Reduce Motion | 🔴 FlameAura, LightAuraBloom flagged as 60fps main-thread timers — must be fixed before any OB animation is built on top |
| G-V8 | All animation durations use `AppAnimation.fast`, `.standard`, `.slow` tokens — no raw `.easeInOut(duration: 0.3)` | 🔴 AppAnimation token file not confirmed built |

### Technical — Global

| # | Check | Status |
|---|-------|--------|
| G-T1 | `OnboardingStore` is the single source of truth for all OB state | 🔴 OnboardingStore does not exist per build state — this is the stated P0 blocker |
| G-T2 | Views call store actions only — zero direct service or DB calls from any View | 🔵 Cannot verify until OnboardingStore is written |
| G-T3 | Every async action on store is covered by `isLoading` flag — no screen freezes | 🔴 No store = no loading state contract |
| G-T4 | Every tappable element has press state (`.scaleEffect` or `.offset`), haptic (`.sensoryFeedback`), and action — no silent taps | 🟡 Not verifiable per-phase until components exist, but must be enforced in review |
| G-T5 | `OnboardingData` is fully populated by `commit()` — all fields non-nil before `BuildingPathPhase` | 🔴 Stated P0 — currently all data is dropped on the floor |
| G-T6 | `UserProfile` written to SwiftData with `saveWithLogging()` on OB completion — no `try?` | 🔴 Stated P0 |
| G-T7 | `hasCompletedOnboarding` prevents OB replay on relaunch | 🔴 Not implemented per build state |
| G-T8 | Every text element uses `Font.custom(_:size:relativeTo:)` — `relativeTo:` is mandatory, never bare size | 🔴 AppStore compliance violation if missing |
| G-T9 | Every tappable element has minimum 44×44pt hit target | 🟡 Card-tap mechanics (GenderPhase drag, ContextPhase swipe) require explicit geometry audit |
| G-T10 | VoiceOver labels on every custom/gesture-driven component — decoratives hidden | 🟡 Card faces, dealer animations, foil tears must all declare accessibility intent |
| G-T11 | `UIScreen` is banned — all screen dimensions via `AppLayout.from(geometry)` | 🟡 C6 lists deprecated `UIScreen.main.bounds` in multiple files |

---

## Phase-by-Phase Audit

---

### Phase 1 — StatPhase
> *"1 in 5" holographic glow + citation + ethos. Pure black. CTA → table world.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 1-V1 | Holographic glow is driven by a semantic color token (e.g., `AppColors.accentHolographic`) — never `Color(hex:)` | 🔴 |
| 1-V2 | Glow animation uses `AppAnimation` token — not raw duration | 🔴 |
| 1-V3 | Citation text uses AppFonts caption/legal weight — legible at minimum Dynamic Type size | 🟡 |
| 1-V4 | CTA button conforms to Button Decision Rule — this is forward navigation = CTA Button, not Selectable Pill | 🔵 Confirm button component chosen |
| 1-V5 | "Pure black — inherits void" means `AppColors.void` is the background, not a raw black | 🔴 |
| 1-V6 | Ambient holographic loop wrapped in `.ambientAnimation()` | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 1-T1 | CTA tap triggers `store.advancePhase()` (or equivalent) — no routing logic in View | 🔴 |
| 1-T2 | CTA has press state + haptic + action | 🟡 |
| 1-T3 | VoiceOver: stat headline has `.accessibilityLabel` describing the stat — not just the glyph | 🟡 |
| 1-T4 | VoiceOver: CTA button has `.accessibilityAddTraits(.isButton)` | 🟡 |

#### Open Questions
- 🔵 Does AtmosphereView render on this phase, or is it truly pure void? If AtmosphereView is suppressed here, that exception must be documented in the store, not the view.

---

### Phase 2 — NamePhase
> *Name entry. Typewriter card face. WriteLineView. Card 1 → CornerDeck.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 2-V1 | Card surface uses `.glassCard()` + `.hairline(.resting/.active)` | 🔴 |
| 2-V2 | Typewriter animation uses `AppAnimation` token — not raw timer/`DispatchQueue` | 🔴 |
| 2-V3 | Text field uses AppFonts — `relativeTo:` present | 🔴 |
| 2-V4 | Keyboard avoidance: name input never occluded by software keyboard | 🔴 AppStore compliance — must use `.ignoresSafeArea(.keyboard)` on scroll container |
| 2-V5 | CornerDeck card-fly animation uses `AppAnimation.standard` or slower — no snap | 🟡 |
| 2-V6 | Empty state: what does the CTA look like before the user has typed anything? Disabled state must be visually distinct | 🔵 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 2-T1 | Name field binding lives on `OnboardingStore` — `@Bindable var store` — not local `@State` | 🔴 |
| 2-T2 | CTA disabled until name is non-empty — validation in store, not view | 🔴 |
| 2-T3 | WriteLineView: if it wraps a custom drawing surface, it must have `.accessibilityLabel("Name entry field")` | 🟡 |
| 2-T4 | CornerDeck card #1 state change driven by store flag — view only reacts | 🟡 |
| 2-T5 | No `DispatchQueue.main.async` in typewriter animation — use `Task` + `try await Task.sleep` | 🔴 |

#### Open Questions
- 🔵 Is there a character limit on name? If yes, where is it enforced — store or service?
- 🔵 Is the name trimmed of whitespace before persisting?

---

### Phase 3 — GenderPhase
> *Gender identity. Slot machine card face. Handle drag → reel spin → card tear → picker.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 3-V1 | Slot machine reel uses AppColors tokens for reel face backgrounds | 🔴 |
| 3-V2 | Card tear animation is a defined, named transition — not ad-hoc offset math | 🟡 |
| 3-V3 | Reel spin velocity tied to drag velocity — feels physical, not linear | 🔵 Confirm physics model |
| 3-V4 | Card surface `.glassCard()` + `.hairline(.active)` while drag is active, `.resting` when settled | 🟡 |
| 3-V5 | Picker that appears post-tear uses AppSpacing for row height/padding | 🔴 |
| 3-V6 | Selected gender identity visually distinct via semantic color token — not raw `.blue` or `.purple` | 🔴 |
| 3-V7 | Ambient reel idle loop wrapped in `.ambientAnimation()` | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 3-T1 | Drag gesture state tracked in store or via `@GestureState` — not raw `@State var offset` that leaks between phases | 🟡 |
| 3-T2 | Gender selection stored on `OnboardingStore.onboardingData.genderIdentity` — not local | 🔴 |
| 3-T3 | Custom picker must be navigable via VoiceOver — each option `.accessibilityLabel` + `.isSelected` trait | 🔴 |
| 3-T4 | Drag affordance (handle) has minimum 44×44pt hit target | 🔴 |
| 3-T5 | Card tear transition must respect Reduce Motion — fallback to opacity fade | 🔴 |
| 3-T6 | No force unwrap on selected gender value before advancing | 🔴 |

#### Open Questions
- 🔵 Is the gender identity list fixed (enum) or user-typed? If user-typed, same keyboard + validation rules as NamePhase apply.
- 🔵 What is the "card tear" fallback on Reduce Motion? Defined or TBD?

---

### Phase 4 — ModeSelectPhase
> *Solo Discovery vs Shared Journey. Mirror deal. Two cards from opposite sides. Tap to lift, swipe up to confirm.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 4-V1 | Both cards use `.glassCard()` — unselected `.hairline(.resting)`, selected/lifted `.hairline(.active)` | 🔴 |
| 4-V2 | Mirror deal animation is symmetrical — uses `AppAnimation.standard` | 🟡 |
| 4-V3 | "Lift" press state uses `.scaleEffect` driven by gesture phase — not an arbitrary scale value | 🔴 |
| 4-V4 | Swipe-up confirmation gesture has a visible affordance (chevron, indicator) styled with AppColors | 🟡 |
| 4-V5 | Unselected card visually recedes — opacity/scale delta uses design tokens, not raw `0.6` | 🔴 |
| 4-V6 | Card labels (Solo Discovery / Shared Journey) use AppFonts with `relativeTo:` | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 4-T1 | `AppMode` selection stored on `OnboardingStore` — drives `OnboardingData.appMode` | 🔴 |
| 4-T2 | Swipe-up gesture uses `DragGesture` with threshold — threshold value is a named constant in AppLayout or the Store, not a raw `100` | 🟡 |
| 4-T3 | VoiceOver: both cards labeled, selected state declared via `.isSelected` trait, non-selected card not hidden | 🔴 |
| 4-T4 | Browsing/solo fork in routing logic lives in `OnboardingStore` — not in `ModeSelectView` | 🔴 |
| 4-T5 | No silent tap — tapping either card must trigger haptic | 🔴 |
| 4-T6 | Swipe-up must also trigger haptic on confirm | 🔴 |
| 4-T7 | Card that is not selected: is it tappable to switch selection, or must user lift the selected card first? | 🔵 |

#### Open Questions
- 🔵 If user selects Solo → does partner linking appear later in onboarding or is it deferred to Settings? This affects `ConfirmationPhase` display.
- 🔵 "Mirror deal from opposite sides" — does this require `AppLayout.from(geometry)` to compute safe entry points? Confirm UIScreen is not used.

---

### Phase 5 — ExperienceLevelPhase
> *Three Card Monte deal → shuffle → simultaneous flip. Candle card face — three intensity states.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 5-V1 | Three cards use `.glassCard()` + `.hairline` appropriate to state | 🔴 |
| 5-V2 | Candle intensity states (3) use semantic color tokens — not raw brightness values | 🔴 |
| 5-V3 | Shuffle animation uses `AppAnimation` token — cards have spring physics feel | 🟡 |
| 5-V4 | Simultaneous flip on all three cards — must be a single coordinated `withAnimation` block, not three separate delayed calls | 🟡 |
| 5-V5 | Ambient candle flicker wrapped in `.ambientAnimation()` | 🔴 |
| 5-V6 | Selected card visually distinct from unselected — not relying on color alone (shape, weight, or position change also present) | 🔴 Accessibility: color-only distinction fails WCAG |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 5-T1 | Experience level stored on `OnboardingStore.onboardingData.experienceLevel` | 🔴 |
| 5-T2 | Three Card Monte shuffle is visual only — order of options is fixed after initial deal, not random (random order = unpredictable UX) | 🔵 |
| 5-T3 | VoiceOver: each card announces its level label + selected state | 🔴 |
| 5-T4 | Tapping a card: haptic + press state + store action — all three | 🔴 |
| 5-T5 | Reduce Motion: shuffle animation collapses to crossfade — candle intensity change is instant | 🔴 |

#### Open Questions
- 🔵 Are the three intensity states mapped to a typed enum in `AppEnums.swift`? What are the canonical values?
- 🔵 Does experience level feed into `ContentLoader` deck selection at HomeRouterView? If yes, document the join key now.

---

### Phase 6 — ContextPhase
> *Cards deal onto felt → table fades → stack lifts into VaylCardPhysics carousel. Swipe up → confirmed card pockets → vacuum pull clears felt.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 6-V1 | Felt texture, if rendered, is a designated asset — not a raw `Color` or `UIColor` | 🟡 |
| 6-V2 | VaylCardPhysics carousel: each card uses `.glassCard()` + `.hairline` | 🔴 |
| 6-V3 | Carousel spring parameters use `AppAnimation` tokens — not raw stiffness/damping values | 🔴 |
| 6-V4 | "Vacuum pull" exit animation — direction and duration are named constants, not inline magic numbers | 🔴 |
| 6-V5 | "Table fades" transition uses `AppAnimation.standard` — not raw `.easeOut(duration:)` | 🔴 |
| 6-V6 | Swipe-up affordance styled consistently with Phase 4 confirm gesture | 🟡 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 6-T1 | Context/relationship status stored on `OnboardingStore` | 🔴 |
| 6-T2 | VaylCardPhysics: if physics is driven by a custom gesture loop, it must not use `DispatchQueue` or `Timer` — use SwiftUI gesture + `withAnimation` | 🔴 |
| 6-T3 | Carousel is VoiceOver navigable — swipe left/right between options, current option announced | 🔴 |
| 6-T4 | "Cards deal onto felt" — deal animation does not start until view appears, not pre-baked | 🟡 |
| 6-T5 | Vacuum pull uses `Task` + `try await Task.sleep` for sequencing — not `DispatchQueue.asyncAfter` | 🔴 |
| 6-T6 | ContextPhase is the most animation-dense phase so far — profile it. No dropped frames at 60fps on iPhone 12 minimum | 🟡 |

#### Open Questions
- 🔵 What are the context options? Typed enum in AppEnums.swift or free-form? This must be decided before implementation.
- 🔵 "Stack lifts into carousel" — does AppLayout.from(geometry) drive the lift offset, or is it a fixed value?

---

### Phase 7 — QuizPhase
> *One research-backed curiosity question. Four answer cards on felt. Dealer line above. Tap → glow → 1.5s pause → vacuum pull. Ephemeral.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 7-V1 | Answer cards use `.glassCard()` + `.hairline(.resting)` at rest | 🔴 |
| 7-V2 | "Correct card glows" — glow uses `AppColors.accentPrimary` or equivalent semantic token, not raw cyan | 🔴 |
| 7-V3 | Dealer line is a styled divider — uses AppSpacing for its vertical position from top | 🟡 |
| 7-V4 | 1.5s pause before vacuum pull — must feel intentional, not like a hang. Consider subtle ambient card shimmer during pause using `.ambientAnimation()` | 🔵 |
| 7-V5 | Vacuum pull direction is consistent with ContextPhase vacuum pull | 🟡 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 7-T1 | "Ephemeral" — quiz answer is NOT stored in `OnboardingData` beyond informing routing, and is NOT written to SwiftData | 🔴 Confirm this is intentional — if it feeds content routing it must persist somewhere |
| 7-T2 | 1.5s pause uses `try await Task.sleep(for: .seconds(1.5))` — not `DispatchQueue.asyncAfter` | 🔴 |
| 7-T3 | Four answer cards: each tappable with 44×44pt minimum, haptic on tap, press `.scaleEffect` | 🔴 |
| 7-T4 | VoiceOver: each card reads its answer text + announces when selected/glowing | 🔴 |
| 7-T5 | Reduce Motion: glow is an opacity pulse — vacuum pull becomes a fade | 🔴 |
| 7-T6 | What happens if user taps two cards before the 1.5s elapses? Store must debounce — only first tap counts | 🔴 |

#### Open Questions
- 🔵 "Ephemeral" — if the quiz answer never persists, what is its purpose? Does it seed something in BuildingPathPhase copy? This data contract must be defined before writing the store action.
- 🔵 No CornerDeck card for this phase — is that reflected in the corner deck progress indicator? Does the indicator skip, or is it hidden for this phase?

---

### Phase 8 — CuriosityPhase
> *Two rounds. TBD — currently being redesigned. Corner deck reaches 6/6 on round 2 confirm.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 8-V1 | Phase is marked TBD — **do not implement visual design until spec is finalized** | 🔴 |
| 8-V2 | CornerDeck reaching 6/6 should have a distinct completion micro-animation — needs to be specced | 🔵 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 8-T1 | `CuriosityScreenConfig` is listed as commented out in build state — cannot build this phase until config is unblocked | 🔴 |
| 8-T2 | CuriosityPhase data is stored on `OnboardingStore.onboardingData.curiositySelections` | 🔴 |
| 8-T3 | Two-round structure: round state lives in store — not local view state | 🔴 |

#### Open Questions
- 🔵 This phase is being redesigned. **Do not write any implementation code until the redesign is finalized and reviewed.** Flag this phase as LOCKED.

---

### Phase 9 — ConfirmationPhase *(NEW)*
> *Review + edit all entries. Full corner deck visible. Tap credential card to edit. Confirm → BuildingPathPhase.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 9-V1 | Each credential card uses `.glassCard()` + `.hairline(.resting)` — `.active` on press | 🔴 |
| 9-V2 | Tapping a credential card to edit: transition back to the relevant phase must be a defined, named transition (not `.default`) | 🟡 |
| 9-V3 | Full corner deck at 6/6 visible — its position uses AppLayout, not hardcoded offsets | 🔴 |
| 9-V4 | Confirm CTA is clearly the primary action — visual weight follows Button Decision Rule (CTA button, not pill) | 🔴 |
| 9-V5 | Each credential card shows the captured value legibly at minimum Dynamic Type size | 🔴 |
| 9-V6 | Empty or nil credential values should have a visible "not set" indicator — not blank | 🔵 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 9-T1 | Editing a credential routes back through `OnboardingStore.currentPhase` — the store owns backward navigation, not a sheet or NavigationStack pushed by the view | 🔴 |
| 9-T2 | After editing and returning to ConfirmationPhase, edited value is immediately reflected — no stale state | 🔴 |
| 9-T3 | All six data fields read from `OnboardingStore.onboardingData` — never from local copies | 🔴 |
| 9-T4 | Confirm button triggers `store.advanceToBuilding()` — one action, no inline logic | 🔴 |
| 9-T5 | Each credential card: press state + haptic + action — no silent taps | 🔴 |
| 9-T6 | VoiceOver: each credential card announces field name + current value + "double tap to edit" | 🔴 |
| 9-T7 | This phase is new — its case must be added to the `OnboardingPhase` enum **on the same commit** it is written | 🔴 |

#### Open Questions
- 🔵 What is the back-navigation UX? Does the corner deck "unstack" a card when editing, then re-stack on return? Or does CornerDeck stay at 6/6 throughout?
- 🔵 If user is in Solo mode, is the partner-link credential shown here? If not, what fills that slot?
- 🔵 QuizPhase is ephemeral — it has no credential card. Does the Confirmation screen show 5 rows or 6? Clarify the exact list displayed.

---

### Phase 10 — BuildingPathPhase
> *Slot machine copy rolls through each data point → checkmark. "{name}" hero. Four items resolve. Deck assembles. Skip after 1.5s.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 10-V1 | Slot machine text animation: characters use AppFonts — `relativeTo:` present | 🔴 |
| 10-V2 | Hero `{name}` display uses a distinct headline token from AppFonts — visually dominant | 🟡 |
| 10-V3 | Checkmark reveal uses `AppAnimation.fast` — snappy, satisfying | 🟡 |
| 10-V4 | Deck assembly on table: cards use `.glassCard()` + `.hairline` | 🔴 |
| 10-V5 | Skip button appears after 1.5s — uses `AppAnimation.fast` fade-in, not snap | 🟡 |
| 10-V6 | Four items resolve sequentially — stagger uses `AppAnimation` tokens, not raw `.delay(0.3)` | 🔴 |
| 10-V7 | Slot machine idle (before resolution) wrapped in `.ambientAnimation()` | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 10-T1 | All four data points read from `OnboardingStore.onboardingData` — this phase is purely presentational | 🔴 |
| 10-T2 | Slot machine sequencing uses `Task` + structured concurrency — no `DispatchQueue` chains | 🔴 |
| 10-T3 | Skip button: after 1.5s, revealed via store flag — not a local `@State var showSkip` | 🟡 |
| 10-T4 | Skip tap skips to `FoilPhase` — routing in store | 🔴 |
| 10-T5 | VoiceOver: when screen appears, announce "Building your path" — then each resolved item announced as it confirms | 🟡 |
| 10-T6 | Reduce Motion: slot machine becomes a simple sequential fade. No spinning. | 🔴 |
| 10-T7 | No writes happen in this phase — all SwiftData writes occur in `commit()` on ConfirmationPhase confirm. Verify this contract. | 🔴 |

#### Open Questions
- 🔵 What are the exact "four items" that resolve? Name, mode, experience level, context? Confirm the canonical list.
- 🔵 "Deck assembles on table" — is this the actual deck the user will use (loaded by ContentLoader), or a visual placeholder? If real, `ContentLoader` is called here — that must be in the store.

---

### Phase 11 — FoilPhase
> *Foil wraps deck. Spectrum crinkle. Tap to tear. 3–5 taps → dissolve. Particles scatter. Deck revealed. 1s stillness. Letter rises.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 11-V1 | Foil material is a layered shader or asset — not a raw gradient | 🟡 |
| 11-V2 | Spectrum particles use semantic color tokens: `AppColors.spectrumCyan`, `AppColors.spectrumPurple`, `AppColors.spectrumMagenta` — not raw values | 🔴 |
| 11-V3 | 800ms fade uses `AppAnimation` token — not raw `.easeOut(duration: 0.8)` | 🔴 |
| 11-V4 | Foil catch of "amber light" implies a light source — confirm this is an asset or shader, not `Color.yellow.opacity(0.3)` | 🔴 |
| 11-V5 | Tear-at-tap-point mechanic: tap point used to drive tear origin — uses `DragGesture` location or `TapGesture` with location, not center-fixed | 🟡 |
| 11-V6 | 1s stillness after reveal — ensure no ambient animation fires during this beat. It should be silence. | 🔵 |
| 11-V7 | Ambient foil shimmer before first tap wrapped in `.ambientAnimation()` | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 11-T1 | Tap counter (3–5 taps to dissolve) lives in store — not `@State var tapCount` in view | 🔴 |
| 11-T2 | Particle system: if using Canvas or custom drawing, must be wrapped in `TimelineView` or SwiftUI animation — not a `CADisplayLink` | 🔴 |
| 11-T3 | Each foil tap: haptic (impact, `.medium`) + press state + action | 🔴 |
| 11-T4 | Reduce Motion: no tear animation, no particles — foil fades out, deck crossfades in | 🔴 |
| 11-T5 | VoiceOver: announce "Tap to unwrap your deck" — tear taps announced as progress ("Tap 1 of 3", etc.) | 🟡 |
| 11-T6 | "Letter rises" transition hands off to `FounderLetterPhase` — store advances phase | 🔴 |
| 11-T7 | 1s stillness: `try await Task.sleep(for: .seconds(1.0))` in store action — not timer | 🔴 |

#### Open Questions
- 🔵 Is 3–5 taps variable (random each session) or fixed? If variable, where is the count generated — store init, or on phase entry?
- 🔵 Does the foil phase require a fallback for users who do not tap within N seconds? Auto-dissolve timeout? Define this now.

---

### Phase 12 — FounderLetterPhase
> *Card rises from deck. Flips — dark paper, typewritten. Name first. Signature writes in real time. Single swipe down → home rises.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 12-V1 | Card surface: `.glassCard()` + `.hairline(.resting)` — unless intentionally "dark paper" overrides glassCard. If so, document the design exception. | 🔵 |
| 12-V2 | Typewritten text animation: AppFonts monospace or typewriter token — `relativeTo:` present | 🔴 |
| 12-V3 | Signature draw-in: strokes follow a defined path — not freehand randomness | 🟡 |
| 12-V4 | "Card rises from deck" — entry animation uses `AppAnimation.standard` | 🟡 |
| 12-V5 | Card flip: `.rotation3DEffect` uses `AppAnimation` token for duration | 🔴 |
| 12-V6 | "Home screen rises simultaneously" with swipe down — this is a matched geometry / simultaneous transition. Must not be two sequential animations. | 🔴 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 12-T1 | User's name interpolated into letter copy from `OnboardingStore.onboardingData.displayName` — never from local state | 🔴 |
| 12-T2 | Signature draw-in: `Path` animation using `trim(from:to:)` animated with `AppAnimation` — not `CAShapeLayer` | 🟡 |
| 12-T3 | Typewriter sequencing uses `Task` + structured concurrency | 🔴 |
| 12-T4 | Swipe-down gesture: `DragGesture` — threshold is a named constant, not raw `100` | 🟡 |
| 12-T5 | "Contracts mid-gesture" — card scale driven by `DragGesture.translation.height` — proportional, not stepped | 🟡 |
| 12-T6 | Home screen rising: the `OnboardingStore` sets `hasCompletedOnboarding = true` and triggers AppState transition — not a NavigationStack push | 🔴 |
| 12-T7 | VoiceOver: full letter text must be readable. Typewriter animation should complete immediately for VoiceOver users (check `accessibilityReduceMotion` or announce full text on appear). | 🔴 |
| 12-T8 | Reduce Motion: typewriter completes instantly, flip is a crossfade, swipe-down transition is a simple fade | 🔴 |

#### Open Questions
- 🔵 Does the letter content vary by `AppMode` (Solo vs Together) or `NMStage`? If yes, letter copy must come from a typed content source — not be hardcoded in the view.
- 🔵 "Dark paper, typewritten" — does this phase intentionally not use AtmosphereView? Document the exception if so.

---

### Phase 13 — AppArrival
> *All six credential cards fanned. The collected deck IS the symbol. App opens.*

#### Visual Checks
| # | Check | Flag |
|---|-------|------|
| 13-V1 | Fan layout uses AppLayout geometry — no hardcoded rotation or offset values | 🔴 |
| 13-V2 | Each credential card uses `.glassCard()` + `.hairline(.resting)` | 🔴 |
| 13-V3 | Fan-to-home transition: this is the seam between onboarding and the app — it must feel continuous with HomeRouterView's AtmosphereView | 🔴 |
| 13-V4 | The fan moment should have a beat of stillness before the home screen appears — same principle as FoilPhase 1s pause | 🔵 |
| 13-V5 | Cards fan into their final positions using a spring animation — `AppAnimation.standard` with spring | 🟡 |

#### Technical Checks
| # | Check | Flag |
|---|-------|------|
| 13-T1 | `hasCompletedOnboarding = true` must already be set by FounderLetterPhase — AppArrival is purely visual | 🔴 |
| 13-T2 | AppState transition (onboarding → home) triggered from store — HomeRouterView must be conditionally rendered by AppState, not pushed | 🔴 |
| 13-T3 | Six credential cards sourced from `OnboardingStore.onboardingData` — the same data that was just committed | 🔴 |
| 13-T4 | VoiceOver: announce "Welcome to Vayl, {name}" — then transition | 🟡 |
| 13-T5 | This phase must not perform any SwiftData writes or network calls — it is a pure ceremony | 🔴 |
| 13-T6 | If AppArrival is interrupted (background → foreground), user should land on HomeRouterView, not replay AppArrival | 🔴 |

#### Open Questions
- 🔵 Do the six fanned credential cards persist visually into the HomeRouterView as a hero moment, or do they dissolve before home appears?
- 🔵 Is there a sound design moment here? If audio is introduced at any phase, it must handle `AVAudioSession` + silent mode correctly.

---

## Summary Scoreboard

| Phase | 🔴 Blockers | 🟡 Warnings | 🔵 Open Questions |
|-------|-------------|-------------|-------------------|
| Global | 10 | 3 | 2 |
| 1 — Stat | 4 | 0 | 1 |
| 2 — Name | 5 | 1 | 2 |
| 3 — Gender | 5 | 1 | 2 |
| 4 — ModeSelect | 6 | 1 | 2 |
| 5 — Experience | 4 | 1 | 2 |
| 6 — Context | 5 | 2 | 2 |
| 7 — Quiz | 5 | 1 | 2 |
| 8 — Curiosity | 2 | 0 | 1 |
| 9 — Confirmation | 7 | 1 | 3 |
| 10 — BuildingPath | 6 | 2 | 2 |
| 11 — Foil | 7 | 1 | 2 |
| 12 — FounderLetter | 7 | 3 | 2 |
| 13 — AppArrival | 6 | 1 | 2 |
| **TOTAL** | **79** | **18** | **27** |

---

## Top 10 Must-Fix Before Any Phase Is Implemented

These are the prerequisite blockers. Nothing else can be built correctly without them.

1. **OnboardingStore does not exist.** Every phase flag is downstream of this. Write it first.
2. **AppSpacing, AppLayout, AppAnimation, AppRadius token files do not exist.** Every visual check fails without them.
3. **AppColors semantic tokens not confirmed.** Every color in every phase must route through them.
4. **AppFonts with `relativeTo:` not confirmed.** Every text element in every phase is an App Store compliance violation without it.
5. **`saveWithLogging()` in OnboardingStore `commit()`.** UserProfile is currently never written.
6. **`hasCompletedOnboarding` flag prevents OB replay.** Without it, every relaunch replays the entire flow.
7. **`DispatchQueue` / `Timer` banned in animation sequencing.** FlameAura and LightAuraBloom must be fixed before any new OB animations are layered on top.
8. **Reduce Motion fallbacks must be designed for every animated phase.** Not an afterthought — spec them now.
9. **CuriosityPhase is LOCKED until redesign is complete.** Do not implement Phase 8 in any form.
10. **ConfirmationPhase (Phase 9) enum case must be added to `OnboardingPhase` on the same commit it is written.** Pre-plan the enum update.

---

*Audit version 1.0 — against Vayl Session Rules v2.1*
*Re-audit required after: OnboardingStore written, design tokens built, CuriosityPhase redesign delivered.*
