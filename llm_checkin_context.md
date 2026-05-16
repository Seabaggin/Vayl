# LLM Context — Open Lightly · Daily Check-In Feature

> **Scope: Existing reusable design system + home layer + new check-in files to build.**
>
> Feature being built:
>   RelationalWeather   — 14-day capacity barometer chart (home dashboard widget)
>   DailyCheckInView    — 5-question check-in sequence (cinematic resolution)
>   CheckInPhase        — phase machine: idle | questions | resolving | done
>   CheckInEntry        — model: date, capacityScore, glowColor, speed
>   RelationalWeatherEntry — model: per-day score for the timeline graph
>
> React prototype (port reference) is appended at the end of this file.
> All dy math, tier thresholds, and camera step geometry come from there.
>
> Files marked MISSING in warnings = new files that need to be created.
>
> Generated: 2026-04-06 18:41:31 PDT

---

## Table of Contents

  1. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  2. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)
  3. [`Open Lightly/Design/Components/Effects/AuroraGlowField.swift`](#file-open-lightly-design-components-effects-auroraglowfield-swift)
  4. [`Open Lightly/Design/Components/Effects/GlowOrb.swift`](#file-open-lightly-design-components-effects-gloworb-swift)
  5. [`Open Lightly/Design/Components/Effects/HolographicShimmer.swift`](#file-open-lightly-design-components-effects-holographicshimmer-swift)
  6. [`Open Lightly/Design/Components/Effects/OnboardingGlowField.swift`](#file-open-lightly-design-components-effects-onboardingglowfield-swift)
  7. [`Open Lightly/Design/Components/Buttons/SelectablePill.swift`](#file-open-lightly-design-components-buttons-selectablepill-swift)
  8. [`Open Lightly/Features/Home/HomeDashboardView.swift`](#file-open-lightly-features-home-homedashboardview-swift)
  9. [`Open Lightly/Features/Home/HomeStates.swift`](#file-open-lightly-features-home-homestates-swift)
  10. [`Open Lightly/Features/Home/HomeRouterView.swift`](#file-open-lightly-features-home-homerouterview-swift)
  11. [`Open Lightly/Features/Home/Components/HomeCardCarousel.swift`](#file-open-lightly-features-home-components-homecardcarousel-swift)
  12. [`Open Lightly/Features/Home/Components/DesireMapIndicator.swift`](#file-open-lightly-features-home-components-desiremapindicator-swift)
  13. [`Open Lightly/Features/Home/Components/ReflectionCard.swift`](#file-open-lightly-features-home-components-reflectioncard-swift)
  14. [`Open Lightly/Features/Home/Components/ResearchTicker.swift`](#file-open-lightly-features-home-components-researchticker-swift)
  15. [`Open Lightly/Features/Home/Components/PartnerChip.swift`](#file-open-lightly-features-home-components-partnerchip-swift)
  16. [`Open Lightly/Features/Home/Components/PickUpCard.swift`](#file-open-lightly-features-home-components-pickupcard-swift)
  17. [`Open Lightly/Features/Home/Components/ReflectionBannerView.swift`](#file-open-lightly-features-home-components-reflectionbannerview-swift)

---

## File: `Open Lightly/App/Theme/AppColors.swift` {#file-open-lightly-app-theme-appcolors-swift}

```swift
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

    /// Violet — between purple and blue, used in warm-tier pill gradients
    static let violet = Color(hex: "7C3AED")
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
    // Page -> Card -> Surface (lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")

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
    // MARK: Text
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings
    static let textPrimary   = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels
    static let textSecondary = Color(hex: "AAAABC")

    /// Tertiary text — timestamps, meta
    static let textTertiary  = Color(hex: "666680")

    /// Quaternary text — pronoun hint, subtle placeholders
    static let textQuaternary = Color(red: 0.42, green: 0.42, blue: 0.50)

    /// Muted text — disabled states, subtle hints
    static let textMuted     = Color.white.opacity(0.20)

    /// Bright near-white for small labels that need to survive
    /// a purple-tinted ambient background (status strip counts,
    /// overline labels, etc). Device-absolute — cannot be tinted.
    static let textBright = Color(white: 0.90)

    /// Muted body text — sublabels inside cards.
    /// Use when textSecondary reads below threshold on deep backgrounds.
    static let textMutedBody = Color(white: 0.62)

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
    /// Gold usage rule:
    /// At full or near-full opacity: safety signals only
    /// (safe word button, warnings, hard stop actions).
    /// Never decorative at visible opacity.
    /// Aurora atmospheric use at ≤8% opacity is acceptable
    /// because it cannot be read as a directional signal
    /// at that opacity level. If it is visible enough to be
    /// noticed as gold, it is too opaque for non-safety use.
    static let gold       = Color(hex: "C8960A")
    static let goldLight  = Color(hex: "E2B93B")
    static let goldDark   = Color(hex: "8B6914")
    static let glowGold   = gold
    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Glow aliases — reference the canonical spectrum tokens
    static let glowCyan    = cyan
    static let glowMagenta = magenta
    static let glowPurple  = purple

    /// Shadow colors
    static let shadowDeep  = Color.black.opacity(0.50)
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

    // Text
    /// Near-black — primary headings and body on cream
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// Mid-tone label text on cream — labels, descriptions.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.50) on #F8F6EE.
    static let lightTextSecondary = Color(hex: "8C8C94")

    /// Subtle meta text on cream — timestamps, hints, tertiary labels.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.30) on #F8F6EE.
    static let lightTextTertiary  = Color(hex: "B3B3BA")

    // Borders
    /// Default subtle border on cream surfaces
    static let lightBorder      = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover = Color.black.opacity(0.10)

    // Frosted glass fills
    // Used with .background + backdrop blur in SwiftUI.
    // These are NOT opaque — the aurora bleeds through intentionally.
    /// Glass card fill — 58% white over aurora
    // OPACITY-FIX: was Color.white.opacity(0.58)
    static let lightFrostCard    = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream
    // OPACITY-FIX: was Color.white.opacity(0.55) — semi-transparent
    // whites multiply with container opacity causing pills to vanish
    // at disabled 0.45. Opaque equivalent preserves identical appearance
    // at full opacity and holds at any container opacity.
    // TINT-FIX: was (0.988, 0.984, 0.970) near-white — shimmer had nothing
    // to push against. Now a soft lavender-blush sits visibly on
    // lightPageBg (#F8F6EE). Parallel role to surfaceBg (#1A1825) in dark.
    // PILL-FILL-FIX: was (0.945, 0.925, 0.960) — near-white, indistinguishable
    // from lightPageBg (#F8F6EE). Shimmer had nothing to push against.
    // Now a visible lavender — parallel role to surfaceBg (#1A1825) in dark mode.
    // The shimmer sweeps over this tinted base the same way HolographicShimmer
    // sweeps over the deep purple surfaceBg.
    static let lightFrostPill    = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — slightly more opaque for legibility
    // PILL-FILL-FIX: was (0.950, 0.922, 0.968) — barely distinguishable from
    // lightFrostPill. Selected state had no visual lift over unselected.
    // Now a visible rose-blush — selected reads richer and warmer than unselected.
    // Contrast between selected/unselected mirrors dark mode's surfaceBg delta.
    static let lightFrostPillSel = Color(red: 0.958, green: 0.875, blue: 0.925)

    // MARK: - Pill Tokens

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Selected pill interior tint multiplier base.
    /// View applies .opacity() on top of this.
    static let pillSurfaceSelected = Color(red: 0.051, green: 0.043, blue: 0.122)

    /// Ambient lift shadow applied to every pill in dark mode.
    /// Keeps pills visually separated from the background without
    /// a directional light source.
    static let pillGlow = Color(white: 1.0).opacity(0.04)

    /// CTA button fill — frosted, never fully opaque
    // OPACITY-FIX: was Color.white.opacity(0.70)
    static let lightFrostCTA     = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose so button reads
    /// correctly at both full and 0.45 disabled opacity.
    /// Harmonises with LightModeShimmer's purple/magenta/gold tints.
    static let lightCTAFill      = Color(red: 0.98, green: 0.91, blue: 0.93)

    // Floating label colors
    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy
    // TODO: replace with opaque equivalent
    static let lightHintText      = magentaDark.opacity(0.50)

    // Aurora atmosphere blobs
    // Four colors that pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)    // magenta — top right
    static let auroraBlob2 = purple.opacity(0.08)     // purple  — bottom left
    static let auroraBlob3 = gold.opacity(0.07)       // gold at 7% — below signal threshold, atmospheric use only. See gold usage rule above.
    static let auroraBlob4 = pink.opacity(0.06)       // pink    — mid left

    // Aurora shadow spread
    // On light surfaces, shadow IS the glow.
    // These replace the cyan/magenta bloom shadows from dark mode.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // MARK: - Light Mode Card Text
    // Warm wine-toned text tokens for OnboardingGroundRulesView cards.
    // Used for card title and detail body on rose-blush fill in light mode only.

    /// Dark rose — deep wine for headlines on rose fill (#3D1A26)
    static let lightHeadlineDarkRose = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Wine dark — card title on rose fill (#5C1F35)
    static let lightCardTitle  = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Mid wine — card detail body on rose fill (#7A2D45)
    static let lightCardDetail = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = Color(red: 1.00, green: 0.00, blue: 0.42).opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = Color(red: 1.00, green: 0.30, blue: 0.00).opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = Color(red: 0.78, green: 0.59, blue: 0.04).opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)
    /// Card shadow — warm amber mid
    static let lightCardShadowMagenta = Color(red: 0.78, green: 0.39, blue: 0.20)

    /// Card shadow — warm orange
    static let lightCardShadowOrange  = Color(red: 1.00, green: 0.39, blue: 0.20)

    /// Wine dark — unselected pill / CTA label on light surfaces (#703040)
    static let wineDark = Color(red: 0.44, green: 0.07, blue: 0.18)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Border
    //
    // One gradient border used on ALL screens in both
    // dark and light mode. Replaces per-mode branching
    // on borders — the gradient works on both surfaces.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    //        Both live in PillBorder.swift
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    /// purple → magentaLight → gold, topLeading → bottomTrailing
    /// Matches the aurora atmosphere palette exactly
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — for "acquainted." and keyword highlights
    /// purple → purpleLight → magentaLight
    /// Stays within the purple-original blend, warm but not jarring on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    /// Same warm palette at low opacity — not the full spectrum blast
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]

    // lightPillShimmerColors — higher opacity than
    // lightShimmerColors. Used on interactive surfaces
    // (selected pills, active input borders) where the
    // shimmer needs to be as visible as HolographicShimmer
    // is in dark mode. lightShimmerColors remains unchanged
    // for background wash usage.
    static let lightPillShimmerColors: [Color] = [
        AppColors.magenta.opacity(0.50),
        AppColors.gold.opacity(0.55),
        AppColors.magenta.opacity(0.45),
        AppColors.goldLight.opacity(0.50),
        AppColors.magenta.opacity(0.50),
    ]

    // ─────────────────────────────────────────────
    // MARK: Light-mode surface tokens
    // ─────────────────────────────────────────────

    /// Slightly off-white field background for light mode.
    /// Sits above cardSurfaceLight without blending in.
    /// Parallel to dark-mode kFieldBG = white.opacity(0.07).
    static let fieldBgLight     = Color.white.opacity(0.82)

    /// Structural 1pt border for cards and fields in light mode.
    /// opacity(0.14) mirrors LivingText static shadow opacity(0.18) —
    /// visual weight matches LT-G-03: structural, not atmospheric.
    static let borderLight      = purple.opacity(0.14)

    /// Frosted white lift for the glass card surface in light mode.
    /// 0.72 lets the light atmosphere ellipse breathe through without
    /// muddying field fills inside the card.
    static let cardSurfaceLight = Color.white.opacity(0.72)

    /// Semantic blue — used in dark-mode atmosphere ellipse gradient.
    static let blue             = Color.blue
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

```

---

## File: `Open Lightly/App/Theme/AppFonts.swift` {#file-open-lightly-app-theme-appfonts-swift}

```swift
//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens

    // --- Display Scale (Clash Display) ---
    static var heroTitle: Font           { display(42, weight: .bold) }           // 42pt Bold
    static var displayHero: Font         { display(64, weight: .bold) }           // 64pt Bold
    static var scoreDisplay: Font        { display(32, weight: .bold) }           // 32pt Bold
    static var screenTitle: Font         { display(24, weight: .semibold) }       // 24pt Semibold
    static var cardTitle: Font           { display(22, weight: .semibold) }       // 22pt Semibold
    static var sectionHeading: Font      { display(20, weight: .medium) }         // 20pt Medium
    static var sectionLabelSmall: Font   { display(13, weight: .medium) }         // 13pt Medium
    static var prompt: Font              { display(17, weight: .medium) }         // 17pt Medium
    static var promptHighlight: Font     { display(17, weight: .semibold) }       // 17pt Semibold

    // --- Body Scale (Switzer) ---
    static var ctaLabel: Font            { body(16, weight: .semibold) }          // 16pt Semibold
    static var bodyText: Font            { body(16, weight: .regular) }           // 16pt Regular
    static var bodyMedium: Font          { body(15, weight: .medium) }            // 15pt Medium
    static var buttonLabel: Font         { body(14, weight: .semibold) }          // 14pt Semibold
    static var caption: Font             { body(13, weight: .regular) }           // 13pt Regular
    static var overline: Font            { body(11, weight: .semibold) }          // 11pt Semibold
    static var buttonLabelSmall: Font    { body(11, weight: .medium) }            // 11pt Medium
    static var tabLabel: Font            { body(10, weight: .medium) }            // 10pt Medium
    static var label: Font               { body(10, weight: .semibold) }          // 10pt Semibold
    static var badge: Font               { body(10, weight: .medium) }            // 10pt Medium
    static var meta: Font                { body(10, weight: .regular) }           // 10pt Regular

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/AuroraGlowField.swift` {#file-open-lightly-design-components-effects-auroraglowfield-swift}

```swift
//
//  AuroraGlowField.swift
//  Open Lightly
//
//  Warm Aurora atmospheric blob field for light mode screens.
//  Near-verbatim copy of OnboardingGlowField with warm palette
//  swapped in and opacities raised ~1.8–2.2× to compensate
//  for cream (#F8F6EE) absorbing color vs dark (#030305) amplifying it.
//

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Private palette
// File-scoped only. DO NOT add to AppColors.swift.
// ─────────────────────────────────────────────

private extension Color {
    static let auroraOrange  = Color(hex: "E04A10")
    static let auroraWine    = Color(hex: "6B1030")
    static let auroraPink    = Color(hex: "D42060")
    static let auroraWineLo  = Color(hex: "8A1430")
    // CHANGE (v2): Added purple — required for brandView gradient harmony.
    // Purple bridges the gap between wine/pink and gold in the brand palette.
    static let auroraPurple  = Color(hex: "6B28AA")
    // CHANGE (v2): Added gold — brandView uses magenta→orange→gold arc.
    static let auroraGold    = Color(hex: "E8A020")
}

// ─────────────────────────────────────────────
// MARK: Aurora Configuration
// ─────────────────────────────────────────────

struct AuroraConfig: Equatable {
    var topOpacityMult:    Double
    var midOpacityMult:    Double
    var bottomOpacityMult: Double
    var globalOpacity:     Double

    // CHANGE (v2): Added brandView config.
    // Heavy top-right (gold/orange) + strong left (purple/pink) +
    // fading bottom. Mirrors the asymmetric distribution in the mockup.
    // globalOpacity 0.78 — slightly under statView (0.85) because the
    // brand screen has a filament orbit that already contributes color
    // energy. Aurora should be atmospheric, not competing.
    static let brandView = AuroraConfig(
        topOpacityMult:    1.0,
        midOpacityMult:    0.35,
        bottomOpacityMult: 0.70,
        globalOpacity: 0.88
    )

    static let statView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.4,
        bottomOpacityMult: 1.15, globalOpacity: 1.0)

    static let nameView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.1,
        bottomOpacityMult: 1.15, globalOpacity: 0.85)

    static let modeSelectView = AuroraConfig(
        topOpacityMult: 0.1, midOpacityMult: 0.3,
        bottomOpacityMult: 1.15, globalOpacity: 0.90)

    static let contextView = AuroraConfig(
        topOpacityMult: 0.4, midOpacityMult: 0.2,
        bottomOpacityMult: 0.85, globalOpacity: 0.75)

    static let curiosityPickerView = AuroraConfig(
        topOpacityMult: 0.3, midOpacityMult: 0.1,
        bottomOpacityMult: 0.75, globalOpacity: 0.65)

    static let groundRulesView = AuroraConfig(
        topOpacityMult: 0.15, midOpacityMult: 0.2,
        bottomOpacityMult: 1.05, globalOpacity: 0.75)
}

// ─────────────────────────────────────────────
// MARK: Aurora Glow Field
// ─────────────────────────────────────────────

struct AuroraGlowField: View {
    var config: AuroraConfig = .statView

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 9)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 9)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let global = config.globalOpacity

            ZStack {

                // ── Tier 1: Top zone — heavy, asymmetric ──────────────────
                //
                // CHANGE (v2): Was single upper-left orange blob.
                // Now two blobs: dominant gold top-right + strong pink top-left.
                // This matches the mockup's asymmetric top-heavy distribution
                // and introduces gold into the upper field for brandView harmony.

                // Gold — dominant top-right
                blob(.auroraGold, 0.82 * config.topOpacityMult * global, 340, 280, 80, 0)
                    .offset(
                        x: sin(blobPhase[0] * .pi * 2) * 14,
                        y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 10
                    )
                    .position(x: w * 0.78, y: h * 0.14)

                // Pink — strong top-left
                blob(.auroraPink, 0.76 * config.topOpacityMult * global, 280, 240, 72, 1)
                    .offset(
                        x: sin(blobPhase[1] * .pi * 2) * -10,
                        y: sin(blobPhase[1] * .pi * 2 + .pi / 4) * 12
                    )
                    .position(x: w * 0.18, y: h * 0.17)

                // ── Tier 2: Mid zone — supporting, moderate opacity ────────
                //
                // CHANGE (v2): Added purple blob center-right — bridges the
                // wine/pink and gold colors. Was absent in v1 entirely.
                // Wine blob repositioned from center to center-left so the
                // mid zone has left/right color separation rather than one
                // central mass.

                // Purple — center-right (new)
                blob(.auroraPurple, 0.70 * config.midOpacityMult * global, 300, 260, 78, 2)
                    .scaleEffect(
                        blobVisible[2]
                            ? 1 + 0.05 * sin(blobPhase[2] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[2] * .pi * 2) * 8)
                    .position(x: w * 0.80, y: h * 0.36)

                // Wine — center-left (was: center w * 0.50)
                blob(.auroraWine, 0.67 * config.midOpacityMult * global, 320, 280, 78, 3)
                    .scaleEffect(
                        blobVisible[3]
                            ? 1 + 0.06 * sin(blobPhase[3] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[3] * .pi * 2) * 5)
                    .position(x: w * 0.28, y: h * 0.40)

                // Orange — warm mid accent (unchanged position, opacity tuned)
                blob(.auroraOrange, 0.42 * config.midOpacityMult * global, 200, 180, 80, 4)
                    .offset(
                        x: sin(blobPhase[4] * .pi) * 8,
                        y: sin(blobPhase[4] * .pi) * -6
                    )
                    .position(x: w * 0.55, y: h * 0.50)

                // ── Tier 3: Lower zone — faint, wide ──────────────────────
                //
                // CHANGE (v2): WineLo blob repositioned from w*0.18 h*0.60
                // to w*0.22 h*0.64 — slightly more centered so the lower
                // field doesn't feel left-only.
                // Floor wash y moved from h*0.80 → h*0.86 for brandView
                // so it doesn't bleed into the tagline zone at h*0.595.
                // Bottom orange accent opacity reduced — less competition
                // with the tagline text at the bottom of the brand screen.

                // WineLo — lower left
                blob(.auroraWineLo, 0.67 * config.midOpacityMult * global, 280, 200, 85, 5)
                    .scaleEffect(
                        blobVisible[5]
                            ? 1 + 0.05 * sin(blobPhase[5] * .pi * 2)
                            : 0.7
                    )
                    .offset(
                        x: sin(blobPhase[5] * .pi) * 8,
                        y: sin(blobPhase[5] * .pi) * -5
                    )
                    .position(x: w * 0.22, y: h * 0.64)

                // Floor wash — wide radial sweep across bottom
                Ellipse()
                    .fill(RadialGradient(
                        stops: [
                            .init(
                                color: Color.auroraWine.opacity(
                                    0.48 * config.bottomOpacityMult * global
                                ),
                                location: 0
                            ),
                            .init(
                                color: Color.auroraPink.opacity(
                                    0.28 * config.bottomOpacityMult * global
                                ),
                                location: 0.4
                            ),
                            .init(color: .clear, location: 0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    ))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(
                        blobVisible[6]
                            ? 1 + 0.06 * sin(blobPhase[6] * .pi * 2)
                            : 0.7
                    )
                    .opacity(blobVisible[6] ? 1 : 0)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.86)

                // Orange — bottom accent (opacity reduced v1→v2: 0.324→0.22)
                blob(.auroraOrange, 0.35 * config.bottomOpacityMult * global, 220, 140, 88, 7)
                    .offset(x: sin(blobPhase[7] * .pi * 2) * -8)
                    .position(x: w * 0.46, y: h * 0.91)

                // Gold — bottom-right faint accent (new in v2)
                // Anchors the gold presence in the lower field so the
                // warm arc (gold top-right → gold bottom-right) reads as
                // intentional, not a single isolated blob.
                blob(.auroraGold, 0.26 * config.bottomOpacityMult * global, 200, 140, 85, 8)
                    .offset(x: sin(blobPhase[8] * .pi * 2) * 6)
                    .position(x: w * 0.80, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 1.0), value: config)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(
        _ color: Color,
        _ opacity: Double,
        _ w: CGFloat,
        _ h: CGFloat,
        _ blur: CGFloat,
        _ i: Int
    ) -> some View {
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(color: color.opacity(opacity),        location: 0.20),
                    .init(color: color.opacity(opacity * 0.55), location: 0.55),
                    .init(color: .clear,                        location: 1.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(w, h) / 2
            ))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration
    //
    // CHANGE (v2): Extended from 7 blobs → 9 blobs.
    // Two new entries appended to all arrays (indices 7, 8).
    // Phase-drifted durations prevent synchronization across blobs.

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.10, 0.20, 0.30, 0.35, 0.40, 0.50, 0.60, 0.65, 0.70]
        let fadeDurations: [Double] = [0.90, 1.00, 0.90, 1.00, 1.00, 1.20, 1.00, 1.00, 1.10]
        let loopDurations: [Double] = [8,    10,   9,    11,   12,   14,   10,   13,   11  ]
        let loopDelays:    [Double] = [0.80, 1.00, 1.20, 1.30, 1.50, 1.60, 1.80, 1.90, 2.00]

        for i in 0..<9 {
            withAnimation(
                .easeInOut(duration: fadeDurations[i])
                .delay(fadeDelays[i])
            ) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(
                    .linear(duration: loopDurations[i])
                    .repeatForever(autoreverses: false)
                ) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Brand View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .brandView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Dark") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Effects/GlowOrb.swift` {#file-open-lightly-design-components-effects-gloworb-swift}

```swift
//
//  GlowOrb.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

// ✅ Design system audit — verified March 9, 2026

import SwiftUI

struct GlowOrb: View {
    @Environment(\.theme) private var t
    let color: Color
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 40)
            .opacity(t.glowOpacity)
            .allowsHitTesting(false)
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/HolographicShimmer.swift` {#file-open-lightly-design-components-effects-holographicshimmer-swift}

```swift
import SwiftUI

/// Self-contained animated holographic shimmer fill.
/// Renders a 3× wide neon gradient that sweeps left→right continuously.
///
/// Use as a background layer clipped to any shape:
/// ```swift
/// Capsule()
///     .fill(AppColors.surfaceBg)
///     .overlay { HolographicShimmer().clipShape(Capsule()) }
/// ```
struct HolographicShimmer: View {
    /// Animation duration in seconds. Defaults to 6 (gentle sweep).
    var duration: Double = 6

    @State private var phase: CGFloat = 0

    private let colors: [Color] = [
        AppColors.cyan.opacity(0.50),
        AppColors.purple.opacity(0.45),
        AppColors.magenta.opacity(0.45),
        AppColors.pink.opacity(0.40),
        AppColors.cyan.opacity(0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/OnboardingGlowField.swift` {#file-open-lightly-design-components-effects-onboardingglowfield-swift}

```swift
// OnboardingGlowField.swift
// Open Lightly
//
// Atmospheric glow blob field shared across all onboarding screens.
// Extracted from OnboardingNameView's inline glowField implementation.
// Usage: OnboardingGlowField() — manages its own animation state.
import SwiftUI

struct OnboardingGlowField: View {
    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Cyan — upper-left
                blob(AppColors.cyan,  0.32, 300, 280, 75, 0)
                    .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                            y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                    .position(x: w * 0.22, y: h * 0.20)

                // Purple — center
                blob(AppColors.purple, 0.28, 380, 360, 75, 1)
                    .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                    .position(x: w * 0.50, y: h * 0.40)

                // Magenta — right edge
                blob(AppColors.magenta, 0.24, 280, 300, 75, 2)
                    .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                            y: cos(blobPhase[2] * .pi * 2) * 12)
                    .position(x: w * 0.88, y: h * 0.33)

                // Gold — warm accent
                blob(AppColors.goldLight, 0.12, 200, 180, 80, 3)
                    .offset(x: sin(blobPhase[3] * .pi) * 8,
                            y: sin(blobPhase[3] * .pi) * -6)
                    .position(x: w * 0.20, y: h * 0.48)

                // Magenta — mid-left
                blob(AppColors.magenta, 0.15, 300, 220, 85, 4)
                    .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[4] * .pi) * 8,
                            y: sin(blobPhase[4] * .pi) * -6)
                    .position(x: w * 0.18, y: h * 0.60)

                // Floor wash
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.deepBlue.opacity(0.12), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),   location: 0.4),
                        .init(color: .clear,                           location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                    .opacity(blobVisible[5] ? 1 : 0)
                    .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.80)

                // Cyan accent — bottom
                blob(AppColors.cyan, 0.08, 240, 150, 90, 6)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                    .position(x: w * 0.45, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(_ color: Color, _ opacity: Double, _ w: CGFloat, _ h: CGFloat, _ blur: CGFloat, _ i: Int) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.1, 0.2, 0.3, 0.35, 0.4,  0.5,  0.6]
        let fadeDurations: [Double] = [0.9, 1.0, 0.9, 1.0,  1.0,  1.2,  1.0]
        let loopDurations: [Double] = [8,   10,  9,   11,   12,   14,   10]
        let loopDelays:    [Double] = [0.8, 1.0, 1.2, 1.3,  1.5,  1.6,  1.8]

        for i in 0..<7 {
            withAnimation(.easeInOut(duration: fadeDurations[i]).delay(fadeDelays[i])) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(.linear(duration: loopDurations[i]).repeatForever(autoreverses: false)) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingGlowField()
    }
}

```

---

## File: `Open Lightly/Design/Components/Buttons/SelectablePill.swift` {#file-open-lightly-design-components-buttons-selectablepill-swift}

```swift
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
            .foregroundStyle(isLight ? AppColors.wineDark : Color.white)
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
            return AppColors.wineDark   // selected and unselected both deep wine on cream
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

```

---

## File: `Open Lightly/Features/Home/HomeDashboardView.swift` {#file-open-lightly-features-home-homedashboardview-swift}

```swift
// HomeDashboardView.swift
// Open Lightly

import SwiftUI

struct HomeDashboardView: View {

    // MARK: - Injected Properties

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var cards: [Prompt] = Prompt.samples
    var desireMapState: DesireMapState = .hidden
    var reflectionCardState: ReflectionCardState = .hidden
    var pickUpItems: [PickUpItem] = []
    var stageIndex: Int = 1
    var cardsCompleted: Int = 0
    var daysSinceLastSession: Int? = nil
    var recentEvents: [HomeEvent] = []
    var isSolo: Bool = false
    var showReflectionBanner: Bool = false

    // MARK: - Callbacks

    var onRemindPartner: (() -> Void)? = nil
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil
    var onDesireMapReveal: (() -> Void)? = nil
    var onDesireMapUnlock: (() -> Void)? = nil
    var onReflectionDone: (([String], String?, Bool) -> Void)? = nil
    var onReflectionBannerDismiss: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onPickUpItemTap: ((PickUpItem) -> Void)? = nil
    var onInvitePartner: (() -> Void)? = nil

    // MARK: - Environment + State

    @Environment(\.colorScheme) private var colorScheme

    @State private var greetingVisible   = false
    @State private var sessionVisible    = false
    @State private var desireMapVisible  = false
    @State private var reflectionVisible = false
    @State private var pickUpVisible     = false
    @State private var tickerVisible     = false
    @State private var hasAnimated       = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    Spacer(minLength: 16)

                    // ── Greeting ──────────────────────────────
                    greetingBlock
                        .padding(.horizontal, 24)
                        .opacity(greetingVisible ? 1 : 0)
                        .offset(y: greetingVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: greetingVisible)

                    Spacer(minLength: 16)

                    // ── Card Carousel ─────────────────────────
                    HomeCardCarousel(
                        cards: cards,
                        onCardAction: onCardAction
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                    .opacity(sessionVisible ? 1 : 0)
                    .offset(y: sessionVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.5),
                               value: sessionVisible)

                    // ── Desire Map Indicator ──────────────────
                    if desireMapState != .hidden
                        && desireMapState != .fullyUnlocked {

                        Spacer(minLength: 14)

                        DesireMapIndicator(
                            state: desireMapState,
                            onReveal: onDesireMapReveal,
                            onUnlock: onDesireMapUnlock,
                            onRemind: onRemindPartner
                        )
                        .padding(.horizontal, 20)
                        .opacity(desireMapVisible ? 1 : 0)
                        .offset(y: desireMapVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: desireMapVisible)
                    }

                    // ── Reflection Card ───────────────────────
                    if reflectionCardState != .hidden {

                        Spacer(minLength: 14)

                        ReflectionCard(
                            state: reflectionCardState,
                            onMoreTap: onMoreTap,
                            onDone: { pills, note in
                                onReflectionDone?(pills, note, true)
                            }
                        )
                        .padding(.horizontal, 20)
                        .opacity(reflectionVisible ? 1 : 0)
                        .offset(y: reflectionVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: reflectionVisible)
                    }

                    // ── Pick Up Where You Left Off ────────────
                    if !pickUpItems.isEmpty {

                        Spacer(minLength: 14)

                        PickUpCard(
                            items: pickUpItems,
                            onItemTap: onPickUpItemTap
                        )
                        .padding(.horizontal, 20)
                        .opacity(pickUpVisible ? 1 : 0)
                        .offset(y: pickUpVisible ? 0 : 8)
                        .animation(.easeOut(duration: 0.5),
                                   value: pickUpVisible)
                    }

                    // ── Research Ticker ───────────────────────
                    Spacer(minLength: 20)

                    ResearchTicker()
                        .opacity(tickerVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.6),
                                   value: tickerVisible)

                    Spacer(minLength: 120)
                }
            }
            .background {
                backgroundLayer
                    .ignoresSafeArea()
            }
            .overlay {
                // ── Reflection Banner Overlay ─────────────────────
                if showReflectionBanner {
                    VStack {
                        ReflectionBannerView(
                            sessionLabel: bannerSessionLabel,
                            partnerName: bannerPartnerName,
                            onDone: onReflectionDone,
                            onDismiss: onReflectionBannerDismiss
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        Spacer()
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal:   .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: showReflectionBanner
                    )
                }
            }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(greetingSalutation)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary
                        )

                    if !displayName.isEmpty {
                        Text("\(displayName).")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                            )
                    }
                }

                Spacer()

                PartnerChip(
                    state: partnerChipState,
                    onInviteTap: onInvitePartner
                )
                .padding(.top, 4)
            }

            Text(eventOneLiner)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(
                    colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Computed Properties

    private var greetingSalutation: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Hey"
        case 17..<21: return "Good evening"
        default:      return "Still up"
        }
    }

    private var eventOneLiner: String {
        let partner: String? = {
            if case .active(let name, _) = partnerChipState {
                return name
            }
            return nil
        }()
        return HomeEventEngine.oneLiner(
            events: recentEvents,
            stageIndex: stageIndex,
            cardsCompleted: cardsCompleted,
            isSolo: isSolo,
            partnerName: partner
        )
    }

    private var bannerSessionLabel: String {
        if case .pendingYours(let label, _) = reflectionCardState {
            return label
        }
        return "Last session"
    }

    private var bannerPartnerName: String? {
        if case .active(let name, _) = partnerChipState {
            return name
        }
        return nil
    }

    // MARK: - Background

   private var backgroundLayer: some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.18),
                            AppColors.deepBlue.opacity(0.08),
                            Color.clear
                        ],
                        center:      .top,
                        startRadius: 30,
                        endRadius:   380
                    ))
                    .frame(width: 600, height: 400)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) {
            greetingVisible   = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            sessionVisible    = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.38)) {
            desireMapVisible  = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) {
            reflectionVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) {
            pickUpVisible     = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.70)) {
            tickerVisible     = true
        }
    }
}

// MARK: - Equatable helpers

extension DesireMapState: Equatable {
    static func == (lhs: DesireMapState,
                    rhs: DesireMapState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.bothReady, .bothReady),
             (.fullyUnlocked, .fullyUnlocked):
            return true
        case (.youDone(let a), .youDone(let b)):
            return a == b
        case (.freeRevealSeen(let a), .freeRevealSeen(let b)):
            return a == b
        case (.redoInProgress(let a, let b),
              .redoInProgress(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }
}

extension ReflectionCardState: Equatable {
    static func == (lhs: ReflectionCardState,
                    rhs: ReflectionCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): return true
        default:                 return false
        }
    }
}

