# Vayl — File Tree & Descriptions

_Last updated: 2026-06-28_  
_~350+ Swift files + Metal shaders + test suites across 50+ directories_

---

## Vayl/ (App Source)

```
Vayl/
├── Vayl.entitlements          — App capabilities and permissions
├── Vayl.plist                 — App configuration metadata
├── AppIconRetreival.swift     — Loads app icon from bundle for display in UI.
│
├── App/
│   ├── VaylApp.swift          — @main entry point; creates AppState, ThemeManager, ModelContainer, injects environment objects.
│   ├── AppShell.swift         — Tab router; switches between home, play, map, learn tabs with RacetrackTabBar.
│   ├── ModelContainer.swift   — SwiftData ModelContainer factory; returns previewContainer or live container.
│   │
│   └── Theme/
│       ├── AppAnimation.swift           — Reusable animation curves and durations (fast, slow, spring, etc.).
│       ├── AppColors.swift              — Full semantic color palette; ground truth for all colors.
│       ├── AppElevation.swift           — Shadow and depth scale for hierarchical elevation.
│       ├── AppFonts.swift               — Font factory for Clash Display, Switzer, Volkhov; semantic sizes.
│       ├── AppGlows.swift               — Glow and shimmer effect definitions for spectrum borders and accents.
│       ├── AppGrid.swift                — Layout grid constants; columns, gaps, alignment guides.
│       ├── AppLayout.swift              — Responsive layout sizing; adapts padding, margins, font sizes for screen size.
│       ├── AppRadius.swift              — Border radius scale for consistent corner rounding across components.
│       ├── AppRootView.swift            — Top-level routing gate; shows SplashScreenView once, then routes to auth/onboarding.
│       ├── AppSafeArea.swift            — Safe area insets and home indicator padding helpers.
│       ├── AppSpacing.swift             — Spacing scale (xs, sm, md, lg, xl, xxs, xxl); used for consistent padding/margins.
│       ├── AppTheme.swift               — ThemeMode enum and palette definitions; defines light/dark palettes.
│       ├── ThemeManager.swift           — @Observable class; persists theme mode to UserDefaults, resolves active palette.
│       ├── ThemeModifiers.swift         — ThemedRootModifier; injects AppPalette into environment and sets preferredColorScheme.
│       └── VaylPrimitives.swift         — Tier 1 raw hex colors; cyan, purple, magenta, gold, ink scale, neutrals.
│
├── Core/
│   ├── Models/
│   │   ├── AcknowledgementRecord.swift  — SwiftData model; tracks acknowledgement events (read, viewed, etc.).
│   │   ├── Card.swift                   — Core card model; title, description, answers, metadata.
│   │   ├── CardSession.swift            — SwiftData model; tracks card history within a session.
│   │   ├── CompanionCard.swift          — SwiftData model; companion cards (follow-ups, contextual prompts).
│   │   ├── Couple.swift                 — SwiftData model; represents paired couple; pairing code, experience type.
│   │   ├── Deck.swift                   — Card deck model; title, description, category, all cards.
│   │   ├── DeckProgress.swift           — Tracks progress through a deck; completed count, current position.
│   │   ├── DesireItem.swift             — SwiftData model; desire/compatibility item with categories and metadata.
│   │   ├── DesireMatch.swift            — SwiftData model; represents desire/compatibility rating between partners.
│   │   ├── DesireRating.swift           — SwiftData model; user's rating for a desire item in a category.
│   │   ├── EventLogEntry.swift          — SwiftData model; logs app events for debugging and analytics.
│   │   ├── LockInSession.swift          — SwiftData model; represents a locked-in session between partners.
│   │   ├── MilestoneRecord.swift        — SwiftData model; tracks user milestones and achievements.
│   │   ├── PulseAnswers.swift           — SwiftData model; pulse checkin answers (mood, status, etc.).
│   │   ├── PulseEntry.swift             — SwiftData model; daily pulse/mood checkin entry with timestamp.
│   │   ├── PulseHistory.swift           — SwiftData model; historical pulse data and trends.
│   │   ├── PulsePosition.swift          — SwiftData model; positional data for pulse visualization.
│   │   ├── SessionRecord.swift          — SwiftData model; tracks session metadata (start time, answers, etc.).
│   │   ├── SessionReflection.swift      — SwiftData model; post-session reflections and insights.
│   │   ├── SyncTask.swift               — SwiftData model; pending sync tasks to Supabase.
│   │   ├── UserProfile.swift            — SwiftData model; user profile data (name, preferences, birthday, etc.).
│   │   │
│   │   └── Enums/
│   │       ├── AppAccessEnums.swift     — Enums for access control (partner access, visibility, etc.).
│   │       ├── AppCardEnums.swift       — Enums for card types, card states, difficulty levels.
│   │       ├── AppDesireEnums.swift     — Enums for desire categories, ratings, match states.
│   │       ├── AppEnums.swift           — Shared enums (ExperienceType, LinkState, GenderIdentity, etc.).
│   │       ├── AppOBEnums.swift         — Enums for onboarding phases and states.
│   │       ├── AppPulseEnums.swift      — Enums for pulse tiers, mood states, check-in types.
│   │       ├── AppTab.swift             — Tab enum (home, play, map, learn).
│   │       ├── EventLogEnums.swift      — Enums for event log categories and types.
│   │       ├── Flavor.swift             — Enum for relationship flavor/style preferences.
│   │       └── UserDefaultsKey.swift    — Keys for UserDefaults storage.
│   │
│   ├── Debug/
│   │   ├── DiagnosticOverlay.swift      — #if DEBUG only; drop-in view overlays (CTAPositionMarker, measurePosition) for layout debugging.
│   │   └── DragDebugView.swift          — #if DEBUG only; debug view for testing drag interactions.
│   │
│   ├── Persistence/
│   │   ├── DataStore.swift              — SwiftData persistence layer; CRUD operations for models.
│   │   └── ModelContext+Extensions.swift — Fetch helper extensions for ModelContext.
│   │
│   └── Services/
│       ├── AgreementsService.swift      — Manages couple agreements and shared commitments.
│       ├── AppState.swift               — @Observable class; owns experienceType, linkState, displayName; persists to UserDefaults.
│       ├── AuthService.swift            — @Observable class; Sign in with Apple via Supabase; owns isAuthenticated, userId.
│       ├── Config.swift                 — Static constants; Supabase project URL and anon API key.
│       ├── ConsentService.swift         — Manages consent records for features and data access.
│       ├── ContentLoader.swift          — Loads bundled JSON files (cards.json, assessment_questions.json, etc.).
│       ├── ContentService.swift         — Manages content from resources and Supabase.
│       ├── DesireSyncService.swift      — Syncs desire ratings between local and Supabase; handles conflicts.
│       ├── EntitlementService.swift     — Manages feature entitlements and paywall state.
│       ├── EventLogService.swift        — Logs app events for debugging and analytics.
│       ├── LegalLinks.swift             — Manages legal document links (privacy, terms, etc.).
│       ├── PairingService.swift         — Couple pairing; generate codes, look up codes, complete pairing in Supabase.
│       ├── ProfileService.swift         — Reads/writes user profile to Supabase profiles table.
│       ├── PulseSyncService.swift       — Syncs pulse entries between local and Supabase.
│       ├── PushService.swift            — Manages push notification tokens and subscriptions.
│       ├── RealtimeSessionService.swift — Handles realtime updates for couple sessions via Supabase.
│       ├── SessionSyncService.swift     — Syncs session records (answers, timing) between local and Supabase.
│       ├── StoreKitService.swift        — Manages in-app purchases and entitlements via StoreKit 2.
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
│       │   ├── InfiniteCarousel.swift          — Infinite scrolling carousel component.
│       │   ├── PremiumCardShell.swift          — Premium card wrapper; adds premium badge and border.
│       │   ├── PromptCard.swift                — Generic prompt card container.
│       │   ├── SettingsCard.swift              — Settings panel card; key-value display.
│       │   ├── VaylCardAction.swift            — Action handlers for Vayl cards.
│       │   ├── VaylCardBack.swift              — New spectrum card back with Vayl branding.
│       │   ├── VaylCardContent.swift           — Content rendering for Vayl cards.
│       │   ├── VaylCardFace.swift              — New spectrum card front face (the canonical OB card).
│       │   ├── VaylCardRenderer.swift          — Card render orchestrator; handles flipping, animation, state.
│       │   ├── VaylCardCarousel.swift          — Carousel for Vayl cards with physics-based interaction.
│       │   ├── VaylDeckStack.swift             — Stack of Vayl cards with managed state.
│       │   │
│       │   ├── CardFaces/                      — Specialized card faces for different content types
│       │   │   ├── CandleCardFace.swift        — Card face with candle intensity visualization.
│       │   │   ├── CompassCardFace.swift       — Card face with compass/direction UI.
│       │   │   ├── CompassOptionCardFace.swift — Compass card with selectable options.
│       │   │   ├── CompassSliderCardFace.swift — Compass card with slider interaction.
│       │   │   ├── ContextCardFace.swift       — Card face for context selection.
│       │   │   ├── ControllerCardFace.swift    — Solo controller illustration card face.
│       │   │   ├── ControllerPainter.swift     — Painting logic for controller illustrations.
│       │   │   ├── DualControllerCardFace.swift — Dual controller illustration card face.
│       │   │   ├── RadioTunerCardFace.swift    — Card face with radio tuner interaction.
│       │   │   ├── SlotMachineCardFace.swift   — Card face with slot machine animation.
│       │   │   ├── SnapshotCardFace.swift      — Card face for snapshot/photo content.
│       │   │   └── TypewriterCardFace.swift    — Card face with typewriter text animation.
│       │   │
│       │   └── CardPhysics/                    — Physics engines for card animations
│       │       ├── CardFlightScene.swift       — SpriteKit scene driving card flight animations.
│       │       ├── CardMirrorDeal.swift        — Physics for dealing cards in a mirror pattern.
│       │       ├── CarouselPhysics.swift       — Physics for carousel scrolling behavior.
│       │       └── ThreeCardFanController.swift — Physics for dealing 3-card fan pattern.
│       │
│       ├── Effects/
│       │   ├── AuroraGlowField.swift           — Aurora shimmer background; animates soft glow across screen.
│       │   ├── FilamentMode.swift              — Metal shader effect; creates filament/thread visual pattern.
│       │   ├── FlameAura.swift                 — Flame-like aura effect; orange/red gradient glow.
│       │   ├── GlassSpecularSweep.swift        — Glass-like specular reflection effect.
│       │   ├── GlowOrb.swift                   — Glowing orb component; uses theme gradient.
│       │   ├── GlowUnderline.swift             — Animated glow underline for text; spectrum gradient.
│       │   ├── GlowUnderlineView.swift         — Container for glow underline effect.
│       │   ├── GradBadge.swift                 — Badge with spectrum gradient border.
│       │   ├── HolographicShimmer.metal        — Metal shader; creates holographic shimmer effect.
│       │   ├── HolographicShimmer.swift        — Wrapper for holographic shimmer Metal shader.
│       │   ├── LightAuraBloom.swift            — Light bloom effect; soft expanding glow.
│       │   ├── LightModeShimmer.swift          — Shimmer effect for light mode; warm gradient.
│       │   ├── MazePatternView.swift           — Procedural maze pattern background.
│       │   ├── OrbitSpark.metal                — Metal shader; creates orbiting spark effect.
│       │   ├── OrbitSparkBorderView.swift      — Sparking border animation around elements.
│       │   ├── PillBorder.swift                — Pill-shaped border with spectrum gradient.
│       │   ├── SectionHeader.swift             — Decorative section header divider.
│       │   ├── SectionHairline.swift           — Hairline divider for section separation.
│       │   ├── SparkField.swift                — Field of animated sparks; background effect.
│       │   ├── SparkleStar.swift               — Individual sparkling star component.
│       │   ├── SpectrumHairline.swift          — Hairline with spectrum gradient.
│       │   ├── StarVeil.swift                  — Veil of stars effect; background composition.
│       │   ├── TileOrbitView.swift             — Tiles orbiting in a circle; decorative effect.
│       │   ├── VaylBorderEffect.swift          — Complex border effect with multiple layers and animation.
│       │   ├── VaylButton.swift                — Button with Vayl-specific styling and effects.
│       │   ├── VaylFlourishView.swift          — Signature decorative flourish; duality encoding.
│       │   │
│       │   └── FoilOpen/                       — Foil/tuck-box tear effect components
│       │       ├── FoilDeckTheme.swift         — Theme configuration for foil deck appearance.
│       │       ├── MetallicCaseView.swift      — 3D metallic case rendering for foil tear.
│       │       └── SpectrumSparkField.swift    — Spark field effect for foil opening.
│       │
│       ├── Input/
│       │   ├── InteractiveField.swift          — Text input field with validation and decoration.
│       │   └── ToggleRow.swift                 — Toggle switch row for settings.
│       │
│       ├── Navigation/
│       │   ├── NavArrow.swift                  — Directional arrow button for navigation.
│       │   ├── OnboardingFooter.swift          — Footer with navigation buttons for onboarding.
│       │   ├── OnboardingNavBar.swift          — Navigation bar for onboarding screens.
│       │   ├── RacetrackTabBar.swift           — Custom tab bar with racetrack shape.
│       │   ├── SafariView.swift                — Wrapper for opening URLs in Safari.
│       │   ├── TabContentWrapper.swift         — Wrapper for tab content; handles transitions (deprecated, kept for reference).
│       │   ├── VaylPresentation.swift          — Reusable presentation modifiers (.vaylCover, .vaylSheet).
│       │   └── VaylSheet.swift                 — Custom sheet presentation container.
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
│       │   ├── HolographicText.swift           — Text with holographic glass effect.
│       │   ├── KeywordHighlightText.swift      — Text with highlighted keywords.
│       │   ├── LivingText.swift                — Animated text with gradient that changes per light/dark mode.
│       │   └── SpectrumBulletRow.swift         — Bullet point row with spectrum styling.
│       │
│       └── VaylMark.swift                      — Vayl wordmark/logo component.
│
├── Features/
│   ├── Auth/
│   │   └── Views/
│   │       └── SignInView.swift                — Sign in with Apple screen; handles AuthService.
│   │
│   ├── Desire Map/
│   │   ├── Store/
│   │   │   ├── CompanionCardStore.swift        — State management for companion cards.
│   │   │   ├── DesireMapStore.swift            — State management for desire map feature.
│   │   │   └── DesireRevealStore.swift         — State management for desire reveal/unlock flow.
│   │   ├── Views/
│   │   │   ├── DesireMapView.swift             — Main desire compatibility map visualization.
│   │   │   ├── DesireRevealView.swift          — Reveal/unlock view for desire map.
│   │   │   │
│   │   │   └── Components/
│   │   │       ├── ConstellationField.swift    — Star field layout for desire constellation.
│   │   │       ├── DesireConstellationView.swift — Desire constellation visualization.
│   │   │       ├── DesireMapListSheet.swift    — Sheet view listing desire items.
│   │   │       ├── DesireMatchDetail.swift     — Detail view for individual desire match.
│   │   │       └── DesireStarView.swift        — Individual desire star component.
│   │   │       └── DesireStarDetailSheet.swift — Detail sheet for desire star.
│   │   │
│   │   ├── CeremonyVariant.swift               — Variants for desire map reveal ceremony animation.
│   │   └── ConstellationLayout.swift           — Layout calculations for constellation positioning.
│   │
│   ├── Home/
│   │   ├── Components/
│   │   │   ├── CardChestContainer.swift        — Container for displaying available card decks.
│   │   │   ├── DeckPedestal.swift              — Pedestal display for featured deck.
│   │   │   ├── DesireMapIndicator.swift        — Small indicator for desire map on home.
│   │   │   ├── GettingStartedEntryCard.swift   — Entry card for getting started flow.
│   │   │   ├── HomeLexicon.swift               — Daily lexicon/term display on home.
│   │   │   ├── HomePulseRail.swift             — Rail display for pulse status.
│   │   │   ├── HomeWidgetShell.swift           — Container for home screen widgets (Pulse, etc.).
│   │   │   ├── PartnerChip.swift               — Displays partner info chip on home.
│   │   │   ├── ReflectionBannerView.swift      — Banner showing relationship reflection/insight.
│   │   │   └── ReflectionCard.swift            — Card displaying a reflection prompt.
│   │   ├── Models/
│   │   │   ├── GettingStarted.swift            — Getting started flow data model.
│   │   │   ├── HomeEventEngine.swift           — Event state machine for home screen transitions.
│   │   │   └── HomeModels.swift                — Data models for home screen state.
│   │   ├── Store/
│   │   │   └── HomeStore.swift                 — @Observable store; manages home screen state.
│   │   └── Views/
│   │       ├── GettingStartedPathView.swift    — Getting started path selection view.
│   │       ├── HomeDashboardView.swift         — Main home screen layout; card carousel, widgets.
│   │       ├── HomeGateView.swift              — Gate screen; routes to dashboard, waiting, or match-ready views.
│   │       ├── HomeRouterView.swift            — Navigation router for home tab.
│   │       └── MapChartedMoment.swift          — Map moment visualization on home.
│   │
│   ├── Learn/
│   │   ├── Store/
│   │   │   └── LearnStore.swift                — @Observable store; manages learn tab state.
│   │   └── Views/
│   │       ├── ConstellationNode.swift         — Individual node in learning constellation.
│   │       ├── FindingDetailView.swift         — Detail view for research findings.
│   │       ├── LearnCardStyle.swift            — Card styling for learn tab.
│   │       ├── LearnSegmented.swift            — Segmented control for learn content.
│   │       ├── LearnView.swift                 — Educational content browser; constellation layout.
│   │       ├── ResearchDatabaseView.swift      — Database view of research content.
│   │       ├── ResourcesOverlayView.swift      — Overlay for resource browsing.
│   │       └── Sections/
│   │           ├── ContentHubSection.swift    — Content hub section (books, watch, listen, voices).
│   │           ├── QuizCarouselSection.swift  — Carousel section for quizzes.
│   │           └── ResearchSection.swift      — Research findings section.
│   │
│   ├── Map/
│   │   ├── Components/
│   │   │   ├── FlavorVisuals.swift             — Visual styling for relationship flavors.
│   │   │   ├── MapPrimitives.swift             — Primitive UI elements for map display.
│   │   │   ├── MapPulseHero.swift              — Hero section showing pulse data.
│   │   │   ├── MapRecord.swift                 — Record/data display for map.
│   │   │   ├── MapUsLayer.swift                — "Us" layer visualization for map.
│   │   │   └── MeCardCompact.swift             — Compact "Me" card display.
│   │   ├── Vault/
│   │   │   ├── Components/
│   │   │   │   ├── DiscussionCardView.swift    — Card view for discussion/agreements.
│   │   │   │   ├── VaultAgreementsSection.swift — Section for displaying agreements.
│   │   │   │   ├── VaultDesireSection.swift    — Section for displaying desire data.
│   │   │   │   └── VaultLogSection.swift       — Section for event log display.
│   │   │   ├── EventEntryEditor.swift          — Editor for vault event entries.
│   │   │   ├── VaultSheet.swift                — Sheet presentation for vault.
│   │   │   └── VaultStore.swift                — State management for vault section.
│   │   ├── MapStore.swift                      — @Observable store; manages map tab state.
│   │   ├── MapView.swift                       — Main map tab view; Me/Us toggle, Pulse hero, Vault.
│   │   ├── MeCardSheet.swift                   — Sheet for detailed Me card view.
│   │   └── PrismView.swift                     — 3D prism effect for map visualization.
│   │
│   ├── Monetization/
│   │   ├── Store/
│   │   │   └── EntitlementStore.swift          — State management for entitlements and paywall.
│   │   └── Views/
│   │       └── PaywallSheet.swift              — Paywall presentation sheet.
│   │
│   ├── Onboarding/
│   │   ├── Canvas/
│   │   │   ├── Engines/
│   │   │   │   └── CardFlightEngine.swift      — Physics engine for card flight during onboarding.
│   │   │   ├── Math/
│   │   │   │   └── CanvasEasing.swift          — Easing functions for canvas animations.
│   │   │   ├── Sequencers/
│   │   │   │   ├── CuriositySequencer.swift    — Sequencer for curiosity phase timing.
│   │   │   │   ├── DemoSequencer.swift         — Sequencer for demo phase timing.
│   │   │   │   ├── GenderSequencer.swift       — Sequencer for gender phase timing.
│   │   │   │   └── NameSequencer.swift         — Sequencer for name phase timing.
│   │   │   ├── TableSurface/
│   │   │   │   └── TableSurfaceMath.swift      — Math calculations for table surface background.
│   │   │   ├── OBDeepCardFace.swift            — Card face driven by elapsed-time param for holographic shader.
│   │   │   ├── OnboardingCanvasView.swift      — Top-level onboarding canvas; orchestrates phases.
│   │   │   ├── OnboardingStage.swift           — Enum/types for onboarding stages.
│   │   │   ├── TableSurfaceView.swift          — Background table surface for onboarding.
│   │   │   └── VaylDirector.swift              — Orchestrates onboarding flow; routes between phases.
│   │   ├── Components/
│   │   │   ├── CornerDeckView.swift            — Decorative card in corner of screen.
│   │   │   ├── DeckWrapView.swift              — Wrapper for deck display during onboarding.
│   │   │   ├── FounderLetterSheet.swift        — Sheet for displaying founder letter.
│   │   │   ├── HandBackFollow.swift            — Hand/gesture follow animation.
│   │   │   ├── LiftHalo.swift                  — Halo effect for lift affordance teaching.
│   │   │   └── OnboardingAtmosphere.swift      — Background atmosphere/glow for onboarding.
│   │   ├── Director/
│   │   │   ├── BuildDeckCeremony.swift         — Ceremony logic for building the deck.
│   │   │   ├── DealerDictionary.swift          — Mapping of dealer/card states.
│   │   │   └── DealerProjector.swift           — Projector for dealer layout/positioning.
│   │   ├── Layout/
│   │   │   └── OnboardingLayout.swift          — Layout constants and geometry for onboarding.
│   │   ├── Models/
│   │   │   ├── CardLandingSlot.swift           — Predefined landing zones for OB card deal.
│   │   │   ├── ContextOption.swift             — Model for context selection options.
│   │   │   ├── CuriosityDeck.swift             — Model for curiosity category deck.
│   │   │   ├── CuriositySortCard.swift         — Model for curiosity sort card (categorization).
│   │   │   ├── DemoDictionary.swift            — Dictionary of demo content and sequencing.
│   │   │   ├── FoilTear.swift                  — Animation model for foil tear effect.
│   │   │   ├── OnboardingData.swift            — Data structure for onboarding content.
│   │   │   ├── VaylCardModel.swift             — Card model specific to onboarding.
│   │   │   └── WelcomeDeck.swift               — Welcome/intro deck model for onboarding.
│   │   ├── Phases/
│   │   │   ├── BuildDeckPhase.swift            — Onboarding phase: build the starter deck ceremony.
│   │   │   ├── ConfirmationPhase.swift         — Onboarding phase: confirm choices before finishing.
│   │   │   ├── ContextPhase.swift              — Onboarding phase: select relationship context.
│   │   │   ├── CredentialEditorSheet.swift     — Sheet for editing credentials/personal info during OB.
│   │   │   ├── CuriosityPhase.swift            — Onboarding phase: select curiosity categories.
│   │   │   ├── DemoPhase.swift                 — Onboarding phase: introductory demo.
│   │   │   ├── ExperienceLevelPhase.swift      — Onboarding phase: select experience level.
│   │   │   ├── FounderLetterPhase.swift        — Onboarding phase: display founder letter.
│   │   │   ├── GenderPhase.swift               — Onboarding phase: select gender identity.
│   │   │   ├── ModeSelectPhase.swift           — Onboarding phase: select solo/together mode.
│   │   │   ├── NamePhase.swift                 — Onboarding phase: enter user name.
│   │   │   ├── SingleGreetingSheet.swift       — Sheet for single/solo mode greeting.
│   │   │   └── StatPhase.swift                 — Onboarding phase: show stats/summary.
│   │   ├── Renders/
│   │   │   ├── AnimatedSignature.swift         — Animated signature rendering.
│   │   │   ├── DealPointView.swift             — Renders deal point (card reveal point).
│   │   │   └── ProjectedTextView.swift         — Text with projection/perspective effect.
│   │   └── Store/
│   │       └── OnboardingStore.swift           — @Observable store; manages onboarding state.
│   │
│   ├── Pairing/
│   │   ├── PairingInviteView.swift             — Screen to generate and share pairing code.
│   │   ├── PairingJoinView.swift               — Screen to enter pairing code and join.
│   │   ├── PairingSettingsView.swift           — Settings for managing pairing.
│   │   └── PairingStore.swift                  — State management for pairing feature.
│   │
│   ├── Play/
│   │   ├── Components/
│   │   │   ├── DeckBeginCeremony.swift         — Ceremony view for beginning a deck session.
│   │   │   ├── DeckCaseView.swift              — Case/shelf display for deck.
│   │   │   ├── DeckCellView.swift              — Individual deck cell in grid.
│   │   │   ├── DeckDetailView.swift            — Detail view for a deck.
│   │   │   ├── DeckGlyph.swift                 — Icon/glyph for deck representation.
│   │   │   ├── DeckWallView.swift              — Wall/gallery view of decks.
│   │   │   ├── PlayEmptyState.swift            — Empty state when no decks available.
│   │   │   ├── PlayHeroView.swift              — Hero section of Play tab.
│   │   │   ├── PlayMastheadView.swift          — Masthead/header for Play tab.
│   │   │   └── ZoomablePanView.swift           — Zoomable and pannable view for deck exploration.
│   │   ├── Models/
│   │   │   ├── DeckStyle.swift                 — Style configuration for deck display.
│   │   │   └── DeckSummary.swift               — Summary data for deck.
│   │   ├── Services/
│   │   │   └── DeckCatalogService.swift        — Service for loading deck catalog.
│   │   ├── Store/
│   │   │   ├── PlayMode.swift                  — Enum/state for play mode variants.
│   │   │   └── PlayStore.swift                 — @Observable store; manages play tab state.
│   │   └── PlayView.swift                      — Play tab main view; card game interface.
│   │
│   ├── Progress/
│   │   └── ProgressDashboardView.swift         — Dashboard showing progress through decks/sessions.
│   │
│   ├── Pulse/
│   │   ├── Components/
│   │   │   ├── PulseAura.swift                 — Aura effect for pulse visualization.
│   │   │   ├── PulseCapsule.swift              — Capsule display for pulse data.
│   │   │   ├── PulseField.swift                — Field visualization for pulse.
│   │   │   └── PulseHistoryGrid.swift          — Grid display of pulse history.
│   │   ├── CheckInShell.swift                  — Container for checkin modals.
│   │   ├── DailyCheckInView.swift              — Daily pulse/mood checkin interface.
│   │   ├── PulseCheckInCover.swift             — Cover presentation for pulse checkin.
│   │   ├── PulseCheckInView.swift              — Pulse checkin interaction view.
│   │   ├── PulseFullView.swift                 — Full view of pulse history with graphs.
│   │   ├── PulseSheetView.swift                — Sheet presentation for pulse details.
│   │   ├── PulseWidget.swift                   — Home screen widget showing pulse status.
│   │   ├── TierGuideSheet.swift                — Sheet explaining pulse tier/level system.
│   │   └── Store/
│   │       └── PulseStore.swift                — @Observable store; manages pulse/checkin state.
│   │
│   ├── Sessions/
│   │   ├── AirlockView.swift                   — Airlock/transition view for entering sessions.
│   │   ├── CardSessionContainerView.swift      — Container for card session experience.
│   │   ├── CoupleSessionStore.swift            — State management for couple sessions.
│   │   ├── SessionAtmosphere.swift             — Background atmosphere for session.
│   │   ├── SessionCloseView.swift              — View for closing/exiting a session.
│   │   ├── SessionPlan.swift                   — Plan/structure for a session.
│   │   ├── SessionPlayerView.swift             — Player view for session card display.
│   │   ├── SessionStore.swift                  — State management for session tracking.
│   │   └── SessionView.swift                   — Session history and details view.
│   │
│   └── Settings/
│       ├── SettingsAppearanceView.swift        — Settings for app appearance (theme, etc.).
│       ├── SettingsComponents.swift            — Reusable settings UI components.
│       ├── SettingsIdentityView.swift          — Settings for user identity and profile.
│       ├── SettingsNotificationsView.swift     — Settings for push notifications.
│       ├── SettingsPartnerView.swift           — Settings for partner/pairing management.
│       ├── SettingsPrivacyView.swift           — Settings for privacy and legal (consent, etc.).
│       └── SettingsView.swift                  — Main settings screen.
│
└── Resources/
    ├── Content/
    │   ├── assessment_questions.json           — Bundled assessment questions for quizzes.
    │   ├── cards.json                          — Bundled card deck data.
    │   ├── categories.json                     — Bundled category definitions.
    │   ├── companion_cards.json                — Companion card prompts and metadata.
    │   ├── desire_items.json                   — Bundled desire/compatibility items.
    │   ├── learn_media.json                    — Learn tab media resources (books, videos, etc.).
    │   ├── learn_quizzes.json                  — Learn tab quiz definitions.
    │   ├── lexicon_terms.json                  — Daily lexicon terms for Home feed.
    │   ├── media_quotes.json                   — Curated media quotes.
    │   ├── research_findings.json              — Research findings for Learn tab.
    │   ├── support_resources.json              — Support resources (hotlines, etc.).
    │   └── voices.json                         — Voices/resources for Learn content.
    ├── Decks/
    │   ├── before-tonight.json                 — Deck: Before Tonight (pre-session prep).
    │   ├── boundaries.json                     — Deck: Boundaries (boundary exploration).
    │   ├── communication.json                  — Deck: Communication (relationship talk).
    │   ├── deck-catalog.json                   — Catalog metadata for all decks.
    │   ├── deck-index.json                     — Index of available decks.
    │   ├── desire-and-fantasy.json             — Deck: Desire & Fantasy.
    │   ├── jealousy-compersion.json            — Deck: Jealousy & Compersion.
    │   ├── metamour.json                       — Deck: Metamour (non-primary partner).
    │   ├── right-now.json                      — Deck: Right Now (current state).
    │   ├── solo-prep.json                      — Deck: Solo Prep (solo mode starter).
    │   ├── the-audit.json                      — Deck: The Audit (relationship review).
    │   ├── the-check-in.json                   — Deck: The Check-In (regular checkin).
    │   ├── the-opener.json                     — Deck: The Opener (starter deck).
    │   ├── the-styles.json                     — Deck: The Styles (relationship styles).
    │   ├── trust-repair.json                   — Deck: Trust Repair (rebuilding trust).
    │   └── unfinished-business.json            — Deck: Unfinished Business (past issues).
    │
    └── Fonts/
        ├── ClashDisplay-*.otf                  — Clash Display font family (6 weights).
        ├── IBMPlexMono-*.ttf                   — IBM Plex Mono monospace font.
        ├── Switzer-*.otf                       — Switzer body font family (15 weights/styles).
        ├── Volkhov-*.ttf                       — Volkhov serif font (editorial use).
        └── Zodiak-*.otf                        — Zodiak decorative font family (15 weights/styles).
```

