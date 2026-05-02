import SwiftUI

// ─────────────────────────────────────────────
// MARK: Border Glow Tier
//
// Semantic intensity scale for all three border modifiers.
// Pass `tier:` to override explicit lineWidth/glowRadius/opacity
// as a set. When nil, the explicit parameters are used as-is,
// so all existing call sites remain unchanged.
//
// Usage:
//   .pillBorder(tier: .structural)   // ambient card borders
//   .pillBorder(tier: .interactive)  // selected pills, active states
//   .pillBorder(tier: .primary)      // CTA buttons, conversion moments
// ─────────────────────────────────────────────

enum BorderGlowTier {
    case structural   // ambient card borders, always visible
    case interactive  // selected pills, floating cards, active states
    case primary      // CTA buttons, conversion moments

    var lineWidth: CGFloat {
        switch self {
        case .structural:  return 1.5
        case .interactive: return 2.0
        case .primary:     return 2.5
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .structural:  return 3
        case .interactive: return 6
        case .primary:     return 10
        }
    }

    var opacity: Double {
        switch self {
        case .structural:  return 0.45
        case .interactive: return 0.75
        case .primary:     return 0.90
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Dark Mode — Spectrum Pill Border
// Unchanged. Used on all dark mode selected/active states.
// cyan → purple → magenta, topLeading → bottomTrailing
// ─────────────────────────────────────────────

/// Shared holographic pill border — single source of truth.
struct PillBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 3
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.8
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth  = tier?.lineWidth  ?? lineWidth
        let activeGlowRadius = tier?.glowRadius ?? glowRadius
        let activeOpacity    = tier?.opacity    ?? opacity

        let gradient = LinearGradient(
            colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: activeLineWidth + 1)
                    .blur(radius: activeGlowRadius)
                    .opacity(0.35)
            )
            .shadow(color: AppColors.accentSecondary.opacity(0.18), radius: 6)
            .shadow(color: AppColors.accentPrimary.opacity(0.08),   radius: 12)
            .shadow(color: AppColors.accentSecondary.opacity(0.06), radius: 16)
    }
}

extension View {
    func pillBorder(
        cornerRadius: CGFloat    = 100,
        lineWidth: CGFloat       = 3,
        glowRadius: CGFloat      = 6,
        opacity: Double          = 0.8,
        tier: BorderGlowTier?    = nil
    ) -> some View {
        modifier(PillBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity,
            tier: tier
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Warm Aurora Border
//
// Used on ALL light mode selected/active states.
// Replaces .pillBorder() when colorScheme == .light.
//
// Gradient: AppColors.spectrumBorder
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
//   .warmAuroraBorder(cornerRadius: AppRadius.container)         // rounded rect cards
//   .warmAuroraBorder(lineWidth: 3, opacity: 0.95) // CTA buttons
// ─────────────────────────────────────────────

struct WarmAuroraBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var opacity: Double       = 0.82
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth = tier?.lineWidth ?? lineWidth
        let activeOpacity   = tier?.opacity   ?? opacity

        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            .shadow(color: AppColors.shadowMagenta, radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.shadowPurple,  radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.shadowGold,    radius: 6,  x: 0, y: 2)
    }
}

extension View {
    func warmAuroraBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        opacity: Double       = 0.82,
        tier: BorderGlowTier? = nil
    ) -> some View {
        modifier(WarmAuroraBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            opacity: opacity,
            tier: tier
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
//   .magentaGoldBorder(cornerRadius: AppRadius.container)          // rounded rect cards
//   .magentaGoldBorder(lineWidth: 3, opacity: 0.90) // CTA weight
// ─────────────────────────────────────────────

private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.accentTertiary,    location: 0.00),
        .init(color: AppColors.progressBarLeading,  location: 0.55), // VQ-08: extended pink zone
        .init(color: AppColors.safetyAccent,       location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

struct MagentaGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.82
    var tier: BorderGlowTier? = nil

    func body(content: Content) -> some View {
        let activeLineWidth  = tier?.lineWidth  ?? lineWidth
        let activeGlowRadius = tier?.glowRadius ?? glowRadius
        let activeOpacity    = tier?.opacity    ?? opacity

        return content
            // Crisp gradient stroke
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: activeLineWidth)
                    .opacity(activeOpacity)
            )
            // Blurred duplicate — mirrors PillBorder glow overlay pattern.
            // Visible on cream because the gradient is warm and saturated.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: activeLineWidth + 1)
                    .blur(radius: activeGlowRadius)
                    .opacity(0.35)
            )
            // Shadow spread — three layers, same pattern as WarmAuroraBorder.
            // Magenta: tight warm halo. OrangeHot: mid warmth. Gold: wide soft glow.
            .shadow(color: AppColors.accentTertiary.opacity(0.18),   radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.progressBarLeading.opacity(0.12), radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.safetyAccent.opacity(0.08),      radius: 6,  x: 0, y: 2)
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
    ///   - tier: Optional semantic tier — overrides lineWidth, glowRadius, opacity as a set.
    func magentaGoldBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        glowRadius: CGFloat   = 6,
        opacity: Double       = 0.82,
        tier: BorderGlowTier? = nil
    ) -> some View {
        modifier(MagentaGoldBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity,
            tier: tier
        ))
    }
}