// MARK: - Previews

#Preview("Dark — Day Zero, Solo") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Day Zero, Invite Pending") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .youDone(partnerName: "Alex"),
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Mid Deck, Both Map Ready") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .bothReady,
        reflectionCardState: .pendingYours(
            sessionLabel: "Stage 1 · Session 1",
            sessionDate:  Date().addingTimeInterval(-172800)
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [
            .partnerCompletedDesireMap(partnerName: "Alex")
        ]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Both Reflected, Summary") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .summary(
            arc:           "You've moved from something heavy surfacing to feeling connected twice running.",
            yourName:      "Jordan",
            yourDots:      [true, true, true],
            partnerName:   "Alex",
            partnerDots:   [true, true, false],
            swipePosition: 2
        ),
        pickUpItems:         [
            PickUpItem(
                contentType: .timelineScenario(
                    branchCurrent: 2, branchTotal: 4),
                title:       "Alex is home. Sam has been quiet.",
                contextLine: "You're at branch point 2 of 4",
                actionLabel: "Continue →"
            )
        ],
        stageIndex:          1,
        cardsCompleted:      8,
        recentEvents:        []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Deck Complete") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .freeRevealSeen(partnerName: "Alex"),
        reflectionCardState: .bothReflected(
            sessionLabel: "Stage 1 · Session 4",
            yourName:     "Jordan",
            yourPills:    ["Connected", "Surprised"],
            yourNote:     "Didn't expect to feel that settled.",
            partnerName:  "Alex",
            partnerPills: ["Heavy", "Want to talk more"],
            partnerNote:  nil,
            swipePosition: 0
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      12,
        recentEvents:        [.stageCompleted(stageName: "Curiosity")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Waiting on Partner") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [.daysSinceSession(3, partnerName: "Alex")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Reflection Banner") {
    HomeDashboardView(
        displayName:          "Jordan",
        partnerChipState:     .active(name: "Alex", initial: "A"),
        cards:                Prompt.samples,
        desireMapState:       .hidden,
        reflectionCardState:  .hidden,
        pickUpItems:          [],
        stageIndex:           1,
        cardsCompleted:       3,
        recentEvents:         [],
        showReflectionBanner: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Light — Day Zero") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .preferredColorScheme(.light)
}

#Preview("Dark — No Name") {
    HomeDashboardView(
        displayName:         "",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Home/HomeStates.swift` {#file-open-lightly-features-home-homestates-swift}

```swift
//
//  HomeStates.swift
//  Open Lightly
//
//  Consolidated home state views — Gate, Waiting, and MatchReady.
//  Each struct represents a distinct navigation state in the HomeRouterView.
//

import SwiftUI

// MARK: - HomeGateView

struct HomeGateView: View {
    let isPaired: Bool
    let onStartMap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible     = false
    @State private var cardVisible       = false
    @State private var detailVisible     = false
    @State private var ctaVisible        = false
    @State private var hasAnimated       = false

    // Subtle breathing glow behind the CTA
    @State private var breathe: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let topPad      = max(16.0, h * 0.04)
            let sectionGap  = max(20.0, h * 0.032)
            let cardPad     = max(16.0, h * 0.022)

            ViewThatFits(in: .vertical) {

                // Attempt 1 — preferred, no scroll
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap,
                                 cardPad: cardPad, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, 24)
                }

                // Attempt 2 — scroll fallback (SE + large text)
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap,
                                     cardPad: cardPad, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // ...existing code...
    private func contentBlock(
        h: CGFloat,
        sectionGap: CGFloat,
        cardPad: CGFloat,
        topPad: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionGap) {

            // ── Overline ───────────────────────────────────────────
            Text("STEP 1 OF 2")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(colorScheme == .light
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.magenta, AppColors.gold],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(AppColors.cyanLight))
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Before you can see")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Text("what you share —")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Gradient keyword line
                Text("know what YOU want.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(
                        colorScheme == .light
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppColors.magenta, AppColors.gold],
                                startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing))
                    )
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Info card ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                infoRow(
                    icon: "lock.fill",
                    text: "17 questions. Your answers stay **completely private**."
                )
                infoRow(
                    icon: "clock.fill",
                    text: "About **5 minutes**. No wrong answers."
                )
                infoRow(
                    icon: "eye.slash.fill",
                    text: isPaired
                        ? "Your partner **never sees** your individual answers — only what you both agree on."
                        : "When your partner joins, they'll **never see** your individual answers."
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, cardPad)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.lightBorder
                            : AppColors.border,
                        lineWidth: 1
                    )
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 12)

            // ── Reassurance ────────────────────────────────────────
            Text("There are no right answers. Just yours.")
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(detailVisible ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, topPad)
        .padding(.bottom, 16)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(colorScheme == .light
                        ? AppColors.magenta.opacity(0.08)
                        : AppColors.cyan.opacity(0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
            }
            .fixedSize()

            // Markdown-style bold text
            Text(parseInlineBold(text))
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    private var ctaBlock: some View {
        VStack(spacing: 16) {

            // Primary CTA
            HoloCTAButton(
                title: "Start Your Desire Map",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartMap()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            // Education escape hatch
            Button {
                // Route to Learn tab
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Browse the education library while you wait")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .easeOut(duration: 0.4).delay(0.1),
                value: ctaVisible
            )

            // Footer
            OnboardingFooter(text: "Your answers are encrypted and never leave your device.")
        }
    }

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Atmospheric ellipse — purple top wash
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.25),
                            AppColors.deepBlue.opacity(0.12),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.55)
                    .offset(y: -h * 0.1)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { detailVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible    = true }

        // Breathing glow loop — starts after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    private func parseInlineBold(_ raw: String) -> AttributedString {
        var result = AttributedString()
        let parts  = raw.components(separatedBy: "**")
        for (i, part) in parts.enumerated() {
            var segment = AttributedString(part)
            if i % 2 == 1 {
                segment.font = AppFonts.bodyMedium
            }
            result.append(segment)
        }
        return result
    }
}

