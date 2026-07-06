//
//  DesireItem.swift
//  Vayl
//
//  A single Desire Map prompt loaded from desire_items.json.
//  Pure data shape — no logic, no dependencies (Model layer).
//
//  COHORT-ADAPTIVE: `tracks` says which cohort(s) see this item; `answers` holds the
//  four answer strings PER track, in fixed weight order:
//      [excitedAboutIt, openToIt, probablyNot, notForMe]   (DesireRatingValue.allCases order)
//  Only the WEIGHT (index) is ever stored/synced — the displayed string is cohort copy.
//  Item identity (id/name/description) is cohort-neutral so a mixed couple rates the same item.
//

import Foundation

struct DesireItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String        // structures / emotional / sexual / communication / health / logistics
    let sensitivity: Int        // 1–3, drives primer framing later
    let sortOrder: Int
    let tracks: [String]        // "curious" / "established"
    let answers: [String: [String]]   // track -> 4 answers, in DesireRatingValue.allCases order
    /// Couple-framed reveal copy, keyed by DesireMatchType.rawValue ("mutual" / "adjacent").
    /// Names what THIS couple shares about THIS item — never a verdict about either person.
    let meaning: [String: String]?

    /// The four answer strings for a given track, weight-ordered. nil if this item
    /// isn't part of that track.
    func answers(for track: String) -> [String]? {
        answers[track]
    }

    /// Whether this item is shown to the given cohort track.
    func appears(in track: String) -> Bool {
        tracks.contains(track)
    }
}
