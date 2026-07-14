//
//  DeckBeginCeremony.swift
//  Vayl — Play
//
//  The first-open ceremony: the reserved metallic case + crack/dissolve, played
//  once per person when a SEALED deck is first opened. It breaks the seal and
//  lands in the deck detail (not a session — Start from detail begins play). A
//  quiet top-right Skip pill is present from the start; skipping STILL breaks the
//  seal (same destination, minus the animation) — a skip that only deferred would
//  re-nag. Reduce Motion / Low Power cross-fade straight through. (Spec §3.)
//

import SwiftUI

struct DeckBeginCeremony: View {
    let store: PlayStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dissolve: Date = .distantFuture

    private var deck: DeckSummary? { store.summary(store.ceremonyDeckID) }

    /// MetallicCaseView renders a static frame under RM AND Low Power Mode —
    /// with LPM on, waiting the full dissolve would be 2s of blank void, so
    /// both take the fast cross-fade path.
    private var skipsMotion: Bool { reduceMotion || AppAnimation.lowPower }

    var body: some View {
        ZStack {
            if let deck {
                AppColors.void.ignoresSafeArea()

                MetallicCaseView(theme: theme(deck),
                                 dissolveStart: skipsMotion ? .distantPast : dissolve)
                    .frame(width: 210, height: 310)
                    .contentShape(Rectangle())
                    .onTapGesture { openDeck() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Open deck")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { openDeck() }

                if dissolve == .distantFuture && !skipsMotion {
                    Text("tap the seal to open")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .offset(y: 200)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if deck != nil { skipPill.padding(AppSpacing.lg) }
        }
        .transition(.opacity)
        .task(id: dissolve) {
            // RM / Low Power: skip straight through. Otherwise wait for the
            // dissolve. Cancellation (tab switch mid-ceremony) must NOT finish
            // the ceremony — Task.sleep swallows CancellationError under try?.
            if skipsMotion {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                store.ceremonyFinished()
            } else if dissolve != .distantFuture {
                try? await Task.sleep(for: .seconds(2.0))
                guard !Task.isCancelled else { return }
                store.ceremonyFinished()
            }
        }
    }

    /// Quiet, always-present skip. Breaks the seal and jumps to detail without the
    /// animation — the manual equivalent of the RM / Low-Power short-path.
    private var skipPill: some View {
        Button { store.skipFirstOpen() } label: {
            Text("Skip")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Capsule().fill(AppColors.cardBg.opacity(0.6)))
                .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("Skip ceremony")
    }

    private func theme(_ d: DeckSummary) -> FoilDeckTheme {
        FoilDeckTheme(colorway: store.style(for: d).colorway, deckName: d.title.uppercased())
    }

    private func openDeck() {
        if dissolve == .distantFuture { dissolve = .now }
    }
}

#if DEBUG
// "the-opener" is a free deck, so beginFirstOpen sets ceremonyDeckID directly
// (a locked id would route to the paywall instead and leave the preview blank).
#Preview("Begin ceremony") {
    let store = PlayStore.preview
    store.beginFirstOpen("the-opener")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        DeckBeginCeremony(store: store)
    }
    .preferredColorScheme(.dark)
}
#endif
