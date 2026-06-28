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

struct HomeDashboardView: View {

    // MARK: - Injected Properties

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var cards: [Card] = []
    var desireMapState: DesireMapState = .hidden
    var reflectionCardState: ReflectionCardState = .hidden
    var pickUpItems: [PickUpItem] = []
    var stageIndex: Int = 1
    var cardsCompleted: Int = 0
    var daysSinceLastSession: Int? = nil
    var recentEvents: [HomeEvent] = []
    var isSolo: Bool = false
    var showReflectionBanner: Bool = false

    // MARK: - Getting Started Activation
    // Optional namespace so the existing #Previews still compile (Namespace.ID has no public
    // initializer); the real call site (HomeRouterView) always supplies it.
    var gettingStarted: GettingStarted = GettingStarted.resolve(
        myMapComplete: false, isPaired: false, partnerMapComplete: false, revealDone: false
    )
    var pathNamespace: Namespace.ID? = nil
    var pathOpen: Bool = false
    var onOpenPath: (() -> Void)? = nil

    // MARK: - Callbacks

    var onRemindPartner: (() -> Void)? = nil
    var onCardAction: ((Card, CardAction) -> Void)? = nil
    var onDesireMapReveal: (() -> Void)? = nil
    var onDesireMapUnlock: (() -> Void)? = nil
    var onReflectionDone: (([String], String?, Bool) -> Void)? = nil
    var onReflectionBannerDismiss: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onPickUpItemTap: ((PickUpItem) -> Void)? = nil
    var onInvitePartner: (() -> Void)? = nil
    var onPartnerTap: (() -> Void)? = nil
    var onNavigateToPlay: (() -> Void)? = nil
    /// The Lexicon CTA route (→ Learn).
    var onOpenLexicon: (() -> Void)? = nil
    /// The Pulse rail tap (→ Map / Pulse history). Minimal for now.
    var onPulseTap: (() -> Void)? = nil
    /// The Pulse "Check in" affordance. Final form: presents the shared check-in
    /// sheet in place over Home (Bryan's PulseWidget pass). Interim: routes to the
    /// Pulse surface so it is never dead.
    var onCheckIn: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    // MARK: - State

    @State private var greetingVisible = false
    @State private var heroVisible     = false
    @State private var pulseVisible    = false
    @State private var lexVisible      = false

    /// The deck's phase (floating → spread → lifted → carousel), reported by
    /// CardCarousel. The room recedes once the deck is engaged.
    @State private var deckPhase: CarouselPhase = .floating

    /// Tonight's hand (card ids, in add order), built by tapping cards in the carousel.
    @State private var handIDs: [String] = []

    /// Bumped to reset the carousel back to floating after "Settle in".
    @State private var deckReset = 0

    /// Whether the Pulse graph is expanded. Tap the rail to toggle; the column reflows and
    /// the ScrollView scrolls if it overflows — no scroll-linked sizing, no fit math.
    @State private var pulseExpanded = false

    /// Presents the Pulse QRG. Owned here (not in HomePulseRail) so the sheet
    /// covers the whole screen rather than the nested rail's bounds.
    @State private var showPulseInfo = false

    /// Presents the Pulse check-in in place over Home (no tab-yank). The shared
    /// PulseStore the cover writes to is the same instance the rail reads.
    @State private var showPulseCheckIn = false
    @Environment(PulseStore.self) private var pulseStore

    /// Tonight's hand, set when the carousel hands off via `onStartHand`. Non-nil
    /// drives the protected session cover.
    @State private var sessionHand: [Card]? = nil

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

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
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
            // Tap-to-expand: the Pulse graph is a DISCRETE state, not a scroll-linked size.
            // `expansion` is 0 or 1 (animated on tap). Expanding reflows the column and the
            // ScrollView scrolls if it overflows. No fit constants, no snap, no minHeight
            // floor — the engine owns the sizing, so it adapts to every screen for free.
            let maxGraphHeight = layout.screenHeight * 0.38   // graph height when expanded
            let expansion = pulseExpanded ? 1.0 : 0.0
            // Drops the pedestal light-strip to the hero card's lower edge so the deck
            // reads as levitating on a beam of light. The card is 190pt tall with an
            // 8pt top pad inside CardCarousel; the strip sits at its center, so ~155
            // lands it on that bottom edge. Effect-surface alignment (not an AppSpacing
            // candidate), tunable on device.
            let pedestalDropY: CGFloat = 191

            ZStack(alignment: .top) {
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
                            .opacity(greetingVisible ? 1 : 0)
                        }

                        // Top void — the hero's approach.
                        Color.clear.frame(height: layout.screenHeight * 0.04)

