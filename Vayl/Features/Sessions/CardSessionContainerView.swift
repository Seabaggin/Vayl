// Features/Sessions/CardSessionContainerView.swift
// Vayl
//
// The protected container for a couple card session — the single `.vaylCover`
// destination for the whole flow. It boots from a SessionLaunch, builds the
// CoupleSessionStore (+ AirlockStore for two-device launches) and runs the
// phase machine:
//
//   lobby/airlock (AirlockStore) → transition → in-session player →
//   close / safeClose → done
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
            let realtime: RealtimeSessionService? =
                launch.session != nil ? RealtimeSessionService() : nil
            let built = CoupleSessionStore(
                launch: launch,
                modelContainer: modelContext.container,
                appState: appState,
                realtime: realtime
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
        .onDisappear {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var transitionBreathe = false

    var body: some View {
        ZStack {
            SessionAtmosphere(turn: turn)

            content
        }
        .animation(AppAnimation.slow.reduceMotionSafe, value: store.phase)
        .onChange(of: store.phase) { _, phase in
            guard phase == .done else { return }
            // A beat on "kept", then leave the cover at a natural end.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.1))
                vaylDismiss(confirm: false)
            }
        }
    }

    private var turn: SessionAtmosphere.Turn {
        guard store.phase == .session else { return .none }
        return store.currentDrawer == .you ? .you : .partner
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .airlock:
            if let airlock {
                switch airlock.state {
                case .waitingForPartner, .failed:
                    SessionLobbyView(store: store, airlock: airlock).transition(.opacity)
                case .bothPresent, .bandwidthSet, .consented, .activating:
                    AirlockView(store: store, airlock: airlock).transition(.opacity)
                case .active:
                    Color.clear.onAppear {
                        airlock.leave()                   // hand the channel to the coordinator
                        store.airlockDidActivate()
                    }
                }
            } else {
                AirlockView(store: store, airlock: nil).transition(.opacity)   // DEBUG local
            }
        case .transition:
            transitionBeat.transition(.opacity)
        case .session:
            SessionPlayerView(store: store).transition(.opacity)
        case .close:
            SessionCloseView(store: store).transition(.opacity)
        case .safeClose:
            SafeWordCloseView(store: store).transition(.opacity)
        case .done:
            doneBeat.transition(.opacity)
        }
    }

    // MARK: - Transition (a held breath, together)

    private var transitionBeat: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Text("look at each other.")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(transitionBreathe && !reduceMotion ? 1.08 : 1.0)
                .opacity(transitionBreathe && !reduceMotion ? 1.0 : 0.7)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                    value: transitionBreathe
                )
                .padding(.top, AppSpacing.xl)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { transitionBreathe = true }
    }

    // MARK: - Done beat

    private var doneBeat: some View {
        VStack(spacing: AppSpacing.sm) {
            if store.safeWordUsed {
                Text("closed, no questions")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                Text("kept, just for you")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("it'll show up in your Map")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
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
