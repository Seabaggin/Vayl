//
//  AppColors.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = .black // fallback color for invalid hex
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black // fallback color for invalid length
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// AppColors.swift
// Open Lightly
//
// Design System: Hot Border × Clash Display × Gradient Keywords
// Card intensity scales 1–8 with prompt difficulty
// ──────────────────────────────────────────────────────

// MARK: - App Colors

struct AppColors {

  // ─────────────────────────────────────────────
  // MARK: Core Spectrum
  // The 3 anchor colors — used for borders,
  // gradient text highlights, glows
  // Gradient direction: 135° (top-left -> bottom-right)
  // ─────────────────────────────────────────────

  static let cyan       = Color(hex: "00C2FF")
  static let purple     = Color(hex: "6C3AE0")
  static let magenta    = Color(hex: "FF006A")

  /// Soft magenta variant — used in shimmer gradients and atmospheric fills
  static let pink       = Color(hex: "FF2D8A")

  /// Deep atmospheric blue — used in glow field floor washes
  static let deepBlue   = Color(hex: "0078FF")
  /// Violet — between purple and blue, used in warm-tier pill gradients
  static let violet = Color(hex: "7C3AED")

  // Lighter variants — gradient text on keywords, badges
  static let cyanLight    = Color(hex: "4DD8FF")
  static let purpleLight  = Color(hex: "A78BFA")
  static let magentaLight = Color(hex: "FF4D94")

  // Darker variants — tinted backgrounds, deep accents
  static let cyanDark    = Color(hex: "0891B2")
  static let purpleDark  = Color(hex: "1A1A5E")
  static let magentaDark = Color(hex: "BE185D")

  // ─────────────────────────────────────────────
  // MARK: Backgrounds
  // Page -> Card -> Surface (lightest)
  // ─────────────────────────────────────────────

  /// Main app background
  static let pageBg = Color(hex: "030305")

  /// Default card interior (levels 1–4)
  static let cardBg = Color(hex: "050507")

  /// Elevated surfaces, sheets, modals
  static let surfaceBg = Color(hex: "08080C")

  /// Slightly raised elements (input fields, etc)
  static let surfaceRaised = Color(hex: "0C0C10")

  // Tinted card backgrounds (for intensity levels 5–8)
  static let tintCyan    = Color(hex: "061018")
  static let tintPurple  = Color(hex: "080614")
  static let tintMagenta = Color(hex: "120610")
  static let tintNavy    = Color(hex: "0A1018")
  static let tintIndigo  = Color(hex: "0A0820")
  static let tintPlum    = Color(hex: "180818")

  // Supernova (ultimate) gradient layers — deepest possible darks
  static let tintSupernovaA = Color(hex: "081420")  // deep navy
  static let tintSupernovaB = Color(hex: "0C0624")  // deep indigo
  static let tintSupernovaC = Color(hex: "1A0620")  // deep plum
  static let tintSupernovaD = Color(hex: "1C0818")  // deep crimson

  // ─────────────────────────────────────────────
  // MARK: Text
  // ─────────────────────────────────────────────

  /// Primary text — prompt content, headings
  static let textPrimary   = Color(hex: "E8E8F0")

  /// Secondary text — descriptions, labels
  static let textSecondary = Color(hex: "AAAABC")

  /// Tertiary text — timestamps, meta
  static let textTertiary  = Color(hex: "666680")

  /// Muted text — disabled states, subtle hints
  static let textMuted     = Color.white.opacity(0.20)

  /// Badge/tag text
  static let textBadge     = Color(hex: "5BB8CC")

  // ─────────────────────────────────────────────
  // MARK: Borders
  // ─────────────────────────────────────────────

  /// Default subtle border
  static let border        = Color.white.opacity(0.06)

  /// Hover/active border
  static let borderHover   = Color.white.opacity(0.10)

  /// Prominent border
  static let borderActive  = Color.white.opacity(0.15)

  // ─────────────────────────────────────────────
  // MARK: UI Elements
  // ─────────────────────────────────────────────

