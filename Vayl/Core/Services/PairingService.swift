//
//  PairingService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


//
//  PairingService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import Supabase
import Foundation
import Combine

@MainActor
final class PairingService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var generatedCode: String?
    @Published var isGenerating = false
    @Published var isLookingUp = false
    @Published var isPairing = false
    @Published var error: String?
    
    @Published var partnerName: String?
    @Published var partnerPronouns: String?
    @Published var partnerId: String?
    
    @Published var pairingComplete = false
    @Published var coupleId: String?
    
    // MARK: - Private
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    private let profileService = ProfileService()
    
    // MARK: - Code Generation
    
    /// Generates a 3-character pairing code: D4G, R2N, 7KM, etc.
    func generateCode(userId: UUID) async {
        isGenerating = true
        error = nil
        let code = createPairingCode()
        do {
            _ = try await profileService.ensureProfileExists(authId: userId)
            try await supabase
                .from("pairing_codes")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("used", value: false)
                .execute()
            let expiresAt = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(5 * 60)
            )
            try await supabase
                .from("pairing_codes")
                .insert([
                    "code": code,
                    "user_id": userId.uuidString,
                    "expires_at": expiresAt,
                    "used": "false"
                ])
                .execute()
            try await supabase
                .from("user_profiles")
                .update(["pairing_code": code])
                .eq("auth_id", value: userId.uuidString)
                .execute()
            self.generatedCode = code
            #if DEBUG
            print("✅ Pairing code generated: \(code)")
            #endif
        } catch {
            self.error = "Cannot generate code — your profile isn't set up yet. Please complete onboarding first."
            #if DEBUG
            print("❌ Code generation failed: \(error.localizedDescription)")
            #endif
        }
        isGenerating = false
    }
    
    // MARK: - Code Lookup
    
    /// Calls the lookup-code Edge Function to validate a partner's code
    func lookupCode(_ code: String) async {
        isLookingUp = true
        error = nil
        partnerName = nil
        partnerPronouns = nil
        partnerId = nil
        
        do {
            let data: LookupResponse = try await supabase.functions.invoke(
                "lookup-code",
                options: .init(body: ["code": code.uppercased().trimmingCharacters(in: .whitespaces)])
            )
            
            if data.valid {
                self.partnerId = data.partnerId
                self.partnerName = data.partnerName
                self.partnerPronouns = data.partnerPronouns
                #if DEBUG
                print("✅ Code valid — partner: \(data.partnerName ?? "unknown")")
                #endif
            } else {
                self.error = "Invalid or expired code"
            }
        } catch {
            self.error = "Code not found. Check and try again."
            #if DEBUG
            print("❌ Lookup failed: \(error.localizedDescription)")
            #endif
        }
        
        isLookingUp = false
    }
    
    // MARK: - Create Pair
    
    /// Calls the create-pair Edge Function to link both users
    func createPair(code: String, requesterId: UUID) async {
        isPairing = true
        error = nil
        
        do {
            _ = try await profileService.ensureProfileExists(authId: requesterId)
            let data: PairResponse = try await supabase.functions.invoke(
                "create-pair",
                options: .init(body: [
                    "code": code.uppercased().trimmingCharacters(in: .whitespaces),
                    "requesterId": requesterId.uuidString
                ])
            )
            
            if data.success {
                self.coupleId = data.coupleId
                self.pairingComplete = true
                #if DEBUG
                print("✅ Pairing complete! Couple ID: \(data.coupleId ?? "unknown")")
                #endif
            } else {
                self.error = "Pairing failed. Try again."
            }
        } catch {
            self.error = "Pairing failed. Try again."
            #if DEBUG
            print("❌ Pairing failed: \(error.localizedDescription)")
            #endif
        }
        
        isPairing = false
    }
    
    // MARK: - Reset
    
    func reset() {
        generatedCode = nil
        partnerName = nil
        partnerPronouns = nil
        partnerId = nil
        pairingComplete = false
        coupleId = nil
        error = nil
    }
    
    // MARK: - 3-Character Code Generator
    
    /// Generates codes like D4G, R2N, 7KM, B9X
    /// ~27,000 unique combos — no confusing chars (0/O, 1/I, L)
    private func createPairingCode() -> String {
        let chars: [Character] = Array("ABCDEFGHJKMNPQRSTUVWXYZ2345679")
        return String((0..<3).map { _ in chars.randomElement()! })
    }
    
    // MARK: - Response Models
    struct LookupResponse: Codable {
        let valid: Bool
        let partnerId: String?
        let partnerName: String?
        let partnerPronouns: String?
    }
    
    struct PairResponse: Codable {
        let success: Bool
        let coupleId: String?
        let userA: String?
        let userB: String?
    }
}
