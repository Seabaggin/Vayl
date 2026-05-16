//  AppSafeArea.swift
//  Vayl
//
//  Design System — Phase 2.2
//
//  Safe area helpers built on top of AppLayout. These replace every hardcoded
//  top and bottom padding value that was being used as a hardware-clearance proxy.
//
//  The two patterns this file solves:
//
//  1. Sticky bottom CTAs — buttons that sit above the home indicator without
//     overlapping it. Always use .stickyBottomCTA() on the containing view,
//     never .padding(.bottom, 34) or .padding(.bottom, 100).
//
//  2. Content top clearance — clearing the Dynamic Island, notch, or status
//     bar when a view intentionally extends behind the system chrome.
//     Always use .topClearance(layout:) rather than .padding(.top, 60).
//
//  Rules:
//  - Never hardcode .padding(.top, 60), .padding(.top, 120), .padding(.bottom, 34),
//    or .padding(.bottom, 100) as hardware-clearance proxies anywhere in the app.
//  - .safeAreaInset(edge:) is the correct SwiftUI primitive — use it here and
//    nowhere else. Call sites use the named modifiers below, never the primitive.
//  - .bottomContentInset(_:) must never be used on a scroll view that also has
//    .stickyBottomCTA — .stickyBottomCTA automatically adjusts the scroll inset.
//    Double-applying will produce double bottom padding.
//  - AppLayout must be resolved at the screen root before any of these helpers
//    are called. Do not instantiate AppLayout inside a helper.

import SwiftUI

// MARK: - Sticky Bottom CTA

extension View {

    /// Attaches a sticky bottom CTA to the view, sitting flush above the home
    /// indicator or bottom of screen using real safe area geometry.
    ///
    /// This replaces every instance of .padding(.bottom, 100) and
    /// .padding(.bottom, 34) used as tab-bar or home-indicator proxies.
    ///
    /// Usage:
    ///     ScrollView {
    ///         content
    ///     }
    ///     .stickyBottomCTA {
    ///         VaylButton("Continue") { ... }
    ///     }
    ///
    /// The spacing between the CTA and the home indicator is AppSpacing.md (16pt).
    /// The CTA itself is not padded — callers control internal button padding.
    ///
    /// Do NOT combine with .bottomContentInset(_:) on the same scroll view.
    /// .safeAreaInset automatically adjusts the scroll view's content inset —
    /// adding .bottomContentInset on top will double-pad the bottom.
    func stickyBottomCTA<CTA: View>(@ViewBuilder cta: () -> CTA) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            cta()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                // ignoresSafeAreaEdges: .bottom forces the material to bleed
                // to the physical bezel — without this the frosted glass clips
                // at the safe area boundary leaving a transparent gap.
                .background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)
        }
    }

    /// Adds bottom padding equal to the real home indicator inset plus a
    /// standard content gap. Use on scroll content that must not be occluded
    /// by a tab bar or the home indicator.
    ///
    /// This replaces .padding(.bottom, 100) used as a tab-bar-height proxy
    /// in HomeDashboardView and HomeRouterView.
    ///
    /// ONLY use on scroll views that do NOT have .stickyBottomCTA attached.
    /// .stickyBottomCTA handles scroll inset automatically via .safeAreaInset.
    func bottomContentInset(_ layout: AppLayout) -> some View {
        self.padding(.bottom, layout.safeAreaInsets.bottom + AppSpacing.xl)
    }

    /// Bottom content inset including optional tab bar height.
    /// Use for floating elements and overlay content that must clear both the home
    /// indicator and, optionally, a visible tab bar.
    ///
    /// Usage:
    ///   .bottomClearance(layout)                          // home indicator + AppSpacing.xl
    ///   .bottomClearance(layout, includesTabBar: true)    // home indicator + tab bar + AppSpacing.xl
    ///
    /// Do NOT combine with .stickyBottomCTA or .bottomContentInset on the same scroll view.
    func bottomClearance(_ layout: AppLayout, includesTabBar: Bool = false) -> some View {
        let extra = includesTabBar ? layout.tabBarHeight : 0
        return self.padding(.bottom, layout.safeAreaInsets.bottom + AppSpacing.xl + extra)
    }

    /// Adds top padding equal to the real Dynamic Island or notch inset plus
    /// an optional additional padding value (defaults to AppSpacing.md).
    /// Use on content that sits directly below the system chrome without a navigation bar.
    ///
    /// Usage:
    ///   .topClearance(layout)                         // clearance + AppSpacing.md
    ///   .topClearance(layout, padding: AppSpacing.lg) // clearance + custom breathing room
    ///   .topClearance(layout, padding: 0)             // bare clearance only
    ///
    /// This replaces .padding(.top, 60) and .padding(.top, 120) used as
    /// safe-area proxies in HomeDashboardView, GravLiftView, PulseFullView,
    /// and RacetrackTabBar.
    func topClearance(_ layout: AppLayout, padding: CGFloat = AppSpacing.md) -> some View {
        self.padding(.top, layout.safeAreaInsets.top + padding)
    }
}

// MARK: - Safe Area Values

extension AppLayout {

    /// The minimum bottom padding required to clear the home indicator.
    /// Zero on devices without a home indicator (iPhone SE 1st gen, iPad with
    /// home button). Use this when you need the raw inset value rather than
    /// a view modifier.
    var homeIndicatorInset: CGFloat {
        safeAreaInsets.bottom
    }

    /// The minimum top padding required to clear the Dynamic Island, notch,
    /// or status bar. Use this when you need the raw inset value rather than
    /// a view modifier.
    var topHardwareInset: CGFloat {
        safeAreaInsets.top
    }

    /// True when the device has a home indicator rather than a home button —
    /// i.e. the bottom safe area inset is greater than zero.
    /// Use to conditionally apply extra bottom breathing room on notchless devices.
    var hasHomeIndicator: Bool {
        safeAreaInsets.bottom > 0
    }

    /// True when the device has a Dynamic Island or notch —
    /// i.e. the top safe area inset is greater than the status bar height.
    /// 20pt is the standard status bar height on non-notched devices.
    var hasNotchOrIsland: Bool {
        safeAreaInsets.top > 20
    }
}