// MARK: - HomeWaitingView

struct HomeWaitingView: View {
    let isPaired: Bool
    let partnerName: String
    let onInvite: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible  = false
    @State private var statusVisible  = false
    @State private var ctaVisible     = false
    @State private var secondaryVisible = false
    @State private var hasAnimated    = false
    @State private var pulsing        = false

    private var displayPartnerName: String {
        partnerName.isEmpty ? "your partner" : partnerName
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    contentBlock(h: h)
                }
                ctaBlock
                    .padding(.horizontal, 24)
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // ...existing code...
    private func contentBlock(h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(24.0, h * 0.036)) {

            // ── Overline ───────────────────────────────────────────
            Text("YOUR PART IS DONE")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppColors.cyanLight)
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(isPaired
                     ? "Now we wait for"
                     : "Invite your partner")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isPaired {
                    Text(displayPartnerName + ".")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Partner status indicator ───────────────────────────
            if isPaired {
                partnerStatusCard
                    .opacity(statusVisible ? 1 : 0)
                    .offset(y: statusVisible ? 0 : 12)
            }

            // ── Context copy ───────────────────────────────────────
            Text(isPaired
                 ? "Their answers are private too. When they're done, you'll see what you have in common."
                 : "They'll complete their own map privately. When you're both done, you'll see your first shared result.")
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(statusVisible ? 1 : 0)
                .offset(y: statusVisible ? 0 : 8)

            // ── While you wait ─────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                Text("While you wait")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)

                whileYouWaitRow(
                    icon: "books.vertical.fill",
                    text: "Browse the education library",
                    action: { /* route to Learn tab */ }
                )
                whileYouWaitRow(
                    icon: "eye.fill",
                    text: "Preview your first conversation deck",
                    action: { /* route to deck preview */ }
                )
            }
            .opacity(secondaryVisible ? 1 : 0)
            .offset(y: secondaryVisible ? 0 : 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 16)
    }

    private var partnerStatusCard: some View {
        HStack(spacing: 14) {
            // Pulsing pending indicator
            ZStack {
                Circle()
                    .fill(AppColors.cyan.opacity(pulsing ? 0.15 : 0.06))
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulsing ? 1.15 : 1.0)

                Circle()
                    .fill(AppColors.cyan.opacity(0.3))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayPartnerName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                Text("Map in progress...")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }

            Spacer()

            Text("Waiting")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(colorScheme == .light
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.06))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightCardFill
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }

    private func whileYouWaitRow(
        icon: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.purple
                        : AppColors.cyanLight)
                    .frame(width: 20)

                Text(text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var ctaBlock: some View {
        VStack(spacing: 16) {
            HoloCTAButton(
                title: isPaired
                    ? "Remind \(displayPartnerName)"
                    : "Invite Your Partner",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onInvite()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            OnboardingFooter(
                text: isPaired
                    ? "We won't tell them how you answered."
                    : "They'll set up their own account and complete the map privately."
            )
        }
    }

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.20),
                            AppColors.deepBlue.opacity(0.10),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.50)
                    .offset(y: -h * 0.08)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { statusVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { secondaryVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible       = true }

        // Pulsing partner status loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

// MARK: - HomeMatchReadyView

struct HomeMatchReadyView: View {
    let onReveal: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var readyVisible   = false
    @State private var bodyVisible    = false
    @State private var ctaVisible     = false
    @State private var togetherVisible = false
    @State private var hasAnimated    = false

    // Spectrum bloom breathing — this screen's signature
    @State private var bloom: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                Spacer()

                // ── Core content — deliberately centered ──────────
                VStack(spacing: max(24.0, h * 0.034)) {

                    // Particle burst placeholder
                    // Replace with ParticleBurstView when built (Risk 3 in DESIGN_DOC)
                    HStack(spacing: 12) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(
                                    [AppColors.cyan, AppColors.purple,
                                     AppColors.magenta, AppColors.cyan,
                                     AppColors.purple][i]
                                    .opacity(bloom ? 0.9 : 0.4)
                                )
                                .frame(width: 6, height: 6)
                                .scaleEffect(bloom ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.18),
                                    value: bloom
                                )
                        }
                    }
                    .opacity(readyVisible ? 1 : 0)

                    // Headline
                    VStack(spacing: 6) {
                        Text("You're both ready.")
                            .font(AppFonts.heroTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .light
                                        ? [AppColors.magenta, AppColors.gold]
                                        : [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .opacity(readyVisible ? 1 : 0)
                    .offset(y: readyVisible ? 0 : 16)

                    // Body
                    Text("One thing you agree on\nis waiting to be seen.")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(bodyVisible ? 1 : 0)
                }
                .padding(.horizontal, 32)

                Spacer()

                // ── CTA — pinned to bottom ─────────────────────────
                VStack(spacing: 12) {
                    HoloCTAButton(
                        title: "See Your First Match",
                        isEnabled: true
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onReveal()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(ctaVisible ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

                    // "Do this together" — only instruction on this screen
                    Text("Do this together.")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(togetherVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // ...existing code...
    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Tri-color bloom — all three spectrum colors present
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.cyan.opacity(bloom ? 0.18 : 0.10),
                            AppColors.purple.opacity(bloom ? 0.14 : 0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 400
                    ))
                    .frame(width: w * 1.6, height: h * 0.6)
                    .offset(y: -h * 0.05)
                    .blur(radius: 90)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(bloom ? 0.12 : 0.06),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 300
                    ))
                    .frame(width: w * 1.2, height: h * 0.4)
                    .offset(y: h * 0.15)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: bloom)
    }

    private func runEntranceAnimations() {
        // Deliberate slowness — this screen gets more ceremony
        withAnimation(.easeOut(duration: 0.7).delay(0.30)) { readyVisible    = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.60)) { bodyVisible     = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.90)) { ctaVisible      = true }
        withAnimation(.easeOut(duration: 0.4).delay(1.05)) { togetherVisible = true }

        // Bloom breathing — starts after content settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bloom = true
            }
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/HomeRouterView.swift` {#file-open-lightly-features-home-homerouterview-swift}

```swift
//
//  HomeState.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeRouterView.swift
// Open Lightly
//
// Root router for the Home tab.
// Reads UserProfile + Couple state and renders the correct home experience.
// All tab-locking logic lives here — single source of truth.
//
// State machine:
//   S1 — unpaired, map incomplete      → HomeGateView
//   S2 — unpaired, map complete        → PostMapReflectionView (if needed) → HomeWaitingView
//   S3 — paired, my map incomplete     → HomeGateView
//   S4 — paired, waiting on partner    → HomeWaitingView
//   S5 — both complete, no reveal yet  → HomeMatchReadyView
//   S6 — reveal done                   → HomeDashboardView

