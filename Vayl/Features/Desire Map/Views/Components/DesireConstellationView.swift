//
//  DesireConstellationView.swift
//  Vayl
//
//  The Desire Map reveal constellation with the telegraphed two-seed assembly ceremony.
//  Renders generated star positions + MST edges and, in `.assemble`, lights the stars in the
//  variant's order (each via DesireStarView's two-seed ignite) while the lines draw and a
//  telegraph plays. Reduce Motion lands on the static lit sky.
//
//  Replaces the reveal's use of ConstellationField. Positions/edges come from ConstellationLayout
//  (stable per couple); the variant comes from CeremonyVariant.
//
//  Feel reference: docs/prototypes/desire-map-ceremony-variants.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import SwiftUI

struct DesireConstellationView: View {

    struct Star: Identifiable {
        let id: String
        let point: CGPoint        // normalized 0...1
        let size: CGFloat
        let label: String?
        let isHero: Bool
        let isLocked: Bool
        let cadence: DesireStarView.Cadence
        /// Adjacent ("worth exploring") matches carry a dashed orbit ring once unlocked.
        var isAdjacent: Bool = false
    }

    enum Mode: Equatable {
        case intro      // beat 1: only the hero free star, igniting
        case teasers    // beat 2/3: all shown, hero lit, locked dim, no lines
        case assemble   // revealed (motion): the telegraphed variant ceremony
        case resolved   // revealed (reduce motion / static): all lit, lines drawn, no motion
    }

