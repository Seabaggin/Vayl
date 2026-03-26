// Features/MeUs/MeUsView.swift
// Open Lightly
//
// Personal profile and partner connection hub.
// Label: "Me" for solo experiences, "Us · Me" for couple accounts.
// Stub — full implementation in a future batch.

import SwiftUI

struct MeUsView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text(appState.experienceType.isCoupleAccount ? "MeUsView" : "MeView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Solo") {
    let state = AppState()
    state.experienceType = .soloSingle
    return MeUsView().environment(state)
}

#Preview("Couple") {
    let state = AppState()
    state.experienceType = .coupleNew
    return MeUsView().environment(state)
}