import SwiftUI

enum HomeState: Equatable {
    case gated              // S1 / S3 — map not done
    case postReflection     // R1 / R2 / R3 — post-map reflection stems
    case waiting            // S4 — waiting on partner
    case matchReady         // S5 — both done, reveal pending
    case dashboard          // S6 — full experience
}

struct HomeRouterView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Injected from DataStore / AppState
    // These will be @Bindable SwiftData models in the real implementation.
    // Using simple @State here so the file compiles standalone for now.
    @State private var myMapComplete: Bool          = false
    @State private var partnerMapComplete: Bool     = false
    @State private var isPaired: Bool               = false
    @State private var revealDone: Bool             = false
    @State private var postReflectionDone: Bool     = false
    @State private var reflectionStep: Int          = 1    // 1, 2, or 3

    // Derived state — single computed property drives all routing
    private var homeState: HomeState {
        guard myMapComplete else         { return .gated }
        guard postReflectionDone else    { return .postReflection }
        guard isPaired && partnerMapComplete else { return .waiting }
        guard revealDone else            { return .matchReady }
        return .dashboard
    }

    var body: some View {
        ZStack {
            switch homeState {
            case .gated:
                HomeGateView(
                    isPaired: isPaired,
                    onStartMap: { /* route to DesireMapView */ }
                )
                .transition(.opacity)

            case .postReflection:
                PostMapReflectionView(
                    step: $reflectionStep,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            postReflectionDone = true
                        }
                    },
                    onSkipAll: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            postReflectionDone = true
                        }
                    }
                )
                .transition(.opacity)

            case .waiting:
                HomeWaitingView(
                    isPaired: isPaired,
                    partnerName: "your partner", // replace with real partner name
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                HomeDashboardView()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: homeState)
    }
}

