//
//  TopoField.swift
//  Vayl
//

// Features/Onboarding/Canvas/TableSurface/TopoField.swift

import SwiftUI

/// Precomputed topo-line geometry for TableSurfaceView.
///
/// The topo field's base shape (62 fbm/domain-warped contour lines, ~600 sample
/// rows each) is fully determined by the canvas size — none of the animated
/// inputs (fade, rimBurst, forgeEnergy, dissolution) change the underlying
/// noise. Evaluating it inside the Canvas closure meant ~1.4M sin/cos calls on
/// the main thread for EVERY animated frame the table was part of; that cost is
/// what made table fades, rim bursts, and the forge oscillation drop frames.
///
/// This cache evaluates the noise once per canvas size and stores:
///   • per-line base sample points (pre-warp, pre-sway) for the animated draws
///   • fully built resting Paths for the common no-warp/no-forge case
///
/// Thread-safety: Canvas rendering closures are not formally actor-isolated, so
/// access is serialized with a lock rather than assuming @MainActor.
final class TopoField: @unchecked Sendable {

    static let shared = TopoField()

    /// One sampled point of a topo line, before any animated displacement.
    /// `depthT` is cached because the forge sway and clipping both need it.
    struct Sample {
        let x:      CGFloat
        let y:      CGFloat
        let depthT: CGFloat
    }

    /// One contour line: static paint attributes + its base samples.
    struct Line {
        let seed:   CGFloat
        let alpha:  Double
        let width:  CGFloat
        let samples: [Sample]
    }

    /// Everything a draw pass needs for one canvas size.
    struct Field {
        let lines: [Line]
        /// Pre-clipped, pre-built paths for the resting table (no warp, no
        /// forge). Stroking these is the whole draw in the common case.
        let restingPaths: [(path: Path, alpha: Double, width: CGFloat)]
    }

    private let lock = NSLock()
    private var cachedSize:  CGSize = .zero
    private var cachedField: Field? = nil

    /// Returns the field for `size`, computing and caching it on first request.
    /// Geometry constants mirror TableSurfaceView exactly — the base samples are
    /// bit-identical to what the previous per-frame loop produced.
    func field(for size: CGSize) -> Field {
        lock.lock()
        defer { lock.unlock() }
        if let field = cachedField, cachedSize == size { return field }

        let field = Self.compute(size: size)
        cachedSize  = size
        cachedField = field
        return field
    }

    private static func compute(size: CGSize) -> Field {
        let W      = size.width
        let H      = size.height
        let TY     = H * AppLayout.tableArcPeakYFrac
        let tableR = H * AppLayout.tableArcRadiusFrac
        let cx     = W * 0.50
        let cy     = TY + tableR
        let tableRSqInner = (tableR - 2) * (tableR - 2)

        // 62 — topo line count. Rendering constant — produces the correct
        // visual density of contour lines across the felt surface.
        let lineCount = 62

        var lines: [Line] = []
        lines.reserveCapacity(lineCount)
        var restingPaths: [(path: Path, alpha: Double, width: CGFloat)] = []
        restingPaths.reserveCapacity(lineCount)

        for li in 0 ..< lineCount {
            let t      = CGFloat(li) / CGFloat(lineCount - 1)
            let startX = lerp(cx - tableR * 0.96, cx + tableR * 0.96, t)

            let isIndex   = (li % 7 == 6)
            // 0.165 / 0.100 — index and standard line opacities.
            let alpha     = isIndex ? 0.165 : 0.100
            // 0.75 / 0.45 — index and standard line widths.
            let lineWidth = isIndex ? CGFloat(0.75) : CGFloat(0.45)
            // 0.713 / 1.05 — seed values for per-line noise phase offset.
            let seed      = CGFloat(li) * 0.713 + 1.05

            let yStart = Int(TY) - 6
            let yEnd   = Int(H)

            var samples: [Sample] = []
            samples.reserveCapacity(yEnd - yStart + 1)

            var restingPath = Path()
            var wasInside   = false

            for pyInt in yStart ... yEnd {
                let py      = CGFloat(pyInt)
                let depthT  = clamp((py - TY) / (H - TY), 0, 1.05)
                // 0.40 — fan sweep scale; 0.09 — lateral fan bias scale.
                let sweep   = depthT * depthT * W * 0.40
                let fanBias = (1.0 - t) * depthT * W * 0.09

                let nx = (startX / W) * 2.2 + seed * 0.28
                let ny = depthT * 2.8 + seed * 0.14
                let ws = 0.30 + 0.22 * sin(depthT * .pi)

                let n1 = domainWarp(nx, ny, ws)
                let n2 = fbm(nx * 1.7 + 0.5, ny * 1.3 + seed * 0.4, 4) * 0.50
                let n3 = fbm(nx * 3.8 + 1.1, ny * 2.6 + seed * 0.8, 3) * 0.22

                // 10 / 26 — noise amplitude range.
                let noiseAmp: CGFloat = 10 + depthT * 26
                let noiseX            = (n1 + n2 * 0.45 + n3 * 0.20) * noiseAmp
                let px                = startX - sweep - fanBias + noiseX

                samples.append(Sample(x: px, y: py, depthT: depthT))

                // Build the resting path alongside — same inside-circle clip
                // the per-frame loop applied, evaluated once.
                let dx     = px - cx
                let dyCir  = py - cy
                let distSq = dx * dx + dyCir * dyCir
                let inside = distSq < tableRSqInner && py >= TY - 2

                if inside {
                    if !wasInside { restingPath.move(to: CGPoint(x: px, y: py)) }
                    else          { restingPath.addLine(to: CGPoint(x: px, y: py)) }
                }
                wasInside = inside
            }

            lines.append(Line(seed: seed, alpha: alpha, width: lineWidth, samples: samples))
            if !restingPath.isEmpty {
                restingPaths.append((path: restingPath, alpha: alpha, width: lineWidth))
            }
        }

        return Field(lines: lines, restingPaths: restingPaths)
    }
}
