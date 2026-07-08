//
//  DeckBeginCeremony.swift
//  Vayl — Play
//
//  The reserved metallic case + crack/dissolve, played only on Begin. Reduce
//  Motion / fallback cross-fades straight through to the session.
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

    private func theme(_ d: DeckSummary) -> FoilDeckTheme {
        FoilDeckTheme(colorway: store.style(for: d).colorway, deckName: d.title.uppercased())
    }

    private func openDeck() {
        if dissolve == .distantFuture { dissolve = .now }
    }
}
