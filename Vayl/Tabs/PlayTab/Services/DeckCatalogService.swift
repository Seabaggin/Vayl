//  DeckCatalogService.swift
//  Vayl — Play

import Foundation

/// I/O only. Loads the lightweight catalog and (separately) a full deck.
struct DeckCatalogService {
    func loadSummaries() throws -> [DeckSummary] {
        try ContentLoader.load(DeckSummary.self, from: "deck-catalog")
    }
    func loadDeck(id: String) throws -> Deck {
        try ContentLoader.loadDeck(id: id)
    }
}
