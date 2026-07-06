// Core/Models/Learn/LearnMediaItem.swift
import Foundation

struct LearnMediaItem: Codable, Identifiable, Hashable {
    let id: String
    let kind: MediaKind
    let title: String
    let creator: String
    let positioning: String
    let tier: String?
    let platform: String?
    let artworkUrl: String?
    let link: String?
}

enum MediaKind: String, Codable, CaseIterable {
    case book, show, podcast
}
