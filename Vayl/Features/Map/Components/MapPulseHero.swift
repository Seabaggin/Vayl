// Features/Map/Components/MapPulseHero.swift
// STUB: PulseGraph removed. Will be rebuilt in Segment 4 as aura hero + field.

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    var onCheckIn: () -> Void
    var onOpenHistory: () -> Void

    var body: some View {
        Text("Pulse")
            .font(AppFonts.screenTitle)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Map Pulse hero stub") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MapPulseHero(onCheckIn: {}, onOpenHistory: {})
            .padding(AppSpacing.lg)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
