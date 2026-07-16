//
//  ContextKickerView.swift
//  Vayl
//
//  Persistent context header for banner-type context_beat_copy (design spec
//  docs/superpowers/specs/2026-07-07-context-beat-header-design.md). Sits
//  glued directly above the question inside SessionPlayerView's centered
//  band. No dismiss affordance, no timer — visible for as long as its card
//  is current, and fades with the rest of screenLayer's existing dealing
//  animation (no independent wiring needed).
//

import SwiftUI

struct ContextKickerView: View {

    let copy: String

    var body: some View {
        Text(copy)
            .font(AppFonts.caption)
            .italic()
            .foregroundStyle(AppColors.textTertiary)
            .padding(.leading, AppSpacing.sm)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.spectrumPurple.opacity(0.5))
                    .frame(width: 2)
            }
    }
}

// MARK: - Preview

#Preview("Context Kicker") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ContextKickerView(copy: "Jealousy has a memory. It's older than the two of you.")
            .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.dark)
}
