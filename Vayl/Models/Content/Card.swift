//
//  Card.swift
//  Vayl
//
//  Location: Models/Content/Card.swift
//  Stub — full implementation after errors are cleared.
//

import Foundation

struct Card: Identifiable, Codable {
    let id: String
    let deckId: String
    let text: String
    let highlightWords: [String]
    let type: CardType
    let intensity: CardIntensity
    let whoStarts: WhoStarts
    let isSensitive: Bool
    let canSkip: Bool
    let register: EmotionalRegister
    let contextBeatType: ContextBeatType?
    let contextBeatCopy: String?
    let backCopy: String?
    let isGenderedCard: Bool
    let genderedFor: GenderDynamic?
    let sortOrder: Int

    static let samples: [Card] = []
}