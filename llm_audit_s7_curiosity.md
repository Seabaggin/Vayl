# LLM Audit Context — Open Lightly
> Script : gather_audit_s7_curiosity.sh
> Generated: 2026-04-04 10:45:05 PDT

---

## Table of Contents

  1. [`FILE_TRACKER.md`](#file-file-tracker-md)
  2. [`PROJECT_SCOPE.md`](#file-project-scope-md)
  3. [`Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift`](#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift)
  4. [`Open Lightly/Features/Onboarding/Components/CuriosityPill.swift`](#file-open-lightly-features-onboarding-components-curiositypill-swift)
  5. [`Open Lightly/Features/Onboarding/Components/CuriosityStatusStrip.swift`](#file-open-lightly-features-onboarding-components-curiositystatusstrip-swift)
  6. [`Open Lightly/Features/Onboarding/Components/CuriosityPanelNudge.swift`](#file-open-lightly-features-onboarding-components-curiositypanelnudge-swift)
  7. [`Open Lightly/Features/Onboarding/Components/CuriosityPreviewLine.swift`](#file-open-lightly-features-onboarding-components-curiositypreviewline-swift)
  8. [`Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift`](#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift)
  9. [`Open Lightly/Design/Components/Effects/FloatingCard.swift`](#file-open-lightly-design-components-effects-floatingcard-swift)

---

## File: `FILE_TRACKER.md` {#file-file-tracker-md}

```markdown
# Open Lightly — File Tracker

> Last updated: 2026-04-03
> ~160 Swift files across 36 directories

---

## Reach Tags

Files that touch many other files or provide cross-cutting infrastructure get a reach tag:

| Tag | Meaning |
|---|---|
| **`FOUNDATION`** | Imported or referenced by 10+ files across the codebase |
| **`BACKBONE`** | Core architectural piece — removing it breaks the app |
| **`BRIDGE`** | Connects two major subsystems (e.g. local data ↔ remote) |
| **`HUB`** | Central routing or orchestration point |

---

## `App/`

| File | What It Does | Reach |
|---|---|---|
| **`ContentView.swift`** | Root router. Gates onboarding vs. main tab bar vs. guest shell based on `@AppStorage("hasCompletedOnboarding")` and `AppState.experienceType`. | **`HUB`** |
| **`Open_LightlyApp.swift`** | `@main` entry point. Creates `AppState`, `ThemeManager`, and the SwiftData `ModelContainer`. Injects all environment objects. Gates auth (`SignInView` vs `ContentView`). Retries pending Supabase syncs on launch. | **`BACKBONE`** |

### `App/Theme/`

| File | What It Does | Reach |
|---|---|---|
| **`AppColors.swift`** | Full color palette as static `Color` constants plus a `Color(hex:)` initializer. Single source of truth for every color token in the app. **⚠️ Contains 10 unused tokens** (`purpleBright`, `electricViolet`, `cyanDark`, `deepPurple`, `surfaceRaised`, `textQuaternary`, `btnGhostBorder`, `btnGhostText`, `badgeBg`, `destructive`) — candidates for removal. | **`FOUNDATION`** |
| **`AppFonts.swift`** | Centralized font factory. Static methods for Clash Display (display/headline) and Switzer (body) at named semantic sizes (`screenTitle`, `overline`, `body`, etc.). | **`FOUNDATION`** |
| **`AppTheme.swift`** | Defines `ThemeMode` enum (system / light / amoled) and `AppPalette` — the resolved set of semantic colors for the active theme. | |
| **`ThemeManager.swift`** | `@Observable` class. Persists the user's selected theme mode to `UserDefaults` and resolves the active `AppPalette` from mode + system `colorScheme`. | |
| **`ThemeModifiers.swift`** | `ThemedRootModifier` ViewModifier. Injects the resolved `AppPalette` into the environment and sets `preferredColorScheme`. Applied once at the root via `.themedRoot()`. | |

---

## `Core/Services/`

| File | What It Does | Reach |
|---|---|---|
| **`AppState.swift`** | `@MainActor @Observable` class. Owns `experienceType` (persisted to `UserDefaults`) which drives all home-screen routing. Injected as `@Environment` at the root. | **`BACKBONE`** |
| **`Config.swift`** | Static constants for Supabase project URL and anon key. The only file with hardcoded credentials. | |
| **`SupabaseManager.swift`** | Singleton. Initializes and exposes the single `SupabaseClient` instance. All services read from `SupabaseManager.shared.client`. | **`BRIDGE`** |
| **`AuthService.swift`** | Sign in with Apple via Supabase auth. Publishes `isAuthenticated`, `userId`, `isLoading`, `error`. Uses `ObservableObject` (legacy — pre-`@Observable` migration). | |
| **`ProfileService.swift`** | Reads/writes user profile data to Supabase `profiles` table. **⚠️ Contains nested `SupabaseProfile` Codable struct** — should be extracted to `Models/` for cross-service visibility (also used by `SyncManager`). Uses `ObservableObject` (legacy). | |
| **`PairingService.swift`** | Couple pairing: generate codes, look up codes, complete pairing in Supabase. Publishes `generatedCode`, `isPairing`, `error`. Uses `ObservableObject` (legacy). | |
| **`ContentLoader.swift`** | Static generic helper that decodes bundled JSON files from the app bundle. `fatalError` on missing/malformed files (dev-time catch). | |
| **`SyncManager.swift`** | Orchestrator for local-first data writes. Pattern: save to SwiftData first, push to Supabase; if push fails, flag for retry via `UserDefaults`. Coordinates all domain sync services. | **`BRIDGE`** |
| **`AssessmentSyncService.swift`** | Pushes completed assessment data (responses + results) from SwiftData to Supabase `assessment_responses` / `assessment_results`. | |
| **`DesireSyncService.swift`** | Pushes desire map ratings from SwiftData to Supabase `desire_ratings`. Ratings are private — only used server-side for DesireMatch computation. | |
| **`SessionSyncService.swift`** | Pushes completed couple session records from SwiftData to Supabase `couple_session_records`. Syncs on completion, pause, and safe-word. | |

---

## `Data/Store/`

| File | What It Does | Reach |
|---|---|---|
| **`DataStore.swift`** | Central persistence layer. All SwiftData reads/writes go through here (`saveSession`, `fetchAllSessions`, `fetchOrCreateStreak`, etc.). Initialized with a `ModelContext`. | **`BRIDGE`** |
| **`ModelContainer.swift`** | `extension ModelContainer` that registers all `@Model` classes into the shared container. Called once from the app entry point. | |

---

## `Design/Components/`

### `Banners/`

| File | What It Does |
|---|---|
| **`GuestBannerView.swift`** | Persistent top banner for guest/browsing users. "Create an account" button resets onboarding flag to re-enter the flow. References `AppState`. |

### `Buttons/`

| File | What It Does |
|---|---|
| **`CriticalButton.swift`** | Destructive/neutral action button. `.neutral` and `.danger` styles. Themed via `\.theme` (`AppPalette`). |
| **`GradientButton.swift`** | Full-width gradient CTA button. Uses `t.buttonGradient`. Glow shadow adapts between amoled and light. **⚠️ Contains `GradBadge` component** (lines 45–59) — only used in `DesireMapView` and `ThemeTestView`; consider deprecation. |
| **`HoloCTAButton.swift`** | Primary onboarding CTA. Dark: holographic shimmer + pill border + bloom. Light: warm aurora shimmer + shadow spread. References `HolographicShimmer`, `LightModeShimmer`, `PillBorder`. **⚠️ Contains unused `CTABorderModifier`** (lines 165–176) — defined but never instantiated; consider refactoring to use it or removing. |
| **`SafeWordButton.swift`** | Always-visible safety button during sessions. Shows confirmation alert before triggering the safe-word callback. |
| **`SelectablePill.swift`** | Toggle pill for multi-select lists (onboarding pickers). Three intensity levels. Dark: holo shimmer + flame aura. Light: aurora shimmer + shadow. |

### `Cards/`

| File | What It Does |
|---|---|
| **`AtmosphericGhostDeck.swift`** | Ghost deck visual for CardRevealView. Layered cards with atmospheric blur + glow. |
| **`CardBackView.swift`** | Back face of the CardReveal flip card. Gradient fill, "Something came up" heading, and 4 `CardRevealPill` option buttons. Pill selection state and entrance stagger managed here. |
| **`CardFrontView.swift`** | Front face of the CardReveal flip card. Bridge prompt text + fuse timer burn effect that progressively erases the spectrum border clockwise via Canvas. Contains `interpolate` helper for position-based spark color. |
| **`CardLayout.swift`** | Single source of truth for card dimensions. Standard card: 313×438pt (poker/bridge 1:1.40 ratio). Defines `width`, `height`, `cornerRadius`, `size`, `horizontalMargin`. |
| **`CardRevealPillButton.swift`** | Individual pill button on `CardBackView`. Handles selected/unselected visual states, entrance stagger animation, and disabled state for non-selected pills post-selection. |
| **`CardShadows.swift`** | `View` extension `.cardShadows(isLight:)`. Reusable two-layer shadow modifier (ambient color + depth drop) shared by `CardFrontView`, `CardBackView`, and related cards. |
| **`CategoryTileView.swift`** | Home-screen grid tile. Emoji, name, card count, and a `ProgressBar` for one category. |
| **`CircularArrowView.swift`** | Animated circular arrow indicator. Used in gesture-driven UI. |
| **`ConversationCard.swift`** | Rendered prompt card in sessions. Displays text with highlighted keywords, difficulty badge, category. |
| **`ConversationCardTypes.swift`** | Types and enums for conversation cards. Card styling by difficulty/type. |
| **`CuriosityCardBack.swift`** | Face-down side of curiosity picker cards. Laser-engraved maze texture (`MazePatternView`) + embedded `TileOrbitView` orbit. Orbit stops (`isActive: false`) when flipped to prevent Canvas bleed-through. |
| **`CuriosityFlipCard.swift`** | 3D flip container. Pairs `CuriosityCardBack` with a caller-supplied front face. `isFlipped = false` → back visible, orbit active. `isFlipped = true` → front visible, orbit stopped. |
| **`FuseTimerView.swift`** | Session timer display. Countdown or elapsed time with optional urgency indicators. |
| **`PromptCard.swift`** | Renders a single conversation prompt card with difficulty-keyed styling (background tint, border opacity, glow color). |
| **`SettingsCard.swift`** | Generic `<Content: View>` container. Wraps content in a padded `.cardStyle()` shell for Settings and list screens. |

### `Effects/`

| File | What It Does |
|---|---|
| **`AuroraGlowField.swift`** | Light mode atmospheric blob background. 6 blobs in magenta/purple/gold/pink at 6–9% opacity. Light mode counterpart to `OnboardingGlowField`. |
| **`FlameAura.swift`** | Flame-wisp particle effect for selected `SelectablePill`s in dark mode. Intensity-driven sizing. |
| **`FloatingCard.swift`** | Individual floating glass card (`FloatingCardSpec` data model + `FloatingCard` view). Used in `OnboardingCuriosityPickerView`. Float physics (Y offset, rotation, gravity) driven by parent; owns press state and mounted entrance. Dark: deep purple + angular gradient border. Light: frost fill + warm aurora border. |
| **`FloatingStack.swift`** | Generic collapsible card stack (`FloatingStackConfig` + `FloatingStack<Item, Content>`). Config-driven with `.curiosityStack` and `.sessionDeck` presets. Collapsed: stacked ghost layers with count badge. Expanded: vertical list with collapse handle. Supports float animation when used in cluster. |
| **`GlowOrb.swift`** | Single blurred radial-gradient circle. Opacity from `t.glowOpacity`. Decorative accent. |
| **`HolographicShimmer.swift`** | Animated 3x-wide cyan→purple→magenta→pink gradient that sweeps L→R. Dark mode overlay, clipped to any shape. |
| **`LightAuraBloom.swift`** | Light mode bloom/glow effect. Aurora palette with breathing animation for atmospheric depth. |
| **`LightModeShimmer.swift`** | Light mode counterpart to `HolographicShimmer`. `AppColors.lightShimmerColors` at 7–11% opacity, 11s sweep cycle. |
| **`MazePatternView.swift`** | Concentric ring maze with gaps and spokes. Three rendering layers (groove shadow / main engraved line / highlight edge). Optional glow bloom for light mode. Embeds `TileOrbitView` at center via shared `GeometryReader` for co-centered orbit. |
| **`OnboardingGlowField.swift`** | Dark mode animated glow blob field for all onboarding screens. Self-managing animation state (7 blobs). |
| **`SparkField.swift`** | Canvas-based campfire ember particle system for light mode. Multiple screen-specific configs (`.statView`, `.nameView`, `.modeSelectView`, etc.). |
| **`TileOrbitView.swift`** | Canvas-based comet orbit animation for small tile contexts (44–88pt). Resting: static arc indicator(s). Active: `TimelineView`-driven comets with tail gradient, head glow, and color cycling (cyan→magenta→purple / warm aurora in light). 1, 2, or 3 orbits. Zero GPU cost in resting state. |

### `Input/`

| File | What It Does |
|---|---|
| **`InteractiveField.swift`** | Styled text field with emoji/icon prefix. Themed background and text color. |
| **`RatingButtonGroup.swift`** | 2x2 grid of rating buttons for the Desire Map. Bound to `DesireLevel?`. Haptic feedback. |
| **`ToggleRow.swift`** | Icon + label + Toggle row for Settings sections. |

### `Navigation/`

| File | What It Does |
|---|---|
| **`OnboardingFooter.swift`** | Small footer below the CTA ("Your data is encrypted..."). Adapts color to light/dark. |
| **`OnboardingNavBar.swift`** | Back chevron + centered `OnboardingProgressBar`. Back button gets a frosted circle in light mode. |

### `Progress/`

| File | What It Does |
|---|---|
| **`OnboardingProgressBar.swift`** | Highly refined animated progress bar for onboarding. Dual-mode (light/dark). Bloom glow, holographic shimmer fill, atmospheric gradient, breathing pulse. |
| **`OrbitIndicator.swift`** | Orbital animation progress indicator. Used in BuildingPath screen for processing animation. |
| **`ProgressBar.swift`** | Simple themed horizontal bar. `t.buttonGradient` fill on a muted track. |
| **`ProgressRingView.swift`** | Circular progress ring. Configurable line width and size. Track adapts to amoled/light. |
| **`ScoreRing.swift`** | Circular ring displaying a 0–100 score. Animates fill on appear via `t.ringGradient`. |
| **`SpectrumBar.swift`** | Thin capsule filled with `t.spectrumGradient`. Decorative separator/accent. |

### `Text/`

| File | What It Does |
|---|---|
| **`GradientText.swift`** | Static (non-animated) gradient text. Dark: pink→purple→magenta. Light: magentaDark→magenta→orangeHot. Lightweight alternative to `LivingText` for gradient labels that don't need shimmer. |
| **`KeywordHighlightText.swift`** | Renders text with specific keywords highlighted in cyan/magenta/gold via `NSAttributedString`. Used on prompt cards. |
| **`LivingText.swift`** | Animated gradient text with breathing glow. `TimelineView` at 30fps, RTL-aware, dual-mode. The animated text identity for the app. |

### Misc Components

| File | What It Does |
|---|---|
| **`CardStyle.swift`** | `ViewModifier`. Reusable card shell: background + rounded clip + border stroke. Replaces the repetitive 3-line pattern across views. |
| **`FilamentMode.swift`** | Mode enum and utilities for filament-style animations and effects. **❌ DEAD CODE** — `FilamentMode` and `FilamentPattern` enums are never referenced anywhere. Candidate for deletion. |
| **`NavArrow.swift`** | Reusable chevron navigation arrow component. |
| **`OrbitSparkBorderView.swift`** | Decorative border with orbital spark animation. |
| **`PillBorder.swift`** | `ViewModifier`. Holographic pill border: cyan→purple→magenta gradient stroke + glow overlay. Single source of truth for dark mode selected/active borders. |
| **`ScreenshotProtectionModifier.swift`** | Listens for screenshot/screen-recording notifications and overlays a blur + "Content Protected" message. Uses UIKit notification hooks. |
| **`SectionHeader.swift`** | All-caps muted label for section dividers. `AppFonts.sectionHeader` + `AppColors.textMuted`. |

---

## `Features/`

### `Auth/`

| File | What It Does |
|---|---|
| **`SignInView.swift`** | Sign in with Apple screen. Dark background, app name + tagline, Apple sign-in button. Uses `AuthService` via `@EnvironmentObject`. |

### `Compatibility/`

| File | What It Does |
|---|---|
| **`DesireMapView.swift`** | Desire map UI. Expandable category list where users privately rate intimacy items with `DesireLevel`. **⚠️ Placeholder data** — full persistence and partner reveal flow pending implementation. |

### `Explore/`

| File | What It Does |
|---|---|
| **`ExploreView.swift`** | Content discovery hub. **❌ STUB** — renders a label only. Not yet implemented. |

### `Home/`

| File | What It Does |
|---|---|
| **`HomeView.swift`** | Thin router. Switches on `appState.experienceType` → renders matching home view variant. Zero business logic. |
| **`HomeDashboardView.swift`** | Main home dashboard. Shows categories, progress, session history, and quick-start buttons. |
| **`HomeGateView.swift`** | Gate view for home. Handles loading state and permission checks. |
| **`HomeMatchReadyView.swift`** | Couple home variant. Shows partner readiness status and synchronized session invitations. |
| **`HomeRouterView.swift`** | Advanced router for complex home navigation flows. Handles deep linking and state restoration. |
| **`HomeWaitingView.swift`** | Waiting state view for pending partner acceptance or sync. |
| **`HomeViewSingle.swift`** | Home screen for solo users with no partner. |
| **`HomeViewSolo.swift`** | Home screen for solo users who have a partner. |
| **`HomeViewCoupleNew.swift`** | Home screen for couples new to ENM. |
| **`HomeViewCoupleExp.swift`** | Home screen for couples with existing ENM experience. |
| **`PostMapReflectionView.swift`** | Post-desire-map reflection screen. Synthesis of alignment data and relationship insights. |

#### `Home/Components/`

| File | What It Does |
|---|---|
| **`DesireMapIndicator.swift`** | Visual indicator showing desire map completion status. |
| **`PartnerChip.swift`** | Compact partner profile chip for couple views. Name, status, photo. |
| **`PickUpCard.swift`** | Quick-action card to resume or start a session. |
| **`ReflectionBannerView.swift`** | Banner prompting reflection after key moments. |
| **`ReflectionCard.swift`** | Card for structured reflection prompts. |
| **`ResearchTicker.swift`** | Scrolling research insights ticker. |
| **`SessionCard.swift`** | Card summarizing a past session. Category, duration, cards discussed. |

#### `Home/Models/`

| File | What It Does |
|---|---|
| **`HomeEventEngine.swift`** | Event orchestration for home screen state transitions and notifications. |
| **`HomeModels.swift`** | Data models for home screen views. Session summaries, category tiles, partner data. |

### `MeUs/`

| File | What It Does |
|---|---|
| **`MeUsView.swift`** | Personal profile + partner connection hub. Tab label adapts ("Me" for solo, "Us · Me" for couple). **❌ STUB** — not yet implemented. |

### `More/`

| File | What It Does |
|---|---|
| **`MoreView.swift`** | Settings / account / support hub. Also the sole visible screen for guest/browsing users. **❌ STUB** — placeholder only. |

### `Onboarding/Components/`

| File | What It Does |
|---|---|
| **`ContextCard.swift`** | Single card in the context-select stack. Dual-mode: light uses frosted ultraThinMaterial; dark uses intensity-keyed gradient. Embeds `TileOrbitView` as watermark. Breathing animation on confirm. *(Relocated from `Design/Components/Cards/`)* |
| **`ContextCardStack.swift`** | Gesture-driven infinite-scroll card stack. Swipe to browse, tap to confirm/unconfirm. Auto-advances 0.45s after selection. *(Relocated from `Design/Components/Cards/`)* |
| **`ContextIntensity.swift`** | Six intensity levels (ember → nova) mapping to visual properties: bg tint gradient, internal glow size/color/blur, border opacity, shadow color/radius. *(Relocated from `Design/Components/Cards/`)* |
| **`ContextOption.swift`** | Plain data model for one context card. Holds `RelationshipContext`, `ContextIntensity`, title, subtitle, detail. *(Relocated from `Design/Components/Cards/`)* |
| **`CuriosityPanelNudge.swift`** | Contextual nudge text shown below `CuriosityStatusStrip`. Guides user to complete both panels ("Select from both panels to continue" / "Swipe left — pick one more thing →" / "← Swipe back..."). |
| **`CuriosityPill.swift`** | Selectable pill for curiosity picker panels. Gradient checkmark icon on selection. Border and background adapt to `CuriosityOption.contentType` and selection state. Dark/light dual-mode. |
| **`CuriosityPreviewLine.swift`** | Italic preview text shown beneath a selected pill. Tells the user how their selection shapes their path. Subtle tinted background with matching border. |
| **`CuriosityStatusStrip.swift`** | Three-dot panel indicator + selection count label. Active dot shows `HolographicShimmer` / `LightModeShimmer` with glow. Animates width on panel change. |

### `Onboarding/Data/`

| File | What It Does |
|---|---|
| **`OnboardingData.swift`** | The single mutable data bag threaded through the entire onboarding flow. Holds name, pronouns, mode, relationship context, curiosity selections, experience level, ground rules timestamp, and completion flag. Now includes `nmCardResponse` for CardReveal pill selection. |
| **`CuriosityScreenConfig.swift`** | Config model driving `OnboardingCuriosityPickerView`. Two sections of labels, sublabels, option arrays, visibility flags. Derived from `OnboardingData`. |

### `Onboarding/Design/`

| File | What It Does |
|---|---|
| **`OnboardingAtmosphere.swift`** | Centralized atmosphere layer for all onboarding screens. Owns glow fields, spark fields, and transitions between atmosphere configs per screen. **New in this version.** |

### `Onboarding/Layout/`

| File | What It Does |
|---|---|
| **`OnboardingLayout.swift`** | Layout constants and utilities for onboarding screens. Screen-relative measurements, spacing, animation timings. **New in this version.** |

### `Onboarding/Views/`

| File | Screen | What It Does |
|---|---|---|
| **`OnboardingFlowView.swift`** | *Coordinator* | Flow coordinator. Defines the 8-step sequence, manages transitions via `advance()` with spring animations, derives `ExperienceType` on completion, writes to `AppState`, sets `hasCompletedOnboarding`. Passes `data: $onboardingData` to CardRevealView. |
| **`OnboardingStatView.swift`** | Screen 0 | Trust trigger. Large emotional statistic with animated holographic glow + tap-to-expand citation + ethos statement before CTA. |
| **`OnboardingBrandView.swift`** | Screen 0.5 | Animated brand reveal (auto-advance). Beam widths, opacities, wisp particles, center glow. Calls `onFinished` when complete. |
| **`OnboardingNameView.swift`** | Screen 1 | Name + pronouns entry. Glass-style text field, pronoun pill selector, custom pronoun field. Three-slot entrance cascade (ANIM-STD). |
| **`OnboardingModeSelectView.swift`** | Screen 2 | Solo vs. Couple mode + NM experience level (curious / exploring / experienced). Drives remainder of flow branching. (ANIM-STD-06–12) |
| **`OnboardingContextView.swift`** | Screen 3 | Relationship context picker. Solo: 3 cards. Couple: 4 cards. Uses `ContextCardStack`. Auto-advances after selection. (ANIM-STD-13–18) |
| **`OnboardingCuriosityPickerView.swift`** | Screen 4 | Two-section interest + intent picker. Config from `OnboardingData`. Uses `SelectablePill`. (ANIM-STD-19–26) |
| **`OnboardingBuildingPathView.swift`** | Screen 6 | Non-interactive "Building your path" processing animation. Derives `defaultDifficulty` from `nmStage`. Auto-advances. (ANIM-STD-27–30) |
| **`OnboardingCardRevealView.swift`** | Screen 6.5 | Card reveal with tap-to-flip mechanic. User flips card to reveal bridge prompt + 4 selectable pills. Idle animations (pulse, wiggle, skip text). Stores pill selection to `data.nmCardResponse`. Accepts `@Binding var data: OnboardingData`. |
| **`OnboardingGroundRulesView.swift`** | Screen 7 | Must-acknowledge ethical framing. 3 promise cards with flip animations + reassurance text. No back, no skip. Writes acceptance timestamp + completion flags, then calls `onFinished`. (ANIM-STD-31–36) |
| **`PairingForkView.swift`** | *(Couple fork)* | Couple-only decision: "Pair Now" (inline pairing) or "Pair Later" (skip to Settings). No data saving — closures only. |

---

## `Models/`

### `Models/Enums/`

| File | What It Does | Reach |
|---|---|---|
| **`AppEnums.swift`** | Master enum file. All shared domain enums: `CardType`, `Difficulty`, `Sensitivity`, `TurnOrder`, `CategoryType`, `CategoryPhase`, `AssessmentDomain`, `DesireLevel`, `DesireAlignment`, `RelationshipContext`, `ExplorationMode`, `NMStage`, `PronounOption`, `RelationshipStatus`, `NMFlavor`, `CardStatus`, `PromptCategory`, `PromptDifficulty`, `WhoStarts`. | **`FOUNDATION`** |
| **`AppTab.swift`** | Four tab cases: `home`, `meUs`, `explore`, `more`. `Hashable` for `TabView` selection. | |
| **`ExperienceType.swift`** | Five experience modes: `browsing`, `soloSingle`, `soloPartnered`, `coupleNew`, `coupleExperienced`. Drives all home-screen routing. `CaseIterable`, `Codable`. | **`BACKBONE`** |

### `Models/Content/` *(read-only, decoded from bundled JSON)*

| File | What It Does |
|---|---|
| **`ContentAssessmentQuestion.swift`** | One of 20 assessment questions (5 domains x 4). Types: scale (1–5 Likert) or multi-select. Answers live in `AssessmentResponse`, not here. |
| **`ContentCard.swift`** | Read-only content model for a conversation card within a category. Per-card progress tracked separately in `CardProgress`. |
| **`ContentCategory.swift`** | One of the 6 topic categories. Progress tracking lives in SwiftData, not here. |
| **`ContentDesireItem.swift`** | One item on the Desire Map. "Not For Me" ratings are never revealed to partners — alignment engine returns `.boundary`. |
| **`Prompt.swift`** | Prompt card model for `SessionView`. Text, highlight words, category, difficulty, sensitivity flags, `canSkip`, `whoStarts`. Includes static sample data. |

### `Models/Persistence/` *(SwiftData `@Model` classes — local-first)*

| File | What It Does |
|---|---|
| **`RatingRecord.swift`** | One record per prompt shown in a session. Owned by `SessionRecord` via cascade. Stores prompt text, reaction, timestamp. |
| **`SessionRecord.swift`** | One row per completed or safe-worded session. Category, difficulty, duration, prompts shown, completion flag, date. |
| **`StreakRecord.swift`** | Singleton record. Tracks `currentStreak`, `longestStreak`, `totalSessions`, `lastSessionDate`. Updated by `DataStore`. |

### `Models/Progress/` *(SwiftData `@Model` classes — synced to Supabase)*

| File | What It Does |
|---|---|
| **`AssessmentResponse.swift`** | One user's answer to one assessment question. Scale value or selected option IDs, computed score, timestamp. Owned by `UserProfile`. |
| **`AssessmentResult.swift`** | Overall assessment result. Per-domain scores (string-keyed dict), composite weighted score, readiness band. Owned by `UserProfile`. |
| **`CardProgress.swift`** | Couple-level per-card progress: discussed/skipped/bookmarked, timestamps, notes. Owned by `Couple` via cascade. |
| **`Couple.swift`** | Links two `UserProfile`s as partners. Owns `CardProgress` + `CoupleSessionRecord` via cascade. Deleting a `Couple` does NOT delete the profiles. |
| **`CoupleSessionRecord.swift`** | One couple session record. Cards discussed/skipped, timing, metadata. Owned by `Couple`. |
| **`DesireMatch.swift`** | Positive desire alignment between two partners on a specific item. Only created when alignment is positive. Owned by `Couple`. |
| **`DesireRating.swift`** | One person's private rating of one desire map item. Never exposed to partner — used only to compute `DesireMatch`. Owned by `UserProfile`. |
| **`UserProfile.swift`** | Full user profile. Name, pronouns, orientation, mode, experience level, `NMFlavor`, curiosity selections. Owns `AssessmentResponse`, `AssessmentResult`, `DesireRating` collections. |

---

## File Count by Directory

| Directory | Files |
|---|---|
| `App/` | 2 |
| `App/Theme/` | 5 |
| `Core/Services/` | 11 |
| `Data/Store/` | 2 |
| `Design/Components/` | ~47 |
| `Design/Components/Banners/` | 1 |
| `Design/Components/Buttons/` | 5 |
| `Design/Components/Cards/` | 15 |
| `Design/Components/Effects/` | 13 |
| `Design/Components/Input/` | 3 |
| `Design/Components/Navigation/` | 2 |
| `Design/Components/Progress/` | 6 |
| `Design/Components/Text/` | 3 |
| `Design/Components/Misc/` | 7 |
| `Features/Auth/` | 1 |
| `Features/Compatibility/` | 1 |
| `Features/Explore/` | 1 |
| `Features/Home/` | 10 |
| `Features/Home/Components/` | 7 |
| `Features/Home/Models/` | 2 |
| `Features/MeUs/` | 1 |
| `Features/More/` | 1 |
| `Features/Onboarding/` | ~28 |
| `Features/Onboarding/Components/` | 8 |
| `Features/Onboarding/Data/` | 2 |
| `Features/Onboarding/Design/` | 1 |
| `Features/Onboarding/Layout/` | 1 |
| `Features/Onboarding/Views/` | 11 |
| `Features/Progress/` | 1 |
| `Features/Sessions/` | 1 |
| `Features/Settings/` | 3 |
| `Models/Content/` | 5 |
| `Models/Enums/` | 3 |
| `Models/Persistence/` | 3 |
| `Models/Progress/` | 8 |
| `Resources/` | 1 (Documentation) |
| **Total** | **~160** |

*Note: Count reflects consolidation from old `Card/` to `Cards/` (plural) directory in this redesign cycle. Some components may be nested across multiple files.*

---

## Recent Changes (This Session)

- **OnboardingFlowView.swift**: Restored to clean ANIM-STD state; pass `data: $onboardingData` to CardRevealView (cardReveal case line 135)
- **OnboardingCardRevealView.swift**: Accepts `@Binding var data: OnboardingData`; EncouragementView body simplified to single Text
- **OnboardingBuildingPathView.swift**: Fixed BPFloatingFragment scope (moved from nested in BPOrbitCanvas to top-level private struct)
- **OnboardingGroundRulesView.swift**: Removed baseBackground/glowOverlay/sparkOverlay; background now uses Color.clear + atmosphereLayer; previews wrapped in ZStack with AppColors background + OnboardingAtmosphere
- **File reorganization**: Moved Cards from `Design/Components/Card/` to `Design/Components/Cards/` (note plural); deleted old `Card/` directory
- **Context components relocated**: `ContextCard`, `ContextCardStack`, `ContextIntensity`, `ContextOption` moved from `Design/Components/Cards/` → `Features/Onboarding/Components/`
- **New card infrastructure**: `CardLayout`, `CardBackView`, `CardFrontView`, `CardRevealPillButton`, `CardShadows` added to `Design/Components/Cards/`
- **New flip cards**: `CuriosityCardBack` + `CuriosityFlipCard` added to `Design/Components/Cards/`
- **New effects**: `FloatingCard`, `FloatingStack`, `MazePatternView`, `TileOrbitView` added to `Design/Components/Effects/`
- **New text component**: `GradientText` added to `Design/Components/Text/`
- **New onboarding components**: `CuriosityPill`, `CuriosityPanelNudge`, `CuriosityPreviewLine`, `CuriosityStatusStrip` added to `Features/Onboarding/Components/`

---

## Dead Code & Maintenance Inventory

### 🚨 Critical Issues

| Item | File | Details | Impact |
|---|---|---|---|
| **Exposed API Keys** | `Config.swift:2-3` | Supabase URL + anon key hardcoded in source code (committed to git). Should be in xcconfig or environment. | **SECURITY**: Credentials visible in version control. |
| **SessionView God Object** | `Features/Sessions/SessionView.swift:4-50` | Manages session state, UI presentation, timing, card advancement, progress tracking, and persistence all in one view. 50+ lines of logic. | **MAINTAINABILITY**: Hard to test, difficult to extend, state changes scattered. |
| **UserDefaults Key Inconsistency** | `SyncManager.swift` vs `AppState.swift` | SyncManager uses hardcoded strings (`"supabaseProfileId"`, `"pendingProfileSync"`); AppState uses `PersistenceKey` enum. No shared key management. | **MAINTAINABILITY**: Inconsistent patterns, key duplication, hard to refactor. |
| **ContentLoader.swift Fatal Error** | `Core/Services/ContentLoader.swift` | Uses `fatalError` on JSON parse failure. A typo in bundled JSON crashes the app in production. | **RELIABILITY**: No graceful fallback; bundle errors are unrecoverable. |

### 🗑️ Dead Code to Remove

| Item | File | Lines | Action |
|---|---|---|---|
| **FilamentMode** | `FilamentMode.swift` | Entire file | No references. Delete. |
| **10 Unused Colors** | `AppColors.swift` | 10 tokens | `purpleBright`, `electricViolet`, `cyanDark`, `deepPurple`, `surfaceRaised`, `textQuaternary`, `btnGhostBorder`, `btnGhostText`, `badgeBg`, `destructive` — remove. |

### ⚠️ Code Quality Issues

| Item | File | Action |
|---|---|---|
| **Nested SupabaseProfile** | `ProfileService.swift` | Extract to `Models/ProfileService/SupabaseProfile.swift` for cross-service visibility. |
| **Unused CTABorderModifier** | `HoloCTAButton.swift:165-176` | Either refactor to use it or remove. |
| **Limited GradBadge Usage** | `GradientButton.swift:45-59` | Used only in 2 files (`DesireMapView`, `ThemeTestView`). Deprecate or move to test utilities. |
| **Duplicate Header Comments** | `SyncManager.swift`, `ProfileService.swift` | Both files have header comment blocks appearing twice. Remove the duplicates. |

### 🔧 Magic Numbers & Missing Constants

| Item | Files Affected | Fix |
|---|---|---|
| **Animation Durations** | ContextCard, ConversationCard, ContextCardStack, SessionView (7+ instances) | Extract to `Animation.cardTransition` and similar constants. |
| **Corner Radius `20`** | ContextCard, ConversationCard, SessionView, CardStyle (4+ instances) | Define `DesignTokens.cardCornerRadius = 20`. |
| **Padding `28`** | ContextCard, ConversationCard (3+ instances) | Define `DesignTokens.cardPadding = 28`. |
| **Light Mode Shadow Spread** | ContextCard:157-159, SelectablePill:334-339 | Extract to `.lightGlowShadows()` modifier. |
| **Dark/Light Border Logic** | SelectablePill, ContextCard, HoloCTAButton | Create `ThemedBorderModifier`. |
| **Blob Timing Arrays** | `AuroraGlowField.swift:270-273` | Extract to named `BlobTimingConfig` struct. |

### 📊 Naming Issues

| Item | File | Fix |
|---|---|---|
| **Boolean Naming** | `UserProfile.swift:39-40` | `mythBusterComplete` → `hasMythBusterCompleted`; `mythBusterSkipped` → `isMythBusterSkipped`. |
| **Vague Parameters** | `ContextCard.swift:7-8` | `index: Int` → `cardIndex: Int`; `total: Int` → `totalCards: Int`. |
| **Single-Letter Theme Var** | `ProgressRingView`, `ContextCard` | `@Environment(\.theme) private var t` → use `palette`. |
| **Abbreviated NM** | `AppEnums.swift` | Document or standardize `nmLogistics` / `NM` usage. |

---

## Key Architectural Notes

- **Onboarding Atmosphere**: Centralized in `OnboardingAtmosphere.swift` (Design/) for all screens; config-driven per-screen transitions
- **Home Expansion**: Home directory grew significantly with `HomeDashboardView`, component library, and event engine for complex state management
- **Card System Consolidation**: New unified card rendering system in `Design/Components/Cards/` for both conversation and context cards
- **ANIM-STD Protocol**: All onboarding screens now use standardized entrance animations (three-slot cascade: slot A @ 0ms, slot B @ 100ms, slot C @ 200ms) with reduce-motion fallback
- **Desire Map Architecture**: Still using private-first model; `DesireRating` never exposed to partners; alignment computed server-side via `DesireMatch`

---

## Design System Gaps (Missing Constants)

The codebase lacks centralized constants for spacing, sizing, and animations. These are currently scattered as magic numbers:

| Category | Current State | Recommended Constant |
|---|---|---|
| **Card Corner Radius** | `20` hardcoded in 4+ files | `DesignTokens.cardCornerRadius = 20` |
| **Card Padding** | `28` hardcoded in 3+ files | `DesignTokens.cardPadding = 28` |
| **Button Height** | Explicit in `HoloCTAButton` (56), implicit/padding-based in others | `DesignTokens.buttonHeight = 56` |
| **Line Width (borders)** | 1.5–3.0 depending on context | `DesignTokens.borderStandard = 1.5`, `.strong = 2.5`, `.cta = 3.0` |
| **Card Transition Duration** | 0.25–0.4s scattered across files | `Animation.cardTransition` constant |
| **Spring Animation** | `spring(response: 0.4, dampingFraction: 0.75/0.7)` used 7+ times | `Animation.cardSpring`, `Animation.pillSpring` |
| **Light Mode Shadows** | Triple-shadow block (magenta/purple/gold) copied in 2 files | `.lightGlowShadows()` ViewModifier |
| **Dark/Light Border Logic** | Conditional repeated in 3+ files | `ThemedBorderModifier` struct |

**Action**: Create a `DesignTokens` enum (or split into `Spacing`, `Sizing`, `Animation`) to centralize these values.

```

---

## File: `PROJECT_SCOPE.md` {#file-project-scope-md}

```markdown
# Open Lightly — Project Scope
**Last Updated:** March 31, 2026 (home redesign, onboarding polish, design system expansion, CuriosityPickerView layout fixes)
**Developer:** Bryan Jorden
**Platform:** iOS 26 (SwiftUI, SwiftData, Supabase)

---

## 1. What Is Open Lightly

Open Lightly is a privacy-first iOS app built for couples navigating the gap between "we're curious about non-monogamy" and "we've had the conversations and know where we stand." At launch, it is a focused tool for one thing done extremely well: helping new NM couples have the conversations they've been putting off.

**Launch identity — Act 1:**
> *"The tool couples have been looking for since the first conversation they couldn't finish."*

The core product: guided conversation card decks and a mutual Desire Map reveal. Both partners complete the Desire Map independently; one matched item surfaces free; the full compatibility picture is behind the paywall. That moment — *your first glimpse of what you actually have in common* — is the conversion event.

**Core premise:** Conversations that would be awkward to start become natural when framed as a game.

**What this app is NOT:** See Section 4 — Moral Red Line.

### The Three-Act Reveal

This is not a pivot sequence. It is a reveal sequence. The product expands in a way that feels inevitable to users rather than scattered.

| Act | When | Who | Tagline |
|-----|------|-----|---------|
| **Act 1** | Launch | New NM couples | *"The tool couples have been looking for since the first conversation they couldn't finish."* |
| **Act 2** | V1.1 | Experienced ENM practitioners | *"For people doing non-monogamy intentionally."* |
| **Act 3** | V1.2+ | Solo explorers | *"For people who take relationships seriously. All kinds of relationships."* |

The Act 3 tagline is the destination. Every architecture decision now should allow the product to arrive there without a rewrite. The architecture supports all three user types from day one — what changes at each act is the marketing focus, not the codebase.

### How It Works

```
PAIR    → QR scan (in person), verbal code (same room), or share link (remote)
ASSESS  → Each partner privately answers 20 questions
REVEAL  → Sit together, see combined Readiness Score
EXPLORE → Work through guided conversation cards by category
MAP     → Privately rate 40+ intimacy items — one match revealed free, full reveal behind paywall
DECIDE  → Informed decision based on mutual understanding
```

Over time, logged check-ins, reflections, and emotional data compound into a personal relationship intelligence layer — the app gets more valuable the longer someone uses it.

---

## 2. Target Users — Three Acts, One Architecture

Open Lightly serves all four relationship populations from day one. The architecture supports everyone; the marketing reveal is sequential. Each act has a primary user, a pain point, and a clear build priority.

### Act 1 — Primary User at Launch: The New NM Couple

**Who:** Two people in a committed relationship, curious about ENM, haven't fully navigated the conversation yet. Usually one partner initiated. Ages 25–40.

**Primary pain:** "We tried to talk about it and it went sideways. We don't know how to start without it feeling like an accusation."

**What they need:** Structure that makes hard conversations feel like a game, not a fight. A mutual reveal that gives both partners a safe way to say what they want without having to say it directly first.

**Build priority:** Build for them first. Market to them exclusively at launch. Every Act 1 decision is a front-door decision.

### Act 2 — Secondary User (Present at Launch, Not Marketed): The Experienced ENM Practitioner

**Who:** Couples actively practicing ENM — swinging, polyamory, relationship anarchy, any flavor. They know the landscape. They're downloading because a friend recommended it or they saw a review.

**Primary pain:** "We've been doing this for years with no operational infrastructure. We've built our own systems from scratch, most of which are informal and inconsistent."

**What they discover:** Daily pulse, jealousy mapping, agreements vault, connection cards. The "aha" is: *this isn't just for people figuring it out — it's for people living it.*

**Build priority:** Tools present in architecture and discoverable. Not marketed until V1.1 Act 2 expansion.

### Act 3 — Secondary User (Routing Exists, Not Marketed): The Solo Explorer

**Who:** Singles, solo poly people, people navigating ENM without a primary partner. They belong here — they've always belonged here. The product now explicitly invites them.

**Primary pain:** "Every ENM resource assumes I have a partner to do this work with. I'm doing it alone."

**What they discover:** The app was never about having a partner. It was always about doing the work of non-monogamy intentionally. Solo users were always going to belong here.

**Build priority:** Solo path fully routed in architecture. Not marketed at launch. Front-door marketing shift happens at V1.2.

### Persona Tags (internal, never shown to user)

Each person must feel like the app was built for them specifically. The persona filter (set at onboarding via `nmStage`) routes them to a personalized roadmap, tailored prompt voice, and curated education — all from one shared content library.

### Persona Tags (internal, never shown to user)

| Selection | Tag | App Experience |
|-----------|-----|---------------|
| Solo + Curious | `solo-curious` | Self-discovery → preparation → "How to find & start an NM relationship" |
| Solo + Experienced | `solo-experienced` | Self-maintenance → advanced tools → community navigation |
| Coupled + Curious | `coupled-curious` | Graduated exposure roadmap → first experiences |
| Coupled + Experienced | `coupled-experienced` | Communication tune-ups → advanced scenarios → repair tools |

### Tone Shift Between Populations

| Element | Curious Tone | Experienced Tone |
|---------|-------------|-----------------|
| Vocabulary | Plain language, define everything | Community language, no hand-holding |
| Pacing | Slow, gentle, "it's okay" | Direct, efficient, respects their time |
| Assumed knowledge | Zero | Full |
| Emotional register | Warm, reassuring, validating | Honest, challenging, growth-oriented |
| Prompt complexity | One question at a time | Multi-layered, asks for nuance |
| Example | "What's one thing about NM that excites you? Just one." | "What pattern keeps showing up that you haven't fully addressed?" |

If a curious user sees experienced content → overwhelmed, unready. If an experienced user sees curious content → patronized, deletes the app. **The persona filter is the difference between "this app gets me" and "this app isn't for me."**

### Solo ↔ Coupled Transition

When a solo user finds a partner:
- Solo journal entries are NEVER shared (privacy is sacred)
- Shared journey starts fresh
- Solo stages completed inform where the coupled roadmap begins (skip already-done self-work)

---

## 3. The Problem We Solve


The #1 problem isn't jealousy. It's that people don't know how to START. The gap between curiosity and first conversation is where most NM journeys die.

### The 9 Pain Points (in customer journey order)

| # | Problem | Who | Urgency | What They'd Pay |
|---|---------|-----|---------|-----------------|
| 1 | "I can't even start the conversation" | Solo curious | Critical | $30–60 |
| 2 | "We tried to talk about it and it went badly" | Coupled curious | Critical | $40–60 |
| 3 | "I don't know what I actually want" | All curious | High | $25–40 |
| 4 | "We can't set boundaries that work" | Coupled (all stages) | Critical | $40–60 |
| 5 | "Jealousy is eating me alive" | All practitioners | Critical | $25–50 |
| 6 | "Something went wrong — crisis" | Coupled, active | Critical | $50+ |
| 7 | "I can't find a therapist who gets this" | Everyone | High | $40–60 |
| 8 | "I don't know anyone else who does this" | Everyone, esp. new | Moderate | $20–30 |
| 9 | "We've been doing this for years and we're stuck" | Experienced | Moderate | $40–60 |

### Why Existing Solutions Fail

- **Books/podcasts** — Information overload, consumed solo, no partner involvement
- **Reddit** — Contradictory crowd-sourced advice, no structure
- **Therapy** — $150–300/session, 2–6 week waitlists, most therapists aren't NM-informed and some actively pathologize it
- **"Just be honest"** — Radical honesty without structure = emotional flooding
- **Winging it** — How boundary violations happen. Not because people are bad, but because they never agreed on where the lines were.

### What the Market Actually Wants

1. **Structure over information** — They're drowning in content. They need a PROCESS for turning it into conversations.
2. **Partner involvement** — Every resource is single-player. NM is a two-person journey. Mutual reveal mechanics are the product-market fit.
3. **Normalization over pathologization** — They don't want clinical language. They want to feel like this is a legitimate, navigable life choice.
4. **Accessibility over expertise** — 70% of what a good NM therapist provides, available tonight, for the price of a book.
5. **Privacy over community** — Most NM-curious people want a PRIVATE space to figure this out first.

---

## 3.5. V1.0 Feature Set

Features are organized by act ownership. Act 1 features are front-door — marketed, prioritized, and polished first. Act 2 features ship at V1.0 but are discovered, not marketed. Act 3 features ship in architecture and routing only at V1.0; marketing focus shifts at V1.2.

### The Desire Map: Primary Conversion Architecture

The Desire Map mutual reveal is not a feature gate. It is the revenue mechanic.

1. **Both partners complete the Desire Map independently** — 17 items, ~4.5 minutes, fully private. Neither sees the other's ratings.
2. **One matched item is revealed free** — the instant personalized result. The first glimpse of what they actually agree on creates the demand the paywall fulfills.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product. The free match is the proof it works.

This is "instant personalized result → paywall on that result." The mechanic works because the result is real, immediate, and deeply personal. It cannot be replicated by any other app because it requires both partners to have already completed the assessment.

### Feature Matrix

| Feature | Act | V1.0 Ships | Notes |
|---------|-----|-----------|-------|
| Onboarding flow — all three paths | 1/2/3 | ✅ | All routes present; Act 1 path marketed at launch |
| Conversation card decks (Coupled Curious) | 1 | ✅ | Core product, front-door |
| Desire Map — 17 items, mutual private rating | 1 | ✅ | Primary conversion moment |
| Desire Map — 1 free match reveal | 1 | ✅ | Free tier hook |
| Desire Map — full reveal | 1 | ✅ | Behind paywall |
| Readiness Assessment | 1 | ✅ | Front-door |
| Partner pairing (QR, code, link) | 1 | ✅ | Front-door |
| CardReveal screen (replaces solo reflection gate) | 1/2/3 | ✅ | Universal — every user sees this. Pill selection feeds archetype routing. Scraps the separate post-onboarding reflection gate entirely. |
| Graduated exposure roadmap (Coupled Curious) | 1 | ✅ | Front-door |
| Home dashboard + Today view | 1 | ✅ | Front-door |
| Safe word (always accessible) | 1 | ✅ | Front-door |
| Screenshot protection | 1 | ✅ | Front-door |
| Drop Box — AI message translation (100 msgs) | 1 | ✅ | Communication Pack |
| Coupled Experienced roadmap | 2 | ✅ | Present, not marketed at launch |
| Advanced scenario cards | 2 | ✅ | Present, not marketed at launch |
| Agreement foundation prompts | 2 | ✅ | Present, not marketed at launch |
| Solo Curious roadmap | 3 | ✅ | Architecture present, not marketed |
| Solo Experienced roadmap | 3 | ✅ | Architecture present, not marketed |
| Bridge cards (solo user with partner) | 3 | ✅ | Architecture present, not marketed |
| Connection Cards / Partner Roster | 2 | V1.1 | Infrastructure for pulse, vault, check-ins |
| Daily Relationship Pulse | 2 | V1.1 | 30-second daily habit; data compounds retention |
| Insight Engine — pattern surfacing | 2 | V1.1 | Needs logged data to work |
| Emotional Texture Calendar | 2 | V1.1 | Needs pulse data |
| Jealousy Mapping | 2 | V1.2 | Dedicated in-the-moment tool |
| Agreements Vault | 2 | V1.2 | Requires connection roster first |
| Anonymous Community Feed | 2/3 | V1.5 | Moderation cost too high pre-scale |
| Your Year, Lightly | 2/3 | V2.0 | Needs 6+ months of active logged data |

---

## 4. Moral Red Line

**This app is not therapy. This is non-negotiable.**

Open Lightly is a communication tool and an educational resource. It facilitates structured conversations between partners. It provides research-backed frameworks for exploring difficult topics. It does NOT diagnose, treat, or replace professional mental health care.

As a future therapist building this product: no dollar is worth an ethical violation. The moment this app crosses from "guided conversation tool" into "therapy substitute," it causes harm — to users who deserve real clinical care, and to the credibility of the therapeutic profession.

### What This Means in Practice

**The app WILL:**
- Frame itself as a conversation tool, not a clinician
- Surface crisis resources (988, Crisis Text Line, National DV Hotline) when language suggests distress
- Include "Find a Therapist" resources with NM-informed directories
- State on Ground Rules screen: "We're not a therapist. If things get heavy, we'll point you to people who can help."
- Position AI features as communication SKILLS education, never clinical interpretation

**The app will NEVER:**
- Diagnose relationship patterns ("this is stonewalling," "this is anxious attachment")
- Use clinical terminology in user-facing output (no Gottman labels, no attachment framework language)
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Compare partners ("Partner A communicates better than Partner B")
- Provide unsolicited feedback on communication quality
- Frame NM as something that needs to be "fixed" or "managed"
- Replace the recommendation to seek professional help when situations exceed the app's scope

> **New features boundary:** Jealousy Mapping logs feelings, not diagnoses. Compersion Tracker celebrates moments, not prescribes them. The Insight Engine surfaces observations ("You tend to feel X after Y"), never evaluations ("Your jealousy is getting worse"). Pattern data is a mirror. The user draws their own conclusions.

### The Line Between Education and Therapy

| Education (we do this) | Therapy (we never do this) |
|------------------------|---------------------------|
| "Here's another way to express that" | "You're using criticism, a predictor of divorce" |
| "Many couples find it helpful to..." | "Based on your pattern, you should..." |
| "Research suggests that direct requests..." | "Your communication style indicates..." |
| Offer alternative phrasings, user chooses | Prescribe interventions |
| Cite communication principles | Apply clinical frameworks to user behavior |

### The Three Rules

**Rule 1: Facilitate, Never Diagnose**
- Wrong: "Based on your responses, you have an anxious attachment style."
- Right: "You mentioned feeling worried when your partner is distant. What does that worry need?"
- The first is a clinical judgment. The second is a mirror. The user draws their own conclusion.

**Rule 2: Open Doors, Never Push Through Them**
- Wrong: "It's important that you confront your jealousy. Let's work through it."
- Right: "Jealousy showed up. Want to explore what it's telling you? [Yes] [Not tonight]"
- A therapist can push — they have informed consent, a treatment plan, malpractice insurance. We have none of those. The app offers the door. The user decides.

**Rule 3: Credit the User, Not the Tool**
- Wrong: "Our evidence-based approach helped you identify your core needs."
- Right: "You just named something important."
- The app showed up with the right question at the right time. The user did the work.

### Language Guide

| Therapeutic language (avoid) | Companion language (use) |
|------------------------------|--------------------------|
| "Your assessment indicates..." | "You mentioned..." |
| "Let's work on..." | "Want to explore..." |
| "This exercise will help you..." | "Some people find it useful to..." |
| "You should discuss this with your partner" | "If this feels worth sharing, you'll know when" |
| "Processing your trauma" | "Sitting with what came up" |
| "Treatment plan" | "Your path" |
| "Session goals" | "Tonight's intention" |

### The Bar Conversation Test

Every card should pass this: Could a really wise, well-read friend say this to you over a drink without it feeling clinical?
- ✅ "What's one thing you want that you haven't said out loud yet?"
- ❌ "Identify an unmet relational need and articulate it to your partner."
- ✅ "When jealousy shows up, where do you feel it in your body?"
- ❌ "Describe the somatic manifestation of your jealousy response."

Same insight. Same evidence base. Completely different relationship with the user.

### Using Clinical Frameworks Without Crossing the Line

The app draws on Gottman, attachment theory, CBT, NVC, EFT, and motivational interviewing. The difference is framing:

| Framework | What a therapist does | What this app does |
|-----------|----------------------|-------------------|
| Gottman's Four Horsemen | Diagnoses communication dysfunction, assigns treatment plan | Card: "Notice when you're criticizing vs. complaining. What's the difference feel like?" |
| Attachment theory | Assesses attachment style, restructures interaction patterns | Reflection: "When your partner pulls away, what's the first thing you feel?" |
| CBT restructuring | Identifies and challenges distorted thought patterns | Card: "The story I'm telling myself about this is ___. What's another version?" |
| EFT | Guides couples through de-escalation cycles | Prompt sequence: surface reaction → underlying emotion → need → request |
| Motivational interviewing | Strategic questioning to move through stages of change | Card phrasing mirrors MI — open questions, affirmations, reflective framing |
| Expressive writing (Pennebaker) | Prescribed journaling for trauma processing | Free-text reflection with "Only you see this" |

Same intellectual DNA. Completely different claim.

### Where the Line Gets Tested

| Scenario | What therapy does | What this app does |
|----------|------------------|-------------------|
| Suicidal ideation in a reflection | Clinician assesses risk, activates safety protocol | Surface crisis resources immediately. Don't try to help. Route to professionals. |
| Partner describes abuse | Clinician reports, creates safety plan | Surface DV hotline. Don't counsel. Don't notify the partner. |
| User in distress after a session | Clinician de-escalates, extends session | "That was heavy. You don't have to carry this alone." + therapist finder + grounding exercise |
| Couple in active conflict during session | Therapist mediates | Card design avoids inflammatory prompts at low depth levels. The depth slider is the safety valve. |

**The rule: when it gets clinical, get out of the way and point to clinicians.** The app handles the 95% of moments where two curious people want a better conversation. The 5% where real crisis shows up is not our jurisdiction.

### Crisis Detection

Keyword-based detection (not ML). If solo reflection or session text contains crisis language:
- Surface resources immediately (988, Crisis Text Line, National DV Hotline)
- Non-blocking — resources shown, user continues at their discretion
- Always accessible in Settings → Get Support
- False positives are acceptable. Missing someone who needs help is not.

### The Philosophical Frame

This app is closer to a **really good book of questions** than it is to therapy. Think Esther Perel's card games, The School of Life conversation cards, the 36 Questions to Fall in Love. All draw on deep psychological research. None are therapy.

- A **book of questions** assumes two capable adults who want to grow.
- **Therapy** assumes something is broken and someone trained needs to help fix it.

This app assumes the first. It says: "You're not broken. You're exploring. Here are better questions than the ones you've been asking yourselves."

### Positioning

> "We're not therapy. We're what you use when you can't find a therapist who gets it — or between sessions with one who does."

### Legal Disclaimer (accessible but not obnoxious)

> "[App name] is a conversation companion, not a therapist. It's informed by relationship science and designed to help you explore — but it's not a substitute for professional support. If you're in crisis or experiencing abuse, please reach out to [resources]."

Present in: App Store listing, Settings → About, Onboarding Ground Rules. One line. Not a wall of legal text.

---

## 5. AI Ethics & Communication Coaching

### Guiding Principle

> "We don't tell you what you said wrong. We show you other ways you could say what you meant."

### AI Can / Cannot

✅ **AI CAN:**
- Identify linguistic patterns (you-statements, absolutes, questions vs. statements)
- Offer alternative phrasings (not interpretations)
- Show speaking time balance
- Highlight questions asked (encourages curiosity)
- Note moments of agreement/alignment
- Translate messages in the Drop Box (anonymous, non-judgmental rephrasing)

❌ **AI CANNOT:**
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Diagnose patterns ("this is stonewalling")
- Apply clinical frameworks in output
- Provide unsolicited feedback
- Show one partner's analysis without the other present
- Train on users' private conversations

### AI Implementation Levels

| Level | What It Actually Is | Difficulty | Cost | When |
|-------|-------------------|-----------|------|------|
| **1. System Prompt** | GPT-4o/Claude with a detailed role prompt + user context injection (assessment data, desire map, session history). Not retrained — role-playing well. | Easy | ~$20/mo API | Launch (Drop Box) |
| **2. RAG** | Source material (NM books, NVC, Gottman research, your content) chunked into embeddings, stored in vector DB. User question → semantic search → relevant chunks injected as context → grounded response. | Medium | ~$50–100/mo | Month 4–6 (AI Coach) |
| **3. Fine-Tuning** | Retrain a model on hundreds of example conversations in your voice/tone. Learns your specific framing. | Medium-Hard | $500–2K training | Month 12+ (if enough data) |
| **4. From Scratch** | Don't. OpenAI and Anthropic spent the billions. Stand on their shoulders. | — | — | Never |

**RAG tech stack:**

| Component | Tool | Cost |
|-----------|------|------|
| LLM | OpenAI GPT-4o or Claude | ~$0.01–0.05/turn |
| Vector DB | Supabase pgvector (already in stack) | Free tier |
| Embedding | OpenAI text-embedding-3-small | Pennies |
| Orchestration | LangChain or LlamaIndex | Free (open source) |

**AI Coach feature map:**

| Feature | What It Does |
|---------|-------------|
| Ask the Coach | Freeform chat for questions that don't fit prompts. Context-aware via assessment + desire map data. |
| Jealousy First Aid | Real-time CBT reframing: identify thought → examine evidence → find distortion → reframe → action plan. Personalized to their archetype, attachment signals, and agreements. |
| Post-Conversation Processing | "We just had a hard conversation. Help us make sense of it." |
| Scenario Expansion | After a hypothetical, "What if [variation]?" — AI generates new angles dynamically. |
| Assessment Interpreter | "What does our score actually mean for [specific situation]?" |
| Drop Box Translation | Anonymous AI rephrasing: say what you mean without the loaded language. |

**AI implementation phases:**

| Phase | When | What | Method |
|-------|------|------|--------|
| Launch | Day 1 | Drop Box (100 AI translations) | Level 1 — system prompt |
| Month 4–6 | AI Coach v1 | Ask the Coach + Jealousy First Aid | Level 1 with context injection |
| Month 7–9 | AI Coach v2 | RAG upgrade — responses grounded in curated NM content | Level 2 |
| Month 12+ | Voice refinement | Fine-tune on anonymized Drop Box patterns | Level 3 (if data exists) |

### Communication Coaching Models (Late Feature — Batch 24+)

| Model | What It Is | When |
|-------|-----------|------|
| **Pattern Library** | Browsable library of common communication patterns with research-backed alternatives. No recording, no surveillance. Users self-identify. | Batch 24–26 |
| **Post-Conversation Replay** | Couple opts in to record a session. Together, they tap any line to see alternative phrasings. No judgment on which is "better." | Batch 29+ |
| **Hybrid Analysis** | Linguistic structure analysis (not emotional/clinical). Alternatives sourced from NVC, Gottman soft startup research, active listening frameworks. | Batch 30+ |

### Consent Architecture (for recording features)

- Opt-in PER SESSION (not global)
- BOTH partners must consent (double opt-in)
- Either partner can delete at any time
- On-device processing or E2E encrypted
- Clear disclosure before recording begins

### Transparency

Public documentation of:
1. What we analyze (linguistic structure, speaking balance, conversational flow)
2. What we don't analyze (emotional tone, who's "right," clinical categories)
3. Where alternatives come from (NVC, Gottman published research, active listening frameworks)
4. Every suggestion has a "This doesn't fit" button
5. Model never trains on private conversations

---

## 6. Psychology & Emotional Design

### Shame Reduction Architecture

Every design decision passes through: "Does this reduce shame or increase it?"

- **Onboarding stat screen** ("1 in 5 Americans") — normalizes before asking anything personal
- **"No judgment on any answer"** — explicit on relationship status screen (the partnered_hidden option carries shame)
- **Skip is always real** — no guilt copy, no "Are you sure?", no re-prompting
- **Jealousy is data, not failure** — reframed as information about unmet needs, not proof something is wrong
- **Every outcome is valid** — including "We explored this and decided it's not for us"

### Desire Map Assessment — Core 17 Items

The Desire Map is a mutual-reveal compatibility tool. Both partners rate 17 items independently; results are compared only when both complete. The 17 items cover all 7 of Moors' (2024) clinical assessment dimensions for CNM couples.

| # | Item | Category | Sensitivity | Source |
|---|------|----------|-------------|--------|
| 1 | Opening Our Relationship | Structure | 1 | Conley 2017 |
| 2 | Swinging or Playing Together | Structure | 1 | Rubel & Bogaert 2015 |
| 3 | Dating Separately | Structure | 2 | Moors 2017 |
| 4 | Polyamory — Loving More Than One | Structure | 2 | Fern 2020, Haupert 2017 |
| 5 | Our Relationship Comes First | Structure | 2 | Fern 2020 (hierarchy) |
| 6 | Emotional Connections With Others | Emotional | 2 | Mogilski 2017 |
| 7 | New Relationship Energy (NRE) | Emotional | 2 | Easton & Hardy 2017 |
| 8 | Your Partner Falling in Love | Emotional | 3 | Conley 2017 |
| 9 | Group Sexual Experiences | Sexual | 2 | Lehmiller 2018 |
| 10 | Safer Sex Boundaries | Health | 1 | Moors 2024, Fern 2020 |
| 11 | Overnight Stays With Others | Logistics | 2 | Sheff 2014 |
| 12 | Time and Attention | Logistics | 2 | Moors 2024, Mogilski 2017 |
| 13 | Veto Power | Logistics | 2 | Easton & Hardy 2017 |
| 14 | Full Disclosure — Knowing Everything | Communication | 2 | Mogilski 2017, Deri 2015 |
| 15 | Meeting Your Partner's Other Connections | Communication | 1 | Sheff 2014 |
| 16 | Who Knows About Us | Social | 1 | Sheff 2014, PMC 2025 |
| 17 | Handling Jealousy Together | Emotional | 2 | Veh et al. 2025 |

**Why 17, not 15:** The 3 clinically-mandated additions (safer sex, hierarchy, social disclosure) can't replace existing items without creating a gap. 17 items × 15 seconds = ~4.5 minutes. Under the 5-minute threshold.

**Clinical coverage:**

| Moors (2024) Dimension | Items |
|------------------------|-------|
| Structural agreement | 1–4 |
| Emotional boundaries | 5–8 |
| Sexual health agreements | 10 |
| Disclosure preferences | 14 |
| Time management | 11–12 |
| Social identity management | 16 |
| Conflict resolution style | 17 |

**Key clinical insights informing the design:**
- **Gottman:** ~70% of couple problems are perpetual. The Desire Map doesn't solve disagreements — it identifies which are perpetual (need ongoing dialogue) vs. solvable. That reframe shapes item descriptions.
- **Fern (2020):** Hierarchy is the most common unspoken assumption. Partners who disagree on #5 build their CNM structure on a fault line.
- **Sheff (2014):** Closeting stress is the #1 predictor of long-term CNM burnout. Partners often disagree sharply on outness (#16).
- **Veh et al. (2025):** Jealousy management is the strongest predictor of CNM satisfaction. Item #17 is the only item measuring a PROCESS (how you deal with feelings) vs. a PREFERENCE (what you want).

### Archetype System (Post-Reflection Classification)

Solo reflection text is embedded and compared against 8 archetype centroids:

| Archetype | Signals | Content Path |
|-----------|---------|-------------|
| The Curious | "wondering," "thinking about it" | Foundational, exploratory |
| The Anxious | "scared," "worried about losing" | Reassurance-first, attachment-focused |
| The Wanting | "desire," "something missing" | Desire exploration, permission-giving |
| The Going-Along | "partner wants," "they asked me" | Autonomy-focused |
| The Processing | "jealousy," "struggling" | Emotional processing tools |
| The Stuck | "been doing this but," "not working" | Advanced mechanics, renegotiation |
| The Communicator | "don't know how to talk about" | Communication frameworks |
| The Builder | "rules," "structure," "boundaries" | Practical tools, agreements |

Classification is **invisible infrastructure**. The system tags a user as `anxious` internally for content routing. The user never sees that label. They see cards that happen to address their experience. The user experience is just: "Wow, this app gets me." Use the science to build the engine. Let the user experience feel like wisdom, not treatment.

### Emotional Pacing

- Onboarding screens 1–7: logistics (setup energy)
- Screen 8 (Ground Rules): ethical frame (trust energy)
- Screen 9 (Priming): emotional threshold — everything after is personal
- Solo Reflection: first vulnerable moment — earns the right to personalize

### Ground Rules Resurfacing

| Moment | What Appears |
|--------|-------------|
| First couples session | "No scorecards. This is exploration, not evaluation." |
| Cards touching conflict | Footer: "This isn't about right or wrong." |
| Post-session checkout | "How did that feel? (Just for you — your partner sees their own.)" |
| Settings → About | Full ground rules + crisis resources |
| 14+ days inactive | No guilt. At most: "Still here when you're ready." |

---

## 7. Marketing & Positioning

### Core Positioning

Don't sell "an NM app." Sell the solution to specific pain points. The app is ONE product. The marketing speaks to NINE different moments of pain.

### Pain-Point Marketing Hooks

| Hook | Problem It Targets |
|------|-------------------|
| "How to bring up non-monogamy without your partner thinking you want to cheat" | #1 — Can't start |
| "Your first NM conversation went badly. Here's what to do next." | #2 — Went badly |
| "Swinging? Polyamory? Open? How to figure out what YOU actually want" | #3 — Don't know what I want |
| "The boundary-setting conversation most NM couples skip (and regret)" | #4 — Boundaries |
| "What to do when jealousy hits and 'just sit with it' isn't working" | #5 — Jealousy |
| "It's 11pm and your partner's date ran late. Here's how to handle tonight." | #6 — Crisis |
| "When your therapist doesn't get non-monogamy" | #7 — Therapist gap |
| "You're not the only couple figuring this out" | #8 — Isolation |
| "Been doing NM for years? When's the last time you audited your agreements?" | #9 — Experienced but stuck |

### Price Psychology

- **$14.99 Core** = less than a physical card deck ($25–45), less than one therapy session, less than dinner out
- **$34.99 Complete** = the "I'm all in" option — feels like buying a book, not renting access
- **$6.99/mo AI Coach** = less than one coffee/week, justified by real per-message API costs
- Expansion packs feel earned — couples hit them naturally as they progress

### Buyer Journey

```
$0 (Free) → "Let me just see what this is"
  ↓ Assessment blows their mind
$14.99 (Core) → "This is actually good, $15 is nothing"
  ↓ Complete Phase 1, feel momentum
+$9.99 (Communication) → "I NEED the Drop Box — I can't say this out loud"
  ↓ Hit message limit, want more
$6.99/mo (AI Coach) → "Unlimited Drop Box + a coach? For $7/mo? Yes."
  ↓ Using insights, reports, coaching regularly
Total: ~$35 one-time + $7/mo for active AI features
```

### Revenue Projections (Conservative)

| Timeframe | Downloads | Free→Core (15%) | Core→Bundle (30%) | AI Coach (10% of paid) | Monthly Revenue |
|-----------|-----------|-----------------|-------------------|----------------------|----------------|
| Month 3 | 3,000 | 450 | 135 | — | ~$9,900 (one-time) |
| Month 6 | 8,000 | 1,200 | 360 | 120 | ~$26,400 + $839/mo |
| Month 12 | 20,000 | 3,000 | 900 | 300 | ~$72,000 + $2,100/mo |

---

## 8. Design System

### Colors — `AppColors`

| Token | Hex | Usage |
|-------|-----|-------|
| `cyan` | #00C2FF | Primary accent, cool spectrum |
| `purple` | #6C3AE0 | Mid-spectrum, transitions |
| `magenta` | #FF006A | Emotion accent, hot spectrum |
| `pink` | #FF2D8A | Shimmer gradients |
| `deepBlue` | #0078FF | Atmospheric floor washes |
| `gold` | #C8960A | Safety ONLY (safe word, warnings) |
| `pageBg` | #030305 | Page backgrounds |
| `cardBg` / `card` | #050507 | Card interiors |
| `surfaceBg` | #08080C | Elevated surfaces |
| `textPrimary` | #E8E8F0 | Headings, prompt text |
| `textSecondary` | #AAAABC | Labels, descriptions |
| `textTertiary` | #666680 | Timestamps, meta |
| `border` | white @ 6% | Subtle card borders |
| `spectrumGradient` | cyan→purple→magenta | Hot border, prompt cards |

#### Light Mode Color Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `orangeHot` | — | Light mode accent, borders |
| `lightPageBg` | — | Light mode page background |
| `lightCardTitle` | — | Light mode card heading text |

### Typography — `AppFonts`

All tokens use two factory functions: `display(size, weight:)` (Clash Display) and `body(size, weight:)` (Switzer).

| Token | Font | Size |
|-------|------|------|
| `heroTitle` | Clash Display Bold | 42 |
| `cardTitle` | Clash Display Semibold | 22 |
| `screenTitle` | Clash Display Semibold | 24 |
| `bodyText` | Switzer Regular | 16 |
| `bodyMedium` | Switzer Medium | 15 |
| `caption` | Switzer Regular | 13 |
| `ctaLabel` | Switzer Semibold | 16 |
| `buttonLabel` | Switzer Semibold | 14 |
| `overline` | Switzer Medium | ~11 (tracking 1.2) | Status labels, metadata |

### Shared Modifiers

| Modifier | What it does |
|----------|-------------|
| `.cardStyle()` | `background + clipShape(RoundedRectangle) + border stroke` |
| `.pillBorder()` | Neon gradient stroke (cyan→purple→magenta) with blur + shadow layers |
| `.screenshotProtected()` | Prevents screenshots on sensitive content |

### Card Dimensions — `CardLayout`
Single source of truth for all card-shaped UI. Defined in `Design/Components/Cards/CardLayout.swift`.
| Constant | Value | Notes |
|----------|-------|-------|
| `CardLayout.width` | 313 pt | Screen width − 80 pt margin |
| `CardLayout.height` | 438 pt | 313 × 1.40 — poker/bridge aspect ratio |
| `CardLayout.cornerRadius` | 20 pt | All card shapes |
| `CardLayout.size` | CGSize(313, 438) | Convenience |
| `CardLayout.horizontalMargin` | 80 pt | Total horizontal margin removed from screen width |

### Design Rules

1. **Color is earned** — Gradient only on interactive/prompt cards. Static UI uses muted surfaces.
2. **Gold = safety only** — Never decorative. Safe word, warnings, exit actions.
3. **Hot border = prompt cards only** — Spectrum gradient stroke reserved for PromptCard.
4. **Zero hardcoded values** — All colors via `AppColors`, all fonts via `AppFonts`.

---

## 9. Architecture

### Tab Architecture

The Roadmap is the spine. Tab layout adapts based on persona:

```
Coupled:  Home  |  Roadmap  |  Us ∞    |  You
Solo:     Home  |  Roadmap  |  Journal ✦  |  You
```

| Tab | Coupled Users | Solo Users |
|-----|--------------|------------|
| **Home** | Tonight's check-in, roadmap position, quick play | Same |
| **Roadmap** | Visual journey map. Current stage expanded with Deck + Learn + Pre/Post. All stages browsable (not locked). | Same structure, different roadmap |
| **Us / Journal** | Mutual reveals, session history, partner roadmap progress, saved cards | Private reflections, personal growth timeline, bookmarked prompts, "Questions to ask a future partner" |
| **You** | Profile, settings, safe word config, pairing | Same (minus pairing) |

Learn/Education lives inside each Roadmap stage AND as a browsable section under a "More" area.

### Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI | SwiftUI (iOS 26) | |
| Persistence | SwiftData | Local-first — all session data stays on device |
| Architecture | MVVM | `@Observable`, `@AppStorage`, `@Environment` |
| Backend | Supabase (Free tier) | Postgres, Realtime, Edge Functions, RLS, Auth |
| Auth | Sign in with Apple → Supabase Auth | |
| Purchases | StoreKit 2 | |
| Security | CryptoKit (encryption), Keychain (tokens/keys), LocalAuthentication (biometrics) | |
| Fonts | Clash Display (headings), Switzer (body), Zodiak + GeneralSans (brand) | |
| External deps | Supabase Swift SDK (only external dependency) | |

**Supabase tier: Free ($0/mo)**
- 50,000 monthly active users included
- 500 MB database
- Unlimited API requests
- Upgrade to Pro ($25/mo) only when exceeding 50K MAU

### Project Structure

```
App/
  Open_LightlyApp.swift        — Entry point, auth gate, SwiftData container
  ContentView.swift             — Root router: onboarding vs. tabbed app
  Theme/
    AppColors.swift             — Single source of truth for all colors
    AppFonts.swift              — Font factory functions + semantic tokens
    AppTheme.swift              — ThemeMode enum, AppPalette (light/dark/AMOLED)
    ThemeManager.swift          — Observable theme state
    ThemeModifiers.swift        — .themedRoot() modifier

Features/
  Auth/
    SignInView.swift
  Home/
    HomeRouterView.swift         — Top-level router
    HomeView.swift               — Persona-based router (routes per experienceType)
    HomeDashboardView.swift      — Main dashboard (categories + progress + today)
    HomeGateView.swift           — Loading & permission gate
    HomeMatchReadyView.swift     — Couple-specific variant
    HomeWaitingView.swift        — Pending partner acceptance
    PostMapReflectionView.swift  — Post-desire-map reflection
    Models/
      HomeEventEngine.swift, HomeModels.swift
    Components/
      DesireMapIndicator, PartnerChip, PickUpCard,
      ReflectionBannerView, ReflectionCard, ResearchTicker, SessionCard
  Sessions/
    SessionView.swift
  Compatibility/
    DesireMapView.swift
  Progress/
    ProgressDashboardView.swift
  Settings/
    SettingsView.swift
    ThemePickerView.swift
    ThemeTestView.swift
  MeUs/
    MeUsView.swift
  More/
    MoreView.swift
  Explore/
    ExploreView.swift
  Onboarding/
    OnboardingFlowView.swift    — Coordinator / screen sequencer
    Design/
      OnboardingAtmosphere.swift — Centralized atmosphere for all screens
    Layout/
      OnboardingLayout.swift     — OL namespace: screen-relative layout constants
    Data/
      OnboardingData.swift
      CuriosityScreenConfig.swift
    Views/
      OnboardingStatView, OnboardingBrandView, OnboardingNameView,
      OnboardingModeSelectView, OnboardingContextView,
      OnboardingCuriosityPickerView, OnboardingCardRevealView,
      OnboardingBuildingPathView, OnboardingGroundRulesView,
      PairingForkView
    Components/
      CuriosityPill, CuriosityStatusStrip, CuriosityPanelNudge,
      CuriosityPreviewLine, ContextOption

Design/Components/
  Buttons/                    — GradientButton, HoloCTAButton, CriticalButton, SafeWordButton, SelectablePill
  Cards/                      — PromptCard, SettingsCard, CategoryTileView, ContextCard, ConversationCard,
                              — AtmosphericGhostDeck, CircularArrowView, ContextCardStack, FuseTimerView,
                              — CuriosityFlipCard, CuriosityCardBack, CardLayout, ConversationCardTypes,
                              — CardBackView, CardFrontView, CardRevealPillButton, CardShadows
  Effects/                    — HolographicShimmer, OnboardingGlowField, SparkField, GlowOrb,
                              — AuroraGlowField, LightAuraBloom, LightModeShimmer, FlameAura,
                              — MazePatternView, TileOrbitView
  Input/                      — InteractiveField, RatingButtonGroup, ToggleRow
  Navigation/                 — OnboardingNavBar, OnboardingFooter
  Progress/                   — OnboardingProgressBar, ProgressBar, ProgressRingView, ScoreRing,
                              — SpectrumBar, OrbitIndicator
  Text/                       — LivingText, KeywordHighlightText, GradientText
  Misc Components/            — CardStyle.swift, PillBorder.swift, ScreenshotProtectionModifier.swift,
                              — SectionHeader.swift, NavArrow.swift, OrbitSparkBorderView.swift, FilamentMode.swift

Core/Services/
  AppState.swift              — Experienceype routing state (@Observable)
  AuthService.swift           — Sign in with Apple + Supabase session
  SupabaseManager.swift       — Shared Supabase client
  SyncManager.swift           — Retry pending syncs on launch
  ContentLoader.swift         — JSON prompt loading
  Config.swift                — API keys, environment config
  ProfileService.swift        — User profile CRUD
  PairingService.swift        — Couple pairing codes + Realtime
  SessionSyncService.swift    — Session data sync
  AssessmentSyncService.swift — Assessment results sync
  DesireSyncService.swift     — Desire map ratings sync

Data/Store/
  DataStore.swift             — Central persistence layer
  ModelContainer.swift        — SwiftData container config

Models/
  Content/                    — ContentCard, ContentCategory, ContentAssessmentQuestion,
                              — ContentDesireItem, Prompt
  Enums/
    AppEnums.swift            — All shared domain enums (CardType, Difficulty, RelationshipContext, etc.)
    AppTab.swift              — Tab routing enum
    ExperienceType.swift      — Experience routing (browsing, soloSingle, soloPartnered, coupleNew, coupleExperienced)
  Persistence/                — SessionRecord, RatingRecord, StreakRecord (local-first)
  Progress/                   — UserProfile, AssessmentResult, Couple, DesireMatch, CoupleSessionRecord,
                              — CardProgress, DesireRating, AssessmentResponse (synced to Supabase)
```

---

## 10. Onboarding Flow (v2.0)

**Goal:** App Store download → first meaningful moment in 60–90 seconds (Solo/Couple) or 45–60 seconds (Browsing).

**Design principles:**
- Trust before ask: normalization (Stats) before data collection
- Progressive disclosure: simple asks first, deeper questions after investment
- Breathing room: auto-advance screens provide mental breaks
- Self-honesty before partner performance: Solo Reflection happens first, even for couples
- Clear value exchange: user understands why each question matters
- No dead ends: every path leads to value

### Screen Sequence (9 screens)

| # | Screen | File | Type | Data Collected | Purpose |
|---|--------|------|------|---------------|---------|
| 1 | StatView | `OnboardingStatView.swift` | Interactive | None | "1 in 5" stat — normalize, reduce shame |
| 2 | BrandView | `OnboardingBrandView.swift` | Auto (3.5s) | None | Brand identity — mental break before first ask |
| 3 | NameView | `OnboardingNameView.swift` | Form | `displayName`, `gender` | Personalization seed, lowest-stakes first ask |
| 4 | ModeSelectView | `OnboardingModeSelectView.swift` | Two-stage | `explorationMode`, `nmStage` | Primary branch: Solo / Couple / Just Browsing |
| 5 | ContextView | `OnboardingContextView.swift` | Card stack | `relationshipContext` | Relationship situation — **skipped for Browsing** |
| 6 | CuriosityPickerView | `OnboardingCuriosityPickerView.swift` | Multi-select | `curiositySelections`, `communicationGoals`, `learningGoals` | Interest + intent picker — drives content personalization |
| 7 | CardRevealView | `OnboardingCardRevealView.swift` | Tap-to-flip card | `nmCardResponse` | **The reflective moment.** Replaces the old standalone solo reflection gate. Universal — every path. Front: open question the user sits with. Back: four pills (A desire / A fear / A boundary / A truth). Pill selection feeds archetype routing invisibly. Skip stores nil. |
| 8 | BuildingPathView | `OnboardingBuildingPathView.swift` | Auto (~7.5s) | Derives `defaultDifficulty` from `nmStage` | **Arrival ceremony — not processing animation.** Responds directly to CardReveal data. Four orbit rows including `nmCardResponse`. Exit line: "Jordan, you're in." Copy: "YOUR PATH IS READY." |
| 9 | GroundRulesView | `OnboardingGroundRulesView.swift` | Must-acknowledge, ScrollView | `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt` | Ethical frame — what this is and isn't. Home renders blurred and non-interactive behind this screen. User sees destination before final acknowledgment. Blur animates to zero BEFORE `hasCompletedOnboarding` fires. No back button. |

**Then:**
```
→ HOME DASHBOARD (direct)
```

**NOTE: The Solo Reflection gate has been scrapped. Its function is
fully absorbed by the CardReveal screen (step 7), which poses the
reflective open question universally within the onboarding flow itself.
Post-onboarding, all paths land directly on the home dashboard with
no intermediate gate.**

### Path Variations

| Path | Screens | Notes |
|------|---------|-------|
| **Solo** | All 9 | ContextView shows 3 relationship-context cards. CardReveal is universal. |
| **Couple** | All 9 | ContextView shows 4 relationship-context cards. CardReveal is universal. Pairing deferred to Settings. |
| **Just Browsing** | 8 (skips ContextView) | CardReveal universal. Education tab unlocked; sessions locked until upgrade. |

**Note on screen count:** The count increases by 1 from the previous spec
because CardReveal has moved from step 7.5 (a half-step) to step 7 (a full
step), with BuildingPath at step 8 and GroundRules at step 9. The total
user experience duration is unchanged — BuildingPath and CardReveal existed
before, they have simply been reordered and reframed.

### Act-Ownership Routing Logic

The onboarding routing is intentional and permanent — not a placeholder to be replaced, but the architecture that enables the three-act reveal sequence. No onboarding screens change between acts; only the marketing focus shifts.

| Onboarding Selection | Act | Marketing Status at Launch |
|---------------------|-----|---------------------------|
| Coupled + Curious (`nmStage`: curious / exploring) | **Act 1** | Marketed — primary front-door path |
| Coupled + Experienced (`nmStage`: experienced) | **Act 2** | Present, not marketed — experienced tools surface first; these users discover the operational infrastructure organically |
| Solo (any `nmStage`) | **Act 3** | In architecture, not marketed — full routing present; excluded from launch marketing; front-door shift at V1.2 |

When Act 2 marketing begins at V1.1, experienced users have always had a complete path. When Act 3 marketing begins at V1.2, solo users have always had a complete path. The routing is the strategy encoded in code.

**CardReveal routing note:** nmCardResponse is available to BuildingPath
because CardReveal now precedes it in the flow. BuildingPath reads this
value to populate its fourth orbit row. The archetype classification that
previously happened post-solo-reflection now happens at the same point —
during BuildingPath's animation window, which provides sufficient processing
time before the user reaches GroundRules.

### User Modes

```swift
enum UserMode: String, Codable {
    case solo      // Self-discovery, partner optional
    case couple    // Joint exploration, paired via code
    case browsing  // Learn first, no sessions yet
}
```

### Experience Levels (collected in ModeSelectView, stage 2)

Defined in `AppEnums.swift` as part of `NMStage`:

```swift
enum NMStage: String, Codable, CaseIterable {
    case curious     // Brand new → defaultDifficulty: "warm"
    case exploring   // Some context → defaultDifficulty: "medium"
    case experienced // Knows what they want → defaultDifficulty: "hot"
}
```

This was consolidated from the old standalone `ExperienceLevel.swift` into `AppEnums.swift` for unified enum management.

### Relationship Context Options (ContextView)

**Solo (3 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `single` | "I'm single" | ember |
| `partneredOpen` | "I have a partner (they know)" | spark |
| `partneredHidden` | "It's complicated" | blaze |

**Couple (4 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `notTalked` | "Haven't really talked about it" | ember |
| `talking` | "We've been talking" | flame |
| `someExperience` | "We've tried some things" | inferno |
| `needsReset` | "We need a reset" | nova |

### Curiosity Categories (CuriosityPickerView, multi-select)

- Communication & Dirty Talk
- Sensation & Touch
- Power Dynamics
- Fantasy & Role Play
- Trust & Vulnerability
- Romance & Connection
- Adventure & Novelty
- Bondage & Restraint
- Not sure yet — surprise me *(mutually exclusive with all others)*

### Navigation Logic

```swift
// Implemented in OnboardingFlowView.swift as advance(to:)
// All transitions: .spring(response: 0.35, dampingFraction: 0.8), .opacity.combined(with: .scale(0.95))
// (ANIM-STD-37: advance() spring, ANIM-STD-38: screen transitions)

enum OnboardingStep: Int, CaseIterable {
    case stat, brand, name, modeSelect, contextSelect, curiosityPicker, cardReveal, buildingPath, groundRules
}
// NOTE: cardReveal precedes buildingPath intentionally.
// CardReveal is the reflective moment — nmCardResponse feeds directly
// into BuildingPath's fourth orbit row and exit copy.
// BuildingPath is the arrival ceremony, not a processing screen.

func advance(to step: OnboardingStep) {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
        currentStep = step
    }
}

// Main navigation flow:
switch currentStep {
    case .stat:             advance(to: .brand)
    case .brand:            advance(to: .name)           // auto-advance at 3.5s
    case .name:             advance(to: .modeSelect)
    case .modeSelect:
        // Browsing skips context — goes directly to curiosity picker
        advance(to: explorationMode == .browsing ? .curiosityPicker : .contextSelect)
    case .contextSelect:    advance(to: .curiosityPicker)
    case .curiosityPicker:  advance(to: .cardReveal)
    case .cardReveal:
        // User taps to flip & select pill (or skip)
        // Stores data.nmCardResponse (String? — nil if skip)
        // Encouragement typewriter completes → advance
        advance(to: .buildingPath)
    case .buildingPath:     advance(to: .groundRules)    // auto-advance at ~7.5s
    case .groundRules:
        // Must-acknowledge; no back button
        // Writes: groundRulesAcceptedAt, onboardingComplete, completedAt
        // Then calls onFinished → coordinator marks onboarding done → HOME
        onFinished?()
}

func goBack() {
    // .stat, .brand — no back (brand already played)
    switch currentStep {
    case .name:            advance(to: .modeSelect)   // back goes forward to avoid re-playing brand
    case .modeSelect:      advance(to: .name)
    case .contextSelect:   advance(to: .modeSelect)
    case .curiosityPicker:
        // Browsing went modeSelect → curiosity, so back goes to modeSelect
        advance(to: explorationMode == .browsing ? .modeSelect : .contextSelect)
    // NOTE: cardReveal, buildingPath, groundRules — no back button
    // cardReveal: first vulnerable moment, no return
    // buildingPath: auto-advance terminal, no back
    // groundRules: terminal screen, no back
    default: break
    }
}
```

### Data Model

```swift
struct OnboardingData {
    // Screen 3 — NameView
    var displayName: String = ""
    var pronouns: [PronounOption] = []

    // Screen 4 — ModeSelectView
    var explorationMode: ExplorationMode?  // solo / couple / browsing (from AppEnums)
    var nmStage: NMStage?                  // curious / exploring / experienced (from AppEnums)

    // Screen 5 — ContextView (Solo/Couple only)
    var relationshipContext: RelationshipContext?  // from AppEnums

    // Screen 6 — CuriosityPickerView
    var curiositySelections: [String] = []
    var communicationGoals: [String] = []
    var learningGoals: [String] = []

    // Screen 7 — CardRevealView
    // Pill selection for archetype routing; nil when user skips.
    // This IS the solo reflection moment — no separate gate exists.
    var nmCardResponse: String? = nil

    // Screen 8 — BuildingPathView (auto-advance)
    // Derived from nmStage. BuildingPath reads nmCardResponse to
    // populate its fourth orbit row and personalise exit copy.
    var defaultDifficulty: String {
        switch nmStage {
        case .curious:     return "warm"
        case .exploring:   return "medium"
        case .experienced: return "hot"
        default:           return "warm"
        }
    }

    // Completion (Screen 9 — GroundRulesView)
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?
}
```

**Notes:**
- `nmCardResponse` is stored but used primarily for internal archetype classification
- `nil` when user skips CardReveal (skip button or close); archetype routing uses fallback
- Data defined in `Features/Onboarding/Data/OnboardingData.swift`
- Threaded as `@Binding var data: OnboardingData` through all onboarding screens

### Partner Pairing (Couple Mode — deferred to Settings)

Pairing is no longer a mandatory onboarding screen. Couple users complete their own onboarding individually, then pair via Settings. This removes the blocking dependency on a partner being present at signup time.

Three pairing methods remain available in Settings:
| Method | When | How |
|--------|------|-----|
| **QR Code** | Same room | Partner A shows QR → Partner B scans |
| **Verbal Code** | Same room, different device | Format: `WORD + 2-digit number` (e.g. "SPARK 42") |
| **Share Link** | Remote | iMessage/text deep link |

---

### Solo Reflection — Absorbed Into CardReveal

The standalone post-onboarding solo reflection gate has been scrapped.
Its function is fully absorbed by the CardReveal screen (step 7 in the
onboarding flow).

**What changed:**
- `SoloReflectionEntry` model is no longer needed — remove if present
- No post-onboarding gate on first HOME visit
- All paths land directly on home dashboard after GroundRules acknowledges
- The reflective question ("What would you desire if nobody, not even you,
  would judge the answer?") is posed universally during onboarding
- `nmCardResponse` stores the pill selection and drives archetype routing
- Skip behavior identical: nil stored, archetype routing uses fallback,
  seed is still planted (user read the question even if they didn't answer)

**Why this is better:**
The old gate created a friction point at the home threshold — users who
just completed 8 onboarding screens hit another reflective prompt before
seeing the app. CardReveal poses the same quality of question at the
correct moment in the emotional arc (immediately before BuildingPath
confirms what was built from it) rather than as a post-hoc gate.

---

## 11. Content Structure & Roadmaps

### The Roadmap is the Spine

The Roadmap is the primary navigation — a visual journey map (not a checklist, not a progress bar). Each persona gets a different roadmap. Each stage has three layers:

| Layer | What It Is |
|-------|-----------|
| **Conversation Deck** | 8–12 prompts specific to this stage |
| **Education Module** | Curated resources (books, podcasts, Reddit threads, videos) contextual to this stage |
| **Pre/Post Processing** | Before: "What are we hoping to feel? What are we afraid of?" / After: "What actually happened? What surprised us?" |

### Coupled Curious Roadmap — Graduated Exposure

This is **systematic desensitization** (Wolpe, 1958) applied to NM exploration. Each step increases only ONE variable (observation → participation → emotional → physical → autonomy). Each step has a natural pause-and-process point. Regression is expected and normalized.

| Stage | Anxiety | What It Tests | Clinical Parallel |
|-------|:---:|---------------|-------------------|
| 1. Curiosity | 1/10 | Can we even have this conversation? | Psychoeducation / imaginal exposure |
| 2. Fantasy Together | 2/10 | Can we be sexual while acknowledging others exist? | Imaginal exposure |
| 3. Observation | 3/10 | Can we be in a sexually charged environment together? | In-vivo exposure (observation) |
| 4. Mild Participation | 4/10 | Can I see my partner receiving attention from someone else? | In-vivo exposure (mild) |
| 5. Controlled Experience | 5/10 | Can we involve a third party in a boundaried way? | In-vivo exposure (controlled) |
| 6. Emotional Connection | 5/10 | Can we handle emotional attention from others? | In-vivo (emotional domain) |
| 7. Low-Stakes Dating | 6/10 | Can we handle our partner on a date? | In-vivo (social/romantic) |
| 8. Raising Stakes | 7/10 | Can we handle escalation? | Graded exposure |
| 9. Full Experience | 8–9/10 | The real thing, together or separately | Full exposure (with safety) |
| 10. Autonomy | 10/10 | Maximum trust | Full autonomy |

**Framing: descriptive, not prescriptive.** "Many couples find that starting with low-stakes observation helps them gauge comfort" — NOT "You should start with strip clubs." No required order. A guide, not a gate. You can stop anywhere. Every stage is an arrival, not a waypoint.

**Evidence basis:** No peer-reviewed research on this exact sequence for swinging. But the underlying framework is massively validated: graduated exposure (Wolpe 1958), processing with partner improves outcomes (Gottman, Johnson), psychoeducation before novel experiences reduces negative outcomes (health psych), autonomy at each step predicts satisfaction (Deci & Ryan + Moors et al.), emotional regulation improves with practice (Gross 2015).

### Solo Curious Roadmap

| Stage | Focus |
|-------|-------|
| 1. Understand Yourself | What do I want? What am I afraid of? What does commitment mean to me? |
| 2. Learn the Landscape | NM styles, structures, terminology. What resonates? |
| 3. Process Your Feelings | Internalized monogamy, shame, fear. What stories am I telling myself? |
| 4. Prepare to Date | Profiles, disclosure timing, vetting NM partners |
| 5. Build Your World | Community, support, who do I tell? How? |
| 6. Start Dating | First conversations, first dates, processing what comes up |
| 7. Navigate Your First NM Relationship | Communication, boundaries, NRE — "It's real now" |

### Coupled Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. State of the Union | How are WE doing? Honest check-in. What's working? What's friction? |
| 2. Agreement Audit | Review every rule and boundary. "Does this still serve us or just protect us?" |
| 3. Unfinished Conversations | Things you've been avoiding. Resentments, unspoken desires, fears. |
| 4. Advanced Scenarios | NRE management, unequal situations, evolving structures |
| 5. Repair Shop | When trust was damaged. Specific incident processing framework. |
| 6. What's Next | Deeper exploration, new structures. "Where do we want to be in a year?" |

### Solo Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. Check In With Yourself | Where am I? What patterns keep showing up? |
| 2. Sharpen Your Tools | Communication upgrade, boundary audit |
| 3. Go Deeper | Attachment patterns in NM, jealousy triggers, compersion cultivation |
| 4. Navigate Complexity | Multiple relationships, time, energy, hinge skills, metamour dynamics |
| 5. Handle Hard Stuff | Breakups, transitions, restructuring, repair |
| 6. Sustain & Thrive | Long-term NM wellness, preventing burnout, maintaining joy |

### Content Ratio: Shared vs. Unique

Not four apps — one content library with four paths:

| Content Type | Shared | Unique per path |
|-------------|--------|-----------------|
| Education library (books, podcasts, links) | 80% | 20% path-specific curation |
| Glossary (~50 terms) | 100% | Highlights terms relevant to current stage |
| Conversation prompts | 30% (reframed per persona) | 70% unique |
| Roadmap stages | 0% | 100% unique journeys |
| Pre/Post processing | 40% shared framework | 60% unique prompts |
| Emotional tools (jealousy, NRE) | 50% shared concepts | 50% unique prompts |

**Same topic, four framings (example — jealousy card):**

| Persona | How the card reads |
|---------|-------------------|
| Solo Curious | "When you imagine a future partner being with someone else, what comes up? Sit with that feeling." |
| Solo Experienced | "Think about the last time jealousy showed up. What was the trigger underneath the trigger?" |
| Coupled Curious | "Read this to each other: 'When I imagine you being with someone else, I feel ____.' Just listen." |
| Coupled Experienced | "When was the last time jealousy surprised you — a situation where you thought you'd be fine but weren't?" |

### Content Volume Estimate

| Path | Unique prompts | Shared (reframed) | Total |
|------|---------------|-------------------|-------|
| Solo Curious | ~80 | ~40 | ~120 |
| Solo Experienced | ~70 | ~40 | ~110 |
| Coupled Curious | ~90 | ~40 | ~130 |
| Coupled Experienced | ~75 | ~40 | ~115 |
| **Total** | **~315 unique** | **~40 × 4 = 160** | **~475 prompt variations** |

### Launch Content Priority

**Phase 1 (Launch):** Solo Curious + Coupled Curious = ~295 prompts + glossary + curated education

**Phase 2 (Month 2–3):** Add Experienced paths = ~145 additional prompts

**Phase 3 (Month 4+):** Style-specific roadmaps (polyamory, relationship anarchy, kink+NM intersection)

### Prompt Phases (purchase tiers)

| Phase | Content | Tier |
|-------|---------|------|
| 0 | Relationship Strengthening | Core |
| 1 | Foundation Conversations (40+ prompts) | Free (3) + Core |
| 2 | NM Education Modules | Education Pack |
| 3 | Hypothetical Scenarios | Scenarios Pack |
| 4 | After First Experience | Scenarios Pack |

### Prompt Model

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | The prompt question |
| `highlightWords` | [String] | Keywords highlighted via GradientText |
| `category` | PromptCategory | .prompt, .reflect, .ultimate, etc. |
| `difficulty` | PromptDifficulty | .easy → .ultimate (6 levels) |
| `isSensitive` | Bool | Triggers screenshot protection |
| `canSkip` | Bool | Whether user can skip |
| `whoStarts` | WhoStarts | .partnerA, .partnerB, .both |

### Education Library

Attached to each roadmap stage (contextual, not standalone). Also browsable as a top-level section.

```
LEARN
├── ⭐ Recommended for You (3–4 based on persona + current stage)
├── 📚 Books (curated per persona — same library, different "Start Here")
├── 🎙️ Podcasts (We Gotta Thing, Normalizing NM, Room 77, Front Porch Swingers)
├── 📺 Videos (curated playlist)
├── 💬 Communities (Reddit, lifestyle sites, local finding guide)
├── 📋 Glossary (universal — highlights terms relevant to current stage)
└── 🧭 Where Do I Start? (different entry point per persona)
```

Resources are curated, not created. The app doesn't write textbooks — it organizes the best existing resources and surfaces them at the moment they're needed.

---

## 12. Revenue Model

### Primary Conversion Architecture — The Desire Map Paywall

> **This is not a feature gate. This is the business model.**

The Desire Map mutual reveal is the primary revenue mechanic at launch. The structure:

1. **Both partners complete the Desire Map free** — 17 items, ~4.5 minutes, fully private.
2. **One matched item is revealed free** — both partners see one thing they agree on. This is the "instant personalized result" that creates the demand.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product being purchased.

The free match reveal is the hook. It proves the product works before asking for money. It is personally relevant, immediately gratifying, and impossible to replicate without completing the assessment — which means any user who sees the free match has already invested in the product. The paywall lands at peak intent.

**Where it sits in the pricing tier:** The full Desire Map reveal unlocks with Core Edition ($14.99) or the Complete Bundle ($34.99). It is the primary reason couples upgrade from free.

---

### Pricing Tiers

| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | Onboarding, assessment preview, 3 prompts, desire map teaser |
| Core Edition | $14.99 | Full scores, Phase 0+1, full desire map, boundary workshop |
| Communication Pack | +$9.99 | Drop Box (100 AI-translated messages), communication profiles |
| Education Pack | +$9.99 | Phase 2 modules, quizzes, STI resources |
| Scenarios Pack | +$14.99 | Phase 3+4, advanced boundary tools |
| Complete Bundle | $34.99 | Everything. All future content updates. |
| AI Coach (subscription) | $6.99/mo | Unlimited Drop Box, AI coach, jealousy first aid, insights, reports |

### Why One-Time + Subscription

Static content is yours forever — buying a book, not renting access. The ONLY subscription is for AI features that cost real money per use (every chat message, every transcription, every analysis). Users understand that.

### Future Freemium Consideration

The Flo Health model suggests a compelling alternative: free tier creates the habit and the data, premium unlocks the value of the data already collected. For Open Lightly this could mean:

| Free Tier | Premium |
|---|---|
| Basic check-ins (last 10 entries) | Full check-in history + pattern insights |
| Up to 3 connection cards | Unlimited connections |
| Basic jealousy log | Full jealousy history + pattern dashboard |
| 5 daily pulse entries | Full pulse history + emotional calendar |
| Community prompts (read) | Full prompt library + custom |

**Decision deferred to post-V1.0 data review.** The current one-time + subscription model ships first. Conversion to freemium considered only if D30 retention data suggests the data-compounding model would produce stronger LTV.

### Subscription Features Breakdown

| Feature | Why Subscription | Cost Driver |
|---------|-----------------|-------------|
| Unlimited Drop Box | $0.02–0.08 per AI translation, heavy users send 50+/month | Per-message API cost |
| Conversation Insights | Recording → transcription → analysis per session | Whisper + GPT per session |
| Monthly Reports | AI-generated relationship health reports | Accumulated data analysis |
| Evolving Compatibility | Quarterly re-assessment with trend analysis | Embedding + comparison |

---

## 13. Build Progress

Act 1 batches ship before Act 2 batches are polished before Act 3 batches are completed.

| Batch | Act | Scope | Status |
|-------|-----|-------|--------|
| 1–3 | 1/2/3 | Project setup, data models, enums | Done |
| 4 | 1/2/3 | Theme — AppColors, AppFonts, AppTheme, ThemeManager | Done |
| 5 | 1/2/3 | Navigation — ContentView, 5-tab structure | Done |
| 6 | 1 | Components — PromptCard, GradientText, SafeWordButton, ProgressRingView | Done |
| 7 | 1 | Feature screens — Home, Session, DesireMap, Progress, Settings | Done |
| 8 | 1/2/3 | SwiftData persistence — sessions, ratings, streaks | Done |
| 9 | 1/2/3 | Auth (Sign in with Apple + Supabase), partner pairing, sync services | Done |
| 10 | 1/2/3 | Theming (light/AMOLED), sync retry on launch | Done |
| — | 1/2/3 | Codebase audit & refactor (design tokens, shared components, dead code) | Done |
| 11 | 1/2/3 | Onboarding flow complete (all 9 screens, CuriosityPickerView three-panel card deal, CardReveal, BuildingPath, GroundRules); home screen redesign (HomeDashboardView, router, per-persona views, PostMapReflection); design system expansion (CardLayout, OrbitIndicator, FilamentMode, new effects) | **Done** |
| 11.1 | 1 | CuriosityPickerView layout fixes: .clipped() + .background() shadow overlay resolves shadow/clip tension; back-card overflow contained | **Done** |
| 12 | 1 | Content authoring — Act 1 prompts, card decks, education modules | Planned |
| 13 | 1 | Assessment / archetype classification (post-first-session) | Planned |
| 14 | 1 | Communication Pack — Drop Box + AI translation | Planned |
| 15 | 1 | AI Coach Membership | Planned |
| 16 | 3 | Bridge Cards (solo user with partner path) | Planned |
| 17 | 3 | Journal / notes system (solo path) | Planned |
| 18 | 2 | Jealousy Mapping — structured logging/decoding tool | Planned |
| 19 | 2 | Compersion Tracker — emotional logging | Planned |
| 20 | 2 | Connection Cards / Partner Roster — visual relationship network | Planned |
| 21 | 2 | Solo/Couple Check-In Rituals — structured pre/post-date check-ins | Planned |
| 22 | 2 | Daily Relationship Pulse — 30-second micro-check-in | Planned |
| 23 | 2 | Contextual Resource Library — trigger-based education | Planned |
| 24–26 | 2 | Communication Pattern Library (browsable, no recording) | Planned |
| 27–28 | 2 | Opt-in recording, transcription, alternative phrasing engine | Planned |
| 29+ | 2 | Post-conversation replay, transparency documentation | Planned |
| 30+ | 2 | Hybrid linguistic analysis (with full consent architecture) | Planned |

---

## 14. Guiding Principles

1. **This is not therapy.** It is a conversation tool. A communication skills resource. An educational framework. The line is non-negotiable. See Section 3.
2. **Privacy is the product.** Local-first. Solo reflections never shared. Screenshot protection on sensitive content. No social graph. No accounts linked to social media.
3. **The couple is the user.** Every feature asks: does this bring them closer or create friction?
4. **Buy content, subscribe to AI.** Static content is yours forever. Subscription only for features that cost real money per use.
5. **Color is earned.** The UI rewards engagement with visual richness.
6. **Safety is sacred.** Gold means stop. The safe word is always accessible, never hidden.
7. **Skip is real.** No guilt, no nagging, no re-prompting. Every "skip" is a valid choice.
8. **Normalize, don't pathologize.** The voice is a thoughtful friend, not a clinician. Every outcome — including "this isn't for us" — is valid.
9. **Structure over information.** They have enough information. They need a process for turning it into conversations.
10. **No dollar is worth an ethical violation.** If a feature could cause harm, it doesn't ship. Period.

> **The Compounding Data Principle:** Every check-in, every journal entry, every jealousy log should feel like it's building something — a picture of yourself and your relationships that gets more accurate and more valuable the longer you stay. The moment a user thinks "this app knows me better than I know myself" — that's when retention becomes organic.

---

## 15. Session System

### Card Actions

Replaces the original thumbs up/down design:

| Action | Button | What It Means | Signal |
|--------|--------|---------------|--------|
| **We Discussed This** | ✅ Primary gradient CTA | Partners talked about this card | Completion |
| **Not Ready** | ⏩ Secondary | Not ready for this topic yet | Honest signal, no shame |
| **Bookmark** | 🔖 Icon button | Save to revisit later | High intent |

**Rationale for removing thumbs up/down:**
- `CardStatus` enum (`.discussed` / `.skipped` / `.bookmarked`) tracks the meaningful signals
- "Did you talk about it?" matters more than "Did you like the card?"
- The conversation IS the engagement, not the rating tap
- Skip/bookmark data is more actionable for content improvement than 👍👎

### Card Layout (per card in session)

```
┌──────────────────────────────────────┐
│          1 of 5 • Category           │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ "Prompt text here..."          │  │
│  │                                │  │
│  │ Take turns sharing.            │  │
│  │ Listen without judgment.       │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────────┐  ┌──────┐         │
│  │ ⏩ Not Ready  │  │ 🔖  │         │
│  └──────────────┘  └──────┘         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ✅ We Discussed This          │  │
│  └────────────────────────────────┘  │
│                                      │
│           🛑 Safe Word               │
└──────────────────────────────────────┘
```

### Session Summary

- Cards discussed count
- Cards skipped count ("no pressure")
- Cards bookmarked count ("saved for later")
- Feeling emoji check-in
- Encouragement text

---

## 16. Data Models

### Architecture

```
UserProfile A          UserProfile B
│                      │
└──────┐  ┌────────────┘
       │  │
       ▼  ▼
      Couple
      ├── cardProgress[]
      ├── sessionRecords[]
      └── kinkMatches[]
```

Individual data (assessment answers, kink ratings) lives on `UserProfile`.
Shared data (sessions, card progress, kink matches) lives on `Couple`.
Deleting a `Couple` does NOT delete the `UserProfile`s.

### Couple Model

```
Couple
├── id: UUID
├── createdAt: Date
├── partnerA: UserProfile?
├── partnerB: UserProfile?
├── sharedSafeWord: String          (default: "red")
├── matchesRevealed: Bool           (default: false)
├── cardProgress: [CardProgress]
├── sessionRecords: [CoupleSessionRecord]
└── kinkMatches: [KinkMatch]
```

### UserProfile Model

```
UserProfile
├── id: UUID
├── name: String
├── createdAt: Date
├── pronouns: String
├── sexualOrientation: String
├── rolePreference: String
├── userMode: String                ("solo", "couple", "curious")
├── experienceLevel: String         ("new", "some", "experienced")
├── defaultDifficulty: String       ("warm", "medium", "hot", "blazing")
├── nmFlavor: NMFlavor?
├── curiositySelections: [String]
├── surpriseMeEnabled: Bool
├── hasCompletedOnboarding: Bool
├── hasCompletedAssessment: Bool
├── mythBusterComplete: Bool
├── mythBusterSkipped: Bool
├── onboardingDropoffScreen: String?    (analytics)
├── accountId: String?                  (Sign in with Apple)
├── accountCreated: Bool
├── pairingCode: String
├── isLinked: Bool
├── partnerLabel: PartnerLabel?
├── assessmentResponses: [AssessmentResponse]
└── kinkRatings: [KinkRating]
```

---

## 17. Scoring & Matching

### Two Separate Rating Systems

| Model | Purpose | Data Type | Owner | Privacy |
|-------|---------|-----------|-------|---------|
| **RatingRecord** | Prompt card reactions during sessions | String (`"discussed"` / `"skipped"` / `"bookmarked"`) | `SessionRecord` | Shared — written together |
| **KinkRating** | Individual kink/BDSM map answers | Typed `Rating` enum (`.love` / `.curious` / `.neutral` / `.hardNo`) | `UserProfile` | Private — Hard No NEVER revealed |

`KinkRating` feeds into `KinkMatch`. `RatingRecord` feeds into session history and progress stats. They are completely separate systems.

### Hard No Protection (Defense in Depth)

Hard No ratings must **NEVER** be visible to a partner. Enforced at three levels:

| Level | Protection |
|-------|-----------|
| **Database (RLS)** | `kink_ratings` table: only owner can query. Partner cannot access this table at all. |
| **Server (Edge Function)** | `compute_kink_matches()` filters out any row where either rating = `hardNo` BEFORE writing to `kink_matches` table. |
| **Client (Swift)** | `KinkRating` model is local-only for `hardNo` items. Only `.love` / `.curious` / `.neutral` are ever sent to server for matching. `hardNo` items never leave the device. |

---

## 18. Privacy Rules

| Rule | Detail | Enforcement Level |
|------|--------|-------------------|
| Individual assessment answers | Encrypted locally. Never synced raw. Partner never sees them. | Device + Database (never uploaded) |
| Kink Hard No's | Never revealed. Never stored on server. Never queryable by partner. | Device + Server (Edge Function filter) + Database (RLS) |
| Safe word usage | Not logged. Not surfaced in stats. Not stored anywhere. | App code (no tracking call) |
| Session notes | Local only. Never synced to Supabase. | Device only |
| Push notifications | No sensitive content in notification text. | Server (Edge Function templates) |
| Backend data | Only: pairing data, completion status, domain-level scores (not raw answers), positive kink matches. | Database (RLS on every table) |
| Cross-user access | No user can query another user's data except through couple relationship. | Database (RLS policies) |
| Unauthenticated access | Zero. All queries require valid Sign in with Apple JWT. | Database (RLS) + Supabase Auth |
| Service role key | Server-side only. Never in client code. Never in git. | Code review + audit checklist |
| Encryption at rest | Kink ratings and assessment answers encrypted via CryptoKit before any storage. | Device (CryptoKit + Keychain) |

### Data Classification

| Data | Sensitivity | Storage | Encrypted | Synced to Supabase |
|------|-------------|---------|-----------|-------------------|
| Display name | Low | SwiftData + Supabase | No | Yes |
| Pronouns | Low | SwiftData + Supabase | No | Yes |
| NM Flavor | Medium | SwiftData + Supabase | No | Yes |
| Pairing code | Low (ephemeral) | Supabase only | No | Yes (expires 24h) |
| Assessment answers (raw) | High | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Assessment domain scores | Medium | SwiftData + Supabase | No | Yes (aggregated, not raw) |
| Kink ratings (individual) | Critical | SwiftData (encrypted) | Yes (CryptoKit) | Only non-hardNo, encrypted, for matching |
| Kink Hard No items | Critical | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Kink matches (positive) | Medium | SwiftData + Supabase | No | Yes (only mutual positives) |
| Session notes | High | SwiftData ONLY | No | NO — never leaves device |
| Session card statuses | Low | SwiftData + Supabase | No | Yes (discussed/skipped/bookmarked) |
| Safe word usage | Critical | NOT LOGGED | N/A | NO — never recorded anywhere |

---

## 19. Database Security Plan

### Why This Matters More for This App

This app stores the most sensitive data possible — sexual preferences, kink ratings, intimate conversation history, partner pairing status, psychological assessment answers. A breach for a to-do app is embarrassing. A breach for this app ruins lives.

### The 7 Mistakes We Will Not Make

| # | Mistake | What Happens | Our Mitigation |
|---|---------|-------------|----------------|
| 1 | No Row Level Security (RLS) | Anyone with Supabase URL reads/writes ALL data | RLS enabled on EVERY table at creation, BEFORE any data is inserted |
| 2 | API keys in frontend code | Anyone can extract keys from app bundle | Only anon key in app (safe with RLS). Service role key NEVER in client code. |
| 3 | No auth required for queries | Unauthenticated users read entire database | Sign in with Apple required before any DB access. No anonymous queries. |
| 4 | Service role key in the app | "God mode" key shipped to users | Service role key exists ONLY in Supabase Edge Functions (server-side) |
| 5 | No policies on sensitive tables | Kink ratings, messages readable by anyone | Every table has explicit USING/WITH CHECK policies per row |
| 6 | Client-side validation only | User modifies request, bypasses checks | All security enforced at database level via RLS. Client validation is UX only. |
| 7 | No encryption for sensitive fields | Breach exposes plaintext data | Kink ratings encrypted with CryptoKit before upload. Even a breach yields encrypted blobs. |

### Row Level Security Policies

**Every table gets RLS enabled and policies written BEFORE any data is inserted.**

```sql
-- ============================================
-- USER PROFILES: Only own profile accessible
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- KINK RATINGS: Private — ONLY the owner
-- ============================================
ALTER TABLE kink_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Private kink ratings"
  ON kink_ratings FOR ALL
  USING (auth.uid() = owner_id);

-- Partner can NEVER query this table for the other user.
-- Matching is done via Edge Function (server-side) that
-- filters out Hard No before returning results.

-- ============================================
-- COUPLES: Only the two linked partners
-- ============================================
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple members only"
  ON couples FOR SELECT
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

CREATE POLICY "Couple members update"
  ON couples FOR UPDATE
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

-- ============================================
-- KINK MATCHES: Only the couple, positive only
-- ============================================
ALTER TABLE kink_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views matches"
  ON kink_matches FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );

-- ============================================
-- ASSESSMENT STATUS: Own data + partner completion flag
-- ============================================
ALTER TABLE assessment_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Own assessment data"
  ON assessment_status FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Partner completion check"
  ON assessment_status FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
-- NOTE: Partner can see is_complete flag, NOT individual scores or answers.

-- ============================================
-- ENTITLEMENTS: Both partners read
-- ============================================
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views entitlements"
  ON entitlements FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
```

### Key Management

| Key | Where It Lives | Who Can Access |
|-----|---------------|----------------|
| Supabase URL | App config (public) | Anyone (by design — safe with RLS) |
| Supabase anon key | App config (public) | Anyone (by design — safe with RLS) |
| Supabase service role key | Supabase Edge Functions ONLY | Server-side only. NEVER in client code. NEVER in git. |
| User encryption key | iOS Keychain (per device) | Only the device owner via biometric auth |
| JWT tokens | iOS Keychain | Only the authenticated user |

### Pre-Launch Security Audit Checklist

```
□ RLS enabled on every Supabase table (check dashboard badges)
□ Every table has explicit SELECT/INSERT/UPDATE/DELETE policies
□ Test: unauthenticated request to any table returns 0 rows
□ Test: User A authenticated, query User B's kink_ratings → 0 rows
□ Test: User A authenticated, query User B's assessment → 0 rows
□ Test: User A in Couple 1, query Couple 2 data → 0 rows
□ Test: Query kink_matches for a couple → no Hard No items present
□ Search entire Xcode project for service role key → 0 results
□ Search entire git history for service role key → 0 results
□ Supabase anon key is the ONLY key in client code
□ Sign in with Apple is required before any database operation
□ Kink ratings encrypted before any network transmission
□ Hard No items never included in any Supabase write operation
□ Push notification text contains no sensitive content
□ Screenshot protection active on: assessment, kink map, results, notes
□ App lock (Face ID / Touch ID) enabled by default
□ Privacy policy accurately describes data handling
□ Run Supabase security advisor (dashboard tool)
```

### Incident Response Plan

If a security issue is discovered:
1. Immediately revoke all active sessions (Supabase dashboard)
2. Immediately rotate the anon key and service role key
3. Assess what data was exposed and for how long
4. Notify affected users within 72 hours (GDPR/CCPA requirement)
5. Document the root cause and fix
6. Post-mortem — update security policies to prevent recurrence

---

## 20. Supabase Cost Projections

### Cost by User Scale

| Monthly Active Users | Plan | Base | MAU Overage | Est. Total/mo | Revenue Needed to Cover |
|---------------------|------|------|-------------|--------------|------------------------|
| 0 – 50,000 | Free | $0 | $0 | $0 | Nothing |
| 50,001 – 100,000 | Pro | $25 | $0 (100K included) | ~$25–35 | 2–3 paid users |
| 100,001 – 250,000 | Pro | $25 | 150K × $0.00325 = $488 | ~$525 | 53 paid users |
| 250,001 – 500,000 | Pro | $25 | 400K × $0.00325 = $1,300 | ~$1,400 | 140 paid users |
| 500,001 – 1,000,000 | Pro/Team | $25–599 | 900K × $0.00325 = $2,925 | ~$3,000–3,500 | 350 paid users |

### Hidden Cost Triggers

| Resource | Free Limit | Pro Limit | Overage Cost | When It Bites |
|----------|-----------|-----------|-------------|--------------|
| Database size | 500 MB | 8 GB | $0.125/GB | ~100K users with kink ratings + sessions |
| Bandwidth (egress) | 5 GB | 250 GB | $0.09/GB | Real-time sync for couples is chatty |
| File storage | 1 GB | 100 GB | $0.021/GB | Only if profile photos added later |
| Compute | Shared CPU | $10 credit | Varies | If real-time pairing feels slow |

### Break-Even Context

At Y1 target of 2,000–5,000 paying couples:
- Supabase cost: **$0** (well under 50K MAU)
- App revenue: $50,000–$80,000
- Backend costs are irrelevant until app is already profitable

> **Note:** Free tier projects pause after 1 week of inactivity — upgrade to Pro ($25/mo) before any real users to prevent this.

---

## 21. Expansion Roadmap — Acts 2 & 3

Each expansion is a marketing shift as much as a feature release. The tools are largely present in architecture at V1.0; what changes at each act milestone is the front-door story and who we tell it to.

### Act 2 Expansion — V1.1 (30–60 days post-launch)

**Marketing shift:** *"For people doing non-monogamy intentionally."* Experienced ENM practitioners who downloaded the app out of curiosity discover it has operational infrastructure they've never had. This expansion surfaces what was already present.

| Feature | User Type | Rationale |
|---|---|---|
| Connection Cards / Partner Roster | Both | Infrastructure — other features (vault, check-ins, logs) link to connections |
| Solo Date Check-In / Self Check-In | Both | Structured post-date ritual. Natural evolution of solo reflection. |
| Compersion Tracker | Both | Low-friction emotional logging. Counterweight to jealousy work. |
| Daily Relationship Pulse | Both | 30-second daily habit. Data compounds → retention compounds. |
| Smart Contextual Notifications | Both | Personalized nudges based on logged data. Max 1/day, all user-adjustable. |
| Contextual Resource Library | Both | Education surfaced at the right moment — triggered by logging activity. |
| Insight Engine — Pattern Surfacing | Both | Weekly/monthly insights from logged data. Core retention mechanic. Needs data from V1.0 usage to work. |
| Emotional Texture Calendar | Both | Calendar layer showing emotional color per day. Needs pulse data. |

### Act 2 Continued — V1.2 (60–120 days post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Jealousy Mapping | Both | Dedicated in-the-moment tool. Treats jealousy as information, not failure. |
| Agreements Vault | Partnered | Structured, per-partner agreement storage. Requires connection roster first. |
| Discovery Journal | Solo | Prompted private journal for self-discovery. Extends reflection system. |
| Non-Negotiables Document | Solo | Personal values/boundaries document. Living reference, not one-time fill. |

### Act 3 Expansion — V1.2+ (Marketing shift accompanies feature polish)

**Marketing shift:** *"For people who take relationships seriously. All kinds of relationships."* Solo users are explicitly invited. The product reveals it was never about having a partner — it was always about doing the work intentionally. The solo path has existed since V1.0; this is when we tell that story publicly.

Solo-specific polish, bridge cards, and expanded solo roadmap content ship as part of the Act 3 marketing push. No architectural changes required — the routing has always been there.

### V1.5 (4–8 months post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Anonymous Community Feed | Both | Context-mapped social layer. Requires Pulse + logging features at critical mass first. Moderation cost too high pre-scale. |
| Relationship Report (Exportable) | Both | PDF summary for therapist/coach use. Only meaningful with significant logged history. |

### V2.0+ (Far Future Considerations)

| Feature | Notes |
|---|---|
| Your Year, Lightly | Annual cinematic retrospective. Spotify Wrapped for your relational year. Hidden from users with < 6 months active logging — surfaces when earned, not unlocked. Not named in scope yet. |
| Multi-Partner Calendar | Scheduling + emotional texture overlay. High complexity. |
| NRE Navigator | Second-order feature for active new connections. |
| Polycule Network Visualizer | Requires populated roster. |

---

## 22. Anonymous Community Feed — V1.5 Design Principles

> The feed is not a forum bolted onto a tracking app. It is where people who already know themselves — because the app taught them — come to locate their experience within a larger map of human ENM life.

### The Core Differentiator From r/nonmonogamy

Reddit's problem: posts are the atomic unit. Every new person with a jealousy spiral creates a new post, gets 12 replies saying "communicate with your partner," and the collective knowledge never compounds. Open Lightly's feed inverts this.

**The post is a last resort. The default action is finding yourself in what already exists.**

### Pre-Post Mapping Flow

When a user opens "Share something," they don't get a text field. They get a short framing funnel:

1. *What kind of thing is this?* — Processing something difficult / Sharing a win / Asking for perspective / Something I've never seen discussed
2. *What's at the center of it?* — Tags drawn from the app's vocabulary (jealousy, compersion, NRE, bandwidth, agreements, endings, metamour dynamics, etc.)

The app then surfaces: **"Here's what others have shared from a similar place"** — a visual cluster of existing posts mapped by emotional similarity, not keyword match. If a user finds themselves in an existing post, they react and they're done. They found their people without adding noise.

Only if nothing matches does the compose screen open — with nearby posts visible, relevant tags pre-suggested, and a prompt: *"What's the angle nobody's captured yet?"*

### Post Context Layer

Posts optionally carry relational context the app already knows:
- *"Writing from: 8 months into ENM, coupled primary structure, recently added a new connection"*
- No name, no photo — but structural context that makes advice actually calibrated

This is the thing Reddit can never replicate: people arriving with language and self-knowledge the app built for them.

### Feed Structure

- **Resonance clustering** — not chronological, not upvote-ranked. Posts bookmarked by users at similar stages cluster to the surface.
- **"Still true" signal** — users can mark a post weeks or months later when it still reflects something real. Posts with sustained "still true" signals become the durable knowledge base.
- **Sections:** Processing / Wins / Never discussed this before / Questions
- **Reactions:** Heart / Resonate only — no downvotes, no public reply counts on individual posts

### Access Model

- Read-only on free tier
- Posting unlocked on Premium or V1.5+ active user tier
- Moderation architecture designed before launch, not after

---

## 23. Your Year, Lightly — V2.0 Design Principles

> Spotify Wrapped works because it makes you the protagonist of a story you were already living. Open Lightly's version carries real emotional weight: you processed jealousy 14 times, logged compersion 9 times, your bandwidth was lowest in October, you added three connections and closed one with grace.

### Eligibility Gate

The feature does not exist for ineligible users — no locked state, no teaser. It surfaces when earned:
- ≥ 6 months of active logging (not installs)
- ≥ 20 check-ins or session completions
- ≥ 1 connection card with meaningful history

### The Experience Arc

A cinematic scroll — one reveal at a time, each screen its own moment. Opens not with stats but with a tone read:

> *"2025 was a year of expansion for you. You moved toward things that scared you — and most of them were worth it."*

Derived from actual log data: net emotional trajectory, connections opened vs. closed, jealousy trend, bandwidth patterns. The app already knows this. It just hasn't said it out loud yet.

### Postcard System

Each significant moment gets its own designed postcard — shareable, beautiful, optionally private. Not a screenshot of a log. A *designed artifact* that transforms data into memory.

**Milestone cards** — first-of-kind events the user tagged or the app inferred:
- First new connection added to an existing relational structure
- First agreement renegotiation the user initiated
- First time logging compersion after previously only logging jealousy
- Sexual and experiential milestones the user tagged (first club night, first moresome, etc.) — app never labels or assumes; only celebrates what the user explicitly logged

**Emotional arc cards:**
- Jealousy patterns: frequency, most common triggers, and whether the pattern shifted over the year
- Compersion log highlights: the moments that made the list
- Bandwidth rhythm: highest and lowest capacity months

**Connection cards** — one per active relationship:
- Time together logged, sessions run, most-used card category
- A pulled quote from a reflection they wrote (their words, their meaning)

**The numbers card:**
- Check-ins completed / Reflection entries written / Agreements created or revised
- Connections active at start vs. end of year
- Emotional arc summary in one line

### Sharing Design

- **Private first** by default — the full experience is personal
- **Shareable postcards** designed to carry meaning without requiring context. *"I logged compersion 23 times in 2025"* means everything to ENM people and reads as emotional growth to everyone else
- **Partner share** option — send your Year card to a partner so they can see your year from the inside. No comparison, no leaderboard. Just: *"here's what this year looked like for me"* — a conversation starter no other app can create

### Name

**Your Year, Lightly** — the app handing something back to you, not performing for you.

---

## 22. Professional-Grade Engineering — Guardrails for Vibe Coders

> **Context:** This section exists because vibe coding + AI assistants can produce apps that look finished but have silent, catastrophic failure modes. This app stores the most sensitive data users will ever hand an app. The bar is higher than a to-do list. These rules are the difference between a hobby project and a shippable product.

---

### The Core Problem With Vibe Coding

AI writes code that works for the happy path. It doesn't write code that handles the 37 things that can go wrong. You have to know what questions to ask — and this section gives you those questions.

**The pattern to break:**
```
❌ Vibe: Write code → it works in simulator → ship it
✅ Professional: Write code → ask "what happens when this fails?" → handle failure → test edge cases → then ship
```

---

### 1. Error Handling — The #1 Vibe Coder Blind Spot

AI-generated code almost always has this pattern:
```swift
// What AI writes (dangerous)
let data = try await supabase.from("profiles").select().execute()

// What it should be
do {
    let data = try await supabase.from("profiles").select().execute()
} catch {
    // Log it. Show user something meaningful. Don't crash silently.
    logger.error("Profile fetch failed: \(error.localizedDescription)")
    await MainActor.run { self.errorState = .networkFailure }
}
```

**Every network call needs:**
- A success path
- A failure path
- A loading state
- A retry mechanism (or at least a retry button)

**The three states every async view needs:**
```
.loading   → show skeleton / spinner
.loaded    → show content
.error     → show "Something went wrong" + retry button (NOT a blank screen)
```

A blank white screen when the network fails isn't UX — it's a bug that looks like a feature.

---

### 2. SwiftData Safety — Silent Data Destruction

SwiftData schema changes are the most dangerous thing you can do to existing users. A model change that worked fine in your simulator will wipe a real user's data if migrated wrong.

**The rule: Every SwiftData model change that isn't purely additive requires a migration plan.**

| Change Type | Safe? | What to Do |
|-------------|-------|-----------|
| Add a new optional property | ✅ Safe | Just add it |
| Add a new required property | ⚠️ Dangerous | Must provide default value or migration |
| Rename a property | ❌ Destructive | Write a `MigrationPlan` with `MigrationStage` |
| Change a property type | ❌ Destructive | Write a migration |
| Delete a property | ⚠️ Careful | Data is gone — intentional? |
| Rename a model | ❌ Destructive | Write a migration |

**What a migration looks like:**
```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]

    static var stages: [MigrationStage] = [
        migrateV1toV2
    ]

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // transform data here
        }
    )
}
```

**Before shipping any model change:** Delete the app from your simulator, reinstall fresh, verify the new schema works from scratch. Then verify migration from the old schema works.

---

### 3. Main Thread Violations — The Crash You Won't See in Testing

SwiftUI requires UI updates on the main thread. Supabase callbacks and async operations often return on background threads. Violating this crashes the app — sometimes immediately, sometimes randomly in production.

```swift
// ❌ Crashes in production (fine in simulator sometimes)
func fetchProfile() async {
    let profile = try await profileService.fetch()
    self.userProfile = profile  // ← UI update on background thread
}

// ✅ Correct
func fetchProfile() async {
    let profile = try await profileService.fetch()
    await MainActor.run {
        self.userProfile = profile
    }
}
```

**The rule:** Any property marked `@Published` or that drives SwiftUI views must only be mutated on `@MainActor`. Mark your ViewModels `@MainActor` at the class level to prevent the entire class of bugs:

```swift
@MainActor
class SessionViewModel: ObservableObject {
    @Published var cards: [PromptCard] = []
    // All mutations here are automatically main-thread safe
}
```

---

### 4. The Empty State Problem

Every list, every collection, every result set can be empty. Vibe coders handle the case where data exists. Professional apps handle all three cases:

| State | What to Show |
|-------|-------------|
| Loading | Skeleton / spinner |
| Empty (no data yet) | Helpful message + CTA ("No sessions yet — start your first one") |
| Empty (no results for filter) | Explanation ("Nothing matches") |
| Error | "Something went wrong" + retry |
| Has data | The actual content |

A `ForEach` over an empty array shows nothing. Users think the app is broken.

```swift
// Always wrap lists with state awareness
if cards.isEmpty && !isLoading {
    EmptyStateView(message: "No cards yet. Start a session to explore.")
} else {
    ForEach(cards) { card in CardView(card: card) }
}
```

---

### 5. Sensitive Data Must Never Hit the Console

Xcode's console and `print()` statements are your friend during development. They are a data breach in production.

**Never log:**
- Kink ratings or any assessment answers
- User names paired with relationship data
- Authentication tokens or session IDs
- Pairing codes
- Any property from `UserProfile` beyond `id`

**Use a proper logger:**
```swift
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "Sessions")

// Safe — category only, no user data
logger.info("Session started")

// NEVER do this
print("User \(user.name) rated kink item \(kinkItem.title) as \(rating)")
```

**Before shipping:** Search the entire codebase for `print(` and audit every single one. Remove or replace with `logger`. Build for release and check the console — if sensitive data appears there, it's a bug.

---

### 6. Git Hygiene — One Mistake That Can't Be Undone

Secrets pushed to git are compromised, full stop. Rotate them immediately. Deleting the commit doesn't help — git history is forever, and bots scrape GitHub for secrets within minutes of a push.

**Your `.gitignore` must include:**
```
# Secrets
Config.xcconfig
*.xcconfig
.env
Secrets.plist

# Xcode noise
*.xcuserstate
xcuserdata/
DerivedData/

# OS junk
.DS_Store
```

**The `Config.xcconfig` pattern for secrets:**
```
// Config.xcconfig (git-ignored)
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

```swift
// Config.swift — reads from build settings, never hardcodes
struct Config {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
}
```

**Branching strategy (simple, actually follow it):**
```
main          → only tested, working code. Never commit directly.
dev           → integration branch. Test here before merging to main.
feature/xxx   → one branch per feature. Merge via PR to dev.
```

---

### 7. Two Environments: Dev and Production

The #1 way vibe coders corrupt real user data: running development builds against the production database.

**You need two Supabase projects:**
- `openlightly-dev` — your sandbox. Blow it up, reset it, experiment freely.
- `openlightly-prod` — real users. Touch only for intentional releases.

**How to switch:**
```
// Dev scheme → points to openlightly-dev Supabase
// Prod scheme → points to openlightly-prod Supabase

// In Xcode: Product → Scheme → Manage Schemes
// Create "Open Lightly Dev" and "Open Lightly Prod"
// Each scheme uses a different Config.xcconfig
```

**The rule:** Run the Dev scheme 99% of the time. Switch to Prod only for TestFlight builds and releases. If you're ever unsure which environment you're pointed at, check before touching the database.

---

### 8. StoreKit Testing — Don't Find Out at Submission

StoreKit is the most "works in simulator, breaks in production" layer in iOS development.

**Testing checklist before submission:**
```
□ Test purchase flow with StoreKit sandbox (not simulator mock)
□ Test restore purchases on a fresh device (users WILL do this when they get a new phone)
□ Test what happens when a purchase is interrupted (network drops mid-transaction)
□ Test subscription expiry — does the app correctly downgrade access?
□ Test family sharing (does one family member's purchase unlock for others? Is that intended?)
□ Verify receipt validation happens server-side, not just client-side
□ Test with a StoreKit sandbox account, not your Apple ID
```

**Receipt validation:** If you validate purchases client-side only, users can spoof receipts and get paid content for free. For this app's scale, client-side validation is acceptable at launch — but document it as a known limitation to address before scaling.

---

### 9. App Store Submission — Common Rejection Reasons

Apple rejects apps for predictable reasons. Know them before you submit.

| Rejection Reason | How to Avoid |
|-----------------|-------------|
| **Guideline 1.1.6** — Dating/social apps must have content moderation | This is NOT a dating app — make sure the App Store listing, screenshots, and app description are clear about that. |
| **Guideline 5.1.1** — Privacy policy required | Write one before submission. It must accurately describe all data collected and how it's used. |
| **Guideline 3.1.1** — All digital goods sold via IAP | You cannot use Stripe, PayPal, etc. for in-app purchases. StoreKit only. |
| **Guideline 2.1** — App crashes or has major bugs | Test on a real device (not just simulator). Test every purchase flow. |
| **Guideline 5.1.2** — Sensitive data handling | Must have a privacy policy link in the App Store listing AND in the app. |
| **Guideline 2.3.3** — App description misleading | Screenshots must show actual app UI, not mockups. |
| **Guideline 4.2** — Minimum functionality | Free tier must have enough functionality to demonstrate value. |
| **Metadata rejection** — screenshots too similar | Every screenshot must show clearly different content. |

**Before submitting, run your App Store listing through this lens:**
> "Does this sound like a hook-up app, a therapy app, or a sex app?"

It must sound like none of those. It's a conversation tool for couples. Review every word of the listing with that framing.

---

### 10. Memory Management — Retain Cycles

SwiftUI and `@Observable` handle most memory management automatically. But `async`/`await` and closures can still create retain cycles that silently grow your app's memory footprint.

**The pattern to watch:**
```swift
// ❌ Potential retain cycle — self holds task, task holds self
func loadCards() {
    Task {
        self.cards = await fetchCards()  // strong capture of self
    }
}

// ✅ Weak capture when appropriate
func loadCards() {
    Task { [weak self] in
        guard let self else { return }
        self.cards = await fetchCards()
    }
}
```

**How to detect:**
- In Xcode: Debug → Memory Graph Debugger during a session
- Look for objects that should have been deallocated still showing up
- Use Instruments → Leaks for a full leak report before submission

---

### 11. Accessibility — Not Optional

Apple reviews for accessibility. Users with disabilities use your app. And VoiceOver users in the NM community exist.

**Minimum requirements:**
```swift
// Every interactive element needs a label
Button(action: skipCard) {
    Image(systemName: "forward.fill")
}
.accessibilityLabel("Skip this card")

// Images that convey meaning need descriptions
Image("desire-map-result")
    .accessibilityLabel("Desire map showing high compatibility in emotional connection")

// Images that are decorative should be hidden
Image("background-gradient")
    .accessibilityHidden(true)
```

**Test with VoiceOver (Settings → Accessibility → VoiceOver):** Navigate the entire onboarding flow without looking at the screen. If you can't complete it, real users can't either.

**Dynamic Type:** Go to Settings → Accessibility → Display & Text Size → Larger Text → max out the slider. Run your app. If text clips, overlaps, or disappears, you have layout bugs.

---

### 12. Offline Behavior — Design for No Connection

Users will open this app in a cabin, on a plane, in bed with their phone on airplane mode. The app must not be useless offline.

**Local-first architecture (already your model) means:**
- App loads from SwiftData without network → show local data immediately
- Network sync happens in background
- If sync fails → local data is still visible → show a subtle "Sync pending" indicator
- Never show a loading spinner indefinitely — set a timeout (10-15 seconds) and show an error state

**The offline checklist:**
```
□ Turn on airplane mode
□ Open the app
□ Does it load? (It should — from SwiftData)
□ Can you start a session? (Yes — cards are local)
□ What happens when you complete a card? (Queues for sync)
□ Turn wifi back on
□ Does queued data sync? (SyncManager handles this)
□ Is nothing lost? (The answer must be yes)
```

---

### 13. Testing — The Minimum You Actually Need

You don't need 100% test coverage. You need tests for the things that will ruin your users' experience if they break.

**Write tests for:**

| What | Why |
|------|-----|
| Hard No never included in kink match payload | The #1 privacy guarantee. If this breaks silently, you've violated user trust catastrophically. |
| Pairing code format validation | Bad codes cause failed pairings. Users blame the app. |
| Assessment score calculation | Wrong scores feed wrong content routing. The whole personalization engine breaks. |
| SwiftData model persistence | Basic smoke test: save a UserProfile, restart the container, verify it's still there. |
| StoreKit entitlement checks | Verify paid content gates work. Verify free users can't access paid content. |

```swift
// Example: The most important test in the app
func testHardNoNeverIncludedInMatchPayload() {
    let ratings = [
        KinkRating(itemId: "item1", rating: .love),
        KinkRating(itemId: "item2", rating: .hardNo),  // Must never appear in payload
        KinkRating(itemId: "item3", rating: .curious),
    ]
    let payload = KinkMatchService.buildPayload(from: ratings)
    XCTAssertFalse(payload.contains(where: { $0.itemId == "item2" }),
                   "Hard No item must never be included in sync payload")
}
```

**How to run:** Cmd+U in Xcode. Run before every TestFlight build.

---

### 14. Crash Reporting — Know When Your App Breaks in the Wild

You won't be there when real users hit bugs. You need to be notified.

**At minimum: Enable Xcode Organizer crash reports**
- Xcode → Window → Organizer → Crashes
- Apple sends you symbolicated crash reports automatically for App Store builds
- Check this weekly after launch

**Better: Add a free crash reporter**
- [Crashlytics (Firebase)](https://firebase.google.com/products/crashlytics) — free, industry standard
- Zero data privacy concerns (just crash stack traces, no user data)
- Setup is ~30 minutes: add SDK, one line in `AppDelegate`/`App.swift`, done
- You get an email every time a new crash type is discovered

**The rule:** Never go more than a week post-launch without checking crash reports.

---

### 15. Performance — Profile Before It's Too Late

Slow apps get deleted. The simulator lies — it runs on a Mac CPU. Real iPhones, especially older models (iPhone 12, iPhone 13), will expose performance issues the simulator hides.

**Test on a real device — specifically:**
- The oldest iPhone you want to support
- iPhone with low storage (< 5GB free) — storage pressure slows SwiftData
- While other apps are running in background

**Instruments (Xcode → Open Developer Tool → Instruments):**

| Instrument | What It Catches |
|------------|----------------|
| Time Profiler | Functions taking too long (scroll lag, slow loads) |
| Core Data / SwiftData | Slow fetches, N+1 query problems |
| Leaks | Objects that should be freed but aren't |
| Network | Unnecessary requests, slow API calls |

**The one SwiftData performance mistake to avoid:**
```swift
// ❌ N+1 problem — fetches each card separately in a loop
for session in sessions {
    let cards = session.cards  // Each access triggers a fetch
}

// ✅ Fetch everything you need upfront with a predicate
@Query(sort: \.createdAt, order: .reverse) var sessions: [SessionRecord]
// SwiftData pre-fetches relationships when declared this way
```

---

### 16. The Vibe Coder Anti-Pattern Checklist

Run through this before every significant PR or TestFlight build:

```
SECURITY
□ No hardcoded API keys, passwords, or secrets anywhere in the code
□ `Config.xcconfig` is in .gitignore and not in the git history
□ `print()` statements don't log any user data
□ Service role key is not in any client-side file

DATA SAFETY
□ No SwiftData model changes without a migration plan
□ Tested fresh install (delete app, reinstall, verify onboarding works)
□ Tested upgrade from previous version (don't delete, just update)
□ Hard No kink ratings never included in any server payload

ERROR HANDLING
□ Every async function has a do/catch or .catch handler
□ Every view has a loading state, empty state, and error state
□ No force-unwrap `!` on values that could realistically be nil
□ Network failures show a user-facing message, not a blank screen

UI/UX
□ Tested with airplane mode on
□ Tested with Dynamic Type at maximum size
□ Tested with VoiceOver on (at least onboarding)
□ Tested on a real device (not just simulator)
□ All lists handle empty state gracefully

PERFORMANCE
□ No blocking operations on the main thread (no `Thread.sleep`, no heavy sync work)
□ Heavy work (JSON parsing, encryption, sync) runs on background Task
□ Scrollable lists use lazy loading (LazyVStack, LazyVGrid, not VStack)

STORE
□ Tested purchase flow with StoreKit sandbox
□ Tested restore purchases on a fresh install
□ All paid content correctly gated behind entitlement check

BEFORE TESTFLIGHT
□ Build in Release configuration (not Debug)
□ Run on a real device in Release mode
□ Check Xcode Organizer for any existing crash reports
□ Run Cmd+U — all tests pass
```

---

### 17. The Questions to Ask Claude/AI When Vibe Coding

AI assistants write code that works. Your job is to ask the questions that surface what breaks. Add these to any prompt where you're implementing something real:

```
After every code generation, ask:
1. "What happens if this network call fails?"
2. "What happens if the user has no internet connection?"
3. "What happens if this data is nil or empty?"
4. "Is there any user data being logged or printed here?"
5. "Does this run on the main thread? Should it?"
6. "What happens if the user leaves this screen mid-operation?"
7. "Is there any way this could expose one user's data to another user?"
8. "What's the migration path if I need to change this SwiftData model later?"
```

These 8 questions, asked consistently, are worth more than a CS degree for shipping a safe, reliable app.

---

### 18. The Honest Scale of What You're Building

This isn't meant to intimidate — it's meant to calibrate:

| App Category | Consequences of a Bug |
|-------------|----------------------|
| To-do app | User re-enters a task |
| Social app | User sees wrong posts |
| **This app** | User's kink preferences exposed to their partner, therapist, family, employer |

The stakes are genuinely high. The data is genuinely sensitive. That's not a reason not to build it — it's a reason to build it right.

The professional bar isn't about having a CS degree. It's about knowing which questions to ask and building the habits (error handling, environment separation, testing the unhappy path) that prevent silent failures.

You have something most CS graduates don't: you understand your users deeply, you've thought carefully about ethics, and you have domain knowledge that can't be taught in a classroom. The technical guardrails above can be learned. The judgment you bring to the product is harder to acquire.

**Build carefully. Ship confidently.**

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift` {#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift}

```swift
//
//  OnboardingCuriosityPickerView.swift
//  Open Lightly
//

import SwiftUI

private enum ClusterPhase: Equatable {
    case set1Active
    case set2Active
    case exiting
}

// Scatter slots — 2-column organic layout with hand-tuned positions
private struct ScatterSlot {
    let xFrac:    CGFloat
    let yPt:      CGFloat
    let baseRot:  Double
    let scale:    CGFloat
}

private let set1Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  70,  baseRot: -1.2, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt:  55,  baseRot:  0.8, scale: 0.97),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot:  0.5, scale: 1.02),
    ScatterSlot(xFrac: 0.52,  yPt: 215,  baseRot: -0.7, scale: 0.98),
    ScatterSlot(xFrac: 0.28,  yPt: 375,  baseRot: -0.8, scale: 1.00),
]

private let set2Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  65,  baseRot:  1.1, scale: 0.98),
    ScatterSlot(xFrac: 0.52,  yPt:  48,  baseRot: -0.9, scale: 1.01),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot: -0.6, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt: 218,  baseRot:  1.3, scale: 0.97),
    ScatterSlot(xFrac: 0.28,  yPt: 385,  baseRot:  0.6, scale: 1.00),
]

