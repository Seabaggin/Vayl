//
//  VaultAgreementsSection.swift
//  Vayl
//
//  The Vault's Agreements segment (Phase A): the shared safe word, pending proposals
//  (the dual lock, you approve your partner's, they approve yours), the active list,
//  and an inline propose / edit / retire flow. Every change is a proposal that takes
//  effect only once both agree. Free. VaultStore owns the data + the async actions.
//

import SwiftUI
import SwiftData

struct VaultAgreementsSection: View {

    @Bindable var store: VaultStore
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var composingNew = false
    @State private var newText = ""
    @State private var editingId: UUID? = nil
    @State private var editText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            safeWordCard
            pendingProposals
            activeAgreements
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Safe word

    private var safeWordCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Shared safe word")
            HStack {
                Text(store.safeWord)
                    .font(AppFonts.display(20, weight: .bold, relativeTo: .title2))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "lifepreserver")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppColors.safetyAccent)
            }
            .padding(AppSpacing.md)
            .vaylGlassCard(accent: AppColors.safetyAccent)
        }
    }

    // MARK: - Pending proposals (the dual lock)

    @ViewBuilder
    private var pendingProposals: some View {
        if !store.proposals.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                MapSectionHeader(title: "Awaiting agreement")
                VStack(spacing: 0) {
                    ForEach(Array(store.proposals.enumerated()), id: \.element.id) { idx, p in
                        proposalRow(p)
                        if idx < store.proposals.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard(accent: AppColors.accentSecondary)
            }
        }
    }

    private func proposalRow(_ p: VaultStore.ProposalVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(proposalLabel(p))
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            if p.mineToDecide {
                HStack(spacing: AppSpacing.sm) {
                    Button("Not now") { decide(p, approve: false) }
                        .buttonStyle(.plain)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Approve") { decide(p, approve: true) }
                        .buttonStyle(PressableCardStyle())
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs + 1)
                        .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
                }
            } else {
                Text("Awaiting your partner")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
    }

    private func proposalLabel(_ p: VaultStore.ProposalVM) -> String {
        switch p.action {
        case "create": return "New agreement: \(p.proposedText ?? "")"
        case "edit":   return "Change to: \(p.proposedText ?? "")"
        case "retire": return "Retire an agreement"
        default:       return "A proposed change"
        }
    }

    // MARK: - Active agreements + propose

    private var activeAgreements: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Agreements")
            if store.agreements.isEmpty && !composingNew {
                VStack(spacing: 0) {
                    MapEmptyState(
                        icon: "doc.text",
                        headline: "No agreements yet",
                        message: "Propose one. It becomes active once you both agree, and changing it later needs you both too."
                    )
                    composeRow
                }
                .vaylGlassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(store.agreements) { a in
                        agreementRow(a)
                        Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                    }
                    composeRow
                }
                .vaylGlassCard()
            }
        }
    }

    private func agreementRow(_ a: VaultStore.AgreementVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(a.text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            if editingId == a.id {
                TextField("New wording", text: $editText, axis: .vertical)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Cancel") { editingId = nil }
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Propose change") {
                        propose(action: "edit", text: editText, target: a.id)
                        editingId = nil
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentPrimary)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: AppSpacing.lg) {
                    Button("Propose change") { editingId = a.id; editText = a.text }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentSecondary)
                    Button("Retire") { propose(action: "retire", text: nil, target: a.id) }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    private var composeRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if composingNew {
                TextField("Propose an agreement", text: $newText, axis: .vertical)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Cancel") { composingNew = false; newText = "" }
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Propose") {
                        propose(action: "create", text: newText, target: nil)
                        composingNew = false; newText = ""
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentPrimary)
                    .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .buttonStyle(.plain)
            } else {
                Button { composingNew = true } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("Propose an agreement")
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Actions

    private func propose(action: String, text: String?, target: UUID?) {
        Task {
            await store.propose(action: action, text: text, targetId: target,
                                appState: appState, context: modelContext)
        }
    }

    private func decide(_ p: VaultStore.ProposalVM, approve: Bool) {
        Task {
            await store.decideProposal(p.id, approve: approve,
                                       appState: appState, context: modelContext)
        }
    }
}
