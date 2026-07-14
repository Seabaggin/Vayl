#if DEBUG

import Foundation
import OSLog
import Supabase
import SwiftData

private let debugSeedLogger = Logger(
    subsystem: "com.vayl.app",
    category: "DebugCoupleSeed"
)

enum DebugCoupleSeedRole: String {
    case a
    case b
}

struct DebugCoupleSeedConfig {
    let role: DebugCoupleSeedRole
    let pairCode: String
    let freshAuth: Bool
    let resetSessions: Bool
    let email: String
    let password: String
    let allowSignUp: Bool

    static func fromLaunchArguments(_ arguments: [String] = CommandLine.arguments) -> DebugCoupleSeedConfig? {
        guard arguments.contains("-vaylDebugSeedCouple") else { return nil }
        let roleRaw = value(after: "-vaylDebugSeedRole", in: arguments)?.lowercased() ?? "a"
        guard let role = DebugCoupleSeedRole(rawValue: roleRaw) else {
            debugSeedLogger.error("Invalid -vaylDebugSeedRole \(roleRaw, privacy: .public)")
            return nil
        }
        let code = value(after: "-vaylDebugPairCode", in: arguments) ?? "VAYL42"
        let freshAuth = arguments.contains("-vaylDebugFreshAuth")
        let resetSessions = arguments.contains("-vaylDebugResetSessions")
        let normalizedCode = code.uppercased()
        let defaultEmail = "vayl-debug-\(normalizedCode.lowercased())-\(role.rawValue)@debug.vayl.local"
        let email = value(after: "-vaylDebugSeedEmail", in: arguments) ?? defaultEmail
        let password = value(after: "-vaylDebugSeedPassword", in: arguments) ?? "VaylDebug!2026"
        let allowSignUp = !arguments.contains("-vaylDebugNoSignUp")
        return DebugCoupleSeedConfig(
            role: role,
            pairCode: normalizedCode,
            freshAuth: freshAuth,
            resetSessions: resetSessions,
            email: email,
            password: password,
            allowSignUp: allowSignUp
        )
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(arguments.index(after: index)) else { return nil }
        return arguments[arguments.index(after: index)]
    }
}

@MainActor
final class DebugCoupleSeedService {

    private struct RemoteCoupleRow: Decodable {
        let id: UUID
        let userA: UUID?
        let userB: UUID?
        let connectionComposition: String?

        enum CodingKeys: String, CodingKey {
            case id
            case userA = "user_a"
            case userB = "user_b"
            case connectionComposition = "connection_composition"
        }
    }

    private struct ProfileCoupleRow: Decodable {
        let coupleId: UUID?

        enum CodingKeys: String, CodingKey {
            case coupleId = "couple_id"
        }
    }

    private struct DebugPairingCodeInsert: Encodable {
        let createdBy: String
        let code: String

        enum CodingKeys: String, CodingKey {
            case createdBy = "created_by"
            case code
        }
    }

    private struct DebugPairingCodeRow: Decodable {
        let expiresAt: Date

        enum CodingKeys: String, CodingKey {
            case expiresAt = "expires_at"
        }
    }

    private enum DebugCoupleSeedError: LocalizedError {
        case emailConfirmationRequired(String)