// MARK: - Tab Lock Helper
// Called from the tab bar coordinator to determine which tabs are accessible.
// Single source of truth — no logic scattered across tab items.

extension HomeRouterView {
    static func isTabLocked(_ tab: AppTab, homeState: HomeState) -> Bool {
        switch homeState {
        case .dashboard:
            return false // All tabs open
        default:
            // Only Home and More are accessible during gate/waiting/reveal states
            return tab == .meUs || tab == .explore
        }
    }
}
```

---

## File: `Open Lightly/Features/Home/Components/HomeCardCarousel.swift` {#file-open-lightly-features-home-components-homecardcarousel-swift}

```swift
// Features/Home/Components/HomeCardCarousel.swift
// Open Lightly

import SwiftUI

// MARK: - Supporting Types

enum CarouselPhase: Equatable {
    case spread
    case gathering
    case lifted
    case carousel
}

enum CarouselDirection {
    case next
    case prev
}

enum CardAction {
    case discussed
    case notReady
    case bookmark
}

// MARK: - Layout Constants

private let cardW: CGFloat = 300
private let cardH: CGFloat = 190

// 6-Card Converging Fan — indexes: [Far L, Far R, Mid L, Mid R, In L, In R]
private let spreadOffsets:   [CGFloat] = [-180,      180,       -120,      120,       -60,      60   ]
private let spreadRotations: [Double]  = [ -18,       18,        -12,       12,        -6,       6   ]
private let spreadYOffsets:  [CGFloat] = [  24,       24,         16,       16,         8,       8   ]
private let spreadScales:    [CGFloat] = [0.78,     0.78,       0.84,     0.84,       0.90,    0.90  ]
private let spreadOpacities: [Double]  = [0.25,     0.25,       0.50,     0.50,       0.75,    0.75  ]

// 6-Card Gathered State
private let gatheredYOffsets:  [CGFloat] = [15,   12,   9,    6,    4,    2   ]
private let gatheredOpacities: [Double]  = [0.30, 0.45, 0.60, 0.75, 0.85, 0.95]
private let gatheredScales:    [CGFloat] = [0.91, 0.93, 0.95, 0.96, 0.97, 0.98]

// MARK: - HomeCardCarousel

struct HomeCardCarousel: View {

    var cards: [Prompt]
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil

