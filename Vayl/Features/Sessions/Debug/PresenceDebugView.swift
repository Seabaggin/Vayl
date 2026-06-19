//
//  PresenceDebugView.swift
//  Vayl
//
//  THROWAWAY debug harness for Phase B1 (channel + presence). #if DEBUG only —
//  it never ships. Two devices join one couple channel with DISTINCT user ids
//  and watch each other appear / disappear. Delete once AirlockStore (B3) owns
//  the real channel lifecycle.
//

#if DEBUG
import SwiftUI
import Supabase

// MARK: - Store
// @Observable @MainActor so the View can bind directly. This is the temporary
// stand-in for AirlockStore (B3): it owns the channel lifecycle and the derived
// "who is present" set; the service stays a pure factory + helpers.

@Observable
@MainActor
final class PresenceDebugStore {

    enum ConnectionState: String {
        case idle, connecting, live, error
    }

    var coupleIdText: String = ""
    var userIdText: String = UUID().uuidString   // distinct per device by default
    var state: ConnectionState = .idle
    var presentUserIds: [String] = []
    var lastError: String?

    private let service = RealtimeSessionService()
    private var channel: RealtimeChannelV2?
    private var presenceTask: Task<Void, Never>?

    func join() {
        guard state == .idle || state == .error else { return }

        let coupleStr = coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        let userStr   = userIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let coupleId = UUID(uuidString: coupleStr),
              let userId   = UUID(uuidString: userStr) else {
            lastError = "Couple ID and User ID must both be valid UUIDs."
            state = .error
            return
        }

        lastError = nil
        state = .connecting
        presentUserIds = []

        let channel = service.sessionChannel(coupleId: coupleId, userId: userId)
        self.channel = channel

        // A Task created from a @MainActor context inherits MainActor isolation,
        // so the self mutations below are main-actor safe with no explicit hops.
        presenceTask = Task { [weak self] in
            guard let self else { return }

            // Register the presence stream BEFORE subscribing — ordering matters.
            let presence = channel.presenceChange()
            do {
                try await channel.subscribeWithError()
                try await self.service.trackPresence(on: channel, userId: userId)
                self.state = .live
            } catch {
                self.lastError = error.localizedDescription
                self.state = .error
                return
            }

            // Maintain the present set from join/leave deltas. Keys are user ids.
            for await change in presence {
                var present = Set(self.presentUserIds)
                present.formUnion(change.joins.keys)
                present.subtract(change.leaves.keys)
                self.presentUserIds = present.sorted()
            }
        }
    }

    func leave() {
        presenceTask?.cancel()
        presenceTask = nil
        presentUserIds = []
        state = .idle
        if let channel {
            self.channel = nil
            Task { await service.leaveChannel(channel) }
        }
    }
}

// MARK: - View

struct PresenceDebugView: View {

    @State private var store = PresenceDebugStore()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                Text("Presence Debug · B1")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Run on TWO devices. Use the SAME Couple ID and DIFFERENT User IDs. Tap Join on both — each should see the other's id appear. Tap Leave (or background) and it disappears on the partner.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)

                VStack(spacing: AppSpacing.sm) {
                    InteractiveField(placeholder: "Couple ID (UUID)", icon: "👥", text: $store.coupleIdText)
                    InteractiveField(placeholder: "User ID (UUID)", icon: "🆔", text: $store.userIdText)
                }

                HStack(spacing: AppSpacing.md) {
                    VaylButton(label: store.state == .live ? "Joined" : "Join", size: .compact) {
                        store.join()
                    }
                    VaylButton(label: "Leave", style: .secondary, size: .compact) {
                        store.leave()
                    }
                }

                statusRow

                if let error = store.lastError {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.destructive)
                }

                presenceList
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.pageBackground.ignoresSafeArea())
        .navigationTitle("Presence Debug")
    }

    private var statusRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: AppSpacing.sm, height: AppSpacing.sm)
            Text(store.state.rawValue.capitalized)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var statusColor: Color {
        switch store.state {
        case .idle:       return AppColors.textMuted
        case .connecting: return AppColors.accentSecondary
        case .live:       return AppColors.success
        case .error:      return AppColors.destructive
        }
    }

    @ViewBuilder
    private var presenceList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("PRESENT (\(store.presentUserIds.count))")
                .font(AppFonts.overline)
                .foregroundColor(AppColors.textTertiary)

            if store.presentUserIds.isEmpty {
                Text("No one here yet.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textMuted)
            } else {
                let me = store.userIdText.trimmingCharacters(in: .whitespacesAndNewlines)
                ForEach(store.presentUserIds, id: \.self) { id in
                    HStack(spacing: AppSpacing.sm) {
                        Text(id)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textBody)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if id == me {
                            Text("you")
                                .font(AppFonts.overline)
                                .foregroundColor(AppColors.accentPrimary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
#endif
