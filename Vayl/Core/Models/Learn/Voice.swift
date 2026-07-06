// Core/Models/Learn/Voice.swift
import Foundation

struct Voice: Codable, Identifiable, Hashable {
    let id: String
    let kind: VoiceKind
    let name: String
    let role: String
    let blurb: String
    let platform: String
    let link: String?
}

enum VoiceKind: String, Codable, CaseIterable {
    case creator, researcher
}
