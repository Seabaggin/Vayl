# Vayl — File Tracker

> Last updated: 2026-05-16
> ~230 Swift files across 44 directories

---

## Reach Tags

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
| **`VaylApp.swift`** | `@main` entry point. Creates `ThemeManager`, `AppState`, `PulseStore`, `AuthService`, `OnboardingStore`. Injects all environment objects. Retries pending syncs on launch via `SyncManager`. | **`BACKBONE`** |
| **`AppRootView.swift`** | Thin gate router. Branches on auth state → `SignInView` vs. content views. | **`HUB`** |
| **`AppShell.swift`** | Main tab bar shell. Switches on `selectedTab: AppTab` (.home/.play/.map/.learn) and wraps each in `TabContentWrapper`. | **`HUB`** |
| **`ContentView.swift`** | Root onboarding gate. Branches on `isOnboardingComplete` → `OnboardingFlowView` vs. `AppShell`. | **`HUB`** |
| **`ModelContainer.swift`** | SwiftData schema definition (SchemaV1). Registers all `@Model` classes. Called from `VaylApp`. | |

### `App/Theme/`

| File | What It Does | Reach |
|---|---|---|
| **`AppColors.swift`** | Tier 2 semantic color tokens. Every color resolves automatically for light/dark via `UIColor(dynamicProvider:)`. Maps exclusively to `VaylPrimitives`. | **`FOUNDATION`** |
| **`AppFonts.swift`** | Typography scale. Font.custom only, no Font.system. Semantic sizes: screenTitle/headline/body/caption. | **`FOUNDATION`** |
| **`VaylPrimitives.swift`** | Tier 1 primitive color constants. Light dawn palette (warm cream) and dark midnight palette (deep ink). Never referenced outside `AppColors.swift`. | |
| **`AppTheme.swift`** | Defines `ThemeMode` enum (system/light/amoled) and theme palette structs. | |
| **`ThemeManager.swift`** | `@Observable` class. Persists user-selected theme to `UserDefaults` and resolves active palette from mode + system `colorScheme`. | |
| **`ThemeModifiers.swift`** | `ThemedRootModifier` ViewModifier. Injects resolved `AppPalette` into environment and sets `preferredColorScheme`. Applied once at root. | |
| **`AppAnimation.swift`** | Centralized animation timing constants (`.standard`, `.cardTransition`, spring configs). | |
| **`AppSpacing.swift`** | Spacing scale: `xs`/`sm`/`md`/`lg`/`xl`/`xxl`. | |
| **`AppRadius.swift`** | Corner radius tokens: `none`/`sm`/`md`/`lg`/`full`. | |
| **`AppGrid.swift`** | Grid layout system. Column counts and gutter widths for device classes. | |
| **`AppLayout.swift`** | OB card geometry functions. `obCardWidth(in:)` / `obCardHeight(in:)` — never hardcoded. | |
| **`AppSafeArea.swift`** | UIKit key window reader. Never geo.safeAreaInsets in OB. | |
| **`AppElevation.swift`** | Elevation/z-index tokens for layering hierarchy. | |
| **`AppGlows.swift`** | Glow intensity and color mappings for effects across the app. | |

---

## `Core/Models/`

