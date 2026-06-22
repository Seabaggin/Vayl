// Core/Models/Learn/ResearchFinding.swift
import Foundation

struct ResearchFinding: Codable, Identifiable, Hashable {
    let id: String
    let type: FindingType
    let stat: String?
    let headline: String
    let finding: String
    let bullets: [String]
    let limitation: String
    let citation: String
    let author: String
    let year: Int
    let topics: [String]
    let connected: [String]
}

enum FindingType: String, Codable, CaseIterable {
    case prevalence, comparison, predictor, myth, mechanism
}
