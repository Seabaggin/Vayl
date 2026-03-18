import Foundation
import SwiftData

// MARK: - ModelContainer+App
// Configures the shared SwiftData ModelContainer with all schemas.
// This is the single place where we register every @Model class.
// Called once from OpenLightlyApp.swift to inject into the SwiftUI scene.

extension ModelContainer {

    /// Creates the app-wide ModelContainer with all models registered.
    /// - Returns: A configured ModelContainer ready to inject via .modelContainer()
    ///
    /// Usage in OpenLightlyApp.swift:
    /// ```
    /// .modelContainer(ModelContainer.appContainer)
    /// ```
    ///
    /// If the container fails to create (corrupted DB, schema mismatch),
    /// this will crash with a fatalError — intentional so we catch it immediately.
    static var appContainer: ModelContainer {
        do {
            let schema = Schema([
                SessionRecord.self,
                RatingRecord.self,
                StreakRecord.self,
                UserProfile.self,
                DesireRating.self,
                Couple.self,
                DesireMatch.self,
                CardProgress.self,
                CoupleSessionRecord.self,
                AssessmentResponse.self,
                AssessmentResult.self
            ])

            let config = ModelConfiguration(
                "OpenLightly",
                schema: schema,
                isStoredInMemoryOnly: false
            )

            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    /// In-memory container for SwiftUI previews and unit tests.
    /// Same schema, but nothing hits disk.
    static var previewContainer: ModelContainer {
        do {
            let schema = Schema([
                SessionRecord.self,
                RatingRecord.self,
                StreakRecord.self,
                UserProfile.self,
                DesireRating.self,
                Couple.self,
                DesireMatch.self,
                CardProgress.self,
                CoupleSessionRecord.self,
                AssessmentResponse.self,
                AssessmentResult.self
            ])

            let config = ModelConfiguration(
                "OpenLightlyPreview",
                schema: schema,
                isStoredInMemoryOnly: true
            )

            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }
}
