// Core/Models/Learn/MediaQuote.swift
//
// "From the culture" — short, attributed quotes (books, shows, podcasts, people,
// or adages) for the Home daily-5. Server-driven (media_quotes table) with a
// bundled JSON fallback. Keep quotes short and ALWAYS attributed.
import Foundation

struct MediaQuote: Codable, Identifiable, Hashable {
    let id: String
    let quote: String
    let author: String     // who said it (person / work / "… adage")
    let source: String?    // the work: book / show / podcast (optional)
    let kind: String?      // book|show|podcast|person|adage (optional)
    let link: String?
}
