//
//  DesireMapStore.swift
//  Vayl
//
//  Store layer for the Desire Map rater (4-Layer arch: View → Store → Service/Model).
//  Owns rater state, resolves the cohort TRACK from the local profile, and upserts
//  one DesireMapEntry per (userId, itemId). Local-only in D1 — no Service/sync calls.
//
//  TRACK resolution (D1, local): UserProfile.nmStage → "curious" | "established".
//  The couple-level rule (either partner curious → both get the Curious set) needs the
//  partner's nmStage and lands at compare time (D3/D4); this resolves the local user only.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class DesireMapStore: Identifiable {

    /// Identity for `.sheet`/`.fullScreenCover(item:)` presentation.
    let id = UUID()

    // MARK: - Published state

    /// Items for the resolved track, ordered by sortOrder.
    private(set) var items: [DesireItem] = []

    /// itemId → chosen weight. Mirrors the persisted DesireMapEntry rows.
    private(set) var ratings: [String: DesireRatingValue] = [:]

    /// "curious" | "established" — drives which answer copy the View shows.
    private(set) var track: String = "curious"

    /// Set when there is no local profile / load failed; the View shows an empty state.
    private(set) var loadError: String?

    var totalCount: Int { items.count }
    var ratedCount: Int { items.reduce(0) { $0 + (ratings[$1.id] != nil ? 1 : 0) } }
    var isComplete: Bool { totalCount > 0 && ratedCount == totalCount }

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private var userId: UUID?      // PRIVATE local profile id — stamped on each entry
    private var nmStageRaw: String = "curious"   // raw nm_stage — synced for the match edge fn

    /// Sync seam. Defaults to the real best-effort SyncManager push; tests inject a no-op (or a
    /// capture) so completion never spawns a background network/SwiftData Task that races teardown.
    /// Mirrors `CoupleSessionStore.enqueueSync`.
    private let enqueueSync: @MainActor ([PendingDesireRating], String) -> Void

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        enqueueSync: (@MainActor ([PendingDesireRating], String) -> Void)? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.enqueueSync = enqueueSync ?? { snapshot, stage in
            Task { await SyncManager.shared.syncDesireMap(ratings: snapshot, nmStage: stage) }
        }
    }

    // MARK: - Load

    /// Resolve the profile + track, load the track's items, and hydrate any existing ratings.
    func load() {
        resolveProfile()
        loadItems()
        loadExistingRatings()
        if isComplete {
            // Self-heal: a map completed before the completion flag was written still marks
            // the profile complete (idempotent).
            markProfileComplete()
            // Offline-retry: if a prior completion failed to sync, retry now that the rater is open.
            if UserDefaults.standard.bool(forKey: "pendingDesireSync") {
                triggerSync()
            }
        }
    }

    private func resolveProfile() {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            loadError = "No profile found — finish onboarding first."
            return
        }
        userId = profile.id
        nmStageRaw = profile.nmStage.rawValue
        track = (profile.nmStage == .curious) ? "curious" : "established"
    }

    private func loadItems() {
        do {
            let all = try ContentLoader.loadDesireItems()
            items = all
                .filter { $0.appears(in: track) }
                .sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            loadError = "Couldn't load desire items: \(error.localizedDescription)"
            items = []
        }
    }

    private func loadExistingRatings() {
        guard let userId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let entries = try? context.fetch(descriptor) else { return }
        ratings = Dictionary(entries.map { ($0.itemId, $0.rating) }, uniquingKeysWith: { _, latest in latest })
    }

    // MARK: - Rate (upsert)

    /// Save or update the user's rating for one item. Re-rating updates in place
    /// (one DesireMapEntry per (userId, itemId), mirroring the desire_ratings unique key).
    func rate(itemId: String, rating: DesireRatingValue) {
        guard let userId else { loadError = "No profile"; return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId && $0.itemId == itemId }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.rating = rating
            existing.completedAt = Date()
        } else {
            context.insert(DesireMapEntry(userId: userId, itemId: itemId, rating: rating))
        }
        try? context.save()
        ratings[itemId] = rating

        // On completion: durably mark the local profile complete (the truth the rest of the app
        // reads — HomeStore.myMapComplete, Getting Started, desireMapState), THEN sync. Local-first:
        // the flag is set independently of sync success (sync is best-effort and retried on reopen).
        if isComplete {
            markProfileComplete()
            triggerSync()
        }
    }

    // MARK: - Completion flag

    /// Durably mark the local profile's Desire Map complete — the single source of truth the rest
    /// of the app reads (`HomeStore.myMapComplete`, Getting Started, `desireMapState`). Set on
    /// completion, independently of remote sync. Idempotent.
    private func markProfileComplete() {
        guard let userId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let profile = try? context.fetch(descriptor).first,
              !profile.hasCompletedDesireMap else { return }
        profile.hasCompletedDesireMap = true
        try? context.save()
    }

    // MARK: - Sync (D2)

    /// Snapshot all of this user's entries and push to Supabase (best-effort, via SyncManager).
    private func triggerSync() {
        let snapshot = entrySnapshots()
        guard !snapshot.isEmpty else { return }
        enqueueSync(snapshot, nmStageRaw)
    }

    private func entrySnapshots() -> [PendingDesireRating] {
        guard let userId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let entries = try? context.fetch(descriptor) else { return [] }
        return entries.map(PendingDesireRating.init)
    }

    // MARK: - View helpers

    /// The four answer strings for `item` on the resolved track, in DesireRatingValue.allCases order.
    func answers(for item: DesireItem) -> [String] {
        item.answers(for: track) ?? []
    }

    func existingRating(for itemId: String) -> DesireRatingValue? {
        ratings[itemId]
    }

    // MARK: - Flow decisions (audit Blueprint C — the rater's forks live HERE, testable)

    /// Where the rater resumes: the first unrated item, or nil when everything is rated
    /// (or nothing is loaded).
    var firstUnratedIndex: Int? {
        items.firstIndex { existingRating(for: $0.id) == nil }
    }

    /// The post-rating branch — the "second-finisher rule". One owner: both the
    /// returning-user greeting and the charted-beat exit route through this.
    enum PostRatingDestination { case ready, mirror }
    func postRatingDestination(partnerComplete: Bool) -> PostRatingDestination {
        partnerComplete ? .ready : .mirror
    }

    /// The positive (excited / open) weights in item order — feeds the accumulating star sky.
    var positiveRatings: [DesireRatingValue] {
        items.compactMap { item in
            guard let r = existingRating(for: item.id),
                  r == .excitedAboutIt || r == .openToIt else { return nil }
            return r
        }
    }

    /// Rated items grouped by weight, in DesireRatingValue.allCases order, empty groups
    /// dropped — feeds the mirror screen. (Replaces a view computed property that
    /// force-unwrapped the rating between two separate lookups.)
    var ratedItemsByGroup: [(DesireRatingValue, [DesireItem])] {
        var grouped: [DesireRatingValue: [DesireItem]] = [:]
        for item in items {
            if let rating = existingRating(for: item.id) {
                grouped[rating, default: []].append(item)
            }
        }
        return DesireRatingValue.allCases.compactMap { rating in
            guard let items = grouped[rating], !items.isEmpty else { return nil }
            return (rating, items)
        }
    }
}
