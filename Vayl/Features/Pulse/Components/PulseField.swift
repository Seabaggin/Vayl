// Features/Pulse/Components/PulseField.swift
//
// The 2D capacity circumplex: four soft colour zones (no grid), places PulseAura(s)
// at their circumplex positions, and shows a bloom ring when isBloom is set.
//
// Coordinate mapping:
//   openness → x  (0 = left / Guarded,  1 = right / Open)
//   energy   → y  (0 = bottom / Low,    1 = top / High)
//
// Axis labels (showAxisLabels: true) appear around the field boundary: High/Low
// on the vertical axis, Guarded/Open on the horizontal.
//
// Visual reference: docs/prototypes/map-pulse-us.html — the `.field` block.

import SwiftUI

// MARK: - Entry model

struct PulseFieldEntry: Identifiable {
    /// Use a stable string ID so SwiftUI animates position changes rather than
    /// removing and re-inserting the aura (which would break the drift animation).
    var id: String = "primary"
    var position: PulsePosition
    var auraSize: CGFloat = 44
    var isBloom:  Bool    = false
    /// Overrides the position-derived ramp (e.g. the check-in's silver-to-start state).
    /// nil (default) = every existing caller is unaffected.
    var rampOverride: AuraColors? = nil
    /// Dims a stale reading (e.g. a days-old position shown as "last known,"
    /// not "today"). 1.0 (default, no-op) = every existing caller unaffected.
    var opacity: Double = 1.0

    /// The six-space classification for this reading. nil (default) = derive it from the
    /// position, so every existing caller is unaffected; the check-in passes an explicit
    /// value when the Uncharted variance check has fired (position alone can't recover it).
    var space: PulseSpace? = nil

    /// Uncharted: the orb wanders slowly instead of landing at a fixed coordinate. false
    /// (default, no-op) = every existing caller is unaffected.
    var isDrifting: Bool = false

    var quadrant: PulseQuadrant { position.quadrant }

    /// Resolved space — the explicit override, or derived from the coordinates.
    var resolvedSpace: PulseSpace { space ?? PulseSpace.resolve(position) }

    /// The one shared dim level for a stale aura — a single tuning point so
    /// Map-Me's orb, the field sheet, and Map-Us's two auras can never drift
    /// apart. 🎚️ FEEL: tune on device.
    static let staleOpacity: Double = 0.6
}

// MARK: - Field view

struct PulseField: View {

    var entries:         [PulseFieldEntry]
    var size:            CGFloat = 200
    var showAxisLabels:  Bool    = false   // High/Low/Guarded/Open rim labels
    /// Uncharted resolution: the field (zones, ghost labels, axis labels) fades to nothing,
    /// leaving the drifting orb alone on the void. The aura layer never fades. (spec §9)
    var isUncharted:     Bool    = false

    var body: some View {
        ZStack {
            zones
                .opacity(isUncharted ? 0 : 1)
                .animation(AppAnimation.pulseUnchartedFieldFade, value: isUncharted)
            ghostLabels
                .opacity(isUncharted ? 0 : 1)
                .animation(AppAnimation.pulseUnchartedFieldFade, value: isUncharted)
            if showAxisLabels {
                axisLabels
                    .opacity(isUncharted ? 0 : 1)
                    .animation(AppAnimation.pulseUnchartedFieldFade, value: isUncharted)
            }
            auraLayer
        }
        .frame(width: size, height: size)
    }

    // MARK: - Zone washes

    private var zones: some View {
        // Four boxes that TILE the square rather than four floating discs: each colour is clipped
        // to its own quadrant rectangle, brightest at the outer field corner and fading toward the
        // centre. The rectangle edges — the outer boundary and the centre cross where the four
        // meet — do the shaping, so the field reads as a boxy grid with no drawn lines. Opacity is
        // luminance-compensated so the four read as EQUAL presence (cyan bright → down, rose dusty
        // → up). 🎚️ FEEL: opacities were tuned for soft blobs; a filled box covers more area, so
        // nudge down if any quadrant reads too hot on device.
        ZStack {
            zoneBox(AppColors.auraCoreMagenta, corner: .topLeading,     cx: 0.25, cy: 0.25, opacity: 0.20)  // Reactive
            zoneBox(AppColors.auraCoreCyan,    corner: .topTrailing,    cx: 0.75, cy: 0.25, opacity: 0.16)  // Expansive
            zoneBox(AppColors.auraCoreRose,    corner: .bottomLeading,  cx: 0.25, cy: 0.75, opacity: 0.32)  // Protective
            zoneBox(AppColors.auraCoreIndigo,  corner: .bottomTrailing, cx: 0.75, cy: 0.75, opacity: 0.23)  // Receptive
        }
        .frame(width: size, height: size)
    }

