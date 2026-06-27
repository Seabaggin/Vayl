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

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            if let deck = store.featured { header(deck) }

            CardCarousel(
                cards: store.featuredCards,
                onCardAction: { _, action in
                    if case .startSession = action, let id = store.featuredID {
                        store.beginCeremony(id)
                    }
                },
                selecting: false,
                dimOpacity: 0.15,
                colorway: store.featured.map { store.style(for: $0).colorway },
                glyphPath: store.featured.map { store.style(for: $0).glyph.path }
            )
            .overlay(alignment: .top) {
                DeckPedestal(showBloom: false)
                    .offset(y: 191)
            }
        }
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

    private func header(_ d: DeckSummary) -> some View {
        let style = store.style(for: d)
        return VStack(spacing: AppSpacing.sm) {
            eyebrow

            Text(d.title)
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.sm) {
                Circle().fill(style.accent)
                    .frame(width: AppSpacing.sm, height: AppSpacing.sm)
                Text(d.intensity.difficultyLabel)
                Circle().fill(AppColors.textMuted)
                    .frame(width: AppSpacing.xxs, height: AppSpacing.xxs)
                Text("\(d.cardCount) cards")
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)

            continuityRow
        }
    }

    /// Continuity eyebrow — flips with the featured deck's real `DeckProgress`.
    private var eyebrow: some View {
        let icon: String
        let label: String
        let tint: Color
        switch store.featuredContinuity {
        case .inProgress:
            icon = "play.fill";        label = "Continue";  tint = AppColors.accentPrimary
        case .completed:
            icon = "arrow.clockwise";  label = "Play again"; tint = AppColors.accentPrimary
        case .fresh:
            icon = "sparkles";         label = "New deck";   tint = AppColors.spectrumCyan
        }
        return HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
            Text(label)
        }
        .font(AppFonts.overline)
        .foregroundStyle(tint)
    }

    /// ~128pt continuity bar (token-derived; matches the masthead/peek widths).
    private var barWidth: CGFloat { AppSpacing.xxl * 2 + AppSpacing.xl }

    /// Continuity read — slim spectrum bar + "X of N explored", or "Not started".
    /// Both states keep the same slot height so the hero does not jump between decks.
    private var continuityRow: some View {
        Group {
            switch store.featuredContinuity {
            case .inProgress(let index, let total):
                progressReadout(value: index, total: total, label: "\(index) of \(total) explored")
            case .completed:
                progressReadout(value: 1, total: 1, label: "Completed")
            case .fresh:
                Text("Not started")
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .font(AppFonts.caption)
        .padding(.top, AppSpacing.xxs)
    }

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
