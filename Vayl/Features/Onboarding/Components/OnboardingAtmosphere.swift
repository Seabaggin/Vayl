// OnboardingAtmosphere.swift
// Vayl

import SwiftUI

// MARK: - AtmosphereConfig

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark: AtmosphereIntensity

    static let stat = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.40, bottom: 1.15, global: 0.85),
        dark: AtmosphereIntensity(top: 1.00, mid: 0.50, bottom: 1.00, global: 0.70)
    )

    /// Learn tab. Same tri-colour bloom as `.stat`, but raised (`mid`) so colour
    /// climbs higher behind the Knowledge Hub card and the lit→dark transition is
    /// gradual instead of a hard cut. Paired with a lowered `maskStart` at the call
    /// site (LearnView). Separate from `.stat` so no other screen's atmosphere moves.
    static let learn = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.92, bottom: 1.10, global: 0.85),
        dark: AtmosphereIntensity(top: 1.00, mid: 0.92, bottom: 1.00, global: 0.76)
    )

    static let brand = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.35, bottom: 0.70, global: 0.78),
        dark: AtmosphereIntensity(top: 1.00, mid: 0.45, bottom: 0.80, global: 0.65)
    )

    static let name = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.10, bottom: 1.15, global: 0.60),
        dark: AtmosphereIntensity(top: 0.80, mid: 0.20, bottom: 0.90, global: 0.55)
    )

    static let modeSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.30, bottom: 1.15, global: 0.70),
        dark: AtmosphereIntensity(top: 0.15, mid: 0.35, bottom: 1.00, global: 0.60)
    )

    static let contextSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.40, mid: 0.20, bottom: 0.85, global: 0.50),
        dark: AtmosphereIntensity(top: 0.30, mid: 0.25, bottom: 0.75, global: 0.45)
    )

    static let curiosityPicker = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.30, mid: 0.10, bottom: 0.75, global: 0.40),
        dark: AtmosphereIntensity(top: 0.20, mid: 0.15, bottom: 0.65, global: 0.35)
    )

    static let buildingPath = AtmosphereConfig.curiosityPicker

    static let cardReveal = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.05, bottom: 0.40, global: 0.25),
        dark: AtmosphereIntensity(top: 0.08, mid: 0.08, bottom: 0.35, global: 0.22)
    )

    static let groundRules = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.15, mid: 0.20, bottom: 1.05, global: 0.50),
        dark: AtmosphereIntensity(top: 0.10, mid: 0.20, bottom: 0.90, global: 0.45)
    )
}

// MARK: - AtmosphereIntensity

struct AtmosphereIntensity: Equatable {
    var top: Double
    var mid: Double
    var bottom: Double
    var global: Double
}

// MARK: - OnboardingAtmosphere

struct OnboardingAtmosphere: View {

    var config: AtmosphereConfig = .stat
    var opacity: Double           = 1.0
    /// Where the void-only zone ends and the bloom starts fading in, as a fraction of
    /// screen height. 0.52 (default) matches every existing screen's "no colour above
    /// 52%" contract exactly — unchanged unless a caller opts into an earlier value.
    var maskStart: CGFloat = 0.52

    var body: some View {
        OBVoidBloom(intensity: config.dark, maskStart: maskStart)
            .animation(AppAnimation.atmosphereShift, value: config)
            .opacity(opacity)
    }
}

// MARK: - OBVoidBloom

/// Dark mode OB atmosphere.
/// Upper 65%: pure void — #0a0810, no color.
/// Lower 35%: tri-color bloom rising from below screen edge.
/// Cyan left · Purple center · Magenta right.
///
/// intensity.mid    — how far the bloom rises into the screen
/// intensity.bottom — bloom saturation / opacity
/// intensity.global — overall opacity multiplier

private struct OBVoidBloom: View {
    let intensity: AtmosphereIntensity
    var maskStart: CGFloat = 0.52

    private var bloomRise: CGFloat {
        CGFloat(0.28 + intensity.mid * 0.18)
    }

    private var cyanOpacity: Double { 0.20 * intensity.bottom * intensity.global }
    private var purpleOpacity: Double { 0.28 * intensity.bottom * intensity.global }
    private var magentaOpacity: Double { 0.18 * intensity.bottom * intensity.global }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack {
                // ── Void base ──────────────────────────────────────
                AppColors.void
                    .ignoresSafeArea()

                // ── Cyan — left anchor ─────────────────────────────
                Ellipse()
                    .fill(AppColors.spectrumCyan.opacity(cyanOpacity))
                    .frame(width: W * 0.80, height: H * 0.42)
                    .blur(radius: 55)
                    .offset(
                        x: -W * 0.18,
                        y: H * (0.50 - bloomRise * 0.85)
                    )

                // ── Purple — center anchor ─────────────────────────
                Ellipse()
                    .fill(AppColors.spectrumPurple.opacity(purpleOpacity))
                    .frame(width: W * 1.0, height: H * 0.50)
                    .blur(radius: 62)
                    .offset(
                        x: 0,
                        y: H * (0.50 - bloomRise)
                    )

                // ── Magenta — right anchor ─────────────────────────
                Ellipse()
                    .fill(AppColors.spectrumMagenta.opacity(magentaOpacity))
                    .frame(width: W * 0.75, height: H * 0.40)
                    .blur(radius: 55)
                    .offset(
                        x: W * 0.18,
                        y: H * (0.50 - bloomRise * 0.80)
                    )

                // ── Vertical mask ──────────────────────────────────
                // Hard contract: no color above `maskStart` (52% by default) of screen
                // height — content zone always sits on pure void. The three ramp stops
                // below keep the same relative shape as the default 52% curve, just
                // shifted so a caller can start the fade-in earlier (e.g. the check-in
                // field's own trail-in) without changing anyone else's rendering.
                LinearGradient(
                    stops: [
                        .init(color: AppColors.void, location: 0.00),
                        .init(color: AppColors.void, location: maskStart),
                        .init(color: AppColors.void.opacity(0.94), location: maskStart + 0.08),
                        .init(color: AppColors.void.opacity(0.70), location: maskStart + 0.18),
                        .init(color: AppColors.void.opacity(0.25), location: maskStart + 0.32),
                        .init(color: AppColors.void.opacity(0.02), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            // Rasterize the bloom to one Metal texture. Without this the three
            // large-radius ellipse blurs are live Core Animation filters,
            // re-evaluated on the GPU every frame anything on screen animates —
            // a constant tax under the whole OB (and Home). Rasterized, the
            // texture re-renders only while the bloom itself changes (the 1s
            // atmosphereShift config crossfade), then composites for free.
            // FEEL-GATE: blur now samples within screen bounds — verify the
            // left/right edge falloff on device (difference, if visible at all,
            // is a slightly dimmer strip inside the blur radius at the sides).
            // opaque: false — the alpha channel is required so that external
            // .opacity() modifiers (e.g. the 0.68 in OnboardingCanvasView) composite
            // correctly. opaque:true declared no alpha channel, which caused the
            // compositor to drop the atmosphere when opacity < 1.0 was applied.
            .drawingGroup(opaque: false)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Name — Dark") {
    ZStack {
        OnboardingAtmosphere(config: .name, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}

#Preview("Stat — Dark") {
    ZStack {
        OnboardingAtmosphere(config: .stat, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}

#Preview("CardReveal — Dark") {
    ZStack {
        OnboardingAtmosphere(config: .cardReveal, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}
