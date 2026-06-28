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
    @State private var sweepActive   = false  // drives glassSweep via GlassSpecularSweep factory

    private var tier: PulseCapacityColor { quadrant.capacityColor }

    var body: some View {
        ZStack {
            bodyLayer
            causticLayer
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
        // CSS `background:` layers composite bottom-to-top (last declaration = bottom).
        // Canvas mirrors that exactly — each fill() draws over the prior one.
        // This single-pass render matches CSS's internal multi-background compositing;
        // a ZStack of separate RadialGradient views doesn't — the z-order was inverted
        // (white ended up at the bottom, colored blobs on top) producing the viscous look.
        let s = size * 1.32  // `inset: -16%` → 100% + 2×16% = 132%
        return Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // Blob 3 — BOTTOM: tier core at 50% 80% (last CSS declaration)
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .radialGradient(
                        Gradient(colors: [tier.auraCore, .clear]),
                        center: CGPoint(x: w * 0.50, y: h * 0.80),
                        startRadius: 0, endRadius: w * 0.30))
            // Blob 2 — MIDDLE: tier light at 66% 60%
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .radialGradient(
                        Gradient(colors: [tier.auraLight, .clear]),
                        center: CGPoint(x: w * 0.66, y: h * 0.60),
                        startRadius: 0, endRadius: w * 0.28))
            // Blob 1 — TOP: white specular at 35% 38% (first CSS declaration)
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.60), .clear]),
                        center: CGPoint(x: w * 0.35, y: h * 0.38),
                        startRadius: 0, endRadius: w * 0.30))
        }
        .frame(width: s, height: s)
        .blendMode(.screen)
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
        // Geometry: strip is 2.8× wide so edges stay off-screen during the sweep.
        // Gradient recipe from GlassSpecularSweep.glassSpecular() — StatPhase canonical.
        let offsetX = sweepActive ? size * 0.9 : -size * 0.892
        return Rectangle()
            .fill(LinearGradient.glassSpecular())
            .frame(width: size * 2.8, height: size * 1.24)
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
