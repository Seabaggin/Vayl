// Features/Pulse/Views/PulseCheckInFlow.swift
//
// The Pulse check-in FLOW: a bounded, self-driving sequence inside one cover —
// the one-time "Your First Pulse" doorway, then the check-in itself.
//
// WHY A FLOW AND NOT A SECOND COVER:
// Both Home and Map open the check-in. If each decided whether to show the doorway, the
// first-run gate would live in two tabs and drift apart. Instead both present THIS, and the
// gate exists once, here, next to the store that owns the answer. A tab knows nothing about
// first-run state; it only reports where its aura is on screen so the entrance has something
// to travel from.
//
// PRESENTATION: the caller's `.vaylCover` is unchanged in kind — still full-screen, still
// interactive-dismiss-disabled. Only the entrance differs, and only while the doorway is
// showing (see PulseOrbSource / presentWithoutAnimation at the call sites).

import SwiftUI

struct PulseCheckInFlow: View {

    let store: PulseStore
    /// Where the aura the user tapped sits on screen, global coordinates. nil is fine — the
    /// doorway then opens without the travel, and the check-in never used it at all.
    var sourceOrbFrame: CGRect?
    var onClose: () -> Void

    /// Resolved ONCE, when the flow is constructed. Deliberately not recomputed while the
    /// cover is open: `shouldShowFraming` reads `entries`, and committing the first check-in
    /// mutates `entries` — a live read would yank the gate out from under the flow mid-flight.
    @State private var showFraming: Bool

    init(store: PulseStore, sourceOrbFrame: CGRect? = nil, onClose: @escaping () -> Void) {
        self.store = store
        self.sourceOrbFrame = sourceOrbFrame
        self.onClose = onClose
        _showFraming = State(initialValue: store.shouldShowFraming)
    }

    var body: some View {
        if showFraming {
            PulseFramingView(
                sourceOrbFrame: sourceOrbFrame,
                onBegin: {
                    // Marked on Begin, not on completing the check-in: someone who bails on
                    // question three has still read the doorway, and re-showing it is nagging.
                    store.markFramingSeen()
                    withAnimation(AppAnimation.depthQuiet) { showFraming = false }
                },
                // "Maybe later" leaves WITHOUT marking it seen — they declined checking in,
                // not learning, so the doorway is still owed to them next time.
                onDismiss: onClose
            )
            .transition(.opacity)
        } else {
            PulseCheckInView(store: store, onClose: onClose)
                .transition(.opacity)
        }
    }
}

// MARK: - Source orb frame

/// Publishes the on-screen frame of the aura that opens the check-in, so the framing doorway
/// can begin its entrance on the very object the user touched instead of conjuring a new one.
///
/// A preference rather than a binding: the orb is buried inside HomePulseRail / MapPulseHero,
/// and threading a binding down would make those components know about a flow they don't own.
/// They just mark their aura; the screen root reads it.
struct PulseOrbFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Mark this view as the aura the Pulse check-in opens from.
    /// Read at the screen root with `.onPreferenceChange(PulseOrbFrameKey.self)`.
    func pulseOrbSource() -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: PulseOrbFrameKey.self, value: geo.frame(in: .global))
            }
        )
    }
}

// MARK: - Preview

#if DEBUG
/// Previews the flow's DOORWAY branch specifically — the default store has no entries but
/// also has not hydrated, so `shouldShowFraming` is correctly false in a preview and the real
/// flow would jump straight to the check-in. This host forces the doorway so the entrance can
/// be iterated on without touching the gate.
#Preview("Flow — doorway over a backdrop") {
    ZStack {
        // Stand-in for the screen being left behind, so the dissolve has something to eat.
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.glassSurface)
                    .frame(height: 96)
            }
        }
        .padding(AppSpacing.lg)

        PulseFramingView(sourceOrbFrame: nil, onBegin: {}, onDismiss: {})
    }
    .preferredColorScheme(.dark)
}
#endif
