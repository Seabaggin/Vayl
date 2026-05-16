// Design/Components/Effects/PillBorder.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// Spectrum gradient border modifiers.
//
// Rules:
//   • pillBorder()        — dark-mode spectrum border (cyan → purple → magenta)
//                           adaptive: uses AppColors.spectrumBorder which is
//                           cyan→purple→magenta in Midnight, purple→magenta→gold
//                           in Dawn.
//   • magentaGoldBorder() — light-mode warm border (magenta → orangeHot → gold)
//                           Used on selected selectable pills and LM card borders.
//
//   Both modifiers apply a crisp stroke overlay + a blurred glow duplicate
//   at reduced opacity. The glow is clipped outward only — no interior bleed.
//
//   Parameters all have sensible defaults matching the design spec:
//     cornerRadius — matches the surface shape. Use AppRadius tokens.
//     lineWidth    — 1.0pt (subtle selected state)
//     glowRadius   — 5pt  (soft outward blur)
//     opacity      — 0.85 (dark) / 0.60 (light) per DESIGN_DOC
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - pillBorder

extension View {

    /// Spectrum gradient stroke border + soft outward glow.
    /// Midnight: cyan → purple → magenta.
    /// Dawn:     purple → magenta → gold (AppColors.spectrumBorder is adaptive).
    /// Use on selected/active states only — never on static non-interactive surfaces.
    func pillBorder(
        cornerRadius: CGFloat = AppRadius.pill,
        lineWidth:    CGFloat = 1.0,
        glowRadius:   CGFloat = 5,
        opacity:      Double  = 0.85
    ) -> some View {
        modifier(PillBorderModifier(
            gradient:     AppColors.spectrumBorder,
            cornerRadius: cornerRadius,
            lineWidth:    lineWidth,
            glowRadius:   glowRadius,
            opacity:      opacity
        ))
    }

    /// Warm gradient stroke border: magenta → orangeHot → gold.
    /// Dawn (light) mode selected-state border. Matches LM card border spec.
    /// Use on selected selectable pills and LM card bordered surfaces only.
    func magentaGoldBorder(
        cornerRadius: CGFloat = AppRadius.pill,
        lineWidth:    CGFloat = 1.0,
        glowRadius:   CGFloat = 5,
        opacity:      Double  = 0.60
    ) -> some View {
        modifier(PillBorderModifier(
            gradient: LinearGradient(
                colors: [
                    AppColors.spectrumMagenta,
                    // progressBarLeading resolves to orangeHot in Dawn —
                    // the warm mid-stop the spec calls for.
                    AppColors.progressBarLeading,
                    AppColors.safetyAccent,
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            ),
            cornerRadius: cornerRadius,
            lineWidth:    lineWidth,
            glowRadius:   glowRadius,
            opacity:      opacity
        ))
    }
}

// MARK: - PillBorderModifier

/// Shared implementation for pillBorder and magentaGoldBorder.
/// Applies a crisp gradient stroke + a blurred glow duplicate at reduced opacity.
private struct PillBorderModifier: ViewModifier {

    let gradient:     LinearGradient
    let cornerRadius: CGFloat
    let lineWidth:    CGFloat
    let glowRadius:   CGFloat
    let opacity:      Double

    func body(content: Content) -> some View {
        content
            .overlay(
                // Blurred glow duplicate — sits behind the crisp stroke.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth + 2)
                    .blur(radius: glowRadius)
                    .opacity(opacity * 0.55)
            )
            .overlay(
                // Crisp stroke on top.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
    }
}

// MARK: - Preview

#Preview("PillBorder modifiers") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.xl) {

            Text("Spectrum Border (Dark)")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .pillBorder()

            Text("Spectrum Border (custom width)")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .pillBorder(lineWidth: 1.5, glowRadius: 8)

            Text("Magenta Gold Border")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .magentaGoldBorder()

            Text("Rounded Rect (xl)")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .pillBorder(cornerRadius: AppRadius.xl, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        }
    }
    .preferredColorScheme(.dark)
}
