// Features/Sessions/CardSessionContainerView.swift
// Vayl
//
// The protected container for a couple card session — the single `.vaylCover`
// destination for the whole flow. It builds the local CoupleSessionStore from
// the environment and runs the phase machine:
//
//   airlock → transition (phones down) → in-session player → close + reflection → done
//
// FRONT-END / LOCAL: no Realtime. Partner presence and advance are mocked in
// the store; swapping RealtimeSessionService in is a one-layer change there.
// The store/views carry no network. See
// docs/superpowers/specs/2026-06-21-couple-session-quickplay-implementation-spec.md.

import SwiftUI
import SwiftData

struct CardSessionContainerView: View {

    /// Tonight's hand, dealt from the carousel.
    let hand: [Card]

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var store: CoupleSessionStore?

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store {
                CoupleSessionFlow(store: store)
            }
        }
        .task {
            if store == nil {
                store = CoupleSessionStore(
                    hand: hand,
                    modelContainer: modelContext.container,
                    appState: appState
                )
            }
        }
    }
}

// MARK: - CoupleSessionFlow

/// Routes the store's phase to a screen, owns the session atmosphere and the
/// guarded exit. The close uses an unconfirmed `vaylDismiss` — it is a natural
/// end, not an abandon.
private struct CoupleSessionFlow: View {

    @Bindable var store: CoupleSessionStore

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
            AirlockView(store: store).transition(.opacity)
        case .transition:
            transitionBeat.transition(.opacity)
        case .session:
            SessionPlayerView(store: store).transition(.opacity)
        case .close:
            SessionCloseView(store: store).transition(.opacity)
        case .done:
            doneBeat.transition(.opacity)
        }
    }

    // MARK: - Transition (phones down)

    private var transitionBeat: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Text("put your phones down.")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("look at each other.")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textSecondary)
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

#Preview("Session Container — stub") {
    CardSessionContainerView(hand: Array(Card.samples.prefix(8)))
        .environment(AppState())
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
