//
//  AppLayout.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


//
//  AppLayout.swift
//  Vayl
//
//  Design System — Phase 2.1
//
//  AppLayout resolves real screen geometry from a GeometryProxy and exposes
//  derived layout values used throughout the app. This is the single source
//  of truth for screen dimensions, device-class breakpoints, and safe area insets.
//
//  Usage — at the root of any screen-level view:
//
//      GeometryReader { geo in
//          let layout = AppLayout.from(geo)
//          YourView(layout: layout)
//      }
//
//  Rules:
//  - UIScreen.main.bounds is banned. Always use AppLayout.from(geometry).
//  - Never hardcode width, height, or safe-area offsets for layout purposes.
//  - Never hardcode .padding(.top, 60) or .padding(.bottom, 34) to clear
//    hardware elements — use layout.safeAreaInsets.top / .bottom instead.
//  - cardWidth, fullWidth, and contentMaxWidth are the only permitted width
//    values in layout code. Never derive your own from screenWidth directly.
//  - isSmallDevice and isLargeDevice drive conditional layout — never branch
//    on hardcoded point values in views.

import SwiftUI

struct AppLayout {

    // MARK: - Screen Dimensions

    /// Full screen width resolved from GeometryProxy. Never hardcode this value.
    let screenWidth: CGFloat

    /// Full screen height resolved from GeometryProxy. Never hardcode this value.
    let screenHeight: CGFloat

    // MARK: - Safe Area Insets

    /// Safe area insets resolved from GeometryProxy.
    /// Accounts for the Dynamic Island, notch, status bar, and home indicator
    /// on every device without hardcoding any pixel values.
    ///
    /// - `safeAreaInsets.top`    — clears the Dynamic Island, notch, or status bar.
    /// - `safeAreaInsets.bottom` — clears the home indicator on notchless devices.
    ///
    /// Use these wherever the violation catalogue shows .top, 60 or .bottom, 100
    /// or .bottom, 34 used as hardware-clearance proxies.
    let safeAreaInsets: EdgeInsets

    // MARK: - Device Class

    /// True for iPhone SE and iPhone mini form factors — screen width at or below 375pt.
    /// Use to apply compact layout adjustments, never to gate features.
    let isSmallDevice: Bool

    /// True for iPhone Pro Max and Plus form factors — screen width at or above 428pt.
    /// Use to apply expanded layout where additional breathing room is available.
    let isLargeDevice: Bool

    // MARK: - Derived Layout Values

    /// Standard content width with symmetric horizontal margins.
    /// Equal to screenWidth minus two AppSpacing.lg margins (24pt each side).
    /// Use for cards, form fields, and single-column content blocks.
    var cardWidth: CGFloat {
        screenWidth - (AppSpacing.lg * 2)
    }

    /// Full bleed width — equal to screenWidth.
    /// Use only for backgrounds, hero imagery, and tab bars that span edge to edge.
    /// All interactive content must remain within cardWidth or contentMaxWidth.
    var fullWidth: CGFloat {
        screenWidth
    }

    /// Maximum content width for readability on large screens.
    /// Clamps at 460pt so that text and form content never becomes uncomfortably
    /// wide on Pro Max devices. Use for body text containers and form layouts.
    var contentMaxWidth: CGFloat {
        min(screenWidth - (AppSpacing.lg * 2), 460)
    }

    // MARK: - Tab Bar