| File | What It Does | Reach |
|---|---|---|
| **`UserProfile.swift`** | `@Model`. Created on OB completion. Never before. Full user profile — name, pronouns, gender, NM stage, app mode, curiosity selections, archetype. | **`BACKBONE`** |
| **`Couple.swift`** | `@Model`. Links two UserProfiles. `EntitlementRecord` lives here, not UserProfile. Archived not deleted. | **`BACKBONE`** |
| **`Card.swift`** | Codable struct. Loaded from JSON. NEVER SwiftData. One prompt: text, highlights, category, difficulty, sensitivity. | |
| **`Deck.swift`** | Codable struct. Loaded from JSON. NEVER SwiftData. One deck: cards array, difficulty, intensity. | |
| **`CardSession.swift`** | `@Model`. `coupleId` — never `userId`. One playback of a deck. Cards shown, skipped, reactions, timestamps. | |
| **`SessionRecord.swift`** | `@Model`. One completed or safe-worded session. Duration, category, completion date. | |
| **`DeckProgress.swift`** | `@Model`. String `cardId` joins to Card. Never stores card text. Per-user per-deck progress. | |
| **`DesireRating.swift`** | `@Model`. Local SwiftData only. NEVER synced. `notForUs` never leaves device. One user's private rating of one desire map item. | |
| **`DesireMatch.swift`** | Supabase only. Computed by Edge Function. Never by client. Positive desire alignment between partners. | |
| **`PulseEntry.swift`** | `@Model`. Local only. Emotional state — health-adjacent data. One daily mood check-in. | |
| **`EntitlementRecord.swift`** | `@Model`. On Couple, not UserProfile. One purchase = both partners. | |
| **`MilestoneRecord.swift`** | `@Model`. Milestone/achievement records. Type, date achieved. | |
| **`AcknowledgementRecord.swift`** | `@Model`. Ground rules / ethical acknowledgements. Timestamp accepted. | |
| **`LockInSession.swift`** | `@Model`. Lock-in session record. (Pending full implementation.) | |

### `Core/Models/Enums/`

| File | What It Does | Reach |
|---|---|---|
| **`AppEnums.swift`** | Master enum file. `NMStage`, `AppMode`, `CardIntensity`, `CardStatus`, `ConnectionType`, `OpenerDeckType`, `ArchetypeTag`. All shared domain enums. | **`FOUNDATION`** |
| **`AppTab.swift`** | Four tab cases: `.home`, `.play`, `.map`, `.learn`. Hashable for TabView selection. | |

---

## `Core/Persistence/`

| File | What It Does | Reach |
|---|---|---|
| **`DataStore.swift`** | Central persistence layer. Stub implementations — RatingRecord/StreakRecord replacements pending. | **`BRIDGE`** |
| **`ModelContext+Extensions.swift`** | Extension helpers for SwiftData operations. | |

---

## `Core/Services/`

| File | What It Does | Reach |
|---|---|---|
| **`AppState.swift`** | `@Observable @MainActor`. Central app-level state. Owns onboarding gate, link state, tab routing. | **`BACKBONE`** |
| **`AuthService.swift`** | `@Observable @MainActor`. Sign in with Apple via Supabase. Publishes `isAuthenticated`, `userId`, `isLoading`, `error`. | **`BACKBONE`** |
| **`SupabaseManager.swift`** | Singleton. Initializes and exposes single `SupabaseClient`. All services read from `SupabaseManager.shared.client`. | **`BRIDGE`** |
| **`ContentLoader.swift`** | Static generic helper. Decodes bundled JSON files (decks, cards). `fatalError` on missing/malformed — dev-time catch. | |
| **`PairingService.swift`** | Couple pairing — generate codes, lookup, complete pairing in Supabase. | |
| **`SyncManager.swift`** | Local-first orchestrator. Save to SwiftData first, push to Supabase; flag for retry via `UserDefaults` on failure. | **`BRIDGE`** |
| **`DesireSyncService.swift`** | Pushes desire ratings from SwiftData to Supabase. Ratings are private — only used server-side for alignment. | |

---

## `Design/Brand/`

| File | What It Does |
|---|---|
| **`VaylAppIcon.swift`** | App icon vector render. Geometric spectrum design. |
| **`SplashScreenView.swift`** | Animated intro splash screen. Plays once on cold launch before routing to content. |

---

## `Design/Components/Buttons/`

