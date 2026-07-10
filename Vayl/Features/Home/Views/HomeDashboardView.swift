//
//  HomeDashboardView.swift
//  Vayl
//
//  The Home screen — a calm, single-screen composition over the five-blob void.
//  Faithful to docs/prototypes/home-final.html ("Final — converged"):
//
//    Header (gradient name + partner pill)
//      → Module 1 · The Deck    — a glass card levitating on a pedestal of light
//      → Module 2 · The Pulse   — a light instrument rail (minimal placeholder;
//                                  the real Pulse work is a separate focused pass)
//      → Module 3 · The Lexicon — centered daily typography (hold-to-keep, share)
//
//  Day-1 keeps the Getting Started entry card between the header and the deck
//  (→ Path overlay, owned by HomeRouterView). The converged home retired the
//  scrolling dashboard, the galaxy-morph background, GravLift, the Ticker, the
//  PickUp card, and the Pulse/Prism/Constellation widget stack.
//

import SwiftUI
import SwiftData

/// Reports `greetingBlock`'s own rendered height up to `HomeDashboardView`,
/// so the partner-chip popover can sit just beneath the header without a
/// hardcoded pixel guess (the chip/header row grows at larger Dynamic Type
/// sizes). Deliberately just a height, measured locally within
/// `greetingBlock`'s own `GeometryReader` — NOT a full frame translated
/// through a named coordinate space across the ScrollView boundary. That
/// cross-container x/y translation (via a `"homeRoot"` coordinate space) was
/// the earlier approach and it was fragile in practice (two fix attempts,
/// still wrong on-device) for exactly the reason `docs/prototypes/
/// partner-chip-and-pairing.html` never bothers with it either: the popover
/// reads as "a card that opens under the header," not something that must
/// track the chip's exact rendered pixel — a simple static top-offset (this
/// height + a fixed gap) plus trailing-edge alignment is enough, and SwiftUI's
/// own `alignment: .topTrailing` + `.padding(.trailing:)` handles the x-axis
/// robustly without any screen-width arithmetic to get wrong.
private struct GreetingHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeDashboardView: View {

    // MARK: - Injected Properties

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var cards: [Card] = []
    /// The active deck's title, for the small header above the card. Empty hides the header.
    var deckTitle: String = ""
    var desireMapState: DesireMapState = .hidden
    /// The partner's current Pulse position, for the chip's expand quick-view tile
    /// only (current position, not history — nil renders the confirmed-empty copy).
    var partnerPulsePosition: PulsePosition?
    /// True when the last partner-pulse fetch failed — the tile shows an honest
    /// "couldn't check" instead of reading the failure as confirmed-empty.
    var partnerPulseFetchFailed: Bool = false
    var reflectionCardState: ReflectionCardState = .hidden
    var pickUpItems: [PickUpItem] = []
    var stageIndex: Int = 1
    var cardsCompleted: Int = 0
    var daysSinceLastSession: Int?
    var recentEvents: [HomeEvent] = []
    var isSolo: Bool = false
    var showReflectionBanner: Bool = false
    /// Server-overridden Lexicon content from HomeStore (nil → bundled baseline).
    var lexiconRemotePool: LexiconRemotePool?

    // MARK: - Getting Started Activation
    // Optional namespace so the existing #Previews still compile (Namespace.ID has no public
    // initializer); the real call site (HomeRouterView) always supplies it.
    var gettingStarted: GettingStarted = GettingStarted.resolve(
        myMapComplete: false, isPaired: false, partnerMapComplete: false, revealDone: false
    )
    var pathNamespace: Namespace.ID?
    var pathOpen: Bool = false
    var onOpenPath: (() -> Void)?

    // MARK: - Callbacks

    var onRemindPartner: (() -> Void)?
    var onCardAction: ((Card, CardAction) -> Void)?
    var onDesireMapReveal: (() -> Void)?
    var onDesireMapUnlock: (() -> Void)?
    var onReflectionDone: (([String], String?, Bool) -> Void)?
    var onReflectionBannerDismiss: (() -> Void)?
    var onMoreTap: (() -> Void)?
    var onPickUpItemTap: ((PickUpItem) -> Void)?
    var onInvitePartner: (() -> Void)?
    var onPartnerTap: (() -> Void)?
    var onNavigateToPlay: (() -> Void)?
    /// Fired when a session cover presented from Home dismisses — the router
    /// refreshes HomeStore's deck state so the hero reflects tonight's play
    /// without needing a tab switch.
    var onSessionEnded: (() -> Void)?
    /// The Lexicon CTA route (→ Learn).
    var onOpenLexicon: (() -> Void)?
    /// The Pulse rail tap (→ Map / Pulse history). Minimal for now.
    var onPulseTap: (() -> Void)?
    /// The Pulse "Check in" affordance. Final form: presents the shared check-in
    /// sheet in place over Home (Bryan's PulseWidget pass). Interim: routes to the
    /// Pulse surface so it is never dead.
    var onCheckIn: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    // MARK: - State

