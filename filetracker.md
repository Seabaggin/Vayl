# Codebase File Tracker & Audit Report
**Last Updated:** 2026-04-28
**Total Files:** ~158 Swift files
**Last Full Audit:** 2026-04-12 (partial refresh 2026-04-28 — inventory updated, issues inherited)
**Branch:** feat/home-redesign-onboarding-polish

---

## What Changed Since Last Audit (2026-04-28 refresh)

| Change | Detail |
|--------|--------|
| Project renamed | Open Lightly → Vayl (all paths updated) |
| `App/Open_LightlyApp.swift` | → `App/VaylApp.swift` |
| `Data/Store/ModelContainer.swift` | Moved → `App/ModelContainer.swift` |
| `Models/Content/` | Complete rewrite: ContentCard + Prompt + ContentAssessmentQuestion + ContentDesireItem + ContentCategory all deleted; replaced by `Card.swift` + `Deck.swift` |
| `Models/Enums/ExperienceType.swift` | Deleted |
| `Models/Persistence/` | RatingRecord + StreakRecord deleted; Added AcknowledgementRecord, LockInSession, MilestoneRecord; PulseStore moved here from old Models/Pulse/ |
| `Models/Pulse/` folder | Dissolved: PulseEntry → `Models/Progress/`, PulseStore → `Models/Persistence/`, PulseWindow → absorbed into AppEnums |
| `Models/Progress/` | Removed AssessmentResponse, AssessmentResult, CardProgress, CoupleSessionRecord; Added CardSession, DeckProgress, EntitlementRecord, PulseEntry |
| `Core/Services/AssessmentSyncService.swift` | Deleted |
| `Core/Services/AppState.swift` | New |
| `Design/Components/Banners/` | GuestBannerView.swift deleted — folder now empty |
| `Design/Brand/VaylAppIcon.swift` | New |
| `App/Theme/ColorRow.swift` | New |
| `AppIconRetreival.swift` | New (at Vayl/ root) |
| `Features/Explore/ExploreView.swift` | Deleted |
| `Features/Home/Components/CardChestContainer.swift` | New |
| `Features/Home/Components/GravLiftView.swift` | New |
| `Features/Learn/ConstellationNode.swift` | New |
| `Features/Map/PrismView.swift` | New |

---

## Audit Summary

| Metric | Count |
|--------|-------|
| Files in inventory | ~158 |
| **CRITICAL issues** | **11** (3 resolved by refactor — AssessmentSyncService gone, ModelContainer path changed, ContentCard model simplified) |
| **WARNING issues** | ~55 (inherited; some may be resolved) |
| INFO observations | 40+ |

> **Note:** Issues below were audited against the Apr 12 snapshot. Files added or restructured since then are marked ⚠️ Uninspected. Re-audit before shipping those files.

---

## CRITICAL Issues (Fix Before Shipping)

### 1. Hardcoded Supabase Credentials in Source Code
**Files:** `Core/Services/Config.swift:2-3`
**Type:** Security
Supabase URL and anon key are hardcoded as string literals. Move to a `.gitignored` xcconfig or CI-injected secrets; have `Config.swift` read from `Bundle.main.infoDictionary`.

### 2. `isAuthenticated` Defaults to `true`
**Files:** `Core/Services/AuthService.swift:19`, `App/ContentView.swift:29`
**Type:** Security / UX
`AuthService.isAuthenticated` defaults to `true`, creating a window where unauthenticated users see the main app. Both should default to `false` with a splash/loading state.

### 3. Sensitive PII Stored in Plaintext
**Files:** `Models/Progress/UserProfile.swift:19-22`, `Models/Progress/Couple.swift:29`
**Type:** Security / Privacy
Sexual orientation, role preference, and safe words stored as plaintext in SwiftData. Consider encrypting at rest or using Keychain for sensitive fields.

### 4. Timer Memory Leak in ResearchTicker
**File:** `Features/Home/Components/ResearchTicker.swift:102`
**Type:** Performance / Memory
`Timer.scheduledTimer` created in `onAppear` but never invalidated. Each `onAppear` creates a new timer, causing memory leak, stacked timers, and accelerating tick rate.

