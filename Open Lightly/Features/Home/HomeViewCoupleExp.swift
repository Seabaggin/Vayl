// Features/Home/HomeViewCoupleExp.swift
// Open Lightly
//
// Home screen for couples with existing ENM experience.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewCoupleExp: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewCoupleExp")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .coupleExperienced
    return HomeViewCoupleExp()
        .environment(state)
}
