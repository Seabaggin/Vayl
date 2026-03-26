# Open Lightly — File Tracker

> Last updated: 2026-03-20
> 101 Swift files across 16 directories

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
| **`AppColors.swift`** | Full color palette as static `Color` constants plus a `Color(hex:)` initializer. Single source of truth for every color token in the app. | **`FOUNDATION`** |
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
| **`ProfileService.swift`** | Reads/writes user profile data to Supabase `profiles` table. Inner `SupabaseProfile` Codable struct for JSON mapping. Uses `ObservableObject` (legacy). | |
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
| **`GradientButton.swift`** | Full-width gradient CTA button. Uses `t.buttonGradient`. Glow shadow adapts between amoled and light. |
| **`HoloCTAButton.swift`** | Primary onboarding CTA. Dark: holographic shimmer + pill border + bloom. Light: warm aurora shimmer + shadow spread. References `HolographicShimmer`, `LightModeShimmer`, `PillBorder`. |
| **`SafeWordButton.swift`** | Always-visible safety button during sessions. Shows confirmation alert before triggering the safe-word callback. |
| **`SelectablePill.swift`** | Toggle pill for multi-select lists (onboarding pickers). Three intensity levels. Dark: holo shimmer + flame aura. Light: aurora shimmer + shadow. |

### `Card/`

| File | What It Does |
|---|---|
| **`CategoryTileView.swift`** | Home-screen grid tile. Emoji, name, card count, and a `ProgressBar` for one category. |
| **`PromptCard.swift`** | Renders a single conversation prompt card with difficulty-keyed styling (background tint, border opacity, glow color). |
| **`SettingsCard.swift`** | Generic `<Content: View>` container. Wraps content in a padded `.cardStyle()` shell for Settings and list screens. |

### `Cards/` *(Context cards — onboarding screen 4)*

| File | What It Does |
|---|---|
| **`ContextCard.swift`** | Single card in the context-select stack. Gradient background + internal glow + breathing animation keyed to `ContextIntensity`. |
| **`ContextCardStack.swift`** | Gesture-driven infinite-scroll card stack. Swipe to browse, tap to confirm. Auto-advances 0.8s after selection. |
| **`ContextIntensity.swift`** | Six intensity levels (ember → nova) mapping to visual properties: gradient tint, glow size, border opacity, shadow. |
| **`ContextOption.swift`** | Plain data model for one context card. Holds `RelationshipContext`, `ContextIntensity`, title, subtitle, detail. |

### `Effects/`

| File | What It Does |
|---|---|
| **`AuroraGlowField.swift`** | Light mode atmospheric blob background. 6 blobs in magenta/purple/gold/pink at 6–9% opacity. Light mode counterpart to `OnboardingGlowField`. |
| **`FlameAura.swift`** | Flame-wisp particle effect for selected `SelectablePill`s in dark mode. Intensity-driven sizing. |
| **`GlowFieldView.swift`** | Multi-blob animated glow field. Parent-driven `blobVisible`/`blobPhase` arrays (8 blobs in cyan/purple/magenta/gold). |
| **`GlowOrb.swift`** | Single blurred radial-gradient circle. Opacity from `t.glowOpacity`. Decorative accent. |
| **`HolographicShimmer.swift`** | Animated 3x-wide cyan→purple→magenta→pink gradient that sweeps L→R. Dark mode overlay, clipped to any shape. |
| **`LightModeShimmer.swift`** | Light mode counterpart to `HolographicShimmer`. `AppColors.lightShimmerColors` at 7–11% opacity, 11s sweep cycle. |
| **`OnboardingGlowField.swift`** | Dark mode animated glow blob field for all onboarding screens. Self-managing animation state (7 blobs). |
| **`SparkField.swift`** | Canvas-based campfire ember particle system for light mode. Multiple screen-specific configs (`.statView`, `.nameView`, `.modeSelectView`, etc.). |

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
| **`OnboardingProgressBar.swift`** | Highly refined animated progress bar for onboarding. Dual-mode (light/dark). Bloom glow, holographic shimmer fill, atmospheric gradient, breathing pulse. Extensive VQ changelog. |
| **`ProgressBar.swift`** | Simple themed horizontal bar. `t.buttonGradient` fill on a muted track. |
| **`ProgressRingView.swift`** | Circular progress ring. Configurable line width and size. Track adapts to amoled/light. |
| **`ScoreRing.swift`** | Circular ring displaying a 0–100 score. Animates fill on appear via `t.ringGradient`. |
| **`SpectrumBar.swift`** | Thin capsule filled with `t.spectrumGradient`. Decorative separator/accent. |

