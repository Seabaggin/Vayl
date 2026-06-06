//
//  AppGlows.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

// App/Theme/AppGlows.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 2 — Semantic glow tokens.
//
// Rules:
//   • Every .shadow() call whose purpose is emissive glow
//     (not elevation depth) must reference a token from this file
//   • Elevation shadows live in AppElevation — never here
//   • Glow tokens describe energy emitted from a surface
//   • Elevation tokens describe height above a surface below
//   • If the shadow moves with the light source, it is elevation
//   • If the shadow pulses, reacts to input, or animates on its
//     own, it is a glow — it belongs here
//   • No raw CGFloat for radius or opacity anywhere in the app
//     that relates to a glow effect
//   • VaylPrimitives is never referenced in this file —
//     all colors come through AppColors tokens
// ─────────────────────────────────────────────────────────────

internal enum AppGlows {

    // ─────────────────────────────────────────────
    // MARK: Glow Layer Definition
    //
    // A GlowLayer is one pass of a .shadow() modifier.
    // Glows are always multi-layer — a tight inner core
    // for intensity, a broader outer halo for atmosphere.
    // Never apply a single .shadow() and call it a glow.
    // ─────────────────────────────────────────────

    struct GlowLayer {
        /// The color of this shadow pass.
        /// Always sourced from AppColors — never a raw color literal.
        let color: Color

        /// Blur radius. Larger = softer and more diffuse.
        /// Inner layers: tight (2–4pt). Outer layers: broad (8–16pt).
        let radius: CGFloat

        /// Always 0 for glow effects — glows radiate symmetrically.
        /// Non-zero x/y values produce directional shadows (elevation), not glows.
        let x: CGFloat
        let y: CGFloat