### 5. `Timer.publish(every: 1/60)` on Main Thread
**Files:** `Design/Components/Effects/FlameAura.swift`, `Design/Components/Effects/LightAuraBloom.swift`
**Type:** Performance
60fps timer on the main thread blocks UI. Replace with `TimelineView(.animation)` or `CADisplayLink`.

### 6. Deprecated `UIScreen.main.bounds` Usage
**Files:** `Design/Components/Effects/FloatingStack.swift`, `Design/Components/Pulse/PulseFullView.swift`, `Features/Onboarding/Components/CuriosityPill.swift:86`, `Features/Onboarding/Views/OnboardingCuriosityPickerView.swift:86-87`
**Type:** Performance / Compatibility
Not reactive to window changes, iPad multitasking, or Stage Manager. Use `GeometryReader` instead.

### 7. `UIApplication.shared.connectedScenes` for Screen Width
**Files:** `Design/Components/Cards/ConversationCard.swift`, `Features/Onboarding/Views/OnboardingBuildingPathView.swift:98-103`
**Type:** Performance / Compatibility
Bypasses SwiftUI's layout system. Not reactive, breaks on window resize / iPad multitasking.

### 8. DEBUG Gate Bypass
**File:** `Features/Home/HomeRouterView.swift:25-36`
**Type:** Logic / Testing
`#if DEBUG` block sets `myMapComplete = true`, etc., so TestFlight/DEBUG builds skip all onboarding gates.

### 9. Hardcoded Pairing Code Placeholders
**Files:** `Features/Settings/SettingsView.swift:7`, `Features/Pairing/PairingSettingsView.swift:13`
**Type:** Logic
Hardcoded `"AX7-QM2"` pairing code placeholder; `PairingSettingsView` copies it to clipboard.

### 10. ForEach/totalPanels Mismatch — Potential Crash
**File:** `Features/Onboarding/Components/CuriosityStatusStrip.swift:24 vs 32`
**Type:** Logic
`ForEach(0..<3)` iterates 3 indices but `totalPanels` is 2. Potential out-of-bounds crash.

### 11. Privacy Rule Violation in DesireMatch
**File:** `Models/Progress/DesireMatch.swift:36-38`
**Type:** Privacy
`ratingA`/`ratingB` store exact ratings for both partners including `notForUs`. Privacy guarantee is UI-only, not enforced at the data layer.

> **Resolved since last audit:**
> - C12 (ModelContainer computed property) — file moved to `App/ModelContainer.swift`; re-verify fix is in place
> - C13 (SessionView wrong category) — verify fix landed
> - C14 (Pairing code entropy) — verify fix landed

---

## WARNING Issues (Fix Before Beta)

### Architecture & Patterns
| # | Issue | File(s) | Lines |
|---|-------|---------|-------|
| W1 | Dual theming: ~10 files use `@Environment(\.theme)` while newer files use `AppColors.*` directly | CategoryTileView, GlowOrb, SafeWordButton, CriticalButton, GradientButton, InteractiveField, SpectrumBar, ProgressBar, ProgressRingView, ScoreRing | throughout |
| W2 | `@EnvironmentObject` in SignInView vs `@Environment` everywhere else | Features/Auth/SignInView.swift | 11 |
| W3 | Inconsistent color token: `AppColors.background` vs `AppColors.pageBg` | SettingsView, SessionView, ProgressDashboardView, DesireMapView | various |

