// Core/Models/Learn/SupportResource.swift
import Foundation

struct SupportResource: Codable, Identifiable, Hashable {
    let id: String
    let tier: ResourceTier
    let title: String
    let detail: String
    let action: String
    let icon: String
}

enum ResourceTier: String, Codable, CaseIterable {
    case ongoing, crisis
}
