//
//  Card.swift
//  Vayl
//
//  Location: Models/Content/Card.swift
//  Read-only. Loaded from JSON at runtime.
//  NEVER stored in SwiftData.
//  Replaces Prompt.swift and ContentCard.swift — both deleted.
//  The String cardId on CardResult is the only join between
//  this content layer and the SwiftData progress layer.
//

import Foundation

// MARK: - Card

struct Card: Codable, Identifiable {

    let id: String                          // stable — never changes even if text changes
    let deckId: String
    let text: String
    let highlightWords: [String]
    let type: CardType
    let intensity: CardIntensity
    let whoStarts: WhoStarts
    let isSensitive: Bool                   // true → screenshot protection active
    let canSkip: Bool
    let register: EmotionalRegister         // which register this card primarily serves
    let contextBeatType: ContextBeatType?   // nil = no beat before this card
    let contextBeatCopy: String?            // nil if no beat
    let backCopy: String?                   // responsive to answer — not setup copy
    let isGenderedCard: Bool
    let genderedFor: GenderDynamic?         // nil if isGenderedCard is false
    let sortOrder: Int

    // MARK: - Derived

    /// Whether this card requires both partners to input privately before reveal.
    var isRevealMechanic: Bool {
        switch type {
        case .whisper, .unspoken, .mirror, .snapshot, .whatIf:
            return true
        default:
            return false
        }
    }

    /// Whether this card has a pre-card context beat.
    var hasContextBeat: Bool {
        contextBeatType != nil && contextBeatCopy != nil
    }

    /// Whether this card has back copy.
    var hasBackCopy: Bool {
        backCopy != nil
    }

    /// Whether this card is a structural/ceremonial card.
    var isCeremonial: Bool {
        switch type {
        case .openingRitual, .closingRitual, .pause:
            return true
        default:
            return false
        }
    }

    /// Whether this card is a living card (native to digital medium).
    var isLivingCard: Bool {
        switch type {
        case .prompt, .reflect:
            return false
        default:
            return true
        }
    }
}

// MARK: - Card Sample Data
// Used for UI previews and stub state only.
// Real content loads from JSON via ContentLoader.

extension Card {

    static let openerSamples: [Card] = [
        Card(
            id: "opener-01",
            deckId: "the-opener",
            text: "What are the anchors that have kept you two tethered to each other through everything so far?",
            highlightWords: ["anchors", "tethered"],
            type: .prompt,
            intensity: .deepOcean,
            whoStarts: .partnerA,
            isSensitive: false,
            canSkip: false,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 1
        ),
        Card(
            id: "opener-02",
            deckId: "the-opener",
            text: "What does a boundary mean to you?\n\nDo you feel like you two genuinely respect each other's boundaries?",
            highlightWords: ["boundary"],
            type: .prompt,
            intensity: .emberFloor,
            whoStarts: .partnerA,
            isSensitive: false,
            canSkip: false,
            register: .flexible,
            contextBeatType: .interstitial,
            contextBeatCopy: "Something worth knowing before you go further:\n\nA boundary is a limit you set for yourself — not a rule you can set for someone else.\n\n\"I won't sleep with anyone without a condom\" is a boundary. It's yours. Your partner is still free to make their own choice — but now you know if you're compatible.",
            backCopy: "If either of you answered no to the second question — that's not a red flag, it's a starting point. What specific boundary has felt ignored? Name it out loud before the next card.",
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 2
        ),
        Card(
            id: "opener-03",
            deckId: "the-opener",
            text: "Where does communication between you two usually fall apart?\n\nWhat does that moment typically look like?",
            highlightWords: ["fall apart"],
            type: .prompt,
            intensity: .split,
            whoStarts: .partnerB,
            isSensitive: false,
            canSkip: true,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 3
        ),
        Card(
            id: "opener-04",
            deckId: "the-opener",
            text: "Exploring this will bring things to the surface that have been easy to ignore until now.\n\nWhat insecurities do you expect to show up for you?\n\nHow do you want your partner to show up when they do?",
            highlightWords: ["insecurities"],
            type: .prompt,
            intensity: .split,
            whoStarts: .partnerA,
            isSensitive: false,
            canSkip: true,
            register: .anxious,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 4
        ),
        Card(
            id: "opener-05",
            deckId: "the-opener",
            text: "What tends to trigger it in you specifically?\n\nWhat do you need to build to navigate it well in this?",
            highlightWords: ["trigger", "navigate"],
            type: .prompt,
            intensity: .nebula,
            whoStarts: .partnerB,
            isSensitive: false,
            canSkip: true,
            register: .flexible,
            contextBeatType: .banner,
            contextBeatCopy: "Jealousy will show up. Guaranteed.",
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 5
        ),
        Card(
            id: "opener-06",
            deckId: "the-opener",
            text: "In most NM spaces men find the dating landscape harder to navigate than expected.\n\nFewer matches. More skepticism. A quiet question that can creep in...\n\nAm I enough?\n\nHow do you each sit with that reality? What does it bring up for you? What does it make you want to do for each other?",
            highlightWords: ["Am I enough?"],
            type: .prompt,
            intensity: .nebula,
            whoStarts: .both,
            isSensitive: false,
            canSkip: true,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: true,
            genderedFor: .mf,
            sortOrder: 6
        ),
        Card(
            id: "opener-07",
            deckId: "the-opener",
            text: "Women in NM often find themselves with more access than they anticipated.\n\nThat can feel electric but it can also complicate things. Enjoying all of this newness will require balance.\n\nHow do you both intend to find it? What feels exciting? What feels scary?",
            highlightWords: ["balance", "electric"],
            type: .prompt,
            intensity: .nebula,
            whoStarts: .both,
            isSensitive: false,
            canSkip: true,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: true,
            genderedFor: .mf,
            sortOrder: 7
        ),
        Card(
            id: "opener-08",
            deckId: "the-opener",
            text: "Expectations rarely match reality.\n\nWhat are you each expecting this to look and feel like?\n\nWhich feel grounded? Which are you holding onto a little too tightly?",
            highlightWords: ["Expectations", "reality"],
            type: .prompt,
            intensity: .auroraBand,
            whoStarts: .partnerA,
            isSensitive: false,
            canSkip: true,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 8
        ),
        Card(
            id: "opener-09",
            deckId: "the-opener",
            text: "What do you love most about your sex life together?\n\nWhat's one thing you'd change, add, or explore if you could?",
            highlightWords: ["sex life", "explore"],
            type: .prompt,
            intensity: .deepSpace,
            whoStarts: .partnerB,
            isSensitive: true,
            canSkip: true,
            register: .excited,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 9
        ),
        Card(
            id: "opener-10",
            deckId: "the-opener",
            text: "One thing.\n\nWhat excites you most about where this could go?",
            highlightWords: ["One thing."],
            type: .whisper,
            intensity: .supernova,
            whoStarts: .both,
            isSensitive: true,
            canSkip: false,
            register: .excited,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 10
        )
    ]

    /// Empty sample set — safe default when no content is loaded.
    static let samples: [Card] = openerSamples
}
