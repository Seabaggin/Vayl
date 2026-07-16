// Tabs/LearnTab/Views/Sections/ContentHubSection.swift
//
// Section 2 — Content Hub. A segmented control over four panels: Books (cover
// shelf), Watch + Listen (media rows), Voices (circular avatars + a
// Creators/Researchers filter). Third-party media: where to go deeper.
//
// Polish pass 2026-07-16:
// • Every row was a `Button {}` — an empty action — while media and voice rows
//   drew a chevron promising navigation. Both models have carried `link: String?`
//   all along; the views just never read it. Rows now open their link, and a row
//   with no link renders as plain content with no tap target and no arrow. An
//   affordance that does nothing is worse than no affordance.
// • The arrow is `arrowUpRight`, not `chevronRight`: these leave the app for
//   Safari. A chevron means "push deeper in Vayl" everywhere else, and
//   ResourcesOverlayView already uses the up-right arrow for exactly this.
// • Accent unified to purple. Magenta means Us/shared and Learn is a private,
//   solo surface — that's the Don't-Cross-the-Wires rule, not a taste call. The
//   per-tab spectrum sweep (cyan/bridge/purple/magenta) is gone too: it made each
//   panel look like a different product.

import SwiftUI

struct ContentHubSection: View {
    let store: LearnStore

    @Environment(\.openURL) private var openURL
    @State private var tab: HubTab = .books

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
                    // A cover with nowhere to go is just a cover.
                    if let url = link(book.link) {
                        Button { openURL(url) } label: { bookCover(book) }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityHint("Opens in Safari")
                    } else {
                        bookCover(book)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    /// Non-empty, parseable links only — a blank string in the corpus must not
    /// produce a tap target that opens nothing.
    private func link(_ raw: String?) -> URL? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: raw)
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
                    if let url = link(item.link) {
                        Button { openURL(url) } label: { mediaRow(item, tag: tag, linked: true) }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityHint("Opens in Safari")
                    } else {
                        mediaRow(item, tag: tag, linked: false)
                    }
                }
            }
        }
    }

    private func mediaRow(_ m: LearnMediaItem, tag: String, linked: Bool) -> some View {
        HStack(spacing: AppSpacing.md) {
            thumb(url: m.artworkUrl, icon: kindIcon(m.kind), circle: false)
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
            // Up-right, not a chevron: this leaves the app. Only when it does.
            if linked {
                Image(systemName: AppIcons.arrowUpRight)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Voices

    /// Creators only — see Voice.swift for why researchers aren't listed here.
    /// The Creators/Researchers filter is gone with them; a segmented control over
    /// one category was chrome pretending the shelf was deeper than it is.
    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if store.voices.isEmpty {
                emptyPanel(headline: "No voices yet",
                           message: "People worth following will show up here.")
            } else {
                ForEach(store.voices) { voice in
                    if let url = link(voice.link) {
                        Button { openURL(url) } label: { voiceRow(voice, linked: true) }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityHint("Opens in Safari")
                    } else {
                        voiceRow(voice, linked: false)
                    }
                }
            }
        }
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

    private func voiceRow(_ v: Voice, linked: Bool) -> some View {
        HStack(spacing: AppSpacing.md) {
            thumb(url: nil, icon: AppIcons.personFill, circle: true)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(v.role)
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
                platformBadge(v.platform)
            }
            Spacer(minLength: 0)
            if linked {
                Image(systemName: AppIcons.arrowUpRight)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Shared bits

    @ViewBuilder
    private func thumb(url: String?, icon: String, circle: Bool) -> some View {
        let base = coverOrIcon(url: url, icon: icon).frame(width: 52, height: 52)
        if circle {
            base.clipShape(Circle())
                .overlay(Circle().stroke(accent.opacity(0.22), lineWidth: 1))
        } else {
            base.clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(accent.opacity(0.2), lineWidth: 1))
        }
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