        var errorDescription: String? {
            switch self {
            case .emailConfirmationRequired(let email):
                return "Debug seed account \(email) was created but needs email confirmation. Confirm it in Supabase or pass existing credentials with -vaylDebugSeedEmail and -vaylDebugSeedPassword."
            }
        }
    }

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let authService: AuthService
    private let supabase = SupabaseManager.shared.client
    private let pairingService = PairingService()

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        authService: AuthService
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.authService = authService
    }

    @discardableResult
    func runIfRequested() async -> Bool {
        guard let config = DebugCoupleSeedConfig.fromLaunchArguments() else { return false }
        do {
            try await run(config)
            authService.error = nil
        } catch {
            authService.error = "Debug couple seed failed: \(error.localizedDescription)"
            debugSeedLogger.error("Debug couple seed failed: \(error.localizedDescription, privacy: .public)")
        }
        return true
    }

    private func run(_ config: DebugCoupleSeedConfig) async throws {
        let authId = try await ensureDebugSession(config)
        let profileId = try await SyncManager.shared.syncProfileToSupabase(authId: authId)
        let profile = try seedLocalProfile(profileId: profileId, role: config.role)
        await SyncManager.shared.pushDisplayIdentity(localProfile: profile)

        let coupleId: UUID
        switch config.role {
        case .a:
            let expiresAt = try await createDebugPairingCode(config.pairCode, authId: authId)
            debugSeedLogger.info("Debug role A waiting on pair code \(config.pairCode, privacy: .public)")
            let debugDeadline = min(expiresAt, Date().addingTimeInterval(90))
            coupleId = try await waitForLinkedCouple(deadline: debugDeadline)
        case .b:
            debugSeedLogger.info("Debug role B claiming pair code \(config.pairCode, privacy: .public)")
            coupleId = try await claimWhenAvailable(config.pairCode)
        }

        let remoteCouple = try await fetchRemoteCouple(coupleId: coupleId)
        try mirrorLink(coupleId: coupleId, remoteCouple: remoteCouple, localProfileId: profileId)
        if config.resetSessions {
            try await RealtimeSessionService().debugAbandonOpenSessions(coupleId: coupleId)
        }
        debugSeedLogger.info("Debug couple seed complete: \(coupleId.uuidString, privacy: .public)")
    }

    private func ensureDebugSession(_ config: DebugCoupleSeedConfig) async throws -> UUID {
        if config.freshAuth {
            try? await supabase.auth.signOut()
            UserDefaults.standard.removeObject(forKey: "supabaseProfileId")
        } else if let session = try? await supabase.auth.session, !session.isExpired {
            authService.userId = session.user.id
            authService.isAuthenticated = true
            return session.user.id
        }

        let session: Session
        do {
            session = try await supabase.auth.signIn(
                email: config.email,
                password: config.password
            )
        } catch {
            guard config.allowSignUp else { throw error }
            let response = try await supabase.auth.signUp(
                email: config.email,
                password: config.password
            )
            guard let createdSession = response.session else {
                throw DebugCoupleSeedError.emailConfirmationRequired(config.email)
            }
            session = createdSession
        }

        authService.userId = session.user.id
        authService.isAuthenticated = true
        debugSeedLogger.info("Debug seed signed in \(config.email, privacy: .public)")
        return session.user.id
    }

    private func seedLocalProfile(profileId: UUID, role: DebugCoupleSeedRole) throws -> UserProfile {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        let profile: UserProfile
        if let existing = try context.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.id = profileId
        profile.displayName = role == .a ? "Jordan A" : "Jordan B"
        profile.genderIdentity = nil
        profile.pronouns = ["they/them"]
        profile.appMode = .together
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt = profile.onboardingCompletedAt ?? Date()
        profile.hasCompletedDesireMap = true
        profile.isLinked = false
        profile.coupleId = nil
        profile.linkedAt = nil

        try context.saveWithLogging()
        appState.markOnboardingComplete(profile, context: context)
        appState.displayName = profile.displayName
        appState.appMode = .together
        return profile
    }

    private func createDebugPairingCode(_ code: String, authId: UUID) async throws -> Date {
        do {
            try await supabase
                .from("pairing_codes")
                .delete()
                .eq("code", value: code)
                .execute()
        } catch {
            debugSeedLogger.debug("No owned debug pairing code to clear before insert")
        }

        let row: DebugPairingCodeRow = try await supabase
            .from("pairing_codes")
            .insert(DebugPairingCodeInsert(
                createdBy: authId.uuidString,
                code: code
            ))
            .select("expires_at")
            .single()
            .execute()
            .value
        return row.expiresAt
    }

    private func claimWhenAvailable(_ code: String) async throws -> UUID {
        let deadline = Date().addingTimeInterval(90)
        var lastError: Error?

        while Date() < deadline {
            do {
                return try await pairingService.claimCode(code)
            } catch {
                lastError = error
                if let coupleId = try await linkedCoupleIdForCurrentProfile() {
                    return coupleId
                }
                try await Task.sleep(for: .seconds(2))
            }
        }

        throw lastError ?? PairingError.expiredCode
    }

    private func waitForLinkedCouple(deadline: Date) async throws -> UUID {
        var lastError: Error?

        while Date() < deadline {
            do {
                if let coupleId = try await linkedCoupleIdForCurrentProfile() {
                    return coupleId
                }
            } catch {
                lastError = error
            }
            try await Task.sleep(for: .seconds(2))
        }

        throw lastError ?? PairingError.expiredCode
    }

    private func linkedCoupleIdForCurrentProfile() async throws -> UUID? {
        let authId = try await supabase.auth.session.user.id
        let rows: [ProfileCoupleRow] = try await supabase
            .from("user_profiles")
            .select("couple_id")
            .eq("auth_id", value: authId.uuidString)
            .execute()
            .value
        return rows.first?.coupleId
    }

    private func fetchRemoteCouple(coupleId: UUID) async throws -> RemoteCoupleRow {
        try await supabase
            .from("couples")
            .select("id,user_a,user_b,connection_composition")
            .eq("id", value: coupleId.uuidString)
            .single()
            .execute()
            .value
    }

    private func mirrorLink(
        coupleId: UUID,
        remoteCouple: RemoteCoupleRow,
        localProfileId: UUID
    ) throws {
        let context = ModelContext(modelContainer)

        var profileDescriptor = FetchDescriptor<UserProfile>()
        profileDescriptor.fetchLimit = 1
        guard let profile = try context.fetch(profileDescriptor).first else {
            throw PairingError.unknown("Debug seed could not find the local profile.")
        }
        profile.id = localProfileId
        profile.coupleId = coupleId
        profile.isLinked = true
        profile.linkedAt = Date()
        profile.firstInviteSentAt = nil

        let partnerA = remoteCouple.userA ?? localProfileId
        let partnerB = remoteCouple.userB ?? localProfileId
        var coupleDescriptor = FetchDescriptor<Couple>(
            predicate: #Predicate { $0.id == coupleId }
        )
        coupleDescriptor.fetchLimit = 1
        let couple: Couple
        if let existing = try context.fetch(coupleDescriptor).first {
            couple = existing
        } else {
            couple = Couple(partnerAId: partnerA, partnerBId: partnerB)
            context.insert(couple)
        }
        couple.id = coupleId
        couple.partnerAId = partnerA
        couple.partnerBId = partnerB
        if let raw = remoteCouple.connectionComposition,
           let composition = GenderDynamic(rawValue: raw) {
            couple.connectionComposition = composition
        }

        try context.saveWithLogging()
        appState.linkState = .linked
        appState.coupleId = coupleId
    }
}

#endif
