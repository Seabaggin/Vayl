// Tabs/LearnTab/Views/Sections/ContentHubSection.swift
//
// Section 2 — Content Hub. A segmented control over four panels: Books (cover
// shelf), Watch + Listen (media rows), Voices (circular avatars + a
// Creators/Researchers filter). Third-party media: where to go deeper.
//
// 2026-07-16 — every row now opens ContentItemSheet, Vayl's own background on the
// thing, with the outbound doors inside it. Two rewrites got us here:
//
// 1. Rows were `Button {}` — an empty action — while drawing a chevron that
//    promised navigation. Both models carried `link: String?` that no view read.
// 2. So rows opened the link directly. But that made the row's destination
//    hostage to an external URL, and every link in the corpus was null — the whole
//    hub rendered untappable. A row should not depend on a vendor's URL existing.
//
// Now the destination is ours. The chevron is honest again (it opens a sheet
// inside Vayl); `arrowUpRight` moved into the sheet, on the links that actually
// leave. Vayl links a profile, never a link-aggregator page.
//
// Accent unified to purple: magenta means Us/shared and Learn is a private, solo
// surface — the Don't-Cross-the-Wires rule, not a taste call. The per-tab spectrum
// sweep (cyan/bridge/purple/magenta) went with it; it made each panel look like a
// different product.

import SwiftUI

struct ContentHubSection: View {
    let store: LearnStore

    @State private var tab: HubTab = .books
    @State private var selected: HubItem?
    /// nil = all topics.
    @State private var voiceTopic: VoiceTopic?

    /// One accent for the whole hub, matching the Knowledge hub's. Purple is the
    /// spectrum midpoint and carries no directional meaning, unlike cyan (Me) and
    /// magenta (Us) — correct for content, which is nobody's data.
    private let accent = AppColors.spectrumPurple

    enum HubTab: String, CaseIterable, Identifiable {
        case books, watch, listen, voices
        var id: String { rawValue }
        var label: String {
            switch self {
            case .books: return "Books"; case .watch: return "Watch"
            case .listen: return "Listen"; case .voices: return "Voices"
            }
        }
        var icon: String {
            switch self {
            case .books:  return AppIcons.booksVertical
            case .watch:  return AppIcons.playRectangle
            case .listen: return AppIcons.waveform
            case .voices: return AppIcons.person2
            }
        }
        var accent: Color { AppColors.spectrumPurple }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Content hub")
                .font(AppFonts.sectionHeading)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSectionLabel)

