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
        MilestoneRecord.self,
        SyncTask.self,
        SessionReflection.self,
        EventLogEntry.self
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
    ///
    /// Store location is explicit — Application Support/Vayl.store.
    /// This guarantees the file lands inside the app sandbox where the
    /// Data Protection capability (Complete Protection) covers it.
    /// The file is unreadable when the device is locked.
    ///
    /// fatalError on failure is intentional — catches schema mismatches
    /// at launch rather than producing silent data loss.
    ///
    /// `static let`, not `static var` — the container is built once and
    /// cached. Every caller (VaylApp's .modelContainer, EntitlementStore,
    /// hydrateOnboardingState, SyncManager) must see the SAME instance, or
    /// writes through one Store's context silently don't appear in another's.
    static let appContainer: ModelContainer = {
        do {
            let schema = Schema(SchemaV1.models)

            // Explicit store URL — never let SwiftData choose the location.
            // Application Support is the correct directory for persistent
            // structured data. It is excluded from user-visible Documents
            // and included in the Data Protection sandbox.
            let storeURL = URL.applicationSupportDirectory
                .appending(path: "Vayl.store")

            let config = ModelConfiguration(
                "Vayl",
                schema: schema,
                url: storeURL
            )

            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    /// In-memory container for SwiftUI previews and unit tests.
    /// Identical schema to appContainer — nothing hits disk.
    /// No URL parameter — memory-only containers have no file to locate.
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

    /// In-memory container seeded with a completed UserProfile.
    /// Use for any preview that exercises code gated on onboarding completion:
    /// DesireMapView, DesireRevealView, AppShell (where the rater/reveal are reachable).
    static var previewContainerWithProfile: ModelContainer {
        do {
            let schema = Schema(SchemaV1.models)
            let config = ModelConfiguration(
                "VaylPreviewWithProfile",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
            let context = ModelContext(container)
            let profile = UserProfile(displayName: "Jordan")
            profile.hasCompletedOnboarding = true
            profile.onboardingCompletedAt = Date()
            context.insert(profile)
            try? context.save()
            return container
        } catch {
            fatalError("❌ Failed to create preview ModelContainer (with profile): \(error.localizedDescription)")
        }
    }
}
