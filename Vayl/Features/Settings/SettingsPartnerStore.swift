// Settings/SettingsPartnerStore.swift

import Foundation
import SwiftData

@Observable
@MainActor
final class SettingsPartnerStore {
    private(set) var pairedSince: Date? = nil

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func loadPairedSince() {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        pairedSince = profile.linkedAt
    }
}
