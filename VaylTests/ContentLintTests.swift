//
//  ContentLintTests.swift
//  VaylTests
//
//  Structural lint for the 2026-07-01 launch deck re-cut (spec: card-sessions
//  front-to-back, sections 7 + 11). These encode the content contract that has
//  no UI to catch a regression:
//   • the catalog is exactly the 12 canonical launch decks with the right tiers,
//   • every deck file decodes, and counts/rituals/living-card mix hold,
//   • no card uses a deferred (render-path-less) CardType,
//   • gendered slots ship the mf + flexible pair, symmetrically,
//   • no em dash or en dash anywhere in copy (repo-wide rule),
//   • schemaVersion is pinned per deck so silent edits are visible.
//

import XCTest
@testable import Vayl

final class ContentLintTests: XCTestCase {

    // MARK: - Fixture

    /// The canonical launch slate, in catalog order (spec section 7.1).
    private static let launchDeckIds: [String] = [
        "the-opener", "the-check-in",
        "communication-intimacy", "sex-and-pleasure",
        "jealousy", "flavors-discovery", "swinging",
        "before-tonight", "after-last-night", "the-first-time",
        "when-it-gets-hard", "appreciation"
    ]

    private static let freeDeckIds: Set<String> = ["the-opener", "the-check-in"]

    /// Decks whose gendered slots ship the mf + flexible variant pair.
    private static let genderedDeckIds: Set<String> = [
        "the-opener", "sex-and-pleasure", "jealousy", "swinging"
    ]

    /// CardTypes with no V1 render path (Memory/Time + Shared Creation).
    /// Using one is a content bug: the session would render nothing.
    private static let deferredTypes: Set<CardType> = [
        .timeCapsule, .echo, .callback, .beforeAfter,
        .sharedCanvas, .spectrum, .wordCloud
    ]

    /// The Opener is canonical and feel-approved as shipped: its closing
    /// ritual IS the whisper ceremony (card 10), and its living-card count
    /// predates the dispatch matrix. Named exemption, asserted explicitly
    /// in test_closingRituals / test_livingCardCounts, never skipped silently.
    private static let canonicalCeremonyDeckId = "the-opener"

    /// schemaVersion pin: 2 = existing id touched by the re-cut,
    /// 1 = net-new id introduced by it. Any content edit must bump these.
    private static let expectedSchemaVersions: [String: Int] = [
        "the-opener": 2, "the-check-in": 2, "before-tonight": 2,
        "communication-intimacy": 1, "sex-and-pleasure": 1, "jealousy": 1,
        "flavors-discovery": 1, "swinging": 1, "after-last-night": 1,
        "the-first-time": 1, "when-it-gets-hard": 1, "appreciation": 1
    ]

    private var decks: [Deck] = []

    override func setUpWithError() throws {
        decks = try Self.launchDeckIds.map { try ContentLoader.loadDeck(id: $0) }
    }

    // MARK: - Catalog

    func test_catalog_isExactlyTheTwelveLaunchDecks() throws {
        let summaries = try DeckCatalogService().loadSummaries()
        XCTAssertEqual(summaries.map(\.id), Self.launchDeckIds,
                       "deck-catalog.json must list exactly the 12 canonical decks, in order")
    }

    func test_catalog_tiersMatchTheFreeTierDecision() throws {
        // D8: the-opener + the-check-in free; the other 10 Core-locked.
        let summaries = try DeckCatalogService().loadSummaries()
        for summary in summaries {
            if Self.freeDeckIds.contains(summary.id) {
                XCTAssertFalse(summary.isLocked, "\(summary.id) must be free")
                XCTAssertNil(summary.requiredEntitlement, "\(summary.id) must be free")
            } else {
                XCTAssertTrue(summary.isLocked, "\(summary.id) must be Core-locked")
                XCTAssertEqual(summary.requiredEntitlement, "core", "\(summary.id) must require core")
            }
        }
    }

    func test_catalog_cardCountsMatchPlayableCounts() throws {
        let summaries = try DeckCatalogService().loadSummaries()
        for (summary, deck) in zip(summaries, decks) {
            XCTAssertEqual(summary.id, deck.id)
            XCTAssertEqual(summary.cardCount, deck.cards(for: .mf).count,
                           "\(deck.id): catalog card_count must equal the playable count")
        }
    }

    // MARK: - Deck structure

    func test_everyDeck_parses_andCountsAreInRange() {
        XCTAssertEqual(decks.count, 12)
        for deck in decks {
            let playable = deck.cards(for: .mf).count
            let range = deck.id == "the-check-in" ? 5...6 : 10...11
            XCTAssertTrue(range.contains(playable),
                          "\(deck.id): \(playable) playable cards, expected \(range)")
            // The mf and flexible hands are the same size (variant pairs are symmetric).
            XCTAssertEqual(playable, deck.cards(for: .flexible).count,
                           "\(deck.id): mf and flexible hands must be the same size")
        }
    }

    func test_everyDeck_hasExactlyOneClosingRitual_asItsLastCard() {
        for deck in decks {
            let ordered = deck.orderedCards
            let closers = ordered.filter { $0.type == .closingRitual }
            if deck.id == Self.canonicalCeremonyDeckId {
                // The Opener's closer is its canonical whisper ceremony.
                XCTAssertEqual(closers.count, 0, "the-opener carries no closingRitual card")
                XCTAssertEqual(ordered.last?.type, .whisper,
                               "the-opener must end on its canonical whisper ceremony")
            } else {
                XCTAssertEqual(closers.count, 1,
                               "\(deck.id): exactly one closingRitual, found \(closers.count)")
                XCTAssertEqual(ordered.last?.id, closers.first?.id,
                               "\(deck.id): the closingRitual must be the last card")
            }
        }
    }

