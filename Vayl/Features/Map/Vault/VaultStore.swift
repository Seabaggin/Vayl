//
//  VaultStore.swift
//  Vayl
//
//  State owner for the Vault sheet (Map -> Us layer -> Vault). Segment 1 (foundation)
//  owns the segment selection + the Desire Map summary derived from local data.
//  Agreements, the Event Log, and the consent exchange extend this in later segments.
//  Spec: docs/superpowers/specs/2026-06-24-vault-design.md.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class VaultStore {

    enum Segment: String, CaseIterable {
        case desire, agreements, log
    }

    var segment: Segment = .desire
    var showPaywall = false

    // MARK: - Desire Map summary (Segment 1, local data)

    struct DesireSummary {
        var rated: Int = 0
        var yes: Int = 0       // excitedAboutIt
        var curious: Int = 0   // openToIt
        var kept: Int = 0      // notForMe (private)
    }

    private(set) var desire = DesireSummary()
    private(set) var align: [MapStore.AlignItem] = []
    private(set) var lockedAlignCount: Int = 0

    /// Couple-fact source of truth, attached once from the hosting view's `.task`
    /// (@State store construction can't reach @Environment).
    private var couple: CoupleContext?

    func configure(couple: CoupleContext) {
        guard self.couple == nil else { return }
        self.couple = couple
    }

    // MARK: - Dependencies

    private let desireSync: DesireSyncService
    private let agreementsService: AgreementsService
    private let consentService: ConsentService
    private let companionCardStore: CompanionCardStore

    /// Params nil-resolve inside the MainActor-isolated body (a `= .shared` default
    /// argument would evaluate nonisolated — same pattern as SettingsStore).
    init(
        desireSync: DesireSyncService? = nil,
        agreementsService: AgreementsService? = nil,
        consentService: ConsentService? = nil,
        companionCards: CompanionCardStore? = nil
    ) {
        self.desireSync = desireSync ?? .shared
        self.agreementsService = agreementsService ?? AgreementsService()
        self.consentService = consentService ?? ConsentService()
        self.companionCardStore = companionCards ?? CompanionCardStore()
    }

    /// Builds the Desire Map summary from the user's local ratings + server matches,
    /// gated on `CoupleContext.canRevealAll` (the OR'd entitlement: server tier OR
    /// local StoreKit ownership). Idempotent; safe to re-run after a paywall unlock.
    func loadDesire(appState: AppState, context: ModelContext) async {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            desire = DesireSummary()
            align = []
            lockedAlignCount = 0
            return
        }

        let userId = profile.id
        let entries = (try? context.fetch(
            FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        )) ?? []

        var summary = DesireSummary(rated: entries.count)
        for entry in entries {
            switch entry.rating {
            case .excitedAboutIt: summary.yes += 1
            case .openToIt:       summary.curious += 1
            case .notForMe:       summary.kept += 1
            default:              break
            }
        }
        desire = summary

        var revealed: [MapStore.AlignItem] = []
        var locked = 0
        if let coupleId = appState.coupleId {
            // THE gate rule — CoupleContext.canRevealAll (OR'd entitlement), never the
            // local Couple mirror (which can lag a just-purchased buyer and under-reveal
            // the Vault while the reveal shows unlocked).
            let canReveal = couple?.canRevealAll ?? false
            let rows = (try? await desireSync.fetchMatches(coupleId: coupleId)) ?? []
            let items = (try? ContentLoader.loadDesireItems()) ?? []
            let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
            for row in rows {
                if canReveal || row.isFreeReveal {
                    revealed.append(MapStore.AlignItem(
                        id: row.desireItemId,
                        name: nameById[row.desireItemId] ?? row.desireItemId,
                        isMutual: row.matchType == .mutual
                    ))
                } else {
                    locked += 1
                }
            }
        }
        align = revealed.sorted { $0.isMutual && !$1.isMutual }
        lockedAlignCount = locked
    }

    // MARK: - Agreements (Phase A: dual-lock, mutual approval to change)

    struct AgreementVM: Identifiable { let id: UUID; let text: String }

    struct ProposalVM: Identifiable {
        let id: UUID
        let action: String          // create | edit | retire
        let proposedText: String?
        let targetId: UUID?
        let mineToDecide: Bool      // true when my partner proposed it (I'm the approver)
    }

    private(set) var safeWord: String = "red"
    private(set) var agreements: [AgreementVM] = []
    private(set) var proposals: [ProposalVM] = []

    /// Loads the shared safe word + active agreements + pending proposals.
    func loadAgreements(appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        if let couple = try? context.fetch(
            FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        ).first {
            safeWord = couple.sharedSafeWord
        }
        let rows = (try? await agreementsService.fetchAgreements(coupleId: coupleId)) ?? []
        let pending = (try? await agreementsService.fetchPendingProposals(coupleId: coupleId)) ?? []
        agreements = rows.filter(\.isActive).map { AgreementVM(id: $0.id, text: $0.text) }
        proposals = pending.map {
            ProposalVM(id: $0.id, action: $0.action, proposedText: $0.proposedText,
                       targetId: $0.targetAgreementId, mineToDecide: $0.proposedBy != me.id)
        }
    }

    /// Proposes a create / edit / retire. Takes effect only once the partner approves.
    func propose(action: String, text: String?, targetId: UUID?,
                 appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        try? await agreementsService.propose(coupleId: coupleId, proposerId: me.id,
            action: action, targetAgreementId: targetId, text: text)
        await loadAgreements(appState: appState, context: context)
    }

    /// Approves or declines a pending proposal (the partner's decision).
    func decideProposal(_ proposalId: UUID, approve: Bool,
                        appState: AppState, context: ModelContext) async {
        try? await agreementsService.decide(proposalId: proposalId, approve: approve)
        await loadAgreements(appState: appState, context: context)
    }

    // MARK: - Event Log (Phase B: private or shared, local-first + synced)

    private(set) var logEntries: [EventLogEntry] = []
    private let eventLogService = EventLogService()

    /// Loads local entries (the source of truth), newest first.
    func loadLog(context: ModelContext) {
        logEntries = (try? context.fetch(
            FetchDescriptor<EventLogEntry>(sortBy: [SortDescriptor(\.occurredOn, order: .reverse)])
        )) ?? []
    }

    /// Creates or updates an entry locally, then pushes it up. `id == nil` creates.
    func saveEntry(id: UUID?, date: Date, title: String, note: String?,
                   mood: EventMood?, tags: [EventTag], who: String?,
                   visibility: EventVisibility, appState: AppState, context: ModelContext) {
        guard let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        let coupleId = visibility == .shared ? appState.coupleId : nil

        let entry: EventLogEntry
        if let id, let existing = logEntries.first(where: { $0.id == id }) {
            entry = existing
            entry.occurredOn = date
            entry.title = title
            entry.note = note
            entry.mood = mood?.rawValue
            entry.tags = tags.map(\.rawValue)
            entry.who = who
            entry.visibility = visibility.rawValue
            entry.coupleId = coupleId
            entry.updatedAt = Date()
        } else {
            entry = EventLogEntry(authorId: me.id, coupleId: coupleId, occurredOn: date,
                                  title: title, note: note, mood: mood?.rawValue,
                                  tags: tags.map(\.rawValue), who: who,
                                  visibility: visibility.rawValue)
            context.insert(entry)
        }
        try? context.save()
        loadLog(context: context)

        let payload = EventLogUpsert(
            id: entry.id.uuidString, author_id: entry.authorId.uuidString,
            couple_id: entry.coupleId?.uuidString,
            occurred_on: EventLogService.dayFormatter.string(from: entry.occurredOn),
            title: entry.title, note: entry.note, mood: entry.mood,
            tags: entry.tags, who: entry.who, visibility: entry.visibility)
        Task { try? await eventLogService.push(payload) }
    }

    func deleteEntry(_ entry: EventLogEntry, context: ModelContext) {
        let id = entry.id
        context.delete(entry)
        try? context.save()
        loadLog(context: context)
        Task { try? await eventLogService.delete(id: id) }
    }

    /// Pulls remote entries (own + shared) and upserts them into local SwiftData, so a
    /// new device restores your entries and the partner's shared entries appear.
    func syncLogDown(context: ModelContext) async {
        guard let rows = try? await eventLogService.pull() else { return }
        for row in rows {
            let rid = row.id
            let existing = (try? context.fetch(
                FetchDescriptor<EventLogEntry>(predicate: #Predicate { $0.id == rid })
            ))?.first
            let date = EventLogService.dayFormatter.date(from: row.occurredOn) ?? Date()
            if let e = existing {
                e.title = row.title; e.note = row.note; e.mood = row.mood
                e.tags = row.tags; e.who = row.who; e.visibility = row.visibility
                e.coupleId = row.coupleId; e.occurredOn = date
            } else {
                let e = EventLogEntry(authorId: row.authorId, coupleId: row.coupleId,
                                      occurredOn: date, title: row.title, note: row.note,
                                      mood: row.mood, tags: row.tags, who: row.who,
                                      visibility: row.visibility)
                e.id = rid
                context.insert(e)
            }
        }
        try? context.save()
        loadLog(context: context)
    }

    // MARK: - Consent exchange (Phase C: open a conversation; a decline never discloses)

    struct ConsentVM: Identifiable {
        let id: UUID
        let itemId: String
        let itemName: String
        let status: String          // pending | opened
        let iAmAsker: Bool
        let discussionCardId: String?
    }

    struct ConsentTopic: Identifiable {
        let id: String              // itemId
        let name: String
    }

    private(set) var myAsks: [ConsentVM] = []      // I asked, still pending (stays pending even if declined)
    private(set) var incoming: [ConsentVM] = []    // partner asked me, pending, not yet declined by me
    private(set) var openedConsent: [ConsentVM] = []
    private(set) var askableTopics: [ConsentTopic] = []

    func loadConsent(appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            myAsks = []; incoming = []; openedConsent = []; askableTopics = []
            return
        }
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let requests = (try? await consentService.fetchRequests(coupleId: coupleId)) ?? []
        let declines = (try? await consentService.fetchMyDeclines(coupleId: coupleId)) ?? []
        let declinedIds = Set(declines.map(\.itemId))
        let requestedIds = Set(requests.map(\.itemId))

        let all = requests.map { r in
            ConsentVM(id: r.id, itemId: r.itemId, itemName: nameById[r.itemId] ?? r.itemId,
                      status: r.status, iAmAsker: r.askerId == me.id, discussionCardId: r.discussionCardId)
        }
        openedConsent = all.filter { $0.status == "opened" }
        myAsks = all.filter { $0.status == "pending" && $0.iAmAsker }
        incoming = all.filter { $0.status == "pending" && !$0.iAmAsker && !declinedIds.contains($0.itemId) }

        // Askable: my positive local items with no request yet (a short, calm list).
        let userId = me.id
        let entries = (try? context.fetch(
            FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        )) ?? []
        let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }
        askableTopics = Array(
            positive
                .filter { !requestedIds.contains($0.itemId) }
                .map { ConsentTopic(id: $0.itemId, name: nameById[$0.itemId] ?? $0.itemId) }
                .sorted { $0.name < $1.name }
                .prefix(5)
        )
    }

    func askToOpen(itemId: String, appState: AppState, context: ModelContext) async {
        try? await consentService.ask(itemId: itemId)
        await loadConsent(appState: appState, context: context)
    }

    func respondToOpen(itemId: String, open: Bool, appState: AppState, context: ModelContext) async {
        try? await consentService.respond(itemId: itemId, open: open)
        await loadConsent(appState: appState, context: context)
    }

    // MARK: - Discussion card

    private(set) var selectedDiscussionCard: CompanionCard? = nil

    /// Opens the discussion card for a desire item at the given tier.
    func openDiscussion(itemId: String, itemName: String, tier: CompanionCardTier) {
        let card = companionCardStore.card(forItemId: itemId, tier: tier)
            ?? CompanionCard(
                id: "discussion_fallback_\(itemId)",
                desireItemId: itemId,
                title: itemName,
                prompt: "What would you want to explore together here?",
                suggestedDeckId: nil
            )
        selectedDiscussionCard = card
    }

    /// Clears the discussion card state.
    func closeDiscussion() {
        selectedDiscussionCard = nil
    }
}
