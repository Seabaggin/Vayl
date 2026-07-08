//
//  PathActivityEntry.swift
//  Vayl — Path
//
//  Mirrors one row of `path_activity_log` (spec §11) — a plain-language,
//  append-only record of changes to the couple's shared Path map (spec §10).
//

import Foundation

/// Mirrors one row of `path_activity_log`. Append-only — this type is never
/// mutated after creation, only fetched and displayed (spec §10).
struct PathActivityEntry: Identifiable, Equatable {
    var id: UUID
    var coupleId: UUID
    var pathStyle: String
    var landmarkId: String
    var actorId: UUID
    var kind: PathActivityKind
    var detail: [String: String]?
    var createdAt: Date
}

enum PathActivityKind: String, Codable, Equatable {
    case curiousShared = "curious_shared"
    case discussedSession = "discussed_session"
    case discussedManual = "discussed_manual"
    case planningSet = "planning_set"
    case didItSet = "did_it_set"
    case didItDateChanged = "did_it_date_changed"
    case skipped
    case restored
}