| File | What It Does |
|---|---|
| **`VaylButton.swift`** | Primary branded button. Spectrum gradient border + glow. Replaces GradientButton and HoloCTAButton. |
| **`CriticalButton.swift`** | Destructive/neutral action button. `.neutral` and `.danger` styles. |
| **`SafeWordButton.swift`** | Always-visible safety button during sessions. Confirmation alert before triggering safe-word callback. |
| **`SelectablePill.swift`** | Toggle pill for multi-select lists. Three intensity levels. Dark: holo shimmer + flame aura. Light: aurora shimmer + shadow. |

---

## `Design/Components/Cards/`

| File | What It Does |
|---|---|
| **`CardLayout.swift`** | Single source of truth for card dimensions. Standard card: 313×438pt (1.40 ratio). |
| **`CardStyle.swift`** | ViewModifier. Reusable card shell: background + rounded clip + border stroke. |
| **`VaylCardRenderer.swift`** | Unified card rendering system for sessions/play. Renders both faces. |
| **`VaylCardFace.swift`** | Front card face. Prompt, highlights, difficulty badge, category. |
| **`VaylCardBack.swift`** | Back card face. Options and interaction state. |
| **`CardBackView.swift`** | Back face of flip card. Gradient fill, "Something came up" heading, 4 selectable pill buttons. |
| **`CardFrontView.swift`** | Front face of flip card. Bridge prompt text + fuse timer burn effect. |
| **`CardRevealPillButton.swift`** | Individual pill button on CardBackView. Selected/unselected visual states, entrance stagger. |
| **`CardShadows.swift`** | `.cardShadows(isLight:)` View extension. Two-layer shadow modifier. |
| **`CardCarousel.swift`** | Carousel navigation model and state. Enum-based phase tracking. |
| **`AtmosphericGhostDeck.swift`** | Ghost deck visual for reveals. Layered cards with atmospheric blur + glow. |
| **`CategoryTileView.swift`** | Home-screen grid tile. Emoji, name, card count, ProgressBar per category. |
| **`ConversationCard.swift`** | Rendered prompt card in sessions. Text with highlighted keywords, difficulty badge. |
| **`ConversationCardTypes.swift`** | Types and enums for conversation cards. Card styling by difficulty/type. |
| **`CuriosityCardBack.swift`** | Face-down side of curiosity picker cards. Laser-engraved maze texture + embedded TileOrbitView. |
| **`CuriosityFlipCard.swift`** | 3D flip container. `isFlipped` drives visibility and orbit state. |
| **`FuseTimerView.swift`** | Session timer display. Countdown/elapsed with optional urgency indicators. |
| **`PromptCard.swift`** | Single conversation prompt with difficulty-keyed styling (tint, border opacity, glow). |
| **`SettingsCard.swift`** | Generic `<Content: View>` container. Wraps content in padded `.cardStyle()` shell. |
| **`PremiumCardShell.swift`** | Premium/entitlement-gated card container. Shows lock or unlock state. |

---

## `Design/Components/Effects/`

