// Tabs/LearnTab/Views/ContentItemSheet.swift
//
// The sheet behind every Content Hub row: Vayl's own background on a book, show,
// podcast, or creator, with the outbound doors underneath.
//
// Why this exists (2026-07-16): before, a row's only destination was an external
// URL, so a row with a null link had no destination at all — and every link in the
// corpus was null, which made the entire hub a shelf you couldn't touch. Now the
// row opens OUR copy. The link is one element inside, not the row's reason to
// exist, so the section works before a single URL is filled in.
//
// It also changes what the hub IS. A cover with a buy button is a store; a cover
// with "here's what this is, who it's for, and where to find it" is a guide — which
// is the job Learn actually has.
//
// Grammar: .vaylSheet (previewing something you return from), never a cover.

import SwiftUI

/// One tappable thing in the hub. Media and voices don't share a shape — a book has
/// a cover and an author, a person has a face and a self-description — but they do
/// share this destination.
enum HubItem: Identifiable {
    case media(LearnMediaItem)
    case voice(Voice)

    var id: String {
        switch self {
        case .media(let m): return "media-\(m.id)"
        case .voice(let v): return "voice-\(v.id)"
        }
    }
}

struct ContentItemSheet: View {
    let item: HubItem

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header
                Text(backgroundCopy)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                if !links.isEmpty {
                    VaylHairline()
                        .padding(.vertical, AppSpacing.xs)
                    linksSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        switch item {
        case .media(let m):
            HStack(alignment: .top, spacing: AppSpacing.md) {
                artwork(m.artworkAsset, m.artworkUrl, kind: m.kind)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(kindLabel(m.kind))
                        .overlineTracked()
                        .foregroundStyle(AppColors.textSectionLabel)
                    Text(m.title)
                        .font(AppFonts.sheetTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(m.creator)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    if let platform = m.platform { platformBadge(platform) }
                }
            }
        case .voice(let v):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // The label is the person's own claim, never ours: "Poly educator"
                // is topic + mode, and mode never exceeds what they call themselves.
                Text(v.label)
                    .overlineTracked()
                    .foregroundStyle(AppColors.textSectionLabel)
                Text(v.name)
                    .font(AppFonts.sheetTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(v.role)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                platformBadge(v.platform)
            }
        }
    }

    // MARK: - Body copy

    /// Falls back to the row's one-liner until the longer copy is written, so the
    /// sheet is never empty — the fallback is short, not absent.
    private var backgroundCopy: String {
        switch item {
        case .media(let m): return m.background ?? m.positioning
        case .voice(let v): return v.background ?? v.blurb
        }
    }

    // MARK: - Links

    private var links: [ContentLink] {
        switch item {
        case .media(let m): return m.links.usable
        case .voice(let v): return v.links.usable
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Where to find it")
                .overlineTracked()
                .foregroundStyle(AppColors.textSectionLabel)
            ForEach(links) { link in
                if let url = link.resolved {
                    Button { openURL(url) } label: { linkRow(link) }
                        .buttonStyle(PressableCardStyle())
                        .accessibilityHint("Opens in Safari")
                }
            }
        }
    }

    private func linkRow(_ link: ContentLink) -> some View {
        HStack(spacing: AppSpacing.md2) {
            Text(link.label)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Spacer(minLength: 0)
            // Up-right, not a chevron: this leaves the app.
            Image(systemName: AppIcons.arrowUpRight)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textAccent)
        }
        .padding(AppSpacing.md)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(AppColors.whisperFill))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
            .stroke(AppColors.borderSubtle, lineWidth: 1))
    }

    // MARK: - Bits

    @ViewBuilder
    private func artwork(_ asset: String?, _ url: String?, kind: MediaKind) -> some View {
        Group {
            if let asset, UIImage(named: asset) != nil {
                Image(asset).resizable().aspectRatio(contentMode: .fill)
            } else if let url, let u = URL(string: url) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: iconTile(kind)
                    }
                }
            } else {
                iconTile(kind)
            }
        }
        .frame(width: 88, height: 128)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.sm)
            .stroke(AppColors.borderSubtle, lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func iconTile(_ kind: MediaKind) -> some View {
        ZStack {
            AppColors.whisperFill
            Image(systemName: kindIcon(kind))
                .font(AppFonts.body(22, weight: .regular, relativeTo: .body))
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

    private func kindLabel(_ kind: MediaKind) -> String {
        switch kind {
        case .book:    return "Book"
        case .show:    return "Watch"
        case .podcast: return "Listen"
        }
    }

    private func kindIcon(_ kind: MediaKind) -> String {
        switch kind {
        case .book:    return AppIcons.bookClosedFill
        case .show:    return AppIcons.playRectangleFill
        case .podcast: return AppIcons.waveform
        }
    }
}

#Preview("Voice") {
    let v = Voice(
        id: "polyphiliablog", name: "Leanne Yau", role: "Polyamorous Relationship Educator",
        blurb: "Polyamory education, plainly and at scale.",
        topic: .polyamory, mode: .educator, platform: "Instagram", background: nil,
        links: [ContentLink(label: "Instagram", url: "https://www.instagram.com/polyphiliablog/")]
    )
    return ZStack {
        AppColors.modalBackground.ignoresSafeArea()
        ContentItemSheet(item: .voice(v))
    }
}
