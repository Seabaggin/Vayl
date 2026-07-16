//
//  DeckPanelView.swift
//  Vayl — Play
//
//  One deck's panel inside the full-screen detail carousel (`DeckCarouselView`,
//  the Explore surface). Ports the proven DeckDetailView content — case thumbnail,
//  meta/progress, outcome + question tiles, locked-blur, star/CTA branching — into
//  a single swipeable panel. The CENTERED panel's case thumbnail carries the one
//  live carousel animation (the capped, RM/LPM-gated twinkle, §9); off-center
//  panels render fully static and never mount the TimelineView.
//
//  Spec: docs/superpowers/specs/2026-07-11-play-deck-library-redesign-design.md §8/§9.
//

import SwiftUI

struct DeckPanelView: View {
    let store: PlayStore
    let deck: DeckSummary
    /// The carousel centers exactly one panel; only that one loads real question
    /// tiles (`store.detailPreviewCards` is scoped to the centered deck) and mounts
    /// the live twinkle. Off-center panels stay static.
    let isCentered: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var locked: Bool { store.isLocked(deck) }
    private var starredByMe: Bool { store.isStarredByMe(deck) }

    // Case thumbnail footprint (2:3 → height derives from width).
    private let thumbWidth: CGFloat = 78

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            topRow
            divider
            description
            previewScroller
            footerCTA
        }
        .padding(AppSpacing.md)
        // Content-height card (no greedy vertical fill): the carousel stage centers
        // it, so Start sits under the tiles instead of stranded at the stage floor.
        .frame(maxWidth: .infinity, alignment: .top)
        .background(panelBackground)
        .overlay(alignment: .top) { rimGlow }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) { ribbon }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .spectrumBorderGlow(intensity: isCentered ? 0.4 : 0.14)
        .modalElevation()
    }

    // MARK: - Panel chrome

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
            .fill(AppColors.void)
            .overlay(
                LinearGradient(colors: [AppColors.cardBackgroundRaised, .clear],
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            )
    }

    /// The spectrum rim across the top edge — a blurred gradient band that reads as
    /// the panel catching the room's light. Colorway-tinted so each deck's panel
    /// glows in its own hue.
    private var rimGlow: some View {
        let cw = store.style(for: deck).colorway
        return LinearGradient(colors: [cw.c0, cw.c1, cw.c2],
                              startPoint: .leading, endPoint: .trailing)
            .frame(height: AppSpacing.xs)
            .blur(radius: AppSpacing.sm)
            .opacity(isCentered ? 0.9 : 0.5)
            .padding(.horizontal, AppSpacing.lg)
            .allowsHitTesting(false)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.spectrumBorder)
            .frame(height: 1)
            .opacity(0.3)
    }

    // MARK: - Top row (thumbnail + meta)

    private var topRow: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            caseThumbnail
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(deck.category.displayName)
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textHint)
                Text(deck.title)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(cardCountLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                progressReadout
                    .padding(.top, AppSpacing.xxs)
            }
            // Leave the ribbon its corner without the title colliding into it.
            .padding(.trailing, AppSpacing.lg)
        }
    }

    private var cardCountLine: String {
        locked ? "\(deck.cardCount) cards · Premium" : "\(deck.cardCount) cards"
    }

    /// The case thumbnail. Only the centered panel overlays the live twinkle, and
    /// only when ambient motion is allowed (Reduce Motion + Low Power both gate it
    /// off — the static case reads complete).
    private var caseThumbnail: some View {
        DeckCaseView(summary: deck,
                     style: store.style(for: deck),
                     state: store.deckState(deck),
                     width: thumbWidth)
            .overlay {
                if isCentered && !(reduceMotion || AppAnimation.lowPower) {
                    CaseTwinkle()
                }
            }
    }

    @ViewBuilder
    private var progressReadout: some View {
        if let fraction = store.progressFraction(deck) {
            HStack(spacing: AppSpacing.sm) {
                PanelProgressBar(fraction: fraction)
                    .frame(width: 64, height: 4)
                Text("\(store.progressIndex(deck))/\(deck.cardCount)")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
            }
        } else if store.isCompleted(deck) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: AppIcons.checkmark)
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.accentSecondary)
                Text("Completed")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Completed")
        }
    }

    // MARK: - Bookmark ribbon

    /// The mockup's ribbon (a bookmark glyph): FILLED magenta when saved by me, a
    /// small partner dot when saved by my partner. Hidden entirely when starring is
    /// impossible (no couple row) — a silently dead control is worse than none.
    @ViewBuilder
    private var ribbon: some View {
        if store.canStar {
            Button { store.toggleStar(deck) } label: {
                Image(systemName: starredByMe ? "bookmark.fill" : "bookmark")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(starredByMe ? AppColors.spectrumMagenta : AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .overlay(alignment: .topTrailing) {
                        if store.isStarredByPartner(deck) {
                            Circle()
                                .fill(AppColors.spectrumCyan)
                                .frame(width: 6, height: 6)
                        }
                    }
            }
            .buttonStyle(PressableCardStyle())
            .sensoryFeedback(.selection, trigger: starredByMe)
            .padding(AppSpacing.sm)
            .accessibilityLabel(ribbonA11yLabel)
        }
    }

    private var ribbonA11yLabel: String {
        let me = store.isStarredByMe(deck)
        let partner = store.isStarredByPartner(deck)
        switch (me, partner) {
        case (false, false): return "Save deck for later"
        case (true, false):  return "Saved by you. Remove."
        case (false, true):  return "Saved by \(store.partnerName ?? "your partner")"
        case (true, true):   return "Saved by you and \(store.partnerName ?? "your partner")"
        }
    }

    // MARK: - Description

    private var description: some View {
        Text(deck.description)
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Preview scroller (outcome + question tiles)

    /// Outcome tile FIRST (deck-specific, always shown), then question tiles. Question
    /// tiles are only meaningful for the centered deck (`detailPreviewCards` is loaded
    /// for it); a locked deck shows the outcome plus exactly ONE blurred taste.
    private var previewScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                OutcomeTile(text: store.outcomeLine(deck))
                if locked {
                    if let first = store.detailPreviewCards.first {
                        QuestionTile(text: first.text, blurred: true)
                    }
                } else if isCentered {
                    ForEach(Array(store.detailPreviewCards.enumerated()), id: \.offset) { _, card in
                        QuestionTile(text: card.text, blurred: false)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - Footer CTA

    @ViewBuilder
    private var footerCTA: some View {
        if locked {
            VStack(spacing: AppSpacing.xxs) {
                VaylButton(label: "Unlock all decks") { store.requestUnlock(deck) }
                Text(store.corePriceText ?? "$24.99")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        } else if store.isCompleted(deck) {
            VaylButton(label: "Play again") { store.startDeck(deck) }
        } else {
            VaylButton(label: "Start") { store.startDeck(deck) }
        }
    }
}

// MARK: - Progress bar

private struct PanelProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.borderSubtle)
                Capsule()
                    .fill(AppColors.spectrumBorder)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
    }
}

// MARK: - Preview tiles

/// The "what you'll leave with" tile — spectrum-edged so it reads as the payoff, not
/// just another card. No difficulty badge anywhere (spec §7/§8).
private struct OutcomeTile: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("BY THE END")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.spectrumTextSafe)
            Text(text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .padding(AppSpacing.sm)
        .frame(width: 150, height: 108, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(0.6)
        )
    }
}

