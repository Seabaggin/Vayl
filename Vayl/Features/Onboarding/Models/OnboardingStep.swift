//
//  OnboardingStep.swift
//  Vayl
//

import Foundation

// Navigation shape for the onboarding flow.
// Owned here — referenced by OnboardingStore and OnboardingFlowView.
// Step order is intentional and load-bearing.
// cardReveal precedes buildingPath: CardReveal collects
// nmCardResponse, which BuildingPath reads for its fourth
// orbit row and personalised exit copy. Do not reorder.

enum OnboardingStep: Int, CaseIterable {
    case stat
    case brand
    case name
    case modeSelect
    case contextSelect
    case curiosityPicker
    case cardReveal
    case buildingPath
    case groundRules
}