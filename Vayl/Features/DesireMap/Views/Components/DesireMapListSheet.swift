//
//  DesireMapListSheet.swift
//  Vayl
//
//  Screen 9 — "Where you meet" full-map list, hosted as a bottom sheet inside the
//  reveal cover. Two surfaces:
//
//  • DesireMapListView   — pure content (header + match rows + CTA). Reused by
//                          VaultDesireSection in Phase 3 — keep inputs generic.
//  • DesireMapListSheet  — sheet chrome wrapper (grab handle, close, vaylSheetChrome).
//
//  Pattern mirrors DesireStarDetailSheet: no .vaylSheet or .sheet — custom ZStack
//  bottom-sheet inside the cover, transition .move(edge:.bottom).
//

import SwiftUI

// MARK: - Sheet wrapper

struct DesireMapListSheet: View {

    let matches: [RevealMatch]
    let priceText: String?
    var onUnlockTapped: () -> Void = {}
    var onClose: () -> Void = {}
    /// Tapped "Talk about this" inside an expanded row — routes to the Vault (wired by the host).
    var onTalk: (RevealMatch) -> Void = { _ in }

    // Content-height when it fits; scrolls on small screens / long lists. vaylSheetChrome
    // forces maxHeight:.infinity (shared, off-limits), so the chrome wraps BOTH candidates
    // and .fixedSize(vertical) makes the fitting one hug content — PaywallSheet's recipe.
    // Dismissal is scrim-tap (mockup screen 9 has no X).
    var body: some View {
        ViewThatFits(in: .vertical) {
            sheetStack
                .vaylSheetChrome()
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(showsIndicators: false) { sheetStack }
                .vaylSheetChrome()
        }
    }

    private var sheetStack: some View {
        VStack(spacing: 0) {
            grabHandle

            DesireMapListView(
                matches: matches,
                priceText: priceText,
                onUnlockTapped: onUnlockTapped,
                onTalk: onTalk
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.55)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
    }
}

// MARK: - List content (reusable in Phase 3 Vault)

/// Pure content: header + match rows + optional unlock CTA.
/// Input is `[RevealMatch]` — Phase 3 maps `MapStore.AlignItem` to this shape before calling.
struct DesireMapListView: View {

    let matches: [RevealMatch]
    let priceText: String?
    var onUnlockTapped: () -> Void = {}
    var onTalk: (RevealMatch) -> Void = { _ in }

    @State private var expandedId: String?

    private var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    private var lockedCount: Int { matches.filter { $0.isLocked }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            listHeader
            matchRows
            if lockedCount > 0 {
                unlockCTA
            }
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Where you meet")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)

            Text(subCaption)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var subCaption: String {
        if lockedCount == 0 {
            let n = matches.count
            return "\(n) desire\(n == 1 ? "" : "s") you share"
        }
        let revealed = unlockedMatches.count
        return "\(revealed) revealed · \(lockedCount) more you share"
    }

    // MARK: - Match rows

    @ViewBuilder
    private var matchRows: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(matches) { match in
                if match.isLocked {
                    _LockedMatchRow(match: match, onTap: onUnlockTapped)
                } else {
                    _ExpandableMatchRow(
                        match: match,
                        isExpanded: Binding(
                            get: { expandedId == match.id.uuidString },
                            set: { expanded in
                                withAnimation(AppAnimation.standard.reduceMotionSafe) {
                                    expandedId = expanded ? match.id.uuidString : nil
                                }
                            }
                        ),
                        onTalk: { onTalk(match) }
                    )
                }
            }
        }
    }

    // MARK: - Unlock CTA

    private var unlockCTA: some View {
        VStack(spacing: AppSpacing.sm) {
            SpectrumHairline()

            VaylButton(
                label: "Unlock the full map · \(priceText ?? "$24.99")",
                style: .gold,
                size: .fullWidth,
                action: onUnlockTapped
            )
            .frame(height: VaylButtonSize.fullWidth.height)

            Text("One purchase unlocks for both of you.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xs)
    }
}

// MARK: - Expandable row (unlocked match)

private struct _ExpandableMatchRow: View {

    let match: RevealMatch
    @Binding var isExpanded: Bool
    var onTalk: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header — always visible
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    alignmentDot
                    // Unlocked rows always arrive named (the store's content-drift guard
                    // drops nameless unlocked rows); the fallback only satisfies the optional.
                    Text(match.itemName ?? "")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .contentShape(Rectangle())
                .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(DetailPressStyle())

            // Expanded body
            if isExpanded {
                DesireMatchDetail(match: match, onTalkTapped: onTalk)
                    .padding(.top, AppSpacing.sm)
                    .padding(.leading, AppSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.borderSubtle.opacity(isExpanded ? 0.5 : 0.25), lineWidth: 1)
        )
    }

    private var alignmentDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }

    private var dotColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumMagenta
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }
}

// MARK: - Locked row

private struct _LockedMatchRow: View {

    let match: RevealMatch
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: AppIcons.lock)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary.opacity(0.6))

                // Server-enforced paywall (review 2026-07-09 §1.2): locked rows carry no
                // real name — render the honest category teaser as PLAIN text. A blur
                // would fake a secret the client doesn't hold (and leaked to VoiceOver).
                Text(match.teaserTitle)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: AppIcons.chevronRight)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary.opacity(0.4))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(DetailPressStyle())
        .accessibilityLabel("Hidden match")
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.borderSubtle.opacity(0.15), lineWidth: 1)
        )
        .opacity(0.65)
    }
}

// MARK: - Preview

#if DEBUG
/// Locked rows mirror the server shape: no name, teaser category only.
private let _previewMatches: [RevealMatch] = [
    .sample("New Relationship Energy", .mutual),
    .sample("Overnight Stays", .adjacent),
    RevealMatch(id: UUID(), itemName: nil, itemCategory: "sexual", alignment: nil, isLocked: true, bridgeCardId: nil),
    RevealMatch(id: UUID(), itemName: nil, itemCategory: "logistics", alignment: nil, isLocked: true, bridgeCardId: nil),
    RevealMatch(id: UUID(), itemName: nil, itemCategory: nil, alignment: nil, isLocked: true, bridgeCardId: nil)
]

#Preview("Partial reveal — sheet") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        AppColors.shadowDeep.ignoresSafeArea()

        DesireMapListSheet(
            matches: _previewMatches,
            priceText: "$24.99"
        )
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}

#Preview("Fully unlocked — list content") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMapListView(
            // Post-unlock the server names every row — stubs never appear here.
            matches: [
                .sample("New Relationship Energy", .mutual),
                .sample("Overnight Stays", .adjacent),
                .sample("Meeting Partners", .mutual),
                .sample("Shared Space Agreements", .adjacent),
                .sample("Time and Attention", .mutual)
            ],
            priceText: nil
        )
        .padding(AppSpacing.lg)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}
#endif
