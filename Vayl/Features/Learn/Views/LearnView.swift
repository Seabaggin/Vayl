//
//  LearnView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Learn/LearnView.swift
// Open Lightly

import SwiftUI

struct LearnView: View {
    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            Text("Learn")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
