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

    private(set) var quizzes: [LearnQuiz] = []
    private(set) var findings: [ResearchFinding] = []
    private(set) var lexiconTerms: [LexiconTerm] = []
    private(set) var mediaQuotes: [MediaQuote] = []
    private(set) var media: [LearnMediaItem] = []
    private(set) var voices: [Voice] = []
    private(set) var supportResources: [SupportResource] = []
    private(set) var loadError: String?

    init() {
        load()                          // instant bundled baseline
        Task { await refresh() }        // then override from Supabase when reachable
    }

    /// Pulls server-driven content (findings + glossary), overriding the bundled
    /// baseline only when the fetch succeeds. Safe to call repeatedly.
    func refresh() async {
        if let f = await ContentService.shared.fetchFindings() { findings = f }
        if let t = await ContentService.shared.fetchGlossary() { lexiconTerms = t }
        if let q = await ContentService.shared.fetchQuotes()   { mediaQuotes = q }
    }

    func load() {
        do {
            quizzes          = try ContentLoader.load(LearnQuiz.self,       from: "learn_quizzes")
            findings         = try ContentLoader.load(ResearchFinding.self, from: "research_findings")
            lexiconTerms     = try ContentLoader.load(LexiconTerm.self,     from: "lexicon_terms")
            mediaQuotes      = try ContentLoader.load(MediaQuote.self,      from: "media_quotes")
            media            = try ContentLoader.load(LearnMediaItem.self,  from: "learn_media")
            voices           = try ContentLoader.load(Voice.self,           from: "voices")
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
    func voices(_ kind: VoiceKind) -> [Voice] { voices.filter { $0.kind == kind } }
    func finding(id: String) -> ResearchFinding? { findings.first { $0.id == id } }
    func resources(_ tier: ResourceTier) -> [SupportResource] { supportResources.filter { $0.tier == tier } }
}
