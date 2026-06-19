//
//  ContentLoader.swift
//  Vayl
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "ContentLoader"
)

// ============================================================
// ContentLoader
// Static helper for reading bundled, read-only JSON content
// shipped with the app.
//
// All methods throw on failure — never fatalError in production.
// Callers are responsible for handling errors visibly.
// ============================================================

enum ContentLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Content file not found in bundle: \(filename).json"
        case .decodingFailed(let filename, let underlying):
            return "Failed to decode '\(filename).json': \(underlying.localizedDescription)"
        }
    }
}

struct ContentLoader {

    // MARK: - Generic Loader

    /// Loads and decodes a single Decodable value from a bundled JSON file.
    /// The filename should NOT include the .json extension.
    /// Throws ContentLoaderError on missing file or decoding failure.
    static func loadSingle<T: Decodable>(
        _ type: T.Type,
        from filename: String,
        in subdirectory: String? = nil
    ) throws -> T {
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json",
            subdirectory: subdirectory
        ) else {
            logger.error("Content file not found: \(filename).json")
            throw ContentLoaderError.fileNotFound(filename)
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(type, from: data)
        } catch {
            logger.error("Failed to decode \(filename).json: \(error.localizedDescription)")
            throw ContentLoaderError.decodingFailed(filename, error)
        }
    }

    /// Loads and decodes an array of Decodable items from a bundled JSON file.
    /// The filename should NOT include the .json extension.
    /// Throws ContentLoaderError on missing file or decoding failure.
    static func load<T: Decodable>(
        _ type: T.Type,
        from filename: String,
        in subdirectory: String? = nil
    ) throws -> [T] {
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json",
            subdirectory: subdirectory
        ) else {
            logger.error("Content file not found: \(filename).json")
            throw ContentLoaderError.fileNotFound(filename)
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch {
            logger.error("Failed to decode \(filename).json: \(error.localizedDescription)")
            throw ContentLoaderError.decodingFailed(filename, error)
        }
    }

    // MARK: - Deck Loader

    /// Loads a single Deck from Resources/Decks/<id>.json.
    /// Throws ContentLoaderError on missing file or decoding failure.
    static func loadDeck(id: String) throws -> Deck {
        try loadSingle(Deck.self, from: id, in: nil)
    }

    // MARK: - Legacy Accessors
    // These now throw instead of fatalError.
    // Callers must handle errors visibly.

    static func loadCategories() throws -> [[String: String]] {
        try load([String: String].self, from: "categories")
    }

    static func loadCards() throws -> [[String: String]] {
        try load([String: String].self, from: "cards")
    }

    static func loadAssessmentQuestions() throws -> [[String: String]] {
        try load([String: String].self, from: "assessment_questions")
    }

    static func loadDesireItems() throws -> [DesireItem] {
        try load(DesireItem.self, from: "desire_items")
    }
}
