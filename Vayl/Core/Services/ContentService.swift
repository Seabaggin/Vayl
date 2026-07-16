//
//  ContentService.swift
//  Vayl
//
//  Fetches server-driven editorial content (research findings + glossary terms)
//  from Supabase so the Learn corpus and the Home "Today" daily-5 can be updated
//  without an app build. Read-only, public content (RLS: published rows only).
//
//  Every method returns nil on any failure (offline, decode, etc.) so callers can
//  fall back to the bundled JSON — bundled is always the instant baseline; remote
//  is an override when reachable.
//

import Foundation
import Supabase

struct ContentService {

    static let shared = ContentService()

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    /// Published research findings, server sort order. Nil → use bundled fallback.
    func fetchFindings() async -> [ResearchFinding]? {
        do {
            let rows: [ResearchFinding] = try await supabase
                .from("research_findings")
                .select("id,type,stat,headline,finding,bullets,limitation,citation,author,year,topics,connected")
                .order("sort_order")
                .execute()
                .value
            return rows.isEmpty ? nil : rows
        } catch {
            return nil
        }
    }

    /// Published glossary terms, server sort order. Nil → use bundled fallback.
    func fetchGlossary() async -> [LexiconTerm]? {
        do {
            let rows: [LexiconTerm] = try await supabase
                .from("glossary_terms")
                .select("id,kind,term,definition,example")
                .order("sort_order")
                .execute()
                .value
            return rows.isEmpty ? nil : rows
        } catch {
            return nil
        }
    }

    /// Published "From the culture" quotes, server sort order. Nil → bundled fallback.
    func fetchQuotes() async -> [MediaQuote]? {
        do {
            let rows: [MediaQuote] = try await supabase
                .from("media_quotes")
                .select("id,quote,author,source,kind,link")
                .order("sort_order")
                .execute()
                .value
            return rows.isEmpty ? nil : rows
        } catch {
            return nil
        }
    }

    /// Published books/shows/podcasts, server sort order. Nil → bundled fallback.
    ///
    /// Remote-overridable because these rows carry outbound links, and links rot.
    /// Bundle-only meant a dead URL cost an App Store release.
    func fetchMedia() async -> [LearnMediaItem]? {
        do {
            let rows: [LearnMediaItem] = try await supabase
                .from("learn_media")
                .select("id,kind,title,creator,positioning,tier,platform,artwork_url,background,links")
                .order("sort_order")
                .execute()
                .value
            return rows.isEmpty ? nil : rows
        } catch {
            return nil
        }
    }

    /// Published creators, server sort order. Nil → bundled fallback.
    ///
    /// The most rot-prone corpus in the app: Instagram restricts, renames, and
    /// removes non-monogamy educators at a real rate, and creators migrate when it
    /// happens. This fetcher is what makes a dead handle a row update.
    func fetchVoices() async -> [Voice]? {
        do {
            let rows: [Voice] = try await supabase
                .from("voices")
                .select("id,name,role,blurb,topic,mode,platform,background,links")
                .order("sort_order")
                .execute()
                .value
            return rows.isEmpty ? nil : rows
        } catch {
            return nil
        }
    }
}