  /// Badge background
  static let badgeBg       = cyan.opacity(0.08)

  /// Ghost button border
  static let btnGhostBorder = Color.white.opacity(0.06)

  /// Ghost button text
  static let btnGhostText   = Color(hex: "444444")

  /// Toggle / switch active
  static let toggleActive   = cyan

  /// Destructive / warning
  static let destructive    = Color(hex: "FF4444")

  /// Success / confirmed
  static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    static let gold       = Color(hex: "C8960A")
    static let goldLight  = Color(hex: "E2B93B")
    static let goldDark   = Color(hex: "8B6914")
    static let glowGold   = gold

  /// Glow aliases — reference the canonical spectrum tokens
  static let glowCyan    = cyan
  static let glowMagenta = magenta
  static let glowPurple  = purple

  /// Shadow colors
  static let shadowDeep = Color.black.opacity(0.50)
  static let shadowLight = Color.black.opacity(0.25)

  // ─────────────────────────────────────────────
  // MARK: Gradients
  // ─────────────────────────────────────────────

  /// Card border gradient — the "Hot Border"
  /// Used on every prompt card at full opacity
  static let spectrumBorder = LinearGradient(
      colors: [cyan, purple, magenta],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
  )

  /// Keyword highlight gradient — applied to select words
  /// Use with .foregroundStyle() on Text views
  static let spectrumText = LinearGradient(
      colors: [cyan, purpleLight, magenta],
      startPoint: .leading,
      endPoint: .trailing
  )

