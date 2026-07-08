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
    case incompleteData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let underlying):
            return "Failed to save onboarding data: \(underlying.localizedDescription)"
        case .incompleteData:
            return "Onboarding data is incomplete and cannot be saved yet."
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
    // Called by VaylDirector.finishOnboarding() when the user finishes onboarding.
    // Gated by OnboardingData.isReadyToComplete. Creates a fresh ModelContext at
    // call time — never stored on self. Returns true on success.
    //   On success: persists data, calls AppState.markOnboardingComplete (the single
    //     writer of truth+surface+cache), clears lastCommitError, sets didComplete.
    //   On failure (incomplete data or save error): sets lastCommitError, returns
    //     false, and never sets didComplete or the completion flag.

    @discardableResult
    func commit(data: OnboardingData) -> Bool {
        guard data.isReadyToComplete else {
            lastCommitError = OnboardingError.incompleteData
            logger.error("Onboarding commit blocked — data not ready to complete")
            return false
        }
        do {
            let (profile, context) = try persist(data: data)
            mirrorIntoAppState(data: data)                              // displayName + appMode
            appState.markOnboardingComplete(profile, context: context) // single completion writer (truth+surface+cache)
            lastCommitError = nil
            didComplete = true
            logger.info("Onboarding committed — appMode: \(data.appMode.rawValue)")
            return true
        } catch {
            lastCommitError = error
            logger.error("Onboarding commit failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Persistence

    /// Fetches existing UserProfile or creates a new one.
    /// Creates a fresh ModelContext from the container at call time.
    /// Writes every OnboardingData field to the profile (NOT the completion flag —
    /// that is AppState.markOnboardingComplete's job). Throws on any failure.
    /// Returns the (profile, context) so the caller can mark completion atomically.
    private func persist(data: OnboardingData) throws -> (UserProfile, ModelContext) {
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
        // nil for solo users, or if the partner skipped the field.
        profile.partnerGenderIdentity  = data.genderB
        profile.partnerPronouns        = data.pronounsB

        profile.appMode                = data.appMode
        profile.nmStage                = data.nmStage
        // ContextPhase signals
        profile.relationshipContext    = data.relationshipContext
        profile.situationalRegister    = data.situationalRegister
        // DemoPhase snapshot — emotionalRegister derived from "I [verb] [noun]"
        // (revives the cut Compass Q3 signal); verb/noun kept raw for the
        // first-session callback and any future re-derivation.
        profile.emotionalRegister      = data.emotionalRegister
        profile.demoVerb               = data.demoVerb
        profile.demoNoun               = data.demoNoun
        profile.agency                 = data.agency
        profile.motivation             = data.motivation
        profile.compassNotes           = data.compassNotes
        profile.curiositySelections    = data.curiositySelections
        profile.openerDeckType         = data.openerDeckType
        // Completion flag + onboardingCompletedAt are set by
        // AppState.markOnboardingComplete (single writer), not here.

        // Fields not written here:
        // groundRulesAcceptedAt — written from home screen flow
        // acknowledgementAcceptedAt — written from 3-card modal
        // nmCardResponse — old flow only, not collected in new OB canvas flow

        do {
            try context.saveWithLogging()
        } catch {
            throw OnboardingError.saveFailed(error)
        }

        return (profile, context)
    }

    // MARK: - AppState Mirror

    /// Mirrors displayName + appMode into AppState for in-memory routing.
    /// Completion is NOT set here — AppState.markOnboardingComplete owns that.
    /// AppState is not the source of truth — UserProfile is.
    private func mirrorIntoAppState(data: OnboardingData) {
        appState.displayName = data.displayName
        appState.appMode     = data.appMode
    }
}
