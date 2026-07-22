//
//  PlayHeroView.swift
//  Vayl — Play
//
//  The active-deck hero: the deck title/meta ABOVE the SAME floating card
//  container Home uses (`CardCarousel` + `DeckPedestal`). Tapping the card
//  spreads → lifts → carousel; tapping a card begins the deck.
//

import SwiftUI

struct PlayHeroView: View {
    let store: PlayStore
    /// 0 = full at rest, 1 = collapsed. Scroll-linked (matches Home's hero-zone transform).
    var collapse: Double = 0

    /// Tonight's hand, built by tapping cards in the hero carousel — same
    /// selecting mechanic Home uses. "Settle in" opens the session with these.
    @State private var handIDs: [String] = []

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            if let deck = store.featured { header(deck) }

            CardCarousel(
                cards: store.featuredCards,
                onCardAction: { _, _ in },
                selecting: true,
                selectedIDs: Set(handIDs),
                onToggleSelect: { toggleHand($0) },
                dimOpacity: 0.15,
                colorway: store.featured.map { store.style(for: $0).colorway },
                glyphPath: store.featured.map { store.style(for: $0).glyph.path }
            )
            .overlay(alignment: .top) {
                DeckPedestal(showBloom: false)
                    .offset(y: 191)
            }

            if !handIDs.isEmpty {
                settleInBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.spring, value: handIDs.isEmpty)
        // A · recede into depth — the hero tilts back in 3D and falls away as the
        // library rises past it (the chosen collapse). Still the same scroll-linked,
        // Home-matched mechanism, just a grander transform on top.
        .scaleEffect(1 - collapse * 0.26, anchor: .top)
        .rotation3DEffect(
            .degrees(collapse * -52),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 0.6
        )
        .opacity(1 - collapse * 0.92)
        .offset(y: -collapse * 22)
    }

    /// "Settle in · N →" — opens the session with tonight's selected hand,
    /// matching Home's CTA. Placement in the scroll-collapsing hero is
    /// feel-gated (Bryan's device pass).
    private var settleInBar: some View {
        VaylButton(label: "Settle in  ·  \(handIDs.count)  →", isDisabled: false) {
            store.settleInFeatured(cardIds: handIDs)
            handIDs = []
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func toggleHand(_ card: Card) {
        withAnimation(AppAnimation.spring) {
            if let idx = handIDs.firstIndex(of: card.id) {
                handIDs.remove(at: idx)
            } else {
                handIDs.append(card.id)
            }
        }
    }

    /// Three lines, one register each: the state line carries logistics, the
    /// title carries identity, the subtitle carries meaning (what the deck is
    /// for — the question the retired difficulty label was crudely proxying).
    private func header(_ d: DeckSummary) -> some View {
        VStack(spacing: AppSpacing.sm) {
            eyebrow(d)

            Text(d.title)
                .font(AppFonts.deckHeroTitle)
                .vaylDisplayTracking(32)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(d.subtitle)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if case .inProgress(let index, let total) = store.featuredContinuity {
                progressReadout(value: index, total: total, label: "\(index) of \(total) explored")
                    .font(AppFonts.caption)
                    .padding(.top, AppSpacing.xxs)
            }
        }
    }

    /// Continuity eyebrow — flips with the featured deck's real `DeckProgress`.
    /// Fresh/completed carry the card count here (muted, after a dot); in-progress
    /// drops it — the total already lives inside "X of N explored" below.
    private func eyebrow(_ d: DeckSummary) -> some View {
        let icon: String
        let label: String
        let tint: Color
        let showCount: Bool
        switch store.featuredContinuity {
        case .inProgress:
            icon = "play.fill";        label = "Continue";   tint = AppColors.accentPrimary; showCount = false
        case .completed:
            icon = "arrow.clockwise";  label = "Play again"; tint = AppColors.accentPrimary; showCount = true
        case .fresh:
            icon = "sparkles";         label = "New deck";   tint = AppColors.accentPrimary; showCount = true
        }
        return HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
            Text(label)
            if showCount {
                Circle().fill(AppColors.textMuted)
                    .frame(width: AppSpacing.xxs, height: AppSpacing.xxs)
                Text("\(d.cardCount) cards")
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .font(AppFonts.overline)
        .foregroundStyle(tint)
    }

    /// ~128pt continuity bar (token-derived; matches the masthead/peek widths).
    private var barWidth: CGFloat { AppSpacing.xxl * 2 + AppSpacing.xl }

    /// Bar + label, folding from a row to a stack at large Dynamic Type so nothing clips.
    private func progressReadout(value: Int, total: Int, label: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.sm) { progressBar(value, total); Text(label) }
            VStack(spacing: AppSpacing.xs) { progressBar(value, total); Text(label) }
        }
        .foregroundStyle(AppColors.textSecondary)
    }

    private func progressBar(_ value: Int, _ total: Int) -> some View {
        ProgressBar(value: Double(value), max: Double(total))
            .frame(width: barWidth)
    }
}

#if DEBUG
#Preview("Play hero") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PlayHeroView(store: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
