//
//  LockInSession.swift
//  Vayl
//
//  Location: Models/Persistence/LockInSession.swift
//

import Foundation
import SwiftData

// MARK: - LockInSession
// Records the pre-session emotional state check-in for both partners.
// Device only — never synced to Supabase.
//
// Lock In is the only place pre-session emotional state is captured.
// One Lock In interaction feeds two data points:
//   1. CardSession.lockInBandwidthA/B — session context
//   2. PulseStore — individual emotional history
//
// bandwidthGap is computed once on write — never recomputed on read.
// gapSurfaced prevents showing the "different places" moment twice
// for the same session.
// isLDR changes server-side Realtime handling for the session.

@Model
final class LockInSession {

    // MARK: - Identity

    var id: UUID
    var cardSessionId: UUID

    // MARK: - Bandwidth

    var partnerABandwidth: Float    // 0.0-1.0
    var partnerBBandwidth: Float    // 0.0-1.0
    var bandwidthGap: Float         // abs(A - B) — computed once on write

    // MARK: - State

    var gapSurfaced: Bool           // was "different places" moment shown
    var isLDR: Bool                 // changes Realtime handling server-side

    // MARK: - Timestamps

    var startedAt: Date
    var completedAt: Date?

    // MARK: - Init

    init(
        cardSessionId: UUID,
        bandwidthA: Float,
        bandwidthB: Float,
        isLDR: Bool = false
    ) {
        self.id = UUID()
        self.cardSessionId = cardSessionId
        self.partnerABandwidth = bandwidthA
        self.partnerBBandwidth = bandwidthB
        self.bandwidthGap = abs(bandwidthA - bandwidthB)    // computed once here
        self.gapSurfaced = false
        self.isLDR = isLDR
        self.startedAt = Date()
        self.completedAt = nil
    }

    // MARK: - Computed

    /// Whether the bandwidth gap is significant enough to surface
    /// the "different places" moment to both partners.
    /// Threshold is 0.4 — meaningful gap without being alarmist.
    var hasSignificantGap: Bool {
        bandwidthGap >= 0.4
    }

    /// Both partners are in a high bandwidth state.
    var bothExpansive: Bool {
        partnerABandwidth >= 0.7 && partnerBBandwidth >= 0.7
    }

    /// Both partners are in a low bandwidth state.
    var bothProtective: Bool {
        partnerABandwidth <= 0.3 && partnerBBandwidth <= 0.3
    }

    // MARK: - Preview Helpers

    static let example = LockInSession(
        cardSessionId: UUID(),
        bandwidthA: 0.8,
        bandwidthB: 0.7
    )

    static let gapExample = LockInSession(
        cardSessionId: UUID(),
        bandwidthA: 0.9,
        bandwidthB: 0.3
    )

    static let lowExample = LockInSession(
        cardSessionId: UUID(),
        bandwidthA: 0.2,
        bandwidthB: 0.3
    )
}