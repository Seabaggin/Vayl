//
//  MapStore.swift
//  Vayl
//
//  The Map tab's state owner (4-layer: View -> Store -> Service -> Model). Owns the
//  Me/Us layer toggle, derives the personal masthead, and assembles the Record
//  (session history + category distribution) from the couple's CardSession data.
//  Later segments extend it (Me Card, Us layer, Vault). The store fetches; views
//  only read.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class MapStore {

    /// The two faces of the Map: your own mirror, and the couple layer.
    enum Layer: String, CaseIterable {
        case me, us
    }

    /// Which layer the segmented control is showing.
    var layer: Layer = .me

    // MARK: - Lens gating (Map dashboard spec §2.3)

    /// Us exists only after linking: partner identity loaded. Views render no
    /// toggle, no sublabel, no Us content when this is false.
    var hasUs: Bool { !partnerName.isEmpty }

    /// If the Us lens vanished (unlink, partner cleared), snap back to Me.
    func enforceLensGate() {
        if !hasUs && layer == .us { layer = .me }
    }

    // MARK: - Us reveal ceremony flag (spec §2.4)

    private let defaults: UserDefaults
    /// Single source for the key — SettingsStore's unlink reset uses the same statics.
    static let usRevealKey = "map.usRevealSeen"

    private let pulseSync: PulseSyncService
    private let desireSync: DesireSyncService
    private let deckCatalog: DeckCatalogService

    /// Service params nil-resolve inside the MainActor-isolated body (a `= .shared`
    /// default argument would evaluate nonisolated — same pattern as SettingsStore).
    init(
        defaults: UserDefaults = .standard,
        pulseSync: PulseSyncService? = nil,
        desireSync: DesireSyncService? = nil,
        deckCatalog: DeckCatalogService? = nil
    ) {
        self.defaults = defaults
        self.pulseSync = pulseSync ?? .shared
        self.desireSync = desireSync ?? .shared
        self.deckCatalog = deckCatalog ?? DeckCatalogService()
    }

    var usRevealSeen: Bool { defaults.bool(forKey: Self.usRevealKey) }
    func markUsRevealSeen() { defaults.set(true, forKey: Self.usRevealKey) }
    /// Unlink resets the flag so a future re-link earns the ceremony again (§2.3).
    func resetUsReveal() { defaults.set(false, forKey: Self.usRevealKey) }
    /// Static variant for callers without a MapStore (the Settings unlink path).
    static func resetUsRevealGlobally() { UserDefaults.standard.set(false, forKey: usRevealKey) }

    // MARK: - Derived masthead

    private(set) var displayName: String = ""
    private(set) var subtitle: String = ""

    /// The linked partner's name — drives the "Jordan & Alex." header toggle.
    /// Empty when unpaired or not yet fetched (header falls back to your name only).
    /// Read from CoupleContext — the single owner of partner identity (audit F1);
    /// this store no longer runs its own fetch.
    var partnerName: String { couple?.partnerName ?? "" }

    /// Couple-fact source of truth, attached once from the hosting view's `.task`
    /// (@State store construction can't reach @Environment).
    private var couple: CoupleContext?

    func configure(couple: CoupleContext) {
        guard self.couple == nil else { return }
        self.couple = couple
    }

    // MARK: - The Record (Me layer)

    struct RecordSession: Identifiable {
        let id: UUID
        let deckName: String
        let category: DeckCategory
        let date: Date
        let cardCount: Int
    }

    struct CategoryShare: Identifiable {
        let category: DeckCategory
        let count: Int
        var id: String { category.rawValue }
    }

    private(set) var sessions: [RecordSession] = []
    private(set) var categoryShares: [CategoryShare] = []

    // MARK: - The Me Card (Me layer)

    struct DrawnTag: Identifiable, Hashable {
        let name: String
        let isShared: Bool
        var id: String { name }
    }

    struct MeCard {
        var flavor: Flavor = .explorer
        var name: String = ""
        var title: String = ""
        var tags: [DrawnTag] = []
    }

    private(set) var meCard = MeCard()

    // MARK: - Pulse positions

    /// The partner's current circumplex position — derived from their most recent
    /// `pulse_entries` row. nil when unpaired, not shared, or not yet logged.
    private(set) var partnerPosition: PulsePosition? = nil

    /// The partner's full check-in history (oldest first) — feeds the Us layer's
    /// paired history grid. Empty for the same reasons partnerPosition can be nil.
    private(set) var partnerEntries: [PulseEntry] = []

    // MARK: - The Us layer

    struct UsStats {
        var isLinked: Bool = false
        var tenureStage: String? = nil
        var tenureTime: String? = nil
        var weeksOnVayl: Int = 0
        var sessionCount: Int = 0
    }

    struct AlignItem: Identifiable {
        let id: String
        let name: String
        let isMutual: Bool
    }

    private(set) var usStats = UsStats()
    private(set) var alignItems: [AlignItem] = []
    private(set) var lockedAlignCount: Int = 0

    // MARK: - Load

    /// Idempotent — safe to call on every appear. The desire-match gate reads
    /// `CoupleContext.canRevealAll` (the OR'd entitlement), never the lagging
    /// local Couple mirror.
    func load(appState: AppState, context: ModelContext) {
        loadMasthead(appState: appState, context: context)
        loadRecord(coupleId: appState.coupleId, context: context)
        loadMeCard(context: context)
        loadUs(appState: appState, context: context)
        Task { await loadServerAlignData(appState: appState, context: context) }
    }

    /// Async: fetches the partner's full Pulse history and derives their current position
    /// from the latest entry — feeds both the Us field's live orb (G6) and the Us history
    /// grid's partner column (G4/G5). Unlike loadPartner (name, cached once after first
    /// success), this re-fetches on every call: the partner may check in again while this
    /// tab is open elsewhere in the app, and there's no cheap way to know without asking.
    /// A nil result (offline / fetch failure) leaves whatever's already loaded untouched;
    /// only an explicit "not paired" clears it.
    func loadPartnerPulse(appState: AppState) async {
        guard appState.linkState == .linked else {
            partnerPosition = nil
            partnerEntries = []
            return
        }
        guard let entries = await pulseSync.fetchPartnerEntries() else { return }
        partnerEntries = entries
        partnerPosition = entries.last?.resolvedPosition
    }

    private func loadMasthead(appState: AppState, context: ModelContext) {
        displayName = appState.displayName
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let stageLabel = (profile?.nmStage ?? .exploring).displayName
        subtitle = Self.subtitle(stageLabel: stageLabel, joinedAt: profile?.createdAt)
    }

    private func loadRecord(coupleId: UUID?, context: ModelContext) {
        guard let coupleId else {
            sessions = []
            categoryShares = []
            return
        }

        // Deck content is bundle JSON (not network); safe to load in the store.
        let summaries = (try? deckCatalog.loadSummaries()) ?? []
        let byId = Dictionary(summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var fetch = FetchDescriptor<CardSession>(
            predicate: #Predicate { $0.coupleId == coupleId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        fetch.fetchLimit = 50
        let raw = (try? context.fetch(fetch)) ?? []

        sessions = raw.map { s in
            let summary = byId[s.deckId]
            return RecordSession(
                id: s.id,
                deckName: summary?.title ?? "A deck",
                category: summary?.category ?? .wildcard,
                date: s.startedAt,
                cardCount: s.cardsDiscussed
            )
        }

        let counts = Dictionary(grouping: sessions, by: { $0.category }).mapValues(\.count)
        categoryShares = counts
            .map { CategoryShare(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func loadMeCard(context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            meCard = MeCard(
                flavor: .explorer,
                name: displayName,
                title: Flavor.explorer.titles.first ?? "",
                tags: []
            )
            return
        }
        let flavor = profile.flavor.flatMap(Flavor.init(rawValue:)) ?? .explorer
        let title = profile.chosenTitle ?? flavor.titles.first ?? ""
        let tags = Self.drawnTags(userId: profile.id, coupleId: profile.coupleId, context: context)
        meCard = MeCard(flavor: flavor, name: profile.displayName, title: title, tags: tags)
    }

    /// Derives the "Drawn to" tags from the user's positive Desire ratings. Shared (mutual)
    /// state is resolved asynchronously in loadServerAlignData after the server fetch arrives;
    /// this synchronous path produces un-glowed tags as an immediate placeholder.
    private static func drawnTags(userId: UUID, coupleId: UUID?, context: ModelContext) -> [DrawnTag] {
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let entryFetch = FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        let entries = (try? context.fetch(entryFetch)) ?? []
        let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }

        // Shared tags are resolved in loadServerAlignData after the server fetch.
        let sharedIds = Set<String>()
        _ = coupleId  // coupleId retained in signature for future local-cache fast path

        let tags = positive.map { entry in
            DrawnTag(name: nameById[entry.itemId] ?? entry.itemId, isShared: sharedIds.contains(entry.itemId))
        }
        // Shared first, then a small cap so the card stays calm.
        return Array(tags.sorted { $0.isShared && !$1.isShared }.prefix(5))
    }

    // MARK: - Me Card editing

    func setFlavor(_ flavor: Flavor, context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.flavor = flavor.rawValue
        // Drop a title that does not belong to the new flavor (falls back to default).
        if let current = profile.chosenTitle, !flavor.titles.contains(current) {
            profile.chosenTitle = nil
        }
        try? context.save()
        loadMeCard(context: context)
    }

    func setTitle(_ title: String, context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.chosenTitle = title
        try? context.save()
        loadMeCard(context: context)
    }

    // MARK: - The Us layer

    private func loadUs(appState: AppState, context: ModelContext) {
        var stats = UsStats(isLinked: appState.linkState == .linked, sessionCount: sessions.count)

        if let coupleId = appState.coupleId,
           let couple = try? context.fetch(
                FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
           ).first {
            stats.tenureStage = couple.relationshipTenure?.stageLabel
            stats.tenureTime  = couple.relationshipTenure?.timeLabel
            stats.weeksOnVayl = Self.weeks(since: couple.createdAt)
        }
        usStats = stats

        // Server matches are fetched async in loadServerAlignData — local mirror is not populated.
        alignItems = []
        lockedAlignCount = 0
    }

    /// Fetches server desire matches and updates the Us align list and meCard tags.
    /// Runs after loadUs so the synchronous scaffold is already in place.
    private func loadServerAlignData(appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId else { return }

        let matchRows = (try? await desireSync.fetchMatches(coupleId: coupleId)) ?? []

        // THE gate rule — CoupleContext.canRevealAll (OR'd entitlement), never the
        // local Couple.canRevealDesireMap mirror, which can lag a just-purchased buyer.
        let canReveal = couple?.canRevealAll ?? false

        // Build the Us align list using the server-authoritative gate rule.
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        var revealed: [AlignItem] = []
        var locked = 0
        for row in matchRows {
            if canReveal || row.isFreeReveal {
                revealed.append(AlignItem(
                    id: row.desireItemId,
                    name: nameById[row.desireItemId] ?? row.desireItemId,
                    isMutual: row.matchType == .mutual
                ))
            } else {
                locked += 1
            }
        }
        alignItems = revealed.sorted { $0.isMutual && !$1.isMutual }
        lockedAlignCount = locked

        // Update meCard tags: mutual shared items glow once server data arrives.
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            let sharedIds = Set(
                matchRows
                    .filter { (canReveal || $0.isFreeReveal) && $0.matchType == .mutual }
                    .map(\.desireItemId)
            )
            // Capture the UUID into a local let so the #Predicate macro can see a plain value.
            let profileId = profile.id
            let entryFetch = FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == profileId })
            let entries = (try? context.fetch(entryFetch)) ?? []
            let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }
            let tags = positive.map { entry in
                DrawnTag(name: nameById[entry.itemId] ?? entry.itemId, isShared: sharedIds.contains(entry.itemId))
            }
            meCard.tags = Array(tags.sorted { $0.isShared && !$1.isShared }.prefix(5))
        }
    }

    private static func weeks(since date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.weekOfYear], from: date, to: Date()).weekOfYear ?? 0)
    }

    // MARK: - Helpers

    /// "Exploring · 14 weeks on Vayl" once there is real tenure, otherwise the
    /// forming variant.
    private static func subtitle(stageLabel: String, joinedAt: Date?) -> String {
        guard let joinedAt else { return "\(stageLabel) · your map is just beginning" }
        let weeks = Calendar.current
            .dateComponents([.weekOfYear], from: joinedAt, to: Date())
            .weekOfYear ?? 0
        guard weeks >= 1 else { return "\(stageLabel) · your map is just beginning" }
        let unit = weeks == 1 ? "week" : "weeks"
        return "\(stageLabel) · \(weeks) \(unit) on Vayl"
    }
}
