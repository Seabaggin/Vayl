//
//  ConstellationLayout.swift
//  Vayl
//
//  Pure, deterministic constellation generator for the Desire Map reveal (Model/util layer —
//  no SwiftUI, no state). Maps a match count + a per-couple seed to star positions, connecting
//  edges, and a hero index. Same (count, seed) always yields the same constellation, so a
//  couple's sky is stable, varies across couples, and is unit-testable.
//
//  Positions: a seeded golden-angle (phyllotaxis) spiral, perturbed by the seed (rotation +
//  jitter + slight aspect squash) — even spread, no crowding, any count from 1 to 17.
//  Edges: a minimum spanning tree (always one connected figure, never a web) plus up to two
//  short extra links for richness.
//
//  Feel reference: docs/prototypes/desire-map-constellation-engine.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import SwiftUI

enum ConstellationLayout {

    /// A connecting line, stored **oriented**: `a` is always the endpoint nearer the hero, `b` the
    /// farther one. The reveal draws every line `a → b`, so the constellation always grows *away*
    /// from the hero — see `DesireConstellationView`. Orientation is a property of the figure, not
    /// of any beat's ignition timing, which is what lets one rule cover every reveal mode.
    struct Edge: Equatable {
        /// Hero-nearer endpoint. The draw origin.
        let a: Int
        /// Farther endpoint. The draw target.
        let b: Int
        /// MST depth of `a` from the hero (hero itself is 0). Drives the outward draw stagger, so
        /// lines ripple away from the hero instead of firing in array order.
        let depth: Int
        /// True for the seeded short links added on top of the spanning tree. These are what make a
        /// low-count sky read as a figure rather than a chain (see `extraLengthSpan`).
        let isExtra: Bool
    }

    struct Result: Equatable {
        /// Normalized 0...1 positions inside the field.
        let points: [CGPoint]
        /// Index pairs to connect with a line. Empty when count < 2.
        let edges: [Edge]
        /// Index of the central hero star (the free-reveal star sits here). 0 when count <= 1.
        let heroIndex: Int
    }

    /// Golden angle (137.5°) in radians — the phyllotaxis spoke separation.
    private static let goldenAngle: Double = 2.399963229728653

    // MARK: - Generate

    static func generate(count: Int, seed: UInt64) -> Result {
        guard count > 0 else { return Result(points: [], edges: [], heroIndex: 0) }

        var rng = SeededRNG(seed: seed)
        let rotation = rng.nextUnit() * 2 * .pi
        let squash = 0.84 + rng.nextUnit() * 0.26   // slight aspect variation per seed

        // The constellation's own frame is fixed for the entire reveal ceremony (see
        // DesireRevealView) — nothing about that frame ever resizes across beats. Confining the
        // sky to roughly the frame's upper half, rather than spreading through its full height,
        // means the figure never needs to shift or recentre once lines start drawing; it's already
        // sitting where it will stay. `verticalReach` compresses the spiral's y spread (x keeps its
        // full reach) before recentring higher and clamping near the top half.
        let verticalReach = 0.62
        var points: [CGPoint] = []
        points.reserveCapacity(count)
        for i in 0..<count {
            // A single star (i=0, count=1) would otherwise still get `sqrt(0.5)*0.40 ≈ 0.28` of
            // radius from the `+0.5` phyllotaxis offset — meant to space the *first of many*
            // points off-center, not to displace the *only* point there. With one star that reads
            // as an arbitrary offset instead of a centered hero, and risks the halo drifting toward
            // the frame's edge. Force it to the anchor with no radius.
            let r = count == 1 ? 0 : sqrt((Double(i) + 0.5) / Double(count)) * 0.40
            let theta = Double(i) * goldenAngle + rotation
            let jx = (rng.nextUnit() - 0.5) * 0.05
            let jy = (rng.nextUnit() - 0.5) * 0.05
            let x = 0.5 + r * cos(theta) + jx
            let y = 0.30 + r * sin(theta) * squash * verticalReach + jy
            points.append(CGPoint(
                x: CGFloat(min(0.87, max(0.13, x))),
                y: CGFloat(min(0.50, max(0.09, y)))
            ))
        }

        let heroIndex = nearestToCentroidIndex(points)
        let edges = count > 1 ? buildEdges(points: points, hero: heroIndex, rng: &rng) : []
        return Result(points: points, edges: edges, heroIndex: heroIndex)
    }