| File | What It Does |
|---|---|
| **`VaylBorderEffect.swift`** | Animated spectrum gradient border. Used on VaylButton and bordered surfaces. |
| **`AuroraGlowField.swift`** | Light mode atmospheric blob background. 6 blobs in magenta/purple/gold/pink at 6–9% opacity. |
| **`HomeGlowField.swift`** | Home screen variant of glow field. Config-driven atmosphere. |
| **`OnboardingGlowField.swift`** | Onboarding atmosphere glow field. Per-screen config transitions. |
| **`HolographicShimmer.swift`** | Animated cyan→purple→magenta→pink gradient sweeping L→R. Dark mode overlay. |
| **`LightModeShimmer.swift`** | Light mode counterpart shimmer. 7–11% opacity, 11s sweep. |
| **`FlameAura.swift`** | Flame-wisp particle effect for selected pills in dark mode. |
| **`FloatingCard.swift`** | Individual floating glass card with float physics (Y offset, rotation, gravity). |
| **`FloatingStack.swift`** | Generic collapsible card stack. Config-driven with `.curiosityStack` and `.sessionDeck` presets. |
| **`GlowOrb.swift`** | Single blurred radial-gradient circle. Decorative accent. |
| **`GlowUnderline.swift`** | Underline ViewModifier with glow effect. |
| **`GlowUnderlineView.swift`** | Standalone glow underline view. |
| **`GradBadge.swift`** | Gradient badge component. Used in DesireMapView and ThemeTestView. |
| **`MazePatternView.swift`** | Concentric ring maze with gaps/spokes. Three rendering layers. Embeds TileOrbitView at center. |
| **`TileOrbitView.swift`** | Canvas-based comet orbit animation for small tiles (44–88pt). Zero GPU cost at rest. |
| **`OrbitSparkBorderView.swift`** | Decorative border with orbital spark animation. |
| **`PillBorder.swift`** | ViewModifier. Holographic pill border: cyan→purple→magenta gradient stroke + glow. |
| **`SparkField.swift`** | Canvas-based campfire ember particle system for light mode. Screen-specific configs. |
| **`FilamentMode.swift`** | **[DEAD CODE — never referenced. Delete.]** |
| **`SectionHeader.swift`** | All-caps muted label for section dividers. |

---

## `Design/Components/Input/`

| File | What It Does |
|---|---|
| **`InteractiveField.swift`** | Styled text field with emoji/icon prefix. Themed background and text. |
| **`RatingButtonGroup.swift`** | 2×2 grid of rating buttons for Desire Map. Bound to `DesireLevel?`. Haptic feedback. |
| **`ToggleRow.swift`** | Icon + label + Toggle row for Settings. |

---

## `Design/Components/Navigation/`

| File | What It Does |
|---|---|
| **`OnboardingNavBar.swift`** | Back chevron + centered `OnboardingProgressBar`. Frosted circle in light mode. |
| **`OnboardingFooter.swift`** | Small footer below CTA ("Your data is encrypted…"). Adapts to light/dark. |
| **`NavArrow.swift`** | Reusable chevron navigation arrow component. |
| **`RacetrackTabBar.swift`** | Custom racetrack-style tab bar navigation. |
| **`TabContentWrapper.swift`** | Wraps tab content. Handles safe area and layout constraints. |

---

## `Design/Components/Progress/`

| File | What It Does |
|---|---|
| **`OnboardingProgressBar.swift`** | Animated progress bar for onboarding. Bloom glow, holographic shimmer, breathing pulse. |
| **`ProgressBar.swift`** | Simple themed horizontal bar. `t.buttonGradient` fill on muted track. |
| **`ProgressRingView.swift`** | Circular progress ring. Configurable line width. Track adapts to amoled/light. |
| **`ScoreRing.swift`** | Circular ring displaying 0–100 score. Animates fill on appear. |
| **`SpectrumBar.swift`** | Thin capsule filled with `t.spectrumGradient`. Decorative separator. |
| **`OrbitIndicator.swift`** | Orbital animation progress indicator. Used in processing animations. |
| **`ScreenshotProtectionModifier.swift`** | Listens for screenshot/screen-recording. Overlays blur + "Content Protected". |

---

## `Design/Components/Text/`

| File | What It Does |
|---|---|
| **`GradientText.swift`** | Static gradient text. Dark: pink→purple→magenta. Light: magentaDark→magenta→orangeHot. |
| **`LivingText.swift`** | Animated gradient text with breathing glow. TimelineView @ 30fps. App's animated text identity. |
| **`KeywordHighlightText.swift`** | Renders text with keywords highlighted in cyan/magenta/gold via NSAttributedString. |

---

## `Features/Auth/Views/`

| File | What It Does |
|---|---|
| **`SignInView.swift`** | Sign in with Apple screen. Uses `AuthService` via `@Environment`. |

---

## `Features/Compatibility/`

