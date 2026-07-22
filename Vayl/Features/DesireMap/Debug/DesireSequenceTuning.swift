//
//  DesireSequenceTuning.swift
//  Vayl
//
//  DEBUG-only live overrides for the Desire Map reveal sequence's timing.
//
//  Why this exists: the reveal sequence's values were authored in an HTML feel reference
//  (docs/mockups/desire-reveal-sequence.html) and deliberately shipped UNTUNED — the project's
//  animation contract says feel is confirmed on device, and a slider in a browser cannot tell you
//  how a nine-star sky reads on a phone in a dark room. This lets the numbers be dialled in the
//  running app instead of via edit-build-relaunch.
//
//  The contract is preserved: `AppAnimation` remains the single source of truth, its production
//  values are still literals in that file, and every default here is exactly the literal it
//  shadows. In RELEASE this file does not exist and `AppAnimation` returns the literals directly.
//
//  Once Bryan locks the values, copy them back into AppAnimation's literals — this is a dial, not
//  a store. Nothing outside DEBUG may read it.
//

#if DEBUG
import Foundation
import Observation

/// Live-tunable copies of the reveal sequence's timing.
///
/// `@Observable` rather than a bag of statics: the debug panel binds directly to these, and a
/// plain static would force the view to invalidate itself manually on every change — which is
/// exactly what broke the sliders (the manual `.id()` invalidation remounted the `Slider`
/// mid-drag, so a drag could never travel). Observation tracks the reads for us.
///
/// Read by `AppAnimation`'s reveal-sequence accessors and written from the debug UI — both on the
/// main actor (the app runs under default-MainActor isolation). A debug dial, never production
/// state.
@Observable
@MainActor
final class DesireSequenceTuning {

    static let shared = DesireSequenceTuning()

    private init() {}

    // 0 · Star size — a multiplier over the count-derived base size (rebuildConstellation).
    // Takes effect on the next Replay, since sizes are computed when the store is built.
    var starSizeScale: Double = 1.0

    // 0b · Brightness hierarchy (unlocked ≫ dormant > line). Live — no Replay needed.
    var lockedCore: Double = 0.55         // dormant core (crisp cool pinpoint)
    var lockedGlow: Double = 0.32         // dormant glow (compact, hueless)
    var lineOpacity: Double = 0.42        // connecting lines (the floor)
    var dormantSizeScale: Double = 1.12   // dormant glyph scale (distinguishable, not a speck)

    // 1 · Star cascade
    var starCascadeStep: Double = 0.09
    var starBloomDuration: Double = 0.56

    // 2 · Hold
    var holdStarsToLines: Double = 0.22

    // 3 · Line draw
    var lineDrawDuration: Double = 0.90
    var lineDrawStep: Double = 0.07
    /// Index into `curves`.
    var lineCurveIndex: Int = 0

    // 4 · Rows
    var holdLinesToRows: Double = 0.26
    var rowStaggerStep: Double = 0.08
    var rowEnterDuration: Double = 0.36

    // 5 · First reveal
    var holdRowsToReveal: Double = 0.70

    // Tail
    var beatHold1: Double = 0.40

    /// The line-draw curve candidates carried over from the HTML reference, so the comparison that
    /// was available in the browser is available on device too. `current (in-out)` is the curve the
    /// old opacity fade used — kept so the thing being replaced can still be seen next to it.
    static let curves: [(name: String, control: (Double, Double, Double, Double))] = [
        ("quint-out",        (0.22, 1.00, 0.36, 1.00)),
        ("expo-out",         (0.16, 1.00, 0.30, 1.00)),
        ("ease-out",         (0.00, 0.00, 0.58, 1.00)),
        ("current (in-out)", (0.42, 0.00, 0.58, 1.00)),
    ]

    var curve: (Double, Double, Double, Double) {
        Self.curves[min(max(lineCurveIndex, 0), Self.curves.count - 1)].control
    }

    func reset() {
        starSizeScale = 1.0
        lockedCore = 0.55
        lockedGlow = 0.32
        lineOpacity = 0.42
        dormantSizeScale = 1.12
        starCascadeStep = 0.09
        starBloomDuration = 0.56
        holdStarsToLines = 0.22
        lineDrawDuration = 0.90
        lineDrawStep = 0.07
        lineCurveIndex = 0
        holdLinesToRows = 0.26
        rowStaggerStep = 0.08
        rowEnterDuration = 0.36
        holdRowsToReveal = 0.70
        beatHold1 = 0.40
    }

    /// Paste-ready snapshot for copying the dialled values back into `AppAnimation`.
    var export: String {
        let c = Self.curves[min(max(lineCurveIndex, 0), Self.curves.count - 1)]
        return """
        starSizeScale (× base)   = \(fmt(starSizeScale))
        lockedCore opacity       = \(fmt(lockedCore))
        lockedGlow opacity       = \(fmt(lockedGlow))
        line opacity             = \(fmt(lineOpacity))
        dormantSizeScale         = \(fmt(dormantSizeScale))
        desireStarCascadeStep    = \(fmt(starCascadeStep))
        desireStarBloomDuration  = \(fmt(starBloomDuration))
        desireHoldStarsToLines   = \(fmt(holdStarsToLines))
        desireLineDrawDuration   = \(fmt(lineDrawDuration))
        desireLineDrawStep      = \(fmt(lineDrawStep))
        desireLineDraw curve     = \(c.name) \(c.control)
        desireHoldLinesToRows    = \(fmt(holdLinesToRows))
        desireBeatStaggerStep    = \(fmt(rowStaggerStep))
        desireLockedRowEnterDur  = \(fmt(rowEnterDuration))
        desireHoldRowsToReveal   = \(fmt(holdRowsToReveal))
        desireBeatHold1          = \(fmt(beatHold1))
        """
    }

    private func fmt(_ v: Double) -> String { String(format: "%.2f", v) }
}
#endif
