// Features/Explore/ExploreView.swift
// Open Lightly
//
// Content discovery hub — articles, exercises, education tracks.
// Stub — full implementation in a future batch.

import SwiftUI

struct ExploreView: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("ExploreView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloSingle
    return ExploreView().environment(state)
}
