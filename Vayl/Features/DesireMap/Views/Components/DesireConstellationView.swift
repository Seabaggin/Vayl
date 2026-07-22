//
//  DesireConstellationView.swift
//  Vayl
//
//  The Desire Map reveal constellation. Stars cascade into an empty sky hero-outward, then the
//  lines DRAW themselves outward from the hero — a trim, never an opacity fade. Post-unlock, the
//  telegraphed variant ceremony re-lights the whole sky with the two-seed ignite.
//
//  Positions/edges come from ConstellationLayout (stable per couple); the variant from
//  CeremonyVariant. Edges arrive already oriented hero-outward (`Edge.a` is the nearer endpoint),
//  so this view never has to decide a direction — it just draws `a → b`.
//
//  Spec: plans/001-desire-reveal-constellation-sequence.md
//  Feel reference: docs/mockups/desire-reveal-sequence.html
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
        /// beat 1 — the sky is empty and fills: stars cascade in dim, hero-outward, then the lines
        /// draw outward. Nothing is lit yet; the hero's own reveal is a later beat.
        case ceremony
        /// beat 2/3 — the ceremony's terminal state, landed instantly. Also where a tap-to-skip
        /// arrives, which is why skipping needs no separate code path.
        case settled
        /// revealed (motion) — the telegraphed variant ceremony: every star ignites two-seed.
        case assemble
        /// revealed (Reduce Motion / static) — all lit, lines drawn, no motion.
        case resolved
    }

    let stars: [Star]
    let edges: [ConstellationLayout.Edge]
    let variant: CeremonyVariant
    let mode: Mode
    /// Whether the free (hero) match has opened yet. False through the whole beat-1 ceremony —
    /// the hero sits dim among the rest until its own moment, so the open reads as a gift rather
    /// than as the one star that was always brighter.
    var heroRevealed: Bool = false
    var onTap: ((String) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Stars that have arrived in the sky. During `.ceremony` this fills on a hero-outward
    /// schedule; every other mode lands it complete.
    @State private var present: Set<Int> = []
    /// Armed once the star cascade has settled — every line's trim animates 0 → 1 off this,
    /// delayed by its own MST depth so the figure draws outward.
    @State private var linesArmed = false
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
                    line(edge, ordinal: drawOrdinal[index], in: geo.size)
                }

                ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                    if present.contains(index) {
                        starView(index, star)
                            .position(x: star.point.x * geo.size.width,
                                      y: star.point.y * geo.size.height)
                    }
                }
            }
        }
        .task(id: taskKey) { await applyMode() }
    }

    /// Re-runs the timeline when the mode changes *or* when the hero opens — the latter so the
    /// hero's two-seed entrance is armed at the right moment rather than on first mount.
    private var taskKey: String { "\(mode)-\(heroRevealed)" }

    // MARK: - Per-star rendering

    @ViewBuilder
    private func starView(_ index: Int, _ star: Star) -> some View {
        DesireStarView(
            size: star.size,
            state: starState(index, star),
            label: showsLabel(star) ? star.label : nil,
            cadence: star.cadence,
            entrance: entrance(index),
            ring: (star.isAdjacent && !star.isLocked) ? .dashed : .none
        )
        // Remounting on the hero's open is what lets its two-seed entrance play *then*, instead of
        // only on first appearance. Non-hero stars keep a stable identity so the cascade isn't
        // restarted underneath them.
        .id(star.isHero ? "\(star.id)-\(heroRevealed)" : star.id)
        .onTapGesture { onTap?(star.id) }
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(star.isLocked ? "Locked desire" : (star.label ?? "Desire"))
        .accessibilityAction { onTap?(star.id) }
    }

    /// The cascade uses the plain bloom; the hero's own moment and the post-unlock ceremony use the
    /// two-seed convergence. See `DesireStarView.Entrance` for why that distinction is load-bearing.
    private func entrance(_ index: Int) -> DesireStarView.Entrance {
        switch mode {
        case .ceremony:
            return index == heroIndex && heroRevealed ? .twoSeed : .bloom
        case .assemble:
            return .twoSeed
        case .settled:
            // Only the hero animates here — it opens during beat 2, after the sky already settled.
            return index == heroIndex && heroRevealed ? .twoSeed : .none
        case .resolved:
            return .none
        }
    }

    /// Through the ceremony every star is dim, hero included — the sky arrives locked and *then*
    /// one star opens. Post-unlock, everything is lit.
    private func starState(_ index: Int, _ star: Star) -> DesireStarView.StarState {
        switch mode {
        case .ceremony, .settled:
            if index == heroIndex { return heroRevealed ? .lit : .dim }
            return star.isLocked ? .dim : .lit
        case .assemble, .resolved:
            return .lit
        }
    }

    private func showsLabel(_ star: Star) -> Bool {
        guard star.label != nil, !star.isLocked else { return false }
        // The hero carries no name until it opens — a name on a dim star would give away the one
        // thing the reveal is holding back.
        if star.isHero { return heroRevealed }
        return stars.count <= 6
    }

    // MARK: - Lines

    /// One view structure for every mode — no branch swap on `mode`. Earlier this switched between
    /// two structurally different views, and swapping `if`/`else` branches when `mode` changed meant
    /// SwiftUI couldn't interpolate across the swap, so the transition popped instead of animating.
    /// Keeping one structure means `.animation(value:)` always has a continuous change to animate.
    ///
    /// The line is a **trim**, not a fade. `Edge.a` is guaranteed to be the hero-nearer endpoint
    /// (ConstellationLayout orients every edge), so `trim(from: 0, to:)` always grows the line away
    /// from the hero — in every mode, with no per-mode special case and no dependence on which star
    /// happened to light first.
    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, ordinal: Int, in size: CGSize) -> some View {
        if let from = point(edge.a, size), let to = point(edge.b, size) {
            let progress: CGFloat = lineDrawn(edge) ? 1 : 0
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .trim(from: 0, to: progress)
            .stroke(Color.white.opacity(lineOpacity), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
            .animation(lineAnimation(edge, ordinal: ordinal).reduceMotionSafe, value: progress)
        }
    }

    /// Per-**line** draw stagger (`drawOrdinal`), NOT per-depth. A hero-centred MST puts most edges
    /// at depth 0 — 4 of 6 lines in a typical 5-star sky — so staggering by depth alone fired those
    /// four at the same instant and the figure appeared to draw all at once. Ordering every edge
    /// individually (depth first, so the flow is still outward; then a stable tiebreak) guarantees
    /// no two lines ever start together.
    /// `.assemble` keeps its seeded per-edge jitter — its own ignition schedule already supplies the
    /// spread, and an ordinal ramp on top would double-count.
    private func lineAnimation(_ edge: ConstellationLayout.Edge, ordinal: Int) -> Animation {
        switch mode {
        case .ceremony, .settled:
            return AppAnimation.desireLineDraw
                .delay(Double(ordinal) * AppAnimation.desireLineDrawStep)
        case .assemble:
            return AppAnimation.desireLineDraw
                .delay(edgeJitter(edge) * AppAnimation.desireLineJitterSpan)
        case .resolved:
            return AppAnimation.desireLineDraw
        }
    }

    /// Maps each edge (by its index in `edges`) to its position in the draw sequence: sorted by MST
    /// depth so lines still ripple outward from the hero, then by array order as a stable tiebreak
    /// so same-depth lines draw one after another instead of together. `buildEdges` emits the MST
    /// nearest-first and appends extras last, so that array order already reads outward within a ring.
    private var drawOrdinal: [Int] {
        let sorted = edges.indices.sorted { a, b in
            edges[a].depth != edges[b].depth ? edges[a].depth < edges[b].depth : a < b
        }
        var ordinal = [Int](repeating: 0, count: edges.count)
        for (position, index) in sorted.enumerated() { ordinal[index] = position }
        return ordinal
    }

    /// Deterministic 0...1 unit derived from the edge's endpoints, so simultaneous ignitions don't
    /// settle in mechanical lockstep.
    private func edgeJitter(_ edge: ConstellationLayout.Edge) -> Double {
        var hasher = Hasher()
        hasher.combine(min(edge.a, edge.b))
        hasher.combine(max(edge.a, edge.b))
        return Double(hasher.finalize() & 0xFF) / 255.0
    }

    private func lineDrawn(_ edge: ConstellationLayout.Edge) -> Bool {
        switch mode {
        case .resolved, .settled:
            return true
        case .ceremony:
            return linesArmed
        case .assemble:
            // Lines follow the stars: a line draws once both its endpoints exist. Deliberately not
            // the reverse (arrival igniting the far star) — a chain reaction would force the MST's
            // topology onto every variant and make `.constellate`'s simultaneous merge unexpressible.
            return present.contains(edge.a) && present.contains(edge.b)
        }
    }

    /// Lines are the FLOOR of the hierarchy — structure, beneath the nodes they connect. Lowered
    /// from 0.68 (2026-07-21): at 0.68 a line outshone a locked star and the wires dominated the
    /// figure. "Confident" means fully-drawn, not bright — the line stays one continuous stroke,
    /// just quiet. Still no dim "hint of connection" state; a line is either drawn or it isn't.
    private var lineOpacity: Double {
        #if DEBUG
        DesireSequenceTuning.shared.lineOpacity
        #else
        0.42
        #endif
    }

    /// Guards against an index that outruns `stars` — `edges` index into the layout's full point
    /// list, and a placement gap would otherwise crash rather than simply omit a line.
    private func point(_ index: Int, _ size: CGSize) -> CGPoint? {
        guard stars.indices.contains(index) else { return nil }
        return scaled(stars[index].point, size)
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

    // MARK: - Timelines

    private func applyMode() async {
        sweepVisible = false
        gatherContracted = false
        sweepProgress = 0

        switch mode {
        case .settled, .resolved:
            // Terminal state. This is also exactly where a tap-to-skip lands, which is why skipping
            // needs no separate branch: the parent moves the mode on, and the sky is simply done.
            present = Set(stars.indices)
            linesArmed = true

        case .ceremony:
            if reduceMotion {
                present = Set(stars.indices)
                linesArmed = true
                return
            }
            await runCascade()

        case .assemble:
            present = []
            linesArmed = false
            await runAssembly()
        }
    }

    /// beat 1 — stars bloom in hero-outward, then (after a hold) the lines draw outward. Both
    /// orderings are rooted at the hero so the two halves read as one continuous outward motion
    /// rather than two unrelated events.
    private func runCascade() async {
        guard !stars.isEmpty else { return }
        linesArmed = false
        present = []

        let hero = stars.indices.contains(heroIndex) ? stars[heroIndex].point : CGPoint(x: 0.5, y: 0.5)
        let order = stars.indices.sorted {
            distance(stars[$0].point, hero) < distance(stars[$1].point, hero)
        }

        for (step, index) in order.enumerated() {
            if step > 0 {
                try? await Task.sleep(for: .seconds(AppAnimation.desireStarCascadeStep))
            }
            if Task.isCancelled { return }
            present.insert(index)
        }

        // Let the last star's bloom finish before the shape starts asserting itself.
        try? await Task.sleep(for: .seconds(AppAnimation.desireHoldStarsToLines))
        if Task.isCancelled { return }
        linesArmed = true
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
            present.insert(step.index)
        }
        sweepVisible = false
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(Double(a.x - b.x), Double(a.y - b.y))
    }
}
