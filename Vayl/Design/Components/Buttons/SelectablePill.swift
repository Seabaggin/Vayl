// Design/Components/Buttons/SelectablePill.swift
// Open Lightly
//
// Supports dark mode (spectrum glow + flame aura) and
// light mode (warm aurora border + shadow spread).
//
// Dark:  surfaceBg fill + HolographicShimmer + flame aura + spectrum shadows
// Light: lightFrostPill fill + LightModeShimmer + warmAuroraBorder + shadow spread
//        Flame aura skipped — glow is invisible on cream, shadow spread replaces it

import SwiftUI

struct SelectablePill: View {

    enum Intensity: CGFloat {
        case dim   = 0.15
        case warm  = 0.5
        case alive = 1.0
    }

    let label: String
    let isSelected: Bool
    var intensity: Intensity = .warm
    var height: CGFloat = 46
    var fontSize: CGFloat = 15
    var showFlame: Bool = true
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // ─────────────────────────────────────────────
    // MARK: Dark mode computed properties — unchanged
    // ─────────────────────────────────────────────

    private var shimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.22
            case .warm:  return 0.38
            case .alive: return 0.46
            }
        }
    }

    private var shimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6
        case .warm:  return 4
        case .alive: return 3.5
        }
    }
    
    private var lightShimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6.0
        case .warm:  return 4.0
        case .alive: return 3.5
        }
    }

    private var borderWidth: CGFloat {
        guard isSelected else { return 1.5 }
        switch intensity {
        case .dim:   return 1.5
        case .warm:  return 2.0
        case .alive: return 2.5
        }
    }

    private var borderColor: Color {
        guard isSelected else { return AppColors.borderHover }
        switch intensity {
        case .dim:   return Color.white.opacity(0.12)
        case .warm:  return Color.white.opacity(0.22)
        case .alive: return Color.white.opacity(0.25)
        }
    }

    private var flameFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 90
        case .alive: return 120
        }
    }

    private var lightBloomFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Light mode computed properties
    // ─────────────────────────────────────────────
    private var lightShimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.10
            case .warm:  return 0.16
            case .alive: return 0.22
            }
        }
    }

    /// Light mode border opacity — higher than dark because no glow
    /// canvas to boost the visual weight of the border.
    private var lightBorderOpacity: Double {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.78
            case .alive: return 0.90
            }
        } else {
            return 0.40
        }
    }

    /// Light mode border line width — matches warmAuroraBorder defaults.
    private var lightBorderWidth: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 1.5
            case .warm:  return 2.5
            case .alive: return 3.0
            }
        } else {
            return 1.5
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Body
    // ─────────────────────────────────────────────

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            pillContent
                .modifier(PillShadowModifier(
                    isLight: isLight,
                    isSelected: isSelected,
                    intensity: intensity
                ))
                .background(alignment: .bottom) {
                    flameLayer
                }
                .offset(y: isLight && isSelected ? -1 : 0)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var pillContent: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(isLight ? AppColors.lightBodyWineDark : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isLight
                ? (isSelected
                    ? AppColors.lightFrostPillSel
                    : AppColors.lightFrostPill)   // FIX: was lightSurfaceBg (#F2EFE6)
                                                   // which is near-identical to lightPageBg.
                                                   // lightFrostPill is visibly lavender-tinted
                                                   // so the shimmer has a tinted base to sweep
                                                   // over — same role surfaceBg plays in dark.
                : AppColors.surfaceBg)
            .overlay {
                if isLight {
                    LightModeShimmer(duration: lightShimmerSpeed, usePillColors: true)
                        .opacity(lightShimmerOpacity)
                        .allowsHitTesting(false)
                } else {
                    HolographicShimmer(duration: shimmerSpeed)
                        .opacity(shimmerOpacity)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(Capsule())
            .modifier(PillBorderModifier(
                isLight: isLight,
                isSelected: isSelected,
                darkBorderColor: borderColor,
                darkBorderWidth: borderWidth,
                lightBorderOpacity: lightBorderOpacity,
                lightBorderWidth: lightBorderWidth
            ))
    }

    @ViewBuilder
    private var flameLayer: some View {
        if isSelected && intensity != .dim && showFlame {
            GeometryReader { geo in
                if isLight {
                    LightAuraBloom(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.15,
                            height: lightBloomFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - lightBloomFrameHeight / 2
                        )
                } else {
                    FlameAura(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.2,
                            height: flameFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - flameFrameHeight / 2
                        )
                }
            }
            .frame(height: isLight ? lightBloomFrameHeight : flameFrameHeight)
            .allowsHitTesting(false)
            .transition(.opacity.animation(.easeIn(duration: 0.4)))
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Helpers — unchanged from original
    // ─────────────────────────────────────────────

    private var labelColor: Color {
        if isLight {
            return AppColors.lightBodyWineDark   // selected and unselected both deep wine on cream
        } else {
            return .white
        }
    }

    private func glowColor(_ base: Color, _ dimAlpha: CGFloat, _ warmAlpha: CGFloat, _ aliveAlpha: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(dimAlpha)
        case .warm:  return base.opacity(warmAlpha)
        case .alive: return base.opacity(aliveAlpha)
        }
    }

    private func pick(_ dim: CGFloat, _ warm: CGFloat, _ alive: CGFloat) -> CGFloat {
        switch intensity {
        case .dim:   return dim
        case .warm:  return warm
        case .alive: return alive
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillBorderModifier
// Handles the dark/light border split cleanly
// without .if() helper to avoid redeclaration.
// ─────────────────────────────────────────────

private struct PillBorderModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let darkBorderColor: Color
    let darkBorderWidth: CGFloat
    let lightBorderOpacity: Double
    let lightBorderWidth: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            if isSelected {
                // Selected light — magenta-gold gradient border
                content
                    .magentaGoldBorder(
                        cornerRadius: 100,
                        lineWidth: lightBorderWidth,
                        glowRadius: 6,
                        opacity: lightBorderOpacity
                    )
            } else {
                content.overlay(
                    Capsule().strokeBorder(
                        AppColors.lightBorderHover,
                        lineWidth: 1.5
                    )
                )
            }
        } else {
            // Dark — spectrum pillBorder when selected; subtle plain stroke when not
            if isSelected {
                content.pillBorder(cornerRadius: 100, lineWidth: darkBorderWidth, glowRadius: 5, opacity: 0.85)
            } else {
                content.overlay(
                    Capsule().strokeBorder(darkBorderColor, lineWidth: darkBorderWidth)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillShadowModifier
// Dark: spectrum glow ring
// Light: warm aurora shadow spread
// ─────────────────────────────────────────────

private struct PillShadowModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let intensity: SelectablePill.Intensity

    func body(content: Content) -> some View {
        if isLight {
            // Shadow spread — opacity scales with intensity
            let base: Double = isSelected ? 1.0 : 0.0
            content
                .shadow(color: AppColors.lightShadowMagenta.opacity(base * magentaScale),
                        radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple.opacity(base * purpleScale),
                        radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold.opacity(base * goldScale),
                        radius: 6,  x: 0, y: 2)
        } else {
            // Dark — original spectrum glow ring, unchanged
            content
                .shadow(color: isSelected ? glowColor(AppColors.purple,  0.20, 0.25, 0.34) : .clear,
                        radius: pick(6,  12, 14))
                .shadow(color: isSelected ? glowColor(AppColors.cyan,    0.0,  0.15, 0.30) : .clear,
                        radius: pick(0,  16, 28))
                .shadow(color: isSelected ? glowColor(AppColors.magenta, 0.0,  0.08, 0.25) : .clear,
                        radius: pick(0,  8,  45))
                .shadow(color: isSelected ? glowColor(AppColors.pink,    0.0,  0.0,  0.12) : .clear,
                        radius: pick(0,  0,  70))
        }
    }

    // Light shadow intensity scales with pill intensity
    private var magentaScale: Double {
        switch intensity { case .dim: return 0.5; case .warm: return 0.9; case .alive: return 1.0 }
    }
    private var purpleScale: Double {
        switch intensity { case .dim: return 0.4; case .warm: return 0.8; case .alive: return 1.0 }
    }
    private var goldScale: Double {
        switch intensity { case .dim: return 0.3; case .warm: return 0.7; case .alive: return 1.0 }
    }

    // Helpers mirror the original SelectablePill private functions
    private func glowColor(_ base: Color, _ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(d)
        case .warm:  return base.opacity(w)
        case .alive: return base.opacity(a)
        }
    }
    private func pick(_ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> CGFloat {
        switch intensity { case .dim: return d; case .warm: return w; case .alive: return a }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Dark") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}
