//
//  OnboardingStore.swift
//  Vayl
//

import Foundation
import SwiftData
import SwiftUI
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "OnboardingStore"
)

// MARK: - Errors

enum OnboardingError: Error, LocalizedError {
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let underlying):
            return "Failed to save onboarding data: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - OnboardingStore

@Observable
@MainActor
final class OnboardingStore {

    // MARK: - Public State

    private(set) var didComplete: Bool = false
    private(set) var lastCommitError: Error? = nil

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    var appState: AppState

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        appState: AppState
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
    }

    // MARK: - Commit
    // Called by VaylDirector at founderLetter phase.
    // Creates a fresh ModelContext at call time — never stored on self.
    // On success: mirrors into AppState and sets didComplete = true.
    // On failure: sets lastCommitError only — never sets didComplete.

    func commit(data: OnboardingData) {
        do {
            try persist(data: data)
            mirrorIntoAppState(data: data)
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            didComplete = true
            logger.info("Onboarding committed — displayName: \(data.displayName), appMode: \(data.appMode.rawValue)")
        } catch {
            lastCommitError = error
            logger.error("Onboarding commit failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Persistence

    /// Fetches existing UserProfile or creates a new one.
    /// Creates a fresh ModelContext from the container at call time.
    /// Writes every OnboardingData field to the profile.
    /// Throws on any failure — never swallows errors.
    private func persist(data: OnboardingData) throws {
        // Create a fresh context at write time — never stored on self
        let context = ModelContext(modelContainer)

        // Fetch existing profile or create a new one
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = try context.fetch(descriptor)
        let profile: UserProfile

        if let found = existing.first {
            profile = found
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        // Write every field from OnboardingData
        profile.displayName            = data.displayName
        // Gender + pronouns — self (GenderPhase spin 1, always collected)
        profile.genderIdentity         = data.genderA
        profile.pronouns               = data.pronounsA.map { [$0] } ?? []

        // Gender + pronouns — partner (GenderPhase spin 2, together mode only)
        // nil for solo / browsing users, or if the partner skipped the field.
        profile.partnerGenderIdentity  = data.genderB
        profile.partnerPronouns        = data.pronounsB

        profile.appMode                = data.appMode
        profile.nmStage                = data.nmStage
        // ContextPhase signals
        profile.relationshipContext    = data.relationshipContext
        profile.situationalRegister    = data.situationalRegister
        // CompassPhase signals (Q3 emotionalRegister written fresh — not ContextPhase)
        profile.emotionalRegister      = data.emotionalRegister
        profile.agency                 = data.agency
        profile.motivation             = data.motivation
        profile.compassNotes           = data.compassNotes
        profile.curiositySelections    = data.curiositySelections
        profile.openerDeckType         = data.openerDeckType
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt  = Date()

        // Fields not written here:
        // groundRulesAcceptedAt — written from home screen flow
        // acknowledgementAcceptedAt — written from 3-card modal
        // nmCardResponse — old flow only, not collected in new OB canvas flow

        do {
            try context.saveWithLogging()
        } catch {
            throw OnboardingError.saveFailed(error)
        }
    }

    // MARK: - AppState Mirror

    /// Writes displayName, appMode, and isOnboardingComplete into AppState.
    /// AppState is not the source of truth — UserProfile is.
    /// This mirrors only what AppState needs for in-memory routing.
    private func mirrorIntoAppState(data: OnboardingData) {
        appState.displayName         = data.displayName
        appState.appMode             = data.appMode
        appState.isOnboardingComplete = true
    }
}
