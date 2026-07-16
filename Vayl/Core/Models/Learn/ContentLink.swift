// Core/Models/Learn/ContentLink.swift
//
// One outbound door on a Learn item.
//
// Why an array and not a single `link` field: a single URL forces a vendor
// choice, and for this audience that choice has a cost. Buying a non-monogamy
// book on Amazon puts it in an order history a partner can see, and Vayl's user
// is often exploring before that conversation has happened. So Learn points at
// FINDERS rather than sellers, and offers more than one:
//
//   Books    → Bookshop.org (funds indie stores) + a library finder
//   Shows    → JustWatch (answers "where can I watch this", not "buy it here")
//   Podcasts → the show's own site, or Apple + Spotify both
//   Voices   → their own profile
//
// No affiliate codes. The money is negligible at this scale, and an undisclosed
// cut on a product whose whole positioning is "we hand you the vocabulary, not a
// verdict" is a trust leak that stays invisible right up until someone notices.
//
// Vayl links a person's profile, never their link-aggregator page: what someone
// links from their own profile is their chain, not ours.

import Foundation

struct ContentLink: Codable, Identifiable, Hashable {
    /// Short, plain, and honest about where it goes: "Bookshop", "Find at a
    /// library", "Instagram", "Where to watch".
    let label: String
    let url: String

    var id: String { url }

    /// Non-empty, parseable links only — a blank string in the corpus must never
    /// produce a door that opens nothing.
    var resolved: URL? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
}

extension Array where Element == ContentLink {
    /// Only the links that actually resolve. The UI draws affordances from this,
    /// never from the raw array.
    var usable: [ContentLink] { filter { $0.resolved != nil } }
}