    func test_everyDeck_livingCardCountIsThreeToFour() {
        // Exempt: the-check-in (5-6 card ritual deck by design) and the
        // canonical Opener (9 discussion + 1 whisper, feel-approved as shipped).
        let exempt: Set<String> = ["the-check-in", Self.canonicalCeremonyDeckId]
        for deck in decks where !exempt.contains(deck.id) {
            let living = deck.cards(for: .mf).filter(\.isLivingCard).count
            XCTAssertTrue((3...4).contains(living),
                          "\(deck.id): \(living) living cards, expected 3-4")
        }
    }

    func test_noCard_usesADeferredCardType() {
        for deck in decks {
            for card in deck.cards {
                XCTAssertFalse(Self.deferredTypes.contains(card.type),
                               "\(deck.id)/\(card.id): \(card.type) has no V1 render path")
            }
        }
    }

    func test_noCard_usesSoloWhoStarts() {
        // The solo lane left the couple catalog (spec section 1).
        for deck in decks {
            for card in deck.cards {
                XCTAssertNotEqual(card.whoStarts, .solo,
                                  "\(deck.id)/\(card.id): solo whoStarts in a couple deck")
            }
        }
    }

    func test_noRevealMechanicCard_isTaggedAsABannerKicker() {
        // hasContextKicker must exclude reveal mechanics (spec non-goal:
        // whisper/unspoken/mirror/snapshot/whatIf get their own dedicated
        // explanation screens instead — docs/superpowers/specs/2026-07-07-
        // context-beat-header-design.md). This guards against a future
        // content-authoring mistake tagging a reveal-mechanic card as
        // context_beat_type: "banner", which would otherwise silently no-op.
        for deck in decks {
            for card in deck.cards where card.isRevealMechanic {
                XCTAssertFalse(card.hasContextKicker,
                               "\(deck.id)/\(card.id): reveal-mechanic card must never show the banner kicker")
            }
        }
    }

    // MARK: - Gendered contract

    func test_genderedDecks_shipSymmetricMfAndFlexiblePairs() {
        for deck in decks {
            let gendered = deck.cards.filter(\.isGenderedCard)
            if Self.genderedDeckIds.contains(deck.id) {
                let mf = gendered.filter { $0.genderedFor == .mf }
                let flex = gendered.filter { $0.genderedFor == .flexible }
                XCTAssertEqual(mf.count, 2, "\(deck.id): expected a His + Her mf pair")
                XCTAssertEqual(flex.count, 2, "\(deck.id): expected 2 flexible variants")
                // Variants pair up by shared sortOrder, so exactly one renders per slot.
                XCTAssertEqual(Set(mf.map(\.sortOrder)), Set(flex.map(\.sortOrder)),
                               "\(deck.id): mf and flexible variants must share sortOrders")
                // Only the two shipped dynamics exist; mm/ff copy is deferred.
                XCTAssertTrue(gendered.allSatisfy { $0.genderedFor == .mf || $0.genderedFor == .flexible },
                              "\(deck.id): only mf and flexible variants may ship")
            } else {
                XCTAssertTrue(gendered.isEmpty,
                              "\(deck.id): unexpected gendered card in a non-gendered deck")
            }
        }
    }

    // MARK: - Copy rules

    func test_noEmDashOrEnDash_inAnyCopyField() {
        let banned: Set<Character> = ["\u{2014}", "\u{2013}"]
        for deck in decks {
            var fields: [(String, String)] = [
                ("\(deck.id).title", deck.title),
                ("\(deck.id).subtitle", deck.subtitle)
            ]
            for card in deck.cards {
                fields.append(("\(card.id).text", card.text))
                for word in card.highlightWords {
                    fields.append(("\(card.id).highlightWords", word))
                }
                if let beat = card.contextBeatCopy { fields.append(("\(card.id).contextBeatCopy", beat)) }
                if let back = card.backCopy { fields.append(("\(card.id).backCopy", back)) }
            }
            for (label, value) in fields {
                XCTAssertFalse(value.contains(where: { banned.contains($0) }),
                               "em/en dash in \(label): \(value)")
            }
        }
    }

    // MARK: - Versioning

    func test_schemaVersions_arePinned() {
        for deck in decks {
            XCTAssertEqual(deck.schemaVersion, Self.expectedSchemaVersions[deck.id],
                           "\(deck.id): schemaVersion drifted; bump the pin with the edit")
        }
    }

    // MARK: - Dead files

    func test_deadContentFilesAreGone() {
        // Deleted by the re-cut; zero Swift callers (verified in plan 15 + this pass).
        for name in ["deck-index", "assessment_questions", "cards"] {
            XCTAssertNil(Bundle.main.url(forResource: name, withExtension: "json"),
                         "\(name).json should have been deleted from the bundle")
        }
        for deckId in ["boundaries", "trust-repair", "right-now", "metamour",
                       "the-audit", "unfinished-business", "solo-prep",
                       "communication", "desire-and-fantasy", "jealousy-compersion",
                       "the-styles"] {
            XCTAssertNil(Bundle.main.url(forResource: deckId, withExtension: "json"),
                         "\(deckId).json left the catalog and should be deleted")
        }
    }
}
