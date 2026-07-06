//
//  SyncTask.swift
//  Vayl
//

import Foundation
import SwiftData

/// Represents an asynchronous background task that needs to be synchronized
/// with the Supabase backend. Replaces fragile UserDefaults boolean flags.
@Model
final class SyncTask {
    
    // Use an enum-like string to avoid schema migrations for new task types
    var taskType: String
    
    // A string identifier for the entity being synced (e.g. Session UUID)
    var entityId: String
    
    // Timestamp when the task was created
    var createdAt: Date
    
    // Number of failed attempts
    var retryCount: Int
    
    // Optional JSON payload if the task doesn't rely on fetching the entity again
    var payload: Data?
    
    init(taskType: String, entityId: String, payload: Data? = nil) {
        self.taskType = taskType
        self.entityId = entityId
        self.createdAt = Date()
        self.retryCount = 0
        self.payload = payload
    }
}
