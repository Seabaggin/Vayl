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

    /// When the active invite code expires (read back from the DB at generate
    /// time). Drives the waiting-state countdown. Nil until a code is generated.
    private(set) var codeExpiresAt: Date?

    /// True when the active code timed out before a partner joined. The invite
    /// view shows a "code expired — regenerate" prompt instead of the spinner.
    private(set) var codeExpired: Bool = false

    /// The linked partner's display name (from `get-partner`). Nil until fetched
    /// or if the partner hasn't set one. Use `partnerDisplayName` for UI.
    private(set) var partnerName: String?

    /// Partner name for display, with a graceful fallback when it's unset.
    var partnerDisplayName: String { partnerName ?? "Your partner" }

    /// When the FIRST invite code was generated for this pairing attempt (mirrors
    /// `UserProfile.firstInviteSentAt`). Nil until an invite has been sent. Backs
    /// the invite view's static "sent X ago" caption — read once on appear rather
    /// than driving a live countdown.
    private(set) var firstInviteSentAt: Date?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let pairingService: PairingService
    private let syncManager: SyncManager

    // MARK: - Private

    private var pollTask: Task<Void, Never>?

    // MARK: - Init

    /// `pairingService` / `syncManager` nil-resolve inside the MainActor-isolated body
    /// (a `= .shared` default argument would evaluate nonisolated and not compile).
    init(
        modelContainer: ModelContainer,
        appState: AppState,
        pairingService: PairingService? = nil,
        syncManager: SyncManager? = nil,
        initialState: PairingLinkState = .idle
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.pairingService = pairingService ?? PairingService()
        self.syncManager = syncManager ?? .shared
        self.linkState = initialState
    }

    isolated deinit {
        pollTask?.cancel()
    }

    // MARK: - Generate Invite

    /// Person A — generates a pairing code and begins polling for partner.
    /// Moves to .waitingForPartner on success.
    /// Moves to .error on failure.
    func generateInvite() async {
        guard case .idle = linkState else { return }
        linkState = .generating
        codeExpired = false
        await syncIdentityToRemote()   // push my name so my partner can read it post-link

        do {
            let (code, expiresAt) = try await pairingService.generateCode()
            codeExpiresAt = expiresAt
            await recordFirstInviteSentIfNeeded()
            linkState = .waitingForPartner(code: code)
            PostHogService.shared.capture("pairing_invite_generated", properties: [
                "code_length": code.count,
                "invite_expiry_seconds": max(0, Int(expiresAt.timeIntervalSinceNow))
            ])
            logger.info("Invite generated — expires \(expiresAt)")
            await pollForPartner(code: code, deadline: expiresAt)
        } catch {
            linkState = .error(error.localizedDescription)
            logger.error("Generate invite failed: \(error.localizedDescription)")
        }
    }

    /// Stamps `firstInviteSentAt` the first time an invite is generated for this
    /// pairing attempt. Regenerating an expired code does NOT reset it — the
    /// nudge threshold measures "how long you've been trying to pair," not the
    /// lifetime of any single code.
    ///
    /// Internal (not private) so `@testable import Vayl` can call this method
    /// directly in tests, rather than reimplementing its guard logic inline.
    func recordFirstInviteSentIfNeeded() async {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        guard profile.firstInviteSentAt == nil else { return }
        profile.firstInviteSentAt = Date()
        try? context.saveWithLogging()
        firstInviteSentAt = profile.firstInviteSentAt
    }

    /// Reads `firstInviteSentAt` back from disk — call on invite-view appear so
    /// re-entering a `.waitingForPartner` state (e.g. reopening the sheet) shows
    /// the correct "sent X ago" caption even without regenerating a code.
    func loadFirstInviteSentAt() async {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        firstInviteSentAt = profile.firstInviteSentAt
    }

    // MARK: - Regenerate

    /// Discards an expired/failed invite and mints a fresh one. Backs the
    /// "Generate new code" action in the expired state.
    func regenerate() async {
        cancelPolling()
        codeExpired = false
        codeExpiresAt = nil
        linkState = .idle
        await generateInvite()
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
        await syncIdentityToRemote()   // push my name before linking

        do {
            let coupleId = try await pairingService.claimCode(code)
            try await persistLink(coupleId: coupleId)
            linkState = .linked(coupleId: coupleId)
            PostHogService.shared.capture("pairing_join_succeeded", properties: [
                "code_length": code.trimmingCharacters(in: .whitespaces).count,
                "linked_from_join": true
            ])
            logger.info("Joined successfully — coupleId: \(coupleId)")
            await refreshPartner()
        } catch {
            linkState = .error(error.localizedDescription)
            logger.error("Join failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Poll For Partner

    /// Person A — polls every 3 seconds until partner joins.
    /// Moves to .linked when partner claims the code.
    func pollForPartner(code: String, deadline: Date) async {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            do {
                let coupleId = try await self.pairingService.pollForClaim(code: code, deadline: deadline)
                guard !Task.isCancelled else { return }
                try await self.persistLink(coupleId: coupleId)
                self.linkState = .linked(coupleId: coupleId)
                logger.info("Partner joined — coupleId: \(coupleId)")
                await self.refreshPartner()
            } catch is CancellationError {
                logger.info("Polling cancelled")
            } catch PairingError.expiredCode {
                guard !Task.isCancelled else { return }
                self.codeExpired = true
                logger.info("Pairing code expired — prompting regenerate")
            } catch {
                guard !Task.isCancelled else { return }
                self.linkState = .error(error.localizedDescription)
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
        codeExpired = false
        codeExpiresAt = nil
        linkState = .idle
    }

    // MARK: - Identity Sync

    /// Pushes the local display name/pronouns to the remote profile so the partner
    /// can read them post-link (the rich profile otherwise lives only in local
    /// SwiftData). Called on every pairing action + linked-screen load, so couples
    /// linked before P3 back-fill their names on the next visit. Best-effort.
    private func syncIdentityToRemote() async {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        await syncManager.pushDisplayIdentity(localProfile: profile)
    }

    // MARK: - Partner Identity

    /// Pushes our own identity (back-filling existing couples) then reads the
    /// partner's name via `get-partner`. Called on link + when a linked surface
    /// appears. Best-effort — a failure just leaves the "Your partner" fallback.
    func refreshPartner() async {
        await syncIdentityToRemote()
        do {
            if let partner = try await pairingService.fetchPartner() {
                partnerName = partner.name
                persistPartnerGender(partner.gender)
                deriveCompositionProposal(partnerGender: partner.gender)
            }
        } catch {
            logger.error("Fetch partner failed: \(error.localizedDescription)")
        }
    }

    /// Fulfills UserProfile.partnerGenderIdentity's "populated via pairing
    /// flow" contract (UserProfile.swift). Best-effort.
    private func persistPartnerGender(_ gender: String?) {
        guard let gender else { return }
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.partnerGenderIdentity = gender
        try? context.saveWithLogging()
    }

    // MARK: - Connection Composition (spec §9)

    /// The composition to propose on the linked screen. Nil = nothing to
    /// propose (non-binary / declined / already resolved) → silent .flexible,
    /// which is the DB default — no write needed.
    private(set) var compositionProposal: GenderDynamic?

    /// Set when `confirmComposition()` fails to write remotely. The proposal
    /// stays set so the UI can offer a retry (tapping confirm again) rather
    /// than silently discarding the user's choice. Cleared on the next attempt.
    private(set) var compositionError: String?

    /// Set once the user answers (either way) so a re-entered linked surface
    /// never re-asks. UserDefaults because it is per-device UI state, not data.
    private let proposalResolvedKey = "vayl.compositionProposalResolved"

    /// Derives the proposal from both partners' OB gender answers. Called from
    /// refreshPartner after the partner's gender lands. One-shot per device.
    private func deriveCompositionProposal(partnerGender: String?) {
        guard case .linked = linkState,
              !UserDefaults.standard.bool(forKey: proposalResolvedKey) else { return }
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        compositionProposal = GenderDynamic.proposal(
            myGender: profile.genderIdentity,
            partnerGender: partnerGender
        )
        if compositionProposal == nil {
            // Nothing to propose — resolve silently so we never re-derive.
            UserDefaults.standard.set(true, forKey: proposalResolvedKey)
        }
    }

    /// One-tap confirm. Writes the proposal remotely (RPC), mirrors into the
    /// local Couple if one exists (same mirror-if-present rule as
    /// EntitlementStore.apply — this store never creates Couple rows).
    func confirmComposition() async {
        guard case .linked(let coupleId) = linkState,
              let proposal = compositionProposal else { return }
        compositionError = nil
        do {
            try await pairingService.setComposition(coupleId: coupleId, proposal)
            mirrorCompositionLocally(proposal, coupleId: coupleId)
            compositionProposal = nil
            UserDefaults.standard.set(true, forKey: proposalResolvedKey)
            logger.info("Composition confirmed: \(proposal.rawValue)")
        } catch {
            // Keep the proposal set so the user can retry — proposalResolvedKey
            // is NOT marked, since the write never actually landed.
            compositionError = error.localizedDescription
            logger.error("Composition write failed, proposal kept for retry: \(error.localizedDescription)")
        }
    }

    /// "Keep it flexible" / card skipped. No network call — the column already
    /// defaults to flexible, which is the spec's silent fallback.
    func dismissComposition() {
        compositionProposal = nil
        UserDefaults.standard.set(true, forKey: proposalResolvedKey)
        logger.info("Composition proposal dismissed — staying flexible")
    }

    private func mirrorCompositionLocally(_ value: GenderDynamic, coupleId: UUID) {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        guard let couple = try? context.fetch(descriptor).first else { return }
        couple.connectionComposition = value
        try? context.saveWithLogging()
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
        profile.firstInviteSentAt = nil

        do {
            try context.saveWithLogging()
        } catch {
            throw PairingError.unknown("Failed to save link state: \(error.localizedDescription)")
        }

        // Mirror into AppState for in-memory routing
        appState.linkState = .linked
        appState.coupleId = coupleId
        logger.info("Link persisted — coupleId: \(coupleId)")

        // Pairing-completion compute trigger (review 2026-07-09, decision #2): couples who
        // finished the map BEFORE pairing were stranded — their completion-time compute hit
        // the edge fn as "unpaired" and nothing ever re-triggered it. Now that the couple
        // exists, re-fire the full sync path (marks this side complete server-side; computes
        // matches when both are done; idempotent). Fire-and-forget — pairing never waits on it.
        if profile.hasCompletedDesireMap {
            let container = modelContainer
            let manager = syncManager   // the injected instance (tests can stub it)
            Task { await manager.resyncDesireMapIfComplete(modelContainer: container) }
        }
    }
}
