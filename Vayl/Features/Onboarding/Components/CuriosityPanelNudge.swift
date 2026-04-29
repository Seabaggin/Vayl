//
//  CuriosityPanelNudge.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPanelNudge.swift
//  Open Lightly
//
//  Contextual nudge shown below the status strip.
//  Guides the user toward completing both panels.
//

import SwiftUI

struct CuriosityPanelNudge: View {
    let s1Empty: Bool
    let s2Empty: Bool
    let isLight: Bool

    private var text: String? {
        if s1Empty && s2Empty  { return "Select from both panels to continue" }
        if !s1Empty && s2Empty { return "Swipe left — pick one more thing →" }
        if s1Empty && !s2Empty { return "← Swipe back — pick one thing there too" }
        return nil
    }

    var body: some View {
        ZStack {
            if let nudge = text {
                Text(nudge)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightCardTitle.opacity(0.35)
                            : AppColors.textTertiary
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .offset(y: 4)))
                    .id(nudge)
            }
        }
        .frame(height: 22)
        .animation(.easeOut(duration: 0.3), value: text)
        .padding(.bottom, 4)
    }
}

#Preview("Dark — s1 done") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityPanelNudge(s1Empty: false, s2Empty: true, isLight: false)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — both empty") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityPanelNudge(s1Empty: true, s2Empty: true, isLight: true)
    }
    .preferredColorScheme(.light)
}