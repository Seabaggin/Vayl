//
//  AppSpacing.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// App/Theme/AppSpacing.swift

import CoreGraphics

/// Tier 2 — Semantic spacing tokens.
/// Every padding, gap, and spacing value in the codebase must reference one of these.
/// Hardcoded numeric values in `.padding()`, `.spacing()`, or `.offset()` are a violation.
/// Nothing in this file may be referenced from VaylPrimitives — spacing has no primitive tier.
internal enum AppSpacing {

    /// 2pt — Micro-adjustments only.
    /// Use for drag handle gaps, dot separators, and sub-pixel optical corrections.
    /// Never use as a structural gap or content spacing value.
    static let xxs: CGFloat = 2

    /// 4pt — Tight internal gaps only.
    /// Use between an icon and its adjacent label, or between two tightly coupled inline elements.
    /// Never use as a structural margin or between independent content blocks.
    static let xs: CGFloat = 4

    /// 8pt — Compact vertical or horizontal gaps between related elements.
    /// Use between a title and its subtitle, between stacked labels in a card, or inside a pill's internal padding.
    /// Never use as a screen-edge margin or between independent sections.
    static let sm: CGFloat = 8

    /// 16pt — Default structural gap and card-edge padding.
    /// Use as the standard horizontal padding inside cards, the gap between form fields,
    /// and the vertical spacing between related content groups within a section.
    static let md: CGFloat = 16

    /// 24pt — Section separation and screen-edge horizontal margin.
    /// Use as the leading and trailing margin from screen edges to content,
    /// and as the vertical gap between independent sections on a screen.
    static let lg: CGFloat = 24

    /// 32pt — Bottom padding above sticky or bottom-anchored CTAs.
    /// Use to create breathing room between the last content element and a fixed bottom button.
    /// Also use as generous internal vertical padding on tall modal surfaces.
    static let xl: CGFloat = 32

    /// 48pt — Hero and top-of-screen breathing room.
    /// Use as the top padding above a screen's primary headline, and as the vertical gap
    /// between major structural breaks such as a hero block and the first content section.
    static let xxl: CGFloat = 48
}
