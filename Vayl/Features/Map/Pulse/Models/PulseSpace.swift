// Vayl/Core/Models/PulseSpace.swift
//
// The six-named-space classification of a circumplex reading — the richer layer on top
// of PulseQuadrant's four geometric corners. Adds Neutral (both axes sitting in the
// centre border zone), Uncharted (contradictory answers on both axes; see PulseAnswers),
// and four directional border states (exactly one axis in the border zone).
//
// Assignment order (evaluated exactly this way, per spec §3):
//   1. Uncharted variance check — fires regardless of coordinates (passed in as `isUncharted`).
//   2. Neutral — both Energy and Openness in the 0.475–0.525 border zone.
//   3. Directional border — exactly one axis in the border zone, the other clearly outside.
//   4. Named quadrant — from the coordinates.
//
// This is a pure model: no state, no UI, no dependency on a Store.
// Colour resolution (dotCoreStatic, borderCores, ramp, dotCore) lives in
// PulseAura.swift alongside AuraColors — Models expose semantics only.

import Foundation

nonisolated enum PulseSpace: Equatable {
    case expansive
    case reactive
    case receptive
    case protective
    case neutral
    case uncharted
    case borderExpansiveReactive    // high energy, openness in border zone
    case borderReceptiveProtective  // low energy, openness in border zone
    case borderExpansiveReceptive   // high openness, energy in border zone
    case borderReactiveProtective   // low openness, energy in border zone

    // MARK: - Border zone

    /// The centre band on either axis. Inclusive of the endpoints. A tight ±0.025 around
    /// 0.5: Neutral (both axes in the band) then fires on only ~1.4% of readings, so it
    /// stays a genuinely rare "dead-centre, steady" day rather than a catch-all. This same
    /// band widths the four directional border states (~16% combined). 🎚️ FEEL: at ±0.10
    /// Neutral was 16% and borders 46%; widen back toward 0.45/0.55 if borders feel too rare.
    static let borderLower = 0.475
    static let borderUpper = 0.525

    static func inBorder(_ v: Double) -> Bool { v >= borderLower && v <= borderUpper }

    // MARK: - Resolution

    /// Classify a reading into a space. `isUncharted` is computed upstream in the scoring
    /// layer (PulseAnswers) because the variance check needs the raw per-question answers,
    /// not just the derived coordinates.
    static func resolve(energy: Double, openness: Double, isUncharted: Bool = false) -> PulseSpace {
        // 1. Uncharted wins outright.
        if isUncharted { return .uncharted }

        let eBorder = inBorder(energy)
        let oBorder = inBorder(openness)

        // 2. Neutral — both axes centred.
        if eBorder && oBorder { return .neutral }

        // 3. Directional border — exactly one axis centred (the other is, by elimination,
        //    strictly < 0.40 or > 0.60).
        if eBorder {
            return openness > borderUpper ? .borderExpansiveReceptive : .borderReactiveProtective
        }
        if oBorder {
            return energy > borderUpper ? .borderExpansiveReactive : .borderReceptiveProtective
        }

        // 4. Named quadrant from the coordinates.
        switch PulsePosition(energy: energy, openness: openness).quadrant {
        case .expansive:  return .expansive
        case .reactive:   return .reactive
        case .receptive:  return .receptive
        case .protective: return .protective
        }
    }

    static func resolve(_ position: PulsePosition, isUncharted: Bool = false) -> PulseSpace {
        resolve(energy: position.energy, openness: position.openness, isUncharted: isUncharted)
    }

    // MARK: - Classification helpers

    var isBorder: Bool {
        switch self {
        case .borderExpansiveReactive, .borderReceptiveProtective,
             .borderExpansiveReceptive, .borderReactiveProtective: return true
        default: return false
        }
    }

    /// The two named quadrants a border state sits between (nil for non-border spaces).
    var borderingQuadrants: (PulseQuadrant, PulseQuadrant)? {
        switch self {
        case .borderExpansiveReactive:   return (.expansive, .reactive)
        case .borderReceptiveProtective: return (.receptive, .protective)
        case .borderExpansiveReceptive:  return (.expansive, .receptive)
        case .borderReactiveProtective:  return (.reactive, .protective)
        default:                          return nil
        }
    }

    // MARK: - Display

    /// Title for the check-in reveal. Border states name both neighbours; the rest use the
    /// quadrant's own space name (Neutral / Uncharted carry their own copy).
    func title(at position: PulsePosition) -> String {
        switch self {
        case .expansive:  return PulseQuadrant.expansive.spaceName
        case .reactive:   return PulseQuadrant.reactive.spaceName
        case .receptive:  return PulseQuadrant.receptive.spaceName
        case .protective: return PulseQuadrant.protective.spaceName
        case .neutral:    return "The Neutral Space"
        case .uncharted:  return "The Uncharted Space"
        default:
            guard let (a, b) = borderingQuadrants else { return position.quadrant.spaceName }
            return "Bordering \(a.spaceName) and \(b.spaceName)"
        }
    }

    /// Descriptor line. For border states this is the descriptors of the space the
    /// coordinates are closest to (position.quadrant already resolves the nearest corner).
    func descriptors(at position: PulsePosition) -> String {
        switch self {
        case .expansive:  return PulseQuadrant.expansive.sublabel
        case .reactive:   return PulseQuadrant.reactive.sublabel
        case .receptive:  return PulseQuadrant.receptive.sublabel
        case .protective: return PulseQuadrant.protective.sublabel
        case .neutral:    return "Steady · Calm"
        case .uncharted:  return "Fluid · Searching"
        default:          return position.quadrant.sublabel
        }
    }

    /// The named quadrant a non-border space corresponds to (nil for border states).
    var namedQuadrant: PulseQuadrant? {
        switch self {
        case .expansive:  return .expansive
        case .reactive:   return .reactive
        case .receptive:  return .receptive
        case .protective: return .protective
        default:          return nil
        }
    }

    /// Standalone display name (no position needed) — used by the history-grid callout.
    var displayName: String {
        switch self {
        case .neutral:   return "The Neutral Space"
        case .uncharted: return "The Uncharted Space"
        default:
            if let q = namedQuadrant { return q.spaceName }
            guard let (a, b) = borderingQuadrants else { return "" }
            return "Bordering \(a.spaceName) and \(b.spaceName)"
        }
    }

}
