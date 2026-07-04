//
//  SpectrumBulletRow.swift
//  Vayl
//
//  A labeled row marked by a FLAT spectrum disc with a holographic specular sweep — a band of
//  light that crosses the disc periodically (the moving light-catch from StatPhase's "1 in 5",
//  flattened onto a disc: no spherical highlight). NOT a checkmark — the disc is a neutral list
//  marker, so a list reads as "here's what this is for," possibilities you'll work toward, not a
//  checklist of guaranteed deliverables (a checkmark would over-promise: the app gives the
//  framework, the couple still does the work).
//
//  `Color.white` here is a specular rendering constant (as in StatPhase), not a semantic color.
//  The sweep is gated off under Reduce Motion. Pass `phaseOffset` (by index) so a list of rows
//  doesn't sweep in lockstep.
//

import SwiftUI

struct SpectrumBulletRow: View {

    let text: String
    /// Per-row delay (set by index) so the light cascades DOWN the list — the first bullet sweeps,
    /// then the next, and so on. Higher value = later.
    var phaseOffset: Double = 0
    /// The label font (default body-medium; consumers can size it up, e.g. the paywall).
    var font: Font = AppFonts.bodyMedium

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            orb
            Text(text)
                .font(font)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var orb: some View {
        Circle()
            .fill(AppColors.spectrumBorder)
            .frame(width: 22, height: 22)
            .overlay {
                if !reduceMotion && !AppAnimation.lowPower {
                    // 30fps cap — one of these mounts per bullet row (the
                    // paywall renders several); a slow specular sweep never
                    // needs display rate.
                    TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                        specularSweep(at: tl.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
            .clipShape(Circle())
            .spectrumBorderGlow(intensity: 0.6)
            .accessibilityHidden(true)   // decorative marker; the row's text carries the label
    }

    /// A diagonal white band that sweeps across the disc once per cycle, then parks off-screen
    /// for the remainder (a periodic light-catch, not a constant shimmer). Geometry values are
    /// specular rendering physics — not design tokens.
    private func specularSweep(at t: TimeInterval) -> some View {
        let cycle = AppAnimation.ambientDrift                                  // ~4s, token
        let raw = (t / cycle) - phaseOffset                                    // subtract → later rows sweep later
        let phase = raw - raw.rounded(.down)                                   // normalize to [0, 1) → cascades down
        let progress = min(1.0, phase / 0.40)                                  // band crosses in first 40%
        let sweepX = CGFloat(26 - progress * 52)                              // off-right → off-left

        return LinearGradient(
            stops: [
                .init(color: .clear,                   location: 0.00),
                .init(color: Color.white.opacity(0.0), location: 0.40),
                .init(color: Color.white.opacity(0.5), location: 0.50),
                .init(color: Color.white.opacity(0.0), location: 0.60),
                .init(color: .clear,                   location: 1.00),
            ],
            startPoint: UnitPoint(x: -0.1, y: 1.0),
            endPoint:   UnitPoint(x: 1.1, y: -0.25)
        )
        .frame(width: 52)
        .offset(x: sweepX)
        .blendMode(.plusLighter)
    }
}

#if DEBUG
#Preview("Spectrum bullet rows") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Explore with less guesswork")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.bottom, AppSpacing.xs)

            let lines = [
                "Understand what you each want",
                "Talk openly about sex, boundaries, and what-ifs",
                "Open up at a pace you both set",
                "Keep your agreements clear and honored",
            ]
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                SpectrumBulletRow(text: line, phaseOffset: Double(i) * 0.22)
            }
        }
        .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.dark)
}
#endif
