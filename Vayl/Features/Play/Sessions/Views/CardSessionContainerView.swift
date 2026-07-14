// Features/Sessions/CardSessionContainerView.swift
// Vayl
//
// The protected container for a couple card session — the single `.vaylCover`
// destination for the whole flow. It boots from a SessionLaunch, builds the
// CoupleSessionStore (+ AirlockStore for two-device launches) and runs the
// phase machine:
//
//   lobby/airlock (AirlockStore) → transition → in-session player →
//   close → done
//
// Reconnect: an already-active row skips the airlock and rebuilds the player
// from the row (CoupleSessionStore.resumeIfNeeded). `launch.session == nil` is
// the pure-local DEBUG path (mocked partner in the store).

import SwiftUI
import SwiftData

struct CardSessionContainerView: View {

    let launch: SessionLaunch

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    @State private var store: CoupleSessionStore?
    @State private var airlock: AirlockStore?

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store {
                CoupleSessionFlow(store: store, airlock: airlock)
            }
        }
        .task {
            guard store == nil else { return }
            // The store resolves its own realtime service from the launch —
            // this view composes Stores only, never Services.
            let built = CoupleSessionStore(
                launch: launch,
                modelContainer: modelContext.container,
                appState: appState
            )
            store = built
            // Fresh lobby/airlock rows run the handshake; active/paused rows are
            // the reconnect path (resumeIfNeeded) and skip the airlock.
            if let session = launch.session,
               session.status == CuratedSessionStatus.lobby.rawValue
                || session.status == CuratedSessionStatus.airlock.rawValue,
               let myId = built.localProfileId {
                let a = AirlockStore(
                    coupleId: session.coupleId,
                    myProfileId: myId,
                    role: launch.role
                )
                airlock = a
                Task { await a.start() }
            }
            await built.resumeIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store?.handleScenePhaseActive()
                // The realtime websocket drops in background; the airlock's
                // one-shot presence timeout has already fired by the time we
                // come back, so it needs its own recovery (Fix B).
                if store?.phase == .airlock, let airlock {
                    Task { await airlock.handleScenePhaseActive() }
                }
            }
        }
        .onDisappear {
            // Leaving BEFORE the session went active means the handshake will
            // never finish — abandon the row so the partner's device sees the
            // end instead of a zombie lobby (a mid-session exit keeps the row
            // open on purpose: that's the reconnect path). Skip this when the
            // row is already terminal (airlock state .ended) — re-abandoning
            // an already-dead row is a no-op write we don't need.
            if store?.phase == .airlock, airlock?.state != .ended {
                store?.abandonRemoteSession()
            }
            airlock?.leave()
            store?.teardown()
        }
    }
}

// MARK: - CoupleSessionFlow

/// Routes the store's phase to a screen, owns the session atmosphere and the
/// guarded exit. The close uses an unconfirmed `vaylDismiss` — it is a natural
/// end, not an abandon.
private struct CoupleSessionFlow: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore?

    @Environment(\.vaylDismiss) private var vaylDismiss

    @State private var endedOkayPressed = false
    /// Flips when a logged sitting reaches the close, firing the one terminal
    /// success haptic on the "kept" beat. A first-card bail never sets it.
    @State private var keptTrigger = false

    var body: some View {
        ZStack {
            // The canonical OnboardingAtmosphere runs the whole cover now —
            // airlock through the live session (SessionAtmosphere's turn-
            // tinted blobs read too bright/busy against this screen family).
            // maskStart pulled up from the 0.52 default — the fan deck sits
            // much higher on this screen than a typical OB screen's hero
            // content, so the void needs to end sooner or the deck reads as
            // floating in true black.
            OnboardingAtmosphere(config: .stat, maskStart: 0.12)

            content
        }
        .animation(AppAnimation.slow.reduceMotionSafe, value: store.phase)
        .sensoryFeedback(.success, trigger: keptTrigger)
        .onChange(of: store.phase) { _, phase in
            guard phase == .done else { return }
            // A logged sitting holds a beat on "kept" before leaving. A
            // first-card bail logged nothing, so it just leaves — no beat, no
            // success haptic, and no "it'll show up in your Map" promise to break.
            Task { @MainActor in
                if store.sessionLogged {
                    keptTrigger.toggle()   // the one terminal success haptic
                    try? await Task.sleep(for: .seconds(1.1))
                }
                vaylDismiss(confirm: false)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .airlock:
            if let airlock {
                switch airlock.state {
                case .waitingForPartner, .failed:
                    SessionSettingsView(store: store, airlock: airlock).transition(.opacity)
                case .bothPresent, .consented, .activating:
                    AirlockView(store: store, airlock: airlock).transition(.opacity)
                case .active:
                    Color.clear.onAppear {
                        airlock.leave()                   // hand the channel to the coordinator
                        store.airlockDidActivate()
                    }
                case .ended:
                    endedBeat.transition(.opacity)
                }
            } else {
                AirlockView(store: store, airlock: nil).transition(.opacity)   // DEBUG local
            }
        case .transition:
            SessionDealIntroView(
                dealerCopy: dealerCopy,
                firstPrompt: store.currentCard?.text ?? store.hand.first?.text ?? "",
                onComplete: { store.introDidFinish() }
            )
            .transition(.opacity)
        case .session:
            SessionPlayerView(store: store).transition(.opacity)
        case .close:
            SessionCloseView(store: store).transition(.opacity)
        case .done:
            // Only a logged sitting earns the "kept" beat; a first-card bail
            // shows nothing and the cover dismisses immediately.
            if store.sessionLogged {
                doneBeat.transition(.opacity)
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Pre-session beat dealer copy

    /// The pre-session beat's spoken line. No dedicated deck-authored "dealer
    /// intro line" content field exists yet (flagged as a future content
    /// task) — the catalog's one-line deck tagline reads warm enough to
    /// stand in, with a generic fallback for a hand with no resolvable deck.
    private var dealerCopy: String {
        store.deckSubtitle ?? "tonight, the two of you open up."
    }

    // MARK: - Ended beat (the row died before going active)

    private var endedBeat: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            VStack(spacing: AppSpacing.sm) {
                Text("Looks like this session ended")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("You can set up a new one anytime.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Text("Okay")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                )
                .scaleEffect(endedOkayPressed ? 0.96 : 1.0)
                .sensoryFeedback(.impact(weight: .light), trigger: endedOkayPressed)
                .onTapGesture {
                    endedOkayPressed = true
                    vaylDismiss(confirm: false)
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.12))
                        endedOkayPressed = false
                    }
                }
                .accessibilityLabel("Okay, dismiss ended session")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Done beat

    private var doneBeat: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("kept, just for you")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("it'll show up in your Map")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Session Container — local stub") {
    CardSessionContainerView(launch: SessionLaunch(
        hand: Array(Card.samples.prefix(8)),
        entry: .localDebug,
        role: .a,
        session: nil
    ))
    .environment(AppState())
    .modelContainer(.previewContainer)
    .preferredColorScheme(.dark)
}