### Data Integrity
| # | Issue | File(s) | Lines |
|---|-------|---------|-------|
| W4 | `try? context.save()` silently swallows all SwiftData errors | DataStore.swift, SyncManager.swift | 89,153,167,189,196,223,165 |
| W5 | Magic number `86400` for day calculation (doesn't handle DST) | Data/Store/DataStore.swift | 73 |
| W6 | No upsert/conflict handling on batch inserts | DesireSyncService.swift | 134-137 |
| W7 | Cached profile ID in UserDefaults can become stale | Core/Services/ProfileService.swift | 204-206 |
| W8 | Pulse data stored in plaintext UserDefaults | Models/Persistence/PulseStore.swift | — |
| W9 | Desire ratings privacy is UI-only | Models/Progress/DesireRating.swift | — |

### Performance
| # | Issue | File(s) | Lines |
|---|-------|---------|-------|
| W10 | `DataStore(context:)` created as computed property — queries on every render | ProgressDashboardView, DesireMapView | 9, 38 |
| W11 | `UIImpactFeedbackGenerator` created inline per gesture instead of cached | CardCarousel.swift, OnboardingNameView.swift | various |
| W12 | SparkSystem `Timer.publish` — particle updates on main thread | Design/Components/Effects/SparkField.swift | 50-100 |
| W13 | `TimelineView` at 30fps in CuriosityPickerView — GPU-intensive | Features/Onboarding/Views/OnboardingCuriosityPickerView.swift | 417-418 |
| W14 | `cardSpecs()` recomputed on every render | Features/Onboarding/Views/OnboardingCuriosityPickerView.swift | 425,435 |
| W15 | `AnyView` wrapping defeats SwiftUI structural identity | Design/Components/Effects/LightAuraBloom.swift | 80-90 |

### Code Quality / Dead Code
| # | Issue | File(s) | Lines |
|---|-------|---------|-------|
| W16 | 30+ `@State` properties in single views | OnboardingBrandView (30+), OnboardingCardRevealView (25+) | 21-78, 63-113 |
| W17 | `DispatchQueue.main.asyncAfter` chains with no cancellation on view dismiss | OnboardingBrandView, OnboardingCardRevealView, RacetrackTabBar | various |
| W18 | Dead code: multiple unused functions/properties | SessionView (`advance()`), OnboardingNameView (`dismissCustomIfNeeded()`), ReflectionBannerView (`isVisible`), SettingsView (`navigateToThemePicker`), BuildingPathView (`deriveDefaultDifficulty()`) | various |
| W19 | Non-functional UI: "Link Partner" button has empty action | Features/Pairing/PairingSettingsView.swift | 72-74 |
| W20 | `Task.sleep(for: .seconds(1))` instead of proper async coordination | App/VaylApp.swift | ~110 |
| W21 | Simulator hardcodes a fixed UUID for auth | Core/Services/AuthService.swift | 36-37 |
| W22 | `pulseScale` repeatForever animation never cancelled | Features/Home/Components/PickUpCard.swift | 79 |
| W23 | "Temporarily bypass isPaired check" left in prod code | Features/Home/HomeRouterView.swift | 55 |

### DRY Violations
| # | Issue | File(s) |
|---|-------|---------|
| W24 | `GlowUnderline.swift` / `GlowUnderlineView.swift` — exact duplicate | Design/Components/Effects/ |
| W25 | `OnboardingGlowField` / `AuroraGlowField` — structural duplicate, only palette differs | Design/Components/Effects/ |
| W26 | `cardFill` computed property duplicated | PremiumCardShell.swift, CardBackView.swift |
| W27 | `ReflectionCard` / `ReflectionBannerView` — significant code overlap | Features/Home/Components/ |
| W28 | Duplicated animation schedule in BuildingPathView (~140 lines near-identical) | Features/Onboarding/Views/OnboardingBuildingPathView.swift |
| W29 | `HolographicShimmer` / `LightModeShimmer` — same pattern, different colors | Design/Components/Effects/ |

### Misc
| # | Issue | File(s) | Lines |
|---|-------|---------|-------|
| W30 | `fatalError` on missing/malformed bundle content | Core/Services/ContentLoader.swift | 27, 36 |
| W31 | `fatalError` on invalid Supabase URL | Core/Services/SupabaseManager.swift | 18-19 |
| W32 | Profile ID cached in plain UserDefaults (should be Keychain) | Core/Services/ProfileService.swift | 204-221 |
| W33 | Orphaned `ProfileService()` instances created inline | PairingService, DesireSyncService | various |
| W34 | `retryPendingSyncs` has no backoff or max retry count | Core/Services/SyncManager.swift | 210-242 |
| W35 | Raw error display in SignInView could expose internals | Features/Auth/SignInView.swift | 57 |
| W36 | `PostMapReflectionView` loses state on view destruction | Features/Home/Components/PostMapReflectionView.swift | 82 |
| W37 | `OnboardingData` not persisted — lost if app killed mid-flow | Features/Onboarding/Data/OnboardingData.swift | — |
| W38 | Oversized views should be decomposed | DailyCheckInView (~740), PulseWidget (~730), CardCarousel (~690) | — |
| W39 | ~400 lines of preview code in OrbitIndicator | Design/Components/Progress/OrbitIndicator.swift | 400-794 |
| W40 | `FilamentMode.swift` should use `@Observable` | Design/Components/FilamentMode.swift | — |

---

## File Inventory

### App Layer (11 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| App/VaylApp.swift | ⚠️ | W20 (Task.sleep) |
| App/ContentView.swift | 🔴 | C2 (hasCompletedOnboarding defaults true) |
| App/AppShell.swift | ✅ | Clean |
| App/ModelContainer.swift | ⚠️ Uninspected | Moved from Data/Store/ — re-verify C12 fix |
| App/Theme/AppColors.swift | ✅ | Clean |
| App/Theme/AppFonts.swift | ✅ | Clean |
| App/Theme/AppTheme.swift | ✅ | Clean |
| App/Theme/ThemeModifiers.swift | ✅ | Clean |
| App/Theme/ThemeManager.swift | ✅ | Clean |
| App/Theme/ColorRow.swift | ⚠️ Uninspected | New since last audit |
| AppIconRetreival.swift | ⚠️ Uninspected | New since last audit |

### Core Services (10 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Core/Services/Config.swift | 🔴 | C1 (hardcoded credentials) |
| Core/Services/AuthService.swift | 🔴 | C2 + W21 (simulator UUID) |
| Core/Services/AppState.swift | ⚠️ Uninspected | New since last audit |
| Core/Services/ProfileService.swift | ⚠️ | W7, W32, W33 |
| Core/Services/SyncManager.swift | ⚠️ | W4, W34 |
| Core/Services/PairingService.swift | ⚠️ | W33 |
| Core/Services/DesireSyncService.swift | ⚠️ | W6, W33 |
| Core/Services/SessionSyncService.swift | ✅ | Skeleton — minimal code |
| Core/Services/ContentLoader.swift | ⚠️ | W30 (fatalError) |
| Core/Services/SupabaseManager.swift | ⚠️ | W31 (fatalError) |

### Data Store (1 file)

| File Path | Status | Issues |
|-----------|--------|--------|
| Data/Store/DataStore.swift | ⚠️ | W4 (silent saves), W5 (magic 86400) |

### Design — Brand (1 file)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Brand/VaylAppIcon.swift | ⚠️ Uninspected | New since last audit |

### Design — Buttons (5 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Buttons/HoloCTAButton.swift | ⚠️ | Missing: destructive variant, size param, icon support, a11y label |
| Design/Components/Buttons/SelectablePill.swift | ⚠️ | Missing: maxWidth param, accent override, ViewBuilder variant, a11y |
| Design/Components/Buttons/SafeWordButton.swift | ⚠️ | W1 (old theme), missing a11y label |
| Design/Components/Buttons/GradientButton.swift | ⚠️ | W1 (old theme), missing isEnabled + a11y |
| Design/Components/Buttons/CriticalButton.swift | ⚠️ | W1 (old theme), missing isEnabled + a11y |

### Design — Cards (16 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Cards/CardCarousel.swift | ⚠️ | W11 (haptics), hardcoded spread config, W38 (oversized ~690L) |
| Design/Components/Cards/ConversationCard.swift | 🔴 | C7 (UIApplication scenes), hardcoded card dims |
| Design/Components/Cards/CardBackView.swift | ⚠️ | W26 (cardFill DRY) |
| Design/Components/Cards/PremiumCardShell.swift | ⚠️ | W26 (cardFill DRY) |
| Design/Components/Cards/CuriosityCardBack.swift | ⚠️ | Hardcoded RGB gradient values |
| Design/Components/Cards/FuseTimerView.swift | ✅ | Clean |
| Design/Components/Cards/CardFrontView.swift | ✅ | Clean |
| Design/Components/Cards/CardRevealPillButton.swift | ⚠️ | Hardcoded animation timing |
| Design/Components/Cards/CategoryTileView.swift | ⚠️ | W1 (old theme), missing a11y |
| Design/Components/Cards/AtmosphericGhostDeck.swift | ⚠️ | Hardcoded drift/opacity values |
| Design/Components/Cards/CuriosityFlipCard.swift | ✅ | Clean |
| Design/Components/Cards/ConversationCardTypes.swift | ✅ | Clean |
| Design/Components/Cards/CardLayout.swift | ✅ | Clean |
| Design/Components/Cards/CardShadows.swift | ✅ | Clean |
| Design/Components/Cards/PromptCard.swift | ✅ | Clean |
| Design/Components/Cards/SettingsCard.swift | ✅ | Clean |

### Design — Effects (15 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Effects/SparkField.swift | ⚠️ | W12 (main thread timer) |
| Design/Components/Effects/FloatingStack.swift | 🔴 | C6 (UIScreen deprecated) |
| Design/Components/Effects/FloatingCard.swift | ⚠️ | Hardcoded card dims (168pt, 20pt corner radius) |
| Design/Components/Effects/TileOrbitView.swift | ⚠️ | Hardcoded orbit timing constants |
| Design/Components/Effects/AuroraGlowField.swift | ⚠️ | W25 (DRY with OnboardingGlowField), file-scoped hex colors |
| Design/Components/Effects/FlameAura.swift | 🔴 | C5 (60fps timer on main thread), W15 |
| Design/Components/Effects/MazePatternView.swift | ✅ | Clean |
| Design/Components/Effects/LightAuraBloom.swift | 🔴 | C5 (60fps timer), W15 (AnyView) |
| Design/Components/Effects/OnboardingGlowField.swift | ⚠️ | W25 (DRY with AuroraGlowField), hardcoded timing |
| Design/Components/Effects/LightModeShimmer.swift | ⚠️ | W29 (DRY with HolographicShimmer) |
| Design/Components/Effects/HolographicShimmer.swift | ⚠️ | W29 (DRY with LightModeShimmer) |
| Design/Components/Effects/HomeGlowField.swift | ⚠️ | Hardcoded deep-space hex colors, blob config |
| Design/Components/Effects/GlowUnderline.swift | ⚠️ | W24 (DRY with GlowUnderlineView), hardcoded sizing |
| Design/Components/Effects/GlowUnderlineView.swift | 🔴 | W24 — exact duplicate; delete this file |
| Design/Components/Effects/GlowOrb.swift | ⚠️ | W1 (old theme) |

### Design — FilamentMode (1 file)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/FilamentMode.swift | ⚠️ | W40 (use @Observable) |

### Design — Input (3 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Input/RatingButtonGroup.swift | ⚠️ | No light mode, no a11y labels |
| Design/Components/Input/InteractiveField.swift | ⚠️ | W1 (old theme), no status enum, no a11y |
| Design/Components/Input/ToggleRow.swift | ✅ | Clean (minor: expose toggleTint param) |

### Design — Navigation (4 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Navigation/RacetrackTabBar.swift | ⚠️ | W17 (asyncAfter) |
| Design/Components/Navigation/TabContentWrapper.swift | ✅ | Clean |
| Design/Components/Navigation/OnboardingNavBar.swift | ✅ | Clean |
| Design/Components/Navigation/OnboardingFooter.swift | ✅ | Clean |

### Design — Other Root (5 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/NavArrow.swift | ✅ | Clean |
| Design/Components/PillBorder.swift | ✅ | Clean (minor: expose gradient override) |
| Design/Components/CardStyle.swift | ✅ | Clean |
| Design/Components/ScreenshotProtectionModifier.swift | ✅ | Clean |
| Design/Components/OrbitSparkBorderView.swift | ✅ | Clean (0 callers) |
| Design/Components/SectionHeader.swift | ✅ | Clean (minor: add a11y label) |
| Design/Components/FilamentMode.swift | ⚠️ | W40 |

### Design — Progress (6 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Progress/OnboardingProgressBar.swift | ✅ | Clean (well-engineered; misnamed — general-purpose) |
| Design/Components/Progress/OrbitIndicator.swift | ⚠️ | W39 (~400 lines of previews) |
| Design/Components/Progress/ProgressBar.swift | ⚠️ | W1 (old theme); duplicate of OnboardingProgressBar; mark deprecated |
| Design/Components/Progress/ProgressRingView.swift | ⚠️ | W1 (old theme); overlaps ScoreRing |
| Design/Components/Progress/ScoreRing.swift | ⚠️ | W1 (old theme); feature-specific ("OF 100" text); belongs in Features/Home/ |
| Design/Components/Progress/SpectrumBar.swift | ⚠️ | W1 (old theme) |

### Design — Pulse (8 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Pulse/PulseGraph.swift | ✅ | Clean (correct Animatable pattern) |
| Design/Components/Pulse/DailyCheckInView.swift | ⚠️ | W38 (oversized, mixed concerns); should be in Features/Pulse/ |
| Design/Components/Pulse/PulseWidget.swift | ⚠️ | W38 (oversized); review screen vs widget split |
| Design/Components/Pulse/PulseDotSummary.swift | ✅ | Clean |
| Design/Components/Pulse/PulseFullView.swift | 🔴 | C6 (UIScreen deprecated); is a screen — should be in Features/Pulse/ |
| Design/Components/Pulse/PulseSheetView.swift | ⚠️ | Is a screen — should be in Features/Pulse/ |
| Design/Components/Pulse/CheckInShell.swift | ✅ | Clean |
| Design/Components/Pulse/PulseCanvasScrollView.swift | ✅ | Clean |

### Design — Text (3 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Design/Components/Text/LivingText.swift | ✅ | Clean (good a11y) |
| Design/Components/Text/GradientText.swift | ✅ | Clean (minor: add a11y label) |
| Design/Components/Text/KeywordHighlightText.swift | ⚠️ | No light mode support for highlight colors |

### Models — Content (2 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Models/Content/Card.swift | ⚠️ Uninspected | New since last audit — replaced ContentCard + Prompt + 3 others |
| Models/Content/Deck.swift | ⚠️ Uninspected | New since last audit |

### Models — Enums (2 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Models/Enums/AppEnums.swift | ⚠️ | Blanket Identifiable extension; now also contains PulseWindow |
| Models/Enums/AppTab.swift | ✅ | Clean |

### Models — Persistence (5 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Models/Persistence/SessionRecord.swift | ⚠️ | Raw strings instead of enums for category/difficulty |
| Models/Persistence/AcknowledgementRecord.swift | ⚠️ Uninspected | New since last audit |
| Models/Persistence/LockInSession.swift | ⚠️ Uninspected | New since last audit |
| Models/Persistence/MilestoneRecord.swift | ⚠️ Uninspected | New since last audit |
| Models/Persistence/PulseStore.swift | ⚠️ | W8 (plaintext UserDefaults); moved from old Models/Pulse/ |

### Models — Progress (8 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Models/Progress/UserProfile.swift | 🔴 | C3 (PII plaintext) |
| Models/Progress/Couple.swift | 🔴 | C3 (safe word plaintext) |
| Models/Progress/DesireMatch.swift | 🔴 | C11 (privacy violation — exact ratings stored) |
| Models/Progress/DesireRating.swift | ⚠️ | W9 (privacy UI-only) |
| Models/Progress/PulseEntry.swift | ⚠️ Uninspected | Moved from old Models/Pulse/ |
| Models/Progress/CardSession.swift | ⚠️ Uninspected | New since last audit |
| Models/Progress/DeckProgress.swift | ⚠️ Uninspected | New since last audit |
| Models/Progress/EntitlementRecord.swift | ⚠️ Uninspected | New since last audit |

### Features — Auth (1 file)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Auth/SignInView.swift | ⚠️ | W2 (@EnvironmentObject), W35 (raw errors) |

### Features — Compatibility (1 file)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Compatibility/DesireMapView.swift | ⚠️ | W10 (render queries), W3 (color token) |

### Features — Home (15 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Home/HomeDashboardView.swift | ⚠️ | Naming issue, dead gesture |
| Features/Home/HomeRouterView.swift | 🔴 | C8 (DEBUG bypass), W23 (bypass comment) |
| Features/Home/HomeStates.swift | ⚠️ | Dead state, W46 (fragile parser) |
| Features/Home/Models/HomeEventEngine.swift | ✅ | Clean (needs unit tests) |
| Features/Home/Models/HomeModels.swift | ✅ | Clean |
| Features/Home/Components/PartnerChip.swift | ✅ | Clean; candidate for extraction to Design/Components/ |
| Features/Home/Components/HomeWidgetShell.swift | ✅ | Clean; candidate for extraction to Design/Components/ |
| Features/Home/Components/DesireMapIndicator.swift | ✅ | Clean |
| Features/Home/Components/PickUpCard.swift | ⚠️ | W22 (uncancelled animation) |
| Features/Home/Components/ResearchTicker.swift | 🔴 | C4 (timer leak) |
| Features/Home/Components/ReflectionCard.swift | ⚠️ | W27 (DRY with BannerView) |
| Features/Home/Components/ReflectionBannerView.swift | ⚠️ | W18 (dead code), W27 |
| Features/Home/Components/PostMapReflectionView.swift | ⚠️ | W35 (state lost on dismiss) |
| Features/Home/Components/CardChestContainer.swift | ⚠️ Uninspected | New since last audit |
| Features/Home/Components/GravLiftView.swift | ⚠️ Uninspected | New since last audit |

### Features — Learn (2 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Learn/LearnView.swift | ✅ | Stub |
| Features/Learn/ConstellationNode.swift | ⚠️ Uninspected | New since last audit |

### Features — Map (2 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Map/MapView.swift | ✅ | Stub |
| Features/Map/PrismView.swift | ⚠️ Uninspected | New since last audit |

### Features — Onboarding (22 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Onboarding/Views/OnboardingBuildingPathView.swift | ⚠️ | C7 (UIApplication), W28 (dup schedule), W18 (dead code) |
| Features/Onboarding/Views/OnboardingCardRevealView.swift | ⚠️ | W16 (25+ @State), W17 (asyncAfter) |
| Features/Onboarding/Views/OnboardingNameView.swift | ⚠️ | W11 (inline haptics), W18 (dead code) |
| Features/Onboarding/Views/OnboardingBrandView.swift | ⚠️ | W16 (30+ @State), W17 (asyncAfter chains) |
| Features/Onboarding/Views/OnboardingModeSelectView.swift | ✅ | Clean (proper Task cancellation) |
| Features/Onboarding/Views/OnboardingCuriosityPickerView.swift | 🔴 | C6 (UIScreen) + W13, W14 |
| Features/Onboarding/Views/OnboardingGroundRulesView.swift | ✅ | Clean (good a11y) |
| Features/Onboarding/Views/OnboardingStatView.swift | ⚠️ | Magic numbers, uncancelled animations |
| Features/Onboarding/Views/OnboardingContextView.swift | ✅ | Clean |
| Features/Onboarding/Views/OnboardingFlowView.swift | ✅ | Clean |
| Features/Onboarding/Data/CuriosityScreenConfig.swift | ✅ | Clean |
| Features/Onboarding/Data/OnboardingData.swift | ⚠️ | W37 (not persisted) |
| Features/Onboarding/Design/OnboardingAtmosphere.swift | ✅ | Clean |
| Features/Onboarding/Layout/OnboardingLayout.swift | ✅ | Clean |
| Features/Onboarding/Components/ContextCard.swift | ✅ | Clean; candidate for extraction to Design/Components/ |
| Features/Onboarding/Components/ContextIntensity.swift | ✅ | Clean; candidate for extraction to Design/Components/ |
| Features/Onboarding/Components/ContextCardStack.swift | ✅ | Clean; onboarding-specific, keep in place |
| Features/Onboarding/Components/ContextOption.swift | ✅ | Clean |
| Features/Onboarding/Components/CuriosityPill.swift | 🔴 | C6 (UIScreen deprecated) |
| Features/Onboarding/Components/CuriosityStatusStrip.swift | 🔴 | C10 (ForEach/totalPanels mismatch) |
| Features/Onboarding/Components/CuriosityPreviewLine.swift | ✅ | Clean |
| Features/Onboarding/Components/CuriosityPanelNudge.swift | ✅ | Clean |

### Features — Other (9 files)

| File Path | Status | Issues |
|-----------|--------|--------|
| Features/Sessions/SessionView.swift | ⚠️ | Verify C13 (wrong category) was fixed; 2 other warnings |
| Features/Settings/SettingsView.swift | 🔴 | C9 (hardcoded code) + 4 warnings |
| Features/Settings/ThemeTestView.swift | ✅ | Clean (DEBUG only) |
| Features/Settings/ThemePickerView.swift | ✅ | Clean |
| Features/Compatibility/DesireMapView.swift | ⚠️ | W10 (render queries) |
| Features/Progress/ProgressDashboardView.swift | ⚠️ | W10 (render queries), W3 (color token) |
| Features/Pairing/PairingSettingsView.swift | 🔴 | C9 (hardcoded code) + 2 warnings |
| Features/Auth/SignInView.swift | ⚠️ | W2, W35 |
| Features/Play/PlayView.swift | ✅ | Stub |

---

## Issue Distribution

| Category | Critical | Warning |
|----------|----------|---------|
| Security / Privacy | 3 | 5 |
| Performance | 3 | 6 |
| Data Integrity | 2 | 6 |
| Architecture / DRY | 0 | 10 |
| Code Quality / Dead Code | 1 | 15 |
| Logic / UX | 2 | 8 |

---

## Priority Action Plan

### P0 — Ship Blockers
1. Move Supabase credentials out of source control (C1)
2. Fix `isAuthenticated` / `hasCompletedOnboarding` defaults to `false` (C2)
3. Fix `ResearchTicker` timer leak (C4)
4. Verify `SessionView` category bug fix landed (C13)
5. Fix `CuriosityStatusStrip` ForEach/totalPanels mismatch (C10)
6. Remove hardcoded pairing code placeholders (C9)
7. Remove DEBUG gate bypass in HomeRouterView (C8)

### P1 — Security & Privacy
8. Encrypt sensitive PII fields — sexual orientation, safe word, role preference (C3)
9. Enforce desire rating privacy at the data layer (C11)
10. Sanitize error messages in SignInView (W35)
11. Move Pulse data from UserDefaults to encrypted storage (W8)

### P2 — Performance
12. Replace `Timer.publish(every: 1/60)` with TimelineView in FlameAura + LightAuraBloom (C5)
13. Replace all `UIScreen.main.bounds` with GeometryReader (C6)
14. Fix `UIApplication.shared.connectedScenes` screen width (C7)
15. Fix `DataStore` render-time queries (W10)
16. Cache `UIImpactFeedbackGenerator` instances (W11)

### P3 — Design System (active branch work)
17. Unify HolographicShimmer + LightModeShimmer → Shimmer.swift (W29)
18. Delete GlowUnderlineView.swift — exact duplicate (W24)
19. Migrate remaining views from `@Environment(\.theme)` to `AppColors.*` (W1)
20. Parameterize HoloCTAButton, SelectablePill, GradientButton, CriticalButton
21. Extract PartnerChip → Design/Components/Indicators/
22. Extract HomeWidgetShell → Design/Components/Cards/WidgetShell
23. Extract ContextCard + ContextIntensity → Design/Components/Cards/

### P4 — Code Quality
24. Consolidate AuroraGlowField / OnboardingGlowField (W25)
25. Remove dead code (W18)
26. Add upsert handling to sync services (W6)
27. Audit all ⚠️ Uninspected files added since Apr 12
