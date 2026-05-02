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
}