    @State private var greetingVisible = false
    @State private var heroVisible     = false
    @State private var pulseVisible    = false
    @State private var lexVisible      = false

    /// Whether the partner chip's quick-view popover (`PartnerChipExpand`) is
    /// open. Only meaningful for `.active` — the chip's tap handler only
    /// toggles this in that state; other states keep routing through
    /// `onPartnerTap` as before.
    @State private var isChipExpanded = false

    /// `greetingBlock`'s own rendered height, measured via `GreetingHeightKey`
    /// (the row grows taller than the eyeballed default at larger Dynamic Type
    /// sizes). Used only to place the popover's static top offset just below
    /// the header — see `GreetingHeightKey`'s doc comment for why this
    /// replaced the earlier cross-container chip-frame tracking.
    @State private var greetingHeight: CGFloat = 0

    /// The deck's phase (floating → spread → lifted → carousel), reported by
    /// CardCarousel. The room recedes once the deck is engaged.
    @State private var deckPhase: CarouselPhase = .floating

    /// Tonight's hand (card ids, in add order), built by tapping cards in the carousel.
    @State private var handIDs: [String] = []

    /// Bumped to reset the carousel back to floating after "Settle in".
    @State private var deckReset = 0

    /// Presents the Pulse check-in in place over Home (no tab-yank). The shared
    /// PulseStore the cover writes to is the same instance the rail reads.
    @State private var showPulseCheckIn = false
    @Environment(PulseStore.self) private var pulseStore

    /// Presents the two-knob session-settings sheet from the chest cog.
    @State private var showSessionSettingsSheet = false

    /// Tonight's hand, set when the carousel hands off via `onStartHand`. Non-nil
    /// drives the protected session cover. DEBUG-only couch mode (spec rule 26):
    /// release "Settle in" routes to Play instead.
    @State private var sessionHand: [Card]?

    /// Joiner entry: "‹name› set up a session" banner + join cover.
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(CoupleContext.self) private var coupleContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var entryStore: SessionEntryStore?
    @State private var joinerLaunch: SessionLaunch?

    #if DEBUG
    @State private var showDebugGrid = false
    #endif

    // MARK: - Derived

    /// When a desire-map nudge is live, it takes the bottom module slot in place
    /// of the Lexicon (conversion beat outranks the daily word).
    private var showDesireNudge: Bool {
        gettingStarted.isComplete
            && desireMapState != .hidden
            && desireMapState != .fullyUnlocked
    }

    /// The room recedes once the deck is taken past its floating/spread states
    /// (matches CardCarousel's own screen dim).
    private var deckEngaged: Bool {
        deckPhase != .floating && deckPhase != .spread
    }

    /// Half of CardCarousel's own card width (private `cardW = 300` there) — used
    /// to anchor the cog/corner-deck chrome to the card's real edges rather than
    /// an arbitrary screen inset. Keep in sync if CardCarousel's cardW changes.
    private let cardHalfWidth: CGFloat = 150

    // MARK: - Body

