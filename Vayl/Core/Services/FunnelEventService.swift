//
//  FunnelEventService.swift
//  Vayl
//
//  Observability layer 1 (Desire Map launch hardening, review 2026-07-09): a thin,
//  fire-and-forget event trail at the reveal/purchase funnel joints, so a report like
//  "I paid and nothing unlocked" can be reconstructed server-side without the device.
//
//  PAYLOAD RULE (privacy, non-negotiable): `event` and `detail` carry NO desire content —
//  never an item id, never a match name. Ids, event names, build number, and error
//  strings only. The table is service-role-read-only; clients can only insert own rows.
//
//  Best-effort by design: a failed insert is logged locally and dropped — observability
//  must never block or break the funnel it observes.
//

import Foundation
import OSLog
import Supabase

enum FunnelEvent: String {
    case revealOpened      = "reveal_opened"
    case beat2Reached      = "beat2_reached"
    case paywallOpened     = "paywall_opened"
    case purchaseStarted   = "purchase_started"
    case purchaseSucceeded = "purchase_succeeded"
    case purchaseFailed    = "purchase_failed"
    case purchasePending   = "purchase_pending"
    case grantRetried      = "grant_retried"
    case unlockRendered    = "unlock_rendered"
    case computeSelfHeal   = "compute_selfheal_fired"
}

@MainActor
final class FunnelEventService {

    static let shared = FunnelEventService()

    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private let profileService = ProfileService()
    private let logger = Logger(subsystem: "com.vayl.app", category: "FunnelEvents")

    private struct Row: Encodable {
        let userId: String
        let coupleId: String?
        let event: String
        let detail: String?
        let build: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case coupleId = "couple_id"
            case event, detail, build
        }
    }

    private static let build: String = {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }()

    /// Fire-and-forget. `detail` must follow the payload rule (error strings / counts only).
    func log(_ event: FunnelEvent, coupleId: UUID?, detail: String? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let authId = try await supabase.auth.session.user.id
                let profileId = try await profileService.ensureProfileExists(authId: authId)
                let row = Row(
                    userId: profileId.uuidString,
                    coupleId: coupleId?.uuidString,
                    event: event.rawValue,
                    detail: detail,
                    build: Self.build
                )
                try await supabase.from("desire_funnel_events").insert(row).execute()
            } catch {
                logger.info("funnel event \(event.rawValue) dropped: \(error.localizedDescription)")
            }
        }
    }
}
