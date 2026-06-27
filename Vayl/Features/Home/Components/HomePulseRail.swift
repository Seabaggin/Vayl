// Features/Home/Components/HomePulseRail.swift
// Vayl
//
// Module 2 — "The Pulse", as LIGHT in the void (not a widget, not a card).
//
// Hierarchy by depth, not by dimming: the hero deck is an OBJECT (it floats,
// it has a border + shadow + pedestal). The Pulse is the room's own light
// gathering into a line — no border, no shadow, no lift — so it reads as second
// fiddle no matter how vivid or detailed it is. The graph LEADS; its glow uses
// the bloom palette and its area melts downward into the atmosphere bloom, so the
// line and the background are the same substance ("Atmosphere gathers").
//
// The widget-header chrome is gone (no "THE PULSE" overline, chevron, or bold
// title — that read as a competing boxless card). The content still works:
//   • the quick reference = the user's current Space (computed from their LATEST
//     real check-in) + its descriptor words
//   • a worded "Check in" affordance when today has no check-in yet
//
// Data states, from the user's real check-ins (PulseStore.entries):
//   • 0 entries     → an inviting baseline + "Check in to begin"
//   • 1...6 entries  → BUILD-UP graph that fills the week from the ember leftward
//   • 7+ entries     → the settled 7-day trend (last 7 check-ins)
//
// ⚠️ CONSTRAINT: this is the Home rail, a lightweight read of PulseStore. It does
// NOT touch PulseWidget.swift and does NOT use the full instrument's graph code
// (PulseGraph). The materialise-on-attention behaviour, the history sheet, and the
// shared check-in sheet remain the focused Pulse pass.

import SwiftUI

struct HomePulseRail: View {

    /// Tapping the rail body routes to the Pulse surface (glance → detail).
    var onTap: (() -> Void)? = nil
    /// The worded "Check in" affordance. Routes to the shared check-in sheet.
    var onCheckIn: (() -> Void)? = nil
    /// The info "ⓘ" — opens the Pulse QRG. Presented from HomeDashboardView so it
    /// covers the whole screen (a sheet from this nested view would not).
    var onInfo: (() -> Void)? = nil

    /// Scroll-linked reveal: 0 = collapsed (header only, graph hidden), 1 = full.
    var expansion: Double = 1
    /// The graph's height at full expansion.
    var maxGraphHeight: CGFloat = 160

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(PulseStore.self) private var pulse

    /// Drives the spark "developing" from the ember (the trim start oscillates).
    @State private var develop = false

    private let slots = 7

    /// The graph height for the current state: 0 collapsed → maxGraphHeight expanded.
    /// `expansion` is a discrete 0/1 (the parent animates the flip; Reduce Motion just gets
    /// the snap without animation), so the graph genuinely collapses for everyone.
    private var resolvedGraphHeight: CGFloat { CGFloat(expansion) * maxGraphHeight }
    private var resolvedGraphOpacity: Double { expansion }

    /// Subtle expanded detail (day ticks) fades in over the last 40% of expansion.
    private var detailOpacity: Double {
        reduceMotion ? 1 : max(0, min(1, (expansion - 0.6) / 0.4))
    }

    /// The quiet hairline panel dissolves over the first half of the expansion, so
    /// the graph becomes free light once it has earned the space.
    private var cardChromeOpacity: Double {
        reduceMotion ? 0 : max(0, 1 - expansion / 0.5)
    }

