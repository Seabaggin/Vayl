//
//  AppElevation.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppElevation.swift

import SwiftUI

/// Tier 2 — Semantic elevation tokens.
/// Every surface in the app belongs to exactly one elevation level.
/// Elevation communicates depth — which surface sits on top of which.
/// Shadows are never grey in either mode. Dawn and Midnight use tinted shadows only.
///
/// Elevation hierarchy (bottom to top):
///   Page → Card → Modal
///
/// Rules:
///   - A Page surface never has a shadow — it is the base layer.
///   - A Card surface always casts a shadow onto the Page below it.
///   - A Modal surface always casts a stronger shadow than a Card.
///   - Never nest a Page inside a Card, or a Card inside a Modal.
///   - Never apply a Card shadow to a Page surface or a Modal shadow to a Card surface.
internal enum AppElevation {

    // MARK: — Shadow Definition

    /// A fully specified shadow. Apply all four properties together — never mix
    /// the radius from one level with the offset from another.
    struct Shadow {
        /// The shadow color. Always a tinted AppColors token — never grey, never black.
        let color: Color
        /// The blur radius. Larger values produce softer, more diffuse shadows.
        let radius: CGFloat
        /// Horizontal offset. Positive moves the shadow right.
        let x: CGFloat
        /// Vertical offset. Positive moves the shadow down.
        let y: CGFloat
    }

    // MARK: — Page

    /// The base layer of every screen.
    /// Page surfaces sit directly on the display — they have no shadow.
    /// Background: AppColors.pageBackground
    /// Use: ScrollView backgrounds, full-screen view backgrounds, ZStack base layers.
    /// Never nest a Page surface inside any other surface.
    enum page {
        /// Page surfaces cast no shadow. This is a deliberate architectural constraint —
        /// if you feel a Page needs a shadow, the surface is at the wrong elevation level.
        static let shadow: Shadow? = nil
    }

    // MARK: — Card

    /// Content containers that sit on a Page surface.
    /// Card surfaces always cast a shadow downward onto the Page below them.
    /// Background: AppColors.cardBackground / AppColors.cardBackgroundRaised
    /// Use: Content cards, widget shells, pill containers, input field backgrounds.
    /// Never place a Card directly on a Modal surface.
    enum card {

        /// Midnight mode — deep cool shadow with a magenta warmth at the edge.
        /// Communicates the card sitting slightly above the dark page surface.
        static let midnightShadow = Shadow(
            color: AppColors.shadowDeep,
            radius: 16,
            x: 0,
            y: 8
        )

        /// Midnight mode — secondary magenta glow layer.
        /// Adds chromatic depth — the card feels lit from within, not just lifted.
        static let midnightGlow = Shadow(
            color: AppColors.shadowMagenta,
            radius: 24,
            x: 0,
            y: 4
        )

        /// Dawn mode — warm gold shadow.
        /// Grey shadows read as dirt on a warm background. Gold reads as sunlight.
        static let dawnShadow = Shadow(
            color: AppColors.shadowGold,
            radius: 12,
            x: 0,
            y: 6
        )

        /// Dawn mode — secondary purple warmth layer.
        /// Prevents the gold shadow from reading as a stain by adding spectral depth.
        static let dawnGlow = Shadow(
            color: AppColors.shadowPurple,
            radius: 20,
            x: 0,
            y: 3
        )
    }

    // MARK: — Modal

    /// Overlay surfaces that sit above Card surfaces.
    /// Modal surfaces always cast a stronger shadow than Cards — they are higher in the stack.
    /// Background: AppColors.modalBackground
    /// Use: Bottom sheets, full-screen overlays, contextual menus, confirmation dialogs.
    /// Never use a Modal surface for inline content — it must visually float above cards.
    enum modal {

        /// Midnight mode — deep shadow with increased radius and offset.
        /// The larger radius signals greater height above the page than a card.
        static let midnightShadow = Shadow(
            color: AppColors.shadowDeep,
            radius: 32,
            x: 0,
            y: 16
        )

        /// Midnight mode — strong magenta glow layer.
        /// More intense than the card glow to reinforce the greater elevation.
        static let midnightGlow = Shadow(
            color: AppColors.shadowMagenta,
            radius: 48,
            x: 0,
            y: 8
        )

        /// Dawn mode — deep gold shadow with stronger offset.
        /// The increased offset makes the modal read as clearly higher than any card.
        static let dawnShadow = Shadow(
            color: AppColors.shadowGold,
            radius: 24,
            x: 0,
            y: 12
        )

