//
//  Untitled.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/28/26.
//

//
//  ModelContext+Extensions.swift
//  Vayl
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "ModelContext"
)

extension ModelContext {

    /// Save the context with full error logging and rethrow on failure.
    /// Use this everywhere instead of try? context.save().
    /// Silent saves are never acceptable — every failure must be visible.
    func saveWithLogging() throws {
        do {
            try save()
        } catch {
            logger.error("ModelContext save failed: \(error.localizedDescription)")
            throw error
        }
    }
}
