//
//  PathTransport.swift
//  Vayl — Path
//
//  The Store's seam to the network, following AirlockStore's AirlockTransport
//  pattern (protocol-seamed, mockable) rather than PulseSyncService's bare-
//  singleton pattern — PathStore needs to be testable without hitting
//  Supabase. LivePathTransport (Task 6) is the production conformance;
//  MockPathTransport (below) scripts fixtures in tests.
//

import Foundation

// MARK: - PathTransport (the store's seam — mocked in VaylTests)

/// Everything PathStore consumes. LivePathTransport is the production
/// conformance; MockPathTransport (VaylTests) scripts the fixtures.
protocol PathTransport: AnyObject {
    func fetchProgress(coupleId: UUID, pathStyle: String) async throws -> [PathLandmarkProgress]
    func setState(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        state: PathLandmarkState, discussedVia: DiscussedVia?, didItDate: Date?, setBy: UUID
    ) async throws -> PathLandmarkProgress
    func editDidItDate(
        coupleId: UUID, pathStyle: String, landmarkId: String, newDate: Date, setBy: UUID
    ) async throws -> PathLandmarkProgress

    func fetchPrivateMarks(profileId: UUID, pathStyle: String) async throws -> [PathPrivateMark]
    func addPrivateMark(profileId: UUID, coupleId: UUID?, pathStyle: String, landmarkId: String) async throws -> PathPrivateMark
    func removePrivateMark(profileId: UUID, pathStyle: String, landmarkId: String) async throws

    func fetchActivity(coupleId: UUID, pathStyle: String) async throws -> [PathActivityEntry]
    func logActivity(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        actorId: UUID, kind: PathActivityKind, detail: [String: String]?
    ) async throws
}

// MARK: - MockPathTransport (test double)

/// In-memory PathTransport double for VaylTests — scripts fixtures for
/// PathStore tests without touching Supabase.
final class MockPathTransport: PathTransport {
    var progress: [PathLandmarkProgress] = []
    var privateMarks: [PathPrivateMark] = []
    var activity: [PathActivityEntry] = []
    var loggedKinds: [PathActivityKind] = []

    func fetchProgress(coupleId: UUID, pathStyle: String) async throws -> [PathLandmarkProgress] {
        progress.filter { $0.coupleId == coupleId && $0.pathStyle == pathStyle }
    }

    func setState(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        state: PathLandmarkState, discussedVia: DiscussedVia?, didItDate: Date?, setBy: UUID
    ) async throws -> PathLandmarkProgress {
        let entry = PathLandmarkProgress(
            id: UUID(), coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            state: state, discussedVia: discussedVia, didItDate: didItDate, setBy: setBy, updatedAt: Date()
        )
        progress.removeAll { $0.coupleId == coupleId && $0.pathStyle == pathStyle && $0.landmarkId == landmarkId }
        progress.append(entry)
        return entry
    }

    func editDidItDate(
        coupleId: UUID, pathStyle: String, landmarkId: String, newDate: Date, setBy: UUID
    ) async throws -> PathLandmarkProgress {
        guard let idx = progress.firstIndex(where: { $0.coupleId == coupleId && $0.pathStyle == pathStyle && $0.landmarkId == landmarkId }) else {
            throw PathTransportError.notFound
        }
        progress[idx].didItDate = newDate
        progress[idx].updatedAt = Date()
        return progress[idx]
    }

    func fetchPrivateMarks(profileId: UUID, pathStyle: String) async throws -> [PathPrivateMark] {
        privateMarks.filter { $0.profileId == profileId && $0.pathStyle == pathStyle }
    }

    func addPrivateMark(profileId: UUID, coupleId: UUID?, pathStyle: String, landmarkId: String) async throws -> PathPrivateMark {
        let mark = PathPrivateMark(id: UUID(), profileId: profileId, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId, markedAt: Date())
        privateMarks.append(mark)
        return mark
    }

    func removePrivateMark(profileId: UUID, pathStyle: String, landmarkId: String) async throws {
        privateMarks.removeAll { $0.profileId == profileId && $0.pathStyle == pathStyle && $0.landmarkId == landmarkId }
    }

    func fetchActivity(coupleId: UUID, pathStyle: String) async throws -> [PathActivityEntry] {
        activity.filter { $0.coupleId == coupleId && $0.pathStyle == pathStyle }
    }

    func logActivity(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        actorId: UUID, kind: PathActivityKind, detail: [String: String]?
    ) async throws {
        loggedKinds.append(kind)
        activity.append(PathActivityEntry(id: UUID(), coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId, actorId: actorId, kind: kind, detail: detail, createdAt: Date()))
    }
}

enum PathTransportError: Error {
    case notFound
}
