// Features/Home/HomeViewCoupleNew.swift
// Open Lightly
//
// Home screen for couples who are new to non-monogamy exploration.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewCoupleNew: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewCoupleNew")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .coupleNew
    return HomeViewCoupleNew()
        .environment(state)
}
