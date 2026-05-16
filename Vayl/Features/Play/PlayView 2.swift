//
//  PlayView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Play/PlayView.swift
// Open Lightly

import SwiftUI

struct PlayView: View {
    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            Text("Play")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
