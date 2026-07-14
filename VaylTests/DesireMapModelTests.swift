//
//  DesireMapModelTests.swift
//  VaylTests
//
//  Pure-logic tests for the Desire Map models + the client-safe read DTOs.
//  No container, no network — these encode invariants that have no UI to catch a regression:
//   • the 4-point weight order (the answer copy maps to it positionally),
//   • the alignment vocabulary the reveal speaks,
//   • the celebration copy by alignment,
//   • that the client decode path is alignment-only and structurally cannot carry a raw answer.
//

import XCTest
@testable import Vayl

@MainActor
final class DesireMapModelTests: XCTestCase {

    // MARK: - DesireRatingValue (the 4-point weight)

    func test_ratingValue_caseOrderIsLoadBearing() {
        // The displayed answer arrays are indexed against this exact order — reordering it
        // silently mismaps every answer to the wrong weight.
        XCTAssertEqual(
            DesireRatingValue.allCases,
            [.excitedAboutIt, .openToIt, .probablyNot, .notForMe]
        )
    }

    func test_ratingValue_rawValuesMatchBackendVocabulary() {
        // These strings cross the wire to desire_ratings.rating (CHECK-constrained server-side).
        XCTAssertEqual(DesireRatingValue.excitedAboutIt.rawValue, "excitedAboutIt")
        XCTAssertEqual(DesireRatingValue.openToIt.rawValue, "openToIt")
        XCTAssertEqual(DesireRatingValue.probablyNot.rawValue, "probablyNot")
        XCTAssertEqual(DesireRatingValue.notForMe.rawValue, "notForMe")
    }

    func test_ratingValue_notForMeIsAFirstClassWeight() {
        // Privacy posture is sync-all-obscure-at-match: notForMe is a real, stored weight
        // (protected by RLS + excluded by the edge fn), NOT withheld at the client.
        XCTAssertTrue(DesireRatingValue.allCases.contains(.notForMe))
    }

    func test_ratingValue_codableRoundTrip() throws {
        for value in DesireRatingValue.allCases {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(DesireRatingValue.self, from: data)
            XCTAssertEqual(decoded, value)
        }
    }

    func test_ratingValue_displayNames() {
        XCTAssertEqual(DesireRatingValue.excitedAboutIt.displayName, "Excited About It")
        XCTAssertEqual(DesireRatingValue.openToIt.displayName, "Open To It")
        XCTAssertEqual(DesireRatingValue.probablyNot.displayName, "Probably Not")
        XCTAssertEqual(DesireRatingValue.notForMe.displayName, "Not For Me")
    }

    // MARK: - DesireMatchType (the shared signal)

    func test_matchType_casesAndRawValues() {
        XCTAssertEqual(DesireMatchType.allCases, [.mutual, .adjacent])
        XCTAssertEqual(DesireMatchType.mutual.rawValue, "mutual")
        XCTAssertEqual(DesireMatchType.adjacent.rawValue, "adjacent")
    }

    func test_matchType_displayNames() {
        XCTAssertEqual(DesireMatchType.mutual.displayName, "Mutual")
        XCTAssertEqual(DesireMatchType.adjacent.displayName, "Worth Exploring")
    }

    // MARK: - RevealMatch (view model)

    func test_revealMatch_celebrationByAlignment() {
        XCTAssertEqual(RevealMatch.sample("X", .mutual).celebration, "You're both excited about this.")
        XCTAssertEqual(RevealMatch.sample("X", .adjacent).celebration, "You're mostly aligned here.")
    }

    func test_revealMatch_celebrationWhenAlignmentUnknown() {
        let m = RevealMatch(id: UUID(), itemName: "X", itemCategory: nil,
                            alignment: nil, isLocked: false, bridgeCardId: nil)
        XCTAssertEqual(m.celebration, "You share this.")
    }

    func test_revealMatch_lockedFlagDefaultsUnlocked() {
        XCTAssertFalse(RevealMatch.sample("X", .mutual).isLocked)
        XCTAssertTrue(RevealMatch.sample("X", .mutual, locked: true).isLocked)
    }

    // MARK: - DesireMatchRow (client-safe read DTO)

    func test_matchRow_decodesAlignmentOnlyPayload() throws {
        let json = """
        { "id": "11111111-1111-1111-1111-111111111111",
          "desire_item_id": "shared_curiosity",
          "alignment_level": "mutual",
          "is_free_reveal": true,
          "bridge_card_id": null }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(DesireMatchRow.self, from: json)
        XCTAssertEqual(row.desireItemId, "shared_curiosity")
        XCTAssertEqual(row.matchType, .mutual)
        XCTAssertTrue(row.isFreeReveal)
        XCTAssertNil(row.bridgeCardId)
    }

    func test_matchRow_adjacentAndUnknownAlignment() throws {
        func row(_ level: String) throws -> DesireMatchRow {
            let json = """
            { "id": "22222222-2222-2222-2222-222222222222",
              "desire_item_id": "x", "alignment_level": "\(level)",
              "is_free_reveal": false, "bridge_card_id": null }
            """.data(using: .utf8)!
            return try JSONDecoder().decode(DesireMatchRow.self, from: json)
        }
        XCTAssertEqual(try row("adjacent").matchType, .adjacent)
        XCTAssertNil(try row("garbage").matchType)   // unknown level → no typed alignment
    }

    func test_matchRow_ignoresLeakedRawAnswerFields() throws {
        // Even if a payload smuggled raw answers, the client DTO has no field to receive them —
        // structural proof the read path is alignment-only.
        let json = """
        { "id": "33333333-3333-3333-3333-333333333333",
          "desire_item_id": "x", "alignment_level": "adjacent",
          "is_free_reveal": false, "bridge_card_id": null,
          "partner_a_value": "excitedAboutIt", "partner_b_value": "openToIt", "gap_size": 1 }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(DesireMatchRow.self, from: json)
        XCTAssertEqual(row.matchType, .adjacent)   // decodes fine, extra keys silently dropped
    }

    // MARK: - DesireMapStatusRow

    func test_statusRow_bothCompleteLogic() throws {
        func status(_ a: Bool, _ b: Bool) throws -> DesireMapStatusRow {
            let json = """
            { "track": "curious", "partner_a_complete": \(a), "partner_b_complete": \(b) }
            """.data(using: .utf8)!
            return try JSONDecoder().decode(DesireMapStatusRow.self, from: json)
        }
        XCTAssertFalse(try status(true, false).bothComplete)
        XCTAssertFalse(try status(false, true).bothComplete)
        XCTAssertTrue(try status(true, true).bothComplete)
    }

    // MARK: - RevealProgressRow (per-user "Seen")

    func test_revealProgressRow_seenFlags() throws {
        let json = """
        { "free_reveal_seen_at": "2026-06-26T00:00:00Z", "full_reveal_seen_at": null }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(RevealProgressRow.self, from: json)
        XCTAssertTrue(row.hasSeenFree)
        XCTAssertFalse(row.hasSeenFull)
    }

    // MARK: - DesireItem (track routing + answer mapping)

    func test_desireItem_trackMembershipAndAnswers() {
        let item = DesireItem(
            id: "x", name: "X", description: "d", category: "emotional",
            sensitivity: 1, sortOrder: 0,
            tracks: ["curious"],
            answers: ["curious": ["a", "b", "c", "d"]], meaning: nil
        )
        XCTAssertTrue(item.appears(in: "curious"))
        XCTAssertFalse(item.appears(in: "established"))
        XCTAssertEqual(item.answers(for: "curious"), ["a", "b", "c", "d"])
        XCTAssertNil(item.answers(for: "established"))
    }
}
