// Features/Pulse/PulseSheetView.swift
// STUB: PulseGraph removed. Will be rebuilt in Segment 4/5 with field + history grid.

import SwiftUI

struct PulseSheetView: View {

    var entries:     [PulseEntry]
    var onDismiss:   (() -> Void)? = nil
    var onOpenInMap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            Text("Pulse History")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

#Preview {
    PulseSheetView(entries: PulseEntry.previews)
        .preferredColorScheme(.dark)
}
