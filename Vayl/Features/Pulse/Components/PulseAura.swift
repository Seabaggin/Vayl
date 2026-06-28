// Features/Pulse/Components/PulseAura.swift
// Living-caustic-under-glass aura. Four layers: body / caustic (screen) / glass sweep / rim.
// Visual reference: docs/prototypes/pulse-aura-glass.html — port its layer order and gradients.
// FEEL: all animation values tuned on device vs the mockup; see AppAnimation.aura* tokens.

import SwiftUI

struct PulseAura: View {

    let quadrant: PulseQuadrant
    var size: CGFloat = 44

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breatheScale: CGFloat = 1.0
    @State private var causticActive = false
    @State private var sweepActive   = false

    private var tier: PulseCapacityColor { quadrant.capacityColor }

    var body: some View {
        ZStack {
            bodyLayer
            causticLayer
                .blendMode(.screen)
            glassSweep
            rimLayer
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .clipShape(Circle())
        .shadow(color: tier.auraGlow, radius: size * 0.27)   // FEEL: tune on device
        .scaleEffect(breatheScale)
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.auraBreathe).repeatForever(autoreverses: true),
            value: breatheScale
        )
        .onAppear { startAmbient() }
        .accessibilityHidden(true)
    }

    // MARK: - Layers

    private var bodyLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [tier.auraLight, tier.auraCore, tier.auraDeep],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.5
                )
            )
    }

    private var causticLayer: some View {
        let s = size * 1.32  // oversized so drift edges never show through the clip
        return ZStack {
            // blob 1: specular white flash (35% 38%)
            RadialGradient(
                colors: [.white.opacity(0.60), .clear],
                center: UnitPoint(x: 0.35, y: 0.38),
                startRadius: 0,
                endRadius: s * 0.30
            )
            // blob 2: tier light (66% 60%)
            RadialGradient(
                colors: [tier.auraLight.opacity(0.90), .clear],
                center: UnitPoint(x: 0.66, y: 0.60),
                startRadius: 0,
                endRadius: s * 0.28
            )
            // blob 3: tier core (50% 80%)
            RadialGradient(
                colors: [tier.auraCore.opacity(0.80), .clear],
                center: UnitPoint(x: 0.50, y: 0.80),
                startRadius: 0,
                endRadius: s * 0.30
            )
        }
        .frame(width: s, height: s)
        // drift: alternates between two positions; phase driven by causticActive toggle
        .offset(
            x: causticActive ?  size * 0.07 : -size * 0.06,  // FEEL: tune
            y: causticActive ? -size * 0.06 :  size * 0.06   // FEEL: tune
        )
        .rotationEffect(.degrees(causticActive ? 36 : -28))   // FEEL: tune
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.auraCausticDrift).repeatForever(autoreverses: true),
            value: causticActive
        )
    }

    private var glassSweep: some View {
        // Strip is 2.8× the aura width, starting parked off-screen left.
        // Parked center (sweepActive=false): -size * 0.892  (translateX(-64%) of strip width)
        // Passed center (sweepActive=true):  +size * 0.9   (translateX(0%), strip off-screen right)
        // The gradient bands are only visible as the strip passes through the clipped circle.
        // FEEL: gradient stop positions and opacity tuned on device vs pulse-aura-glass.html.
        let stripW  = size * 2.8
        let offsetX = sweepActive ? size * 0.9 : -size * 0.892
        return Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,               location: 0.36),
                        .init(color: .white.opacity(0.30), location: 0.405),
                        .init(color: .clear,               location: 0.45),
                        .init(color: .clear,               location: 0.57),
                        .init(color: .white.opacity(0.15), location: 0.61),
                        .init(color: .clear,               location: 0.65),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: stripW, height: size * 1.24)
            .offset(x: offsetX)
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.auraGlassSweep).repeatForever(autoreverses: false),
                value: sweepActive
            )
    }

    private var rimLayer: some View {
        ZStack {
            // inner highlight at the curved glass edge
            Circle()
                .stroke(.white.opacity(0.42), lineWidth: 1.5)
                .blur(radius: 2)
            // soft inner glow reinforcing the glass read
            Circle()
                .stroke(.white.opacity(0.16), lineWidth: size * 0.13)
                .blur(radius: size * 0.06)
        }
    }

    // MARK: - Animation control

    private func startAmbient() {
        guard !reduceMotion else { return }
        breatheScale  = 1.045  // FEEL: tune on device
        causticActive = true
        sweepActive   = true
    }
}

// MARK: - Preview

#Preview("All four quadrants") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            // hero size (150pt)
            HStack(spacing: AppSpacing.lg) {
                ForEach(PulseQuadrant.allCases, id: \.self) { q in
                    VStack(spacing: AppSpacing.xs) {
                        PulseAura(quadrant: q, size: 150)
                        Text(q.capacityColor.label)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            // field size (44pt)
            HStack(spacing: AppSpacing.lg) {
                ForEach(PulseQuadrant.allCases, id: \.self) { q in
                    PulseAura(quadrant: q, size: 44)
                }
            }
            // widget size (32pt)
            HStack(spacing: AppSpacing.md) {
                ForEach(PulseQuadrant.allCases, id: \.self) { q in
                    PulseAura(quadrant: q, size: 32)
                }
                Text("widget size")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
