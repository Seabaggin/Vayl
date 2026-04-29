//
//  ModelContainer.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - SchemaV1
// Single source of truth for all registered @Model classes.
//
// Rule: add a model to SchemaV1.models on the SAME commit
// you write the model file. Never before it compiles.
// Never after — the app will crash on launch if the array
// and the actual @Model classes in the project diverge.
//
// Models marked PENDING are not yet written.
// Uncomment each line the moment its file compiles.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [

        // ── Existing — kept, will be extended not replaced ──────────────
        Couple.self,
        DesireMatch.self,
        UserProfile.self,

        // ── New models — uncomment as each file compiles ─────────────────
        CardSession.self,
        CardResult.self,
        SoloSession.self,
        DeckProgress.self,
        DesireMapEntry.self,
        DesireMapStatus.self,
        EntitlementRecord.self,
        ConnectionEntitlement.self,
        LockInSession.self,
        AcknowledgementRecord.self,
        MilestoneRecord.self
    ]
}

// MARK: - Migration Plan
// Empty stages are correct — no real users exist yet.
// When any @Model changes in the future, add a MigrationStage
// here before shipping. Never ship a model change without
// updating this first.

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self]
    static var stages: [MigrationStage] = []
}

// MARK: - ModelContainer

extension ModelContainer {

    /// App-wide ModelContainer.
    /// Called once from VaylApp.swift via .modelContainer(ModelContainer.appContainer)
    /// fatalError on failure is intentional — catches schema mismatches immediately.
    static var appContainer: ModelContainer {
        do {
            let schema = Schema(SchemaV1.models)
            let config = ModelConfiguration(
                "Vayl",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    /// In-memory container for SwiftUI previews and unit tests.
    /// Identical schema to appContainer — nothing hits disk.
    static var previewContainer: ModelContainer {
        do {
            let schema = Schema(SchemaV1.models)
            let config = ModelConfiguration(
                "VaylPreview",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("❌ Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }
}
