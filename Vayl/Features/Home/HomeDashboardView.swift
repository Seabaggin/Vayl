//
//  HomeDashboardView.swift
//  Vayl
//

import SwiftUI

private struct ConstellationOffsetKey: PreferenceKey {
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
    var desireMapState: DesireMapState = .hidden
    var reflectionCardState: ReflectionCardState = .hidden
    var pickUpItems: [PickUpItem] = []
    var stageIndex: Int = 1
    var cardsCompleted: Int = 0
    var daysSinceLastSession: Int? = nil
    var recentEvents: [HomeEvent] = []
    var isSolo: Bool = false
    var showReflectionBanner: Bool = false

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

    // MARK: - Environment + State

    @Environment(\.colorScheme) private var colorScheme

    @State private var greetingVisible   = false
    @State private var sessionVisible    = false
    @State private var desireMapVisible  = false
    @State private var reflectionVisible = false
    @State private var pickUpVisible     = false
    @State private var pulseVisible      = false
    @State private var prismVisible      = false
    @State private var tickerVisible     = false
    @State private var deckFocused: Bool    = false
    @State private var breathPhase: CGFloat = 0

    // MARK: - Scroll Tracking

    @State private var scrollOffset: CGFloat = 0
    @State private var didFireThresholdHaptic = false
    @State private var constellationMorphProgress: CGFloat = 0

    private let greetingExitThreshold: CGFloat = 160

    private var greetingExitProgress: CGFloat {
        min(max(scrollOffset / greetingExitThreshold, 0), 1)
    }

    // MARK: - Debug

    #if DEBUG
    @State private var showDebugGrid = false
    #endif

    // MARK: - Opacity Helpers

    private func elementOpacity(visible: Bool, focusedFloor: CGFloat = 0.06) -> CGFloat {
        let entranceAlpha: CGFloat = visible ? 1.0 : 0.0
        let focusAlpha: CGFloat   = deckFocused ? focusedFloor : 1.0
        return entranceAlpha * focusAlpha
    }

    private var greetingOpacity: CGFloat {
        let entrance: CGFloat  = greetingVisible ? 1.0 : 0.0
        let exitCurve: CGFloat = pow(1.0 - greetingExitProgress, 1.5)
        let focus: CGFloat     = deckFocused ? 0.05 : 1.0
        return entrance * exitCurve * focus
    }

    // MARK: - Deck Focus Animation

