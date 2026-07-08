//
//  PathPrivateMark.swift
//  Vayl — Path
//
//  Mirrors one row of `path_private_marks` (spec §11) — the private,
//  local-only Curious marker a partner sees before they choose to share it
//  (spec §4).
//

import Foundation

/// Mirrors one row of `path_private_marks`. Exists only on the marking
/// partner's own device/account — never couple-scoped, never joined against
/// the partner's data. See spec §4 and the RLS policy in Task 1.
struct PathPrivateMark: Identifiable, Equatable {
    var id: UUID
    var profileId: UUID
    var coupleId: UUID?
    var pathStyle: String
    var landmarkId: String
    var markedAt: Date
}
