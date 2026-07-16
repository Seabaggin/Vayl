// Core/Models/Learn/LearnMediaItem.swift
//
// A book, show, or podcast Vayl points people toward — third-party media, the
// "where to go deeper" half of Learn.
//
// `background` and `links` (2026-07-16) replace a single `link: String?`. Two
// reasons, both learned the hard way:
//
// 1. A row whose only destination was an external URL had no destination at all
//    when that column was null — which it was, in 100% of records. Tapping now
//    opens Vayl's own background copy, so the row always works and the outbound
//    link is one element inside the sheet rather than its reason to exist.
// 2. One URL forces a vendor choice. See ContentLink for why that costs this
//    audience something real.

import Foundation

struct LearnMediaItem: Codable, Identifiable, Hashable {
    let id: String
    let kind: MediaKind
    let title: String
    let creator: String
    /// One line for the row: what this is, in Vayl's voice.
    let positioning: String
    /// Editorial shelf marker ("Start here", "After first convo"). Optional.
    let tier: String?
    /// Where it lives ("Netflix", "Apple · Spotify"). Display only.
    let platform: String?
    let artworkUrl: String?
    /// Longer copy for the item sheet: what it is, who it's for, what it isn't.
    /// Nil until written — the sheet falls back to `positioning`.
    let background: String?
    let links: [ContentLink]
}

enum MediaKind: String, Codable, CaseIterable {
    case book, show, podcast
}
