//
//  PairingLinkState.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/28/26.
//


//
//  PairingStore.swift
//  Vayl
//

import Foundation
import SwiftData
import SwiftUI
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "PairingStore"
)

// MARK: - PairingLinkState

enum PairingLinkState: Equatable {
    case idle
    case generating
    case waitingForPartner(code: String)
    case joining
    case linked(coupleId: UUID)
    case error(String)

    static func == (lhs: PairingLinkState, rhs: PairingLinkState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.generating, .generating):
            return true
        case (.waitingForPartner(let a), .waitingForPartner(let b)):
            return a == b
        case (.joining, .joining):
            return true
        case (.linked(let a), .linked(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - PairingStore

@Observable
@MainActor
final class PairingStore {

    // MARK: - Public State


    var linkState: PairingLinkState = .idle

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let pairingService: PairingService

    // MARK: - Private

    private var pollTask: Task<Void, Never>? = nil

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        pairingService: PairingService = PairingService(),
        initialState: PairingLinkState = .idle
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.pairingService = pairingService
        self.linkState = initialState
    }

    // MARK: - Generate Invite

    /// Person A — generates a pairing code and begins polling for partner.
    /// Moves to .waitingForPartner on success.
    /// Moves to .error on failure.
    func generateInvite() async {
        guard case .idle = linkState else { return }
        linkState = .generating

        do {
            let code = try await pairingService.generateCode()
            linkState = .waitingForPartner(code: code)
            logger.info("Invite generated — code: \(code)")
            await pollForPartner(code: code)
        } catch {
            linkState = .error(error.localizedDescription)
            logger.error("Generate invite failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Join With Code

    /// Person B — claims a code and completes linking.
    /// Moves to .linked on success.
    /// Moves to .error on failure.
    func joinWithCode(_ code: String) async {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            linkState = .error("Please enter a code.")
            return
        }

        linkState = .joining

        do {
            let coupleId = try await pairingService.claimCode(code)
            try await persistLink(coupleId: coupleId)
            linkState = .linked(coupleId: coupleId)
            logger.info("Joined successfully — coupleId: \(coupleId)")
        } catch {
            linkState = .error(error.localizedDescription)
            logger.error("Join failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Poll For Partner

    /// Person A — polls every 3 seconds until partner joins.
    /// Moves to .linked when partner claims the code.
    func pollForPartner(code: String) async {
        pollTask?.cancel()
        pollTask = Task {
            do {
                let coupleId = try await pairingService.pollForClaim(code: code)
                guard !Task.isCancelled else { return }
                try await persistLink(coupleId: coupleId)
                linkState = .linked(coupleId: coupleId)
                logger.info("Partner joined — coupleId: \(coupleId)")
            } catch is CancellationError {
                logger.info("Polling cancelled")
            } catch {
                guard !Task.isCancelled else { return }
                linkState = .error(error.localizedDescription)
                logger.error("Polling failed: \(error.localizedDescription)")
            }
        }
        await pollTask?.value
    }

    // MARK: - Cancel Polling

    /// Cancels active polling — call on view dismiss or flow exit.
    func cancelPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Reset

    /// Resets to idle — allows retry from clean state.
    func reset() {
        cancelPolling()
        linkState = .idle
    }

    // MARK: - Persistence

    /// Writes coupleId, isLinked, and linkedAt to UserProfile via SwiftData.
    /// Mirrors coupleId into AppState.
    /// Creates a fresh ModelContext at write time — never stored on self.
    private func persistLink(coupleId: UUID) async throws {
        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)

        guard let profile = profiles.first else {
            logger.error("persistLink — no UserProfile found")
            throw PairingError.unknown("No user profile found. Please complete onboarding first.")
        }

        profile.coupleId  = coupleId
        profile.isLinked  = true
        profile.linkedAt  = Date()

        do {
            try context.saveWithLogging()
        } catch {
            throw PairingError.unknown("Failed to save link state: \(error.localizedDescription)")
        }

        // Mirror into AppState for in-memory routing
        appState.linkState = .linked
        appState.coupleId = coupleId
        logger.info("Link persisted — coupleId: \(coupleId)")
    }
}
