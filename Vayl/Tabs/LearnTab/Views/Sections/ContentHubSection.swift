// Tabs/LearnTab/Views/Sections/ContentHubSection.swift
//
// The Content Hub — books (cover shelf), watch + listen (media rows), voices.
// Third-party media: "where to go deeper," as opposed to the reference's cited
// first-party "what we know." That split is why it is its own screen now.
//
// Presented as a cover from Learn's hub door (2026-07-16). It kept its segmented
// control because at screen level that's honest IA — the sin was nesting it inside
// a card inside a tab, where four panels fought over one small box.
//
// What changed in the restyle: the per-panel accent sweep is gone (each tab used to
// paint itself a different spectrum colour, which is what made Learn read as a
// template), the display-caps header is now the tracked overline, and the card is
// the unified `learnCard()`.

import SwiftUI

struct ContentHubSection: View {
    let store: LearnStore

    @State private var tab: HubTab = .books
    @State private var voiceFilter: VoiceKind = .creator

    /// One accent for the whole hub. Cyan, not magenta: magenta means Us/shared,
    /// and Learn is a private, solo surface. Don't cross the wires.
    private let accent = AppColors.spectrumCyan

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
            case .books: return "books.vertical"; case .watch: return "play.rectangle"
            case .listen: return "waveform"; case .voices: return "person.2"
            }
        }
        /// One accent across all four. The old per-tab spectrum sweep made each
        /// panel look like a different product.
        var accent: Color { AppColors.spectrumCyan }
    }

    var body: some View {
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

    // MARK: - Books

    private var bookShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                ForEach(store.media(.book)) { book in
                    Button {} label: { bookCover(book) }
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
                    Text(tier.uppercased())
                        .font(AppFonts.label)
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
            ForEach(store.media(kind)) { item in
                Button {} label: { mediaRow(item, tag: tag) }
                    .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func mediaRow(_ m: LearnMediaItem, tag: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            thumb(url: m.artworkUrl, icon: kindIcon(m.kind), circle: false)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(tag.uppercased())
                    .font(AppFonts.label)
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
            Image(systemName: AppIcons.chevronRight).foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
        .contentShape(Rectangle())
    }

    // MARK: - Voices

    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SegmentedPillGroup(
                options: [
                    .init(VoiceKind.creator, label: "Creators", accent: AppColors.spectrumCyan),
                    .init(VoiceKind.researcher, label: "Researchers", accent: AppColors.spectrumMagenta)
                ],
                selection: $voiceFilter
            )
            ForEach(store.voices(voiceFilter)) { voice in
                Button {} label: { voiceRow(voice) }
                    .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func voiceRow(_ v: Voice) -> some View {
        HStack(spacing: AppSpacing.md) {
            thumb(url: nil, icon: "person.fill", circle: true)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(v.role.uppercased())
                    .font(AppFonts.label)
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
            Image(systemName: AppIcons.chevronRight).foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
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
        case .book: return "book.closed.fill"
        case .show: return "play.rectangle.fill"
        case .podcast: return "waveform"
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView { ContentHubSection(store: LearnStore()).padding() }
    }
}
