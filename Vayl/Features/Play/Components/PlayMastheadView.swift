//
//  PlayMastheadView.swift
//  Vayl — Play
//
//  The tab's world identity: a "Cards" editorial masthead (Clash spectrum
//  wordmark + a short spectrum underline), left-aligned and island-safe (it
//  sits below the safe area, never crowding the Dynamic Island). Purely
//  presentational. The `PlayMode` engine + `simulatorEnabled` gate stay in the
//  store, so the Simulator world drops back in beside this post-launch with no
//  rework: we are hiding the switch, not deleting the engine.
//

import SwiftUI

struct PlayMastheadView: View {
    var body: some View {
        // Consistent header treatment across tabs: gradient wordmark + period
        // (no underline bar). "Cards" stays — future-proof for more game types.
        Text("Cards.")
            .font(AppFonts.display(40, weight: .bold, relativeTo: .largeTitle))
            .foregroundStyle(AppColors.spectrumText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("Play masthead") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PlayMastheadView()
            .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif
