// Design/Components/Effects/SectionHairline.swift
//
// A thin single-color hairline (clear → color → clear) for Learn-section
// colour-coding: cyan = quizzes, purple = research, magenta = content hub.
// (The existing SpectrumHairline is always the full cyan→purple→magenta gradient.)

import SwiftUI

struct SectionHairline: View {
    let color: Color
    var thickness: CGFloat = 1.5

    var body: some View {
        LinearGradient(
            colors: [.clear, color.opacity(0.9), color, color.opacity(0.9), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: thickness)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            SectionHairline(color: AppColors.spectrumCyan)
            SectionHairline(color: AppColors.spectrumPurple)
            SectionHairline(color: AppColors.spectrumMagenta)
        }
        .padding()
    }
}