  /// Primary button fill — subtle gradient
  static let btnPrimaryFill = LinearGradient(
      colors: [
          cyan.opacity(0.12),
          magenta.opacity(0.10)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
  )

  /// Max-intensity CTA — used sparingly (level 8, special)
  static let btnMaxFill = LinearGradient(
      colors: [cyan, purple, magenta],
      startPoint: .leading,
      endPoint: .trailing
  )

  /// Top-edge ambient wash (cards level 2+)
  static let topCyanWash = LinearGradient(
      colors: [
          cyan.opacity(0.04),
          Color.clear
      ],
      startPoint: .top,
      endPoint: .center
  )

    // MARK: - Canonical Aliases (Batch 6 spec)
    static var card: Color { cardBg }
    static var background: Color { pageBg }
    static var cardElevated: Color { surfaceRaised }

    // MARK: - Spectrum Gradient (Batch 6 spec)
    static var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, purple, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// Card Intensity System
// Maps prompt difficulty -> visual intensity
// ──────────────────────────────────────────────────────

enum CardIntensity: Int, CaseIterable, Identifiable {
  case void        = 1
  case deepOcean   = 2
  case emberFloor  = 3
  case split       = 4
  case nebula      = 5
  case auroraBand  = 6
  case deepSpace   = 7
  case supernova   = 8

  var id: Int { rawValue }

  // ─────────────────────────────────────────────
  // MARK: Mapping from prompt data
  // ─────────────────────────────────────────────

  /// Map a difficulty string to a card intensity
  static func from(difficulty: String) -> CardIntensity {
      switch difficulty.lowercased() {
      case "easy":        return .void
      case "light":       return .deepOcean
      case "medium":      return .split
      case "deep":        return .nebula
      case "sensitive":   return .deepSpace
      case "ultimate":    return .supernova
      default:            return .deepOcean
      }
  }

  /// Map a numeric score (1–10) to intensity
  static func from(score: Int) -> CardIntensity {
      switch score {
      case 1...2:  return .void
      case 3:      return .deepOcean
      case 4:      return .emberFloor
      case 5:      return .split
      case 6:      return .nebula
      case 7:      return .auroraBand
      case 8:      return .deepSpace
      case 9...10: return .supernova
      default:     return .deepOcean
      }
  }

  // ─────────────────────────────────────────────
  // MARK: Background
  // ─────────────────────────────────────────────

  /// Base background color
  var backgroundColor: Color {
      switch self {
      case .void, .deepOcean, .emberFloor, .split, .auroraBand:
          return AppColors.cardBg
      case .nebula:
          return AppColors.tintCyan
      case .deepSpace:
          return AppColors.tintNavy
      case .supernova:
          return AppColors.tintIndigo
      }
  }

  /// Optional gradient background for higher levels
  var backgroundGradient: LinearGradient? {
      switch self {
      case .void, .deepOcean, .emberFloor, .split, .auroraBand:
          return nil
      case .nebula:
          return LinearGradient(
              colors: [AppColors.tintCyan, AppColors.tintPurple, AppColors.tintMagenta],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
          )
      case .deepSpace:
          return LinearGradient(
              colors: [AppColors.tintNavy, AppColors.tintIndigo, AppColors.tintPlum],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
          )
      case .supernova:
          return LinearGradient(
              colors: [
                  AppColors.tintSupernovaA,
                  AppColors.tintSupernovaB,
                  AppColors.tintSupernovaC,
                  AppColors.tintSupernovaD
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
          )
      }
  }

  /// Whether this level uses a gradient bg vs flat color
  var usesGradientBackground: Bool {
      rawValue >= 5
  }

  // ─────────────────────────────────────────────
  // MARK: Radial Wash Overlays
  // These get layered on top of the background
  // ─────────────────────────────────────────────

  /// Cyan wash position + opacity
  var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
      switch self {
      case .void:         return nil
      case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
      case .emberFloor:   return nil
      case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
      case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
      case .auroraBand:   return nil  // uses band instead
      case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
      case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
      }
  }

  /// Magenta wash position + opacity
  var magentaWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
      switch self {
      case .void, .deepOcean: return nil
      case .emberFloor:       return (x: 0.5, y: 1.1, opacity: 0.09)
      case .split:            return (x: 0.9, y: 1.0, opacity: 0.06)
      case .nebula:           return (x: 0.85, y: 0.8, opacity: 0.05)
      case .auroraBand:       return nil
      case .deepSpace:        return (x: 0.8, y: 0.9, opacity: 0.07)
      case .supernova:        return (x: 0.9, y: 1.0, opacity: 0.09)
      }
  }

  // ─────────────────────────────────────────────
  // MARK: Glow / Shadow
  // ─────────────────────────────────────────────

  /// Outer glow shadow radius
  var glowRadius: CGFloat {
      switch self {
      case .void, .deepOcean, .emberFloor:  return 30
      case .split, .nebula, .auroraBand:    return 40
      case .deepSpace:                       return 45
      case .supernova:                       return 60
      }
  }

  /// Glow intensity multiplier
  var glowMultiplier: Double {
      switch self {
      case .void:        return 0.6
      case .deepOcean:   return 0.8
      case .emberFloor:  return 0.8
      case .split:       return 0.9
      case .nebula:      return 1.0
      case .auroraBand:  return 0.9
      case .deepSpace:   return 1.1
      case .supernova:   return 1.3
      }
  }

  /// Cyan shadow opacity (pre-multiplied)
  var cyanGlowOpacity: Double {
      0.08 * glowMultiplier
  }

  /// Magenta shadow opacity (pre-multiplied)
  var magentaGlowOpacity: Double {
      0.06 * glowMultiplier
  }

  // ─────────────────────────────────────────────
  // MARK: Display Helpers
  // ─────────────────────────────────────────────

  var displayName: String {
      switch self {
      case .void:        return "Void"
      case .deepOcean:   return "Deep Ocean"
      case .emberFloor:  return "Ember Floor"
      case .split:       return "Split"
      case .nebula:      return "Nebula"
      case .auroraBand:  return "Aurora Band"
      case .deepSpace:   return "Deep Space"
      case .supernova:   return "Supernova"
      }
  }

  var difficultyLabel: String {
      switch self {
      case .void, .deepOcean:         return "Easy"
      case .emberFloor, .split:       return "Medium"
      case .nebula, .auroraBand:      return "Deep"
      case .deepSpace:                return "Sensitive"
      case .supernova:                return "Ultimate"
      }
  }
}
