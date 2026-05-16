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
        isLight ? AppColors.accentSecondary        : AppColors.accentPrimary
    }
    private var ringMid: Color {
        isLight ? AppColors.accentTertiary       :AppColors.accentSecondary
    }
    private var ringOuter: Color {
        isLight ? AppColors.accentTertiary  : AppColors.accentTertiary
    }

    // Scrim color — dark mode uses page background so the blackout
    // is seamless. Light mode must use true black — cream scrim
    // at 0.92 reads beige, not dark.
    private var scrimColor: Color {
        isLight ? Color.black.opacity(0.78) : AppColors.pageBackground.opacity(0.95)
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
                isLight ? AppColors.textTertiary : AppColors.textTertiary
            )
            .padding(.bottom, AppSpacing.xs)

            // Tier name — gradient matches mode
            Text(entry.tier.label)
                .font(AppFonts.sectionHeading)
                .foregroundStyle(
                    LinearGradient(
                        colors: isLight
                            ? [AppColors.accentSecondary, AppColors.accentTertiary, AppColors.safetyAccent]
                            : [AppColors.accentPrimary,AppColors.accentSecondary, AppColors.accentTertiary],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .padding(.bottom, AppSpacing.xxs)

            // Glow underline
            glowUnderline
                .padding(.bottom, AppSpacing.xs)

            // Sublabel
            Text(entry.tier.sublabel)
                .font(AppFonts.caption)
                .foregroundStyle(
                    isLight ? AppColors.textTertiary : AppColors.textTertiary
                )
                .padding(.bottom, AppSpacing.sm)

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
                            ? AppColors.textSecondary
                            : AppColors.textSecondary
                    )
                Spacer()
                Text(value)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(
                        isLight
                            ? AppColors.textPrimary
                            : AppColors.textPrimary
                    )
            }
            .padding(.vertical, AppSpacing.sm)

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
                        ? [AppColors.accentSecondary, AppColors.accentTertiary, AppColors.safetyAccent, .clear]
                        : [AppColors.accentPrimary,AppColors.accentSecondary, AppColors.accentTertiary, .clear],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
            )
            .frame(width: 140, height: 1.5)
            .shadow(color:AppColors.accentSecondary.opacity(0.7), radius: 4)
            .shadow(color: AppColors.accentPrimary.opacity(0.4),           radius: 8)
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
        withAnimation(AppAnimation.enter) {
            emberOpacity = 1.0
        }
        animateEmbers()

        // Char flicker — begins after burn has opened
        // 6 cycles of brightness pulse mimicking cooling embers
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            triggerCharFlicker(cycles: 6)
        }

        // Info fades in after burn has opened
        withAnimation(AppAnimation.enter.delay(0.55)) {
            infoOpacity = 1.0
        }

        // Embers fade as they travel
        withAnimation(AppAnimation.enter.delay(0.75)) {
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
        // DESIGN DECISION: 0.08 + random(0...0.04) — intentional jitter.
        // Each flicker cycle varies ±25% around 0.08s to simulate organic ember cooling.
        // A fixed duration would produce a metronomic pulse that reads as mechanical.
        // Do not migrate to an AppAnimation token — this is stochastic physics, not UI state.
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
        withAnimation(AppAnimation.exit) {
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
                AppColors.accentSecondary,
                AppColors.accentTertiary,
                AppColors.accentSecondary,
                AppColors.accentTertiary,
                AppColors.safetyAccent,
                AppColors.accentSecondary,
                AppColors.accentTertiary,
            ]
            : [
                AppColors.accentPrimary,
               AppColors.accentSecondary,
                AppColors.accentTertiary,
                AppColors.accentTertiary,
                AppColors.accentSecondary,
                AppColors.accentPrimary,
                AppColors.accentTertiary,
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
        PulseDotSummary(
            entry:       PulseEntry.previews[6],
            dotPosition: CGPoint(x: 200, y: 40),
            graphHeight: 280,
            onDismiss:   {}
        )
    }
    .preferredColorScheme(.light)
}
