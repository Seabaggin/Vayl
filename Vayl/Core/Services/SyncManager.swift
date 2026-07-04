//
//  SyncManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  SyncManager.swift
//  Open Lightly
//
//  Created in Batch 10 — The Bridge Between Local and Remote
//
//  PURPOSE:
//  SyncManager is the ORCHESTRATOR that coordinates writes between:
//    - SwiftData (local, on-device, instant, works offline)
//    - Supabase (remote, cloud, async, needs internet)
//
//  THE GOLDEN RULE:
//  ┌────────────────────────────────────────────────────┐
//  │  1. Save to SwiftData FIRST (instant, never fails) │
//  │  2. Push to Supabase SECOND (async, might fail)    │
//  │  3. If push fails → flag it for retry later        │
//  └────────────────────────────────────────────────────┘
//
//  WHY THIS PATTERN?
//  - The user sees instant UI updates (SwiftData drives the views)
//  - If they're offline or Supabase is down, the app still works
//  - Pending syncs are retried on next app launch
//  - SwiftData = source of truth for UI
//  - Supabase = source of truth for multiplayer/cross-device
//
//  WHO CALLS SYNCMANAGER?
//  Views and view models call SyncManager. SyncManager calls
//  ProfileService, DesireSyncService, etc. Views should NEVER
//  call ProfileService directly.
//

import Foundation
import SwiftData
import Combine
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "SyncManager"
)

@MainActor  // Runs on main thread — safe for @Published properties that drive UI
class SyncManager: ObservableObject {

    // MARK: - Singleton

    /// Shared instance — access with `SyncManager.shared`
    static let shared = SyncManager()

    // MARK: - Published State (UI can observe these)

    /// True while any sync operation is in progress.
    /// You can use this to show a spinner or "Syncing..." indicator.
    @Published var isSyncing = false

    /// If the last sync failed, this contains the error message.
    /// Nil means everything is fine. You can show this in a toast/alert.
    @Published var lastSyncError: String?

    // MARK: - Dependencies

    /// Reference to ProfileService for all profile-related Supabase calls.
    private let profileService = ProfileService()

    // =========================================================================
    // MARK: - Profile Sync (After Onboarding)
    // =========================================================================