    var body: some View {
        @Bindable var appState = appState
        return GeometryReader { geo in
            let layout = AppLayout.from(geo)
            // The hero owns the first screen; the collapsed Pulse and the Lexicon share the
            // rest. All three are a plain stack the ScrollView lays out — the layout engine
            // sizes them, we don't.
            let heroIsolation = layout.screenHeight * 0.12
            // The ScrollView's viewport height. This GeometryReader is laid out INSIDE the
            // safe area (AppShell's tab-bar `.safeAreaInset` + the island), so `geo.size.height`
            // is ALREADY the visible height between the island and the tab bar — the ScrollView
            // fills exactly this. `geo.safeAreaInsets` still REPORTS the insets (62/114) as
            // leftover metadata, but they've already been removed from `size.height`; subtracting
            // them again shrank the fill target ~176pt below the real viewport, which is what
            // floated the Lexicon above a fixed dead gap. The viewport IS screenHeight.
            let safeContentH = layout.screenHeight
            // Drops the pedestal light-strip to the hero card's lower edge so the deck
            // reads as levitating on a beam of light. The card is 190pt tall with an
            // 8pt top pad inside CardCarousel; the strip sits at its center, so ~155
            // lands it on that bottom edge. Effect-surface alignment (not an AppSpacing
            // candidate), tunable on device.
            let pedestalDropY: CGFloat = 191

            ZStack(alignment: .top) {
                // Named coordinate space so PartnerChip's frame (reported from
                // deep inside greetingBlock → the ScrollView content) can be
                // translated into a frame that's meaningful HERE, at the outer
                // ZStack's own level — needed because PartnerChipExpand now
                // renders as a sibling in this same outer ZStack instead of
                // nested locally next to the chip.
                // Same atmosphere as the OB canvas — keep the app's background
                // language consistent (void floor + tri-colour bloom).
                OnboardingAtmosphere(config: .stat)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        greetingBlock
                            .opacity(greetingVisible ? (deckEngaged ? 0.25 : 1) : 0)
                            .blur(radius: deckEngaged ? 6 : 0)
                            .offset(y: greetingVisible ? 0 : 10)
                            .animation(AppAnimation.slow, value: greetingVisible)
                            .animation(AppAnimation.enter, value: deckEngaged)

                        if !gettingStarted.isComplete, let ns = pathNamespace {
                            GettingStartedEntryCard(
                                gettingStarted: gettingStarted,
                                namespace: ns,
                                isHidden: pathOpen,
                                onTap: { onOpenPath?() }
                            )
                            .padding(.top, AppSpacing.md)
                            // Recede with the rest of Home when the deck engages (matches greetingBlock).
                            .opacity(greetingVisible ? (deckEngaged ? 0.25 : 1) : 0)
                            .blur(radius: deckEngaged ? 6 : 0)
                            .animation(AppAnimation.enter, value: deckEngaged)
                        }

                        // Top void — the hero's approach.
                        Color.clear.frame(height: layout.screenHeight * 0.04)

                        // Deck header — appears only once the user has clicked into the
                        // chest (deckEngaged); the floating card stays unlabeled. Plain
                        // text, not LivingText: a functional label reading the deck you're
                        // browsing shouldn't compete with the card for attention —
                        // LivingText is reserved for hero moments like the greeting name.
                        if !deckTitle.isEmpty && deckEngaged {
                            VStack(spacing: AppSpacing.xxs) {
                                Text(deckTitle)
                                    .font(AppFonts.sectionHeading)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("\(cardsCompleted) / \(cards.count) explored")
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            .transition(.opacity)
                            .animation(AppAnimation.enter, value: deckEngaged)
                            .padding(.bottom, AppSpacing.sm)
                        }

                        // The deck — CardCarousel elevates IN PLACE (no cover): tap
                        // the floating card and the deck spreads → lifts → carousel,
                        // dimming the screen with its own backdrop. Tapping a card
                        // adds it to tonight's hand.
                        CardCarousel(
                            cards: cards,
                            onNavigateToPlay: onNavigateToPlay,
                            onPhaseChange: { phase in
                                deckPhase = phase
                                // Mirror engagement to the shell so the tab bar recedes too.
                                appState.deckEngaged = (phase != .floating && phase != .spread)
                                // Dismiss / clicked-out → start tonight's hand over.
                                // Idempotent: settleIn() already clears + bumps
                                // deckReset (which re-fires .floating), and first
                                // appear fires .floating with the hand already empty.
                                if phase == .floating { handIDs = [] }
                            },
                            selecting: true,
                            selectedIDs: Set(handIDs),
                            onToggleSelect: { toggleHand($0) },
                            dimOpacity: 0.15
                        )
                        // The pedestal of light — a spectrum strip at the card's lower
                        // edge so the deck reads as levitating. Drawn as an OVERLAY (in
                        // front): the card body is opaque, so a background strip would be
                        // occluded by the card's lower edge. Strip only (CardCarousel
                        // already supplies the bloom); fades out once the deck is engaged.
                        .overlay(alignment: .top) {
                            DeckPedestal(showBloom: false)
                                .offset(y: pedestalDropY)
                                .opacity(deckEngaged ? 0 : 1)
                                .animation(AppAnimation.enter, value: deckEngaged)
                        }
                        .id(deckReset)
                        .opacity(heroVisible ? 1 : 0)
                        .animation(AppAnimation.spring, value: heroVisible)
                        .zIndex(10)
                        // When the chest opens, settle the card toward vertical center so it
                        // uses the lower space instead of staying crammed up top under the
                        // SETUP / TONIGHT chrome. Proportional geometry, like the top-void and
                        // heroIsolation above. Feel value: tune the fraction on device.
                        .offset(y: deckEngaged ? layout.screenHeight * 0.12 : 0)
                        .animation(AppAnimation.enter, value: deckEngaged)

                        // Flexible hero-isolation void: the deck floats up top while the Pulse
                        // + Lexicon settle at the bottom (it fills the collapsed screen's slack).
                        // Collapses to its minimum when the graph expands and the view scrolls.
                        Spacer(minLength: heroIsolation)

                        // The Pulse — a secondary, ambient-hero signal. Tapping it opens
                        // the full Pulse on the Map; the pill (re-)runs a check-in.
                        pulseModule(
                            // The column's real inner width. An ENFORCED ceiling (not
                            // an exact width) so the long title scales-to-fit instead
                            // of reporting its unscaled ideal and blowing the card past
                            // the column (vertical ScrollViews let content overflow the
                            // viewport, pinning leading → off the right edge).
                            columnWidth: layout.screenWidth - AppSpacing.lg * 2
                        )

                        // Breathing gap between the Pulse and the Lexicon.
                        Color.clear.frame(height: layout.screenHeight * 0.06)

                        lexiconModule
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    // The header sits just below the system chrome. The ScrollView already
                    // insets its content for the safe area, so we add only a small breathing
                    // pad here — NOT topClearance, which would double the Dynamic Island inset.
                    .padding(.top, AppSpacing.md)
                    // Fill at least the visible area so the collapsed composition anchors the
                    // Lexicon at the bottom (the flexible hero void takes the slack). When the
                    // graph expands past one screen the content grows and the ScrollView scrolls.
                    .frame(maxWidth: .infinity, minHeight: safeContentH, alignment: .top)
                }
                .scrollIndicators(.hidden)

                // Outside-tap dismiss for the partner-chip popover. A full-screen,
                // invisible tap-catcher: sits ABOVE the ScrollView content (so a tap
                // doesn't fall through to a deck card underneath) but BELOW
                // `PartnerChipExpand` (rendered further below, in this SAME outer
                // ZStack, at zIndex 2) so the popover's own tiles/buttons stay
                // tappable while the catcher still eats every other tap on screen.
                // zIndex only orders siblings within one container — this and the
                // popover must live in the same ZStack for the ordering to mean
                // anything, which is why the popover was moved out of the small
                // local ZStack inside greetingBlock. Only mounted while the
                // popover is open, so it never intercepts normal Home interaction
                // at rest.
                if isChipExpanded {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(AppAnimation.standard) { isChipExpanded = false }
                        }
                        .ignoresSafeArea()
                        .zIndex(1)
                }

                // The partner-chip quick-view popover — rendered here, as a sibling
                // of the dismiss tap-catcher above, in the OUTER root ZStack (NOT
                // nested inside greetingBlock's local ZStack) so their relative
                // zIndex genuinely determines paint/hit-test order.
                //
                // Positioned with a static top offset (header top padding +
                // greetingBlock's measured height + a breathing gap) and
                // trailing-edge alignment — matching docs/prototypes/
                // partner-chip-and-pairing.html, which anchors the expand card
                // with a plain `top / right` offset from the screen, not a
                // measured chip position. The earlier approach translated the
                // chip's exact frame through a `"homeRoot"` named coordinate
                // space across the ScrollView boundary and needed screen-width
                // arithmetic to convert it back into an offset — fragile in
                // practice, wrong on-device twice. `alignment: .topTrailing`
                // plus `.padding(.trailing:)` lets SwiftUI handle the x-axis
                // directly; only the header's height needs measuring at all.
                if isChipExpanded, case .active = partnerChipState {
                    PartnerChipExpand(
                        state: partnerChipState,
                        desireMapState: desireMapState,
                        partnerPulsePosition: partnerPulsePosition,
                        partnerPulseFetchFailed: partnerPulseFetchFailed,
                        onDesireMapTap: {
                            isChipExpanded = false
                            onPartnerTap?() // existing Map-tab routing
                        },
                        onPulseTap: {
                            isChipExpanded = false
                            onPartnerTap?() // existing Map-tab routing
                        },
                        onManageTap: {
                            isChipExpanded = false
                            onPartnerTap?() // existing routing — a later task points this at Settings
                        }
                    )
                    .frame(
                        maxWidth: .infinity, maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                    .padding(.top, AppSpacing.md + greetingHeight + AppSpacing.xs)
                    .padding(.trailing, AppSpacing.lg)
                    // Fade + a small downward nudge — no scale. Scaling the
                    // whole card up from a fraction of its size read as the
                    // small capsule-shaped pill above it warping/stretching
                    // into a much larger rectangular card (felt in an
                    // interactive HTML reference before landing here, per
                    // the feel-first build protocol).
                    .transition(.opacity.combined(with: .offset(y: -AppSpacing.xs)))
                    .zIndex(2)
                }

                // "Settle in" rides above the carousel's screen dim once a card is in
                // tonight's hand, and carries the hand into the session.
                if deckPhase == .carousel {
                    deckChrome(layout: layout)
                        .zIndex(100)
                }

                reflectionBanner

                pendingSessionBanner

                joinErrorBanner

                #if DEBUG
                debugOverlay(layout: layout)
                #endif
            }
            // Pin the screen ZStack to the true screen width. A child (deck backdrop /
            // atmosphere) was inflating it past the screen, anchoring at the leading
            // edge and pushing the centered content column ~13pt right (off the right
            // edge). Clamping here re-centers every module on the physical screen.
            .frame(width: layout.screenWidth, alignment: .center)
            .onPreferenceChange(GreetingHeightKey.self) { greetingHeight = $0 }
            .onAppear { runEntranceAnimations() }
            .blur(radius: pathOpen ? 9 : 0)
            .animation(AppAnimation.spring, value: pathOpen)
            .vaylCover(
                isPresented: Binding(
                    get: { sessionHand != nil },
                    set: { if !$0 { sessionHand = nil } }
                )
            ) {
                // DEBUG-only couch mode: sessionHand is only ever set in DEBUG
                // builds (see settleIn()).
                CardSessionContainerView(launch: SessionLaunch(
                    hand: sessionHand ?? [], entry: .localDebug, role: .a, session: nil
                ))
            }
            // Joiner path: partner opened a lobby → banner → this cover.
            .vaylCover(isPresented: Binding(
                get: { joinerLaunch != nil },
                set: { if !$0 { joinerLaunch = nil; onSessionEnded?() } }
            )) {
                if let launch = joinerLaunch {
                    CardSessionContainerView(launch: launch)
                        .id(launch.id)
                }
            }
            .onAppear {
                if entryStore == nil {
                    entryStore = SessionEntryStore(
                        modelContainer: modelContext.container,
                        appState: appState,
                        // Live read of the couple-fact source of truth (the old
                        // closure captured the chip BY VALUE at store creation,
                        // so a later-arriving partner name never reached it).
                        partnerName: { [couple = coupleContext] in couple.partnerName }
                    )
                }
                entryStore?.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    entryStore?.refresh()
                    onSessionEnded?()   // re-read deck state on foreground too
                }
            }
            .onChange(of: entryStore?.acceptedLaunch) { _, launch in
                if let launch { joinerLaunch = launch; entryStore?.acceptedLaunch = nil }
            }
            // Pulse check-in — full-screen cover so PulseField gets real screen-derived
            // geometry instead of a sheet's measured-content sizing (the bug that made it
            // not land reliably). Not confirm-on-exit: a check-in is quick and low-stakes,
            // not a protected two-device session.
            .vaylCover(isPresented: $showPulseCheckIn, confirmOnExit: false) {
                PulseCheckInView(store: pulseStore, onClose: { showPulseCheckIn = false })
            }
            // The Vayl sheet (custom OB chrome). Pass the real screen height so the
            // half fraction is reliable — the overlay's own geometry here measures the
            // tall scroll runway, which would resolve the fraction too large.
            .vaylSheet(
                isPresented: $showSessionSettingsSheet,
                heightFraction: 0.5,
                screenHeight: layout.screenHeight
            ) {
                SessionSettingsSheet(
                    reader: $appState.sessionSettings.reader,
                    length: $appState.sessionSettings.length,
                    partnerName: coupleContext.partnerName ?? "Partner"
                ) {
                    showSessionSettingsSheet = false
                }
            }
        }
    }

    // MARK: - Pulse (the secondary hero — tap the rail to expand the graph)

    private func pulseModule(columnWidth: CGFloat) -> some View {
        HomePulseRail(
            onTap: { onPulseTap?() },
            onCheckIn: { showPulseCheckIn = true }
        )
        // Cap at the column's inner width so the long title scales-to-fit rather than
        // forcing the card wider than the viewport (which a vertical ScrollView would
        // then pin leading, running the right edge off-screen). maxWidth = ceiling, so
        // it can only shrink to fit — never an exact width that could itself overflow.
        .frame(maxWidth: columnWidth, alignment: .center)
        .opacity(pulseVisible ? 1 : 0)
        .animation(AppAnimation.slow, value: pulseVisible)
        .blur(radius: deckEngaged ? 6 : 0)
        .opacity(deckEngaged ? 0.25 : 1)
        .allowsHitTesting(!deckEngaged)
        .animation(AppAnimation.enter, value: deckEngaged)
    }

    // MARK: - Lexicon (the type layer, pushed down as the graph expands)

    private var lexiconModule: some View {
        VStack(spacing: 0) {
            // DesireMapIndicator retired from the dashboard: the waiting state now lives in the
            // partner pill, completion is the one-shot moment, and the reveal entry is the Getting
            // Started step. (The indicator is kept on disk for the M5 unlock surface.)
            HomeLexicon(remotePool: lexiconRemotePool, onOpen: onOpenLexicon)
        }
        .opacity(lexVisible ? 1 : 0)
        .animation(AppAnimation.slow, value: lexVisible)
        .blur(radius: deckEngaged ? 6 : 0)
        .opacity(deckEngaged ? 0.25 : 1)
        .allowsHitTesting(!deckEngaged)
        .animation(AppAnimation.enter, value: deckEngaged)
    }

    /// You finished your map; your partner has not. Drives the partner-pill waiting indicator.
    private var isWaitingOnPartner: Bool {
        if case .youDone = desireMapState { return true }
        return false
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        HStack(alignment: .center) {
            // Home leads with the brand wordmark; the personal name now lives on the
            // Map tab (Me / Us). Consistent treatment: gradient wordmark + period.
            LivingText(
                text: "VAYL.",
                font: AppFonts.tabMasthead,
                animated: false
            )
            Spacer()
            PartnerChip(
                state: partnerChipState,
                waiting: isWaitingOnPartner,
                onInviteTap: onInvitePartner,
                onPartnerTap: {
                    switch partnerChipState {
                    case .active:
                        withAnimation(AppAnimation.standard) { isChipExpanded.toggle() }
                    default:
                        // .invitePending / .nudge / .none route through the existing
                        // onPartnerTap wiring today (Map tab). A later task replaces
                        // this with the real pairing sheet — not this task's concern.
                        onPartnerTap?()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Reports this row's own rendered height (a plain local measurement,
        // no named coordinate space) so the popover in `body` can sit its
        // static top offset just below the header. See `GreetingHeightKey`'s
        // doc comment for why this replaced tracking the chip's cross-
        // container frame.
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: GreetingHeightKey.self, value: geo.size.height)
            }
        )
    }

    // MARK: - Reflection Banner

    @ViewBuilder
    private var reflectionBanner: some View {
        if showReflectionBanner {
            VStack {
                ReflectionBannerView(
                    sessionLabel: bannerSessionLabel,
                    partnerName: bannerPartnerName,
                    onDone: onReflectionDone,
                    onDismiss: onReflectionBannerDismiss
                )
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                )
            )
            .animation(AppAnimation.spring, value: showReflectionBanner)
        }
    }

    // MARK: - Pending Session Banner (joiner entry)

    @ViewBuilder
    private var pendingSessionBanner: some View {
        if let pending = entryStore?.pendingSession {
            VStack {
                Group {
                    if pending.kind == .resume {
                        ResumeSessionBanner(
                            deckTitle: pending.deckTitle,
                            cardPosition: pending.cardPosition,
                            cardCount: pending.cardCount,
                            onResume: { entryStore?.resume() },
                            onEnd: { entryStore?.endResumable() }
                        )
                    } else {
                        PendingSessionBanner(
                            initiatorName: pending.initiatorName,
                            deckTitle: pending.deckTitle,
                            onJoin: { entryStore?.accept() },
                            onDismiss: { entryStore?.dismissBanner() }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(AppAnimation.spring, value: entryStore?.pendingSession)
            .zIndex(2)
        }
    }

    // MARK: - Join/resume error banner (spec 2026-07-09 §1.8: fail loud, never silent)

    @ViewBuilder
    private var joinErrorBanner: some View {
        if let joinError = entryStore?.joinError {
            VStack {
                Spacer()
                SessionErrorBanner(message: joinError) { entryStore?.clearJoinError() }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
            .transition(.opacity)
            .animation(AppAnimation.standard, value: entryStore?.joinError)
            .zIndex(3)
        }
    }

    // MARK: - Phase / Entrance

    // MARK: - Deck (hand + settle in)

    private var settleInBar: some View {
        VaylButton(label: "Settle in  ·  \(handIDs.count)  →", isDisabled: false) {
            settleIn()
        }
    }

    private func toggleHand(_ card: Card) {
        withAnimation(AppAnimation.spring) {
            if let idx = handIDs.firstIndex(of: card.id) {
                handIDs.remove(at: idx)
            } else {
                handIDs.append(card.id)
            }
        }
    }

    private func settleIn() {
        let hand = handIDs.compactMap { id in cards.first { $0.id == id } }
        guard !hand.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Single-device couch mode survives only behind DEBUG (spec rule 26);
        // release routes to Play, where the real two-device flow begins.
        #if DEBUG
        sessionHand = hand
        #else
        onNavigateToPlay?()
        #endif
        handIDs = []
        deckReset += 1   // reset the carousel back to floating behind the session
    }

    /// The deck's chrome over the open carousel: the "tonight" corner deck (always
    /// present while open) and the "Settle in" bar (once a card is in hand).
    @ViewBuilder
    private func deckChrome(layout: AppLayout) -> some View {
        ZStack {
            // Corner "tonight" deck — positioned EXPLICITLY in the top-right corner.
            // (A Spacer/padding chain was rendering it off-screen.)
            // Corner "tonight" deck + label, anchored above the card's own RIGHT edge
            // (not a fixed screen inset) — CardCarousel's card is 300pt wide, centered.
            // Anchoring to the card's real footprint (not the screen edge) is what
            // makes these read as the card's own controls instead of floating loose.
            VStack(spacing: AppSpacing.xs) {
                cornerDeck
                Text("Tonight")
                    .font(AppFonts.label)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .position(
                x: layout.screenWidth / 2 + cardHalfWidth,
                y: layout.safeAreaInsets.top + 34
            )

            // Settings cog + label — anchored above the card's own LEFT edge, opposite
            // the corner deck. Opens the two-knob session-settings sheet.
            VStack(spacing: AppSpacing.xs) {
                settingsCog
                Text("Setup")
                    .font(AppFonts.label)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .position(
                x: layout.screenWidth / 2 - cardHalfWidth,
                y: layout.safeAreaInsets.top + 34
            )

            if !handIDs.isEmpty {
                VStack {
                    Spacer()
                    settleInBar
                        .padding(.horizontal, AppSpacing.lg)
                        // Tab content adds NO hardware/bar clearance — AppShell's
                        // .safeAreaInset reserves the bar + home indicator.
                        .padding(.bottom, AppSpacing.xl)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .animation(AppAnimation.spring, value: handIDs.isEmpty)
    }

    /// Tonight's hand, as a small corner pile — an empty ghost card while the hand
    /// is empty, filling (with a count) as cards are added.
    private var cornerDeck: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(0..<max(1, min(handIDs.count, 3)), id: \.self) { k in
                RoundedRectangle(cornerRadius: AppRadius.cornerCard, style: .continuous)
                    .fill(AppColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.cornerCard)
                            .strokeBorder(
                                AppColors.spectrumBorder.opacity(handIDs.isEmpty ? 0.22 : 0.5),
                                lineWidth: 0.7
                            )
                    )
                    .frame(width: 42, height: 30)
                    .rotationEffect(.degrees(Double(k - 1) * 6))
            }
        }
        // Fixed bound so the explicit .position in deckChrome centers it cleanly;
        // the count badge is an overlay INSIDE these bounds (no off-screen overflow).
        .frame(width: 56, height: 40)
        .overlay(alignment: .topTrailing) {
            if !handIDs.isEmpty {
                Text("\(handIDs.count)")
                    .font(AppFonts.display(11, weight: .bold, relativeTo: .caption2))
                    .foregroundStyle(AppColors.void)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(AppColors.accentPrimary))
                    .offset(y: -2)
            }
        }
        .animation(AppAnimation.spring, value: handIDs.count)
    }

    /// Chest settings cog — opens the two-knob session-settings sheet.
    private var settingsCog: some View {
        SettingsCogButton { showSessionSettingsSheet = true }
    }

    private func runEntranceAnimations() {
        withAnimation(AppAnimation.slow.delay(0.10)) { greetingVisible = true }
        withAnimation(AppAnimation.spring.delay(0.30)) { heroVisible     = true }
        withAnimation(AppAnimation.slow.delay(0.62)) { pulseVisible    = true }
        withAnimation(AppAnimation.slow.delay(0.78)) { lexVisible      = true }
    }

    // MARK: - Computed

    private var bannerSessionLabel: String {
        if case .pendingYours(let label, _) = reflectionCardState { return label }
        return "Last session"
    }

    private var bannerPartnerName: String? {
        if case .active(let name, _) = partnerChipState { return name }
        return nil
    }

    // MARK: - Debug

    #if DEBUG
    @ViewBuilder
    private func debugOverlay(layout: AppLayout) -> some View {
        if showDebugGrid {
            DebugGridOverlay()
        }

        VStack {
            Spacer()
            HStack {
                Button { showDebugGrid.toggle() } label: {
                    Image(systemName: showDebugGrid ? "grid.circle.fill" : "grid.circle")
                        .font(AppFonts.body(22, weight: .regular, relativeTo: .title3))
                        .foregroundStyle(showDebugGrid ? Color.cyan : Color.white.opacity(0.4))
                        .padding(AppSpacing.sm)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.leading, AppSpacing.md)
                .bottomContentInset(layout)

                Spacer()
            }
        }
    }
    #endif
}

// MARK: - Settings Cog Button

/// Small circular glass button for the chest's top-leading corner. Opens the
/// two-knob session-settings sheet. Owns its own press state (tap contract).
private struct SettingsCogButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: AppIcons.gearOutline)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.spectrumText)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(AppColors.glassSurface)
                )
                .overlay(
                    Circle().strokeBorder(AppColors.borderDefault, lineWidth: 0.7)
                )
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("Settings")
    }
}

