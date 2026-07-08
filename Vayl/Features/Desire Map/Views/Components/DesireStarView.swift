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
    /// Alignment marker: adjacent ("worth exploring") stars carry a dashed orbit ring
    /// so mutual and adjacent read differently on the unlocked sky.
    enum RingStyle { case none, dashed }
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
    var label: String?
    var cadence: Cadence = .free
    /// When true, the star plays the two-seed ignite entrance once on appear (your purple + their
    /// magenta converging into one bright star). Default false — renders lit immediately.
    var ignites: Bool = false
    /// Dashed orbit ring for adjacent ("worth exploring") matches on the unlocked sky.
    var ring: RingStyle = .none

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkleTrigger: Int = 0
    /// Entrance state. Initialized from `ignites` so non-igniting stars render at rest with no
    /// first-frame flash; igniting stars start collapsed and bloom in `startEntrance()`.
    @State private var bloomed: Bool
    @State private var seedsMerged: Bool

    init(size: CGFloat, state: StarState = .lit, label: String? = nil, cadence: Cadence = .free, ignites: Bool = false, ring: RingStyle = .none) {
        self.size = size
        self.state = state
        self.label = label
        self.cadence = cadence
        self.ignites = ignites
        self.ring = ring
        _bloomed = State(initialValue: !ignites)
        _seedsMerged = State(initialValue: !ignites)
    }

    // MARK: Derived geometry (all proportional to size)
    //
    // Ground truth: desire-map-flow-family.html `.snode`. There the reference dimension is
    // the GLOW (--g); the core is a pinpoint (~0.09–0.12 of the glow — hero 5px on a 54px
    // glow), the cross spans ~1.3–1.6 of the glow at 1px, and the halo is 2.2× the glow.
    // `size` here stays the caller-facing scale knob (glow = size * 3.2), but every layer
    // derives from the glow so the star reads as a spark in light, never a white disc.

    private var glowSize: CGFloat { size * 3.2 }
    private var haloSize: CGFloat { glowSize * 2.2 }
    private var coreSize: CGFloat { glowSize * 0.12 }
    private var crossLen: CGFloat { glowSize * 1.4 }
    private var crossW: CGFloat { 1.0 }
    private var sparkleSize: CGFloat { size * 2.2 }
    private var ringSize: CGFloat { glowSize * 0.92 }
    private var labelWidth: CGFloat { max(haloSize, 120) }

    private var glowOpacity: Double { state == .lit ? 1.0 : 0.18 }
    private var coreOpacity: Double { state == .lit ? 1.0 : 0.28 }
    private var crossOpacity: Double { state == .lit ? 0.38 : 0.20 }

    // MARK: Body

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Two-seed entrance — a cool (you) and warm (them) point converging as the star
                // ignites. Present only while the entrance plays; otherwise no seeds, instant bloom.
                if playsEntrance {
                    seedView(color: AppColors.spectrumPurple, dx: -seedOffset)
                    seedView(color: AppColors.spectrumMagenta, dx: seedOffset)
                }

                ZStack {
                    haloLayer
                    glowLayer
                    if ring == .dashed {
                        ringLayer
                    }
                    coreLayer
                    crossLayer
                    if state == .lit {
                        sparkleLayer
                    }
                }
                .scaleEffect(bloomed ? 1 : entranceStartScale)
                .opacity(bloomed ? 1 : 0)
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
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: labelWidth)
                    .opacity(bloomed ? 1 : 0)
            }
        }
        // A star with a label is visually taller than one without (VStack + label height), but
        // the constellation lines and `.position(...)` in DesireConstellationView must always
        // target the GLYPH's centre, not the glyph+label group's centre. Pinning the reported
        // frame to just the glyph's own haloSize×haloSize box, top-aligned, keeps the label a
        // pure visual overflow below that box (SwiftUI doesn't clip un-clipped overflow) without
        // it ever shifting what external `.position(...)` calls centre on. Without this, any
        // labeled star (currently: the hero) renders visibly offset from its own connecting line.
        .frame(width: haloSize, height: haloSize, alignment: .top)
        .onAppear { startEntrance() }
        .task(id: "\(state == .lit)-\(!reduceMotion)") {
            guard !AppAnimation.ambientMotionDisabled, state == .lit else { return }
            await sparkleLoop()
        }
    }

    // MARK: Entrance (two-seed ignite)

    private var playsEntrance: Bool { ignites && state == .lit && !reduceMotion }

    private var seedDiameter: CGFloat { glowSize * 0.5 }
    private var seedOffset: CGFloat { glowSize * 0.45 }
    private var entranceStartScale: CGFloat { 0.2 }
    private var seedRestOpacity: Double { 0.6 }

    /// A faint pre-merge seed point (cool = you, warm = them). Drifts to center and fades as the
    /// star blooms. Geometry is proportional to `size`.
    private func seedView(color: Color, dx: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(0.95), color.opacity(0.22), .clear],
                center: .center, startRadius: 0, endRadius: seedDiameter / 2))
            .frame(width: seedDiameter, height: seedDiameter)
            .blur(radius: 5)
            .scaleEffect(seedsMerged ? 0.35 : 1)
            .offset(x: seedsMerged ? 0 : dx, y: seedsMerged ? 0 : dx * 0.35)
            .opacity(seedsMerged ? 0 : seedRestOpacity)
    }

    /// Drives the entrance on appear. Igniting stars converge two seeds and bloom; everything
    /// else (no ignite, or Reduce Motion) lands at rest instantly.
    private func startEntrance() {
        guard ignites else { return }              // already at rest (bloomed initialized true)
        guard playsEntrance else {                 // Reduce Motion / not lit: skip the ceremony
            bloomed = true
            seedsMerged = true
            return
        }
        withAnimation(AppAnimation.desireStarSeedDrift) { seedsMerged = true }
        withAnimation(AppAnimation.desireStarMergeSettle.delay(AppAnimation.desireStarMergeBloomDelay)) { bloomed = true }
        Task {
            try? await Task.sleep(for: .seconds(AppAnimation.desireStarMergeBloomDelay * 2))
            sparkleTrigger += 1
        }
    }

    // MARK: Layers

    // Gradient stops mirror the mockup's radial-gradients exactly (shalo / sglow).
    private var haloLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: AppColors.spectrumMagenta.opacity(0.14), location: 0.0),
                        .init(color: AppColors.spectrumPurple.opacity(0.07), location: 0.54),
                        .init(color: .clear, location: 0.76)
                    ]),
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
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.85), location: 0.0),
                        .init(color: AppColors.spectrumMagenta.opacity(0.42), location: 0.28),
                        .init(color: AppColors.spectrumPurple.opacity(0.14), location: 0.60),
                        .init(color: .clear, location: 0.80)
                    ]),
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
            .shadow(color: Color.white, radius: 3)
            .shadow(color: AppColors.spectrumMagenta.opacity(0.82), radius: 7)
            .shadow(color: AppColors.spectrumPurple.opacity(0.42), radius: 15)
            .opacity(coreOpacity)
    }

    // Dashed orbit ring — the adjacent ("worth exploring") marker on the unlocked sky.
    private var ringLayer: some View {
        Circle()
            .stroke(
                Color.white.opacity(state == .lit ? 0.30 : 0.14),
                style: StrokeStyle(lineWidth: 0.9, dash: [2.5, 3.5])
            )
            .frame(width: ringSize, height: ringSize)
    }

    // Two thin rectangles (H + V) with a white gradient that fades at both ends.
    // This is the star's permanent character — present even at rest.
    private var crossLayer: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.62), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: crossLen, height: crossW)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.62), Color.clear],
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
            guard !Task.isCancelled, !AppAnimation.ambientMotionDisabled else { return }
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

#Preview("Two-seed ignite") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.xl) {
            DesireStarView(size: 22, state: .lit, label: "Opening Up", cadence: .free, ignites: true)
            DesireStarView(size: 15, state: .lit, label: "Shared", cadence: .free, ignites: true)
        }
    }
    .preferredColorScheme(.dark)
}
