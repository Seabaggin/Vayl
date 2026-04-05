// HomeDashboardView.swift
// Open Lightly

import SwiftUI

struct HomeDashboardView: View {

    // MARK: - Injected Properties

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var cards: [Prompt] = Prompt.samples
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
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil
    var onDesireMapReveal: (() -> Void)? = nil
    var onDesireMapUnlock: (() -> Void)? = nil
    var onReflectionDone: (([String], String?, Bool) -> Void)? = nil
    var onReflectionBannerDismiss: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onPickUpItemTap: ((PickUpItem) -> Void)? = nil
    var onInvitePartner: (() -> Void)? = nil

    // MARK: - Environment + State

    @Environment(\.colorScheme) private var colorScheme

    @State private var greetingVisible   = false
    @State private var sessionVisible    = false
    @State private var desireMapVisible  = false
    @State private var reflectionVisible = false
    @State private var pickUpVisible     = false
    @State private var tickerVisible     = false
    @State private var hasAnimated       = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    Spacer(minLength: 16)

                    // ── Greeting ──────────────────────────────
                    greetingBlock
                        .padding(.horizontal, 24)
                        .opacity(greetingVisible ? 1 : 0)
                        .offset(y: greetingVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: greetingVisible)

                    Spacer(minLength: 16)

                    // ── Card Carousel ─────────────────────────
                    HomeCardCarousel(
                        cards: cards,
                        onCardAction: onCardAction
                    )
                    .padding(.horizontal, 20)
                    .opacity(sessionVisible ? 1 : 0)
                    .offset(y: sessionVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.5),
                               value: sessionVisible)

                    // ── Desire Map Indicator ──────────────────
                    if desireMapState != .hidden
                        && desireMapState != .fullyUnlocked {

                        Spacer(minLength: 14)

                        DesireMapIndicator(
                            state: desireMapState,
                            onReveal: onDesireMapReveal,
                            onUnlock: onDesireMapUnlock,
                            onRemind: onRemindPartner
                        )
                        .padding(.horizontal, 20)
                        .opacity(desireMapVisible ? 1 : 0)
                        .offset(y: desireMapVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: desireMapVisible)
                    }

                    // ── Reflection Card ───────────────────────
                    if reflectionCardState != .hidden {

                        Spacer(minLength: 14)

                        ReflectionCard(
                            state: reflectionCardState,
                            onMoreTap: onMoreTap,
                            onDone: { pills, note in
                                onReflectionDone?(pills, note, true)
                            }
                        )
                        .padding(.horizontal, 20)
                        .opacity(reflectionVisible ? 1 : 0)
                        .offset(y: reflectionVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: reflectionVisible)
                    }

                    // ── Pick Up Where You Left Off ────────────
                    if !pickUpItems.isEmpty {

                        Spacer(minLength: 14)

                        PickUpCard(
                            items: pickUpItems,
                            onItemTap: onPickUpItemTap
                        )
                        .padding(.horizontal, 20)
                        .opacity(pickUpVisible ? 1 : 0)
                        .offset(y: pickUpVisible ? 0 : 8)
                        .animation(.easeOut(duration: 0.5),
                                   value: pickUpVisible)
                    }

                    // ── Research Ticker ───────────────────────
                    Spacer(minLength: 20)

                    ResearchTicker()
                        .opacity(tickerVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.6),
                                   value: tickerVisible)

                    Spacer(minLength: 120)
                }
            }
            .background {
                backgroundLayer
                    .ignoresSafeArea()
            }
            .overlay {
                // ── Reflection Banner Overlay ─────────────────────
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
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: showReflectionBanner
                    )
                }
            }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(greetingSalutation)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary
                        )

                    if !displayName.isEmpty {
                        Text("\(displayName).")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                            )
                    }
                }

                Spacer()

                PartnerChip(
                    state: partnerChipState,
                    onInviteTap: onInvitePartner
                )
                .padding(.top, 4)
            }

            Text(eventOneLiner)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(
                    colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Computed Properties

    private var greetingSalutation: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Hey"
        case 17..<21: return "Good evening"
        default:      return "Still up"
        }
    }

    private var eventOneLiner: String {
        let partner: String? = {
            if case .active(let name, _) = partnerChipState {
                return name
            }
            return nil
        }()
        return HomeEventEngine.oneLiner(
            events: recentEvents,
            stageIndex: stageIndex,
            cardsCompleted: cardsCompleted,
            isSolo: isSolo,
            partnerName: partner
        )
    }

    private var bannerSessionLabel: String {
        if case .pendingYours(let label, _) = reflectionCardState {
            return label
        }
        return "Last session"
    }

    private var bannerPartnerName: String? {
        if case .active(let name, _) = partnerChipState {
            return name
        }
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
                OnboardingGlowField()
            }
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) {
            greetingVisible   = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            sessionVisible    = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.38)) {
            desireMapVisible  = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) {
            reflectionVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) {
            pickUpVisible     = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.70)) {
            tickerVisible     = true
        }
    }
}

