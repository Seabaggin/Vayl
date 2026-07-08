// Design/Components/Buttons/SelectablePill.swift
// Open Lightly
//
// Dark-only (V1): surfaceBg fill + HolographicShimmer + flame aura + spectrum shadows

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
    /// true (default) = the pill fills its row (a vertical list of full-width options).
    /// Set false for a horizontal row of pills (e.g. inside a ScrollView(.horizontal) +
    /// HStack) — multiple maxWidth: .infinity siblings competing for that axis's
    /// effectively-unbounded proposed width collapses/overlaps them.
    var fillWidth: Bool = true
    var action: () -> Void

    // ─────────────────────────────────────────────
    // MARK: Dark mode computed properties
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

    private var borderWidth: CGFloat {
        guard isSelected else { return 1.5 }
        switch intensity {
        case .dim:   return 1.5
        case .warm:  return 2.0
        case .alive: return 2.5
        }
    }

    private var borderColor: Color {
        guard isSelected else { return AppColors.borderSubtle }
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
                    isSelected: isSelected,
                    intensity: intensity
                ))
                .background(alignment: .bottom) {
                    flameLayer
                }
                .animation(AppAnimation.fast, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var pillContent: some View {
        Text(label)
            // AppFonts.body replaces .system(size:weight:) —
            // scales correctly with Dynamic Type via relativeTo: .body.
            .font(AppFonts.body(fontSize, weight: .medium, relativeTo: .body))
            // textPrimary, not raw Color.white — token-compliant, and this IS the
            // label the user needs to read/tap, not subtext, so it stays full
            // brightness whether the pill is selected or not.
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, fillWidth ? 0 : AppSpacing.md)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .frame(height: height)
            // Shimmer moved from .overlay (drawn ON TOP of the text, muting it toward
            // grey — HolographicShimmer's own root is an opaque fill, not a transparent
            // decoration) into .background (drawn BEHIND it), so the label always
            // renders crisp on top instead of blended under a semi-opaque texture layer.
            .background {
                AppColors.modalBackground
                HolographicShimmer(duration: shimmerSpeed)
                    .opacity(shimmerOpacity)
                    .allowsHitTesting(false)
            }
            .clipShape(Capsule())
            .modifier(PillBorderModifier(
                isSelected: isSelected,
                darkBorderColor: borderColor,
                darkBorderWidth: borderWidth
            ))
    }

    @ViewBuilder
    private var flameLayer: some View {
        if isSelected && intensity != .dim && showFlame {
            GeometryReader { geo in
                FlameAura(intensity: intensity)
                    .frame(
                        width: geo.size.width * 1.2,
                        height: flameFrameHeight
                    )
                    .position(
                        x: geo.size.width  / 2,
                        y: geo.size.height - flameFrameHeight / 2
                    )
            }
            .frame(height: flameFrameHeight)
            .allowsHitTesting(false)
            .transition(.opacity.animation(AppAnimation.enter))
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────

    private func glowColor(
        _ base: Color,
        _ dimAlpha: CGFloat,
        _ warmAlpha: CGFloat,
        _ aliveAlpha: CGFloat
    ) -> Color {
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
// ─────────────────────────────────────────────

private struct PillBorderModifier: ViewModifier {
    let isSelected: Bool
    let darkBorderColor: Color
    let darkBorderWidth: CGFloat

    func body(content: Content) -> some View {
        if isSelected {
            content.pillBorder(
                cornerRadius: AppRadius.pill,
                lineWidth: darkBorderWidth,
                glowRadius: 5,
                opacity: 0.85
            )
        } else {
            content.overlay(
                Capsule().strokeBorder(darkBorderColor, lineWidth: darkBorderWidth)
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillShadowModifier
// ─────────────────────────────────────────────

private struct PillShadowModifier: ViewModifier {
    let isSelected: Bool
    let intensity: SelectablePill.Intensity

    func body(content: Content) -> some View {
        content
            .shadow(color: isSelected ? glowColor(AppColors.accentSecondary, 0.20, 0.25, 0.34) : .clear,
                    radius: pick(6, 12, 14))
            .shadow(color: isSelected ? glowColor(AppColors.accentPrimary, 0.0, 0.15, 0.30) : .clear,
                    radius: pick(0, 16, 28))
            .shadow(color: isSelected ? glowColor(AppColors.accentTertiary, 0.0, 0.08, 0.25) : .clear,
                    radius: pick(0, 8, 45))
            .shadow(color: isSelected ? glowColor(AppColors.accentTertiary, 0.0, 0.0, 0.12) : .clear,
                    radius: pick(0, 0, 70))
    }

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
    VStack(spacing: AppSpacing.md) {
        SelectablePill(label: "She/Her", isSelected: true, intensity: .alive) { }
        SelectablePill(label: "He/Him", isSelected: false, intensity: .warm) { }
        SelectablePill(label: "They/Them", isSelected: true, intensity: .warm) { }
        SelectablePill(label: "Curious", isSelected: true, intensity: .dim) { }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VStack(spacing: AppSpacing.md) {
        SelectablePill(label: "She/Her", isSelected: true, intensity: .alive) { }
        SelectablePill(label: "He/Him", isSelected: false, intensity: .warm) { }
        SelectablePill(label: "They/Them", isSelected: true, intensity: .warm) { }
        SelectablePill(label: "Curious", isSelected: true, intensity: .dim) { }
    }
    .padding(AppSpacing.lg)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}
