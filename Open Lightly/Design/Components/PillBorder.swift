import SwiftUI

// ─────────────────────────────────────────────
// MARK: Dark Mode — Spectrum Pill Border
// Unchanged. Used on all dark mode selected/active states.
// cyan → purple → magenta, topLeading → bottomTrailing
// ─────────────────────────────────────────────

/// Shared holographic pill border — single source of truth.
struct PillBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat = 3
    var glowRadius: CGFloat = 6
    var opacity: Double = 0.8

    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth + 1)
                    .blur(radius: glowRadius)
                    .opacity(0.35)
            )
            .shadow(color: AppColors.purple.opacity(0.18), radius: 6)
            .shadow(color: AppColors.cyan.opacity(0.08),   radius: 12)
            .shadow(color: AppColors.purple.opacity(0.06), radius: 16)
    }
}

extension View {
    func pillBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat = 3,
        glowRadius: CGFloat = 6,
        opacity: Double = 0.8
    ) -> some View {
        modifier(PillBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Warm Aurora Border
//
// Used on ALL light mode selected/active states.
// Replaces .pillBorder() when colorScheme == .light.
//
// Gradient: AppColors.warmAuroraBorder
//   purple → magenta → gold, topLeading → bottomTrailing
//
// Key differences from dark PillBorder:
//   - No blur overlay — blur is invisible on cream, adds muddiness
//   - Shadows replaced with colored spread (shadow IS the glow on light)
//   - Default lineWidth 2.5 vs 3 — slightly finer on cream reads better
//   - Default opacity 0.82 — higher than dark because no glow canvas to boost it
//
// Usage:
//   .warmAuroraBorder()                         // pills, fields, cards
//   .warmAuroraBorder(cornerRadius: 20)         // rounded rect cards
//   .warmAuroraBorder(lineWidth: 3, opacity: 0.95) // CTA buttons
// ─────────────────────────────────────────────

struct WarmAuroraBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var opacity: Double       = 0.82

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
    }
}

extension View {
    func warmAuroraBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        opacity: Double       = 0.82
    ) -> some View {
        modifier(WarmAuroraBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            opacity: opacity
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Magenta Gold Border
//
// Used on light mode pill selected states and LivingText
// contexts where the magentaGold palette is active.
//
// Gradient: magenta → orangeHot → gold
//   #FF006A 0% → #E07020 55% → #C8960A 100%
//   topLeading → bottomTrailing
//
// The 0.55 mid-stop extends the hot pink longer before
// amber arrives — mirrors the VQ-08 principle from the
// progress bar fill gradient.
//
// Glow pattern mirrors PillBorder exactly:
//   - Crisp stroke overlay at `opacity`
//   - Blurred duplicate at lineWidth+1, blur glowRadius, opacity 0.35
//     (same structure as dark PillBorder blur overlay)
//   - Three shadow spread layers: magenta tight, orangeHot mid, gold wide
//
// Usage:
//   .magentaGoldBorder()                          // pills — default
//   .magentaGoldBorder(cornerRadius: 20)          // rounded rect cards
//   .magentaGoldBorder(lineWidth: 3, opacity: 0.90) // CTA weight
// ─────────────────────────────────────────────

private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,    location: 0.00),
        .init(color: AppColors.orangeHot,  location: 0.55), // VQ-08: extended pink zone
        .init(color: AppColors.gold,       location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

struct MagentaGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.82

    func body(content: Content) -> some View {
        content
            // Crisp gradient stroke
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            // Blurred duplicate — mirrors PillBorder glow overlay pattern.
            // Visible on cream because the gradient is warm and saturated.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: lineWidth + 1)
                    .blur(radius: glowRadius)
                    .opacity(0.35)
            )
            // Shadow spread — three layers, same pattern as WarmAuroraBorder.
            // Magenta: tight warm halo. OrangeHot: mid warmth. Gold: wide soft glow.
            .shadow(color: AppColors.magenta.opacity(0.18),   radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.orangeHot.opacity(0.12), radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.gold.opacity(0.08),      radius: 6,  x: 0, y: 2)
    }
}

extension View {
    /// Light mode magenta → amber → gold border.
    /// Use on pill selected states that pair with the magentaGold
    /// LivingText palette, and anywhere the warm ember identity
    /// is stronger than the purple aurora identity.
    ///
    /// - Parameters:
    ///   - cornerRadius: Match the shape. Default 100 (pill).
    ///   - lineWidth: Default 2.5. Use 3.0 for CTA weight.
    ///   - glowRadius: Default 6. Blur radius of the glow duplicate overlay.
    ///   - opacity: Default 0.82. Use 0.90 for CTA. Use 0.65 for resting borders.
    func magentaGoldBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        glowRadius: CGFloat   = 6,
        opacity: Double       = 0.82
    ) -> some View {
        modifier(MagentaGoldBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}