---

## VaylTests/ (Test Suite)

```
VaylTests/
├── CandleIntensityTests.swift                  — Unit tests for candle intensity calculations.
├── ContextOptionTests.swift                    — Unit tests for context selection logic.
├── CoupleSessionPlaythroughTests.swift         — Integration tests for couple session flow.
├── DesireMapModelTests.swift                   — Unit tests for desire map models and calculations.
├── DesireMapStoreTests.swift                   — Unit tests for DesireMapStore state management.
├── DesireRevealStoreTests.swift                — Unit tests for DesireRevealStore paywall/reveal flow.
├── GettingStartedTests.swift                   — Unit tests for getting started flow.
├── MonteRowGeometryTests.swift                 — Unit tests for Pulse history grid geometry.
├── PulseAnswersTests.swift                     — Unit tests for pulse checkin answer models.
├── PulseHistoryTests.swift                     — Unit tests for pulse history calculations.
└── PulsePositionTests.swift                    — Unit tests for pulse position/visualization data.
```

---

## supabase/

```
supabase/
├── config.toml                                 — Supabase project configuration.
│
├── functions/                                  — Deno edge functions
│   ├── appstore-notifications/
│   │   └── index.ts                            — Handles App Store receipt validation and entitlement grants.
│   ├── compute-desire-matches/
│   │   ├── index.ts                            — Computes desire compatibility scores between partners.
│   │   └── match-logic.test.ts                 — Tests for match logic.
│   │   └── match-logic.ts                      — Desire matching algorithm implementation.
│   ├── consent-ask/
│   │   └── index.ts                            — Initiates consent request flow between partners.
│   ├── consent-respond/
│   │   └── index.ts                            — Handles consent responses (accept/decline).
│   ├── create-pair/
│   │   ├── deno.json                           — Dependencies for create-pair function.
│   │   ├── .npmrc                              — NPM configuration.
│   │   └── index.ts                            — Creates couple pairing relationship.
│   ├── get-partner/
│   │   └── index.ts                            — Fetches partner profile/relationship data.
│   ├── grant-entitlement/
│   │   └── index.ts                            — Grants feature entitlements to users.
│   ├── lookup-code/
│   │   ├── deno.json                           — Dependencies for lookup-code function.
│   │   ├── .npmrc                              — NPM configuration.
│   │   └── index.ts                            — Looks up pairing code validity and details.
│   ├── rapid-task/
│   │   └── index.ts                            — Rapid task processing for time-sensitive operations.
│   └── send-session-invite/
│       └── index.ts                            — Sends session invitations to partner via push.
│
├── migrations/                                 — Database schema migrations
│   ├── 20260101000000_baseline.sql             — Initial schema baseline (users, profiles, couples).
│   ├── 20260616223000_p5d_revoke_anon_default_privileges.sql — Security migration revoking default anon privileges.
│   ├── 20260617000000_desire_map_backend.sql   — Desire map tables (items, ratings, matches, reveals).
│   ├── 20260617120000_monetization_entitlements.sql — Entitlements table for feature access.
│   ├── 20260617130000_entitlement_payer_portable_resolution.sql — Entitlement portability (payer-based tiers).
│   ├── 20260621180000_session_push_tokens.sql  — Push token storage for realtime notifications.
│   ├── 20260624120000_vault_agreements.sql     — Couple agreements/commitments table.
│   ├── 20260624120100_vault_event_log.sql      — Event log for couple activities.
│   ├── 20260624120200_vault_consent.sql        — Consent tracking table.
│   └── 20260626000000_desire_map_reveal_state_collapse.sql — Desire reveal state restructuring.
│
└── tests/                                      — pgTAP test suite
    ├── README.md                               — Test documentation.
    ├── desire_map_integration.test.sql         — Integration tests for desire map flows.
    └── desire_map_invariants.test.sql          — Invariant tests for desire map data integrity.
```