// MARK: - Equatable helpers

extension DesireMapState: Equatable {
    static func == (lhs: DesireMapState,
                    rhs: DesireMapState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.bothReady, .bothReady),
             (.fullyUnlocked, .fullyUnlocked):
            return true
        case (.youDone(let a), .youDone(let b)):
            return a == b
        case (.freeRevealSeen(let a), .freeRevealSeen(let b)):
            return a == b
        case (.redoInProgress(let a, let b),
              .redoInProgress(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }
}

extension ReflectionCardState: Equatable {
    static func == (lhs: ReflectionCardState,
                    rhs: ReflectionCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): return true
        default:                 return false
        }
    }
}

// MARK: - Previews

#Preview("Dark — Day Zero, Solo") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Day Zero, Invite Pending") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .youDone(partnerName: "Alex"),
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Mid Deck, Both Map Ready") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .bothReady,
        reflectionCardState: .pendingYours(
            sessionLabel: "Stage 1 · Session 1",
            sessionDate:  Date().addingTimeInterval(-172800)
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [
            .partnerCompletedDesireMap(partnerName: "Alex")
        ]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Both Reflected, Summary") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .summary(
            arc:           "You've moved from something heavy surfacing to feeling connected twice running.",
            yourName:      "Jordan",
            yourDots:      [true, true, true],
            partnerName:   "Alex",
            partnerDots:   [true, true, false],
            swipePosition: 2
        ),
        pickUpItems:         [
            PickUpItem(
                contentType: .timelineScenario(
                    branchCurrent: 2, branchTotal: 4),
                title:       "Alex is home. Sam has been quiet.",
                contextLine: "You're at branch point 2 of 4",
                actionLabel: "Continue →"
            )
        ],
        stageIndex:          1,
        cardsCompleted:      8,
        recentEvents:        []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Deck Complete") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .freeRevealSeen(partnerName: "Alex"),
        reflectionCardState: .bothReflected(
            sessionLabel: "Stage 1 · Session 4",
            yourName:     "Jordan",
            yourPills:    ["Connected", "Surprised"],
            yourNote:     "Didn't expect to feel that settled.",
            partnerName:  "Alex",
            partnerPills: ["Heavy", "Want to talk more"],
            partnerNote:  nil,
            swipePosition: 0
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      12,
        recentEvents:        [.stageCompleted(stageName: "Curiosity")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Waiting on Partner") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [.daysSinceSession(3, partnerName: "Alex")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Reflection Banner") {
    HomeDashboardView(
        displayName:          "Jordan",
        partnerChipState:     .active(name: "Alex", initial: "A"),
        cards:                Prompt.samples,
        desireMapState:       .hidden,
        reflectionCardState:  .hidden,
        pickUpItems:          [],
        stageIndex:           1,
        cardsCompleted:       3,
        recentEvents:         [],
        showReflectionBanner: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Light — Day Zero") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .preferredColorScheme(.light)
}

#Preview("Dark — No Name") {
    HomeDashboardView(
        displayName:         "",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .preferredColorScheme(.dark)
}