    private func zoneBox(_ color: Color, corner: UnitPoint, cx: CGFloat, cy: CGFloat, opacity: Double) -> some View {
        let half = size * 0.5
        return RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.opacity(opacity),        location: 0.0),
                .init(color: color.opacity(opacity * 0.62), location: 0.55),
                .init(color: .clear,                        location: 1.0)   // fades into the centre seam
            ]),
            center: corner,                 // anchored at the field's outer corner for this quadrant
            startRadius: 0,
            endRadius: half * 1.42           // reach diagonally across to the centre cross
        )
        .frame(width: half, height: half)    // hard rectangular clip = the boxy edge
        .position(x: cx * size, y: cy * size)
    }

    // MARK: - Ghost quadrant labels

    private var ghostLabels: some View {
        ZStack {
            // Left words ride higher, right words lower within each pair, so a big word and its
            // neighbour interlock at different heights instead of colliding at the centre line.
            ghostLabel("Reactive",   AppColors.auraCoreMagenta, leading: true,  yFrac: 0.16, quadrant: .reactive)
            ghostLabel("Expansive",  AppColors.auraCoreCyan,    leading: false, yFrac: 0.30, quadrant: .expansive)
            ghostLabel("Protective", AppColors.auraCoreRose,    leading: true,  yFrac: 0.70, quadrant: .protective)
            ghostLabel("Receptive",  AppColors.auraCoreIndigo,  leading: false, yFrac: 0.84, quadrant: .receptive)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    // Big, bold quadrant words. Full-width side-aligned band, staggered by yFrac so pairs never
    // collide — lets each word stay large (≈0.085×field) and heavy without crossing into its twin.
    private func ghostLabel(_ name: String, _ color: Color, leading: Bool, yFrac: CGFloat, quadrant: PulseQuadrant) -> some View {
        let isActive = entries.contains { $0.quadrant == quadrant }
        return Text(name.uppercased())
            .font(AppFonts.display(size * 0.085, weight: .bold, relativeTo: .title2))
            .tracking(size * 0.004)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(color.opacity(isActive ? 0.34 : 0.17))
            .frame(width: size * 0.92, alignment: leading ? .leading : .trailing)
            .position(x: size * 0.5, y: size * yFrac)
    }

    // MARK: - Aura layer

    private var auraLayer: some View {
        GeometryReader { geo in
            ForEach(entries) { entry in
                let r  = entry.auraSize * 0.5
                let pt = fieldPoint(for: entry.position, in: geo.size, inset: r)
                ZStack {
                    if entry.isBloom {
                        BloomRing(color: entry.quadrant.capacityColor.auraCore,
                                  size:  entry.auraSize)
                    }
                    // Colour precedence: an explicit rampOverride wins (e.g. the check-in's
                    // silver-to-start state); otherwise the resolved space paints the orb —
                    // a continuous bilinear blend for named/border spaces, a fixed ramp for
                    // Neutral (lavender silver) and Uncharted (sage deep).
                    if let ramp = entry.rampOverride {
                        PulseAura(ramp: ramp, size: entry.auraSize)
                    } else {
                        PulseAura(ramp: entry.resolvedSpace.ramp(at: entry.position),
                                  size: entry.auraSize)
                    }
                }
                .modifier(UnchartedDrift(active: entry.isDrifting))
                .position(x: pt.x, y: pt.y)
                .opacity(entry.opacity)
                .animation(AppAnimation.pulseBallDrift, value: pt)
            }
        }
    }

    // MARK: - Position mapping

    /// Maps a PulsePosition (0-1 on each axis) to a point in the GeometryReader's coordinate
    /// space, inset by `inset` pt on all sides so the aura center never leaves the field.
    private func fieldPoint(for pos: PulsePosition, in size: CGSize, inset: CGFloat = 0) -> CGPoint {
        CGPoint(
            x: inset + pos.openness * (size.width  - 2 * inset),
            y: inset + (1 - pos.energy) * (size.height - 2 * inset)
        )
    }

    // MARK: - Quadrant corner labels (inside the field — 8.5pt Clash Display, per-quadrant colour)

    private var quadrantLabels: some View {
        ZStack {
            quadrantText("Expansive",  .topTrailing,   AppColors.pulseTierExpansive.opacity(0.78))
            quadrantText("Friction",   .topLeading,    AppColors.pulseTierFriction.opacity(0.65))
            quadrantText("Protective", .bottomLeading, AppColors.pulseTierProtective.opacity(0.70))
            quadrantText("Sovereign",  .bottomTrailing,AppColors.pulseTierSovereign.opacity(0.72))
        }
        .allowsHitTesting(false)
    }

    private func quadrantText(_ label: String, _ alignment: Alignment, _ color: Color) -> some View {
        Text(label)
            .font(AppFonts.display(8.5, weight: .semibold, relativeTo: .caption2))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(AppSpacing.xs)
    }

    // MARK: - Axis labels (inside the field near each edge)

    private var axisLabels: some View {
        ZStack {
            axisText("Charged") .position(x: size * 0.50, y: 11)
            axisText("Depleted").position(x: size * 0.50, y: size - 11)
            axisText("Guarded").rotationEffect(.degrees(-90)).position(x: 11, y: size * 0.50)
            axisText("Open")   .rotationEffect(.degrees(90)) .position(x: size - 11, y: size * 0.50)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private func axisText(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.white.opacity(0.70))
    }
}

// MARK: - Uncharted drift

/// Slow, non-repeating orb wander for the Uncharted landing — two out-of-phase sinusoids per
/// axis give an organic Lissajous drift rather than a clean loop. Static under Reduce Motion.
/// Amplitude/timing 🎚️ FEEL: tune on device (see AppAnimation.pulseUnchartedDrift).
private struct UnchartedDrift: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if active && !reduceMotion && !AppAnimation.lowPower {
            // 30fps cap — the wander's fastest sinusoid moves ~5pt over 6s; sampling
            // at 30Hz is far below perception. Wall-clock drive (and thus the drift
            // path itself) is untouched — render-gating only.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let d = AppAnimation.pulseUnchartedDrift
                let x = sin(t / d * 2 * .pi) * 5 + sin(t / (d * 1.7) * 2 * .pi) * 3
                let y = cos(t / (d * 1.3) * 2 * .pi) * 5
                content.offset(x: x, y: y)
            }
        } else {
            content
        }
    }
}

