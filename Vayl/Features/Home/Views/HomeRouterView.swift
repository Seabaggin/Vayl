//
//  HomeRouterView.swift
//  Vayl
//
//  Thin view. Renders only.
//  All routing logic lives in HomeStore.
//  All state lives in HomeStore.
//  This file switches on store.homeState and renders the result.
//

import SwiftUI
import SwiftData

struct HomeRouterView: View {

    @Environment(AppState.self) private var appState
    @Environment(CoupleContext.self) private var coupleContext
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeRouterInnerView(
            appState: appState,
            coupleContext: coupleContext,
            modelContainer: modelContext.container
        )
    }
}

private struct HomeRouterInnerView: View {

    @Environment(AppState.self) private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AuthStore.self) private var authStore
    @Environment(\.modelContext) private var modelContext

    @State private var store: HomeStore

    // ── Desire Map rater presentation ────────────────────────────────────
    // Presented as a .vaylCover so the rater is a protected, immersive, unhurried
    // beat (interactive-dismiss disabled; exit is explicit via vaylDismiss).
    // Reachable for unpaired users too (head-start hook).
    @State private var activeMap: DesireMapStore?

    // Captured when the rater opens, so the dismiss handler can tell whether the user JUST
    // completed (false → true) and should see the one-shot completion beat.
    @State private var mapWasCompleteOnOpen = false

    // ── Desire-Map reveal presentation (D4) ──────────────────────────────
    // Full-screen "magic moment" — celebrates where the couple aligns (free/locked split).
    @State private var activeReveal: DesireRevealStore?

    // ── Getting Started "Path" overlay ───────────────────────────────────
    // The day-1 activation expands the dashboard entry card (matched geometry)
    // into a Path overlay over a blurred Home. Hosted here — not a cover — so
    // the blurred Home shows behind it.
    @Namespace private var pathNamespace
    @State private var showPath = false

    // ── Pairing sheet presentation ───────────────────────────────────────
    // Home is now a first-class entry point for pairing (previously routed to
    // the Map tab). Mirrors the exact pattern in SettingsPartnerView: fresh
    // PairingStore per presentation, appState injected via .environment.
    @State private var showPairingInvite = false
    @State private var showPairingJoin = false

    init(appState: AppState, coupleContext: CoupleContext, modelContainer: ModelContainer) {
        _store = State(initialValue: HomeStore(
            modelContainer: modelContainer,
            appState: appState,
            couple: coupleContext
        ))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            Group {
                routedContent(store: store, layout: layout)
            }
        }
        .vaylCover(
            isPresented: Binding(
                get: { activeMap != nil },
                set: { if !$0 { activeMap = nil } }
            ),
            confirmOnExit: false,
            // The rater is a natural-end exit (no confirm dialog). The dismiss handler
            // fires via the cover's onExit hook, preserving the completion-beat behavior.
            onExit: handleRaterDismiss
        ) {
            if let mapStore = activeMap {
                DesireMapView(
                    store: mapStore,
                    partnerName: store.partnerName ?? "your partner",
                    // Live: @Observable re-evaluates this when HomeStore's value changes,
                    // so the mirror's ready bar can materialize mid-session (review
                    // 2026-07-09, decision #5).
                    partnerComplete: store.partnerMapComplete,
                    // One-shot status refetch when the mirror appears — the store refetches
                    // through its Service; the view only surfaces the moment.
                    onMirrorAppeared: { await store.refreshDesireStatus() }
                )
            }
        }
        .vaylCover(
            isPresented: Binding(
                get: { activeReveal != nil },
                set: { if !$0 { activeReveal = nil } }
            ),
            confirmOnExit: false
        ) {
            if let revealStore = activeReveal {
                DesireRevealView(store: revealStore)
            }
        }
        .vaylSheet(isPresented: $showPairingInvite, heightFraction: 0.92) {
            PairingInviteView(
                store: PairingStore(modelContainer: modelContext.container, appState: appState)
            )
            .environment(appState)
        }
        .vaylSheet(isPresented: $showPairingJoin, heightFraction: 0.92) {
            PairingJoinView(
                store: PairingStore(modelContainer: modelContext.container, appState: appState)
            )
            .environment(appState)
        }
    }

    // MARK: - Routed Content

    @ViewBuilder
    private func routedContent(store: HomeStore, layout: AppLayout) -> some View {
        ZStack {
            // Home leads with the dashboard from day one; .gated is vestigial. The waiting/reveal
            // progression is surfaced via the Getting Started path + partner pill, not a dashboard
            // card. The dashboard blurs behind the one-shot map-charted moment.
            Group {
                switch store.homeState {
                case .gated, .dashboard, .soloUnpaired:
                    dashboardContent(store: store)
                        .transition(.opacity)
                }
            }
            .blur(radius: store.showCompletionBeat ? 18 : 0)
            .animation(AppAnimation.enter, value: store.showCompletionBeat)

            // The Path overlay sits above the dashboard so the blurred Home shows behind it.
            if showPath {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation(AppAnimation.spring) { showPath = false } }

                GettingStartedPathView(
                    gettingStarted: store.gettingStarted,
                    namespace: pathNamespace,
                    onSelect: { kind in
                        withAnimation(AppAnimation.spring) { showPath = false }
                        handleStep(kind, store: store)
                    },
                    onClose: { withAnimation(AppAnimation.spring) { showPath = false } }
                )
                .padding(.horizontal, AppSpacing.lg)
                .transition(.opacity)
            }

            // One-shot completion beat — a brief moment over the dashboard, never a home state.
            if store.showCompletionBeat {
                MapChartedMoment(
                    partnerName: store.partnerName ?? "your partner",
                    onDone: { store.dismissCompletionBeat() }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(AppAnimation.enter, value: store.homeState)
        .animation(AppAnimation.spring, value: showPath)
        .animation(AppAnimation.enter, value: store.showCompletionBeat)
        .task {
            await store.loadAll()
        }

        #if DEBUG
        // Keep the simulator-only state controls clear of the Pulse pill on the card's
        // trailing edge. Synthesized taps target screen coordinates, so an overlapping
        // debug Button otherwise receives the check-in tap and opens the reveal fixture.
        .overlay(alignment: .bottomLeading) {
            debugControls(store: store, layout: layout)
        }
        #endif
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(store: HomeStore) -> some View {
        if let error = store.deckLoadError {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.exclamationTriangle)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.accentTertiary)

                Text("Couldn't load your deck")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(error)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task { await store.loadDeck() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppSpacing.xl)

        } else if store.isLoadingDeck || store.deck == nil {
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.accentPrimary)
                Text("Loading your deck...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
            }

        } else if let loadedDeck = store.deck {
            HomeDashboardView(
                displayName: appState.displayName,
                partnerChipState: store.partnerChipState,
                cards: loadedDeck.orderedCards,
                deck: loadedDeck,
                deckTitle: loadedDeck.title,
                desireMapState: store.desireMapState,
                partnerPulsePosition: store.partnerPulsePosition,
                partnerPulseFetchFailed: store.partnerPulseFetchFailed,
                reflectionCardState: store.reflectionCardState,
                pickUpItems: [],
                stageIndex: store.stageIndex,
                cardsCompleted: store.cardsCompleted,
                recentEvents: [],
                isSolo: store.isSolo,
                isOffline: authStore.isOffline,
                lexiconRemotePool: store.lexiconRemotePool,
                gettingStarted: store.gettingStarted,
                pathNamespace: pathNamespace,
                pathOpen: showPath,
                onOpenPath: { withAnimation(AppAnimation.spring) { showPath = true } },
                onCardAction: { card, action in
                    handleCardAction(card: card, action: action, deck: loadedDeck, store: store)
                },
                onInvitePartner: { showPairingInvite = true },
                onPartnerTap: {
                    switch appState.linkState {
                    case .linked:
                        appState.settingsPresented = true
                    default:
                        showPairingJoin = true
                    }
                },
                onSessionEnded: { Task { await store.refreshDeckState() } },
                onOpenLexicon: { appState.selectedTab = .learn },
                onPulseTap: { appState.selectedTab = .map },
                // Interim: route to the Pulse surface. Final: present the shared
                // check-in sheet in place (Bryan's PulseWidget pass).
                onCheckIn: { appState.selectedTab = .map },
                onOpenSettings: { appState.settingsPresented = true }
            )
        }
    }

    // MARK: - Card Action Handler

    /// Handles card actions from HomeDashboardView.
    /// Lives here because this view owns appState and modelContext.
    private func handleCardAction(card: Card, action: CardAction, deck: Deck, store: HomeStore) {
        switch action {

        case .navigateToPlay:
            appState.selectedTab = .play

        default:
            break
        }
    }

    // MARK: - Getting Started Step Router

    /// Routes a tapped Path step to its destination. Only `.active` steps are tappable
    /// (enforced in GettingStartedPathView), so this just opens the right surface.
    private func handleStep(_ kind: GettingStartedStepKind, store: HomeStore) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // TODO(Moments): when gettingStarted advances a step (e.g. map → invite), fire a warm
        // HomeEvent/Moment ("First Spark") via the (future) Moments surface. No silent flag.
        switch kind {
        case .mapDesires:
            mapWasCompleteOnOpen = store.myMapComplete
            activeMap = DesireMapStore(
                modelContainer: modelContext.container,
                appState: appState
            )
        case .invitePartner:
            showPairingInvite = true
        case .seeReveal:
            presentReveal()                  // D4 reveal (stub) — full-screen "magic moment"
        case .profile:
            break                            // profile already done
        }
    }

    /// Presents the Desire-Map reveal (D4). Reads matches + the entitlement gate via the store.
    private func presentReveal() {
        activeReveal = DesireRevealStore(appState: appState, entitlements: entitlements)
    }

    /// Gap between the rater cover dismissing and the reveal cover rising. Two covers on one
    /// host cannot transition at once, so the reveal waits for the rater's dismiss to settle.
    private static let raterToRevealHandoff: Double = 0.35

    /// On rater close: the store refreshes and resolves the branch (reveal handoff /
    /// one-shot completion beat / nothing — see HomeStore.raterDismissOutcome). This
    /// view only presents the result.
    private func handleRaterDismiss() {
        Task {
            switch await store.raterDismissOutcome(wasCompleteOnOpen: mapWasCompleteOnOpen) {
            case .showReveal:
                try? await Task.sleep(for: .seconds(Self.raterToRevealHandoff))
                presentReveal()
            case .celebrateCompletion:
                store.celebrateMapCompletion()
            case .none:
                break
            }
        }
    }

    // MARK: - Debug Controls

    #if DEBUG
    private func debugControls(store: HomeStore, layout: AppLayout) -> some View {
        VStack(alignment: .trailing, spacing: AppSpacing.sm) {
            Text("HomeState: \(String(describing: store.homeState))")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)

            Button("OB ✓") {
                let profile: UserProfile
                if let existing = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
                    profile = existing
                } else {
                    profile = UserProfile(displayName: "Debug User")
                    modelContext.insert(profile)
                }
                appState.markOnboardingComplete(profile, context: modelContext)
            }

            Button(store.myMapComplete ? "Map ✓" : "Map ✗") {
                store.myMapComplete.toggle()
            }
            Button(store.postReflectionDone ? "Reflected ✓" : "Reflected ✗") {
                store.postReflectionDone.toggle()
            }
            Button(store.partnerMapComplete ? "Partner ✓" : "Partner ✗") {
                store.partnerMapComplete.toggle()
            }
            Button(store.revealDone ? "Reveal ✓" : "Reveal ✗") {
                store.revealDone.toggle()
            }
            // Direct reveal entry for testing — the production link is the Getting Started
            // `.seeReveal` step, only reachable once BOTH partners finish. One button per variant
            // so all three telegraphs are feelable solo (production picks one by coupleId).
            Button("Reveal · Gather ▶") { presentSampleReveal(.gather) }
            Button("Reveal · Sweep ▶") { presentSampleReveal(.sweep) }
            Button("Reveal · Constellate ▶") { presentSampleReveal(.constellate) }
        }
        .font(AppFonts.overline)
        .foregroundStyle(AppColors.accentPrimary)
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.trailing, AppSpacing.md)
        .bottomContentInset(layout)
    }

    /// Opens the reveal with sample matches and a forced ceremony variant (debug feel-testing).
    private func presentSampleReveal(_ variant: CeremonyVariant) {
        let reveal = DesireRevealStore.previewStore(matches: [
            .sample("New Relationship Energy", .mutual, free: true),
            .sample("Overnight Stays With Others", .adjacent, locked: true),
            .sample("Meeting Your Partner's Connections", .mutual, locked: true),
            .sample("Shared Space Agreements", .mutual, locked: true),
            .sample("Deep Conversations Outside", .adjacent, locked: true)
        ], entitlements: entitlements)
        reveal.debugVariantOverride = variant
        activeReveal = reveal
    }
    #endif
}

#if DEBUG
// Same environment recipe as the MapView / PlayView previews: one AppState shared
// by every store, in-memory container, no live services touched at init (loadAll's
// remote fetches fail silently in the canvas; the deck loads from the bundle).
#Preview("Home router") {
    let state = { let s = AppState(); s.displayName = "Jordan"; return s }()
    let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: state)
    return HomeRouterView()
        .environment(state)
        .environment(PulseStore())
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainer))
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
