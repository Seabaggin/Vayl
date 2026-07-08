//
//  DemoDictionary.swift
//  Vayl
//
//  Features/Onboarding/Models/DemoDictionary.swift
//

import Foundation

/// Pure mapping from the DemoPhase snapshot ("I [verb] [noun].") to an
/// `EmotionalRegister`. The noun's keyword stem picks a base category; the verb
/// modulates it. Unmapped nouns fall back to `.flexible` (a neutral baseline).
///
/// This revives the signal CompassPhase Q3 used to write — a behavioral
/// diagnostic disguised as a sentence completion. No evaluation is ever shown to
/// the user; the derived register only tones downstream card copy.
///
/// Stems are matched as substrings against the lowercased noun, so "clarity" and
/// "clarify" both hit `clarit`, "boundaries" hits `boundar`, etc.
enum DemoDictionary {

    private static let anxiousStems = [
        "safe", "honest", "clarit", "truth", "trust", "rule", "boundar",
        "peace", "understand", "communicat", "secur", "stabil", "reassur"
    ]
    private static let excitedStems = [
        "freedom", "explor", "fun", "pleasur", "novel", "variet", "passion",
        "thrill", "adventur", "sex", "kink", "more", "autonom", "independen"
    ]
    private static let flexibleStems = [
        "connect", "growth", "align", "balanc", "love", "intima", "partner",
        "depth", "shared", "communit", "famil"
    ]

    /// Base category from the noun alone. `nil` when unmapped.
    private static func category(for noun: String) -> EmotionalRegister? {
        let n = noun.lowercased().trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return nil }
        if anxiousStems.contains(where: n.contains) { return .anxious }
        if excitedStems.contains(where: n.contains) { return .excited }
        if flexibleStems.contains(where: n.contains) { return .flexible }
        return nil
    }

    /// Triangulate verb × noun → `EmotionalRegister`. Unmapped nouns → `.flexible`.
    ///
    /// The verb modulates the noun category:
    ///   need + excited-noun   → anxious   ("needs freedom" reads as feeling trapped)
    ///   desire + anxious-noun → flexible  ("desires trust" softens toward open)
    ///   desire + flexible-noun → excited  (desire tilts the neutral category warm)
    static func register(verb: DemoVerb, noun: String) -> EmotionalRegister {
        guard let base = category(for: noun) else { return .flexible }
        switch (verb, base) {
        case (.need, .excited):  return .anxious
        case (.desire, .anxious):  return .flexible
        case (.desire, .flexible): return .excited
        default:                   return base
        }
    }
}
