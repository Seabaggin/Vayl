// Design/Components/Text/HolographicText.swift
// Vayl
//
// The app's holographic text treatment — the StatPhase "1 in 5" glass effect as a
// reusable view: a drifting spectrum gradient fill, a blurred glow bloom beneath it,
// and a specular light-sweep across the glyphs. Lifted so the Home Lexicon's research
// kind reads with the same "evidence catching the light" quality as the onboarding stat.
//
// One source of truth: HolographicTextCore renders the pixels — StatPhase's exact recipe
// (StatPhase is king; every consumer matches it), plus the optional StatPhase arrival-
// ignition layers. HolographicText owns the ambient drift/sweep animation; StatPhase's
// StatNumberView drives the same core from its own arrival cascade + ignition.
//
// Reduce Motion: a static gradient, no drift or sweep.

import SwiftUI

// MARK: - HolographicTextCore — shared pixel recipe (no animation, no state)

/// Pure rendering of the holographic glass treatment. All animation state is injected by
/// the consumer (HolographicText's ambient drift, or StatPhase's cascade), so this view
/// never animates itself. Default output is exactly [glow bloom, core, specular]; the
/// optional ignition inputs add StatPhase's two interleaved layers in their exact z-order:
/// glow bloom → ignite bloom → core → specular → ignite sweep.
struct HolographicTextCore: View {

    let text: String
    var font: Font
    var tracking: CGFloat = 0
    var lineLimit: Int? = nil
    var minScale: CGFloat = 0.6

    // Animation-driven inputs — owned by the consumer.
    let shift:    CGFloat   // gradient drift phase
    let flash:    CGFloat   // specular sweep position
    let glowHigh: Bool      // glow breathe state (high/low)

    /// Multiplier on the colored glow bloom. 1.0 = StatPhase baseline (king); a
    /// consumer can soften its halo without changing the canonical recipe.
    var glowOpacity: CGFloat = 1.0

    // Optional StatPhase arrival-ignition layers. nil → layer omitted, so HolographicText
    // renders the unchanged [glow bloom, core, specular] stack.
    var igniteGlow:   Double?  = nil   // additive bloom opacity, rendered between glow + core
    var igniteSweepX: CGFloat? = nil   // bright one-time sweep, rendered above specular

    /// Lay the ZStack out at its ideal size (StatPhase's single-glyph numeral).
    var fixedSize: Bool = false

    // Recipe constants — felt on device, not tokens. StatPhase's values (it is the
    // canonical look); every consumer matches it.
    private let glowHi: CGFloat = 0.40
    private let glowLo: CGFloat = 0.25
    private let specPrimary:   CGFloat = 0.30
    private let specSecondary: CGFloat = 0.18
    private let glowBleed:     CGFloat = -6

    private var stops: [Gradient.Stop] {
        [
            .init(color: AppColors.accentPrimary,   location: 0.00),
            .init(color: AppColors.accentSecondary, location: 0.25),
            .init(color: AppColors.accentTertiary,  location: 0.50),
            .init(color: AppColors.accentTertiary,  location: 0.65),
            .init(color: AppColors.accentSecondary, location: 0.80),
            .init(color: AppColors.accentPrimary,   location: 1.00),
        ]
    }

    private var gradient: LinearGradient {
        LinearGradient(
            stops: stops,
            startPoint: UnitPoint(x: -shift,       y: -0.2),
            endPoint:   UnitPoint(x: 2.0 - shift,  y:  1.2)
        )
    }

