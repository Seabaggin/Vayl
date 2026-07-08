// Features/Onboarding/Models/CuriositySortCard.swift

import Foundation

/// A single sort card in the CuriosityPhase pile mechanic.
/// `id` is the stable key written to OnboardingData — never branch on `text`.
struct CuriositySortCard: Identifiable, Equatable {
    let id:    String
    let text:  String
    let round: Int     // CuriosityDeck round the card belongs to (OB deals round 2 only)
}
