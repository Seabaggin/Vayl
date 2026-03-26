// Features/Home/HomeViewSingle.swift
// Open Lightly
//
// Home screen for solo users with no current partner.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewSingle: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSingle")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloSingle
    return HomeViewSingle()
        .environment(state)
}
