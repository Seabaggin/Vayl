//
//  CheckInShell.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Pulse/CheckIn/CheckInShell.swift
// Open Lightly
//
// Full-screen container for the check-in experience.
// Presented via fullScreenCover from PulseWidget.
// PulseGraph fills top 60% — always visible, never replaced.
// DailyCheckInView panel slides up from bottom 40%.
// All camera + live state owned by PulseWidget, passed as bindings.
// Background and glow field live here — not in DailyCheckInView.

import SwiftUI

struct CheckInShell: View {

    // MARK: - Inputs

    let entries: [PulseEntry]

    // Camera + live state — owned by PulseWidget
    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    // MARK: - Layout

    // Graph occupies top 60% of the shell.
    // Questions panel occupies bottom 40%.
    // These are the proportions described in the product doc.
    private let graphFraction: CGFloat = 0.60

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let graphH  = geo.size.height * graphFraction
            let graphW  = geo.size.width
            let panelH  = geo.size.height * (1 - graphFraction)

            ZStack(alignment: .top) {

                // ── Background ──────────────────────────────
                (isLight ? AppColors.pageBackground : AppColors.pageBackground)
                    .ignoresSafeArea()

                // ── Atmosphere ──────────────────────────────
                if isLight {
                    AuroraGlowField()
                        .ignoresSafeArea()
                } else {
                    OnboardingAtmosphere()
                        .ignoresSafeArea()
                }

                // ── Graph — top 60%, always visible ─────────
                // This is the only PulseGraph instance during check-in.
                // Camera bindings animate this graph directly.
                // The user watches themselves move here in real time.
                VStack(spacing: 0) {
                    PulseGraph(
                        entries:          entries,
                        graphWidth:       graphW,
                        graphHeight:      graphH,
                        camScale:         camScale,
                        camTx:            camTx,
                        camTy:            camTy,
                        liveScore:        liveScore,
                        drawProgress:     drawProgress,
                        disableTouchGlow: true
                    )
                    .frame(width: graphW, height: graphH)

                    Spacer()
                }

                // ── Questions panel — bottom 40% ─────────────
                // DailyCheckInView renders only its phase content here.
                // It writes into the bindings above — moves the graph.
                VStack(spacing: 0) {
                    Spacer()
                    DailyCheckInView(
                        entries:              entries,
                        graphWidth:           graphW,
                        graphHeight:          graphH,
                        camScale:             $camScale,
                        camTx:                $camTx,
                        camTy:                $camTy,
                        liveScore:            $liveScore,
                        drawProgress:         $drawProgress,

                        onComplete:           onComplete,
                        onDismiss:            onDismiss
                    )
                    .frame(height: panelH)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Harness for live binding testing

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

#Preview("Shell — live bindings — dark") {
    CheckInShellHarness()
        .preferredColorScheme(.dark)
}

#Preview("Shell — live bindings — light") {
    CheckInShellHarness()
        .preferredColorScheme(.light)
}
