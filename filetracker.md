# Vayl — File Tree & Descriptions

_Last updated: 2026-05-16_  
_~180 Swift files + Metal shaders across 40+ directories_

---

## Vayl/ (App Source)

```
Vayl/
├── Vayl.entitlements          — App capabilities and permissions
├── Vayl.plist                 — App configuration metadata
│
├── App/
│   ├── VaylApp.swift          — @main entry point; creates AppState, ThemeManager, ModelContainer, injects environment objects.
│   ├── AppShell.swift         — Tab router; switches between home, play, map, learn tabs with RacetrackTabBar.
│   ├── ContentView.swift      — Auth router; gates SignInView vs AppShell based on AuthService.isAuthenticated.
│   ├── ModelContainer.swift   — SwiftData ModelContainer factory; returns previewContainer or live container.
│   ├── AppIconRetreival.swift — Loads app icon from bundle for display in UI.
│   │
│   └── Theme/
│       ├── AppAnimation.swift           — Reusable animation curves and durations (fast, slow, spring, etc.).
│       ├── AppColors.swift              — Full semantic color palette via Color.dynamic(light:dark:) tokens; ground truth for all colors.
│       ├── AppElevation.swift           — Shadow and depth scale for hierarchical elevation.
│       ├── AppFonts.swift               — Font factory for Clash Display and Switzer; semantic sizes (heroTitle, body, etc.).
│       ├── AppGlows.swift               — Glow and shimmer effect definitions for spectrum borders and accents.
│       ├── AppGrid.swift                — Layout grid constants; columns, gaps, alignment guides.
│       ├── AppLayout.swift              — Responsive layout sizing; adapts padding, margins, font sizes for screen size.
│       ├── AppRadius.swift              — Border radius scale for consistent corner rounding across components.
│       ├── AppRootView.swift            — Top-level routing gate; shows SplashScreenView once, then routes to auth/onboarding.
│       ├── AppSafeArea.swift            — Safe area insets and home indicator padding.
│       ├── AppSpacing.swift             — Spacing scale (xs, sm, md, lg, xl); used for consistent padding/margins.
│       ├── AppTheme.swift               — ThemeMode enum and AppPalette struct; defines light/dark palettes.
│       ├── ThemeManager.swift           — @Observable class; persists theme mode to UserDefaults, resolves active palette.
│       ├── ThemeModifiers.swift         — ThemedRootModifier; injects AppPalette into environment and sets preferredColorScheme.
│       └── VaylPrimitives.swift         — Tier 1 raw hex colors; cyan, purple, magenta, gold, ink scale, neutrals.
│
├── Core/
│   ├── Models/
│   │   ├── AcknowledgementRecord.swift  — SwiftData model; tracks acknowledgement events (read, viewed, etc.).
│   │   ├── Card.swift                   — Core card model; title, description, answers, metadata.
│   │   ├── CardSession.swift            — SwiftData model; tracks card history within a session.
│   │   ├── Couple.swift                 — SwiftData model; represents paired couple; pairing code, experience type.
│   │   ├── Deck.swift                   — Card deck model; title, description, category, all cards.
│   │   ├── DeckProgress.swift           — Tracks progress through a deck; completed count, current position.
│   │   ├── DesireMatch.swift            — SwiftData model; represents desire/compatibility rating between partners.
│   │   ├── DesireRating.swift           — SwiftData model; user's rating for a desire item in a category.
│   │   ├── EntitlementRecord.swift      — SwiftData model; tracks feature entitlements and unlock status.
│   │   ├── LockInSession.swift          — SwiftData model; represents a locked-in session between partners.
│   │   ├── MilestoneRecord.swift        — SwiftData model; tracks user milestones and achievements.
│   │   ├── PulseEntry.swift             — SwiftData model; daily pulse/mood checkin entry.
│   │   ├── SessionRecord.swift          — SwiftData model; tracks session metadata (start time, answers, etc.).
│   │   ├── UserProfile.swift            — SwiftData model; user profile data (name, preferences, birthday, etc.).
│   │   │
│   │   └── Enums/
│   │       ├── AppEnums.swift           — Shared enums (ExperienceType, LinkState, GenderIdentity, etc.).
│   │       └── AppTab.swift             — Tab enum (home, play, map, learn).
│   │
│   ├── Persistence/
│   │   ├── DataStore.swift              — Migrated; SwiftData persistence layer; CRUD operations for models.
│   │   └── ModelContext+Extensions.swift — Fetch helper extensions for ModelContext.
│   │
│   └── Services/
│       ├── AppState.swift               — @Observable class; owns experienceType, linkState, displayName; persists to UserDefaults.
│       ├── AuthService.swift            — @Observable class; Sign in with Apple via Supabase; owns isAuthenticated, userId.
│       ├── Config.swift                 — Static constants; Supabase project URL and anon API key.
│       ├── ContentLoader.swift          — Loads bundled JSON files (cards.json, assessment_questions.json, etc.).
│       ├── DesireSyncService.swift      — Syncs desire ratings between local and Supabase; handles conflicts.
│       ├── PairingService.swift         — Couple pairing; generate codes, look up codes, complete pairing in Supabase.
│       ├── ProfileService.swift         — Reads/writes user profile to Supabase profiles table.
│       ├── SessionSyncService.swift     — Syncs session records (answers, timing) between local and Supabase.
│       ├── SupabaseManager.swift        — Singleton SupabaseClient; all services read from SupabaseManager.shared.client.
│       └── SyncManager.swift            — Orchestrates all sync services; retry logic for pending syncs.
│
├── Design/
│   ├── Brand/
│   │   ├── SplashScreenView.swift       — Animated splash screen; plays on cold launch, tears away to reveal app.
│   │   └── VaylAppIcon.swift            — Renders spectrum icon; used in brand contexts.
│   │
│   └── Components/
│       ├── Buttons/
│       │   ├── CriticalButton.swift     — Destructive action button (logout, delete); red background, white text.
│       │   ├── SafeWordButton.swift     — Safeword action button; shows red pill with white text.
│       │   └── SelectablePill.swift     — Toggle pill button; selected/unselected states with animation.
│       │
│       ├── Cards/
│       │   ├── AtmosphericGhostDeck.swift      — Ghost deck background; faded cards visible beneath current.
│       │   ├── CardBackView.swift              — Card back face; spectrum border, glow, animation.
│       │   ├── CardCarousel.swift              — Horizontal carousel of cards with swipe navigation.
│       │   ├── CardFrontView.swift             — Card front face; displays question and answer options.
│       │   ├── CardLayout.swift                — Card sizing and geometry; handles responsive sizing.
│       │   ├── CardRevealPillButton.swift      — Reveals answer button; triggers card flip animation.
│       │   ├── CardShadows.swift               — Card shadow styles; floating elevation, pressed states.
│       │   ├── CardStyle.swift                 — Card appearance modifiers; fills, borders, corner styles.
│       │   ├── CategoryTileView.swift          — Category tile for desire map; shows icon, title, rating.
│       │   ├── ConversationCard.swift          — Conversation prompt card; displays relationship question.
│       │   ├── ConversationCardTypes.swift     — Enums and types for conversation cards.
│       │   ├── CuriosityCardBack.swift         — Curiosity card back; custom styling with intensity meter.
│       │   ├── CuriosityFlipCard.swift         — Flippable curiosity card; front/back animation.
│       │   ├── FuseTimerView.swift             — Timer display for fuse/session countdown.
│       │   ├── PremiumCardShell.swift          — Premium card wrapper; adds premium badge and border.
│       │   ├── PromptCard.swift                — Generic prompt card container.
│       │   ├── SettingsCard.swift              — Settings panel card; key-value display.
│       │   ├── VaylCardBack.swift              — New spectrum card back with Vayl branding.
│       │   ├── VaylCardFace.swift              — New spectrum card front face.
│       │   └── VaylCardRenderer.swift          — Card render orchestrator; handles flipping, animation, state.
│       │
│       ├── Effects/
│       │   ├── AuroraGlowField.swift           — Aurora shimmer background; animates soft glow across screen.
│       │   ├── FilamentMode.swift              — Metal shader effect; creates filament/thread visual pattern.
│       │   ├── FlameAura.swift                 — Flame-like aura effect; orange/red gradient glow.
│       │   ├── FloatingCard.swift              — Card floating in space; bobbing animation, perspective.
│       │   ├── FloatingStack.swift             — Multiple floating cards stacked with depth.
│       │   ├── GlowOrb.swift                   — Glowing orb component; uses theme gradient.
│       │   ├── GlowUnderline.swift             — Animated glow underline for text; spectrum gradient.
│       │   ├── GlowUnderlineView.swift         — Container for glow underline effect.
│       │   ├── GradBadge.swift                 — Badge with spectrum gradient border.
│       │   ├── HolographicShimmer.metal        — Metal shader; creates holographic shimmer effect.
│       │   ├── HolographicShimmer.swift        — Wrapper for holographic shimmer Metal shader.
│       │   ├── HomeGlowField.swift             — Glow background for home screen; adapts to light/dark.
│       │   ├── LightAuraBloom.swift            — Light bloom effect; soft expanding glow.
│       │   ├── LightModeShimmer.swift          — Shimmer effect for light mode; warm gradient.
│       │   ├── MazePatternView.swift           — Procedural maze pattern background.
│       │   ├── OnboardingGlowField.swift       — Glow background for onboarding screens.
│       │   ├── OrbitSpark.metal                — Metal shader; creates orbiting spark effect.
│       │   ├── OrbitSparkBorderView.swift      — Sparking border animation around elements.
│       │   ├── PillBorder.swift                — Pill-shaped border with spectrum gradient.
│       │   ├── SectionHeader.swift             — Decorative section header divider.
│       │   ├── SparkField.swift                — Field of animated sparks; background effect.
│       │   ├── TileOrbitView.swift             — Tiles orbiting in a circle; decorative effect.
│       │   ├── VaylBorderEffect.swift          — Complex border effect with multiple layers and animation.
│       │   └── VaylButton.swift                — Button with Vayl-specific styling and effects.
│       │
│       ├── Input/
│       │   ├── InteractiveField.swift          — Text input field with validation and decoration.
│       │   ├── RatingButtonGroup.swift         — Group of rating buttons (1-5 stars/scale).
│       │   └── ToggleRow.swift                 — Toggle switch row for settings.
│       │
│       ├── Navigation/
│       │   ├── NavArrow.swift                  — Directional arrow button for navigation.
│       │   ├── OnboardingFooter.swift          — Footer with navigation buttons for onboarding.
│       │   ├── OnboardingNavBar.swift          — Navigation bar for onboarding screens.
│       │   ├── RacetrackTabBar.swift           — Custom tab bar with racetrack shape.
│       │   └── TabContentWrapper.swift         — Wrapper for tab content; handles transitions.
│       │
│       ├── Progress/
│       │   ├── OnboardingProgressBar.swift     — Horizontal progress bar for onboarding steps.
│       │   ├── OrbitIndicator.swift            — Circular orbit progress indicator.
│       │   ├── ProgressBar.swift               — Linear progress bar component.
│       │   ├── ProgressRingView.swift          — Circular progress ring with center percentage.
│       │   ├── ScoreRing.swift                 — Circular ring displaying a score value.
│       │   ├── ScreenshotProtectionModifier.swift — Blocks screenshots for sensitive screens.
│       │   └── SpectrumBar.swift               — Spectrum gradient bar for visual accent.
│       │
│       ├── Text/
│       │   ├── GradientText.swift              — Text with spectrum gradient fill.
│       │   ├── KeywordHighlightText.swift      — Text with highlighted keywords.
│       │   └── LivingText.swift                — Animated text with gradient that changes per light/dark mode.
│       │
│       └── (Removed: Pulse components moved to Features/Pulse/)
│
├── Features/
│   ├── Auth/
│   │   └── Views/
│   │       └── SignInView.swift                — Sign in with Apple screen; handles AuthService.
│   │
│   ├── Compatibility/
│   │   ├── Store/
│   │   │   └── DesireMapStore.swift            — State management for desire map feature.
│   │   └── Views/
│   │       └── DesireMapView.swift             — Desire compatibility map visualization.
│   │
│   ├── Home/
│   │   ├── Components/
│   │   │   ├── CardChestContainer.swift        — Container for displaying available card decks.
│   │   │   ├── DesireMapIndicator.swift        — Small indicator for desire map on home.
│   │   │   ├── GravLiftView.swift              — Gravity well lift effect; pulls cards upward.
│   │   │   ├── HomeWidgetShell.swift           — Container for home screen widgets (Pulse, etc.).
│   │   │   ├── PartnerChip.swift               — Displays partner info chip on home.
│   │   │   ├── PickUpCard.swift                — "Pick me up" card suggestion widget.
│   │   │   ├── PostMapReflectionView.swift     — Reflection on desire map interaction.
│   │   │   ├── ReflectionBannerView.swift      — Banner showing relationship reflection/insight.
│   │   │   ├── ReflectionCard.swift            — Card displaying a reflection prompt.
│   │   │   └── ResearchTicker.swift            — Scrolling ticker of research/tips.
│   │   ├── Models/
│   │   │   ├── HomeEventEngine.swift           — Event state machine for home screen transitions.
│   │   │   └── HomeModels.swift                — Data models for home screen state.
│   │   ├── Store/
│   │   │   └── HomeStore.swift                 — @Observable store; manages home screen state.
│   │   └── Views/
│   │       ├── HomeDashboardView.swift         — Main home screen layout; card carousel, widgets, reflection.
│   │       ├── HomeGateView.swift              — Gate screen; routes to dashboard, waiting, or match-ready views.
│   │       ├── HomeMatchReadyView.swift        — Screen when partners are ready to play.
│   │       ├── HomeRouterView.swift            — Navigation router for home tab.
│   │       └── HomeWaitingView.swift           — Screen shown while waiting for partner.
│   │
│   ├── Learn/
│   │   └── Views/
│   │       ├── ConstellationNode.swift         — Individual node in learning constellation.
│   │       └── LearnView.swift                 — Educational content browser; constellation layout.
│   │
│   ├── Map/
│   │   ├── MapView.swift                       — Desire/compatibility map display.
│   │   └── PrismView.swift                     — 3D prism effect for map visualization.
│   │
│   ├── Onboarding/
│   │   ├── Canvas/
│   │   │   ├── OnboardingCanvasView.swift      — Top-level onboarding canvas; orchestrates phases.
│   │   │   ├── TableSurfaceView.swift          — Background table surface for onboarding.
│   │   │   └── VaylDirector.swift              — Orchestrates onboarding flow; routes between phases.
│   │   ├── Components/
│   │   │   ├── ContextCard.swift               — Card for selecting relationship context.
│   │   │   ├── ContextCardStack.swift          — Stack of context cards.
│   │   │   ├── ContextIntensity.swift          — Intensity slider for context selection.
│   │   │   ├── ContextOption.swift             — Individual context option button.
│   │   │   ├── CornerDeckView.swift            — Decorative card in corner of screen.
│   │   │   ├── CornerMarksView.swift           — Corner decorative marks/lines.
│   │   │   ├── CuriosityPanelNudge.swift       — Nudge prompting curiosity selection.
│   │   │   ├── CuriosityPill.swift             — Pill button for curiosity category.
│   │   │   ├── CuriosityPreviewLine.swift      — Preview line of curiosity categories.
│   │   │   ├── CuriosityStatusStrip.swift      — Status strip showing curiosity progress.
│   │   │   └── OnboardingAtmosphere.swift      — Background atmosphere/glow for onboarding.
│   │   ├── Layout/
│   │   │   └── OnboardingLayout.swift          — Layout constants and geometry for onboarding.
│   │   ├── Models/
│   │   │   ├── FoilTear.swift                  — Animation model for foil tear effect.
│   │   │   ├── OnboardingData.swift            — Data structure for onboarding content.
│   │   │   └── VaylCardModel.swift             — Card model specific to onboarding.
│   │   ├── Phases/
│   │   │   ├── BuildingPathPhase.swift         — Onboarding phase: select relationship building path.
│   │   │   ├── ContextPhase.swift              — Onboarding phase: select relationship context.
│   │   │   ├── CuriosityPhase.swift            — Onboarding phase: select curiosity categories.
│   │   │   ├── ExperienceLevelPhase.swift      — Onboarding phase: select experience level.
│   │   │   ├── FoilPhase.swift                 — Onboarding phase: animated foil tear transition.
│   │   │   ├── FounderLetterPhase.swift        — Onboarding phase: display founder letter.
│   │   │   ├── GenderPhase.swift               — Onboarding phase: select gender identity.
│   │   │   ├── ModeSelectPhase.swift           — Onboarding phase: select solo/together mode.
│   │   │   ├── NamePhase.swift                 — Onboarding phase: enter user name.
│   │   │   ├── QuizPhase.swift                 — Onboarding phase: compatibility quiz.
│   │   │   └── StatPhase.swift                 — Onboarding phase: show stats/summary.
│   │   ├── Renders/
│   │   │   ├── DealPointView.swift             — Renders deal point (card reveal point).
│   │   │   └── ProjectedTextView.swift         — Text with projection/perspective effect.
│   │   ├── Store/
│   │   │   ├── CuriosityScreenConfig.swift     — Configuration for curiosity selection screen.
│   │   │   ├── OnboardingStep.swift            — Enum defining onboarding steps.
│   │   │   └── OnboardingStore.swift           — @Observable store; manages onboarding state.
│   │   └── Views/
│   │       ├── OnboardingCardRevealView.swift  — Phase view: reveal cards after name entry.
│   │       ├── OnboardingContextView.swift     — Phase view: context selection.
│   │       ├── OnboardingCuriosityPickerView.swift — Phase view: curiosity category picker.
│   │       ├── OnboardingFlowView.swift        — Main onboarding flow container.
│   │       ├── OnboardingGroundRulesView.swift — Phase view: display ground rules.
│   │       ├── OnboardingModeSelectView.swift  — Phase view: solo vs together mode.
│   │       ├── OnboardingNameView.swift        — Phase view: name entry with animation.
│   │       └── OnboardingStatView.swift        — Phase view: display user stats.
│   │
│   ├── Pairing/
│   │   ├── PairingInviteView.swift             — Screen to generate and share pairing code.
│   │   ├── PairingJoinView.swift               — Screen to enter pairing code and join.
│   │   ├── PairingSettingsView.swift           — Settings for managing pairing.
│   │   └── PairingStore.swift                  — State management for pairing feature.
│   │
│   ├── Play/
│   │   └── PlayView.swift                      — Play tab main view; card game interface.
│   │
│   ├── Progress/
│   │   └── ProgressDashboardView.swift         — Dashboard showing progress through decks/sessions.
│   │
│   ├── Pulse/
│   │   ├── CheckInShell.swift                  — Container for checkin modals.
│   │   ├── DailyCheckInView.swift              — Daily pulse/mood checkin interface.
│   │   ├── PulseCanvasScrollView.swift         — Scrollable canvas for pulse history.
│   │   ├── PulseDotSummary.swift               — Summary view of pulse entries as dots.
│   │   ├── PulseFullView.swift                 — Full view of pulse history with graphs.
│   │   ├── PulseGraph.swift                    — Graph visualization of pulse data.
│   │   ├── PulseSheetView.swift                — Sheet presentation for pulse details.
│   │   ├── PulseWidget.swift                   — Home screen widget showing pulse status.
│   │   ├── TierGuideSheet.swift                — Sheet explaining pulse tier/level system.
│   │   └── Store/
│   │       └── PulseStore.swift                — @Observable store; manages pulse/checkin state.
│   │
│   ├── Sessions/
│   │   ├── SessionStore.swift                  — State management for session tracking.
│   │   └── SessionView.swift                   — Session history and details view.
│   │
│   └── Settings/
│       ├── SettingsView.swift                  — Settings screen; preferences, theme, account.
│       ├── ThemePickerView.swift               — Theme mode picker (system/light/dark).
│       └── ThemeTestView.swift                 — Debug view for testing theme colors.
│
└── Resources/
    ├── Content/
    │   ├── assessment_questions.json           — Bundled assessment questions for quizzes.
    │   ├── cards.json                          — Bundled card deck data.
    │   ├── categories.json                     — Bundled category definitions.
    │   └── desire_items.json                   — Bundled desire/compatibility items.
    ├── Decks/
    │   ├── deck-index.json                     — Index of available decks.
    │   └── the-opener.json                     — The Opener starter deck data.
    └── Fonts/
        └── (ClashDisplay, Switzer, Zodiak — custom OTF font files)
```

