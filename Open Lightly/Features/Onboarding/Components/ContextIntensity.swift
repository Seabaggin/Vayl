import SwiftUI

/// Visual intensity levels mirroring the HTML design spec (ember → nova).
/// Controls background gradient, internal glow, border opacity, and external shadow.
enum ContextIntensity: Int {
    case ember   = 1
    case spark   = 2
    case flame   = 3
    case blaze   = 4
    case inferno = 5
    case nova    = 6

    // MARK: Background gradient tint (applied from bottom-trailing)
    var bgTintColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.04)
        case .flame:   return AppColors.cyan.opacity(0.06)
        case .blaze:   return AppColors.purple.opacity(0.08)
        case .inferno: return AppColors.magenta.opacity(0.06)
        case .nova:    return AppColors.magenta.opacity(0.10)
        }
    }

    /// Where the solid cardBg stops and the tint begins (gradient stop location)
    var bgTintStart: CGFloat {
        switch self {
        case .ember:   return 1.0   // no gradient
        case .spark:   return 0.70
        case .flame:   return 0.50
        case .blaze:   return 0.40
        case .inferno: return 0.30
        case .nova:    return 0.20
        }
    }

    // MARK: Spectrum border opacity
    var borderOpacity: Double {
        switch self {
        case .ember:   return 0.40
        case .spark:   return 0.50
        case .flame:   return 0.60
        case .blaze:   return 0.70
        case .inferno: return 0.80
        case .nova:    return 0.90
        }
    }

    // MARK: Internal top-right glow
    var internalGlowColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.10)
        case .flame:   return AppColors.purple.opacity(0.15)
        case .blaze:   return AppColors.purple.opacity(0.20)
        case .inferno: return AppColors.magenta.opacity(0.20)
        case .nova:    return AppColors.magenta.opacity(0.30)
        }
    }

    var internalGlowSize: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 100
        case .flame:   return 130
        case .blaze:   return 150
        case .inferno: return 170
        case .nova:    return 200
        }
    }

    var internalGlowBlur: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 30
        case .flame:   return 40
        case .blaze:   return 50
        case .inferno: return 60
        case .nova:    return 70
        }
    }

    // MARK: External ambient shadow
    var shadowColor: Color {
        switch self {
        case .ember:   return AppColors.cyan.opacity(0.04)
        case .spark:   return AppColors.cyan.opacity(0.06)
        case .flame:   return AppColors.purple.opacity(0.08)
        case .blaze:   return AppColors.purple.opacity(0.12)
        case .inferno: return AppColors.magenta.opacity(0.10)
        case .nova:    return AppColors.magenta.opacity(0.16)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .ember:   return 10
        case .spark:   return 15
        case .flame:   return 20
        case .blaze:   return 25
        case .inferno: return 30
        case .nova:    return 35
        }
    }
}
