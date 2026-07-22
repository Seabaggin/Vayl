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

    // ── Racetrack floating pill geometry ──────────────────────────────
    //
    // Verified at real logical widths in docs/mockups/tab-bar-sizing.html
    // (2026-07-21). Apple publishes metrics for the standard full-width bar
    // (~50pt over a 34pt indicator strip) but none for a floating pill, so
    // these were derived empirically and locked here rather than left as
    // literals in the view.
    //
    // 36 is deliberately OFF the AppSpacing scale (32 → 48). It is component
    // geometry, not a spacing step: it holds the pill at 80.8–83.6% of screen
    // width across every shipping width — 375 (SE/mini), 390 (16e), 393 (15/16),
    // 402 (17/17 Pro), 420 (Air), 440 (Pro Max) — a 2.8-point drift. Widths read
    // from Xcode 26.6's own simulator device profiles, not estimated.

    /// Horizontal inset per side for the floating tab pill.
    static let tabBarInset: CGFloat = 36

    /// Icon frame edge inside a tab. Drives the pill and bar heights:
    /// bar = icon + AppSpacing.sm × 4 = 60pt.
    static let tabBarIcon: CGFloat = 28

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
            screenWidth: width,
            screenHeight: geometry.size.height,
            safeAreaInsets: geometry.safeAreaInsets,
            isSmallDevice: width <= 375,
            isLargeDevice: width >= 428
        )
    }

    // MARK: - Standard Screen Spacing
    // Referenced by the Screen Building Protocol and used across all main-app screens.
    // Do not override these values per-screen — if a screen needs more breathing room,
    // the layout design should be revisited, not the tokens.

    /// 18pt — Horizontal padding from screen edge to content.
    /// Applied to the outer ScrollView or VStack container of every screen.
    static let screenHPad: CGFloat = 18

    /// 24pt — Horizontal margin applied to the OB canvas content column.
    /// Wider than screenHPad (18pt) — the OB canvas uses a more spacious
    /// margin appropriate for cinematic phase layouts.
    static let screenMargin: CGFloat = 24

    /// 32pt — Horizontal inset for the primary CTA on OB screens.
    /// Intentionally wider than screenMargin so the CTA button sits visually
    /// inside the content column rather than spanning edge-to-edge.
    static let ctaHorizontalMargin: CGFloat = 32

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

    /// 224pt — The airlock lock-in ring's base diameter (the size its geometry
    /// is proportioned against; SyncLockInRing / LockInRingBloom scale from it).
    /// The entrance grows it via scaleEffect, not by changing this value.
    static let lockInRingSize: CGFloat = 224

    /// 36pt — Width of the drag handle on a bottom sheet.
    static let dragHandleW: CGFloat = 36

    /// 4pt — Height of the drag handle on a bottom sheet.
    static let dragHandleH: CGFloat = 4

    /// 300pt — Maximum width of the expandable citation panel in StatPhase.
    /// Constrains the dense citation copy to a readable measure regardless of
    /// screen width. Matches the visual design at standard iPhone widths.
    static let citationPanelMaxWidth: CGFloat = 300

    // MARK: - Touch targets

    /// The iOS minimum comfortable hit area (HIG). Not a feel value and never tuned:
    /// it is Apple's floor, and Accessibility & Inclusion in PRODUCT.md commits to it.
    ///
    /// Use it whenever the GLYPH is smaller than the TARGET — a 15pt ⓘ, a chevron, a
    /// small close affordance. Pattern: keep the icon at its optical size and hang a
    /// `.frame(width:height:)` + `.contentShape(Rectangle())` off it, rather than
    /// inflating the icon to reach 44 (which makes it shout) or leaving a 15pt target
    /// (which makes it miss).
    static let minTouchTarget: CGFloat = 44

    // MARK: - Map Dashboard Hero (Void Rule)
    //
    // The Map hero obeys the Void Rule: it floats on the atmosphere with no card
    // chrome (clause 1 — already true, see MapUsPulseCard), and it sizes off the
    // screen, never a constant (clause 2 — what these values fix).
    //
    // These replace `mapPulseCardHeight = 218` / `mapMeAuraSize = 218 * 0.62`.
    // That 218 was named for a card that does not render and sized for a history
    // grid that moved to PulseFullView; both justifications were already dead. Its
    // last claimed job, a shared Me/Us footprint, turned out to be dead too — see
    // the retirement note below.
    // See docs/design/2026-07-17-void-rule-and-map-hero-scale.md.

    /// 0.46 of screen width — ≈184pt orb, ≈479pt glow wash at 402pt.
    ///
    /// FEEL — LOCKED 2026-07-17 on device (Bryan, iPhone 17 Pro), scrubbed live and
    /// approved at 0.459; stored as 0.46, a 0.4pt difference at this width. This is a
    /// felt value, not a derived one: the wash runs ≈2.6x the orb and bleeds past the
    /// screen edges, so the hero's real presence is nothing you can compute from this
    /// number. Do not "improve" it by arithmetic against Home's deck. Re-feel it.
    static let defaultMapHeroOrbFraction: CGFloat = 0.46

    // RETIRED 2026-07-17 — `mapHeroSlotFraction` (0.26, ≈221pt), the shared Me/Us
    // `minHeight` floor carried over from the old 218. It was co-tuned to a 135pt orb:
    // minimal hero content ran 135 + header + padding + a text line ≈ 215, so the floor
    // bound by a hair. At the locked 184pt orb it cannot bind in ANY state, empty
    // included, because the orb alone clears it. A floor below every natural height
    // enforces nothing — it was a ghost of the same species as `mapPulseCardHeight`,
    // so it goes rather than get a new magic number.
    //
    // Deleting it changes no pixels: it had already stopped binding, which means the
    // Me/Us flip has been unparented for a while and is no worse now. If the flip
    // visibly jumps on device, parity needs to be MEASURED (reserve max(me, us)), not
    // floored — a constant cannot track conditional content (the check-in pill, the
    // weather line, the linked note) and pretending otherwise is how 218 happened.

    /// The live orb fraction. A stored `var` with a default, so it lands last in the
    /// memberwise init and `from(_:)` never passes it. Nothing overrides it now that
    /// the fraction is locked; the seam stays because re-feeling the hero means
    /// re-introducing a tuner, and this is the hook it writes to.
    var mapHeroOrbFraction: CGFloat = AppLayout.defaultMapHeroOrbFraction

    /// The Map hero orb's diameter. Shared by BOTH lenses (Me's single aura and
    /// Us's split orb) so the lens flip preserves visual parity.
    var mapHeroOrbSize: CGFloat { screenWidth * mapHeroOrbFraction }

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
    /// Width of a card sitting on the OB table during the deal sequence.
    /// ~30% of screen width — small enough to read as a physical card on a surface.
    /// Distinct from obCardWidth (72%) which is used for the full-bleed expanded state.
    /// Never use obTableCardWidth for any state other than the on-table resting position.
    static func obTableCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.30, 195)
    }

    /// Height of the on-table card. Derived from obTableCardWidth at 3:2 portrait ratio.
    static func obTableCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obTableCardWidth(in: screenWidth) * 1.5
    }

    /// Width of a card in the ExperienceLevel fanned hand. Larger than the on-table
    /// row card because the fan cards overlap — the overlap absorbs the extra width.
    static func obFanCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.42, 280)
    }

    /// Height of a fan card. Derived at the 3:2 portrait ratio.
    static func obFanCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obFanCardWidth(in: screenWidth) * 1.5
    }

    /// Per-slot (offset-from-center, angle-degrees) for the three fanned-hand cards.
    /// Slot 0 = left, 1 = center (upright, on top), 2 = right. Offsets are relative to
    /// screen center; the caller adds the fan center Y (`obTableCardCenterY`).
    static func monteFanLayout(in containerWidth: CGFloat) -> [(offset: CGSize, angle: Double)] {
        let fanW = obFanCardWidth(in: containerWidth)
        let fanH = obFanCardHeight(in: containerWidth)
        let dx   = fanW * 0.58     // horizontal spread — wider so the outer cards peek out more
        let rise = fanH * 0.05     // outer cards lift slightly (held-hand arc)
        let tilt = 17.0            // outer-card fan angle (deg) — steeper = more spread
        return [
            (CGSize(width: -dx, height: -rise), -tilt),
            (CGSize(width: 0, height: 0), 0),
            (CGSize(width: dx, height: -rise), tilt)
        ]
    }

    /// Cinematic zoom applied to the on-table card during the NamePhase deal sequence.
    /// Scales `obTableCardWidth` from 30% to ~45% of screen width, matching the HTML
    /// prototype's visual proportion (195px card in a 430px max-width container).
    /// Only NamePhase applies this. Do not use in other table card contexts.
    static let obTableCardCinematicScale: CGFloat = 1.5

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

    /// 48pt — Width of the corner deck mini-card stack.
    static let cornerDeckWidth: CGFloat = 48

    /// 72pt — Height of the corner deck mini-card stack.
    static let cornerDeckHeight: CGFloat = 72

    /// 56pt — Distance from the top safe-area edge to the top of the corner deck.
    /// Sits just below the Dynamic Island with breathing room.
    /// Bump to 64 or 72 if it still reads too high on device.
    static let cornerDeckTop: CGFloat = 56

    /// 24pt — Distance from the right screen edge to the right of the corner deck.
    static let cornerDeckRight: CGFloat = 24

    // MARK: - OB Gender Card Rest Position

    /// 0.52 — Vertical position of the gender card's rest state as a fraction of screen height.
    /// Card is placed HERE from frame 0 during the dissolution sequence — it never moves.
    /// Used by VaylDirector (restY calculation) and GenderPhase (bloom layer center Y).
    static let obGenderCardRestYFrac: CGFloat = 0.52

    // MARK: - OB Deal Point Geometry
    // The deal point is the origin from which all OB cards are launched.
    // Its position is derived from screen dimensions at render time —
    // these are the constants that define its appearance and vertical anchor.

    /// 22pt — Radius of the deal point glow ring.
    /// The center dot and outer haze scale from this value in DealPointView.
    static let dealPointRadius: CGFloat = 22

    /// 0.32 — Vertical position of the deal point as a fraction of screen height.
    /// The deal point sits at the horizon where the felt meets the void.
    /// This fraction is shared with tableHorizonYFrac — they are the same anchor.
    static let dealPointYFrac: CGFloat = 0.32

    // MARK: - OB Table Geometry

    /// 0.32 — Vertical position of the table horizon line as a fraction of screen height.
    /// The felt trapezoid's top edge, the deal point, and the projected text anchor
    /// all derive from this single fraction. Change this value to reposition the
    /// entire table world simultaneously.
    static let tableHorizonYFrac: CGFloat = 0.32

    /// 0.13 — Dealer-line anchor while the forged case floats (BuildDeck Beat 4).
    /// At 2× zoom the case occupies the horizon band where projected text normally
    /// lives — a line at tableHorizonYFrac would type invisibly behind it. This
    /// anchor projects the line into the clear air above the case.
    static let forgeFloatTextYFrac: CGFloat = 0.13

    /// 0.34 — Arc peak Y fraction for the circular table surface.
    /// Matches the HTML reference prototype where the table edge sits at H*0.34,
    /// giving the "zoomed in on the table" perspective the user wants.
    /// Distinct from tableHorizonYFrac (0.32) which is the trapezoid horizon.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcPeakYFrac: CGFloat = 0.34

    /// 1.05 — Table circle radius as a fraction of screen height.
    /// Large radius ensures only the top cap of the circle is visible.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcRadiusFrac: CGFloat = 1.05

    // MARK: - OB Card Landing Slots
    // Five predefined landing configurations for the OB deal sequence.
    // Cards pick from the available pool so no two cards in the same round
    // share a landing zone. Slots are defined in screen-fraction space so
    // they adapt to any device size.

    static let obCardLandingSlots: [CardLandingSlot] = [

        // Slot 0 — Center settle: classic deal, card rests just right of center
        CardLandingSlot(
            id: 0,
            xFrac: 0.50, yFrac: 0.535,
            angleDeg: 1.8,
            jitterX: 12, jitterY: 8, jitterAngle: 1.0
        ),

        // Slot 1 — Left lean: card drifts wide left, slight CCW tilt
        CardLandingSlot(
            id: 1,
            xFrac: 0.30, yFrac: 0.61,
            angleDeg: -6.0,
            jitterX: 12, jitterY: 8, jitterAngle: 1.5
        ),

        // Slot 2 — Deep slide: card overshoots toward the player, steep CW,
        // bottom third of card clips off-screen
        CardLandingSlot(
            id: 2,
            xFrac: 0.52, yFrac: 0.74,
            angleDeg: 13.0,
            jitterX: 14, jitterY: 10, jitterAngle: 2.0
        ),

        // Slot 3 — Hard right: card cuts right, steep CCW, right edge off-screen
        CardLandingSlot(
            id: 3,
            xFrac: 0.80, yFrac: 0.64,
            angleDeg: -19.0,
            jitterX: 12, jitterY: 8, jitterAngle: 2.0
        ),

        // Slot 4 — Bottom-left diagonal: card curves lower-left, partially off-screen
        CardLandingSlot(
            id: 4,
            xFrac: 0.24, yFrac: 0.70,
            angleDeg: -11.0,
            jitterX: 12, jitterY: 10, jitterAngle: 2.5
        )
    ]

    /// Returns the Y coordinate of the optical center of the felt table surface.
    /// Derived from tableArcPeakYFrac — the fraction where the spectrum rim arc peaks.
    /// The table surface runs from that point to the bottom of the screen.
    /// Card center is the midpoint of that zone.
    /// Use this for every card resting position in the OB sequence.
    /// Never hardcode 0.55 or any raw Y fraction for card positioning.
    static func obTableCardCenterY(in screenHeight: CGFloat) -> CGFloat {
        let arcPeakY    = screenHeight * tableArcPeakYFrac
        let tableHeight = screenHeight - arcPeakY
        return arcPeakY + (tableHeight * 0.50)
    }

    // MARK: - OB NamePhase Layout Tokens
    // Exclusive to NamePhase. Never use in main-app screens.

    /// 80pt — Height of the swipe-to-submit zone above the name input field.
    static let swipeZoneHeight: CGFloat = 80

    /// 80pt — Translation threshold for a swipe-down to register as a submit gesture.
    static let swipeSubmitThreshold: CGFloat = 80

    /// 1.2 — Multiplier applied to screen height for the dragY exit translation on submit.
    /// Ensures the UI travels well past the screen bottom before disappearing.
    static let dragExitMultiplier: CGFloat = 1.2

    /// 30 — Maximum character count for a user-entered display name.
    static let maxNameLength: Int = 30

    /// 28pt — Blur radius applied to the card during the lift-toward-camera sequence.
    static let cardLiftBlurRadius: CGFloat = 28.0

    /// 4.5 — Scale multiplier for the card diving toward the camera during performLift.
    /// At 4.5× the card exceeds the screen width — the lens is inside the surface.
    static let cardLiftDiveMultiplier: CGFloat = 4.5

    /// 0.5pt — Letter-spacing applied to the user's name in the greeting display.
    static let nameLetterSpacing: CGFloat = 0.5

    // MARK: - StatPhase Hero Numeral
    // Exclusive to the StatPhase "1 in 5" hero. Never use elsewhere.

    /// Responsive point size for the holographic stat hero numeral.
    /// Lives here (not as inline literals in StatPhase) so the hero scales by the
    /// same geometry rules as every other OB element. Three steps, by usable height
    /// and width: short devices (SE) shrink to 100pt to clear the cascade; tall wide
    /// devices (Pro Max) grow to 164pt; the common case sits at 140pt. Dynamic Type
    /// still scales the result via AppFonts.statHero's relativeTo: .largeTitle anchor.
    static func statHeroSize(usableHeight: CGFloat, screenWidth: CGFloat) -> CGFloat {
        if usableHeight <= 700 { return 100 }
        return screenWidth > 390 ? 164 : 140
    }

    // MARK: - OB Flourish Geometry
    // Exclusive to VaylFlourishView. Never use in main-app screens.

    /// 280pt — Width of the VaylFlourishView decorative component.
    static let flourishWidth: CGFloat = 280

    /// 72pt — Height of the VaylFlourishView decorative component.
    static let flourishHeight: CGFloat = 72

    /// 1.015 — Scale factor for the ambient breathing pulse on VaylFlourishView.
    static let flourishPulseScale: CGFloat = 1.015

    /// Visible position offset for the greeting row. Negative = moves up.
    /// Proportional to screen height for correct positioning across device sizes.
    static func greetingOffsetVisible(in screenHeight: CGFloat) -> CGFloat {
        -(screenHeight * 0.07)
    }

    /// Hidden/resting position offset for the greeting row.
    static func greetingOffsetHidden(in screenHeight: CGFloat) -> CGFloat {
        screenHeight * 0.017
    }
}
