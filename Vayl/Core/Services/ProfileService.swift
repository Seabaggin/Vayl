//
//  ProfileService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


//
//  ProfileService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import Supabase
import Foundation
import Combine

@MainActor
final class ProfileService: ObservableObject {
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Supabase Profile Struct
    
    struct SupabaseProfile: Codable {
        let id: UUID?
        let authId: UUID
        let name: String?
        let pronouns: String
        let sexualOrientation: String
        let rolePreference: String
        let userMode: String
        let experienceLevel: String
        let defaultDifficulty: String
        let curiositySelections: [String]
        let surpriseMeEnabled: Bool
        let mythBusterComplete: Bool
        let mythBusterSkipped: Bool
        let nmFlavor: String?
        let pairingCode: String?
        let isLinked: Bool
        let partnerLabel: String?
        let hasCompletedOnboarding: Bool
        let hasCompletedAssessment: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case authId = "auth_id"
            case name
            case pronouns
            case sexualOrientation = "sexual_orientation"
            case rolePreference = "role_preference"
            case userMode = "user_mode"
            case experienceLevel = "experience_level"
            case defaultDifficulty = "default_difficulty"
            case curiositySelections = "curiosity_selections"
            case surpriseMeEnabled = "surprise_me_enabled"
            case mythBusterComplete = "myth_buster_complete"
            case mythBusterSkipped = "myth_buster_skipped"
            case nmFlavor = "nm_flavor"
            case pairingCode = "pairing_code"
            case isLinked = "is_linked"
            case partnerLabel = "partner_label"
            case hasCompletedOnboarding = "has_completed_onboarding"
            case hasCompletedAssessment = "has_completed_assessment"
        }
    }
    
    // MARK: - Fetch or Create Profile
    
    /// Fetches the user's profile from Supabase. If none exists, creates one.
    func fetchOrCreateProfile(authId: UUID) async throws -> SupabaseProfile {
        // Try to fetch existing profile
        let existing: [SupabaseProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("auth_id", value: authId.uuidString)
            .execute()
            .value
        
        if let profile = existing.first {
            return profile
        }
        
        // No profile exists — create one
        let newProfile = SupabaseProfile(
            id: nil,
            authId: authId,
            name: nil,
            pronouns: "they/them",
            sexualOrientation: "prefer not to say",
            rolePreference: "not sure",
            userMode: "solo",
            experienceLevel: "new",
            defaultDifficulty: "warm",
            curiositySelections: [],
            surpriseMeEnabled: false,
            mythBusterComplete: false,
            mythBusterSkipped: false,
            nmFlavor: nil,
            pairingCode: nil,
            isLinked: false,
            partnerLabel: nil,
            hasCompletedOnboarding: false,
            hasCompletedAssessment: false
        )
        
        let created: SupabaseProfile = try await supabase
            .from("user_profiles")
            .insert(newProfile)
            .select()
            .single()
            .execute()
            .value
        
        return created
    }
    
    // MARK: - Lookup Pairing Code

    /// Scoped response for pairing code lookup.
    /// Contains ONLY the fields needed to confirm a partner in the UI.
    /// Sexual orientation, NM flavor, role preference and all other
    /// sensitive profile fields are intentionally excluded.
    struct PartnerPreview: Codable {
        let name: String?
        let pronouns: String
    }

    /// Looks up a pairing code and returns only the partner's display name
    /// and pronouns — nothing else. The full SupabaseProfile is never
    /// fetched or transmitted to the requesting client.
    func lookupPairingCode(_ code: String) async throws -> PartnerPreview? {
        struct PairingCodeRecord: Codable {
            let code: String
            let userId: UUID
            let used: Bool

            enum CodingKeys: String, CodingKey {
                case code
                case userId = "user_id"
                case used
            }
        }

        let records: [PairingCodeRecord] = try await supabase
            .from("pairing_codes")
            .select()
            .eq("code", value: code)
            .eq("used", value: false)
            .execute()
            .value

        guard let record = records.first else { return nil }

        // Fetch ONLY name and pronouns — all other columns are excluded
        // from the projection so they are never transmitted to the client.
        let previews: [PartnerPreview] = try await supabase
            .from("user_profiles")
            .select("name,pronouns")
            .eq("id", value: record.userId.uuidString)
            .execute()
            .value

        return previews.first
    }
    // MARK: - Mark Onboarding Complete (Batch 10)
        
        /// Sets `has_completed_onboarding = true` in Supabase.
        ///
        /// Called by SyncManager AFTER the local SwiftData model has already
        /// been updated. This is the remote half of that operation.
        ///
        /// - Parameter profileId: The user's profile UUID (the `id` column, not `auth_id`)
        func markOnboardingComplete(profileId: UUID) async throws {
            struct ProfileIdOnly: Codable { let id: UUID }
            let check: [ProfileIdOnly] = try await supabase
                .from("user_profiles")
                .select("id")
                .eq("id", value: profileId.uuidString)
                .execute()
                .value

            guard !check.isEmpty else {
                throw SyncManager.SyncError.profileNotFound
            }

            try await supabase
                .from("user_profiles")
                .update(["has_completed_onboarding": true])
                .eq("id", value: profileId.uuidString)
                .execute()
        }
    
    // MARK: - Ensure Profile Exists

    /// Checks if a profile exists for the given authId. If not, throws an error.
    /// Caches the profile ID in UserDefaults for future use.
    func ensureProfileExists(authId: UUID) async throws -> UUID {
        if let cached = UserDefaults.standard.string(forKey: "supabaseProfileId"),
           let cachedId = UUID(uuidString: cached) {
            return cachedId
        }
        struct ProfileIdOnly: Codable {
            let id: UUID
        }
        let results: [ProfileIdOnly] = try await supabase
            .from("user_profiles")
            .select("id")
            .eq("auth_id", value: authId.uuidString)
            .execute()
            .value
        guard let profile = results.first else {
            throw SyncManager.SyncError.profileNotFound
        }
        UserDefaults.standard.set(profile.id.uuidString, forKey: "supabaseProfileId")
        return profile.id
    }
}