| File | What It Does |
|---|---|
| **`DesireMapView.swift`** | Expandable category list where users privately rate intimacy items with `DesireLevel`. Persistence pending. |
| **`Store/DesireMapStore.swift`** | Manages desire map category expansion and rating state. |

---

## `Features/Home/Views/`

| File | What It Does |
|---|---|
| **`HomeDashboardView.swift`** | Main home dashboard. Categories, progress, session history, quick-start buttons. |
| **`HomeRouterView.swift`** | Advanced home router. Deep linking, state restoration, routing logic. |
| **`HomeGateView.swift`** | Gate view for home. Handles loading state and auth checks. |
| **`HomeMatchReadyView.swift`** | Couple home variant. Partner readiness status and synchronized session invitations. |
| **`HomeWaitingView.swift`** | Waiting state for pending partner acceptance or sync. |

### `Features/Home/Components/`

| File | What It Does |
|---|---|
| **`CardChestContainer.swift`** | Card chest/deck container. Shows available cards to play. |
| **`DesireMapIndicator.swift`** | Visual indicator for desire map completion status. |
| **`GravLiftView.swift`** | Gravity lift animation effect component. |
| **`HomeWidgetShell.swift`** | Generic widget container for home screen cards. Enum-based rim variants. |
| **`PartnerChip.swift`** | Compact partner profile chip. Name, status, initial. |
| **`PickUpCard.swift`** | Quick-action card to resume or start a session. |
| **`PostMapReflectionView.swift`** | Post-desire-map reflection screen. Synthesis of alignment data. |
| **`ReflectionBannerView.swift`** | Banner prompting reflection after key moments. |
| **`ReflectionCard.swift`** | Card for structured reflection prompts. |
| **`ResearchTicker.swift`** | Scrolling research insights ticker. |

### `Features/Home/Models/`

| File | What It Does |
|---|---|
| **`HomeModels.swift`** | Data models for home views. Session summaries, category tiles, partner data. `ReflectionCardState` enum. |

### `Features/Home/Store/`

| File | What It Does | Reach |
|---|---|---|
| **`HomeStore.swift`** | `@Observable @MainActor`. Brain of home flow. Deck loading, map completion, routing state. Dependencies injected via init — never from `@Environment`. | **`HUB`** |

---

## `Features/Sessions/`

| File | What It Does | Reach |
|---|---|---|
| **`SessionView.swift`** | Thin view — renders only. All logic lives in `SessionStore`. | |
| **`SessionStore.swift`** | `@Observable @MainActor`. Brain of card session. Card navigation, result recording, persistence. Dependencies injected via init. | **`HUB`** |

---

## `Features/Play/`

| File | What It Does |
|---|---|
| **`PlayView.swift`** | Play hub. Browse and start sessions by category or difficulty. |

---

## `Features/Map/`

| File | What It Does |
|---|---|
| **`MapView.swift`** | Navigation hub for desire map and relationship insights. |
| **`PrismView.swift`** | Prism visualization. Alignment/relationship insights. Enum `PrismMode`-driven. |

---

## `Features/Learn/Views/`

| File | What It Does |
|---|---|
| **`LearnView.swift`** | Learn hub. Educational content about communication, boundaries, intimacy. |
| **`ConstellationNode.swift`** | Interactive node in learn constellation. Topic with expandable details. |

---

## `Features/Pulse/`

| File | What It Does |
|---|---|
| **`PulseFullView.swift`** | Full pulse mood tracking view. Daily check-ins, graph, tier guide. |
| **`PulseWidget.swift`** | Compact pulse widget. Quick mood entry. |
| **`PulseSheetView.swift`** | Sheet view for pulse interactions. |
| **`PulseGraph.swift`** | Graph visualization of pulse entries over time. |
| **`PulseDotSummary.swift`** | Summary view of mood dots. |
| **`PulseCanvasScrollView.swift`** | Canvas-based scrollable pulse visualization. |
| **`CheckInShell.swift`** | Shell/container for daily check-in flow. |
| **`DailyCheckInView.swift`** | Daily mood check-in interface. Enum `CheckInPhase`-driven stages. |
| **`TierGuideSheet.swift`** | Guide sheet explaining tier levels (1–5 mood scale). |