    /// The tier-coloured gradient for the Space title (secondary hero).
    private func tierGradient(_ tier: PulseTier) -> LinearGradient {
        LinearGradient(
            colors: [tier.color, tier.color.opacity(0.55)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var totalCount: Int { pulse.entries.count }
    private var recent: [PulseEntry] { Array(pulse.entries.suffix(slots)) }
    private var isBuildUp: Bool { totalCount < slots }

    private var latest: PulseEntry? { pulse.entries.last }
    private var checkedInToday: Bool {
        guard let d = latest?.date else { return false }
        return Calendar.current.isDateInToday(d)
    }

    /// The current Space, computed from the user's LATEST real check-in (nil with
    /// no data, so we never show a faked Space).
    private var currentTier: PulseTier? { latest?.tier }

    // Contrast-aware text tiers (promote one step under Increase Contrast).
    private var spaceColor: Color { contrast == .increased ? AppColors.textPrimary   : AppColors.textSecondary }
    private var wordsColor: Color { contrast == .increased ? AppColors.textSecondary : AppColors.textTertiary }

    // capacityScore 1.0...4.0 → normalised y (inverted). Wide amplitude so the line
    // fills the earned height with real peaks and valleys, not a flat strip.
    private func yFor(_ score: Double) -> CGFloat {
        0.86 - CGFloat((score - 1) / 3) * 0.72
    }

    /// Right-anchored points: the latest check-in is always the ember at the right
    /// edge; the line grows leftward as the week fills.
    private var points: [CGPoint] {
        guard !recent.isEmpty else { return [] }
        let step = 1 / CGFloat(slots - 1)
        let offset = slots - recent.count
        return recent.enumerated().map { i, e in
            CGPoint(x: CGFloat(offset + i) * step, y: yFor(e.capacityScore))
        }
    }

    /// The unlogged days, shown as faint slots on the left during build-up.
    private var emptySlots: [CGFloat] {
        guard isBuildUp, totalCount > 0 else { return [] }
        let step = 1 / CGFloat(slots - 1)
        let offset = slots - recent.count
        return (0..<offset).map { CGFloat($0) * step }
    }

    var body: some View {
        // No "THE PULSE" header — it broke the home's cohesiveness. The card stands
        // on its own; the info "ⓘ" (the Pulse QRG) reveals inline next to the
        // descriptor once you scroll.
        pulseCard
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap?()
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    develop = true
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(a11yLabel)
            .accessibilityAddTraits(.isButton)
    }

    /// The info "ⓘ" fades in as the user scrolls (after rest).
    private var infoReveal: Double {
        reduceMotion ? 1 : max(0, min(1, expansion / 0.25))
    }

    // MARK: - The card (Space + check-in, dissolves into the graph)

    private var pulseCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                // Claim the remaining width so the title shrinks to fit (via
                // minimumScaleFactor) instead of pushing the "+" past the margin.
                quickReference
                    .frame(maxWidth: .infinity, alignment: .leading)
                checkInPlus
            }

            // Decouple the GeometryReader from layout negotiation: a clear proxy
            // reliably expands to full width (GeometryReader reports ~zero ideal
            // width, which would otherwise shrink-wrap the card to the text). The
            // graph lives in the overlay and just adopts the proxy's stable size.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: resolvedGraphHeight)
                .overlay(alignment: .topLeading) { graph }
                .opacity(resolvedGraphOpacity)
                .clipped()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .center)   // full-width, centered
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    // Full spectrum stroke + a spectrum glow so the border reads as
                    // vivid as the hero card's, not the faded 0.22 hairline it was.
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.7), lineWidth: 1.5)
                        .spectrumBorderGlow(intensity: 0.55 * cardChromeOpacity)
                )
                .opacity(cardChromeOpacity)
        )
    }

    // MARK: - Quick reference (the current Space)

    @ViewBuilder
    private var quickReference: some View {
        if let tier = currentTier {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // Secondary hero: the Space in its own tier-coloured gradient, so the
                // title's hue encodes the user's current capacity.
                Text(tier.label)
                    .font(AppFonts.display(32, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(tierGradient(tier))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: AppSpacing.xs) {
                    Text(tier.sublabel)
                        .font(AppFonts.body(14, weight: .regular, relativeTo: .subheadline))
                        .foregroundStyle(wordsColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    // The Pulse QRG affordance — reveals as you scroll.
                    infoButton
                        .opacity(infoReveal)
                        .allowsHitTesting(infoReveal > 0.5)
                }
            }
        } else {
            // No data yet — the quick reference is the invitation itself.
            Text("Check in to begin")
                .font(AppFonts.body(16, weight: .medium, relativeTo: .body))
                .foregroundStyle(spaceColor)
        }
    }

    // MARK: - Check-in affordance (a "+" pinned top-right)

    private var checkInPlus: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCheckIn?()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)   // white on the dark void
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.04)))
                .overlay(
                    Circle().strokeBorder(AppColors.spectrumBorder, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlusPressStyle())
        .accessibilityLabel("Check in")
        .accessibilityHint("Opens today's check-in")
    }

    // MARK: - Info affordance (the "i" in the divider)

    private var infoButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onInfo?()
        } label: {
            Image(systemName: "info")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle().strokeBorder(
                        AppColors.spectrumBorder.opacity(0.4),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(PlusPressStyle())
        .accessibilityLabel("About the Pulse")
    }

    // MARK: - Graph

    private var graph: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Anchored at the ember (to: 1.0); develops leftward as trimStart eases.
            let trimStart: CGFloat = reduceMotion ? 0 : (develop ? 0.0 : 0.45)

            ZStack(alignment: .topLeading) {
                // Baseline accent — a faint ground line the light rests on.
                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.14))
                    .frame(width: w, height: 1)
                    .position(x: w / 2, y: h - 0.5)

                // Today marker accent — a soft vertical light rising to the ember.
                if let last = points.last {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.spectrumMagenta.opacity(0.0),
                                    AppColors.spectrumMagenta.opacity(0.20),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: h * 0.5)
                        .position(x: last.x * w, y: h * 0.75)
                }

                // Expanded detail — faint day ticks + a mid capacity gridline that
                // fade in over the last stretch of the scroll expansion.
                Group {
                    if detailOpacity > 0 {
                        let step = 1 / CGFloat(slots - 1)
                        ForEach(0..<slots, id: \.self) { d in
                            Rectangle()
                                .fill(AppColors.spectrumBorder.opacity(0.18))
                                .frame(width: 1, height: 4)
                                .position(x: CGFloat(d) * step * w, y: h - 3)
                        }
                        Rectangle()
                            .fill(AppColors.spectrumBorder.opacity(0.08))
                            .frame(width: w, height: 1)
                            .position(x: w / 2, y: h * 0.5)
                    }
                }
                .opacity(detailOpacity)

                if points.count >= 2 {
                    // Area melt — the line's substance pooling down into the bloom.
                    AreaShape(points: points)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.spectrumPurple.opacity(0.22), location: 0.0),
                                    .init(color: AppColors.spectrumPurple.opacity(0.04), location: 0.6),
                                    .init(color: .clear,                                 location: 1.0),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    // Glow pass — soft, bloom-coloured.
                    SparkShape(points: points)
                        .trim(from: trimStart, to: 1.0)
                        .stroke(AppColors.spectrumText,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .opacity(0.32)
                        .blur(radius: 9)

                    // Crisp pass.
                    SparkShape(points: points)
                        .trim(from: trimStart, to: 1.0)
                        .stroke(AppColors.spectrumText,
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                        .opacity(0.95)
                } else if points.isEmpty {
                    // No data yet — a faint dashed baseline invites the first check-in.
                    SparkShape(points: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)])
                        .stroke(AppColors.spectrumText,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                        .opacity(0.22)
                }

                // Unlogged days (build-up): faint slots awaiting a check-in.
                ForEach(Array(emptySlots.enumerated()), id: \.offset) { _, fx in
                    Circle()
                        .fill(AppColors.textTertiary.opacity(0.35))
                        .frame(width: 3, height: 3)
                        .position(x: fx * w, y: 0.5 * h)
                }

                // The "today" ember — filled when checked in today, an inviting hollow
                // ring when today is still open.
                EmberNode(inviting: !checkedInToday)
                    .frame(width: 30, height: 30)
                    .position(x: (points.last?.x ?? 1) * w,
                              y: (points.last?.y ?? 0.5) * h)
            }
            .frame(width: w, height: h)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.10),
                        .init(color: .black, location: 1.0),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        }
        .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private var a11yLabel: String {
        let state: String
        if let tier = currentTier {
            state = "\(tier.label). \(tier.sublabel)."
        } else {
            state = "No check-ins yet."
        }
        let action = checkedInToday ? "" : " Check in available."
        return "The Pulse. \(state)\(action)"
    }
}