    private var base: some View {
        Text(text)
            .font(font)
            .tracking(tracking)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minScale)
    }

    var body: some View {
        ZStack {
            // Glow bloom — blurred gradient duplicate beneath the glyphs.
            base.foregroundStyle(.clear)
                .overlay { gradient.mask { base } }
                .blur(radius: 12)
                .opacity((glowHigh ? glowHi : glowLo) * glowOpacity)
                .padding(glowBleed)
                .accessibilityHidden(true)

            // Ignition bloom (StatPhase) — additive blurred duplicate that swells once on
            // land, boosting the resting glow to its ignition peak, then settles to 0.
            if let igniteGlow {
                base.foregroundStyle(.clear)
                    .overlay { gradient.mask { base } }
                    .blur(radius: 16)
                    .opacity(igniteGlow)
                    .padding(glowBleed)
                    .accessibilityHidden(true)
            }

            // Core gradient glyphs.
            base.foregroundStyle(.clear)
                .overlay { gradient.mask { base } }
                .accessibilityHidden(true)

            // Specular highlight — light catching the surface.
            base.foregroundStyle(.clear)
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                            location: 0.00),
                            .init(color: .clear,                            location: 0.30),
                            .init(color: .white.opacity(specPrimary),       location: 0.38),
                            .init(color: .white.opacity(0),                 location: 0.42),
                            .init(color: .clear,                            location: 0.50),
                            .init(color: .white.opacity(specSecondary),     location: 0.60),
                            .init(color: .clear,                            location: 0.65),
                            .init(color: .clear,                            location: 1.00),
                        ],
                        startPoint: UnitPoint(x: -0.1, y:  1.0),
                        endPoint:   UnitPoint(x:  1.1, y: -0.25)
                    )
                    .frame(width: 800)
                    .offset(x: flash * 320)
                    .mask { base }
                }
                .clipped()
                .accessibilityHidden(true)

            // Ignition sweep (StatPhase) — one bright band that crosses the glyphs as they
            // seat. Parked off-screen at rest; sweeps across on land.
            if let igniteSweepX {
                base.foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                location: 0.42),
                                .init(color: .white.opacity(0.95),  location: 0.50),
                                .init(color: .clear,                location: 0.58),
                            ],
                            startPoint: UnitPoint(x: -0.1, y:  1.0),
                            endPoint:   UnitPoint(x:  1.1, y: -0.25)
                        )
                        .frame(width: 700)
                        .offset(x: igniteSweepX * 320)
                        .mask { base }
                    }
                    .clipped()
                    .accessibilityHidden(true)
            }
        }
        .fixedSize(horizontal: fixedSize, vertical: fixedSize)
    }
}

// MARK: - HolographicText — self-animating ambient consumer

struct HolographicText: View {

    let text: String
    var font: Font
    var tracking: CGFloat = 0
    var lineLimit: Int? = nil
    var minScale: CGFloat = 0.6
    /// Multiplier on the colored glow bloom (1.0 = StatPhase baseline).
    var glowOpacity: CGFloat = 1.0
    /// Perpetual ambient drift + back-and-forth sweep (matches StatPhase). When false,
    /// the light catches once on appear, then the gradient rests.
    var perpetual: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shift:   CGFloat = -0.35   // gradient drift phase
    @State private var flash:   CGFloat =  2.5    // specular position (parked off right)
    @State private var glowHigh = false
    @State private var started  = false

    var body: some View {
        HolographicTextCore(
            text:      text,
            font:      font,
            tracking:  tracking,
            lineLimit: lineLimit,
            minScale:  minScale,
            shift:     shift,
            flash:     flash,
            glowHigh:  glowHigh,
            glowOpacity: glowOpacity
        )
        .accessibilityElement()
        .accessibilityLabel(text)
        .onAppear(perform: start)
    }

    private func start() {
        guard !started else { return }
        started = true

        guard !reduceMotion else {
            shift = 0.3; glowHigh = true; flash = -0.5   // static, light at rest
            return
        }

        if perpetual {
            // Drift the gradient + breathe the glow + sweep the specular, forever.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                shift = 0.65
                glowHigh = true
            }
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                flash = -0.5
            }
        } else {
            // One light-catch on appear, then rest.
            withAnimation(.easeInOut(duration: 2.0)) { shift = 0.3; glowHigh = true }
            withAnimation(.easeInOut(duration: 0.9)) { flash = -0.5 }
        }
    }
}

#Preview("Holographic") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: 40) {
            HolographicText(text: "1 in 5",
                            font: AppFonts.display(46, weight: .semibold, relativeTo: .largeTitle))
            HolographicText(text: "No less satisfied",
                            font: AppFonts.display(34, weight: .semibold, relativeTo: .largeTitle),
                            lineLimit: 2)
                .frame(maxWidth: 320)
        }
    }
    .preferredColorScheme(.dark)
}
