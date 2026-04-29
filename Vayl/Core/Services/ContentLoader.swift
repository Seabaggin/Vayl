//
//  ContentLoader.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// ContentLoader.swift
// Simple static helper for reading bundled, read-only JSON
// content shipped with the app. These files are part of the
// app bundle and should always be present in production.
// Missing or malformed content is considered a developer error
// and intentionally triggers a fatalError so it is caught early
// during development.
// ============================================================

struct ContentLoader {

    /// Generic loader for an array of Decodable items from a
    /// bundled JSON file. The `filename` should NOT include the
    /// `.json` extension.
    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> [T] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Content file not found in bundle: \(filename).json")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch {
            fatalError("Failed to load or decode bundled content '\(filename).json': \(error)")
        }
    }


    // MARK: - Convenience Accessors

    static func loadCategories() -> [ContentCategory] {
        load(ContentCategory.self, from: "categories")
    }

    static func loadCards() -> [ContentCard] {
        load(ContentCard.self, from: "cards")
    }

    static func loadAssessmentQuestions() -> [ContentAssessmentQuestion] {
        load(ContentAssessmentQuestion.self, from: "assessment_questions")
    }

    static func loadDesireItems() -> [ContentDesireItem] {
        load(ContentDesireItem.self, from: "desire_items")
    }
}