        /// Dawn mode — strong purple depth layer.
        /// Matches the increased intensity of the midnight modal glow in the warm palette.
        static let dawnGlow = Shadow(
            color: AppColors.shadowPurple,
            radius: 40,
            x: 0,
            y: 6
        )
    }

    // MARK: — Citation Panel
    // Exclusive to the expandable citation card in StatPhase.
    // Lighter radius than card elevation — the panel is a secondary
    // surface attached to inline copy, not a first-class card.

    enum citationPanel {

        /// Dawn mode — purple-tinted shadow matching the warm palette.
        static let dawnShadow = Shadow(
            color:  AppColors.shadowPurple,
            radius: 16,
            x:      0,
            y:      4
        )

        /// Midnight mode — deep shadow with slightly more spread.
        static let midnightShadow = Shadow(
            color:  AppColors.shadowDeep,
            radius: 20,
            x:      0,
            y:      6
        )
    }

    // MARK: — OB Card Physics Elevation
    // These tokens are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens — the table metaphor
    // does not leave the OB boundary.
    //
    // OB cards exist on a continuous elevation range from 0.0 (flat on the table)
    // to 1.0 (fully lifted toward the user). The standard Page/Card/Modal tiers
    // do not apply here — card height is driven by physics state, not surface hierarchy.

    /// A shadow specification for a VaylCardModel at a given elevation.
    /// VaylDirector writes card.elevation. VaylCardRenderer calls this function.
    ///
    /// elevation 0.0 — card lying flat on the felt.
    ///   color: black at 50% opacity, radius 8pt, y offset 4pt.
    /// elevation 1.0 — card fully lifted toward the user.
    ///   color: black at 16% opacity, radius 32pt, y offset 20pt.
    ///
    /// The opacity inversion is intentional — a lifted card scatters its shadow
    /// across a larger area, so the color lightens as the radius grows.
    /// This matches the physical behaviour of an overhead point light source.
    ///
    /// - Parameter elevation: A Double in the range 0.0–1.0. Values outside
    ///   this range are not clamped — callers are responsible for correct input.
    struct CardShadow {
        let color:  Color
        let radius: CGFloat
        let y:      CGFloat
    }

    static func cardShadow(elevation: Double) -> CardShadow {
        CardShadow(
            color:  Color.black.opacity(lerp(0.50, 0.16, elevation)),
            radius: lerp(8,  32, elevation),
            y:      lerp(4,  20, elevation)
        )
    }

    // MARK: — Private Helpers

    /// Linear interpolation between two Double values.
    /// Used by cardShadow(elevation:) — not exported.
    /// a = value at t=0, b = value at t=1.
    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }
}

// MARK: — View Modifiers

private struct CardElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let primary = colorScheme == .dark
            ? AppElevation.card.midnightShadow
            : AppElevation.card.dawnShadow

        let glow = colorScheme == .dark
            ? AppElevation.card.midnightGlow
            : AppElevation.card.dawnGlow

        return content
            .shadow(color: primary.color, radius: primary.radius, x: primary.x, y: primary.y)
            .shadow(color: glow.color, radius: glow.radius, x: glow.x, y: glow.y)
    }
}

private struct ModalElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let primary = colorScheme == .dark
            ? AppElevation.modal.midnightShadow
            : AppElevation.modal.dawnShadow

        let glow = colorScheme == .dark
            ? AppElevation.modal.midnightGlow
            : AppElevation.modal.dawnGlow

        return content
            .shadow(color: primary.color, radius: primary.radius, x: primary.x, y: primary.y)
            .shadow(color: glow.color, radius: glow.radius, x: glow.x, y: glow.y)
    }
}

// MARK: — View Extension

extension View {

    /// Applies the correct Card elevation shadow for the current color scheme.
    /// Use on every surface at Card elevation. Never call this on Page or Modal surfaces.
    ///
    /// Example:
    ///   MyCardView()
    ///       .cardElevation()
    func cardElevation() -> some View {
        self.modifier(CardElevationModifier())
    }

    /// Applies the correct Modal elevation shadow for the current color scheme.
    /// Use on every surface at Modal elevation. Never call this on Page or Card surfaces.
    ///
    /// Example:
    ///   MySheetView()
    ///       .modalElevation()
    func modalElevation() -> some View {
        self.modifier(ModalElevationModifier())
    }
}
