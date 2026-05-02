// App/Theme/AppColors.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 2 — Semantic color tokens.
//
// Rules:
//   • Every token has ONE name describing purpose, not appearance
//   • Every token resolves automatically for light and dark via
//     UIColor(dynamicProvider:) — no manual branching in views
//   • Every token maps exclusively to VaylPrimitives values
//   • Every token has a one-line use context comment
//   • VaylPrimitives is NEVER referenced outside this file
//
// Light = Dawn mode   (warm cream, refractive atmosphere)
// Dark  = Midnight mode (deep ink, emissive glows)
// ─────────────────────────────────────────────────────────────

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Backgrounds — elevation hierarchy
    //
    // Page → Card → Modal. Never nest a higher
    // elevation color inside a lower one.
    // ─────────────────────────────────────────────

    /// Root view background. One per screen, never nested.
    static let pageBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkBase
    )

    /// Content containers that sit directly on pageBackground.
    static let cardBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkCard
    )

    /// Second-tier elevated cards that sit on cardBackground.
    static let cardBackgroundRaised = Color.dynamic(
        light: UIColor(red: 1.0,   green: 0.957, blue: 0.965, alpha: 1),
        dark:  UIColor(red: 0.086, green: 0.078, blue: 0.141, alpha: 0.92)
    )

    /// Sheets, modals, overlays. Always sits above cardBackground.
    static let modalBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkSurface
    )

    /// Input fields and inset wells. Recessed below pageBackground.
    static let inputBackground = Color.dynamic(
        light: VaylPrimitives.offWhite,
        dark:  VaylPrimitives.inkRaised
    )

    /// Home widget base layers only. Between page and card elevation.
    static let widgetBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkWidget
    )

    /// Constellation node core fill. Slightly lighter than pageBackground with a
    /// purple undertone. Distinct from cardBackground / modalBackground — not a
    /// general surface token; use only in ConstellationView node circles.
    static let constellationNodeCore = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkNodeCore
    )

    // ─────────────────────────────────────────────
    // MARK: Text — hierarchy
    //
    // Never use a lower-hierarchy token for primary content.
    // ─────────────────────────────────────────────

    /// Headings, screen titles, display text.
    static let textPrimary = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  UIColor(hex: "#E8E8F0")
    )

    /// Paragraph content, card text, descriptions.
    static let textBody = Color.dynamic(
        light: VaylPrimitives.wineMid,
        dark:  UIColor.white
    )

    /// Labels, descriptions, supporting copy. 60% hierarchy.
    static let textSecondary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.60),
        dark:  UIColor.white.withAlphaComponent(0.65)
    )

    /// Timestamps, metadata, counts. 38% hierarchy.
    /// Apply .italic() at usage site — italic is the semantic signal.
    static let textTertiary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.38),
        dark:  UIColor.white.withAlphaComponent(0.38)
    )

    /// Placeholder text, pronoun hints, inline helper copy.
    static let textHint = Color.dynamic(
        light: VaylPrimitives.magentaDark.withAlphaComponent(0.50),
        dark:  UIColor.white.withAlphaComponent(0.42)
    )

    /// Disabled states, ghost copy. Lowest visible hierarchy.
    static let textMuted = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.22),
        dark:  UIColor.white.withAlphaComponent(0.20)
    )

    /// Overline labels and status counts. Must survive a tinted
    /// ambient background — device-absolute, never tinted.
    static let textBright = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  UIColor(white: 0.90, alpha: 1)
    )

    /// Tappable links and accent body text.
    static let textAccent = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    /// Card overline and section labels with spectrum tint.
    static let textCardLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.70),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.60)
    )

    // ─────────────────────────────────────────────
    // MARK: Accent — action and emphasis
    // ─────────────────────────────────────────────

    /// Primary interactive accent. CTAs, active states, focus rings.
    /// Midnight: cyan (emissive). Dawn: magenta (refractive).
    static let accentPrimary = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Secondary accent. Decorative spectrum, orbit trails.
    static let accentSecondary = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Tertiary accent. Badge fills, atmospheric tints.
    static let accentTertiary = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default card and surface border. Barely visible structural edge.
    static let borderSubtle = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.06),
        dark:  UIColor.white.withAlphaComponent(0.06)
    )

    /// Hover and focus border. Slightly more present than subtle.
    static let borderDefault = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.10),
        dark:  UIColor.white.withAlphaComponent(0.10)
    )

    /// Active, selected, or structural border.
    static let borderActive = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.15),
        dark:  UIColor.white.withAlphaComponent(0.15)
    )

    /// Accent-tinted border. Focus rings on accent inputs.
    static let borderAccent = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.22),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.20)
    )

    /// Purple-tinted structural border. Cards and fields in light mode.
    static let borderPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.14),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.14)
    )

    // ─────────────────────────────────────────────
    // MARK: Feedback states
    // ─────────────────────────────────────────────

    /// Destructive actions, error states, irreversible confirmations.
    static let destructive = Color.dynamic(
        light: VaylPrimitives.destructiveRed,
        dark:  VaylPrimitives.destructiveRed
    )

    /// Success confirmations, completed states.
    static let success = Color.dynamic(
        light: VaylPrimitives.successGreen,
        dark:  VaylPrimitives.successGreen
    )

    // ─────────────────────────────────────────────
    // MARK: Gold — safety signal
    //
    // At full or near-full opacity: safety signals only.
    // (safe word button, warnings, hard stop actions)
    // Aurora atmospheric use at ≤8% opacity is acceptable —
    // it cannot be read as a directional signal at that opacity.
    // If it is visible enough to be noticed as gold, it is
    // too opaque for non-safety use.
    // ─────────────────────────────────────────────

    /// Safety signal accent. Safe word, warnings, hard stops only.
    static let safetyAccent = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    /// Aurora atmospheric wash. ≤8% opacity enforced at call sites.
    static let safetyAtmosphere = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    // ─────────────────────────────────────────────
    // MARK: Shadows and glows
    // ─────────────────────────────────────────────

    /// Modal scrims and card drop shadows.
    static let shadowDeep = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.12),
        dark:  UIColor.black.withAlphaComponent(0.50)
    )

    /// Dawn tinted shadow — magenta channel. Cards in light mode.
    static let shadowMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.10)
    )

    /// Dawn tinted shadow — purple channel. Cards in light mode.
    static let shadowPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.12),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    /// Dawn tinted shadow — gold warmth layer. Lowest shadow channel.
    static let shadowGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.07),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Aurora atmosphere
    //
    // Background blobs behind frosted surfaces.
    // Opacity intentionally low — felt, not seen.
    // ─────────────────────────────────────────────

    /// Aurora blob — top right corner.
    static let auroraBlob1 = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.09),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.09)
    )

    /// Aurora blob — bottom left corner.
    static let auroraBlob2 = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.08),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    // ─────────────────────────────────────────────
    // MARK: Glass fills
    //
    // Opaque values only. Semi-transparent fills multiply with
    // container opacity and vanish at disabled (0.45).
    // These hold shape identity at any opacity level.
    // ─────────────────────────────────────────────

    /// Frosted card fill. Warm near-white over aurora in Dawn.
    static let glassFrostCard = Color.dynamic(
        light: UIColor(red: 0.989, green: 0.985, blue: 0.972, alpha: 1),
        dark:  VaylPrimitives.inkCard
    )

    /// Unselected pill fill. Visible contrast against page background.
    static let glassFrostPill = Color.dynamic(
        light: UIColor(red: 0.910, green: 0.875, blue: 0.945, alpha: 1),
        dark:  UIColor(red: 0.10,  green: 0.09,  blue: 0.16,  alpha: 1)
    )

    /// Selected pill fill. Lifts visibly over unselected state.
    static let glassFrostPillSelected = Color.dynamic(
        light: UIColor(red: 0.958, green: 0.875, blue: 0.925, alpha: 1),
        dark:  VaylPrimitives.inkSurface
    )

    /// CTA button fill. Warm rose on Dawn, ink surface on Midnight.
    static let glassFrostCTA = Color.dynamic(
        light: UIColor(red: 0.98, green: 0.91, blue: 0.93, alpha: 1),
        dark:  VaylPrimitives.inkSurface
    )

    // ─────────────────────────────────────────────
    // MARK: Pill surface — Midnight mode
    //
    // ~15% brighter than cardBackground so pill labels have a
    // contrast floor against the purple ambient atmosphere.
    // ─────────────────────────────────────────────

    /// Unselected pill interior gradient — top stop.
    static let pillSurface = Color.dynamic(
        light: UIColor(red: 0.910, green: 0.875, blue: 0.945, alpha: 1),
        dark:  UIColor(red: 0.10,  green: 0.09,  blue: 0.16,  alpha: 1)
    )

    /// Unselected pill interior gradient — bottom stop.
    static let pillSurfaceBottom = Color.dynamic(
        light: UIColor(red: 0.880, green: 0.845, blue: 0.920, alpha: 1),
        dark:  UIColor(red: 0.08,  green: 0.07,  blue: 0.13,  alpha: 1)
    )

    /// Ambient lift shadow on every pill.
    static let pillGlow = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.04),
        dark:  UIColor.white.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Input
    // ─────────────────────────────────────────────

    /// Floating label color when a text field is focused.
    static let inputLabelFocused = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Icon badge backgrounds
    // ─────────────────────────────────────────────

    /// Magenta-tinted icon badge background.
    static let iconBadgeMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.12)
    )

    /// Amber-tinted icon badge background.
    static let iconBadgeAmber = Color.dynamic(
        light: VaylPrimitives.orangeHot.withAlphaComponent(0.14),
        dark:  VaylPrimitives.orangeHot.withAlphaComponent(0.10)
    )

    /// Gold-tinted icon badge background.
    static let iconBadgeGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.14),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.10)
    )

    // ─────────────────────────────────────────────
    // MARK: Toggle
    // ─────────────────────────────────────────────

    /// Active toggle and switch fill.
    static let toggleActive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Progress bar
    // ─────────────────────────────────────────────

    /// Leading stop of onboarding progress bar fill.
    static let progressBarLeading = Color.dynamic(
        light: VaylPrimitives.orangeHot,
        dark:  VaylPrimitives.cyan
    )

    /// Trailing stop of onboarding progress bar fill.
    static let progressBarTrailing = Color.dynamic(
        light: VaylPrimitives.orangeDeep,
        dark:  VaylPrimitives.purple
    )

    // ─────────────────────────────────────────────
    // MARK: App icon
    // ─────────────────────────────────────────────

    /// App icon launch background. Asset-matched fixed value.
    static let appIconBackground = Color(uiColor: VaylPrimitives.inkAppIcon)

    // ─────────────────────────────────────────────
    // MARK: Gradient stop tokens — structural only
    //
    // These are building blocks for gradients below.
    // Not for direct use in views — if you see gradientStop*
    // in a view file, that is a violation.
    //
    // Midnight: cyan  → purple → magenta   (emissive spectrum)
    // Dawn:     purple → magenta → gold    (refractive aurora)
    //
    // Cyan never appears in Dawn — it reads clinical on warm cream.
    // ─────────────────────────────────────────────

    private static let gradientStop1 = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.cyan
    )
    private static let gradientStop2 = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.purple
    )
    private static let gradientStop3 = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Gradients — public tokens
    // ─────────────────────────────────────────────

    /// Universal spectrum border.
    /// Midnight: cyan → purple → magenta
    /// Dawn:     purple → magenta → gold
    /// Applied to every prompt card and bordered surface.
    static let spectrumBorder = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Universal spectrum text highlight.
    /// Same adaptive stops as spectrumBorder, horizontal direction.
    /// Use with .foregroundStyle() on keyword Text views.
    static let spectrumText = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep. Used in LightModeShimmer.swift only.
    static let lightShimmerColors: [Color] = [
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.20)),
        Color(uiColor: VaylPrimitives.gold.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
    ]

    // ─────────────────────────────────────────────
    // MARK: Card intensity — tinted backgrounds
    //
    // Used by CardIntensity extension only.
    // Not for general use in views or components.
    // ─────────────────────────────────────────────

    static let cardIntensityTintCyan      = Color(uiColor: VaylPrimitives.tintCyan)
    static let cardIntensityTintPurple    = Color(uiColor: VaylPrimitives.tintPurple)
    static let cardIntensityTintMagenta   = Color(uiColor: VaylPrimitives.tintMagenta)
    static let cardIntensityTintNavy      = Color(uiColor: VaylPrimitives.tintNavy)
    static let cardIntensityTintIndigo    = Color(uiColor: VaylPrimitives.tintIndigo)
    static let cardIntensityTintPlum      = Color(uiColor: VaylPrimitives.tintPlum)
    static let cardIntensityTintSupernovaA = Color(uiColor: VaylPrimitives.tintSupernovaA)
    static let cardIntensityTintSupernovaB = Color(uiColor: VaylPrimitives.tintSupernovaB)
    static let cardIntensityTintSupernovaC = Color(uiColor: VaylPrimitives.tintSupernovaC)
    static let cardIntensityTintSupernovaD = Color(uiColor: VaylPrimitives.tintSupernovaD)
    
    // ─────────────────────────────────────────────────────────────
    // MARK: Pulse tier — data visualization only
    //
    // These colors represent emotional capacity states on a scale.
    // Used exclusively in pulse graph and tier indicators.
    // Never used for UI interaction states or accents.
    //
    // Midnight: emissive spectrum — cyan down to soft magenta
    // Dawn:     refractive spectrum — magenta down to muted wine
    // ─────────────────────────────────────────────────────────────

    /// Pulse tier 1 — Expansive. Highest capacity. Connected, adventurous.
    static let pulseTierExpansive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Pulse tier 2 — Sovereign. Stable capacity. Grounded, secure.
    static let pulseTierSovereign = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Pulse tier 3 — Friction. Reduced capacity. Anxious, defensive.
    static let pulseTierFriction = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.magenta
    )

    /// Pulse tier 4 — Protective. Lowest capacity. Overwhelmed, needs space.
    static let pulseTierProtective = Color.dynamic(
        light: VaylPrimitives.wineFaint,
        dark:  VaylPrimitives.magentaLight
    )
}



// MARK: - Color.dynamic

extension Color {
    /// Resolves automatically for light and dark via UIColor(dynamicProvider:).
    /// No @Environment(\.colorScheme) branching required in views.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }))
    }
}

// MARK: - Color(hex:) — SwiftUI convenience

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
