//
//  DesireStarView.swift
//  Vayl
//
//  Reusable warm star atom for the Desire Map rater sky and reveal constellation.
//  Mirrors the ConstellationNode recipe from Learn but uses the warm magenta-led
//  desire colorway (magenta → purple, never cyan).
//
//  Do NOT wrap in .drawingGroup() — the sparkle keyframeAnimator must re-render
//  only its own layer, and the resting cross + core are cheap enough to skip rasterizing.
//

import SwiftUI

// MARK: - Supporting types

extension DesireStarView {
    enum StarState { case dim, lit }
    enum Cadence { case free, locked }
}

private struct SparkleValues {
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
    var rotation: Double = 0.0
}

// MARK: - DesireStarView

/// A single warm desire star.
///
/// `size` is the core circle diameter — all other dimensions derive from it.
/// Typical ranges: 10–18pt for rater sky accumulation; 28–40pt for reveal hero.
struct DesireStarView: View {

    var size: CGFloat
    var state: StarState = .lit
    var label: String? = nil
    var cadence: Cadence = .free

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkleTrigger: Int = 0

    // MARK: Derived geometry (all proportional to size)

    private var haloSize: CGFloat  { size * 6.0  }
    private var glowSize: CGFloat  { size * 3.2  }
    private var coreSize: CGFloat  { size        }
    private var crossLen: CGFloat  { size * 3.5  }
    private var crossW: CGFloat    { max(0.8, size * 0.075) }
    private var sparkleSize: CGFloat { size * 2.2 }

    private var glowOpacity: Double   { state == .lit ? 1.0 : 0.18 }
    private var coreOpacity: Double   { state == .lit ? 1.0 : 0.28 }
    private var crossOpacity: Double  { state == .lit ? 0.38 : 0.20 }

    // MARK: Body

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                haloLayer
                glowLayer
                coreLayer
                crossLayer
                if state == .lit {
                    sparkleLayer
                }
            }
            .frame(width: haloSize, height: haloSize)

            if let label {
                Text(label)
                    .font(AppFonts.body(10, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.85), radius: 2)
                    .shadow(color: AppColors.spectrumMagenta.opacity(0.55), radius: 5)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: haloSize)
            }
        }
        .task(id: "\(state == .lit)-\(!reduceMotion)") {
            guard !reduceMotion, state == .lit else { return }
            await sparkleLoop()
        }
    }

    // MARK: Layers

    private var haloLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppColors.spectrumMagenta.opacity(0.16),
                        AppColors.spectrumPurple.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: haloSize / 2
                )
            )
            .frame(width: haloSize, height: haloSize)
            .blur(radius: 17)
    }

    private var glowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.85),
                        AppColors.spectrumMagenta.opacity(0.42),
                        AppColors.spectrumPurple.opacity(0.13),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowSize / 2
                )
            )
            .frame(width: glowSize, height: glowSize)
            .blur(radius: 5)
            .opacity(glowOpacity)
    }

    private var coreLayer: some View {
        Circle()
            .fill(Color.white)
            .frame(width: coreSize, height: coreSize)
            .shadow(color: Color.white,                                   radius: 3)
            .shadow(color: AppColors.spectrumMagenta.opacity(0.82),       radius: 7)
            .shadow(color: AppColors.spectrumPurple.opacity(0.42),        radius: 15)
            .opacity(coreOpacity)
    }

    // Two thin rectangles (H + V) with a white gradient that fades at both ends.
    // This is the star's permanent character — present even at rest.
    private var crossLayer: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: crossLen, height: crossW)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: crossW, height: crossLen)
        }
        .opacity(crossOpacity)
    }

    private var sparkleLayer: some View {
        SparkleStar()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: sparkleSize / 2
                )
            )
            .frame(width: sparkleSize, height: sparkleSize)
            .keyframeAnimator(
                initialValue: SparkleValues(),
                trigger: sparkleTrigger
            ) { content, values in
                content
                    .scaleEffect(values.scale)
                    .opacity(values.opacity)
                    .rotationEffect(.degrees(values.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(1.0, duration: AppAnimation.desireSparkleDuration * 0.45)
                    CubicKeyframe(0.55, duration: AppAnimation.desireSparkleDuration * 0.55)
                }
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(1.0, duration: AppAnimation.desireSparkleDuration * 0.35)
                    CubicKeyframe(0.0, duration: AppAnimation.desireSparkleDuration * 0.65)
                }
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(12.0, duration: AppAnimation.desireSparkleDuration)
                }
            }
    }

    // MARK: Sparkle loop

    private func sparkleLoop() async {
        let baseRate = cadence == .free
            ? AppAnimation.desireSparkleFreeRate
            : AppAnimation.desireSparkleLockedRate
        while !Task.isCancelled {
            let factor = Double.random(in: 0.55...1.6)
            let wait = baseRate * factor
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            sparkleTrigger += 1
        }
    }
}

// MARK: - Previews

#Preview("Lit — free cadence") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.xxl) {
            DesireStarView(size: 20, state: .lit, label: "Shared space", cadence: .free)
            DesireStarView(size: 14, state: .lit, cadence: .free)
            DesireStarView(size: 10, state: .dim, cadence: .locked)
        }
    }
}

#Preview("Sizes — lit vs dim") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.lg) {
                Text("Lit").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                DesireStarView(size: 32, state: .lit, cadence: .free)
                DesireStarView(size: 18, state: .lit, cadence: .free)
                DesireStarView(size: 12, state: .lit, cadence: .free)
            }
            VStack(spacing: AppSpacing.lg) {
                Text("Dim").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                DesireStarView(size: 32, state: .dim, cadence: .locked)
                DesireStarView(size: 18, state: .dim, cadence: .locked)
                DesireStarView(size: 12, state: .dim, cadence: .locked)
            }
        }
    }
}

#Preview("Locked cadence") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireStarView(size: 24, state: .lit, label: "Rare spark", cadence: .locked)
    }
}