                        // The deck — CardCarousel elevates IN PLACE (no cover): tap
                        // the floating card and the deck spreads → lifts → carousel,
                        // dimming the screen with its own backdrop. Tapping a card
                        // adds it to tonight's hand.
                        CardCarousel(
                            cards: cards,
                            onNavigateToPlay: onNavigateToPlay,
                            onPhaseChange: { phase in
                                deckPhase = phase
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

                        // Flexible hero-isolation void: the deck floats up top while the Pulse
                        // + Lexicon settle at the bottom (it fills the collapsed screen's slack).
                        // Collapses to its minimum when the graph expands and the view scrolls.
                        Spacer(minLength: heroIsolation)

                        // The Pulse — a secondary hero. Collapsed it shows just its
                        // tier-coloured header + the "+"; tap the rail to expand the graph.
                        pulseModule(
                            expansion: expansion,
                            maxGraphHeight: maxGraphHeight,
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

                // "Settle in" rides above the carousel's screen dim once a card is in
                // tonight's hand, and carries the hand into the session.
                if deckPhase == .carousel {
                    deckChrome(layout: layout)
                        .zIndex(100)
                }

                reflectionBanner

                #if DEBUG
                debugOverlay(layout: layout)
                #endif
            }
            // Pin the screen ZStack to the true screen width. A child (deck backdrop /
            // atmosphere) was inflating it past the screen, anchoring at the leading
            // edge and pushing the centered content column ~13pt right (off the right
            // edge). Clamping here re-centers every module on the physical screen.
            .frame(width: layout.screenWidth, alignment: .center)
            .onAppear { runEntranceAnimations() }
            .blur(radius: pathOpen ? 9 : 0)
            .animation(AppAnimation.spring, value: pathOpen)
            .vaylCover(
                isPresented: Binding(
                    get: { sessionHand != nil },
                    set: { if !$0 { sessionHand = nil } }
                )
            ) {
                CardSessionContainerView(hand: sessionHand ?? [])
            }
            // Pulse check-in — sheet (discrete task), not a cover (not an immersive mode).
            .vaylSheet(
                isPresented: $showPulseCheckIn,
                heightFraction: 0.82,
                screenHeight: layout.screenHeight
            ) {
                PulseCheckInView(store: pulseStore, onClose: { showPulseCheckIn = false })
            }
            // The Vayl sheet (custom OB chrome). Pass the real screen height so the
            // half fraction is reliable — the overlay's own geometry here measures the
            // tall scroll runway, which would resolve the fraction too large.
            .vaylSheet(
                isPresented: $showPulseInfo,
                heightFraction: 0.75,
                screenHeight: layout.screenHeight
            ) {
                PulseInfoSheet()
            }
        }
    }

    // MARK: - Pulse (the secondary hero — tap the rail to expand the graph)

    private func pulseModule(expansion: Double, maxGraphHeight: CGFloat, columnWidth: CGFloat) -> some View {
        HomePulseRail(
            onTap: { withAnimation(AppAnimation.spring) { pulseExpanded.toggle() } },
            onCheckIn: { showPulseCheckIn = true },
            onInfo: { showPulseInfo = true },
            expansion: expansion,
            maxGraphHeight: maxGraphHeight
        )
        // Animate the graph growth + the column reflow when the expanded state flips.
        .animation(AppAnimation.spring, value: expansion)
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
            HomeLexicon(onOpen: onOpenLexicon)
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
                font: AppFonts.display(40, weight: .bold, relativeTo: .largeTitle),
                animated: false
            )
            Spacer()
            PartnerChip(
                state: partnerChipState,
                waiting: isWaitingOnPartner,
                onInviteTap: onInvitePartner,
                onPartnerTap: onPartnerTap
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    removal:   .move(edge: .top).combined(with: .opacity)
                )
            )
            .animation(AppAnimation.spring, value: showReflectionBanner)
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
        sessionHand = hand
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
            cornerDeck
                .position(
                    x: layout.screenWidth - 48,
                    y: layout.safeAreaInsets.top + 24
                )

            if !handIDs.isEmpty {
                VStack {
                    Spacer()
                    settleInBar
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl + layout.homeIndicatorInset)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                    .background(Circle().fill(AppColors.spectrumBorder))
                    .offset(y: -2)
            }
        }
        .animation(AppAnimation.spring, value: handIDs.count)
    }

    private func runEntranceAnimations() {
        withAnimation(AppAnimation.slow.delay(0.10))   { greetingVisible = true }
        withAnimation(AppAnimation.spring.delay(0.30)) { heroVisible     = true }
        withAnimation(AppAnimation.slow.delay(0.62))   { pulseVisible    = true }
        withAnimation(AppAnimation.slow.delay(0.78))   { lexVisible      = true }
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
                        .font(Font.custom("Switzer-Regular", size: 22, relativeTo: .title3))
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
    .modelContainer(.previewContainer)
    .preferredColorScheme(.dark)
}