    private var focusAnimation: Animation {
        deckFocused
            ? .easeOut(duration: 0.4)
            : .easeIn(duration: 0.15)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {

                    Spacer(minLength: 4)

                    greetingBlock
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scaleEffect(
                            1.0 - (greetingExitProgress * 0.15),
                            anchor: .bottomLeading
                        )
                        .opacity(greetingOpacity)
                        .offset(
                            y: (greetingVisible ? 0.0 : 12.0)
                             + (scrollOffset > 0 ? scrollOffset * 0.3 : 0)
                        )
                        .blur(
                            radius: (greetingExitProgress * 8.0)
                                  + (deckFocused ? 20.0 : 0.0)
                        )
                        .allowsHitTesting(!deckFocused && greetingExitProgress < 0.5)
                        .animation(.easeOut(duration: 0.5), value: greetingVisible)
                        .animation(focusAnimation, value: deckFocused)

                    Color.clear
                        .frame(height: max(0, 8 - (max(0, scrollOffset) * 0.3)))

                    CardChestContainer(
                        cards: cards,
                        cardsCompleted: cardsCompleted,
                        onCardAction: onCardAction,
                        onNavigateToPlay: onNavigateToPlay,
                        onPhaseChange: { phase in
                            let shouldFocus = (phase != .floating)
                            if shouldFocus != deckFocused {
                                if !shouldFocus {
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(200))
                                        deckFocused = false
                                    }
                                } else {
                                    deckFocused = true
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .opacity(sessionVisible ? 1 : 0)
                    .offset(y: sessionVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.5), value: sessionVisible)
                    .zIndex(10)

                    if desireMapState != .hidden && desireMapState != .fullyUnlocked {
                        Spacer(minLength: 56)
                        DesireMapIndicator(
                            state: desireMapState,
                            onReveal: onDesireMapReveal,
                            onUnlock: onDesireMapUnlock,
                            onRemind: onRemindPartner
                        )
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(elementOpacity(visible: desireMapVisible))
                        .offset(y: desireMapVisible ? 0 : 12)
                        .blur(radius: deckFocused ? 20 : 0)
                        .allowsHitTesting(!deckFocused)
                        .animation(.easeOut(duration: 0.5), value: desireMapVisible)
                        .animation(focusAnimation, value: deckFocused)
                    }

                    if reflectionCardState != .hidden {
                        Spacer(minLength: 56)
                        ReflectionCard(
                            state: reflectionCardState,
                            onMoreTap: onMoreTap,
                            onDone: { pills, note in
                                onReflectionDone?(pills, note, true)
                            }
                        )
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(elementOpacity(visible: reflectionVisible))
                        .offset(y: reflectionVisible ? 0 : 12)
                        .blur(radius: deckFocused ? 20 : 0)
                        .allowsHitTesting(!deckFocused)
                        .animation(.easeOut(duration: 0.5), value: reflectionVisible)
                        .animation(focusAnimation, value: deckFocused)
                    }

                    if !pickUpItems.isEmpty {
                        Spacer(minLength: 56)
                        PickUpCard(
                            items: pickUpItems,
                            onItemTap: onPickUpItemTap
                        )
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(elementOpacity(visible: pickUpVisible))
                        .offset(y: pickUpVisible ? 0 : 8)
                        .blur(radius: deckFocused ? 20 : 0)
                        .allowsHitTesting(!deckFocused)
                        .animation(.easeOut(duration: 0.4), value: pickUpVisible)
                        .animation(focusAnimation, value: deckFocused)
                    }

                    GravLiftView(breathPhase: breathPhase)
                        .padding(.horizontal, 20)
                        .frame(height: 32)
                        .opacity(deckFocused ? 0.0 : 1.0)
                        .animation(focusAnimation, value: deckFocused)

                    Spacer(minLength: 32)

                    ambientZone

                    Spacer(minLength: 320)
                }
            }
            .scrollClipDisabled()
            .onPreferenceChange(ConstellationOffsetKey.self) { minY in
                let screenH   = UIScreen.main.bounds.height
                let fadeStart = screenH * 1.10
                let fadeEnd   = screenH * 0.30
                constellationMorphProgress = max(0, min(1, (fadeStart - minY) / (fadeStart - fadeEnd)))
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                scrollOffset = max(0, newOffset)
                if newOffset >= greetingExitThreshold && !didFireThresholdHaptic {
                    didFireThresholdHaptic = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if newOffset < greetingExitThreshold {
                    didFireThresholdHaptic = false
                }
            }
            .background {
                backgroundLayer.ignoresSafeArea()
            }
            .simultaneousGesture(DragGesture(minimumDistance: 10))

            if showReflectionBanner {
                VStack {
                    ReflectionBannerView(
                        sessionLabel: bannerSessionLabel,
                        partnerName: bannerPartnerName,
                        onDone: onReflectionDone,
                        onDismiss: onReflectionBannerDismiss
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    )
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showReflectionBanner)
            }

            #if DEBUG
            if showDebugGrid {
                DebugGridOverlay()

                VStack(alignment: .leading, spacing: 4) {
                    Text("SCROLL MATH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.yellow)
                        .padding(.bottom, 2)
                    Text("offset:       \(scrollOffset, specifier: "%.1f")")
                    Text("exitProgress: \(greetingExitProgress, specifier: "%.3f")")
                    Text("greetingVis:  \(greetingVisible ? "TRUE" : "FALSE")")
                    Text("pulseVis:     \(pulseVisible ? "TRUE" : "FALSE")")
                    Text("deckFocused:  \(deckFocused ? "TRUE" : "FALSE")")
                    Text("breathPhase:  \(breathPhase, specifier: "%.3f")")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.top, 60)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                HStack {
                    Button { showDebugGrid.toggle() } label: {
                        Image(systemName: showDebugGrid ? "grid.circle.fill" : "grid.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(showDebugGrid ? Color.cyan : Color.white.opacity(0.4))
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 100)
                    Spacer()
                }
            }
            #endif
        }
        .onAppear { runEntranceAnimations() }
    }

    // MARK: - Section Divider

    private func sectionDivider(label: String, colors: [Color]) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: 16)

            Text(label)
                .font(AppFonts.overline)
                .tracking(2.5)
                .foregroundStyle(
                    colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            (colorScheme == .light ? Color.black : Color.white).opacity(0.10),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Pulse → Prism Thread

    private var pulseToprismThread: some View {
        GeometryReader { geo in
            let threadWidth = geo.size.width * 0.20
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                       location: 0.00),
                            .init(color: AppColors.cyan.opacity(0.22), location: 0.20),
                            .init(color: AppColors.cyan.opacity(0.22), location: 0.80),
                            .init(color: .clear,                       location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: threadWidth, height: 1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 1)
        .padding(.horizontal, 20)
    }

    // MARK: - Ambient Zone

    private var ambientZone: some View {
        VStack(spacing: 0) {

            Spacer(minLength: 16)

            sectionDivider(label: "THE PULSE", colors: [AppColors.cyan, AppColors.purple])
                .opacity(elementOpacity(visible: pulseVisible))
                .animation(.easeOut(duration: 0.5), value: pulseVisible)

            Spacer(minLength: 12)

            HomeWidgetShell(
                isLight:     colorScheme == .light,
                accentColor: AppColors.cyan,
                rimVariant:  .pulse
            ) {
                ZStack {
                    if colorScheme == .dark {
                        OrbLayer(accentColor: AppColors.cyan, height: 300, variant: .pulse)
                    }
                    PulseWidget(onOpenInMap: onNavigateToPlay)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .opacity(pulseVisible ? 1.0 : 0.0)
            .offset(y: pulseVisible ? 0 : 12)
            .allowsHitTesting(!deckFocused)
            .animation(.easeOut(duration: 0.5), value: pulseVisible)

            Spacer(minLength: 20)
            pulseToprismThread
            Spacer(minLength: 16)

            sectionDivider(label: "THE PRISM", colors: [AppColors.purple, AppColors.magenta])
                .opacity(elementOpacity(visible: prismVisible))
                .animation(.easeOut(duration: 0.5), value: prismVisible)

            Spacer(minLength: 12)

            HomeWidgetShell(
                isLight:     colorScheme == .light,
                accentColor: AppColors.electricViolet,
                rimVariant:  .prism
            ) {
                ZStack {
                    if colorScheme == .dark {
                        OrbLayer(accentColor: AppColors.electricViolet, height: 300, variant: .prism)
                    }
                    PrismView(breathPhase: breathPhase)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)

            Spacer(minLength: 20)
            pulseToprismThread
            Spacer(minLength: 16)

            sectionDivider(
                label:  "THE CONSTELLATION",
                colors: colorScheme == .dark
                    ? [AppColors.cyan, AppColors.purple]
                    : [AppColors.purple, AppColors.magenta]
            )
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ConstellationOffsetKey.self,
                        value: proxy.frame(in: .global).minY
                    )
                }
            )
            .opacity(elementOpacity(visible: prismVisible))
            .animation(.easeOut(duration: 0.5), value: prismVisible)

            Spacer(minLength: 12)

            ConstellationView()
                .padding(.horizontal, 14)
                .opacity(elementOpacity(visible: prismVisible))
                .offset(y: prismVisible ? 0 : 12)
                .blur(radius: deckFocused ? 20 : 0)
                .allowsHitTesting(!deckFocused)
                .animation(.easeOut(duration: 0.5), value: prismVisible)
                .animation(focusAnimation, value: deckFocused)
        }
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        HStack(alignment: .center) {
            if !displayName.isEmpty {
                LivingText(
                    text: "\(displayName).",
                    font: AppFonts.display(40, weight: .bold)
                )
            }
            Spacer()
            PartnerChip(
                state: partnerChipState,
                onInviteTap: onInvitePartner,
                onPartnerTap: onPartnerTap
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.18),
                            AppColors.deepBlue.opacity(0.08),
                            Color.clear
                        ],
                        center:      .top,
                        startRadius: 30,
                        endRadius:   380
                    ))
                    .frame(width: 600, height: 400)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                HomeGlowField(morphProgress: constellationMorphProgress)
            }
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) { greetingVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { sessionVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.38)) { desireMapVisible  = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { reflectionVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) { pickUpVisible     = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.65)) { pulseVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.80)) { prismVisible      = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.95)) { tickerVisible     = true }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                breathPhase = 1.0
            }
        }
    }
}

