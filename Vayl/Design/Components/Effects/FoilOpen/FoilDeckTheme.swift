//
//  FoilDeckTheme.swift
//  Vayl
//
//  FoilOpen module — deck identity for the sealed case.
//  The case material (debossed hex lattice in anodized metal) is house language,
//  identical for every deck. Identity enters ONLY through this theme:
//  a category colorway and the deck name embossed on the front face.
//

import SwiftUI

/// Ordered three-stop ramp — the color identity of a deck category.
/// Solo decks use the app spectrum; other categories (sex, jealousy, …)
/// get their own ramps via a legend defined later.
struct FoilColorway: Equatable {
    var c0: Color
    var c1: Color
    var c2: Color

    /// App-centric colorway — solo decks and the OB starter deck.
    static let solo = FoilColorway(
        c0: AppColors.spectrumCyan,
        c1: AppColors.spectrumPurple,
        c2: AppColors.spectrumMagenta
    )
}

/// Pure data — no logic, no dependencies beyond color tokens.
struct FoilDeckTheme: Equatable {
    var colorway: FoilColorway
    var deckName: String

    /// The OB starter deck.
    static let vayl = FoilDeckTheme(colorway: .solo, deckName: "VAYL")
}
