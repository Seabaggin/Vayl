//
//  SessionSettings.swift
//  Vayl
//
//  The two-knob session-settings model: who reads first, and length/pace.
//  Pure struct, no dependencies. `length` implies an in-session gentle timer
//  (built later) via `softCapMinutes(cardCount:)`; `.unhurried` ("No Rush")
//  means no cap at all.
//
//  Pace scales to the selected hand, not a fixed clock: a couples-deck card is
//  a full exchange (read the prompt, both partners answer, both ask follow-ups),
//  so time is estimated per card. Enum rawValues stay stable; only the display
//  labels changed ("Let it decide" → "Dealer's Choice", "Unhurried" → "No Rush").
//

struct SessionSettings: Equatable, Codable {

    /// Who reads the current card first. `.either` = let the deck decide.
    enum Reader: String, Codable, CaseIterable {
        case you, partner, either

        /// `.partner` resolves to the partner's name; `.either` is "Dealer's Choice".
        func displayLabel(partnerName: String) -> String {
            switch self {
            case .you:     "You"
            case .partner: partnerName
            case .either:  "Dealer's Choice"
            }
        }
    }

    /// Length/pace band. `.unhurried` ("No Rush") runs with no timer at all.
    enum Length: String, Codable, CaseIterable {
        case short, full, unhurried

        var displayLabel: String {
            switch self {
            case .short:     "Short"
            case .full:      "Full"
            case .unhurried: "No Rush"
            }
        }

        /// Minutes a single card takes at this pace. nil == no cap.
        /// Full ≈ 7 min/card (both answer + follow-ups); Short is a lighter
        /// pass (~4 min/card, briefer answers, minimal follow-up).
        var minutesPerCard: Int? {
            switch self {
            case .short:     4
            case .full:      7
            case .unhurried: nil
            }
        }

        /// Estimated session length for a hand of `cardCount`. nil == no timer.
        func estimatedMinutes(cardCount: Int) -> Int? {
            guard let per = minutesPerCard else { return nil }
            return per * max(0, cardCount)
        }
    }

    var reader: Reader = .you
    var length: Length = .full

    /// The soft-cap minutes the in-session gentle timer consumes for a hand of
    /// `cardCount`. nil == no timer (No Rush).
    func softCapMinutes(cardCount: Int) -> Int? {
        length.estimatedMinutes(cardCount: cardCount)
    }
}