/// A single real-card taste. Locked decks blur all but nothing (they surface exactly
/// one, blurred) — a deliberate glimpse, not the whole deck.
private struct QuestionTile: View {
    let text: String
    let blurred: Bool

    var body: some View {
        Text(text)
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .padding(AppSpacing.sm)
            .frame(width: 150, height: 108, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .blur(radius: blurred ? 6 : 0)
            .allowsHitTesting(!blurred)
            .accessibilityHidden(blurred)
    }
}

// MARK: - Centered-panel twinkle (spec §9)

/// The one live animation in the carousel: stochastic spectrum glimmers over the
/// centered deck's case footprint. A single capped `TimelineView` (~25fps) drives a
/// `Canvas` of seeded, independently-cycling glimmers. Each glimmer's PRNG is seeded
/// by its index (stable, launch-to-launch); the clock is ELAPSED-since-mount, wrapped
/// to a bounded range — never an absolute timestamp handed to a float. Mounted only
/// by the centered panel, and only when ambient motion is allowed (the caller gates
/// Reduce Motion + Low Power before mounting this at all).
private struct CaseTwinkle: View {
    private let cellCount = 16
    /// @State so it initialises once at view birth and survives re-renders — the
    /// stable origin for elapsed time.
    @State private var birth = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04)) { timeline in
            Canvas { context, size in
                // Elapsed since mount, wrapped to a bounded window so the float never
                // grows without limit (the shader-time-precision guardrail applied to
                // pure-Swift Canvas math). Per-glimmer phase keeps them independent.
                let elapsed = timeline.date.timeIntervalSince(birth)
                    .truncatingRemainder(dividingBy: 3600)

                for i in 0..<cellCount {
                    let s = Double(i)
                    let px = fract(s * 1.13 + 0.7)
                    let py = fract(s * 2.71 + 1.3)
                    let period = 1.6 + fract(s * 3.3) * 2.4        // 1.6–4.0s life
                    let phase = fract(s * 4.7)
                    let localT = fract(elapsed / period + phase)
                    let envelope = sin(localT * .pi)               // 0 → peak → 0
                    guard envelope > 0.03 else { continue }

                    let color = spectrumColor(at: fract(s * 5.9))
                    let radius = size.width * (0.05 + fract(s * 6.1) * 0.06)
                    let center = CGPoint(x: px * size.width, y: py * size.height)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.opacity = envelope * 0.85
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
            .blendMode(.plusLighter)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous))
        .allowsHitTesting(false)
    }

    /// Deterministic fractional hash — the per-glimmer PRNG. Stable every launch
    /// (unlike Swift's per-run `hashValue`).
    private func fract(_ x: Double) -> Double {
        let v = sin(x * 12.9898 + 78.233) * 43758.5453
        return v - v.rounded(.down)
    }
}

#if DEBUG
#Preview("Panel — fresh") {
    let store = PlayStore.preview
    store.openCarousel("the-opener")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        if let deck = store.summary("the-opener") ?? store.unlockedSummaries.first {
            DeckPanelView(store: store, deck: deck, isCentered: true)
                .frame(width: 320, height: 560)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Panel — locked") {
    let store = PlayStore.preview
    return ZStack {
        AppColors.void.ignoresSafeArea()
        if let deck = store.lockedSummaries.first ?? store.summaries.first {
            DeckPanelView(store: store, deck: deck, isCentered: true)
                .frame(width: 320, height: 560)
        }
    }
    .preferredColorScheme(.dark)
}
#endif