    /// Pushes the user's profile data to Supabase after it's been saved locally.
    ///
    /// WHEN TO CALL:
    /// At the end of onboarding, AFTER you've saved the UserProfile to SwiftData.
    ///
    /// WHAT HAPPENS:
    /// 1. Sets `isSyncing = true` (UI can show a loading state)
    /// 2. Calls ProfileService to create/fetch the remote profile
    /// 3. On success: prints confirmation, clears any previous error
    /// 4. On failure: stores error message, flags sync as pending in UserDefaults
    /// 5. Sets `isSyncing = false`
    ///
    /// FAILURE HANDLING:
    /// If the push fails (no internet, Supabase down, etc.), we set a flag in
    /// UserDefaults: "pendingProfileSync" = true. On next app launch,
    /// `retryPendingSyncs()` will pick this up and try again.
    ///
    /// - Parameter authId: Authenticated user's UUID from AuthService
    @discardableResult
    func syncProfileToSupabase(authId: UUID) async throws -> UUID {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let profile = try await profileService.fetchOrCreateProfile(authId: authId)
            guard let profileId = profile.id else {
                throw SyncError.profileMissingId
            }
            UserDefaults.standard.set(profileId.uuidString, forKey: "supabaseProfileId")
            logger.info("✅ Profile synced to Supabase")
            return profileId
        } catch {
            lastSyncError = error.localizedDescription
            UserDefaults.standard.set(true, forKey: "pendingProfileSync")
            logger.error("❌ Profile sync failed: \(error.localizedDescription)")
            throw error
        }
    }

    // =========================================================================
    // MARK: - Display Identity Sync (P3 — partner-visible name/pronouns)
    // =========================================================================

    /// Pushes the local profile's display name + pronouns to the remote
    /// `user_profiles` row so a linked partner can read them. Best-effort — the
    /// name is only consumed on the linked screen, so a transient failure is
    /// non-fatal and is simply retried next time pairing is opened.
    func pushDisplayIdentity(localProfile: UserProfile) async {
        let trimmedName = localProfile.displayName.trimmingCharacters(in: .whitespaces)
        let pronouns = localProfile.pronouns.isEmpty
            ? nil
            : localProfile.pronouns.joined(separator: ", ")
        do {
            try await profileService.updateIdentity(
                name: trimmedName.isEmpty ? nil : trimmedName,
                pronouns: pronouns,
                gender: localProfile.genderIdentity
            )
            logger.info("✅ Display identity synced to Supabase")
        } catch {
            logger.warning("⚠️ Display identity sync failed (non-fatal): \(error.localizedDescription)")
        }
    }

    func pushNMStage(_ stage: String) async {
        do {
            try await profileService.updateNMStage(stage)
            logger.info("✅ NM stage synced: \(stage)")
        } catch {
            logger.warning("⚠️ NM stage sync failed (non-fatal): \(error.localizedDescription)")
        }
    }

    func pushSharePulse(_ value: Bool) async {
        do {
            try await profileService.updateSharePulse(value)
            logger.info("✅ Share pulse preference synced: \(value)")
        } catch {
            logger.warning("⚠️ Share pulse sync failed (non-fatal): \(error.localizedDescription)")
        }
    }

    // =========================================================================
    // MARK: - Desire Map Sync (D2)
    // =========================================================================

    /// Pushes the user's desire-map weights + nm_stage to Supabase after the local
    /// `DesireMapEntry` rows are saved. Best-effort: on failure, flags `pendingDesireSync`
    /// so the rater re-syncs on next open. Mirrors the profile-sync pattern. All weights
    /// sync (incl. `notForMe`) — boundaries are obscured at the reveal layer, not here.
    func syncDesireMap(ratings: [PendingDesireRating], nmStage: String) async {
        guard !ratings.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await DesireSyncService.shared.syncRatings(ratings)
            try await profileService.updateNMStage(nmStage)
            // Mark this side complete + compute matches if both partners are done (server-side).
            try await DesireSyncService.shared.computeMatches()
            UserDefaults.standard.set(false, forKey: "pendingDesireSync")
            lastSyncError = nil
            logger.info("✅ Desire map synced (\(ratings.count) weights, stage \(nmStage))")
        } catch {
            lastSyncError = error.localizedDescription
            UserDefaults.standard.set(true, forKey: "pendingDesireSync")
            logger.error("❌ Desire map sync failed — will retry on next rater open: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Errors

    enum SyncError: LocalizedError {
        case profileMissingId
        case profileNotFound
        case onboardingNotComplete

        var errorDescription: String? {
            switch self {
            case .profileMissingId:
                return "Profile was created but returned no ID. Cannot proceed."
            case .profileNotFound:
                return "No confirmed profile found. Please complete onboarding first."
            case .onboardingNotComplete:
                return "Onboarding has not been completed. Cannot sync data."
            }
        }
    }

    // =========================================================================
    // MARK: - Complete Onboarding (Local + Remote)
    // =========================================================================

    /// Pushes the onboarding-complete flag to Supabase. **Remote-only.**
    ///
    /// Local completion is owned by `AppState.markOnboardingComplete` — the single
    /// writer of the durable truth (UserProfile), the in-memory surface, and the
    /// UserDefaults cache. Intended flow: set local via AppState first, then call
    /// this to sync upstream. On failure, flags a retry that `retryPendingSyncs`
    /// picks up on the next launch.
    ///
    /// - Note: this previously also wrote the local flag + UserDefaults cache; those
    ///   writes were removed so local completion has exactly one writer (AppState).
    func pushOnboardingComplete() async throws {
        guard let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
              let profileId = UUID(uuidString: profileIdString) else {
            throw SyncError.profileMissingId
        }
        do {
            try await profileService.markOnboardingComplete(profileId: profileId)
            logger.info("✅ Onboarding flag synced to Supabase")
        } catch {
            logger.error("❌ Onboarding sync failed — will retry: \(error)")
            UserDefaults.standard.set(true, forKey: "pendingOnboardingSync")
        }
    }

    // =========================================================================
    // MARK: - Retry Pending Syncs
    // =========================================================================

    /// Checks for any failed syncs from previous sessions and retries them.
    ///
    /// WHEN TO CALL:
    /// In your app's root view (e.g., `AppRootView` / `VaylApp`),
    /// inside a `.task { }` modifier that runs on app launch:
    ///
    /// ```swift
    /// .task {
    ///     if let userId = authService.userId {
    ///         await SyncManager.shared.retryPendingSyncs(userId: userId)
    ///     }
    /// }
    /// ```
    ///
    /// HOW IT WORKS:
    /// 1. Checks UserDefaults for "pendingOnboardingSync" flag
    /// 2. If true → re-attempts the onboarding-complete push
    /// 3. If the retry succeeds → clears the flag
    /// 4. If it fails again → flag stays set, will retry next launch
    ///
    /// Profile creation is no longer retried here — as of Pairing Segment P2 it's
    /// handled at sign-in by `AuthService.ensureRemoteProfile()`, which self-heals
    /// on failure (leaves the `supabaseProfileId` cache nil so the next launch retries).
    ///
    /// - Parameter userId: Authenticated user's UUID
    func retryPendingSyncs(userId: UUID) async {
        // 1) Process legacy UserDefaults queue
        if UserDefaults.standard.bool(forKey: "pendingOnboardingSync"),
           let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
           let profileId = UUID(uuidString: profileIdString) {
            do {
                try await profileService.markOnboardingComplete(profileId: profileId)
                UserDefaults.standard.set(false, forKey: "pendingOnboardingSync")
                logger.info("✅ Pending onboarding sync completed on retry")
            } catch {
                logger.warning("⚠️ Retry failed for onboarding sync — will try again next launch")
            }
        }
        
        // 2) Process durable SwiftData SyncTask queue
        await processTaskQueue()
    }
    
    // =========================================================================
    // MARK: - Durable Background Queue (SyncTask)
    // =========================================================================

    /// Enqueues a task into SwiftData for reliable background synchronization.
    func enqueueSyncTask(taskType: String, entityId: String, payload: Data? = nil) {
        let context = ModelContext(ModelContainer.appContainer)
        let task = SyncTask(taskType: taskType, entityId: entityId, payload: payload)
        context.insert(task)
        do {
            try context.saveWithLogging()
            logger.info("Enqueued SyncTask: \(taskType) for entity \(entityId)")
        } catch {
            logger.error("Failed to enqueue SyncTask (\(taskType), entity \(entityId)): \(error.localizedDescription)")
        }
        
        // Trigger a process run in the background
        Task { await processTaskQueue() }
    }
    
    /// Processes all pending SyncTasks in the local queue.
    private func processTaskQueue() async {
        let context = ModelContext(ModelContainer.appContainer)
        let descriptor = FetchDescriptor<SyncTask>(sortBy: [SortDescriptor(\.createdAt)])
        
        guard let tasks = try? context.fetch(descriptor), !tasks.isEmpty else { return }
        logger.info("Processing \(tasks.count) pending SyncTasks")
        
        for task in tasks {
            do {
                switch task.taskType {
                case "sync_session":
                    if let payload = task.payload {
                        try await SessionSyncService.shared.pushSession(payload: payload)
                    }
                default:
                    logger.warning("Unknown taskType in queue: \(task.taskType)")
                }
                
                // On success, remove from queue. If this save fails the delete is lost and the
                // task re-processes next launch (duplicate push) — so surface the failure.
                context.delete(task)
                do {
                    try context.saveWithLogging()
                } catch {
                    logger.error("Failed to persist SyncTask deletion (\(task.taskType)): \(error.localizedDescription)")
                }
            } catch {
                task.retryCount += 1
                // Persist the retry-count bump; a lost save silently drops retry accounting.
                do {
                    try context.saveWithLogging()
                } catch {
                    logger.error("Failed to persist SyncTask retry bump (\(task.taskType)): \(error.localizedDescription)")
                }
                logger.error("SyncTask failed (\(task.taskType), retries: \(task.retryCount)): \(error.localizedDescription)")
            }
        }
    }
}