// MARK: - Debug Grid Overlay

#if DEBUG
private struct DebugGridOverlay: View {
    private let unit: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let width  = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .topLeading) {
                gridLines(width: width, height: height)
                marginGuides(width: width)
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        ForEach(0..<Int(height / unit), id: \.self) { i in
            let y: CGFloat   = CGFloat(i) * unit
            let isMajor: Bool = i % 8 == 0
            Rectangle()
                .fill(Color.cyan.opacity(isMajor ? 0.18 : 0.06))
                .frame(height: 1)
                .offset(y: y)
        }
        ForEach(0..<Int(width / unit), id: \.self) { i in
            let x: CGFloat   = CGFloat(i) * unit
            let isMajor: Bool = i % 8 == 0
            Rectangle()
                .fill(Color.cyan.opacity(isMajor ? 0.18 : 0.06))
                .frame(width: 1)
                .offset(x: x)
        }
    }

    @ViewBuilder
    private func marginGuides(width: CGFloat) -> some View {
        Rectangle()
            .fill(Color(red: 1, green: 0, blue: 1).opacity(0.55))
            .frame(width: 1)
            .offset(x: width / 2)
        Rectangle()
            .fill(Color.yellow.opacity(0.45))
            .frame(width: 1)
            .offset(x: 24)
        Rectangle()
            .fill(Color.yellow.opacity(0.45))
            .frame(width: 1)
            .offset(x: width - 24)
    }
}
#endif

// MARK: - Equatable Helpers

extension ReflectionCardState: Equatable {
    static func == (lhs: ReflectionCardState, rhs: ReflectionCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): return true
        default:                 return false
        }
    }
}

// MARK: - Previews
// Routing verification: seeded with real opener cards (proper VaylCardFace) + the
// AppState + model container the .vaylCover's CardSessionContainerView needs, so
// the whole route is tappable in the canvas.
#Preview("Dark — Deck → Session routing") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .none,
        cards: Card.openerSamples, desireMapState: .hidden,
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 3, recentEvents: [], isSolo: false
    )
    .environment(PulseStore())
    .environment({ let state = AppState(); state.coupleId = UUID(); return state }())
    .environment({
        let state = AppState()
        return CoupleContext(
            appState: state,
            entitlements: EntitlementStore(modelContainer: .previewContainer, appState: state),
            modelContainer: .previewContainer
        )
    }())
    .modelContainer(.previewContainer)
    .preferredColorScheme(.dark)
}
