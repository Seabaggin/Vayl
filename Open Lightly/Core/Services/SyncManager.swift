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
            #if DEBUG
            print("✅ Profile synced to Supabase")
            #endif
            return profileId
        } catch {
            lastSyncError = error.localizedDescription
            UserDefaults.standard.set(true, forKey: "pendingProfileSync")
            #if DEBUG
            print("❌ Profile sync failed: \(error.localizedDescription)")
            #endif
            throw error
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

    /// Marks onboarding as complete in BOTH SwiftData and Supabase.
    ///
    /// FLOW:
    /// 1. Set `hasCompletedOnboarding = true` on the local SwiftData model (instant)
    /// 2. Save the SwiftData context (persists to disk)
    /// 3. Push the same flag to Supabase (async, might fail)
    /// 4. If Supabase push fails → flag for retry
    ///
    /// WHY LOCAL FIRST?
    /// Because the app checks `hasCompletedOnboarding` on every launch to decide
    /// whether to show onboarding or the home screen. If we waited for Supabase,
    /// the user could be stuck in onboarding if they're offline.
    ///
    /// - Parameters:
    ///   - profileId: Supabase profile UUID
    ///   - localProfile: The SwiftData UserProfile model instance
    ///   - modelContext: The SwiftData ModelContext (needed to call .save())
    func completeOnboarding(
        localProfile: UserProfile,
        modelContext: ModelContext
    ) async throws {
        guard let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
              let profileId = UUID(uuidString: profileIdString) else {
            throw SyncError.profileMissingId
        }
        localProfile.hasCompletedOnboarding = true
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        do {
            try await profileService.markOnboardingComplete(profileId: profileId)
            #if DEBUG
            print("✅ Onboarding flag synced to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("❌ Onboarding sync failed — will retry: \(error)")
            #endif
            UserDefaults.standard.set(true, forKey: "pendingOnboardingSync")
        }
    }

    // =========================================================================
    // MARK: - Retry Pending Syncs
    // =========================================================================

    /// Checks for any failed syncs from previous sessions and retries them.
    ///
    /// WHEN TO CALL:
    /// In your app's root view (e.g., `ContentView` or `Open_LightlyApp.swift`),
    /// inside a `.task { }` modifier that runs on app launch:
    ///
    /// ```swift
    /// .task {
    ///     if let userId = authService.userId, let profile = localProfile {
    ///         await SyncManager.shared.retryPendingSyncs(
    ///             userId: userId,
    ///             localProfile: profile
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// HOW IT WORKS:
    /// 1. Checks UserDefaults for "pendingProfileSync" flag
    /// 2. If true → re-attempts the profile sync using local SwiftData data
    /// 3. If the retry succeeds → clears the flag
    /// 4. If it fails again → flag stays set, will retry next launch
    /// 5. Same pattern for "pendingOnboardingSync"
    ///
    /// - Parameters:
    ///   - userId: Authenticated user's UUID
    ///   - localProfile: The local SwiftData UserProfile (has the data to push)
    func retryPendingSyncs(userId: UUID, localProfile: UserProfile?) async {
        if UserDefaults.standard.bool(forKey: "pendingProfileSync"),
           let profile = localProfile {
            do {
                try await syncProfileToSupabase(authId: userId)
                if lastSyncError == nil {
                    UserDefaults.standard.set(false, forKey: "pendingProfileSync")
                    #if DEBUG
                    print("✅ Pending profile sync completed on retry")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ Pending profile sync retry failed: \(error)")
                #endif
            }
        }
        if UserDefaults.standard.bool(forKey: "pendingOnboardingSync"),
           let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
           let profileId = UUID(uuidString: profileIdString) {
            do {
                try await profileService.markOnboardingComplete(profileId: profileId)
                UserDefaults.standard.set(false, forKey: "pendingOnboardingSync")
                #if DEBUG
                print("✅ Pending onboarding sync completed on retry")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Retry failed for onboarding sync — will try again next launch")
                #endif
            }
        }
    }
}
