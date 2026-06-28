// Features/Pulse/PulseWidget.swift
// STUB: PulseGraph removed. Will be replaced in Segment 6 with the compact aura widget.

import SwiftUI

struct PulseWidget: View {

    @Environment(PulseStore.self) private var store

    var onOpenInMap: (() -> Void)? = nil

    @State private var showCheckIn = false

    var body: some View {
        Text("Pulse")
            .font(AppFonts.screenTitle)
            .foregroundStyle(AppColors.textMuted)
            .vaylSheet(isPresented: $showCheckIn, heightFraction: 0.82) {
                PulseCheckInView(store: store, onClose: { showCheckIn = false })
            }
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
