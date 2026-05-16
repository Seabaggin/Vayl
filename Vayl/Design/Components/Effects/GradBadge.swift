// Design/Components/Effects/GradBadge.swift

import SwiftUI

/// Small capsule pill with a spectrum gradient border and a text label inside.
/// Use for metadata counts, status tags, and category chips — never for CTAs.
///
/// Gradient border: AppColors.spectrumBorder (adaptive — spectrum in dark, aurora in light).
/// Label font:  AppFonts.label
/// Label color: AppColors.textSecondary
struct GradBadge: View {

    let text: String

    var body: some View {
        Text(text)
            .font(AppFonts.label)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground.opacity(0.60))
            )
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            GradBadge(text: "3/8")
            GradBadge(text: "Ready with Awareness")
            GradBadge(text: "12/12")
        }
    }
    .preferredColorScheme(.dark)
}
