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
        dark: VaylPrimitives.inkBase
    )

    /// Content containers that sit directly on pageBackground.
    static let cardBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark: VaylPrimitives.inkCard
    )

    /// Second-tier elevated cards that sit on cardBackground.
    static let cardBackgroundRaised = Color.dynamic(
        light: VaylPrimitives.roseWhite,
        dark: VaylPrimitives.inkCardRaised
    )

    /// Sheets, modals, overlays. Always sits above cardBackground.
    static let modalBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark: VaylPrimitives.inkSurface
    )

    /// Racetrack selected-tab fill — the decided purplish that reads as a
    /// lifted chip above the darker bar base (button-family surface, not the
    /// frosted glass look). Matches the CTA base fill.
    static let tabSelectionFill = Color(.sRGB, red: 32/255, green: 28/255, blue: 52/255)  // #201C34

    /// Racetrack bar base fill — a touch darker than the elevated surface so the
    /// selected chip lifts off it, still purplish (not black).
    static let tabBarFill = Color(.sRGB, red: 19/255, green: 17/255, blue: 29/255)  // #13111D

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
        dark: VaylPrimitives.inkRaised
    )

    /// Home widget base layers only. Between page and card elevation.
    static let widgetBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark: VaylPrimitives.inkWidget
    )

    /// Constellation node core fill. Slightly lighter than pageBackground with a
    /// purple undertone. Distinct from cardBackground / modalBackground — not a
    /// general surface token; use only in ConstellationView node circles.
    static let constellationNodeCore = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark: VaylPrimitives.inkNodeCore
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
        dark: VaylPrimitives.cyan.withAlphaComponent(0.90)
    )

    /// Ethos gradient trail stop. accentSecondary at softened presence.
    /// 20% drop from lead produces a gentle luminosity fade across the short phrase.
    static let ethosGradientTrail = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.80),
        dark: VaylPrimitives.purple.withAlphaComponent(0.80)
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
        dark: VaylPrimitives.inkVoid
    )

    /// OB card glass surface. Applied to VaylCardBack and VaylCardFace.
    /// Distinct from cardBackground (inkCard #12111A) — the OB card
    /// surface is #120f1a, a fraction warmer in the blue channel.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let cardBg = Color.dynamic(
        light: VaylPrimitives.inkCardOB,
        dark: VaylPrimitives.inkCardOB
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
        dark: VaylPrimitives.tableFeltCore
    )

    /// Felt fill gradient — mid stop. TableSurfaceView use only.
    static let tableFeltMid = Color.dynamic(
        light: VaylPrimitives.tableFeltMid,
        dark: VaylPrimitives.tableFeltMid
    )

    /// Felt fill gradient — outer stop. TableSurfaceView use only.
    static let tableFeltOuter = Color.dynamic(
        light: VaylPrimitives.tableFeltOuter,
        dark: VaylPrimitives.tableFeltOuter
    )

    /// Felt fill gradient — trailing edge stop. TableSurfaceView use only.
    static let tableFeltEdge = Color.dynamic(
        light: VaylPrimitives.tableFeltEdge,
        dark: VaylPrimitives.tableFeltEdge
    )

    /// Topo contour line stroke. TableSurfaceView use only.
    static let tableTopoLine = Color.dynamic(
        light: VaylPrimitives.tableTopoLine,
        dark: VaylPrimitives.tableTopoLine
    )

    /// Compass star base color. TableSurfaceView use only.
    static let tableCompassStar = Color.dynamic(
        light: VaylPrimitives.tableCompassStar,
        dark: VaylPrimitives.tableCompassStar
    )

    /// Amber overhead lamp pool center stop. TableSurfaceView use only.
    static let tableAmberPool = Color.dynamic(
        light: VaylPrimitives.tableAmberPool,
        dark: VaylPrimitives.tableAmberPool
    )

    /// Warm amber-cream dealer voice. ProjectedTextView use only.
    static let tableProjectedText = Color.dynamic(
        light: VaylPrimitives.tableProjectedText,
        dark: VaylPrimitives.tableProjectedText
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

    /// Spectrum lilac mid-stop. #7A5CFF. DeckPedestal strip use only —
    /// the lilac point on the strip's cyan-to-magenta sweep.
    static let spectrumLilac   = Color(uiColor: VaylPrimitives.lilac)

    // ─────────────────────────────────────────────
    // MARK: Liquid-metal spectrum
    //
    // The ONE metal material: spectrum hues + bright highlights + deep
    // spectrum shadows (continuous ring, no black valley). Used only on
    // earned states — selected pill, CTA press, selected tab ring — via
    // MetalRing / VaylBorderEffect. Never on chrome, backgrounds, or
    // unselected states.
    // ─────────────────────────────────────────────

    static let spectrumMetalStops: [Gradient.Stop] = [
        .init(color: spectrumCyan, location: 0.00),
        .init(color: Color(uiColor: VaylPrimitives.metalHiCyan), location: 0.12),
        .init(color: spectrumPurple, location: 0.30),
        .init(color: Color(uiColor: VaylPrimitives.metalShadowA), location: 0.44),
        .init(color: spectrumMagenta, location: 0.60),
        .init(color: Color(uiColor: VaylPrimitives.metalHiMagenta), location: 0.72),
        .init(color: spectrumLilac, location: 0.86),
        .init(color: Color(uiColor: VaylPrimitives.metalShadowB), location: 0.94),
        .init(color: spectrumCyan, location: 1.00)
    ]

    static let spectrumMetalAngular = AngularGradient(
        gradient: Gradient(stops: spectrumMetalStops),
        center: .center
    )

    // ─────────────────────────────────────────────
    // MARK: Text — hierarchy
    //
    // Never use a lower-hierarchy token for primary content.
    // ─────────────────────────────────────────────

    /// Headings, screen titles, display text.
    static let textPrimary = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark: VaylPrimitives.inkText
    )

    /// Paragraph content, card text, descriptions.
    static let textBody = Color.dynamic(
        light: VaylPrimitives.wineMid,
        dark: VaylPrimitives.pureWhite
    )

    /// Labels, descriptions, supporting copy. 60% hierarchy.
    static let textSecondary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.60),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.65)
    )

    /// Timestamps, metadata, counts. 38% hierarchy.
    /// Apply .italic() at usage site — italic is the semantic signal.
    static let textTertiary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.38),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.50)
    )

    /// Placeholder text, pronoun hints, inline helper copy.
    static let textHint = Color.dynamic(
        light: VaylPrimitives.magentaDark.withAlphaComponent(0.50),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.60)
    )

    /// Disabled states, ghost copy. Lowest visible hierarchy.
    static let textMuted = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.22),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.20)
    )

    /// Overline labels and status counts. Must survive a tinted
    /// ambient background — device-absolute, never tinted.
    static let textBright = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark: UIColor(white: 0.90, alpha: 1)
    )

    /// Tappable links and accent body text.
    static let textAccent = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark: VaylPrimitives.cyan
    )

    /// Card overline and section labels with spectrum tint.
    static let textCardLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.70),
        dark: VaylPrimitives.cyan.withAlphaComponent(0.75)
    )

    /// Section headers and eyebrow labels — the lavender-purple from docs/prototypes/settings-v2.html.
    /// Matches `--label: rgba(160,125,205,0.5)` in HTML prototypes. Softer than textCardLabel
    /// (which skews cyan in Midnight). Use for .sec-h style grouping labels in list screens.
    static let textSectionLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.65),
        dark: VaylPrimitives.purpleBright.withAlphaComponent(0.85)
    )

    // ─────────────────────────────────────────────
    // MARK: Accent — action and emphasis
    // ─────────────────────────────────────────────

    /// Primary interactive accent. CTAs, active states, focus rings.
    /// Midnight: cyan (emissive). Dawn: magenta (refractive).
    static let accentPrimary = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark: VaylPrimitives.cyan
    )

    /// Secondary accent. Decorative spectrum, orbit trails.
    static let accentSecondary = Color.dynamic(
        light: VaylPrimitives.purple,
        dark: VaylPrimitives.purple
    )

    /// Tertiary accent. Badge fills, atmospheric tints.
    static let accentTertiary = Color.dynamic(
        light: VaylPrimitives.gold,
        dark: VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default card and surface border. Barely visible structural edge.
    static let borderSubtle = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.06),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.06)
    )

    /// Hover and focus border. Slightly more present than subtle.
    static let borderDefault = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.10),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.10)
    )

    /// Active, selected, or structural border.
    static let borderActive = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.15),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.15)
    )

    /// Accent-tinted border. Focus rings on accent inputs.
    static let borderAccent = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.22),
        dark: VaylPrimitives.cyan.withAlphaComponent(0.20)
    )

    /// Purple-tinted structural border. Cards and fields in light mode.
    static let borderPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.14),
        dark: VaylPrimitives.purple.withAlphaComponent(0.14)
    )

    // ─────────────────────────────────────────────
    // MARK: Feedback states
    // ─────────────────────────────────────────────

    /// Destructive actions, error states, irreversible confirmations.
    static let destructive = Color.dynamic(
        light: VaylPrimitives.destructiveRed,
        dark: VaylPrimitives.destructiveRed
    )

    /// Success confirmations, completed states.
    static let success = Color.dynamic(
        light: VaylPrimitives.successGreen,
        dark: VaylPrimitives.successGreen
    )

    // ─────────────────────────────────────────────
    // MARK: Gold — safety signal
    //
    // At full or near-full opacity: safety signals only.
    // (warnings, hard stop actions, crisis links)
    // Aurora atmospheric use at ≤8% opacity is acceptable —
    // it cannot be read as a directional signal at that opacity.
    // If it is visible enough to be noticed as gold, it is
    // too opaque for non-safety use.
    // ─────────────────────────────────────────────

    /// Safety signal accent. Warnings, hard stops, crisis links only.
    static let safetyAccent = Color.dynamic(
        light: VaylPrimitives.gold,
        dark: VaylPrimitives.gold
    )

    /// Aurora atmospheric wash. ≤8% opacity enforced at call sites.
    static let safetyAtmosphere = Color.dynamic(
        light: VaylPrimitives.gold,
        dark: VaylPrimitives.gold
    )

    // ─────────────────────────────────────────────
    // MARK: Shadows and glows
    // ─────────────────────────────────────────────

    /// Modal scrims and card drop shadows.
    static let shadowDeep = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.12),
        dark: VaylPrimitives.pureBlack.withAlphaComponent(0.50)
    )

    /// Full-screen backdrop dim behind an elevated/engaged surface (an open
    /// carousel, a reveal's bottom sheet). Heavier than `shadowDeep`, which is
    /// for a resting modal scrim — this is for a surface the user is actively
    /// inside. Values sourced from CardCarousel's existing tuned dim.
    static let scrimHeavy = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.35),
        dark: VaylPrimitives.pureBlack.withAlphaComponent(0.75)
    )

    /// The lightest scrim — a hint of separation behind a small floating element
    /// (a greeting sheet, an inline editor) without dimming the scene. Replaces
    /// the ad-hoc `Color.black.opacity(0.10)` washes in the feature layer.
    static let scrimWhisper = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.06),
        dark: VaylPrimitives.pureBlack.withAlphaComponent(0.10)
    )

    /// Dawn tinted shadow — magenta channel. Cards in light mode.
    static let shadowMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark: VaylPrimitives.magenta.withAlphaComponent(0.10)
    )

    /// Dawn tinted shadow — purple channel. Cards in light mode.
    static let shadowPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.12),
        dark: VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    /// Dawn tinted shadow — gold warmth layer. Lowest shadow channel.
    static let shadowGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.07),
        dark: VaylPrimitives.gold.withAlphaComponent(0.04)
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
        dark: VaylPrimitives.magenta.withAlphaComponent(0.09)
    )

    /// Aurora blob — bottom left corner.
    static let auroraBlob2 = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.08),
        dark: VaylPrimitives.purple.withAlphaComponent(0.08)
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
        dark: VaylPrimitives.inkCard
    )

    /// Unselected pill fill. Visible contrast against page background.
    static let glassFrostPill = Color.dynamic(
        light: VaylPrimitives.frostPill,
        dark: VaylPrimitives.inkPill
    )

    /// Selected pill fill. Lifts visibly over unselected state.
    static let glassFrostPillSelected = Color.dynamic(
        light: VaylPrimitives.frostPillSelected,
        dark: VaylPrimitives.inkPillSelected
    )

    /// CTA button fill. Warm rose on Dawn, ink surface on Midnight.
    static let glassFrostCTA = Color.dynamic(
        light: VaylPrimitives.frostCTA,
        dark: VaylPrimitives.inkSurface
    )

    /// Translucent glass surface for cards that float on the void + atmosphere
    /// (the Map tab and any void-native surface). Unlike `glassFrostCard` /
    /// `cardBackground` (the opaque `inkCard`), this lets the aurora bloom read
    /// through the card. The canonical `.vaylGlassCard` fill — mockup parity is
    /// rgba(255,255,255,0.03) over the void.
    static let glassSurface = Color.dynamic(
        light: VaylPrimitives.frostCard,
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.03)
    )

    /// Barely-there tonal wash — a hint of surface without committing to a fill.
    /// Unlike `glassSurface` (opaque frost in light mode), this stays translucent
    /// on both appearances. For a subtle background tint on rows, pills, and tiles.
    static let whisperFill = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.03),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.04)
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
        dark: VaylPrimitives.inkPillBottom
    )

    /// Ambient lift shadow on every pill.
    static let pillGlow = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.04),
        dark: VaylPrimitives.pureWhite.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Input
    // ─────────────────────────────────────────────

    /// Floating label color when a text field is focused.
    static let inputLabelFocused = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark: VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Icon badge backgrounds
    // ─────────────────────────────────────────────

    /// Magenta-tinted icon badge background.
    static let iconBadgeMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark: VaylPrimitives.magenta.withAlphaComponent(0.12)
    )

    /// Amber-tinted icon badge background.
    static let iconBadgeAmber = Color.dynamic(
        light: VaylPrimitives.orangeHot.withAlphaComponent(0.14),
        dark: VaylPrimitives.orangeHot.withAlphaComponent(0.10)
    )

    /// Gold-tinted icon badge background.
    static let iconBadgeGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.14),
        dark: VaylPrimitives.gold.withAlphaComponent(0.10)
    )

    // ─────────────────────────────────────────────
    // MARK: Toggle
    // ─────────────────────────────────────────────

    /// Active toggle and switch fill.
    static let toggleActive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark: VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Progress bar
    // ─────────────────────────────────────────────

    /// Leading stop of onboarding progress bar fill.
    static let progressBarLeading = Color.dynamic(
        light: VaylPrimitives.orangeHot,
        dark: VaylPrimitives.cyan
    )

    /// Trailing stop of onboarding progress bar fill.
    static let progressBarTrailing = Color.dynamic(
        light: VaylPrimitives.orangeDeep,
        dark: VaylPrimitives.purple
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
        dark: VaylPrimitives.cyan
    )
    private static let gradientStop2 = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark: VaylPrimitives.purple
    )
    private static let gradientStop3 = Color.dynamic(
        light: VaylPrimitives.gold,
        dark: VaylPrimitives.magenta
    )

    // Text-safe spectrum stops. The stroke gradient's dark midpoint (purple #6C3AE0)
    // clears only ~3:1 on the void and FAILS AA-large on card/modal fills — fine for a
    // stroke, not for text. These lighter stops all clear WCAG AA (4.5:1+) as text on
    // every surface, so gradient TEXT stays legible. Cyan still never appears in Dawn.
    private static let textStop1 = Color.dynamic(
        light: VaylPrimitives.purpleLight,
        dark: VaylPrimitives.cyanLight
    )
    private static let textStop2 = Color.dynamic(
        light: VaylPrimitives.magentaLight,
        dark: VaylPrimitives.purpleLight
    )
    private static let textStop3 = Color.dynamic(
        light: VaylPrimitives.gold,
        dark: VaylPrimitives.magentaLight
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

    /// Contrast-safe spectrum text gradient (lighter stops).
    /// Use on gradient TEXT that must clear WCAG AA — smaller sizes, or any text on
    /// a card/modal fill. Reserve `spectrumText` (darker stops) for strokes/borders and
    /// hero display text (≥24pt) that sits on the page floor. Same horizontal direction.
    static let spectrumTextSafe = LinearGradient(
        colors: [textStop1, textStop2, textStop3],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep. Used in LightModeShimmer.swift only.
    static let lightShimmerColors: [Color] = [
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.20)),
        Color(uiColor: VaylPrimitives.gold.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22))
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
        dark: VaylPrimitives.cyan
    )

    /// Pulse tier 2 — Sovereign. Stable capacity. Grounded, secure.
    static let pulseTierSovereign = Color.dynamic(
        light: VaylPrimitives.purple,
        dark: VaylPrimitives.purple
    )

    /// Pulse tier 3 — Friction. Reduced capacity. Anxious, defensive.
    static let pulseTierFriction = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark: VaylPrimitives.magenta
    )

    /// Pulse tier 4 — Protective. Lowest capacity. Overwhelmed, needs space.
    static let pulseTierProtective = Color.dynamic(
        light: VaylPrimitives.wineFaint,
        dark: VaylPrimitives.magentaLight
    )

    /// Renamed vocabulary (2D circumplex): the Reactive Space is the old Friction tier,
    /// the Receptive Space is the old Sovereign tier. Reference-only aliases so callers
    /// speak the new names while the underlying colour is unchanged.
    static let pulseTierReactive  = AppColors.pulseTierFriction
    static let pulseTierReceptive = AppColors.pulseTierSovereign

    // ─────────────────────────────────────────────────────────────
    // MARK: Aura tier color ramps — PulseAura use only
    //
    // Each tier: core (midpoint) / light (inner highlight) / deep (outer edge) / glow (shadow).
    // Maps to HTML: .cyan → expansive, .indigo → sovereign, .magenta → friction, .rose → protective.
    // FEEL: intensities tuned on device against docs/prototypes/pulse-aura-glass.html.
    // ─────────────────────────────────────────────────────────────

    static let auraCoreCyan     = Color(uiColor: VaylPrimitives.cyan)
    static let auraLightCyan    = Color(uiColor: VaylPrimitives.cyanLight)
    static let auraDeepCyan     = Color(uiColor: VaylPrimitives.cyanDark)
    static let auraGlowCyan     = Color(uiColor: VaylPrimitives.cyan).opacity(0.30)

    static let auraCoreIndigo   = Color(uiColor: VaylPrimitives.electricViolet)
    static let auraLightIndigo  = Color(uiColor: VaylPrimitives.purpleBright)
    static let auraDeepIndigo   = Color(uiColor: VaylPrimitives.purple)
    static let auraGlowIndigo   = Color(uiColor: VaylPrimitives.electricViolet).opacity(0.30)

    static let auraCoreMagenta  = Color(uiColor: VaylPrimitives.magenta)
    static let auraLightMagenta = Color(uiColor: VaylPrimitives.magentaLight)
    static let auraDeepMagenta  = Color(uiColor: VaylPrimitives.magentaDark)
    static let auraGlowMagenta  = Color(uiColor: VaylPrimitives.magenta).opacity(0.28)

    static let auraCoreRose     = Color(uiColor: VaylPrimitives.rose)
    static let auraLightRose    = Color(uiColor: VaylPrimitives.roseLight)
    static let auraDeepRose     = Color(uiColor: VaylPrimitives.roseDark)
    static let auraGlowRose     = Color(uiColor: VaylPrimitives.rose).opacity(0.26)

    // Neutral Space ramp — Lavender Silver. Does NOT participate in the bilinear blend;
    // resolved directly when the space is .neutral (both axes in the 0.475–0.525 border zone).
    static let auraCoreNeutral  = Color(uiColor: VaylPrimitives.lavenderSilverCore)
    static let auraLightNeutral = Color(uiColor: VaylPrimitives.lavenderSilverLight)
    static let auraDeepNeutral  = Color(uiColor: VaylPrimitives.lavenderSilverDeep)
    static let auraGlowNeutral  = Color(uiColor: VaylPrimitives.lavenderSilverCore).opacity(0.22)

    // ─────────────────────────────────────────────
    // MARK: Pulse check-in answer scale — SelectablePill tint only
    //
    // A fixed 5-step colour whisper for a check-in question's five pills,
    // leftmost (highest score) to rightmost (lowest): Cyan / Purple / Neutral
    // (lavender silver, reused from the Neutral space above) / Magenta / Orange.
    // Deliberately NOT the 3-token brand spectrum above (cyan/purple/magenta
    // only, cyan=Me/magenta=Us) — this is a standalone 5-step scale for the
    // check-in pills only (docs/mockups/pulse-checkin-pill-options.html Option
    // A). Orange was Bryan's explicit call (2026-07-09): a straight 3-way
    // cyan/purple/magenta scale had no complementary colour to close the ramp
    // out against magenta, so Orange fills that 5th step visually rather than
    // carrying any circumplex-quadrant meaning. Reuses the existing amber
    // primitive already used elsewhere in the app.
    // ─────────────────────────────────────────────
    static let pulseAnswerScaleOrange = Color(uiColor: VaylPrimitives.orangeHot)

    // Pre-answer ramp — plain silver-white, the orb's colour before the FIRST answer lands.
    // Deliberately distinct from the Neutral SPACE's lavender-silver ramp above: no answer
    // yet means no hue at all. Values preserved exactly from the check-in's original inline ramp.
    static let auraLightStart = Color.white
    static let auraCoreStart  = Color(white: 0.7)
    static let auraDeepStart  = Color(white: 0.5)
    static let auraGlowStart  = Color.white.opacity(0.3)

    // Uncharted Space ramp — Sage Deep. Fixed colour, does NOT blend; the orb dissolves to
    // this when the variance check fires (contradictory answers on both axes).
    static let auraCoreUncharted  = Color(uiColor: VaylPrimitives.sageDeepCore)
    static let auraLightUncharted = Color(uiColor: VaylPrimitives.sageDeepLight)
    static let auraDeepUncharted  = Color(uiColor: VaylPrimitives.sageDeepDeep)
    static let auraGlowUncharted  = Color(uiColor: VaylPrimitives.sageDeepCore).opacity(0.26)

    /// Pulse "Us" capsule halo — soft periwinkle glow around the connector stroke.
    /// Mockup parity: map-pulse-us.html `.capsule` box-shadow rgba(130,160,230,.18).
    static let pulseCapsuleGlow = Color(uiColor: VaylPrimitives.periwinkle).opacity(0.18)

    // ─────────────────────────────────────────────────────────────
    // MARK: Flame / warm aura ramp — FlameAura + LightAuraBloom use only
    //
    // Verbatim from the hardcoded Color(red:green:blue:) literals in
    // FlameAura.swift (wisp base/tip) and LightAuraBloom.swift (five blobs).
    // Not a general-purpose warm palette — do not reuse elsewhere.
    // ─────────────────────────────────────────────────────────────

    /// FlameAura wisp base — hot pink. Lerped toward flameMagentaViolet by wisp seed.
    static let flameHotPink       = Color(uiColor: VaylPrimitives.flameHotPink)
    /// FlameAura wisp base — magenta-violet lerp target.
    static let flameMagentaViolet = Color(uiColor: VaylPrimitives.flameMagentaViolet)
    /// FlameAura wisp tip — deep purple.
    static let flameDeepPurple    = Color(uiColor: VaylPrimitives.flameDeepPurple)
    /// LightAuraBloom centre blob — rose.
    static let flameRoseCentre    = Color(uiColor: VaylPrimitives.flameRoseCentre)
    /// LightAuraBloom left blob — peach.
    static let flamePeach         = Color(uiColor: VaylPrimitives.flamePeach)
    /// LightAuraBloom right blob — gold. Distinct from AppColors.accentTertiary/safetyAccent gold.
    static let flameGold          = Color(uiColor: VaylPrimitives.flameGold)
    /// LightAuraBloom far-left blob — lavender.
    static let flameLavender      = Color(uiColor: VaylPrimitives.flameLavender)
    /// LightAuraBloom far-right blob — blush.
    static let flameBlush         = Color(uiColor: VaylPrimitives.flameBlush)

    // ─────────────────────────────────────────────────────────────
    // MARK: Vault rose glow ramp — VaultDoorCard's VaultEmblem use only
    //
    // Verbatim from VaultDoorCard.swift's two radial gradients (centre aura glow +
    // rotated core highlight). Apply .opacity() at the call site to match each
    // gradient stop's original alpha — these tokens hold full-opacity base color only.
    // The gradients' shared mid-tone stop is NOT here — it is exactly
    // AppColors.spectrumMagenta, reuse that token instead.
    // ─────────────────────────────────────────────────────────────

    /// Centre aura glow, inner stop. Apply .opacity(0.7) to match the original.
    static let vaultRoseHighlight = Color(uiColor: VaylPrimitives.vaultRoseHighlight)
    /// Rotated core gradient, inner highlight stop. Apply .opacity(0.85) to match the original.
    static let vaultRoseCore      = Color(uiColor: VaylPrimitives.vaultRoseCore)
    /// Rotated core gradient, outer edge stop. Apply .opacity(0.92) to match the original.
    static let vaultRoseDeep      = Color(uiColor: VaylPrimitives.vaultRoseDeep)
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