### `Features/Pulse/Store/`

| File | What It Does | Reach |
|---|---|---|
| **`PulseStore.swift`** | `@Observable`. Owns pulse entries array. Persists to `UserDefaults` (`"pulse.entries.v1"`). | **`HUB`** |

---

## `Features/Settings/`

| File | What It Does |
|---|---|
| **`SettingsView.swift`** | Settings hub. Account, theme, privacy, support links. |
| **`ThemePickerView.swift`** | Theme mode picker (system/light/amoled). |
| **`ThemeTestView.swift`** | Debug view for theme tokens and components. |

---

## `Features/Pairing/`

| File | What It Does | Reach |
|---|---|---|
| **`PairingInviteView.swift`** | Generate and share pairing code with partner. | |
| **`PairingJoinView.swift`** | Join partner via pairing code. | |
| **`PairingSettingsView.swift`** | Pairing settings. View/edit partner, disconnect. | |
| **`Store/PairingStore.swift`** | `@Observable @MainActor`. Enum `PairingLinkState`-driven: idle/generating/waitingForPartner/joining/linked/error. | **`HUB`** |

---

## `Features/Onboarding/Views/` — **[LEGACY — excluded from build]**

> Kept for reference during OB overhaul. See `Phases/` for current implementation.

| File | Screen | Notes |
|---|---|---|
| **`OnboardingFlowView.swift`** | Coordinator | Legacy flow coordinator. |
| **`OnboardingBrandView.swift`** | Screen 0.5 | Animated brand reveal (now `SplashScreenView`). |
| **`OnboardingNameView.swift`** | Screen 1 | Name + pronouns entry. |
| **`OnboardingStatView.swift`** | Screen 0 | Trust trigger statistic with glow. |
| **`OnboardingModeSelectView.swift`** | Screen 2 | Solo vs. couple mode + NM experience level. |
| **`OnboardingContextView.swift`** | Screen 3 | Relationship context picker. |
| **`OnboardingCuriosityPickerView.swift`** | Screen 4 | Two-section interest + intent picker. |
| **`OnboardingCardRevealView.swift`** | Screen 6.5 | Card reveal with tap-to-flip mechanic. |
| **`OnboardingGroundRulesView.swift`** | Screen 7 | Ethical framing + flip cards acknowledgement. |

---

## `Features/Onboarding/Phases/` — **[CURRENT IMPLEMENTATION]**

| File | What It Does |
|---|---|
| **`NamePhase.swift`** | Name + pronouns + gender identity entry. Text fields and pill selectors. |
| **`ModeSelectPhase.swift`** | Solo vs. together mode + NM experience level. Drives flow branching. |
| **`ExperienceLevelPhase.swift`** | NM stage selection (curious/exploring/experienced) with detailed descriptions. |
| **`ContextPhase.swift`** | Relationship context picker. Card stack. Solo: 3 cards. Together: 4 cards. |
| **`CuriosityPhase.swift`** | Two-section interest + intent picker. Pills with gradient checkmarks. |
| **`GenderPhase.swift`** | Gender identity optional entry. Text field with suggestions. |
| **`StatPhase.swift`** | Trust trigger statistic. Animated holographic glow + citation + ethos statement. |
| **`FoilPhase.swift`** | Foil tear mechanic. Card reveal with destructive interaction. `FoilTear` models tear state. |
| **`FounderLetterPhase.swift`** | Founder welcome letter. Onboarding frame-setting. |
| **`BuildingPathPhase.swift`** | Non-interactive "Building your path" processing animation. `OrbitIndicator` shows progress. |
| **`QuizPhase.swift`** | Assessment or knowledge check. (Pending full design.) |