    @State private var phase:          CarouselPhase = .spread
    @State private var activeIndex:    Int     = 0
    @State private var dragOffset:     CGFloat = 0
    @State private var isDragging:         Bool    = false
    @State private var dragVelocity:       CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var specularPhase:      CGFloat = 0
    @State private var specularActive: Bool    = false
    @State private var borderRotation: Double  = 0.0
    
    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    private var activeCard: Prompt? {
        guard cards.indices.contains(activeIndex) else { return nil }
        return cards[activeIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            instructionLabel
            cardStack
            metadataCrossfade

            // Action buttons
            if phase == .lifted || phase == .carousel {
                actionButtons
                    .transition(.opacity.animation(
                        .easeIn(duration: 0.3).delay(0.2)))
                    .padding(.top, 16)
            }

            // Progress dots
            if phase == .carousel {
                progressDots
                    .transition(.opacity)
                    .padding(.top, 12)
            }
        }
        .onAppear {
            // Drives the animated gradient border
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                borderRotation = 360.0
            }
        }
    }

    // MARK: - Instruction Label

    @ViewBuilder
    private var instructionLabel: some View {
        if phase == .spread {
            Text("Tap to begin")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .transition(.opacity)
                .padding(.bottom, 12)
        } else {
            Color.clear.frame(height: 1)
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            auroraBloom
            backingCards
            carouselCards
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardH + 80)
        // Curtain lives in .background so it never contributes to layout sizing
        .background {
            Rectangle()
                .fill(Color.black.opacity(isLight ? 0.35 : 0.75))
                .frame(width: 3000, height: 3000)
                .opacity(phase == .spread ? 0 : 1)
                .allowsHitTesting(phase != .spread)
                .onTapGesture { handleDismissQuickview() }
        }
        .overlay { glassTrackpad }
        .scaleEffect(phase == .spread ? 0.75 : 1.0)
        .offset(y: phase == .spread ? 0 : -20)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.3)
                : .spring(response: 0.95, dampingFraction: 0.85),
            value: phase
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardStackA11yLabel)
        .accessibilityHint(cardStackA11yHint)
        .accessibilityAdjustableAction { direction in
            guard phase == .carousel else { return }
            switch direction {
            case .increment: navigateCarousel(direction: .next)
            case .decrement: navigateCarousel(direction: .prev)
            @unknown default: break
            }
        }
    }

    private var cardStackA11yLabel: String {
        phase == .carousel
            ? "Card \(activeIndex + 1) of \(cards.count). \(activeCard?.text ?? "")"
            : "Card deck. Tap to begin."
    }

    private var cardStackA11yHint: String {
        phase == .carousel
            ? "Swipe left or right to navigate cards"
            : "Double tap to open"
    }

    // MARK: - Glass Trackpad (drag overlay)

    private var glassTrackpad: some View {
        Color.white.opacity(0.001)
            .onTapGesture {
                if phase == .spread {
                    handleSpreadTap()
                } else if phase == .lifted {
                    handleDismissQuickview()
                }
            }
            .highPriorityGesture(
                (phase == .carousel || phase == .lifted)
                    ? DragGesture(minimumDistance: 5)
                        .onChanged { handleDragChanged($0) }
                        .onEnded   { handleDragEnded($0) }
                    : nil
            )
    }

   private func handleDragChanged(_ value: DragGesture.Value) {
        // AUTO-UPGRADE: Swiping while lifted instantly starts the carousel
        if phase == .lifted {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                phase = .carousel
            }
        }

        if dragOffset == 0 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        isDragging = true
        dragVelocity = value.translation.width - previousDragOffset
        
        // APEX HAPTIC: Fire a physical tick exactly when the card crosses the 50% center mark
        let currentProgress = abs(value.translation.width / (cardW + 16))
        let previousProgress = abs(previousDragOffset / (cardW + 16))
        if (currentProgress >= 0.5 && previousProgress < 0.5) ||
           (currentProgress < 0.5 && previousProgress >= 0.5) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        }

        previousDragOffset = value.translation.width

        let atStart = activeIndex == 0 && value.translation.width > 0
        let atEnd = activeIndex == cards.count - 1 && value.translation.width < 0

        if atStart || atEnd {
            if abs(value.translation.width) > 20 && abs(dragOffset) < 5 {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            dragOffset = value.translation.width * 0.35
        } else {
            dragOffset = value.translation.width
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        let predicted = value.predictedEndTranslation.width
        let threshold: CGFloat = 50

        var newIndex = activeIndex
        if (dragOffset < -threshold || predicted < -200) && activeIndex < cards.count - 1 {
            newIndex += 1
        } else if (dragOffset > threshold || predicted > 200) && activeIndex > 0 {
            newIndex -= 1
        }

        if newIndex != activeIndex {
            let shift: CGFloat = newIndex > activeIndex ? (cardW + 16) : -(cardW + 16)
            dragOffset += shift
            activeIndex = newIndex
            UISelectionFeedbackGenerator().selectionChanged()
            if !reduceMotion { triggerSpecularGlint() }
        }

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                isDragging = false
                dragOffset = 0
            }
        }

        dragVelocity       = 0
        previousDragOffset = 0
    }

    // MARK: - Metadata Crossfade

    @ViewBuilder
    private var metadataCrossfade: some View {
        if phase == .carousel, let card = activeCard {
            HStack(spacing: 8) {
                Text(card.category.displayName.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(AppColors.textTertiary)
                Text("·")
                    .foregroundStyle(AppColors.textTertiary)
                Text(card.difficulty.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(card.difficulty.glowColor)
            }
            .id(activeIndex)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 6)),
                removal:   .opacity.combined(with: .offset(y: -6))
            ))
            .animation(.easeOut(duration: 0.22), value: activeIndex)
            .padding(.top, 10)
        }
    }

    // MARK: - Aurora Bloom
    
    @ViewBuilder
    private var auroraBloom: some View {
        if let card = activeCard {
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        card.difficulty.glowColor
                            .opacity(phase == .spread ? 0.14 : 0.28),
                        card.difficulty.glowColor.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                ))
                .frame(width: 380, height: 260)
                .blur(radius: 60)
                // REACTIVE BREATHING: Background flares up during a drag
                .scaleEffect(isDragging ? 1.15 : 1.0)
                .opacity(isDragging ? 1.0 : 0.6)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.55), value: activeIndex)

            if phase == .carousel && !reduceMotion {
                let incoming = dragOffset < 0
                    ? min(activeIndex + 1, cards.count - 1)
                    : max(activeIndex - 1, 0)
                let bleed = min(abs(dragOffset) / 320, 1.0)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            cards[incoming].difficulty.glowColor
                                .opacity(bleed * 0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    ))
                    .frame(width: 380, height: 260)
                    .offset(x: dragOffset < 0 ? 50 : -50)
                    .blur(radius: 65)
                    .allowsHitTesting(false)
                    .animation(
                        isDragging ? .none : .easeOut(duration: 0.4),
                        value: dragOffset
                    )
            }
        }
    }

    // MARK: - Backing Cards

    private var backingCards: some View {
        ForEach(0..<6, id: \.self) { i in
            let isSpread = phase == .spread
            CardBackView(
                offsetX:  isSpread ? spreadOffsets[i]   : 0,
                offsetY:  isSpread ? spreadYOffsets[i]  : gatheredYOffsets[i],
                rotation: isSpread ? spreadRotations[i] : 0,
                scale:    isSpread ? spreadScales[i]    : gatheredScales[i],
                opacity:  phase == .carousel ? 0
                    : isSpread ? spreadOpacities[i]
                    : gatheredOpacities[i],
                isLight: isLight
            )
            .zIndex(Double(i))
            .offset(y: (phase == .lifted || phase == .carousel) ? -15 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.3)
                    : .spring(response: 0.85, dampingFraction: 0.80),
                value: phase
            )
        }
    }

    // MARK: - Unified Carousel Cards
    
    @ViewBuilder
    private var carouselCards: some View {
        if cards.isEmpty {
            EmptyView()
        } else {
            let minIdx = max(0, activeIndex - 2)
            let maxIdx = min(cards.count - 1, activeIndex + 2)

            ForEach(minIdx...maxIdx, id: \.self) { i in
                let relativeIndex = i - activeIndex
                
                let baseOffset = CGFloat(relativeIndex) * (cardW + 16)
                let rawX = phase == .carousel ? (baseOffset + dragOffset) : 0
                
                let progress = rawX / (cardW + 16)
                let clampedProgress = min(max(progress, -1.0), 1.0)
                let visualX = clampedProgress * (cardW * 0.55) // Tighter overlap

                if phase == .carousel || i == activeIndex {
                    ZStack {
                        PromptCard(prompt: cards[i], showDifficultyDots: false)
                            .frame(width: cardW, height: cardH)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .opacity(phase == .carousel && i != activeIndex ? 0.75 : 1.0)
                            
                            // NATIVE EDGE GLOW: Uses your exact AppColors border
                            .overlay {
                                ZStack {
                                    if isLight {
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
                                                    .blur(radius: phase == .carousel ? 10 * abs(clampedProgress) : 0)
                                                    .opacity(phase == .carousel ? abs(clampedProgress) : 0)
                                                    .blendMode(.plusDarker)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
                                                    .blur(radius: phase == .carousel ? 10 * abs(clampedProgress) : 0)
                                                    .opacity(phase == .carousel ? abs(clampedProgress) : 0)
                                                    .blendMode(.screen)
                                            )
                                    }
                                }
                            }
                            
                        // THE REAL-TIME LIGHT ROLL
                        if phase == .carousel {
                            LinearGradient(
                                colors: [.clear, .white.opacity(isLight ? 0.4 : 0.12), .clear],
                                startPoint: .init(x: 0.2 - (progress * 1.5), y: 0),
                                endPoint:   .init(x: 0.8 - (progress * 1.5), y: 1)
                            )
                            .blendMode(.screen)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .allowsHitTesting(false)
                        }

                        if i == activeIndex && specularActive && phase != .carousel {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white.opacity(isLight ? 0.14 : 0.08), location: 0.35),
                                        .init(color: .white.opacity(isLight ? 0.28 : 0.20), location: 0.50),
                                        .init(color: .white.opacity(isLight ? 0.14 : 0.08), location: 0.65),
                                        .init(color: .clear, location: 1),
                                    ],
                                    startPoint: .init(x: specularPhase * 1.4 - 0.4, y: 0),
                                    endPoint:   .init(x: specularPhase * 1.4 - 0.1, y: 1)
                                ))
                                .blendMode(.screen)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .frame(width: cardW, height: cardH)
                    .offset(x: phase == .carousel ? visualX : 0,
                            y: (phase == .lifted || phase == .carousel) ? -40 : 0)
                    
                    .scaleEffect(
                        phase == .carousel
                            ? max(0.75, 1.0 - abs(clampedProgress) * 0.25)
                            : (phase == .lifted ? 1.04 : 1.0)
                    )
                    
                    // DEPTH OF FIELD BLUR
                    .blur(radius: phase == .carousel ? abs(clampedProgress) * 2.5 : 0)
                    
                    .rotation3DEffect(
                        (phase == .carousel && !reduceMotion)
                            ? .degrees(Double(clampedProgress * -25.0)) : .zero,
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.25
                    )
                    
                    .zIndex(100.0 - Double(abs(progress) * 10))
                    .allowsHitTesting(false)
                    
                    // DEEP SHADOW: Pushes the active card forward visually
                    .shadow(
                        color: (phase == .lifted || phase == .carousel)
                            ? cards[i].difficulty.glowColor.opacity(
                                (i == activeIndex ? 0.35 : 0.0) + (abs(clampedProgress) * 0.45)
                              )
                            : .clear,
                        radius: phase == .carousel ? 36 + (abs(clampedProgress) * 45) : 36,
                        y: 18
                    )
                    .animation(.spring(response: 0.55, dampingFraction: 0.80), value: phase)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let card = activeCard {
                HStack(spacing: 10) {
                    actionButton(label: "✓ Discussed",
                                 color: AppColors.cyan) {
                        onCardAction?(card, .discussed)
                    }
                    .accessibilityLabel("Mark as Discussed")

                    actionButton(label: "→ Not Ready",
                                 color: AppColors.textTertiary) {
                        onCardAction?(card, .notReady)
                    }
                    .accessibilityLabel("Skip — not ready")

                    actionButton(label: "🔖",
                                 color: AppColors.gold) {
                        onCardAction?(card, .bookmark)
                    }
                    .accessibilityLabel("Bookmark")
                    .frame(width: 48)
                }
                .padding(.horizontal, 20)
            }

            Button {
                phase == .carousel
                    ? handleBackToDeck()
                    : handleBrowseDeck()
            } label: {
                Text(phase == .carousel
                     ? "← Back to deck" : "Browse Deck")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.20), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(cards.indices, id: \.self) { i in
                Capsule()
                    .fill(dotFill(index: i))
                    .frame(width: i == activeIndex ? 20 : 4, height: 3)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8),
                        value: activeIndex
                    )
                    .onTapGesture { activeIndex = i }
            }
        }
    }

    private func dotFill(index i: Int) -> AnyShapeStyle {
        guard i == activeIndex else {
            return AnyShapeStyle(AppColors.textTertiary.opacity(0.35))
        }
        let glow = cards[i].difficulty.glowColor
        let colors: [Color]
        if glow == AppColors.cyan {
            colors = [AppColors.cyan, AppColors.purple]
        } else if glow == AppColors.purple {
            colors = [AppColors.purple, AppColors.magenta]
        } else {
            colors = [AppColors.magenta, AppColors.pink]
        }
        return AnyShapeStyle(LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        ))
    }

    // MARK: - Specular Glint

    func triggerSpecularGlint() {
        guard !reduceMotion else { return }
        specularPhase  = 0
        specularActive = true
        withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.75)) {
            specularPhase = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            specularActive = false
            specularPhase  = 0
        }
    }

    // MARK: - Phase Transitions

    func handleSpreadTap() {
        guard phase == .spread else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.6, dampingFraction: 0.7)
        withAnimation(anim) { phase = .lifted }
        if !reduceMotion { triggerSpecularGlint() }
    }

    func handleBrowseDeck() {
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(anim) { phase = .carousel }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleDismissQuickview() {
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.6, dampingFraction: 0.8)
        withAnimation(anim) {
            phase = .spread
            activeIndex = 0
            dragOffset = 0
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func handleBackToDeck() {
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(anim) {
            phase       = .lifted
            activeIndex = 0
            dragOffset  = 0
        }
    }

    // MARK: - Carousel Navigation

    func navigateCarousel(direction: CarouselDirection) {
        let next = direction == .next
            ? min(activeIndex + 1, cards.count - 1)
            : max(activeIndex - 1, 0)

        guard next != activeIndex else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                dragOffset = 0
            }
            return
        }

        // Treadmill: instant swap with offset compensation so card slides in naturally
        let shift: CGFloat = next > activeIndex ? (cardW + 16) : -(cardW + 16)
        dragOffset += shift
        activeIndex = next
        UISelectionFeedbackGenerator().selectionChanged()
        if !reduceMotion { triggerSpecularGlint() }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            dragOffset = 0
        }
    }
}

