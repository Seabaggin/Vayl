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
}