---

## Key Architectural Layers

**Tier 1 — Primitives (VaylPrimitives.swift)**  
Raw hex colors, values, and design constants.

**Tier 2 — Tokens (AppColors.swift, AppFonts.swift, AppSpacing.swift, etc.)**  
Semantic tokens derived from primitives. Used everywhere in views.

**Tier 3 — Components (Design/Components/)**  
Reusable UI elements (buttons, cards, effects, text, navigation, progress, specialized card faces).

**Tier 4 — Features (Features/)**  
Screens and flows (Home, Onboarding, Pairing, Pulse, Sessions, Map, Settings, etc.).

**Cross-cutting — Services & Stores (Core/Services/, Features/*/Store/)**  
State management, sync, auth, data persistence, and business logic.

**Persistence — Models, Persistence, Services**  
SwiftData models, Supabase sync, and backend integration.

---

## Notable Architecture Decisions

### Card Faces (Design/Components/Cards/CardFaces/)
Specialized card rendering components for different content types (Candle, Compass, Radio Tuner, Slot Machine, Typewriter, etc.). Each face implements unique interaction and animation patterns.

### Onboarding Canvas (Features/Onboarding/Canvas/)
Phase-based onboarding orchestrated by `VaylDirector`. Canvas uses `TableSurfaceView` background, `OBDeepCardFace` for the hero card, and specialized sequencers for timing each phase. Avoid modifications to `VaylCardFace` shell geometry or foil-tear.

### 4-Layer Architecture (CLAUDE.md)
**View** → **Store** → **Service** → **Model**
- Views call Stores only; Stores own state, call Services
- Services handle network/I/O; Models are pure data
- `VaylDirector.advance()` is the ONLY phase change mechanism
- No View writes to `VaylCardModel` directly

### Desire Map (Features/Desire Map/)
Multi-phase reveal flow with constellation visualization. Stores include `DesireMapStore` (map logic), `DesireRevealStore` (paywall/unlock), and `CompanionCardStore` (follow-up cards).

### Monetization (Features/Monetization/)
`EntitlementStore` manages paywall state and feature access. Backend enforces via Supabase RLS and edge functions (`grant-entitlement`, `appstore-notifications`).

### Vault (Features/Map/Vault/)
Shared couple record: agreements, event log, consent tracking. Accessed via Map tab secondary section.

### Pulse Redesign (Features/Pulse/)
2D circumplex visualization + "living caustic under glass" aura + Us-comparison capsule + last-30-logged split grid. Components split into separate files (PulseAura, PulseCapsule, PulseField, PulseHistoryGrid).

### Map Tab (Features/Map/)
Me|Us toggle (NOT "Mirror"). Pulse hero + Vault. Single canonical glass card + reused Pulse/Desire/Couple components.

---

## File Change Summary (from 2026-05-19 baseline)

### Major Additions (2026-06-28 update)
- **Monetization**: Full paywall/entitlement system (EntitlementStore, PaywallSheet, grant-entitlement edge function)
- **Desire Map Reveal**: Reveal flow with constellation and match ceremony (DesireRevealStore, DesireRevealView)
- **Map Tab**: Full redesign with Me/Us toggle, Pulse hero, Vault sections
- **Vault**: Agreements, event log, consent tracking
- **Learn Tab**: Expanded with sections, quizzes, research, resources
- **Pulse Redesign**: Split into modular components (PulseAura, PulseCapsule, PulseField, PulseHistoryGrid)
- **Card Faces**: Specialized rendering for different card types (Candle, Compass, RadioTuner, SlotMachine, Typewriter, etc.)
- **Onboarding Canvas**: Sequencers and engines for phase timing
- **FoilOpen**: 3D metallic case tear effect for deck opening
- **Effects**: Extended with GlassSpecularSweep, SparkleStar, StarVeil, SpectrumHairline, SectionHairline
- **Navigation**: VaylPresentation, VaylSheet for consistent presentation grammar
- **Services**: ConsentService, EntitlementService, EventLogService, PushService, RealtimeSessionService, StoreKitService, AgreementsService
- **Enums**: Reorganized into discrete files by domain (AppAccessEnums, AppCardEnums, AppDesireEnums, AppPulseEnums, EventLogEnums, Flavor, UserDefaultsKey)
- **Learn Models**: Dedicated folder with LearnMediaItem, LearnQuiz, LexiconTerm, MediaQuote, ResearchFinding, SupportResource, Voice
- **Settings**: Split into focused views (SettingsAppearanceView, SettingsIdentityView, SettingsNotificationsView, SettingsPartnerView, SettingsPrivacyView)
- **Play Tab**: Components for deck display (DeckCaseView, DeckGlyph, DeckWallView, DeckDetailView, etc.)
- **Tests**: Full test suite with 11 test files covering models, stores, and integration flows

### Deprecated/Reference Only
- `TabContentWrapper.swift` — deprecated; AppShell now uses native tab bar; kept for reference
- (`RotaryDial.swift` and `Sessions/Debug/PresenceDebugView.swift` deleted 2026-07-07 — dead code)
