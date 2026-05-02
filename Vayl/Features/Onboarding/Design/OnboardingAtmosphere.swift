// OnboardingAtmosphere.swift
// Open Lightly
//
// Unified atmospheric background for the entire onboarding flow.
// Consolidates OnboardingGlowField (dark) and AuroraGlowField (light)
// into one component with one config system covering both modes.
//
// Architecture:
//   - Lives in OnboardingFlowView's ZStack, below the screen switch.
//   - Never leaves the hierarchy — screens render on top of it.
//   - Light mode: AuroraGlowField morphs between per-screen configs via
//     its built-in .animation(.easeInOut(duration: 1.0), value: config).
//   - Dark mode: OnboardingGlowField is self-contained, no config needed.
//   - SparkField is light mode only — folded in here, not a separate call.
//
// BrandView exit contract:
//   OnboardingBrandView fires onAtmosphereExit() at t=4780ms.
//   FlowView receives this and sets atmosphereOpacity = 0 (easeIn 400ms).
//   FlowView owns atmosphereOpacity and passes it in here.
//   BrandView owns the timing. FlowView owns the state. Neither reaches
//   into the other's domain.
//
// Usage:
//   OnboardingAtmosphere(
//       config: auroraConfig,
//       sparkConfig: sparkConfig,
//       opacity: atmosphereOpacity
//   )
//   .ignoresSafeArea()
//   .allowsHitTesting(false)
//   .accessibilityHidden(true)

import SwiftUI

// MARK: - AtmosphereConfig
//
// One config per screen. Each config carries both light and dark
// intensity values so they live next to each other and can be
// tuned in one place.
//
// Light values carry over from the existing AuroraConfig presets.
// Dark values are tuned separately — dark mode amplifies color
// differently than cream does so the same multipliers would overblow.

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark:  AtmosphereIntensity

    // ── Per-screen presets ────────────────────────────────────────────

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

    // buildingPath reuses curiosityPicker —
    // de-energised atmosphere, content is the focus.
    static let buildingPath   = AtmosphereConfig.curiosityPicker

    // CardReveal — quiet reflective moment. Significantly reduced
    // from curiosityPicker to let the single card hold full attention.
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

    var config:      AtmosphereConfig      = .stat
    var sparkConfig: SparkConfiguration    = .statView
    var opacity:     Double                = 1.0

    @Environment(\.colorScheme) private var colorScheme

    // Map AtmosphereConfig → AuroraConfig so AuroraGlowField
    // continues to receive the typed value it expects.
    // This bridge is internal — callers only deal with AtmosphereConfig.
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
                // Dark mode: applies global opacity per screen config.
                // Per-blob intensity control is not yet implemented —
                // OnboardingGlowField does not accept intensity params.
                // Full dark mode config responsiveness requires extending
                // OnboardingGlowField to accept AtmosphereIntensity.
                OnboardingGlowField()
                    .opacity(config.dark.global)
                    .animation(.easeInOut(duration: 1.0), value: config)
            }
        }
        .opacity(opacity)
    }
}
// MARK: - Previews

#Preview("Stat — Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
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
