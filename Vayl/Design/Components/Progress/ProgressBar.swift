//
//  ProgressBar.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct ProgressBar: View {
    let value: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.borderSubtle)

                Capsule()
                    .fill(AppColors.spectrumBorder)
                    .frame(width: geo.size.width * (value / max))
                    .animation(AppAnimation.slow, value: value)
            }
        }
        .frame(height: 4)
    }
}
