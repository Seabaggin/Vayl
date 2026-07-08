// Design/Components/SpectrumHairline.swift

import SwiftUI

/// Thin cyan→purple→magenta gradient line that fades at both ends — the app's
/// hairline accent (mirrors VaylBorderEffect's tapered hairline at section
/// scale). Used by the CredentialEditorSheet header and the FounderLetterSheet
/// chrome so both on-brand sheets share one accent.
struct SpectrumHairline: View {
    var body: some View {
        LinearGradient(
            colors: [
                .clear,
                AppColors.spectrumCyan.opacity(0.9),
                AppColors.spectrumPurple,
                AppColors.spectrumMagenta.opacity(0.9),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1.5)
        .frame(maxWidth: .infinity)
    }
}

/// The CTA border-hairline taper: a lens/spindle that is thickest at the centre
/// and tapers to sharp POINTS at both ends (a shape taper, not just a colour
/// fade), filled with the spectrum gradient. Mirrors VaylBorderEffect's
/// `TaperedHairlineShape`. Used as the OB sheet top-edge accent.
struct TaperedSpectrumHairline: View {
    /// Peak thickness at the centre.
    var thickness: CGFloat = 2.5
    /// Fraction of the width over which each end tapers to a point.
    var taperFraction: CGFloat = 0.16

    var body: some View {
        TaperedHairlineShape(taperFraction: taperFraction)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        AppColors.spectrumCyan.opacity(0.9),
                        AppColors.spectrumPurple,
                        AppColors.spectrumMagenta.opacity(0.9),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: thickness)
            .frame(maxWidth: .infinity)
    }
}

/// Lens shape — same geometry as the CTA's tapered hairline: thick at centre,
/// curving to a point `taperFraction` of the width in from each end.
private struct TaperedHairlineShape: Shape {
    var taperFraction: CGFloat = 0.16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let taperEnd = w * taperFraction
        let cp       = w * (taperFraction / 2)   // keeps the tip sharp

        // Upper arc: left tip → right tip
        path.move(to: CGPoint(x: taperEnd, y: h / 2))
        path.addCurve(
            to: CGPoint(x: w - taperEnd, y: h / 2),
            control1: CGPoint(x: taperEnd + cp, y: 0),
            control2: CGPoint(x: w - taperEnd - cp, y: 0)
        )
        // Lower arc: right tip → left tip
        path.addCurve(
            to: CGPoint(x: taperEnd, y: h / 2),
            control1: CGPoint(x: w - taperEnd - cp, y: h),
            control2: CGPoint(x: taperEnd + cp, y: h)
        )
        path.closeSubpath()
        return path
    }
}
