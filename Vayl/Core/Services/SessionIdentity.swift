//
//  SessionIdentity.swift
//  Vayl — Core
//
//  Shared local-identity resolution for opening/joining a curated session:
//  the local SwiftData profile id, and which SessionRole (a/b) that profile
//  occupies on a couple's row. Extracted verbatim from PlayStore so Home can
//  eventually open a session the same way Play does (Task 3a, pure refactor
//  — SessionEntryStore keeps its own private copies for now; dedup deferred).
//

import Foundation
import SwiftData

enum SessionIdentity {

    /// The local SwiftData profile id (auth-id vs profile-id convention: this
    /// is the PROFILE id, which is what couples rows reference).
    static func localProfileId(context: ModelContext, coupleId: UUID?) -> UUID? {
        localProfile(context: context)?.id
    }

    /// SessionRole identity rule (spec 4.2, hard): derives from the local
    /// Couple row's partnerAId vs my LOCAL profile id. Never the supabase
    /// auth id.
    static func role(context: ModelContext, coupleId: UUID?, profileId: UUID) -> SessionRole {
        guard let coupleId else { return .a }
        var fetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        fetch.fetchLimit = 1
        guard let couple = try? context.fetch(fetch).first else { return .a }
        return couple.partnerAId == profileId ? .a : .b
    }

    /// The local SwiftData profile row (single-profile device convention).
    private static func localProfile(context: ModelContext) -> UserProfile? {
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first
    }
}