### `Features/Onboarding/Canvas/`

| File | What It Does |
|---|---|
| **`OnboardingCanvasView.swift`** | Canvas-based onboarding render. Orchestrates drawing and phase animations. |
| **`TableSurfaceView.swift`** | Table surface visual. Spatial context for cards and canvas elements. |
| **`VaylDirector.swift`** | `@Observable`. Orchestrates phase transitions, animations, and timing. Brain of canvas onboarding. |

### `Features/Onboarding/Components/`

| File | What It Does |
|---|---|
| **`ContextCard.swift`** | Single card in context stack. Light: frosted ultraThinMaterial. Dark: intensity-keyed gradient. Embeds TileOrbitView. |
| **`ContextCardStack.swift`** | Gesture-driven infinite-scroll card stack. Auto-advances 0.45s after selection. |
| **`ContextIntensity.swift`** | Six intensity levels (ember → nova) mapping gradient, glow, border, shadow. |
| **`ContextOption.swift`** | Data model for one context card. Holds `RelationshipContext`, intensity, title, subtitle, detail. |
| **`CuriosityPill.swift`** | Selectable pill for curiosity picker. Gradient checkmark on selection. Border/background adapt to contentType. |
| **`CuriosityPanelNudge.swift`** | Contextual nudge text guiding user to complete both picker panels. |
| **`CuriosityPreviewLine.swift`** | Italic preview text showing how selection shapes user's path. |
| **`CuriosityStatusStrip.swift`** | Three-dot panel indicator + selection count. Active dot shows HolographicShimmer. |
| **`OnboardingAtmosphere.swift`** | Centralized atmosphere layer. Owns glow fields, spark fields, per-screen config transitions. |
| **`CornerDeckView.swift`** | Corner deck visual element. Layered cards in corner for spatial context. |
| **`CornerMarksView.swift`** | Corner marks/cutouts for design framing. |

### `Features/Onboarding/Models/`

| File | What It Does |
|---|---|
| **`OnboardingData.swift`** | Mutable data bag. Name, pronouns, mode, context, curiosity selections, experience level. Threaded through the full OB flow. |
| **`VaylCardModel.swift`** | `@Observable`. Card reveal interaction state. Flip state, pill selections. |
| **`FoilTear.swift`** | Struct. Models one foil tear. Position, tear progress, animations. |

### `Features/Onboarding/Store/`

| File | What It Does | Reach |
|---|---|---|
| **`OnboardingStore.swift`** | `@Observable @MainActor`. Orchestrates phase transitions, data persistence. Saves `UserProfile` on completion. Derives `AppMode` and `NMStage` from selections. | **`HUB`** |
| **`OnboardingStep.swift`** | Enum. CaseIterable phase markers for step sequencing. | |
| **`CuriosityScreenConfig.swift`** | Config model driving `CuriosityPhase`. Two sections of labels, options, visibility flags. Derived from `OnboardingData`. | |

### `Features/Onboarding/Layout/`

| File | What It Does |
|---|---|
| **`OnboardingLayout.swift`** | Layout constants and utilities. Screen-relative measurements, spacing, animation timings. |

### `Features/Onboarding/Renders/`

| File | What It Does |
|---|---|
| **`ProjectedTextView.swift`** | Perspective text rendering. Text appears to recede into space. |
| **`DealPointView.swift`** | Deal point marker/callout component. Annotates key onboarding moments. |

---

## Dead Code & Maintenance

| Item | File | Action |
|---|---|---|
| **FilamentMode** | `Design/Components/Effects/FilamentMode.swift` | Never referenced. Delete when safe. |
| **Legacy OB Views** | `Features/Onboarding/Views/` (9 files) | Excluded from build. Delete after OB overhaul ships. |
| **DataStore stubs** | `Core/Persistence/DataStore.swift` | RatingRecord/StreakRecord replacements pending. |
