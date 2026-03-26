// Features/More/MoreView.swift
// Open Lightly
//
// Settings, account, support, and app-level actions.
// Also serves as the only visible screen for browsing/guest users.
// Stub — full implementation in a future batch.

import SwiftUI

struct MoreView: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("MoreView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    return MoreView().environment(state)
}
