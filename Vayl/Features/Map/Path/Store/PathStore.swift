//
//  PathStore.swift
//  Vayl — Path
//
//  Owns the couple's shared Path map: bundled landmark content (via
//  PathContentService), per-couple progress and activity (via PathTransport),
//  and this profile's private Curious marks. Follows AirlockStore's
//  Store-owns-Transport-seam pattern.
//
//  The no-cascading guarantee (spec §2): a landmark's state is read straight
//  off its own PathLandmarkProgress row, or `.untouched` if none exists.
//  Setting one landmark's state never touches another landmark's row.
//

import Foundation

@Observable
@MainActor
final class PathStore {
    private(set) var landmarks: [PathLandmark] = []
    private(set) var phases: [PathPhase] = []
    private(set) var progressByLandmark: [String: PathLandmarkProgress] = [:]
    private(set) var activity: [PathActivityEntry] = []
    private(set) var privateMarkedLandmarkIds: Set<String> = []

    let coupleId: UUID
    let profileId: UUID
    let pathStyle: String

    private let transport: PathTransport
    private let content: PathContentService

    init(coupleId: UUID, profileId: UUID, pathStyle: String, transport: PathTransport, content: PathContentService = PathContentService()) {
        self.coupleId = coupleId
        self.profileId = profileId
        self.pathStyle = pathStyle
        self.transport = transport
        self.content = content
    }

    func load() async throws {
        let styleContent = try content.loadStyle(pathStyle)
        landmarks = styleContent.landmarks.sorted { $0.sortOrder < $1.sortOrder }
        phases = styleContent.phases

        let rows = try await transport.fetchProgress(coupleId: coupleId, pathStyle: pathStyle)
        progressByLandmark = Dictionary(uniqueKeysWithValues: rows.map { ($0.landmarkId, $0) })

        let marks = try await transport.fetchPrivateMarks(profileId: profileId, pathStyle: pathStyle)
        privateMarkedLandmarkIds = Set(marks.map(\.landmarkId))

        activity = try await transport.fetchActivity(coupleId: coupleId, pathStyle: pathStyle)
    }

    /// A landmark's state is `.untouched` unless a progress row exists for it —
    /// there is no cascading, no inference from other landmarks' states (spec §2).
    func state(for landmarkId: String) -> PathLandmarkState {
        progressByLandmark[landmarkId]?.state ?? .untouched
    }

    /// The earliest landmark not yet Did it — a pure wayfinding anchor, never a
    /// gate on interaction with any other landmark (spec §8).
    var nowLandmarkId: String? {
        landmarks.first { state(for: $0.id) != .didIt && state(for: $0.id) != .skipped }?.id
    }

    /// Sets a landmark's shared state and logs the matching activity kind in
    /// one round trip — the shared body behind setDidIt/setDiscussed/
    /// setPlanning/skip, which differ only in which state+kind they pass.
    @discardableResult
    private func applyState(
        _ landmarkId: String, state: PathLandmarkState, discussedVia: DiscussedVia? = nil,
        didItDate: Date? = nil, kind: PathActivityKind
    ) async throws -> PathLandmarkProgress {
        let updated = try await transport.setState(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            state: state, discussedVia: discussedVia, didItDate: didItDate, setBy: profileId
        )
        progressByLandmark[landmarkId] = updated
        try await transport.logActivity(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            actorId: profileId, kind: kind, detail: nil
        )
        return updated
    }

    func setDidIt(_ landmarkId: String, date: Date) async throws {
        try await applyState(landmarkId, state: .didIt, didItDate: date, kind: .didItSet)
    }

    func discussedVia(for landmarkId: String) -> DiscussedVia? {
        progressByLandmark[landmarkId]?.discussedVia
    }

    func didItDate(for landmarkId: String) -> Date? {
        progressByLandmark[landmarkId]?.didItDate
    }

    /// A landmark not `.skipped` — this is the default trail/ledger view.
    /// Restoring in Edit your path (Task 13) is the only way back.
    var visibleLandmarks: [PathLandmark] {
        landmarks.filter { state(for: $0.id) != .skipped }
    }

    func isPrivatelyMarkedCurious(_ landmarkId: String) -> Bool {
        privateMarkedLandmarkIds.contains(landmarkId)
    }

    func markCuriousPrivately(_ landmarkId: String) async throws {
        _ = try await transport.addPrivateMark(profileId: profileId, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId)
        privateMarkedLandmarkIds.insert(landmarkId)
    }

    /// Sharing is a unilateral act by whoever holds the private mark — it is
    /// never contingent on the partner having marked anything (spec §4).
    func shareCurious(_ landmarkId: String) async throws {
        try await applyState(landmarkId, state: .curious, kind: .curiousShared)
        try await transport.removePrivateMark(profileId: profileId, pathStyle: pathStyle, landmarkId: landmarkId)
        privateMarkedLandmarkIds.remove(landmarkId)
    }

    func setDiscussed(_ landmarkId: String, via: DiscussedVia) async throws {
        try await applyState(
            landmarkId, state: .discussed, discussedVia: via,
            kind: via == .session ? .discussedSession : .discussedManual
        )
    }

    func setPlanning(_ landmarkId: String) async throws {
        try await applyState(landmarkId, state: .planning, kind: .planningSet)
    }

    /// The date records when it was told to the app, never a claim about exact
    /// real-world timing — always editable afterward (spec §7).
    func editDidItDate(_ landmarkId: String, date: Date) async throws {
        let updated = try await transport.editDidItDate(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId, newDate: date, setBy: profileId
        )
        progressByLandmark[landmarkId] = updated
        try await transport.logActivity(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            actorId: profileId, kind: .didItDateChanged, detail: nil
        )
    }

    func skip(_ landmarkId: String) async throws {
        try await applyState(landmarkId, state: .skipped, kind: .skipped)
    }

    /// Restoring returns the landmark to `.untouched` — restoring is not the
    /// same as "undo the last real state," it's a clean reset back onto the trail.
    /// `.untouched` is never persisted (PathLandmarkProgress.swift), so this
    /// deletes the remote row outright rather than merely clearing the local
    /// cache — otherwise a later `load()` (relaunch, pull-to-refresh, partner's
    /// realtime update) would resurrect the stale `.skipped` row.
    func restore(_ landmarkId: String) async throws {
        try await transport.deleteProgress(coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId)
        progressByLandmark.removeValue(forKey: landmarkId)
        try await transport.logActivity(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            actorId: profileId, kind: .restored, detail: nil
        )
    }
}