            VStack(spacing: AppSpacing.md) {
                SegmentedPillGroup(
                    options: HubTab.allCases.map { .init($0, label: $0.label, icon: $0.icon, accent: $0.accent) },
                    selection: $tab
                )

                Group {
                    switch tab {
                    case .books:  bookShelf
                    case .watch:  mediaList(.show, tag: "Watch")
                    case .listen: mediaList(.podcast, tag: "Listen")
                    case .voices: voicesPanel
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .learnCard()
        }
        .vaylSheet(isPresented: sheetBinding, heightFraction: 0.7) {
            if let selected { ContentItemSheet(item: selected) }
        }
    }

    private var sheetBinding: Binding<Bool> {
        Binding(get: { selected != nil },
                set: { if !$0 { selected = nil } })
    }

    // MARK: - Books

    @ViewBuilder
    private var bookShelf: some View {
        if store.media(.book).isEmpty {
            emptyPanel(headline: "No books yet",
                       message: "Reading worth your time will show up here.")
        } else {
            bookScroller
        }
    }

    private var bookScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                ForEach(store.media(.book)) { book in
                    Button { selected = .media(book) } label: { bookCover(book) }
                        .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    private func bookCover(_ b: LearnMediaItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ZStack(alignment: .topLeading) {
                coverImage(b.artworkUrl)
                    .frame(width: 118, height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderSubtle, lineWidth: 1))
                if let tier = b.tier {
                    Text(tier)
                        .font(AppFonts.label)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1))
                        .padding(AppSpacing.xs)
                }
            }
            Text(b.title)
                .font(AppFonts.caption).bold()
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
            Text(b.positioning)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
        .frame(width: 118, alignment: .leading)
    }

    @ViewBuilder
    private func coverImage(_ url: String?) -> some View {
        if let url, let u = URL(string: url) {
            AsyncImage(url: u) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(AppColors.cardBackground)
            }
        } else {
            Rectangle().fill(AppColors.cardBackground)
        }
    }

    // MARK: - Media rows (Watch / Listen)

    private func mediaList(_ kind: MediaKind, tag: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            if store.media(kind).isEmpty {
                emptyPanel(headline: "Nothing here yet",
                           message: "\(tag) picks will show up here.")
            } else {
                ForEach(store.media(kind)) { item in
                    Button { selected = .media(item) } label: { mediaRow(item, tag: tag) }
                        .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    private func mediaRow(_ m: LearnMediaItem, tag: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            thumb(url: m.artworkUrl, icon: kindIcon(m.kind))
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(tag)
                    .overlineTracked()
                    .foregroundStyle(AppColors.textTertiary)
                Text(m.title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(m.positioning)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                if let platform = m.platform { platformBadge(platform) }
            }
            Spacer(minLength: 0)
            // A chevron again, honestly: this opens a sheet inside Vayl. The
            // up-right arrow lives in that sheet, on the links that do leave.
            Image(systemName: AppIcons.chevronRight)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Voices

    /// Creators only — see Voice.swift for why researchers aren't listed here.
    ///
    /// The old Creators/Researchers control filtered on CREDENTIAL, which is why it
    /// collapsed the moment the researchers came out. This filters on TOPIC: the
    /// shape of non-monogamy someone's work is about, which is a real property of
    /// the work and roughly the shape-space a couple is choosing between. Chips
    /// rather than a second SegmentedPillGroup — a segmented control nested inside a
    /// segmented control is the thing that made this section read as chrome.
    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if store.voices.isEmpty {
                emptyPanel(headline: "No voices yet",
                           message: "People worth following will show up here.")
            } else {
                if topicsPresent.count > 1 { topicChips }
                if visibleVoices.isEmpty {
                    emptyPanel(headline: "None here yet",
                               message: "Nobody in this corner of the map yet.")
                } else {
                    ForEach(visibleVoices) { voice in
                        Button { selected = .voice(voice) } label: { voiceRow(voice) }
                            .buttonStyle(PressableCardStyle())
                    }
                }
            }
        }
    }

    /// Only offer a filter for topics the corpus actually has.
    private var topicsPresent: [VoiceTopic] {
        VoiceTopic.allCases.filter { t in store.voices.contains { $0.topic == t } }
    }

    private var visibleVoices: [Voice] {
        guard let voiceTopic else { return store.voices }
        return store.voices.filter { $0.topic == voiceTopic }
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                topicChip("All", on: voiceTopic == nil) { voiceTopic = nil }
                ForEach(topicsPresent) { t in
                    topicChip(t.label, on: voiceTopic == t) { voiceTopic = t }
                }
            }
        }
    }

    private func topicChip(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(AppAnimation.standard) { action() }
        } label: {
            Text(label)
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(minHeight: 44)
                .background(Capsule()
                    .fill(on ? accent.opacity(0.2) : AppColors.whisperFill)
                    .overlay(Capsule().stroke(on ? accent.opacity(0.45) : AppColors.borderSubtle,
                                              lineWidth: 1)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    /// The hub's panels can each render zero rows once the corpus changes; the
    /// contract wants an empty state on every data surface, and a bare ForEach
    /// renders blank space inside the glass card.
    private func emptyPanel(headline: String, message: String) -> some View {
        VaylEmptyState(
            icon: AppIcons.textMagnifyingglass,
            headline: headline,
            message: message
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    /// No avatar. `thumb(url: nil, icon: .personFill)` drew the identical grey
    /// person glyph beside all 24 names — an avatar slot with no avatar, spending
    /// 52pt of row width to convey nothing. A book has a cover, so `mediaRow`
    /// showing artwork is information; a person here has no image asset, so the
    /// name is the identity. Text-only reads as a reference, which is the job.
    private func voiceRow(_ v: Voice) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // "Poly educator" — topic + mode. Never exceeds their own claim.
                Text(v.label)
                    .overlineTracked()
                    .foregroundStyle(AppColors.textTertiary)
                Text(v.name)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(v.blurb)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: AppIcons.chevronRight)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Shared bits

    /// Media artwork only. The circular variant existed for voice avatars; with
    /// those gone, nothing calls it.
    private func thumb(url: String?, icon: String) -> some View {
        coverOrIcon(url: url, icon: icon)
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(accent.opacity(0.2), lineWidth: 1))
    }

    @ViewBuilder
    private func coverOrIcon(url: String?, icon: String) -> some View {
        if let url, let u = URL(string: url) {
            AsyncImage(url: u) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { iconTile(icon) }
        } else {
            iconTile(icon)
        }
    }

    private func iconTile(_ icon: String) -> some View {
        ZStack {
            accent.opacity(0.08)
            Image(systemName: icon)
                .font(AppFonts.body(20, weight: .regular, relativeTo: .body))
                .foregroundStyle(accent)
        }
    }

    private func platformBadge(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.meta)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(Capsule().fill(AppColors.whisperFill)
                .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1)))
    }

    private func kindIcon(_ kind: MediaKind) -> String {
        switch kind {
        case .book:    return AppIcons.bookClosedFill
        case .show:    return AppIcons.playRectangleFill
        case .podcast: return AppIcons.waveform
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView { ContentHubSection(store: LearnStore()).padding() }
    }
}
