# Open Lightly — File Tracker

> Last updated: 2026-04-04
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
| **`AppColors.swift`** | Full color palette as static `Color` constants plus a `Color(hex:)` initializer. Single source of truth for every color token in the app. All light-mode tokens (`lightCardTitle`, `lightCardDetail`, `lightCardFill`, etc.) and dark-mode tokens are defined here and documented in DESIGN_DOC.md. **⚠️ Contains 10 unused tokens** (`purpleBright`, `electricViolet`, `cyanDark`, `deepPurple`, `surfaceRaised`, `textQuaternary`, `btnGhostBorder`, `btnGhostText`, `badgeBg`, `destructive`) — candidates for removal. | **`FOUNDATION`** |
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
