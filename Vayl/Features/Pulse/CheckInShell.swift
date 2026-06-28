// Features/Pulse/CheckIn/CheckInShell.swift
// STUB: PulseGraph removed. Will be rebuilt in Segment 3 as PulseCheckInView host.

import SwiftUI

struct CheckInShell: View {

    // Public API preserved — callers (PulseWidget, PulseCheckInCover) compile unchanged.
    let entries: [PulseEntry]
    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            Text("Check In")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

// MARK: - Preview harness

private struct CheckInShellHarness: View {
    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    var body: some View {
        CheckInShell(
            entries:      PulseEntry.previews,
            camScale:     $camScale,
            camTx:        $camTx,
            camTy:        $camTy,
            liveScore:    $liveScore,
            drawProgress: $drawProgress,
            onComplete:   { _ in },
            onDismiss:    {}
        )
    }
}

#Preview("Stub") {
    CheckInShellHarness()
        .preferredColorScheme(.dark)
}
