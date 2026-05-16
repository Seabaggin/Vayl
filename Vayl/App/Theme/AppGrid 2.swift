//
//  AppGrid.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


//
//  AppGrid.swift
//  Vayl
//
//  Design System — Phase 2.3
//
//  Grid constants for consistent content layout across the app.
//  All values derive from AppLayout and AppSpacing — nothing is hardcoded.
//
//  Rules:
//  - Never use a raw CGFloat for column count, gutter width, or content width.
//  - All width calculations go through AppLayout — never UIScreen.
//  - These constants describe layout geometry only. Component-level spacing
//    (internal padding, icon gaps, label offsets) still uses AppSpacing directly.
//
//  Usage:
//      GeometryReader { geo in
//          let layout = AppLayout.from(geo)
//          let grid   = AppGrid(layout: layout)
//          LazyVGrid(columns: grid.twoColumnGrid) { ... }
//      }

import SwiftUI

struct AppGrid {

    // MARK: - Init

    private let layout: AppLayout

    init(layout: AppLayout) {
        self.layout = layout
    }

    // MARK: - Gutter

    /// Standard gutter between columns and between a column and the screen edge.
    /// Always AppSpacing.md — 16pt.
    var gutter: CGFloat {
        AppSpacing.md
    }

    // MARK: - Column Widths

    /// Full single-column content width.
    /// Equal to AppLayout.cardWidth — screenWidth minus two AppSpacing.lg margins.
    /// Use for cards, form fields, and any full-width single-column content.
    var singleColumn: CGFloat {
        layout.cardWidth
    }

    /// Width of one column in a symmetric two-column layout.
    /// Derived from cardWidth minus one internal gutter, divided by two.
    /// Use for paired cards, category tiles, and two-up grids.
    var twoColumnItem: CGFloat {
        (layout.cardWidth - gutter) / 2
    }

    /// Width of one column in a symmetric three-column layout.
    /// Derived from cardWidth minus two internal gutters, divided by three.
    /// Use for icon grids, tag rows, and compact three-up layouts.
    var threeColumnItem: CGFloat {
        (layout.cardWidth - (gutter * 2)) / 3
    }

    // MARK: - SwiftUI GridItem Arrays

    /// Single adaptive column filling the full content width.
    /// Use with LazyVGrid for single-column scrolling lists.
    var singleColumnGrid: [GridItem] {
        [GridItem(.flexible(), spacing: 0)]
    }

    /// Two fixed-width columns with a standard gutter.
    /// Use for paired card layouts and two-up grids.
    var twoColumnGrid: [GridItem] {
        [
            GridItem(.fixed(twoColumnItem), spacing: gutter),
            GridItem(.fixed(twoColumnItem), spacing: 0)
        ]
    }

    /// Three fixed-width columns with standard gutters.
    /// Use for icon grids and compact three-up layouts.
    var threeColumnGrid: [GridItem] {
        [
            GridItem(.fixed(threeColumnItem), spacing: gutter),
            GridItem(.fixed(threeColumnItem), spacing: gutter),
            GridItem(.fixed(threeColumnItem), spacing: 0)
        ]
    }

    // MARK: - Vertical Section Spacing

    /// Standard vertical spacing between major content sections on a screen.
    /// Always AppSpacing.xl — 32pt.
    var sectionSpacing: CGFloat {
        AppSpacing.xl
    }

    /// Standard vertical spacing between items within a section.
    /// Always AppSpacing.md — 16pt.
    var itemSpacing: CGFloat {
        AppSpacing.md
    }

    /// Compact vertical spacing for dense lists and tight stacks.
    /// Always AppSpacing.sm — 8pt.
    var compactSpacing: CGFloat {
        AppSpacing.sm
    }
}