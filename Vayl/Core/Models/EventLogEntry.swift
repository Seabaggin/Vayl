//
//  EventLogEntry.swift
//  Vayl
//
//  A single Event Log entry: a real-world date / night / event, how it felt, kept
//  private or shared with the partner. Local SwiftData is the source of truth; entries
//  sync to `event_log_entries` (private rows are author-only by RLS, shared rows reach
//  the couple). Distinct from the Pulse (capacity) and from SessionReflection (a Vayl
//  session). `mood`/`tags`/`visibility` store the enum rawValues from EventLogEnums.
//

import Foundation
import SwiftData

@Model
final class EventLogEntry {
    var id: UUID
    var authorId: UUID
    var coupleId: UUID?          // set when shared
    var occurredOn: Date
    var title: String
    var note: String?
    var mood: String?            // EventMood.rawValue
    var tags: [String]           // EventTag.rawValue
    var who: String?
    var visibility: String       // EventVisibility.rawValue
    var createdAt: Date
    var updatedAt: Date

    init(
        authorId: UUID,
        coupleId: UUID? = nil,
        occurredOn: Date,
        title: String,
        note: String? = nil,
        mood: String? = nil,
        tags: [String] = [],
        who: String? = nil,
        visibility: String = "private"
    ) {
        self.id = UUID()
        self.authorId = authorId
        self.coupleId = coupleId
        self.occurredOn = occurredOn
        self.title = title
        self.note = note
        self.mood = mood
        self.tags = tags
        self.who = who
        self.visibility = visibility
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isShared: Bool { visibility == EventVisibility.shared.rawValue }
    var moodValue: EventMood? { mood.flatMap(EventMood.init(rawValue:)) }
    var tagValues: [EventTag] { tags.compactMap(EventTag.init(rawValue:)) }
}
