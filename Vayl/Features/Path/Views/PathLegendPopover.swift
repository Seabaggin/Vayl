//
//  PathLegendPopover.swift
//  Vayl — Path
//
//  Trail mode's ⚷ key — the five-state legend PathTrailView's own labels no
//  longer carry, now that they're name-only (spec §12). Read-only, no
//  interaction; PathScreen (Task 12) owns when it's shown.
//

import SwiftUI

struct PathLegendPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            legendRow("Untouched", style: AppColors.textSecondary)
            legendRow("Curious", style: AppColors.spectrumMagenta)
            legendRow("Discussed", style: AppColors.spectrumPurple)
            legendRow("Planning", style: AppColors.spectrumCyan)
            // "Did it" is a spectrum gradient everywhere else it renders
            // (PathTrailView.nodeView, PathLedgerView.stateDot) — the legend
            // swatch matches that identity rather than substituting a raw
            // .white, which isn't a token and doesn't exist as one in
            // AppColors.
            legendRow("Did it", style: AppColors.spectrumBorder)
        }
        .padding(AppSpacing.md)
    }

    private func legendRow<S: ShapeStyle>(_ title: String, style: S) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle().fill(style).frame(width: 10, height: 10)
            Text(title)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("PathLegendPopover") {
    PathLegendPopover()
        .background(AppColors.void.ignoresSafeArea())
}
#endif
