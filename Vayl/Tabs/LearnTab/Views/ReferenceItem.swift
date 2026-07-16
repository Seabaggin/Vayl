// Tabs/LearnTab/Views/ReferenceItem.swift
//
// One body, two shapes. Research findings and glossary terms are the same kind of
// thing — cited, first-party, "what we know" — so they share Learn's carousel and
// database. They don't share a row, because a finding is a claim someone measured
// (leads with the number, ends with the citation that makes it checkable) and a
// term is a word (leads with the word; the definition IS the payload).
//
// A view-layer join, not a model: the two corpora stay separate on disk and in
// LearnStore. This only exists so one list can hold both.

import SwiftUI

enum ReferenceItem: Identifiable {
    case finding(ResearchFinding)
    case term(LexiconTerm)

    /// Namespaced: a finding and a term could otherwise collide on a shared slug.
    var id: String {
        switch self {
        case .finding(let f): return "finding-\(f.id)"
        case .term(let t):    return "term-\(t.id)"
        }
    }

    /// Topics for filtering. Terms carry none today, so they only ever match "All".
    var topics: [String] {
        switch self {
        case .finding(let f): return f.topics
        case .term:           return []
        }
    }
}

/// The Learn reference's one filter dimension.
enum ReferenceFilter: String, CaseIterable, Identifiable {
    case all, findings, terms
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:      return "All"
        case .findings: return "Findings"
        case .terms:    return "Terms"
        }
    }
}

extension LearnStore {
    /// Findings then terms, filtered by kind. Order is corpus order and stable —
    /// a reference you consult should be where you left it.
    func reference(_ filter: ReferenceFilter = .all) -> [ReferenceItem] {
        var items: [ReferenceItem] = []
        if filter != .terms { items += findings.map(ReferenceItem.finding) }
        if filter != .findings { items += lexiconTerms.map(ReferenceItem.term) }
        return items
    }

    /// A short mixed preview for the front-page carousel: a few findings, then a
    /// couple of terms, so the section shows both halves of the body it opens into.
    var referencePreview: [ReferenceItem] {
        findings.prefix(3).map(ReferenceItem.finding)
            + lexiconTerms.filter { $0.kind == .term }.prefix(2).map(ReferenceItem.term)
    }
}
