//
//  AppRadius.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// App/Theme/AppRadius.swift

import CoreGraphics

/// Tier 2 — Semantic corner radius tokens.
/// Every `.cornerRadius()`, `.clipShape()`, or `RoundedRectangle(cornerRadius:)` call
/// in the codebase must reference one of these tokens.
/// Hardcoded numeric values in any corner radius context are a violation.
/// Nothing in this file may reference VaylPrimitives — radius has no primitive tier.
///
/// Grid note: Radius tokens use a 4pt grid. This is intentional and independent
/// of the 8pt spacing grid — radius granularity requirements are finer than spacing
/// requirements. The two grids do not need to be unified.
internal enum AppRadius {

    /// 2pt — Drag handle pills and fine decorative dividers.
    /// Use for drag handle capsules, hairline divider end-caps, and sub-pixel decorative rounding.
    /// Never use for interactive elements, cards, or any tappable surface.
    static let micro: CGFloat = 2

    /// 8pt — Small interactive chips, tags, and badge labels.
    /// Use for pills that display metadata (counts, status tags) and small category chips.
    /// Never use for primary buttons, cards, or any surface larger than a label container.
    static let sm: CGFloat = 8

    /// 12pt — Input fields and secondary buttons.
    /// Use for text input containers, secondary action buttons, and segmented control backgrounds.
    /// Never use for primary CTAs, cards, or modal surfaces.
    static let md: CGFloat = 12

    /// 16pt — Cards and primary action buttons.
    /// Use for all content cards regardless of elevation level, and for the HoloCTAButton.
    /// Never use for modals, sheets, or surfaces larger than a card.
    static let lg: CGFloat = 16

    /// 24pt — Modals, sheets, and large overlay surfaces.
    /// Use for bottom sheets, full-screen overlays presented over content, and large surface containers.
    /// Never use for cards or buttons — this radius is reserved for surfaces that sit above cards.
    static let xl: CGFloat = 24

    /// 20pt — Onboarding cards, home widgets, and pairing surfaces.
    /// Use for the dominant off-grid card radius seen across onboarding and home feature surfaces.
    /// Distinct from lg (16pt cards) and xl (24pt modals) — sits between them for hero containers.
    static let container: CGFloat = 20

    /// Infinity — Fully rounded capsule shape.
    /// Use for selectable pills, toggle tracks, and any element that must render as a perfect capsule.
    /// SwiftUI mathematically clamps .infinity to perfectly round the shortest edge.
    /// Never use for cards, buttons, inputs, or any rectangular surface.
    static let pill: CGFloat = .infinity

    /// 57pt — Native-style presented sheet corners for Dynamic Island devices.
    /// Apple's native bottom sheets on modern Pro devices (iPhone 14/15 Pro) use
    /// a much larger continuous corner radius of ~55pt to match the hardware corners.
    /// Because VaylSheetChrome applies a 2pt bleed (pushing the shape off-screen),
    /// we increase this to 57pt. This ensures exactly 55pt of the curve is
    /// visible on-screen.
    static let sheet: CGFloat = 57

    // MARK: - OB Card Radii
    // These tokens are exclusive to the Onboarding canvas and its card components.
    // They must never appear in main-app screens — the table metaphor does not
    // leave the OB boundary.

    /// 14pt — Full-size OB vertical card.
    /// Applied to VaylCardBack, VaylCardFace, and VaylCardRenderer frame clips.
    /// Distinct from lg (16pt) — the slightly tighter radius reads as a playing card,
    /// not a UI card. Do not substitute lg here.
    /// Vertical cards are OB/personal only. This token never appears on session cards.
    static let obCard: CGFloat = 14

    /// 4pt — Corner deck mini-card stack.
    /// Applied to the scaled-down card representations in CornerDeckView.
    /// At the rendered scale of the corner deck (~22% of full card size), 4pt
    /// produces the correct visual proportion of the obCard radius.
    /// Never use for full-size cards.
    static let cornerCard: CGFloat = 4

    /// 16pt — Foil wrapper overlay in BuildDeckPhase.
    /// Applied to FoilRenderer as it wraps the assembled deck.
    /// Matches lg intentionally — the foil sits over the deck surface and its
    /// edge radius must align with the card stack beneath it.
    static let foilEdge: CGFloat = 16
}
