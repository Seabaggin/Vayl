// Core/Models/Learn/LexiconTerm.swift
//
// The lexicon corpus — terms and "in a sentence" usages. Loaded from
// lexicon_terms.json (bundled, snake_case decoded). Feeds the Learn glossary
// and the Home "Today" daily-5 (alongside ResearchFinding), replacing the
// hardcoded pool that used to live in HomeLexicon.
import Foundation

struct LexiconTerm: Codable, Identifiable, Hashable {
    let id: String
    let kind: LexiconKind
    let term: String
    let definition: String
    let example: String?   // .sentence kind only — the usage quote
}

enum LexiconKind: String, Codable {
    case term       // word + definition leads
    case sentence   // a usage quote leads, then the term + meaning
}
