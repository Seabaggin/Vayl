// Core/Models/Learn/Voice.swift
//
// A public-facing creator Vayl points people toward.
//
// Two rules govern this model, and both exist because these are real people:
//
// 1. CONSENT. Voices are creators only. A researcher publishing a paper makes
//    their WORK citable — that's what publication is for, and it's why findings
//    carry author/citation. It does not make the person a channel who opted into
//    being followed, least of all from a non-monogamy app. Researchers appear as
//    citations under findings; people whose own public account IS their chosen
//    channel appear here.
//
// 2. NEVER INFLATE. `mode` may never exceed what the person claims for themselves.
//    Calling someone an educator who calls themselves a creator hands them
//    authority they didn't ask for — the same failure as repeating an expired
//    certification, just softer. When it's ambiguous, take the more modest label;
//    under-claiming is the recoverable error. Every label ships traceable to the
//    person's own bio (see docs, and scratchpad research for sourcing).

import Foundation

struct Voice: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    /// Free text, as they present themselves ("Solo polyamory content creator").
    /// Distinct from `mode`, which is the closed vocabulary the UI filters and
    /// labels on. Never publish a surname for someone who publishes only a first
    /// name, and never assert a credential that isn't sourced.
    let role: String
    /// One line for the row.
    let blurb: String
    let topic: VoiceTopic
    let mode: VoiceMode
    /// Where they publish ("Instagram", "TikTok · IG"). Display only.
    let platform: String
    /// Longer copy for the item sheet: what they're about and who they're for.
    /// Nil until written — the sheet falls back to `blurb`.
    let background: String?
    /// Outbound links. Vayl links a profile, never a link-aggregator page: what
    /// someone links from their own profile is their chain, not ours.
    let links: [ContentLink]
}

/// The shape of non-monogamy someone's work is about — the Voices filter.
///
/// This is a real taxonomy of the territory, not a content tag: it's roughly the
/// shape-space a couple is choosing between. Assigned from the person's own
/// framing only ("A Swinger Podcast" → .lifestyle), never inferred from a vibe.
enum VoiceTopic: String, Codable, CaseIterable, Identifiable {
    case polyamory
    case open           // open relationships that aren't swinging
    case lifestyle      // swinging; the community's own term for it
    case sexEducation   // broader sex + intimacy education

    var id: String { rawValue }

    /// Filter chip label.
    var label: String {
        switch self {
        case .polyamory:    return "Polyamory"
        case .open:         return "Open"
        case .lifestyle:    return "The Lifestyle"
        case .sexEducation: return "Sex ed"
        }
    }

    /// The adjective half of a row label ("Poly educator").
    var shortLabel: String {
        switch self {
        case .polyamory:    return "Poly"
        case .open:         return "Open"
        case .lifestyle:    return "Lifestyle"
        case .sexEducation: return "Sex"
        }
    }
}

/// What someone does — the label's second half. NEVER exceeds their own claim.
enum VoiceMode: String, Codable {
    case creator      // shares lived experience; the safe default
    case writer       // essays, books, columns — their own word
    case educator     // teaches; only if they call themselves that
    case coach        // only with a sourced practice
    case therapist    // only with a sourced licence

    var label: String {
        switch self {
        case .creator:   return "creator"
        case .writer:    return "writer"
        case .educator:  return "educator"
        case .coach:     return "coach"
        case .therapist: return "therapist"
        }
    }
}

extension Voice {
    /// "Poly educator", "Lifestyle creator" — topic + mode, composed.
    var label: String { "\(topic.shortLabel) \(mode.label)" }
}
