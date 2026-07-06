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

    var body: some View {
        ZStack {
            if let deck {
                AppColors.void.ignoresSafeArea()

                MetallicCaseView(theme: theme(deck),
                                 dissolveStart: reduceMotion ? .distantPast : dissolve)
                    .frame(width: 210, height: 310)
                    .onTapGesture {
                        if dissolve == .distantFuture { dissolve = .now }
                    }

                if dissolve == .distantFuture && !reduceMotion {
                    Text("tap the seal to open")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .offset(y: 200)
                }
            }
        }
        .transition(.opacity)
        .task(id: dissolve) {
            // Reduce Motion: skip straight through. Otherwise wait for the dissolve.
            if reduceMotion {
                try? await Task.sleep(for: .milliseconds(350))
                store.ceremonyFinished()
            } else if dissolve != .distantFuture {
                try? await Task.sleep(for: .seconds(2.0))
                store.ceremonyFinished()
            }
        }
    }

    private func theme(_ d: DeckSummary) -> FoilDeckTheme {
        FoilDeckTheme(colorway: store.style(for: d).colorway, deckName: d.title.uppercased())
    }
}