### `Text/`

| File | What It Does |
|---|---|
| **`KeywordHighlightText.swift`** | Renders text with specific keywords highlighted in cyan/magenta/gold via `NSAttributedString`. Used on prompt cards. |
| **`LivingText.swift`** | Animated gradient text with breathing glow. `TimelineView` at 30fps, RTL-aware, dual-mode. The animated text identity for the app. |

### Misc Components

| File | What It Does |
|---|---|
| **`CardStyle.swift`** | `ViewModifier`. Reusable card shell: background + rounded clip + border stroke. Replaces the repetitive 3-line pattern across views. |
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
| **`DesireMapView.swift`** | Desire map UI. Expandable category list where users privately rate intimacy items with `DesireLevel`. Placeholder data pending full persistence batch. |

### `Explore/`

| File | What It Does |
|---|---|
| **`ExploreView.swift`** | Content discovery hub. **Stub** — renders a label only. Full implementation deferred. |

### `Home/`

| File | What It Does |
|---|---|
| **`HomeView.swift`** | Thin router. Switches on `appState.experienceType` → renders matching home view variant. Zero business logic. |
| **`HomeViewSingle.swift`** | Home screen for solo users with no partner. **Stub** — centered label only. |
| **`HomeViewSolo.swift`** | Home screen for solo users who have a partner. **Stub** — centered label only. |
| **`HomeViewCoupleNew.swift`** | Home screen for couples new to ENM. **Stub** — centered label only. |
| **`HomeViewCoupleExp.swift`** | Home screen for couples with existing ENM experience. **Stub** — centered label only. |

### `MeUs/`

| File | What It Does |
|---|---|
| **`MeUsView.swift`** | Personal profile + partner connection hub. Tab label adapts ("Me" for solo, "Us · Me" for couple). **Stub** — label only. |

### `More/`

| File | What It Does |
|---|---|
| **`MoreView.swift`** | Settings / account / support hub. Also the sole visible screen for guest/browsing users. **Stub** — label only. |

### `Onboarding/Data/`

| File | What It Does |
|---|---|
| **`OnboardingData.swift`** | The single mutable data bag threaded through the entire onboarding flow. Holds name, pronouns, mode, relationship context, curiosity selections, experience level, ground rules timestamp, and completion flag. |
| **`OnboardingTokens.swift`** | Static color + font constants scoped to onboarding. Older token system predating `AppColors`/`AppFonts`. |
| **`CuriosityScreenConfig.swift`** | Config model driving `OnboardingCuriosityPickerView`. Two sections of labels, sublabels, option arrays, visibility flags. Derived from `OnboardingData`. |
| **`ExperienceLevel.swift`** | Binary enum: `.curious` (foundational, slower pacing) vs `.experienced` (skip basics, deeper faster). `Codable`, `CaseIterable`. |

### `Onboarding/Views/`

