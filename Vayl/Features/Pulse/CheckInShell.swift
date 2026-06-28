// Features/Pulse/CheckIn/CheckInShell.swift
// Thin forwarding shell. Hosts PulseCheckInView.
// Legacy camera bindings kept so PulseCheckInCover (deprecated path) compiles.

import SwiftUI

struct CheckInShell: View {

    let store:    PulseStore
    var onDismiss: () -> Void

    // Legacy camera bindings — kept for ABI compat, unused by PulseCheckInView.
    let entries:      [PulseEntry]
    var camScale:     Binding<CGFloat> = .constant(1)
    var camTx:        Binding<CGFloat> = .constant(0)
    var camTy:        Binding<CGFloat> = .constant(0)
    var liveScore:    Binding<Double?> = .constant(nil)
    var drawProgress: Binding<CGFloat> = .constant(0)
    var onComplete:   (PulseEntry) -> Void = { _ in }

    var body: some View {
        PulseCheckInView(store: store, onClose: onDismiss)
    }
}

#Preview {
    CheckInShell(store: PulseStore(), onDismiss: {}, entries: [])
        .preferredColorScheme(.dark)
}
