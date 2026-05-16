// OnboardingAtmosphere.swift
// Vayl

import SwiftUI

// MARK: - AtmosphereConfig

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark:  AtmosphereIntensity

    static let stat = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.40, bottom: 1.15, global: 0.85),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.50, bottom: 1.00, global: 0.70)
    )

    static let brand = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.35, bottom: 0.70, global: 0.78),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.45, bottom: 0.80, global: 0.65)
    )

    static let name = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.10, bottom: 1.15, global: 0.60),
        dark:  AtmosphereIntensity(top: 0.80, mid: 0.20, bottom: 0.90, global: 0.55)
    )

    static let modeSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.30, bottom: 1.15, global: 0.70),
        dark:  AtmosphereIntensity(top: 0.15, mid: 0.35, bottom: 1.00, global: 0.60)
    )

    static let contextSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.40, mid: 0.20, bottom: 0.85, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.30, mid: 0.25, bottom: 0.75, global: 0.45)
    )

    static let curiosityPicker = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.30, mid: 0.10, bottom: 0.75, global: 0.40),
        dark:  AtmosphereIntensity(top: 0.20, mid: 0.15, bottom: 0.65, global: 0.35)
    )

    static let buildingPath = AtmosphereConfig.curiosityPicker

    static let cardReveal = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.05, bottom: 0.40, global: 0.25),
        dark:  AtmosphereIntensity(top: 0.08, mid: 0.08, bottom: 0.35, global: 0.22)
    )

    static let groundRules = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.15, mid: 0.20, bottom: 1.05, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.10, mid: 0.20, bottom: 0.90, global: 0.45)
    )
}

// MARK: - AtmosphereIntensity

struct AtmosphereIntensity: Equatable {
    var top:    Double
    var mid:    Double
    var bottom: Double
    var global: Double
}

// MARK: - OnboardingAtmosphere

struct OnboardingAtmosphere: View {

    var config:      AtmosphereConfig   = .stat
    var sparkConfig: SparkConfiguration = .statView
    var opacity:     Double             = 1.0

    @Environment(\.colorScheme) private var colorScheme

    private var auroraConfig: AuroraConfig {
        let i = colorScheme == .light ? config.light : config.dark
        return AuroraConfig(
            topOpacityMult:    i.top,
            midOpacityMult:    i.mid,
            bottomOpacityMult: i.bottom,
            globalOpacity:     i.global
        )
    }

    var body: some View {
        Group {
            if colorScheme == .light {
                ZStack {
                    AuroraGlowField(config: auroraConfig)
                    SparkField(config: sparkConfig)
                }
            } else {
                OBVoidBloom(intensity: config.dark)
                    .animation(.easeInOut(duration: 1.0), value: config)
            }
        }
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

    private var bloomRise: CGFloat {
        CGFloat(0.28 + intensity.mid * 0.18)
    }

    private var cyanOpacity:    Double { 0.20 * intensity.bottom * intensity.global }
    private var purpleOpacity:  Double { 0.28 * intensity.bottom * intensity.global }
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
                        y:  H * (0.50 - bloomRise * 0.85)
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
                        x:  W * 0.18,
                        y:  H * (0.50 - bloomRise * 0.80)
                    )

                // ── Vertical mask ──────────────────────────────────
                // Hard contract: no color above 52% of screen height.
                // Content zone always sits on pure void.
                LinearGradient(
                    stops: [
                        .init(color: AppColors.void,              location: 0.00),
                        .init(color: AppColors.void,              location: 0.52),
                        .init(color: AppColors.void.opacity(0.94),location: 0.60),
                        .init(color: AppColors.void.opacity(0.70),location: 0.70),
                        .init(color: AppColors.void.opacity(0.25),location: 0.84),
                        .init(color: AppColors.void.opacity(0.02),location: 1.00),
                    ],
                    startPoint: .top,
                    endPoint:   .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
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

#Preview("Stat — Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}
