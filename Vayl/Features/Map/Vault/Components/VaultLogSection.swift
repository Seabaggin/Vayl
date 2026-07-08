//
//  VaultLogSection.swift
//  Vayl
//
//  The Vault's Log segment (Phase B): a newest-first timeline of event entries with a
//  per-entry private / shared marker, mood, who, and tags. Tapping an entry edits it;
//  "Add" opens the editor. Display-only; VaultStore owns the data, the editor writes.
//

import SwiftUI

struct VaultLogSection: View {

    let entries: [EventLogEntry]
    var onAdd: () -> Void
    var onEdit: (EventLogEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Your log", linkLabel: "Add", onLink: onAdd)

            if entries.isEmpty {
                MapEmptyState(
                    icon: "book",
                    headline: "No entries yet",
                    message: "Log a date, a night, a feeling. Keep it private, or share it with your partner."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, e in
                        row(e)
                        if idx < entries.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard()
            }
        }
    }

    private func row(_ e: EventLogEntry) -> some View {
        Button { onEdit(e) } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .top) {
                    Text(e.title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Spacer()
                    Image(systemName: e.isShared ? "person.2.fill" : "lock.fill")
                        .font(AppFonts.body(10, weight: .regular, relativeTo: .caption2))
                        .foregroundStyle(AppColors.textTertiary)
                }

                HStack(spacing: AppSpacing.xs) {
                    Text(e.occurredOn, format: .dateTime.month().day())
                    if let m = e.moodValue { Text("·"); Text(m.label) }
                    if let who = e.who, !who.isEmpty { Text("·"); Text(who) }
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

                if !e.tagValues.isEmpty {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(e.tagValues) { t in
                            Text(t.label)
                                .font(AppFonts.overline)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppColors.glassSurface))
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
