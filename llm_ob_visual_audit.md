# LLM Context — Open Lightly · Onboarding Visual UI/UX Audit

> **Scope: Onboarding visual experience only.**
> Every screen, component, effect, animation, and design primitive
> that makes up the onboarding flow. No backend. No persistence.
>
> Onboarding flow sequence:
>   0   StatView       — trust trigger stat
>   0.5 BrandView      — animated brand reveal (auto-advance)
>   1   NameView       — name + pronouns entry
>   2   ModeSelectView — solo/couple + NM experience level
>   3   ContextView    — relationship context card stack
>   4   CuriosityPicker— two-panel interest + intent picker
>   6   BuildingPath   — processing animation (auto-advance)
>   6.5 CardReveal     — tap-to-flip card + pill selection
>   7   GroundRules    — ethical framing, must acknowledge
>   *   PairingFork    — couple only: pair now vs pair later
>
> Light mode + Dark mode + AMOLED all in scope.
> ANIM-STD three-slot cascade protocol applies to all screens.
>
> Generated: 2026-04-03 21:22:43 PDT

---

## Table of Contents

  1. [`FILE_TRACKER.md`](#file-file-tracker-md)
  2. [`PROJECT_SCOPE.md`](#file-project-scope-md)
  3. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  4. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)
  5. [`Open Lightly/App/Theme/AppTheme.swift`](#file-open-lightly-app-theme-apptheme-swift)
  6. [`Open Lightly/App/Theme/ThemeManager.swift`](#file-open-lightly-app-theme-thememanager-swift)
  7. [`Open Lightly/App/Theme/ThemeModifiers.swift`](#file-open-lightly-app-theme-thememodifiers-swift)
  8. [`Open Lightly/Features/Onboarding/Data/OnboardingData.swift`](#file-open-lightly-features-onboarding-data-onboardingdata-swift)
  9. [`Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift`](#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift)
  10. [`Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift`](#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift)
  11. [`Open Lightly/Features/Onboarding/Layout/OnboardingLayout.swift`](#file-open-lightly-features-onboarding-layout-onboardinglayout-swift)
  12. [`Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift`](#file-open-lightly-features-onboarding-views-onboardingflowview-swift)
  13. [`Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift`](#file-open-lightly-features-onboarding-views-onboardingstatview-swift)
  14. [`Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift`](#file-open-lightly-features-onboarding-views-onboardingbrandview-swift)
  15. [`Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift`](#file-open-lightly-features-onboarding-views-onboardingnameview-swift)
  16. [`Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift`](#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift)
  17. [`Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift`](#file-open-lightly-features-onboarding-views-onboardingcontextview-swift)
  18. [`Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift`](#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift)
  19. [`Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift`](#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift)
  20. [`Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift`](#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift)
  21. [`Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift`](#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift)
  22. [`Open Lightly/Features/Onboarding/Views/PairingForkView.swift`](#file-open-lightly-features-onboarding-views-pairingforkview-swift)
  23. [`Open Lightly/Features/Onboarding/Components/ContextCard.swift`](#file-open-lightly-features-onboarding-components-contextcard-swift)
  24. [`Open Lightly/Features/Onboarding/Components/ContextCardStack.swift`](#file-open-lightly-features-onboarding-components-contextcardstack-swift)
  25. [`Open Lightly/Features/Onboarding/Components/ContextIntensity.swift`](#file-open-lightly-features-onboarding-components-contextintensity-swift)
  26. [`Open Lightly/Features/Onboarding/Components/ContextOption.swift`](#file-open-lightly-features-onboarding-components-contextoption-swift)
  27. [`Open Lightly/Features/Onboarding/Components/CuriosityPanelNudge.swift`](#file-open-lightly-features-onboarding-components-curiositypanelnudge-swift)
  28. [`Open Lightly/Features/Onboarding/Components/CuriosityPill.swift`](#file-open-lightly-features-onboarding-components-curiositypill-swift)
  29. [`Open Lightly/Features/Onboarding/Components/CuriosityPreviewLine.swift`](#file-open-lightly-features-onboarding-components-curiositypreviewline-swift)
  30. [`Open Lightly/Features/Onboarding/Components/CuriosityStatusStrip.swift`](#file-open-lightly-features-onboarding-components-curiositystatusstrip-swift)
  31. [`Open Lightly/Design/Components/Navigation/OnboardingNavBar.swift`](#file-open-lightly-design-components-navigation-onboardingnavbar-swift)
  32. [`Open Lightly/Design/Components/Navigation/OnboardingFooter.swift`](#file-open-lightly-design-components-navigation-onboardingfooter-swift)
  33. [`Open Lightly/Design/Components/Progress/OnboardingProgressBar.swift`](#file-open-lightly-design-components-progress-onboardingprogressbar-swift)
  34. [`Open Lightly/Design/Components/Progress/OrbitIndicator.swift`](#file-open-lightly-design-components-progress-orbitindicator-swift)
  35. [`Open Lightly/Design/Components/Buttons/HoloCTAButton.swift`](#file-open-lightly-design-components-buttons-holoctabutton-swift)
  36. [`Open Lightly/Design/Components/Buttons/SelectablePill.swift`](#file-open-lightly-design-components-buttons-selectablepill-swift)
  37. [`Open Lightly/Design/Components/Buttons/GradientButton.swift`](#file-open-lightly-design-components-buttons-gradientbutton-swift)
  38. [`Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift`](#file-open-lightly-design-components-cards-atmosphericghostdeck-swift)
  39. [`Open Lightly/Design/Components/Cards/CardBackView.swift`](#file-open-lightly-design-components-cards-cardbackview-swift)
  40. [`Open Lightly/Design/Components/Cards/CardFrontView.swift`](#file-open-lightly-design-components-cards-cardfrontview-swift)
  41. [`Open Lightly/Design/Components/Cards/CardLayout.swift`](#file-open-lightly-design-components-cards-cardlayout-swift)
  42. [`Open Lightly/Design/Components/Cards/CardRevealPillButton.swift`](#file-open-lightly-design-components-cards-cardrevealpillbutton-swift)
  43. [`Open Lightly/Design/Components/Cards/CardShadows.swift`](#file-open-lightly-design-components-cards-cardshadows-swift)
  44. [`Open Lightly/Design/Components/Cards/CuriosityCardBack.swift`](#file-open-lightly-design-components-cards-curiositycardback-swift)
  45. [`Open Lightly/Design/Components/Cards/CuriosityFlipCard.swift`](#file-open-lightly-design-components-cards-curiosityflipcard-swift)
  46. [`Open Lightly/Design/Components/Effects/AuroraGlowField.swift`](#file-open-lightly-design-components-effects-auroraglowfield-swift)
  47. [`Open Lightly/Design/Components/Effects/FlameAura.swift`](#file-open-lightly-design-components-effects-flameaura-swift)
  48. [`Open Lightly/Design/Components/Effects/FloatingCard.swift`](#file-open-lightly-design-components-effects-floatingcard-swift)
  49. [`Open Lightly/Design/Components/Effects/FloatingStack.swift`](#file-open-lightly-design-components-effects-floatingstack-swift)
  50. [`Open Lightly/Design/Components/Effects/GlowOrb.swift`](#file-open-lightly-design-components-effects-gloworb-swift)
  51. [`Open Lightly/Design/Components/Effects/HolographicShimmer.swift`](#file-open-lightly-design-components-effects-holographicshimmer-swift)
  52. [`Open Lightly/Design/Components/Effects/LightAuraBloom.swift`](#file-open-lightly-design-components-effects-lightaurabloom-swift)
  53. [`Open Lightly/Design/Components/Effects/LightModeShimmer.swift`](#file-open-lightly-design-components-effects-lightmodeshimmer-swift)
  54. [`Open Lightly/Design/Components/Effects/MazePatternView.swift`](#file-open-lightly-design-components-effects-mazepatternview-swift)
  55. [`Open Lightly/Design/Components/Effects/OnboardingGlowField.swift`](#file-open-lightly-design-components-effects-onboardingglowfield-swift)
  56. [`Open Lightly/Design/Components/Effects/SparkField.swift`](#file-open-lightly-design-components-effects-sparkfield-swift)
  57. [`Open Lightly/Design/Components/Effects/TileOrbitView.swift`](#file-open-lightly-design-components-effects-tileorbitview-swift)
  58. [`Open Lightly/Design/Components/Text/LivingText.swift`](#file-open-lightly-design-components-text-livingtext-swift)
  59. [`Open Lightly/Design/Components/Text/GradientText.swift`](#file-open-lightly-design-components-text-gradienttext-swift)
  60. [`Open Lightly/Design/Components/Text/KeywordHighlightText.swift`](#file-open-lightly-design-components-text-keywordhighlighttext-swift)
  61. [`Open Lightly/Design/Components/Input/InteractiveField.swift`](#file-open-lightly-design-components-input-interactivefield-swift)
  62. [`Open Lightly/Design/Components/PillBorder.swift`](#file-open-lightly-design-components-pillborder-swift)
  63. [`Open Lightly/Design/Components/CardStyle.swift`](#file-open-lightly-design-components-cardstyle-swift)
  64. [`Open Lightly/Design/Components/NavArrow.swift`](#file-open-lightly-design-components-navarrow-swift)
  65. [`Open Lightly/Design/Components/OrbitSparkBorderView.swift`](#file-open-lightly-design-components-orbitsparkborderview-swift)
  66. [`Open Lightly/Design/Components/SectionHeader.swift`](#file-open-lightly-design-components-sectionheader-swift)
  67. [`Open Lightly/Design/Components/OrbitSpark.metal`](#file-open-lightly-design-components-orbitspark-metal)

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

## File: `Open Lightly/App/Theme/AppColors.swift` {#file-open-lightly-app-theme-appcolors-swift}

```swift
//
//  AppColors.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = .black
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// AppColors.swift
// Open Lightly
//
// Design System: Hot Border × Clash Display × Gradient Keywords
// Card intensity scales 1–8 with prompt difficulty
// ──────────────────────────────────────────────────────

// MARK: - App Colors

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Core Spectrum
    // The 3 anchor colors — used for borders,
    // gradient text highlights, glows
    // Gradient direction: 135° (top-left -> bottom-right)
    // ─────────────────────────────────────────────

    static let cyan       = Color(hex: "00C2FF")
    static let purple     = Color(hex: "6C3AE0")
    static let magenta    = Color(hex: "FF006A")

    /// Soft magenta variant — used in shimmer gradients and atmospheric fills
    static let pink       = Color(hex: "FF2D8A")

    /// Deep atmospheric blue — used in glow field floor washes
    static let deepBlue   = Color(hex: "0078FF")

    /// Violet — between purple and blue, used in warm-tier pill gradients
    static let violet = Color(hex: "7C3AED")
    static let electricViolet = Color(hex: "8B5CF6")
    
    
    /// Electric purple — vivid gradient midpoint, LivingText only
    static let purpleVivid = Color(hex: "9333EA")
    
    static let purpleBright = Color(hex: "C084FC")

    // Lighter variants — gradient text on keywords, badges
    static let cyanLight    = Color(hex: "4DD8FF")
    static let purpleLight  = Color(hex: "A78BFA")
    static let magentaLight = Color(hex: "FF4D94")

    // Darker variants — tinted backgrounds, deep accents
    static let cyanDark    = Color(hex: "0891B2")
    static let purpleDark  = Color(hex: "1A1A5E")
    static let magentaDark = Color(hex: "BE185D")

    // ─────────────────────────────────────────────
    // MARK: Backgrounds
    // Page -> Card -> Surface (lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")

    /// Default card interior (levels 1–4)
    // DARK-FILL-FIX: was #050507 — only 2/255 delta from pageBg.
    // At disabled opacity 0.45 the button was invisible.
    // #12111A holds shape identity at 0.45 while staying dark.
    static let cardBg = Color(hex: "12111A")

    /// Elevated surfaces, sheets, modals
    // DARK-FILL-FIX: was #08080C — 5/255 delta from pageBg.
    // Invisible at 0.45 opacity. #1A1825 holds pill shape.
    static let surfaceBg = Color(hex: "1A1825")

    /// Slightly raised elements (input fields, etc)
    static let surfaceRaised = Color(hex: "0C0C10")

    // Tinted card backgrounds (for intensity levels 5–8)
    static let tintCyan    = Color(hex: "061018")
    static let tintPurple  = Color(hex: "080614")
    static let tintMagenta = Color(hex: "120610")
    static let tintNavy    = Color(hex: "0A1018")
    static let tintIndigo  = Color(hex: "0A0820")
    static let tintPlum    = Color(hex: "180818")

    // Supernova (ultimate) gradient layers — deepest possible darks
    static let tintSupernovaA = Color(hex: "081420")
    static let tintSupernovaB = Color(hex: "0C0624")
    static let tintSupernovaC = Color(hex: "1A0620")
    static let tintSupernovaD = Color(hex: "1C0818")

    // ─────────────────────────────────────────────
    // MARK: Text
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings
    static let textPrimary   = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels
    static let textSecondary = Color(hex: "AAAABC")

    /// Tertiary text — timestamps, meta
    static let textTertiary  = Color(hex: "666680")

    /// Quaternary text — pronoun hint, subtle placeholders
    static let textQuaternary = Color(red: 0.42, green: 0.42, blue: 0.50)

    /// Muted text — disabled states, subtle hints
    static let textMuted     = Color.white.opacity(0.20)

    /// Bright near-white for small labels that need to survive
    /// a purple-tinted ambient background (status strip counts,
    /// overline labels, etc). Device-absolute — cannot be tinted.
    static let textBright = Color(white: 0.90)

    /// Muted body text — sublabels inside cards.
    /// Use when textSecondary reads below threshold on deep backgrounds.
    static let textMutedBody = Color(white: 0.62)

    /// Badge/tag text
    static let textBadge     = Color(hex: "5BB8CC")

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default subtle border
    static let border        = Color.white.opacity(0.06)

    /// Hover/active border
    static let borderHover   = Color.white.opacity(0.10)

    /// Prominent border
    static let borderActive  = Color.white.opacity(0.15)

    // ─────────────────────────────────────────────
    // MARK: UI Elements
    // ─────────────────────────────────────────────

    /// Badge background
    static let badgeBg       = cyan.opacity(0.08)

    /// Ghost button border
    static let btnGhostBorder = Color.white.opacity(0.06)

    /// Ghost button text
    static let btnGhostText   = Color(hex: "444444")

    /// Toggle / switch active
    static let toggleActive   = cyan

    /// Destructive / warning
    static let destructive    = Color(hex: "FF4444")

    /// Success / confirmed
    static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    static let gold       = Color(hex: "C8960A")
    static let goldLight  = Color(hex: "E2B93B")
    static let goldDark   = Color(hex: "8B6914")
    static let glowGold   = gold
    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Glow aliases — reference the canonical spectrum tokens
    static let glowCyan    = cyan
    static let glowMagenta = magenta
    static let glowPurple  = purple

    /// Shadow colors
    static let shadowDeep  = Color.black.opacity(0.50)
    static let shadowLight = Color.black.opacity(0.25)

    // ─────────────────────────────────────────────
    // MARK: Gradients
    // ─────────────────────────────────────────────

    /// Card border gradient — the "Hot Border"
    /// Used on every prompt card at full opacity
    static let spectrumBorder = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Keyword highlight gradient — applied to select words
    /// Use with .foregroundStyle() on Text views
    static let spectrumText = LinearGradient(
        colors: [cyan, purpleLight, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Primary button fill — subtle gradient
    static let btnPrimaryFill = LinearGradient(
        colors: [
            cyan.opacity(0.12),
            magenta.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Max-intensity CTA — used sparingly (level 8, special)
    static let btnMaxFill = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Top-edge ambient wash (cards level 2+)
    static let topCyanWash = LinearGradient(
        colors: [
            cyan.opacity(0.04),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .center
    )

    // MARK: - Canonical Aliases (Batch 6 spec)
    static var card: Color { cardBg }
    static var background: Color { pageBg }
    static var cardElevated: Color { surfaceRaised }

    // MARK: - Spectrum Gradient (Batch 6 spec)
    static var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, purple, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // ─────────────────────────────────────────────
    // MARK: Light Mode — Warm Aurora
    //
    // Background: #F8F6EE (warm cream — never change)
    // Aurora palette: Magenta / Purple / Gold — no cyan
    // All tokens prefixed with light* or aurora* to
    // prevent any collision with dark mode tokens.
    // ─────────────────────────────────────────────

    // Backgrounds
    /// Warm cream — the one true light mode page background
    static let lightPageBg    = Color(hex: "F8F6EE")

    /// Pure white — card interiors lift off the cream naturally
    static let lightCardBg    = Color(hex: "FFFFFF")

    /// Inset fields — slightly deeper than page, clearly recessed
    static let lightSurfaceBg = Color(hex: "F2EFE6")

    // Text
    /// Near-black — primary headings and body on cream
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// 50% near-black — labels, descriptions
    static let lightTextSecondary = Color(hex: "1A1A1E").opacity(0.50)

    /// 30% near-black — timestamps, meta, hints
    static let lightTextTertiary  = Color(hex: "1A1A1E").opacity(0.30)

    // Borders
    /// Default subtle border on cream surfaces
    static let lightBorder      = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover = Color.black.opacity(0.10)

    // Frosted glass fills
    // Used with .background + backdrop blur in SwiftUI.
    // These are NOT opaque — the aurora bleeds through intentionally.
    /// Glass card fill — 58% white over aurora
    // OPACITY-FIX: was Color.white.opacity(0.58)
    static let lightFrostCard    = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream
    // OPACITY-FIX: was Color.white.opacity(0.55) — semi-transparent
    // whites multiply with container opacity causing pills to vanish
    // at disabled 0.45. Opaque equivalent preserves identical appearance
    // at full opacity and holds at any container opacity.
    // TINT-FIX: was (0.988, 0.984, 0.970) near-white — shimmer had nothing
    // to push against. Now a soft lavender-blush sits visibly on
    // lightPageBg (#F8F6EE). Parallel role to surfaceBg (#1A1825) in dark.
    // PILL-FILL-FIX: was (0.945, 0.925, 0.960) — near-white, indistinguishable
    // from lightPageBg (#F8F6EE). Shimmer had nothing to push against.
    // Now a visible lavender — parallel role to surfaceBg (#1A1825) in dark mode.
    // The shimmer sweeps over this tinted base the same way HolographicShimmer
    // sweeps over the deep purple surfaceBg.
    static let lightFrostPill    = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — slightly more opaque for legibility
    // PILL-FILL-FIX: was (0.950, 0.922, 0.968) — barely distinguishable from
    // lightFrostPill. Selected state had no visual lift over unselected.
    // Now a visible rose-blush — selected reads richer and warmer than unselected.
    // Contrast between selected/unselected mirrors dark mode's surfaceBg delta.
    static let lightFrostPillSel = Color(red: 0.958, green: 0.875, blue: 0.925)

    // MARK: - Pill Tokens

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Selected pill interior tint multiplier base.
    /// View applies .opacity() on top of this.
    static let pillSurfaceSelected = Color(red: 0.051, green: 0.043, blue: 0.122)

    /// Ambient lift shadow applied to every pill in dark mode.
    /// Keeps pills visually separated from the background without
    /// a directional light source.
    static let pillGlow = Color(white: 1.0).opacity(0.04)

    /// CTA button fill — frosted, never fully opaque
    // OPACITY-FIX: was Color.white.opacity(0.70)
    static let lightFrostCTA     = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose so button reads
    /// correctly at both full and 0.45 disabled opacity.
    /// Harmonises with LightModeShimmer's purple/magenta/gold tints.
    static let lightCTAFill      = Color(red: 0.98, green: 0.91, blue: 0.93)

    // Floating label colors
    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy
    static let lightHintText      = magentaDark.opacity(0.50)

    // Aurora atmosphere blobs
    // Four colors that pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)    // magenta — top right
    static let auroraBlob2 = purple.opacity(0.08)     // purple  — bottom left
    static let auroraBlob3 = gold.opacity(0.07)       // gold    — bottom right
    static let auroraBlob4 = pink.opacity(0.06)       // pink    — mid left

    // Aurora shadow spread
    // On light surfaces, shadow IS the glow.
    // These replace the cyan/magenta bloom shadows from dark mode.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // MARK: - Light Mode Card Text
    // Warm wine-toned text tokens for OnboardingGroundRulesView cards.
    // Used for card title and detail body on rose-blush fill in light mode only.

    /// Dark rose — deep wine for headlines on rose fill (#3D1A26)
    static let lightHeadlineDarkRose = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Wine dark — card title on rose fill (#5C1F35)
    static let lightCardTitle  = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Mid wine — card detail body on rose fill (#7A2D45)
    static let lightCardDetail = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = Color(red: 1.00, green: 0.00, blue: 0.42).opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = Color(red: 1.00, green: 0.30, blue: 0.00).opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = Color(red: 0.78, green: 0.59, blue: 0.04).opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)
    /// Card shadow — warm amber mid
    static let lightCardShadowMagenta = Color(red: 0.78, green: 0.39, blue: 0.20)

    /// Card shadow — warm orange
    static let lightCardShadowOrange  = Color(red: 1.00, green: 0.39, blue: 0.20)

    /// Wine dark — unselected pill / CTA label on light surfaces (#703040)
    static let wineDark = Color(red: 0.44, green: 0.07, blue: 0.18)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Border
    //
    // One gradient border used on ALL screens in both
    // dark and light mode. Replaces per-mode branching
    // on borders — the gradient works on both surfaces.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    //        Both live in PillBorder.swift
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    /// purple → magentaLight → gold, topLeading → bottomTrailing
    /// Matches the aurora atmosphere palette exactly
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — for "acquainted." and keyword highlights
    /// purple → purpleLight → magentaLight
    /// Stays within the purple-original blend, warm but not jarring on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    /// Same warm palette at low opacity — not the full spectrum blast
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]

    // lightPillShimmerColors — higher opacity than
    // lightShimmerColors. Used on interactive surfaces
    // (selected pills, active input borders) where the
    // shimmer needs to be as visible as HolographicShimmer
    // is in dark mode. lightShimmerColors remains unchanged
    // for background wash usage.
    static let lightPillShimmerColors: [Color] = [
        AppColors.magenta.opacity(0.50),
        AppColors.gold.opacity(0.55),
        AppColors.magenta.opacity(0.45),
        AppColors.goldLight.opacity(0.50),
        AppColors.magenta.opacity(0.50),
    ]

    // ─────────────────────────────────────────────
    // MARK: Light-mode surface tokens
    // ─────────────────────────────────────────────

    /// Slightly off-white field background for light mode.
    /// Sits above cardSurfaceLight without blending in.
    /// Parallel to dark-mode kFieldBG = white.opacity(0.07).
    static let fieldBgLight     = Color.white.opacity(0.82)

    /// Structural 1pt border for cards and fields in light mode.
    /// opacity(0.14) mirrors LivingText static shadow opacity(0.18) —
    /// visual weight matches LT-G-03: structural, not atmospheric.
    static let borderLight      = purple.opacity(0.14)

    /// Frosted white lift for the glass card surface in light mode.
    /// 0.72 lets the light atmosphere ellipse breathe through without
    /// muddying field fills inside the card.
    static let cardSurfaceLight = Color.white.opacity(0.72)

    /// Semantic blue — used in dark-mode atmosphere ellipse gradient.
    static let blue             = Color.blue
}

// MARK: - ──────────────────────────────────────────────
// Card Intensity System
// Maps prompt difficulty -> visual intensity
// ──────────────────────────────────────────────────────

enum CardIntensity: Int, CaseIterable, Identifiable {
    case void        = 1
    case deepOcean   = 2
    case emberFloor  = 3
    case split       = 4
    case nebula      = 5
    case auroraBand  = 6
    case deepSpace   = 7
    case supernova   = 8

    var id: Int { rawValue }

    // ─────────────────────────────────────────────
    // MARK: Mapping from prompt data
    // ─────────────────────────────────────────────

    static func from(difficulty: String) -> CardIntensity {
        switch difficulty.lowercased() {
        case "easy":        return .void
        case "light":       return .deepOcean
        case "medium":      return .split
        case "deep":        return .nebula
        case "sensitive":   return .deepSpace
        case "ultimate":    return .supernova
        default:            return .deepOcean
        }
    }

    static func from(score: Int) -> CardIntensity {
        switch score {
        case 1...2:  return .void
        case 3:      return .deepOcean
        case 4:      return .emberFloor
        case 5:      return .split
        case 6:      return .nebula
        case 7:      return .auroraBand
        case 8:      return .deepSpace
        case 9...10: return .supernova
        default:     return .deepOcean
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Background
    // ─────────────────────────────────────────────

    var backgroundColor: Color {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return AppColors.cardBg
        case .nebula:
            return AppColors.tintCyan
        case .deepSpace:
            return AppColors.tintNavy
        case .supernova:
            return AppColors.tintIndigo
        }
    }

    var backgroundGradient: LinearGradient? {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return nil
        case .nebula:
            return LinearGradient(
                colors: [AppColors.tintCyan, AppColors.tintPurple, AppColors.tintMagenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .deepSpace:
            return LinearGradient(
                colors: [AppColors.tintNavy, AppColors.tintIndigo, AppColors.tintPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .supernova:
            return LinearGradient(
                colors: [
                    AppColors.tintSupernovaA,
                    AppColors.tintSupernovaB,
                    AppColors.tintSupernovaC,
                    AppColors.tintSupernovaD
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var usesGradientBackground: Bool {
        rawValue >= 5
    }

    // ─────────────────────────────────────────────
    // MARK: Radial Wash Overlays
    // ─────────────────────────────────────────────

    var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void:         return nil
        case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
        case .emberFloor:   return nil
        case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
        case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
        case .auroraBand:   return nil
        case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
        case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
        }
    }

    var magentaWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void, .deepOcean: return nil
        case .emberFloor:       return (x: 0.5, y: 1.1, opacity: 0.09)
        case .split:            return (x: 0.9, y: 1.0, opacity: 0.06)
        case .nebula:           return (x: 0.85, y: 0.8, opacity: 0.05)
        case .auroraBand:       return nil
        case .deepSpace:        return (x: 0.8, y: 0.9, opacity: 0.07)
        case .supernova:        return (x: 0.9, y: 1.0, opacity: 0.09)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Glow / Shadow
    // ─────────────────────────────────────────────

    var glowRadius: CGFloat {
        switch self {
        case .void, .deepOcean, .emberFloor:  return 30
        case .split, .nebula, .auroraBand:    return 40
        case .deepSpace:                       return 45
        case .supernova:                       return 60
        }
    }

    var glowMultiplier: Double {
        switch self {
        case .void:        return 0.6
        case .deepOcean:   return 0.8
        case .emberFloor:  return 0.8
        case .split:       return 0.9
        case .nebula:      return 1.0
        case .auroraBand:  return 0.9
        case .deepSpace:   return 1.1
        case .supernova:   return 1.3
        }
    }

    var cyanGlowOpacity: Double    { 0.08 * glowMultiplier }
    var magentaGlowOpacity: Double { 0.06 * glowMultiplier }

    // ─────────────────────────────────────────────
    // MARK: Display Helpers
    // ─────────────────────────────────────────────

    var displayName: String {
        switch self {
        case .void:        return "Void"
        case .deepOcean:   return "Deep Ocean"
        case .emberFloor:  return "Ember Floor"
        case .split:       return "Split"
        case .nebula:      return "Nebula"
        case .auroraBand:  return "Aurora Band"
        case .deepSpace:   return "Deep Space"
        case .supernova:   return "Supernova"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .void, .deepOcean:         return "Easy"
        case .emberFloor, .split:       return "Medium"
        case .nebula, .auroraBand:      return "Deep"
        case .deepSpace:                return "Sensitive"
        case .supernova:                return "Ultimate"
        }
    }
}

```

---

## File: `Open Lightly/App/Theme/AppFonts.swift` {#file-open-lightly-app-theme-appfonts-swift}

```swift
//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            return Font.system(size: size, weight: .bold, design: .default)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens
    static var heroTitle: Font { display(42, weight: .bold) }
    static var cardTitle: Font { display(22, weight: .semibold) }
    static var sectionHeading: Font { display(20, weight: .medium) }
    static var bodyText: Font { body(16, weight: .regular) }
    static var bodyMedium: Font { body(15, weight: .medium) }
    static var caption: Font { body(13, weight: .regular) }
    static var overline: Font { body(11, weight: .semibold) }
    static var buttonLabel: Font { body(14, weight: .semibold) }

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }

    static var prompt: Font          { display(17, weight: .medium) }
    static var promptHighlight: Font { display(17, weight: .semibold) }
    static var badge: Font           { body(10, weight: .medium) }
    static var button: Font          { body(11, weight: .medium) }
    static var meta: Font            { body(10, weight: .regular) }
    static var sectionHeader: Font   { display(13, weight: .medium) }
    static var screenTitle: Font     { display(24, weight: .semibold) }
    static var label: Font           { body(10, weight: .semibold) }
    static var tabLabel: Font        { body(10, weight: .medium) }
    static var scoreDisplay: Font    { display(32, weight: .bold) }
    static var ctaLabel: Font        { body(16, weight: .semibold) }
}

```

---

## File: `Open Lightly/App/Theme/AppTheme.swift` {#file-open-lightly-app-theme-apptheme-swift}

```swift
//
//  AppTheme.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case amoled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .amoled: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .amoled: return "moon.fill"
        }
    }
}

// MARK: - Color Palette

struct AppPalette {
    let bg: Color
    let bgElevated: Color
    let surface1: Color
    let surface2: Color
    let surface3: Color

    let border: Color
    let borderSubtle: Color

    let text: Color
    let textSecondary: Color
    let textMuted: Color

    let success: Color
    let successDim: Color
    let error: Color
    let errorDim: Color

    /// UI accent — links, active states, highlights
    let cyan: Color
    /// UI accent — CTAs, emphasis, warnings
    let magenta: Color
    /// Decorative only — spectrum bar, score ring, flag swatch
    let navy: Color
    let gold: Color

    let glowOpacity: Double
    let glowCyan: Color
    let glowMagenta: Color
    let glowGold: Color

    let isAmoled: Bool
}

// MARK: - Computed Gradients

extension AppPalette {
    /// Spectrum bar: cyan -> magenta -> navy (decorative)
    var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta, navy],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Primary CTA: cyan -> magenta (no navy)
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Score ring: full 3-color polyam sweep (decorative)
    var ringGradient: AngularGradient {
        AngularGradient(
            colors: [cyan, magenta, navy, cyan],
            center: .center
        )
    }

    /// Card border — hairline white on AMOLED, warm gray on light
    var cardBorder: Color {
        isAmoled ? .white.opacity(0.08) : border
    }
}

// MARK: - Light Palette

extension AppPalette {
    static let light = AppPalette(
        bg:            Color(hex: "F8F7F4"),
        bgElevated:    .white,
        surface1:      .white,
        surface2:      Color(hex: "F3F1ED"),
        surface3:      Color(hex: "E8E5DF"),
        border:        Color(hex: "E0DDD6"),
        borderSubtle:  Color(hex: "EAE7E1"),
        text:          Color(hex: "1A1918"),
        textSecondary: Color(hex: "5C5955"),
        textMuted:     Color(hex: "9E9A92"),
        success:       Color(hex: "14B866"),
        successDim:    Color(hex: "14B866").opacity(0.1),
        error:         Color(hex: "DC4444"),
        errorDim:      Color(hex: "DC4444").opacity(0.1),
        cyan:          Color(hex: "0891B2"),
        magenta:       Color(hex: "BE185D"),
        navy:          Color(hex: "1A3A8F"),
        gold:          Color(hex: "B8860B"),
        glowOpacity:   0.06,
        glowCyan:      Color(hex: "0891B2").opacity(0.10),
        glowMagenta:   Color(hex: "BE185D").opacity(0.08),
        glowGold:      Color(hex: "B8860B").opacity(0.08),
        isAmoled:      false
    )
}

// MARK: - AMOLED Palette

extension AppPalette {
    static let amoled = AppPalette(
        bg:            .black,
        bgElevated:    .black,
        surface1:      Color(hex: "0A0A10"),
        surface2:      Color(hex: "101018"),
        surface3:      Color(hex: "18181F"),
        border:        .white.opacity(0.08),
        borderSubtle:  .white.opacity(0.05),
        text:          Color(hex: "F4F3F9"),
        textSecondary: Color(hex: "8A88A0"),
        textMuted:     Color(hex: "4A485C"),
        success:       Color(hex: "5CE0A0"),
        successDim:    Color(hex: "5CE0A0").opacity(0.10),
        error:         Color(hex: "EF6B6B"),
        errorDim:      Color(hex: "EF6B6B").opacity(0.20),
        cyan:          Color(hex: "5ED0EE"),
        magenta:       Color(hex: "F472AD"),
        navy:          Color(hex: "9494D0"),
        gold:          Color(hex: "FFD700"),
        glowOpacity:   0.18,
        glowCyan:      Color(hex: "5ED0EE").opacity(0.20),
        glowMagenta:   Color(hex: "F472AD").opacity(0.20),
        glowGold:      Color(hex: "FFD700").opacity(0.20),
        isAmoled:      true
    )
}

```

---

## File: `Open Lightly/App/Theme/ThemeManager.swift` {#file-open-lightly-app-theme-thememanager-swift}

```swift
//
//  ThemeManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

@Observable
class ThemeManager {

    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appThemeMode")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "system"
        self.mode = ThemeMode(rawValue: saved) ?? .system
    }

    func palette(for systemScheme: ColorScheme) -> AppPalette {
        switch mode {
        case .light:  return .light
        case .amoled: return .amoled
        case .system: return systemScheme == .dark ? .amoled : .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .amoled: return .dark
        }
    }
}

// MARK: - Environment Key

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: AppPalette = .light
}

extension EnvironmentValues {
    var theme: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

```

---

## File: `Open Lightly/App/Theme/ThemeModifiers.swift` {#file-open-lightly-app-theme-thememodifiers-swift}

```swift
//
//  ThemeModifiers.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Root Modifier

struct ThemedRootModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = themeManager.palette(for: systemScheme)
        content
            .environment(\.theme, palette)
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    func themedRoot() -> some View {
        modifier(ThemedRootModifier())
    }
}

// MARK: - Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.theme) private var t
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(t.surface1)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? t.cyan : t.cardBorder,
                        lineWidth: selected ? 2 : 1.5
                    )
            )
            .shadow(
                color: selected && t.isAmoled
                    ? t.glowCyan
                    : .clear,
                radius: selected ? 8 : 0
            )
    }
}

extension View {
    func themedCard(selected: Bool = false) -> some View {
        modifier(ThemedCardModifier(selected: selected))
    }
}

// MARK: - Conditional Modifier Helper
// Applies a modifier only when `condition` is true.
// Usage: .if(someFlag) { $0.screenshotProtected() }

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

```

---

## File: `Open Lightly/Features/Onboarding/Data/OnboardingData.swift` {#file-open-lightly-features-onboarding-data-onboardingdata-swift}

```swift
//
// OnboardingData.swift
// Open Lightly
//

import Foundation

struct OnboardingData {
    // Screen 1 — Name + Gender
    var displayName: String = ""
    var gender: String? = nil
    // Solo path only — captured in ContextView when
    // user selects a card implying a partner exists.
    // Couple path does not use this field —
    // partner sets their own gender in NameView.
    // nil = not provided or not applicable.
    var partnerPronouns: String? = nil

    // Screen 2 — Mode Select
    var explorationMode: ExplorationMode?

    // Screen 3 — Relationship Status (solo only)
    var relationshipStatus: RelationshipStatus?

    // Screen 4 — Relationship Context (branches on explorationMode)
    var relationshipContext: RelationshipContext?

    // Screen 4 — Personalize
    var nmStage: NMStage?
    var defaultDepth: Float = 0.3

    // Screen 5 — Curiosity Picker
    var communicationGoals: [String] = []    // Section 1 selections
    var learningGoals: [String] = []         // Section 2 selections
    var curiositySelections: [String] = []   // Derived: communicationGoals + learningGoals

    // Screen 6 — Pairing (couple only)
    var pairingId: String?

    // Screen 7 — Building Path (derived from nmStage)
    var defaultDifficulty: String = ""

    // Screen 7.5 — Card Reveal (pill selection for archetype routing)
    // nil when user skips — archetype routing uses fallback.
    var nmCardResponse: String? = nil

    // Screen 8 — Ground Rules + completion
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?

    // Solo Reflection
    var firstReflection: String?
    var firstReflectionCompleted: Bool = false
    var firstReflectionTimestamp: Date?
}

// MARK: - Enums

enum PronounOption: String, CaseIterable, Identifiable, Hashable {
    case sheHer = "she/her"
    case heHim = "he/him"
    case theyThem = "they/them"
    
    var id: String { rawValue }
}

enum ExplorationMode: String, CaseIterable {
    case solo
    case couple
    case browsing
}

enum RelationshipStatus: String, CaseIterable {
    case single
    case partneredOpen
    case partneredHidden
}

enum NMStage: String, CaseIterable {
    case curious
    case exploring
    case experienced
}

enum RelationshipContext: String, CaseIterable, Codable {
    // Solo contexts
    case single
    case partneredOpen
    case partneredHidden

    // Couple contexts
    case notTalked
    case talking
    case someExperience
    case needsReset
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

## File: `Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift` {#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift}

```swift
// OnboardingAtmosphere.swift
// Open Lightly
//
// Unified atmospheric background for the entire onboarding flow.
// Consolidates OnboardingGlowField (dark) and AuroraGlowField (light)
// into one component with one config system covering both modes.
//
// Architecture:
//   - Lives in OnboardingFlowView's ZStack, below the screen switch.
//   - Never leaves the hierarchy — screens render on top of it.
//   - Light mode: AuroraGlowField morphs between per-screen configs via
//     its built-in .animation(.easeInOut(duration: 1.0), value: config).
//   - Dark mode: OnboardingGlowField is self-contained, no config needed.
//   - SparkField is light mode only — folded in here, not a separate call.
//
// BrandView exit contract:
//   OnboardingBrandView fires onAtmosphereExit() at t=4780ms.
//   FlowView receives this and sets atmosphereOpacity = 0 (easeIn 400ms).
//   FlowView owns atmosphereOpacity and passes it in here.
//   BrandView owns the timing. FlowView owns the state. Neither reaches
//   into the other's domain.
//
// Usage:
//   OnboardingAtmosphere(
//       config: auroraConfig,
//       sparkConfig: sparkConfig,
//       opacity: atmosphereOpacity
//   )
//   .ignoresSafeArea()
//   .allowsHitTesting(false)
//   .accessibilityHidden(true)

import SwiftUI

// MARK: - AtmosphereConfig
//
// One config per screen. Each config carries both light and dark
// intensity values so they live next to each other and can be
// tuned in one place.
//
// Light values carry over from the existing AuroraConfig presets.
// Dark values are tuned separately — dark mode amplifies color
// differently than cream does so the same multipliers would overblow.

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark:  AtmosphereIntensity

    // ── Per-screen presets ────────────────────────────────────────────

    static let stat = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.40, bottom: 1.15, global: 0.85),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.50, bottom: 1.00, global: 0.70)
    )

    static let brand = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.35, bottom: 0.70, global: 0.78),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.45, bottom: 0.80, global: 0.65)
    )

    static let name = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.10, bottom: 1.15, global: 0.60),
        dark:  AtmosphereIntensity(top: 0.80, mid: 0.20, bottom: 0.90, global: 0.55)
    )

    static let modeSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.30, bottom: 1.15, global: 0.70),
        dark:  AtmosphereIntensity(top: 0.15, mid: 0.35, bottom: 1.00, global: 0.60)
    )

    static let contextSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.40, mid: 0.20, bottom: 0.85, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.30, mid: 0.25, bottom: 0.75, global: 0.45)
    )

    static let curiosityPicker = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.30, mid: 0.10, bottom: 0.75, global: 0.40),
        dark:  AtmosphereIntensity(top: 0.20, mid: 0.15, bottom: 0.65, global: 0.35)
    )

    // buildingPath and cardReveal reuse curiosityPicker —
    // de-energised atmosphere, content is the focus.
    static let buildingPath   = AtmosphereConfig.curiosityPicker
    static let cardReveal     = AtmosphereConfig.curiosityPicker

    static let groundRules = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.15, mid: 0.20, bottom: 1.05, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.10, mid: 0.20, bottom: 0.90, global: 0.45)
    )
}

// MARK: - AtmosphereIntensity

struct AtmosphereIntensity: Equatable {
    var top:    Double
    var mid:    Double
    var bottom: Double
    var global: Double
}

// MARK: - OnboardingAtmosphere

struct OnboardingAtmosphere: View {

    var config:      AtmosphereConfig      = .stat
    var sparkConfig: SparkConfiguration    = .statView
    var opacity:     Double                = 1.0

    @Environment(\.colorScheme) private var colorScheme

    // Map AtmosphereConfig → AuroraConfig so AuroraGlowField
    // continues to receive the typed value it expects.
    // This bridge is internal — callers only deal with AtmosphereConfig.
    private var auroraConfig: AuroraConfig {
        let i = colorScheme == .light ? config.light : config.dark
        return AuroraConfig(
            topOpacityMult:    i.top,
            midOpacityMult:    i.mid,
            bottomOpacityMult: i.bottom,
            globalOpacity:     i.global
        )
    }

    var body: some View {
        Group {
            if colorScheme == .light {
                ZStack {
                    AuroraGlowField(config: auroraConfig)
                    SparkField(config: sparkConfig)
                }
            } else {
                OnboardingGlowField()
            }
        }
        .opacity(opacity)
    }
}
// MARK: - Previews

#Preview("Stat — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}

#Preview("Stat — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Layout/OnboardingLayout.swift` {#file-open-lightly-features-onboarding-layout-onboardinglayout-swift}

```swift
// Features/Onboarding/Layout/OnboardingLayout.swift
//
// Shared proportional spacing constants for the onboarding flow.
// All values are expressed as fractions of the screen's live height or width
// so that the layout scales correctly across the full device matrix:
//
//   iPhone SE 2/3    375 × 667 pt   (home button, no bottom safe area)
//   iPhone 16        393 × 852 pt   (34 pt bottom safe area)
//   iPhone 16 Plus   430 × 932 pt   (34 pt bottom safe area)
//   iPhone 16 Pro    402 × 874 pt   (34 pt bottom safe area)
//   iPhone 16 Pro Max 440 × 956 pt  (34 pt bottom safe area)
//
// Reference device: iPhone 16 (852 pt height).
// Fraction × 852 == the original hardcoded pt value at reference size.
//
// Usage:
//   GeometryReader { geo in
//       let h = geo.size.height
//       let w = geo.size.width
//       VStack(spacing: 0) { ... }
//           .padding(.top, OL.navTop(h))
//   }

import SwiftUI

typealias OL = OnboardingLayout

enum OnboardingLayout {

    // MARK: - Nav Bar

    /// Fixed top padding for the nav bar across all major iPhone models.
    /// GeometryReader height (safe-area-excluded) is the key.
    /// Values validated against:
    ///   SE 2/3        667pt   → 8pt
    ///   iPhone 14/15  844pt   → 12pt
    ///   iPhone 16     852pt   → 12pt
    ///   iPhone 16 Pro 874pt   → 14pt
    ///   iPhone 16 Plus 932pt  → 14pt
    ///   iPhone 16 Pro Max 956pt → 16pt
    ///   iPhone 17 Pro Max 956pt → 16pt
    static func navTop(_ h: CGFloat) -> CGFloat {
        switch h {
        case ..<700:  return 8
        case ..<860:  return 12
        case ..<940:  return 14
        default:      return 16
        }
    }

    /// Gap between nav bar and first content element.
    /// SE: ~14pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func navBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Vertical Rhythm Scale

    /// Tight gap — between tightly-coupled elements (label → sub-label).
    /// SE: ~9pt   |   reference: ~12pt   |   Pro Max: ~13pt
    static func compact(_ h: CGFloat) -> CGFloat   { h * 0.014 }

    /// Standard section gap — between distinct content blocks.
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func standard(_ h: CGFloat) -> CGFloat  { h * 0.028 }

    /// Loose breathing room — between major sections or before/after CTA.
    /// SE: ~31pt  |   reference: ~40pt   |   Pro Max: ~45pt
    static func loose(_ h: CGFloat) -> CGFloat     { h * 0.047 }

    // MARK: - Progress Bar Clearance

    /// Space above the progress bar (below nav / safe area).
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func progressTop(_ h: CGFloat) -> CGFloat    { h * 0.028 }

    /// Space below the progress bar before the first text element.
    /// SE: ~15pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func progressBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Spacer Bounds

    /// Minimum spacer height — prevents content from touching on SE.
    static func spacerMin(_ h: CGFloat) -> CGFloat  { h * 0.033 }

    /// Maximum spacer height — prevents excessive dead space on Pro Max.
    static func spacerMax(_ h: CGFloat) -> CGFloat  { h * 0.075 }

    // MARK: - Atmosphere Decoration

    /// Width for full-bleed atmosphere ellipses (maps 600 pt at 393 w reference).
    static func atmosW(_ w: CGFloat) -> CGFloat { w * 1.53 }

    /// Height for full-bleed atmosphere ellipses (maps 500 pt at 852 h reference).
    static func atmosH(_ h: CGFloat) -> CGFloat { h * 0.587 }

    // MARK: - ScrollView Content

    /// Minimum VStack height inside a ScrollView — fills screen before
    /// scroll activates, preventing compression on small devices.
    static func scrollMinH(_ h: CGFloat) -> CGFloat { h * 0.85 }
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift` {#file-open-lightly-features-onboarding-views-onboardingflowview-swift}

```swift
// Features/Onboarding/OnboardingFlowView.swift

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "OnboardingFlowView")

enum OnboardingStep: Int, CaseIterable {
    case stat
    case brand
    case name
    case modeSelect
    case contextSelect
    case curiosityPicker
    case buildingPath
    case cardReveal
    case groundRules
}

struct OnboardingFlowView: View {

    init(startAt: OnboardingStep = .stat) {
        _currentStep = State(initialValue: startAt)
    }

    @State private var currentStep: OnboardingStep
    @State private var onboardingData = OnboardingData()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // ── Shared background ─────────────────────────────────────
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            // ── Persistent atmosphere ─────────────────────────────────
            OnboardingAtmosphere(
                config:      atmosphereConfig,
                sparkConfig: sparkConfig
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // ── Screen switch ─────────────────────────────────────────
            switch currentStep {

            case .stat:
                OnboardingStatView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentStep = .brand
                    }
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(
                    onFinished: {
                        currentStep = .name
                    }
                )

            case .name:
                OnboardingNameView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .modeSelect) },
                    onBack:     { advance(to: .brand) }
                )

            case .modeSelect:
                OnboardingModeSelectView(
                    data:       $onboardingData,
                    onContinue: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .curiosityPicker)
                        } else {
                            advance(to: .contextSelect)
                        }
                    },
                    onBack: { advance(to: .name) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .contextSelect:
                OnboardingContextView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .curiosityPicker) },
                    onBack:     { advance(to: .modeSelect) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .buildingPath) },
                    onBack: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .modeSelect)
                        } else {
                            advance(to: .contextSelect)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .buildingPath:
                OnboardingBuildingPathView(
                    data:       $onboardingData,
                    onFinished: { advance(to: .cardReveal) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .cardReveal:
                OnboardingCardRevealView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .groundRules) }
                )
                .transition(.opacity)

            case .groundRules:
                OnboardingGroundRulesView(
                    data:       $onboardingData,
                    onFinished: {
                        let experience = deriveExperienceType(from: onboardingData)
                        appState.experienceType = experience
                        logger.info("Onboarding complete — experienceType: \(experience.rawValue)")
                        hasCompletedOnboarding = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Atmosphere config per step

    private var atmosphereConfig: AtmosphereConfig {
        switch currentStep {
        case .stat:            return .stat
        case .brand:           return .brand
        case .name:            return .name
        case .modeSelect:      return .modeSelect
        case .contextSelect:   return .contextSelect
        case .curiosityPicker: return .curiosityPicker
        case .buildingPath:    return .buildingPath
        case .cardReveal:      return .cardReveal
        case .groundRules:     return .groundRules
        }
    }

    // MARK: - Spark config per step (light mode only)

    private var sparkConfig: SparkConfiguration {
        switch currentStep {
        case .stat:            return .statView
        case .brand:           return .statView
        case .name:            return .nameView
        case .modeSelect:      return .modeSelectView
        case .contextSelect:   return .contextView
        case .curiosityPicker: return .curiosityPickerView
        case .buildingPath:    return .curiosityPickerView
        case .cardReveal:      return .curiosityPickerView
        case .groundRules:     return .groundRulesView
        }
    }

    // MARK: - Navigation

    private func advance(to step: OnboardingStep) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentStep = step
        }
    }

    // MARK: - Experience Type Derivation

    private func deriveExperienceType(from data: OnboardingData) -> ExperienceType {
        switch data.explorationMode {
        case .browsing:
            return .browsing
        case .solo:
            switch data.relationshipContext {
            case .partneredOpen, .partneredHidden:
                return .soloPartnered
            default:
                return .soloSingle
            }
        case .couple:
            let isExperienced = data.nmStage == .experienced
                || data.relationshipContext == .someExperience
            return isExperienced ? .coupleExperienced : .coupleNew
        case .none:
            logger.warning("deriveExperienceType: explorationMode nil — defaulting to soloSingle")
            return .soloSingle
        }
    }
}

// MARK: - Previews

#Preview("Full Flow — Dark") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Full Flow — Light") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

#Preview("Jump → Curiosity Picker") {
    OnboardingFlowView(startAt: .curiosityPicker)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Brand") {
    OnboardingFlowView(startAt: .brand)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Name") {
    OnboardingFlowView(startAt: .name)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift` {#file-open-lightly-features-onboarding-views-onboardingstatview-swift}

```swift
import SwiftUI

// MARK: - Layout constants
private let kReferenceHeight: CGFloat = 844

// MARK: - Spacing Scale (8pt grid)
private enum Spacing {
    // Base unit
    static let unit: CGFloat = 8

    // Fixed steps
    static let xs:  CGFloat = 8   // 1×
    static let sm:  CGFloat = 16  // 2×
    static let md:  CGFloat = 24  // 3×
    static let lg:  CGFloat = 32  // 4×
    static let xl:  CGFloat = 48  // 6×

    // Screen-relative top padding
    // Keeps hero vertically centred on every device
    //
    //  iPhone SE  (568pt) → ~10%  = 56pt  (feels tight, so floor at 8%)
    //  iPhone 14  (844pt) → 10%  = 84pt
    //  iPhone 14+ (926pt) → 10%  = 92pt
    //  iPhone 15 Pro Max (932pt) → 10% = 93pt
    static func topPad(for h: CGFloat) -> CGFloat {
        let pct: CGFloat = h <= 700 ? 0.08 : 0.10
        return (h * pct).rounded()
    }

    // Space between stat and body copy
    // Larger screens get more air; SE gets minimum viable
    static func statToBody(scale: CGFloat) -> CGFloat {
        (24 * scale).rounded()   // 24pt @ 844  →  ~16pt @ SE
    }

    // Body copy → citation pill
    // These are *related* items so keep them close (sm)
    static func bodyToCite(scale: CGFloat) -> CGFloat {
        (16 * scale).rounded()
    }

    // Citation pill → ethos line
    // Slightly more air — different semantic group
    static func citeToEthos(scale: CGFloat) -> CGFloat {
        (28 * scale).rounded()
    }

    // Bottom safe area under home bar
    static let homeBarBottom: CGFloat = 8

    // Horizontal page margin — matches HIG (16pt min, 20pt comfortable)
    static let hPad: CGFloat = 24
}

// MARK: - Main Onboarding View
struct OnboardingStatView: View {
    
    var onContinue: (() -> Void)? = nil
    
    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat = 2.5
    @State private var glowPulseHigh = false
    @State private var castPulseHigh = false
    
    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false
    
    @State private var citeOpen = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false
    
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    
    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let scale   = screenH / kReferenceHeight
            let screenW = geo.size.width
            let statFontSize: CGFloat = screenH <= 700
            ? 100
            : (screenW > 390 ? 164 : 140)
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.12), location: 0),
                            .init(color: Color.blue.opacity(0.06),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: 380, height: 220)
                        .blur(radius: 90)
                    // ✦ SPACING — keep cast glow anchored below stat block
                        .offset(y: 260 * scale)
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 0) {
                    
                    // ──────────────────────────────────────────
                    // TOP PADDING
                    // Screen-relative so hero sits at ~golden
                    // ratio on every device size.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.topPad(for: screenH))
                    
                    // ──────────────────────────────────────────
                    // HERO BLOCK
                    // All content items are *related*, so they
                    // share a single VStack with explicit,
                    // intentional gaps rather than Spacers.
                    // ──────────────────────────────────────────
                    VStack(spacing: 0) {
                        
                        StatNumberView(
                            holoShiftPhase:  holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh:   glowPulseHigh,
                            castPulseHigh:   castPulseHigh,
                            fontSize:        statFontSize,
                            isLight:         isLight
                        )
                        // ✦ stat → body: 24pt scaled (related, but different type)
                        .padding(.bottom, Spacing.statToBody(scale: scale))
                        
                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18))
                            .lineSpacing(10.8)
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)
                        
                        // ✦ body → citation pill: 16pt scaled (tightly related)
                        CitationTapView(citeOpen: $citeOpen)
                            .padding(.top, Spacing.bodyToCite(scale: scale))
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)
                        
                        // ✦ citation → ethos: 28pt scaled (new semantic group)
                        EthosTextView()
                            .padding(.top, Spacing.citeToEthos(scale: scale))
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                            .animation(.easeOut(duration: 0.5).delay(1.0), value: showEthos)
                    }
                    .padding(.horizontal, Spacing.hPad)
                    
                    // ──────────────────────────────────────────
                    // FLEXIBLE SPACE
                    // Single Spacer between content and CTA so
                    // the button is always visually anchored to
                    // the bottom on every screen height.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.lg)
                    
                    // ──────────────────────────────────────────
                    // CTA — anchored to bottom
                    // ──────────────────────────────────────────
                    HoloCTAButton(
                        title: "Explore",
                        isEnabled: true,
                        action: {
                            guard !hasAdvanced else { return }
                            hasAdvanced = true
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingStatView: onContinue not injected — wire from coordinator.")
#endif
                            onContinue?()
                        },
                        cornerRadius: 100,
                        height: 56,
                        lightModeGradient: isLight ? LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.0),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ) : nil
                    )
                    .padding(.horizontal, Spacing.hPad)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)
                    
                  
                    
                    
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        }
        .onDisappear {
            hasAnimated = false
            hasAdvanced = false
        }
    }
    
    // MARK: - Animation Orchestration
    private func startAllAnimations() {
        
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            holoShiftPhase = 0.65
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            holoFlashOffset = -0.5
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            glowPulseHigh = true
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            castPulseHigh = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5))  { showStatLabel = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.7))  { showCiteTap   = true }
        withAnimation(.easeOut(duration: 0.5).delay(1.0))  { showEthos     = true }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(1.05)) {
            showCTA = true
        }
    }
    
    // MARK: - Stat Number (Holographic "1 in 5")
    private struct StatNumberView: View {
        let holoShiftPhase: CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh: Bool
        let castPulseHigh: Bool
        
        var fontSize: CGFloat = 140
        var isLight: Bool = false
        
        private let txt = "1 in 5"
        
        private var fnt:  Font    { AppFonts.display(fontSize, weight: .bold) }
        private var trk:  CGFloat { -3.2 * (fontSize / 140) }
        
        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }
        
        private var holoStops: [Gradient.Stop] {
            [
                .init(color: AppColors.cyan,    location: 0.00),
                .init(color: AppColors.purple,  location: 0.25),
                .init(color: AppColors.magenta, location: 0.50),
                .init(color: AppColors.pink,    location: 0.65),
                .init(color: AppColors.purple,  location: 0.80),
                .init(color: AppColors.cyan,    location: 1.00),
            ]
        }
        
        private var warmStops: [Gradient.Stop] {
            [
                .init(color: AppColors.magenta,   location: 0.00),
                .init(color: AppColors.orangeHot, location: 0.55),
                .init(color: AppColors.gold,      location: 1.00),
            ]
        }
        
        private var holoGradient: LinearGradient {
            LinearGradient(
                stops:      holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var warmGradient: LinearGradient {
            LinearGradient(
                stops:      warmStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var activeGradient: LinearGradient {
            isLight ? warmGradient : holoGradient
        }
        
        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }
        
        var body: some View {
            ZStack {
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    .padding(-6)
                
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: isLight
                              ? AppColors.magenta.opacity(0.18)
                              : AppColors.purple.opacity(0.18), location: 0),
                        .init(color: isLight
                              ? AppColors.gold.opacity(0.10)
                              : AppColors.cyan.opacity(0.10),   location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    .offset(y: castOffset)
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                     location: 0.00),
                                .init(color: .clear,                     location: 0.30),
                                .init(color: Color.white.opacity(0.30),  location: 0.38),
                                .init(color: Color.white.opacity(0.00),  location: 0.42),
                                .init(color: .clear,                     location: 0.50),
                                .init(color: Color.white.opacity(0.18),  location: 0.60),
                                .init(color: .clear,                     location: 0.65),
                                .init(color: .clear,                     location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y:  1.0),
                            endPoint:   UnitPoint(x:  1.1, y: -0.25)
                        )
                        .frame(width: 800)
                        .offset(x: holoFlashOffset * 320)
                        .mask { baseText }
                    }
                    .clipped()
            }
            .fixedSize()
        }
    }
    
    // MARK: - Citation Tap
    private struct CitationTapView: View {
        @Binding var citeOpen: Bool
        
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        private func citationBody() -> AttributedString {
            var result = AttributedString()
            
            var first = AttributedString("8,718 single adults")
            first.font = AppFonts.body(11.5, weight: .semibold)
            result.append(first)
            
            var second = AttributedString(" across two nationally representative studies. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(11.5, weight: .regular)
            result.append(second)
            
            return result
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(isLight
                                             ? AppColors.magenta
                                             : AppColors.cyanLight)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(isLight
                                  ? Color.white.opacity(0.08)
                                  : Color.white.opacity(0.06))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isLight
                                        ? AppColors.lightBorder
                                        : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .buttonStyle(.plain)
                // ✦ NO top padding here — parent VStack owns the gap above
                
                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextPrimary
                                             : AppColors.textPrimary)
                            .lineSpacing(11.5 * 0.7)
                        
                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10).italic())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                            .padding(.top, Spacing.xs)   // 8pt — tight, same group
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical,   Spacing.sm)    // 16pt
                    .padding(.horizontal, Spacing.sm)    // 16pt
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isLight
                                  ? AppColors.lightCardFill
                                  : AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(isLight
                                        ? AppColors.lightBorder
                                        : AppColors.borderActive,
                                        lineWidth: 1))
                    )
                    .shadow(color: isLight
                            ? AppColors.lightShadowPurple
                            : Color.black.opacity(0.5),
                            radius: isLight ? 16 : 20,
                            y:      isLight ?  4 :  6)
                    .padding(.top, Spacing.sm)           // 16pt — card floats below pill
                    .frame(maxHeight: 140)
                    .clipped()
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
    }
    
    // MARK: - Ethos Text
    private struct EthosTextView: View {
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        var body: some View {
            if isLight {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(AppColors.lightCardTitle)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.90),
                                AppColors.purple.opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(.white)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            }
        }
    }
    
}
#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift` {#file-open-lightly-features-onboarding-views-onboardingbrandview-swift}

```swift
import SwiftUI
import Combine

struct OnboardingBrandView: View {

    var onFinished: (() -> Void)? = nil

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Screen geometry

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    // MARK: - Canvas bloom state

    @State private var bl1Width: CGFloat = 6
    @State private var bl1Opacity: Double = 0.8
    @State private var hotWidth: CGFloat = 3
    @State private var hotOpacity: Double = 0.6
    @State private var thickWidth: CGFloat = 0
    @State private var thickOpacity: Double = 0
    @State private var centerGlowOpacity: Double = 0
    @State private var centerGlowScale: CGFloat = 1.0
    @State private var wisp1Opacity: Double = 0
    @State private var wisp2Opacity: Double = 0
    @State private var wisp3Opacity: Double = 0
    @State private var wisp1Offset: CGSize = .zero
    @State private var wisp1Scale: CGFloat = 1.0
    @State private var wisp2Offset: CGSize = .zero
    @State private var wisp2Scale: CGFloat = 1.0
    @State private var wisp3Offset: CGSize = .zero
    @State private var wisp3Scale: CGFloat = 1.0
    @State private var floorWidth: CGFloat = 0
    @State private var floorOpacity: Double = 0
    @State private var floorScaleX: CGFloat = 1.0

    // MARK: - Holo gradient sweep state

    @State private var holoPhase: CGFloat = 0
    @State private var holoPhaseB: CGFloat = 0

    // MARK: - Wordmark per-word state

    @State private var openOpacity: Double = 0
    @State private var openScale: CGFloat = 0.90
    @State private var openOffsetY: CGFloat = 12
    @State private var lightlyOpacity: Double = 0
    @State private var lightlyScale: CGFloat = 0.92
    @State private var lightlyOffsetY: CGFloat = 10
    @State private var wordmarkBreath: CGFloat = 1.0

    // MARK: - Tagline state
    //
    // taglineOpacity is EXIT-ONLY — starts at 1.0, only animated to 0 on exit.
    // No positional animation on the container — always at final position.
    //
    // Line 1 enters t=1950ms easeOut(0.22) → done t=2170ms
    // Line 2 enters t=2150ms easeOut(0.22) → done t=2370ms
    // Stagger gap (200ms) > duration × 0.7 (154ms) — reading beat honoured.
    // Exit does not begin until t=4500ms — 2130ms+ of settled dwell.

    @State private var taglineOpacity: Double = 1.0
    @State private var taglineBreath: Double = 0.55
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0

    // MARK: - Global state

    @State private var autoAdvanceFired = false
    @State private var filamentStarted = false
    @State private var glowFieldOpacity: Double = 0
    @State private var sceneEntryOpacity: Double = 0

    // NOTE: fadeOutOpacity REMOVED — coordinator owns the cover.

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let _ = cacheSize(geo.size)
            let w = screenW
            let h = screenH

            ZStack {
                Color.clear.ignoresSafeArea()

                wisps(w: w, h: h)
                    .allowsHitTesting(false)

                centerGlow()
                    .allowsHitTesting(false)

                floorReflection(h: h)
                    .allowsHitTesting(false)

                if filamentStarted {
                    FilamentView(size: screenW, mode: .solo, speed: 1.0, showConnections: false)
                        .frame(width: screenW, height: screenW)
                        .position(x: w / 2, y: h * 0.46)
                        .allowsHitTesting(false)
                }

                wordmark
                    .scaleEffect(wordmarkBreath)
                    .position(x: w / 2 + 8, y: h * 0.46)
                    .accessibilityHidden(true)

                taglineView
                    .position(x: w / 2, y: h * 0.571)
                    .accessibilityHidden(true)

                // NOTE: No fadeOutOpacity cover layer here.
                // The coordinator's cover sits above this entire view.

                #if DEBUG
                VStack {
                    Spacer()
                Button("↺ Replay") { replay() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 48)
                }
                #endif

                // Accessibility: invisible, VoiceOver only.
                VStack(spacing: 4) {
                    Text("Open Lightly")
                    Text("Hard Conversations, Made Easier.")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Open Lightly. Hard Conversations, Made Easier.")
                .opacity(0)
                .allowsHitTesting(false)
            }
            .opacity(sceneEntryOpacity)
            .drawingGroup()
        }
        .ignoresSafeArea()
        .onAppear { startEverything() }
        .onDisappear {
            filamentStarted   = false
            autoAdvanceFired  = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                centerGlowOpacity = 0
                floorOpacity      = 0
                glowFieldOpacity  = 0
                holoPhase         = 0
                holoPhaseB        = 0
                wordmarkBreath    = 1.0
                taglineBreath     = 0.55
            }
        }
    }

    // MARK: - Size cache

    private func cacheSize(_ size: CGSize) {
        if screenW != size.width || screenH != size.height {
            DispatchQueue.main.async {
                screenW = size.width
                screenH = size.height
            }
        }
    }

    // MARK: - Background layers

    private func bleedInit(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.02),
                        .init(color: AppColors.cyan.opacity(0.12),    location: 0.12),
                        .init(color: AppColors.purple.opacity(0.22),  location: 0.30),
                        .init(color: AppColors.magenta.opacity(0.20), location: 0.50),
                        .init(color: AppColors.purple.opacity(0.18),  location: 0.70),
                        .init(color: AppColors.pink.opacity(0.10),    location: 0.88),
                        .init(color: .clear,                          location: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bl1Width, height: h)
            .opacity(bl1Opacity)
    }

    private func bleedThick(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                           location: 0.05),
                        .init(color: AppColors.magenta.opacity(0.14),  location: 0.20),
                        .init(color: AppColors.purple.opacity(0.20),   location: 0.40),
                        .init(color: AppColors.cyan.opacity(0.12),     location: 0.60),
                        .init(color: AppColors.pink.opacity(0.14),     location: 0.80),
                        .init(color: .clear,                           location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: thickWidth, height: h)
            .blur(radius: 40)
            .opacity(thickOpacity)
    }

    private func bleedHot(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.10),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: hotWidth, height: h * 0.8)
            .opacity(hotOpacity)
    }

    private func centerGlow() -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.purple.opacity(0.10),  location: 0),
                        .init(color: AppColors.magenta.opacity(0.06), location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 250, height: 150)
            .scaleEffect(centerGlowScale)
            .blur(radius: 50)
            .opacity(centerGlowOpacity)
    }

    private func wisps(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(AppColors.cyan.opacity(0.06))
                .frame(width: 120, height: 80)
                .blur(radius: 35)
                .scaleEffect(wisp1Scale)
                .offset(wisp1Offset)
                .offset(x: -w * 0.15, y: -h * 0.12)
                .opacity(wisp1Opacity)

            Ellipse()
                .fill(AppColors.magenta.opacity(0.05))
                .frame(width: 80, height: 120)
                .blur(radius: 35)
                .scaleEffect(wisp2Scale)
                .offset(wisp2Offset)
                .offset(x: w * 0.18, y: h * 0.02)
                .opacity(wisp2Opacity)

            Ellipse()
                .fill(AppColors.purple.opacity(0.06))
                .frame(width: 100, height: 90)
                .blur(radius: 35)
                .scaleEffect(wisp3Scale)
                .offset(wisp3Offset)
                .offset(x: -w * 0.05, y: h * 0.18)
                .opacity(wisp3Opacity)
        }
    }

    private func floorReflection(h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.magenta.opacity(0.10), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),  location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: floorWidth * 0.5
                )
            )
            .frame(width: floorWidth, height: 90)
            .scaleEffect(x: floorScaleX, y: 1.0)
            .blur(radius: 35)
            .opacity(floorOpacity)
            .offset(y: h * 0.36)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(spacing: screenH < 700 ? -10 : -16) {
            Text("Open")
                .font(.custom("Zodiak-Extrabold", size: 58))
                .tracking(-1.5)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.purple)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.cyan, AppColors.purple],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhase * 0.4,
                                y:  0.0 + holoPhase * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhase * 0.4,
                                y:  1.0 + holoPhase * 0.2
                            )
                          ))
                )
                .opacity(openOpacity)
                .scaleEffect(openScale)
                .offset(y: openOffsetY)

            Text("Lightly")
                .font(.custom("Zodiak-Bold", size: 54))
                .tracking(2)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.orangeHot)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.pink, AppColors.pink],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhaseB * 0.4,
                                y:  0.0 + holoPhaseB * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhaseB * 0.4,
                                y:  1.0 + holoPhaseB * 0.2
                            )
                          ))
                )
                .opacity(lightlyOpacity)
                .scaleEffect(lightlyScale)
                .offset(y: lightlyOffsetY)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Tagline

    private var taglineView: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Hard")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Conversations")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line1Opacity)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Made")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Easier")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line2Opacity)
        }
        .font(.custom("Switzer-Light", size: 18))
        .tracking(0.3)
        .multilineTextAlignment(.center)
        .opacity(taglineOpacity)
    }

    // MARK: - Replay (DEBUG only)

    private func replay() {
        #if DEBUG
        if autoAdvanceFired {
            print("[OnboardingBrandView] ⚠️ replay() called after " +
                  "ambient loops started — competing animations possible.")
        }
        #endif

        bl1Width          = 6
        bl1Opacity        = 0.8
        hotWidth          = 3
        hotOpacity        = 0.6
        thickWidth        = 0
        thickOpacity      = 0
        centerGlowOpacity = 0
        centerGlowScale   = 1.0
        wisp1Opacity      = 0
        wisp2Opacity      = 0
        wisp3Opacity      = 0
        wisp1Offset       = .zero
        wisp2Offset       = .zero
        wisp3Offset       = .zero
        wisp1Scale        = 1.0
        wisp2Scale        = 1.0
        wisp3Scale        = 1.0
        floorWidth        = 0
        floorOpacity      = 0
        floorScaleX       = 1.0
        holoPhase         = 0
        holoPhaseB        = 0
        openOpacity       = 0
        openScale         = 0.90
        openOffsetY       = 12
        lightlyOpacity    = 0
        lightlyScale      = 0.92
        lightlyOffsetY    = 10
        wordmarkBreath    = 1.0
        taglineOpacity    = 1.0
        taglineBreath     = 0.55
        line1Opacity      = 0
        line2Opacity      = 0
        glowFieldOpacity  = 0
        sceneEntryOpacity = 0
        filamentStarted   = false
        autoAdvanceFired  = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startEverything()
        }
    }

    // MARK: - Animation timeline
    //
    // FINAL TIMELINE (v7 — Layered Dissolve) total runtime ~5020ms to handoff:
    //
    //   t=0ms       Canvas bloom begins
    //   t=300ms     Filament starts (skipped if reduceMotion)
    //   t=600ms     "Open" lands
    //   t=900ms     "Lightly" lands
    //   t=1000ms    Glow field begins (dark: 2.5s creep / light: 0.6s)
    //   t=1800ms    Atmospheric loops begin (skipped if reduceMotion)
    //   t=2000ms    Wordmark gradient sweep begins
    //   t=2200ms    Wordmark breath begins
    //   t=1950ms    Line 1 fades in — easeOut(0.22) done t=2170ms
    //   t=2150ms    Line 2 fades in — easeOut(0.22) done t=2370ms
    //   t=2370ms–4500ms  Fully settled dwell (~2130ms)
    //   t=4500ms    Tagline exits     — easeIn(160ms)  done t=4660ms
    //   t=4700ms    Wordmark exits    — easeIn(280ms)  done t=4980ms
    //   t=4780ms    Atmosphere exits  — easeIn(400ms)  done t=5180ms
    //   t=5020ms    onFinished() fires — coordinator takes over
    //
    //   COORDINATOR then:
    //   +0ms    NextScreen renders under cover (already opaque)
    //   +50ms   Cover lifts — easeOut(320ms)
    //   +410ms  Cover gone, NextScreen fully visible
    //   +450ms  BrandView removed from hierarchy

    private func startEverything() {

        // ── Scene entry fade ──────────────────────
        withAnimation(.easeOut(duration: 0.4)) {
            sceneEntryOpacity = 1.0
        }

        // ── Phase 1: Canvas bloom (0ms) ──────────────────────────────────

        withAnimation(.easeOut(duration: 1.2)) {
            bl1Width   = 420
            bl1Opacity = 0.18
        }
        withAnimation(.easeOut(duration: 0.8)) {
            hotWidth   = 200
            hotOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 1.4)) {
                thickWidth   = 420
                thickOpacity = 0.22
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.8)) {
                wisp1Opacity      = 1.0
                wisp2Opacity      = 1.0
                wisp3Opacity      = 1.0
                centerGlowOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 1.0)) {
                floorWidth   = 360
                floorOpacity = 0.4
            }
        }

        // ── Glow field ────────────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.5)) {
                glowFieldOpacity = 1.0
            }
        }

        // ── Phase 2: "Open" lands (600ms) ────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                openOpacity = 1.0
                openScale   = 1.0
                openOffsetY = 0
            }
        }

        // ── Filament (300ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if !reduceMotion {
                filamentStarted = true
            }
        }

        // ── Phase 2b: "Lightly" lands (900ms) ────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                lightlyOpacity = 1.0
                lightlyScale   = 1.0
                lightlyOffsetY = 0
            }
        }

        // ── Ambient loops — staggered ignition (v7) ───────────────────────
        //
        // Three separate dispatch times prevent the "loop bomb" where all
        // repeatForever transactions fire on the same RunLoop tick:
        //
        //   t=1800ms  Atmospheric layer (wisps, glow, floor)
        //   t=2000ms  Gradient sweep (holoPhase, holoPhaseB)
        //   t=2200ms  Wordmark breath (wordmarkBreath, taglineBreath)
        //
        // 200ms micro-stagger is sub-perceptual as a pause but spreads
        // GPU transaction load across frames.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
            ) {
                wisp1Offset     = CGSize(width: 20,  height: -15)
                wisp1Scale      = 1.10
                wisp2Offset     = CGSize(width: -18, height: 18)
                wisp2Scale      = 1.12
                wisp3Offset     = CGSize(width: 12,  height: 15)
                wisp3Scale      = 1.08
                centerGlowScale = 1.2
                floorScaleX     = 1.06
                floorOpacity    = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 5.2)
                    .repeatForever(autoreverses: true)
            ) {
                holoPhase  = 1.0
                holoPhaseB = 1.0
            }
            withAnimation(
                .easeInOut(duration: 5.5)
                    .repeatForever(autoreverses: true)
            ) {
                taglineBreath = 0.72
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 5.0)
                    .repeatForever(autoreverses: true)
            ) {
                wordmarkBreath = 1.02
            }
        }

        // ── Tagline entrance ──────────────────────────────────────────────
        //
        // Stagger gap (200ms) > duration × 0.7 (154ms) — Line 1 fully
        // opaque before Line 2 starts. Reading beat is honoured.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            withAnimation(.easeOut(duration: 0.22)) {
                line1Opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                line2Opacity = 1.0
            }
        }

        // ── Settled dwell: t=2370ms → t=4500ms (~2130ms) ─────────────────

        // ── Phase 4: Exit sequence ────────────────────────────────────────
        //
        // Beat 1 — Tagline dissolves (t=4500ms, 160ms)
        // Beat 2 — Wordmark contracts+fades (t=4700ms, 280ms)
        //          Starts 40ms after tagline done (4660ms + 40ms buffer)
        // Beat 3 — Atmosphere fades (t=4780ms, 400ms)
        //          Overlaps wordmark tail — bg layer has lower priority
        // Handoff — onFinished() at t=5020ms
        //          40ms before atmosphere fully done (5180ms)
        //          Coordinator receives and starts cover lift

        // Beat 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.50) {
            withAnimation(.easeIn(duration: 0.16)) {
                taglineOpacity = 0
            }
        }

        // Beat 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.70) {
            withAnimation(.easeIn(duration: 0.28)) {
                openOpacity    = 0
                openScale      = 0.96
                lightlyOpacity = 0
                lightlyScale   = 0.96
            }
        }

        // Beat 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.78) {
            withAnimation(.easeIn(duration: 0.40)) {
                glowFieldOpacity  = 0
                centerGlowOpacity = 0
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                floorOpacity      = 0
            }
        }

        // ── Handoff (5020ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
            withAnimation(.easeIn(duration: 0.35)) {
                sceneEntryOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.20) {
            guard !autoAdvanceFired else { return }
            autoAdvanceFired = true
            #if DEBUG
            assert(
                onFinished != nil,
                "OnboardingBrandView: onFinished not injected — " +
                "wire this callback from the coordinator."
            )
            #endif
            onFinished?()
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.light)
}
 

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift` {#file-open-lightly-features-onboarding-views-onboardingnameview-swift}

```swift

// OnboardingNameView.swift
// Open Lightly
//
// Screen 1: Name + Pronouns

import SwiftUI

// MARK: - Main View

struct OnboardingNameView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // Form state
    @State private var displayName:       String         = ""
    @State private var selectedGender:    String? = nil
    @State private var customGenderText:  String = ""
    @State private var showCustomGenderField: Bool = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var borderPhase: CGFloat   = 0
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // Greeting response
    @State private var greetingVisible = false
    @State private var greetingOwnsName: Bool = false
    @State private var nameTextOpacity: Double = 1.0
    @State private var fieldCollapsed: Bool = false
    @State private var typingDebounce: DispatchWorkItem? = nil

    // Gender section
    @State private var genderSectionVisible = false

    // Validation Bloom
    @State private var isButtonGlowing: Bool = false

    // Pulse Animation
    @State private var glowPulse: Bool = false

    // Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface tokens

    private var kFieldBG: Color {
        colorScheme == .light
            ? AppColors.lightSurfaceBg
            : Color.white.opacity(0.07)
    }

    private var kGlassBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : Color.white.opacity(0.09)
    }

    private var kFieldBorderActive: some ShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(AppColors.warmAuroraBorder)
        } else {
            return AnyShapeStyle(AppColors.spectrumBorder)
        }
    }

    private var kFloatingLabelFocused: Color {
        colorScheme == .light
            ? AppColors.lightLabelFocused
            : AppColors.purpleLight
    }

    private var kFloatingLabelUnfocused: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.40)
            : AppColors.textTertiary
    }

    private var kTextPrimary: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle
            : .white
    }

    private var kPronounLabel: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.65)
            : .white.opacity(0.75)
    }

    private var kPronounHint: Color {
        colorScheme == .light
            ? AppColors.lightHintText
            : AppColors.textTertiary
    }

    private var kCustomPillFill: Color {
        colorScheme == .light
            ? AppColors.lightFrostPillCustom
            : AppColors.surfaceBg
    }

    private var kCustomPillBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : AppColors.borderHover
    }

    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 1 && trimmed.count <= 30 && selectedGender != nil
    }

    // MARK: - Name Field

    @ViewBuilder
    private var nameField: some View {
        ZStack(alignment: .leading) {

            // Floating label
            Text("What should we call you?")
                .font(displayName.isEmpty && !nameFieldFocused
                      ? AppFonts.display(22, weight: .semibold)
                      : AppFonts.overline)
                .foregroundStyle(
                    displayName.isEmpty && !nameFieldFocused
                        ? (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightTextSecondary)
                            : AnyShapeStyle(AppColors.textSecondary))
                        : (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightLabelFocused)
                            : AnyShapeStyle(AppColors.purpleLight))
                )
                .offset(y: displayName.isEmpty && !nameFieldFocused ? 0 : -36)
                .animation(.easeInOut(duration: 0.35), value: nameFieldFocused)
                .animation(.easeInOut(duration: 0.35), value: displayName.isEmpty)
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: fieldCollapsed)
                .accessibilityHidden(true)

            TextField("", text: $displayName)
                .font(AppFonts.display(28, weight: .semibold))
                .foregroundColor(
                    (colorScheme == .light
                        ? AppColors.lightCardTitle
                        : AppColors.textPrimary)
                    .opacity(nameTextOpacity)
                )
                .tint(colorScheme == .light
                    ? AppColors.lightLabelFocused
                    : AppColors.cyan)
                .offset(y: 10)
                .focused($nameFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    nameFieldFocused = false
                    triggerCollapse()
                }
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                .disabled(fieldCollapsed)
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > 30 {
                        displayName = String(newValue.prefix(30))
                    }

                    let hasContent = !newValue
                        .trimmingCharacters(in: .whitespaces)
                        .isEmpty

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        genderSectionVisible = hasContent
                    }

                    typingDebounce?.cancel()

                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        return
                    }

                    let work = DispatchWorkItem {
                        triggerCollapse()
                    }
                    typingDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
                }
                .onChange(of: nameFieldFocused) { _, isFocused in
                    if isFocused && greetingOwnsName {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                    }
                }
                .accessibilityLabel("What should we call you?")
        }
        .frame(height: 72)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            ZStack {
                // Base line — always visible
                Rectangle()
                    .fill(
                        nameFieldFocused || !displayName.isEmpty
                            ? (colorScheme == .light
                                ? AnyShapeStyle(AppColors.warmAuroraBorder)
                                : AnyShapeStyle(AppColors.spectrumBorder))
                            : (colorScheme == .light
                                ? AnyShapeStyle(AppColors.lightBorder)
                                : AnyShapeStyle(AppColors.border))
                    )
                    .frame(height: nameFieldFocused ? 3 : 2)
                    .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                // Gradient glow line — appears when focused or has content
                if nameFieldFocused || !displayName.isEmpty {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.6),
                                        AppColors.pink.opacity(0.9),
                                        AppColors.purple.opacity(0.7),
                                        AppColors.magenta.opacity(0.6)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.6),
                                        AppColors.purple.opacity(0.9),
                                        AppColors.pink.opacity(0.8),
                                        AppColors.cyan.opacity(0.6)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 4)
                        .opacity(nameFieldFocused ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                    // Outer soft glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.2),
                                        AppColors.pink.opacity(0.35),
                                        AppColors.purple.opacity(0.25),
                                        AppColors.magenta.opacity(0.2)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.2),
                                        AppColors.purple.opacity(0.35),
                                        AppColors.pink.opacity(0.3),
                                        AppColors.cyan.opacity(0.2)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .blur(radius: 6)
                        .opacity(nameFieldFocused ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)
                }
            }
            .opacity(fieldCollapsed ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // ── Background ───────────────────────────────────────────
                Color.clear.ignoresSafeArea()

                // ── Atmosphere ellipse ────────────────────────────────────
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.22), location: 0),
                            .init(color: Color.blue.opacity(0.12),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: geo.size.width, height: h * 0.31)
                        .blur(radius: 80)
                        .offset(y: h * 0.30)
                        .allowsHitTesting(false)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, geo.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold))
                            .foregroundColor(kTextPrimary)
                        LivingText(text: "acquainted.")
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1.0 : 0.95)
                    .padding(.bottom, 28)

                    // ── Name field ────────────────────────────────────────
                    nameField
                        .padding(.bottom, 20)
                        .opacity(cardVisible ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)

                    // ── Greeting ──────────────────────────────────────────
                    // FIX: corrected brace structure
                    HStack(alignment: .firstTextBaseline, spacing: 7.5) {
                        Spacer()

                        Text("Hi ")
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary.opacity(0.94))

                        Text(displayName.trimmingCharacters(in: .whitespaces))
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary)
                            .modifier(GlowUnderline(isLight: colorScheme == .light))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? -65 : 16)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.88),
                        value: greetingVisible
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            nameFieldFocused = true
                        }
                    }
                    .accessibilityLabel("Edit name")
                    .accessibilityHint("Tap to change what we call you")
                    .accessibilityAddTraits(.isButton)

                    Rectangle()
                        .fill(colorScheme == .light
                              ? AppColors.lightBorder
                              : Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.bottom, 18)
                        .opacity(cardVisible && !fieldCollapsed ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85).delay(0.23),
                            value: cardVisible
                        )

                    genderSection
                        .opacity(cardVisible && genderSectionVisible ? 1 : 0)
                        .scaleEffect(cardVisible && genderSectionVisible ? 1.0 : 0.95)

                    Spacer(minLength: OL.spacerMin(h))

                    // ── CTA ───────────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(LinearGradient(
                                colors: [
                                    AppColors.pink.opacity(0.30),
                                    AppColors.purple.opacity(0.25),
                                    AppColors.magenta.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .blur(radius: 36)
                            .opacity(isButtonGlowing ? 1.0 : 0.0)
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.6),
                                value: isButtonGlowing
                            )
                            .allowsHitTesting(false)

                        HoloCTAButton(
                            title: "Next",
                            isEnabled: isValid
                        ) {
                            triggerHaptic(.medium)
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingNameView: onContinue not injected — " +
                                   "wire this callback from the coordinator.")
#endif
                            commitData()
                            onContinue?()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(
                            color: isButtonGlowing
                                ? AppColors.pink.opacity(
                                    reduceMotion ? 0.30 : (glowPulse ? 0.40 : 0.20)
                                )
                                : .clear,
                            radius: isButtonGlowing
                                ? (reduceMotion ? 12 : (glowPulse ? 18 : 8))
                                : 0,
                            x: 0, y: 0
                        )
                    }
                    .opacity(ctaVisible ? 1 : 0)
                    .scaleEffect(ctaVisible ? 1.0 : 0.95)

                    OnboardingFooter()
                        .opacity(ctaVisible ? 1 : 0)
                        .scaleEffect(ctaVisible ? 1.0 : 0.95)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geo.size.width, alignment: .topLeading)
            .onAppear {
                restoreStateIfNeeded()

                if isValid {
                    isButtonGlowing = true
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(0.6)
                        ) { glowPulse = true }
                    }
                }

                guard !hasAnimated else { return }
                hasAnimated = true

                if colorScheme == .dark {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        borderPhase = 1.0
                    }
                }

                let entranceSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)

                if reduceMotion {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        headerVisible = true
                        cardVisible   = true
                        ctaVisible    = true
                    }
                } else {
                    withAnimation(entranceSpring.delay(0.08)) { headerVisible = true }
                    withAnimation(entranceSpring.delay(0.23)) { cardVisible = true }
                    withAnimation(entranceSpring.delay(0.38)) { ctaVisible = true }
                }

                if !reduceMotion {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            nameFieldFocused = true
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onDisappear {
                hasAnimated      = false
                headerVisible    = false
                cardVisible      = false
                ctaVisible       = false
                isButtonGlowing  = false
                glowPulse        = false
                greetingOwnsName = false
                nameTextOpacity  = 1.0
                fieldCollapsed   = false
            }
            .onChange(of: isValid) { _, newValue in
                if newValue {
                    triggerHaptic(.medium)
                    if reduceMotion {
                        isButtonGlowing = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isButtonGlowing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(
                                .easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                            ) { glowPulse = true }
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isButtonGlowing = false
                    }
                    glowPulse = false
                }
            }
        }
    }

    // MARK: - Gender Section

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Gender identity")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(kPronounLabel)
                Spacer()
                Text("helps us personalize")
                    .font(AppFonts.body(13, weight: .regular))
                    .foregroundColor(kPronounHint)
            }
            .padding(.bottom, 12)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Man",
                        isSelected: selectedGender == "Man",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Man" ? nil : "Man"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Woman",
                        isSelected: selectedGender == "Woman",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Woman" ? nil : "Woman"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Non-binary",
                        isSelected: selectedGender == "Non-binary",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Non-binary" ? nil : "Non-binary"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Something else",
                        isSelected: selectedGender == "Something else",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Something else"
                                ? nil : "Something else"
                            showCustomGenderField = selectedGender == "Something else"
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                SelectablePill(
                    label: "Prefer not to say",
                    isSelected: selectedGender == "Prefer not to say",
                    showFlame: false
                ) {
                    nameFieldFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedGender = selectedGender == "Prefer not to say"
                            ? nil : "Prefer not to say"
                        showCustomGenderField = false
                        customGenderText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender identity — optional")
    }

    // MARK: - Haptic

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Helpers

    private func triggerCollapse() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        typingDebounce?.cancel()
        withAnimation(.easeInOut(duration: 0.35)) {
            nameTextOpacity = 0
            fieldCollapsed = true
        }
        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.85)
            .delay(0.28)
        ) {
            greetingVisible = true
            greetingOwnsName = true
        }
    }

    private func dismissCustomIfNeeded() {
        if showCustomGenderField {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCustomGenderField = false
                customGenderText = ""
            }
        }
    }

    // MARK: - State Restoration

    private func restoreStateIfNeeded() {
        if !data.displayName.isEmpty {
            displayName = data.displayName
        }
        if let savedGender = data.gender {
            selectedGender = savedGender
        }
    }

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        let custom = customGenderText.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty {
            data.gender = custom
        } else if let selected = selectedGender {
            data.gender = selected
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift` {#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift}

```swift
import SwiftUI

// MARK: - Main View

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible  = false
    @State private var navVisible    = false
    @State private var cardsVisible  = false
    @State private var hasAnimated   = false

    // Breathing atmosphere — one phase per tile, offset so they never sync
    @State private var soloBreath:    CGFloat = 0
    @State private var coupleBreath:  CGFloat = 0
    @State private var browseBreath:  CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var selectionMade: Bool {
        data.explorationMode != nil && data.nmStage != nil
    }

    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:    return "New to this — maybe I've read about it or know people who do it."
        case .exploring:  return "I've dipped my toes in. A few real experiences."
        case .experienced:return "This has been part of my life for a while."
        case .none:       return nil
        }
    }

    private var atmosphereColors: (primary: Color, secondary: Color) {
        switch data.explorationMode {
        case .solo:     return (AppColors.cyan,    AppColors.deepBlue)
        case .couple:   return (AppColors.magenta, AppColors.purple)
        case .browsing: return (AppColors.gold,    AppColors.orangeHot)
        case .none:     return (AppColors.purple,  AppColors.deepBlue)
        }
    }

    private func handleSelection(_ mode: ExplorationMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if data.explorationMode == mode {
                data.explorationMode = nil
            } else {
                data.explorationMode = mode
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder
    private func selectedBorder(
        isSelected:   Bool,
        cornerRadius: CGFloat
    ) -> some View {
        if isSelected {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 2
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .opacity(0.25)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let sectionSpacing: CGFloat = h < 700
                ? max(8.0, h * 0.012)
                : max(12.0, h * 0.018)

            ZStack {
                Color.clear.ignoresSafeArea()

                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                atmosphereColors.primary.opacity(0.30),
                                atmosphereColors.secondary.opacity(0.15),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        ))
                        .frame(width: OL.atmosW(w), height: OL.atmosH(h))
                        .offset(y: -h * 0.09)
                        .blur(radius: 80)
                        .animation(
                            .easeOut(duration: 0.45),
                            value: data.explorationMode?.rawValue ?? "none"
                        )
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    OnboardingNavBar(
                        currentStep: 2,
                        totalSteps:  6,
                        onBack:      onBack
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, max(8.0, h * 0.014))
                    .opacity(navVisible ? 1.0 : 0.0)

                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 0) {
                            contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            Spacer(minLength: 0)
                            ctaBlock.padding(.horizontal, 24)
                        }
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            }
                            ctaBlock.padding(.horizontal, 24)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                guard !hasAnimated else {
                    titleVisible = true
                    cardsVisible = true
                    navVisible   = true
                    return
                }
                hasAnimated = true
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { titleVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) { cardsVisible = true }
                withAnimation(.easeOut(duration: 0.3).delay(1.50)) { navVisible   = true }

                // Solo — 4s cycle
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    soloBreath = 1.0
                }
                // Couple — 5s cycle, different rhythm
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                        coupleBreath = 1.0
                    }
                }
                // Browsing — 6s cycle, quieter
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                        browseBreath = 1.0
                    }
                }
            }
            .onDisappear {
                hasAnimated  = false
                soloBreath   = 0
                coupleBreath = 0
                browseBreath = 0
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        sectionSpacing: CGFloat,
        geo:            GeometryProxy
    ) -> some View {
        let h = geo.size.height
        let tileH: CGFloat = max(130, h * 0.195)
        
        return VStack(alignment: .leading, spacing: sectionSpacing) {
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextPrimary
                                         : AppColors.textPrimary)
                    LivingText(text: "exploring?", font: AppFonts.heroTitle)
                }
                Text("There's no wrong way to start.")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                                     ? AppColors.lightTextSecondary
                                     : AppColors.textSecondary)
            }
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)
            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    bentoCentered(mode: .solo,   tileH: tileH)
                    bentoCentered(mode: .couple, tileH: tileH)
                }
                bentoBar(mode: .browsing)
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            
            if let mode = data.explorationMode {
                let teaserText: String = {
                    switch mode {
                    case .solo:     return "Starts with what you actually want."
                    case .couple:   return "Starts with the conversation you've been circling."
                    case .browsing: return "No commitment. Just curiosity."
                    }
                }()
                
                LivingText(
                    text: teaserText,
                    font: AppFonts.body(17, weight: .semibold)
                )
                .id(mode)
                .transition(.opacity)
                .frame(maxWidth: .infinity)
            }
            
            let expVisible = data.explorationMode != nil
            
            if expVisible {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                        Spacer()
                        Text("No judgment")
                            .font(AppFonts.overline)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextTertiary
                                             : AppColors.textTertiary)
                    }
                    
                    HStack(spacing: 10) {
                        SelectablePill(
                            label:      "Curious",
                            isSelected: data.nmStage == .curious,
                            intensity:  .dim,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .curious
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Exploring",
                            isSelected: data.nmStage == .exploring,
                            intensity:  .warm,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .exploring
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Experienced",
                            isSelected: data.nmStage == .experienced,
                            intensity:  .alive,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .experienced
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Group {
                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(isLight
                                                 ? AppColors.lightTextSecondary
                                                 : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: data.nmStage?.rawValue ?? "")
                    
                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextTertiary
                                         : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, sectionSpacing)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: data.explorationMode?.rawValue ?? "none")
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 0) {
            HoloCTAButton(title: "Next", isEnabled: selectionMade) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }
            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
        }
    }

    // MARK: - Bento Centered Tile
    @ViewBuilder
    private func bentoCentered(
        mode:  ExplorationMode,
        tileH: CGFloat
    ) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = min(tileH * 0.52, 88)

        // Per-tile color and breath values
        let tileColor: Color = {
            switch mode {
            case .solo:   return AppColors.cyan
            case .couple: return AppColors.magenta
            default:      return AppColors.purple
            }
        }()

        let breathValue: CGFloat = {
            switch mode {
            case .solo:   return soloBreath
            case .couple: return coupleBreath
            default:      return browseBreath
            }
        }()

        // Glow opacity: low at rest, amplified on selection
        let glowOpacity: Double = isSelected
            ? 0.18 + Double(breathValue) * 0.10
            : 0.06 + Double(breathValue) * 0.04

        let headline: String = {
            switch mode {
            case .solo:   return "Solo Discovery"
            case .couple: return "Shared Journey"
            default:      return ""
            }
        }()

        let subtitle: String = {
            switch mode {
            case .solo:   return "I want clarity\nfor myself first."
            case .couple: return "Starting the conversation\ntogether."
            default:      return ""
            }
        }()

        Button {
            handleSelection(mode)
        } label: {
            VStack(spacing: 6) {
                Spacer(minLength: 0)

                // CHANGE: always active, speed idles at 0.28, accelerates on selection
                TileOrbitView(
                    orbitCount: mode == .solo ? 1 : 2,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.28,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.35)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                Text(headline)
                    .font(AppFonts.display(17, weight: .semibold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: tileH)
            .background(
                ZStack {
                    // Base fill — unchanged
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing radial atmosphere — exists at rest, amplifies on selection
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tileColor.opacity(glowOpacity),
                                        tileColor.opacity(glowOpacity * 0.3),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: tileH * 0.6
                                )
                            )
                            .blur(radius: 20)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(
                ZStack {
                    selectedBorder(isSelected: isSelected, cornerRadius: 20)

                    // CHANGE: left-edge glow accent on selected tile
                    if isSelected && !isLight {
                        HStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            tileColor.opacity(0.7),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 2)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .allowsHitTesting(false)
                    }
                }
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : AppColors.purple.opacity(0.28))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowPurple
                        : AppColors.cyan.opacity(0.18))
                    : .clear,
                radius: 16
            )
            .shadow(
                color: isSelected
                    ? AppColors.magenta.opacity(isLight ? 0.06 : 0.10)
                    : .clear,
                radius: 28
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.965 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel(headline)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(headline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Bento Bar
    @ViewBuilder
    private func bentoBar(mode: ExplorationMode) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = 56

        let glowOpacity: Double = isSelected
            ? 0.18 + Double(browseBreath) * 0.08
            : 0.05 + Double(browseBreath) * 0.03

        Button {
            handleSelection(mode)
        } label: {
            HStack(spacing: 14) {
                // CHANGE: always active at idle speed
                TileOrbitView(
                    orbitCount: 3,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.22,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.30)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safe Learning")
                        .font(AppFonts.display(17, weight: .semibold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                    Text("Just looking around for now.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing gold atmosphere on browsing bar
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.gold.opacity(glowOpacity),
                                        AppColors.gold.opacity(glowOpacity * 0.25),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .blur(radius: 16)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.20 : 0.28)
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.12 : 0.18)
                    : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.97 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel("Safe Learning")
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select Safe Learning")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Dark — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .solo
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Browsing selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .browsing
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift` {#file-open-lightly-features-onboarding-views-onboardingcontextview-swift}

```swift
// Features/Onboarding/Views/OnboardingContextView.swift
//
// Screen 4: Relationship Context — branches on explorationMode
// Solo: 3 cards  |  Couple: 4 cards

import SwiftUI

struct OnboardingContextView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible      = false
    @State private var cardsVisible       = false
    @State private var reassuranceVisible = false
    @State private var hasAnimated        = false

    @State private var selection: ContextOption? = nil
    @State private var autoAdvanceFired          = false

    // FIXED: Extracted from body to avoid preview type-checker timeout.
    // `let isLight` inside body was captured across 6+ nested result-builder
    // closure scopes (foregroundStyle ternaries + background Group if/else).
    private var isLight: Bool { colorScheme == .light } // FIXED: was `let isLight` in body

    // MARK: - Option Data

    private let soloOptions: [ContextOption] = [
        ContextOption(
            id: "single", context: .single, intensity: .ember,
            title: "I'm single",
            subtitle: "No partner in the picture",
            detail: "Your journey is yours alone — we'll tailor everything to individual exploration."
        ),
        ContextOption(
            id: "partnered_open", context: .partneredOpen, intensity: .spark,
            title: "I have a partner",
            subtitle: "They know I'm exploring",
            detail: "We'll include prompts that help you navigate with transparency."
        ),
        ContextOption(
            id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
            title: "I haven't brought it up yet",
            subtitle: "Curious, but the conversation hasn't happened",
            detail: "That's exactly what this is for. We'll help you find the words."
        ),
    ]

    private let coupleOptions: [ContextOption] = [
        ContextOption(
            id: "not_talked", context: .notTalked, intensity: .ember,
            title: "Haven't really talked about it",
            subtitle: "One or both of us is curious",
            detail: "We'll start with the basics — language, comfort levels, and small openings."
        ),
        ContextOption(
            id: "talking", context: .talking, intensity: .flame,
            title: "We've been talking",
            subtitle: "No experience yet, but we're on the same page",
            detail: "Great foundation. We'll build on your shared curiosity with structured prompts."
        ),
        ContextOption(
            id: "some_experience", context: .someExperience, intensity: .inferno,
            title: "We've tried some things",
            subtitle: "Real experiences — good, bad, or somewhere in between",
            detail: "We'll help you process what happened and decide what comes next."
        ),
        ContextOption(
            id: "needs_reset", context: .needsReset, intensity: .nova,
            title: "We need a reset",
            subtitle: "Something's off and we want to find our footing again",
            detail: "We'll focus on repair, reconnection, and rebuilding trust first."
        ),
    ]

    private var options: [ContextOption] {
        data.explorationMode == .couple ? coupleOptions : soloOptions
    }

    private var headlineText: String {
        let name = data.displayName.trimmingCharacters(in: .whitespaces)
        let hasName = !name.isEmpty
        if data.explorationMode == .couple {
            return hasName
                ? "\(name), you're exploring this together."
                : "You're exploring this together."
        } else {
            return hasName
                ? "\(name), you're exploring on your own."
                : "You're exploring on your own."
        }
    }

    private var subheadText: String {
        // NOTE: The solo subhead intentionally ends with an em dash.
        // The card stack below completes the implied sentence — each
        // card title is the answer to "one thing that helps us
        // personalize." This is a deliberate stylistic choice.
        // Change only after user testing confirms it reads as an error
        // rather than an intentional grammatical pause.
        data.explorationMode == .couple
            ? "Where are you two at?"
            : "One thing that helps us personalize —"
    }

    private var reassuranceText: String {
        data.explorationMode == .couple
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // FIXED: Extracted from body — inline AnyShapeStyle ternary with LinearGradient
    // inside .foregroundStyle() exceeded the preview type-checker's inference budget.
    private var reassuranceGradientStyle: AnyShapeStyle { // FIXED: extracted from body
        if isLight {
            // RULE B — magenta→gold for all display gradient text in light
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            // Dark path — byte-for-byte unchanged
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    private var headlineStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle)
            : AnyShapeStyle(AppColors.textPrimary)
    }

    private var subheadStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
            : AnyShapeStyle(AppColors.textSecondary)
    }

    private var pronounLabelStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightTextTertiary)
            : AnyShapeStyle(AppColors.textTertiary)
    }

    // MARK: - Accessibility

    // Provides a spoken summary of the current front card
    // for VoiceOver users who cannot see the visual stack.
    private var accessibilityStackLabel: String {
        guard let current = selection ?? options.first else {
            return "Relationship context selection. \(options.count) options available."
        }
        return "\(current.title). \(current.subtitle). \(current.detail)"
    }

    // Allows VoiceOver swipe-up / swipe-down to navigate the
    // card stack without requiring drag gestures.
    // Note: direction parameter type is inferred — AccessibilityAdjustableAction
    // is not available as a standalone named type in SwiftUI.

    // MARK: - Extracted Decoration Layers
    //
    // FIXED: Extracted from body modifier chain to reduce result-builder
    // expression depth, same pattern as OnboardingGroundRulesView.

    // LAYOUT-FIX: converted from var to func(size:) so the atmosphere ellipse
    // can receive proportional dimensions from the GeometryReader in body.
    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // Dark mode screen-specific accent — kept, not atmosphere
            if !isLight {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.3),
                            AppColors.deepBlue.opacity(0.15),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height)) // LAYOUT-FIX: was 600×500
                    .offset(y: -size.height * 0.09)                                       // LAYOUT-FIX: was -80
                    .blur(radius: 80)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in // LAYOUT-FIX: single GeometryReader for proportional spacing
        let h = geo.size.height
        VStack(spacing: 0) {

            OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: onBack)
                .padding(.top, OL.navTop(h))        // LAYOUT-FIX: was 12 hardcoded
                .padding(.bottom, OL.navBottom(h))  // LAYOUT-FIX: was 20 hardcoded
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            VStack(alignment: .leading, spacing: OL.compact(h)) { // LAYOUT-FIX: was 8 hardcoded
                Text(headlineText)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(headlineStyle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subheadText)
                    .font(AppFonts.caption)
                    .foregroundStyle(subheadStyle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            ContextCardStack(
                selection: $selection,
                options: options,
                onAdvance: handleAdvance
            )
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityStackLabel)
            .accessibilityHint("Swipe left or right to browse options. Double-tap to select the current card.")
            .accessibilityValue(selection?.title ?? "No selection")
            .accessibilityAdjustableAction { direction in
                let currentIndex = options.firstIndex(where: {
                    $0.id == (selection ?? options.first)?.id
                }) ?? 0
                let newIndex: Int
                switch direction {
                case .increment:
                    newIndex = min(currentIndex + 1, options.count - 1)
                case .decrement:
                    newIndex = max(currentIndex - 1, 0)
                @unknown default:
                    return
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selection = options[newIndex]
                }
            }
            .accessibilityAction(named: "Select") {
                handleAdvance()
            }

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(reassuranceGradientStyle) // FIXED: uses pre-resolved property
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(reassuranceVisible ? 1 : 0)
                .offset(y: reassuranceVisible ? 0 : 8)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(reassuranceText)

            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
                .padding(.horizontal, 24)
                .accessibilityHidden(true)
        }
        .background { backgroundLayer(size: geo.size) } // LAYOUT-FIX: passes live size for proportional atmosphere
        // RULE D — .preferredColorScheme(.dark) removed;
        // screen now responds to system appearance.
        // BrandView and BuildingPathView remain permanently dark.
        .onAppear {
            #if DEBUG
            assert(
                data.explorationMode == .solo || data.explorationMode == .couple,
                "OnboardingContextView: received explorationMode " +
                "\(String(describing: data.explorationMode)) — " +
                "this screen should only be presented for .solo or .couple. " +
                "Browsing users must be routed to CuriosityPickerView."
            )
            #endif
            restoreSelectionIfNeeded()
            guard !hasAnimated else { return }
            hasAnimated = true
            runEntranceAnimations()
        }
        } // LAYOUT-FIX: end GeometryReader
    }

    // MARK: - Actions

    private func handleAdvance() {
        guard !autoAdvanceFired else { return }
        guard let confirmedContext = selection?.context else {
            // selection is nil — ContextCardStack fired onAdvance
            // before a card was confirmed. Do not advance.
            // This should never happen in production.
            assertionFailure(
                "OnboardingContextView: handleAdvance() called " +
                "with nil selection — ContextCardStack contract violated."
            )
            return
        }
        autoAdvanceFired = true
        data.relationshipContext = confirmedContext
        #if DEBUG
        assert(onContinue != nil,
            "OnboardingContextView: onContinue not injected — " +
            "wire this callback from the coordinator.")
        #endif
        onContinue?()
    }

    // MARK: - State Restoration

    private func restoreSelectionIfNeeded() {
        // Restore confirmed selection from the binding on back navigation.
        // Only restores if data has a committed value — safe on first appear
        // (data.relationshipContext will be nil, no-op).
        guard let context = data.relationshipContext else { return }
        if selection?.context != context {
            selection = options.first(where: { $0.context == context })
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible      = true
            cardsVisible       = true
            reassuranceVisible = true
            return
        }
        #endif
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible       = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { reassuranceVisible = true }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

// MARK: - Changes applied
// ISSUE 1:  ContextCardStack — added .accessibilityElement,
//           .accessibilityLabel (accessibilityStackLabel computed
//           property), .accessibilityHint, .accessibilityValue,
//           .accessibilityAdjustableAction (accessibilityNavigate),
//           and .accessibilityAction("Select"); VoiceOver users
//           can now navigate and confirm cards without gestures
// ISSUE 2:  Added @State hasAnimated guard; added
//           restoreSelectionIfNeeded() call before guard in
//           onAppear; prevents re-animation on back navigation
// ISSUE 3:  Added restoreSelectionIfNeeded() — restores selection
//           from data.relationshipContext on every appear;
//           card stack shows confirmed state on back navigation
// ISSUE 4:  handleAdvance() — added guard let confirmedContext
//           defensive nil check with assertionFailure for
//           ContextCardStack contract violation
// ISSUE 5:  Added #if DEBUG assert in onAppear verifying
//           explorationMode is .solo or .couple; guards against
//           browsing users being routed here incorrectly
// ISSUE 6:  headlineText — updated to prepend data.displayName
//           when non-empty; falls back to original copy when
//           displayName is empty; first use of name in the flow
// ISSUE 7:  handleAdvance() — added #if DEBUG assert for missing
//           onContinue callback, mirroring Screens 1–3 pattern
// ISSUE 8:  Reassurance Text — added .accessibilityAddTraits +
//           .accessibilityLabel; OnboardingFooter marked
//           .accessibilityHidden(true) to reduce VoiceOver noise
// ISSUE 9:  Added explanatory comment on subheadText documenting
//           the intentional em dash; copy unchanged
// ISSUE 10: Added two new #Preview variants: "Solo — with name"
//           and "Couple — with name" to verify ISSUE 6 behavior
// ISSUE 11: Light mode pass — removed .preferredColorScheme(.dark);
//           added @Environment(\.colorScheme); branched background
//           to lightPageBg + AuroraGlowField + SparkField(.contextView)
//           in light; headlineText → lightTextPrimary in light;
//           subheadText → lightTextSecondary in light; reassurance
//           gradient → magenta→gold in light (dark path unchanged);
//           added 4 light preview variants alongside existing 4 dark
// ISSUE 12: Preview fix — extracted `let isLight` from body to
//           `private var isLight: Bool`; extracted background ZStack
//           to `backgroundLayer` property; extracted reassurance
//           gradient to `reassuranceGradientStyle` property.
//           Root cause: 6+ closure captures of `let isLight` inside
//           @ViewBuilder body exceeded preview type-checker budget.
// ISSUE 13: Revert NavArrow integration in OnboardingContextView:
//           restore top bar onBack, remove NavArrow block from bottom
// ISSUE 14: Added headlineStyle, subheadStyle, and pronounLabelStyle
//           as extracted computed properties below reassuranceGradientStyle

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
        let seamGap: CGFloat = -75  // was 60
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

                    // Title crossfade with GlowUnderline accents
                    ZStack(alignment: .topLeading) {
                        Text(config.section1Label)
                            .font(AppFonts.display(22, weight: .semibold))
                            .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                            .modifier(GlowUnderline(isLight: isLight))
                            .opacity(1 - atmosphereProgress)
                            .offset(x: atmosphereProgress * -12)

                        Text(config.section2Label)
                            .font(AppFonts.display(22, weight: .semibold))
                            .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                            .modifier(GlowUnderline(isLight: isLight))
                            .opacity(atmosphereProgress)
                            .offset(x: (1 - atmosphereProgress) * 12)
                    }
                    .frame(height: 32)
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

    // MARK: - Subtitle label

    @ViewBuilder
    private func liveLabelSubtitle(_ text: String, opacity: CGFloat) -> some View {
        Text(text)
            .font(AppFonts.body(14, weight: .regular))
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

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift` {#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift}

```swift
// Features/Onboarding/Views/OnboardingBuildingPathView.swift
//
// REVISION 3 — fixes persistent rightward layout offset.
//
// ROOT CAUSE (correct diagnosis):
//
// Revisions 1 and 2 correctly identified that .ignoresSafeArea() children
// were involved, but applied the wrong fix (.frame on the ZStack). The
// actual mechanism: when multiple children inside a ZStack use
// .ignoresSafeArea(), the ZStack computes its internal alignment origin
// from the UNION of all children's frames — including safe-area-extended
// frames. This shifts the alignment center rightward (and/or downward),
// dragging all content with it. .frame(width:height:) on the ZStack only
// constrains its external reported size; it does NOT override the internal
// alignment computation.
//
// FIX:
//
// All .ignoresSafeArea() layers (pageBg, atmosphere, OnboardingGlowField,
// fade overlay) are moved OUT of the ZStack into .background() and
// .overlay() modifiers. These modifiers render content behind/above the
// ZStack respectively but do NOT participate in the ZStack's alignment
// computation. The ZStack now contains ONLY non-ignoresSafeArea children
// (fragmentLayer, mainContent, skipAffordance, accessibility overlay),
// so its alignment origin is the true center of its frame.
//
// fragmentLayer()'s .ignoresSafeArea() is also removed — it was
// unnecessary since the parent ZStack already covers the full screen
// via the outer GeometryReader's .ignoresSafeArea().
//
// All BUG-1 through BUG-7 and R-BUG-1 through R-BUG-3 fixes from
// prior revisions are preserved where still applicable.

import SwiftUI

// MARK: - Supporting Types

private enum BPIndicatorState: Equatable {
case pending
case processing
case complete
}

private struct BPBuildItem {
let category: String
let resolved: String
}

private struct BPFragmentState {
var visible: Bool = false
var fading:  Bool = false
}

// MARK: - Main View

struct OnboardingBuildingPathView: View {
@Binding var data: OnboardingData
var onFinished: (() -> Void)? = nil



@Environment(\.colorScheme) private var colorScheme

@State private var screenW: CGFloat = 393
@State private var screenH: CGFloat = 852

@State private var hasAnimated = false
@State private var atmosphericVisible = false
@State private var glowPeak           = false
@State private var overlabelVisible   = false
@State private var nameVisible        = false
@State private var taglineVisible     = false

@State private var indicatorStates: [BPIndicatorState] = [
    .pending, .pending, .pending, .pending
]
@State private var fragmentStates: [BPFragmentState] = [
    BPFragmentState(), BPFragmentState(), BPFragmentState()
]

@State private var itemsFadingOut   = false
@State private var fadeOutVisible   = false
@State private var autoAdvanceFired = false
@State private var skipAvailable    = false
@State private var skipVisible      = false

private var reduceMotion: Bool {
    UIAccessibility.isReduceMotionEnabled
}

/// Physical top safe-area inset (Dynamic Island / notch / status bar)
/// read directly from the UIKit key window.
///
/// geo.safeAreaInsets.top returns 0 in this view because the outer
/// GeometryReader uses .ignoresSafeArea() — which zeroes the proxy's
/// inset values. The UIKit window always reports the true physical
/// insets regardless of SwiftUI's modifier chain.
private var deviceTopInset: CGFloat {
    guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
                as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow })
    else { return 0 }
    return window.safeAreaInsets.top
}

// MARK: - Computed: Build Items

private var resolvedBuildItems: [BPBuildItem] {
    [        BPBuildItem(category: "Starting point",     resolved: stageLabel),        BPBuildItem(category: "Your situation",     resolved: contextLabel),        BPBuildItem(category: "First to explore",   resolved: goalsLabel),        BPBuildItem(category: "How you'll explore", resolved: modeLabel),    ]
}

private var stageLabel: String {
    switch data.nmStage {
    case .curious:     return "Beginning from curiosity"
    case .exploring:   return "Building on what you've tried"
    case .experienced: return "Starting from experience"
    default:           return "Your starting point"
    }
}

private var contextLabel: String {
    switch data.relationshipContext {
    case .partneredOpen:   return "Navigating openness together"
    case .partneredHidden: return "Finding words for the unspoken"
    case .notTalked:       return "Opening the conversation"
    case .talking:         return "Growing shared curiosity"
    case .single:          return "Your journey, your pace"
    case .someExperience:  return "Processing what's happened"
    case .needsReset:      return "Rebuilding from here"
    default:               return "Your situation"
    }
}

private var goalsLabel: String {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return "What you want to explore" }
    return s.count > 32 ? String(s.prefix(32)) + "…" : s
}

private var modeLabel: String {
    switch data.explorationMode {
    case .solo:   return "At your own pace"
    case .couple: return "Together, step by step"
    default:      return "Your conversation style"
    }
}

// MARK: - Computed: Fragments

private var stageFragment: String {
    switch data.nmStage {
    case .curious:     return "Starting fresh"
    case .exploring:   return "Building on what you know"
    case .experienced: return "Going deeper"
    default:           return "Starting fresh"
    }
}

private var contextFragment: String? {
    switch data.relationshipContext {
    case .single:          return "Your journey"
    case .partneredOpen:   return "With transparency"
    case .partneredHidden: return "Finding the words"
    case .notTalked:       return "Starting together"
    case .talking:         return "Shared curiosity"
    case .someExperience:  return "Processing this"
    case .needsReset:      return "Rebuilding"
    default:               return nil
    }
}

// R-BUG-3 FIX: Fragment strings are kept short (≤20 chars) so they
// never exceed their capped frame width and bleed off-screen.

private var selectionFragment: String? {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return nil }
    // Cap at 20 chars for fragment display — full string is in the list row
    return s.count > 20 ? String(s.prefix(20)) + "…" : s
}

// MARK: - Computed: Personalization

private var trimmedName: String {
    data.displayName.trimmingCharacters(in: .whitespaces)
}

private var hasPersonalName: Bool { !trimmedName.isEmpty }

private var exitLine: String {
    hasPersonalName
        ? "\(trimmedName), here's your first step."
        : "Here's where you begin."
}

// MARK: - Accessibility

private var accessibilitySummary: String {
    let items = resolvedBuildItems
    let owner = hasPersonalName ? "\(trimmedName)'s" : "your"
    return "Building \(owner) path. " +
           "Assembling \(items[0].resolved), " +
           "\(items[1].resolved), " +
           "\(items[2].resolved), " +
           "and \(items[3].resolved). " +
           exitLine
}

// MARK: - Helpers

private func cacheSize(_ size: CGSize) {
    guard screenW != size.width || screenH != size.height else { return }
    DispatchQueue.main.async {
        screenW = size.width
        screenH = size.height
    }
}

private func schedule(_ seconds: Double, _ action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
}

private func deriveDefaultDifficulty() {
    switch data.nmStage {
    case .curious:     data.defaultDifficulty = "warm"
    case .exploring:   data.defaultDifficulty = "medium"
    case .experienced: data.defaultDifficulty = "hot"
    default:           data.defaultDifficulty = "warm"
    }
}

private func completeAndAdvance() {
    guard !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    #if DEBUG
    assert(
        onFinished != nil,
        "OnboardingBuildingPathView: onFinished not injected."
    )
    #endif
    onFinished?()
}

// MARK: - Body

var body: some View {
    GeometryReader { geo in
        let _ = cacheSize(geo.size)
        // geo.safeAreaInsets.top is ZERO here because
        // .ignoresSafeArea() on the GeometryReader zeroes the
        // proxy's inset values. Read the real physical inset
        // from the UIKit key window instead.
        let topInset = deviceTopInset

        ZStack {
            // ── Floating fragments ───────────────────────────
            fragmentLayer(topInset: topInset)

            // ── Main content ─────────────────────────────────
            mainContent(topInset: topInset)

            // ── Skip affordance ──────────────────────────────
            skipAffordance()

            // ── VoiceOver overlay ────────────────────────────
            Text(accessibilitySummary)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(width: geo.size.width, height: geo.size.height)
        // LAYOUT FIX: Atmospheric layers (.ignoresSafeArea()) are
        // moved to .background() so they cannot distort the ZStack's
        // internal alignment origin. When .ignoresSafeArea() children
        // sit inside a ZStack, the ZStack computes its alignment
        // center from the union of all children's frames — including
        // safe-area-extended frames — which shifts the origin
        // rightward and drags all content with it.
        .background(
            ZStack {
                // Dark: near-black | Light: warm cream
                (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                atmosphere()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                OnboardingGlowField()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        )
        // LAYOUT FIX: Fade overlay also isolated via .overlay()
        // for the same reason — its .ignoresSafeArea() must not
        // participate in ZStack alignment.
        .overlay(
            (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                .opacity(fadeOutVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: fadeOutVisible)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        )
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { handleSkip() }
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
    .onAppear {
        guard !hasAnimated else { return }
        hasAnimated = true
        startAnimation()
    }
}

// MARK: - Skip

private func handleSkip() {
    guard skipAvailable, !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    withAnimation(.easeIn(duration: 0.25)) { fadeOutVisible = true }
    schedule(0.30) { onFinished?() }
}

@ViewBuilder
private func skipAffordance() -> some View {
    VStack {
        Spacer()
        HStack {
            Spacer()
            if skipVisible {
                Text("Continue →")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.textTertiary
                        : AppColors.lightTextTertiary)
                    .opacity(0.55)
                    .padding(.trailing, 28)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .accessibilityLabel("Skip loading and continue")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
    .animation(.easeIn(duration: 0.4), value: skipVisible)
    .allowsHitTesting(skipAvailable)
}

// MARK: - Fragment Layer
//
// topInset: the physical top safe-area inset from UIKit's key window.
//
// The inner GeometryReader does NOT use .ignoresSafeArea() (removed
// in Rev 3 to fix the layout origin). Its geo.size.height is the
// safe-area-inset region — shorter than the physical screen by topInset.
//
// fullH = geo.size.height + topInset reconstructs the physical screen
// height from live geometry on every frame (unlike the @State screenH
// which may hold its initial value of 852 on the first render frame).
// midY is computed in inset-region coordinates, then each position
// adds topInset back for the correct physical screen position.

@ViewBuilder
private func fragmentLayer(topInset: CGFloat) -> some View {
    GeometryReader { geo in
        // fullH reconstructs the physical screen height from live geometry.
        // geo.size.height excludes topInset (no .ignoresSafeArea here).
        // screenH is cached and may hold its initial value of 852 on the
        // first render frame — using it caused fragments to jump position.
        // geo.size.height + topInset is always accurate on every frame.
        let fullH        = geo.size.height + topInset
        let midX         = geo.size.width / 2
        // midY in inset-region coordinates:
        //   physical center = fullH / 2
        //   inset-region y  = physical y − topInset
        let midY         = (fullH / 2) - topInset
        let fragmentMaxW = geo.size.width / 2 - 24

        ZStack {
            // Fragment 0 — stage — upper left of center
            BPFloatingFragment(
                text:          stageFragment,
                targetOpacity: 0.60,
                isVisible:     fragmentStates[0].visible,
                isFading:      fragmentStates[0].fading
            )
            .frame(maxWidth: fragmentMaxW)
            .position(
                x: midX - screenW * 0.22,
                y: midY - fullH * 0.28 + topInset
            )

            // Fragment 1 — context — upper right of center
            if let f1 = contextFragment {
                BPFloatingFragment(
                    text:          f1,
                    targetOpacity: 0.55,
                    isVisible:     fragmentStates[1].visible,
                    isFading:      fragmentStates[1].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX + screenW * 0.22,
                    y: midY - fullH * 0.32 + topInset
                )
            }

            // Fragment 2 — selection — centered above name
            if let f2 = selectionFragment {
                BPFloatingFragment(
                    text:          f2,
                    targetOpacity: 0.50,
                    isVisible:     fragmentStates[2].visible,
                    isFading:      fragmentStates[2].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX,
                    y: midY - fullH * 0.38 + topInset
                )
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
}

// MARK: - Main Content
//
// topInset: the physical top safe-area inset (Dynamic Island / notch /
// status bar height) read from UIKit's key window.
//
// WHY geo.safeAreaInsets.top DOES NOT WORK HERE:
//
// The outer GeometryReader uses .ignoresSafeArea(). When a view opts
// out of safe areas, SwiftUI zeroes the GeometryProxy's safeAreaInsets
// — the proxy reports 0 for all edges because the view has declared it
// doesn't care about safe areas. Every prior attempt that captured
// geo.safeAreaInsets.top was capturing 0, producing padding equal to
// just OL.progressTop (~24pt) — well within the ~59pt Dynamic Island.
//
// The fix: deviceTopInset reads UIApplication → UIWindowScene →
// UIWindow.safeAreaInsets.top, which always reports the real physical
// inset regardless of SwiftUI's modifier chain. This value is passed
// as topInset to mainContent and fragmentLayer.

@ViewBuilder
private func mainContent(topInset: CGFloat) -> some View {
    let completeCount = indicatorStates.filter { $0 == .complete }.count

    VStack(alignment: .center, spacing: 0) {

        // Progress bar
        //
        // .padding(.top) = topInset (Dynamic Island / notch clearance,
        //                   from UIKit key window — NOT geo.safeAreaInsets)
        //                 + OL.progressTop (design spacing below island).
        OnboardingProgressBar(
            currentStep:          completeCount,
            totalSteps:           5
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, topInset + OL.progressTop(screenH))
        .padding(.bottom, OL.progressBottom(screenH))
        .accessibilityHidden(true)

        Spacer()

        // Overline — BUG-3 FIX retained
        Text("BUILDING YOUR PATH")
            .font(AppFonts.overline)
            .foregroundStyle(colorScheme == .dark
                ? LinearGradient(
                    colors: [AppColors.purple, AppColors.magenta],
                    startPoint: .leading, endPoint: .trailing)
                : LinearGradient(stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.pink,    location: 0.45),
                    .init(color: AppColors.gold,    location: 1.00),
                  ],
                  startPoint: .leading, endPoint: .trailing))
            .tracking(2.5)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(overlabelVisible ? 1 : 0)
            .offset(y: overlabelVisible ? 0 : 8)
            .animation(.easeOut(duration: 1.0), value: overlabelVisible)
            .padding(.bottom, 10)
            .accessibilityHidden(true)

        // Name headline — BUG-1 downstream fix retained
        nameHeadline
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(nameVisible ? 1 : 0)
            .offset(y: nameVisible ? 0 : 14)
            .animation(.easeOut(duration: 1.2), value: nameVisible)
            .padding(.bottom, OL.loose(screenH))
            .accessibilityHidden(true)

        // Build item list — BUG-1 FIX retained: no .fixedSize(horizontal:)
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(resolvedBuildItems.enumerated()), id: \.offset) { i, item in
                BPBuildItemRow(
                    item:           item,
                    indicatorState: indicatorStates[i],
                    isVisible:      indicatorStates[i] != .pending && !itemsFadingOut,
                    isComplete:     indicatorStates[i] == .complete && !itemsFadingOut
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)

        // Exit tagline — BUG-5 FIX retained
        Text(exitLine)
            .font(AppFonts.body(18, weight: .medium))
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(taglineVisible ? 1 : 0)
            .offset(y: taglineVisible ? 0 : 10)
            .animation(.easeOut(duration: 1.2), value: taglineVisible)
            .padding(.top, OL.loose(screenH))
            .accessibilityHidden(true)

        // BUG-7 FIX retained
        Spacer(minLength: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // BUG-6 FIX retained: single source of horizontal inset.
    .padding(.horizontal, 36)
    // BUG-7 FIX retained: home indicator clearance
    .padding(.bottom, 34)
}

// MARK: - Name Headline

@ViewBuilder
private var nameHeadline: some View {
    if hasPersonalName {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(trimmedName)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.lightCardTitle)
            Text(".")
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.spectrumBorder
                    : AppColors.warmAuroraBorder)
        }
        .font(AppFonts.heroTitle)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    } else {
        Text("Your path.")
            .font(AppFonts.heroTitle)
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

// MARK: - Atmospheric Layer
// Unchanged — atmosphere() renders correctly once the ZStack frame
// is pinned (R-BUG-1 fix). Orb offsets are screen-relative and correct.

// Dark:  cool spectrum — purple / cyan / magenta orbs
// Light: warm aurora  — purple / gold / magenta orbs (no cyan)
private var atmosAccent: Color {
    colorScheme == .dark ? AppColors.cyan : AppColors.gold
}

private func atmosphere() -> some View {
    ZStack {
        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.40),
                         atmosAccent.opacity(0.20),
                         Color.clear],
                center: .top, startRadius: 30, endRadius: 380))
            .frame(width: OL.atmosW(screenW), height: OL.atmosH(screenH))
            .offset(y: -screenH * 0.42)
            .blur(radius: 90)
            .opacity(atmosphericVisible ? 1 : 0)
            .animation(.easeInOut(duration: 2.0), value: atmosphericVisible)

        Ellipse()
            .fill(atmosAccent.opacity(0.12))
            .frame(width: 180, height: 180)
            .blur(radius: 55)
            .offset(x: -screenW * 0.32, y: -screenH * 0.22)
            .opacity(glowPeak ? 0.90 : 0.40)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.10))
            .frame(width: 140, height: 140)
            .blur(radius: 50)
            .offset(x: screenW * 0.32, y: -screenH * 0.26)
            .opacity(glowPeak ? 0.85 : 0.28)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.purple.opacity(0.14))
            .frame(width: 240, height: 240)
            .blur(radius: 80)
            .opacity(glowPeak ? 1.00 : 0.45)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(atmosAccent.opacity(0.08))
            .frame(width: 110, height: 110)
            .blur(radius: 42)
            .offset(x: -screenW * 0.38, y: screenH * 0.22)
            .opacity(glowPeak ? 0.75 : 0.18)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.08))
            .frame(width: 150, height: 150)
            .blur(radius: 60)
            .offset(x: screenW * 0.38, y: screenH * 0.18)
            .opacity(glowPeak ? 0.85 : 0.22)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.18),
                         atmosAccent.opacity(0.10),
                         Color.clear],
                center: .center, startRadius: 0, endRadius: 200))
            .frame(width: 400, height: 400)
            .blur(radius: 70)
            .scaleEffect(glowPeak ? 1.0 : 0.36)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Rectangle()
            .fill(LinearGradient(
                colors: [AppColors.purple.opacity(0.10), Color.clear],
                startPoint: .bottom, endPoint: .top))
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)
    }
    .drawingGroup()
}

    // MARK: - Animation (startFullAnimation replacement)
    //
    // BUG-1 FIX: the #if DEBUG / XCODE_RUNNING_FOR_PREVIEWS block
    // previously hard-jumped to indicatorStates = [.complete × 4] and
    // returned early. This meant BPOrbitCanvas was NEVER mounted in any
    // preview — the .processing state was skipped entirely, so the comet
    // orbit was invisible.
    //
    // BUG-2 FIX (downstream): BPBuildItemRow.isVisible is computed as
    // indicatorStates[i] != .pending. When the DEBUG block set states to
    // .complete before the animation sequence ran, the rows started
    // invisible (opacity 0) and stayed there because no animation ever
    // fired to transition them in.
    //
    // FIX: the preview path now runs a real but fast (0.4× speed) animation
    // sequence using the same schedule() calls as the device path. This
    // ensures every state — pending → processing → complete — is visited,
    // all rows animate in, and the comet orbit is visible.
    //
    // The instanceID UUID toggle in the preview re-creates the view from
    // scratch on each Reset tap, which resets hasAnimated = false and
    // replays the sequence.
    
    private func startAnimation() {
        if reduceMotion { startReducedMotionAnimation(); return }
        schedule(0.15) { startFullAnimation() }
    }
    
    private func startReducedMotionAnimation() {
        overlabelVisible = true
        nameVisible      = true
        indicatorStates  = [.complete, .complete, .complete, .complete]
        taglineVisible   = true
        schedule(2.00) { completeAndAdvance() }
    }

    private func startFullAnimation() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview-fast path: same sequence as below but at 0.4× wall-clock
            // time so the full pending → processing → complete flow is visible
            // without waiting 4+ seconds per canvas reload.
            //
            // Multiplier 0.4 maps the real-device schedule (0s–4.6s) into
            // approximately 0s–1.85s in the preview canvas.
            let k = 0.4
            schedule(0.00 * k) {
                withAnimation(.easeInOut(duration: 1.6 * k)) { atmosphericVisible = true }
            }
            schedule(0.00 * k) {
                withAnimation(.easeOut(duration: 0.8 * k)) { overlabelVisible = true }
            }
            schedule(0.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[0].visible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { nameVisible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[0] = .processing }
            }
            schedule(0.70 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[1] = .processing }
            }
            schedule(1.00 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[2] = .processing }
            }
            schedule(1.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[1].visible = true }
            }
            schedule(1.30 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[3] = .processing }
            }
            schedule(1.50 * k) { skipAvailable = true }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.4 * k)) { skipVisible = true }
            }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[0].fading = true }
            }
            schedule(1.90 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[0] = .complete }
            }
            schedule(2.00 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[2].visible = true }
            }
            schedule(2.20 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[1] = .complete }
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[1].fading = true }
            }
            schedule(2.50 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[2] = .complete }
            }
            schedule(2.80 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[3] = .complete }
                withAnimation(.easeInOut(duration: 1.4 * k)) { glowPeak = true }
            }
            schedule(2.90 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[2].fading = true }
            }
            schedule(3.20 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { taglineVisible = true }
            }
            // Do NOT auto-advance in preview — leave the final state on screen.
            return
        }
        #endif

        // ── Real-device timing (unchanged) ───────────────────────────────
        schedule(0.00) {
            withAnimation(.easeInOut(duration: 1.6)) { atmosphericVisible = true }
        }
        schedule(0.00) {
            withAnimation(.easeOut(duration: 0.8)) { overlabelVisible = true }
        }
        schedule(0.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[0].visible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.9)) { nameVisible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[0] = .processing }
        }
        schedule(0.70) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[1] = .processing }
        }
        schedule(1.00) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[2] = .processing }
        }
        schedule(1.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[1].visible = true }
        }
        schedule(1.30) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[3] = .processing }
        }
        schedule(1.50) { skipAvailable = true }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.4)) { skipVisible = true }
        }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[0].fading = true }
        }
        schedule(1.90) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[0] = .complete }
        }
        schedule(2.00) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[2].visible = true }
        }
        schedule(2.20) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[1] = .complete }
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[1].fading = true }
        }
        schedule(2.50) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[2] = .complete }
        }
        schedule(2.80) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[3] = .complete }
            withAnimation(.easeInOut(duration: 1.4)) { glowPeak = true }
        }
        schedule(2.90) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[2].fading = true }
        }
        schedule(3.20) {
            withAnimation(.easeOut(duration: 0.9)) { taglineVisible = true }
        }
        schedule(3.80) {
            withAnimation(.easeIn(duration: 0.4)) {
                overlabelVisible = false
                nameVisible      = false
                itemsFadingOut   = true
            }
        }
        schedule(3.90) {
            withAnimation(.easeIn(duration: 0.4)) { taglineVisible = false }
        }
        schedule(4.20) {
            withAnimation(.easeIn(duration: 0.3)) { fadeOutVisible = true }
        }
    schedule(4.60) { completeAndAdvance() }
}
}

// MARK: - BPBuildItemRow
// BUG-4 + BUG-6 fixes retained: .frame(maxWidth: .infinity) on both
// the label VStack and the outer HStack. lineLimit + truncationMode on
// both Text nodes. fixedSize(horizontal: false, vertical: true) on
// the resolved text for graceful two-line wrap.

private struct BPBuildItemRow: View {
let item:           BPBuildItem
let indicatorState: BPIndicatorState
let isVisible:      Bool
let isComplete:     Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    HStack(spacing: 14) {
        // Fixed-size indicator — never grows
        BPOrbitIndicator(state: indicatorState)
            .fixedSize()

        VStack(alignment: .leading, spacing: 2) {
            Text(item.category.uppercased())
                .font(AppFonts.overline)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textTertiary
                    : AppColors.lightCardTitle.opacity(0.40))
                .tracking(1.5)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(item.resolved)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(isComplete
                    ? (colorScheme == .dark ? AppColors.textPrimary : AppColors.lightCardTitle)
                    : (colorScheme == .dark ? AppColors.textSecondary : AppColors.lightCardTitle.opacity(0.55)))
                .animation(.easeOut(duration: 0.7), value: isComplete)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Fill remaining width after the indicator + spacing
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    // Fill the padded column width
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 10)
    .animation(.easeOut(duration: 0.8), value: isVisible)
}
}

// MARK: - BPOrbitIndicator (unchanged)

private struct BPOrbitIndicator: View {
let state: BPIndicatorState
private let size: CGFloat = 22



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    ZStack {
        Circle()
            .strokeBorder(
                colorScheme == .dark ? AppColors.border : AppColors.lightBorder,
                lineWidth: 1.5)
            .opacity(state == .pending ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: state == .pending)

        if state == .processing {
            BPOrbitCanvas(size: size, colorScheme: colorScheme)
                .transition(.opacity)
        }

        Circle()
            .fill(LinearGradient(
                colors: colorScheme == .dark
                    ? [AppColors.cyan, AppColors.purple, AppColors.magenta]
                    : [AppColors.purple, AppColors.magenta, AppColors.gold],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .opacity(state == .complete ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: state == .complete)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowCyan : AppColors.lightShadowPurple,
                radius: colorScheme == .dark ? 12 : 7)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowMagenta : AppColors.lightShadowMagenta,
                radius: colorScheme == .dark ? 24 : 14)
    }
    .frame(width: size, height: size)
}
}

// MARK: - BPOrbitCanvas (unchanged)

private struct BPOrbitCanvas: View {
let size: CGFloat
let colorScheme: ColorScheme
private let revolutionDuration: TimeInterval = 1.4



// RGB triples resolved from AppColors tokens per colorScheme.
// Dark:  cyan → purple → magenta
// Light: purple → magenta → gold
private var primaryRGB:   (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.cyan : AppColors.purple)
}
private var secondaryRGB: (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.purple : AppColors.magenta)
}
private var tertiaryRGB:  (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.magenta : AppColors.gold)
}

var body: some View {
    let pRGB = primaryRGB
    let sRGB = secondaryRGB
    let tRGB = tertiaryRGB
    let borderColor: Color = colorScheme == .dark
        ? AppColors.borderHover
        : AppColors.lightBorderHover
    let sparkOuter = AppColors.magenta
    let sparkInner: Color = colorScheme == .dark ? AppColors.cyan : AppColors.purple

    TimelineView(.animation) { timeline in
        Canvas { context, canvasSize in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: revolutionDuration)
            let progress = elapsed / revolutionDuration
            drawOrbit(
                context: context, size: canvasSize, progress: progress,
                pRGB: pRGB, sRGB: sRGB, tRGB: tRGB,
                sparkOuter: sparkOuter, sparkInner: sparkInner,
                borderColor: borderColor
            )
        }
        .frame(width: size, height: size)
    }
}

private func drawOrbit(
    context:     GraphicsContext,
    size:        CGSize,
    progress:    Double,
    pRGB:        (r: Double, g: Double, b: Double),
    sRGB:        (r: Double, g: Double, b: Double),
    tRGB:        (r: Double, g: Double, b: Double),
    sparkOuter:  Color,
    sparkInner:  Color,
    borderColor: Color
) {
    let cx     = size.width  / 2
    let cy     = size.height / 2
    let radius = size.width  / 2 - 2.0
    let steps  = 28

    let headAngle = progress * .pi * 2 - .pi / 2
    let tailArc   = Double.pi * 0.88

    var borderPath = Path()
    borderPath.addEllipse(in: CGRect(
        x: cx - radius, y: cy - radius,
        width: radius * 2, height: radius * 2))
    context.stroke(
        borderPath,
        with: .color(borderColor),
        lineWidth: 1.5)

    for i in 0..<steps {
        let t         = Double(i) / Double(steps - 1)
        let dotAngle  = headAngle - tailArc * (1.0 - t)
        let x         = cx + cos(dotAngle) * radius
        let y         = cy + sin(dotAngle) * radius
        let alpha     = t * 0.58
        let dotRadius = 0.9 + t * 0.65

        let color: Color
        if t < 0.4 {
            let blend = t / 0.4
            color = Color(
                red:   lerp(pRGB.r, sRGB.r, blend),
                green: lerp(pRGB.g, sRGB.g, blend),
                blue:  lerp(pRGB.b, sRGB.b, blend))
        } else {
            let blend = (t - 0.4) / 0.6
            color = Color(
                red:   lerp(sRGB.r, tRGB.r, blend),
                green: lerp(sRGB.g, tRGB.g, blend),
                blue:  lerp(sRGB.b, tRGB.b, blend))
        }

        var dotPath = Path()
        dotPath.addEllipse(in: CGRect(
            x: x - dotRadius, y: y - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2))
        context.fill(dotPath, with: .color(color.opacity(alpha)))
    }

    let hx = cx + cos(headAngle) * radius
    let hy = cy + sin(headAngle) * radius

    var outerPath = Path()
    outerPath.addEllipse(in: CGRect(
        x: hx - 5.5, y: hy - 5.5, width: 11, height: 11))
    context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

    var innerPath = Path()
    innerPath.addEllipse(in: CGRect(
        x: hx - 3, y: hy - 3, width: 6, height: 6))
    context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

    var corePath = Path()
    corePath.addEllipse(in: CGRect(
        x: hx - 1.8, y: hy - 1.8, width: 3.6, height: 3.6))
    context.fill(corePath, with: .color(.white.opacity(0.96)))
}

private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Double(r), Double(g), Double(b))
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}
}

// MARK: - BPFloatingFragment
// R-BUG-3 FIX: .fixedSize() removed from inside the component.
// Width is now controlled by the .frame(maxWidth: fragmentMaxW) applied
// by the caller in fragmentLayer(). Removing .fixedSize() here means the
// Text respects the width cap and wraps rather than overflowing right.
// .lineLimit(1) ensures it stays single-line and truncates cleanly.

private struct BPFloatingFragment: View {
let text:          String
let targetOpacity: Double
let isVisible:     Bool
let isFading:      Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    Text(text.uppercased())
        .font(AppFonts.overline)
        .foregroundStyle(colorScheme == .dark
            ? AppColors.textSecondary
            : AppColors.lightTextSecondary)
        .tracking(2.5)
        .multilineTextAlignment(.center)
        // R-BUG-3 FIX: .fixedSize() removed. Width is capped by caller.
        // .lineLimit(1) ensures single-line with clean truncation.
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(isVisible && !isFading ? targetOpacity : 0)
        .offset(y: isVisible && !isFading ? -4 : 0)
        .animation(.easeInOut(duration: 1.0), value: isVisible)
        .animation(.easeIn(duration: 0.8), value: isFading)
        .allowsHitTesting(false)
}
}

// MARK: - Previews
//
// Each preview uses a @Previewable UUID that is toggled by a Reset button.
// Changing the id re-creates the view from scratch — hasAnimated resets to
// false — so the full entrance animation replays on every canvas reset.

#Preview("Dark Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Jordan"
d.explorationMode     = .couple
d.nmStage             = .curious
d.relationshipContext = .notTalked
d.communicationGoals  = ["Talking about fantasies"]
return d
}()
// Changing this id destroys and recreates the view, restarting animation.
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.white)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.dark)
}

#Preview("Light Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Alex"
d.explorationMode     = .solo
d.nmStage             = .experienced
d.relationshipContext = .needsReset
d.communicationGoals  = ["Rebuilding intimacy"]
return d
}()
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.primary)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift` {#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift}

```swift
//Features/Onboarding/Views/OnboardingCardRevealView.swift
//
// Screen 7.5 — Card Reveal
//
// INTERACTION ARC
// ───────────────
//  t=0            Scene fades in. Card floats up spring(0.42, 0.78).
//                 AtmosphericGhostDeck drifts passively behind.
//  t=0.8s         Card breath begins — scale 1.000 ↔ 1.006, 3.0s sine.
//  t=tap          Flip fires. Ghost deck fades.
//                 3D flip: spring(0.58, 0.84), perspective 0.6.
//                 Front/back cross-fade over 12° window at 90°.
//  t=flip+~320ms  Back face visible. Heading enters, pills stagger up.
//  t=select       Three-beat post-selection sequence:
//                   Beat 1 (0ms):    Pill breathes — scale → 1.06.
//                   Beat 2 (+500ms): Border blooms — lineWidth → 3.0.
//                   Beat 3 (+900ms): Unselected pills sink and fade.
//  t=select+1.3s  Card exits upward, opacity 0, over 450ms.
//  t=select+1.65s Encouragement fades in from below.
//  t=select+1.83s Typewriter begins at 38 cps.
//                 Plain text in body color. Accent in static color.
//                 LivingText crossfades in once accent fully typed.
//                 Cursor blinks ×3 after last char, then fades.
//  t=typing+0.9s  Scene fades to pageBg over 500ms → onContinue().
//
// TRANSITION TO GROUNDRULES
// ──────────────────────────
//  This view owns its exit — sceneOpacity fades to 0, then onContinue()
//  fires. FlowView's spring transition cross-dissolves to GroundRulesView.
//  OnboardingAtmosphere persists in FlowView's ZStack, morphing from
//  .cardReveal to .groundRules config — no background flash.
//
// SKIP
// ────
//  "Continue when ready →" appears at 25s idle.
//  Stores data.nmCardResponse = nil and fades out.

import SwiftUI

// MARK: - Phase

private enum CardRevealPhase: Equatable {
   case idle
   case flipping
   case flipped
   case selected
   case encouragement
   case exiting
}

// MARK: - Main View

struct OnboardingCardRevealView: View {

   @Binding var data: OnboardingData
   var onContinue: (() -> Void)?

   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.accessibilityReduceMotion) private var reduceMotion
   private var isLight: Bool { colorScheme == .light }

   // ── Phase ─────────────────────────────────────────────────────────
   @State private var phase: CardRevealPhase = .idle
   @State private var selectedPill: CardRevealPill? = nil
   @State private var hasAdvanced = false

   // ── Entrance ───────────────────────────────────────────────────────
   @State private var hasAnimated       = false
   @State private var sceneOpacity:     Double  = 0
   @State private var cardOffsetY: CGFloat = 40
   @State private var cardEntryOpacity: Double  = 0

   // ── Float ────────────────────────────────────────────────────
   @State private var isFloating:  Bool    = false
   @State private var floatOffset: CGFloat = 0

   // ── Glow pulse ────────────────────────────────────────────────────
   @State private var glowOpacity: Double = 0.4
   @State private var hasBeenTapped: Bool = false

   // ── Ghost deck ────────────────────────────────────────────────────
   @State private var ghostOpacity: Double = 0

   // ── Flip ──────────────────────────────────────────────────────────
   @State private var flipDegrees:  Double = 180
   @State private var backRevealed: Bool   = false

   // ── Post-selection beat ────────────────────────────────────────────
   @State private var selectedPillScale:      CGFloat = 1.0
   @State private var selectedBorderWidth:    CGFloat = 2.0
   @State private var unselectedPillsVisible: Bool    = true

   // ── Card exit ─────────────────────────────────────────────────────
   @State private var cardExiting: Bool = false

   // ── Encouragement ─────────────────────────────────────────────────
   @State private var encouragementVisible: Bool = false
   @State private var typingComplete:       Bool = false

   // ── Arrow ─────────────────────────────────────────────────────────
   @State private var arrowTriggered: Bool = false
   @State private var sitWithThisVisible: Bool = false

   // ── Skip ──────────────────────────────────────────────────────────
   // Skip affordance removed

   @State private var fuseVisible:   Bool = false
   @State private var fuseCompleted: Bool = false
   @State private var flipHintActive:  Bool   = false
   @State private var flipHintDegrees: Double = 0
   @State private var fuseBurnProgress: Double = 0
   @State private var fuseBurnStartDate: Date? = nil

   @State private var questionVisible: Bool = false
   @State private var pillsVisible:    Bool = false

   // ── Scene exit ────────────────────────────────────────────────────
   @State private var exitingToNext: Bool = false

   // MARK: - Constants

    private let cardSize = CardLayout.size
   private let cardCornerRadius = CardLayout.cornerRadius
   private let fuseDuration:  TimeInterval = 15.0
   private let fuseDelay:     TimeInterval = 3.0
   private let fuseLineWidth: CGFloat      = 2.5

   // MARK: - Body

   var body: some View {
       ZStack {
           Color.clear.ignoresSafeArea()

           // Card stage and encouragement share the same region.
           // Card exits upward; encouragement rises from below.
           VStack {
               Spacer()   // greedy — pushes card DOWN
               ZStack {
                   cardStage

                   if encouragementVisible || typingComplete {
                       EncouragementView(
                           isLight:      isLight,
                           active:       encouragementVisible,
                           reduceMotion: reduceMotion,
                           onComplete:   handleTypingComplete
                       )
                       .transition(
                           .opacity.combined(with: .offset(y: 16))
                       )
                   }
               }
               .frame(width: cardSize.width, height: cardSize.height)

               Text("sit with this")
                   .font(AppFonts.body(16, weight: .regular))
                   .italic()
                   .foregroundStyle(Color.white)
                   .opacity(sitWithThisVisible && phase != .selected && phase != .encouragement && phase != .exiting ? 0.75 : 0)
                   .blur(radius: sitWithThisVisible ? 0 : 4)
                   .offset(y: sitWithThisVisible ? 0 : 6)
                   .padding(.top, 12)

               Color.clear.frame(height: 160)   // fixed — stops card going too low
           }
           .frame(maxWidth: .infinity)

       }
       .opacity(sceneOpacity)
       .animation(
           exitingToNext
               ? .easeIn(duration: 0.5)
               : .easeOut(duration: 0.45),
           value: exitingToNext
       )
       .accessibilityElement(children: .ignore)
       .accessibilityLabel(
           backRevealed
               ? "Something came up. What's it closest to? Choose from: \(CardRevealPill.allCases.map(\.rawValue).joined(separator: ", "))"
               : "What would you desire if nobody, not even you, would judge the answer? Tap to reflect."
       )
       .accessibilityAction(named: "Flip card") {
           if phase == .idle { handleCardTap() }
       }
       .accessibilityAction(named: "Skip") { handleSkip() }
       .onAppear {
           guard !hasAnimated else { return }
           hasAnimated = true
           startEntrance()
       }
       .onDisappear {
           // Skip affordance removed
       }
   }

   // MARK: - Card Stage

   private var cardStage: some View {
       TimelineView(.animation(paused: !fuseVisible || fuseCompleted)) { timeline in
           ZStack {
               // AtmosphericGhostDeck handles its own drift animation internally.
               // We only control its opacity (fades out on flip).
               AtmosphericGhostDeck(
                   cardSize:     cardSize,
                   cornerRadius: cardCornerRadius
               )
               .opacity(ghostOpacity)
               .animation(.easeOut(duration: 0.7), value: ghostOpacity)

               // Main card — entrance offset + float + exit transform
               ZStack {
                   flipContainer
               }
               .shadow(
                   color: phase == .idle && !hasBeenTapped
                       ? AppColors.cyan.opacity(glowOpacity * 0.55)
                       : .clear,
                   radius: 28
               )
               .shadow(
                   color: phase == .idle && !hasBeenTapped
                       ? AppColors.magenta.opacity(glowOpacity * 0.35)
                       : .clear,
                   radius: 40
               )
               .animation(.easeInOut(duration: 2.8), value: glowOpacity)
               .offset(y: cardExiting ? -36 : cardOffsetY + floatOffset)
               .opacity(cardExiting ? 0 : cardEntryOpacity)
               .animation(
                   cardExiting
                       ? .timingCurve(0.4, 0, 0.6, 1, duration: 0.45)
                       : .spring(response: 0.42, dampingFraction: 0.78),
                   value: cardExiting
               )
               .animation(.easeOut(duration: 0.45), value: cardEntryOpacity)
               .onTapGesture {
                   handleCardTap()
               }
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .onChange(of: timeline.date) { _, date in
               updateFuseProgress(at: date)
           }
       }
   }

   // MARK: - Flip Container

   private var flipContainer: some View {
       let _phase = phase

       return ZStack {

           // CardFrontView — question text, fuse, pills, tap target
           CardFrontView(
               cardSize:           cardSize,
               cornerRadius:       cardCornerRadius,
               isLight:            isLight,
               arrowTriggered:     arrowTriggered,
               sitWithThisVisible: sitWithThisVisible,
               onTap:              handleCardTap,
               fuseProgress:       fuseBurnProgress,
               questionVisible:    _phase == .flipped || _phase == .selected,
               pillsVisible:       pillsVisible,
               onPillSelected:     handlePillSelected
           )
           .opacity(frontFaceOpacity)
           .allowsHitTesting(true)

           // CuriosityCardBack — maze pattern, shown face-down
           // Visible during idle (arrival + float) phase only
           CuriosityCardBack(isActive: _phase == .idle)
               .opacity(idleBackFaceOpacity)
               .rotation3DEffect(
                   Angle.degrees(180),
                   axis: (x: 0, y: 1, z: 0)
               )
       }
       .rotation3DEffect(
           Angle.degrees(flipDegrees + flipHintDegrees),
           axis: (x: 0, y: 1, z: 0),
           perspective: 0.6
       )
   }

   // MARK: - Cross-fade opacity
   // Replaces binary < 90° threshold with a 12° overlap window.
   // Both faces are partially visible at 78°–90° where the card
   // is edge-on — the overlap is imperceptible at that angle.

   private var frontFaceOpacity: Double {
       Double(max(0, min(1, (90.0 - flipDegrees) / 12.0)))
   }

   private var backFaceOpacity: Double {
       Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
   }

   // idleBackFaceOpacity — maze back face
   // Full opacity when face-down, fades as card rotates
   // toward front during entrance flip
   private var idleBackFaceOpacity: Double {
       Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
   }

   // MARK: - Entrance

   private func startEntrance() {
       if reduceMotion {
           sceneOpacity     = 1
           cardOffsetY      = 0
           cardEntryOpacity = 1
           ghostOpacity     = 1
           arrowTriggered   = true
           return
       }

       // Scene fade
       withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
           sceneOpacity = 1
       }

       // Card rises slowly — user sees the back face
       withAnimation(.spring(response: 1.4, dampingFraction: 0.78).delay(0.3)) {
           cardOffsetY = 0
       }
       withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
           cardEntryOpacity = 1
       }

       // Float begins after card fully settles — user enjoys the back face
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
           startFloat()
           startGlowPulse()
       }

       // Float for 2 full cycles then auto-flip
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
           guard self.phase == .idle else { return }
           self.performAutoFlip()
       }
   }

   // MARK: - Float

   private func startFloat() {
       guard !reduceMotion else { return }
       isFloating = true
       tickFloat()
   }

   private func tickFloat() {
       guard isFloating, phase == .idle else {
           withAnimation(.easeOut(duration: 0.3)) { floatOffset = 0 }
           return
       }
       withAnimation(.easeInOut(duration: 3.0)) {
           floatOffset = floatOffset < -2 ? 0 : -4
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { tickFloat() }
   }

   private func stopFloat() {
       isFloating = false
       withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
           floatOffset = 0
       }
   }

   // MARK: - Glow Pulse

   private func startGlowPulse() {
       guard !reduceMotion else { return }
       tickGlowPulse()
   }

   private func tickGlowPulse() {
       guard phase == .idle, !hasBeenTapped else { return }
       withAnimation(.easeInOut(duration: 2.8)) {
           glowOpacity = glowOpacity < 0.7 ? 1.0 : 0.4
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
           tickGlowPulse()
       }
   }

   // MARK: - Auto-flip

   private func performAutoFlip() {
       guard phase == .idle else { return }
       phase = .flipping
       stopFloat()
       UIImpactFeedbackGenerator(style: .light).impactOccurred()

       withAnimation(.easeOut(duration: 0.4)) {
           ghostOpacity = 0
       }

       withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
           flipDegrees = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
           backRevealed = true
           phase        = .flipped
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
           withAnimation(.easeOut(duration: 0.35)) {
               self.questionVisible = true
           }
           // Ghost deck materializes as question appears
           withAnimation(.easeOut(duration: 1.56)) {
               self.ghostOpacity = 1
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
           self.fuseBurnStartDate = Date()
           withAnimation(.easeIn(duration: 0.4)) {
               self.fuseVisible = true
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
           guard self.phase == .flipped else { return }
           self.startShake()
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
           withAnimation(.easeOut(duration: 0.9)) {
               self.sitWithThisVisible = true
           }
       }
   }

   private func startShake() {
       guard !reduceMotion else { return }
       let sequence: [(Double, Double)] = [
           (8,  0.55),
           (-6, 0.55),
           (4,  0.55),
           (-2, 0.55),
           (0,  0.55),
       ]
       var delay = 0.0
       for (angle, duration) in sequence {
           DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
               withAnimation(
                   .easeInOut(duration: duration)
               ) {
                   flipHintDegrees = angle
               }
           }
           delay += duration
       }
   }

   // MARK: - Flip

   private func handleCardTap() {
       guard phase == .flipped, !pillsVisible else { return }
       UIImpactFeedbackGenerator(style: .light).impactOccurred()
       withAnimation(.easeInOut(duration: 0.45)) {
           pillsVisible = true
       }
   }

   // MARK: - Pill Selection

   private func handlePillSelected(_ pill: CardRevealPill) {
       guard phase == .flipped, selectedPill == nil else { return }
       selectedPill = pill
       phase        = .selected
       UIImpactFeedbackGenerator(style: .light).impactOccurred()

       ghostOpacity = 0

       // Beat 1 — immediate: selected pill breathes
       withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
           selectedPillScale = 1.06
       }

       // Beat 2 — t+500ms: border blooms
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.easeInOut(duration: 0.3)) {
               selectedBorderWidth = 3.0
           }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
       }

       // Beat 3 — t+900ms: unselected pills sink
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
           withAnimation(.easeIn(duration: 0.35)) {
               unselectedPillsVisible = false
           }
       }

       // t+1.3s — card exits upward
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
           withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.45)) {
               cardExiting = true
           }
       }

       // t+1.65s — encouragement rises into vacated space
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
           phase = .encouragement
           withAnimation(.easeOut(duration: 0.4)) {
               encouragementVisible = true
           }
       }
   }

   // MARK: - Typing complete → advance

   private func handleTypingComplete() {
       guard !hasAdvanced else { return }
       typingComplete = true
       DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
           commitAndAdvance()
       }
   }

   private func commitAndAdvance() {
       guard !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = selectedPill?.rawValue
       phase               = .exiting

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   // MARK: - Skip

   private func handleSkip() {
       fuseBurnProgress  = 0
       fuseBurnStartDate = nil
       fuseVisible   = false
       fuseCompleted = true
       flipHintActive  = false
       flipHintDegrees = 0
       guard phase == .idle, !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = nil

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   private func handleFuseComplete() {
       guard phase == .flipped, !fuseCompleted else { return }
       fuseCompleted    = true
       withAnimation(.easeInOut(duration: 1.2)) {
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
           self.startFlipHint()
       }
       // ...existing code...
   }

   private func startFlipHint() {
       guard phase == .idle else { return }
       flipHintActive = true
       pulseFlipHint()
   }

   private func pulseFlipHint() {
       guard flipHintActive, phase == .idle else {
           flipHintDegrees = 0
           return
       }
       withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
           flipHintDegrees = 12
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               self.flipHintDegrees = 0
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
           self.pulseFlipHint()
       }
   }

   private func updateFuseProgress(at date: Date) {
       guard fuseVisible, !fuseCompleted,
             let start = fuseBurnStartDate else { return }
       let elapsed      = date.timeIntervalSince(start)
       fuseBurnProgress = min(elapsed / fuseDuration, 1.0)
       if fuseBurnProgress >= 1.0 { handleFuseComplete() }
   }
}

// MARK: - Card Front



// MARK: - Card Views
// CardFrontView and CardBackView have been extracted to Design/Components/Cards/

// MARK: - Card Back

// MARK: - Encouragement View
//
// Typewriter reveal at 38 cps using AttributedString — no Text + Text.
//
// Sequence:
//   1. Plain text types in body color
//   2. Accent types in a static single color (cyan dark / magenta light)
//      matching LivingText's leading gradient stop
//   3. Once accent is fully typed, LivingText crossfades in over the
//      static accent — the glow "wakes up" invisibly since both start
//      at the same leading color
//   4. Cursor ("|") blinks × 3 then fades
//   5. onComplete() fires → parent waits 900ms → commitAndAdvance()

private struct EncouragementView: View {

   let isLight:      Bool
   let active:       Bool
   let reduceMotion: Bool
   let onComplete:   () -> Void

   private let plainText  = "This journey asks a lot of the people it's meant for. "
   private let accentText = "You're in good company."
   private var fullText: String { plainText }

   private let charsPerSecond: Double = 18

   @State private var visibleCharCount:  Int    = 0
   @State private var cursorOn:          Bool   = true
   @State private var cursorDone:        Bool   = false
   @State private var accentFullyTyped:  Bool   = false
   @State private var livingTextOpacity: Double = 0
   @State private var livingTextOffsetY: CGFloat = 8
   @State private var typingTask: DispatchWorkItem? = nil

   var body: some View {
       VStack(spacing: 0) {
           Spacer()
           composedText
               .multilineTextAlignment(.center)
               .padding(.horizontal, 40)
           Spacer()
       }
       .frame(width: 300, height: 400)
       .onAppear   { if active { beginTyping() } }
       .onChange(of: active) { _, isActive in
           if isActive { beginTyping() }
       }
   }

   @ViewBuilder
   private var composedText: some View {
       VStack(spacing: 0) {
           // Plain sentence — typewriter until fully typed,
           // then static (cursor gone, accent has arrived)
           Text(buildAttributedString(
               plain:      String(plainText.prefix(visibleCharCount)),
               accent:     "",
               showCursor: !cursorDone && cursorOn
           ))
           .fixedSize(horizontal: false, vertical: true)
           .multilineTextAlignment(.center)

           // Accent — fades in all at once once plain is done.
           // opacity 0 until livingTextOpacity animates to 1.
           LivingText(
               text: accentText,
               font: AppFonts.body(20, weight: .bold)
           )
           .opacity(livingTextOpacity)
           .offset(y: livingTextOffsetY)
       }
   }

   private func buildAttributedString(
       plain:      String,
       accent:     String,
       showCursor: Bool
   ) -> AttributedString {
       // Plain portion
       var result = AttributedString(plain)
       result.font            = AppFonts.body(20, weight: .medium)
       result.foregroundColor = isLight ? AppColors.lightCardTitle : AppColors.textPrimary

       // Accent portion — single color matching LivingText's leading stop
       if !accent.isEmpty {
           var accentAttr = AttributedString(accent)
           accentAttr.font            = AppFonts.body(20, weight: .bold)
           accentAttr.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(accentAttr)
       }

       // Cursor
       if showCursor {
           var cursor = AttributedString("|")
           cursor.font            = AppFonts.body(20, weight: .thin)
           cursor.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(cursor)
       }

       return result
   }

   // MARK: Typing sequence

   private func beginTyping() {
       guard visibleCharCount == 0 else { return }

       if reduceMotion {
           visibleCharCount  = fullText.count
           accentFullyTyped  = true
           cursorDone        = true
           livingTextOpacity = 1
           livingTextOffsetY = 0
           onComplete()
           return
       }

       typeNextChar()
   }

   private func typeNextChar() {
       guard visibleCharCount < fullText.count else {
           blinkCursor(count: 0)
           return
       }

       let item = DispatchWorkItem {
           visibleCharCount += 1

           // Detect when plain text becomes fully visible
           if !accentFullyTyped && visibleCharCount == fullText.count {
               accentFullyTyped = true
               // Cursor fades out first (150ms), then LivingText arrives
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                   cursorDone = true
                   // Opacity and rise arrive together — easeOut so it
                   // decelerates into its final position, not springs
                   withAnimation(.easeOut(duration: 1.0)) {
                       livingTextOpacity  = 1
                       livingTextOffsetY  = 0
                   }
               }
           }

           typeNextChar()
       }
       typingTask = item
       DispatchQueue.main.asyncAfter(
           deadline: .now() + 1.0 / charsPerSecond,
           execute: item
       )
   }

   private func blinkCursor(count: Int) {
       guard count < 6 else {
           cursorOn   = false
           cursorDone = true
           withAnimation(.easeOut(duration: 1.0)) {
               livingTextOpacity = 1
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               onComplete()
           }
           return
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
           cursorOn = !cursorOn
           blinkCursor(count: count + 1)
       }
   }
}

// MARK: - Previews

#Preview("Dark") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.pageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.dark)
}

#Preview("Light") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.lightPageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift` {#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift}

```swift
// Features/Onboarding/Views/OnboardingGroundRulesView.swift
//
// Screen 8: Before you dive in — honest framing of what this journey is and isn't.
// Must-acknowledge. No back button. No skipping.
// Writes data.groundRulesAcceptedAt, data.onboardingComplete, and data.completedAt
// on acknowledgment then calls onFinished.
//
// Layout strategy:
// - All devices use FlipPromiseCards — title front, detail back on tap
// - Card height scales: SE 72pt → mid 80pt → large 88pt
// - ScrollView with minHeight: fits without scroll on tall devices, scrolls on short ones

import SwiftUI

// MARK: - Main View

struct OnboardingGroundRulesView: View {
    @Binding var data: OnboardingData
    var onFinished: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion // ANIM-STD-31

    @State private var hasAnimated        = false
    @State private var atmosphereVisible  = false
    @State private var progressVisible    = false
    @State private var overlineVisible    = false
    @State private var subtextVisible     = false
    @State private var rulesVisible: Set<Int> = []
    @State private var frameVisible       = false
    @State private var ctaVisible         = false
    @State private var isPeeking          = false

    // MARK: - Pill Data

    private struct PillContent: Identifiable {
        let id: Int
        let icon: String
        let iconBg: AnyShapeStyle
        let title: String
        let detail: String
    }

    private var pills: [PillContent] {
        let pill2: PillContent = data.explorationMode == .couple
            ? PillContent(
                id: 1,
                icon: "heart.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This works best when you're both curious.",
                detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
              )
            : PillContent(
                id: 1,
                icon: "figure.walk",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This won't resolve things you're running from.",
                detail: "The best it can do is help you understand what you're running toward."
              )
        return [
            PillContent(
                id: 0,
                icon: "lightbulb.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.orangeHot],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "They say money shows you more of who you are.",
                detail: "This journey will do more of the same, if you see it through."
            ),
            pill2,
            PillContent(
                id: 2,
                icon: "hand.raised.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This is not therapy, and it's not trying to be.",
                detail: "Not every journey into this territory requires clinical support — but if yours does, the resources are here whenever you need them."
            ),
        ]
    }

    // MARK: - Computed helpers

    private var isLight: Bool { colorScheme == .light }

    private var subheadSuffix: String {
        ", the most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadFallback: String {
        "The most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadTextColor: Color {
        isLight ? AppColors.lightCardTitle : AppColors.textPrimary
    }

    private var italicLineStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Subhead View

    @ViewBuilder
    private func subheadView(h: CGFloat) -> some View {
        let font: Font = h < 700
            ? AppFonts.display(18)
            : h < 760
                ? AppFonts.display(20)
                : h < 820
                    ? AppFonts.display(21)
                    : AppFonts.screenTitle

        if data.displayName.isEmpty {
            Text(subheadFallback)
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(data.displayName)\(subheadSuffix)")
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let isCompact = h < 720
            let isMid     = h >= 720 && h < 760
            let cardPad: CGFloat = isCompact ? 12 : isMid ? 10 : 14
            let cardGap: CGFloat = isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h) * 0.7
                    : OL.compact(h)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    contentBlock(
                        h: h, w: w,
                        isCompact: isCompact,
                        isMid: isMid,
                        cardPad: cardPad,
                        cardGap: cardGap
                    )
                    Spacer(minLength: 0)
                    ctaBlock(geo: geo)
                        .padding(.horizontal, 24)
                }
                .frame(minHeight: geo.size.height)
            }
            .background {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    atmosphereLayer
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea()
            }
            .accessibilityLabel("Before you dive in. Screen 8 of 8.")
            .accessibilityAction(named: "I'm ready") { handleAcknowledge() }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                #if DEBUG
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    atmosphereVisible = true
                    progressVisible   = true
                    overlineVisible   = true
                    subtextVisible    = true
                    rulesVisible      = [0, 1, 2]
                    frameVisible      = true
                    ctaVisible        = true
                    return
                }
                #endif
                startAnimation()
            }
        }
    }

    // MARK: - Content Block

    @ViewBuilder
    private func contentBlock(
        h: CGFloat,
        w: CGFloat,
        isCompact: Bool,
        isMid: Bool,
        cardPad: CGFloat,
        cardGap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Progress bar
            OnboardingProgressBar(
                currentStep:          6,
                totalSteps:           6,
                progressDescription:  "Onboarding",
                showCompletionEffect: true
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, isCompact
                ? OL.navTop(h) + OL.compact(h)
                : OL.navTop(h) + OL.standard(h))
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : OL.standard(h))
            .opacity(progressVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: progressVisible)
            .accessibilityHidden(true)

            // Overline
            Group {
                if isLight {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("BEFORE YOU DIVE IN")
                                    .font(AppFonts.overline)
                                    .tracking(2)
                            )
                        )
                } else {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.cyanLight)
                        .tracking(2)
                }
            }
            .opacity(overlineVisible ? 1 : 0) // ANIM-STD-32
            .scaleEffect(overlineVisible ? 1.0 : 0.95) // ANIM-STD-32
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: overlineVisible)
            .padding(.horizontal, 24)
            .padding(.bottom, OL.compact(h))
            .accessibilityHidden(true)

            // Headline
            subheadView(h: h)
                .opacity(subtextVisible ? 1 : 0) // ANIM-STD-32
                .scaleEffect(subtextVisible ? 1.0 : 0.95) // ANIM-STD-32
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: subtextVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, isCompact
                    ? OL.compact(h)
                    : isMid
                        ? OL.compact(h)
                        : OL.standard(h))

            // Promise Cards — all devices use FlipPromiseCard
            VStack(spacing: cardGap) {
                ForEach(pills) { pill in
                    let isVisible = rulesVisible.contains(pill.id)
                    FlipPromiseCard(
                        icon:         pill.icon,
                        iconGradient: pill.iconBg,
                        title:        pill.title,
                        detail:       pill.detail,
                        verticalPad:  cardPad,
                        cardHeight:   isCompact ? 72 : isMid ? 80 : 88
                    )
                    .opacity(isVisible ? 1 : 0) // ANIM-STD-33
                    .scaleEffect(isVisible ? 1.0 : 0.95) // ANIM-STD-33
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
                    .rotation3DEffect(
                        .degrees(pill.id == 0 && isPeeking ? 15 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h)
                    : OL.standard(h))
        }
        // NO Spacer, NO maxHeight frame, NO backgrounds
    }

    // MARK: - CTA Block

    private func ctaBlock(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let isCompact = h < 720
        let isMid = h >= 720 && h < 760
        let lifeguardFont: Font = isCompact
            ? AppFonts.body(16, weight: .medium)
            : isMid
                ? AppFonts.body(17, weight: .medium)
                : AppFonts.body(18, weight: .medium)
        return VStack(spacing: 0) {
            Text("Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one.")
                .font(lifeguardFont)
                .italic()
                .foregroundStyle(italicLineStyle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(frameVisible ? 1 : 0) // ANIM-STD-34
                .scaleEffect(frameVisible ? 1.0 : 0.95) // ANIM-STD-34
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: frameVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, OL.compact(h))
            HoloCTAButton(title: "I'm ready", isEnabled: true) {
                handleAcknowledge()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, geo.safeAreaInsets.bottom > 0
                ? geo.safeAreaInsets.bottom + 8
                : 24)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82),
                value: ctaVisible
            )
        }
    }

    // MARK: - Atmospheric Layer

    private var atmosphereLayer: some View {
        GeometryReader { geo in
            ZStack {
                if isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.magenta.opacity(0.12),
                                AppColors.gold.opacity(0.06),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.purple.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                } else {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.30),
                                AppColors.cyan.opacity(0.12),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.magenta.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)
                }
            }
        }
    }

    // MARK: - Animation Timeline

    private func startAnimation() {
        // ANIM-STD-35: Reduce Motion fallback
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) {
                atmosphereVisible = true
                progressVisible   = true
                overlineVisible   = true
                subtextVisible    = true
                rulesVisible      = [0, 1, 2]
                frameVisible      = true
                ctaVisible        = true
            }
            return
        }

        // ANIM-STD-36: Standardized three-slot spring cascade
        // Slot A (header — progress + overline + subtext): 0ms
        // Slot B (body  — cards, staggered within slot):  100ms
        // Slot C (CTA   — lifeguard line + button):       200ms
        let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)

        withAnimation(.easeInOut(duration: 2.0)) { atmosphereVisible = true }

        // Slot A
        withAnimation(spring) { progressVisible = true }
        withAnimation(spring) { overlineVisible = true }
        withAnimation(spring) { subtextVisible  = true }

        // Slot B — cards staggered within the 100ms slot window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(spring) { _ = rulesVisible.insert(0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            withAnimation(spring) { _ = rulesVisible.insert(1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(spring) { _ = rulesVisible.insert(2) }
        }

        // Slot C
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(spring) { frameVisible = true }
            withAnimation(spring) { ctaVisible   = true }
        }

        // Peek effect — ambient, runs after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPeeking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPeeking = false }
        }
    }

    // MARK: - Acknowledge

    private func handleAcknowledge() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.groundRulesAcceptedAt = Date()
        data.onboardingComplete    = true
        data.completedAt           = Date()
        #if DEBUG
        assert(onFinished != nil,
            "OnboardingGroundRulesView: onFinished not injected — wire from coordinator.")
        #endif
        onFinished?()
    }
}

// MARK: - PromiseCard

private struct PromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 14

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                Text(detail)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, verticalPad)
        .cardSurface(isLight: isLight)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 40, height: 40)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - FlipPromiseCard

private struct FlipPromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 8
    var cardHeight:   CGFloat = 72

    @State private var isFlipped = false
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                iconBadge
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPad)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )

            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, verticalPad)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .cardSurface(isLight: isLight)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? detail : title)
        .accessibilityHint(isFlipped ? "Tap to show title" : "Tap to read more")
        .accessibilityAddTraits(.isButton)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 32, height: 32)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - Card Surface

private struct CardSurface: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight ? AppColors.lightCardFill : Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: AppColors.magenta.opacity(isLight ? 0.07 : 0),
                radius: 8, x: 0, y: 2
            )
            .modifier(PromiseCardBorder(isLight: isLight))
    }
}

private extension View {
    func cardSurface(isLight: Bool) -> some View {
        modifier(CardSurface(isLight: isLight))
    }
}

// MARK: - PromiseCardBorder

private struct PromiseCardBorder: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        if isLight {
            content
                .magentaGoldBorder(cornerRadius: 20, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        } else {
            content
                .pillBorder(cornerRadius: 20, lineWidth: 1, glowRadius: 3, opacity: 0.45)
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/PairingForkView.swift` {#file-open-lightly-features-onboarding-views-pairingforkview-swift}

```swift
//
//  PairingForkView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  PairingForkView.swift
//  Open Lightly
//
//  Created in Batch 10 — Onboarding Pairing Decision
//
//  PURPOSE:
//  Shown ONLY to users who selected "Couple" mode in ModeSelectionView.
//  Gives them two choices:
//    1. "Pair Now" → Opens PairingForkView (built in Batch 9) inline in onboarding
//    2. "Pair Later" → Skips pairing, continues onboarding, can pair from Settings
//
//  DESIGN RATIONALE:
//  We don't force pairing during onboarding because:
//    - The partner might not have the app yet
//    - The user might be setting up on a plane/subway (no internet)
//    - Reducing friction in onboarding improves completion rates
//    - Pairing is always available in Settings (wired in Batch 9)
//
//  This view doesn't do any data saving — it just captures the user's choice
//  via the two closures and lets the parent navigate accordingly.
//

import SwiftUI

struct PairingForkView: View {

    /// Called when the user taps "Pair Now".
    /// The parent view should navigate to PairingForkView.
    let onPairNow: () -> Void

    /// Called when the user taps "I'll do this later".
    /// The parent view should skip ahead to Experience Level or Desire Map.
    let onPairLater: () -> Void

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            // ── Icon ──
            // Visual indicator — a link symbol with a plus badge
            // to communicate "connect with someone."
            Image(systemName: "link.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            // ── Title ──
            Text("Connect with\nyour partner")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // ── Description ──
            // Explains WHY they should pair — unlocks shared features.
            Text("Share a code to link your accounts.\nYou'll unlock shared features like\ncompatibility matching.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // ── Action Buttons ──
            VStack(spacing: 12) {

                // Primary action: Pair Now
                // Uses accent color to draw attention — this is the preferred path.
                Button(action: onPairNow) {
                    Text("Pair Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                // Secondary action: Pair Later
                // Subtle styling (no fill, just text) so it doesn't compete
                // with the primary button, but is still easy to find.
                Button(action: onPairLater) {
                    Text("I'll do this later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/ContextCard.swift` {#file-open-lightly-features-onboarding-components-contextcard-swift}

```swift
import SwiftUI

struct ContextCard: View {
    let option: ContextOption
    let isFront: Bool
    let isConfirmed: Bool
    var index: Int = 0
    var total: Int = 3

    @State private var detailVisible = false
    @State private var isBreathing   = false

    @Environment(\.colorScheme) private var colorScheme

    private var intensity: ContextIntensity { option.intensity }
    private var isLight:   Bool             { colorScheme == .light }

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            // Dark: cardBg flat or intensity gradient — unchanged.
            // Light: lightFrostCard (white 58%) + ultraThinMaterial so the
            //        aurora blobs bleed through the card intentionally.
            if isLight {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.lightFrostCard)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
            } else {
                if intensity.bgTintStart < 1.0 {
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.cardBg,           location: intensity.bgTintStart),
                            .init(color: intensity.bgTintColor,      location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                } else {
                    AppColors.cardBg
                }
            }

            // ── Internal glow ─────────────────────────────────────────────
            // Light: opacity halved — the aurora behind the card already
            //        provides atmosphere; the internal glow would fight it.
            // Dark:  unchanged.
            if intensity.internalGlowSize > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Ellipse()
                            .fill(intensity.internalGlowColor)
                            .frame(
                                width:  intensity.internalGlowSize,
                                height: intensity.internalGlowSize
                            )
                            .blur(radius: intensity.internalGlowBlur)
                            .opacity(isLight
                                ? (isBreathing ? 0.65 : 0.50)  // halved from dark values
                                : (isBreathing ? 1.30 : 1.00)) // dark — unchanged
                            .offset(x: 20, y: -20)
                    }
                    Spacer()
                }
            }

            // ── Watermark ─────────────────────────────────────────────────
            // Replaced with TileOrbitView + position number in top-right.
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        TileOrbitView(
                            orbitCount: min(index + 1, 3),
                            isActive:   isFront,
                            speed:      1.0,
                            size:       36
                        )
                        .frame(width: 36, height: 36)
                        Text(String(format: "%02d", index + 1))
                            .font(AppFonts.overline)
                            .foregroundColor(isLight
                                ? .black.opacity(isFront ? 0.85 : 0.45)
                                : .white.opacity(isFront ? 0.85 : 0.45))
                            .animation(.easeInOut(duration: 0.3), value: isFront)
                    }
                    .padding(16)
                }
                Spacer()
            }

            // ── Content ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : intensity.rawValue >= 4
                            ? Color.white
                            : AppColors.textPrimary)
                    Text(option.subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : intensity.rawValue >= 4
                                ? Color.white.opacity(0.75)
                                : AppColors.textSecondary)
                }

                Spacer()

                Text(option.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : intensity.rawValue >= 4
                            ? Color.white.opacity(0.65)
                            : AppColors.textSecondary)
                    .lineSpacing(13 * 0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(detailVisible ? 1 : 0)
            }
            .padding(28)
            .frame(width: 300, height: 340, alignment: .topLeading)
        }
        .frame(width: 300, height: 340)
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // ── Border overlay ────────────────────────────────────────────────
        // Dark:  spectrum gradient (cyan→purple→magenta).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        // Light: warmAuroraBorder (purple→magenta→gold).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        //        No blur overlay — blur is invisible on cream.
        .overlay(
            Group {
                if isLight {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AppColors.warmAuroraBorder,
                                lineWidth: isConfirmed ? 2.5 : 2.0
                            )
                            .opacity(isConfirmed ? 1.0 : max(intensity.borderOpacity, 0.65))
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AppColors.warmAuroraBorder,
                                lineWidth: isConfirmed ? 3.5 : 3.0
                            )
                            .blur(radius: 6)
                            .opacity(isConfirmed ? 0.35 : 0.25)
                    }
                    .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                    .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                    .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isConfirmed ? 2 : 1.5
                        )
                        .opacity(isConfirmed ? 1.0 : intensity.borderOpacity)
                }
            }
        )
        // ── Shadows ───────────────────────────────────────────────────────
        // Dark:  intensity.shadowColor + cyan/magenta confirmed glow.
        // Light: lightShadowMagenta/Purple spread. intensity.shadowColor
        //        is a dark token so it's skipped on cream — the warm aurora
        //        shadow spread provides equivalent depth.
        .shadow(
            color: isLight
                ? AppColors.lightShadowMagenta.opacity(0.12)
                : intensity.shadowColor,
            radius: isLight ? 12 : intensity.shadowRadius
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.lightShadowMagenta
                    : AppColors.cyan.opacity(isBreathing ? 0.36 : 0.30))
                : .clear,
            radius: 8
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.lightShadowPurple
                    : AppColors.magenta.opacity(isBreathing ? 0.24 : 0.20))
                : .clear,
            radius: 12
        )
        .onChange(of: isFront) { _, newFront in
            if newFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.2)) { detailVisible = true }
            } else {
                withAnimation(.easeOut(duration: 0.15)) { detailVisible = false }
            }
        }
        .onChange(of: isConfirmed) { _, confirmed in
            if confirmed { startBreathing() } else { stopBreathing() }
        }
        .onAppear {
            if isFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) { detailVisible = true }
            }
            if isConfirmed { startBreathing() }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        isBreathing = false
        withAnimation(.easeInOut(duration: 0.2))                          { isBreathing = true  }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = true  }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = false }
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.2)) { isBreathing = false }
    }
}

// MARK: - Previews

private let previewOptions: [ContextOption] = [
    ContextOption(id: "single",           context: .single,          intensity: .ember,   title: "I'm single",              subtitle: "No partner in the picture",       detail: "Your journey is yours alone."),
    ContextOption(id: "partnered_open",   context: .partneredOpen,   intensity: .spark,   title: "I have a partner",        subtitle: "They know I'm exploring",         detail: "We'll include prompts for transparency."),
    ContextOption(id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,   title: "It's complicated",        subtitle: "I'm not sure how to bring it up", detail: "No pressure. We'll start with self-understanding."),
    ContextOption(id: "not_talked",       context: .notTalked,       intensity: .flame,   title: "Haven't talked about it", subtitle: "One or both of us is curious",    detail: "We'll start with the basics."),
    ContextOption(id: "some_experience",  context: .someExperience,  intensity: .inferno, title: "We've tried some things", subtitle: "Good, bad, or in between",        detail: "We'll help you process what happened."),
    ContextOption(id: "needs_reset",      context: .needsReset,      intensity: .nova,    title: "We need a reset",         subtitle: "Something's off",                 detail: "Let's rebuild with structure and care."),
]

#Preview("All Intensities — dark") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(40)
    }
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("All Intensities — light") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(40)
    }
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Confirmed — dark") {
    let option = previewOptions.last!
    HStack(spacing: 20) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Confirmed — light") {
    let option = previewOptions.last!
    HStack(spacing: 20) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(40)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/ContextCardStack.swift` {#file-open-lightly-features-onboarding-components-contextcardstack-swift}

```swift
import SwiftUI

/// Infinite-scroll gesture-driven card stack.
/// Swipe to browse, tap front card to confirm/unconfirm, auto-advances 0.8s after confirm.
struct ContextCardStack: View {
    @Binding var selection: ContextOption?
    let options: [ContextOption]
    let onAdvance: () -> Void

    @State private var currentIndex: Int   = 0
    @State private var dragOffset: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var renderPositions: [Int] {
        (currentIndex - 2 ... currentIndex + 2).map { $0 }
    }

    private func option(at position: Int) -> ContextOption {
        let count = options.count
        let idx   = ((position % count) + count) % count
        return options[idx]
    }

    var body: some View {
        ZStack {
            ForEach(renderPositions, id: \.self) { pos in
                let opt           = option(at: pos)
                let diff          = CGFloat(pos - currentIndex)
                let normalDrag    = dragOffset / 300
                let effectiveDiff = diff + normalDrag
                let absDiff       = abs(effectiveDiff)
                let sign: CGFloat = effectiveDiff >= 0 ? 1 : -1

                let xOffset  = absDiff < 0.001 ? CGFloat(0) : sign * (30 + absDiff * 18)
                let scale    = max(1 - absDiff * 0.07, 0.8)
                let yOffset  = absDiff * 6
                let rotation = (pos == currentIndex && dragOffset != 0)
                                 ? Double(dragOffset * 0.03) : 0.0
                let opacity  = max(1 - absDiff * 0.35, 0)
                let zIdx     = Double(20 - Int(absDiff * 5))

                ContextCard(
                    option: opt,
                    isFront: pos == currentIndex,
                    isConfirmed: opt.id == selection?.id,
                    index: pos,
                    total: options.count
                )
                .offset(x: xOffset, y: yOffset)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .zIndex(zIdx)
            }
        }
        .frame(width: 300, height: 340)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Block drag while confirmed — only taps allowed
                    guard selection == nil else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let totalMove = abs(value.translation.width) + abs(value.translation.height)

                    if totalMove < 10 {
                        // Tap: toggle confirm on front card
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { dragOffset = 0 }
                        let front = option(at: currentIndex)
                        if front.id == selection?.id {
                            // Unconfirm — cancel pending advance
                            autoAdvanceTask?.cancel()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = nil }
                        } else {
                            // Confirm — schedule auto-advance
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = front }
                            autoAdvanceTask?.cancel()
                            autoAdvanceTask = Task {
                                try? await Task.sleep(for: .seconds(0.45))
                                if !Task.isCancelled {
                                    await MainActor.run { onAdvance() }
                                }
                            }
                        }
                        return
                    }

                    // Swipe — blocked if confirmed
                    guard selection == nil else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { dragOffset = 0 }
                        return
                    }

                    let predicted = value.predictedEndTranslation.width
                    let actual    = value.translation.width
                    var newIndex  = currentIndex

                    if predicted > 150 || actual > 50 {
                        newIndex = currentIndex - 1
                    } else if predicted < -150 || actual < -50 {
                        newIndex = currentIndex + 1
                    }

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        currentIndex = newIndex
                        dragOffset   = 0
                    }
                }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    dragOffset = 18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
        }
    }
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/ContextIntensity.swift` {#file-open-lightly-features-onboarding-components-contextintensity-swift}

```swift
import SwiftUI

/// Visual intensity levels mirroring the HTML design spec (ember → nova).
/// Controls background gradient, internal glow, border opacity, and external shadow.
enum ContextIntensity: Int {
    case ember   = 1
    case spark   = 2
    case flame   = 3
    case blaze   = 4
    case inferno = 5
    case nova    = 6

    // MARK: Background gradient tint (applied from bottom-trailing)
    var bgTintColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.04)
        case .flame:   return AppColors.cyan.opacity(0.06)
        case .blaze:   return AppColors.purple.opacity(0.08)
        case .inferno: return AppColors.magenta.opacity(0.06)
        case .nova:    return AppColors.magenta.opacity(0.10)
        }
    }

    /// Where the solid cardBg stops and the tint begins (gradient stop location)
    var bgTintStart: CGFloat {
        switch self {
        case .ember:   return 1.0   // no gradient
        case .spark:   return 0.70
        case .flame:   return 0.50
        case .blaze:   return 0.40
        case .inferno: return 0.30
        case .nova:    return 0.20
        }
    }

    // MARK: Spectrum border opacity
    var borderOpacity: Double {
        switch self {
        case .ember:   return 0.40
        case .spark:   return 0.50
        case .flame:   return 0.60
        case .blaze:   return 0.70
        case .inferno: return 0.80
        case .nova:    return 0.90
        }
    }

    // MARK: Internal top-right glow
    var internalGlowColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.10)
        case .flame:   return AppColors.purple.opacity(0.15)
        case .blaze:   return AppColors.purple.opacity(0.20)
        case .inferno: return AppColors.magenta.opacity(0.20)
        case .nova:    return AppColors.magenta.opacity(0.30)
        }
    }

    var internalGlowSize: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 100
        case .flame:   return 130
        case .blaze:   return 150
        case .inferno: return 170
        case .nova:    return 200
        }
    }

    var internalGlowBlur: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 30
        case .flame:   return 40
        case .blaze:   return 50
        case .inferno: return 60
        case .nova:    return 70
        }
    }

    // MARK: External ambient shadow
    var shadowColor: Color {
        switch self {
        case .ember:   return AppColors.cyan.opacity(0.04)
        case .spark:   return AppColors.cyan.opacity(0.06)
        case .flame:   return AppColors.purple.opacity(0.08)
        case .blaze:   return AppColors.purple.opacity(0.12)
        case .inferno: return AppColors.magenta.opacity(0.10)
        case .nova:    return AppColors.magenta.opacity(0.16)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .ember:   return 10
        case .spark:   return 15
        case .flame:   return 20
        case .blaze:   return 25
        case .inferno: return 30
        case .nova:    return 35
        }
    }
}

```

---

## File: `Open Lightly/Features/Onboarding/Components/ContextOption.swift` {#file-open-lightly-features-onboarding-components-contextoption-swift}

```swift
import Foundation

struct ContextOption: Identifiable {
    let id: String
    let context: RelationshipContext
    let intensity: ContextIntensity
    let title: String
    let subtitle: String
    let detail: String
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

## File: `Open Lightly/Design/Components/Navigation/OnboardingNavBar.swift` {#file-open-lightly-design-components-navigation-onboardingnavbar-swift}

```swift
// OnboardingNavBar.swift
// Open Lightly
//
// Reusable nav row: back chevron + centered progress bar.
// Used at the top of every onboarding screen that shows navigation.
import SwiftUI

// MARK: - Private Modifiers

private struct BackButtonModifier: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.0)
                        )
                        
                )
                .shadow(color: AppColors.magenta.opacity(0.12), radius: 8, y: 2)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 16, y: 2)
        } else {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )
                       
                )
                .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
                .shadow(color: AppColors.cyan.opacity(0.12), radius: 20)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        }
    }
}

// MARK: - View

struct OnboardingNavBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)?  // nil = no back button (ground rules, priming, arrival)
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .light
                                         ? AppColors.wineDark
                                         : Color.white.opacity(0.80))
                        .modifier(BackButtonModifier(colorScheme: colorScheme))
                }
                .accessibilityLabel("Go back")
            } else {
                // Match the 38pt rendered size of the back button
                Color.clear.frame(width: 38, height: 38)
                    .padding(.trailing, 0) 
            }
            
            Spacer()
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
            Spacer()
            
            // FIXED: was 18pt — must match back button total size (18 icon + 10 pad each side = 38)
            Color.clear.frame(width: 38, height: 38)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}

```

---

## File: `Open Lightly/Design/Components/Navigation/OnboardingFooter.swift` {#file-open-lightly-design-components-navigation-onboardingfooter-swift}

```swift
// OnboardingFooter.swift
// Open Lightly
//
// Footer shown below the CTA on onboarding screens.

import SwiftUI

struct OnboardingFooter: View {
    var text: String = "Your data is encrypted and always stays yours."

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(colorScheme == .light
                ? AppColors.lightTextTertiary
                : Color(red: 0.42, green: 0.42, blue: 0.50))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 24)
    }
}

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/OnboardingProgressBar.swift` {#file-open-lightly-design-components-progress-onboardingprogressbar-swift}

```swift
// OnboardingProgressBar.swift
// Open Lightly
//
// FULLY AUDITED & REFINED — v2.3  (visual quality pass)
//
// Changes in v2.3
// ───────────────────────────────────────────────────────
// VQ-01  shimmerCycleDuration default raised 2.4 → 3.0s.
//        At 2.4s the shimmer pulses at 25/min — reads as nervous.
//        3.0s aligns with reward animation research (cf. App Store
//        confetti timing) and simultaneously slows the bloom breathe
//        to ~20/min, closer to the 12–16/min respiratory target.
//
// VQ-02  Bloom atmo vertical spread scalars reduced:
//        Dark  base 3.5 → 2.8,  pulse 2.0 → 1.4
//        Light base 2.2 → 1.8,  pulse 1.1 → 0.8
//        Previous values produced 14–22pt spread on a 4pt bar.
//        New values produce 11–16pt dark / 9–13pt light — still
//        atmospheric but proportionate.
//
// VQ-03  Bloom atmo gradient gains a cyan stop at position 0 (dark)
//        and a deeper orangeDeep stop at 0 (light) to anchor the left
//        end of the bar's color identity into the atmospheric layer.
//        Previously atmo opened with purple, losing cyan entirely.
//
// VQ-04  Bloom atmo magenta opacity cap:
//        Dark:  0.80 → 0.70  (atmo center stop — was competing with fill)
//        Light: 0.80 → 0.50  (cream background — was creating pink cast)
//
// VQ-05  Bloom mid center stop opacity:
//        Light orangeHot 0.90 → 0.65  (too saturated on cream)
//        Dark  purple    0.90 → unchanged (correct)
//
// VQ-06  Bloom core base opacity:
//        Dark  0.50 → 0.38  (was competing with fill surface)
//        Light 0.22 → unchanged (well-calibrated)
//
// VQ-07  Bloom atmo blur base:
//        Light 4.5 → 3.5  (was spreading magenta too far on cream)
//        Dark  6.0 → unchanged
//
// VQ-08  Light mode fill gradient: magenta final stop opacity 0.75 → 0.55,
//        orangeHot mid stop location 0.5 → 0.65 — extends warm amber
//        longer before the pink arrival, reducing harsh colour jump.
//
// VQ-09  Light mode track opacity 0.06 → 0.09 — the rail was barely
//        legible at minimum contrast; 0.09 is structural without heavy.
//
// VQ-10  Shimmer outer blur radius 2 → 3pt — softens the rectangular
//        edge artifact visible at small blur on a 4pt bar.
//
// VQ-11  Shimmer inner opacity range light mode branch added:
//        Light: 0.32 + intensity×0.36  (dark: 0.28 + intensity×0.32)
//        White shimmer is less visible against orange fill; compensated.
//
// VQ-12  Particle rise height: base 10 → 14pt, variation ±3 → ±5pt
//        (range 9–19pt). Previous 7–13pt barely cleared the bloom halo.
//
// VQ-13  Particle ease exponent: base 2.0 → 2.2, variation ±0.5 → ±0.9
//        (range 1.3–3.1). Wider spread creates visible arc-vs-drift variety.
//
// VQ-14  Particle drift frequency: sin multiplier 2.1 → 1.8 per particle
//        index. Previous frequency clustered two particles at similar
//        rightward drift (+4.55, +3.27). New distribution is better spread.
//
// VQ-15  Particle wobble amplitude: easeOut×2 → easeOut×3.5.
//        Previous 2pt max lateral movement was sub-perceptual.
//
// VQ-16  Particle fade-in window: 0–20% → 0–15% of cycle.
//        0.48s fade-in at 2.4s cycle exceeded 300ms attention-capture
//        threshold. Now 0.45s at 3.0s cycle (0–15% × 3.0s).
//
// VQ-17  Particle Y origin: shifted to bar top surface.
//        Previously particles began at barMidY (bar centre).
//        Now: barMidY - barHeight/2 — they appear to launch from
//        the lit surface rather than from inside the fill.
//
// VQ-18  Particle light mode opacity scale: 0.52 → 0.65.
//        At 0.52 the dot (0.47) was too dim against orange fill on cream.
//        0.65 brings dot to 0.59, halo to 0.34 — readable without smear.
//
// All dark bloom color values unchanged except where explicitly noted.
// All accessibility, localisation, architecture, and performance work
// from v2.1/v2.2 preserved exactly.

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ClosedRange clamp helper
// ─────────────────────────────────────────────────────────────────────────────

extension ClosedRange where Bound: Comparable {
    /// Clamps `value` to lie within this range.
    func clamp(_ value: Bound) -> Bound {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pure Animation Math  (zero UI dependencies — unit-testable)
// ─────────────────────────────────────────────────────────────────────────────

enum AnimationMath {

    /// Wraps elapsed seconds into a normalised [0, 1) phase for one cycle.
    static func shimmerPhase(
        elapsed:       CGFloat,
        cycleDuration: CGFloat
    ) -> CGFloat {
        guard cycleDuration > 0 else { return 0 }
        return elapsed
            .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
    }

    /// Peak at mid-cycle. Returns value in [0, 1].
    static func bloomIntensity(phase: CGFloat) -> CGFloat {
        sin(phase * .pi)
    }

    /// Intentionally identical to bloomIntensity so the two effects
    /// pulse in perfect unison (fixes the phase-drift bug from v1).
    static func breatheIntensity(phase: CGFloat) -> CGFloat {
        bloomIntensity(phase: phase)
    }

    /// Shimmer hotspot X offset in points.
    /// Travels from −overshoot to fillWidth+overshoot across one cycle.
    static func shimmerXOffset(
        phase:     CGFloat,
        fillWidth: CGFloat,
        overshoot: CGFloat = 30
    ) -> CGFloat {
        let sweepRange = fillWidth + overshoot * 2
        return phase * sweepRange - overshoot
    }

    /// Progress ratio clamped to [0, 1]; NaN / infinite safe.
    static func safeRatio(current: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let raw = CGFloat(current) / CGFloat(total)
        guard raw.isFinite else { return 0 }
        return (0.0...1.0).clamp(raw)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Animation Clock  (extracted from View — testable, identity-safe)
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class ProgressAnimationClock {

    private(set) var startTime: Date? = nil

    func activate() { startTime = Date() }
    func reset()    { startTime = nil  }

    func elapsed(at date: Date) -> CGFloat {
        guard let start = startTime else { return 0 }
        return CGFloat(date.timeIntervalSince(start))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design Constants
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarConstants {
    static let defaultTotalWidth:    CGFloat = 120
    static let defaultBarHeight:     CGFloat = 5
    /// Extra canvas on each side so bloom can bleed past bar ends.
    static let bloomBleed:           CGFloat = 12
    // VQ-01: raised from 2.4 → 3.0s. See change log.
    static let defaultShimmerCycle:  Double  = 3.0
    static let defaultFillDuration:  Double  = 0.35
    /// Frame-rate cap for the bloom TimelineView.
    static let bloomFPS:             Double  = 30
    /// Max vertical bloom spread as a multiple of barHeight (HIG cap).
    static let maxBloomSpreadFactor: CGFloat = 7.0
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pre-computed Gradients  (static lets — dark mode source of truth)
//
// These are the dark mode gradients, allocated once.
// Light mode variants are computed properties on the View (they must be
// computed because they reference colorScheme, which requires View context).
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarGradients {

    // ── Fill ──────────────────────────────────────────────────────────────
    static let staticFill = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,   location: 0.0),
            .init(color: AppColors.purple, location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let finalFill = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,    location: 0.0),
            .init(color: AppColors.purple,  location: 0.5),
            .init(color: AppColors.magenta, location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )

    // RTL mirrors — colour order preserved, direction flipped
    static let staticFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,   location: 0.0),
            .init(color: AppColors.purple, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
    static let finalFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,    location: 0.0),
            .init(color: AppColors.purple,  location: 0.5),
            .init(color: AppColors.magenta, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )

    // ── Light mode fill variants ───────────────────────────────────────────
    // VQ-08: magenta final stop opacity 0.75 → 0.55; orangeHot mid stop
    //        location 0.5 → 0.65 to extend warm amber before the pink arrives.

    static let staticFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep, location: 0.0),
            .init(color: AppColors.orangeHot,  location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let finalFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep,            location: 0.00),
            .init(color: AppColors.orangeHot,             location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.magenta.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let staticFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep, location: 0.0),
            .init(color: AppColors.orangeHot,  location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
    static let finalFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep,            location: 0.00),
            .init(color: AppColors.orangeHot,             location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.magenta.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Localised String Helpers
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarStrings {

    static func stepLabel(
        description: String,
        current:     Int,
        total:       Int
    ) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.label",
                value: "%@, step %lld of %lld",
                comment: "Accessibility label. Arg1: flow name, Arg2: current step, Arg3: total."
            ),
            description,
            current,
            total
        )
    }

    /// Locale-correct percentage, e.g. "75%" or "75 %" depending on locale.
    static func percentValue(ratio: CGFloat) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle           = .percent
        formatter.locale                = .current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(ratio)))
            ?? "\(Int(ratio * 100))%"
    }

    static func milestoneAnnouncement(current: Int, total: Int) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.announcement",
                value: "Step %lld of %lld",
                comment: "VoiceOver announcement when the user advances a step."
            ),
            current,
            total
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - iOS-version-safe onChange modifier  (wraps #available internally)
// ─────────────────────────────────────────────────────────────────────────────

private struct StepChangeModifier: ViewModifier {
    let currentStep: Int
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: currentStep) { _, _ in action() }
        } else {
            content.onChange(of: currentStep) { _ in action() }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - OnboardingProgressBar
// ─────────────────────────────────────────────────────────────────────────────

struct OnboardingProgressBar: View {

    // ── Public props ───────────────────────────────────────────────────────

    let currentStep:          Int
    let totalSteps:           Int
    var progressDescription:  String  = NSLocalizedString(
        "progress.description.default",
        value: "Onboarding",
        comment: "Default VoiceOver description."
    )
    var showCompletionEffect: Bool    = false
    var totalWidth:           CGFloat = ProgressBarConstants.defaultTotalWidth
    var barHeight:            CGFloat = ProgressBarConstants.defaultBarHeight
    var animationDuration:    Double  = ProgressBarConstants.defaultFillDuration
    var shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle

    // ── Backward-compatible convenience init ──────────────────────────────
    init(
        currentStep:          Int,
        totalSteps:           Int,
        progressDescription:  String  = NSLocalizedString(
            "progress.description.default",
            value: "Onboarding",
            comment: "Default VoiceOver description."
        ),
        showCompletionEffect: Bool    = false,
        totalWidth:           CGFloat = ProgressBarConstants.defaultTotalWidth,
        barHeight:            CGFloat = ProgressBarConstants.defaultBarHeight,
        animationDuration:    Double  = ProgressBarConstants.defaultFillDuration,
        shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle
    ) {
        self.currentStep          = currentStep
        self.totalSteps           = totalSteps
        self.progressDescription  = progressDescription
        self.showCompletionEffect = showCompletionEffect
        self.totalWidth           = totalWidth
        self.barHeight            = barHeight
        self.animationDuration    = animationDuration
        self.shimmerCycleDuration = shimmerCycleDuration
    }

    // ── Private state ──────────────────────────────────────────────────────

    @State private var clock = ProgressAnimationClock()

    // ── Environment ────────────────────────────────────────────────────────

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var increaseContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    @Environment(\.colorScheme)      private var colorScheme
    @Environment(\.layoutDirection)  private var layoutDirection

    // ── Derived values ─────────────────────────────────────────────────────

    var fillRatio: CGFloat {
        AnimationMath.safeRatio(current: currentStep, total: totalSteps)
    }

    private var fillWidth: CGFloat { totalWidth * fillRatio }

    // LIGHT-01 / VQ-09: Light track opacity raised 0.06 → 0.09.
    //   At 0.06 the rail was at minimum legibility on cream.
    //   0.09 is structural without being heavy.
    private var trackColor: Color {
        colorScheme == .light
        ? Color.black.opacity(0.09)   // VQ-09: was 0.06
        : Color.white.opacity(trackOpacity)
    }

    private var trackOpacity: CGFloat {
        increaseContrast ? 0.50 : 0.18
    }

    private var isRTL: Bool { layoutDirection == .rightToLeft }

    // LIGHT-02: Gradient selectors branch dark ↔ light before RTL mirror.
    private var staticFillGradient: LinearGradient {
        if colorScheme == .light {
            return isRTL
            ? ProgressBarGradients.staticFillLightRTL
            : ProgressBarGradients.staticFillLight
        }
        return isRTL
        ? ProgressBarGradients.staticFillRTL
        : ProgressBarGradients.staticFill
    }

    private var finalFillGradient: LinearGradient {
        if colorScheme == .light {
            return isRTL
            ? ProgressBarGradients.finalFillLightRTL
            : ProgressBarGradients.finalFillLight
        }
        return isRTL
        ? ProgressBarGradients.finalFillRTL
        : ProgressBarGradients.finalFill
    }

    // ── Bloom geometry ─────────────────────────────────────────────────────

    private var bloomBleed:     CGFloat { ProgressBarConstants.bloomBleed }
    private var canvasWidth:    CGFloat { totalWidth + bloomBleed * 2 }
    private var maxBloomHeight: CGFloat {
        barHeight * ProgressBarConstants.maxBloomSpreadFactor
    }

    // ── Bloom light/dark scalars ────────────────────────────────────────────
    //
    // VQ-02: Atmo spread reduced. Previous dark base 3.5 → 2.8 (−20%),
    //        pulse 2.0 → 1.4 (−30%). Light base 2.2 → 1.8, pulse 1.1 → 0.8.
    //        On a 4pt bar the old values produced 14–22pt spread —
    //        disproportionate. New range: 11–16pt dark, 9–13pt light.
    //
    // VQ-04: Atmo magenta opacity reduced (see bloomCanvas gradient stops).
    // VQ-06: Core base opacity dark 0.50 → 0.38 — was competing with fill.
    // VQ-07: Atmo blur base light 4.5 → 3.5 — was spreading pink too far.

    private var bloomAtmoOpacityBase:  CGFloat { colorScheme == .dark ? 0.18 : 0.10 }
    private var bloomAtmoOpacityPulse: CGFloat { colorScheme == .dark ? 0.18 : 0.10 }
    private var bloomMidOpacityBase:   CGFloat { colorScheme == .dark ? 0.28 : 0.13 }
    private var bloomMidOpacityPulse:  CGFloat { colorScheme == .dark ? 0.22 : 0.11 }
    private var bloomCoreOpacityBase:  CGFloat { colorScheme == .dark ? 0.38 : 0.22 }  // VQ-06: dark was 0.50
    private var bloomCoreOpacityPulse: CGFloat { colorScheme == .dark ? 0.25 : 0.13 }

    // VQ-02: Spread multipliers tightened.
    private var bloomAtmoSpreadBase:   CGFloat { colorScheme == .dark ? 2.8 : 1.8 }    // VQ-02: dark 3.5→2.8, light 2.2→1.8
    private var bloomAtmoSpreadPulse:  CGFloat { colorScheme == .dark ? 1.4 : 0.8 }    // VQ-02: dark 2.0→1.4, light 1.1→0.8
    private var bloomMidSpreadBase:    CGFloat { colorScheme == .dark ? 2.0 : 1.3 }
    private var bloomMidSpreadPulse:   CGFloat { colorScheme == .dark ? 1.2 : 0.7 }
    private var bloomCoreSpreadBase:   CGFloat { colorScheme == .dark ? 1.2 : 0.9 }
    private var bloomCoreSpreadPulse:  CGFloat { colorScheme == .dark ? 1.0 : 0.6 }

    // VQ-07: Atmo blur base light 4.5 → 3.5.
    private var bloomAtmoBlurBase:     CGFloat { colorScheme == .dark ? 6.0 : 3.5 }    // VQ-07: light was 4.5
    private var bloomAtmoBlurPulse:    CGFloat { colorScheme == .dark ? 3.0 : 1.8 }
    private var bloomMidBlurBase:      CGFloat { colorScheme == .dark ? 5.0 : 3.5 }
    private var bloomMidBlurPulse:     CGFloat { colorScheme == .dark ? 3.0 : 1.8 }
    private var bloomCoreBlurBase:     CGFloat { colorScheme == .dark ? 2.0 : 1.6 }
    private var bloomCoreBlurPulse:    CGFloat { colorScheme == .dark ? 1.0 : 0.7 }

    // VQ-18: Light particle opacity scale raised 0.52 → 0.65.
    private var particleOpacityScale:  CGFloat { colorScheme == .dark ? 1.0 : 0.65 }   // VQ-18: light was 0.52

    // ── Accessibility ──────────────────────────────────────────────────────

    private var a11yLabel: String {
        ProgressBarStrings.stepLabel(
            description: progressDescription,
            current:     currentStep,
            total:       totalSteps
        )
    }

    private var a11yValue: String {
        ProgressBarStrings.percentValue(ratio: fillRatio)
    }

    // ── Timeline schedule (30 fps cap) ─────────────────────────────────────

    private var timelineSchedule: PeriodicTimelineSchedule {
        .periodic(from: .now, by: 1.0 / ProgressBarConstants.bloomFPS)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: body
    // ─────────────────────────────────────────────────────────────────────

    var body: some View {

        assert(totalSteps  >  0, "totalSteps must be > 0, got \(totalSteps)")
        assert(currentStep >= 0, "currentStep must be >= 0, got \(currentStep)")
        assert(
            currentStep <= totalSteps,
            "currentStep (\(currentStep)) exceeds totalSteps (\(totalSteps))"
        )

        return Group {
            if showCompletionEffect && !reduceMotion {
                TimelineView(timelineSchedule) { tl in
                    let e  = clock.elapsed(at: tl.date)
                    let sp = AnimationMath.shimmerPhase(
                        elapsed:       e,
                        cycleDuration: CGFloat(shimmerCycleDuration)
                    )
                    let bi = AnimationMath.bloomIntensity(phase: sp)
                    let br = AnimationMath.breatheIntensity(phase: sp)

                    finalBar(
                        elapsed:          e,
                        shimmerPhase:     sp,
                        bloomIntensity:   bi,
                        breatheIntensity: br
                    )
                }
                .onAppear    { clock.activate() }
                .onDisappear { clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didEnterBackgroundNotification
                    )
                ) { _ in clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in clock.activate() }
                .modifier(StepChangeModifier(currentStep: currentStep) {
                    if showCompletionEffect { clock.activate() }
                })

            } else {
                staticBar
                    .modifier(StepChangeModifier(currentStep: currentStep) { })
            }
        }
        .frame(width: totalWidth, height: barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
        .accessibilityValue(a11yValue)
        .accessibilityAddTraits([.updatesFrequently, .isStaticText])
        .accessibilityIdentifier("OnboardingProgressBar")
        .modifier(StepChangeModifier(currentStep: currentStep) {
            postStepAnnouncement()
        })
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: VoiceOver announcement
    // ─────────────────────────────────────────────────────────────────────

    private func postStepAnnouncement() {
        let msg = ProgressBarStrings.milestoneAnnouncement(
            current: currentStep,
            total:   totalSteps
        )
        UIAccessibility.post(notification: .announcement, argument: msg)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Static bar
    // ─────────────────────────────────────────────────────────────────────

    private var staticBar: some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(staticFillGradient)
                .frame(width: fillWidth, height: barHeight)
                .animation(
                    .easeInOut(duration: animationDuration),
                    value: fillWidth
                )
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Final-step bar
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func finalBar(
        elapsed:          CGFloat,
        shimmerPhase:     CGFloat,
        bloomIntensity:   CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        barContent(
            shimmerPhase:     shimmerPhase,
            bloomIntensity:   bloomIntensity,
            breatheIntensity: breatheIntensity
        )
        .drawingGroup()
        .overlay(
            bloomCanvas(
                elapsed:              elapsed,
                bloomIntensity:       bloomIntensity,
                breatheIntensity:     breatheIntensity,
                colorScheme:          colorScheme,
                barHeight:            barHeight,
                atmoOpacityBase:      bloomAtmoOpacityBase,
                atmoOpacityPulse:     bloomAtmoOpacityPulse,
                midOpacityBase:       bloomMidOpacityBase,
                midOpacityPulse:      bloomMidOpacityPulse,
                coreOpacityBase:      bloomCoreOpacityBase,
                coreOpacityPulse:     bloomCoreOpacityPulse,
                atmoSpreadBase:       bloomAtmoSpreadBase,
                atmoSpreadPulse:      bloomAtmoSpreadPulse,
                midSpreadBase:        bloomMidSpreadBase,
                midSpreadPulse:       bloomMidSpreadPulse,
                coreSpreadBase:       bloomCoreSpreadBase,
                coreSpreadPulse:      bloomCoreSpreadPulse,
                atmoBlurBase:         bloomAtmoBlurBase,
                atmoBlurPulse:        bloomAtmoBlurPulse,
                midBlurBase:          bloomMidBlurBase,
                midBlurPulse:         bloomMidBlurPulse,
                coreBlurBase:         bloomCoreBlurBase,
                coreBlurPulse:        bloomCoreBlurPulse,
                particleOpacityScale: particleOpacityScale
            )
            .frame(width: canvasWidth, height: maxBloomHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bar content (track + fill + shimmer)
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func barContent(
        shimmerPhase:     CGFloat,
        bloomIntensity:   CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(finalFillGradient)
                .frame(width: fillWidth, height: barHeight)

            shimmerOverlay(
                shimmerPhase:     shimmerPhase,
                breatheIntensity: breatheIntensity
            )
        }
        .compositingGroup()
        .clipShape(Capsule())
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Shimmer overlay
    // ─────────────────────────────────────────────────────────────────────
    // VQ-10: outer blur 2 → 3pt — softens rectangular edge on small bar.
    // VQ-11: light mode inner opacity branch added — white shimmer needs
    //        higher opacity to read against orange fill on cream.

    @ViewBuilder
    private func shimmerOverlay(
        shimmerPhase:     CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        let xPos         = AnimationMath.shimmerXOffset(
            phase:     shimmerPhase,
            fillWidth: fillWidth
        )
        let outerOpacity = 0.10 + breatheIntensity * 0.18

        // VQ-11: inner opacity slightly higher in light mode so the white
        //        hotspot reads against the warm orange fill on cream.
        let innerOpacity: CGFloat = colorScheme == .light
            ? 0.32 + breatheIntensity * 0.36   // VQ-11: light (was no branch)
            : 0.28 + breatheIntensity * 0.32   // original dark values

        ZStack(alignment: .leading) {

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(outerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: 16, height: barHeight)
                .blur(radius: 3)            // VQ-10: was 2
                .offset(x: xPos - 2)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(innerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: 10, height: barHeight)
                .offset(x: xPos)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bloom canvas
    // ─────────────────────────────────────────────────────────────────────
    // LIGHT-03: colorScheme passed as parameter.
    // LIGHT-05: _ = elapsed inside Canvas prevents SwiftUI optimising
    //           away the redraw (was missing as _ = timeline.date in v2.1).
    //
    // VQ-03: Atmo gradient gains a cyan/orangeDeep anchor stop at leading
    //        edge so the bar's left-end color identity bleeds into atmosphere.
    // VQ-04: Atmo center magenta opacity: dark 0.80→0.70, light 0.80→0.50.
    // VQ-05: Mid center stop: light orangeHot 0.90→0.65.
    // VQ-06: Core opacity controlled via coreOpacityBase (dark 0.50→0.38).
    // VQ-12–VQ-17: Particle system tuning (see inline comments).
    //
    // barHeight is now explicitly threaded through so Canvas closure can
    // compute the correct Y launch origin (VQ-17) without capturing self.

    @ViewBuilder
    private func bloomCanvas(
        elapsed:              CGFloat,
        bloomIntensity:       CGFloat,
        breatheIntensity:     CGFloat,
        colorScheme:          ColorScheme,
        barHeight:            CGFloat,
        atmoOpacityBase:      CGFloat,
        atmoOpacityPulse:     CGFloat,
        midOpacityBase:       CGFloat,
        midOpacityPulse:      CGFloat,
        coreOpacityBase:      CGFloat,
        coreOpacityPulse:     CGFloat,
        atmoSpreadBase:       CGFloat,
        atmoSpreadPulse:      CGFloat,
        midSpreadBase:        CGFloat,
        midSpreadPulse:       CGFloat,
        coreSpreadBase:       CGFloat,
        coreSpreadPulse:      CGFloat,
        atmoBlurBase:         CGFloat,
        atmoBlurPulse:        CGFloat,
        midBlurBase:          CGFloat,
        midBlurPulse:         CGFloat,
        coreBlurBase:         CGFloat,
        coreBlurPulse:        CGFloat,
        particleOpacityScale: CGFloat
    ) -> some View {
        Canvas { ctx, size in

            _ = elapsed   // LIGHT-05: forces Canvas invalidation every tick.

            let barMinX   = bloomBleed
            let barMidY   = size.height / 2
            // VQ-17: bar top surface Y — particles launch from here, not centre.
            let barTopY   = barMidY - barHeight / 2

            let isLight = colorScheme == .light

            // ── Layer 3: Outer atmosphere ──────────────────────────────────
            // VQ-02: spread values reduced (passed in via parameters).
            // VQ-03: leading stop now uses cyan (dark) / orangeDeep (light)
            //        to anchor the bar's left-end color into the atmosphere.
            // VQ-04: center magenta opacity dark 0.80→0.70, light 0.80→0.50.

            let atmoSpread  = barHeight * (atmoSpreadBase + breatheIntensity * atmoSpreadPulse)
            let atmoOpacity = atmoOpacityBase + breatheIntensity * atmoOpacityPulse
            var atmoCtx     = ctx
            atmoCtx.addFilter(.blur(radius: atmoBlurBase + bloomIntensity * atmoBlurPulse))
            atmoCtx.opacity = atmoOpacity
            let atmoRect    = CGRect(
                x:      barMinX - 2,
                y:      barMidY - atmoSpread / 2 - 3,
                width:  fillWidth + 4,
                height: atmoSpread
            )
            atmoCtx.fill(
                Path(roundedRect: atmoRect, cornerRadius: atmoSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.40),   // VQ-03: anchors left end
                        AppColors.orangeDeep.opacity(0.55),
                        AppColors.magenta.opacity(0.50),       // VQ-04: was 0.80
                        AppColors.orangeDeep.opacity(0.55),
                        AppColors.orangeDeep.opacity(0.30)
                    ] : [
                        AppColors.cyan.opacity(0.35),          // VQ-03: anchors cyan end
                        AppColors.purple.opacity(0.60),
                        AppColors.magenta.opacity(0.70),       // VQ-04: was 0.80
                        AppColors.purple.opacity(0.60),
                        AppColors.purple.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: atmoRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: atmoRect.maxX, y: barMidY)
                )
            )

            // ── Layer 2: Mid halo ──────────────────────────────────────────
            // VQ-05: light mode center stop orangeHot 0.90→0.65.

            let midSpread  = barHeight * (midSpreadBase + breatheIntensity * midSpreadPulse)
            let midOpacity = midOpacityBase + breatheIntensity * midOpacityPulse
            var midCtx     = ctx
            midCtx.addFilter(.blur(radius: midBlurBase + bloomIntensity * midBlurPulse))
            midCtx.opacity = midOpacity
            let midRect    = CGRect(
                x:      barMinX - 4,
                y:      barMidY - midSpread / 2 - 2,
                width:  fillWidth + 8,
                height: midSpread
            )
            midCtx.fill(
                Path(roundedRect: midRect, cornerRadius: midSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.18),
                        AppColors.orangeDeep.opacity(0.50),
                        AppColors.orangeHot.opacity(0.65),     // VQ-05: was 0.90
                        AppColors.magenta.opacity(0.60),
                        AppColors.magenta.opacity(0.30)
                    ] : [
                        AppColors.cyan.opacity(0.18),
                        AppColors.cyan.opacity(0.50),
                        AppColors.purple.opacity(0.90),
                        AppColors.magenta.opacity(0.60),
                        AppColors.magenta.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: midRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: midRect.maxX, y: barMidY)
                )
            )

            // ── Layer 1: Tight core ────────────────────────────────────────
            // VQ-06: coreOpacityBase for dark passed in as 0.38 (was 0.50).
            //        This stops the core layer competing with the fill surface.

            let coreSpread  = barHeight * (coreSpreadBase + breatheIntensity * coreSpreadPulse)
            let coreOpacity = coreOpacityBase + breatheIntensity * coreOpacityPulse
            var coreCtx     = ctx
            coreCtx.addFilter(.blur(radius: coreBlurBase + bloomIntensity * coreBlurPulse))
            coreCtx.opacity = coreOpacity
            let coreRect    = CGRect(
                x:      barMinX - 3,
                y:      barMidY - coreSpread / 2 - 1,
                width:  fillWidth + 6,
                height: coreSpread
            )
            coreCtx.fill(
                Path(roundedRect: coreRect, cornerRadius: coreSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.25),
                        AppColors.orangeHot.opacity(0.90),
                        AppColors.orangeHot.opacity(0.80),
                        AppColors.magenta.opacity(0.90),
                        AppColors.magenta.opacity(0.65)
                    ] : [
                        AppColors.cyan.opacity(0.25),
                        AppColors.cyan.opacity(0.90),
                        AppColors.purple.opacity(0.80),
                        AppColors.magenta.opacity(0.90),
                        AppColors.magenta.opacity(0.65)
                    ]),
                    startPoint: CGPoint(x: coreRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: coreRect.maxX, y: barMidY)
                )
            )

            // ── Particles ──────────────────────────────────────────────────
            // LIGHT-04: color arrays branched on isLight.
            // VQ-18: particleOpacityScale handles overall light/dark scaling.

            let particleDefs: [(Color, CGFloat, Double)] = isLight ? [
                (AppColors.orangeHot,  0.08, 0.0),
                (AppColors.orangeDeep, 0.42, 0.6),
                (AppColors.magenta,    0.72, 1.2),
                (AppColors.orangeHot,  0.90, 0.3),
                (AppColors.magenta,    0.22, 0.95),
                (AppColors.orangeDeep, 0.55, 0.65),
            ] : [
                (AppColors.cyan,    0.08, 0.0),
                (AppColors.purple,  0.42, 0.6),
                (AppColors.magenta, 0.72, 1.2),
                (AppColors.cyan,    0.90, 0.3),
                (AppColors.magenta, 0.22, 0.95),
                (AppColors.purple,  0.55, 0.65),
            ]

            // VQ-18: particleOpacityScale passed in; 0.65 light, 1.0 dark.
            let dotOpacityMultiplier:  CGFloat = 0.90 * particleOpacityScale
            let haloOpacityMultiplier: CGFloat = 0.53 * particleOpacityScale

            let cycleDuration = CGFloat(shimmerCycleDuration)

            for (index, (color, xRatio, delay)) in particleDefs.enumerated() {
                let offsetElapsed = max(0, elapsed - CGFloat(delay))
                let phase: CGFloat = cycleDuration > 0
                    ? offsetElapsed.truncatingRemainder(
                        dividingBy: cycleDuration
                    ) / cycleDuration
                    : 0

                // VQ-16: fade-in window tightened 0–20% → 0–15% of cycle.
                //        At 3.0s this is 0.45s fade-in vs previous 0.72s,
                //        keeping it below the 300ms attention-capture threshold
                //        while still feeling smooth at 30fps.
                let pOpacity: CGFloat = phase < 0.15          // VQ-16: was 0.20
                    ? phase / 0.15                             // VQ-16: was / 0.20
                    : 1.0 - ((phase - 0.15) / 0.85)           // VQ-16: was (phase-0.20)/0.80
                guard pOpacity > 0.01 else { continue }

                let i = CGFloat(index)

                // VQ-12: rise height base 10 → 14pt, variation ±3 → ±5pt.
                //        Range was 7–13pt (barely clears bloom halo at 4pt bar).
                //        New range 9–19pt gives particles room to read distinctly.
                let riseHeight:  CGFloat = 14 + sin(i * 1.3) * 5   // VQ-12: was 10 + sin(i×1.3)×3

                // VQ-13: easeExp base 2.0 → 2.2, variation ±0.5 → ±0.9.
                //        New range [1.3, 3.1] vs old [1.5, 2.5].
                //        Wider spread creates visible arc-vs-drift character
                //        diversity — fast-arcing vs slow-drifting particles.
                let easeExp:     CGFloat = 2.2 + cos(i * 0.9) * 0.9   // VQ-13: was 2.0 + cos(i×0.9)×0.5

                // VQ-14: drift frequency 2.1 → 1.8 per index.
                //        Previous spacing clustered two particles at similar
                //        rightward drift. 1.8 produces better angular spread.
                let driftAmount: CGFloat = sin(i * 1.8) * 5    // VQ-14: was sin(i×2.1)×5

                // VQ-15: wobble amplitude easeOut×2 → easeOut×3.5.
                //        2pt max lateral movement was sub-perceptual on screen.
                //        3.5pt is clearly readable as organic sway.
                let wobbleFreq:  CGFloat = 2.5 + cos(i * 1.7) * 1.0

                let easeOut = 1.0 - pow(1.0 - phase, easeExp)

                // VQ-17: Y origin shifted to bar top surface (barTopY).
                //        Previously barMidY caused particles to appear to
                //        launch from inside the fill rather than off the surface.
                let yPos    = barTopY - easeOut * riseHeight    // VQ-17: was barMidY - easeOut×riseHeight
                let wobble  = sin(phase * .pi * wobbleFreq) * easeOut * 3.5   // VQ-15: was easeOut×2
                let xPos    = barMinX
                    + fillWidth * xRatio
                    + phase * driftAmount
                    + wobble

                // Three concentric ellipses — never .radialGradient
                let haloSizes: [(scale: Double, opacity: Double)] = [
                    (1.0,  Double(pOpacity * haloOpacityMultiplier) * 0.36),
                    (0.60, Double(pOpacity * haloOpacityMultiplier) * 0.22),
                    (0.32, Double(pOpacity * haloOpacityMultiplier) * 0.34),
                ]
                let glowRadius: CGFloat = 2.0
                for halo in haloSizes {
                    let hr = glowRadius * halo.scale
                    var haloCtx = ctx
                    haloCtx.opacity = halo.opacity
                    haloCtx.fill(
                        Path(ellipseIn: CGRect(
                            x: xPos - hr, y: yPos - hr,
                            width: hr * 2, height: hr * 2
                        )),
                        with: .color(color)
                    )
                }

                // 2×2pt dot
                var dotCtx = ctx
                dotCtx.opacity = Double(pOpacity * dotOpacityMultiplier)
                dotCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: xPos - 1, y: yPos - 1,
                        width: 2,    height: 2
                    )),
                    with: .color(color)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Dark — default") {
    PreviewContent().preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    PreviewContent().preferredColorScheme(.light)
}

#Preview("Reduce Motion") {
    PreviewContent()
        .preferredColorScheme(.dark)
}

#Preview("RTL Layout") {
    PreviewContent()
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("RTL Light Mode") {
    PreviewContent()
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview Content
// ─────────────────────────────────────────────────────────────────────────────

private struct PreviewContent: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    sectionHeader("SOLO · COUPLE  (6 steps)")
                    stepGroup(total: 6)

                    sectionHeader("JUST BROWSING  (5 steps)")
                    stepGroup(total: 5)

                    sectionHeader("EDGE CASES")

                    edgeRow("Step 0 of 6  (empty bar)") {
                        OnboardingProgressBar(
                            currentStep: 0,
                            totalSteps:  6
                        )
                    }
                    edgeRow("Step 6 of 6  (full, no bloom)") {
                        OnboardingProgressBar(
                            currentStep: 6,
                            totalSteps:  6
                        )
                    }
                    edgeRow("Step 6 of 6  (full + bloom)") {
                        OnboardingProgressBar(
                            currentStep:          6,
                            totalSteps:           6,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Step 1 of 1  (single step + bloom)") {
                        OnboardingProgressBar(
                            currentStep:          1,
                            totalSteps:           1,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Narrow  (width: 60)") {
                        OnboardingProgressBar(
                            currentStep: 3,
                            totalSteps:  6,
                            totalWidth:  60
                        )
                    }
                    edgeRow("Tall  (height: 8)") {
                        OnboardingProgressBar(
                            currentStep: 4,
                            totalSteps:  6,
                            barHeight:   8
                        )
                    }
                }
                .padding(.vertical, 48)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .foregroundStyle(AppColors.textTertiary)
            .tracking(2)
            .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func stepGroup(total: Int) -> some View {
        VStack(spacing: 20) {
            ForEach(1...total, id: \.self) { step in
                OnboardingProgressBar(
                    currentStep:          step,
                    totalSteps:           total,
                    showCompletionEffect: step == total
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func edgeRow<C: View>(
        _ label: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 24)
            content()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/OrbitIndicator.swift` {#file-open-lightly-design-components-progress-orbitindicator-swift}

```swift
// OrbitIndicator.swift
// Open Lightly
//
// Reusable orbit state indicator — extracted from OnboardingBuildingPathView.
// Used anywhere a three-state (pending → processing → complete) loading flow
// requires visual feedback with an animated comet tail orbit.
//
// USAGE
//
// Basic:
//   OrbitIndicator(state: .processing)
//   OrbitIndicator(state: .complete)
//   OrbitIndicator(state: .pending, size: 32)
//
// Driven by external state:
//   @State private var loadState: OrbitIndicatorState = .pending
//   OrbitIndicator(state: loadState)
//
// In a list row (matches OnboardingBuildingPathView pattern):
//   HStack(spacing: 14) {
//       OrbitIndicator(state: rowState)
//           .fixedSize()
//       VStack(alignment: .leading) { ... }
//   }
//
// Sizes:
//   22pt — default, matches onboarding build list
//   32pt — medium, standalone loading state
//   44pt — large, full-screen loading indicator
//
// Accessibility:
//   Wrap in an accessibilityElement with a dynamic label:
//   .accessibilityLabel(state == .complete ? "Complete" : "Loading")
//   .accessibilityAddTraits(state == .complete ? .isStaticText : [])
//
// ANIMATION NOTES
//
// BUG-3 FIX (OrbitIndicator): _OrbitCanvas previously used
// GraphicsContext.Shading.radialGradient for the spark head.
// That shading is silently discarded by the Xcode preview canvas
// renderer, making the spark invisible in previews. The spark now
// uses .color(opacity:) shading — identical to BPOrbitCanvas —
// which renders correctly in both the simulator and the preview canvas.

import SwiftUI

// MARK: - State Enum

/// Three-state indicator lifecycle.
public enum OrbitIndicatorState: Equatable {
    case pending      // static ring — zero GPU cost
    case processing   // animated comet orbit
    case complete     // gradient fill + glow, orbit dissolves
}

// MARK: - Public View

/// Reusable orbit state indicator for three-state async flows.
///
/// Animates smoothly between pending (static ring), processing (comet orbit),
/// and complete (gradient fill + glow). Uses the project's dark mode color spectrum
/// (cyan → purple → magenta) and follows PillBorder.swift's TimelineView + Canvas architecture.
/// All colors derived from AppColors tokens.
public struct OrbitIndicator: View {
    public let state: OrbitIndicatorState
    public var size: CGFloat = 22
    
    @State private var sheenOffset: CGFloat = -1.5
    @State private var sheenAnimating: Bool = false

    public init(
        state: OrbitIndicatorState,
        size: CGFloat = 22
    ) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            // LAYER 1 — Pending ring
            Circle()
                .strokeBorder(AppColors.border, lineWidth: 1.5)
                .opacity(state == .pending ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: state == .pending)

            // LAYER 2 — Orbit canvas
            //
            // Wrapped in withAnimation context at call sites so the
            // .transition(.opacity) fires correctly when state changes.
            if state == .processing {
                _OrbitCanvas(size: size)
                    .transition(.opacity)
            }

            // LAYER 3 — Complete fill
            // Dark mode spectrum: cyan → purple → magenta
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .opacity(state == .complete ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.6),
                    value: state == .complete
                )

            // LAYER 4 — Complete glow
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .shadow(
                        color: AppColors.glowCyan,
                        radius: 5,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.glowMagenta,
                        radius: 11,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.purple.opacity(0.13),
                        radius: 18,
                        x: 0, y: 0
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6),
                        value: state == .complete
                    )
            }

            // LAYER 5 — Holographic sheen (complete state only)
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                    location: 0.00),
                                .init(color: .clear,                    location: 0.25),
                                .init(color: Color.white.opacity(0.35), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.45),
                                .init(color: .clear,                    location: 0.55),
                                .init(color: Color.white.opacity(0.20), location: 0.65),
                                .init(color: .clear,                    location: 0.72),
                                .init(color: .clear,                    location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y: 1.0),
                            endPoint:   UnitPoint(x: 1.1,  y: -0.25)
                        )
                        // Scale the sweep to the circle diameter.
                        // StatView uses 320pt for a ~140pt text block (2.3× ratio).
                        // A 22pt circle uses 50pt sweep for the same visual ratio.
                        .frame(width: size * 2.5)
                        .offset(x: sheenOffset * (size * 2.5))
                        .mask { Circle() }
                    }
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !sheenAnimating else { return }
                        sheenAnimating = true
                        withAnimation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true)
                        ) {
                            sheenOffset = 1.5
                        }
                    }
                    .onDisappear {
                        sheenAnimating = false
                        sheenOffset = -1.5
                    }
            }
        }
        .frame(width: size, height: size)
        .onChange(of: state) { _, newState in
            if newState != .complete {
                sheenAnimating = false
                sheenOffset = -1.5
            }
        }
    }
}

// MARK: - Private Orbit Canvas

/// TimelineView + Canvas orbit renderer.
/// Draws a 28-dot comet tail orbiting the circle perimeter with a
/// spark head using flat-color opacity shading.
///
/// Architecture mirrors PillBorder.swift: conditional mounting,
/// TimelineView(.animation) for frame-perfect timing, Canvas for
/// direct GPU drawing.
///
/// BUG-3 FIX: spark head previously used radialGradient shading, which
/// the Xcode preview canvas renderer silently discards, making the spark
/// invisible in previews. Now uses .color(opacity:) — matching
/// BPOrbitCanvas — which renders correctly everywhere.
///
/// Color: Dark mode only — comet trail lerps cyan → purple → magenta.
/// RGB components resolved dynamically from AppColors tokens via UIColor.
private struct _OrbitCanvas: View {
    let size: CGFloat

    private let revolutionDuration: TimeInterval = 1.4

    // Pre-resolved RGB triples for the three anchor colors.
    // Dark mode: cyan → purple → magenta spectrum
    private var primaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.cyan)
    }
    private var secondaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.purple)
    }
    private var tertiaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.magenta)
    }

    // Spark head colors — dark mode only
    // BUG-3 FIX: used as .color(opacity:) shading in Canvas,
    // NOT as radialGradient shading (which breaks in preview renderer).
    private let sparkOuter: Color = AppColors.magenta
    private let sparkInner: Color = AppColors.cyan

    var body: some View {
        // Capture resolved values before entering Canvas closure.
        // Canvas closures have no Environment access.
        let pRGB        = primaryRGB
        let sRGB        = secondaryRGB
        let tRGB        = tertiaryRGB
        let outer       = sparkOuter
        let inner       = sparkInner
        let borderColor: Color = AppColors.borderHover

        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: revolutionDuration)
                let progress = elapsed / revolutionDuration
                drawOrbit(
                    context:     context,
                    size:        canvasSize,
                    progress:    progress,
                    pRGB:        pRGB,
                    sRGB:        sRGB,
                    tRGB:        tRGB,
                    sparkOuter:  outer,
                    sparkInner:  inner,
                    borderColor: borderColor
                )
            }
            .frame(width: size, height: size)
        }
    }

    private func drawOrbit(
        context:     GraphicsContext,
        size:        CGSize,
        progress:    Double,
        pRGB:        (r: Double, g: Double, b: Double),
        sRGB:        (r: Double, g: Double, b: Double),
        tRGB:        (r: Double, g: Double, b: Double),
        sparkOuter:  Color,
        sparkInner:  Color,
        borderColor: Color
    ) {
        let cx     = size.width  / 2
        let cy     = size.height / 2
        let radius = size.width  / 2 - 2.0
        let steps  = 28

        let headAngle = progress * .pi * 2 - .pi / 2
        let tailArc   = Double.pi * 0.88

        // Border ring
        var borderPath = Path()
        borderPath.addEllipse(in: CGRect(
            x: cx - radius, y: cy - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(borderPath, with: .color(borderColor), lineWidth: 1.5)

        // Trailing dot loop — lerps across three anchor colors
        for i in 0..<steps {
            let t         = Double(i) / Double(steps - 1)
            let dotAngle  = headAngle - tailArc * (1.0 - t)
            let x         = cx + cos(dotAngle) * radius
            let y         = cy + sin(dotAngle) * radius
            let alpha     = t * 0.58
            let dotRadius = 0.9 + t * 0.65

            // Lerp between the three anchor colors:
            //   t < 0.40 → primary → secondary
            //   t ≥ 0.40 → secondary → tertiary
            let color: Color
            if t < 0.4 {
                let blend = t / 0.4
                color = Color(
                    red:   lerp(pRGB.r, sRGB.r, blend),
                    green: lerp(pRGB.g, sRGB.g, blend),
                    blue:  lerp(pRGB.b, sRGB.b, blend)
                )
            } else {
                let blend = (t - 0.4) / 0.6
                color = Color(
                    red:   lerp(sRGB.r, tRGB.r, blend),
                    green: lerp(sRGB.g, tRGB.g, blend),
                    blue:  lerp(sRGB.b, tRGB.b, blend)
                )
            }

            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: x - dotRadius, y: y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(color.opacity(alpha)))
        }

        // Spark head — three flat-color opacity layers.
        //
        // BUG-3 FIX: previously used GraphicsContext.Shading.radialGradient,
        // which is silently discarded by the Xcode preview canvas renderer,
        // making the spark invisible in previews. Now uses .color(opacity:)
        // shading — identical to BPOrbitCanvas — which renders correctly in
        // both the simulator and the Xcode preview canvas.
        let hx = cx + cos(headAngle) * radius
        let hy = cy + sin(headAngle) * radius

        // Outer glow — tertiary accent, large halo
        var outerPath = Path()
        outerPath.addEllipse(in: CGRect(
            x: hx - 5.5, y: hy - 5.5,
            width: 11, height: 11
        ))
        context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

        // Inner glow — primary accent, tighter focus
        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(
            x: hx - 3, y: hy - 3,
            width: 6, height: 6
        ))
        context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

        // Core — white focal point
        var corePath = Path()
        corePath.addEllipse(in: CGRect(
            x: hx - 1.8, y: hy - 1.8,
            width: 3.6, height: 3.6
        ))
        context.fill(corePath, with: .color(.white.opacity(0.96)))
    }

    // MARK: - Helpers

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    /// Resolve a SwiftUI Color to RGB components via UIColor.
    /// Bridges AppColors tokens into the Canvas rendering path.
    private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Previews
//
// BUG-4 FIX: previews now include a live cycling variant that drives
// OrbitIndicator through all three states on a loop. A purely static
// preview that never invalidates can pause the TimelineView(.animation)
// scheduler. The cycling preview keeps the host view alive and redrawing,
// which ensures TimelineView fires continuously.
//
// The static grid previews are retained for quick visual inspection of
// all sizes and both color schemes.

#Preview("Dark Mode — Static Grid") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.textTertiary)

                // ── Three states at default size (22pt) ──────────────
                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at medium size (32pt) ───────────────
                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at large size (44pt) ────────────────
                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── In-row context ────────────────────────────────────
                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
    }
    .preferredColorScheme(.dark)
}

// BUG-4 FIX: Live cycling preview.
//
// Drives a single OrbitIndicator through pending → processing → complete
// on a repeating loop. This keeps the host view alive and continuously
// invalidating, which ensures TimelineView(.animation) fires every frame.
// Use this preview to verify the comet orbit and complete-fill transitions.
#Preview("Dark Mode — Live Cycle") {
    // State sequence: pending(1.0s) → processing(2.5s) → complete(1.5s) → repeat
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1   // 0=22pt, 1=32pt, 2=44pt
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.textTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.textTertiary)
                .animation(.none, value: cycleState)

            // Size picker
            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.cyan
                            : AppColors.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.cardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.dark)
    .task {
        // Loop: pending → processing → complete → pending …
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}

#Preview("Light Mode — Static Grid") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.lightTextTertiary)

                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.lightTextPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.lightCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Light Mode — Live Cycle") {
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.lightTextTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.lightTextTertiary)
                .animation(.none, value: cycleState)

            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.purple
                            : AppColors.lightTextTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.lightCardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.light)
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Buttons/HoloCTAButton.swift` {#file-open-lightly-design-components-buttons-holoctabutton-swift}

```swift
// HoloCTAButton.swift
// Open Lightly
//
// Single shared CTA button used across all onboarding screens.
// Supports dark mode (spectrum glow) and light mode (warm aurora).
//
// Dark:  cardBg fill + HolographicShimmer + pillBorder + bloom glow
// Light: lightFrostCTA fill + LightModeShimmer + warmAuroraBorder
//        + shadow spread (shadow IS the glow on cream)
//        + no behind-bloom (invisible on light surfaces)

import SwiftUI

struct HoloCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var cornerRadius: CGFloat = 100
    var height: CGFloat = 56
    var lightModeGradient: LinearGradient? = nil

    @Environment(\.colorScheme) private var colorScheme

    // Dark mode color locals — unchanged
    private let cyan    = AppColors.cyan
    private let purple  = AppColors.purple
    private let magenta = AppColors.magenta
    private let pink    = AppColors.pink
    private let ctaBG   = AppColors.cardBg

    @State private var glowPulse:  Bool   = false

    // Convenience
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }, label: {
            ZStack {

                // ── Behind-glow bloom — DARK ONLY ──────────────────
                // Invisible on cream — skipped entirely in light mode.
                if !isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: [cyan.opacity(0.22), purple.opacity(0.18), magenta.opacity(0.14)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(height: 34)
                        .blur(radius: 36)
                        .offset(y: 10)
                        .opacity(glowPulse ? 1.0 : 0.65)
                        .allowsHitTesting(false)
                }

                // ── Pill face ───────────────────────────────────────
                ZStack {
                    // Base fill
                    // FILL-FIX: lightFrostCTA was near-white — at 0.45 disabled
                    // opacity the shimmer's pink washed out entirely.
                    // lightCTAFill is opaque rose so the button reads correctly
                    // at both 1.0 (enabled) and 0.45 (disabled) opacity.
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isLight ? AppColors.lightCTAFill : ctaBG)

                    // Shimmer — warm aurora on light, spectrum on dark
                    if isLight {
                        LightModeShimmer(duration: 8)
                    } else {
                        HolographicShimmer(duration: 6)
                            .opacity(0.50)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                // Single clipShape clips base + shimmer cleanly
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // ── Border ─────────────────────────────────────────
                // Dark:  .pillBorder()         — cyan → purple → magenta + glow blur
                // Light: .warmAuroraBorder()   — purple → magenta → gold + shadow spread
                // Both called AFTER clipShape so border sits on the edge, not inside
                .if(isLight) { view in
                    view.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
                }
                .if(!isLight) { view in
                    view.pillBorder(cornerRadius: cornerRadius)
                }
                // Structural visuals always render at full intensity.
                // Disabled dimming handled by outermost container opacity.

                // ── Ambient glow shadows ───────────────────────────
                // Dark:  cyan/purple/magenta glow ring, pulses with glowPulse
                // Light: shadow spread is already handled inside warmAuroraBorder.
                //        These additional shadows deepen the lift on cream.
                if isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: AppColors.magenta.opacity(glowPulse ? 0.22 : 0.14), radius: 10, x: 0, y: 4)
                        .shadow(color: AppColors.purple.opacity(glowPulse ? 0.16 : 0.10),  radius: 20, x: 0, y: 6)
                        .shadow(color: AppColors.gold.opacity(glowPulse ? 0.10 : 0.05),    radius: 8,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: cyan.opacity(glowPulse ? 0.28 : 0.18),    radius: 10, x: 0, y: 0)
                        .shadow(color: purple.opacity(glowPulse ? 0.22 : 0.14),  radius: 18, x: 0, y: 0)
                        .shadow(color: magenta.opacity(glowPulse ? 0.16 : 0.10), radius: 28, x: 0, y: 0)
                }

                // ── Label ──────────────────────────────────────────
                // Dark:  white
                // Light: lightTextPrimary (#1A1A1E) — white on cream is invisible
                //        Or custom gradient if lightModeGradient is provided
                Text(title)
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(
                        isLight && lightModeGradient != nil
                            ? AnyShapeStyle(lightModeGradient!)
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : Color.white)
                    )
            }
            .frame(height: height)
            .overlay {
                GeometryReader { geo in
                    OrbitSparkBorderView(
                        size:         geo.size,
                        cornerRadius: 28,
                        borderWidth:  3,
                        colorScheme:  colorScheme
                    )
                    .allowsHitTesting(false)
                    .opacity(isEnabled ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: isEnabled)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        })
        .buttonStyle(.plain)
        // CONTRAST-FIX: scale + spring makes enabled state snap.
        // 0.98 shrink on disabled reads as "not ready" instantly.
        // Spring on enable feels like the button inflates to life.
        .opacity(isEnabled ? 1.0 : 0.42)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75),
            value: isEnabled
        )
        .allowsHitTesting(isEnabled)
        .onAppear {
            // Glow pulse — shadow breathing for both modes
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct CTABorderModifier: ViewModifier {
    let isLight: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            content.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
        } else {
            content.pillBorder(cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Previews

#Preview("HoloCTA Dark — enabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Dark — disabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Light — enabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

#Preview("HoloCTA Light — disabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Buttons/SelectablePill.swift` {#file-open-lightly-design-components-buttons-selectablepill-swift}

```swift
// Design/Components/Buttons/SelectablePill.swift
// Open Lightly
//
// Supports dark mode (spectrum glow + flame aura) and
// light mode (warm aurora border + shadow spread).
//
// Dark:  surfaceBg fill + HolographicShimmer + flame aura + spectrum shadows
// Light: lightFrostPill fill + LightModeShimmer + warmAuroraBorder + shadow spread
//        Flame aura skipped — glow is invisible on cream, shadow spread replaces it

import SwiftUI

struct SelectablePill: View {

    enum Intensity: CGFloat {
        case dim   = 0.15
        case warm  = 0.5
        case alive = 1.0
    }

    let label: String
    let isSelected: Bool
    var intensity: Intensity = .warm
    var height: CGFloat = 46
    var fontSize: CGFloat = 15
    var showFlame: Bool = true
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // ─────────────────────────────────────────────
    // MARK: Dark mode computed properties — unchanged
    // ─────────────────────────────────────────────

    private var shimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.22
            case .warm:  return 0.38
            case .alive: return 0.46
            }
        }
    }

    private var shimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6
        case .warm:  return 4
        case .alive: return 3.5
        }
    }
    
    private var lightShimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6.0
        case .warm:  return 4.0
        case .alive: return 3.5
        }
    }

    private var borderWidth: CGFloat {
        guard isSelected else { return 1.5 }
        switch intensity {
        case .dim:   return 1.5
        case .warm:  return 2.0
        case .alive: return 2.5
        }
    }

    private var borderColor: Color {
        guard isSelected else { return AppColors.borderHover }
        switch intensity {
        case .dim:   return Color.white.opacity(0.12)
        case .warm:  return Color.white.opacity(0.22)
        case .alive: return Color.white.opacity(0.25)
        }
    }

    private var flameFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 90
        case .alive: return 120
        }
    }

    private var lightBloomFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Light mode computed properties
    // ─────────────────────────────────────────────
    private var lightShimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.10
            case .warm:  return 0.16
            case .alive: return 0.22
            }
        }
    }

    /// Light mode border opacity — higher than dark because no glow
    /// canvas to boost the visual weight of the border.
    private var lightBorderOpacity: Double {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.78
            case .alive: return 0.90
            }
        } else {
            return 0.40
        }
    }

    /// Light mode border line width — matches warmAuroraBorder defaults.
    private var lightBorderWidth: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 1.5
            case .warm:  return 2.5
            case .alive: return 3.0
            }
        } else {
            return 1.5
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Body
    // ─────────────────────────────────────────────

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            pillContent
                .modifier(PillShadowModifier(
                    isLight: isLight,
                    isSelected: isSelected,
                    intensity: intensity
                ))
                .background(alignment: .bottom) {
                    flameLayer
                }
                .offset(y: isLight && isSelected ? -1 : 0)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var pillContent: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(isLight ? AppColors.wineDark : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isLight
                ? (isSelected
                    ? AppColors.lightFrostPillSel
                    : AppColors.lightFrostPill)   // FIX: was lightSurfaceBg (#F2EFE6)
                                                   // which is near-identical to lightPageBg.
                                                   // lightFrostPill is visibly lavender-tinted
                                                   // so the shimmer has a tinted base to sweep
                                                   // over — same role surfaceBg plays in dark.
                : AppColors.surfaceBg)
            .overlay {
                if isLight {
                    LightModeShimmer(duration: lightShimmerSpeed, usePillColors: true)
                        .opacity(lightShimmerOpacity)
                        .allowsHitTesting(false)
                } else {
                    HolographicShimmer(duration: shimmerSpeed)
                        .opacity(shimmerOpacity)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(Capsule())
            .modifier(PillBorderModifier(
                isLight: isLight,
                isSelected: isSelected,
                darkBorderColor: borderColor,
                darkBorderWidth: borderWidth,
                lightBorderOpacity: lightBorderOpacity,
                lightBorderWidth: lightBorderWidth
            ))
    }

    @ViewBuilder
    private var flameLayer: some View {
        if isSelected && intensity != .dim && showFlame {
            GeometryReader { geo in
                if isLight {
                    LightAuraBloom(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.15,
                            height: lightBloomFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - lightBloomFrameHeight / 2
                        )
                } else {
                    FlameAura(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.2,
                            height: flameFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - flameFrameHeight / 2
                        )
                }
            }
            .frame(height: isLight ? lightBloomFrameHeight : flameFrameHeight)
            .allowsHitTesting(false)
            .transition(.opacity.animation(.easeIn(duration: 0.4)))
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Helpers — unchanged from original
    // ─────────────────────────────────────────────

    private var labelColor: Color {
        if isLight {
            return AppColors.wineDark   // selected and unselected both deep wine on cream
        } else {
            return .white
        }
    }

    private func glowColor(_ base: Color, _ dimAlpha: CGFloat, _ warmAlpha: CGFloat, _ aliveAlpha: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(dimAlpha)
        case .warm:  return base.opacity(warmAlpha)
        case .alive: return base.opacity(aliveAlpha)
        }
    }

    private func pick(_ dim: CGFloat, _ warm: CGFloat, _ alive: CGFloat) -> CGFloat {
        switch intensity {
        case .dim:   return dim
        case .warm:  return warm
        case .alive: return alive
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillBorderModifier
// Handles the dark/light border split cleanly
// without .if() helper to avoid redeclaration.
// ─────────────────────────────────────────────

private struct PillBorderModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let darkBorderColor: Color
    let darkBorderWidth: CGFloat
    let lightBorderOpacity: Double
    let lightBorderWidth: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            if isSelected {
                // Selected light — magenta-gold gradient border
                content
                    .magentaGoldBorder(
                        cornerRadius: 100,
                        lineWidth: lightBorderWidth,
                        glowRadius: 6,
                        opacity: lightBorderOpacity
                    )
            } else {
                content.overlay(
                    Capsule().strokeBorder(
                        AppColors.lightBorderHover,
                        lineWidth: 1.5
                    )
                )
            }
        } else {
            // Dark — spectrum pillBorder when selected; subtle plain stroke when not
            if isSelected {
                content.pillBorder(cornerRadius: 100, lineWidth: darkBorderWidth, glowRadius: 5, opacity: 0.85)
            } else {
                content.overlay(
                    Capsule().strokeBorder(darkBorderColor, lineWidth: darkBorderWidth)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillShadowModifier
// Dark: spectrum glow ring
// Light: warm aurora shadow spread
// ─────────────────────────────────────────────

private struct PillShadowModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let intensity: SelectablePill.Intensity

    func body(content: Content) -> some View {
        if isLight {
            // Shadow spread — opacity scales with intensity
            let base: Double = isSelected ? 1.0 : 0.0
            content
                .shadow(color: AppColors.lightShadowMagenta.opacity(base * magentaScale),
                        radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple.opacity(base * purpleScale),
                        radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold.opacity(base * goldScale),
                        radius: 6,  x: 0, y: 2)
        } else {
            // Dark — original spectrum glow ring, unchanged
            content
                .shadow(color: isSelected ? glowColor(AppColors.purple,  0.20, 0.25, 0.34) : .clear,
                        radius: pick(6,  12, 14))
                .shadow(color: isSelected ? glowColor(AppColors.cyan,    0.0,  0.15, 0.30) : .clear,
                        radius: pick(0,  16, 28))
                .shadow(color: isSelected ? glowColor(AppColors.magenta, 0.0,  0.08, 0.25) : .clear,
                        radius: pick(0,  8,  45))
                .shadow(color: isSelected ? glowColor(AppColors.pink,    0.0,  0.0,  0.12) : .clear,
                        radius: pick(0,  0,  70))
        }
    }

    // Light shadow intensity scales with pill intensity
    private var magentaScale: Double {
        switch intensity { case .dim: return 0.5; case .warm: return 0.9; case .alive: return 1.0 }
    }
    private var purpleScale: Double {
        switch intensity { case .dim: return 0.4; case .warm: return 0.8; case .alive: return 1.0 }
    }
    private var goldScale: Double {
        switch intensity { case .dim: return 0.3; case .warm: return 0.7; case .alive: return 1.0 }
    }

    // Helpers mirror the original SelectablePill private functions
    private func glowColor(_ base: Color, _ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(d)
        case .warm:  return base.opacity(w)
        case .alive: return base.opacity(a)
        }
    }
    private func pick(_ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> CGFloat {
        switch intensity { case .dim: return d; case .warm: return w; case .alive: return a }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Dark") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Buttons/GradientButton.swift` {#file-open-lightly-design-components-buttons-gradientbutton-swift}

```swift
//
//  GradientButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//
//  ✅ Design system audit — verified March 9, 2026
//

import SwiftUI

struct GradientButton: View {
    @Environment(\.theme) private var t
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(t.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: t.isAmoled
                        ? t.glowCyan.opacity(0.5)
                        : t.magenta.opacity(0.2),
                    radius: t.isAmoled ? 16 : 12,
                    y: t.isAmoled ? 0 : 4
                )
                .shadow(
                    color: t.isAmoled
                        ? t.glowMagenta.opacity(0.3)
                        : .clear,
                    radius: 24,
                    y: 0
                )
        }
        .buttonStyle(.plain)
    }
}

struct GradBadge: View {
    @Environment(\.theme) private var t
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(t.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift` {#file-open-lightly-design-components-cards-atmosphericghostdeck-swift}

```swift
//
//  AtmosphericGhostDeck.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct AtmosphericGhostDeck: View {

    // Static offsets — the two ghost cards behind the main card
    private let ghosts: [(offset: CGSize, rotation: Double, opacity: Double)] = [
        (CGSize(width: 8,  height: -10), -3.5, 0.75),
        (CGSize(width: 16, height: -20), -7.0, 0.55),
    ]

    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false

    let cardSize: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Ghost 1 — furthest back, slower drift
            ghostCard
                .offset(ghosts[0].offset)
                .offset(
                    x: drifting ? 5 : 0,
                    y: drifting ? -6 : 0
                )
                .rotationEffect(.degrees(ghosts[0].rotation + (drifting ? 1.5 : 0)))
                .opacity(colorScheme == .light ? 0.90 : ghosts[0].opacity)
                .animation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )

            // Ghost 2 — closer, slightly faster drift
            ghostCard
                .offset(ghosts[1].offset)
                .offset(
                    x: drifting ? -4 : 0,
                    y: drifting ? -4 : 0
                )
                .rotationEffect(.degrees(ghosts[1].rotation + (drifting ? -1.5 : 0)))
                .opacity(colorScheme == .light ? 0.75 : ghosts[1].opacity)
                .animation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
        }
        .onAppear {
            drifting = true
        }
    }

    private var ghostCard: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            Color(hex: "E8DFD0"),  // warm off-white, clear tan presence
                            Color(hex: "DEDAD0"),  // deeper, closer to the cream background
                          ]
                        : [
                            Color(red: 0.10, green: 0.09, blue: 0.23),  // deep indigo
                            Color(red: 0.07, green: 0.06, blue: 0.18),  // darker indigo
                          ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                )
            )
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.purple.opacity(0.12)  // barely-there border, same family as card border
                            : AppColors.purple.opacity(0.38), // strong on dark
                        lineWidth: 2.5
                    )
            )
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardBackView.swift` {#file-open-lightly-design-components-cards-cardbackview-swift}

```swift
//
//  CardBackView.swift
//  Open Lightly
//

import SwiftUI

struct CardBackView: View {
    let cardSize:            CGSize
    let cornerRadius:        CGFloat
    let selectedPill:        CardRevealPill?
    let selectedScale:       CGFloat
    let selectedBorderWidth: CGFloat
    let unselectedVisible:   Bool
    let revealed:            Bool
    let isLight:             Bool
    let onSelect:            (CardRevealPill) -> Void
    let questionVisible:     Bool
    let pillsVisible:        Bool

    var body: some View {
        ZStack {
            // Base fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cardFill)

            // Ambient wash
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.magenta.opacity(0.06), Color.clear]
                            : [AppColors.purple.opacity(0.15),  Color.clear],
                        center:      UnitPoint(x: 0.7, y: 0.8),
                        startRadius: 0,
                        endRadius:   180
                    )
                )

            // Border
            if isLight {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: selectedBorderWidth)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: selectedBorderWidth)
            }

            VStack(spacing: 0) {
                // Heading
                VStack(spacing: 6) {
                    Text("Something came up.")
                        .font(AppFonts.body(20, weight: .semibold))
                        .foregroundStyle(
                            isLight ? AppColors.lightCardTitle : AppColors.textPrimary
                        )
                        .multilineTextAlignment(.center)

                    Text("What's it closest to?")
                        .font(AppFonts.caption)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle.opacity(0.50)
                                : AppColors.textSecondary
                        )
                }
                .padding(.top, 24)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 6)
                .animation(.easeOut(duration: 0.3), value: revealed)

                Spacer()

                // Pills
                VStack(spacing: 8) {
                    ForEach(
                        Array(CardRevealPill.allCases.enumerated()),
                        id: \.element
                    ) { index, pill in
                        Button {
                            guard selectedPill == nil else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSelect(pill)
                        } label: {
                            Text(pill.rawValue)
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(
                                    selectedPill == pill
                                        ? (isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                                        : (isLight ? AppColors.wineDark : Color.white.opacity(0.75))
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedPill == pill
                                                ? (isLight
                                                    ? AnyShapeStyle(AppColors.lightFrostPillSel)
                                                    : AnyShapeStyle(Color.white.opacity(0.10)))
                                                : (isLight
                                                    ? AnyShapeStyle(AppColors.lightFrostPill)
                                                    : AnyShapeStyle(AppColors.cardBg))
                                        )
                                )
                                .overlay(
                                    Group {
                                        if selectedPill == pill {
                                            if isLight {
                                                Capsule()
                                                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.0)
                                            } else {
                                                Capsule()
                                                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.0)
                                            }
                                        } else {
                                            Capsule()
                                                .strokeBorder(
                                                    isLight ? AppColors.lightBorder : AppColors.border,
                                                    lineWidth: 1.5
                                                )
                                        }
                                    }
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedPill == pill ? selectedScale : 1.0)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.7),
                            value: selectedScale
                        )
                        .opacity({
                            if selectedPill != nil && selectedPill != pill {
                                return unselectedVisible ? 1 : 0
                            }
                            return revealed ? 1 : 0
                        }())
                        .offset(y: revealed ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.3).delay(Double(index) * 0.07 + 0.12),
                            value: revealed
                        )
                        .animation(.easeIn(duration: 0.35), value: unselectedVisible)
                        .disabled(selectedPill != nil && selectedPill != pill)
                        .background(
                            Capsule()
                                .fill(isLight 
                                    ? AppColors.lightFrostPill 
                                    : AppColors.cardBg)
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Text("✦")
                    .font(AppFonts.overline)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextTertiary.opacity(0.5)
                            : AppColors.textTertiary.opacity(0.5)
                    )
                    .opacity(revealed ? 0.6 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: revealed)
                    .padding(.bottom, 24)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .cardShadows(isLight: isLight)
    }

    private var cardFill: some ShapeStyle {
        isLight
            ? AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.99, blue: 1.00),
                    Color(red: 0.98, green: 0.97, blue: 0.99),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.043, blue: 0.122),
                    Color(red: 0.031, green: 0.024, blue: 0.094),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardFrontView.swift` {#file-open-lightly-design-components-cards-cardfrontview-swift}

```swift
//
//  CardFrontView.swift
//  Open Lightly
//

import SwiftUI

struct CardFrontView: View {
   let cardSize:           CGSize
   let cornerRadius:       CGFloat
   let isLight:            Bool
   let arrowTriggered:     Bool
   let sitWithThisVisible: Bool
   let onTap:              () -> Void
   let fuseProgress:       Double
   var questionVisible:    Bool = true
   var pillsVisible:       Bool = false
   var onPillSelected:     ((CardRevealPill) -> Void)? = nil

   var body: some View {
       ZStack {
           // Base fill
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(cardFill)

           // Ambient wash — top-left corner
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(
                   RadialGradient(
                       colors: isLight
                           ? [AppColors.magenta.opacity(0.06), Color.clear]
                           : [AppColors.purple.opacity(0.15),  Color.clear],
                       center:      UnitPoint(x: 0.3, y: 0.2),
                       startRadius: 0,
                       endRadius:   180
                   )
               )

           // Border
           if isLight {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
           } else {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
           }

           // Burn cover — occludes the gradient border with card background
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Consumed segment — paints over the gradient border with the
               // card's own background color, creating the burn illusion.
               // lineWidth is wider than the border (4.0 vs 2.5) so it
               // fully occludes the gradient with no fringing.
               let startOffset: Double = 0.75  // mid-right edge, burns clockwise to top-right almost immediately
               let end = startOffset + fuseProgress

               if end <= 1.0 {
                   // No wrap needed
                   let consumed = path.trimmedPath(from: startOffset, to: end)
                   ctx.stroke(consumed,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               } else {
                   // Wrap — draw two segments
                   let seg1 = path.trimmedPath(from: startOffset, to: 1.0)
                   let seg2 = path.trimmedPath(from: 0, to: end - 1.0)
                   ctx.stroke(seg1,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                   ctx.stroke(seg2,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               }
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

           // Spark head — glowing spark at the burn position
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0, fuseProgress < 1.0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Get the point at the current burn position
               let startOffset: Double = 0.75
               let sparkPos = (startOffset + fuseProgress)
                   .truncatingRemainder(dividingBy: 1.0)
               let head = path.trimmedPath(
                   from: max(0, sparkPos - 0.001),
                   to:   sparkPos)
               guard let pt = head.currentPoint else { return }

               let r = CGFloat(3.5)
               let sparkRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

               // Map spark's actual XY position to diagonal gradient progress.
               // Gradient runs topLeading → bottomTrailing so we average
               // normalized X and Y to get a 0→1 diagonal progress value.
               let gradientT = (pt.x / canvasSize.width * 0.5)
                             + (pt.y / canvasSize.height * 0.5)

               let sparkColor: Color = {
                   let t = max(0, min(1, gradientT))
                   if isLight {
                       // purple(0.0) → magenta(0.5) → gold(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.magenta,
                               to:   AppColors.gold,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   } else {
                       // cyan(0.0) → purple(0.5) → magenta(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.cyan,
                               to:   AppColors.purple,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   }
               }()

               // Outer atmospheric glow
               var outerCtx = ctx
               outerCtx.addFilter(.blur(radius: 6))
               outerCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -4, dy: -4)),
                   with: .color(sparkColor.opacity(0.5))
               )

               // Mid glow
               var midCtx = ctx
               midCtx.addFilter(.blur(radius: 3))
               midCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -1, dy: -1)),
                   with: .color(sparkColor.opacity(0.7))
               )

               // Core
               ctx.fill(
                   Circle().path(in: sparkRect),
                   with: .color(sparkColor)
               )

               // Hot white center
               ctx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: r * 0.45, dy: r * 0.45)),
                   with: .color(.white.opacity(0.95))
               )
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

           VStack(spacing: 16) {
               Text("YOUR FIRST CARD")
                   .font(AppFonts.overline)
                   .tracking(2.0)
                   .foregroundStyle(
                       isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                   )
                   .padding(.top, 20)

               Spacer(minLength: 0)

               ZStack {
                   // Question — dissolves out when pillsVisible becomes true
                   questionTextView
                       .opacity(pillsVisible ? 0 : (questionVisible ? 1 : 0))
                       .offset(y: pillsVisible ? -12 : 0)
                       .animation(.easeInOut(duration: 0.45), value: pillsVisible)

                   // Pills — dissolve in when pillsVisible becomes true
                   if pillsVisible {
                       pillsView
                           .opacity(pillsVisible ? 1 : 0)
                           .offset(y: pillsVisible ? 0 : 12)
                           .animation(.easeOut(duration: 0.4), value: pillsVisible)
                           .transition(.opacity.combined(with: .offset(y: 12)))
                   }
               }

               Spacer(minLength: 0)

               Spacer(minLength: 28)
           }
           // ↓ THIS IS THE FIX — VStack must claim the card's full frame
           // so Spacers have room to distribute. Without this, the ZStack
           // collapses the VStack to its content height and Spacers = 0.
           .frame(width: cardSize.width, height: cardSize.height)
       }
       .cardShadows(isLight: isLight)
       .contentShape(Rectangle())
       .onTapGesture { onTap() }
   }

   // MARK: - Question Text View

   private var questionTextView: some View {
       VStack(spacing: 8) {
           Text("What would you desire if nobody")
               .font(AppFonts.body(19, weight: .semibold))
               .foregroundStyle(
                   isLight ? AppColors.lightCardTitle : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)

           LivingText(
               text: "not even you,",
               font: AppFonts.body(20, weight: .semibold)
           )

           Text("would judge the answer?")
               .font(AppFonts.body(19, weight: .semibold))
               .foregroundStyle(
                   isLight ? AppColors.lightCardTitle : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)
       }
       .padding(.horizontal, 28)
   }

   // MARK: - Pills View

   private var pillsView: some View {
       VStack(spacing: 12) {
           ForEach(CardRevealPill.allCases) { pill in
               Button(action: {
                   onPillSelected?(pill)
               }) {
                   Text(pill.rawValue)
                       .font(AppFonts.body(17, weight: .semibold))
                       .foregroundStyle(AppColors.textPrimary)
                       .frame(maxWidth: .infinity)
                       .frame(height: 44)
                       .background(
                           RoundedRectangle(cornerRadius: 12)
                               .fill(Color.white.opacity(0.08))
                       )
               }
           }
       }
       .padding(.horizontal, 28)
   }

   private var cardFill: some ShapeStyle {
       isLight
           ? AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 1.00, green: 0.99, blue: 1.00),
                   Color(red: 0.98, green: 0.97, blue: 0.99),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
           : AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 0.051, green: 0.043, blue: 0.122),
                   Color(red: 0.031, green: 0.024, blue: 0.094),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
   }

   private func interpolate(from: Color, to: Color, t: Double) -> Color {
       let t = max(0, min(1, t))
       let fromUI = UIColor(from)
       let toUI   = UIColor(to)
       var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
       var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
       fromUI.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
       toUI.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
       return Color(
           red:   Double(r1 + (r2 - r1) * t),
           green: Double(g1 + (g2 - g1) * t),
           blue:  Double(b1 + (b2 - b1) * t),
           opacity: Double(a1 + (a2 - a1) * t)
       )
   }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardLayout.swift` {#file-open-lightly-design-components-cards-cardlayout-swift}

```swift
//
//  CardLayout.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CardLayout.swift
//  Open Lightly
//
//  Single source of truth for card dimensions across the app.
//  All screens that render a card reference these values.
//
//  Standard card: 313 × 438 — poker/bridge aspect ratio (1:1.40)
//  This matches the physical card proportion every user already
//  knows from handling real cards.
//

import CoreGraphics

enum CardLayout {

    // MARK: - Standard card
    // 313pt wide = screen width (393pt) - 80pt margin
    // 438pt tall = 313 × 1.40 (poker/bridge aspect ratio)

    static let width:        CGFloat = 313
    static let height:       CGFloat = 438
    static let cornerRadius: CGFloat = 20

    static let size = CGSize(width: width, height: height)

    // MARK: - Margin
    // How much total horizontal space is removed from screen width.
    // w - horizontalMargin = card width on any device.
    static let horizontalMargin: CGFloat = 80
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardRevealPillButton.swift` {#file-open-lightly-design-components-cards-cardrevealpillbutton-swift}

```swift
//
//  CardRevealPillButton.swift
//  Open Lightly
//

import SwiftUI

struct CardRevealPillButton: View {
   let pill:          CardRevealPill
   let index:         Int
   let selectedPill:  CardRevealPill?
   let selectedScale: CGFloat
   let borderWidth:   CGFloat
   let globalVisible: Bool
   let revealed:      Bool
   let isLight:       Bool
   let onTap:         () -> Void

   @State private var entranceVisible = false

   private var isSelected: Bool { selectedPill == pill }
   private var isOther:    Bool { selectedPill != nil && !isSelected }

   // Heading has a 120ms head-start; pills stagger at 70ms each
   private var entranceDelay: Double { Double(index) * 0.07 + 0.12 }

   var body: some View {
       Button {
           guard selectedPill == nil else { return }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
           onTap()
       } label: {
           Text(pill.rawValue)
               .font(AppFonts.bodyMedium)
               .foregroundStyle(
                   isSelected
                       ? (isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                       : (isLight ? AppColors.wineDark : Color.white.opacity(0.75))
               )
               .frame(maxWidth: .infinity)
               .frame(height: 40)
               .background(pillBackground)
               .overlay(pillBorder)
               .clipShape(Capsule())
       }
       .buttonStyle(.plain)
       // Scale — driven by parent selectedPillScale during beat 1
       .scaleEffect(isSelected ? selectedScale : 1.0)
       .animation(
           .spring(response: 0.35, dampingFraction: 0.7),
           value: selectedScale
       )
       // Entrance stagger — rise from y+10
       .opacity(entranceVisible ? (isOther && !globalVisible ? 0 : 1) : 0)
       .offset(y: entranceVisible ? (isOther && !globalVisible ? 4 : 0) : 10)
       .animation(
           .easeOut(duration: 0.35).delay(entranceDelay),
           value: entranceVisible
       )
       // Beat 3 sink — independent from entrance
       .animation(.easeIn(duration: 0.35), value: globalVisible)
       .disabled(isOther)
       .accessibilityLabel(pill.rawValue)
       .accessibilityAddTraits(isSelected ? .isSelected : [])
       .onChange(of: revealed) { _, newVal in
           if newVal { entranceVisible = true }
       }
       .onAppear {
           if revealed { entranceVisible = true }
       }
   }

   @ViewBuilder
   private var pillBackground: some View {
       Capsule()
           .fill(
               isSelected
                   ? (isLight
                       ? AnyShapeStyle(AppColors.lightFrostPillSel)
                       : AnyShapeStyle(Color.white.opacity(0.10)))
                   : (isLight
                       ? AnyShapeStyle(AppColors.lightFrostPill)
                       : AnyShapeStyle(AppColors.cardBg))
           )
   }

   @ViewBuilder
   private var pillBorder: some View {
       if isSelected {
           if isLight {
               Capsule()
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: borderWidth)
           } else {
               Capsule()
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: borderWidth)
           }
       } else {
           Capsule()
               .strokeBorder(
                   isLight ? AppColors.lightBorder : AppColors.border,
                   lineWidth: 1.5
               )
       }
   }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardShadows.swift` {#file-open-lightly-design-components-cards-cardshadows-swift}

```swift
//
//  CardShadows.swift
//  Open Lightly
//

import SwiftUI

extension View {
    func cardShadows(isLight: Bool) -> some View {
        self
            .shadow(
                color: isLight
                    ? AppColors.purple.opacity(0.10)
                    : AppColors.cyan.opacity(0.14),
                radius: 20
            )
            .shadow(
                color: Color.black.opacity(isLight ? 0.06 : 0.85),
                radius: 25,
                y: 25
            )
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CuriosityCardBack.swift` {#file-open-lightly-design-components-cards-curiositycardback-swift}

```swift
//
//  CuriosityCardBack.swift
//  Open Lightly
//
//  The face-down side of each curiosity picker card.
//  Shows a laser-engraved maze texture with an embedded orbit animation.
//
//  The orbit is rendered inside MazePatternView's GeometryReader so it
//  shares the identical cx/cy coordinate origin as the maze rings.
//
//  isActive: false when the card is face-up — stops TileOrbitView's
//  TimelineView from rendering and prevents bleed-through on the front face.
//

import SwiftUI

struct CuriosityCardBack: View {
    var isActive: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {

            // ── Base fill ─────────────────────────────────────────────
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [
                                Color(red: 0.98, green: 0.97, blue: 0.96),
                                Color(red: 0.95, green: 0.93, blue: 0.91),
                              ]
                            : [
                                Color(red: 0.051, green: 0.043, blue: 0.122),
                                Color(red: 0.031, green: 0.024, blue: 0.094),
                              ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                )

            // ── Ambient center glow ───────────────────────────────────
            RadialGradient(
                colors: [
                    (isLight ? AppColors.orangeHot : AppColors.purple).opacity(
                        isLight ? 0.08 : 0.09
                    ),
                    Color.clear,
                ],
                center:      .center,
                startRadius: 0,
                endRadius:   44
            )
            .clipShape(RoundedRectangle(cornerRadius: CardLayout.cornerRadius))

            // ── Maze + embedded orbit ─────────────────────────────────
            // TileOrbitView lives inside MazePatternView's GeometryReader
            // so both share the exact same cx/cy — guaranteed co-centered.
            MazePatternView(
                color:         isLight ? AppColors.orangeHot : AppColors.magenta,
                opacity:       isLight ? 0.14 : 0.16,
                glowColor:     isLight ? AppColors.orangeHot : .clear,
                glowOpacity:   isLight ? 0.10 : 0.0,
                orbitCount:    3,
                isOrbitActive: isActive
            )
            .padding(10)

            // ── Corner marks ──────────────────────────────────────────
            VStack {
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
                Spacer()
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
            }
            .padding(14)

        } // ZStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: CardLayout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: isLight
                            ? [
                                AppColors.purple.opacity(0.40),
                                AppColors.orangeHot,
                                AppColors.gold,
                              ]
                            : [
                                AppColors.purple,
                                AppColors.cyan,
                                AppColors.magenta,
                              ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .opacity(0.65)
        )
        .shadow(
            color: isLight
                ? AppColors.orangeHot.opacity(0.14)
                : AppColors.purple.opacity(0.20),
            radius: 20
        )
        .shadow(color: Color.black.opacity(0.20), radius: 12, y: 6)
    }

    // MARK: - Corner mark

    private var cornerMark: some View {
        Text("✦")
            .font(AppFonts.overline)
            .foregroundStyle(
                (isLight ? AppColors.orangeHot : AppColors.purple)
                    .opacity(isLight ? 0.55 : 0.45)
            )
    }
}

// MARK: - Previews

#Preview("Dark — active") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityCardBack(isActive: true)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — active") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityCardBack(isActive: true)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — inactive (flipped)") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityCardBack(isActive: false)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Cards/CuriosityFlipCard.swift` {#file-open-lightly-design-components-cards-curiosityflipcard-swift}

```swift
//
//  CuriosityFlipCard.swift
//  Open Lightly
//
//  3D flip container for the curiosity picker cards.
//  Back face: CuriosityCardBack (maze + orbit).
//  Front face: caller-supplied content (pill grid).
//
//  isFlipped = false → back face visible, orbit animating
//  isFlipped = true  → front face visible, orbit stopped
//

import SwiftUI

struct CuriosityFlipCard<Content: View>: View {
    let isFlipped: Bool
    let content:   () -> Content

    var body: some View {
        ZStack {

            // ── Back face ─────────────────────────────────────────────
            // isActive stops TileOrbitView's TimelineView when face-up
            // so the Canvas does not bleed through the front face.
            CuriosityCardBack(isActive: !isFlipped)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .opacity(isFlipped ? 0 : 1)

            // ── Front face ────────────────────────────────────────────
            content()
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isFlipped)
    }
}

// MARK: - Previews

#Preview("Back face") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityFlipCard(isFlipped: false) {
            Color.clear
        }
        .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("Front face") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityFlipCard(isFlipped: true) {
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .fill(Color(red: 0.051, green: 0.043, blue: 0.122))
                .overlay(
                    Text("Front content")
                        .foregroundStyle(AppColors.textPrimary)
                )
        }
        .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Effects/AuroraGlowField.swift` {#file-open-lightly-design-components-effects-auroraglowfield-swift}

```swift
//
//  AuroraGlowField.swift
//  Open Lightly
//
//  Warm Aurora atmospheric blob field for light mode screens.
//  Near-verbatim copy of OnboardingGlowField with warm palette
//  swapped in and opacities raised ~1.8–2.2× to compensate
//  for cream (#F8F6EE) absorbing color vs dark (#030305) amplifying it.
//

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Private palette
// File-scoped only. DO NOT add to AppColors.swift.
// ─────────────────────────────────────────────

private extension Color {
    static let auroraOrange  = Color(hex: "E04A10")
    static let auroraWine    = Color(hex: "6B1030")
    static let auroraPink    = Color(hex: "D42060")
    static let auroraWineLo  = Color(hex: "8A1430")
    // CHANGE (v2): Added purple — required for brandView gradient harmony.
    // Purple bridges the gap between wine/pink and gold in the brand palette.
    static let auroraPurple  = Color(hex: "6B28AA")
    // CHANGE (v2): Added gold — brandView uses magenta→orange→gold arc.
    static let auroraGold    = Color(hex: "E8A020")
}

// ─────────────────────────────────────────────
// MARK: Aurora Configuration
// ─────────────────────────────────────────────

struct AuroraConfig: Equatable {
    var topOpacityMult:    Double
    var midOpacityMult:    Double
    var bottomOpacityMult: Double
    var globalOpacity:     Double

    // CHANGE (v2): Added brandView config.
    // Heavy top-right (gold/orange) + strong left (purple/pink) +
    // fading bottom. Mirrors the asymmetric distribution in the mockup.
    // globalOpacity 0.78 — slightly under statView (0.85) because the
    // brand screen has a filament orbit that already contributes color
    // energy. Aurora should be atmospheric, not competing.
    static let brandView = AuroraConfig(
        topOpacityMult:    1.0,
        midOpacityMult:    0.35,
        bottomOpacityMult: 0.70,
        globalOpacity: 0.88
    )

    static let statView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.4,
        bottomOpacityMult: 1.15, globalOpacity: 1.0)

    static let nameView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.1,
        bottomOpacityMult: 1.15, globalOpacity: 0.85)

    static let modeSelectView = AuroraConfig(
        topOpacityMult: 0.1, midOpacityMult: 0.3,
        bottomOpacityMult: 1.15, globalOpacity: 0.90)

    static let contextView = AuroraConfig(
        topOpacityMult: 0.4, midOpacityMult: 0.2,
        bottomOpacityMult: 0.85, globalOpacity: 0.75)

    static let curiosityPickerView = AuroraConfig(
        topOpacityMult: 0.3, midOpacityMult: 0.1,
        bottomOpacityMult: 0.75, globalOpacity: 0.65)

    static let groundRulesView = AuroraConfig(
        topOpacityMult: 0.15, midOpacityMult: 0.2,
        bottomOpacityMult: 1.05, globalOpacity: 0.75)
}

// ─────────────────────────────────────────────
// MARK: Aurora Glow Field
// ─────────────────────────────────────────────

struct AuroraGlowField: View {
    var config: AuroraConfig = .statView

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 9)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 9)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let global = config.globalOpacity

            ZStack {

                // ── Tier 1: Top zone — heavy, asymmetric ──────────────────
                //
                // CHANGE (v2): Was single upper-left orange blob.
                // Now two blobs: dominant gold top-right + strong pink top-left.
                // This matches the mockup's asymmetric top-heavy distribution
                // and introduces gold into the upper field for brandView harmony.

                // Gold — dominant top-right
                blob(.auroraGold, 0.82 * config.topOpacityMult * global, 340, 280, 80, 0)
                    .offset(
                        x: sin(blobPhase[0] * .pi * 2) * 14,
                        y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 10
                    )
                    .position(x: w * 0.78, y: h * 0.14)

                // Pink — strong top-left
                blob(.auroraPink, 0.76 * config.topOpacityMult * global, 280, 240, 72, 1)
                    .offset(
                        x: sin(blobPhase[1] * .pi * 2) * -10,
                        y: sin(blobPhase[1] * .pi * 2 + .pi / 4) * 12
                    )
                    .position(x: w * 0.18, y: h * 0.17)

                // ── Tier 2: Mid zone — supporting, moderate opacity ────────
                //
                // CHANGE (v2): Added purple blob center-right — bridges the
                // wine/pink and gold colors. Was absent in v1 entirely.
                // Wine blob repositioned from center to center-left so the
                // mid zone has left/right color separation rather than one
                // central mass.

                // Purple — center-right (new)
                blob(.auroraPurple, 0.70 * config.midOpacityMult * global, 300, 260, 78, 2)
                    .scaleEffect(
                        blobVisible[2]
                            ? 1 + 0.05 * sin(blobPhase[2] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[2] * .pi * 2) * 8)
                    .position(x: w * 0.80, y: h * 0.36)

                // Wine — center-left (was: center w * 0.50)
                blob(.auroraWine, 0.67 * config.midOpacityMult * global, 320, 280, 78, 3)
                    .scaleEffect(
                        blobVisible[3]
                            ? 1 + 0.06 * sin(blobPhase[3] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[3] * .pi * 2) * 5)
                    .position(x: w * 0.28, y: h * 0.40)

                // Orange — warm mid accent (unchanged position, opacity tuned)
                blob(.auroraOrange, 0.42 * config.midOpacityMult * global, 200, 180, 80, 4)
                    .offset(
                        x: sin(blobPhase[4] * .pi) * 8,
                        y: sin(blobPhase[4] * .pi) * -6
                    )
                    .position(x: w * 0.55, y: h * 0.50)

                // ── Tier 3: Lower zone — faint, wide ──────────────────────
                //
                // CHANGE (v2): WineLo blob repositioned from w*0.18 h*0.60
                // to w*0.22 h*0.64 — slightly more centered so the lower
                // field doesn't feel left-only.
                // Floor wash y moved from h*0.80 → h*0.86 for brandView
                // so it doesn't bleed into the tagline zone at h*0.595.
                // Bottom orange accent opacity reduced — less competition
                // with the tagline text at the bottom of the brand screen.

                // WineLo — lower left
                blob(.auroraWineLo, 0.67 * config.midOpacityMult * global, 280, 200, 85, 5)
                    .scaleEffect(
                        blobVisible[5]
                            ? 1 + 0.05 * sin(blobPhase[5] * .pi * 2)
                            : 0.7
                    )
                    .offset(
                        x: sin(blobPhase[5] * .pi) * 8,
                        y: sin(blobPhase[5] * .pi) * -5
                    )
                    .position(x: w * 0.22, y: h * 0.64)

                // Floor wash — wide radial sweep across bottom
                Ellipse()
                    .fill(RadialGradient(
                        stops: [
                            .init(
                                color: Color.auroraWine.opacity(
                                    0.48 * config.bottomOpacityMult * global
                                ),
                                location: 0
                            ),
                            .init(
                                color: Color.auroraPink.opacity(
                                    0.28 * config.bottomOpacityMult * global
                                ),
                                location: 0.4
                            ),
                            .init(color: .clear, location: 0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    ))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(
                        blobVisible[6]
                            ? 1 + 0.06 * sin(blobPhase[6] * .pi * 2)
                            : 0.7
                    )
                    .opacity(blobVisible[6] ? 1 : 0)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.86)

                // Orange — bottom accent (opacity reduced v1→v2: 0.324→0.22)
                blob(.auroraOrange, 0.35 * config.bottomOpacityMult * global, 220, 140, 88, 7)
                    .offset(x: sin(blobPhase[7] * .pi * 2) * -8)
                    .position(x: w * 0.46, y: h * 0.91)

                // Gold — bottom-right faint accent (new in v2)
                // Anchors the gold presence in the lower field so the
                // warm arc (gold top-right → gold bottom-right) reads as
                // intentional, not a single isolated blob.
                blob(.auroraGold, 0.26 * config.bottomOpacityMult * global, 200, 140, 85, 8)
                    .offset(x: sin(blobPhase[8] * .pi * 2) * 6)
                    .position(x: w * 0.80, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 1.0), value: config)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(
        _ color: Color,
        _ opacity: Double,
        _ w: CGFloat,
        _ h: CGFloat,
        _ blur: CGFloat,
        _ i: Int
    ) -> some View {
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(color: color.opacity(opacity),        location: 0.20),
                    .init(color: color.opacity(opacity * 0.55), location: 0.55),
                    .init(color: .clear,                        location: 1.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(w, h) / 2
            ))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration
    //
    // CHANGE (v2): Extended from 7 blobs → 9 blobs.
    // Two new entries appended to all arrays (indices 7, 8).
    // Phase-drifted durations prevent synchronization across blobs.

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.10, 0.20, 0.30, 0.35, 0.40, 0.50, 0.60, 0.65, 0.70]
        let fadeDurations: [Double] = [0.90, 1.00, 0.90, 1.00, 1.00, 1.20, 1.00, 1.00, 1.10]
        let loopDurations: [Double] = [8,    10,   9,    11,   12,   14,   10,   13,   11  ]
        let loopDelays:    [Double] = [0.80, 1.00, 1.20, 1.30, 1.50, 1.60, 1.80, 1.90, 2.00]

        for i in 0..<9 {
            withAnimation(
                .easeInOut(duration: fadeDurations[i])
                .delay(fadeDelays[i])
            ) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(
                    .linear(duration: loopDurations[i])
                    .repeatForever(autoreverses: false)
                ) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Brand View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .brandView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Dark") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Effects/FlameAura.swift` {#file-open-lightly-design-components-effects-flameaura-swift}

```swift
// Design/Components/Effects/FlameAura.swift
// Open Lightly
//
// Wisp-based flame renderer.
// Each wisp is an independent tapered path that:
//   • rises at its own speed
//   • wobbles horizontally via stacked sine offsets (fake turbulence)
//   • shifts colour from hot-pink/magenta at the base → deep purple at tip
//   • fades in opacity as it rises
//
// Rendered entirely in Canvas so there are zero UIKit/CALayer allocations.

import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: Public view
// ─────────────────────────────────────────────

struct FlameAura: View {

    let intensity: SelectablePill.Intensity

    // Appearance entrance
    @State private var appeared = false
    // Master time driver
    @State private var t: Double = 0

    // Timer publisher — 60 fps
    private let ticker = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    private var wispCount: Int {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 9
        case .alive: return 14
        }
    }

    private var maxWispHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.72   // fraction of frame height
        case .alive: return 0.92
        }
    }

    private var masterOpacity: Double {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.82
        case .alive: return 1.0
        }
    }

    var body: some View {
        Canvas { ctx, size in
            guard wispCount > 0 else { return }
            for i in 0..<wispCount {
                drawWisp(ctx: &ctx, size: size, index: i, t: t)
            }
        }
        .opacity(appeared ? masterOpacity : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.45)) { appeared = true }
        }
        .onDisappear { appeared = false }
        .onReceive(ticker) { _ in t += 0.018 }
        .allowsHitTesting(false)
    }

    // ─────────────────────────────────────────────
    // MARK: Wisp renderer
    // ─────────────────────────────────────────────

    private func drawWisp(
        ctx: inout GraphicsContext,
        size: CGSize,
        index: Int,
        t: Double
    ) {
        // Each wisp gets a stable seed so its personality is consistent
        let seed     = Double(index) * 1.618_033          // golden ratio spread
        let baseX    = size.width * lerp(0.08, 0.92, fract(seed * 0.37))

        // Rise phase — wraps 0→1 continuously, offset per wisp
        let risePhase = fract(t * lerp(0.18, 0.32, fract(seed * 0.71)) + fract(seed * 0.53))
        // Ease the rise so wisps accelerate as they climb
        let easedRise = easeInQuad(risePhase)

        let bottomY  = size.height * 0.95
        let topY     = size.height * (1.0 - maxWispHeight * easedRise)
        let wispH    = bottomY - topY
        guard wispH > 2 else { return }

        // Base width tapers to zero at tip
        let baseWidth = size.width * lerp(0.06, 0.14, fract(seed * 0.29))

        // Horizontal turbulence — two stacked sine waves per wisp
        // creates convincing flicker without Perlin noise
        let wobble1  = sin(t * lerp(1.8, 3.2, fract(seed * 0.43)) + seed) * size.width * 0.045
        let wobble2  = sin(t * lerp(3.0, 5.5, fract(seed * 0.67)) + seed * 2.1) * size.width * 0.022

        // Fade in at birth (risePhase 0→0.15), fade out near tip (0.75→1.0)
        let birthFade = smoothStep(0, 0.15, risePhase)
        let deathFade = 1.0 - smoothStep(0.72, 1.0, risePhase)
        let alpha     = birthFade * deathFade

        guard alpha > 0.01 else { return }

        // Build tapered wisp path — 4-point bezier ribbon
        let cx      = baseX + wobble1 + wobble2
        let path    = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY,
            baseWidth: baseWidth,
            wispH: wispH
        )

        // Colour: base = magenta-pink, tip = deep purple
        // We draw the wisp twice:
        //   pass 1 — wide blur  (outer glow / heat haze)
        //   pass 2 — tight blur (bright core)

        let baseColor = lerpColor(
            Color(red: 1.0,  green: 0.15, blue: 0.55),   // hot pink
            Color(red: 0.72, green: 0.10, blue: 0.90),   // magenta-violet
            fract(seed * 0.19)
        )
        let tipColor = Color(red: 0.25, green: 0.02, blue: 0.55) // deep purple

        let gradient = Gradient(stops: [
            .init(color: baseColor.opacity(alpha * 0.90), location: 0.0),
            .init(color: baseColor.opacity(alpha * 0.55), location: 0.35),
            .init(color: tipColor.opacity(alpha  * 0.20), location: 0.78),
            .init(color: tipColor.opacity(0),             location: 1.0),
        ])

        // Pass 1 — diffuse outer glow
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(8, 18, fract(seed * 0.41))))
            g.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }

        // Pass 2 — bright tight core (thinner path, less blur)
        let corePath = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY + wispH * 0.12,
            baseWidth: baseWidth * 0.38,
            wispH: wispH * 0.88
        )
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(2, 5, fract(seed * 0.53))))
            g.fill(
                corePath,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(alpha * 0.55), location: 0.0),
                        .init(color: baseColor.opacity(alpha * 0.40),   location: 0.40),
                        .init(color: tipColor.opacity(0),               location: 1.0),
                    ]),
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Path builder
    // ─────────────────────────────────────────────

    /// Tapered ribbon: full width at bottom, zero at top.
    /// Two cubic bezier sides give it a slight organic curve.
    private func taperedWispPath(
        cx: Double,
        bottomY: Double,
        topY: Double,
        baseWidth: Double,
        wispH: Double
    ) -> Path {
        var p = Path()
        let halfW  = baseWidth / 2
        // Control point pulls the sides inward 1/3 of the way up
        let ctrl1Y = bottomY - wispH * 0.33
        let ctrl2Y = bottomY - wispH * 0.66

        // left side — bottom-left → top (tapers to point)
        p.move(to: CGPoint(x: cx - halfW, y: bottomY))
        p.addCurve(
            to:      CGPoint(x: cx,        y: topY),
            control1: CGPoint(x: cx - halfW * 0.7, y: ctrl1Y),
            control2: CGPoint(x: cx - halfW * 0.2, y: ctrl2Y)
        )
        // right side — top → bottom-right
        p.addCurve(
            to:      CGPoint(x: cx + halfW, y: bottomY),
            control1: CGPoint(x: cx + halfW * 0.2, y: ctrl2Y),
            control2: CGPoint(x: cx + halfW * 0.7, y: ctrl1Y)
        )
        p.closeSubpath()
        return p
    }

    // ─────────────────────────────────────────────
    // MARK: Math helpers
    // ─────────────────────────────────────────────

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        CGFloat(lerp(Double(a), Double(b), t))
    }
    private func fract(_ x: Double) -> Double { x - floor(x) }
    private func easeInQuad(_ t: Double) -> Double { t * t }
    private func smoothStep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    private func lerpColor(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let t = max(0, min(1, t))
        // Resolve to UIColor for component access
        let ua = UIColor(a), ub = UIColor(b)
        var (r1,g1,b1,a1): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        var (r2,g2,b2,a2): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red:   Double(r1 + (r2-r1) * t),
            green: Double(g1 + (g2-g1) * t),
            blue:  Double(b1 + (b2-b1) * t),
            opacity: Double(a1 + (a2-a1) * t)
        )
    }
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

## File: `Open Lightly/Design/Components/Effects/FloatingStack.swift` {#file-open-lightly-design-components-effects-floatingstack-swift}

```swift
//
//  FloatingStackConfig.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/1/26.
//


// Design/Components/Cards/FloatingStack.swift
// Open Lightly
//
// Generic floating stack — works for CuriosityPicker bubbles
// and session card decks. Pass any view as content.
//
// Usage (bubbles):
//   FloatingStack(items: selectedSpecs, cornerRadius: 20) { spec in
//       FloatingCard(spec: spec, ...)
//   }
//
// Usage (deck):
//   FloatingStack(items: deck.cards, cornerRadius: 16) { card in
//       PromptCard(card: card, ...)
//   }

import SwiftUI

// MARK: - Anchor

enum FloatingStackAnchor {
    case topLeft
    case center
    case centerLeft
    case centerRight

    var staggerX: CGFloat {
        switch self {
        case .topLeft:     return  3
        case .center:      return  3
        case .centerLeft:  return  4
        case .centerRight: return -4
        }
    }

    var staggerY: CGFloat {
        switch self {
        case .topLeft:     return  3
        case .center:      return -3
        case .centerLeft:  return  3
        case .centerRight: return  3
        }
    }

    var expandDirection: FloatingStackConfig.ExpandDirection {
        switch self {
        case .topLeft:     return .down
        case .center:      return .up
        case .centerLeft:  return .right
        case .centerRight: return .left
        }
    }
}

// MARK: - Configuration

struct FloatingStackConfig {
    // Visual
    var cardWidth:        CGFloat = 168
    var cardHeight:       CGFloat = 82
    var cornerRadius:     CGFloat = 20
    var stackOffsetX:     CGFloat = 4     // horizontal stagger per layer
    var stackOffsetY:     CGFloat = 4     // vertical stagger per layer
    var stackRotation:    Double  = 2.5   // degrees per layer
    var maxVisibleLayers: Int     = 3     // how many cards peek behind top

    // Badge
    var showBadge:        Bool    = true
    var badgeFont:        Font    = AppFonts.overline

    // Expansion
    var expandDirection:  ExpandDirection = .up
    var expandSpacing:    CGFloat = 12
    var expandAnimation:  Animation = .spring(response: 0.45, dampingFraction: 0.82)
    var collapseAnimation:Animation = .spring(response: 0.38, dampingFraction: 0.88)

    // Float (when used in cluster context)
    var floatEnabled:     Bool    = true
    var floatAmplitude:   CGFloat = 4
    var floatSpeed:       Double  = 0.009

    // Collapsed state
    var collapsedScale:   CGFloat = 1.0

    enum ExpandDirection {
        case up, down, left, right
    }

    // Preset for curiosity picker corner stack
    static let curiosityStack = FloatingStackConfig(
        cardWidth:        168,
        cardHeight:       82,
        cornerRadius:     20,
        stackOffsetX:     4,
        stackOffsetY:     3,
        stackRotation:    2.0,
        maxVisibleLayers: 3,
        showBadge:        true,
        expandDirection:  .down,
        expandSpacing:    10,
        floatEnabled:     true,
        floatAmplitude:   4,
        floatSpeed:       0.009
    )

    // Preset for session deck
    static let sessionDeck = FloatingStackConfig(
        cardWidth:        UIScreen.main.bounds.width - 48,
        cardHeight:       260,
        cornerRadius:     24,
        stackOffsetX:     6,
        stackOffsetY:     6,
        stackRotation:    1.5,
        maxVisibleLayers: 3,
        showBadge:        true,
        expandDirection:  .up,
        expandSpacing:    16,
        floatEnabled:     false,
        floatAmplitude:   0,
        floatSpeed:       0
    )
}

// MARK: - FloatingStack

struct FloatingStack<Item: Identifiable, CardContent: View>: View {

    let items:       [Item]
    let config:      FloatingStackConfig
    var floatTick:   Double = 0
    var floatPhase:  Double = 0
    var label:       String? = nil   // optional title above stack
    var anchor:      FloatingStackAnchor = .center
    let cardContent: (Item) -> CardContent

    @State private var isExpanded:  Bool   = false
    @State private var mounted:     Bool   = false
    @State private var pressing:    Bool   = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var count: Int { items.count }

    private var floatY: CGFloat {
        guard config.floatEnabled else { return 0 }
        return CGFloat(sin(floatPhase + floatTick * config.floatSpeed) * config.floatAmplitude)
    }

    private var floatRot: Double {
        guard config.floatEnabled else { return 0 }
        return sin(floatPhase + floatTick * config.floatSpeed * 0.7) * 0.5
    }

    // Layers shown behind the top card in collapsed state
    private var visibleLayers: [Item] {
        guard count > 1 else { return [] }
        let behind = Array(items.dropFirst())
        return Array(behind.prefix(config.maxVisibleLayers))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let label {
                stackLabel(label)
                    .padding(.bottom, 8)
            }

            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .offset(y: floatY)
        .rotationEffect(.degrees(floatRot))
        .opacity(mounted ? 1 : 0)
        .scaleEffect(mounted ? 1 : 0.88)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.1)) {
                mounted = true
            }
        }
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        ZStack {
            // Ghost layers behind top card
            ForEach(Array(visibleLayers.enumerated()), id: \.offset) { i, item in
                cardContent(item)
                    .frame(width: config.cardWidth, height: config.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                    .scaleEffect(config.collapsedScale - CGFloat(i + 1) * 0.03)
                    .offset(
                        x: CGFloat(i + 1) * anchor.staggerX,
                        y: CGFloat(i + 1) * anchor.staggerY
                    )
                    .rotationEffect(.degrees(Double(i + 1) * config.stackRotation))
                    .opacity(0.55 - Double(i) * 0.12)
                    .allowsHitTesting(false)
                    .zIndex(Double(config.maxVisibleLayers - i))
            }

            // Top card — tappable
            Group {
                if let first = items.first {
                    cardContent(first)
                        .frame(width: config.cardWidth, height: config.cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                }
            }
            .overlay(alignment: .topTrailing) {
                if config.showBadge && count > 1 {
                    badge
                        .offset(x: 8, y: -8)
                }
            }
            .scaleEffect(pressing ? config.collapsedScale * 0.97 : config.collapsedScale)
            .zIndex(Double(config.maxVisibleLayers + 1))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(config.expandAnimation) {
                    isExpanded = true
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded   { _ in pressing = false }
            )
        }
        .frame(
            width: config.cardWidth * config.collapsedScale
                + CGFloat(config.maxVisibleLayers) * abs(anchor.staggerX),
            height: config.cardHeight * config.collapsedScale
                + CGFloat(config.maxVisibleLayers) * abs(anchor.staggerY)
        )
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: config.expandSpacing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(config.collapseAnimation) {
                    isExpanded = false
                }
            } label: {
                collapseHandle
            }
            .buttonStyle(.plain)

            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                cardContent(item)
                    .frame(width: config.cardWidth, height: config.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                    .transition(.opacity.combined(with: .offset(y: expandInsertionOffset(i))))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.82)
                        .delay(Double(i) * 0.04),
                        value: isExpanded
                    )
            }
        }
    }

    // MARK: - Supporting Views

    private var badge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? AnyShapeStyle(AppColors.magenta)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                          ))
                )
                .frame(width: 22, height: 22)
                .shadow(
                    color: isLight
                        ? AppColors.magenta.opacity(0.40)
                        : AppColors.cyan.opacity(0.55),
                    radius: 6
                )
            Text("\(count)")
                .font(AppFonts.overline)
                .foregroundStyle(.white)
        }
    }

    private var collapseHandle: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.up")
                .font(.system(size: 11, weight: .semibold))
            Text("Collapse")
                .font(AppFonts.caption)
        }
        .foregroundStyle(
            isLight
                ? AppColors.lightTextSecondary
                : AppColors.textSecondary
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(
                    isLight
                        ? AppColors.lightFrostPill
                        : AppColors.surfaceBg
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isLight ? AppColors.lightBorder : AppColors.border,
                            lineWidth: 1
                        )
                )
        )
    }

    private func stackLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .foregroundStyle(
                isLight
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary
            )
            .tracking(1.5)
    }

    private func expandInsertionOffset(_ index: Int) -> CGFloat {
        switch anchor.expandDirection {
        case .up:    return  20
        case .down:  return -20
        case .left:  return  20
        case .right: return -20
        }
    }
}

// MARK: - Safe subscript helper

extension Array {
    subscript(safe index: Int) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/GlowOrb.swift` {#file-open-lightly-design-components-effects-gloworb-swift}

```swift
//
//  GlowOrb.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

// ✅ Design system audit — verified March 9, 2026

import SwiftUI

struct GlowOrb: View {
    @Environment(\.theme) private var t
    let color: Color
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 40)
            .opacity(t.glowOpacity)
            .allowsHitTesting(false)
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/HolographicShimmer.swift` {#file-open-lightly-design-components-effects-holographicshimmer-swift}

```swift
import SwiftUI

/// Self-contained animated holographic shimmer fill.
/// Renders a 3× wide neon gradient that sweeps left→right continuously.
///
/// Use as a background layer clipped to any shape:
/// ```swift
/// Capsule()
///     .fill(AppColors.surfaceBg)
///     .overlay { HolographicShimmer().clipShape(Capsule()) }
/// ```
struct HolographicShimmer: View {
    /// Animation duration in seconds. Defaults to 6 (gentle sweep).
    var duration: Double = 6

    @State private var phase: CGFloat = 0

    private let colors: [Color] = [
        AppColors.cyan.opacity(0.50),
        AppColors.purple.opacity(0.45),
        AppColors.magenta.opacity(0.45),
        AppColors.pink.opacity(0.40),
        AppColors.cyan.opacity(0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/LightAuraBloom.swift` {#file-open-lightly-design-components-effects-lightaurabloom-swift}

```swift
//
//  LightAuraBloom.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/26/26.
//


// Design/Components/Effects/LightAuraBloom.swift
// Open Lightly
//
// Light-mode analogue of FlameAura.
// Renders layered, animated warm blobs that rise above
// a selected pill on a cream/white background.
// Uses rose / peach / gold / lavender — all visible on light surfaces.

import SwiftUI
import Combine

struct LightAuraBloom: View {

    let intensity: SelectablePill.Intensity

    // ── tuneable per-intensity values ──────────────────────────────
    private var blobOpacity: Double {
        switch intensity {
        case .dim:   return 0.30
        case .warm:  return 0.48
        case .alive: return 0.62
        }
    }

    private var bloomHeight: CGFloat {
        switch intensity {
        case .dim:   return 0          // .dim never shows flame/bloom
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ── animation state ───────────────────────────────────────────
    @State private var phase: Double = 0

    var body: some View {
        guard bloomHeight > 0 else { return AnyView(EmptyView()) }
        return AnyView(
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let t = phase
                    drawBloom(ctx: &ctx, size: size, t: t)
                }
                .onAppear { phase = 0 }
                .onReceive(
                    Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
                ) { _ in
                    phase += 0.012
                }
            }
            .allowsHitTesting(false)
        )
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Drawing
    // ─────────────────────────────────────────────────────────────

    private func drawBloom(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let blobs: [(offsetX: Double, color: Color, scale: Double, phaseShift: Double)] = [
            // rose centre
            (offsetX:  0.00, color: Color(red: 1.00, green: 0.40, blue: 0.60),
             scale: 1.00, phaseShift: 0.00),
            // peach left
            (offsetX: -0.18, color: Color(red: 1.00, green: 0.65, blue: 0.45),
             scale: 0.78, phaseShift: 0.90),
            // gold right
            (offsetX:  0.20, color: Color(red: 1.00, green: 0.80, blue: 0.30),
             scale: 0.70, phaseShift: 1.60),
            // lavender far-left
            (offsetX: -0.30, color: Color(red: 0.78, green: 0.60, blue: 1.00),
             scale: 0.60, phaseShift: 2.40),
            // blush far-right
            (offsetX:  0.32, color: Color(red: 1.00, green: 0.55, blue: 0.75),
             scale: 0.55, phaseShift: 3.10),
        ]

        for blob in blobs {
            let waver   = sin(t * 1.8 + blob.phaseShift) * 0.06    // gentle horizontal sway
            let rise    = cos(t * 1.2 + blob.phaseShift) * 0.08    // breathing rise/fall
            let pulse   = 0.88 + sin(t * 2.0 + blob.phaseShift) * 0.12 // opacity pulse

            let cx = size.width  * (0.50 + blob.offsetX + waver)
            // blobs sit just above bottom edge and drift upward
            let cy = size.height * (0.75 + rise)

            let blobW = size.width  * blob.scale * 0.55
            let blobH = size.height * blob.scale * 0.60

            let rect = CGRect(
                x: cx - blobW / 2,
                y: cy - blobH / 2,
                width: blobW,
                height: blobH
            )

            // soft radial gradient per blob
            let gradient = Gradient(stops: [
                .init(color: blob.color.opacity(blobOpacity * pulse), location: 0.0),
                .init(color: blob.color.opacity(0),                   location: 1.0),
            ])

            ctx.drawLayer { inner in
                inner.addFilter(.blur(radius: 18 * blob.scale))
                inner.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        gradient,
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: max(blobW, blobH) / 2
                    )
                )
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/LightModeShimmer.swift` {#file-open-lightly-design-components-effects-lightmodeshimmer-swift}

```swift
// LightModeShimmer.swift
// Open Lightly
//
// Rewritten to match HolographicShimmer's energy on cream surfaces.
//
// Key fixes vs original:
//   - Removed .multiply blend mode — was darkening colours into mud
//   - Added second diagonal pass at different speed — depth/foil feel
//   - Matched HolographicShimmer's normal compositing
//   - Kept warm palette (purple/magenta/gold) — no cyan on cream

import SwiftUI

struct LightModeShimmer: View {
    var duration: Double = 6
    var usePillColors: Bool = false

    @State private var phase1: CGFloat = 0   // primary horizontal sweep
    @State private var phase2: CGFloat = 0   // secondary diagonal sweep

    // Primary sweep — matches HolographicShimmer's colour slot count
    // and opacity range exactly. Only the hues differ (warm vs neon).
    private var primaryColors: [Color] {
        [
            AppColors.purple.opacity(0.55),
            AppColors.magenta.opacity(0.60),
            AppColors.gold.opacity(0.55),
            AppColors.magentaLight.opacity(0.58),
            AppColors.purple.opacity(0.55),
        ]
    }

    // Secondary pass — softer, offset palette
    // Sits on top of primary at lower opacity to create depth.
    // Diagonal start/end point fakes a 2D foil angle.
    private var secondaryColors: [Color] {
        [
            AppColors.gold.opacity(0.30),
            AppColors.purple.opacity(0.25),
            AppColors.magenta.opacity(0.28),
            AppColors.gold.opacity(0.22),
            AppColors.magentaLight.opacity(0.25),
        ]
    }

    // Background wash variant — same structure, lower opacity
    private var washColors: [Color] {
        AppColors.lightShimmerColors
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Pass 1: primary horizontal sweep ─────────────────
                // Identical mechanics to HolographicShimmer.
                // No blend mode — normal compositing, colours at face value.
                LinearGradient(
                    colors: usePillColors ? primaryColors : washColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: w * 3, height: h)
                .offset(x: phase1 * -w * 2)

                // ── Pass 2: secondary diagonal sweep (pills only) ─────
                // Offset diagonal gradient at 60% speed of primary.
                // Creates the illusion of depth — light catching a
                // different facet of the foil at a different angle.
                // Skipped for background wash — too busy on large surfaces.
                if usePillColors {
                    LinearGradient(
                        colors: secondaryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: w * 3, height: h)
                    .offset(x: phase2 * -w * 2)
                    .blendMode(.screen)   // screen on cream = gentle brightening,
                                          // not the darkening that multiply caused
                }
            }
        }
        .clipped()
        .onAppear {
            // Primary sweep — same timing as HolographicShimmer
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) : duration)
                .repeatForever(autoreverses: true)
            ) {
                phase1 = 1
            }

            // Secondary sweep — 60% speed, starts offset so
            // the two passes are never in sync (avoids strobing)
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) * 1.65 : duration * 1.4)
                .repeatForever(autoreverses: true)
                .delay(0.8)
            ) {
                phase2 = 1
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/MazePatternView.swift` {#file-open-lightly-design-components-effects-mazepatternview-swift}

```swift
//
//  MazePatternView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  MazePatternView.swift
//  Open Lightly
//

import SwiftUI

struct MazePatternView: View {

    var color:         Color
    var opacity:       Double = 0.28
    var glowColor:     Color  = .clear
    var glowOpacity:   Double = 0.0
    var orbitCount:    Int    = 3
    var isOrbitActive: Bool   = true

    private struct Ring {
        let radiusFraction: CGFloat
        let gaps: [(Double, Double)]
    }

    private let rings: [Ring] = [
        Ring(
            radiusFraction: 0.42,
            gaps: [(10, 40), (100, 125), (200, 225), (290, 320)]
        ),
        Ring(
            radiusFraction: 0.30,
            gaps: [(30, 60), (150, 180), (250, 275)]
        ),
        Ring(
            radiusFraction: 0.19,
            gaps: [(60, 90), (180, 210)]
        ),
    ]

    private struct Spoke {
        let angleDeg:  Double
        let innerFrac: CGFloat
        let outerFrac: CGFloat
    }

    private let spokes: [Spoke] = [
        Spoke(angleDeg:  15, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg:  75, innerFrac: 0.30, outerFrac: 0.42),
        Spoke(angleDeg: 135, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg: 195, innerFrac: 0.30, outerFrac: 0.42),
        Spoke(angleDeg: 255, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg: 315, innerFrac: 0.19, outerFrac: 0.42),
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cx = size / 2
            let cy = size / 2
            ZStack {
                // AFTER
                // Layer 0 — glow bloom (light mode only)
                              if glowOpacity > 0 {
                                  mazePath(size: size, radiusOffset: 0, lineWidth: 3.0)
                                      .stroke(glowColor, lineWidth: 3.0)
                                      .opacity(glowOpacity * 0.55)
                                      .blur(radius: 2.5)
                              }

                              // Layer 1 — groove shadow
                              mazePath(size: size, radiusOffset: 0.5, lineWidth: 2.8)
                                  .stroke(color, lineWidth: 2.8)
                                  .opacity(opacity * 0.22)

                              // Layer 2 — main engraved line
                              mazePath(size: size, radiusOffset: 0, lineWidth: 1.8)
                                  .stroke(color, lineWidth: 1.8)
                                  .opacity(opacity)
                                  .drawingGroup()

                              // Layer 3 — highlight edge
                              mazePath(size: size, radiusOffset: -0.5, lineWidth: 0.8)
                                  .stroke(Color.white, lineWidth: 0.8)
                                  .opacity(opacity * 0.45)

                // Orbit — rendered here so it shares the GeometryReader's
                // coordinate space. cx/cy are the exact same values used
                // by the maze rings — guaranteed to be co-centered.
                TileOrbitView(
                    orbitCount: orbitCount,
                    isActive:   isOrbitActive,
                    size:       120,
                    glowScale:  0.45   // tight context — glow matches maze line weight
                )
                .frame(width: 120, height: 120)
                .position(x: cx, y: cy)
            }
        }
    }

    private func mazePath(
        size:         CGFloat,
        radiusOffset: CGFloat,
        lineWidth:    CGFloat
    ) -> Path {
        var path = Path()
        let cx = size / 2
        let cy = size / 2

        for ring in rings {
            let r = size * ring.radiusFraction + radiusOffset
            var current: Double = 0
            for (gStart, gEnd) in ring.gaps {
                if current < gStart {
                    path.addArc(
                        center:     CGPoint(x: cx, y: cy),
                        radius:     r,
                        startAngle: .degrees(current),
                        endAngle:   .degrees(gStart),
                        clockwise:  false
                    )
                    let nextX = cx + r * CGFloat(cos(gEnd * .pi / 180))
                    let nextY = cy + r * CGFloat(sin(gEnd * .pi / 180))
                    path.move(to: CGPoint(x: nextX, y: nextY))
                }
                current = gEnd
            }
            if current < 360 {
                path.addArc(
                    center:     CGPoint(x: cx, y: cy),
                    radius:     r,
                    startAngle: .degrees(current),
                    endAngle:   .degrees(360),
                    clockwise:  false
                )
            }
        }

        for spoke in spokes {
            let rad   = spoke.angleDeg * .pi / 180
            let nudge = CGFloat(radiusOffset == 0 ? 0 : (radiusOffset > 0 ? 0.4 : -0.3))
            let x1 = cx + size * spoke.innerFrac * CGFloat(cos(rad)) + nudge
            let y1 = cy + size * spoke.innerFrac * CGFloat(sin(rad)) + nudge
            let x2 = cx + size * spoke.outerFrac * CGFloat(cos(rad)) + nudge
            let y2 = cy + size * spoke.outerFrac * CGFloat(sin(rad)) + nudge
            path.move(to:    CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }

        return path
    }
}

#Preview("Dark") {
    ZStack {
        Color(red: 0.051, green: 0.043, blue: 0.122).ignoresSafeArea()
        MazePatternView(
            color:       AppColors.magenta,
            opacity:     0.28,
            glowColor:   .clear,
            glowOpacity: 0.0
        )
        .frame(width: 280, height: 280)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        MazePatternView(
            color:       AppColors.orangeHot,
            opacity:     0.32,
            glowColor:   AppColors.orangeHot,
            glowOpacity: 0.18
        )
        .frame(width: 280, height: 280)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Effects/OnboardingGlowField.swift` {#file-open-lightly-design-components-effects-onboardingglowfield-swift}

```swift
// OnboardingGlowField.swift
// Open Lightly
//
// Atmospheric glow blob field shared across all onboarding screens.
// Extracted from OnboardingNameView's inline glowField implementation.
// Usage: OnboardingGlowField() — manages its own animation state.
import SwiftUI

struct OnboardingGlowField: View {
    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Cyan — upper-left
                blob(AppColors.cyan,  0.32, 300, 280, 75, 0)
                    .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                            y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                    .position(x: w * 0.22, y: h * 0.20)

                // Purple — center
                blob(AppColors.purple, 0.28, 380, 360, 75, 1)
                    .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                    .position(x: w * 0.50, y: h * 0.40)

                // Magenta — right edge
                blob(AppColors.magenta, 0.24, 280, 300, 75, 2)
                    .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                            y: cos(blobPhase[2] * .pi * 2) * 12)
                    .position(x: w * 0.88, y: h * 0.33)

                // Gold — warm accent
                blob(AppColors.goldLight, 0.12, 200, 180, 80, 3)
                    .offset(x: sin(blobPhase[3] * .pi) * 8,
                            y: sin(blobPhase[3] * .pi) * -6)
                    .position(x: w * 0.20, y: h * 0.48)

                // Magenta — mid-left
                blob(AppColors.magenta, 0.15, 300, 220, 85, 4)
                    .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[4] * .pi) * 8,
                            y: sin(blobPhase[4] * .pi) * -6)
                    .position(x: w * 0.18, y: h * 0.60)

                // Floor wash
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.deepBlue.opacity(0.12), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),   location: 0.4),
                        .init(color: .clear,                           location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                    .opacity(blobVisible[5] ? 1 : 0)
                    .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.80)

                // Cyan accent — bottom
                blob(AppColors.cyan, 0.08, 240, 150, 90, 6)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                    .position(x: w * 0.45, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(_ color: Color, _ opacity: Double, _ w: CGFloat, _ h: CGFloat, _ blur: CGFloat, _ i: Int) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.1, 0.2, 0.3, 0.35, 0.4,  0.5,  0.6]
        let fadeDurations: [Double] = [0.9, 1.0, 0.9, 1.0,  1.0,  1.2,  1.0]
        let loopDurations: [Double] = [8,   10,  9,   11,   12,   14,   10]
        let loopDelays:    [Double] = [0.8, 1.0, 1.2, 1.3,  1.5,  1.6,  1.8]

        for i in 0..<7 {
            withAnimation(.easeInOut(duration: fadeDurations[i]).delay(fadeDelays[i])) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(.linear(duration: loopDurations[i]).repeatForever(autoreverses: false)) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingGlowField()
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/SparkField.swift` {#file-open-lightly-design-components-effects-sparkfield-swift}

```swift
// SparkField.swift
// Open Lightly
//
// Campfire ember particle system for light mode screens.
// Standalone Canvas-based component — place alongside AuroraGlowField
// in the screen background stack.
//
// Palette: warm ember colors — deep magenta, hot pink, gold, amber,
//          rose, warm gold, deep rose, orange-amber.
//          Matches the StatView HTML mockup exactly.
//
// Usage:
//   ZStack {
//       AppColors.lightPageBg.ignoresSafeArea()
//       AuroraGlowField().ignoresSafeArea()
//       SparkField(config: .statView).ignoresSafeArea()
//       // content
//   }
//
// Screen configs:
//   .statView            — Screen 1, free travel, no fade
//   .nameView            — Screen 3, fades before glass card
//   .modeSelectView      — Screen 4, stays in lower third
//   .contextView         — Screen 5, very subtle, early fade
//   .curiosityPickerView — Screen 6, minimal, bottom only
//   .groundRulesView     — Screen 8, confined to bottom quarter
//
// BrandView (Screen 2) and BuildingPathView (Screen 7)
// are permanently dark — never use SparkField on those screens.
//
// Always: .allowsHitTesting(false)
// Always: placed in background, never over content
// Light mode only — never use on dark screens
//
// Architecture notes:
//   - SparkSystem is @StateObject — each SparkField instance owns its
//     own isolated particle state. No singleton. Safe for overlapping
//     views, navigation transitions, and sheet presentations.
//   - plusLighter blend is applied INSIDE the Canvas GraphicsContext only.
//     Sparks glow additively against each other within the offscreen texture.
//     The texture itself composites normally (.normal) against the scene,
//     preserving ember colors against the cream background.
//   - .compositingGroup() on the view seals the layer so sparks physically
//     sit below all ZStack siblings placed after SparkField.

import Combine
import SwiftUI

// ─────────────────────────────────────────────
// MARK: SparkConfiguration
// One config per screen. Defined once, used everywhere.
// Tune numbers here — never inside Particle or SparkSystem.
// ─────────────────────────────────────────────

struct SparkConfiguration {

    // Number of simultaneous sparks
    var count: Int

    // Rise speed — base + variance
    // vy = -(baseSpeed + random * speedVariance)
    var baseSpeed: Double
    var speedVariance: Double

    // Dot size
    var radiusMin: Double
    var radiusMax: Double

    // Glow halo multiplier applied to radius
    var glowMultiplierMin: Double
    var glowMultiplierMax: Double

    // Opacity ceiling — how bright sparks get at peak
    // Tuned per screen: brighter on open screens, dimmer under content
    var opacityCeilMin: Double
    var opacityCeilMax: Double

    // Spawn X range (normalised 0–1)
    var spawnXMin: Double
    var spawnXMax: Double

    // Spawn Y on respawn (normalised 0–1, 1 = bottom)
    // Particles born here when they respawn after lifespan ends
    var respawnYMin: Double

    // Spatial fade zone (normalised 0–1, y decreases as particle rises)
    // nil = no fade — particle travels until lifecycle ends naturally
    // fadeStartY: fade begins (full opacity below this)
    // fadeEndY:   fully transparent (above this y, particle invisible)
    // fadeStartY must be > fadeEndY (y decreases as particle rises)
    var fadeStartY: Double?
    var fadeEndY: Double?

    // Palette override — nil uses the default warm ember palette
    // Provide a custom palette to shift color character per screen
    var palette: [(r: Double, g: Double, b: Double)]?
}

// ─────────────────────────────────────────────
// MARK: Per-screen configurations
// ─────────────────────────────────────────────

extension SparkConfiguration {

    // Default warm ember palette — shared across all screens.
    // Matches the StatView HTML mockup warmPalette exactly.
    static let defaultPalette: [(r: Double, g: Double, b: Double)] = [
        (r: 220/255, g:  30/255, b:  90/255),  // deep magenta   — boosted red channel
        (r: 255/255, g:   0/255, b: 106/255),  // hot pink       — unchanged #FF006A
        (r: 215/255, g: 110/255, b:   0/255),  // amber-gold     — green reduced, warmer
        (r: 240/255, g:  70/255, b:  10/255),  // hot amber      — red pushed, green dropped
        (r: 210/255, g:  10/255, b:  80/255),  // rose           — more saturated
        (r: 255/255, g: 130/255, b:   0/255),  // pure warm gold — green floor raised
        (r: 200/255, g:  20/255, b:  70/255),  // deep rose      — direction unchanged
        (r: 250/255, g:  90/255, b:  20/255),  // hot orange     — red channel maximised
    ]

    // ── Screen 1: StatView ────────────────────
    // No cards. Full vertical travel. No spatial fade.
    // Most expressive — stat number is the hero, sparks
    // surround it freely across the full screen height.
    // Matches HTML StatView mockup: count 28, speed 0.27–0.45.
    static let statView = SparkConfiguration(
        count:             28,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.48,
        opacityCeilMax:    0.75,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.55,
        fadeStartY:        nil,   // full travel — no fade
        fadeEndY:          nil,
        palette:           nil    // default warm ember
    )

    // ── Screen 3: NameView ────────────────────
    // Glass card: y ~0.28–0.72.
    // Sparks spawn below, dissolve before card edge.
    // Form screen — quieter than StatView.
    static let nameView = SparkConfiguration(
        count:             22,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.42,
        opacityCeilMax:    0.65,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.55,
        fadeStartY:        0.58, // dissolve begins here
        fadeEndY:          0.44, // fully gone — well below card edge
        palette:           nil
    )

    // ── Screen 4: ModeSelectView ──────────────
    // Three mode cards start ~y 0.35, experience pills below.
    // Sparks confined to lower half. Quieter density.
    // ScrollView content means particles should not rise
    // high enough to be visible behind text.
    static let modeSelectView = SparkConfiguration(
        count:             18,
        baseSpeed:         0.22,
        speedVariance:     0.14,
        radiusMin:         0.55,
        radiusMax:         1.70,
        glowMultiplierMin: 3.5,
        glowMultiplierMax: 5.5,
        opacityCeilMin:    0.33,
        opacityCeilMax:    0.54,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.62,  // born lower than other screens
        fadeStartY:        0.55,
        fadeEndY:          0.40,
        palette:           nil
    )

    // ── Screen 5: ContextView ─────────────────
    // Gesture-driven card stack takes most of the screen.
    // Sparks must not compete with the drag interaction.
    // Very subtle — almost subliminal presence only.
    static let contextView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.20,
        speedVariance:     0.12,
        radiusMin:         0.50,
        radiusMax:         1.50,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 5.0,
        opacityCeilMin:    0.27,
        opacityCeilMax:    0.45,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.65,
        fadeStartY:        0.60,  // early fade — cards occupy mid-screen
        fadeEndY:          0.48,
        palette:           nil
    )

    // ── Screen 6: CuriosityPickerView ─────────
    // Dense ScrollView fills most of the screen from top.
    // Sparks barely there — content is the entire focus.
    // Lowest density and opacity in the flow.
    static let curiosityPickerView = SparkConfiguration(
        count:             12,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.22,
        opacityCeilMax:    0.36,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.70,  // born in bottom 30% only
        fadeStartY:        0.65,  // dissolve almost immediately after spawning
        fadeEndY:          0.52,
        palette:           nil
    )

    // ── Screen 8: GroundRulesView ─────────────
    // ScrollView with promise cards + italic line + pinned CTA.
    // Sparks confined to bottom quarter. Very dim.
    // Must not distract from the must-read content.
    static let groundRulesView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.24,
        opacityCeilMax:    0.40,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.72,  // bottom quarter only
        fadeStartY:        0.68,
        fadeEndY:          0.56,
        palette:           nil
    )
}

// ─────────────────────────────────────────────
// MARK: SparkField View
// ─────────────────────────────────────────────

struct SparkField: View {

    var config: SparkConfiguration = .statView

    // Each SparkField instance owns its own isolated particle system.
    // @StateObject persists across parent re-renders (e.g. keyboard
    // appearing, @State changes on the parent view) so particles are
    // never accidentally reset mid-animation.
    @StateObject private var system = SparkSystem()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { timeline in
            Canvas { context, size in
                // Reference timeline.date — required so SwiftUI
                // invalidates the Canvas on every tick.
                _ = timeline.date
                system.update(size: size)
                system.drawAll(context: context, size: size)
            }
        }
        // .compositingGroup() flattens this entire Canvas into one
        // offscreen Metal texture before it is composited into the
        // parent ZStack. This means every ZStack sibling placed AFTER
        // SparkField sits in a completely separate layer — sparks are
        // physically underneath buttons, cards, and text.
        //
        // NO .blendMode() here — normal alpha compositing against the
        // scene preserves ember colors on the cream background.
        // plusLighter lives only INSIDE the Canvas (see SparkSystem.drawAll)
        // where it blends sparks against each other, not against the bg.
        .compositingGroup()
        .allowsHitTesting(false)
        .onAppear {
            system.configure(config)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: SparkSystem
// Owns all particle state. ObservableObject so @StateObject
// in SparkField holds a stable reference across re-renders.
// No singleton — each SparkField gets its own instance.
// Safe for overlapping views, navigation transitions, sheets.
// ─────────────────────────────────────────────

final class SparkSystem: ObservableObject {

    // Explicit publisher satisfies ObservableObject without @Published.
    // SparkSystem never needs to push UI updates through Combine —
    // the Canvas refreshes via TimelineView, not objectWillChange.
    // Declared explicitly because the compiler cannot synthesise
    // conformance when no @Published properties are present.
    let objectWillChange = ObservableObjectPublisher()

    private var particles: [Particle] = []
    private var activeConfig: SparkConfiguration = .statView

    func configure(_ config: SparkConfiguration) {
        // Always fully reconfigure — no one-time flag.
        // .onAppear is naturally scoped to the view lifetime,
        // so this is only called when the view actually appears.
        activeConfig = config
        let palette = config.palette ?? SparkConfiguration.defaultPalette
        particles = (0..<config.count).map { _ in
            Particle(config: config, palette: palette, initial: true)
        }
    }

    func update(size: CGSize) {
        let palette = activeConfig.palette ?? SparkConfiguration.defaultPalette
        for i in particles.indices {
            particles[i].update(bounds: size, config: activeConfig, palette: palette)
        }
    }

    func drawAll(context: GraphicsContext, size: CGSize) {
        // plusLighter INSIDE the Canvas only.
        // Sparks that overlap each other add light together — correct
        // ember glow behaviour. The offscreen texture produced by
        // .compositingGroup() then composites normally against the scene,
        // so the cream background is never additively blown out to white.
        var blendedContext = context
        blendedContext.blendMode = .plusLighter

        for particle in particles {
            let px = particle.x * size.width
            let py = particle.y * size.height
            particle.drawAt(context: blendedContext, px: px, py: py)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Particle
// Value type — one ember spark.
// x and y are stored normalised (0–1).
// Converted to pixels in SparkSystem.drawAll().
// All physics values read from SparkConfiguration —
// nothing hardcoded here.
// ─────────────────────────────────────────────

private struct Particle {

    var x: Double
    var y: Double
    var vy: Double
    var vx: Double
    var driftAmp:    Double
    var driftFreq:   Double
    var driftPhase:  Double
    var radius:      Double
    var glowRadius:  Double
    var frame:       Double
    var totalFrames: Double
    var opacityCeil: Double
    var fadeStartY:  Double?
    var fadeEndY:    Double?
    var r: Double
    var g: Double
    var b: Double

    // ── Init ──────────────────────────────────────

    init(
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)],
        initial: Bool
    ) {
        let c = palette[Int.random(in: 0..<palette.count)]
        r = c.r; g = c.g; b = c.b

        x = config.spawnXMin + Double.random(in: 0..<(config.spawnXMax - config.spawnXMin))

        // Initial spread: y 0.15–1.0 so all vertical zones populated on first appear
        // Respawn: born near bottom per config.respawnYMin
        y = initial
            ? (0.15 + Double.random(in: 0..<0.85))
            : (config.respawnYMin + Double.random(in: 0..<(1.0 - config.respawnYMin)))

        radius = config.radiusMin + Double.random(in: 0..<(config.radiusMax - config.radiusMin))

        let spd = config.baseSpeed
        let variance = config.speedVariance
        vy = -(spd + Double.random(in: 0..<variance))
        vx = (Double.random(in: 0..<1.0) - 0.5) * 0.20

        driftAmp   = 0.5 + Double.random(in: 0..<0.9)
        driftFreq  = 0.007 + Double.random(in: 0..<0.011)
        driftPhase = Double.random(in: 0..<(.pi * 2))

        totalFrames = 180 + Double.random(in: 0..<240)
        frame       = initial ? Double.random(in: 0..<totalFrames) : 0

        let glowMult = config.glowMultiplierMin
            + Double.random(in: 0..<(config.glowMultiplierMax - config.glowMultiplierMin))
        glowRadius = radius * glowMult

        opacityCeil = config.opacityCeilMin
            + Double.random(in: 0..<(config.opacityCeilMax - config.opacityCeilMin))

        // Store fade zone per particle so update() can read it without config reference
        fadeStartY = config.fadeStartY
        fadeEndY   = config.fadeEndY
    }

    // ── Opacity curve ─────────────────────────────
    // Lifecycle: ease in (0→0.15), hold (0.15→0.66), ease out (0.66→1.0)
    // Spatial:   dissolve as particle rises into content zone.
    //            nil fadeStartY = no spatial fade.

    var opacity: Double {
        let t = frame / totalFrames

        // Lifecycle curve
        let lifeCurve: Double
        if t < 0.14      { lifeCurve = (t / 0.14) * opacityCeil }
        else if t < 0.66 { lifeCurve = opacityCeil }
        else             { lifeCurve = ((1.0 - t) / 0.34) * opacityCeil }

        // Spatial fade — only applied when config provides fade zone
        guard let startY = fadeStartY, let endY = fadeEndY else {
            return lifeCurve   // no fade — full travel
        }
        let spatialFade: Double
        if y > startY {
            spatialFade = 1.0
        } else if y < endY {
            spatialFade = 0.0
        } else {
            spatialFade = (y - endY) / (startY - endY)
        }
        return lifeCurve * spatialFade
    }

    // ── Update ────────────────────────────────────

    mutating func update(
        bounds: CGSize,
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)]
    ) {
        frame += 1

        let pixelY = y * bounds.height
        if frame >= totalFrames || pixelY < -20 {
            self = Particle(config: config, palette: palette, initial: false)
            return
        }

        let sine = sin(frame * driftFreq + driftPhase)
        x += (vx + sine * driftAmp * 0.032) / bounds.width
        y += vy / bounds.height
        vy *= 1.0012
    }

    // ── Draw ──────────────────────────────────────
    // Three layers: smooth radial gradient halo → crisp dot → hot white core.

    func drawAt(context: GraphicsContext, px: Double, py: Double) {
        let op = opacity
        guard op > 0.01 else { return }

        let baseColor = Color(red: r, green: g, blue: b)

        // Layer 1: Smooth Radial Gradient Halo
        let haloGradient = Gradient(stops: [
            .init(color: baseColor.opacity(op * 0.72), location: 0.0),
            .init(color: baseColor.opacity(op * 0.32), location: 0.40),
            .init(color: baseColor.opacity(op * 0.08), location: 0.75),
            .init(color: baseColor.opacity(0.0),       location: 1.0)
        ])

        let haloRect = CGRect(
            x: px - glowRadius, y: py - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        )
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                haloGradient,
                center: CGPoint(x: px, y: py),
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        // Layer 2: Crisp dot
        let dotRect = CGRect(
            x: px - radius, y: py - radius,
            width: radius * 2, height: radius * 2
        )
        context.fill(Path(ellipseIn: dotRect), with: .color(baseColor.opacity(op * 1.0)))

        // Layer 3: Hot white core for larger sparks
        if radius > 0.7 {
            let coreR = radius * 0.40
            let coreRect = CGRect(
                x: px - coreR, y: py - coreR,
                width: coreR * 2, height: coreR * 2
            )
            context.fill(
                Path(ellipseIn: coreRect),
                with: .color(Color.white.opacity(op * 0.65))
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("StatView — full travel") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .statView).ignoresSafeArea()
        VStack {
            Spacer()
            Text("1 in 5")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(Color.orange)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("NameView — fades before card") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .nameView).ignoresSafeArea()
        VStack {
            Spacer().frame(height: 200)
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .frame(height: 340)
                .padding(.horizontal, 28)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("ModeSelectView — lower third") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .modeSelectView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("ContextView — very subtle") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .contextView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("CuriosityPickerView — minimal") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .curiosityPickerView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("GroundRulesView — bottom quarter") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .groundRulesView).ignoresSafeArea()
        VStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 500)
                .padding(.horizontal, 24)
                .padding(.top, 80)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Effects/TileOrbitView.swift` {#file-open-lightly-design-components-effects-tileorbitview-swift}

```swift
//
//  TileOrbitView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/29/26.
//


// Design/Components/Effects/TileOrbitView.swift
// Open Lightly
//
// Purpose-built comet orbit animation for small tile contexts (44–88pt).
// Drives the mode selection visual in OnboardingModeSelectView.
//
// API:
//   TileOrbitView(orbitCount: 1, isActive: false)  — resting arc
//   TileOrbitView(orbitCount: 2, isActive: true)   — animated comet orbits
//
// Resting state: static arc indicators per orbit count.
//   1 orbit → single 120° arc
//   2 orbits → two offset arcs
//   3 orbits → three full dim rings
//
// Active state: TimelineView-driven comet orbits.
//   Each orbit has a phase offset, radius differential, and speed
//   differential so they never stack. All orbits cycle through
//   cyan → magenta → purple, each offset by one color step so
//   no two orbits share a color at any given frame.
//
// Color cycling:
//   Three AppColors tokens used as cycle anchors:
//     AppColors.cyan    (#00C2FF)
//     AppColors.magenta (#FF006A)
//     AppColors.purple  (#6C3AE0)
//   Light mode uses the warm aurora equivalents:
//     AppColors.magenta → AppColors.orangeHot → AppColors.purple
//
// Performance:
//   No state objects. No trail history. No pattern cycling.
//   TimelineView capped at 60fps via .animation schedule.
//   Canvas drawing only — no SwiftUI view tree overhead.
//   Zero GPU cost in resting state (no TimelineView mounted).

import SwiftUI

// MARK: - TileOrbitView

struct TileOrbitView: View {

    var orbitCount: Int     = 1      // 1, 2, or 3
    var isActive:   Bool    = false  // resting arc vs. animated comet
    var speed:      Double  = 1.0    // global speed multiplier
    var size:       CGFloat = 72     // canvas dimension in points
    var glowScale:  Double  = 1.0    // reduce for tight contexts like card backs

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Color cycle anchors

    // Dark:  cyan → magenta → purple
    // Light: magenta → orangeHot → purple
    private var cycleColors: [Color] {
        isLight
            ? [AppColors.magenta, AppColors.orangeHot, AppColors.purple]
            : [AppColors.cyan,    AppColors.magenta,   AppColors.purple]
    }

    // MARK: - Orbit geometry constants

    // Radii as fractions of baseR — outer to inner
    private let radiiFactors: [Double] = [1.00, 0.65, 0.32]

    // Fixed phase offsets guarantee heads never meet.
    // 2 orbits: π apart — always opposite sides of the ring.
    // 3 orbits: 2π/3 apart — always 120° apart.
    private let phaseOffsets: [Double] = [0, .pi, .pi * 4 / 3]
    
    private let speedMultipliers: [Double] = [1.00, 1.00, 1.00]

    // Color index offset per orbit — never same color simultaneously
    private let colorOffsets: [Int] = [0, 1, 2]

    // MARK: - Body

    var body: some View {
        if isActive {
            TimelineView(.animation) { tl in
                Canvas { context, canvasSize in
                    let elapsed = tl.date.timeIntervalSinceReferenceDate
                    drawActive(
                        context:   &context,
                        size:      canvasSize,
                        elapsed:   elapsed
                    )
                }
                .frame(width: size, height: size)
            }
        } else {
            Canvas { context, canvasSize in
                drawResting(context: &context, size: canvasSize)
            }
            .frame(width: size, height: size)
        }
    }

    // MARK: - Resting Draw

    private func drawResting(
        context: inout GraphicsContext,
        size:    CGSize
    ) {
        let cx     = size.width  / 2
        let cy     = size.height / 2
        let baseR  = Double(size.width) * 0.36
        let stroke = StrokeStyle(lineWidth: 1.0, lineCap: .round)
        let color = isLight
            ? AppColors.lightBorder.opacity(0.28)
            : AppColors.border.opacity(0.28)

        switch orbitCount {

        case 1:
            // Single 120° arc — top of circle
            var arc = Path()
            arc.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR,
                startAngle: .degrees(-150),
                endAngle:   .degrees(-30),
                clockwise:  false
            )
            context.stroke(arc, with: .color(color), style: stroke)

        case 2:
            // Two offset arcs at different radii
            var arc1 = Path()
            arc1.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR * radiiFactors[0],
                startAngle: .degrees(-140),
                endAngle:   .degrees(20),
                clockwise:  false
            )
            context.stroke(arc1, with: .color(color), style: stroke)

            var arc2 = Path()
            arc2.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR * radiiFactors[1],
                startAngle: .degrees(-40),
                endAngle:   .degrees(120),
                clockwise:  false
            )
            context.stroke(arc2, with: .color(color), style: stroke)

        default:
            // Three full dim rings at decreasing radii
            for i in 0 ..< 3 {
                var ring = Path()
                ring.addEllipse(in: CGRect(
                    x: cx - baseR * radiiFactors[i],
                    y: cy - baseR * radiiFactors[i],
                    width:  baseR * radiiFactors[i] * 2,
                    height: baseR * radiiFactors[i] * 2
                ))
                context.stroke(
                    ring,
                    with: .color(isLight
                        ? AppColors.lightBorder.opacity(0.18)
                        : AppColors.border.opacity(0.18)),
                    style: stroke
                )
            }
        }
    }

    // MARK: - Active Draw

    private func drawActive(
        context: inout GraphicsContext,
        size:    CGSize,
        elapsed: Double
    ) {
        let cx    = size.width  / 2
        let cy    = size.height / 2
        let baseR = Double(size.width) * 0.36

        // Global angle — advances with time and speed multiplier
        let angle = elapsed * 2.6 * speed

        // Color cycle — full rotation over ~6 seconds
        let cyclePeriod: Double = 6.0
        let cycleRaw    = elapsed.truncatingRemainder(dividingBy: cyclePeriod)
        let cyclePhase  = cycleRaw / cyclePeriod   // 0.0 → 1.0
        let colorCount  = Double(cycleColors.count)
        let colorPos   = cyclePhase * colorCount
        let colorIndex = Int(colorPos) % cycleColors.count
        let colorFrac  = colorPos - Double(Int(colorPos))

        // Lerp the entire orbit color as a single unit.
        // All parts of the orbit — ring, tail, head — use this one value.
        func orbitColor(forIndex i: Int) -> Color {
            let base = cycleColors[(colorIndex + colorOffsets[i]) % cycleColors.count]
            let next = cycleColors[(colorIndex + colorOffsets[i] + 1) % cycleColors.count]
            // Simple crossfade — colorFrac drives the whole orbit simultaneously
            return colorFrac < 0.5 ? base : next
        }

        for i in 0 ..< orbitCount {
            let orbitR   = baseR * radiiFactors[i]
            let orbSpeed = speedMultipliers[i]
            let phaseOff = phaseOffsets[i]
            let headAngle = angle * orbSpeed + phaseOff

            // Dim full ring
            var ring = Path()
            ring.addEllipse(in: CGRect(
                x: cx - orbitR, y: cy - orbitR,
                width: orbitR * 2, height: orbitR * 2
            ))
            context.stroke(
                ring,
                with: .color(orbitColor(forIndex: i).opacity(0.07)),
                style: StrokeStyle(lineWidth: 1.0)
            )

            // Comet tail — segment-by-segment for opacity gradient
                let tailArc:   Double = .pi * 1.4
                let tailSteps: Int    = 80

            for s in 0 ..< tailSteps {
                let t      = Double(s) / Double(tailSteps)
                let segA   = headAngle - tailArc * (1.0 - t)
                let alpha  = t * 0.52
                let width  = 0.5 + t * 0.9

                let x1 = cx + cos(segA - 0.015) * orbitR
                let y1 = cy + sin(segA - 0.015) * orbitR
                let x2 = cx + cos(segA) * orbitR
                let y2 = cy + sin(segA) * orbitR

                var seg = Path()
                seg.move(to:    CGPoint(x: x1, y: y1))
                seg.addLine(to: CGPoint(x: x2, y: y2))

                context.stroke(
                    seg,
                    with: .color(orbitColor(forIndex: i).opacity(alpha)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
            }

            // Head glow — radial, accent color
            let hx   = cx + cos(headAngle) * orbitR
            let hy   = cy + sin(headAngle) * orbitR
            let glowR = Double(size.width) * 0.09 * glowScale

            let headGlow = Path(ellipseIn: CGRect(
                x: hx - glowR, y: hy - glowR,
                width: glowR * 2, height: glowR * 2
            ))
            context.fill(
                headGlow,
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.90),                    location: 0.00),
                        .init(color: orbitColor(forIndex: i).opacity(0.70),   location: 0.28),
                        .init(color: orbitColor(forIndex: i).opacity(0.00),   location: 1.00),
                    ]),
                    center:      CGPoint(x: hx, y: hy),
                    startRadius: 0,
                    endRadius:   glowR
                )
            )

            // White-hot dot
            let dotR = 1.8
            context.fill(
                Path(ellipseIn: CGRect(
                    x: hx - dotR, y: hy - dotR,
                    width: dotR * 2, height: dotR * 2
                )),
                with: .color(.white.opacity(0.95))
            )
        }
    }
}

// MARK: - Previews

#Preview("Dark — all counts, resting") {
    HStack(spacing: 24) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: 8) {
                TileOrbitView(orbitCount: count, isActive: false, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Dark — all counts, active") {
    HStack(spacing: 24) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: 8) {
                TileOrbitView(orbitCount: count, isActive: true, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light — all counts, active") {
    HStack(spacing: 24) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: 8) {
                TileOrbitView(orbitCount: count, isActive: true, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.lightTextTertiary)
            }
        }
    }
    .padding(40)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Tap to activate") {
    @Previewable @State var active = false
    VStack(spacing: 20) {
        TileOrbitView(orbitCount: 2, isActive: active, size: 88)
        Button(active ? "Deactivate" : "Activate") {
            withAnimation { active.toggle() }
        }
        .font(AppFonts.caption)
        .foregroundStyle(AppColors.textSecondary)
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Text/LivingText.swift` {#file-open-lightly-design-components-text-livingtext-swift}

```swift
import SwiftUI

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold)

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Gradient Stops
    //
    // Dark: clean three-stop directional gradient.
    // cyan left → purpleVivid mid → magenta right.
    // purpleVivid (9333EA) is bright enough to read as a
    // distinct color beat without muddying the transition.
    //
    // Light: directional warm sweep.
    // magenta left → orangeHot mid → gold right.

    private var gradientStops: [Color] {
        if colorScheme == .light {
            return [
                AppColors.magenta,
                AppColors.orangeHot,
                AppColors.gold,
            ]
        } else {
            return [
                AppColors.cyan,
                AppColors.purpleVivid,
                AppColors.magenta,
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                // Static gradient — respects color scheme.
                Text(text)
                    .font(font)
                    .foregroundStyle(LinearGradient(
                        colors: colorScheme == .light
                            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
                            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    // Glow breath — 4.3s cycle.
                    // Drives all three bloom layers in unison.
                    let glowCycle = 4.3
                    let glowPhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: glowCycle)
                        / glowCycle
                    )
                    let intensity = CGFloat(sin(glowPhase * .pi * 2) * 0.5 + 0.5)

                    // Scale breath — 5.0s cycle, independent of glow.
                    // Sub-perceptual as movement but adds physical presence.
                    let scaleCycle = 5.0
                    let scalePhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: scaleCycle)
                        / scaleCycle
                    )
                    let scaleIntensity = CGFloat(sin(scalePhase * .pi * 2) * 0.5 + 0.5)

                    // Tri-color glow — each color blooms at a different phase.
                    // On dark: cyan peaks at 0°, magenta at 120°, purple at 240°.
                    // The three glows are never in the same state simultaneously
                    // so the text always feels alive without a visible loop point.
                    let cyanPhase    = CGFloat(elapsed / 3.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let magentaPhase = CGFloat(elapsed / 4.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let midPhase     = CGFloat(elapsed / 5.0)
                        .truncatingRemainder(dividingBy: 1.0)

                    let cyanGlow    = CGFloat(sin(cyanPhase    * .pi * 2) * 0.5 + 0.5)
                    let magentaGlow = CGFloat(sin(magentaPhase * .pi * 2) * 0.5 + 0.5)
                    let midGlow     = CGFloat(sin(midPhase     * .pi * 2) * 0.5 + 0.5)

                    // Animated gradient — static stops, opacity of each color
                    // breathes independently via tri-color phase offsets.
                    let animatedStops: [Color] = colorScheme == .light
                        ? [
                            AppColors.magenta.opacity(0.75 + cyanGlow * 0.25),
                            AppColors.orangeHot.opacity(0.75 + midGlow * 0.25),
                            AppColors.gold.opacity(0.75 + magentaGlow * 0.25),
                          ]
                        : [
                            AppColors.cyan.opacity(0.70 + cyanGlow * 0.30),
                            AppColors.purpleVivid.opacity(0.70 + midGlow * 0.30),
                            AppColors.magenta.opacity(0.70 + magentaGlow * 0.30),
                          ]

                    let baseGradient = LinearGradient(
                        colors: animatedStops,
                        startPoint: .leading,
                        endPoint:   .trailing
                    )

                    let glowOpacity = colorScheme == .light
                        ? 0.20 + Double(intensity) * 0.22
                        : 0.28 + Double(intensity) * 0.30

                    let glowBlur = colorScheme == .light
                        ? 5.0 + intensity * 4.0
                        : 8.0 + intensity * 7.0

                    // Scale breath — 1.000 → 1.008, barely perceptible.
                    let breathScale = colorScheme == .light
                        ? 1.0 + scaleIntensity * 0.008
                        : 1.0 + scaleIntensity * 0.010

                    ZStack {
                        // Outer bloom — wide, atmospheric.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 1.6)
                            .opacity(glowOpacity * 0.40)
                            .accessibilityHidden(true)

                        // Inner glow — tighter halo ring.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 0.45)
                            .opacity(glowOpacity * 0.80)
                            .accessibilityHidden(true)

                        // Primary crisp layer — full opacity, no blur.
                        // Scale breath applied here only so blur layers
                        // do not scale (which would spread them too wide).
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .scaleEffect(breathScale)
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityLabel(text)
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
            LivingText(text: "Easier",
                       font: AppFonts.screenTitle)
            LivingText(text: "You're in good company.",
                       font: AppFonts.body(20, weight: .bold))
        }
        .padding(28)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
        }
        .padding(28)
    }
    .preferredColorScheme(.light)
}

#Preview("Against atmosphere — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        Ellipse()
            .fill(RadialGradient(
                colors: [
                    AppColors.magenta.opacity(0.30),
                    AppColors.purple.opacity(0.15),
                    Color.clear,
                ],
                center: .top,
                startRadius: 30,
                endRadius: 360
            ))
            .frame(width: 500, height: 400)
            .offset(y: -200)
            .blur(radius: 80)
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                LivingText(text: "exploring?", font: AppFonts.heroTitle)
            }
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Text/GradientText.swift` {#file-open-lightly-design-components-text-gradienttext-swift}

```swift
// GradientText.swift
// Open Lightly
// Static gradient text — no animation, no shimmer

import SwiftUI

struct GradientText: View {
    let text: String
    let font: Font
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            AppColors.magentaDark,
                            AppColors.magenta,
                            AppColors.orangeHot
                          ]
                        : [
                            AppColors.pink,
                            AppColors.purple,
                            AppColors.magenta
                          ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

```

---

## File: `Open Lightly/Design/Components/Text/KeywordHighlightText.swift` {#file-open-lightly-design-components-text-keywordhighlighttext-swift}

```swift
//
//  KeywordHighlightText.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - KeywordHighlightText — keyword highlighting
struct KeywordHighlightText: View {
    let fullText: String
    let keywords: [(text: String, type: String)]
    var font: Font = AppFonts.cardTitle
    var baseColor: Color = AppColors.textPrimary

    private func highlightUIColor(for type: String) -> UIColor {
        switch type.lowercased() {
        case "cyan": return UIColor(AppColors.cyan)
        case "magenta": return UIColor(AppColors.magenta)
        case "gold": return UIColor(AppColors.gold)
        default: return UIColor(baseColor)
        }
    }

    var body: some View {
        Text(buildAttributedString())
            .font(font)
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(fullText)
        result.font = font
        result.foregroundColor = UIColor(baseColor)
        for keyword in keywords {
            var searchRange = result.startIndex..<result.endIndex
            while let range = result[searchRange].range(of: keyword.text, options: .caseInsensitive) {
                result[range].foregroundColor = highlightUIColor(for: keyword.type)
                if range.upperBound < result.endIndex {
                    searchRange = range.upperBound..<result.endIndex
                } else {
                    break
                }
            }
        }
        return result
    }
}

// MARK: - Preview
#Preview {
    KeywordHighlightText(
        fullText: "What does vulnerability look like when you feel truly safe?",
        keywords: [
            (text: "vulnerability", type: "cyan"),
            (text: "truly safe", type: "magenta")
        ]
    )
    .padding()
    .background(AppColors.pageBg)
}

```

---

## File: `Open Lightly/Design/Components/Input/InteractiveField.swift` {#file-open-lightly-design-components-input-interactivefield-swift}

```swift
//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct InteractiveField: View {
    @Environment(\.theme) private var t
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 13))
            TextField(placeholder, text: $text)
                .font(.system(size: 12))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            t.isAmoled ? .white.opacity(0.03) : t.surface1
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(t.cardBorder, lineWidth: 1.5)
        )
        .shadow(
            color: t.isAmoled ? t.glowCyan : .clear,
            radius: 6
        )
    }
}
```

---

## File: `Open Lightly/Design/Components/PillBorder.swift` {#file-open-lightly-design-components-pillborder-swift}

```swift
import SwiftUI

// ─────────────────────────────────────────────
// MARK: Border Glow Tier
//
// Semantic intensity scale for all three border modifiers.
// Pass `tier:` to override explicit lineWidth/glowRadius/opacity
// as a set. When nil, the explicit parameters are used as-is,
// so all existing call sites remain unchanged.
//
// Usage:
//   .pillBorder(tier: .structural)   // ambient card borders
//   .pillBorder(tier: .interactive)  // selected pills, active states
//   .pillBorder(tier: .primary)      // CTA buttons, conversion moments
// ─────────────────────────────────────────────

enum BorderGlowTier {
    case structural   // ambient card borders, always visible
    case interactive  // selected pills, floating cards, active states
    case primary      // CTA buttons, conversion moments

    var lineWidth: CGFloat {
        switch self {
        case .structural:  return 1.5
        case .interactive: return 2.0
        case .primary:     return 2.5
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .structural:  return 3
        case .interactive: return 6
        case .primary:     return 10
        }
    }

    var opacity: Double {
        switch self {
        case .structural:  return 0.45
        case .interactive: return 0.75
        case .primary:     return 0.90
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Dark Mode — Spectrum Pill Border
// Unchanged. Used on all dark mode selected/active states.
// cyan → purple → magenta, topLeading → bottomTrailing
// ─────────────────────────────────────────────

/// Shared holographic pill border — single source of truth.
struct PillBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 3
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.8
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth  = tier?.lineWidth  ?? lineWidth
        let activeGlowRadius = tier?.glowRadius ?? glowRadius
        let activeOpacity    = tier?.opacity    ?? opacity

        let gradient = LinearGradient(
            colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: activeLineWidth + 1)
                    .blur(radius: activeGlowRadius)
                    .opacity(0.35)
            )
            .shadow(color: AppColors.purple.opacity(0.18), radius: 6)
            .shadow(color: AppColors.cyan.opacity(0.08),   radius: 12)
            .shadow(color: AppColors.purple.opacity(0.06), radius: 16)
    }
}

extension View {
    func pillBorder(
        cornerRadius: CGFloat    = 100,
        lineWidth: CGFloat       = 3,
        glowRadius: CGFloat      = 6,
        opacity: Double          = 0.8,
        tier: BorderGlowTier?    = nil
    ) -> some View {
        modifier(PillBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity,
            tier: tier
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Warm Aurora Border
//
// Used on ALL light mode selected/active states.
// Replaces .pillBorder() when colorScheme == .light.
//
// Gradient: AppColors.warmAuroraBorder
//   purple → magenta → gold, topLeading → bottomTrailing
//
// Key differences from dark PillBorder:
//   - No blur overlay — blur is invisible on cream, adds muddiness
//   - Shadows replaced with colored spread (shadow IS the glow on light)
//   - Default lineWidth 2.5 vs 3 — slightly finer on cream reads better
//   - Default opacity 0.82 — higher than dark because no glow canvas to boost it
//
// Usage:
//   .warmAuroraBorder()                         // pills, fields, cards
//   .warmAuroraBorder(cornerRadius: 20)         // rounded rect cards
//   .warmAuroraBorder(lineWidth: 3, opacity: 0.95) // CTA buttons
// ─────────────────────────────────────────────

struct WarmAuroraBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var opacity: Double       = 0.82
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth = tier?.lineWidth ?? lineWidth
        let activeOpacity   = tier?.opacity   ?? opacity

        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
    }
}

extension View {
    func warmAuroraBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        opacity: Double       = 0.82,
        tier: BorderGlowTier? = nil
    ) -> some View {
        modifier(WarmAuroraBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            opacity: opacity,
            tier: tier
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Magenta Gold Border
//
// Used on light mode pill selected states and LivingText
// contexts where the magentaGold palette is active.
//
// Gradient: magenta → orangeHot → gold
//   #FF006A 0% → #E07020 55% → #C8960A 100%
//   topLeading → bottomTrailing
//
// The 0.55 mid-stop extends the hot pink longer before
// amber arrives — mirrors the VQ-08 principle from the
// progress bar fill gradient.
//
// Glow pattern mirrors PillBorder exactly:
//   - Crisp stroke overlay at `opacity`
//   - Blurred duplicate at lineWidth+1, blur glowRadius, opacity 0.35
//     (same structure as dark PillBorder blur overlay)
//   - Three shadow spread layers: magenta tight, orangeHot mid, gold wide
//
// Usage:
//   .magentaGoldBorder()                          // pills — default
//   .magentaGoldBorder(cornerRadius: 20)          // rounded rect cards
//   .magentaGoldBorder(lineWidth: 3, opacity: 0.90) // CTA weight
// ─────────────────────────────────────────────

private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,    location: 0.00),
        .init(color: AppColors.orangeHot,  location: 0.55), // VQ-08: extended pink zone
        .init(color: AppColors.gold,       location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

struct MagentaGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.82
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth  = tier?.lineWidth  ?? lineWidth
        let activeGlowRadius = tier?.glowRadius ?? glowRadius
        let activeOpacity    = tier?.opacity    ?? opacity

        return content
            // Crisp gradient stroke
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            // Blurred duplicate — mirrors PillBorder glow overlay pattern.
            // Visible on cream because the gradient is warm and saturated.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: activeLineWidth + 1)
                    .blur(radius: activeGlowRadius)
                    .opacity(0.35)
            )
            // Shadow spread — three layers, same pattern as WarmAuroraBorder.
            // Magenta: tight warm halo. OrangeHot: mid warmth. Gold: wide soft glow.
            .shadow(color: AppColors.magenta.opacity(0.18),   radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.orangeHot.opacity(0.12), radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.gold.opacity(0.08),      radius: 6,  x: 0, y: 2)
    }
}

extension View {
    /// Light mode magenta → amber → gold border.
    /// Use on pill selected states that pair with the magentaGold
    /// LivingText palette, and anywhere the warm ember identity
    /// is stronger than the purple aurora identity.
    ///
    /// - Parameters:
    ///   - cornerRadius: Match the shape. Default 100 (pill).
    ///   - lineWidth: Default 2.5. Use 3.0 for CTA weight.
    ///   - glowRadius: Default 6. Blur radius of the glow duplicate overlay.
    ///   - opacity: Default 0.82. Use 0.90 for CTA. Use 0.65 for resting borders.
    ///   - tier: Optional semantic tier — overrides lineWidth, glowRadius, opacity as a set.
    func magentaGoldBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        glowRadius: CGFloat   = 6,
        opacity: Double       = 0.82,
        tier: BorderGlowTier? = nil
    ) -> some View {
        modifier(MagentaGoldBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity,
            tier: tier
        ))
    }
}

```

---

## File: `Open Lightly/Design/Components/CardStyle.swift` {#file-open-lightly-design-components-cardstyle-swift}

```swift
import SwiftUI

/// Reusable card-shell modifier: background + rounded clip + border stroke.
///
/// Replaces the repetitive 3-line pattern scattered across views:
/// ```swift
/// .background(AppColors.card)
/// .clipShape(RoundedRectangle(cornerRadius: 20))
/// .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.border, lineWidth: 1))
/// ```
///
/// Usage:
/// ```swift
/// VStack { ... }
///     .cardStyle()                          // defaults: card bg, r20, border stroke
///     .cardStyle(cornerRadius: 12)          // custom radius
///     .cardStyle(background: .surfaceBg)    // custom bg
/// ```
struct CardStyle: ViewModifier {
    var background: Color = AppColors.card
    var cornerRadius: CGFloat = 20
    var borderColor: Color = AppColors.border
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: lineWidth)
            )
    }
}

extension View {
    func cardStyle(
        background: Color = AppColors.card,
        cornerRadius: CGFloat = 20,
        borderColor: Color = AppColors.border,
        lineWidth: CGFloat = 1.5
    ) -> some View {
        modifier(CardStyle(
            background: background,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            lineWidth: lineWidth
        ))
    }
}

```

---

## File: `Open Lightly/Design/Components/NavArrow.swift` {#file-open-lightly-design-components-navarrow-swift}

```swift
// NavArrow.swift
// Open Lightly
//
// Pill nav arrow — adaptive dark/light.
// Dark:  pillBorder()       (cyan → purple → magenta) border + arrow
// Light: warmAuroraBorder() border, magenta → orangeHot → gold arrow

import SwiftUI

// MARK: - Enums

enum ArrowDirection {
    case back
    case forward
}

enum OnboardingArrowStyle {
    case aurora
    case magentaGold
}

// MARK: - Size Constants

extension CGSize {
    /// Top nav bar weight — sits beside progress indicator
    static let navArrowTopBar = CGSize(width: 80, height: 44)
    /// Compact nav bar — smaller screens or tighter headers  //
      static let navArrowCompact = CGSize(width: 56, height: 32)
}

// MARK: - Shared Gradients

/// Dark mode — arrow + border: cyan → purple → magenta
private let spectrumGradient = LinearGradient(
    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

/// Light mode — arrow: magenta → orangeHot → gold
private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,   location: 0.00),
        .init(color: AppColors.orangeHot, location: 0.55),
        .init(color: AppColors.gold,      location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

// MARK: - NavArrowShape
// Direct port of the HTML SVG — viewBox 0 0 48 48
//
// Chevron top arm : (22,10) → (10,24)
// Chevron bot arm : (10,24) → (22,38)
// Upper line      : (14,20) → (38,20)
// Lower line      : (14,28) → (38,28)

struct NavArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // ── Chevron top arm: (22,10) → (10,24)
        path.move(to:    CGPoint(x: w * (22/48), y: h * (10/48)))
        path.addLine(to: CGPoint(x: w * (10/48), y: h * (24/48)))

        // ── Chevron bot arm: (10,24) → (22,38)
        path.addLine(to: CGPoint(x: w * (22/48), y: h * (38/48)))

        // ── Upper line: (14,20) → (38,20)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (20/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (20/48)))

        // ── Lower line: (14,28) → (38,28)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (28/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (28/48)))

        return path
    }
}

// MARK: - GradientStrokeArrow

struct GradientStrokeArrow: View {
    var gradient:     LinearGradient
    var strokeWidth:  CGFloat = 2.8
    var shadowColor1: Color
    var shadowColor2: Color

    var body: some View {
        NavArrowShape()
            .stroke(
                gradient,
                style: StrokeStyle(
                    lineWidth:  strokeWidth,
                    lineCap:    .round,
                    lineJoin:   .round
                )
            )
            .shadow(color: shadowColor1.opacity(0.55), radius: 5)
            .shadow(color: shadowColor2.opacity(0.30), radius: 10)
    }
}

// MARK: - DarkNavArrow
//
// Parameter order: size → action (enables trailing closure, fixes init ordering)
//
// Pill:  surfaceBg fill at 0.85 opacity + pillBorder() spectrum border
// Arrow: spectrumGradient (cyan → purple → magenta)
// Glow:  blurred border duplicate at 0.50 opacity
// strokeWidth scales proportionally with pill height.

struct DarkNavArrow: View {
    var size:   CGSize = .navArrowCompact  // ← first
    var action: () -> Void                // ← last, enables trailing closure

    // Stroke scales with height — 1.8 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 1.8
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.surfaceBg.opacity(0.85))
                    .frame(width: size.width, height: size.height)

                // ── Crisp spectrum border via existing modifier
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .pillBorder()

                // ── Blurred glow border duplicate
                Capsule()
                    .strokeBorder(spectrumGradient, lineWidth: 4)
                    .blur(radius: 7)
                    .opacity(0.50)
                    .frame(width: size.width, height: size.height)

                // ── Arrow glyph — spectrum, 65% of pill
                GradientStrokeArrow(
                    gradient:     spectrumGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.cyan,
                    shadowColor2: AppColors.purple
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
            .shadow(color: AppColors.cyan.opacity(0.12),   radius: 20)
            .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightNavArrow
//
// Parameter order: size → style → action (enables trailing closure, fixes init ordering)
//
// Pill:  lightCardBg fill + warmAuroraBorder() or magentaGoldBorder()
// Arrow: magentaGoldGradient (magenta → orangeHot → gold)
// Glow:  coloured spread shadows
// strokeWidth scales proportionally with pill height.

struct LightNavArrow: View {
    var size:   CGSize               = .navArrowCompact  // ← first
    var style:  OnboardingArrowStyle = .magentaGold     // ← second
    var action: () -> Void                              // ← last, enables trailing closure

    // Stroke scales with height — 2.1 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 2.1
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.lightCardBg)
                    .frame(width: size.width, height: size.height)

                // ── Border — aurora or magentaGold
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .modifier(LightBorderModifier(style: style))

                // ── Arrow glyph — magenta gold, 65% of pill
                GradientStrokeArrow(
                    gradient:     magentaGoldGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.magenta,
                    shadowColor2: AppColors.orangeHot
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.lightShadowMagenta.opacity(0.35), radius: 10, x: 0, y: 4)
            .shadow(color: AppColors.lightShadowPurple.opacity(0.22),  radius: 20, x: 0, y: 6)
            .shadow(color: AppColors.lightShadowGold.opacity(0.18),    radius: 8,  x: 0, y: 2)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightBorderModifier

private struct LightBorderModifier: ViewModifier {
    let style: OnboardingArrowStyle

    func body(content: Content) -> some View {
        switch style {
        case .aurora:
            content.warmAuroraBorder()
        case .magentaGold:
            content.magentaGoldBorder()
        }
    }
}

// MARK: - OnboardingNavArrow (Adaptive Wrapper)

/// Single drop-in component for all onboarding back/forward navigation.
/// Reads colorScheme automatically.
/// Mirrors horizontally for forward direction.
///
/// Usage (ModeSelectView and all onboarding screens):
///   OnboardingNavArrow(direction: .back)    { goBack() }
///   OnboardingNavArrow(direction: .forward) { goNext() }

struct OnboardingNavArrow: View {
    var direction: ArrowDirection                          // ← first
    var size:      CGSize               = .navArrowTopBar // ← second
    var style:     OnboardingArrowStyle = .magentaGold    // ← third, light mode only
    var action:    () -> Void                             // ← last, enables trailing closure

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                DarkNavArrow(size: size, action: action)
            } else {
                LightNavArrow(size: size, style: style, action: action)
            }
        }
        .scaleEffect(x: direction == .forward ? -1 : 1)
        .accessibilityLabel(direction == .back ? "Go back" : "Continue")
    }
}

// MARK: - Previews

#Preview("NavArrow Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("NavArrow Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/OrbitSparkBorderView.swift` {#file-open-lightly-design-components-orbitsparkborderview-swift}

```swift
//
//  OrbitSparkBorderView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/24/26.
//


//
//  OrbitSparkBorderView.swift
//  Open Lightly
//

import SwiftUI

struct OrbitSparkBorderView: View {

    let size:         CGSize
    let cornerRadius: CGFloat
    let borderWidth:  CGFloat
    let colorScheme:  ColorScheme

    @State private var startDate = Date()

    private var borderGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
              )
            : AppColors.warmAuroraBorder   // purple → magenta → gold
    }

    // NEW: tells the Metal shader which palette to use
    private var colorMode: Float {
        colorScheme == .dark ? 0.0 : 1.0
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderGradient, lineWidth: borderWidth)
                .colorEffect(
                    ShaderLibrary.orbitSpark(
                        .float2(size),
                        .float(elapsed),
                        .float(Float(borderWidth)),
                        .float(Float(cornerRadius)),
                        .float(colorMode)    // NEW argument
                    )
                )
                .frame(width: size.width, height: size.height)
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/SectionHeader.swift` {#file-open-lightly-design-components-sectionheader-swift}

```swift
import SwiftUI

/// All-caps muted label used above sections in Settings, Home, and list screens.
/// Usage: `SectionHeader("PROFILE")`
struct SectionHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppFonts.sectionHeader)
            .foregroundColor(AppColors.textMuted)
    }
}

```

---

## File: `Open Lightly/Design/Components/OrbitSpark.metal` {#file-open-lightly-design-components-orbitspark-metal}

```metal
//
//  OrbitSpark.metal
//  Open Lightly
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 orbitSpark(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    float borderWidth,
    float cornerRadius,
    float colorMode     // 0.0 = dark, 1.0 = light
) {
    float2 center = size * 0.5;
    float2 p = position - center;

    float2 d = abs(p) - (center - cornerRadius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cornerRadius;

    float borderMask = 1.0 - smoothstep(0.0, 1.5, abs(dist) - borderWidth * 0.5);

    float angle = atan2(p.y, p.x);

    float orbitSpeed = 0.45;
    float orbitAngle = fmod(time * orbitSpeed * 2.0 * M_PI_F, 2.0 * M_PI_F) - M_PI_F;

    float angleDiff = angle - orbitAngle;
    angleDiff = angleDiff - 2.0 * M_PI_F * round(angleDiff / (2.0 * M_PI_F));

    float sparkWidth = 0.7;
    float spark = smoothstep(sparkWidth, 0.0, abs(angleDiff));
    spark = pow(spark, 2.0);

    float t = clamp(angleDiff / sparkWidth + 0.5, 0.0, 1.0);

    // Dark mode colors
    half3 darkA = half3(0.0,  0.76, 1.0);   // cyan    #00C2FF
    half3 darkB = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 darkC = half3(1.0,  0.0,  0.42);  // magenta #FF006A

    // Light mode colors (warm aurora)
    half3 lightA = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 lightB = half3(1.0,  0.0,  0.42);  // magenta #FF006A
    half3 lightC = half3(0.78, 0.59, 0.04);  // gold    #C8960A

    half3 colorA = mix(darkA, lightA, half(colorMode));
    half3 colorB = mix(darkB, lightB, half(colorMode));
    half3 colorC = mix(darkC, lightC, half(colorMode));

    half3 sparkColor = mix(colorA, colorB, half(t));
    sparkColor = mix(sparkColor, colorC, half(t * t));

    // Hot white core — stays white in both modes
    float core = smoothstep(0.15, 0.0, abs(angleDiff));
    sparkColor = mix(sparkColor, half3(1.0), half(core * 0.5));

    float alpha = spark * borderMask;

    return currentColor + half4(sparkColor * half(alpha), half(alpha));
}

```

---