| File | Screen | What It Does |
|---|---|---|
| **`OnboardingFlowView.swift`** | *Coordinator* | Flow coordinator. Defines the 8-step sequence, manages transitions, derives `ExperienceType` on completion, writes to `AppState`, sets `hasCompletedOnboarding`. |
| **`OnboardingStatView.swift`** | Screen 0 | Trust trigger. Large emotional statistic with animated holographic glow + tap-to-expand citation + ethos statement before CTA. |
| **`OnboardingBrandView.swift`** | Screen 0.5 | Animated brand reveal (auto-advance). Beam widths, opacities, wisp particles, center glow. Calls `onFinished` when complete. |
| **`OnboardingNameView.swift`** | Screen 1 | Name + pronouns entry. Glass-style text field, pronoun pill selector, custom pronoun field. |
| **`OnboardingModeSelectView.swift`** | Screen 2 | Solo vs. Couple mode + NM experience level (curious / exploring / experienced). Drives remainder of flow branching. |
| **`OnboardingContextView.swift`** | Screen 4 | Relationship context picker. Solo: 3 cards. Couple: 4 cards. Uses `ContextCardStack`. Auto-advances after selection. |
| **`OnboardingCuriosityPickerView.swift`** | Screen 5 | Two-section interest + intent picker. Config from `OnboardingData`. Uses `SelectablePill`. |
| **`OnboardingBuildingPathView.swift`** | Screen 7 | Non-interactive "Building your path" processing animation. Derives `defaultDifficulty` from `nmStage`. Auto-advances. |
| **`OnboardingGroundRulesView.swift`** | Screen 8 | Must-acknowledge ethical framing. No back, no skip. Writes acceptance timestamp + completion flags, then calls `onFinished`. |
| **`OnboardingView.swift`** | *(Legacy)* | Older/alternate onboarding entry point (pre-flow refactor). Two `GlowOrb`s + welcome message. Likely superseded by `OnboardingFlowView`. |
| **`PairingForkView.swift`** | *(Couple fork)* | Couple-only decision: "Pair Now" (inline pairing) or "Pair Later" (skip to Settings). No data saving — closures only. |

### `Progress/`

| File | What It Does |
|---|---|
| **`ProgressDashboardView.swift`** | Progress dashboard. Reads `StreakRecord` + `SessionRecord` from SwiftData via `DataStore`. Header, score section, category breakdown. Placeholder category metadata. |

### `Sessions/`

| File | What It Does |
|---|---|
| **`SessionView.swift`** | Active session screen. Prompt cards one at a time with swipe nav, tracks `CardStatus`, supports safe word, saves `SessionRecord` to SwiftData on completion. |

### `Settings/`

| File | What It Does |
|---|---|
| **`SettingsView.swift`** | Settings screen. Partner name, pairing code, screenshot toggle, haptic toggle, theme picker nav, reset/export actions. |
| **`ThemePickerView.swift`** | Compact inline picker for three theme modes. Taps update `ThemeManager.mode` with animation. |
| **`ThemeTestView.swift`** | `#if DEBUG` only. Visual test harness rendering accent swatches + all UI components + theme picker to verify the design system. |

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
| **`Card.swift`** | Single conversation prompt card for a session. Fields: card type, `isFree`, `sortOrder`, `difficulty`. Order is clinically meaningful — never shuffled. |
| **`ContentAssessmentQuestion.swift`** | One of 20 assessment questions (5 domains x 4). Types: scale (1–5 Likert) or multi-select. Answers live in `AssessmentResponse`, not here. |
| **`ContentCard.swift`** | Read-only content model for a conversation card within a category. Per-card progress tracked separately in `CardProgress`. |
| **`ContentCategory.swift`** | One of the 6 topic categories. Progress tracking lives in SwiftData, not here. |
| **`ContentDesireItem.swift`** | One item on the Desire Map. "Not For Me" ratings are never revealed to partners — alignment engine returns `.boundary`. |
| **`DesireItem.swift`** | Runtime Desire Map item with `computeAlignment` method. Implements the full alignment matrix. `.notForMe` from either partner always yields `.boundary`. |
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
| `Design/Components/` | 28 |
| `Features/Auth/` | 1 |
| `Features/Compatibility/` | 1 |
| `Features/Explore/` | 1 |
| `Features/Home/` | 5 |
| `Features/MeUs/` | 1 |
| `Features/More/` | 1 |
| `Features/Onboarding/` | 15 |
| `Features/Progress/` | 1 |
| `Features/Sessions/` | 1 |
| `Features/Settings/` | 3 |
| `Models/Content/` | 7 |
| `Models/Enums/` | 3 |
| `Models/Persistence/` | 3 |
| `Models/Progress/` | 8 |
| **Total** | **99** |
