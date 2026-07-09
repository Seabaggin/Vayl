//
//  SyncRound.swift
//  Vayl
//
//  Pure evaluator for one airlock sync attempt. No SwiftUI, no networking —
//  given two release angles (or terminal states) and the config, it decides the
//  verdict. Unit-tested; the view and coordinator are thin over this.
//

import Foundation

/// One partner's release outcome for a round.
enum SyncRelease: Equatable {
    case tooEarly(angle: Double)   // released before the floor
    case overshoot                 // held all the way to 360° without releasing
    case valid(angle: Double)      // released in [floor, 360)
}

/// The judged outcome of a round, from THIS device's point of view.
enum SyncVerdict: Equatable {
    case inSync
    case soClose(gapDegrees: Double)
    case farApart(gapDegrees: Double)
    case selfTooEarly
    case selfOvershoot
    case partnerTooEarly
    case partnerOvershoot
}

struct SyncRound {
    let config: SyncConfig
    /// Consecutive misses so far (drives silent easing).
    let misses: Int

    var effectiveTolerance: Double { config.tolerance(afterMisses: misses) }
    var backstopReached: Bool { misses >= config.backstopAfterMisses }

    /// Smallest angular distance on a 360° ring.
    static func gap(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    /// Map an elapsed fraction of the sweep (0…1+) to a release kind.
    func classify(elapsedFraction f: Double) -> SyncRelease {
        let angle = f * 360
        if angle >= 360 { return .overshoot }
        if angle < config.floorDegrees { return .tooEarly(angle: angle) }
        return .valid(angle: angle)
    }

    /// Judge both partners' releases. Self-side terminal states take priority so
    /// the feedback names what THIS partner should change first.
    func judge(mine: SyncRelease, partner: SyncRelease) -> SyncVerdict {
        switch mine {
        case .overshoot: return .selfOvershoot
        case .tooEarly:  return .selfTooEarly
        case .valid(let a):
            switch partner {
            case .overshoot: return .partnerOvershoot
            case .tooEarly:  return .partnerTooEarly
            case .valid(let b):
                let g = SyncRound.gap(a, b)
                if g <= effectiveTolerance { return .inSync }
                if g <= effectiveTolerance * 1.5 { return .soClose(gapDegrees: g) }
                return .farApart(gapDegrees: g)
            }
        }
    }
}
