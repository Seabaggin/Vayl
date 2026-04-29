//
//  OnboardingError.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/28/26.
//


//
//  OnboardingStore.swift
//  Vayl
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "OnboardingStore"
)

// MARK: - Errors

enum OnboardingError: Error, LocalizedError {
    case missingAppMode
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .missingAppMode:
            return "App mode was not selected before onboarding completed."
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

    private(set) var currentStep: OnboardingStep
    private(set) var didComplete: Bool = false
    private(set) var lastCommitError: Error? = nil

    // MARK: - Onboarding Data

    var data: OnboardingData = OnboardingData()

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let appState: AppState

    // MARK: - Init

    init(modelContext: ModelContext, appState: AppState, startAt: OnboardingStep = .stat) {
        self.modelContext = modelContext
        self.appState = appState
        self.currentStep = startAt
    }

    // MARK: - Validation

    /// Whether the user is allowed to advance from the current step.
    var canAdvance: Bool {
        switch currentStep {
        case .stat:
            return true
        case .brand:
            return true
        case .name:
            return !data.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case .modeSelect:
            return data.appMode != nil
        case .contextSelect:
            return data.nmStage != nil
        case .curiosityPicker:
            return !data.curiositySelections.isEmpty
        case .cardReveal:
            // nmCardResponse is optional — user may skip
            return true
        case .buildingPath:
            return true
        case .groundRules:
            return data.groundRulesAcceptedAt != nil
        }
    }

    // MARK: - Navigation

    /// Advance to the next step.
    /// Does nothing if canAdvance is false.
    /// Handles every OnboardingStep case exhaustively — no default.
    func advance() {
        guard canAdvance else {
            logger.warning("advance() called but canAdvance is false on step: \(String(describing: self.currentStep))")
            return
        }

        switch currentStep {
        case .stat:
            move(to: .brand)

        case .brand:
            move(to: .name)

        case .name:
            move(to: .modeSelect)

        case .modeSelect:
            switch data.appMode {
            case .browsing:
                finish()
            case .together, .solo:
                move(to: .contextSelect)
            case .none:
                logger.warning("advance() called on modeSelect but appMode is nil")
            }

        case .contextSelect:
            move(to: .curiosityPicker)

        case .curiosityPicker:
            move(to: .cardReveal)

        case .cardReveal:
            move(to: .buildingPath)

        case .buildingPath:
            move(to: .groundRules)

        case .groundRules:
            finish()
        }
    }

    /// Go back one step.
    /// Handles every case exhaustively — no default.
    func goBack() {
        switch currentStep {
        case .stat:
            // First step — nowhere to go back to
            break
        case .brand:
            move(to: .stat)
        case .name:
            // Name is the first data-entry screen.
            // Brand auto-advances and cannot be safely navigated back to.
            break
        case .modeSelect:
            move(to: .name)
        case .contextSelect:
            move(to: .modeSelect)
        case .curiosityPicker:
            move(to: .contextSelect)
        case .cardReveal:
            move(to: .curiosityPicker)
        case .buildingPath:
            move(to: .cardReveal)
        case .groundRules:
            move(to: .buildingPath)
        }
    }

    // MARK: - Private Navigation

    private func move(to step: OnboardingStep) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentStep = step
        }
    }

    // MARK: - Completion

    /// Called when the user reaches the end of their onboarding path.
    /// Calls commit(), mirrors into AppState on success.
    /// On failure, sets lastCommitError and does NOT set didComplete.
    private func finish() {
        Task {
            do {
                try await commit()
                mirrorIntoAppState()
                didComplete = true
                logger.info("Onboarding finished successfully — appMode: \(self.data.appMode?.rawValue ?? "nil")")
            } catch {
                lastCommitError = error
                logger.error("Onboarding finish failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Persistence

    /// Fetches existing UserProfile or creates a new one.
    /// Writes every OnboardingData field to the profile.
    /// Throws on any failure — never swallows errors.
    private func commit() async throws {
        guard let mode = data.appMode else {
            throw OnboardingError.missingAppMode
        }

        // Fetch existing profile or create a new one
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = try modelContext.fetch(descriptor)
        let profile: UserProfile

        if let found = existing.first {
            profile = found
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }

        // Write every field from OnboardingData
        profile.displayName             = data.displayName
        profile.appMode                 = mode
        profile.nmStage                 = data.nmStage ?? .curious
        profile.curiositySelections     = data.curiositySelections
        profile.nmCardResponse          = data.nmCardResponse
        profile.groundRulesAcceptedAt   = data.groundRulesAcceptedAt
        profile.hasCompletedOnboarding  = true
        profile.onboardingCompletedAt   = Date()

        do {
            try modelContext.saveWithLogging()
        } catch {
            throw OnboardingError.saveFailed(error)
        }
    }

    // MARK: - AppState Mirror

    /// Writes display name and app mode into AppState.
    /// AppState is not the source of truth — UserProfile is.
    /// This mirrors only what AppState needs for routing.
    private func mirrorIntoAppState() {
        appState.displayName        = data.displayName
        appState.appMode            = data.appMode ?? .together
        appState.isOnboardingComplete = true
    }
}