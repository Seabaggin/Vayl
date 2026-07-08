//
//  EventEntryEditor.swift
//  Vayl
//
//  Add / edit one Event Log entry, presented as a .vaylSheet from the Vault. Date,
//  what happened, how it felt (one mood, distinct from the Pulse), tags, who (free
//  text), notes, and a prominent private / shared toggle. Save writes through VaultStore
//  (local first, then sync). Free.
//

import SwiftUI
import SwiftData

struct EventEntryEditor: View {

    let entry: EventLogEntry?
    let store: VaultStore
    var onDone: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var date: Date
    @State private var title: String
    @State private var note: String
    @State private var mood: EventMood?
    @State private var tags: Set<EventTag>
    @State private var who: String
    @State private var visibility: EventVisibility

    init(entry: EventLogEntry?, store: VaultStore, onDone: @escaping () -> Void) {
        self.entry = entry
        self.store = store
        self.onDone = onDone
        _date = State(initialValue: entry?.occurredOn ?? Date())
        _title = State(initialValue: entry?.title ?? "")
        _note = State(initialValue: entry?.note ?? "")
        _mood = State(initialValue: entry?.moodValue)
        _tags = State(initialValue: Set(entry?.tagValues ?? []))
        _who = State(initialValue: entry?.who ?? "")
        _visibility = State(initialValue: EventVisibility(rawValue: entry?.visibility ?? "private") ?? .onlyMe)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(entry == nil ? "New entry" : "Edit entry")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)

                field("When") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.accentPrimary)
                }
                field("What happened") {
                    TextField("A date, a night, a moment", text: $title)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                }
                field("How it felt") { moodRow }
                field("Tags") { tagRow }
                field("Who") {
                    TextField("optional", text: $who)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                }
                field("Notes") {
                    TextField("optional", text: $note, axis: .vertical)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(3...8)
                }
                field("Visibility") {
                    LearnSegmented<EventVisibility>(
                        items: [.init(.onlyMe, "Private"), .init(.shared, "Shared")],
                        selection: $visibility,
                        accent: AppColors.accentSecondary
                    )
                }
                Text(visibility == .onlyMe ? "Only you can ever see this." : "Shared with your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)

                saveButton
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label.uppercased())
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            content()
        }
    }

    private var moodRow: some View {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(EventMood.allCases) { m in
                chip(m.label, selected: mood == m) { mood = (mood == m ? nil : m) }
            }
        }
    }

    private var tagRow: some View {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(EventTag.allCases) { t in
                chip(t.label, selected: tags.contains(t)) {
                    if tags.contains(t) { tags.remove(t) } else { tags.insert(t) }
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(selected ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs + 1)
                .background(Capsule().fill(selected ? AppColors.accentSecondary.opacity(0.25) : AppColors.glassSurface))
                .overlay(Capsule().strokeBorder(selected ? AppColors.accentSecondary.opacity(0.55) : AppColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
    }

    private var saveButton: some View {
        let blank = title.trimmingCharacters(in: .whitespaces).isEmpty
        return Button {
            store.saveEntry(
                id: entry?.id, date: date, title: title,
                note: note.isEmpty ? nil : note, mood: mood,
                tags: Array(tags), who: who.isEmpty ? nil : who,
                visibility: visibility, appState: appState, context: modelContext)
            onDone()
        } label: {
            Text("Save")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textBody)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Capsule().fill(AppColors.accentSecondary))
        }
        .buttonStyle(PressableCardStyle())
        .disabled(blank)
        .opacity(blank ? 0.5 : 1)
    }
}