// MARK: - Spark Shape

/// The Pulse spark as an animatable Shape, so `.trim` develops smoothly.
private struct SparkShape: Shape {
    let points: [CGPoint]   // normalised 0...1

    func path(in rect: CGRect) -> Path {
        Path { p in
            for (i, n) in points.enumerated() {
                let pt = CGPoint(x: n.x * rect.width, y: n.y * rect.height)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }
}

// MARK: - Area Shape

/// The area under the spark, closed down to the baseline — filled with a vertical
/// fade so the line's substance melts into the atmosphere bloom below.
private struct AreaShape: Shape {
    let points: [CGPoint]   // normalised 0...1

    func path(in rect: CGRect) -> Path {
        Path { p in
            guard let first = points.first, let last = points.last else { return }
            p.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
            for n in points.dropFirst() {
                p.addLine(to: CGPoint(x: n.x * rect.width, y: n.y * rect.height))
            }
            p.addLine(to: CGPoint(x: last.x * rect.width, y: rect.height))
            p.addLine(to: CGPoint(x: first.x * rect.width, y: rect.height))
            p.closeSubpath()
        }
    }
}

// MARK: - Ember Node

/// The magenta "today" ember — a glowing core inside a breathing halo. When the
/// day is still open (no check-in yet) it reads as an inviting hollow ring.
private struct EmberNode: View {

    var inviting: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.spectrumMagenta.opacity(inviting ? 0.7 : 0.45),
                              lineWidth: 1.5)
                .scaleEffect(breathe ? (inviting ? 1.18 : 1.12) : 0.9)
                .opacity(breathe ? 1.0 : 0.5)

            if inviting {
                // Hollow invitation — a quiet core waiting for today's check-in.
                Circle()
                    .strokeBorder(AppColors.spectrumMagenta.opacity(0.9), lineWidth: 2)
                    .frame(width: 10, height: 10)
            } else {
                Circle()
                    .fill(AppColors.spectrumMagenta)
                    .frame(width: 10, height: 10)
                    .shadow(color: AppColors.spectrumMagenta.opacity(0.9), radius: 7)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse)
                .repeatForever(autoreverses: true)
            ) {
                breathe = true
            }
        }
    }
}

// MARK: - Pulse Info Sheet

/// The "what is the Pulse" explainer + the Space legend. No right or wrong space —
/// just a read on capacity that makes sessions land better.
struct PulseInfoSheet: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("The Pulse")
                        .font(AppFonts.sectionHeading)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("A quick read on your capacity for connection right now. Checking in before a session helps you and your partner meet where you actually are.")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(PulseTier.allCases, id: \.self) { tier in
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            Circle()
                                .fill(tier.color)
                                .frame(width: 12, height: 12)
                                .padding(.top, 3)
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(tier.label)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(tier.sublabel)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }

                Text("There is no right or wrong space. Knowing where you are, capacity-wise, makes sessions with your partner better.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Plus Press Style

private struct PlusPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Home Pulse Rail") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HomePulseRail()
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
