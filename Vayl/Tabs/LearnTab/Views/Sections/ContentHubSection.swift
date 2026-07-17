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
    /// Presentation is the screen's job, not a section's. `.vaylSheet` renders as
    /// an overlay sized from its host's geometry, so attaching it here — inside
    /// LearnView's ScrollView — measured the SECTION's height, not the screen: the
    /// scrim dimmed the display while the sheet resolved to a fraction of a section.
    /// The section reports selection up; LearnView presents.
    var onSelect: (HubItem) -> Void = { _ in }
    var onSeeAllVoices: () -> Void = {}

    @State private var tab: HubTab = .books

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
        /// Purple marks the SELECTED segment — the one thing on this control you
        /// can act on. It is the only colour left in the hub; artwork, icon tiles
        /// and labels are neutral because they're content.
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
                    Button { onSelect(.media(book)) } label: { bookCover(book) }
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
                    Button { onSelect(.media(item)) } label: { mediaRow(item, tag: tag) }
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
    /// A sample, not the whole shelf. 24 creators inline made the card a scroll
    /// inside a scroll with no shape to it: nothing to take in, no way to tell how
    /// much was left. This shows a rotating handful over a "See all" door — the
    /// same recent-plus-door shape the journal threshold uses. The topic filter
    /// lives behind that door, where a list long enough to need filtering actually
    /// is; a filter over four rows would be chrome again.
    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if store.voices.isEmpty {
                emptyPanel(headline: "No voices yet",
                           message: "People worth following will show up here.")
            } else {
                // Computed once, not per ForEach + per count check.
                let sample = store.voicesSample()
                ForEach(sample) { voice in
                    Button { onSelect(.voice(voice)) } label: { voiceRow(voice) }
                        .buttonStyle(PressableCardStyle())
                }
                if store.voices.count > sample.count { seeAllVoices }
            }
        }
    }

    private var seeAllVoices: some View {
        Button { onSeeAllVoices() } label: {
            HStack(spacing: AppSpacing.xs) {
                Text("See all \(store.voices.count)")
                    .font(AppFonts.buttonLabel)
                Image(systemName: AppIcons.chevronRight)
                    .font(AppFonts.caption)
            }
            .foregroundStyle(AppColors.textAccent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
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
    /// Neutral stroke. Artwork is content — it isn't a control, so it doesn't wear
    /// the accent. Purple in Learn means "you can act here": links and selection.
    private func thumb(url: String?, icon: String) -> some View {
        coverOrIcon(url: url, icon: icon)
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 1))
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

    /// The artwork fallback — also content, also neutral.
    private func iconTile(_ icon: String) -> some View {
        ZStack {
            AppColors.whisperFill
            Image(systemName: icon)
                .font(AppFonts.body(20, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textTertiary)
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