    let stars: [Star]
    let edges: [ConstellationLayout.Edge]
    let variant: CeremonyVariant
    let mode: Mode
    var onTap: ((String) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed: Set<Int> = []
    @State private var gatherContracted = false
    @State private var sweepProgress: CGFloat = 0
    @State private var sweepVisible = false

    private var heroIndex: Int { stars.firstIndex(where: \.isHero) ?? 0 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if mode == .assemble && !reduceMotion {
                    telegraph(in: geo.size)
                }

                ForEach(Array(edges.enumerated()), id: \.offset) { index, edge in
                    line(edge, index: index, in: geo.size)
                }

                ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                    if revealed.contains(index) {
                        DesireStarView(
                            size: star.size,
                            state: starState(index, star),
                            label: showsLabel(star) ? star.label : nil,
                            cadence: star.cadence,
                            ignites: ignites(index),
                            ring: (star.isAdjacent && !star.isLocked) ? .dashed : .none
                        )
                        .position(x: star.point.x * geo.size.width,
                                  y: star.point.y * geo.size.height)
                        .onTapGesture { onTap?(star.id) }
                    }
                }
            }
        }
        .task(id: mode) { await applyMode() }
    }

    // MARK: - Per-star rendering

    /// Only the hero plays the two-seed ignite entrance during `.intro` — it's the one star
    /// growing brighter in a system that's already fully present; every other star is simply
    /// there from the start, dim and static, not arriving. During `.assemble` every star ignites
    /// as the telegraphed ceremony reveals it, which is unchanged.
    private func ignites(_ index: Int) -> Bool {
        switch mode {
        case .intro:              return index == heroIndex
        case .assemble:           return true
        case .teasers, .resolved: return false
        }
    }

    private func starState(_ index: Int, _ star: Star) -> DesireStarView.StarState {
        ((mode == .teasers || mode == .intro) && star.isLocked) ? .dim : .lit
    }

    private func showsLabel(_ star: Star) -> Bool {
        guard star.label != nil, !star.isLocked else { return false }
        return star.isHero || stars.count <= 6
    }

    // MARK: - Lines

    // One view structure for every mode — no branch swap on `mode`. Earlier this switched between
    // two structurally different views (a straight-line plain stroke for `.teasers`, a curved
    // blurred stroke for everything else); swapping `if`/`else` branches when `mode` changed from
    // `.intro` to `.teasers` meant SwiftUI couldn't interpolate across the swap, so the beat1→beat2
    // transition — the one most visibly hit in practice — popped the lines in instantly instead of
    // fading them. Keeping one view means `.animation(value: drawn)` always has a continuous
    // property change to animate, at every mode transition, not just within a single mode's run.
    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, index: Int, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        let path = Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        path
            .stroke(Color.white.opacity(drawn ? lineOpacity : 0), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
            .animation(lineAnimation(index: index, edge: edge).reduceMotionSafe, value: drawn)
    }

    /// Per-mode fade timing. Teasers stagger by the edge's own index in `edges` —
    /// ConstellationLayout.buildEdges grows its MST outward from the hero (nearest-neighbor-first),
    /// so that array order already radiates outward from the hero star, reading as the connection
    /// spreading outward rather than every line fading at once. Assemble uses a smaller, seeded
    /// per-edge jitter instead, since its own ignition schedule already provides the spread.
    private func lineAnimation(index: Int, edge: ConstellationLayout.Edge) -> Animation {
        switch mode {
        case .teasers:
            // Was AppAnimation.enter (0.4s ease-out) — ease-out starts fast then decelerates,
            // which read as an abrupt pop rather than a fade. desireLineCondense ramps in gently
            // (ease-in-out) instead, matching the softer settle already used elsewhere on this
            // screen.
            return AppAnimation.desireLineCondense.delay(Double(index) * AppAnimation.desireBeatStaggerStep)
        case .assemble:
            return AppAnimation.desireLineCondense.delay(edgeJitter(edge) * AppAnimation.desireLineJitterSpan)
        case .intro, .resolved:
            return AppAnimation.desireLineCondense
        }
    }

    /// Deterministic 0...1 unit derived from the edge's endpoints, used to offset each line's
    /// condense so simultaneous ignitions don't settle in mechanical lockstep.
    private func edgeJitter(_ edge: ConstellationLayout.Edge) -> Double {
        var hasher = Hasher()
        hasher.combine(min(edge.a, edge.b))
        hasher.combine(max(edge.a, edge.b))
        return Double(hasher.finalize() & 0xFF) / 255.0
    }

    private func lineDrawn(_ edge: ConstellationLayout.Edge) -> Bool {
        switch mode {
        case .resolved:  return true
        case .assemble:  return revealed.contains(edge.a) && revealed.contains(edge.b)
        case .teasers:   return true
        case .intro:     return false
        }
    }

    /// Teaser-beat lines read as a hint of connection, not a confirmed one — dimmer than
    /// the confident weight used once the sky is actually lit (resolved / mid-assembly).
    private var lineOpacity: Double {
        mode == .teasers ? 0.30 : 0.68
    }

    // MARK: - Telegraph

    @ViewBuilder
    private func telegraph(in size: CGSize) -> some View {
        switch variant.telegraph {
        case .gather:
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.22), AppColors.spectrumMagenta.opacity(0.12), .clear],
                    center: .center, startRadius: 0, endRadius: size.width * 0.24))
                .frame(width: size.width * 0.48, height: size.width * 0.48)
                .scaleEffect(gatherContracted ? 0.2 : 1.7)
                .opacity(gatherContracted ? 0 : 0.5)
                .blur(radius: 6)
                .position(x: size.width / 2, y: size.height * 0.46)
                .allowsHitTesting(false)
        case .sweep:
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, Color.white.opacity(0.16), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 60, height: size.height * 1.4)
                .blur(radius: 8)
                .rotationEffect(.degrees(-12))
                .position(x: (sweepProgress * 1.4 - 0.2) * size.width, y: size.height / 2)
                .opacity(sweepVisible ? 0.85 : 0)
                .allowsHitTesting(false)
        case .none:
            EmptyView()
        }
    }

    private func scaled(_ point: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    // MARK: - Assembly timeline

    private func applyMode() async {
        sweepVisible = false
        gatherContracted = false
        sweepProgress = 0
        switch mode {
        case .intro, .teasers, .resolved:
            // The whole sky is present from beat1 onward — the hero is already in its rightful
            // place among the rest, simply lit while they sit dim. It ignites there in place;
            // it doesn't arrive alone and get a system overlaid onto it later.
            revealed = Set(stars.indices)
        case .assemble:
            revealed = []
            await runAssembly()
        }
    }

    private func runAssembly() async {
        guard !stars.isEmpty else { return }

        switch variant.telegraph {
        case .gather:
            withAnimation(AppAnimation.desireGatherPulse) { gatherContracted = true }
            try? await Task.sleep(for: .seconds(AppAnimation.desireGatherLead))
        case .sweep:
            sweepVisible = true
            withAnimation(AppAnimation.desireSweepBand) { sweepProgress = 1 }
        case .none:
            break
        }
        if Task.isCancelled { return }

        let schedule = variant.schedule(points: stars.map(\.point), heroIndex: heroIndex)
            .sorted { $0.delay < $1.delay }
        var elapsed = 0.0
        for step in schedule {
            let wait = step.delay - elapsed
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            if Task.isCancelled { return }
            elapsed = step.delay
            revealed.insert(step.index)
        }
        sweepVisible = false
    }
}