// MARK: - Debug Grid Overlay

#if DEBUG
private struct DebugGridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let width  = geo.size.width
            let height = geo.size.height
            let unit: CGFloat = 8

            ZStack(alignment: .topLeading) {
                ForEach(0..<Int(height / unit), id: \.self) { i in
                    let y       = CGFloat(i) * unit
                    let isMajor = i % 8 == 0
                    Rectangle()
                        .fill(Color.cyan.opacity(isMajor ? 0.18 : 0.06))
                        .frame(height: 1)
                        .offset(y: y)
                }
                ForEach(0..<Int(width / unit), id: \.self) { i in
                    let x       = CGFloat(i) * unit
                    let isMajor = i % 8 == 0
                    Rectangle()
                        .fill(Color.cyan.opacity(isMajor ? 0.18 : 0.06))
                        .frame(width: 1)
                        .offset(x: x)
                }
                Rectangle()
                    .fill(Color(red: 1, green: 0, blue: 1).opacity(0.55))
                    .frame(width: 1)
                    .offset(x: width / 2)
                Rectangle()
                    .fill(Color.yellow.opacity(0.45))
                    .frame(width: 1)
                    .offset(x: 20)
                Rectangle()
                    .fill(Color.yellow.opacity(0.45))
                    .frame(width: 1)
                    .offset(x: width - 20)
                Rectangle()
                    .fill(Color.orange.opacity(0.35))
                    .frame(width: 1)
                    .offset(x: 24)
                Rectangle()
                    .fill(Color.orange.opacity(0.35))
                    .frame(width: 1)
                    .offset(x: width - 24)

                VStack(alignment: .leading, spacing: 4) {
                    Label("center axis", systemImage: "circle.fill").foregroundStyle(Color(red: 1, green: 0, blue: 1))
                    Label("20pt margin", systemImage: "circle.fill").foregroundStyle(.yellow)
                    Label("24pt margin", systemImage: "circle.fill").foregroundStyle(.orange)
                    Label("8pt grid",    systemImage: "circle.fill").foregroundStyle(.cyan)
                }
                .font(.system(size: 9, weight: .medium))
                .padding(8)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .offset(x: 8, y: 8)
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
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

#Preview("Dark — Day Zero, Solo") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .none,
        cards: [], desireMapState: .hidden,
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 0, recentEvents: [], isSolo: true
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Day Zero, Invite Pending") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .invitePending,
        cards: [], desireMapState: .youDone(partnerName: "Alex"),
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 0, recentEvents: []
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Mid Deck, Both Map Ready") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .active(name: "Alex", initial: "A"),
        cards: [], desireMapState: .bothReady,
        reflectionCardState: .pendingYours(sessionLabel: "Stage 1 · Session 1", sessionDate: Date().addingTimeInterval(-172800)),
        pickUpItems: [], stageIndex: 1, cardsCompleted: 5,
        recentEvents: [.partnerCompletedDesireMap(partnerName: "Alex")]
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Reflection Banner") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .active(name: "Alex", initial: "A"),
        cards: [], desireMapState: .hidden,
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 3, recentEvents: [],
        showReflectionBanner: true
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Light — Day Zero") {
    HomeDashboardView(
        displayName: "Jordan", partnerChipState: .none,
        cards: [], desireMapState: .hidden,
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 0, recentEvents: []
    )
    .environment(PulseStore())
    .preferredColorScheme(.light)
}

#Preview("Dark — No Name") {
    HomeDashboardView(
        displayName: "", partnerChipState: .none,
        cards: [], desireMapState: .hidden,
        reflectionCardState: .hidden, pickUpItems: [],
        stageIndex: 1, cardsCompleted: 0, recentEvents: [], isSolo: true
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
