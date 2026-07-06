//
//  CeremonyVariant.swift
//  Vayl
//
//  The three telegraphed Desire Map reveal ceremonies, picked deterministically by the couple
//  (so a new partner or a watched friend gets a different one). The variant only sets the
//  telegraph and the lighting order of the assembly — it composes with any match count and any
//  layout seed. Pure logic, no SwiftUI.
//
//  Feel reference: docs/prototypes/desire-map-ceremony-variants.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import CoreGraphics
import Foundation

enum CeremonyVariant: Int, CaseIterable {
    case gather        // stills, pulls light to center, hero forms, the rest radiate outward
    case sweep         // a band passes; pairs snap together in its wake, in spatial order
    case constellate   // all at once — every star merges simultaneously

    /// Deterministic per couple. Same `coupleId` always resolves the same variant (FNV-1a seed,
    /// not `hashValue`, so it survives relaunches). Unpaired falls back to `.gather`.
    static func resolve(coupleId: UUID?) -> CeremonyVariant {
        guard let coupleId else { return .gather }
        let seed = ConstellationLayout.seed(for: coupleId)
        let index = Int(seed % UInt64(CeremonyVariant.allCases.count))
        return CeremonyVariant(rawValue: index) ?? .gather
    }

    enum Telegraph: Equatable { case gather, sweep, none }

    var telegraph: Telegraph {
        switch self {
        case .gather:      return .gather
        case .sweep:       return .sweep
        case .constellate: return .none
        }
    }

    /// Each star index paired with its delay (seconds) from assembly start. The constellation
    /// lights stars in this order; a line draws once both its endpoints have lit.
    func schedule(points: [CGPoint], heroIndex: Int) -> [(index: Int, delay: Double)] {
        let count = points.count
        guard count > 0 else { return [] }

        switch self {
        case .gather:
            // Hero first, then the rest from the center outward.
            let centroid = centroid(of: points)
            let others = (0..<count)
                .filter { $0 != heroIndex }
                .sorted { distance(points[$0], centroid) < distance(points[$1], centroid) }
            let per = stagger(for: count)
            var result: [(index: Int, delay: Double)] = [(heroIndex, 0)]
            for (k, i) in others.enumerated() {
                result.append((i, AppAnimation.desireCeremonyHeroLead + Double(k) * per))
            }
            return result

        case .sweep:
            // Stars light in spatial order along the sweep, timed to the band's pass.
            let xs = points.map { Double($0.x) }
            let minX = xs.min() ?? 0
            let maxX = xs.max() ?? 1
            let span = max(0.0001, maxX - minX)
            return (0..<count)
                .sorted { points[$0].x < points[$1].x }
                .map { i in
                    let fraction = (Double(points[i].x) - minX) / span
                    return (index: i, delay: fraction * AppAnimation.desireSweepDuration)
                }

        case .constellate:
            // Simultaneous — every star merges at once.
            return (0..<count).map { (index: $0, delay: 0) }
        }
    }

    // MARK: - Helpers

    private func stagger(for count: Int) -> Double {
        let raw = AppAnimation.desireCeremonyBudget / Double(max(count, 1))
        return min(AppAnimation.desireCeremonyStaggerMax,
                   max(AppAnimation.desireCeremonyStaggerMin, raw))
    }

    private func centroid(of points: [CGPoint]) -> CGPoint {
        let n = Double(max(points.count, 1))
        let cx = points.reduce(0.0) { $0 + Double($1.x) } / n
        let cy = points.reduce(0.0) { $0 + Double($1.y) } / n
        return CGPoint(x: cx, y: cy)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(Double(a.x - b.x), Double(a.y - b.y))
    }
}
