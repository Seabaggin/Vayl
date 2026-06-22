// Core/Models/Learn/LearnQuiz.swift
import Foundation

struct LearnQuiz: Codable, Identifiable, Hashable {
    let id: String
    let kind: String
    let title: String
    let subtitle: String
    let questionCount: Int
}
