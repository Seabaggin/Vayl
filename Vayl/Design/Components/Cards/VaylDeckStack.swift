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
    /// Number of stacked backs. Default 6 (BuildDeck). Curiosity passes fewer for a
    /// slimmer symbolic deck.
    var count: Int = 6
    /// When true the stack recedes straight UP behind the front card, so the front
    /// card is anchored to the bottom and both sides. An overlaid LiftHalo then sits
    /// flush there (the deck thickness shows only above the top edge). Default false
    /// keeps BuildDeck's down-right bleed.
    var bleedUp: Bool = false
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                VaylCardBack()
                    .frame(width: size.width, height: size.height)
                    .offset(
                        x: bleedUp ? 0 : CGFloat(count - 1 - i) * 1.2,
                        y: CGFloat(count - 1 - i) * (bleedUp ? -1.6 : 1.6)
                    )
            }
        }
    }
}
