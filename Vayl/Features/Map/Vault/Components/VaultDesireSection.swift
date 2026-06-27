//
//  VaultDesireSection.swift
//  Vayl
//
//  The Vault's Desire Map segment (Segment 1): your private map summary, where you
//  align (revealed mutual/adjacent), a locked-more paywall row, and a placeholder for
//  the consent exchange (Segment 4). Display-only; VaultStore owns the data.
//
//  NOTE: the align row + match badge below intentionally mirror MapUsLayer's; factor
//  into one shared component during the Segment 6 cohesion sweep.
//

import SwiftUI

struct VaultDesireSection: View {

    let summary: VaultStore.DesireSummary
    let align: [MapStore.AlignItem]
    let lockedCount: Int
    var onUnlock: () -> Void
    let store: VaultStore

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            yourMap
            whereYouAlign
            openAConversation
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Your map

    private var yourMap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Your map")
            if summary.rated == 0 {
                MapEmptyState(
                    icon: "circle.grid.2x2",
                    headline: "Your map is empty",
                    message: "Complete your Desire Map and your private summary appears here."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        countChip("\(summary.rated)", "rated")
                        countChip("\(summary.yes)", "yes", tint: AppColors.spectrumCyan)
                        countChip("\(summary.curious)", "curious", tint: AppColors.spectrumBridge)
                        countChip("\(summary.kept)", "private", tint: AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.md)
                .vaylGlassCard()

                Text("Only you ever see what you keep private.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func countChip(_ value: String, _ label: String, tint: Color = AppColors.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.display(18, weight: .bold, relativeTo: .title3))
                .foregroundStyle(tint)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Where you align

    private var whereYouAlign: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Where you align")
            if align.isEmpty {
                MapEmptyState(
                    icon: "diamond",
                    headline: "No matches yet",
                    message: "Revealed together, the overlap appears here, only ever the overlap, never the gaps."
                )
                .vaylGlassCard()
            } else {
                let shown = Array(align.prefix(6))
                VStack(spacing: 0) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, item in
                        alignRow(item)
                        if idx < shown.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                    if lockedCount > 0 { lockedRow }
                }
                .vaylGlassCard()
            }
        }
    }

    private func alignRow(_ item: MapStore.AlignItem) -> some View {
        let tier: CompanionCardTier = item.isMutual ? .mutual : .adjacent
        return Button {
            store.openDiscussion(itemId: item.id, itemName: item.name, tier: tier)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "diamond")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.spectrumBridge)
                Text(item.name)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Spacer()
                badge(item.isMutual)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    private func badge(_ isMutual: Bool) -> some View {
        let tint = isMutual ? AppColors.spectrumCyan : AppColors.spectrumBridge
        return Text(isMutual ? "Mutual" : "Adjacent")
            .font(AppFonts.overline)
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs + 1)
            .background(Capsule().fill(tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
    }

    private var lockedRow: some View {
        Button(action: onUnlock) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
                Text("\(lockedCount) more where you align")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("Unlock the full map")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.accentPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Open a conversation (Segment 4 placeholder)

    private var openAConversation: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Open a conversation")

            let isEmpty = store.incoming.isEmpty && store.openedConsent.isEmpty
                && store.myAsks.isEmpty && store.askableTopics.isEmpty
            if isEmpty {
                MapEmptyState(
                    icon: "bubble.left.and.bubble.right",
                    headline: "Nothing to open yet",
                    message: "When you're curious about something private, ask to open it together here. A decline never discloses."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(store.incoming) { incomingCard($0) }
                    ForEach(store.openedConsent) { openedRow($0) }
                    ForEach(store.myAsks) { waitingRow($0) }
                    ForEach(store.askableTopics) { askRow($0) }
                }
            }
        }
    }

    private func incomingCard(_ c: VaultStore.ConsentVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your partner asked to open this together")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
            Text(c.itemName)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text("Open it and a neutral card appears for you both. Pass, and they are never told it was a no.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppSpacing.sm) {
                Button("Not now") { respond(c, open: false) }
                    .buttonStyle(.plain)
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Button("Open it") { respond(c, open: true) }
                    .buttonStyle(PressableCardStyle())
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs + 1)
                    .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
            }
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(accent: AppColors.accentSecondary)
    }

    private func openedRow(_ c: VaultStore.ConsentVM) -> some View {
        Button {
            store.openDiscussion(itemId: c.itemId, itemName: c.itemName, tier: .consentOpened)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.spectrumCyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.itemName).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                    Text("Opened together").font(AppFonts.caption).foregroundStyle(AppColors.spectrumCyan)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .vaylGlassCard()
        }
        .buttonStyle(PressableCardStyle())
    }

    private func waitingRow(_ c: VaultStore.ConsentVM) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.itemName).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Text("Asked, waiting").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private func askRow(_ t: VaultStore.ConsentTopic) -> some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 1) {
                Text(t.name).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Text("You're curious. Ask to open it together.")
                    .font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
            Button("Ask") { ask(t.id) }
                .buttonStyle(PressableCardStyle())
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs + 1)
                .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
        }
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private func ask(_ itemId: String) {
        Task { await store.askToOpen(itemId: itemId, appState: appState, context: modelContext) }
    }

    private func respond(_ c: VaultStore.ConsentVM, open: Bool) {
        Task { await store.respondToOpen(itemId: c.itemId, open: open, appState: appState, context: modelContext) }
    }
}
