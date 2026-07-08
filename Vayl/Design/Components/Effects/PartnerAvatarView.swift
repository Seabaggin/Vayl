// Vayl/Design/Components/PartnerAvatarView.swift

import SwiftUI

/// The shared spectrum-gradient avatar circle used everywhere a partner's
/// initial needs to render — the Home partner chip, Settings' linked-partner
/// row, and the tap-to-expand quick view. One gradient definition, one place
/// to change it.
struct PartnerAvatarView: View {
    let initial: String
    var size: CGFloat = 20

    var body: some View {
        Circle()
            .fill(AppColors.cardBg)
            .overlay(
                Circle().strokeBorder(AppColors.spectrumBorder, lineWidth: 1.5)
            )
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            )
    }
}

// MARK: - Previews

#Preview("Dark — Sizes") {
    HStack(spacing: AppSpacing.md) {
        PartnerAvatarView(initial: "A", size: 20)
        PartnerAvatarView(initial: "A", size: 22)
        PartnerAvatarView(initial: "A", size: 32)
    }
    .padding()
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}
