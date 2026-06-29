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

    var quadrant: PulseQuadrant { position.quadrant }
}

// MARK: - Field view

struct PulseField: View {

    var entries:         [PulseFieldEntry]
    var size:            CGFloat = 200
    var showAxisLabels:  Bool    = false   // High/Low/Guarded/Open rim labels

    var body: some View {
        ZStack {
            zones
            if showAxisLabels { axisLabels }
            if showAxisLabels { quadrantLabels }
            auraLayer
        }
        .frame(width: size, height: size)
    }

    // MARK: - Zone washes

    private var zones: some View {
        ZStack {
            zoneBlob(AppColors.pulseTierExpansive,  cx: 0.70, cy: 0.30)
            zoneBlob(AppColors.pulseTierFriction,   cx: 0.30, cy: 0.30)
            zoneBlob(AppColors.pulseTierProtective, cx: 0.30, cy: 0.70)
            zoneBlob(AppColors.pulseTierSovereign,  cx: 0.70, cy: 0.70)
        }
    }

    private func zoneBlob(_ color: Color, cx: CGFloat, cy: CGFloat) -> some View {
        let d = size * 0.74
        return Circle()
            .fill(color.opacity(0.16))
            .frame(width: d, height: d)
            .blur(radius: size * 0.105)
            .position(x: cx * size, y: cy * size)
    }

    // MARK: - Aura layer

    private var auraLayer: some View {
        GeometryReader { geo in
            ForEach(entries) { entry in
                let pt = fieldPoint(for: entry.position, in: geo.size)
                ZStack {
                    if entry.isBloom {
                        BloomRing(color: entry.quadrant.capacityColor.auraCore,
                                  size:  entry.auraSize)
                    }
                    PulseAura(quadrant: entry.quadrant, size: entry.auraSize)
                }
                .position(x: pt.x, y: pt.y)
            }
        }
    }

    // MARK: - Position mapping

    private func fieldPoint(for pos: PulsePosition, in size: CGSize) -> CGPoint {
        CGPoint(
            x: pos.openness * size.width,
            y: (1 - pos.energy) * size.height
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
            axisText("Charged").position(x: size * 0.50, y: 11)
            axisText("Quiet")  .position(x: size * 0.50, y: size - 11)
            axisText("Guarded").rotationEffect(.degrees(-90)).position(x: 11, y: size * 0.50)
            axisText("Open")   .rotationEffect(.degrees(90)) .position(x: size - 11, y: size * 0.50)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private func axisText(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 7, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textTertiary.opacity(0.55))
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
                guard !reduceMotion else { return }
                active = true
            }
            .animation(
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
