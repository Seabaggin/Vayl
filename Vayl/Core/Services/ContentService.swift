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
}
