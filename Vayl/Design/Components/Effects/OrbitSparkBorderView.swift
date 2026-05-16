//
//  OrbitSparkBorderView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/24/26.
//


//
//  OrbitSparkBorderView.swift
//  Open Lightly
//

import SwiftUI

struct OrbitSparkBorderView: View {

    let size:         CGSize
    let cornerRadius: CGFloat
    let borderWidth:  CGFloat
    let colorScheme:  ColorScheme

    @State private var startDate = Date()

    private var borderGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading,
                endPoint: .trailing
              )
            : AppColors.spectrumBorder   // purple → magenta → gold
    }

    // NEW: tells the Metal shader which palette to use
    private var colorMode: Float {
        colorScheme == .dark ? 0.0 : 1.0
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderGradient, lineWidth: borderWidth)
                .colorEffect(
                    ShaderLibrary.orbitSpark(
                        .float2(size),
                        .float(elapsed),
                        .float(Float(borderWidth)),
                        .float(Float(cornerRadius)),
                        .float(colorMode)    // NEW argument
                    )
                )
                .frame(width: size.width, height: size.height)
        }
    }
}