    /// Stable per-couple seed from the couple's UUID bytes (FNV-1a). NOT `hashValue` — Swift's
    /// hashing is randomized per process, which would reshuffle the sky every launch.
    static func seed(for coupleId: UUID) -> UInt64 {
        let b = coupleId.uuid
        let bytes: [UInt8] = [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7,
                              b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15]
        var h: UInt64 = 0xcbf29ce484222325            // FNV-1a 64-bit offset basis
        for byte in bytes { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
        return h
    }

    // MARK: - Edges (MST + short extras)

    /// How much longer than the mean tree edge a seeded extra link may be.
    ///
    /// Raised from 1.35 (2026-07-21). At 1.35 the candidate pool is frequently **empty** at low
    /// star counts, so the extras the generator asks for were silently dropped and the figure fell
    /// back to the bare spanning tree — which at 4–6 stars is almost always a *path*, i.e. a chain
    /// that reads as a scribble rather than a constellation. Measured over 12 seeds at 5 stars:
    /// 1.35 left 5 of 12 skies with zero extras; 1.70 left none. Nine-star skies were never
    /// affected (dense enough pool), which is exactly why 5 looked poor next to 9.
    private static let extraLengthSpan: Double = 1.70

    private static func buildEdges(points: [CGPoint], hero: Int, rng: inout SeededRNG) -> [Edge] {
        let n = points.count
        var inTree: Set<Int> = [hero]
        var rest = Set(0..<n)
        rest.remove(hero)
        var edges: [Edge] = []

        // MST depth from the hero, filled as Prim's grows. Prim's already emits (tree-side,
        // new-node) pairs, so every tree edge is born hero-outward — the depth just records it.
        var depth = [Int](repeating: 0, count: n)

        // Prim's minimum spanning tree — guarantees one connected figure with n-1 edges.
        while !rest.isEmpty {
            var best = Double.greatestFiniteMagnitude
            var bi = hero
            var bj = -1
            for i in inTree {
                for j in rest {
                    let d = dist(points[i], points[j])
                    if d < best { best = d; bi = i; bj = j }
                }
            }
            guard bj >= 0 else { break }
            depth[bj] = depth[bi] + 1
            edges.append(Edge(a: bi, b: bj, depth: depth[bi], isExtra: false))
            inTree.insert(bj)
            rest.remove(bj)
        }

        // A couple of short extra links for richness (seeded), never long enough to read as clutter.
        let mean = edges.reduce(0.0) { $0 + dist(points[$1.a], points[$1.b]) } / Double(max(edges.count, 1))
        var have = Set<String>()
        for e in edges { have.insert(key(e.a, e.b)) }
        var candidates: [(d: Double, a: Int, b: Int)] = []
        for i in 0..<n {
            for j in (i + 1)..<n where !have.contains(key(i, j)) {
                let d = dist(points[i], points[j])
                if d < mean * extraLengthSpan { candidates.append((d, i, j)) }
            }
        }
        candidates.sort { $0.d < $1.d }
        let extraCount = n >= 5 ? 1 + Int(rng.nextUnit() * 2) : (n >= 4 ? 1 : 0)
        for c in candidates.prefix(extraCount) {
            // Extras are the one place orientation isn't already decided: they can join two nodes
            // at equal MST depth, where "nearer the hero" is undefined. Tie-break on raw distance
            // to the hero so the rule still resolves. This clause cannot trigger on a tree edge.
            let aIsNearer = depth[c.a] < depth[c.b]
                || (depth[c.a] == depth[c.b] && dist(points[c.a], points[hero]) <= dist(points[c.b], points[hero]))
            let from = aIsNearer ? c.a : c.b
            let to   = aIsNearer ? c.b : c.a
            edges.append(Edge(a: from, b: to, depth: depth[from], isExtra: true))
        }
        return edges
    }

    // MARK: - Helpers

    private static func nearestToCentroidIndex(_ pts: [CGPoint]) -> Int {
        guard pts.count > 1 else { return 0 }
        let cx = pts.reduce(0.0) { $0 + Double($1.x) } / Double(pts.count)
        let cy = pts.reduce(0.0) { $0 + Double($1.y) } / Double(pts.count)
        let centroid = CGPoint(x: CGFloat(cx), y: CGFloat(cy))
        var best = Double.greatestFiniteMagnitude
        var idx = 0
        for (i, p) in pts.enumerated() {
            let d = dist(p, centroid)
            if d < best { best = d; idx = i }
        }
        return idx
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(Double(a.x - b.x), Double(a.y - b.y))
    }

    private static func key(_ i: Int, _ j: Int) -> String {
        "\(min(i, j))-\(max(i, j))"
    }
}

// MARK: - Seeded RNG

/// Tiny deterministic seeded PRNG (SplitMix64). Fast, well-distributed, and reproducible across
/// launches — the property `hashValue` does not give us. File-private to avoid clashing with the
/// identically-named generator in StarVeil.
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Next value in [0, 1) using a 53-bit mantissa.
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}

// MARK: - Debug visual check

#if DEBUG
private struct _ConstellationLayoutDebug: View {
    let count: Int
    let seed: UInt64

    var body: some View {
        GeometryReader { geo in
            let result = ConstellationLayout.generate(count: count, seed: seed)
            ZStack {
                Path { path in
                    for e in result.edges {
                        path.move(to: scaled(result.points[e.a], geo.size))
                        path.addLine(to: scaled(result.points[e.b], geo.size))
                    }
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)

                ForEach(Array(result.points.enumerated()), id: \.offset) { i, p in
                    let isHero = i == result.heroIndex
                    Circle()
                        .fill(isHero ? Color.white : AppColors.spectrumMagenta)
                        .frame(width: isHero ? 11 : 6, height: isHero ? 11 : 6)
                        .shadow(color: AppColors.spectrumPurple.opacity(0.6), radius: 4)
                        .position(scaled(p, geo.size))
                }
            }
        }
    }

    private func scaled(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}

#Preview("Layout — counts (same seed)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            ForEach([1, 2, 5, 9, 14], id: \.self) { c in
                _ConstellationLayoutDebug(count: c, seed: 7)
                    .frame(height: 110)
                    .overlay(alignment: .topLeading) {
                        Text("\(c)").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                    }
            }
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Layout — variety (5 stars, 4 seeds)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            ForEach([UInt64(7), 42, 1000, 999999], id: \.self) { s in
                _ConstellationLayoutDebug(count: 5, seed: s)
                    .frame(height: 110)
            }
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif
