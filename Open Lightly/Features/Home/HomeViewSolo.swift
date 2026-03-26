// Features/Home/HomeViewSolo.swift
// Open Lightly
//
// Home screen for solo users who have a partner (open or not yet disclosed).
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewSolo: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSolo")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloPartnered
    return HomeViewSolo()
        .environment(state)
}
