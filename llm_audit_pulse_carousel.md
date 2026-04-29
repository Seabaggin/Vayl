# LLM Audit Context — Open Lightly · Pulse + Card Carousel

> **Scope: Everything in the home content stack below the greeting.**
>
> Visual layout (top → bottom):
>   [1] Stacked prompt card carousel
>       → CardCarousel / AtmosphericGhostDeck / CardBackView / PickUpCard
>   [2] Pulse widget — graph, sovereign space label, check-in dot trail
>       → PulseWidget / PulseGraph / PulseDotSummary
>   [3] Research ticker strip
>       → ResearchTicker
>   [4] Full pulse / check-in flow (triggered from widget)
>       → PulseCanvasScrollView / PulseFullView / CheckInShell / DailyCheckInView
>
> Intentionally excluded:
>   - HomeDashboardView / HomeRouterView (separate audit)
>   - Learn / Explore / Onboarding features
>   - Services / Supabase layer
>
> Generated: 2026-04-21 15:52:54 PDT

---

## Table of Contents

  1. [`Open Lightly/Design/Components/Pulse/PulseCanvasScrollView.swift`](#file-open-lightly-design-components-pulse-pulsecanvasscrollview-swift)
  2. [`Open Lightly/Design/Components/Pulse/PulseDotSummary.swift`](#file-open-lightly-design-components-pulse-pulsedotsummary-swift)
  3. [`Open Lightly/Design/Components/Pulse/PulseFullView.swift`](#file-open-lightly-design-components-pulse-pulsefullview-swift)
  4. [`Open Lightly/Design/Components/Pulse/PulseGraph.swift`](#file-open-lightly-design-components-pulse-pulsegraph-swift)
  5. [`Open Lightly/Design/Components/Pulse/PulseWidget.swift`](#file-open-lightly-design-components-pulse-pulsewidget-swift)
  6. [`Open Lightly/Design/Components/Pulse/CheckInShell.swift`](#file-open-lightly-design-components-pulse-checkinshell-swift)
  7. [`Open Lightly/Design/Components/Pulse/DailyCheckInView.swift`](#file-open-lightly-design-components-pulse-dailycheckinview-swift)
  8. [`Open Lightly/Design/Components/Cards/CardCarousel.swift`](#file-open-lightly-design-components-cards-cardcarousel-swift)
  9. [`Open Lightly/Design/Components/Cards/CardBackView.swift`](#file-open-lightly-design-components-cards-cardbackview-swift)
  10. [`Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift`](#file-open-lightly-design-components-cards-atmosphericghostdeck-swift)
  11. [`Open Lightly/Features/Home/Components/PickUpCard.swift`](#file-open-lightly-features-home-components-pickupcard-swift)
  12. [`Open Lightly/Features/Home/Components/ResearchTicker.swift`](#file-open-lightly-features-home-components-researchticker-swift)
  13. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  14. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)

---

## File: `Open Lightly/Design/Components/Pulse/PulseCanvasScrollView.swift` {#file-open-lightly-design-components-pulse-pulsecanvasscrollview-swift}

```swift
// Features/Pulse/Components/PulseCanvasScrollView.swift
// Open Lightly
//
// Pure SwiftUI ScrollView wrapper for PulseGraph.
// Both axes owned by SwiftUI — no UIKit conflict.
// Anchors to bottom-trailing on appear:
//   trailing → most recent entry visible
//   bottom   → Contracted zone visible, scroll up for Expansive
//
// isGraphActive binding locks the outer HomeDashboardView ScrollView
// the moment a touch lands on the graph. Unlocks on finger lift.
// DragGesture(minimumDistance: 0) fires before the outer ScrollView
// can claim the gesture — so scroll locking is immediate.

import SwiftUI

struct PulseCanvasScrollView: View {

    // MARK: - Inputs

    let entries:      [PulseEntry]
    let cardWidth:    CGFloat
    let cardHeight:   CGFloat
    let canvasWidth:  CGFloat
    let canvasHeight: CGFloat
    var onDotTapped:  ((PulseEntry, CGPoint) -> Void)? = nil

    // MARK: - Outer scroll lock

    @Binding var isGraphActive: Bool

    // MARK: - Internal state

    @State private var hasAnchored = false

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                PulseGraph(
                    entries:          entries,
                    graphWidth:       canvasWidth,
                    graphHeight:      canvasHeight,
                    onDotTapped:      onDotTapped,
                    disableTouchGlow: true
                )
                .frame(width: canvasWidth, height: canvasHeight)
                .overlay(alignment: .bottomTrailing) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id("pulseAnchor")
                }
            }
            .onAppear {
                guard !hasAnchored else { return }
                hasAnchored = true
                DispatchQueue.main.async {
                    proxy.scrollTo("pulseAnchor", anchor: .bottomTrailing)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

```

---

## File: `Open Lightly/Design/Components/Pulse/PulseDotSummary.swift` {#file-open-lightly-design-components-pulse-pulsedotsummary-swift}

```swift
// Features/Pulse/Components/PulseDotSummary.swift
// Open Lightly
//
// Presented as a ZStack overlay over PulseGraph — not a system sheet.
// Spectrum burn expands from the tapped dot position.
// Info floats in the cleared burn space.
// Smart flip: above dot if dot is in lower 60% of graph, below if upper 40%.
// Dismiss collapses burn back into dot.
//
// Burn color system:
//   Dark mode  — full spectrum: cyan → electricViolet → magenta
//   Light mode — warm aurora:   purple → magenta (no cyan — reads clinical on cream)
// Scrim:
//   Dark mode  — pageBg at 0.95 (near-black, matches app background)
//   Light mode — Color.black at 0.78 (cream scrim kills the blackout — use true black)

import SwiftUI

// MARK: - Ember

private struct Ember: Identifiable {
    let id    = UUID()
    var x:     CGFloat
    var y:     CGFloat
    var color: Color
    var size:  CGFloat
    var angle: Double
    var speed: CGFloat
}

// MARK: - PulseDotSummary

struct PulseDotSummary: View {

    let entry:       PulseEntry
    let dotPosition: CGPoint     // position in local coordinate space of overlay
    let graphHeight: CGFloat     // total graph height for flip threshold
    var onDismiss:   () -> Void

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Burn State

    @State private var burnScale:    CGFloat = 0.0
    @State private var burnOpacity:  Double  = 0.0
    @State private var infoOpacity:  Double  = 0.0
    @State private var isDismissing: Bool    = false

    // MARK: - Char Flicker State
    // Pulses after burn has fully expanded — mimics cooling embers at edge

    @State private var charFlickerOpacity: Double = 1.0

    // MARK: - Bloom State
    // Outer glow atmosphere — soft bloom behind the hole

    @State private var bloomOpacity:  Double  = 0.0
    @State private var bloomScale:    CGFloat = 0.85

    // MARK: - Ember State

    @State private var embers:       [Ember]        = []
    @State private var emberOpacity: Double          = 0.0
    @State private var emberOffsets: [UUID: CGSize]  = [:]

    // MARK: - Burn Geometry

    private let burnDiameter:  CGFloat = 900
    private let bloomDiameter: CGFloat = 960  // slightly larger than burn, bleeds past edge

    // MARK: - Spectrum Colors
    // Dark:  cyan → electricViolet → magenta
    // Light: purple → magenta (warm aurora — no cyan on cream)

    private var ringInner: Color {
        isLight ? AppColors.purple        : AppColors.cyan
    }
    private var ringMid: Color {
        isLight ? AppColors.magenta       : AppColors.electricViolet
    }
    private var ringOuter: Color {
        isLight ? AppColors.magentaLight  : AppColors.magenta
    }

    // Scrim color — dark mode uses page background so the blackout
    // is seamless. Light mode must use true black — cream scrim
    // at 0.92 reads beige, not dark.
    private var scrimColor: Color {
        isLight ? Color.black.opacity(0.78) : AppColors.pageBg.opacity(0.95)
    }

    // MARK: - Info Position
    // Upper 40% of graph → show info below dot
    // Lower 60% of graph → show info above dot

    private var showInfoBelow: Bool {
        dotPosition.y < graphHeight * 0.40
    }

    // Vertical offset from dot center to info panel top edge
    private let infoVerticalClearance: CGFloat = 72
    // Info panel height estimate for above-dot placement
    private let infoPanelHeight: CGFloat = 210

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                // Tap anywhere to dismiss
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { triggerDismiss() }

                // Outer bloom — soft atmosphere glow behind the burn hole
                // Scales and fades independently from the burn group
                bloomLayer
                    .scaleEffect(
                        bloomScale,
                        anchor: UnitPoint(
                            x: dotPosition.x / geo.size.width,
                            y: dotPosition.y / geo.size.height
                        )
                    )
                    .opacity(bloomOpacity)

                // All burn layers + embers scale together
                // anchored to the dot position in this view's coordinate space
                ZStack {
                    burnLayer
                    charLayer
                        .opacity(charFlickerOpacity)
                    emberLayer
                }
                .scaleEffect(
                    burnScale,
                    anchor: UnitPoint(
                        x: dotPosition.x / geo.size.width,
                        y: dotPosition.y / geo.size.height
                    )
                )
                .opacity(burnOpacity)

                // Info floats outside the scaled group
                // so it doesn't scale with the burn
                infoLayer(geo: geo)
            }
        }
        .onAppear { triggerOpen() }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Check in detail for \(entry.date.formatted(.dateTime.month().day()))"
        )
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Bloom Layer
    // Soft outer atmosphere glow — bleeds past the burn edge
    // This is what makes the hole feel lit rather than just cut

    private var bloomLayer: some View {
        Canvas { context, size in
            let center = dotPosition
            let radius = bloomDiameter / 2

            let gradient = Gradient(stops: [
                .init(color: .clear,                                        location: 0.00),
                .init(color: .clear,                                        location: 0.03),
                .init(color: ringInner.opacity(isLight ? 0.18 : 0.30),     location: 0.045),
                .init(color: ringMid.opacity(isLight ? 0.12 : 0.20),       location: 0.06),
                .init(color: ringOuter.opacity(isLight ? 0.06 : 0.12),     location: 0.09),
                .init(color: .clear,                                        location: 0.16),
            ])

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width:  bloomDiameter,
                    height: bloomDiameter
                )),
                with: .radialGradient(
                    gradient,
                    center:      center,
                    startRadius: 0,
                    endRadius:   radius
                )
            )
        }
        .blur(radius: 18)
        .allowsHitTesting(false)
    }

    // MARK: - Burn Layer
    // Dark scrim with a transparent hole burned through it
    // The hole expands from the dot — inner edge glows with spectrum ring

    private var burnLayer: some View {
        Canvas { context, size in
            let center = dotPosition
            let radius = burnDiameter / 2

            let gradient = Gradient(stops: [
                // The hole — fully transparent at center
                .init(color: .clear,                                        location: 0.00),
                .init(color: .clear,                                        location: 0.04),
                // Spectrum ring at the burn edge
                .init(color: ringInner.opacity(isLight ? 0.32 : 0.55),     location: 0.05),
                .init(color: ringMid.opacity(isLight ? 0.22 : 0.40),       location: 0.065),
                .init(color: ringOuter.opacity(isLight ? 0.14 : 0.28),     location: 0.08),
                // Scrim kicks in just past the ring
                .init(color: scrimColor,                                    location: 0.12),
                .init(color: scrimColor,                                    location: 1.00),
            ])

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width:  burnDiameter,
                    height: burnDiameter
                )),
                with: .radialGradient(
                    gradient,
                    center:      center,
                    startRadius: 0,
                    endRadius:   radius
                )
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Char Layer
    // Blurred glow ring at the burn edge — the "hot char"
    // Flickers after open via charFlickerOpacity

    private var charLayer: some View {
        Canvas { context, size in
            let center = dotPosition
            let radius = burnDiameter / 2

            let gradient = Gradient(stops: [
                .init(color: .clear,                                        location: 0.00),
                .init(color: .clear,                                        location: 0.04),
                .init(color: ringInner.opacity(0.90),                       location: 0.05),
                .init(color: ringMid.opacity(0.70),                         location: 0.062),
                .init(color: ringOuter.opacity(0.50),                       location: 0.075),
                .init(color: .clear,                                        location: 0.10),
            ])

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width:  burnDiameter,
                    height: burnDiameter
                )),
                with: .radialGradient(
                    gradient,
                    center:      center,
                    startRadius: 0,
                    endRadius:   radius
                )
            )
        }
        .blur(radius: 5)
        .allowsHitTesting(false)
    }

    // MARK: - Ember Layer

    private var emberLayer: some View {
        ZStack {
            ForEach(embers) { ember in
                Circle()
                    .fill(ember.color)
                    .frame(width: ember.size, height: ember.size)
                    .shadow(color: ember.color.opacity(0.8), radius: 3)
                    .position(x: ember.x, y: ember.y)
                    .offset(emberOffsets[ember.id] ?? .zero)
                    .opacity(emberOpacity)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Info Layer

    @ViewBuilder
    private func infoLayer(geo: GeometryProxy) -> some View {

        let infoY: CGFloat = showInfoBelow
            ? dotPosition.y + infoVerticalClearance
            : dotPosition.y - infoVerticalClearance - infoPanelHeight

        let infoWidth:  CGFloat = 240
        let infoX: CGFloat = max(
            infoWidth / 2 + 16,
            min(dotPosition.x, geo.size.width - infoWidth / 2 - 16)
        )

        VStack(alignment: .leading, spacing: 0) {

            // Date
            Text(entry.date.formatted(
                .dateTime.weekday(.abbreviated).month(.abbreviated).day()
            ))
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(
                isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
            )
            .padding(.bottom, 5)

            // Tier name — gradient matches mode
            Text(entry.tier.label)
                .font(AppFonts.sectionHeading)
                .foregroundStyle(
                    LinearGradient(
                        colors: isLight
                            ? [AppColors.purple, AppColors.magenta, AppColors.gold]
                            : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .padding(.bottom, 2)

            // Glow underline
            glowUnderline
                .padding(.bottom, 4)

            // Sublabel
            Text(entry.tier.sublabel)
                .font(AppFonts.caption)
                .foregroundStyle(
                    isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                )
                .padding(.bottom, 12)

            // Answer rows
            VStack(spacing: 0) {
                infoRow(label: "Nervous system", value: entry.nervousSystem, isLast: false)
                infoRow(label: "Focus",          value: entry.focus,         isLast: false)
                infoRow(label: "Feeling",        value: entry.feeling,       isLast: false)
                infoRow(label: "Capacity",       value: entry.glowColor.label, isLast: false)
                infoRow(label: "Speed",          value: entry.speed,         isLast: true)
            }
        }
        .frame(width: infoWidth, alignment: .leading)
        .position(x: infoX, y: infoY + infoPanelHeight / 2)
        .opacity(infoOpacity)
        .allowsHitTesting(infoOpacity > 0.5)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Info Row

    private func infoRow(
        label: String,
        value: String,
        isLast: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary
                    )
                Spacer()
                Text(value)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary
                    )
            }
            .padding(.vertical, 8)

            if !isLast {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                (isLight ? Color.black : Color.white).opacity(0.06),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Glow Underline

    private var glowUnderline: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: isLight
                        ? [AppColors.purple, AppColors.magenta, AppColors.gold, .clear]
                        : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta, .clear],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
            )
            .frame(width: 140, height: 1.5)
            .shadow(color: AppColors.electricViolet.opacity(0.7), radius: 4)
            .shadow(color: AppColors.cyan.opacity(0.4),           radius: 8)
    }

    // MARK: - Open Animation

    private func triggerOpen() {
        guard !reduceMotion else {
            burnScale         = 1.0
            burnOpacity       = 1.0
            bloomOpacity      = 1.0
            bloomScale        = 1.0
            infoOpacity       = 1.0
            charFlickerOpacity = 1.0
            return
        }

        spawnEmbers()

        // Burn expands from dot
        withAnimation(.easeOut(duration: 0.70)) {
            burnScale   = 1.0
            burnOpacity = 1.0
        }

        // Bloom rises slightly behind the burn — leads the expansion
        // slightly larger scale so it bleeds past the hole edge
        withAnimation(.easeOut(duration: 0.85)) {
            bloomOpacity = 0.80
            bloomScale   = 1.0
        }

        // Embers burst outward from dot
        withAnimation(.easeOut(duration: 0.45)) {
            emberOpacity = 1.0
        }
        animateEmbers()

        // Char flicker — begins after burn has opened
        // 6 cycles of brightness pulse mimicking cooling embers
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            triggerCharFlicker(cycles: 6)
        }

        // Info fades in after burn has opened
        withAnimation(.easeOut(duration: 0.40).delay(0.55)) {
            infoOpacity = 1.0
        }

        // Embers fade as they travel
        withAnimation(.easeOut(duration: 0.40).delay(0.75)) {
            emberOpacity = 0.0
        }
    }

    // MARK: - Char Flicker
    // Alternates charLayer opacity between 1.0 and a dim value
    // Simulates cooling at the burn edge after expansion completes

    private func triggerCharFlicker(cycles: Int, current: Int = 0) {
        guard current < cycles * 2 else {
            // Settle at full opacity when done
            withAnimation(.easeOut(duration: 0.20)) {
                charFlickerOpacity = 1.0
            }
            return
        }
        let targetOpacity: Double = (current % 2 == 0) ? 0.45 : 1.0
        let duration: Double      = 0.08 + Double.random(in: 0...0.04)
        withAnimation(.easeInOut(duration: duration)) {
            charFlickerOpacity = targetOpacity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            triggerCharFlicker(cycles: cycles, current: current + 1)
        }
    }

    // MARK: - Dismiss Animation

    private func triggerDismiss() {
        guard !isDismissing else { return }
        isDismissing = true

        // Info fades first
        withAnimation(.easeIn(duration: 0.22)) {
            infoOpacity = 0.0
        }

        // Bloom fades with burn
        withAnimation(.easeIn(duration: 0.50).delay(0.08)) {
            bloomOpacity = 0.0
            bloomScale   = 0.85
        }

        // Burn collapses back into dot
        withAnimation(.easeIn(duration: 0.55).delay(0.12)) {
            burnScale   = 0.0
            burnOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            onDismiss()
        }
    }

    // MARK: - Embers
    // Dark mode:  full spectrum
    // Light mode: warm aurora (purple / magenta / gold — no cyan on cream)

    private func spawnEmbers() {
        let colors: [Color] = isLight
            ? [
                AppColors.purple,
                AppColors.magenta,
                AppColors.purpleLight,
                AppColors.magentaLight,
                AppColors.gold,
                AppColors.purple,
                AppColors.magenta,
            ]
            : [
                AppColors.cyan,
                AppColors.electricViolet,
                AppColors.magenta,
                AppColors.pink,
                AppColors.purple,
                AppColors.cyan,
                AppColors.magenta,
            ]

        embers = (0..<20).map { i in
            Ember(
                x:     dotPosition.x + CGFloat.random(in: -6...6),
                y:     dotPosition.y + CGFloat.random(in: -6...6),
                color: colors[i % colors.count],
                size:  CGFloat.random(in: 2.0...4.5),
                angle: Double.random(in: 0...(2 * .pi)),
                speed: CGFloat.random(in: 35...95)
            )
        }
    }

    private func animateEmbers() {
        embers.forEach { ember in
            let dx = CGFloat(cos(ember.angle)) * ember.speed
            let dy = CGFloat(sin(ember.angle)) * ember.speed
                   - CGFloat.random(in: 25...70) // bias upward
            withAnimation(
                .easeOut(duration: Double.random(in: 0.5...0.9))
                .delay(Double.random(in: 0.0...0.15))
            ) {
                emberOffsets[ember.id] = CGSize(width: dx, height: dy)
            }
        }
    }
}

// MARK: - Previews

#Preview("Sovereign — mid — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[1],
            dotPosition: CGPoint(x: 180, y: 160),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Expansive — high dot — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[7],
            dotPosition: CGPoint(x: 260, y: 55),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Protective — low dot — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[2],
            dotPosition: CGPoint(x: 90, y: 240),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Sovereign — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[4],
            dotPosition: CGPoint(x: 180, y: 150),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("High dot — light — flip test") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[6],
            dotPosition: CGPoint(x: 200, y: 40),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Pulse/PulseFullView.swift` {#file-open-lightly-design-components-pulse-pulsefullview-swift}

```swift
//
//  PulseFullView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/7/26.
//


// Features/Pulse/PulseFullView.swift
// Open Lightly
//
// Full Pulse history screen — lives on the Me|Us tab.
// Stub only — full implementation pending Me|Us tab design.
// Accepts entries + window selection for future build-out.
// Film burn dot summary presented here (not widget).

import SwiftUI

// MARK: - PulseFullView

struct PulseFullView: View {

    // MARK: - Inputs

    var entries:   [PulseEntry]  = PulseEntry.previews
    var onDismiss: (() -> Void)? = nil

    // MARK: - Window State
    // Owned here — widget always uses .twoWeeks

    @State private var selectedWindow: PulseWindow = .twoWeeks

    // MARK: - Camera State
    // Independent from widget — each manages its own camera

    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    // MARK: - Dot Summary State
    // Full burn animation lives here — not in widget

    @State private var summaryEntry:    PulseEntry? = nil
    @State private var summaryPosition: CGPoint     = .zero
    @State private var showSummary:     Bool        = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var filteredEntries: [PulseEntry] {
        selectedWindow.filter(entries)
    }

    private var graphHeight: CGFloat { 240 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                (isLight ? AppColors.lightPageBg : AppColors.pageBg)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Navigation bar ────────────────────────
                    navBar
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 24)

                    // ── Window selector ───────────────────────
                    windowSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // ── Graph ─────────────────────────────────
                    let pointSpacing:    CGFloat = 65
                    let safeCount                = max(0, filteredEntries.count - 1)
                    let graphContentWidth        = max(geo.size.width, CGFloat(safeCount) * pointSpacing + 104)
                    let graphContentHeight       = graphHeight * 1.6

                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        PulseGraph(
                            entries:          filteredEntries,
                            graphWidth:       graphContentWidth,
                            graphHeight:      graphContentHeight,
                            liveScore:        liveScore,
                            drawProgress:     drawProgress,
                            onDotTapped: { entry, point in
                                summaryEntry    = entry
                                summaryPosition = point
                                showSummary     = true
                            },
                            disableTouchGlow: true
                        )
                        .frame(width: graphContentWidth, height: graphContentHeight)
                    }
                    .frame(height: graphContentHeight)
                    .defaultScrollAnchor(.trailing)
                    .padding(.bottom, 24)
                    // ── Insights placeholder ──────────────────
                    insightsPlaceholder
                        .padding(.horizontal, 20)

                    Spacer()
                }

                // ── Burn overlay — full screen, no clipping ──
                if showSummary, let entry = summaryEntry {
                    PulseDotSummary(
                        entry:       entry,
                        dotPosition: summaryPosition,
                        graphHeight: geo.size.height,
                        onDismiss: {
                            showSummary  = false
                            summaryEntry = nil
                        }
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )

            Spacer()

            if onDismiss != nil {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                        )
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(
                                    isLight
                                        ? Color.black.opacity(0.05)
                                        : Color.white.opacity(0.08)
                                )
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Window Selector

    private var windowSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PulseWindow.allCases) { window in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedWindow = window
                        }
                    } label: {
                        Text(window.label)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(
                                selectedWindow == window
                                    ? (isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                                    : (isLight ? AppColors.lightTextTertiary : AppColors.textTertiary)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedWindow == window
                                            ? (isLight
                                                ? AnyShapeStyle(AppColors.magenta.opacity(0.10))
                                                : AnyShapeStyle(AppColors.electricViolet.opacity(0.20)))
                                            : AnyShapeStyle(
                                                (isLight ? Color.black : Color.white).opacity(0.05)
                                              )
                                    )
                            }
                            .overlay {
                                if selectedWindow == window {
                                    Capsule()
                                        .strokeBorder(
                                            isLight
                                                ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.5))
                                                : AnyShapeStyle(LinearGradient(
                                                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                                    startPoint: .topLeading,
                                                    endPoint:   .bottomTrailing
                                                  )),
                                            lineWidth: 1
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Insights Placeholder
    // Scaffold for future trend + insight sections.
    // Shows a clear "coming later" state without feeling broken.

    private var insightsPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("INSIGHTS")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                )

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trends unlock after 4 weeks")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary
                            )
                        Text("Keep checking in daily to see patterns emerge.")
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary
                            )
                    }
                    Spacer()

                    // Progress indicator — entries toward 28 day threshold
                    let progress = min(1.0, Double(entries.count) / 28.0)
                    ZStack {
                        Circle()
                            .stroke(
                                (isLight ? Color.black : Color.white).opacity(0.08),
                                lineWidth: 3
                            )
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                isLight ? AppColors.magenta : AppColors.electricViolet,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(entries.count)")
                            .font(AppFonts.meta)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary
                            )
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(16)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isLight ? AppColors.lightCardFill : AppColors.cardBg
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isLight ? AppColors.lightBorder : AppColors.border,
                        lineWidth: 1
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("14 entries — dark") {
    PulseFullView(entries: PulseEntry.previews)
        .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    PulseFullView(entries: PulseEntry.previews)
        .preferredColorScheme(.light)
}

#Preview("Zero entries — dark") {
    PulseFullView(entries: [])
        .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Pulse/PulseGraph.swift` {#file-open-lightly-design-components-pulse-pulsegraph-swift}

```swift
// Features/Pulse/Components/PulseGraph.swift
// Open Lightly
//
// Drawing primitive for the Pulse capacity timeline.
// Straight lines between points — dots feel like natural vertices.
// Filled landscape underneath — avoids stock chart association.
// Line breathes every 8s with a 2s breath cycle.
// Single gradient across full canvas — scales from 2 to 200 entries.
// Camera transform bindings allow DailyCheckInView to zoom + pan.
// liveScore drives today dot position during check-in.
// drawProgress animates the new line segment during resolution.
// Dot taps reported via onDotTapped callback — summary presented by parent.
// Used by PulseWidget (home) and PulseFullView (Me|Us).
//
// Architecture note — two-view split required by Animatable + Task:
// PulseGraph (public)    — stable SwiftUI identity, owns breath + demo tasks
// PulseGraphCanvas       — Animatable drawing primitive, instantiated per
//                          animation frame, owns NO tasks
// Animatable views are instantiated ~60x per second during drawProgress
// interpolation. Tasks on Animatable views crash with swift_task_dealloc
// because the throwaway instances are deallocated while tasks are in flight.
//
// Scroll architecture note:
// PulseGraphCanvas no longer owns a ScrollView.
// When used inside PulseWidget, PulseCanvasScrollView (UIViewRepresentable)
// owns both horizontal and vertical scrolling at the OS level.
// When used in CheckInShell/PulseFullView, camera bindings drive pan/zoom.

import SwiftUI

// MARK: - GraphGlowButtonStyle
// Drives touchGlow via SwiftUI's native button press state.
// ScrollView natively cancels button highlights on pan — so the glow
// fades the instant a drag begins, with no gesture conflicts.

private struct GraphGlowButtonStyle: ButtonStyle {
    @Binding var touchGlow: Double

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                withAnimation(.easeOut(duration: isPressed ? 0.15 : 0.45)) {
                    touchGlow = isPressed ? 1.0 : 0.0
                }
            }
    }
}

// MARK: - PulseGraph
// Public surface — callers use this.
// Stable SwiftUI identity across animation frames.
// Owns breath cycle and demo loop tasks.
// Passes breathPhase + demoProgress into PulseGraphCanvas as plain values.

struct PulseGraph: View {

    // MARK: - Inputs

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat
    let graphHeight: CGFloat

    var camScale:     CGFloat = 1.0
    var camTx:        CGFloat = 0.0
    var camTy:        CGFloat = 0.0
    var liveScore:    Double? = nil
    var drawProgress: CGFloat = 0.0
    var onDotTapped:  ((PulseEntry, CGPoint) -> Void)? = nil

    /// When true, disables the touch-glow DragGesture so UIScrollView pan
    /// can claim touches without SwiftUI intercepting them.
    var disableTouchGlow: Bool = false

    // MARK: - Task-Owned State
    // Lives here — not in PulseGraphCanvas.
    // PulseGraphCanvas is discarded per animation frame.
    // These values must survive across frames.

    @State private var breathPhase:  Double  = 0
    @State private var demoProgress: CGFloat = 0
    @State private var demoOpacity:  Double  = 1
    @State private var touchGlow:    Double  = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body
    // ⚠️ CRITICAL: PulseGraphCanvas MUST be wrapped in Group {}.
    // Tasks cannot attach to Animatable views directly.
    // PulseGraphCanvas is Animatable — instantiated ~60x/sec during animation.
    // Tasks on Animatable views crash with swift_task_dealloc.
    // The Group {} gives tasks a stable non-Animatable identity.
    // DO NOT remove the Group {} wrapper under any circumstances.

    var body: some View {
        // ⚠️ CRITICAL: PulseGraphCanvas MUST stay inside Group {}.
        // Tasks below cannot attach to Animatable views.
        // Button wraps only the canvas — tasks remain on the stable Group.
        Group {
            if disableTouchGlow {
                // Scroll context — render canvas directly, no touch interception.
                PulseGraphCanvas(
                    entries:      entries,
                    graphWidth:   graphWidth,
                    graphHeight:  graphHeight,
                    camScale:     camScale,
                    camTx:        camTx,
                    camTy:        camTy,
                    liveScore:    liveScore,
                    drawProgress: drawProgress,
                    breathPhase:  breathPhase,
                    demoProgress: demoProgress,
                    demoOpacity:  demoOpacity,
                    touchGlow:    touchGlow,
                    onDotTapped:  onDotTapped
                )
            } else {
                // Standalone context — Button gives us instant press state
                // that ScrollView natively cancels on pan. No DragGesture needed.
                Button(action: {}) {
                    PulseGraphCanvas(
                        entries:      entries,
                        graphWidth:   graphWidth,
                        graphHeight:  graphHeight,
                        camScale:     camScale,
                        camTx:        camTx,
                        camTy:        camTy,
                        liveScore:    liveScore,
                        drawProgress: drawProgress,
                        breathPhase:  breathPhase,
                        demoProgress: demoProgress,
                        demoOpacity:  demoOpacity,
                        touchGlow:    touchGlow,
                        onDotTapped:  onDotTapped
                    )
                }
                .buttonStyle(GraphGlowButtonStyle(touchGlow: $touchGlow))
            }
        }
        .task(id: entries.isEmpty) {
            guard entries.isEmpty else { return }
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 4.0)) { demoProgress = 1.0 }
                try? await Task.sleep(for: .seconds(5.0))
                guard !Task.isCancelled else { break }
                withAnimation(.easeOut(duration: 0.8)) { demoOpacity = 0.0 }
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { break }
                demoProgress = 0.0
                demoOpacity  = 0.0
                withAnimation(.easeIn(duration: 0.6)) { demoOpacity = 1.0 }
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8.0))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 1.0)) { breathPhase = 1.0 }
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 1.0)) { breathPhase = 0.0 }
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
    }
}

// MARK: - PulseGraphCanvas
// Animatable drawing primitive.
// Instantiated per animation frame during drawProgress interpolation.
// Owns NO tasks, NO @State that needs to persist across frames.
// breathPhase and demoProgress arrive as plain let values from PulseGraph.

private struct PulseGraphCanvas: View, Animatable {

    // MARK: - Inputs

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat
    let graphHeight: CGFloat

    // MARK: - Camera + Live State

    var camScale:     CGFloat = 1.0
    var camTx:        CGFloat = 0.0
    var camTy:        CGFloat = 0.0
    var liveScore:    Double? = nil
    var drawProgress: CGFloat = 0.0

    // MARK: - Passed from PulseGraph — not owned here

    var breathPhase:  Double  = 0
    var demoProgress: CGFloat = 0
    var demoOpacity:  Double  = 1
    var touchGlow:    Double  = 0

    // MARK: - Animatable

    var animatableData: CGFloat {
        get { drawProgress }
        set { drawProgress = newValue }
    }

    // MARK: - Dot Tap Callback

    var onDotTapped: ((PulseEntry, CGPoint) -> Void)? = nil

    // MARK: - Constants

    private let padLeft:    CGFloat = 24
    private let padRight:   CGFloat = 32
    private let padTop:     CGFloat = 72
    private let padBot:     CGFloat = 8
    private let minSpacing: CGFloat = 44

    // MARK: - Dynamic Canvas Width

    private var canvasWidth: CGFloat {
        let slotCount = entries.count + (liveScore != nil ? 1 : 0)
        let computed  = padLeft + CGFloat(max(1, slotCount - 1)) * minSpacing + padRight
        return max(graphWidth, computed)
    }

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Gradient

    private var lineColors: [Color] {
        isLight
        ? [AppColors.purple, AppColors.magenta, AppColors.gold]
        : [AppColors.cyan,   AppColors.purple,  AppColors.magenta]
    }

    private var lineGradient: Gradient {
        Gradient(stops: [
            .init(color: lineColors[0], location: 0.00),
            .init(color: lineColors[1], location: 0.55),
            .init(color: lineColors[2], location: 1.00),
        ])
    }

    private var gradientStartUnit: UnitPoint {
        UnitPoint(x: padLeft / canvasWidth, y: 0.5)
    }
    private var gradientEndUnit: UnitPoint {
        UnitPoint(x: (canvasWidth - padRight) / canvasWidth, y: 0.5)
    }
    private var gradientStartPoint: CGPoint {
        CGPoint(x: padLeft,                y: graphHeight / 2)
    }
    private var gradientEndPoint: CGPoint {
        CGPoint(x: canvasWidth - padRight, y: graphHeight / 2)
    }

    // MARK: - Breath Line Width

    private var breathLineWidth: CGFloat {
        let base:  CGFloat = isLight ? 2.8 : 2.5
        let swell: CGFloat = 1.2
        return base + CGFloat(breathPhase) * swell
    }

    private var breathGlowWidth: CGFloat {
        let base:  CGFloat = isLight ? 7.0 : 6.5
        let swell: CGFloat = 3.0
        return base + CGFloat(breathPhase) * swell
    }

    private var breathGlowOpacity: Double {
        0.35 + breathPhase * 0.30
    }

    // MARK: - Geometry Helpers

    var usableWidth:  CGFloat { canvasWidth  - padLeft - padRight }
    var usableHeight: CGFloat { graphHeight  - padTop  - padBot   }

    func xForIndex(_ index: Int) -> CGFloat {
        let totalSlots = entries.count + (liveScore != nil ? 1 : 0)
        guard totalSlots > 1 else {
            return padLeft + usableWidth / 2
        }
        return padLeft + (CGFloat(index) / CGFloat(totalSlots - 1)) * usableWidth
    }

    func yForScore(_ score: Double) -> CGFloat {
        padTop + CGFloat((4.0 - score) / 3.0) * usableHeight
    }

    private func pointForIndex(_ index: Int) -> CGPoint {
        CGPoint(
            x: xForIndex(index),
            y: yForScore(entries[index].capacityScore)
        )
    }

    private var liveDotPoint: CGPoint? {
        guard let score = liveScore else { return nil }
        return CGPoint(
            x: xForIndex(entries.count),
            y: yForScore(score)
        )
    }

    // MARK: - Body
    // No ScrollView here — PulseCanvasScrollView owns scrolling when
    // used in PulseWidget. Camera bindings handle pan in CheckInShell.

    var body: some View {
        ZStack(alignment: .topLeading) {
            graphContent
        }
        .frame(width: canvasWidth, height: graphHeight)
        .scaleEffect(camScale, anchor: .topLeading)
        .offset(x: camTx, y: camTy)
    }

    // MARK: - Graph Content

    @ViewBuilder
    private var graphContent: some View {
        Canvas { context, size in
            switch entries.count {
            case 0:
                drawDemo(context: context, size: size)
            case 1:
                drawTierGuides(context: context, size: size)
                drawLiveDot(context: context)
            default:
                drawTierGuides(context: context, size: size)
                drawFill(context: context, size: size)
                drawGlowLine(context: context, size: size)
                drawNewSegment(context: context)
                drawLiveDot(context: context)
            }
        }
        .frame(width: canvasWidth, height: graphHeight)

        tierLabelsOverlay
            .frame(width: canvasWidth, height: graphHeight)

        if entries.count >= 2 {
            crispLineLayer
                .frame(width: canvasWidth, height: graphHeight)
                .allowsHitTesting(false)
        }

        if entries.count >= 2 {
            dotsOverlay
                .frame(width: canvasWidth, height: graphHeight)
        }

        if entries.count == 1 {
            singleDotOverlay
                .frame(width: canvasWidth, height: graphHeight)
        }
    }

    // MARK: - Dot Sampling

    private var pointSpacing: CGFloat {
        guard entries.count > 1 else { return usableWidth }
        return usableWidth / CGFloat(entries.count - 1)
    }

    private var sampledIndices: [Int] {
        let minTapSpacing: CGFloat = 22
        guard entries.count > 2 else { return Array(entries.indices) }

        if pointSpacing >= minTapSpacing {
            return Array(entries.indices)
        }

        let maxDots = Int(usableWidth / minTapSpacing)
        guard maxDots > 2 else { return [0, entries.count - 1] }

        let step = max(1, entries.count / maxDots)
        var indices = stride(from: 0, to: entries.count - 1, by: step).map { $0 }
        if !indices.contains(entries.count - 1) {
            indices.append(entries.count - 1)
        }
        return indices.sorted()
    }

    // MARK: - Path Builders

    private func buildLinePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else {
            if let p = points.first {
                path.move(to: CGPoint(x: 0, y: p.y))
                path.addLine(to: p)
            }
            return path
        }
        // Left tail bleeds to canvas left edge
        path.move(to: CGPoint(x: 0, y: points[0].y))
        path.addLine(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }

    private func buildFillPath(points: [CGPoint]) -> Path {
        var path = buildLinePath(points: points)
        guard let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: graphHeight - padBot))
        path.addLine(to: CGPoint(x: 0,      y: graphHeight - padBot))
        path.closeSubpath()
        return path
    }

    // MARK: - Crisp Line Layer

    private var crispLineLayer: some View {
        let points   = entries.indices.map { pointForIndex($0) }
        let linePath = buildLinePath(points: points)

        return ZStack {
            LinearGradient(
                gradient:   lineGradient,
                startPoint: gradientStartUnit,
                endPoint:   gradientEndUnit
            )
            .mask(
                linePath.stroke(style: StrokeStyle(
                    lineWidth: breathGlowWidth,
                    lineCap:   .round,
                    lineJoin:  .round
                ))
            )
            .blur(radius: 3)
            .opacity(breathGlowOpacity)

            LinearGradient(
                gradient:   lineGradient,
                startPoint: gradientStartUnit,
                endPoint:   gradientEndUnit
            )
            .mask(
                linePath.stroke(style: StrokeStyle(
                    lineWidth: breathLineWidth,
                    lineCap:   .round,
                    lineJoin:  .round
                ))
            )
        }
    }

    // MARK: - Tier Labels Overlay
    // SwiftUI Text views positioned to match tier guide lines.
    // Must live outside Canvas — Text with dynamic Color inside Canvas
    // on an Animatable view crashes previews during hot-reload.

    private var tierLabelsOverlay: some View {
        let tiers: [(score: Double, label: String, color: Color)] = [
            (1.0, "Contracted",
             (isLight ? Color.black : Color.white).opacity(0.97)),
            (2.0, "Protective",
             isLight ? AppColors.purple  : AppColors.cyan),
            (3.0, "Sovereign",
             isLight ? AppColors.magenta : AppColors.electricViolet),
            (4.0, "Expansive",
             isLight ? AppColors.gold    : AppColors.magenta),
        ]

        return ZStack(alignment: .topLeading) {
            ForEach(Array(tiers.enumerated()), id: \.offset) { _, tier in
                let y = yForScore(tier.score)
                Text(tier.label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(tier.color)
                    .opacity(isLight ? 0.65 : 0.55)
                    .position(x: padLeft + 36, y: y - 10)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Canvas Drawing

    private func drawTierGuides(context: GraphicsContext, size: CGSize) {

        // ── Per-zone breathing opacity ────────────────────────────────────
        // Each zone offset by 0.25 of the breath cycle so they never
        // peak simultaneously. Touch glow boosts all lines together.
        // Range: dark 0.18→0.32 baseline, up to 0.63 on full touch.
        let zoneOpacity: (Int) -> Double = { index in
            let offset  = Double(index) * 0.25
            let shifted = (self.breathPhase + offset)
                .truncatingRemainder(dividingBy: 1.0)
            let sineVal = sin(shifted * .pi * 2) * 0.5 + 0.5
            let base    = self.isLight
                ? 0.35 + sineVal * 0.20   // light: 0.35 → 0.55
                : 0.18 + sineVal * 0.14   // dark:  0.18 → 0.32
            let touchBoost = self.touchGlow * 0.45
            return min(1.0, base + touchBoost)
        }

        // ── Horizontal tier lines ─────────────────────────────────────────
        // Contracted(0), Protective(1), Sovereign(2), Expansive(3)
        // No zone fills — fills were removed, orbs carry the atmosphere.
        // No bloom width swell — fixed at 4pt, only opacity responds to touch.
        let tierLines: [(score: Double, color: Color)] = [
            (1.0, (isLight ? Color.black : Color.white).opacity(0.999)),
            (2.0, isLight ? AppColors.purple  : AppColors.cyan),
            (3.0, isLight ? AppColors.magenta : AppColors.electricViolet),
            (4.0, isLight ? AppColors.gold    : AppColors.magenta),
        ]

        for (index, tier) in tierLines.enumerated() {
            let y = yForScore(tier.score)
            var linePath = Path()
            linePath.move(to:    CGPoint(x: 0,           y: y))
            linePath.addLine(to: CGPoint(x: canvasWidth, y: y))

            // Crisp solid line — no bloom, no blur
            // Bloom was causing glow bleed between zone lines
            var lineCtx = context
            lineCtx.opacity = zoneOpacity(index)
            lineCtx.stroke(
                linePath,
                with:  .color(tier.color),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
            )
        }
    }

    private func drawFill(context: GraphicsContext, size: CGSize) {
        let points   = entries.indices.map { pointForIndex($0) }
        let fillPath = buildFillPath(points: points)

        context.drawLayer { layer in
            layer.fill(
                fillPath,
                with: .linearGradient(
                    lineGradient,
                    startPoint: gradientStartPoint,
                    endPoint:   gradientEndPoint
                )
            )
            layer.blendMode = .destinationIn
            layer.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.black.opacity(isLight ? 0.22 : 0.35),
                        Color.black.opacity(isLight ? 0.08 : 0.14),
                        Color.black.opacity(0.0)
                    ]),
                    startPoint: CGPoint(x: canvasWidth / 2, y: padTop),
                    endPoint:   CGPoint(x: canvasWidth / 2, y: graphHeight - padBot)
                )
            )
        }
    }

    private func drawGlowLine(context: GraphicsContext, size: CGSize) {
        guard entries.count >= 2 else { return }
        let points   = entries.indices.map { pointForIndex($0) }
        let linePath = buildLinePath(points: points)

        let gradientStyle = GraphicsContext.Shading.linearGradient(
            lineGradient,
            startPoint: gradientStartPoint,
            endPoint:   gradientEndPoint
        )

        // Ambient bloom — breathes with breathPhase
        var ambientBloom = context
        ambientBloom.addFilter(.blur(radius: 10 + breathPhase * 5))
        ambientBloom.stroke(
            linePath,
            with:  gradientStyle,
            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
        )

        // Tight core glow
        var coreBloom = context
        coreBloom.addFilter(.blur(radius: 2 + breathPhase * 2))
        coreBloom.stroke(
            linePath,
            with:  gradientStyle,
            style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
        )

        // ── CRT phosphor burn — most recent segment ───────────────────────
        // Last segment glows hotter than the rest of the line.
        // Simulates a CRT where the most recently traced signal
        // is still phosphorescent.
        let lastIdx = entries.count - 1
        let lastPt  = pointForIndex(lastIdx)
        let prevPt  = pointForIndex(lastIdx - 1)

        var burnPath = Path()
        burnPath.move(to: prevPt)
        burnPath.addLine(to: lastPt)

        var outerBurn = context
        outerBurn.addFilter(.blur(radius: 6 + breathPhase * 3))
        outerBurn.opacity = 0.45 + breathPhase * 0.20
        outerBurn.stroke(
            burnPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 6, lineCap: .round)
        )

        var innerBurn = context
        innerBurn.addFilter(.blur(radius: 1.5))
        innerBurn.opacity = 0.70 + breathPhase * 0.25
        innerBurn.stroke(
            burnPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }

    private func drawNewSegment(context: GraphicsContext) {
        guard drawProgress > 0,
              let livePoint = liveDotPoint,
              let lastPoint = entries.indices.last.map({ pointForIndex($0) })
        else { return }

        let endX = lastPoint.x + (livePoint.x - lastPoint.x) * drawProgress
        let endY = lastPoint.y + (livePoint.y - lastPoint.y) * drawProgress
        let tip  = CGPoint(x: endX, y: endY)

        var segPath = Path()
        segPath.move(to: lastPoint)
        segPath.addLine(to: tip)

        var bloom = context
        bloom.addFilter(.blur(radius: 6))
        bloom.stroke(
            segPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 8, lineCap: .round)
        )

        context.stroke(
            segPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: isLight ? 2.8 : 2.5, lineCap: .round)
        )

        drawWeldingSparks(context: context, tip: tip, progress: drawProgress)
    }

    private func drawLiveDot(context: GraphicsContext) {
        guard let point = liveDotPoint else { return }
        let color = isLight ? AppColors.purple : AppColors.cyan

        context.fill(
            Path(ellipseIn: CGRect(x: point.x-14, y: point.y-14, width: 28, height: 28)),
            with: .color(color.opacity(0.15))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: point.x-8, y: point.y-8, width: 16, height: 16)),
            with: .color(color.opacity(0.25))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: point.x-5, y: point.y-5, width: 10, height: 10)),
            with: .color(color.opacity(0.4 + drawProgress * 0.6))
        )
    }

    // MARK: - Demo Drawing

    private func drawDemo(context: GraphicsContext, size: CGSize) {
        let demoScores: [Double] = [2.5, 3.0, 2.2, 3.2, 2.8, 3.5]
        let count = demoScores.count

        let demoPoints: [CGPoint] = demoScores.indices.map { i in
            CGPoint(
                x: padLeft + (CGFloat(i) / CGFloat(count - 1)) * usableWidth,
                y: yForScore(demoScores[i])
            )
        }

        let fullPath = buildLinePath(points: demoPoints)

        var trimmed = Path()
        fullPath.trimmedPath(from: 0, to: demoProgress).forEach { element in
            switch element {
            case .move(let p):                  trimmed.move(to: p)
            case .line(let p):                  trimmed.addLine(to: p)
            case .quadCurve(let p, let c):      trimmed.addQuadCurve(to: p, control: c)
            case .curve(let p, let c1, let c2): trimmed.addCurve(to: p, control1: c1, control2: c2)
            case .closeSubpath:                 trimmed.closeSubpath()
            }
        }

        var blurred = context
        blurred.addFilter(.blur(radius: 3))
        blurred.stroke(
            trimmed,
            with:  .color(Color.white.opacity(0.08 * demoOpacity)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
        )
        context.stroke(
            trimmed,
            with:  .color(Color.white.opacity(0.12 * demoOpacity)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
        )
    }

    // MARK: - Dot Overlays

    private var dotsOverlay: some View {
        ZStack {
            // Waypoint dots
            ForEach(sampledIndices.dropLast(), id: \.self) { i in
                let point = pointForIndex(i)
                let entry = entries[i]

                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 9, height: 9)
                    .position(point)
                    .onTapGesture { onDotTapped?(entry, point) }
                    .accessibilityLabel(dotAccessibilityLabel(for: entry))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double tap to see full summary")
            }

            // Anchor dot — last historical entry
            if let lastEntry = entries.last {
                let lastIndex = entries.count - 1
                let point     = pointForIndex(lastIndex)
                let color     = lineColors[2]

                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 20, height: 20)
                    .position(point)
                    .allowsHitTesting(false)

                Circle()
                    .fill(isLight ? AppColors.lightCardBg : AppColors.cardBg)
                    .overlay(Circle().stroke(color, lineWidth: 2))
                    .frame(width: 10, height: 10)
                    .position(point)
                    .onTapGesture { onDotTapped?(lastEntry, point) }
                    .accessibilityLabel(dotAccessibilityLabel(for: lastEntry))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double tap to see full summary")
            }

            // Today hero dot — only when no live score active
            if liveScore == nil, let lastEntry = entries.last {
                let lastIndex = entries.count - 1
                let point     = pointForIndex(lastIndex)
                let color     = lineColors[2]

                ZStack {
                    Circle()
                        .fill(color.opacity(0.12 + breathPhase * 0.10))
                        .frame(
                            width:  28 + CGFloat(breathPhase) * 4,
                            height: 28 + CGFloat(breathPhase) * 4
                        )
                    Circle()
                        .fill(color.opacity(0.22 + breathPhase * 0.12))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .shadow(
                            color:  color.opacity(0.6 + breathPhase * 0.3),
                            radius: 6 + CGFloat(breathPhase) * 4
                        )
                }
                .position(point)
                .onTapGesture { onDotTapped?(lastEntry, point) }
                .accessibilityLabel(dotAccessibilityLabel(for: lastEntry))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to see full summary")
            }
        }
    }

    // MARK: - Single Dot Overlay

    private var singleDotOverlay: some View {
        let entry = entries[0]
        let point = CGPoint(
            x: padLeft + usableWidth / 2,
            y: yForScore(entry.capacityScore)
        )
        let color = lineColors[2]

        return ZStack {
            Circle()
                .fill(color.opacity(0.12 + breathPhase * 0.10))
                .frame(
                    width:  28 + CGFloat(breathPhase) * 4,
                    height: 28 + CGFloat(breathPhase) * 4
                )
                .position(point)
                .allowsHitTesting(false)

            Circle()
                .fill(color.opacity(0.22 + breathPhase * 0.12))
                .frame(width: 18, height: 18)
                .position(point)
                .allowsHitTesting(false)

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(
                    color:  color.opacity(0.6 + breathPhase * 0.3),
                    radius: 6 + CGFloat(breathPhase) * 4
                )
                .position(point)
                .onTapGesture { onDotTapped?(entry, point) }
                .accessibilityLabel(dotAccessibilityLabel(for: entry))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to see full summary")
        }
    }

    // MARK: - Accessibility

    private func dotAccessibilityLabel(for entry: PulseEntry) -> String {
        "\(entry.date.formatted(.dateTime.month().day())). " +
        "\(entry.tier.label). " +
        "Nervous system: \(entry.nervousSystem). " +
        "Focus: \(entry.focus). " +
        "Feeling: \(entry.feeling). " +
        "Speed: \(entry.speed)."
    }

    // MARK: - Welding Sparks

    private func drawWeldingSparks(
        context:  GraphicsContext,
        tip:      CGPoint,
        progress: CGFloat
    ) {
        guard progress > 0.02 && progress < 0.97 else { return }

        let edgeFade: CGFloat = {
            let fadeIn  = min(1.0, progress / 0.08)
            let fadeOut = min(1.0, (0.97 - progress) / 0.06)
            return fadeIn * fadeOut
        }()

        guard edgeFade > 0 else { return }

        let colorWhite = Color.white
        let colorHot   = lineColors[0]
        let colorMid   = lineColors[1]
        let colorOuter = lineColors[2]

        var ctx = context
        ctx.translateBy(x: tip.x, y: tip.y)

        // Ambient halo
        var haloCtx = ctx
        haloCtx.addFilter(.blur(radius: 8))
        haloCtx.fill(
            Path(ellipseIn: CGRect(x: -18, y: -18, width: 36, height: 36)),
            with: .color(colorHot.opacity(0.36 * edgeFade))
        )
        haloCtx.fill(
            Path(ellipseIn: CGRect(x: -10, y: -10, width: 20, height: 20)),
            with: .color(colorMid.opacity(0.24 * edgeFade))
        )

        // Core
        ctx.fill(
            Path(ellipseIn: CGRect(x: -3.2, y: -3.2, width: 6.4, height: 6.4)),
            with: .color(colorWhite.opacity(0.80 * edgeFade))
        )
        var coronaCtx = ctx
        coronaCtx.addFilter(.blur(radius: 3))
        coronaCtx.fill(
            Path(ellipseIn: CGRect(x: -5.6, y: -5.6, width: 11.2, height: 11.2)),
            with: .color(colorWhite.opacity(0.56 * edgeFade))
        )

        // Sparks
        let sparkCount = 14
        for i in 0..<sparkCount {
            let fi = CGFloat(i)
            let t1 = progress * 4713.0 + fi * 137.508
            let t2 = progress * 3571.0 + fi * 89.442
            let t3 = progress * 2833.0 + fi * 61.803

            let r1 = abs(sin(t1) * cos(t2 * 0.7))
            let r2 = abs(cos(t2) * sin(t3 * 1.3))
            let r3 = abs(sin(t1 * 0.4 + t3 * 0.6))

            let baseAngle  = r1 * 360.0
            let upwardBias = -45.0 + r2 * 90.0
            let angle      = Angle(degrees: baseAngle * 0.6 + upwardBias * 0.4)

            let distance: CGFloat = r2 < 0.4 ? 3.0 + r1 * 12.0 : 14.0 + r3 * 22.0
            let tailLength: CGFloat = 3.0 + r3 * 14.0

            let sparkColor: Color = {
                if distance < 8  { return colorWhite }
                if distance < 18 { return colorHot   }
                if distance < 30 { return colorMid   }
                return colorOuter
            }()

            let flicker = abs(sin(t1 * 7.3 + t2 * 3.1))
            let opacity  = (0.25 + flicker * 0.60) * edgeFade
            guard opacity > 0.05 else { continue }

            let tailStart = CGPoint(x: distance, y: 0)
            let headEnd   = CGPoint(x: distance + tailLength, y: 0)

            var sparkPath = Path()
            sparkPath.move(to: tailStart)
            sparkPath.addLine(to: headEnd)

            var sparkCtx = ctx
            sparkCtx.rotate(by: angle)

            sparkCtx.stroke(
                sparkPath,
                with: .linearGradient(
                    Gradient(colors: [
                        .clear,
                        sparkColor.opacity(opacity * 0.6),
                        colorWhite.opacity(opacity)
                    ]),
                    startPoint: tailStart,
                    endPoint:   headEnd
                ),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
            )

            var headCtx = sparkCtx
            headCtx.addFilter(.blur(radius: 1.5))
            headCtx.fill(
                Path(ellipseIn: CGRect(x: headEnd.x-2, y: headEnd.y-2, width: 4, height: 4)),
                with: .color(sparkColor.opacity(opacity * 0.5))
            )
        }

        // Drips
        for i in 0..<2 {
            let fi   = CGFloat(i)
            let t    = progress * 1847.0 + fi * 200.0
            let drip = abs(sin(t))

            let dripX: CGFloat = -8.0 + drip * 16.0
            let dripY: CGFloat =  4.0 + drip * 10.0
            let dripR: CGFloat =  1.5 + drip * 1.5

            var dripCtx = ctx
            dripCtx.addFilter(.blur(radius: 1.5))
            dripCtx.fill(
                Path(ellipseIn: CGRect(
                    x: dripX - dripR, y: dripY - dripR,
                    width: dripR * 2, height: dripR * 2
                )),
                with: .color(colorHot.opacity(0.44 * edgeFade))
            )
        }
    }
}

// MARK: - Previews

#Preview("Zero entries — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseGraph(entries: [], graphWidth: 320, graphHeight: 200)
            .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Single entry — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseGraph(
            entries:     [PulseEntry.previews[0]],
            graphWidth:  320,
            graphHeight: 200
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("14 entries — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseGraph(
            entries:     PulseEntry.previews,
            graphWidth:  320,
            graphHeight: 200
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("14 entries — with live dot — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseGraph(
            entries:     PulseEntry.previews,
            graphWidth:  320,
            graphHeight: 200,
            liveScore:   2.5
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        PulseGraph(
            entries:     PulseEntry.previews,
            graphWidth:  320,
            graphHeight: 200
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Pulse/PulseWidget.swift` {#file-open-lightly-design-components-pulse-pulsewidget-swift}

```swift
// Features/Pulse/PulseWidget.swift
// Open Lightly
//
// Compact Pulse timeline widget for the Home dashboard.
// Dot taps → inline card slides up in footer zone.
// Graph stays fully visible — nothing is covered.
// Swipe down or tap card to dismiss.
//
// Layout — ZStack not VStack:
//   Graph fills the full card height.
//   Header floats at top with gradient fade into graph.
//   Footer floats at bottom with gradient fade into graph.
//   Orbs animate via TimelineView — three independent sine waves.
//
// Check-in: [ + ] presents CheckInShell via fullScreenCover.
// CheckInShell owns the single PulseGraph instance during check-in.
// Camera + live state owned here, passed into CheckInShell as bindings.
// No duplicate PulseGraph — the shell's graph IS the stage.

import SwiftUI

// MARK: - PulseWidget

struct PulseWidget: View {

    // MARK: - Store

    @EnvironmentObject private var store: PulseStore

    // MARK: - Inputs

    var onViewAll: (() -> Void)? = nil

    // Passed from HomeDashboardView — disables outer page scroll while
    // a finger is touching the graph canvas.
    @Binding var isGraphActive: Bool

    init(onViewAll: (() -> Void)? = nil, isGraphActive: Binding<Bool> = .constant(false)) {
        self.onViewAll      = onViewAll
        self._isGraphActive = isGraphActive
    }

    private var entries: [PulseEntry] { store.entries }

    // MARK: - Camera + Live State

    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    // MARK: - Check-In State

    @State private var showCheckIn:  Bool        = false
    @State private var pendingEntry: PulseEntry? = nil

    // MARK: - Inline Card State

    @State private var summaryEntry: PulseEntry? = nil
    @State private var cardVisible:  Bool        = false
    @GestureState private var dragY: CGFloat     = 0

    // MARK: - Layout

    private let cardHeight:   CGFloat = 282   // matches 361×282 ambient zone spec
    private let graphHeight:  CGFloat = 282   // matches cardHeight — full bleed
    private let inlineHeight: CGFloat = 200

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var currentTier: PulseTier {
        guard let last = entries.last else { return PulseTier.tier(for: 2.5) }
        return PulseTier.tier(for: last.capacityScore)
    }

    private var moodColor: Color {
        guard let last = entries.last else { return AppColors.purple }
        let score = last.capacityScore
        if score >= 3.8 { return AppColors.magenta }
        if score >= 2.8 { return AppColors.purple }
        if score >= 1.6 { return AppColors.cyan }
        return AppColors.deepBlue
    }

    private var moodColorB: Color {
        guard let last = entries.last else { return AppColors.cyan }
        let score = last.capacityScore
        if score >= 3.8 { return AppColors.purple }
        if score >= 2.8 { return AppColors.cyan }
        if score >= 1.6 { return AppColors.purple }
        return AppColors.purple
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = cardHeight

            ZStack(alignment: .top) {

                // ── Layer 1: Base fill ─────────────────────
                cardBase

                // ── Layer 2: Animated orbs ─────────────────
                if !isLight && !reduceMotion {
                    orbLayer(width: W, height: H)
                }

                // ── Layer 3: 2D Scrollable Full-bleed graph ──────────────
                let minSpacing:  CGFloat = 44
                let safeCount            = max(0, entries.count - 1)
                let canvasWidth          = max(W, CGFloat(safeCount) * minSpacing + 56)
                let canvasHeight         = graphHeight * 1.8

                PulseCanvasScrollView(
                    entries:       entries,
                    cardWidth:     W,
                    cardHeight:    H,
                    canvasWidth:   canvasWidth,
                    canvasHeight:  canvasHeight,
                    onDotTapped:   { entry, _ in showEntry(entry) },
                    isGraphActive: $isGraphActive
                )
                .frame(width: W, height: H)
                .clipShape(RoundedRectangle(cornerRadius: W * (28.0 / 393.0), style: .continuous))
                // ── Layer 4: Floating header ───────────────
                floatingHeader
                    .frame(width: W)

                // ── Layer 5: Floating footer ───────────────
                floatingFooter
                    .frame(width: W)
                    .frame(maxHeight: .infinity, alignment: .bottom)


            }
            .frame(width: W, height: H)
            .overlay(alignment: .bottom) {
                if let entry = summaryEntry {
                    inlineCard(entry: entry)
                        .offset(y: cardVisible ? max(0, dragY) : inlineHeight)
                        .animation(
                            .spring(response: 0.40, dampingFraction: 0.82),
                            value: cardVisible
                        )
                        .gesture(
                            DragGesture()
                                .updating($dragY) { value, state, _ in
                                    if value.translation.height > 0 {
                                        state = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 40 { dismissCard() }
                                }
                        )
                        .onTapGesture { dismissCard() }
                }
            }
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    isLight
                        ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.35))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.22),
                                AppColors.electricViolet.opacity(0.18),
                                AppColors.magenta.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                          )),
                    lineWidth: 1
                )
        }
        .shadow(
            color: isLight
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.20),
            radius: 24,
            y: 8
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if cardVisible { dismissCard() }
            }
        )
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInShell(
                entries:      entries,
                camScale:     $camScale,
                camTx:        $camTx,
                camTy:        $camTy,
                liveScore:    $liveScore,
                drawProgress: $drawProgress,
                onComplete: { entry in
                    pendingEntry = entry
                    showCheckIn  = false
                },
                onDismiss: {
                    resetCheckInState()
                    showCheckIn = false
                }
            )
        }
        .onChange(of: showCheckIn) { _, isShowing in
            if !isShowing, let entry = pendingEntry {
                handleNewEntry(entry)
            }
        }
    }

    // MARK: - Floating Header
    // Gradient fades from opaque at top to transparent at ~40% down.
    // Text and button sit inside the fade zone — graph is visible below.

    private var floatingHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    // Living label
                    LivingText(
                        text: "THE PULSE",
                        font: .system(size: 10, weight: .semibold, design: .monospaced)
                    )

                    // Tier name — gradient colored
                    Text(currentTier.label)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(
                            isLight
                                ? AnyShapeStyle(currentTier.lightColor)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  ))
                        )

                    // Sublabel + count
                    HStack(spacing: 0) {
                        Text(currentTier.sublabel)
                        if !entries.isEmpty {
                            Text("  ·  \(entries.count) check-in\(entries.count == 1 ? "" : "s")")
                        }
                    }
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextSecondary
                            : Color.white.opacity(0.38)
                    )
                }
                .opacity(entries.isEmpty ? 0 : 1)

                Spacer()

                // Check-in button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    resetCheckInState()
                    showCheckIn = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isLight
                                    ? AppColors.magenta.opacity(0.10)
                                    : AppColors.electricViolet.opacity(0.20)
                            )
                            .frame(width: 32, height:32)

                        Circle()
                            .strokeBorder(
                                isLight
                                    ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.6))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .topLeading,
                                        endPoint:   .bottomTrailing
                                      )),
                                lineWidth: 1.2
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                isLight ? AppColors.magenta : AppColors.purpleBright
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start daily check-in")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Gradient dissolve downward into graph
            LinearGradient(
                colors: [
                    (isLight ? AppColors.lightCardBg : AppColors.cardBg).opacity(0),
                    Color.clear
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: 24)
        }
        .background(
            // Opaque zone behind text only
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        isLight
                            ? AppColors.lightCardBg.opacity(0.96)
                            : AppColors.cardBg.opacity(0.90),
                        isLight
                            ? AppColors.lightCardBg.opacity(0.60)
                            : AppColors.cardBg.opacity(0.55),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint:   .bottom
                )
            }
        )
    }

    // MARK: - Floating Footer

    private var floatingFooter: some View {
        HStack {
            Spacer()

            if onViewAll != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onViewAll?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Full history")
                            .font(AppFonts.caption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(
                        isLight ? AppColors.magenta : AppColors.cyanLight
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    // MARK: - Orb Layer
    // Three orbs on independent sine waves.
    // TimelineView drives continuous position + opacity animation.
    // Orb A: primary mood color, drifts top-left quadrant
    // Orb B: secondary mood color, drifts bottom-right quadrant
    // Orb C: always violet, slow center drift

    @ViewBuilder
    private func orbLayer(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            let phaseA = t * 0.22
            let phaseB = t * 0.18 + 1.0
            let phaseC = t * 0.15 + 2.4
            let phaseD = t * 0.19 + 2.1
            let phaseE = t * 0.24 + 0.5

            let orbAX = width  * (0.15 + sin(phaseA) * 0.10)
            let orbAY = height * (0.22 + sin(phaseB) * 0.12)

            let orbBX = width  * (0.72 + sin(phaseC) * 0.10)
            let orbBY = height * (0.65 + sin(phaseD) * 0.10)

            let orbCX = width  * (0.50 + sin(phaseE) * 0.18)
            let orbCY = height * (0.42 + sin(phaseA * 0.7) * 0.08)

            let breathA = sin(t * 0.45) * 0.5 + 0.5
            let breathB = sin(t * 0.38 + 2.1) * 0.5 + 0.5
            let breathC = sin(t * 0.31 + 4.2) * 0.5 + 0.5

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                moodColor.opacity(0.35 + breathA * 0.20),
                                moodColor.opacity(0.14 + breathA * 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 180)
                    .position(x: orbAX, y: orbAY)
                    .blur(radius: 18)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                moodColorB.opacity(0.30 + breathB * 0.18),
                                moodColorB.opacity(0.12 + breathB * 0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 190, height: 155)
                    .position(x: orbBX, y: orbBY)
                    .blur(radius: 20)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.electricViolet.opacity(0.22 + breathC * 0.12),
                                AppColors.electricViolet.opacity(0.08 + breathC * 0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 240, height: 120)
                    .position(x: orbCX, y: orbCY)
                    .blur(radius: 24)
            }
        }
    }

    // MARK: - Card Base

    private var cardBase: some View {
        Group {
            if isLight {
                AppColors.lightCardBg
            } else {
                AppColors.cardBg
            }
        }
    }

    // MARK: - Inline Card

    private func inlineCard(entry: PulseEntry) -> some View {
        let tierColor = isLight ? entry.tier.lightColor : entry.tier.color

        return VStack(alignment: .leading, spacing: 0) {

            Capsule()
                .fill(Color.white.opacity(isLight ? 0.25 : 0.18))
                .frame(width: 32, height: 3)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 10)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(
                        .dateTime.weekday(.abbreviated).month(.abbreviated).day()
                    ))
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(
                        isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                    )

                    Text(entry.tier.label)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(tierColor)
                }

                Spacer()

                Circle()
                    .fill(tierColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: tierColor.opacity(0.6), radius: 4)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            (isLight ? Color.black : Color.white).opacity(0.06),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)
                .padding(.bottom, 8)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 6
            ) {
                compactRow(label: "Nervous system", value: entry.nervousSystem)
                compactRow(label: "Focus",          value: entry.focus)
                compactRow(label: "Feeling",        value: entry.feeling)
                compactRow(label: "Capacity",       value: entry.glowColor.label)
                compactRow(label: "Speed",          value: entry.speed)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isLight
                        ? AppColors.lightCardFill
                        : AppColors.surfaceBg
                )
                .shadow(
                    color: isLight
                        ? AppColors.lightShadowPurple
                        : AppColors.purple.opacity(0.20),
                    radius: 12,
                    y: -4
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isLight
                        ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.30))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.20),
                                AppColors.electricViolet.opacity(0.15),
                                AppColors.magenta.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                          )),
                    lineWidth: 1
                )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Compact Row

    private func compactRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppFonts.meta)
                .foregroundStyle(
                    isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                )
                .lineLimit(1)
            Text(value)
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isLight
                        ? Color.black.opacity(0.03)
                        : Color.white.opacity(0.04)
                )
        }
    }

    // MARK: - Card Actions

    private func showEntry(_ entry: PulseEntry) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        summaryEntry = entry
        withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
            cardVisible = true
        }
    }

    private func dismissCard() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
            cardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            summaryEntry = nil
        }
    }

    // MARK: - Entry Handling

    private func handleNewEntry(_ entry: PulseEntry) {
        store.add(entry)
        pendingEntry = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetCheckInState()
        }
    }

    private func resetCheckInState() {
        camScale     = 1.0
        camTx        = 0.0
        camTy        = 0.0
        liveScore    = nil
        drawProgress = 0.0
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeShort: String {
        let days = Calendar.current.dateComponents(
            [.day], from: self, to: Date()
        ).day ?? 0
        switch days {
        case 0:  return "Checked in today"
        case 1:  return "Last check-in yesterday"
        default: return "Last check-in \(days) days ago"
        }
    }
}

// MARK: - Previews

private func seededStore(
    _ entries: [PulseEntry] = PulseEntry.previews
) -> PulseStore {
    let s = PulseStore()
    entries.forEach { s.add($0) }
    return s
}

#Preview("14 entries — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            PulseWidget()
                .padding(20)
        }
    }
    .environmentObject(seededStore())
    .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            PulseWidget()
                .padding(20)
        }
    }
    .environmentObject(seededStore())
    .preferredColorScheme(.light)
}

#Preview("Zero entries — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            PulseWidget()
                .padding(20)
        }
    }
    .environmentObject(seededStore([]))
    .preferredColorScheme(.dark)
}

#Preview("Single entry — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            PulseWidget()
                .padding(20)
        }
    }
    .environmentObject(seededStore([PulseEntry.previews[0]]))
    .preferredColorScheme(.dark)
}

#Preview("With view all — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()

    
        ScrollView {
            PulseWidget(onViewAll: {})
                .padding(20)
        }
    }
    .environmentObject(seededStore())
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Pulse/CheckInShell.swift` {#file-open-lightly-design-components-pulse-checkinshell-swift}

```swift
//
//  CheckInShell.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Pulse/CheckIn/CheckInShell.swift
// Open Lightly
//
// Full-screen container for the check-in experience.
// Presented via fullScreenCover from PulseWidget.
// PulseGraph fills top 60% — always visible, never replaced.
// DailyCheckInView panel slides up from bottom 40%.
// All camera + live state owned by PulseWidget, passed as bindings.
// Background and glow field live here — not in DailyCheckInView.

import SwiftUI

struct CheckInShell: View {

    // MARK: - Inputs

    let entries: [PulseEntry]

    // Camera + live state — owned by PulseWidget
    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    // MARK: - Layout

    // Graph occupies top 60% of the shell.
    // Questions panel occupies bottom 40%.
    // These are the proportions described in the product doc.
    private let graphFraction: CGFloat = 0.60

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let graphH  = geo.size.height * graphFraction
            let graphW  = geo.size.width
            let panelH  = geo.size.height * (1 - graphFraction)

            ZStack(alignment: .top) {

                // ── Background ──────────────────────────────
                (isLight ? AppColors.lightPageBg : AppColors.pageBg)
                    .ignoresSafeArea()

                // ── Atmosphere ──────────────────────────────
                if isLight {
                    AuroraGlowField()
                        .ignoresSafeArea()
                } else {
                    OnboardingGlowField()
                        .ignoresSafeArea()
                }

                // ── Graph — top 60%, always visible ─────────
                // This is the only PulseGraph instance during check-in.
                // Camera bindings animate this graph directly.
                // The user watches themselves move here in real time.
                VStack(spacing: 0) {
                    PulseGraph(
                        entries:          entries,
                        graphWidth:       graphW,
                        graphHeight:      graphH,
                        camScale:         camScale,
                        camTx:            camTx,
                        camTy:            camTy,
                        liveScore:        liveScore,
                        drawProgress:     drawProgress,
                        disableTouchGlow: true
                    )
                    .frame(width: graphW, height: graphH)

                    Spacer()
                }

                // ── Questions panel — bottom 40% ─────────────
                // DailyCheckInView renders only its phase content here.
                // It writes into the bindings above — moves the graph.
                VStack(spacing: 0) {
                    Spacer()
                    DailyCheckInView(
                        entries:              entries,
                        graphWidth:           graphW,
                        graphHeight:          graphH,
                        camScale:             $camScale,
                        camTx:                $camTx,
                        camTy:                $camTy,
                        liveScore:            $liveScore,
                        drawProgress:         $drawProgress,

                        onComplete:           onComplete,
                        onDismiss:            onDismiss
                    )
                    .frame(height: panelH)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Harness for live binding testing

private struct CheckInShellHarness: View {
    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    var body: some View {
        CheckInShell(
            entries:      PulseEntry.previews,
            camScale:     $camScale,
            camTx:        $camTx,
            camTy:        $camTy,
            liveScore:    $liveScore,
            drawProgress: $drawProgress,
            onComplete:   { _ in },
            onDismiss:    {}
        )
    }
}

#Preview("Shell — live bindings — dark") {
    CheckInShellHarness()
        .preferredColorScheme(.dark)
}

#Preview("Shell — live bindings — light") {
    CheckInShellHarness()
        .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Pulse/DailyCheckInView.swift` {#file-open-lightly-design-components-pulse-dailycheckinview-swift}

```swift
// Features/Pulse/CheckIn/DailyCheckInView.swift
// Open Lightly
//
// 5-question daily check-in panel.
// Rendered inside CheckInShell — not a full-screen view.
// Occupies bottom 40% of the shell. Graph lives above in top 60%.
// Controls PulseGraph camera via bindings owned by PulseWidget.
// Each pill answer moves liveScore → live dot moves on graph immediately.
// Cinematic resolution fires against the graph above — not a separate graph.
// On completion returns a PulseEntry to PulseWidget for persistence.
//
// IMPORTANT: This view renders NO background and NO glow field.
// Those live in CheckInShell which owns the container.
// This view renders only its phase content within the panel frame.

import SwiftUI

// MARK: - CheckInPhase

enum CheckInPhase: Equatable {
    case idle
    case questions
    case resolving
    case done
}

// MARK: - CheckInQuestion

private struct CheckInQuestion {
    let text:  String
    let pills: [CheckInPill]
}

private struct CheckInPill: Identifiable {
    let id            = UUID()
    let label:        String
    let dy:           Double
    let glowOverride: PulseCapacityColor?

    init(_ label: String, dy: Double = 0, glow: PulseCapacityColor? = nil) {
        self.label        = label
        self.dy           = dy
        self.glowOverride = glow
    }
}

// MARK: - DailyCheckInView

struct DailyCheckInView: View {

    // MARK: - Inputs

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat      // actual rendered graph width — must match CheckInShell
    let graphHeight: CGFloat      // actual rendered graph height — must match CheckInShell

    // Camera bindings — control PulseGraph in CheckInShell
    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat
    

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    // MARK: - State

    @State private var phase:       CheckInPhase      = .idle
    @State private var dotY:        Double            = 2.5
    @State private var glowColor:   PulseCapacityColor = .indigo
    @State private var qi:          Int               = 0
    @State private var chosen:      String?           = nil
    @State private var speed:       String?           = nil

    @State private var answerNS:    String = ""
    @State private var answerFocus: String = ""
    @State private var answerFeel:  String = ""

    @State private var msgVisible:     Bool                   = false
    @State private var resolutionAttempt: Int = 0
  

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Questions

    private let questions: [CheckInQuestion] = [
        CheckInQuestion(
            text: "How is your nervous system right now?",
            pills: [
                CheckInPill("Overwhelmed",  dy: -1.0),
                CheckInPill("Exhausted",    dy: -0.5),
                CheckInPill("Stable",       dy:  0.0),
                CheckInPill("Recharging",   dy: +0.5),
                CheckInPill("Energized",    dy: +1.0),
            ]
        ),
        CheckInQuestion(
            text: "Where is your focus naturally pulling you?",
            pills: [
                CheckInPill("Deeply Inward",  dy: -0.75),
                CheckInPill("Just Me",        dy: +0.25),
                CheckInPill("Balanced",       dy:  0.0),
                CheckInPill("Reaching Out",   dy: +0.75),
            ]
        ),
        CheckInQuestion(
            text: "What's the loudest feeling underneath?",
            pills: [
                CheckInPill("Defensive",   dy: -0.5),
                CheckInPill("Anxious",     dy: -0.5),
                CheckInPill("Content",     dy: +0.5),
                CheckInPill("Secure",      dy: +0.75),
                CheckInPill("Adventurous", dy: +1.0),
            ]
        ),
        CheckInQuestion(
            text: "How is your overall capacity to hold space?",
            pills: [
                CheckInPill("Empty",    dy: 0, glow: .rose),
                CheckInPill("Low",      dy: 0, glow: .magenta),
                CheckInPill("Good",     dy: 0, glow: .indigo),
                CheckInPill("Abundant", dy: 0, glow: .cyan),
            ]
        ),
        CheckInQuestion(
            text: "What's the ideal speed for tonight?",
            pills: [
                CheckInPill("Solitude"),
                CheckInPill("Just Proximity"),
                CheckInPill("Light Connection"),
                CheckInPill("Deep Dive"),
                CheckInPill("Playful"),
            ]
        ),
    ]

    // MARK: - Computed

    private var currentQuestion: CheckInQuestion {
        questions[min(qi, questions.count - 1)]
    }

    private var currentTier: PulseTier {
        PulseTier.tier(for: dotY)
    }

    private var completionMessage: String {
        switch dotY {
        case 3.5...: return "You're expanded today. That's real."
        case 2.5...: return "Steady ground. This is enough."
        case 1.5...: return "Friction is honest data. Logged."
        default:     return "Your space is valid today. Logged."
        }
    }

    private var insightCopy: String {
        switch dotY {
        case 3.5...: return "You have room to give. Tonight is a good night to show up fully."
        case 2.5...: return "You're here. That's enough. Presence without performance."
        case 1.5...: return "Something's rubbing. That's not wrong — it's information."
        default:     return "Low capacity is valid data. Protect your energy first."
        }
    }

    // MARK: - Camera Geometry Helpers
    // Must replicate PulseGraph's internal constants and canvasWidth formula exactly.
    // PulseGraph constants: padLeft=10, padRight=28, padTop=16, padBot=24, minSpacing=44
    // If any of those change in PulseGraph they must change here too.

    private let padLeft:    CGFloat = 10
    private let padRight:   CGFloat = 28
    private let padTop:     CGFloat = 16
    private let padBot:     CGFloat = 24
    private let minSpacing: CGFloat = 44

    // Replicates PulseGraph.canvasWidth exactly.
    // liveScore is always non-nil during check-in so slotCount = entries.count + 1.
    // Root cause of camera targeting empty space: usableWidth was derived from
    // graphWidth (~390px) instead of canvasWidth (~654px for 14 entries).
    // Every xForIndex call was returning a coordinate ~240px short of the actual dot.
    private var canvasWidth: CGFloat {
        let slotCount = entries.count + 1   // +1 for live dot — always present during check-in
        let computed  = padLeft + CGFloat(max(1, slotCount - 1)) * minSpacing + padRight
        return max(graphWidth, computed)
    }

    // usableWidth derives from canvasWidth, not graphWidth.
    private var usableWidth:  CGFloat { canvasWidth  - padLeft - padRight }
    private var usableHeight: CGFloat { graphHeight  - padTop  - padBot   }

    private func xForIndex(_ index: Int) -> CGFloat {
        let totalSlots = entries.count + 1
        guard totalSlots > 1 else {
            return padLeft + usableWidth / 2
        }
        return padLeft + (CGFloat(index) / CGFloat(totalSlots - 1)) * usableWidth
    }

    private func yForScore(_ score: Double) -> CGFloat {
        padTop + CGFloat((4.0 - score) / 3.0) * usableHeight
    }

    // ADD THIS: The distance the ScrollView natively shifts the content left
    private var initialScrollOffset: CGFloat {
        max(0, canvasWidth - graphWidth)
    }

    // Camera step 1 — zoom to last historical entry.
    private var step1Values: (scale: CGFloat, tx: CGFloat, ty: CGFloat) {
        let lastX = xForIndex(entries.count - 1)
        let lastY = yForScore(entries.last?.capacityScore ?? 2.5)
        let s: CGFloat = 9.0
        
        // Calculate the actual visual X coordinate on screen
        let visibleX = lastX - initialScrollOffset
        return (
            scale: s,
            tx:    (graphWidth  / 2) - visibleX * s,
            ty:    (graphHeight / 2) - lastY * s
        )
    }

    // Camera step 2 — pan to midpoint (Unused if using the single linear block, but updated for safety)
    private var step2Values: (tx: CGFloat, ty: CGFloat) {
        let lastX  = xForIndex(entries.count - 1)
        let lastY  = yForScore(entries.last?.capacityScore ?? 2.5)
        let todayX = xForIndex(entries.count)
        let todayY = yForScore(dotY)
        let midX   = (lastX + todayX) / 2
        let midY   = (lastY + todayY) / 2
        let s: CGFloat = 9.0
        let visibleMidX = midX - initialScrollOffset
        
        return (
            tx: (graphWidth  / 2) - visibleMidX * s,
            ty: (graphHeight / 2) - midY * s
        )
    }

    // Camera step 3 — settle on today dot
    private var step3Values: (scale: CGFloat, tx: CGFloat, ty: CGFloat) {
        let todayX = xForIndex(entries.count)
        let todayY = yForScore(dotY)
        let s: CGFloat = 11.0   // change this number to change zoom level
        
        let visibleX = todayX - initialScrollOffset
        return (
            scale: s,
            tx:    (graphWidth  / 2) - visibleX * s,
            ty:    (graphHeight / 2) - todayY * s
        )
    }

    // MARK: - Body
    // Renders only the active phase content.
    // No background. No glow field. Those live in CheckInShell.
    // Frame is the bottom 40% panel — CheckInShell owns the layout.

    var body: some View {
        ZStack {
            switch phase {
            case .idle:
                idleView
                    .transition(.opacity.combined(with: .offset(y: 20)))

            case .questions:
                questionView
                    .transition(.opacity.combined(with: .offset(y: 20)))

            case .resolving:
                resolvingView
                    .transition(.opacity)

            case .done:
                doneView
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
        .animation(.easeOut(duration: 0.4), value: phase)
        .onAppear { startIdle() }
        .onDisappear { resolutionAttempt += 1 }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 20) {
            // Divider between graph and panel — subtle, not structural
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            Text("Daily Check-In")
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )

            Text("5 questions. Honest answers.\nNo judgment.")
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                )

            Spacer()

            HoloCTAButton(title: "Begin", isEnabled: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .questions
                }
                liveScore = 2.5
            }
            .padding(.horizontal, 32)

            Button("Not now") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                resetCamera()
                onDismiss()
            }
            .font(AppFonts.caption)
            .foregroundStyle(
                isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
            )
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            // Progress bar
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Question text
            Text(currentQuestion.text)
                .font(AppFonts.sectionHeading)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )
                .padding(.horizontal, 32)
                .id(qi)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal:   .opacity.combined(with: .offset(y: -12))
                ))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            // Pills
            pillGrid
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<questions.count, id: \.self) { i in
                Capsule()
                    .fill(
                        i < qi
                            ? AnyShapeStyle(LinearGradient(
                                colors: isLight
                                    ? [AppColors.purple, AppColors.magenta]
                                    : [AppColors.cyan,   AppColors.purple],
                                startPoint: .leading,
                                endPoint:   .trailing
                              ))
                            : i == qi
                                ? AnyShapeStyle(currentTier.color.opacity(0.6))
                                : AnyShapeStyle(
                                    (isLight ? Color.black : Color.white).opacity(0.08)
                                  )
                    )
                    .frame(height: 3)
                    .animation(.easeOut(duration: 0.3), value: qi)
            }
        }
    }

    // MARK: - Pill Grid

    private var pillGrid: some View {
        let pills = currentQuestion.pills

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 10),
                count: pills.count <= 3 ? pills.count : 2
            ),
            spacing: 10
        ) {
            ForEach(pills) { pill in
                SelectablePill(
                    label:      pill.label,
                    isSelected: chosen == pill.label,
                    intensity:  .warm
                ) {
                    handlePillTap(pill)
                }
            }
        }
        .id(qi)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 16)),
            removal:   .opacity.combined(with: .offset(y: -8))
        ))
    }

    // MARK: - Resolving View
    // Minimal UI — graph is the experience during resolution.
    // Completion message fades in after the line has drawn.

    private var resolvingView: some View {
        VStack {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            if msgVisible {
                Text(completionMessage)
                    .font(AppFonts.sectionHeading)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isLight
                                ? [AppColors.purple, AppColors.magenta]
                                : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta],
                            startPoint: .leading,
                            endPoint:   .trailing
                        )
                    )
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }

            Spacer()
        }
    }

    // MARK: - Done View

    private var doneView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            VStack(spacing: 6) {
                Text(PulseTier.tier(for: dotY).label)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isLight
                                ? [AppColors.purple, AppColors.magenta]
                                : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta],
                            startPoint: .leading,
                            endPoint:   .trailing
                        )
                    )

                Text(PulseTier.tier(for: dotY).sublabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                    )
            }
            .padding(.bottom, 16)

            Text(insightCopy)
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

            HoloCTAButton(title: "Done", isEnabled: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                submitEntry()
            }
            .padding(.horizontal, 32)

            Button("Start over") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                resetAll()
            }
            .font(AppFonts.caption)
            .foregroundStyle(
                isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Pill Tap Handler

    private func handlePillTap(_ pill: CheckInPill) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chosen = pill.label

        if let glow = pill.glowOverride {
            glowColor = glow
        } else {
            dotY = max(1.0, min(4.0, dotY + pill.dy))
        }

        switch qi {
        case 0: answerNS    = pill.label
        case 1: answerFocus = pill.label
        case 2: answerFeel  = pill.label
        case 4: speed       = pill.label
        default: break
        }

        // Move the live dot on the graph above — immediately visible to user
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            liveScore = dotY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if qi < questions.count - 1 {
                withAnimation(.easeOut(duration: 0.3)) {
                    qi     += 1
                    chosen  = nil
                }
            } else {
                // Q5 complete — fire cinematic resolution on the graph above
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .resolving
                }
                triggerResolution()
            }
        }
    }

    // MARK: - Cinematic Resolution
    // Camera moves animate the PulseGraph in CheckInShell's top 60%.
    // The user watches the line draw in real time on the graph above.
  
    private func triggerResolution() {
        guard !reduceMotion else {
            drawProgress = 1.0
            msgVisible   = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { phase = .done }
                resetCamera()
            }
            return
        }

        resolutionAttempt += 1
        let currentAttempt = resolutionAttempt

        Task { @MainActor in

            // t=0.00s — Slow zoom to last historical entry
            let s1 = step1Values
            withAnimation(.easeInOut(duration: 1.8)) {
                camScale = s1.scale
                camTx    = s1.tx
                camTy    = s1.ty
            }

            try? await Task.sleep(for: .seconds(2.0))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=2.0s — Camera tracks pen tip, line draws
            let s3 = step3Values
            withAnimation(.linear(duration: 6.0)) {
                camTx        = s3.tx
                camTy        = s3.ty
                camScale     = s3.scale
                drawProgress = 1.0
            }

            try? await Task.sleep(for: .seconds(6.2))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=8.2s — Message fades in
            withAnimation(.easeOut(duration: 0.7)) {
                msgVisible = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            try? await Task.sleep(for: .seconds(1.8))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=10.0s — Pull back to full graph
            withAnimation(.easeInOut(duration: 1.8)) {
                camScale = 1.0
                camTx    = 0.0
                camTy    = 0.0
            }

            try? await Task.sleep(for: .seconds(1.6))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=11.6s — Done card
            withAnimation(.easeOut(duration: 0.5)) {
                phase = .done
            }
        }
    }

    // MARK: - Submit Entry

    private func submitEntry() {
        let entry = PulseEntry(
            date:          Date(),
            capacityScore: max(1.0, min(4.0, dotY)),
            glowColor:     glowColor,
            speed:         speed ?? "Light Connection",
            nervousSystem: answerNS.isEmpty    ? "Stable"   : answerNS,
            focus:         answerFocus.isEmpty  ? "Balanced" : answerFocus,
            feeling:       answerFeel.isEmpty   ? "Content"  : answerFeel
        )
        resetCamera()
        onComplete(entry)
    }

    // MARK: - Helpers

    private func startIdle() {
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            phase = .idle
        }
    }

    private func resetCamera() {
        withAnimation(.easeOut(duration: 0.5)) {
            camScale = 1.0
            camTx    = 0.0
            camTy    = 0.0
        }
    }

    private func resetAll() {
        resolutionAttempt += 1
        qi           = 0
        chosen       = nil
        speed        = nil
        answerNS     = ""
        answerFocus  = ""
        answerFeel   = ""
        msgVisible   = false
        drawProgress = 0.0
        liveScore    = 2.5
        resetCamera()
        withAnimation(.easeOut(duration: 0.3)) {
            phase = .questions
        }
    }
}

// MARK: - Previews
// Previews render the full shell so the graph is visible above the panel

#Preview("Idle — dark") {
    CheckInShell(
        entries:      PulseEntry.previews,
        camScale:     .constant(1.0),
        camTx:        .constant(0.0),
        camTy:        .constant(0.0),
        liveScore:    .constant(nil),
        drawProgress: .constant(0.0),
        onComplete:   { _ in },
        onDismiss:    {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Idle — light") {
    CheckInShell(
        entries:      PulseEntry.previews,
        camScale:     .constant(1.0),
        camTx:        .constant(0.0),
        camTy:        .constant(0.0),
        liveScore:    .constant(nil),
        drawProgress: .constant(0.0),
        onComplete:   { _ in },
        onDismiss:    {}
    )
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardCarousel.swift` {#file-open-lightly-design-components-cards-cardcarousel-swift}

```swift
// Features/Home/Components/CardCarousel.swift
// Open Lightly

import SwiftUI

// MARK: - Supporting Types

enum CarouselPhase: Equatable {
    case floating
    case spread
    case gathering
    case lifted
    case carousel
}

enum CarouselDirection {
    case next
    case prev
}

enum CardAction {
    case startSession
    case navigateToPlay
    case share
    case redo(Prompt)
}

// MARK: - Layout Constants

private let cardW: CGFloat = 300
private let cardH: CGFloat = 190

// 6-Card Converging Fan
private let spreadOffsets:   [CGFloat] = [-180,  180,  -120,  120,  -60,  60  ]
private let spreadRotations: [Double]  = [ -18,   18,   -12,   12,   -6,   6  ]
private let spreadYOffsets:  [CGFloat] = [  24,   24,    16,   16,    8,   8  ]
private let spreadScales:    [CGFloat] = [0.78, 0.78,  0.84, 0.84, 0.90, 0.90 ]
private let spreadOpacities: [Double]  = [0.25, 0.25,  0.50, 0.50, 0.75, 0.75 ]

// 6-Card Gathered State
private let gatheredYOffsets:  [CGFloat] = [15,   12,   9,    6,    4,    2   ]
private let gatheredOpacities: [Double]  = [0.30, 0.45, 0.60, 0.75, 0.85, 0.95]
private let gatheredScales:    [CGFloat] = [0.91, 0.93, 0.95, 0.96, 0.97, 0.98]

// MARK: - CardCarousel

struct CardCarousel: View {

    var cards: [Prompt]
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil
    var onNavigateToPlay: (() -> Void)? = nil
    var onPhaseChange: ((CarouselPhase) -> Void)? = nil

    @State private var phase:              CarouselPhase = .floating
    @State private var activeIndex:        Int     = 0
    @State private var dragOffset:         CGFloat = 0
    @State private var verticalDragOffset: CGFloat = 0
    @State private var isDragging:         Bool    = false
    @State private var dragVelocity:       CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var specularPhase:      CGFloat = 0
    @State private var specularActive:     Bool    = false
    @State private var borderRotation:     Double  = 0.0
    @State private var floatOffset:        CGFloat = 0
    @State private var bloomOpacity:       Double  = 0.5

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    private var activeCard: Prompt? {
        guard cards.indices.contains(activeIndex) else { return nil }
        return cards[activeIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            cardStack
        }
        .onChange(of: phase) { _, newPhase in
            onPhaseChange?(newPhase)
        }
        .onAppear {
            onPhaseChange?(.floating)
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                borderRotation = 360.0
            }
            DispatchQueue.main.async {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                        floatOffset = -6
                    }
                }
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                bloomOpacity = 0.75
            }
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack(alignment: .top) {
            auroraBloom
            backingCards
            carouselCards
        }
        .frame(maxWidth: .infinity)
        // Tall enough to contain lifted/carousel state without clipping.
        // Cards lift -40pt and have 8pt top padding — 300pt gives clearance
        // above and below without constraining the compositor.
        .frame(height: cardH + 120)
        // No .clipped() here — cards must be able to overflow this frame
        // upward during lifted/carousel phases
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: phase)
        .background {
            Rectangle()
                .fill(Color.black.opacity(isLight ? 0.35 : 0.75))
                .frame(width: 3000, height: 3000)
                .opacity((phase == .floating || phase == .spread) ? 0 : 1)
                .allowsHitTesting(phase != .floating && phase != .spread)
                .onTapGesture { handleDismissQuickview() }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 80 && phase == .carousel {
                        handleDismissQuickview()
                    }
                }
        )
        .overlay { glassTrackpad }
        .scaleEffect(phase == .spread ? 0.75 : 1.0)
        .offset(y: phase == .spread ? 0 : (phase == .floating ? 0 : -20))
        .padding(.bottom, phase == .carousel ? -40 : phase == .spread ? -60 : phase == .floating ? -100 : -20)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.3)
                : .spring(response: 0.95, dampingFraction: 0.85),
            value: phase
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardStackA11yLabel)
        .accessibilityHint(cardStackA11yHint)
        .accessibilityAdjustableAction { direction in
            guard phase == .carousel else { return }
            switch direction {
            case .increment: navigateCarousel(direction: .next)
            case .decrement: navigateCarousel(direction: .prev)
            @unknown default: break
            }
        }
    }

    private var cardStackA11yLabel: String {
        phase == .carousel
            ? "Card \(activeIndex + 1) of \(cards.count). \(activeCard?.text ?? "")"
            : "Card deck. Tap to begin."
    }

    private var cardStackA11yHint: String {
        phase == .carousel
            ? "Swipe left or right to navigate cards"
            : "Double tap to open"
    }

    // MARK: - Glass Trackpad

    private var glassTrackpad: some View {
        Color.white.opacity(0.001)
            .onTapGesture {
                if phase == .floating {
                    handleFloatingTap()
                } else if phase == .lifted {
                    handleDismissQuickview()
                }
            }
            .highPriorityGesture(
                (phase == .carousel || phase == .lifted) && phase != .floating
                    ? DragGesture(minimumDistance: 5)
                        .onChanged { handleDragChanged($0) }
                        .onEnded   { handleDragEnded($0) }
                    : nil
            )
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        if phase == .lifted {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                phase = .carousel
            }
        }
        if dragOffset == 0 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        isDragging = true
        dragVelocity = value.translation.width - previousDragOffset

        let currentProgress  = abs(value.translation.width / (cardW + 16))
        let previousProgress = abs(previousDragOffset / (cardW + 16))
        if (currentProgress >= 0.5 && previousProgress < 0.5) ||
           (currentProgress < 0.5  && previousProgress >= 0.5) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        }
        previousDragOffset = value.translation.width
        dragOffset = value.translation.width

        // Rubber-band downward drag — heavy resistance, not a valid
        // swipe direction. sqrt damping gives a physical feel.
        let verticalTranslation = value.translation.height
        if verticalTranslation > 0 {
            verticalDragOffset = sqrt(verticalTranslation) * 2.5
        } else {
            verticalDragOffset = 0
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        // If primarily a downward drag, dismiss — reset rubber-band
        if value.translation.height > 80 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                verticalDragOffset = 0
            }
            handleDismissQuickview()
            return
        }

        // Reset vertical rubber-band on any release
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            verticalDragOffset = 0
        }

        let predicted  = value.predictedEndTranslation.width
        let threshold: CGFloat = 50
        var newIndex   = activeIndex

        if dragOffset < -threshold || predicted < -200 {
            newIndex = (activeIndex + 1) % cards.count
        } else if dragOffset > threshold || predicted > 200 {
            newIndex = (activeIndex - 1 + cards.count) % cards.count
        }

        if newIndex != activeIndex {
            let shift: CGFloat = newIndex > activeIndex ? (cardW + 16) : -(cardW + 16)
            dragOffset += shift
            activeIndex = newIndex
            UISelectionFeedbackGenerator().selectionChanged()
            if !reduceMotion { triggerSpecularGlint() }
        }

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                isDragging = false
                dragOffset = 0
            }
        }
        dragVelocity       = 0
        previousDragOffset = 0
    }

    // MARK: - Aurora Bloom

    @ViewBuilder
    private var auroraBloom: some View {
        if let card = activeCard {
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        card.difficulty.glowColor
                            .opacity(phase == .spread ? 0.14 : 0.28),
                        card.difficulty.glowColor.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                ))
                .frame(width: 380, height: 260)
                .blur(radius: 60)
                .scaleEffect(isDragging ? 1.15 : 1.0)
                .opacity(phase == .floating ? bloomOpacity : (isDragging ? 1.0 : 0.6))
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.55), value: activeIndex)

            if phase == .carousel && !reduceMotion {
                let incoming = dragOffset < 0
                    ? (activeIndex + 1) % cards.count
                    : (activeIndex - 1 + cards.count) % cards.count
                let bleed = min(abs(dragOffset) / 320, 1.0)
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            cards[incoming].difficulty.glowColor
                                .opacity(bleed * 0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    ))
                    .frame(width: 380, height: 260)
                    .offset(x: dragOffset < 0 ? 50 : -50)
                    .blur(radius: 65)
                    .allowsHitTesting(false)
                    .animation(
                        isDragging ? .none : .easeOut(duration: 0.4),
                        value: dragOffset
                    )
            }
        }
    }

    // MARK: - Backing Cards

    private var backingCards: some View {
        ForEach(0..<6, id: \.self) { i in
            let isSpread = phase == .spread
            CardBackView(
                offsetX:  isSpread ? spreadOffsets[i]   : 0,
                offsetY:  isSpread ? spreadYOffsets[i]  : gatheredYOffsets[i],
                rotation: isSpread ? spreadRotations[i] : 0,
                scale:    isSpread ? spreadScales[i]    : gatheredScales[i],
                opacity:  (phase == .floating || phase == .carousel) ? 0
                    : isSpread ? spreadOpacities[i]
                    : gatheredOpacities[i],
                isLight: isLight
            )
            .zIndex(Double(i))
            .offset(y: (phase == .lifted || phase == .carousel) ? -15 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.3)
                    : .spring(response: 0.85, dampingFraction: 0.80),
                value: phase
            )
        }
    }

    // MARK: - Carousel Cards

    @ViewBuilder
    private var carouselCards: some View {
        if cards.isEmpty {
            EmptyView()
        } else {
            let prevIdx = (activeIndex - 1 + cards.count) % cards.count
            let nextIdx = (activeIndex + 1) % cards.count
            let visibleSlots: [(index: Int, relative: Int)] = [
                (prevIdx, -1),
                (activeIndex, 0),
                (nextIdx, 1)
            ]

            ForEach(visibleSlots, id: \.index) { entry in
                let i             = entry.index
                let relativeIndex = entry.relative
                let baseOffset    = CGFloat(relativeIndex) * (cardW + 16)
                let rawX          = phase == .carousel ? (baseOffset + dragOffset) : 0
                let progress      = rawX / (cardW + 16)
                let clampedProgress = min(max(progress, -1.0), 1.0)
                let visualX       = clampedProgress * (cardW * 0.78)

                ZStack {
                    PromptCard(prompt: cards[i], showDifficultyDots: false)
                        .frame(width: cardW, height: cardH)

                    LinearGradient(
                        colors: [.clear, .white.opacity(isLight ? 0.4 : 0.12), .clear],
                        startPoint: .init(x: 0.2 - (progress * 1.5), y: 0),
                        endPoint:   .init(x: 0.8 - (progress * 1.5), y: 1)
                    )
                    .blendMode(.screen)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
                    .opacity(phase == .carousel ? 1 : 0)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .clear,                                          location: 0),
                                .init(color: .white.opacity(isLight ? 0.14 : 0.08),          location: 0.35),
                                .init(color: .white.opacity(isLight ? 0.28 : 0.20),          location: 0.50),
                                .init(color: .white.opacity(isLight ? 0.14 : 0.08),          location: 0.65),
                                .init(color: .clear,                                          location: 1),
                            ],
                            startPoint: .init(x: specularPhase * 1.4 - 0.4, y: 0),
                            endPoint:   .init(x: specularPhase * 1.4 - 0.1, y: 1)
                        ))
                        .blendMode(.screen)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .opacity((i == activeIndex && specularActive && phase != .carousel) ? 1 : 0)
                }
                .frame(width: cardW, height: cardH)
                .padding(.top, 8)
                .padding(.bottom, -8)
                .offset(
                    x: phase == .carousel ? visualX : 0,
                    y: ((phase == .lifted || phase == .carousel) ? -40
                        : (phase == .floating && i == activeIndex) ? floatOffset
                        : 0)
                    // Rubber-band vertical offset applied on top of phase offset.
                    // Only active card responds — others stay put.
                    + (i == activeIndex ? verticalDragOffset : 0)
                )
                .scaleEffect(
                    phase == .carousel
                        ? max(0.75, 1.0 - abs(clampedProgress) * 0.25)
                        : (phase == .lifted ? 1.04 : 1.0)
                )
                .blur(radius: phase == .carousel ? abs(clampedProgress) * 2.5 : 0)
                .rotation3DEffect(
                    phase == .lifted && !reduceMotion
                        ? .degrees(-4)
                        : (phase == .carousel && !reduceMotion)
                            ? .degrees(Double(clampedProgress * -25.0))
                            : .degrees(0.001),
                    axis: (x: 0.3, y: 1, z: 0),
                    perspective: 0.25
                )
                // Active card always on top. Dragging card gets maximum
                // promotion so it renders above every other element on screen.
                .zIndex(i == activeIndex ? 200.0 : 100.0 - Double(abs(progress) * 10))
                .allowsHitTesting(phase == .carousel && i == activeIndex)
                .onTapGesture {
                    if phase == .carousel && i == activeIndex {
                        onCardAction?(cards[i], .startSession)
                    }
                }
                .shadow(
                    color: (phase == .lifted || phase == .carousel)
                        ? cards[i].difficulty.glowColor.opacity(
                            (i == activeIndex ? 0.35 : 0.0) + (abs(clampedProgress) * 0.45)
                          )
                        : cards[i].difficulty.glowColor.opacity(0.001),
                    radius: phase == .carousel ? 36 + (abs(clampedProgress) * 45) : 36,
                    y: 18
                )
                .opacity(
                    phase == .carousel
                        ? (i == activeIndex ? 1.0 : 0.75)
                        : (i == activeIndex ? 1.0 : 0.0)
                )
                .animation(.spring(response: 0.55, dampingFraction: 0.80), value: phase)
            }
        }
    }

    // MARK: - Specular Glint

    func triggerSpecularGlint() {
        guard !reduceMotion else { return }
        specularPhase  = 0
        specularActive = true
        withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.75)) {
            specularPhase = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            specularActive = false
            specularPhase  = 0
        }
    }

    // MARK: - Phase Transitions

    func handleFloatingTap() {
        guard phase == .floating else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.2)) { floatOffset = 0 }
        let fanAnim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.6, dampingFraction: 0.7)
        withAnimation(fanAnim) { phase = .spread }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
                phase = .lifted
            }
            if !reduceMotion { triggerSpecularGlint() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    phase = .carousel
                }
            }
        }
    }

    func handleBrowseDeck() {
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(anim) { phase = .carousel }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleDismissQuickview() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        ) {
            phase = .spread
            verticalDragOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(response: 0.6, dampingFraction: 0.8)
            ) {
                phase       = .floating
                activeIndex = 0
                dragOffset  = 0
                floatOffset = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                floatOffset = -6
            }
        }
    }

    func handleBackToDeck() {
        let anim: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(anim) {
            phase       = .lifted
            activeIndex = 0
            dragOffset  = 0
        }
    }

    // MARK: - Carousel Navigation

    func navigateCarousel(direction: CarouselDirection) {
        let next = direction == .next
            ? (activeIndex + 1) % cards.count
            : (activeIndex - 1 + cards.count) % cards.count
        guard next != activeIndex else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                dragOffset = 0
            }
            return
        }
        let shift: CGFloat = next > activeIndex ? (cardW + 16) : -(cardW + 16)
        dragOffset += shift
        activeIndex = next
        UISelectionFeedbackGenerator().selectionChanged()
        if !reduceMotion { triggerSpecularGlint() }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            dragOffset = 0
        }
    }
}

// MARK: - Previews

#Preview("Spread — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.dark)
}

#Preview("Spread — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/CardBackView.swift` {#file-open-lightly-design-components-cards-cardbackview-swift}

```swift
//
//  CardBackView.swift
//  Open Lightly
//
//  Two inits:
//  1. Full interactive init — used by onboarding ConversationCard (unchanged)
//  2. Deck mode init — decorative only, used by HomeCardCarousel
//

import SwiftUI

struct CardBackView: View {
    let cardSize:            CGSize
    let cornerRadius:        CGFloat
    let selectedPill:        CardRevealPill?
    let selectedScale:       CGFloat
    let selectedBorderWidth: CGFloat
    let unselectedVisible:   Bool
    let revealed:            Bool
    let isLight:             Bool
    let onSelect:            (CardRevealPill) -> Void
    let questionVisible:     Bool
    let pillsVisible:        Bool

    // ── Deck mode flag ───────────────────────────────────────────────────
    // Set to true by the deck-mode init. Suppresses all interactive
    // content and renders only the card shell + watermark.
    private let deckMode: Bool

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init 1: Full interactive (onboarding ConversationCard)
    // Identical to the original — zero call-site changes required.
    // ─────────────────────────────────────────────────────────────────────
    init(
        cardSize:            CGSize,
        cornerRadius:        CGFloat,
        selectedPill:        CardRevealPill?,
        selectedScale:       CGFloat,
        selectedBorderWidth: CGFloat,
        unselectedVisible:   Bool,
        revealed:            Bool,
        isLight:             Bool,
        onSelect:            @escaping (CardRevealPill) -> Void,
        questionVisible:     Bool,
        pillsVisible:        Bool
    ) {
        self.cardSize            = cardSize
        self.cornerRadius        = cornerRadius
        self.selectedPill        = selectedPill
        self.selectedScale       = selectedScale
        self.selectedBorderWidth = selectedBorderWidth
        self.unselectedVisible   = unselectedVisible
        self.revealed            = revealed
        self.isLight             = isLight
        self.onSelect            = onSelect
        self.questionVisible     = questionVisible
        self.pillsVisible        = pillsVisible
        self.deckMode            = false
        // ── Deck positioning — neutral in interactive mode ──────────────
        self._deckOffsetX        = 0
        self._deckOffsetY        = 0
        self._deckRotation       = 0
        self._deckScale          = 1.0
        self._deckOpacity        = 1.0
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init 2: Deck mode (HomeCardCarousel decorative backing)
    //
    // Usage:
    //   CardBackView(offsetX: -60, offsetY: 8, rotation: -12,
    //                scale: 0.95, opacity: 0.45, isLight: isLight)
    //
    // Renders only: card shell fill + border + ∞ watermark.
    // All pill / reveal / heading content is suppressed.
    // ─────────────────────────────────────────────────────────────────────
    init(
        offsetX:  CGFloat = 0,
        offsetY:  CGFloat = 0,
        rotation: Double  = 0,
        scale:    CGFloat = 1.0,
        opacity:  Double  = 1.0,
        isLight:  Bool    = false
    ) {
        // Fixed deck geometry
        self.cardSize            = CGSize(width: 300, height: 190)
        self.cornerRadius        = 20
        // Suppress all interactive state
        self.selectedPill        = nil
        self.selectedScale       = 1.0
        self.selectedBorderWidth = 1.0
        self.unselectedVisible   = false
        self.revealed            = false
        self.isLight             = isLight
        self.onSelect            = { _ in }
        self.questionVisible     = false
        self.pillsVisible        = false
        self.deckMode            = true
        // Store positioning so the body can apply them
        self._deckOffsetX        = offsetX
        self._deckOffsetY        = offsetY
        self._deckRotation       = rotation
        self._deckScale          = scale
        self._deckOpacity        = opacity
    }

    // Deck positioning — only populated by the deck-mode init.
    // Prefixed with _ to signal they are internal layout values.
    private let _deckOffsetX:  CGFloat
    private let _deckOffsetY:  CGFloat
    private let _deckRotation: Double
    private let _deckScale:    CGFloat
    private let _deckOpacity:  Double

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Base fill ─────────────────────────────────────────────────
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cardFill)

            // ── Ambient wash ──────────────────────────────────────────────
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.magenta.opacity(0.06), Color.clear]
                            : [AppColors.purple.opacity(0.15),  Color.clear],
                        center:      UnitPoint(x: 0.7, y: 0.8),
                        startRadius: 0,
                        endRadius:   180
                    )
                )

            // ── Border ────────────────────────────────────────────────────
            if isLight {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AppColors.warmAuroraBorder,
                        lineWidth: selectedBorderWidth
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AppColors.spectrumBorder,
                        lineWidth: selectedBorderWidth
                    )
            }

            // ── ∞ Watermark (always visible) ──────────────────────────────
            // Shown in both deck mode and interactive mode.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("∞")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(
                            isLight
                                ? AppColors.purple.opacity(0.08)
                                : AppColors.purple.opacity(0.10)
                        )
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }

            // ── Interactive content — suppressed in deck mode ─────────────
            if !deckMode {
                VStack(spacing: 0) {

                    // Heading
                    VStack(spacing: 6) {
                        Text("Something came up.")
                            .font(AppFonts.body(20, weight: .semibold))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightCardTitle
                                    : AppColors.textPrimary
                            )
                            .multilineTextAlignment(.center)

                        Text("What's it closest to?")
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightCardTitle.opacity(0.50)
                                    : AppColors.textSecondary
                            )
                    }
                    .padding(.top, 24)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 6)
                    .animation(.easeOut(duration: 0.3), value: revealed)

                    Spacer()

                    // Pills
                    VStack(spacing: 8) {
                        ForEach(
                            Array(CardRevealPill.allCases.enumerated()),
                            id: \.element
                        ) { index, pill in
                            Button {
                                guard selectedPill == nil else { return }
                                UIImpactFeedbackGenerator(style: .light)
                                    .impactOccurred()
                                onSelect(pill)
                            } label: {
                                Text(pill.rawValue)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(
                                        selectedPill == pill
                                            ? (isLight
                                                ? AppColors.lightCardTitle
                                                : AppColors.textPrimary)
                                            : (isLight
                                                ? AppColors.lightBodyWineDark
                                                : Color.white.opacity(0.75))
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        Capsule()
                                            .fill(
                                                selectedPill == pill
                                                    ? (isLight
                                                        ? AnyShapeStyle(AppColors.lightFrostPillSel)
                                                        : AnyShapeStyle(Color.white.opacity(0.10)))
                                                    : (isLight
                                                        ? AnyShapeStyle(AppColors.lightFrostPill)
                                                        : AnyShapeStyle(AppColors.cardBg))
                                            )
                                    )
                                    .overlay(
                                        Group {
                                            if selectedPill == pill {
                                                if isLight {
                                                    Capsule()
                                                        .strokeBorder(
                                                            AppColors.warmAuroraBorder,
                                                            lineWidth: 2.0
                                                        )
                                                } else {
                                                    Capsule()
                                                        .strokeBorder(
                                                            AppColors.spectrumBorder,
                                                            lineWidth: 2.0
                                                        )
                                                }
                                            } else {
                                                Capsule()
                                                    .strokeBorder(
                                                        isLight
                                                            ? AppColors.lightBorder
                                                            : AppColors.border,
                                                        lineWidth: 1.5
                                                    )
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(
                                selectedPill == pill ? selectedScale : 1.0
                            )
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.7),
                                value: selectedScale
                            )
                            .opacity({
                                if selectedPill != nil && selectedPill != pill {
                                    return unselectedVisible ? 1 : 0
                                }
                                return revealed ? 1 : 0
                            }())
                            .offset(y: revealed ? 0 : 10)
                            .animation(
                                .easeOut(duration: 0.3)
                                    .delay(Double(index) * 0.07 + 0.12),
                                value: revealed
                            )
                            .animation(
                                .easeIn(duration: 0.35),
                                value: unselectedVisible
                            )
                            .disabled(
                                selectedPill != nil && selectedPill != pill
                            )
                            .background(
                                Capsule()
                                    .fill(
                                        isLight
                                            ? AppColors.lightFrostPill
                                            : AppColors.cardBg
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Text("✦")
                        .font(AppFonts.overline)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextTertiary.opacity(0.5)
                                : AppColors.textTertiary.opacity(0.5)
                        )
                        .opacity(revealed ? 0.6 : 0)
                        .animation(
                            .easeOut(duration: 0.4).delay(0.5),
                            value: revealed
                        )
                        .padding(.bottom, 24)
                }
            } // end !deckMode
        }
        .frame(width: cardSize.width, height: cardSize.height)
        // ── Deck-mode positioning ─────────────────────────────────────────
        // In interactive mode these are all neutral (0 / 1.0 / 1.0)
        // so they have zero visual effect on existing call sites.
        .offset(x: _deckOffsetX, y: _deckOffsetY)
        .rotationEffect(.degrees(_deckRotation))
        .scaleEffect(_deckScale)
        .opacity(deckMode ? _deckOpacity : 1.0)
        // Shadows — only on interactive mode; deck mode uses caller-side shadow
        .if(!deckMode) { $0.cardShadows(isLight: isLight) }
    }

    // MARK: - Card fill

    private var cardFill: some ShapeStyle {
        isLight
            ? AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.99, blue: 1.00),
                    Color(red: 0.98, green: 0.97, blue: 0.99),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.043, blue: 0.122),
                    Color(red: 0.031, green: 0.024, blue: 0.094),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
    }
}

// MARK: - Previews

#Preview("Interactive mode — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CardBackView(
            cardSize:            CGSize(width: 340, height: 420),
            cornerRadius:        20,
            selectedPill:        nil,
            selectedScale:       1.0,
            selectedBorderWidth: 1.5,
            unselectedVisible:   true,
            revealed:            true,
            isLight:             false,
            onSelect:            { _ in },
            questionVisible:     true,
            pillsVisible:        true
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — spread fan — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ZStack {
            CardBackView(offsetX: -60, offsetY: 8,
                         rotation: -12, scale: 0.95, opacity: 0.70)
            CardBackView(offsetX: -30, offsetY: 4,
                         rotation: -6,  scale: 0.97, opacity: 0.80)
            CardBackView(offsetX:   0, offsetY: 0,
                         rotation:  0,  scale: 0.98, opacity: 1.00)
            CardBackView(offsetX:  30, offsetY: 4,
                         rotation:  6,  scale: 0.97, opacity: 0.80)
            CardBackView(offsetX:  60, offsetY: 8,
                         rotation:  12, scale: 0.95, opacity: 0.70)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — gathered stack — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ZStack {
            CardBackView(offsetY: 12, scale: 0.930,
                         opacity: 0.42, isLight: true)
            CardBackView(offsetY:  8, scale: 0.960,
                         opacity: 0.56, isLight: true)
            CardBackView(offsetY:  5, scale: 0.975,
                         opacity: 0.68, isLight: true)
            CardBackView(offsetY:  2, scale: 0.985,
                         opacity: 0.80, isLight: true)
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift` {#file-open-lightly-design-components-cards-atmosphericghostdeck-swift}

```swift
//
//  AtmosphericGhostDeck.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct AtmosphericGhostDeck: View {

    // Static offsets — the two ghost cards behind the main card
    private let ghosts: [(offset: CGSize, rotation: Double, opacity: Double)] = [
        (CGSize(width: 8,  height: -10), -3.5, 0.75),
        (CGSize(width: 16, height: -20), -7.0, 0.55),
    ]

    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false

    let cardSize: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Ghost 1 — furthest back, slower drift
            ghostCard
                .offset(ghosts[0].offset)
                .offset(
                    x: drifting ? 5 : 0,
                    y: drifting ? -6 : 0
                )
                .rotationEffect(.degrees(ghosts[0].rotation + (drifting ? 1.5 : 0)))
                .opacity(colorScheme == .light ? 0.90 : ghosts[0].opacity)
                .animation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )

            // Ghost 2 — closer, slightly faster drift
            ghostCard
                .offset(ghosts[1].offset)
                .offset(
                    x: drifting ? -4 : 0,
                    y: drifting ? -4 : 0
                )
                .rotationEffect(.degrees(ghosts[1].rotation + (drifting ? -1.5 : 0)))
                .opacity(colorScheme == .light ? 0.75 : ghosts[1].opacity)
                .animation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
        }
        .onAppear {
            drifting = true
        }
    }

    private var ghostCard: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            Color(hex: "E8DFD0"),  // warm off-white, clear tan presence
                            Color(hex: "DEDAD0"),  // deeper, closer to the cream background
                          ]
                        : [
                            Color(red: 0.10, green: 0.09, blue: 0.23),  // deep indigo
                            Color(red: 0.07, green: 0.06, blue: 0.18),  // darker indigo
                          ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                )
            )
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.purple.opacity(0.12)  // barely-there border, same family as card border
                            : AppColors.purple.opacity(0.38), // strong on dark
                        lineWidth: 2.5
                    )
            )
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/PickUpCard.swift` {#file-open-lightly-features-home-components-pickupcard-swift}

```swift
// Home/Components/PickUpCard.swift

import SwiftUI

struct PickUpCard: View {
    let items: [PickUpItem]
    var onItemTap: ((PickUpItem) -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.prefix(2)) { item in
                    itemCard(item)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onItemTap?(item)
                        }
                }

                if items.count > 2 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all in-progress →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
        }
    }

    private func itemCard(_ item: PickUpItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.contentType.label)
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyanLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.08)
                                    : AppColors.cyan.opacity(0.12))
                        }
                        .overlay {
                            Capsule()
                                .stroke(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.20)
                                    : AppColors.cyan.opacity(0.25),
                                    lineWidth: 1)
                        }

                    Spacer()

                    // Pulsing amber dot
                    Circle()
                        .fill(Color(red: 1, green: 0.72, blue: 0))
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(item.contextLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(item.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .lineLimit(2)

                Text(item.actionLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightFrostCard
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }
}

private extension PickUpContentType {
    var label: String {
        switch self {
        case .timelineScenario: return "TIMELINE"
        case .article:          return "ARTICLE"
        case .judgmentCall:      return "JUDGMENT"
        case .autopsy:          return "AUTOPSY"
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ResearchTicker.swift` {#file-open-lightly-features-home-components-researchticker-swift}

```swift
// Home/Components/ResearchTicker.swift

import SwiftUI

struct ResearchTicker: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private let facts: [ResearchFact] = [
        ResearchFact(category: .research,
            body: "1 in 5 Americans has engaged in CNM\nat some point in their lives.",
            attribution: "— Haupert et al., 2017"),
        ResearchFact(category: .research,
            body: "Communication quality is measurably higher\nin CNM relationships. The structure demands it.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .research,
            body: "The biggest predictor of success isn't\ncompatibility — it's whether both people\ngenuinely chose this.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .definition,
            body: "Compersion: feeling joy at your partner's\nhappiness with someone else.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "NRE — New Relationship Energy:\nthe heightened feeling of a new connection.\nReal, temporary, manageable.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "Metamour: your partner's partner.\nSomeone you may never meet — or become\nclose friends with.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Jealousy is information,\nnot evidence that something is wrong.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Most people who explore CNM\nweren't unhappy. They were curious.",
            attribution: nil),
        ResearchFact(category: .research,
            body: "People who live in alignment with their\nactual desires report lower anxiety —\nregardless of what those desires are.",
            attribution: "— Moors et al., 2017"),
        ResearchFact(category: .reframe,
            body: "Sexual and romantic attraction are\nindependent dimensions. Both matter.\nNeither determines the other.",
            attribution: "— Diamond, 2003"),
    ]

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0

    private let displayDuration: TimeInterval = 10
    private let fadeDuration: TimeInterval = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                // Overline
                Text(facts[currentIndex].category.overlineLabel)
                    .font(AppFonts.overline)
                    .tracking(1.2)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                // Body
                Text(facts[currentIndex].body)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                // Attribution if exists
                if let attribution = facts[currentIndex].attribution {
                    Text(attribution)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
            }
            .opacity(opacity)
            .padding(.vertical, 14)

            // Bottom separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
        .onAppear {
            startCycle()
        }
    }

    private func startCycle() {
        Timer.scheduledTimer(withTimeInterval: displayDuration,
                             repeats: true) { _ in
            // Fade out
            withAnimation(.easeInOut(duration: fadeDuration)) {
                opacity = 0
            }
            // Swap fact + fade in
            DispatchQueue.main.asyncAfter(
                deadline: .now() + fadeDuration + 0.1
            ) {
                currentIndex = (currentIndex + 1) % facts.count
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview("Ticker Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.dark)
}

#Preview("Ticker Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/App/Theme/AppColors.swift` {#file-open-lightly-app-theme-appcolors-swift}

```swift
//
//  AppColors.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = .black
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// AppColors.swift
// Open Lightly
//
// Design System: Hot Border × Clash Display × Gradient Keywords
// Card intensity scales 1–8 with prompt difficulty
// ──────────────────────────────────────────────────────

// MARK: - App Colors

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Core Spectrum
    // The 3 anchor colors — used for borders,
    // gradient text highlights, glows
    // Gradient direction: 135° (top-left -> bottom-right)
    // ─────────────────────────────────────────────

    static let cyan       = Color(hex: "00C2FF")
    static let purple     = Color(hex: "6C3AE0")
    static let magenta    = Color(hex: "FF006A")

    /// Soft magenta variant — used in shimmer gradients and atmospheric fills
    static let pink       = Color(hex: "FF2D8A")

    /// Deep atmospheric blue — used in glow field floor washes
    static let deepBlue   = Color(hex: "0078FF")

    /// Electric violet — gradient midpoint, orb layers, PulseWidget orb C
    /// Use this. `violet` (#7C3AED) was removed — it had 0 usages.
    static let electricViolet = Color(hex: "8B5CF6")

    /// Electric purple — vivid gradient midpoint, LivingText only
    static let purpleVivid = Color(hex: "9333EA")

    static let purpleBright = Color(hex: "C084FC")

    // Lighter variants — gradient text on keywords, badges
    static let cyanLight    = Color(hex: "4DD8FF")
    static let purpleLight  = Color(hex: "A78BFA")
    static let magentaLight = Color(hex: "FF4D94")

    // Darker variants — tinted backgrounds, deep accents
    static let cyanDark    = Color(hex: "0891B2")
    static let purpleDark  = Color(hex: "1A1A5E")
    static let magentaDark = Color(hex: "BE185D")

    // ─────────────────────────────────────────────
    // MARK: Backgrounds
    // Page -> Card -> Surface hierarchy (darkest to lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")

    /// Widget/tray dark floor — sits between pageBg and surfaceRaised.
    /// Used for the dark base layer behind home widgets (PulseWidget, etc.)
    /// so the widget reads as a raised element without going full cardBg.
    static let widgetDarkFloor = Color(hex: "08060A")

    /// Default card interior (levels 1–4)
    // DARK-FILL-FIX: was #050507 — only 2/255 delta from pageBg.
    // At disabled opacity 0.45 the button was invisible.
    // #12111A holds shape identity at 0.45 while staying dark.
    static let cardBg = Color(hex: "12111A")

    /// Elevated surfaces, sheets, modals
    // DARK-FILL-FIX: was #08080C — 5/255 delta from pageBg.
    // Invisible at 0.45 opacity. #1A1825 holds pill shape.
    static let surfaceBg = Color(hex: "1A1825")

    /// Slightly raised elements (input fields, etc)
    static let surfaceRaised = Color(hex: "0C0C10")

    // Tinted card backgrounds (for intensity levels 5–8)
    static let tintCyan    = Color(hex: "061018")
    static let tintPurple  = Color(hex: "080614")
    static let tintMagenta = Color(hex: "120610")
    static let tintNavy    = Color(hex: "0A1018")
    static let tintIndigo  = Color(hex: "0A0820")
    static let tintPlum    = Color(hex: "180818")

    // Supernova (ultimate) gradient layers — deepest possible darks
    static let tintSupernovaA = Color(hex: "081420")
    static let tintSupernovaB = Color(hex: "0C0624")
    static let tintSupernovaC = Color(hex: "1A0620")
    static let tintSupernovaD = Color(hex: "1C0818")

    // ─────────────────────────────────────────────
    // MARK: Dark Mode Text
    //
    // All dark mode text is white-family — opacity lets
    // the purple atmosphere bleed through rather than
    // introducing flat grey hues.
    //
    // textPrimary (#E8E8F0): use for prompt content and
    // headings that need a fixed colour value.
    // .white (1.0): use for body copy that should feel
    // pure — onboarding screens, card text.
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings. Near-white with a subtle
    /// warm tint. Use .white directly for pure body copy.
    static let textPrimary    = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels (white @ 65%)
    /// opacity preserves luminance while letting atmosphere bleed through.
    static let textSecondary  = Color.white.opacity(0.65)

    /// Tertiary text — timestamps, meta (white @ 38%).
    /// Apply .italic() at usage sites — italic is the semantic signal
    /// that separates tertiary from secondary, not just opacity.
    static let textTertiary   = Color.white.opacity(0.38)

    /// Hint text — pronoun hints, placeholders, inline helper copy (white @ 42%).
    /// Slightly brighter than tertiary — hints compete with placeholder
    /// backgrounds and need a touch more presence.
    /// Renamed from textQuaternary (was incorrectly dimmer than tertiary).
    static let textHint       = Color.white.opacity(0.42)

    /// Muted text — disabled states, truly silent copy (white @ 20%)
    static let textMuted      = Color.white.opacity(0.20)

    /// Bright near-white for small labels that need to survive a
    /// purple-tinted ambient background (status strip counts, overline
    /// labels, etc). Device-absolute — cannot be tinted.
    static let textBright     = Color(white: 0.90)

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default subtle border
    static let border         = Color.white.opacity(0.06)

    /// Hover/active border
    static let borderHover    = Color.white.opacity(0.10)

    /// Prominent border
    static let borderActive   = Color.white.opacity(0.15)

    // ─────────────────────────────────────────────
    // MARK: UI Elements
    // ─────────────────────────────────────────────

    /// Badge background
    static let badgeBg        = cyan.opacity(0.08)

    /// Ghost button border
    static let btnGhostBorder = Color.white.opacity(0.06)

    /// Toggle / switch active
    static let toggleActive   = cyan

    /// Destructive / warning
    static let destructive    = Color(hex: "FF4444")

    /// Success / confirmed
    static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    /// Gold usage rule:
    /// At full or near-full opacity: safety signals only
    /// (safe word button, warnings, hard stop actions).
    /// Never decorative at visible opacity.
    /// Aurora atmospheric use at ≤8% opacity is acceptable
    /// because it cannot be read as a directional signal
    /// at that opacity level. If it is visible enough to be
    /// noticed as gold, it is too opaque for non-safety use.
    static let gold      = Color(hex: "C8960A")
    static let goldLight = Color(hex: "E2B93B")
    static let goldDark  = Color(hex: "8B6914")

    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Shadow colors
    static let shadowDeep = Color.black.opacity(0.50)

    // ─────────────────────────────────────────────
    // MARK: Gradients
    // ─────────────────────────────────────────────

    /// Card border gradient — the "Hot Border"
    /// Used on every prompt card at full opacity
    static let spectrumBorder = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Keyword highlight gradient — applied to select words
    /// Use with .foregroundStyle() on Text views
    static let spectrumText = LinearGradient(
        colors: [cyan, purpleLight, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    // ─────────────────────────────────────────────
    // MARK: Light Mode — Warm Aurora
    //
    // Background: #F8F6EE (warm cream — never change)
    // Aurora palette: Magenta / Purple / Gold — no cyan
    // All tokens prefixed with light* or aurora* to
    // prevent any collision with dark mode tokens.
    // ─────────────────────────────────────────────

    // Backgrounds
    /// Warm cream — the one true light mode page background
    static let lightPageBg    = Color(hex: "F8F6EE")

    /// Pure white — card interiors lift off the cream naturally
    static let lightCardBg    = Color(hex: "FFFFFF")

    /// Inset fields — slightly deeper than page, clearly recessed
    static let lightSurfaceBg = Color(hex: "F2EFE6")

    // ─────────────────────────────────────────────
    // MARK: Light Mode Text — Wine Scale
    //
    // Primary body text for all light mode screens derives
    // from the wine family, not near-black. This keeps the
    // full text stack within the warm aurora palette.
    //
    // Hierarchy (solid anchors):
    //   lightHeadline   #3D1A26  darkest — display headers
    //   lightBodyPrimary #5C1F35  mid wine — all body text
    //   lightBodyAccent  #7A2D45  lighter — accent / detail
    //   lightBodyWineDark #703040 lightest — pill labels, CTA text
    //
    // Opacity scale (derived from lightBodyPrimary):
    //   lightTextSecondary  60% — labels, descriptions
    //   lightTextTertiary   38% — meta, timestamps (+ italic at usage)
    //   lightTextMuted      22% — disabled, ghost copy
    //
    // lightTextPrimary (#1A1A1E near-black) is kept for any future
    // screen that genuinely wants neutral dark text, but it is NOT
    // the onboarding body color and should not be used there.
    // ─────────────────────────────────────────────

    /// Near-black — reserved for neutral screens. NOT the onboarding body color.
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// Darkest wine — display headlines on cream (#3D1A26)
    static let lightHeadline      = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Mid wine — primary body text for all light mode screens (#5C1F35)
    /// This is the base for the opacity scale below.
    static let lightBodyPrimary   = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Lighter wine — accent body, card detail text (#7A2D45)
    static let lightBodyAccent    = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Lightest wine — unselected pill labels, CTA text on light surfaces (#703040)
    static let lightBodyWineDark  = Color(red: 0.44, green: 0.07, blue: 0.18)

    /// Secondary text — labels, descriptions (lightBodyPrimary @ 60%)
    static let lightTextSecondary = lightBodyPrimary.opacity(0.60)

    /// Tertiary text — meta, timestamps (lightBodyPrimary @ 38%)
    /// Apply .italic() at usage sites — italic is the semantic differentiator.
    static let lightTextTertiary  = lightBodyPrimary.opacity(0.38)

    /// Muted text — disabled states, ghost copy (lightBodyPrimary @ 22%)
    static let lightTextMuted     = lightBodyPrimary.opacity(0.22)

    // Backwards-compatibility aliases for old token names.
    // Update call sites to lightHeadline / lightBodyPrimary / lightBodyAccent
    // and remove these once callers are migrated.
    static var lightHeadlineDarkRose: Color { lightHeadline }
    static var lightCardTitle: Color        { lightBodyPrimary }
    static var lightCardDetail: Color       { lightBodyAccent }

    // ─────────────────────────────────────────────
    // MARK: Light Mode Borders
    // ─────────────────────────────────────────────

    /// Default subtle border on cream surfaces
    static let lightBorder        = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover   = Color.black.opacity(0.10)

    /// Structural purple-tinted border for cards and fields (#6C3AE0 @ 14%)
    static let lightBorderPurple  = purple.opacity(0.14)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Glass Fills
    // Used with .background + backdrop blur in SwiftUI.
    // Opaque equivalents — semi-transparent whites multiply
    // with container opacity causing shapes to vanish at
    // disabled (0.45). Opaque values hold at any opacity.
    // ─────────────────────────────────────────────

    /// Glass card fill — warm near-white over aurora
    static let lightFrostCard     = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream (visible lavender-blush)
    static let lightFrostPill     = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — rose-blush, lifts visibly over unselected
    static let lightFrostPillSel  = Color(red: 0.958, green: 0.875, blue: 0.925)

    /// Custom pill fill — OnboardingNameView gender picker only
    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)

    /// CTA button fill — warm near-white
    static let lightFrostCTA      = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose, reads at any container opacity
    static let lightCTAFill       = Color(red: 0.98, green: 0.91, blue: 0.93)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Input
    // ─────────────────────────────────────────────

    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy (#BE185D @ 50%)
    static let lightHintText      = magentaDark.opacity(0.50)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Pill Tokens
    // ─────────────────────────────────────────────

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface       = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Ambient lift shadow applied to every pill in dark mode.
    static let pillGlow          = Color(white: 1.0).opacity(0.04)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Aurora Atmosphere
    // ─────────────────────────────────────────────

    // Aurora atmosphere blobs — pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)   // top right
    static let auroraBlob2 = purple.opacity(0.08)    // bottom left

    // Aurora shadow spread — on light surfaces, shadow IS the glow.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // ─────────────────────────────────────────────
    // MARK: Light Mode Icon Badges
    // ─────────────────────────────────────────────

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = magenta.opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = orangeHot.opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = gold.opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Borders
    //
    // One gradient border per mode used on ALL screens.
    // Replaces per-component branching on borders.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — keyword highlights on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]
}

// MARK: - ──────────────────────────────────────────────
// Card Intensity System
// Maps prompt difficulty -> visual intensity
// ──────────────────────────────────────────────────────

enum CardIntensity: Int, CaseIterable, Identifiable {
    case void        = 1
    case deepOcean   = 2
    case emberFloor  = 3
    case split       = 4
    case nebula      = 5
    case auroraBand  = 6
    case deepSpace   = 7
    case supernova   = 8

    var id: Int { rawValue }

    // ─────────────────────────────────────────────
    // MARK: Mapping from prompt data
    // ─────────────────────────────────────────────

    static func from(difficulty: String) -> CardIntensity {
        switch difficulty.lowercased() {
        case "easy":        return .void
        case "light":       return .deepOcean
        case "medium":      return .split
        case "deep":        return .nebula
        case "sensitive":   return .deepSpace
        case "ultimate":    return .supernova
        default:            return .deepOcean
        }
    }

    static func from(score: Int) -> CardIntensity {
        switch score {
        case 1...2:  return .void
        case 3:      return .deepOcean
        case 4:      return .emberFloor
        case 5:      return .split
        case 6:      return .nebula
        case 7:      return .auroraBand
        case 8:      return .deepSpace
        case 9...10: return .supernova
        default:     return .deepOcean
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Background
    // ─────────────────────────────────────────────

    var backgroundColor: Color {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return AppColors.cardBg
        case .nebula:
            return AppColors.tintCyan
        case .deepSpace:
            return AppColors.tintNavy
        case .supernova:
            return AppColors.tintIndigo
        }
    }

    var backgroundGradient: LinearGradient? {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return nil
        case .nebula:
            return LinearGradient(
                colors: [AppColors.tintCyan, AppColors.tintPurple, AppColors.tintMagenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .deepSpace:
            return LinearGradient(
                colors: [AppColors.tintNavy, AppColors.tintIndigo, AppColors.tintPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .supernova:
            return LinearGradient(
                colors: [
                    AppColors.tintSupernovaA,
                    AppColors.tintSupernovaB,
                    AppColors.tintSupernovaC,
                    AppColors.tintSupernovaD
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var usesGradientBackground: Bool {
        rawValue >= 5
    }

    // ─────────────────────────────────────────────
    // MARK: Radial Wash Overlays
    // ─────────────────────────────────────────────

    var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void:         return nil
        case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
        case .emberFloor:   return nil
        case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
        case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
        case .auroraBand:   return nil
        case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
        case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
        }
    }

    var magentaWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void, .deepOcean: return nil
        case .emberFloor:       return (x: 0.5, y: 1.1, opacity: 0.09)
        case .split:            return (x: 0.9, y: 1.0, opacity: 0.06)
        case .nebula:           return (x: 0.85, y: 0.8, opacity: 0.05)
        case .auroraBand:       return nil
        case .deepSpace:        return (x: 0.8, y: 0.9, opacity: 0.07)
        case .supernova:        return (x: 0.9, y: 1.0, opacity: 0.09)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Glow / Shadow
    // ─────────────────────────────────────────────

    var glowRadius: CGFloat {
        switch self {
        case .void, .deepOcean, .emberFloor:  return 30
        case .split, .nebula, .auroraBand:    return 40
        case .deepSpace:                       return 45
        case .supernova:                       return 60
        }
    }

    var glowMultiplier: Double {
        switch self {
        case .void:        return 0.6
        case .deepOcean:   return 0.8
        case .emberFloor:  return 0.8
        case .split:       return 0.9
        case .nebula:      return 1.0
        case .auroraBand:  return 0.9
        case .deepSpace:   return 1.1
        case .supernova:   return 1.3
        }
    }

    var cyanGlowOpacity: Double    { 0.08 * glowMultiplier }
    var magentaGlowOpacity: Double { 0.06 * glowMultiplier }

    // ─────────────────────────────────────────────
    // MARK: Display Helpers
    // ─────────────────────────────────────────────

    var displayName: String {
        switch self {
        case .void:        return "Void"
        case .deepOcean:   return "Deep Ocean"
        case .emberFloor:  return "Ember Floor"
        case .split:       return "Split"
        case .nebula:      return "Nebula"
        case .auroraBand:  return "Aurora Band"
        case .deepSpace:   return "Deep Space"
        case .supernova:   return "Supernova"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .void, .deepOcean:         return "Easy"
        case .emberFloor, .split:       return "Medium"
        case .nebula, .auroraBand:      return "Deep"
        case .deepSpace:                return "Sensitive"
        case .supernova:                return "Ultimate"
        }
    }
}

```

---

## File: `Open Lightly/App/Theme/AppFonts.swift` {#file-open-lightly-app-theme-appfonts-swift}

```swift
//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens

    // --- Display Scale (Clash Display) ---
    static var heroTitle: Font           { display(42, weight: .bold) }           // 42pt Bold
    static var displayHero: Font         { display(64, weight: .bold) }           // 64pt Bold
    static var scoreDisplay: Font        { display(32, weight: .bold) }           // 32pt Bold
    static var screenTitle: Font         { display(24, weight: .semibold) }       // 24pt Semibold
    static var cardTitle: Font           { display(22, weight: .semibold) }       // 22pt Semibold
    static var sectionHeading: Font      { display(20, weight: .medium) }         // 20pt Medium
    static var sectionLabelSmall: Font   { display(13, weight: .medium) }         // 13pt Medium
    static var prompt: Font              { display(17, weight: .medium) }         // 17pt Medium
    static var promptHighlight: Font     { display(17, weight: .semibold) }       // 17pt Semibold

    // --- Body Scale (Switzer) ---
    static var ctaLabel: Font            { body(16, weight: .semibold) }          // 16pt Semibold
    static var bodyText: Font            { body(16, weight: .regular) }           // 16pt Regular
    static var bodyMedium: Font          { body(15, weight: .medium) }            // 15pt Medium
    static var buttonLabel: Font         { body(14, weight: .semibold) }          // 14pt Semibold
    static var caption: Font             { body(13, weight: .regular) }           // 13pt Regular
    static var overline: Font            { body(11, weight: .semibold) }          // 11pt Semibold
    static var buttonLabelSmall: Font    { body(11, weight: .medium) }            // 11pt Medium
    static var tabLabel: Font            { body(10, weight: .medium) }            // 10pt Medium
    static var label: Font               { body(10, weight: .semibold) }          // 10pt Semibold
    static var badge: Font               { body(10, weight: .medium) }            // 10pt Medium
    static var meta: Font                { body(10, weight: .regular) }           // 10pt Regular

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

