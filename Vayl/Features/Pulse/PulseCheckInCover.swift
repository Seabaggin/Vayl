//
//  PulseCheckInCover.swift
//  Vayl
//
//  A self-contained Pulse check-in, presentable IN PLACE over any surface
//  (Home now; Map can adopt the same component later) without routing away.
//
//  Reuses CheckInShell (the full check-in flow) and owns the camera state that
//  CheckInShell drives, then writes the finished entry to the shared PulseStore.
//  Mirrors the wiring PulseWidget already uses — but as a reusable component, so
//  the same check-in can be launched from multiple surfaces. Does NOT touch
//  PulseWidget or PulseGraph.
//

import SwiftUI

struct PulseCheckInCover: View {

    /// The store the finished entry is written to (passed explicitly so it's the
    /// same instance the presenting surface reads — no environment-propagation guess).
    let store: PulseStore

    /// Called to dismiss the cover (set the presenter's binding false).
    var onClose: () -> Void

    // Camera state CheckInShell animates during the check-in choreography.
    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    var body: some View {
        CheckInShell(
            entries:      store.entries,
            camScale:     $camScale,
            camTx:        $camTx,
            camTy:        $camTy,
            liveScore:    $liveScore,
            drawProgress: $drawProgress,
            onComplete: { entry in
                store.add(entry)
                onClose()
            },
            onDismiss: { onClose() }
        )
    }
}
