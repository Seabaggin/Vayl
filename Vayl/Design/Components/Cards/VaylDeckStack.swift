// Design/Components/Cards/VaylDeckStack.swift

import SwiftUI

/// The squared deck — six real card backs whose per-layer offsets mirror
/// ConfirmationPhase's exit positions card-for-card. One source of truth for
/// "a deck of Vayl cards at rest":
///   • CuriosityPhase exit — the kept cards compress into this deck before it
///     flies to the corner (the credential travels as the same object the
///     user is about to see forged).
///   • BuildDeckPhase — the deck on the felt before the melt (its private
///     DeckStack predates this component; unify when next in that file).
struct VaylDeckStack: View {
    var size: CGSize
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                VaylCardBack()
                    .frame(width: size.width, height: size.height)
                    .offset(x: CGFloat(5 - i) * 1.2, y: CGFloat(5 - i) * 1.6)
            }
        }
    }
}
