//
//  ScoreRing.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 110
    var lineWidth: CGFloat = 9

    @State private var progress: CGFloat = 0

    // Spectrum sweep: cyan → purple → magenta → cyan (full arc).
    // Built from AppColors spectrum tokens — no legacy theme env.
    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: [
                AppColors.spectrumCyan,
                AppColors.spectrumPurple,
                AppColors.spectrumMagenta,
                AppColors.spectrumCyan,
            ],
            center: .center
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppColors.borderSubtle,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: AppSpacing.xxs) {
                Text(score, format: .number)
                    .font(.system(
                        size: size > 80 ? 28 : 16,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(AppColors.textPrimary)

                if size > 80 {
                    Text("OF 100")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(AppAnimation.slow) { // was 1.2 — above slow ceiling, nearest token {
                progress = CGFloat(score) / 100.0
            }
        }
    }
}