// MARK: - Previews

#Preview("Spread — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HomeCardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.dark)
}

#Preview("Spread — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HomeCardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Home/Components/DesireMapIndicator.swift` {#file-open-lightly-features-home-components-desiremapindicator-swift}

```swift
// Home/Components/DesireMapIndicator.swift

import SwiftUI

struct DesireMapIndicator: View {
    let state: DesireMapState
    var onReveal: (() -> Void)? = nil
    var onUnlock: (() -> Void)? = nil
    var onRemind: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch state {
        case .hidden, .fullyUnlocked:
            EmptyView()

        case .youDone(let partnerName):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You're done")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary,
                                        lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Text(partnerName)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind \(partnerName) →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .bothReady:
            // Elevated treatment — highest CTA weight on screen
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Spacer()
                        Text("You're both ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                                .frame(width: 7, height: 7)
                            Text("You")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.gold
                                    : AppColors.purple)
                                .frame(width: 7, height: 7)
                            Text("Partner")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Spacer(minLength: 14)

                Button {
                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                    onReveal?()
                } label: {
                    Text("See Your First Match")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.wineDark
                            : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta.opacity(0.18),
                                                 AppColors.gold.opacity(0.14)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                        }
                        .shadow(color: colorScheme == .light
                            ? AppColors.lightShadowMagenta
                            : AppColors.purple.opacity(0.4),
                                radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AnyShapeStyle(
                            AppColors.warmAuroraBorder.opacity(0.6))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.5),
                                     AppColors.purple.opacity(0.4),
                                     AppColors.magenta.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)),
                        lineWidth: 1.5)
            }
            .shadow(color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.2),
                    radius: 20, y: 6)

        case .freeRevealSeen(_):
            statusCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.magenta.opacity(0.10)
                                : AppColors.purple.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.purple, AppColors.magenta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("1 match revealed")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                        Text("+ more waiting")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onUnlock?()
                    } label: {
                        Text("Unlock →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .redoInProgress(let partnerName, let partnerStarted):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("DESIRE MAP")
                                .font(AppFonts.overline)
                                .tracking(1.2)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary)
                            Text("· Check-in")
                                .font(AppFonts.overline)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You — redoing")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(partnerStarted
                                          ? (colorScheme == .light
                                              ? AppColors.gold
                                              : AppColors.purple)
                                          : Color.clear)
                                    .overlay {
                                        if !partnerStarted {
                                            Circle()
                                                .stroke(colorScheme == .light
                                                    ? AppColors.lightTextTertiary
                                                    : AppColors.textTertiary,
                                                    lineWidth: 1)
                                        }
                                    }
                                    .frame(width: 7, height: 7)
                                Text(partnerStarted
                                     ? "\(partnerName) in progress"
                                     : "\(partnerName) hasn't started")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(
                                        partnerStarted
                                        ? (colorScheme == .light
                                            ? AppColors.lightTextSecondary
                                            : AppColors.textSecondary)
                                        : (colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary)
                                    )
                            }
                        }
                    }
                    Spacer()
                    if !partnerStarted {
                        Button {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onRemind?()
                        } label: {
                            Text("Remind →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Shared card shell for compact states

    @ViewBuilder
    private func statusCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ReflectionCard.swift` {#file-open-lightly-features-home-components-reflectioncard-swift}

```swift
// Home/Components/ReflectionCard.swift

import SwiftUI

struct ReflectionCard: View {
    let state: ReflectionCardState
    var onMoreTap: (() -> Void)? = nil
    var onDone: (([String], String?) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var showFullPillSheet: Bool = false
    @State private var shareWithPartner: Bool = true

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .pendingYours(let sessionLabel, let sessionDate):
            pendingCard(sessionLabel: sessionLabel,
                        sessionDate: sessionDate)

        case .waitingOnPartner(let sessionLabel, let yourPills):
            waitingCard(sessionLabel: sessionLabel,
                        yourPills: yourPills)

        case .bothReflected(let sessionLabel,
                            let yourName, let yourPills, let yourNote,
                            let partnerName, let partnerPills,
                            let partnerNote, let swipePosition):
            bothReflectedCard(
                sessionLabel: sessionLabel,
                yourName: yourName, yourPills: yourPills,
                yourNote: yourNote,
                partnerName: partnerName,
                partnerPills: partnerPills,
                partnerNote: partnerNote,
                swipePosition: swipePosition
            )

        case .summary(let arc, let yourName, let yourDots,
                      let partnerName, let partnerDots,
                      let swipePosition):
            summaryCard(
                arc: arc,
                yourName: yourName, yourDots: yourDots,
                partnerName: partnerName, partnerDots: partnerDots,
                swipePosition: swipePosition
            )
        }
    }

    // MARK: - Pending State

    private func pendingCard(sessionLabel: String,
                              sessionDate: Date) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionLabel)
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Text(sessionDate.relativeString)
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                }

                Text("How did that land?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isWritingNote {
                    // Journal mode
                    TextEditor(text: $noteText)
                        .frame(minHeight: 80)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                } else {
                    // Pill row — 5 inline defaults
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            pillButton(pill)
                        }
                    }

                    HStack {
                        Button {
                            showFullPillSheet = true
                        } label: {
                            Text("More →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }

                // Switch mode link
                Button {
                    isWritingNote.toggle()
                } label: {
                    Text(isWritingNote
                         ? "← Use pills instead"
                         : "✎ Write a note instead")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle
                HStack {
                    Text("Share with partner")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                    Spacer()
                    Toggle("", isOn: $shareWithPartner)
                        .labelsHidden()
                        .tint(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                }

                // Done + Not now
                HStack {
                    Button("Not now") {}
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(18)
        }
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Waiting State

    private func waitingCard(sessionLabel: String,
                              yourPills: [String]) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    // Status dots
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                            .frame(width: 7, height: 7)
                    }
                }

                Text("You reflected.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Your pills read-only
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(yourPills, id: \.self) { pill in
                            Text(pill)
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .fill(colorScheme == .light
                                            ? AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.magenta.opacity(0.12),
                                                         AppColors.gold.opacity(0.10)],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                            : AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.cyan.opacity(0.2),
                                                         AppColors.purple.opacity(0.15)],
                                                startPoint: .leading,
                                                endPoint: .trailing)))
                                }
                        }
                    }
                }

                Text("Waiting for your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Both Reflected State

    private func bothReflectedCard(
        sessionLabel: String,
        yourName: String, yourPills: [String], yourNote: String?,
        partnerName: String, partnerPills: [String], partnerNote: String?,
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().fill(colorScheme == .light
                            ? AppColors.gold
                            : AppColors.purple)
                            .frame(width: 7, height: 7)
                    }
                }

                // Your section
                VStack(alignment: .leading, spacing: 6) {
                    Text(yourName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(yourPills,
                                  color: colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                    if let note = yourNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                Rectangle()
                    .fill(colorScheme == .light
                        ? Color.black.opacity(0.06)
                        : Color.white.opacity(0.06))
                    .frame(height: 1)

                // Partner section
                VStack(alignment: .leading, spacing: 6) {
                    Text(partnerName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(partnerPills,
                                  color: colorScheme == .light
                                      ? AppColors.gold
                                      : AppColors.purple)
                    if let note = partnerNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Summary State

    private func summaryCard(
        arc: String,
        yourName: String, yourDots: [Bool],
        partnerName: String, partnerDots: [Bool],
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                // Dot header
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < yourDots.count && yourDots[i]
                                  ? (colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                                  : Color.clear)
                            .overlay {
                                if !(i < yourDots.count && yourDots[i]) {
                                    Circle()
                                        .stroke(colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary,
                                            lineWidth: 1)
                                }
                            }
                            .frame(width: 7, height: 7)
                    }
                    Text("Last 3 sessions")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .padding(.leading, 4)
                }

                // Arc copy
                Text(arc)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Timeline rows
                VStack(alignment: .leading, spacing: 4) {
                    timelineRow(name: yourName, dots: yourDots)
                    timelineRow(name: partnerName, dots: partnerDots)
                }

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pillSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 80)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color.black.opacity(0.03)
                                        : Color.white.opacity(0.04))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightBorder
                                        : AppColors.border,
                                        lineWidth: 1)
                            }
                    }

                    // Share toggle
                    HStack {
                        Text("Share with partner")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyan)
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background((colorScheme == .light
                ? AppColors.lightPageBg
                : AppColors.pageBg).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSection(title: String,
                              pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(pills, id: \.self) { pill in
                    pillButton(pill)
                }
            }
        }
    }

    // MARK: - Shared Subviews

    private func pillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected {
                selectedPills.remove(pill)
            } else {
                selectedPills.insert(pill)
            }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.wineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.4),
                                             AppColors.purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple],
                                    startPoint: .leading, endPoint: .trailing)))
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.lightBorder
                                : AppColors.border),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func pillsReadOnly(_ pills: [String],
                                color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(pills, id: \.self) { pill in
                    Text(pill)
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(color.opacity(0.15))
                        }
                        .overlay {
                            Capsule()
                                .stroke(color.opacity(0.3),
                                        lineWidth: 1)
                        }
                }
            }
        }
    }

    private func timelineRow(name: String,
                              dots: [Bool]) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .frame(width: 60, alignment: .leading)

            Text("──")
                .font(.system(size: 9))
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            ForEach(0..<dots.count, id: \.self) { i in
                if dots[i] {
                    Circle().fill(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
                        .frame(width: 7, height: 7)
                } else {
                    Circle()
                        .stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                        .frame(width: 7, height: 7)
                }
                if i < dots.count - 1 {
                    Text("──")
                        .font(.system(size: 9))
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
            }
        }
    }

    private var cardFooter: some View {
        HStack {
            Spacer()
            Button {
                onMoreTap?()
            } label: {
                Text("More ↗")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func cardShell<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeString: String {
        let days = Calendar.current.dateComponents(
            [.day], from: self, to: Date()
        ).day ?? 0
        switch days {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        case 2:  return "Two days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last \(formatter.string(from: self))"
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ResearchTicker.swift` {#file-open-lightly-features-home-components-researchticker-swift}

```swift
// Home/Components/ResearchTicker.swift

import SwiftUI

struct ResearchTicker: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private let facts: [ResearchFact] = [
        ResearchFact(category: .research,
            body: "1 in 5 Americans has engaged in CNM\nat some point in their lives.",
            attribution: "— Haupert et al., 2017"),
        ResearchFact(category: .research,
            body: "Communication quality is measurably higher\nin CNM relationships. The structure demands it.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .research,
            body: "The biggest predictor of success isn't\ncompatibility — it's whether both people\ngenuinely chose this.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .definition,
            body: "Compersion: feeling joy at your partner's\nhappiness with someone else.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "NRE — New Relationship Energy:\nthe heightened feeling of a new connection.\nReal, temporary, manageable.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "Metamour: your partner's partner.\nSomeone you may never meet — or become\nclose friends with.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Jealousy is information,\nnot evidence that something is wrong.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Most people who explore CNM\nweren't unhappy. They were curious.",
            attribution: nil),
        ResearchFact(category: .research,
            body: "People who live in alignment with their\nactual desires report lower anxiety —\nregardless of what those desires are.",
            attribution: "— Moors et al., 2017"),
        ResearchFact(category: .reframe,
            body: "Sexual and romantic attraction are\nindependent dimensions. Both matter.\nNeither determines the other.",
            attribution: "— Diamond, 2003"),
    ]

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0

    private let displayDuration: TimeInterval = 10
    private let fadeDuration: TimeInterval = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                // Overline
                Text(facts[currentIndex].category.overlineLabel)
                    .font(AppFonts.overline)
                    .tracking(1.2)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                // Body
                Text(facts[currentIndex].body)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                // Attribution if exists
                if let attribution = facts[currentIndex].attribution {
                    Text(attribution)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
            }
            .opacity(opacity)
            .padding(.vertical, 14)

            // Bottom separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
        .onAppear {
            startCycle()
        }
    }

    private func startCycle() {
        Timer.scheduledTimer(withTimeInterval: displayDuration,
                             repeats: true) { _ in
            // Fade out
            withAnimation(.easeInOut(duration: fadeDuration)) {
                opacity = 0
            }
            // Swap fact + fade in
            DispatchQueue.main.asyncAfter(
                deadline: .now() + fadeDuration + 0.1
            ) {
                currentIndex = (currentIndex + 1) % facts.count
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview("Ticker Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.dark)
}

#Preview("Ticker Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Home/Components/PartnerChip.swift` {#file-open-lightly-features-home-components-partnerchip-swift}

```swift
// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    var onInviteTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        switch state {
        case .none:
            EmptyView()

        case .invitePending:
            Button {
                onInviteTap?()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text("Invite partner")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(isLight
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(isLight
                            ? AppColors.lightFrostCard
                            : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .stroke(isLight
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.10),
                            lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

        case .active(let name, let initial):
            HStack(spacing: 6) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(isLight
                            ? Color.black.opacity(0.08)
                            : Color.white.opacity(0.12))
                        .frame(width: 18, height: 18)
                    Text(String(initial))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : .white)
                }
                Text(name)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(isLight
                        ? AppColors.lightFrostCard
                        : Color.white.opacity(0.04))
            }
            .overlay {
                Capsule()
                    .stroke(isLight
                        ? AppColors.lightBorder
                        : Color.white.opacity(0.08),
                        lineWidth: 1)
            }
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/PickUpCard.swift` {#file-open-lightly-features-home-components-pickupcard-swift}

```swift
// Home/Components/PickUpCard.swift

import SwiftUI

struct PickUpCard: View {
    let items: [PickUpItem]
    var onItemTap: ((PickUpItem) -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.prefix(2)) { item in
                    itemCard(item)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onItemTap?(item)
                        }
                }

                if items.count > 2 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all in-progress →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
        }
    }

    private func itemCard(_ item: PickUpItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.contentType.label)
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyanLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.08)
                                    : AppColors.cyan.opacity(0.12))
                        }
                        .overlay {
                            Capsule()
                                .stroke(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.20)
                                    : AppColors.cyan.opacity(0.25),
                                    lineWidth: 1)
                        }

                    Spacer()

                    // Pulsing amber dot
                    Circle()
                        .fill(Color(red: 1, green: 0.72, blue: 0))
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(item.contextLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(item.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .lineLimit(2)

                Text(item.actionLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightFrostCard
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }
}

private extension PickUpContentType {
    var label: String {
        switch self {
        case .timelineScenario: return "TIMELINE"
        case .article:          return "ARTICLE"
        case .judgmentCall:      return "JUDGMENT"
        case .autopsy:          return "AUTOPSY"
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ReflectionBannerView.swift` {#file-open-lightly-features-home-components-reflectionbannerview-swift}

```swift
// Home/Components/ReflectionBannerView.swift

import SwiftUI

struct ReflectionBannerView: View {
    let sessionLabel: String
    let partnerName: String?
    var onDone: (([String], String?, Bool) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var shareWithPartner: Bool = true
    @State private var showFullPillSheet: Bool = false

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.15)
                    : Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Text("How did that land for you?")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                }

                if isWritingNote {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 70)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                } else {
                    // 5 default pills in 2 rows
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            bannerPillButton(pill)
                        }
                    }

                    Button {
                        showFullPillSheet = true
                    } label: {
                        Text("More →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }

                // Mode toggle
                Button {
                    isWritingNote.toggle()
                } label: {
                    Text(isWritingNote
                         ? "← Use pills instead"
                         : "✎ Write a note instead")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle (only if has partner)
                if let name = partnerName {
                    HStack {
                        Text("Share with \(name)")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyan)
                    }
                }

                // Done + Not now
                HStack {
                    Button("Not now") {
                        dismiss()
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty
                              && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill((colorScheme == .light
                            ? AppColors.lightCardFill
                            : AppColors.cardBg).opacity(0.85))
                }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .light
                    ? AnyShapeStyle(
                        AppColors.warmAuroraBorder.opacity(0.5))
                    : AnyShapeStyle(LinearGradient(
                        colors: [AppColors.cyan.opacity(0.4),
                                 AppColors.purple.opacity(0.3),
                                 AppColors.magenta.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)),
                    lineWidth: 1.5)
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.12),
            radius: 20, y: 6
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Pill Button

    private func bannerPillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected { selectedPills.remove(pill) }
            else          { selectedPills.insert(pill) }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.wineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.35),
                                             AppColors.purple.opacity(0.25)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(Color.clear))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta,
                                             AppColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan,
                                             AppColors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.lightBorder
                                : AppColors.border),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pillSheetSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSheetSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSheetSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 80)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color.black.opacity(0.03)
                                        : Color.white.opacity(0.04))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightBorder
                                        : AppColors.border,
                                        lineWidth: 1)
                            }
                    }

                    if let name = partnerName {
                        HStack {
                            Text("Share with \(name)")
                                .font(AppFonts.bodyText)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary)
                            Spacer()
                            Toggle("", isOn: $shareWithPartner)
                                .labelsHidden()
                                .tint(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                        }
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background((colorScheme == .light
                ? AppColors.lightPageBg
                : AppColors.pageBg).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSheetSection(title: String,
                                   pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(pills, id: \.self) { pill in
                    bannerPillButton(pill)
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35,
                               dampingFraction: 0.8)) {
            onDismiss?()
        }
    }
}

```

---

## ⚠️ Files Listed But Not Found — These Need To Be Created

> The following files do not exist yet.
> They represent the exact new files the check-in feature requires.
> Use the React prototype below as the port specification.

- `Open Lightly/Design/Components/CardLayout.swift`
- `Open Lightly/Models/Prompt.swift`
- `Open Lightly/Features/Home/CheckIn/CheckInPhase.swift`
- `Open Lightly/Features/Home/CheckIn/DailyCheckInView.swift`
- `Open Lightly/Features/Home/CheckIn/CheckInQuestionView.swift`
- `Open Lightly/Features/Home/CheckIn/CheckInResolutionView.swift`
- `Open Lightly/Features/Home/Components/RelationalWeather.swift`
- `Open Lightly/Models/RelationalWeatherEntry.swift`
- `Open Lightly/Models/CheckInEntry.swift`

---

## React Prototype — Port Reference

> This is the working React/JS implementation.
> All tier thresholds, dy math, camera step geometry, and
> cinematic timing values should be ported 1:1 to SwiftUI.
>
> Key translation map:
>   useState(dotY)          → @State var dotY: Double
>   useState(glowColor)     → @State var glowColor: Color
>   useState(camScale/Tx/Ty)→ @State var camScale/camTx/camTy: CGFloat
>   CSS transform: translateY → .offset(y:).animation(.spring(response:0.5))
>   CSS transform: scale      → .scaleEffect().animation(.easeInOut(duration:))
>   stroke-dashoffset 0→len  → Path.trim(from:0, to: progress).animation()
>   setTimeout(fn, ms)       → DispatchQueue.main.asyncAfter(deadline: .now() + s)

```jsx
// PASTE FULL REACT ARTIFACT SOURCE HERE
// (copy from the artifact window before running this script)
```

---