        init(color: Color, radius: CGFloat) {
            self.color  = color
            self.radius = radius
            self.x      = 0
            self.y      = 0
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Spectrum Border Glow
    //
    // The emissive glow applied to VaylButton's border arcs
    // when the press animation completes. Three chromatic
    // layers produce a concentrated inner edge with a
    // soft outer halo that reads as high-energy light.
    //
    // Applied to: VaylBorderEffect arc strokes
    // Trigger: glowIntensity > 0
    // Animation: AppAnimation.borderGlowIn / borderGlowOut
    // ─────────────────────────────────────────────

    enum spectrumBorder {

        /// Tight inner core — cyan channel.
        /// Highest opacity, smallest radius.
        /// Gives the border stroke a sharp luminous edge.
        static let inner = GlowLayer(
            color:  AppColors.spectrumCyan.opacity(0.90),
            radius: 3
        )

        /// Mid halo — purple channel.
        /// Bridges inner and outer — produces the chromatic
        /// spread that reads as refracted spectrum light.
        static let mid = GlowLayer(
            color:  AppColors.spectrumPurple.opacity(0.65),
            radius: 8
        )

        /// Broad outer atmosphere — magenta channel.
        /// The softest, most diffuse layer.
        /// Gives the button an ambient emissive presence
        /// that extends visibly beyond the border itself.
        static let outer = GlowLayer(
            color:  AppColors.spectrumMagenta.opacity(0.40),
            radius: 16
        )

        /// All three layers in application order (inner → outer).
        static let layers: [GlowLayer] = [inner, mid, outer]

        // ─── Stroke geometry ───────────────────────────────
        // Stroke weights are part of the glow specification.
        // All three states are defined here so they are never
        // changed independently and drift apart.
        //
        // These values are intentionally heavier than a typical
        // UI border — VaylButton's border is a design centrepiece,
        // not a structural edge. It needs presence.

        /// 1.2pt — Resting hairline in the inactive state.
        /// True hairline — present but quiet.
        static let strokeResting:  CGFloat = 1.2

        /// 1.8pt — Active fill stroke during arc draw-on.
        /// Marginally heavier than resting — the energy reads as
        /// luminosity from the glow, not physical stroke weight.
        static let strokeActive:   CGFloat = 2.2

        /// 2.0pt — Glowing stroke at full glow intensity.
        /// Minimal additional weight — the glow layer creates the
        /// perception of thickness. The stroke itself stays contained.
        static let strokeGlowing:  CGFloat = 2.8

        // ─── Hairline geometry ─────────────────────────────
        // The resting-state hairline is a separate visual element
        // from the arc strokes. It is a gradient strip, not a
        // Shape stroke, so its thickness is a frame height value
        // rather than a lineWidth.

        /// 1.8pt — Hairline strip height in the resting state.
        static let hairlineHeight: CGFloat = 1.8

        // ─── Hairline opacity ──────────────────────────────

        /// 1.0 — Hairline opacity in the resting state.
        static let hairlineOpacity: Double = 1.0
    }

    // ─────────────────────────────────────────────
    // MARK: Corner Deck Glow
    //
    // Pulsed by CornerDeckView when a card lands in
    // the corner deck. Migrated from AppElevation.
    //
    // Applied to: CornerDeckView
    // Trigger: card received event
    // Animation: AppAnimation.deckReceive, fades after 600ms
    // ─────────────────────────────────────────────

    enum cornerDeck {

        /// Spectrum purple at 30% — communicates receipt
        /// without competing with the mini-card content.
        static let color: Color = AppColors.spectrumPurple.opacity(0.30)

        /// 12pt — Tight radius so the glow reads as emanating
        /// from the mini-card stack, not the screen corner.
        static let radius: CGFloat = 12
    }

    // ─────────────────────────────────────────────
    // MARK: Card Breathe Glow
    //
    // The ambient emissive glow on a stationary OB card
    // while it awaits user input.
    //
    // Applied to: VaylCardRenderer in stationary states
    // Animation: AppAnimation.cardBreathe (ambient, repeat)
    // Reduce motion: remove entirely
    // ─────────────────────────────────────────────

    enum cardBreathe {

        static let color:  Color   = AppColors.spectrumPurple.opacity(0.22)
        static let radius: CGFloat = 18
    }

    // ─────────────────────────────────────────────
    // MARK: Accent Focus Glow
    //
    // Applied to focused input fields and selected states.
    //
    // Applied to: VaylTextField focus ring, selected pills
    // Trigger: focus / selection state
    // ─────────────────────────────────────────────

    enum accentFocus {

        static let inner = GlowLayer(
            color:  AppColors.accentPrimary.opacity(0.50),
            radius: 3
        )

        static let outer = GlowLayer(
            color:  AppColors.accentPrimary.opacity(0.18),
            radius: 10
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Lift Copy Glow
    //
    // Tight emissive glow on the gradient text that appears
    // above the table when a card is lifted in ModeSelectPhase.
    // Two layers — inner core hugs the letterforms,
    // outer is a soft falloff. Never a broad radial bloom.
    //
    // Applied to: ModeSelectPhase liftCopyLayer VStack
    // Trigger: card lift state
    // ─────────────────────────────────────────────

    enum liftCopy {

        /// Tight inner core — cyan channel.
        /// Hugs letterforms. Reads as text emitting light.
        static let inner = GlowLayer(
            color:  AppColors.spectrumCyan.opacity(0.18),
            radius: 2
        )

        /// Soft outer falloff — purple channel.
        /// Feathers the glow edge without creating a halo box.
        static let outer = GlowLayer(
            color:  AppColors.spectrumPurple.opacity(0.08),
            radius: 5
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Safety Glow
    //
    // Reserved exclusively for safe word and warning surfaces.
    // Same constraints as AppColors.safetyAccent — never
    // use for decorative or ambient purposes.
    //
    // Applied to: SafeWordButton, hard-stop confirmation UI
    // ─────────────────────────────────────────────

    enum safety {

        static let inner = GlowLayer(
            color:  AppColors.safetyAccent.opacity(0.45),
            radius: 4
        )

        static let outer = GlowLayer(
            color:  AppColors.safetyAccent.opacity(0.20),
            radius: 12
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Compass Star Glow
    //
    // Soft radial glow drawn behind the compass star
    // on the OB table surface. Simulates ambient light
    // scattering from an overhead point source onto the felt.
    //
    // Applied to: TableSurfaceView compass star layer
    // Not animated — static rendering constant
    // ─────────────────────────────────────────────

    enum compassStarGlow {
        /// Base color sourced from the compass star token.
        /// Opacity 0.14 — present as atmosphere, not as a visible halo.
        static let color: Color              = AppColors.tableCompassStar.opacity(0.14)
        /// Caller computes starSize × radiusMultiplier for the actual radius.
        static let radiusMultiplier: CGFloat = 2.2
    }

    // ─────────────────────────────────────────────
    // MARK: Table Rim Inner Glow
    //
    // Radial glow that sits behind the spectrum rim arc
    // on the OB table surface. Gives the rim the appearance
    // of an emissive light source rather than a painted line.
    //
    // Applied to: TableSurfaceView spectrum rim layer
    // inner radius: tableR - innerInset
    // outer radius: tableR + outerInset
    // peak stop position: peakPosition
    // ─────────────────────────────────────────────

    enum tableRimInnerGlow {
        /// Purple at 10% — suggests refracted light bleeding inward from the rim.
        static let color: Color          = AppColors.spectrumPurple.opacity(0.10)
        static let innerInset: CGFloat   = 28
        static let outerInset: CGFloat   = 6
        static let peakPosition: CGFloat = 0.55
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: View Extension — Glow Application
//
// Never call .shadow() directly for glow effects.
// Always use these modifiers so that glow tokens are
// the single point of change when values are updated.
// ─────────────────────────────────────────────────────────────

extension View {

    /// Applies a spectrum border glow using an opacity multiplier.
    ///
    /// Use a Double multiplier (0.0–1.0) rather than toggling
    /// between a color and .clear. Animating to/from .clear
    /// interpolates through a desaturated gray phase — the
    /// multiplier keeps all intermediate values fully chromatic.
    ///
    ///   arcView.spectrumBorderGlow(intensity: glowIntensity)
    ///
    ///   withAnimation(AppAnimation.borderGlowIn)  { glowIntensity = 1.0 }
    ///   withAnimation(AppAnimation.borderGlowOut) { glowIntensity = 0.0 }
    func spectrumBorderGlow(intensity: Double) -> some View {
        let layers = AppGlows.spectrumBorder.layers
        return self
            .shadow(
                color:  layers[0].color.opacity(intensity),
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  layers[1].color.opacity(intensity),
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
            .shadow(
                color:  layers[2].color.opacity(intensity),
                radius: layers[2].radius,
                x:      layers[2].x,
                y:      layers[2].y
            )
    }

    /// Applies a corner deck receive glow.
    func cornerDeckGlow(visible: Bool) -> some View {
        self.shadow(
            color:  visible
                ? AppGlows.cornerDeck.color
                : .clear,
            radius: AppGlows.cornerDeck.radius,
            x: 0,
            y: 0
        )
    }

    /// Applies an accent focus glow for input fields and selected pills.
    func accentFocusGlow(visible: Bool) -> some View {
        let layers = AppGlows.accentFocus.layers
        return self
            .shadow(
                color:  visible ? layers[0].color : .clear,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  visible ? layers[1].color : .clear,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }

    /// Applies a safety glow for safe word and warning surfaces.
    func safetyGlow(visible: Bool) -> some View {
        let layers = AppGlows.safety.layers
        return self
            .shadow(
                color:  visible ? layers[0].color : .clear,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  visible ? layers[1].color : .clear,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }

    /// Applies the lift copy text glow.
    /// Use on the VStack in ModeSelectPhase.liftCopyLayer only.
    func liftCopyGlow() -> some View {
        let layers = AppGlows.liftCopy.layers
        return self
            .shadow(
                color:  layers[0].color,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  layers[1].color,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }
}
