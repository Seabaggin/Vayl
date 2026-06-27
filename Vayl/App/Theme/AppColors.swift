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
        light: VaylPrimitives.roseWhite,
        dark:  VaylPrimitives.inkCardRaised
    )

    /// Sheets, modals, overlays. Always sits above cardBackground.
    static let modalBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkSurface
    )

    /// Holographic shimmer pill base. HolographicShimmer use only.
    static let shimmerBase    = Color(uiColor: VaylPrimitives.inkShimmerBase)
    /// Dark muted orb colours — not the vivid spectrum anchors. HolographicShimmer use only.
    static let shimmerViolet  = Color(uiColor: VaylPrimitives.inkShimmerViolet)
    static let shimmerCyan    = Color(uiColor: VaylPrimitives.inkShimmerCyan)
    static let shimmerPurple  = Color(uiColor: VaylPrimitives.inkShimmerPurple)
    static let shimmerMagenta = Color(uiColor: VaylPrimitives.inkShimmerMagenta)
    static let shimmerIndigo  = Color(uiColor: VaylPrimitives.inkShimmerIndigo)

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
    // MARK: OB StatPhase — ethos gradient
    //
    // Exclusive to EthosTextView in StatPhase.
    // Bakes the per-mode accent colors and their specific opacity values
    // into tokens so no numeric opacity literals appear in the View layer.
    // ─────────────────────────────────────────────

    /// Ethos gradient lead stop. accentPrimary at near-opaque presence.
    /// 10% transparency softens the hard start of the gradient sweep.
    static let ethosGradientLead = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.90),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.90)
    )

    /// Ethos gradient trail stop. accentSecondary at softened presence.
    /// 20% drop from lead produces a gentle luminosity fade across the short phrase.
    static let ethosGradientTrail = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.80),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.80)
    )

    // ─────────────────────────────────────────────
    // MARK: OB Flourish — decorative component
    //
    // These tokens are exclusive to VaylFlourishView.
    // Sourced from the same hue palette as the "1 in 5" headline gradient
    // so the flourish reads as an extension of that typography.
    // ─────────────────────────────────────────────

    /// Flourish gradient left stop — purple end, mirrors accentSecondary palette.
    static let flourishLeft: Color = Color(uiColor: VaylPrimitives.purpleLight)

    /// Flourish gradient midpoint — lavender bridge between purple and coral.
    static let flourishMid: Color = Color(uiColor: VaylPrimitives.purpleBright)

    /// Flourish gradient right stop — coral/pink end, mirrors accentTertiary palette.
    static let flourishRight: Color = Color(uiColor: VaylPrimitives.magentaLight)

    /// Flourish Canvas layer base opacity. Renders as subtle texture, not decoration.
    static let flourishBaseOpacity: Double = 0.75

    // ─────────────────────────────────────────────
    // MARK: OB Canvas
    //
    // These tokens are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens.
    //
    // Light-mode values are placeholders — they mirror the dark
    // values until OB Dawn mode is designed. Update both the
    // primitive and the light: stop here when that work begins.
    // Do not remove the light: parameter — it future-proofs the
    // token for adaptive resolution.
    // ─────────────────────────────────────────────

    /// Absolute floor of the OB canvas. The void the table sits in.
    /// Slightly warmer and more violet than inkBase — gives the table
    /// world its own atmospheric identity separate from the main app.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let void = Color.dynamic(
        light: VaylPrimitives.inkVoid,
        dark:  VaylPrimitives.inkVoid
    )

    /// OB card glass surface. Applied to VaylCardBack and VaylCardFace.
    /// Distinct from cardBackground (inkCard #12111A) — the OB card
    /// surface is #120f1a, a fraction warmer in the blue channel.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let cardBg = Color.dynamic(
        light: VaylPrimitives.inkCardOB,
        dark:  VaylPrimitives.inkCardOB
    )

    // ─────────────────────────────────────────────
    // MARK: OB Table Surface — rendering constants
    //
    // These tokens are exclusive to TableSurfaceView.
    // They simulate physical light on baize and an overhead
    // lamp — they are rendering constants, not brand colors.
    // They must never appear in any other view or component.
    //
    // Light-mode values mirror dark until OB Dawn is designed.
    // ─────────────────────────────────────────────

    /// Felt fill gradient — center stop. TableSurfaceView use only.
    static let tableFeltCore = Color.dynamic(
        light: VaylPrimitives.tableFeltCore,
        dark:  VaylPrimitives.tableFeltCore
    )

    /// Felt fill gradient — mid stop. TableSurfaceView use only.
    static let tableFeltMid = Color.dynamic(
        light: VaylPrimitives.tableFeltMid,
        dark:  VaylPrimitives.tableFeltMid
    )

    /// Felt fill gradient — outer stop. TableSurfaceView use only.
    static let tableFeltOuter = Color.dynamic(
        light: VaylPrimitives.tableFeltOuter,
        dark:  VaylPrimitives.tableFeltOuter
    )

    /// Felt fill gradient — trailing edge stop. TableSurfaceView use only.
    static let tableFeltEdge = Color.dynamic(
        light: VaylPrimitives.tableFeltEdge,
        dark:  VaylPrimitives.tableFeltEdge
    )

    /// Topo contour line stroke. TableSurfaceView use only.
    static let tableTopoLine = Color.dynamic(
        light: VaylPrimitives.tableTopoLine,
        dark:  VaylPrimitives.tableTopoLine
    )

    /// Compass star base color. TableSurfaceView use only.
    static let tableCompassStar = Color.dynamic(
        light: VaylPrimitives.tableCompassStar,
        dark:  VaylPrimitives.tableCompassStar
    )

    /// Amber overhead lamp pool center stop. TableSurfaceView use only.
    static let tableAmberPool = Color.dynamic(
        light: VaylPrimitives.tableAmberPool,
        dark:  VaylPrimitives.tableAmberPool
    )

    // ─────────────────────────────────────────────
    // MARK: Spectrum — fixed accent values
    //
    // These three tokens resolve the fixed spectrum anchor colors
    // used for hairlines, glows, and accents throughout the app.
    // They are NOT adaptive — the spectrum is the same in both modes.
    // Use these tokens wherever a single spectrum channel is needed.
    // For full spectrum gradients use spectrumBorder or spectrumText.
    // ─────────────────────────────────────────────

    /// Spectrum cyan anchor. #00C2FF. Hairlines, glows, accents.
    static let spectrumCyan    = Color(uiColor: VaylPrimitives.cyan)

    /// Spectrum purple anchor. #6C3AE0. Hairlines, glows, accents.
    static let spectrumPurple  = Color(uiColor: VaylPrimitives.purple)

    /// Spectrum magenta anchor. #FF006A. Hairlines, glows, accents.
    static let spectrumMagenta = Color(uiColor: VaylPrimitives.magenta)

    /// Mid-spectrum gradient bridge. Wordmark and spectrum sweep use only.
    /// Sits between cyan and magenta on the gradient arc — not a standalone accent.
    static let spectrumBridge  = Color(uiColor: VaylPrimitives.spectrumBridge)

    // ─────────────────────────────────────────────
    // MARK: Text — hierarchy
    //
    // Never use a lower-hierarchy token for primary content.
    // ─────────────────────────────────────────────

    /// Headings, screen titles, display text.
    static let textPrimary = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  VaylPrimitives.inkText
    )

    /// Paragraph content, card text, descriptions.
    static let textBody = Color.dynamic(
        light: VaylPrimitives.wineMid,
        dark:  VaylPrimitives.pureWhite
    )

    /// Labels, descriptions, supporting copy. 60% hierarchy.
    static let textSecondary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.60),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.65)
    )

    /// Timestamps, metadata, counts. 38% hierarchy.
    /// Apply .italic() at usage site — italic is the semantic signal.
    static let textTertiary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.38),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.38)
    )

    /// Placeholder text, pronoun hints, inline helper copy.
    static let textHint = Color.dynamic(
        light: VaylPrimitives.magentaDark.withAlphaComponent(0.50),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.42)
    )

    /// Disabled states, ghost copy. Lowest visible hierarchy.
    static let textMuted = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.22),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.20)
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
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.06),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.06)
    )

    /// Hover and focus border. Slightly more present than subtle.
    static let borderDefault = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.10),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.10)
    )

    /// Active, selected, or structural border.
    static let borderActive = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.15),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.15)
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
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.12),
        dark:  VaylPrimitives.pureBlack.withAlphaComponent(0.50)
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
        light: VaylPrimitives.frostCard,
        dark:  VaylPrimitives.inkCard
    )

    /// Unselected pill fill. Visible contrast against page background.
    static let glassFrostPill = Color.dynamic(
        light: VaylPrimitives.frostPill,
        dark:  VaylPrimitives.inkPill
    )

    /// Selected pill fill. Lifts visibly over unselected state.
    static let glassFrostPillSelected = Color.dynamic(
        light: VaylPrimitives.frostPillSelected,
        dark:  VaylPrimitives.inkSurface
    )

    /// CTA button fill. Warm rose on Dawn, ink surface on Midnight.
    static let glassFrostCTA = Color.dynamic(
        light: VaylPrimitives.frostCTA,
        dark:  VaylPrimitives.inkSurface
    )

    /// Translucent glass surface for cards that float on the void + atmosphere
    /// (the Map tab and any void-native surface). Unlike `glassFrostCard` /
    /// `cardBackground` (the opaque `inkCard`), this lets the aurora bloom read
    /// through the card. The canonical `.vaylGlassCard` fill — mockup parity is
    /// rgba(255,255,255,0.03) over the void.
    static let glassSurface = Color.dynamic(
        light: VaylPrimitives.frostCard,
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.03)
    )

    // ─────────────────────────────────────────────
    // MARK: Pill surface — Midnight mode
    //
    // ~15% brighter than cardBackground so pill labels have a
    // contrast floor against the purple ambient atmosphere.
    // ─────────────────────────────────────────────

    /// Unselected pill interior gradient — bottom stop.
    static let pillSurfaceBottom = Color.dynamic(
        light: VaylPrimitives.frostPillBottom,
        dark:  VaylPrimitives.inkPillBottom
    )

    /// Ambient lift shadow on every pill.
    static let pillGlow = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.04),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.04)
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
    /// OB files reference this token as spectrumGradient — use this instead.
    static let spectrumBorder = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Universal spectrum text highlight.
    /// Same adaptive stops as spectrumBorder, horizontal direction.
    /// Use with .foregroundStyle() on keyword Text views.
    /// OB files reference this token as spectrumTextGradient — use this instead.
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

    static let cardIntensityTintCyan       = Color(uiColor: VaylPrimitives.tintCyan)
    static let cardIntensityTintPurple     = Color(uiColor: VaylPrimitives.tintPurple)
    static let cardIntensityTintMagenta    = Color(uiColor: VaylPrimitives.tintMagenta)
    static let cardIntensityTintNavy       = Color(uiColor: VaylPrimitives.tintNavy)
    static let cardIntensityTintIndigo     = Color(uiColor: VaylPrimitives.tintIndigo)
    static let cardIntensityTintPlum       = Color(uiColor: VaylPrimitives.tintPlum)
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
    /// Always resolves to the dark variant — app is dark-only (Act 1).
    /// light: param is retained for future Dawn-mode work; it is currently ignored.
    /// No @Environment(\.colorScheme) branching required in views.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: dark)
    }
}

// MARK: - Color(hex:) — SwiftUI convenience

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
