//
//  SessionBuilderStore.swift
//  Vayl
//
//  Session Builder brain (spec §4.3, absorbing fable-plan 11). Input: a deck's
//  composition-filtered cards + the resume index (DeckProgress.currentCardIndex,
//  passed by the host). Output: a SessionPlan (Codable struct) handed back
//  through the view's onConfirm; PlayStore calls openSession with plan.draft.
//
//  Default = authored order, untimed, full remaining hand. Tools = reorder,
//  trim (min 3 cards; the closing ritual is untrimmable when it is in tonight's
//  slice), per-card or global timer. Fast paths = Quick start (defaults, one
//  tap) and Same as last time (last SessionPlan per deck in UserDefaults).
//
//  No SwiftData, no network, no service. Pure state → plan. UserDefaults is
//  injected so tests isolate a suite.
//

import Foundation
import Observation
import OSLog
import SwiftUI   // Array.move(fromOffsets:toOffset:) lives in SwiftUI

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionBuilderStore")

@Observable
@MainActor
final class SessionBuilderStore {

    // MARK: - Entry (one card in tonight's slice)

    struct Entry: Identifiable, Equatable {
        let cardId: String
        let text: String
        let isClosingRitual: Bool
        let isCeremonial: Bool
        var timerSeconds: Int?

        var id: String { cardId }

        static func == (lhs: Entry, rhs: Entry) -> Bool {
            lhs.cardId == rhs.cardId && lhs.timerSeconds == rhs.timerSeconds
        }
    }

    // MARK: - State

    private(set) var entries: [Entry]
    var globalTimerSeconds: Int?

    /// Cards trimmed out of tonight's slice (restorable until start).
    private(set) var trimmed: [Entry] = []

    // MARK: - Rules

    /// The floor: a session is never fewer than 3 cards (spec §4.3).
    static let minimumCards = 3
    /// Per-card timer ladder, cycled by the row chip. 🎚️ Bryan tunes on device.
    static let timerOptions: [Int?] = [nil, 60, 120, 180, 300]

    // MARK: - Dependencies

    private let deckId: String
    private let defaults: UserDefaults
    private static func lastPlanKey(_ deckId: String) -> String {
        "vayl.lastSessionPlan.\(deckId)"
    }

    // MARK: - Init

    /// `cards` is the deck's authored order ALREADY composition-filtered
    /// (the host passes deck.cards(for:), .flexible when unknown).
    /// `startIndex` = DeckProgress.currentCardIndex — the remaining hand starts
    /// there. If fewer than minimumCards remain, the slice resets to the full
    /// hand (a nearly-finished deck starts a fresh run).
    init(deckId: String, cards: [Card], startIndex: Int, defaults: UserDefaults = .standard) {
        self.deckId = deckId
        self.defaults = defaults

        let ordered = cards.sorted { $0.sortOrder < $1.sortOrder }
        let clamped = min(max(0, startIndex), ordered.count)
        var remaining = Array(ordered.dropFirst(clamped))
        if remaining.count < Self.minimumCards {
            remaining = ordered
        }
        self.entries = remaining.map {
            Entry(cardId: $0.id,
                  text: $0.text,
                  isClosingRitual: $0.type == .closingRitual,
                  isCeremonial: $0.isCeremonial,
                  timerSeconds: nil)
        }
    }

    // MARK: - Derived

    var cardCount: Int { entries.count }
    var canTrimAny: Bool { entries.count > Self.minimumCards }

    /// Trim rule per card: floor of 3, and the closing ritual is protected
    /// whenever it is part of tonight's slice.
    func canTrim(_ cardId: String) -> Bool {
        guard entries.count > Self.minimumCards else { return false }
        guard let entry = entries.first(where: { $0.cardId == cardId }) else { return false }
        return !entry.isClosingRitual
    }

    // MARK: - Tools (reorder / trim / timers)

    func move(from offsets: IndexSet, to destination: Int) {
        entries.move(fromOffsets: offsets, toOffset: destination)
    }

    func trim(_ cardId: String) {
        guard canTrim(cardId) else { return }
        guard let idx = entries.firstIndex(where: { $0.cardId == cardId }) else { return }
        trimmed.append(entries.remove(at: idx))
    }

    /// Put a trimmed card back (appended to the end; the user re-orders freely).
    func restore(_ cardId: String) {
        guard let idx = trimmed.firstIndex(where: { $0.cardId == cardId }) else { return }
        entries.append(trimmed.remove(at: idx))
    }

    func setTimer(_ seconds: Int?, for cardId: String) {
        guard let idx = entries.firstIndex(where: { $0.cardId == cardId }) else { return }
        entries[idx].timerSeconds = seconds
    }

    /// Row chip: cycle the ladder nil → 1m → 2m → 3m → 5m → nil.
    func cycleTimer(for cardId: String) {
        guard let entry = entries.first(where: { $0.cardId == cardId }) else { return }
        let options = Self.timerOptions
        let idx = options.firstIndex(where: { $0 == entry.timerSeconds }) ?? 0
        setTimer(options[(idx + 1) % options.count], for: cardId)
    }

    // MARK: - Output

    /// The plan as currently authored. Per-card timers only include cards that
    /// actually have one; nil map when none do (untimed default).
    var plan: SessionPlan {
        var perCard: [String: Int] = [:]
        for entry in entries {
            if let s = entry.timerSeconds { perCard[entry.cardId] = s }
        }
        return SessionPlan(
            deckId: deckId,
            cardIds: entries.map(\.cardId),
            perCardTimerSeconds: perCard.isEmpty ? nil : perCard,
            globalTimerSeconds: globalTimerSeconds,
            deckVariant: nil
        )
    }

    /// Start: snapshot the plan, remember it for "Same as last time", return
    /// it for the host → openSession (Section 2 owns that call).
    func start() -> SessionPlan {
        let built = plan
        persistAsLast(built)
        return built
    }

    // MARK: - Fast paths

    /// QUICK START: the untouched default — authored order, untimed, full
    /// remaining hand. One tap, no authoring.
    func quickStartPlan() -> SessionPlan {
        let built = SessionPlan(
            deckId: deckId,
            cardIds: entries.map(\.cardId),
            perCardTimerSeconds: nil,
            globalTimerSeconds: nil,
            deckVariant: nil
        )
        persistAsLast(built)
        return built
    }

    /// SAME AS LAST TIME: the last started plan for THIS deck, if its cards
    /// are still all present in the current filtered hand (stale ids = no chip).
    var lastPlan: SessionPlan? {
        guard let data = defaults.data(forKey: Self.lastPlanKey(deckId)),
              let stored = try? JSONDecoder().decode(SessionPlan.self, from: data)
        else { return nil }
        let known = Set(entries.map(\.cardId) + trimmed.map(\.cardId))
        guard !stored.cardIds.isEmpty, stored.cardIds.allSatisfy(known.contains)
        else { return nil }
        return stored
    }

    private func persistAsLast(_ plan: SessionPlan) {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: Self.lastPlanKey(deckId))
        logger.info("builder: remembered plan for \(self.deckId) — \(plan.cardIds.count) cards")
    }
}