// MARK: - Bloom ring

private struct BloomRing: View {
    let color: Color
    let size:  CGFloat

    @State private var active = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .stroke(color.opacity(active ? 0 : 0.55), lineWidth: 1.5)
            .frame(width: size, height: size)
            .scaleEffect(active ? 2.6 : 1.0)
            .onAppear {
                guard !reduceMotion, !AppAnimation.lowPower else { return }
                active = true
            }
            // .ambientAnimation (not raw .animation) — the loop contract's modifier,
            // which also nil-outs the loop under Reduce Motion / Low Power Mode.
            .ambientAnimation(
                .easeOut(duration: 1.6).repeatForever(autoreverses: false),
                value: active
            )
    }
}

// MARK: - Preview

#Preview("Four corners + bloom") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            // Four corners
            PulseField(
                entries: [
                    PulseFieldEntry(id: "a", position: PulsePosition(energy: 0.85, openness: 0.85)),
                    PulseFieldEntry(id: "b", position: PulsePosition(energy: 0.85, openness: 0.15)),
                    PulseFieldEntry(id: "c", position: PulsePosition(energy: 0.15, openness: 0.85)),
                    PulseFieldEntry(id: "d", position: PulsePosition(energy: 0.15, openness: 0.15)),
                ],
                size: 260,
                showAxisLabels: true
            )
            // Single aura with bloom
            PulseField(
                entries: [
                    PulseFieldEntry(position: PulsePosition(energy: 0.82, openness: 0.78), isBloom: true)
                ],
                size: 200,
                showAxisLabels: true
            )
        }
    }
    .preferredColorScheme(.dark)
}
