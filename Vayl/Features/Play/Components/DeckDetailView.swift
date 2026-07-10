//
//  DeckDetailView.swift
//  Vayl — Play
//
//  Float-in-space deck detail — a centered overlay card zoomed from the wall
//  cell (matchedGeometry). Locked decks show what the deck is about plus ONE
//  readable real card (a genuine taste, deliberate); the rest stay sealed.
//

import SwiftUI
import SwiftData

struct DeckDetailView: View {
    let store: PlayStore
    let namespace: Namespace.ID

    private var deck: DeckSummary? { store.summary(store.detailID) }

    var body: some View {
        ZStack {
            if let deck {
                scrim
                VStack {
                    Spacer()
                    overlayCard(deck)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, AppSpacing.lg)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.spring, value: store.detailID)
    }

    private var scrim: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .overlay(AppColors.void.opacity(0.6).ignoresSafeArea())
            .onTapGesture { store.closeDetail() }
    }

    // MARK: - Overlay card

    private func overlayCard(_ deck: DeckSummary) -> some View {
        let locked = store.isLocked(deck)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            topRow(deck, locked: locked)
            divider
            if let whenToUse = deck.whenToUse {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    sectionLabel("WHEN TO USE")
                    Text(whenToUse)
                        .font(AppFonts.bodyText.italic())
                        .foregroundStyle(AppColors.spectrumCyan.opacity(0.65))
                }
            }
            if !deck.goals.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    sectionLabel("BY THE END")
                    goalsList(deck.goals)
                }
            }
            cardPreviews(locked: locked)
            if !locked, let lastPlayed = store.lastPlayed(deck) {
                Text("Last played \(lastPlayed.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
            }
            cta(deck, locked: locked)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(AppColors.void)
                .overlay(
                    LinearGradient(colors: [AppColors.cardBg, .clear], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
        .spectrumBorderGlow(intensity: 0.4)
        .modalElevation()
        .overlay(alignment: .topTrailing) { closeButton.padding(AppSpacing.sm) }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.spectrumBorder)
            .frame(height: 1)
            .opacity(0.3)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .foregroundStyle(AppColors.textMuted)
    }

    // MARK: - Close

    private var closeButton: some View {
        VaylCloseButton { store.closeDetail() }
    }

    // MARK: - Top row

    private func topRow(_ deck: DeckSummary, locked: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            // The one live source while the detail is open — the wall cell
            // yields (DeckCellView.detailOpen), so this really zooms.
            DeckCaseView(summary: deck, style: store.style(for: deck), lockedOverride: locked)
                .frame(width: 82)
                .matchedGeometryEffect(id: deck.id, in: namespace, isSource: true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(deck.category.displayName)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textHint)
                Text(deck.title)
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                pills(deck)
                Text(deck.description)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                starButton(deck)
            }
        }
    }

    private func pills(_ deck: DeckSummary) -> some View {
        HStack(spacing: AppSpacing.xs) {
            pill(deck.intensity.difficultyLabel, accented: true)
            pill("\(deck.cardCount) cards")
            if deck.whenToUse != nil {
                pill("Timing note", icon: "clock")
            }
        }
    }

    private func pill(_ text: String, icon: String? = nil, accented: Bool = false) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(AppFonts.label)
        .foregroundStyle(accented ? AppColors.accentSecondary : AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(
            Capsule().fill(accented ? AppColors.accentSecondary.opacity(0.12) : Color.clear)
        )
        .overlay(
            Capsule().strokeBorder(accented ? AppColors.accentSecondary.opacity(0.4) : AppColors.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Star

    /// Hidden entirely when unpaired — a star needs a couple row to live on,
    /// and a silently dead button is worse than no button.
    @ViewBuilder
    private func starButton(_ deck: DeckSummary) -> some View {
        if store.canStar {
            let isStarred = store.isStarredByMe(deck) || store.isStarredByPartner(deck)
            Button {
                store.toggleStar(deck)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? AppColors.accentTertiary : AppColors.textTertiary)
                    Text(starLabel(deck, isStarred: isStarred))
                        .font(AppFonts.caption)
                        .foregroundStyle(isStarred ? AppColors.accentTertiary.opacity(0.85) : AppColors.textTertiary)
                }
            }
            .buttonStyle(PressableStyle())
            .sensoryFeedback(.selection, trigger: isStarred)
        }
    }

    private func starLabel(_ deck: DeckSummary, isStarred: Bool) -> String {
        let me = store.isStarredByMe(deck)
        let partner = store.isStarredByPartner(deck)
        switch (me, partner) {
        case (false, false): return "Save for later"
        case (true, false): return "Saved by you"
        case (false, true): return "Saved by \(store.partnerName ?? "your partner")"
        case (true, true): return "Saved by you and \(store.partnerName ?? "your partner")"
        }
    }

    // MARK: - Goals

    private func goalsList(_ goals: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(goals, id: \.self) { goal in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Circle()
                        .fill(LinearGradient(colors: [AppColors.spectrumPurple, AppColors.spectrumMagenta],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 6, height: 6)
                        .padding(.top, AppSpacing.xxs + 3)
                    Text(goal)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Card previews

    @ViewBuilder
    private func cardPreviews(locked: Bool) -> some View {
        let previewCards = store.detailPreviewCards
        if !previewCards.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(previewCards.enumerated()), id: \.offset) { index, card in
                        CardPreviewTile(card: card)
                            .blur(radius: locked && index > 0 ? 6 : 0)
                            .allowsHitTesting(!(locked && index > 0))
                    }
                }
            }
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private func cta(_ deck: DeckSummary, locked: Bool) -> some View {
        if locked {
            VStack(spacing: AppSpacing.xxs) {
                VaylButton(label: "Purchase Lifetime Access") { store.requestUnlock(deck) }
                Text("\(store.corePriceText ?? "$24.99") · Unlocks all decks")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        } else if store.lastPlayed(deck) != nil {
            VaylButton(label: "Play again") { store.startDeck(deck) }
        } else {
            VaylButton(label: "Start") { store.startDeck(deck) }
        }
    }
}

/// A single card preview tile in the detail overlay's horizontal scroller.
private struct CardPreviewTile: View {
    let card: Card

    var body: some View {
        Text(card.text)
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .padding(AppSpacing.sm)
            .frame(width: 140, height: 100, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
    }
}

/// Shared press contract (scale + haptic) for the detail overlay's small tap targets.
/// Haptic fires on press only (the condition), never a second time on release.
private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in
                pressed
            }
    }
}

#if DEBUG
#Preview("Deck detail — unlocked") {
    @Previewable @Namespace var ns
    let store = PlayStore.preview
    store.openDetail("the-opener")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        DeckDetailView(store: store, namespace: ns)
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck detail — locked") {
    @Previewable @Namespace var ns
    let store = PlayStore.preview
    store.openDetail("jealousy")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        DeckDetailView(store: store, namespace: ns)
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck detail — completed") {
    @Previewable @Namespace var ns
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let coupleId = UUID()
    appState.coupleId = coupleId
    let progress = DeckProgress(coupleId: coupleId, deckId: "the-opener")
    progress.completedAt = Date()
    let context = ModelContext(container)
    context.insert(progress)
    try? context.save()
    let entitlements = EntitlementStore(modelContainer: container, appState: appState)
    let store = PlayStore(
        modelContainer: container,
        appState: appState,
        entitlements: entitlements,
        coupleContext: CoupleContext(appState: appState, entitlements: entitlements, modelContainer: container)
    )
    store.openDetail("the-opener")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        DeckDetailView(store: store, namespace: ns)
    }
    .preferredColorScheme(.dark)
}
#endif
