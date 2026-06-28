// Features/Pulse/PulseWidget.swift
// STUB: PulseGraph removed. Will be replaced in Segment 6 with the compact aura widget.

import SwiftUI

struct PulseWidget: View {

    @Environment(PulseStore.self) private var store

    var onOpenInMap: (() -> Void)? = nil

    @State private var showSheet:    Bool        = false
    @State private var showCheckIn:  Bool        = false
    @State private var pendingEntry: PulseEntry? = nil

    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    private var entries: [PulseEntry] { store.entries }

    var body: some View {
        Text("Pulse")
            .font(AppFonts.screenTitle)
            .foregroundStyle(AppColors.textMuted)
            .fullScreenCover(isPresented: $showCheckIn) {
                CheckInShell(
                    entries:      entries,
                    camScale:     $camScale,
                    camTx:        $camTx,
                    camTy:        $camTy,
                    liveScore:    $liveScore,
                    drawProgress: $drawProgress,
                    onComplete: { entry in
                        pendingEntry = entry
                        showCheckIn  = false
                    },
                    onDismiss: {
                        resetCheckInState()
                        showCheckIn = false
                    }
                )
            }
            .onChange(of: showCheckIn) { _, isShowing in
                if !isShowing, let entry = pendingEntry {
                    store.add(entry)
                    pendingEntry = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        resetCheckInState()
                    }
                }
            }
    }

    private func resetCheckInState() {
        camScale     = 1.0
        camTx        = 0.0
        camTy        = 0.0
        liveScore    = nil
        drawProgress = 0.0
    }
}

#Preview("Stub") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseWidget()
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
