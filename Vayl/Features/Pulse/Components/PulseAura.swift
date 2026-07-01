// Features/Pulse/Components/PulseAura.swift
// Living-caustic-under-glass aura. Four layers: body / caustic (screen) / glass sweep / rim.
// Visual reference: docs/prototypes/pulse-aura-glass.html — port its layer order and gradients.
// FEEL: all animation values tuned on device vs the mockup; see AppAnimation.aura* tokens.

import SwiftUI

struct PulseAura: View {

    let ramp: AuraColors
    var size: CGFloat = 44
    /// Wide ambient halo the orb casts beyond its tight core glow — as a multiple of `size`.
    /// 0 (default) = no halo, so every existing caller (Map hero, field, history grid) is
    /// unchanged. The Home widget sets this to wash the pane with the orb's colour; because
    /// the halo lives here it stays in sync with the cycling dormant ramp automatically.
    var haloSpread: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breatheScale: CGFloat = 1.0
    @State private var causticActive = false
    @State private var sweepActive   = false  // drives glassSweep via GlassSpecularSweep factory

    /// Colour the aura by its quadrant tier (the common case — every existing caller).
    init(quadrant: PulseQuadrant, size: CGFloat = 44, haloSpread: CGFloat = 0) {
        self.ramp = AuraColors(quadrant.capacityColor)
        self.size = size
        self.haloSpread = haloSpread
    }

    /// Colour the aura from an explicit ramp — used by the cycling dormant aura.
    init(ramp: AuraColors, size: CGFloat = 44, haloSpread: CGFloat = 0) {
        self.ramp = ramp
        self.size = size
        self.haloSpread = haloSpread
    }

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
        .shadow(color: ramp.glow, radius: size * 0.27)   // FEEL: tune on device — tight core glow
        // Wide ambient halo — the Home widget's pane wash. A RadialGradient disc, NOT a .shadow
        // (shadows have no spread, so the colour dilutes to nothing) and NOT a .blur() (a Gaussian
        // blur is an offscreen pass — re-rasterising it every frame under the dormant orb's 60fps
        // TimelineView blows the HomeDashboardView preview budget and burns GPU on device). The
        // gradient maps cleanly onto shine.html's `box-shadow: 0 0 150px 60px` on a 66px orb: the
        // solid-colour core stop = the 60px SPREAD, the fade to clear = the 150px blur. `haloSpread`
        // is the disc diameter as a multiple of the orb (~2.8×). ramp.glow's ~.30 alpha ≈ the
        // mockup's .32. No-op when haloSpread is 0. FEEL: tune.
        .background {
            if haloSpread > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: ramp.glow, location: 0.0),
                                .init(color: ramp.glow, location: 0.34),  // solid core = box-shadow spread
                                .init(color: .clear,    location: 1.0)     // soft falloff = the blur
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size * haloSpread * 0.5
                        )
                    )
                    .frame(width: size * haloSpread, height: size * haloSpread)
            }
        }
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
                    colors: [ramp.light, ramp.core, ramp.deep],
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
                        Gradient(colors: [ramp.core, .clear]),
                        center: CGPoint(x: w * 0.50, y: h * 0.80),
                        startRadius: 0, endRadius: w * 0.30))
            // Blob 2 — MIDDLE: tier light at 66% 60%
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .radialGradient(
                        Gradient(colors: [ramp.light, .clear]),
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

// MARK: - Aura colour ramp

/// The four colours that paint a PulseAura. Build one from a quadrant tier, or interpolate
/// between two ramps (for the cycling dormant aura).
struct AuraColors {
    let light: Color
    let core:  Color
    let deep:  Color
    let glow:  Color

    init(light: Color, core: Color, deep: Color, glow: Color) {
        self.light = light; self.core = core; self.deep = deep; self.glow = glow
    }

    init(_ tier: PulseCapacityColor) {
        self.init(light: tier.auraLight, core: tier.auraCore, deep: tier.auraDeep, glow: tier.auraGlow)
    }

    static func lerp(_ a: AuraColors, _ b: AuraColors, _ t: Double) -> AuraColors {
        AuraColors(
            light: a.light.blended(with: b.light, t),
            core:  a.core.blended(with: b.core,  t),
            deep:  a.deep.blended(with: b.deep,  t),
            glow:  a.glow.blended(with: b.glow,  t)
        )
    }
}

private extension Color {
    /// Linear RGBA blend toward another colour. t=0 → self, t=1 → other.
    func blended(with other: Color, _ t: Double) -> Color {
        let f = CGFloat(max(0, min(1, t)))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red:     Double(r1 + (r2 - r1) * f),
            green:   Double(g1 + (g2 - g1) * f),
            blue:    Double(b1 + (b2 - b1) * f),
            opacity: Double(a1 + (a2 - a1) * f)
        )
    }
}

// MARK: - Cycling dormant aura

/// The D1 / empty-state aura: no check-in data yet, so it slowly tours all four spaces —
/// alive and inviting instead of a dead shell. One calm aura under Reduce Motion.
struct PulseCyclingAura: View {
    var size: CGFloat = 56
    var secondsPerSpace: Double = 3.6   // FEEL: tune on device
    /// Forwarded to the inner PulseAura — see PulseAura.haloSpread. The halo cycles colour
    /// in lockstep with the ramp because it's the same view.
    var haloSpread: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Around the circumplex: Expansive → Sovereign → Protective → Friction → back.
    private let ramps: [AuraColors] = [
        AuraColors(.cyan), AuraColors(.indigo), AuraColors(.rose), AuraColors(.magenta),
    ]

    var body: some View {
        if reduceMotion {
            PulseAura(ramp: ramps[0], size: size, haloSpread: haloSpread)
        } else {
            TimelineView(.animation) { timeline in
                PulseAura(ramp: rampAt(timeline.date), size: size, haloSpread: haloSpread)
            }
        }
    }

    private func rampAt(_ date: Date) -> AuraColors {
        let n     = Double(ramps.count)
        let phase = (date.timeIntervalSinceReferenceDate / secondsPerSpace).truncatingRemainder(dividingBy: n)
        let i     = Int(phase)
        let frac  = phase - Double(i)
        let eased = frac * frac * (3 - 2 * frac)   // smoothstep — ease in/out between spaces
        return AuraColors.lerp(ramps[i], ramps[(i + 1) % ramps.count], eased)
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
