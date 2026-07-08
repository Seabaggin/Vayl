//
//  PathSyncService.swift
//  Vayl — Path
//
//  The real Supabase-backed PathTransport (Task 6). Follows PulseSyncService's
//  Row→Model translation-struct convention: private Codable row types with
//  explicit snake_case CodingKeys, a computed translator property, raw
//  SupabaseClient via SupabaseManager.shared.client. PathStore consumes this
//  through the PathTransport protocol seam (Task 5); MockPathTransport scripts
//  fixtures in tests.
//

import Foundation
import Supabase

final class PathSyncService: PathTransport {
    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private struct ProgressRow: Codable {
        let id: UUID
        let coupleId: UUID
        let pathStyle: String
        let landmarkId: String
        let state: String
        let discussedVia: String?
        let didItDate: Date?
        let setBy: UUID?
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case coupleId = "couple_id"
            case pathStyle = "path_style"
            case landmarkId = "landmark_id"
            case state
            case discussedVia = "discussed_via"
            case didItDate = "did_it_date"
            case setBy = "set_by"
            case updatedAt = "updated_at"
        }

        var toModel: PathLandmarkProgress {
            PathLandmarkProgress(
                id: id, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
                state: PathLandmarkState(rawValue: state) ?? .untouched,
                discussedVia: discussedVia.flatMap(DiscussedVia.init(rawValue:)),
                didItDate: didItDate, setBy: setBy, updatedAt: updatedAt
            )
        }
    }

    private struct ProgressUpsert: Encodable {
        let coupleId: UUID
        let pathStyle: String
        let landmarkId: String
        let state: String
        let discussedVia: String?
        let didItDate: Date?
        let setBy: UUID

        enum CodingKeys: String, CodingKey {
            case coupleId = "couple_id"
            case pathStyle = "path_style"
            case landmarkId = "landmark_id"
            case state
            case discussedVia = "discussed_via"
            case didItDate = "did_it_date"
            case setBy = "set_by"
        }
    }

    func fetchProgress(coupleId: UUID, pathStyle: String) async throws -> [PathLandmarkProgress] {
        let rows: [ProgressRow] = try await supabase
            .from("path_landmark_progress")
            .select()
            .eq("couple_id", value: coupleId.uuidString)
            .eq("path_style", value: pathStyle)
            .execute()
            .value
        return rows.map(\.toModel)
    }

    func setState(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        state: PathLandmarkState, discussedVia: DiscussedVia?, didItDate: Date?, setBy: UUID
    ) async throws -> PathLandmarkProgress {
        let upsert = ProgressUpsert(
            coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
            state: state.rawValue, discussedVia: discussedVia?.rawValue, didItDate: didItDate, setBy: setBy
        )
        let row: ProgressRow = try await supabase
            .from("path_landmark_progress")
            .upsert(upsert, onConflict: "couple_id,path_style,landmark_id")
            .select()
            .single()
            .execute()
            .value
        return row.toModel
    }

    func editDidItDate(
        coupleId: UUID, pathStyle: String, landmarkId: String, newDate: Date, setBy: UUID
    ) async throws -> PathLandmarkProgress {
        let row: ProgressRow = try await supabase
            .from("path_landmark_progress")
            .update(["did_it_date": ISO8601DateFormatter().string(from: newDate), "set_by": setBy.uuidString])
            .eq("couple_id", value: coupleId.uuidString)
            .eq("path_style", value: pathStyle)
            .eq("landmark_id", value: landmarkId)
            .select()
            .single()
            .execute()
            .value
        return row.toModel
    }

    private struct PrivateMarkRow: Codable {
        let id: UUID
        let profileId: UUID
        let coupleId: UUID?
        let pathStyle: String
        let landmarkId: String
        let markedAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case profileId = "profile_id"
            case coupleId = "couple_id"
            case pathStyle = "path_style"
            case landmarkId = "landmark_id"
            case markedAt = "marked_at"
        }

        var toModel: PathPrivateMark {
            PathPrivateMark(id: id, profileId: profileId, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId, markedAt: markedAt)
        }
    }

    func fetchPrivateMarks(profileId: UUID, pathStyle: String) async throws -> [PathPrivateMark] {
        let rows: [PrivateMarkRow] = try await supabase
            .from("path_private_marks")
            .select()
            .eq("profile_id", value: profileId.uuidString)
            .eq("path_style", value: pathStyle)
            .execute()
            .value
        return rows.map(\.toModel)
    }

    func addPrivateMark(profileId: UUID, coupleId: UUID?, pathStyle: String, landmarkId: String) async throws -> PathPrivateMark {
        struct Insert: Encodable {
            let profileId: UUID
            let coupleId: UUID?
            let pathStyle: String
            let landmarkId: String
            enum CodingKeys: String, CodingKey {
                case profileId = "profile_id"
                case coupleId = "couple_id"
                case pathStyle = "path_style"
                case landmarkId = "landmark_id"
            }
        }
        let row: PrivateMarkRow = try await supabase
            .from("path_private_marks")
            .insert(Insert(profileId: profileId, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId))
            .select()
            .single()
            .execute()
            .value
        return row.toModel
    }

    func removePrivateMark(profileId: UUID, pathStyle: String, landmarkId: String) async throws {
        _ = try await supabase
            .from("path_private_marks")
            .delete()
            .eq("profile_id", value: profileId.uuidString)
            .eq("path_style", value: pathStyle)
            .eq("landmark_id", value: landmarkId)
            .execute()
    }

    private struct ActivityRow: Codable {
        let id: UUID
        let coupleId: UUID
        let pathStyle: String
        let landmarkId: String
        let actorId: UUID
        let kind: String
        let detail: [String: String]?
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case coupleId = "couple_id"
            case pathStyle = "path_style"
            case landmarkId = "landmark_id"
            case actorId = "actor_id"
            case kind
            case detail
            case createdAt = "created_at"
        }

        var toModel: PathActivityEntry {
            PathActivityEntry(
                id: id, coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId,
                actorId: actorId, kind: PathActivityKind(rawValue: kind) ?? .skipped,
                detail: detail, createdAt: createdAt
            )
        }
    }

    func fetchActivity(coupleId: UUID, pathStyle: String) async throws -> [PathActivityEntry] {
        let rows: [ActivityRow] = try await supabase
            .from("path_activity_log")
            .select()
            .eq("couple_id", value: coupleId.uuidString)
            .eq("path_style", value: pathStyle)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(\.toModel)
    }

    func logActivity(
        coupleId: UUID, pathStyle: String, landmarkId: String,
        actorId: UUID, kind: PathActivityKind, detail: [String: String]?
    ) async throws {
        struct Insert: Encodable {
            let coupleId: UUID
            let pathStyle: String
            let landmarkId: String
            let actorId: UUID
            let kind: String
            let detail: [String: String]?
            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case pathStyle = "path_style"
                case landmarkId = "landmark_id"
                case actorId = "actor_id"
                case kind
                case detail
            }
        }
        _ = try await supabase
            .from("path_activity_log")
            .insert(Insert(coupleId: coupleId, pathStyle: pathStyle, landmarkId: landmarkId, actorId: actorId, kind: kind.rawValue, detail: detail))
            .execute()
    }
}
