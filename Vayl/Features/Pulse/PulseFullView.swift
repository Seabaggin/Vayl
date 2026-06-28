// Features/Pulse/PulseFullView.swift
// STUB: PulseGraph + PulseDotSummary removed. Will be rebuilt in Segment 4/5.

import SwiftUI

struct PulseFullView: View {

    var entries:   [PulseEntry]  = PulseEntry.previews
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            Text("Pulse Full View")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

#Preview {
    PulseFullView(entries: PulseEntry.previews)
        .preferredColorScheme(.dark)
}