---

## supabase/

```
supabase/
├── config.toml                 — Supabase project configuration.
└── functions/
    ├── create-pair/
    │   ├── deno.json           — Dependencies for create-pair Edge Function.
    │   └── index.ts            — Edge Function; creates pair relationship between two users.
    └── lookup-code/
        ├── deno.json           — Dependencies for lookup-code Edge Function.
        └── index.ts            — Edge Function; looks up pairing code details.
```

---

## Key Architectural Layers

**Tier 1 — Primitives (VaylPrimitives.swift)**  
Raw hex colors, values, and design constants.

**Tier 2 — Tokens (AppColors.swift, AppFonts.swift, AppSpacing.swift, etc.)**  
Semantic tokens derived from primitives. Used everywhere in views.

**Tier 3 — Components (Design/Components/)**  
Reusable UI elements (buttons, cards, effects, text, navigation, progress).

**Tier 4 — Features (Features/)**  
Screens and flows (Home, Onboarding, Pairing, Pulse, Settings, etc.).

**Cross-cutting — Services & Stores (Core/Services/, Features/*/Store/)**  
State management, sync, auth, data persistence.

---

## File Change Summary (from 2026-04-04 baseline)

### Moved/Renamed
- `CardFrontView.swift` → refactored into `VaylCardFace.swift`
- `OnboardingBrandView.swift`, `OnboardingBuildingPathView.swift` → replaced with phase-based architecture

### New (2026-05-16)
- **Theme**: `AppGlows.swift`, `AppRootView.swift`
- **Cards**: `VaylCardBack.swift`, `VaylCardFace.swift`, `VaylCardRenderer.swift`
- **Effects**: `GradBadge.swift`, `PillBorder.swift`, `VaylBorderEffect.swift`, `VaylButton.swift`
- **Onboarding Canvas**: `OnboardingCanvasView.swift`, `TableSurfaceView.swift`, `VaylDirector.swift`
- **Onboarding Phases**: `BuildingPathPhase.swift`, `ContextPhase.swift`, `CuriosityPhase.swift`, `ExperienceLevelPhase.swift`, `FoilPhase.swift`, `FounderLetterPhase.swift`, `GenderPhase.swift`, `ModeSelectPhase.swift`, `NamePhase.swift`, `QuizPhase.swift`, `StatPhase.swift`
- **Onboarding Renders**: `DealPointView.swift`, `ProjectedTextView.swift`
- **Onboarding Models**: `FoilTear.swift`, `VaylCardModel.swift`
- **Brand**: `SplashScreenView.swift`
- **Pulse**: `PulseDotSummary.swift`, `TierGuideSheet.swift`
- **Components**: `CornerDeckView.swift`, `CornerMarksView.swift`

### Removed/Archived
- `CardFrontView.swift` (functionality merged into `VaylCardFace.swift`)
- Old onboarding screen views (replaced with phase-based system)
