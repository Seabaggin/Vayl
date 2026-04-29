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
            self = .black
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black
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

    /// Electric violet — gradient midpoint, orb layers, PulseWidget orb C
    /// Use this. `violet` (#7C3AED) was removed — it had 0 usages.
    static let electricViolet = Color(hex: "8B5CF6")

    /// Electric purple — vivid gradient midpoint, LivingText only
    static let purpleVivid = Color(hex: "9333EA")

    static let purpleBright = Color(hex: "C084FC")

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
    // Page -> Card -> Surface hierarchy (darkest to lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")
    // AppColors.swift

    static let appIconBg = Color(hex: "090B17")

    /// Widget/tray dark floor — sits between pageBg and surfaceRaised.
    /// Used for the dark base layer behind home widgets (PulseWidget, etc.)
    /// so the widget reads as a raised element without going full cardBg.
    static let widgetDarkFloor = Color(hex: "08060A")

    /// Default card interior (levels 1–4)
    // DARK-FILL-FIX: was #050507 — only 2/255 delta from pageBg.
    // At disabled opacity 0.45 the button was invisible.
    // #12111A holds shape identity at 0.45 while staying dark.
    static let cardBg = Color(hex: "12111A")

    /// Elevated surfaces, sheets, modals
    // DARK-FILL-FIX: was #08080C — 5/255 delta from pageBg.
    // Invisible at 0.45 opacity. #1A1825 holds pill shape.
    static let surfaceBg = Color(hex: "1A1825")

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
    static let tintSupernovaA = Color(hex: "081420")
    static let tintSupernovaB = Color(hex: "0C0624")
    static let tintSupernovaC = Color(hex: "1A0620")
    static let tintSupernovaD = Color(hex: "1C0818")

    // ─────────────────────────────────────────────
    // MARK: Dark Mode Text
    //
    // All dark mode text is white-family — opacity lets
    // the purple atmosphere bleed through rather than
    // introducing flat grey hues.
    //
    // textPrimary (#E8E8F0): use for prompt content and
    // headings that need a fixed colour value.
    // .white (1.0): use for body copy that should feel
    // pure — onboarding screens, card text.
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings. Near-white with a subtle
    /// warm tint. Use .white directly for pure body copy.
    static let textPrimary    = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels (white @ 65%)
    /// opacity preserves luminance while letting atmosphere bleed through.
    static let textSecondary  = Color.white.opacity(0.65)

    /// Tertiary text — timestamps, meta (white @ 38%).
    /// Apply .italic() at usage sites — italic is the semantic signal
    /// that separates tertiary from secondary, not just opacity.
    static let textTertiary   = Color.white.opacity(0.38)

    /// Hint text — pronoun hints, placeholders, inline helper copy (white @ 42%).
    /// Slightly brighter than tertiary — hints compete with placeholder
    /// backgrounds and need a touch more presence.
    /// Renamed from textQuaternary (was incorrectly dimmer than tertiary).
    static let textHint       = Color.white.opacity(0.42)

    /// Muted text — disabled states, truly silent copy (white @ 20%)
    static let textMuted      = Color.white.opacity(0.20)

    /// Bright near-white for small labels that need to survive a
    /// purple-tinted ambient background (status strip counts, overline
    /// labels, etc). Device-absolute — cannot be tinted.
    static let textBright     = Color(white: 0.90)

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default subtle border
    static let border         = Color.white.opacity(0.06)

    /// Hover/active border
    static let borderHover    = Color.white.opacity(0.10)

    /// Prominent border
    static let borderActive   = Color.white.opacity(0.15)

    // ─────────────────────────────────────────────
    // MARK: UI Elements
    // ─────────────────────────────────────────────

    /// Badge background
    static let badgeBg        = cyan.opacity(0.08)

    /// Ghost button border
    static let btnGhostBorder = Color.white.opacity(0.06)

    /// Toggle / switch active
    static let toggleActive   = cyan

    /// Destructive / warning
    static let destructive    = Color(hex: "FF4444")

    /// Success / confirmed
    static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    /// Gold usage rule:
    /// At full or near-full opacity: safety signals only
    /// (safe word button, warnings, hard stop actions).
    /// Never decorative at visible opacity.
    /// Aurora atmospheric use at ≤8% opacity is acceptable
    /// because it cannot be read as a directional signal
    /// at that opacity level. If it is visible enough to be
    /// noticed as gold, it is too opaque for non-safety use.
    static let gold      = Color(hex: "C8960A")
    static let goldLight = Color(hex: "E2B93B")
    static let goldDark  = Color(hex: "8B6914")

    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Shadow colors
    static let shadowDeep = Color.black.opacity(0.50)

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

    // ─────────────────────────────────────────────
    // MARK: Light Mode — Warm Aurora
    //
    // Background: #F8F6EE (warm cream — never change)
    // Aurora palette: Magenta / Purple / Gold — no cyan
    // All tokens prefixed with light* or aurora* to
    // prevent any collision with dark mode tokens.
    // ─────────────────────────────────────────────

    // Backgrounds
    /// Warm cream — the one true light mode page background
    static let lightPageBg    = Color(hex: "F8F6EE")

    /// Pure white — card interiors lift off the cream naturally
    static let lightCardBg    = Color(hex: "FFFFFF")

    /// Inset fields — slightly deeper than page, clearly recessed
    static let lightSurfaceBg = Color(hex: "F2EFE6")

    // ─────────────────────────────────────────────
    // MARK: Light Mode Text — Wine Scale
    //
    // Primary body text for all light mode screens derives
    // from the wine family, not near-black. This keeps the
    // full text stack within the warm aurora palette.
    //
    // Hierarchy (solid anchors):
    //   lightHeadline   #3D1A26  darkest — display headers
    //   lightBodyPrimary #5C1F35  mid wine — all body text
    //   lightBodyAccent  #7A2D45  lighter — accent / detail
    //   lightBodyWineDark #703040 lightest — pill labels, CTA text
    //
    // Opacity scale (derived from lightBodyPrimary):
    //   lightTextSecondary  60% — labels, descriptions
    //   lightTextTertiary   38% — meta, timestamps (+ italic at usage)
    //   lightTextMuted      22% — disabled, ghost copy
    //
    // lightTextPrimary (#1A1A1E near-black) is kept for any future
    // screen that genuinely wants neutral dark text, but it is NOT
    // the onboarding body color and should not be used there.
    // ─────────────────────────────────────────────

    /// Near-black — reserved for neutral screens. NOT the onboarding body color.
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// Darkest wine — display headlines on cream (#3D1A26)
    static let lightHeadline      = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Mid wine — primary body text for all light mode screens (#5C1F35)
    /// This is the base for the opacity scale below.
    static let lightBodyPrimary   = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Lighter wine — accent body, card detail text (#7A2D45)
    static let lightBodyAccent    = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Lightest wine — unselected pill labels, CTA text on light surfaces (#703040)
    static let lightBodyWineDark  = Color(red: 0.44, green: 0.07, blue: 0.18)

    /// Secondary text — labels, descriptions (lightBodyPrimary @ 60%)
    static let lightTextSecondary = lightBodyPrimary.opacity(0.60)

    /// Tertiary text — meta, timestamps (lightBodyPrimary @ 38%)
    /// Apply .italic() at usage sites — italic is the semantic differentiator.
    static let lightTextTertiary  = lightBodyPrimary.opacity(0.38)

    /// Muted text — disabled states, ghost copy (lightBodyPrimary @ 22%)
    static let lightTextMuted     = lightBodyPrimary.opacity(0.22)

    // Backwards-compatibility aliases for old token names.
    // Update call sites to lightHeadline / lightBodyPrimary / lightBodyAccent
    // and remove these once callers are migrated.
    static var lightHeadlineDarkRose: Color { lightHeadline }
    static var lightCardTitle: Color        { lightBodyPrimary }
    static var lightCardDetail: Color       { lightBodyAccent }

    // ─────────────────────────────────────────────
    // MARK: Light Mode Borders
    // ─────────────────────────────────────────────

    /// Default subtle border on cream surfaces
    static let lightBorder        = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover   = Color.black.opacity(0.10)

    /// Structural purple-tinted border for cards and fields (#6C3AE0 @ 14%)
    static let lightBorderPurple  = purple.opacity(0.14)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Glass Fills
    // Used with .background + backdrop blur in SwiftUI.
    // Opaque equivalents — semi-transparent whites multiply
    // with container opacity causing shapes to vanish at
    // disabled (0.45). Opaque values hold at any opacity.
    // ─────────────────────────────────────────────

    /// Glass card fill — warm near-white over aurora
    static let lightFrostCard     = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream (visible lavender-blush)
    static let lightFrostPill     = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — rose-blush, lifts visibly over unselected
    static let lightFrostPillSel  = Color(red: 0.958, green: 0.875, blue: 0.925)

    /// Custom pill fill — OnboardingNameView gender picker only
    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)

    /// CTA button fill — warm near-white
    static let lightFrostCTA      = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose, reads at any container opacity
    static let lightCTAFill       = Color(red: 0.98, green: 0.91, blue: 0.93)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Input
    // ─────────────────────────────────────────────

    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy (#BE185D @ 50%)
    static let lightHintText      = magentaDark.opacity(0.50)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Pill Tokens
    // ─────────────────────────────────────────────

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface       = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Ambient lift shadow applied to every pill in dark mode.
    static let pillGlow          = Color(white: 1.0).opacity(0.04)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Aurora Atmosphere
    // ─────────────────────────────────────────────

    // Aurora atmosphere blobs — pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)   // top right
    static let auroraBlob2 = purple.opacity(0.08)    // bottom left

    // Aurora shadow spread — on light surfaces, shadow IS the glow.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Icon Badges
    // ─────────────────────────────────────────────

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = magenta.opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = orangeHot.opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = gold.opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Borders
    //
    // One gradient border per mode used on ALL screens.
    // Replaces per-component branching on borders.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — keyword highlights on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]
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

    var usesGradientBackground: Bool {
        rawValue >= 5
    }

    // ─────────────────────────────────────────────
    // MARK: Radial Wash Overlays
    // ─────────────────────────────────────────────

    var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void:         return nil
        case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
        case .emberFloor:   return nil
        case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
        case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
        case .auroraBand:   return nil
        case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
        case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
        }
    }

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

    var glowRadius: CGFloat {
        switch self {
        case .void, .deepOcean, .emberFloor:  return 30
        case .split, .nebula, .auroraBand:    return 40
        case .deepSpace:                       return 45
        case .supernova:                       return 60
        }
    }

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

    var cyanGlowOpacity: Double    { 0.08 * glowMultiplier }
    var magentaGlowOpacity: Double { 0.06 * glowMultiplier }

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
