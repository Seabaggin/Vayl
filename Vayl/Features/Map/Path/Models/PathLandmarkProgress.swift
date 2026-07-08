//
//  PathLandmarkProgress.swift
//  Vayl — Path
//
//  Per-couple state for a single landmark on the shared Path map. Mirrors the
//  `path_landmark_progress` table's shape (spec §11) almost exactly, the same
//  convention already used for `card_progress`.
//

import Foundation

/// A landmark's state on the couple's shared map. `.untouched` is never
/// persisted — it's the Store's default when no row exists for a landmark
/// (spec §2, §11: "sparse — no row exists until something is actually set").
enum PathLandmarkState: String, Codable, Equatable {
    case untouched
    case curious
    case discussed
    case planning
    case didIt = "did_it"
    case skipped
}

enum DiscussedVia: String, Codable, Equatable {
    case session
    case manual
}

/// Mirrors one row of `path_landmark_progress`. `state` here is never
/// `.untouched` — untouched landmarks simply have no `PathLandmarkProgress`.
struct PathLandmarkProgress: Identifiable, Equatable {
    var id: UUID
    var coupleId: UUID
    var pathStyle: String
    var landmarkId: String
    var state: PathLandmarkState
    var discussedVia: DiscussedVia?
    var didItDate: Date?
    var setBy: UUID?
    var updatedAt: Date
}