// MARK: - PulseCapacityColor aura ramp

extension PulseCapacityColor {
    /// Aura body radial gradient center color.
    var auraCore: Color {
        switch self {
        case .cyan:    return AppColors.auraCoreCyan
        case .indigo:  return AppColors.auraCoreIndigo
        case .magenta: return AppColors.auraCoreMagenta
        case .rose:    return AppColors.auraCoreRose
        }
    }
    /// Aura body inner highlight (lightest, at center).
    var auraLight: Color {
        switch self {
        case .cyan:    return AppColors.auraLightCyan
        case .indigo:  return AppColors.auraLightIndigo
        case .magenta: return AppColors.auraLightMagenta
        case .rose:    return AppColors.auraLightRose
        }
    }
    /// Aura body outer edge color (darkest, at rim).
    var auraDeep: Color {
        switch self {
        case .cyan:    return AppColors.auraDeepCyan
        case .indigo:  return AppColors.auraDeepIndigo
        case .magenta: return AppColors.auraDeepMagenta
        case .rose:    return AppColors.auraDeepRose
        }
    }
    /// Glow shadow color for the soft outer halo.
    var auraGlow: Color {
        switch self {
        case .cyan:    return AppColors.auraGlowCyan
        case .indigo:  return AppColors.auraGlowIndigo
        case .magenta: return AppColors.auraGlowMagenta
        case .rose:    return AppColors.auraGlowRose
        }
    }
}
