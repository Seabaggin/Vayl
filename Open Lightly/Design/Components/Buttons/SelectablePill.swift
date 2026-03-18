// Design/Components/Buttons/SelectablePill.swift

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
    var action: () -> Void

    private var shimmerOpacity: CGFloat {
        guard isSelected else { return 0 }
        switch intensity {
        case .dim:   return 0.55
        case .warm:  return 0.72
        case .alive: return 0.85
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

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(AppColors.surfaceBg)
                .overlay {
                    HolographicShimmer(duration: shimmerSpeed)
                        .opacity(shimmerOpacity)
                        .allowsHitTesting(false)
                }
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(borderColor, lineWidth: borderWidth)
                )
                // Flame aura — overlay, not ZStack, so zero layout impact
                .overlay(alignment: .bottom) {
                    if isSelected && intensity != .dim {
                        GeometryReader { geo in
                            FlameAura(intensity: intensity)
                                .frame(
                                    width: geo.size.width * 1.2,
                                    height: flameFrameHeight
                                )
                                .position(
                                    x: geo.size.width / 2,
                                    y: geo.size.height - flameFrameHeight / 2
                                )
                        }
                        .allowsHitTesting(false)
                    }
                }
                .shadow(color: isSelected ? glowColor(AppColors.purple, 0.20, 0.25, 0.34) : .clear,
                        radius: pick(6, 12, 14))
                .shadow(color: isSelected ? glowColor(AppColors.cyan, 0.0, 0.15, 0.30) : .clear,
                        radius: pick(0, 16, 28))
                .shadow(color: isSelected ? glowColor(AppColors.magenta, 0.0, 0.08, 0.25) : .clear,
                        radius: pick(0, 8, 45))
                .shadow(color: isSelected ? glowColor(AppColors.pink, 0.0, 0.0, 0.12) : .clear,
                        radius: pick(0, 0, 70))
        }
        .buttonStyle(.plain)
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
