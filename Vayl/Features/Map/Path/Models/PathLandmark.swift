//
//  PathLandmark.swift
//  Vayl — Path
//
//  Static, bundled content for one Path style (spec §3). Landmarks and their
//  phases never change per-couple — only a couple's `PathLandmarkProgress`
//  rows (state, dates, who set them) are per-couple and mutable.
//

import Foundation

/// One named grouping of landmarks along a Path style's trail (spec §3).
struct PathPhase: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}

/// One static landmark definition — title and copy shipped with the app,
/// never mutated. A couple's actual state for this landmark lives in a
/// separate `PathLandmarkProgress` row, keyed by `id`.
struct PathLandmark: Codable, Identifiable, Equatable {
    let id: String
    let phaseId: Int
    let title: String
    let eventCopy: String
    let goldenRule: String?
    let sortOrder: Int
}

/// The full bundled content for one Path style (e.g. "swinging") — its
/// phases and the landmarks that belong to them.
struct PathStyleContent: Codable, Equatable {
    let styleId: String
    let phases: [PathPhase]
    let landmarks: [PathLandmark]
}
