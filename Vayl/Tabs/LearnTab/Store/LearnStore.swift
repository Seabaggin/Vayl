// Features/Learn/Store/LearnStore.swift
//
// Owns the Learn tab's read-only content, loaded once from bundled JSON
// via ContentLoader. View layer reads these arrays; derived accessors
// shape them per section. Mirrors the @Observable @MainActor shape of
// HomeStore (no SwiftData/appState deps needed for V1 content).

import SwiftUI

@Observable
@MainActor
final class LearnStore {

    private(set) var findings: [ResearchFinding] = []
    private(set) var lexiconTerms: [LexiconTerm] = []
    private(set) var mediaQuotes: [MediaQuote] = []
    private(set) var media: [LearnMediaItem] = []
    private(set) var voices: [Voice] = []
    private(set) var supportResources: [SupportResource] = []
    private(set) var loadError: String?

    private let content: ContentService

    /// `content` nil-resolves inside the MainActor-isolated body (a `= .shared`
    /// default argument would evaluate nonisolated — same pattern as SettingsStore).
    init(content: ContentService? = nil) {
        self.content = content ?? .shared
        load()                          // instant bundled baseline
        Task { await refresh() }        // then override from Supabase when reachable
    }

    /// Pulls server-driven content (findings + glossary), overriding the bundled
    /// baseline only when the fetch succeeds. Safe to call repeatedly.
    func refresh() async {
        if let f = await content.fetchFindings() { findings = f }
        if let t = await content.fetchGlossary() { lexiconTerms = t }
        if let q = await content.fetchQuotes() { mediaQuotes = q }
        // Media and voices were bundle-only until 2026-07-16, which meant a dead
        // outbound link — the one thing these two corpora carry — could only be
        // fixed by shipping a build.
        if let m = await content.fetchMedia() { media = m }
        if let v = await content.fetchVoices() { voices = v }
    }

    func load() {
        do {
            findings         = try ContentLoader.load(ResearchFinding.self, from: "research_findings")
            lexiconTerms     = try ContentLoader.load(LexiconTerm.self, from: "lexicon_terms")
            mediaQuotes      = try ContentLoader.load(MediaQuote.self, from: "media_quotes")
            media            = try ContentLoader.load(LearnMediaItem.self, from: "learn_media")
            voices           = try ContentLoader.load(Voice.self, from: "voices")
            supportResources = try ContentLoader.load(SupportResource.self, from: "support_resources")
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Derived
    var featuredFinding: ResearchFinding? { findings.first }
    var carouselFindings: [ResearchFinding] { Array(findings.dropFirst().prefix(2)) }
    var findingCount: Int { findings.count }

    func media(_ kind: MediaKind) -> [LearnMediaItem] { media.filter { $0.kind == kind } }
    func finding(id: String) -> ResearchFinding? { findings.first { $0.id == id } }
    func resources(_ tier: ResourceTier) -> [SupportResource] { supportResources.filter { $0.tier == tier } }
}
