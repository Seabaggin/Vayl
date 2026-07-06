//
//  PresenceDebugView.swift
//  Vayl
//
//  THROWAWAY debug harness for the Airlock handshake. #if DEBUG only — it never
//  ships. Two devices, SAME couple, each signed in as its own partner. One taps
//  "Open row" (initiator, stub draft), then BOTH tap "Start". Both commit
//  Bandwidth, then Lock in. The row flips `active` exactly once; both reach
//  ACTIVE. "Force poll" exercises the no-realtime path. Delete once the real
//  Airlock UI (Section 2) owns the cover.
//

#if DEBUG
import SwiftUI
import SwiftData
import Supabase

// MARK: - Driver
// Thin @Observable wrapper around the real AirlockStore. The ONLY place the
// harness cheats: openRow() calls RealtimeSessionService directly with a stub
// draft, because the store only ever fetches (the Builder/Lobby opens the row
// in shipping code). Acceptable in a #if DEBUG throwaway, never in production.

@Observable
@MainActor
final class AirlockHarnessDriver {

    var coupleIdText: String = ""
    var status: String = "idle"
    private(set) var store: AirlockStore?

    private let modelContainer: ModelContainer
    init(modelContainer: ModelContainer) { self.modelContainer = modelContainer }

    func openRow() {
        guard let coupleId = UUID(uuidString: coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            status = "Couple ID must be a valid UUID."; return
        }
        Task {
            do {
                let context = ModelContext(modelContainer)
                guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
                    status = "No local UserProfile."; return
                }
                let draft = CuratedSessionDraft(
                    deckId: "debug", deckVariant: nil,
                    cardIds: [], perCardTimer: [:], globalTimerSeconds: nil
                )
                _ = try await RealtimeSessionService().openSession(
                    coupleId: coupleId, initiatorId: profile.id, draft: draft
                )
                status = "row opened, now Start on both devices"
            } catch {
                status = "open failed: \(error.localizedDescription)"
            }
        }
    }

    func startStore() {
        guard let coupleId = UUID(uuidString: coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            status = "Couple ID must be a valid UUID."; return
        }
        guard let s = AirlockStore.make(coupleId: coupleId, modelContainer: modelContainer) else {
            status = "Could not resolve local Couple / UserProfile."; return
        }
        store = s
        status = "role \(s.role.rawValue) · starting"
        Task { await s.start() }
    }

    func bandwidth() { Task { await store?.commitBandwidth(0.55) } }
    func lockIn()    { Task { await store?.consent() } }
    func forcePoll() { Task { await store?.forcePollMode() } }
    func leave()     { store?.leave(); store = nil; status = "left" }
}

// MARK: - View

struct PresenceDebugView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var driver: AirlockHarnessDriver?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                Text("Airlock Handshake")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Run on TWO physical devices, SAME Couple ID, each signed in as its own partner. One taps Open row, then BOTH tap Start. Commit Bandwidth, then Lock in on both. The row flips to active exactly once and both show ACTIVE. Force poll to test the no-realtime path.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)

                if let driver {
                    InteractiveField(placeholder: "Couple ID (UUID)", icon: "👥",
                                     text: Binding(get: { driver.coupleIdText },
                                                   set: { driver.coupleIdText = $0 }))

                    HStack(spacing: AppSpacing.md) {
                        VaylButton(label: "Open row", size: .compact) { driver.openRow() }
                        VaylButton(label: "Start", style: .secondary, size: .compact) { driver.startStore() }
                    }
                    HStack(spacing: AppSpacing.md) {
                        VaylButton(label: "Bandwidth", size: .compact) { driver.bandwidth() }
                        VaylButton(label: "Lock in", style: .secondary, size: .compact) { driver.lockIn() }
                    }
                    HStack(spacing: AppSpacing.md) {
                        VaylButton(label: "Force poll", style: .secondary, size: .compact) { driver.forcePoll() }
                        VaylButton(label: "Leave", style: .secondary, size: .compact) { driver.leave() }
                    }

                    stateReadout(driver)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.pageBackground.ignoresSafeArea())
        .navigationTitle("Airlock Handshake")
        .task {
            if driver == nil {
                driver = AirlockHarnessDriver(modelContainer: modelContext.container)
            }
        }
    }

    @ViewBuilder
    private func stateReadout(_ driver: AirlockHarnessDriver) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(driver.status)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)

            if let store = driver.store {
                row("transport", store.transport.rawValue)
                row("state", stateLabel(store.state))
                row("partner present", store.partnerPresent ? "yes" : "no")
                row("you consented", store.selfConsented ? "yes" : "no")
                row("partner consented", store.partnerConsented ? "yes" : "no")
                row("depth ceiling", store.depthCeiling.map { String(format: "%.2f", $0) } ?? "-")
            } else {
                // Empty state (required on every data screen).
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundColor(AppColors.textTertiary)
                    Text("No handshake yet")
                        .font(AppFonts.cardTitle)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Enter a Couple ID, tap Open row on one device, then Start.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(AppFonts.caption).foregroundColor(AppColors.textTertiary)
            Spacer()
            Text(v).font(AppFonts.caption).foregroundColor(AppColors.textBody)
        }
    }

    private func stateLabel(_ s: AirlockState) -> String {
        switch s {
        case .waitingForPartner:      return "waiting for partner"
        case .bothPresent:            return "both present"
        case .bandwidthSet:           return "bandwidth set"
        case .consented:              return "consented"
        case .activating:             return "activating"
        case .active:                 return "ACTIVE"
        case .failed(let reason):     return "failed: \(reason)"
        }
    }
}
#endif