struct OnboardingCuriosityPickerView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // MARK: - Selection
    @State private var selectedSet1: Set<String> = []
    @State private var selectedSet2: Set<String> = []
    @State private var clusterPhase: ClusterPhase = .set1Active

    // MARK: - Scroll
    @State private var scrollOffset: CGFloat = 0
    @State private var lastOffset:   CGFloat = 0
    @State private var seam:         CGFloat = 0

    // MARK: - UI
    @State private var headerVisible:    Bool    = false
    @State private var cardsVisible:     Bool    = false
    @State private var navHeaderHeight:  CGFloat = 230
    @State private var headerMeasured:   Bool    = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Atmosphere progress 0→1 as user scrolls set1→set2
    private var atmosphereProgress: CGFloat {
        guard seam > 0 else { return 0 }
        return max(0, min(1, scrollOffset / seam))
    }

    private var atmosphereCyanOpacity:    Double { Double(1 - atmosphereProgress) * (isLight ? 0.10 : 0.20) }
    private var atmosphereMagentaOpacity: Double { Double(atmosphereProgress)     * (isLight ? 0.10 : 0.20) }

    // MARK: - Flash intensity — bell curve peaking at crossfade midpoint
    // Essentially zero by progress=0.25 and progress=0.75
    private var flashIntensity: CGFloat {
        guard seam > 0 else { return 0 }
        let p = atmosphereProgress
        return exp(-18 * pow(p - 0.5, 2))
    }

    // MARK: - Responsive font sizes
    private var headerTitleSize: CGFloat {
        UIScreen.main.bounds.width <= 375 ? 18 : 22
    }

    private var headerSubtitleSize: CGFloat {
        UIScreen.main.bounds.width <= 375 ? 12 : 14
    }

    // MARK: - Helpers
    private var hasSelection: Bool  { !selectedSet1.isEmpty && !selectedSet2.isEmpty }
    private var totalSelected: Int  { selectedSet1.count + selectedSet2.count }
    private var config: CuriosityScreenConfig { data.curiosityScreenConfig }

    // MARK: - LivingText gradient stops — single source of truth
    private var livingGradientColors: [Color] {
        isLight
            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta]
    }

    // MARK: - Device-adaptive scaling
    private func scaledSlots(_ slots: [ScatterSlot], screenW: CGFloat) -> [ScatterSlot] {
        // Only scale DOWN for small screens — large screens don't need bigger gaps
        let yScale = min(max(screenW / 390, 0.85), 1.0)
        return slots.map { slot in
            ScatterSlot(
                xFrac:   slot.xFrac,
                yPt:     slot.yPt * yScale,
                baseRot: slot.baseRot,
                scale:   slot.scale
            )
        }
    }

    // MARK: - Card specs
    private enum CardSet { case set1, set2 }

    private struct CardSpec: Identifiable {
        let id:         String
        let lead:       String
        let full:       String
        let slot:       ScatterSlot
        let floatPhase: Double
        let set:        CardSet
    }

    private func cardSpecs(screenH: CGFloat, screenW: CGFloat) -> [CardSpec] {
        let s1slots = scaledSlots(set1Slots, screenW: screenW)
        let s2slots = scaledSlots(set2Slots, screenW: screenW)
        let s1 = Array(config.section1Options.prefix(5))
        let s2 = Array(config.section2Options.prefix(5))
        var out: [CardSpec] = []
        for (i, opt) in s1.enumerated() {
            out.append(CardSpec(
                id:         opt.id,
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s1slots[i % s1slots.count],
                floatPhase: Double(i) * 0.8,
                set:        .set1
            ))
        }
        for (i, opt) in s2.enumerated() {
            out.append(CardSpec(
                id:         opt.id + "_s2",
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s2slots[i % s2slots.count],
                floatPhase: Double(i) * 0.8 + 0.4,
                set:        .set2
            ))
        }
        return out
    }

    private func isSelected(_ spec: CardSpec) -> Bool {
        switch spec.set {
        case .set1: return selectedSet1.contains(spec.id)
        case .set2: return selectedSet2.contains(String(spec.id.dropLast(3)))
        }
    }

    private func toggle(_ spec: CardSpec) {
        guard clusterPhase != .exiting else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch spec.set {
        case .set1:
            if selectedSet1.contains(spec.id) { selectedSet1.remove(spec.id) }
            else { selectedSet1.insert(spec.id) }
        case .set2:
            let raw = String(spec.id.dropLast(3))
            if selectedSet2.contains(raw) { selectedSet2.remove(raw) }
            else { selectedSet2.insert(raw) }
        }
    }

    // MARK: - Float
    // More amplitude (3→5pt Y, 0.2→0.35 rot)
    // Each card gets its own tick multiplier offset — never in sync
    private func floatY(_ spec: CardSpec, tick: Double) -> CGFloat {
        let speedVariance = 0.009 + (spec.floatPhase.truncatingRemainder(dividingBy: 3)) * 0.002
        return CGFloat(sin(spec.floatPhase + tick * speedVariance) * 5)
    }

    private func floatRot(_ spec: CardSpec, tick: Double) -> Double {
        let speedVariance = 0.006 + (spec.floatPhase.truncatingRemainder(dividingBy: 2)) * 0.002
        return sin(spec.floatPhase + tick * speedVariance) * 0.35
    }

    private func gravity(_ spec: CardSpec) -> CGSize {
        guard isSelected(spec) else { return .zero }
        return CGSize(width: spec.slot.xFrac > 0.4 ? 10 : -10, height: 0)
    }

    // MARK: - Card width
    private func cardW(for spec: CardSpec, canvasW: CGFloat) -> CGFloat {
        canvasW * 0.44 * spec.slot.scale
    }

    // MARK: - Tint / border
    private func cardTint(_ spec: CardSpec) -> Color {
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.04 : 0.05)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.04 : 0.05)
        }
    }
    private func cardBorder(_ spec: CardSpec) -> Color {
        guard !isSelected(spec) else { return .clear }
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.18 : 0.14)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.18 : 0.14)
        }
    }

    // MARK: - Data / continue
    private func commitData() {
        data.communicationGoals = config.section1Options
            .filter { selectedSet1.contains($0.id) }.map(\.id).sorted()
        data.learningGoals = config.section2Options
            .filter { selectedSet2.contains($0.id) }.map(\.id).sorted()
        data.curiositySelections = data.communicationGoals + data.learningGoals
    }

    private func handleContinue() {
        commitData()
        withAnimation(.easeInOut(duration: 0.3)) { clusterPhase = .exiting }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onContinue?() }
    }

    // MARK: - Dimensions
    private func sectionHeight(screenW: CGFloat) -> CGFloat {
        let scale = min(max(screenW / 390, 0.85), 1.0)
        return (385 + 90 + 95) * scale  // lastYPt + cardH + buffer for seam/margin
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let h   = geo.size.height
            let w   = geo.size.width
            let top = geo.safeAreaInsets.top
            let bot = geo.safeAreaInsets.bottom

            ZStack(alignment: .top) {

                // ── Atmosphere ────────────────────────────────────────
                ZStack {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.cyan.opacity(atmosphereCyanOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.25)
                        .blur(radius: 70)
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.magenta.opacity(atmosphereMagentaOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.78)
                        .blur(radius: 70)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // ── Scroll canvas ─────────────────────────────────────
                infiniteCanvas(w: w, h: h, top: top)
                    .frame(width: w, height: h)
                    .ignoresSafeArea()

                // ── Fixed nav + header ────────────────────────────────
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        OnboardingNavBar(
                            currentStep: 4,
                            totalSteps:  6,
                            onBack:      onBack
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, top + 8)
                        .padding(.bottom, OL.navBottom(h))

                        headerBlock
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                            .opacity(headerVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: headerVisible)
                    }
                    .background(
                        GeometryReader { navGeo in
                            Color.clear.onAppear {
                                guard !headerMeasured else { return }
                                headerMeasured  = true
                                navHeaderHeight = navGeo.size.height + 20
                            }
                        }
                    )

                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

                // ── Selection count pill — top right, below nav ───────────
                VStack {
                    HStack {
                        Spacer()
                        selectionPill
                            .padding(.top, top + 14)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .zIndex(20)

                // ── Fixed CTA ─────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    bottomZone
                        .padding(.horizontal, 24)
                        .padding(.bottom, bot + 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0),
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0.96),
                                ],
                                startPoint: .top,
                                endPoint:   .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { headerVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.30)) { cardsVisible  = true }
            }
        }
    }

    // MARK: - Infinite canvas

    @ViewBuilder
    private func infiniteCanvas(w: CGFloat, h: CGFloat, top: CGFloat) -> some View {
        let secH     = sectionHeight(screenW: w)
        let seamGap: CGFloat = -90  // was 60
        let topPad:  CGFloat = navHeaderHeight
        let totalH   = topPad + secH + seamGap + secH + 10

        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {

                // ── Scroll tracker ────────────────────────────────────
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let restingY = proxy.frame(in: .global).minY
                            Task { @MainActor in
                                if seam == 0 { seam = secH * 0.74 }
                                lastOffset = restingY
                            }
                        }
                        .onChange(of: proxy.frame(in: .global).minY) { _, currentY in
                            let offset = lastOffset - currentY
                            scrollOffset = max(0, offset)
                            // Keep clusterPhase in sync for card hit-testing
                            let inSet2 = scrollOffset >= seam
                            let target: ClusterPhase = inSet2 ? .set2Active : .set1Active
                            if clusterPhase != target && clusterPhase != .exiting {
                                clusterPhase = target
                            }
                        }
                }
                .frame(width: w, height: 0)

                // ── Animated cards ────────────────────────────────────
                TimelineView(.animation(minimumInterval: 1/30,
                                        paused: clusterPhase == .exiting)) { tl in
                    let tick = tl.date.timeIntervalSinceReferenceDate * 60

                    ZStack(alignment: .topLeading) {
                        Color.clear.frame(width: w, height: totalH)

                        // Set 1
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set1 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = topPad + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }

                        // Set 2
                        let set2Origin = topPad + secH + seamGap
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set2 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = set2Origin + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }
                    }
                    .frame(width: w, height: totalH)
                }
            }
        }
        .frame(width: w, height: h)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.15),
                    .init(color: .black, location: 1.00),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
        )
        .opacity(cardsVisible ? 1 : 0)
    }

    // MARK: - Individual card

    @ViewBuilder
    private func cardView(spec: CardSpec, tick: Double, cw: CGFloat) -> some View {
        let selected = isSelected(spec)
        let opacity: Double = clusterPhase == .exiting ? 0 : 1

        ZStack {
            FloatingCard(
                spec: FloatingCardSpec(
                    id:         spec.id,
                    lead:       spec.lead,
                    full:       spec.full,
                    xFrac:      Double(spec.slot.xFrac),
                    yFrac:      Double(spec.slot.yPt),
                    floatPhase: spec.floatPhase
                ),
                isSelected:    selected,
                floatY:        floatY(spec, tick: tick),
                floatRot:      floatRot(spec, tick: tick),
                gravity:       gravity(spec),
                tick:          tick,
                targetOpacity: opacity,
                cardWidth:     cw,
                tintColor:     cardTint(spec),
                onTap:         { toggle(spec) }
            )

            // ...existing code...
        }
        .allowsHitTesting(opacity > 0.3)
        .animation(.easeInOut(duration: 0.35), value: clusterPhase)
    }

    // MARK: - Fixed header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topLeading) {

                // Flash bloom — uses LivingText palette, direction-aware
                // cyan-weighted entering, magenta-weighted exiting
                LinearGradient(
                    colors: [
                        AppColors.cyan.opacity(flashIntensity * (1 - atmosphereProgress) * 0.25),
                        AppColors.purpleVivid.opacity(flashIntensity * 0.25),
                        AppColors.magenta.opacity(flashIntensity * atmosphereProgress * 0.25),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .blur(radius: 10 + flashIntensity * 14)
                .frame(height: 50)
                .padding(.horizontal, -16)
                .padding(.vertical, -12)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {

                    // Title crossfade with living gradient flash
                    ZStack(alignment: .topLeading) {
                        liveLabelTitle(
                            config.section1Label,
                            opacity: 1 - atmosphereProgress,
                            flash:   flashIntensity * (1 - atmosphereProgress)
                        )
                        liveLabelTitle(
                            config.section2Label,
                            opacity: atmosphereProgress,
                            flash:   flashIntensity * atmosphereProgress
                        )
                    }
                    .frame(height: 32)
                    .scaleEffect(1 + flashIntensity * 0.012, anchor: .leading)
                    .clipped()

                    // Subtitle crossfade — plain opacity, no gradient needed
                    ZStack(alignment: .topLeading) {
                        liveLabelSubtitle(config.section1Sublabel,
                                          opacity: 1 - atmosphereProgress)
                        liveLabelSubtitle(config.section2Sublabel,
                                          opacity: atmosphereProgress)
                    }
                    .frame(height: 22)
                    .padding(.top, 5)
                    .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Title label

    @ViewBuilder
    private func liveLabelTitle(_ text: String,
                                opacity: CGFloat,
                                flash: CGFloat) -> some View {
        ZStack {
            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(isLight
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .opacity(1 - flash)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 5)
                .opacity(flash * 0.40)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 2)
                .opacity(flash * 0.80)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .opacity(flash)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .modifier(GlowUnderline(isLight: isLight, flash: flash))
        .opacity(opacity)
    }

    // MARK: - Subtitle label

    @ViewBuilder
    private func liveLabelSubtitle(_ text: String, opacity: CGFloat) -> some View {
        Text(text)
            .font(AppFonts.body(headerSubtitleSize, weight: .regular))
            .foregroundStyle(isLight
                ? AppColors.lightTextSecondary
                : AppColors.textSecondary)
            .opacity(opacity)
    }

    // MARK: - Selection count pill
    private var selectionPill: some View {
        HStack(spacing: 6) {
            Text("\(totalSelected)")
                .font(AppFonts.body(16, weight: .semibold))
                .foregroundStyle(isLight ? AppColors.wineDark : Color.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: totalSelected)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isLight ? AppColors.lightFrostPill : AppColors.surfaceBg)
        .overlay {
            if isLight {
                LightModeShimmer(duration: 4.0, usePillColors: true)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            } else {
                HolographicShimmer(duration: 4.0)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(Capsule())
        .overlay {
            if isLight {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: livingGradientColors.map { $0.opacity(0.78) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
            } else {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
            }
        }
        .shadow(color: isLight
            ? AppColors.magenta.opacity(0.18)
            : AppColors.purple.opacity(0.25),
                radius: 12, x: 0, y: 4)
        .opacity(totalSelected > 0 ? 1 : 0)
        .scaleEffect(totalSelected > 0 ? 1 : 0.85, anchor: .topTrailing)
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: totalSelected > 0)
    }

    // MARK: - Bottom zone

    private var bottomZone: some View {
        VStack(spacing: 8) {
            HoloCTAButton(
                title:   "Continue",
                isEnabled: hasSelection,
                action:    { handleContinue() }
            )
            .animation(.easeInOut(duration: 0.4), value: hasSelection)

            OnboardingFooter()
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Previews

#Preview("Dark — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — Couple") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/CuriosityPill.swift` {#file-open-lightly-features-onboarding-components-curiositypill-swift}

```swift
//
//  CuriosityPill.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPill.swift
//  Open Lightly
//
//  Selectable pill for the curiosity picker panels.
//  Shows a gradient checkmark when selected.
//  Border and background adapt to content type and selection state.
//

import SwiftUI

struct CuriosityPill: View {
    let option:     CuriosityOption
    let isSelected: Bool
    let pillHeight: CGFloat
    let onTap:      () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    
    private var accentColor: Color {
        switch option.contentType {
        case .quiz, .desireMap: return AppColors.magenta
        default:                return AppColors.cyan
        }
    }
    
    private var darkSelectedBorder: LinearGradient {
        switch option.contentType {
        case .quiz, .desireMap:
            return LinearGradient(
                colors: [AppColors.magenta, AppColors.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                
                // ── Icon slot ─────────────────────────────────────────
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                isLight
                                ? AnyShapeStyle(AppColors.magenta)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            )
                            .shadow(
                                color: isLight
                                ? AppColors.magenta.opacity(0.40)
                                : AppColors.cyan.opacity(0.55),
                                radius: 6
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 14, height: 14)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                .accessibilityHidden(true)
                
                // ── Label ─────────────────────────────────────────────
                Text(option.label)
                    .font(UIScreen.main.bounds.width <= 375
                          ? AppFonts.display(13, weight: .regular)
                          : AppFonts.buttonLabel)
                    .foregroundStyle(
                        isSelected
                        ? (isLight
                           ? AnyShapeStyle(AppColors.lightCardTitle)
                           : AnyShapeStyle(AppColors.textPrimary))
                        : (isLight
                           ? AnyShapeStyle(AppColors.wineDark)
                           : AnyShapeStyle(AppColors.textBright))
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)   // true — lets height grow
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: pillHeight + 8)   // min not fixed — grows for two-line labels
            .background(pillBackground)
            .overlay(pillBorder)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .shadow(
            color: isSelected
            ? (isLight ? AppColors.lightShadowMagenta : accentColor.opacity(0.35))
            : .clear,
            radius: 10
        )
        .shadow(
            color: isLight ? .clear : AppColors.pillGlow,
            radius: 8
        )
        .shadow(
            color: (!isSelected && option.isEmphasized && !isLight)
            ? AppColors.cyan.opacity(0.12)
            : .clear,
            radius: 6
        )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                isSelected
                ? (isLight
                   ? LinearGradient(
                    colors: [AppColors.lightFrostPillSel, AppColors.lightFrostPillSel],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [accentColor.opacity(0.08), AppColors.purple.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                : (isLight
                   ? LinearGradient(
                    colors: [AppColors.lightFrostPill, AppColors.lightFrostPill],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.09, blue: 0.16),
                        Color(red: 0.08, green: 0.07, blue: 0.13),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
    
    // MARK: - Border
    
    @ViewBuilder
    private var pillBorder: some View {
        if isSelected {
            if isLight {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 6)
                        .opacity(0.25)
                }
                .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
            }
        }
    }
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/CuriosityStatusStrip.swift` {#file-open-lightly-features-onboarding-components-curiositystatusstrip-swift}

```swift
//
//  CuriosityStatusStrip.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityStatusStrip.swift
//  Open Lightly
//
//  Panel indicator dots + selection count.
//  Sits between the card strip and the reassurance text.
//

import SwiftUI

struct CuriosityStatusStrip: View {
    let currentPanel:  Int
    let totalSelected: Int
    let isLight:       Bool
    let totalPanels:   Int = 2

    var body: some View {
        HStack(spacing: 10) {

            Spacer()

            // ── Page dots ─────────────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    let isActive = i == currentPanel
                    let dotW: CGFloat = isActive ? 28 : 8
                    let dotH: CGFloat = 8

                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                isActive
                                    ? Color.clear
                                    : (isLight
                                        ? Color.black.opacity(0.12)
                                        : Color.white.opacity(0.15))
                            )
                            .frame(width: dotW, height: dotH)

                        if isActive {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.clear)
                                .frame(width: dotW, height: dotH)
                                .overlay(
                                    Group {
                                        if isLight {
                                            LightModeShimmer(duration: 4, usePillColors: true)
                                        } else {
                                            HolographicShimmer(duration: 4)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 100))
                                )
                                .shadow(
                                    color: isLight
                                        ? AppColors.magenta.opacity(0.35)
                                        : AppColors.cyan.opacity(0.55),
                                    radius: 6
                                )
                        }
                    }
                    .frame(width: dotW, height: dotH)
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.80),
                        value: currentPanel
                    )
                }
            }

            // ── Selection count ───────────────────────────────────────
            if totalSelected > 0 {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(isLight
                            ? Color.black.opacity(0.10)
                            : Color.white.opacity(0.12))
                        .frame(width: 1, height: 10)

                    Text("\(totalSelected) selected")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle.opacity(0.40)
                                : Color(white: 0.90)
                        )
                }
                .transition(
                    .asymmetric(
                        insertion: .offset(x: 8).combined(with: .opacity),
                        removal:   .offset(x: 8).combined(with: .opacity)
                    )
                )
            }

            Spacer()
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: totalSelected > 0)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

#Preview("Dark — panel 0, 3 selected") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityStatusStrip(currentPanel: 0, totalSelected: 3, isLight: false)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — panel 1, 0 selected") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityStatusStrip(currentPanel: 1, totalSelected: 0, isLight: true)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/CuriosityPanelNudge.swift` {#file-open-lightly-features-onboarding-components-curiositypanelnudge-swift}

```swift
//
//  CuriosityPanelNudge.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPanelNudge.swift
//  Open Lightly
//
//  Contextual nudge shown below the status strip.
//  Guides the user toward completing both panels.
//

import SwiftUI

struct CuriosityPanelNudge: View {
    let s1Empty: Bool
    let s2Empty: Bool
    let isLight: Bool

    private var text: String? {
        if s1Empty && s2Empty  { return "Select from both panels to continue" }
        if !s1Empty && s2Empty { return "Swipe left — pick one more thing →" }
        if s1Empty && !s2Empty { return "← Swipe back — pick one thing there too" }
        return nil
    }

    var body: some View {
        ZStack {
            if let nudge = text {
                Text(nudge)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightCardTitle.opacity(0.35)
                            : AppColors.textTertiary
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .offset(y: 4)))
                    .id(nudge)
            }
        }
        .frame(height: 22)
        .animation(.easeOut(duration: 0.3), value: text)
        .padding(.bottom, 4)
    }
}

#Preview("Dark — s1 done") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityPanelNudge(s1Empty: false, s2Empty: true, isLight: false)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — both empty") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityPanelNudge(s1Empty: true, s2Empty: true, isLight: true)
    }
    .preferredColorScheme(.light)
}
```

---

## File: `Open Lightly/Features/Onboarding/Components/CuriosityPreviewLine.swift` {#file-open-lightly-features-onboarding-components-curiositypreviewline-swift}

```swift
//
//  CuriosityPreviewLine.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPreviewLine.swift
//  Open Lightly
//
//  Italic preview text shown beneath a selected pill.
//  Tells the user how their selection shapes their path.
//

import SwiftUI

struct CuriosityPreviewLine: View {
    let text:    String
    let isLight: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(AppFonts.caption)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AppColors.lightCardTitle.opacity(0.70)
                        : AppColors.textSecondary
                )
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isLight
                        ? AppColors.magenta.opacity(0.05)
                        : AppColors.cyan.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isLight
                                ? AppColors.magenta.opacity(0.12)
                                : AppColors.cyan.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .padding(.top, 8)
        .transition(.opacity.combined(with: .offset(y: 6)))
    }
}

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: false
        )
        .padding(24)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: true
        )
        .padding(24)
    }
    .preferredColorScheme(.light)
}
```

---

## File: `Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift` {#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift}

```swift
//
//  CuriosityScreenConfig.swift
//  Open Lightly
//
//  Drives OnboardingCuriosityPickerView.
//  Config is derived from OnboardingData — never hardcode mode checks in the view.
//

import Foundation

// MARK: - CuriosityScreenConfig

struct CuriosityScreenConfig {
    let section1Label: String
    let section1Sublabel: String
    let section2Label: String
    let section2Sublabel: String
    let section1Options: [CuriosityOption]
    let section2Options: [CuriosityOption]
    let showSection2: Bool

    init(
        section1Label: String,
        section1Sublabel: String,
        section2Label: String = "",
        section2Sublabel: String = "",
        section1Options: [CuriosityOption],
        section2Options: [CuriosityOption] = [],
        showSection2: Bool
    ) {
        self.section1Label    = section1Label
        self.section1Sublabel = section1Sublabel
        self.section2Label    = section2Label
        self.section2Sublabel = section2Sublabel
        self.section1Options  = section1Options
        self.section2Options  = section2Options
        self.showSection2     = showSection2
    }
}

// MARK: - CuriosityOption

struct CuriosityOption: Identifiable {
    let id: String
    let label: String
    let isEmphasized: Bool
    let contentType: LearningContentType
}

// MARK: - LearningContentType

enum LearningContentType {
    case communicationGoal
    case educationTrack
    case quiz(QuizType)
    case desireMap
    case reflectionTrack
}

// MARK: - QuizType

enum QuizType {
    case cnmStyleDiscovery
    case cnmReadiness
    case attachmentStyle
    case jealousyAnatomy
}

// MARK: - OnboardingData Extension

extension OnboardingData {
    /// Derives the correct screen config from explorationMode + relationshipContext.
    var curiosityScreenConfig: CuriosityScreenConfig {
        switch (explorationMode, relationshipContext) {
        case (.solo, .single):           return .soloSingleConfig
        case (.solo, .partneredOpen):    return .soloPartneredOpenConfig
        case (.solo, .partneredHidden):  return .soloPartneredHiddenConfig
        case (.solo, nil):               return .soloSingleConfig
        case (.couple, .notTalked):      return .coupleNotTalkedConfig
        case (.couple, .talking):        return .coupleTalkingConfig
        case (.couple, .someExperience): return .coupleSomeExperienceConfig
        case (.couple, .needsReset):     return .coupleNeedsResetConfig
        case (.couple, nil):             return .coupleNotTalkedConfig
        default:                         return .browsingConfig
        }
    }
}

// MARK: - Static Config Instances

extension CuriosityScreenConfig {

    // MARK: Solo — Single
    // Set 1: full emotional spectrum — excited through scared
    // Set 2: flavor, timing with new people, emotional entanglement,
    //         sexual health, where to find people open to this

    static let soloSingleConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "solo_s1_excited",
                label: "I've wanted to explore this for a long time and I'm finally doing something about it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_curious",
                label: "I keep thinking about it and I want to understand what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_neutral",
                label: "I'm not sure how I feel about it yet — I just know I'm not done thinking about it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_nervous",
                label: "I want this but I don't know if I'm the kind of person who can actually handle it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_scared",
                label: "I'm worried I'll want something my future partner won't",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "solo_s2_flavor",
                label: "I don't know which type of non-monogamy actually fits how I'm wired",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "solo_s2_timing",
                label: "I don't know when to bring it up with someone new",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s2_feelings",
                label: "I want to know how to explore this without catching feelings that complicate things",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "solo_s2_sti",
                label: "I want to understand sexual health and what actually being responsible looks like",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "solo_s2_find_people",
                label: "I want to know where people who are open to this actually are",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Open (Partner Knows)
    // Set 1: full emotional spectrum — shared curiosity through fear of feelings
    // Set 2: flavor for me individually, how to start exploring, emotional boundaries,
    //         sexual health with more people involved, conversations to have first

    static let soloPartneredOpenConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "partopen_s1_excited",
                label: "My partner knows and we're both genuinely curious — I want to understand it better",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_curious",
                label: "I keep coming back to certain ideas and I want to explore them more",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_neutral",
                label: "I'm open to it but I'm still figuring out what I actually want from it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_nervous",
                label: "I want to explore but I don't want to do anything that damages what we have",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_scared",
                label: "I'm worried about what happens if I feel something for someone else",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "partopen_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "partopen_s2_explore",
                label: "I want to know how to start exploring without it feeling like I'm going behind my partner's back",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s2_emotional",
                label: "I want to understand what emotional boundaries actually look like in practice",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "partopen_s2_sti",
                label: "I want to know what sexual health looks like when more than two people are involved",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "partopen_s2_conversations",
                label: "I want to know what conversations my partner and I should be having before anything happens",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Hidden (It's Complicated)
    // Set 1: full emotional spectrum — desire present, situation unspoken
    // Set 2: understanding options before saying anything, how to bring it up,
    //         emotional risk, sexual health, figuring out if this is real curiosity

    static let soloPartneredHiddenConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "parthidden_s1_excited",
                label: "The idea genuinely excites me — I just don't know what to do with that yet",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_curious",
                label: "I keep coming back to this and I can't tell if it's something real or just a fantasy",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_neutral",
                label: "I'm not unhappy. I'm just curious about something and I don't know what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_nervous",
                label: "I want to say something but I don't know how to bring it up without changing everything",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_scared",
                label: "I'm worried that wanting this means something is wrong with me or my relationship",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "parthidden_s2_flavor",
                label: "I want to understand what non-monogamy actually looks like before I say anything to anyone",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "parthidden_s2_conversation",
                label: "I want to know how people bring this up with a partner without it going sideways",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s2_emotional",
                label: "I want to understand the emotional risks before I open any of this up",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "parthidden_s2_sti",
                label: "I want to know what responsible sexual health looks like if this ever becomes real",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "parthidden_s2_real",
                label: "I want to figure out if what I'm feeling is curiosity or something I actually want to pursue",
                isEmphasized: false,
                contentType: .reflectionTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — Haven't Really Talked
    // Set 1: full emotional spectrum — one or both arriving at different readiness levels
    // Set 2: how to start the conversation, flavor for me individually,
    //         emotional risk, sexual health, what other people learned first

    static let coupleNotTalkedConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_nottalk_s1_excited",
                label: "We've been thinking about this and I'm genuinely excited to actually explore it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_curious",
                label: "I keep thinking about it and I want to understand what's actually drawing me to it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_neutral",
                label: "I'm open to exploring — I just want to make sure we do it thoughtfully",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_nervous",
                label: "I want this but I'm not sure I know how to handle the parts that are going to be hard",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_scared",
                label: "I'm worried about what happens to us if something doesn't go the way we planned",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_nottalk_s2_conversation",
                label: "I don't know how to start the conversation without it going sideways",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_learned",
                label: "I want to know what other people figured out before we try to figure it out ourselves",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Been Talking
    // Set 1: full emotional spectrum — talking has happened, readiness varies
    // Set 2: flavor for me, what conversations we should have, emotional navigation,
    //         sexual health, keeping new connections from threatening what we have

    static let coupleTalkingConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_talking_s1_excited",
                label: "We've been talking about this for a while and I'm genuinely excited to go deeper into it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_curious",
                label: "I keep thinking about it and I want to understand what's actually drawing me to it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_neutral",
                label: "I'm open to it — I just want to make sure I know what I'm actually agreeing to",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_nervous",
                label: "I want this but I'm not sure I know how to handle the parts that are going to be hard",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_scared",
                label: "I'm worried about what happens to us if something doesn't go the way we planned",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_talking_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_talking_s2_conversations",
                label: "I want to know what conversations my partner and I should be having before anything happens",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_talking_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_talking_s2_entanglement",
                label: "I want to understand how to keep new connections from threatening what my partner and I have",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Tried Some Things
    // Set 1: full emotional spectrum — experience exists, processing what happened
    // Set 2: flavor for me, what went wrong, emotional navigation,
    //         sexual health, handling asymmetric desire

    static let coupleSomeExperienceConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_exp_s1_excited",
                label: "We've done some of this and I want to keep going — smarter this time",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_curious",
                label: "Something came up that I didn't expect and I want to understand it better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_neutral",
                label: "It went okay. I want to understand what would make it go better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_nervous",
                label: "Something got harder than I expected and I'm not sure what to do with that",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_scared",
                label: "Something happened that I'm still processing and I don't know if we're okay",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_exp_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_exp_s2_went_wrong",
                label: "I want to understand what went sideways and why",
                isEmphasized: true,
                contentType: .reflectionTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_asymmetric",
                label: "I want to understand what to do when one person wants this more than the other",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We Need A Reset
    // Set 1: full emotional spectrum — something broke or drifted, range of where people land
    // Set 2: flavor for me now, how to rebuild the conversation, emotional repair,
    //         sexual health revisited, understanding what went wrong

    static let coupleNeedsResetConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_reset_s1_hopeful",
                label: "I still believe in what we're trying to build — I just think we need to rebuild the foundation",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_curious",
                label: "I want to understand what actually went wrong before we try anything again",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_neutral",
                label: "I'm not ready to give up on it — I just think we need a different approach",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_nervous",
                label: "I want to try again but I'm scared of ending up in the same place",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_scared",
                label: "I'm not sure we can come back from what happened and I don't know what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_reset_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me — separately from what we tried",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_reset_s2_conversation",
                label: "I want to know how to have this conversation again without it going the same way",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s2_emotional",
                label: "I want to understand the emotional risks and what we missed the first time",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_reset_s2_sti",
                label: "I want to revisit what sexual health actually looks like and make sure we're on the same page",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_reset_s2_went_wrong",
                label: "I want to understand what went wrong so we don't repeat it",
                isEmphasized: false,
                contentType: .reflectionTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Browsing
    // Set 1: general curiosity — no assumed relationship situation
    // Set 2: educational — all major googlable topics represented

    static let browsingConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "browsing_s1_excited",
                label: "I've been curious about this for a while and I want to actually understand it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_curious",
                label: "I keep coming back to certain ideas and I'm not sure what to do with that",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_neutral",
                label: "I don't know how I feel about it yet — I just want to understand it better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_nervous",
                label: "I'm interested but I'm not sure I'm the kind of person who could actually do this",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_scared",
                label: "The idea appeals to me but something about it also scares me",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "browsing_s2_flavor",
                label: "I want to understand the different types of non-monogamy and which might fit me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "browsing_s2_conversation",
                label: "I want to know how people actually start these conversations",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s2_feelings",
                label: "I want to understand how people manage feelings for more than one person",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "browsing_s2_sti",
                label: "I want to understand what sexual health actually looks like when more people are involved",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "browsing_s2_readiness",
                label: "I want to know if this is actually something I could do — or if I'm just curious",
                isEmphasized: false,
                contentType: .quiz(.cnmReadiness)
            ),
        ],
        showSection2: true
    )
}

// MARK: - Lead Phrase Map
// Short display label shown in summary/preview contexts.
// Key matches CuriosityOption.id.

extension CuriosityScreenConfig {

    static func leadPhrase(for id: String) -> String {
        leadPhrases[id] ?? id
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .prefix(4)
            .joined(separator: " ")
    }

    private static let leadPhrases: [String: String] = [

        // Solo Single — Set 1
        "solo_s1_excited":              "Finally doing something about it.",
        "solo_s1_curious":              "I keep thinking about it.",
        "solo_s1_neutral":              "Not done thinking about it.",
        "solo_s1_nervous":              "Can I actually handle it?",
        "solo_s1_scared":               "What if they don't want this?",

        // Solo Single — Set 2
        "solo_s2_flavor":               "Which type actually fits me?",
        "solo_s2_timing":               "When do I bring it up?",
        "solo_s2_feelings":             "Without catching the wrong feelings.",
        "solo_s2_sti":                  "What does being responsible look like?",
        "solo_s2_find_people":          "Where are these people?",

        // Solo Partnered Open — Set 1
        "partopen_s1_excited":          "We're both curious.",
        "partopen_s1_curious":          "I keep coming back to this.",
        "partopen_s1_neutral":          "Still figuring out what I want.",
        "partopen_s1_nervous":          "I don't want to damage what we have.",
        "partopen_s1_scared":           "What if I feel something for someone?",

        // Solo Partnered Open — Set 2
        "partopen_s2_flavor":           "Which type actually fits me?",
        "partopen_s2_explore":          "Without it feeling like a betrayal.",
        "partopen_s2_emotional":        "What do emotional boundaries look like?",
        "partopen_s2_sti":              "Sexual health with more people involved.",
        "partopen_s2_conversations":    "What should we talk about first?",

        // Solo Partnered Hidden — Set 1
        "parthidden_s1_excited":        "I just don't know what to do with it.",
        "parthidden_s1_curious":        "Real or just a fantasy?",
        "parthidden_s1_neutral":        "I'm not unhappy. Just curious.",
        "parthidden_s1_nervous":        "What if saying it changes everything?",
        "parthidden_s1_scared":         "Does wanting this mean something is wrong?",

        // Solo Partnered Hidden — Set 2
        "parthidden_s2_flavor":         "What does this even look like?",
        "parthidden_s2_conversation":   "How do people bring this up?",
        "parthidden_s2_emotional":      "What are the emotional risks?",
        "parthidden_s2_sti":            "What does responsible look like?",
        "parthidden_s2_real":           "Curiosity or something I want to pursue?",

        // Couple Not Talked — Set 1
        "couple_nottalk_s1_excited":    "I'm genuinely excited.",
        "couple_nottalk_s1_curious":    "What's drawing me to this?",
        "couple_nottalk_s1_neutral":    "Let's do this thoughtfully.",
        "couple_nottalk_s1_nervous":    "Can I handle the hard parts?",
        "couple_nottalk_s1_scared":     "What if something goes wrong?",

        // Couple Not Talked — Set 2
        "couple_nottalk_s2_conversation": "How do I start without it going sideways?",
        "couple_nottalk_s2_flavor":     "Which type actually fits me?",
        "couple_nottalk_s2_emotional":  "What are the emotional risks?",
        "couple_nottalk_s2_sti":        "Let's actually think through sexual health.",
        "couple_nottalk_s2_learned":    "What did others figure out first?",

        // Couple Talking — Set 1
        "couple_talking_s1_excited":    "Ready to go deeper.",
        "couple_talking_s1_curious":    "What's actually drawing me to this?",
        "couple_talking_s1_neutral":    "What am I actually agreeing to?",
        "couple_talking_s1_nervous":    "Can I handle the hard parts?",
        "couple_talking_s1_scared":     "What if something goes wrong?",

        // Couple Talking — Set 2
        "couple_talking_s2_flavor":     "Which type actually fits me?",
        "couple_talking_s2_conversations": "What should we talk about first?",
        "couple_talking_s2_emotional":  "What are the emotional risks?",
        "couple_talking_s2_sti":        "Let's actually think through sexual health.",
        "couple_talking_s2_entanglement": "How do I protect what we have?",

        // Couple Some Experience — Set 1
        "couple_exp_s1_excited":        "Smarter this time.",
        "couple_exp_s1_curious":        "Something I didn't expect.",
        "couple_exp_s1_neutral":        "What would make it go better?",
        "couple_exp_s1_nervous":        "Harder than I expected.",
        "couple_exp_s1_scared":         "Still processing what happened.",

        // Couple Some Experience — Set 2
        "couple_exp_s2_flavor":         "Which type actually fits me?",
        "couple_exp_s2_went_wrong":     "What went sideways and why?",
        "couple_exp_s2_emotional":      "What are the emotional risks?",
        "couple_exp_s2_sti":            "Let's actually think through sexual health.",
        "couple_exp_s2_asymmetric":     "What if one of us wants this more?",

        // Couple Reset — Set 1
        "couple_reset_s1_hopeful":      "Still believe in what we're building.",
        "couple_reset_s1_curious":      "What actually went wrong?",
        "couple_reset_s1_neutral":      "Different approach, not giving up.",
        "couple_reset_s1_nervous":      "Scared of the same outcome.",
        "couple_reset_s1_scared":       "Can we come back from this?",

        // Couple Reset — Set 2
        "couple_reset_s2_flavor":       "Which type actually fits me now?",
        "couple_reset_s2_conversation": "How do I have this conversation again?",
        "couple_reset_s2_emotional":    "What did we miss the first time?",
        "couple_reset_s2_sti":          "Are we actually on the same page?",
        "couple_reset_s2_went_wrong":   "What went wrong so we don't repeat it.",

        // Browsing — Set 1
        "browsing_s1_excited":          "Finally understanding it.",
        "browsing_s1_curious":          "I keep coming back to this.",
        "browsing_s1_neutral":          "Just want to understand it better.",
        "browsing_s1_nervous":          "Could I actually do this?",
        "browsing_s1_scared":           "Appeals to me and scares me.",

        // Browsing — Set 2
        "browsing_s2_flavor":           "Which type might fit me?",
        "browsing_s2_conversation":     "How do people start these conversations?",
        "browsing_s2_feelings":         "Managing feelings for more than one person.",
        "browsing_s2_sti":              "Sexual health with more people involved.",
        "browsing_s2_readiness":        "Curious or actually ready?",
    ]
}

```

---

## File: `Open Lightly/Design/Components/Effects/FloatingCard.swift` {#file-open-lightly-design-components-effects-floatingcard-swift}

```swift
//
//  FloatingCardSpec.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/1/26.
//


// Design/Components/Effects/FloatingCard.swift
// Open Lightly
//
// Individual floating glass card for OnboardingCuriosityPickerView.
// Used as the cardContent closure inside FloatingStack.
//
// Dark:  deep purple fill + AngularGradient hot border + shimmer sweep
// Light: frost fill + warm aurora border + shadow spread
//
// Float physics are driven by the parent via floatY, floatRot, gravity.
// This view owns only its press state and mounted entrance.

import SwiftUI

// MARK: - FloatingCardSpec

struct FloatingCardSpec: Identifiable {
    let id:         String
    let lead:       String   // 3-5 word hook
    let full:       String   // complete sentence
    let xFrac:      Double   // fractional x position in cluster frame
    let yFrac:      Double   // fractional y position in cluster frame
    let floatPhase: Double   // unique phase so cards never drift in sync
}

// MARK: - FloatingCard

struct FloatingCard: View {
    
    let spec:          FloatingCardSpec
    let isSelected:    Bool

    var floatY:        CGFloat = 0
    var floatRot:      Double  = 0
    var gravity:       CGSize  = .zero
    var hue:           Double  = 200
    var tick:          Double  = 0
    var targetOpacity: Double  = 1.0
    var cardWidth:     CGFloat = 168
    var tintColor:     Color   = .clear
    var onTap:         () -> Void

    @State private var mounted  = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var cardCornerRadius: CGFloat { 20 }

    private var shimmerOffset: CGFloat {
        // Oscillates ±18pt around card center — no sweep, no reset
        CGFloat(sin(tick * 0.028) * 4)
    }
    
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(spec.full)
                .font(AppFonts.body(16, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isLight
                    ? AppColors.lightCardTitle
                    : Color.white.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(width: cardWidth, alignment: .leading)
        .background(glassSurface)
        .frame(width: cardWidth)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .offset(
            x: gravity.width,
            y: floatY + gravity.height
        )
        .rotationEffect(.degrees(floatRot))
        .opacity(mounted ? targetOpacity : 0)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isSelected)
        .animation(.easeInOut(duration: 0.45), value: targetOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.08)) {
                mounted = true
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .accessibilityLabel(spec.lead)
        .accessibilityHint(spec.full)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Glass surface

private var glassSurface: some View {
      ZStack {
          // Base fill
          ZStack {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .fill(surfaceFill)
              // Set-identity tint layer — baked under gloss
              if tintColor != .clear {
                  RoundedRectangle(cornerRadius: cardCornerRadius)
                      .fill(tintColor)
              }
          }

          // Gloss + shimmer — all clipped together to card bounds
          ZStack {
              // Top edge highlight
              LinearGradient(
                  colors: [
                      Color.white.opacity(isLight ? 0.55 : 0.08),
                      Color.white.opacity(isLight ? 0.15 : 0.02),
                      Color.clear,
                  ],
                  startPoint: .top,
                  endPoint:   .init(x: 0.5, y: 0.45)
              )

              // Diagonal gloss — top-left corner catch
              LinearGradient(
                  colors: [
                      Color.white.opacity(isLight ? 0.25 : 0.06),
                      Color.clear,
                  ],
                  startPoint: .topLeading,
                  endPoint:   .init(x: 0.6, y: 0.6)
              )

              // Shimmer oscillation — selected dark only
              if isSelected && !isLight {
                  LinearGradient(
                      colors: [
                          .clear,
                          Color.white.opacity(0.03),
                          Color.white.opacity(0.06 + sin(tick * 0.028) * 0.04),
                          Color.white.opacity(0.03),
                          .clear,
                      ],
                      startPoint: .leading,
                      endPoint:   .trailing
                  )
                  .frame(width: cardWidth * 0.28, height: 140)
                  .offset(x: shimmerOffset)
                  .blur(radius: 4)
              }
          }
          .frame(width: cardWidth)
          .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
          .allowsHitTesting(false)

          // Border — outside clip so stroke never gets cut
          if isSelected {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .strokeBorder(
                      LinearGradient(
                          colors: isLight
                              ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
                              : [AppColors.cyan, AppColors.purple, AppColors.magenta],
                          startPoint: .topLeading,
                          endPoint:   .bottomTrailing
                      ),
                      lineWidth: 2.0
                  )
          } else {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .strokeBorder(
                      isLight
                          ? AppColors.lightBorder
                          : Color.white.opacity(0.09),
                      lineWidth: 1
                  )
          }
      }
      .frame(width: cardWidth)
  }

    // MARK: - Surface fill

    private var surfaceFill: AnyShapeStyle {
        if isLight {
            return isSelected
                ? AnyShapeStyle(AppColors.lightFrostPillSel)
                : AnyShapeStyle(AppColors.lightFrostPill)
        } else {
            if isSelected {
                return AnyShapeStyle(LinearGradient(
                    colors: [AppColors.surfaceBg, AppColors.cardBg],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                ))
            } else {
                // Blend tint over base surface
                return AnyShapeStyle(LinearGradient(
                    colors: [
                        AppColors.pillSurface.opacity(0.85),
                        AppColors.pillSurfaceBottom.opacity(0.85),
                    ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                ))
            }
        }
    }
}

// MARK: - Previews

private let previewSpec1 = FloatingCardSpec(
    id: "want_harder",
    lead: "What I want is harder",
    full: "I know what I don't want. What I actually want is harder.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 0.0
)

private let previewSpec2 = FloatingCardSpec(
    id: "same_fight",
    lead: "The same fight, again",
    full: "I've had the same fight in more than one relationship.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 1.17
)

private let previewSpec3 = FloatingCardSpec(
    id: "blow_up",
    lead: "I blow up or shut down",
    full: "Sometimes I blow up or shut down and I don't know why.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 2.34
)

#Preview("Unselected — Dark") {
    VStack(spacing: 16) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: false,
            hue:        200,
            tick:       0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       0,
            onTap:      {}
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Selected — Dark") {
    VStack(spacing: 16) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       120,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: true,
            hue:        320,
            tick:       120,
            onTap:      {}
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Unselected — Light") {
    VStack(spacing: 16) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: false,
            hue:        200,
            tick:       0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       0,
            onTap:      {}
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Selected — Light") {
    VStack(spacing: 16) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       120,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: true,
            hue:        320,
            tick:       120,
            onTap:      {}
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Mixed — Dark") {
    VStack(spacing: 16) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       80,
            targetOpacity: 1.0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       80,
            targetOpacity: 0.15,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: false,
            hue:        160,
            tick:       80,
            targetOpacity: 0.12,
            onTap:      {}
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

```

---