    /// Height of the visible UITabBar, read from the key window at call time.
    /// Returns 0 when no tab bar is present (onboarding, sheets, modals).
    /// Use with .bottomClearance(_:includesTabBar:) — do not read this value directly in views.
    var tabBarHeight: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.rootViewController?
            .view.subviews
            .first(where: { $0 is UITabBar })?
            .frame.height ?? 0
    }

    // MARK: - Factory

    /// Resolves an AppLayout from a GeometryProxy.
    /// Call this once at the root of a screen-level view and pass the result down.
    /// Never call UIScreen.main.bounds — this is the only permitted resolution path.
    static func from(_ geometry: GeometryProxy) -> AppLayout {
        let width = geometry.size.width
        return AppLayout(
            screenWidth:    width,
            screenHeight:   geometry.size.height,
            safeAreaInsets: geometry.safeAreaInsets,
            isSmallDevice:  width <= 375,
            isLargeDevice:  width >= 428
        )
    }

    // MARK: - Standard Screen Spacing
    // Referenced by the Screen Building Protocol and used across all main-app screens.
    // Do not override these values per-screen — if a screen needs more breathing room,
    // the layout design should be revisited, not the tokens.

    /// 18pt — Horizontal padding from screen edge to content.
    /// Applied to the outer ScrollView or VStack container of every screen.
    static let screenHPad: CGFloat = 18

    /// 20pt — Vertical padding at the top of every screen's scroll content.
    /// Provides breathing room below the header before the first card.
    static let screenVPad: CGFloat = 20

    /// 16pt — Horizontal padding inside a card, from card edge to card content.
    static let cardHPad: CGFloat = 16

    /// 14pt — Vertical padding inside a card, from card edge to card content.
    static let cardVPad: CGFloat = 14

    /// 10pt — Vertical gap between adjacent cards in a list or stack.
    static let cardGap: CGFloat = 10

    /// 24pt — Vertical gap between distinct sections on a screen.
    static let sectionGap: CGFloat = 24

    /// 13pt — Horizontal gap between an icon and its accompanying label in a row.
    static let rowGap: CGFloat = 13

    // MARK: - Standard Component Sizing

    /// 52pt — Height of a primary CTA button.
    static let ctaHeight: CGFloat = 52

    /// 32pt — Height of a filter pill or selection pill.
    static let pillHeight: CGFloat = 32

    /// 14pt — Horizontal padding inside a pill, from pill edge to label.
    static let pillHPad: CGFloat = 14

    /// 30pt — Tap area size for a ghost icon button (icon-only, no label).
    /// The visible icon may be smaller — this is the minimum hit target.
    static let iconBtnSize: CGFloat = 30

    /// 36pt — Width of the drag handle on a bottom sheet.
    static let dragHandleW: CGFloat = 36

    /// 4pt — Height of the drag handle on a bottom sheet.
    static let dragHandleH: CGFloat = 4

    /// 300pt — Maximum width of the expandable citation panel in StatPhase.
    /// Constrains the dense citation copy to a readable measure regardless of
    /// screen width. Matches the visual design at standard iPhone widths.
    static let citationPanelMaxWidth: CGFloat = 300

    // MARK: - OB Card Geometry
    // These values are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens — the table metaphor
    // does not leave the OB boundary.
    //
    // All functions take screenWidth as a parameter because OB card geometry
    // is a function of screen width, not a fixed constant. Pass geo.size.width
    // from the GeometryReader in OnboardingCanvasView.

    /// Width of a full-size OB vertical card.
    /// Clamps at 320pt to preserve card proportions on Pro Max devices.
    /// Vertical cards are OB/personal only. Horizontal cards are session/shared.
    static func obCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.72, 320)
    }

    /// Height of a full-size OB vertical card.
    /// Derived from obCardWidth at a fixed 3:2 portrait aspect ratio (×1.5).
    static func obCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obCardWidth(in: screenWidth) * 1.5
    }

    /// Width of a session card (horizontal orientation).
    /// Clamps at 480pt. Used in the main app session flow, never in OB.
    static func sessionCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.88, 480)
    }

    /// Height of a session card (horizontal orientation).
    /// Derived from sessionCardWidth at a fixed aspect ratio (×0.708).
    static func sessionCardHeight(in screenWidth: CGFloat) -> CGFloat {
        sessionCardWidth(in: screenWidth) * 0.708
    }

    // MARK: - OB Corner Deck Geometry
    // The corner deck occupies the top-right corner of OnboardingCanvasView
    // from NamePhase onward. These constants define its frame and position.
    // The top-right ✦ mark is replaced by the corner deck — never overlap them.

    /// 30pt — Width of the corner deck mini-card stack.
    static let cornerDeckWidth:  CGFloat = 30

    /// 45pt — Height of the corner deck mini-card stack.
    static let cornerDeckHeight: CGFloat = 45

    /// 14pt — Distance from the top safe-area edge to the top of the corner deck.
    static let cornerDeckTop:    CGFloat = 14

    /// 18pt — Distance from the right screen edge to the right of the corner deck.
    static let cornerDeckRight:  CGFloat = 18

    // MARK: - OB Deal Point Geometry
    // The deal point is the origin from which all OB cards are launched.
    // Its position is derived from screen dimensions at render time —
    // these are the constants that define its appearance and vertical anchor.

    /// 22pt — Radius of the deal point glow ring.
    /// The center dot and outer haze scale from this value in DealPointView.
    static let dealPointRadius:  CGFloat = 22

    /// 0.32 — Vertical position of the deal point as a fraction of screen height.
    /// The deal point sits at the horizon where the felt meets the void.
    /// This fraction is shared with tableHorizonYFrac — they are the same anchor.
    static let dealPointYFrac:   CGFloat = 0.32

    // MARK: - OB Table Geometry

    /// 0.32 — Vertical position of the table horizon line as a fraction of screen height.
    /// The felt trapezoid's top edge, the deal point, and the projected text anchor
    /// all derive from this single fraction. Change this value to reposition the
    /// entire table world simultaneously.
    static let tableHorizonYFrac: CGFloat = 0.32

    /// 0.52 — Arc peak Y fraction for the circular table surface.
    /// Distinct from tableHorizonYFrac (0.32) which is the trapezoid horizon.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcPeakYFrac: CGFloat = 0.52

    /// 1.05 — Table circle radius as a fraction of screen height.
    /// Large radius ensures only the top cap of the circle is visible.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcRadiusFrac: CGFloat = 1.05
}
