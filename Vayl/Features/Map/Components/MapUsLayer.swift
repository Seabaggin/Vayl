// Features/Map/Components/MapUsLayer.swift
// STUB: Will be rebuilt in Segment 4 with two-aura comparison + PulseCapsule + split grid.

import SwiftUI

struct MapUsLayer: View {

    let stats: MapStore.UsStats
    let align: [MapStore.AlignItem]
    let lockedAlignCount: Int
    var onOpenVault: () -> Void

    var body: some View {
        Text("Us")
            .font(AppFonts.screenTitle)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
