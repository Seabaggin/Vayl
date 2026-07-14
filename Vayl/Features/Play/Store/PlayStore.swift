//
//  PlayStore.swift
//  Vayl — Play
//

import SwiftUI
import SwiftData

/// Where the featured deck stands for this couple, driving the continuity-aware hero
/// header. Resolved from real `DeckProgress` (never aspirational).
enum DeckContinuity: Equatable {
    case fresh                              // never opened, or not advanced past the first card
    case inProgress(index: Int, total: Int)
    case completed
}

/// The wall/case material state, richness increasing locked → sealed → opened.
/// Store-derived from entitlement + per-person seal state; the ONLY input the
/// case/cell views take for which treatment to render. (Spec 2026-07-11.)
enum DeckDisplayState: Equatable {
    case locked     // premium, not owned → dimmed dormant metal + engraved LOCKED → paywall
    case sealed     // owned, never opened by this person → static metallic + glint → first-open ceremony
    case opened     // owned, seal broken → hex lattice + slow sweep → detail
}

// MARK: - Realtime seam (test injection)
//
// Minimal additive seam: PlayStore only ever calls these three methods on its
// injected RealtimeSessionService. Same pattern as SessionEntryRealtime /
// AirlockTransport — a small protocol so tests can fake the network.
protocol PlaySessionOpening: AnyObject {
    func openSession(coupleId: UUID, initiatorId: UUID, draft: CuratedSessionDraft) async throws -> CuratedSessionDTO
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?
    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws
}

extension RealtimeSessionService: PlaySessionOpening {}

@Observable
@MainActor
final class PlayStore {

    // Catalog
    private(set) var summaries: [DeckSummary] = []
    private(set) var loadError: String?
    private(set) var featuredCards: [Card] = []   // the featured deck's cards, for the hero carousel
    private(set) var featuredContinuity: DeckContinuity = .fresh   // continuity read for the hero header

    // Dial
    var activeMode: PlayMode = .cards
    var enabledModes: [PlayMode] { PlayFeatureFlags.enabledModes }

    // Hero / wall / detail / ceremony / builder / lobby / session
    var featuredID: String?
    /// Non-nil → the deck carousel (Explore surface) is open, scoped to a section
    /// (owned OR premium set). `carouselCenterID` is the centered deck. Replaces
    /// the single `detailID` overlay. (Spec §8.)
    var carouselSection: [DeckSummary]?
    var carouselCenterID: String?
    /// The centered deck's preview cards (first few real cards). Loaded by the
    /// store on open/center — the view never touches DeckCatalogService.
    private(set) var detailPreviewCards: [Card] = []
    var ceremonyDeckID: String?
    /// Ceremony finished → the builder shapes tonight's plan for this deck.
    var builderDeck: Deck?
    /// Non-nil → present the session .vaylCover (lobby-first for remote sessions).
    var launch: SessionLaunch?
    var paywallDeck: DeckSummary?       // non-nil → present the Core paywall for this deck
    private(set) var openError: String?
    /// The (deck, plan) of a failed session open, kept so "Try again" can
    /// re-run it without the user rebuilding blind.
    private var failedOpen: (deck: Deck, plan: SessionPlan)?
    /// An existing active/paused row that blocks a NEW session from opening
    /// (the DB's one-open-per-couple index would reject the insert). The
    /// (deck, plan) the user just built is retained so "Start fresh" can
    /// re-run it once the conflict row is abandoned.
    private(set) var conflictSession: CuratedSessionDTO?
    private var conflictPending: (deck: Deck, plan: SessionPlan)?
    /// The conflict row's deck title, resolved for the confirmation dialog
    /// (catalog lookup, falls back to the raw deckId — same pattern as
    /// SessionEntryStore's pendingSession.deckTitle).
    var conflictDeckTitle: String? {
        guard let conflictSession else { return nil }
        return (try? catalog.loadSummaries())?.first { $0.id == conflictSession.deckId }?.title
            ?? conflictSession.deckId
    }
    /// One open at a time — a slow network must not allow a second ceremony
    /// or a duplicate lobby row.
    private(set) var isOpeningSession = false
    /// The local user's starred deck ids — the observable mirror of
    /// DeckUserState.starredByMe, so the star re-renders on toggle.
    private(set) var starredIDs: Set<String> = []

    /// Deck ids this person has opened (seal broken) — observable mirror of
    /// DeckProgress.isUnwrapped, so a case flips sealed → opened the instant the
    /// ceremony (or skip) fires. Local per-device = per-person for V1. (Spec §3.)
    private(set) var openedIDs: Set<String> = []

    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState
    private let entitlements: EntitlementStore          // M3: the single Core gate
    private let realtime: PlaySessionOpening             // opens the lobby row
    private let pairing: PairingService                 // couple composition read (spec §9)
    private let coupleContext: CoupleContext            // partner identity (single source of truth)

    init(modelContainer: ModelContainer,
         appState: AppState,
         entitlements: EntitlementStore,
         coupleContext: CoupleContext,
         catalog: DeckCatalogService? = nil,
         realtime: PlaySessionOpening? = nil,
         pairing: PairingService? = nil) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.entitlements = entitlements
        self.coupleContext = coupleContext
        // Construct the default services on the main actor (this init's isolation),
        // not in a nonisolated default-argument expression.
        self.catalog = catalog ?? DeckCatalogService()
        self.realtime = realtime ?? RealtimeSessionService()
        self.pairing = pairing ?? PairingService()
        load()
    }

    /// Live lock state: catalog flag AND not Core. One purchase flips
    /// entitlements.isCore and every gate below re-derives. Views call this,
    /// never summary.isLocked directly.
    func isLocked(_ summary: DeckSummary) -> Bool {
        summary.isLocked && !entitlements.isCore
    }

    /// StoreKit display price for the locked-detail CTA sub-line (nil until the
    /// product loads — the view falls back to the reference price).
    var corePriceText: String? { entitlements.corePriceText }

    // MARK: - Deck display state (locked / sealed / opened) — spec §3

    /// The wall/case material state for a deck: locked (not owned), sealed (owned
    /// but never opened by this person), or opened (seal broken). The single input
    /// the case + cell views take. Views call this, never the raw flags.
    func deckState(_ summary: DeckSummary) -> DeckDisplayState {
        if isLocked(summary) { return .locked }
        return hasBeenOpened(summary.id) ? .opened : .sealed
    }

    /// Whether THIS person has opened (broken the seal on) this deck. Observable
    /// mirror of DeckProgress.isUnwrapped — a plain fetch here would never
    /// invalidate the calling view.
    func hasBeenOpened(_ deckId: String) -> Bool { openedIDs.contains(deckId) }

    /// Break the seal: mark the deck opened for this person (ceremony completed OR
    /// skipped — both persist, so a skip never silently becomes "defer" and
    /// re-nags; spec §3). Upserts DeckProgress.isUnwrapped and mirrors into the
    /// observable set. No-op when there is no couple row to hang it on (unpaired
    /// V1 keeps the ceremony each launch — acceptable; seal persistence is part of
    /// the deferred backend pass).
    func markOpened(_ deckId: String) {
        openedIDs.insert(deckId)   // optimistic mirror so the case flips immediately
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckProgress>(
            predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
        )
        if let row = try? context.fetch(descriptor).first {
            row.isUnwrapped = true
            if row.firstOpenedAt == nil { row.firstOpenedAt = Date() }
        } else {
            let row = DeckProgress(coupleId: coupleId, deckId: deckId)
            row.isUnwrapped = true
            row.firstOpenedAt = Date()
            context.insert(row)
        }
        try? context.save()
    }

    private func refreshSeal() {
        // A deck reads OPENED when its seal was broken (isUnwrapped) OR it carries
        // any real activity — so pre-existing progress (before this feature) and a
        // resumed/completed deck never regress to sealed and re-trigger a ceremony.
        var opened = Set(fetchProgress().filter { p in
            p.isUnwrapped || p.firstOpenedAt != nil || p.currentCardIndex > 0 || p.completedAt != nil
        }.map(\.deckId))
        // The OB-forged opener is pre-opened (OB already ran its ceremony).
        if let opener = localProfile()?.openerDeckType.welcomeDeckId { opened.insert(opener) }
        openedIDs = opened
    }

    // MARK: - Sections (spec §1) — owned vs premium

    /// "Your decks" — owned (sealed OR opened). Preserves catalog order.
    var unlockedSummaries: [DeckSummary] { summaries.filter { !isLocked($0) } }
    /// "Premium" — locked (behind Core). Empty once Core is owned.
    var lockedSummaries: [DeckSummary] { summaries.filter { isLocked($0) } }

    // MARK: - Per-deck progress (shelf + panel) — spec §5

    /// Fraction through a deck (0…1) for the shelf/panel progress bar, or nil when
    /// fresh (never advanced) or completed. Generalizes the featured-only continuity.
    func progressFraction(_ summary: DeckSummary) -> Double? {
        guard summary.cardCount > 0,
              let row = fetchProgress().first(where: { $0.deckId == summary.id }),
              row.completedAt == nil,
              row.currentCardIndex > 0 else { return nil }
        return min(1, Double(row.currentCardIndex) / Double(summary.cardCount))
    }

    /// The card position through a deck for the "N/total" panel readout, 0 when fresh/completed.
    func progressIndex(_ summary: DeckSummary) -> Int {
        guard let row = fetchProgress().first(where: { $0.deckId == summary.id }),
              row.completedAt == nil else { return 0 }
        return row.currentCardIndex
    }

    /// Whether this deck has ever been completed by the couple.
    func isCompleted(_ summary: DeckSummary) -> Bool {
        fetchProgress().first { $0.deckId == summary.id }?.completedAt != nil
    }

    /// The carousel's one-line "what you'll leave with" outcome copy, derived from
    /// existing catalog content (no new field): first goal, else the description.
    func outcomeLine(_ summary: DeckSummary) -> String {
        if let goal = summary.goals.first(where: { !$0.isEmpty }) { return goal }
        return summary.description
    }

    func load() {
        do {
            var loaded = try catalog.loadSummaries()
            // Opener decks are personal: the forge revealed ONE of the four
            // (UserProfile.openerDeckType). The other three never appear on the
            // wall — a user has their forged deck, not a menu of forgeries.
            let mine = localProfile()?.openerDeckType.welcomeDeckId
            loaded.removeAll { OpenerDeckType.allWelcomeDeckIds.contains($0.id) && $0.id != mine }
            summaries = loaded
            loadError = nil
        } catch {
            summaries = []
            loadError = "Couldn't load decks."
        }
        resolveFeatured()
        loadFeatured()
        refreshComposition()
        refreshStars()
        refreshSeal()
    }

    // MARK: - Connection composition (seam ruling 6)

    /// The couple's composition for card filtering. Hydrated from the local
    /// Couple mirror instantly (rows may not exist — nothing creates them
    /// locally), then the remote couples row. Defaults .flexible when unknown;
    /// never blocks the builder on a fetch.
    private(set) var composition: GenderDynamic = .flexible

    private func refreshComposition() {
        guard let coupleId = appState.coupleId else {
            composition = .flexible
            return
        }
        // Instant local mirror, if a Couple row happens to exist.
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        if let couple = try? context.fetch(descriptor).first {
            composition = couple.connectionComposition
        }
        // Remote truth, best-effort — lands well before the builder opens.
        Task { @MainActor in
            if let remote = try? await pairing.fetchComposition(coupleId: coupleId) {
                composition = remote
            }
        }
    }

    /// Resume point for the builder: the featured/selected deck's
    /// DeckProgress.currentCardIndex, 0 when fresh or completed.
    private(set) var builderStartIndex: Int = 0

    private func resolveBuilderStartIndex(deckId: String) {
        let row = fetchProgress().first { $0.deckId == deckId }
        builderStartIndex = (row?.completedAt == nil) ? (row?.currentCardIndex ?? 0) : 0
    }

    /// Pick the featured deck (most-recently-played in-progress, else the
    /// user's forged opener deck until it's completed, else first available)
    /// and resolve its continuity, both from real `DeckProgress`.
    /// HomeStore's engaged-deck read follows the same rule — keep them in step.
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !isLocked($0) }.map(\.id))   // playable = free OR Core-unlocked
        let engaged = FeaturedDeckRule.engagedDeckId(
            progress: progress,
            availableIDs: availableIDs,
            openerID: localProfile()?.openerDeckType.welcomeDeckId
        )
        // No locked fallback: with nothing playable the hero shows nothing —
        // a locked deck must never sit one tap from a session start.
        featuredID = engaged ?? summaries.first { !isLocked($0) }?.id
        featuredContinuity = continuity(forDeck: featuredID, in: progress)
    }

    /// All `DeckProgress` rows for the active couple (empty when solo / no couple yet).
    private func fetchProgress() -> [DeckProgress] {
        guard let coupleId = appState.coupleId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckProgress>(
            predicate: #Predicate { $0.coupleId == coupleId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Resolve where a deck stands from its `DeckProgress` row (fresh when none exists).
    private func continuity(forDeck id: String?, in progress: [DeckProgress]) -> DeckContinuity {
        guard let id,
              let total = summary(id)?.cardCount,
              let row = progress.first(where: { $0.deckId == id }) else { return .fresh }
        if row.completedAt != nil { return .completed }
        if row.currentCardIndex > 0 { return .inProgress(index: row.currentCardIndex, total: total) }
        return .fresh
    }

    /// Load the featured deck's full cards so the hero carousel shows real cards.
    private func loadFeatured() {
        guard let id = featuredID, let deck = try? catalog.loadDeck(id: id) else {
            featuredCards = []
            return
        }
        featuredCards = deck.orderedCards
    }

    // Derived
    func summary(_ id: String?) -> DeckSummary? { summaries.first { $0.id == id } }
    var featured: DeckSummary? { summary(featuredID) }
    func style(for s: DeckSummary) -> DeckStyle { DeckStyle.make(for: s) }

    /// True when there is nothing to show — a load failure (`loadError`) or an
    /// empty catalog. Drives the wall's empty/error state instead of a blank grid.
    var isEmpty: Bool { summaries.isEmpty }

    /// Re-attempt the catalog load (Retry from the empty/error state).
    func retry() { load() }

    /// Decks grouped into category clusters for the wall, ordered by spectrum position.
    var clusters: [(category: DeckCategory, decks: [DeckSummary])] {
        Dictionary(grouping: summaries, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.category.spectrumPosition < $1.category.spectrumPosition }
    }

    // Intent
    func setMode(_ m: PlayMode) { guard enabledModes.contains(m) else { return }; activeMode = m }

    // MARK: - Tap routing (spec §3)

    /// A wall-case tap. EVERY tap lands in detail; a sealed deck passes through the
    /// first-open ceremony on the way; a locked deck routes to the paywall.
    func tapDeck(_ id: String) {
        guard let summary = summary(id) else { return }
        switch deckState(summary) {
        case .locked: requestUnlock(summary)
        case .sealed: beginFirstOpen(id)
        case .opened: openCarousel(id)
        }
    }

    // MARK: - Carousel (Explore surface)

    func openCarousel(_ id: String) {
        guard let summary = summary(id) else { return }
        // Ring scoped to the section the tapped deck belongs to (no cross-section wrap).
        carouselSection = isLocked(summary) ? lockedSummaries : unlockedSummaries
        carouselCenterID = id
        loadPreview(id)
    }

    /// Called on carousel settle: recenter + reload the newly centered deck's cards.
    func carouselDidCenter(_ id: String) {
        carouselCenterID = id
        loadPreview(id)
    }

    func closeCarousel() {
        carouselSection = nil
        carouselCenterID = nil
        detailPreviewCards = []
    }

    private func loadPreview(_ id: String) {
        detailPreviewCards = Array(((try? catalog.loadDeck(id: id))?.orderedCards ?? []).prefix(5))
    }

    // MARK: - First-open ceremony (spec §3) — the shatter, once per person, → detail

    /// Sealed deck tapped: play the first-open ceremony (`DeckBeginCeremony`). On
    /// finish OR skip it breaks the seal and lands in the deck detail — NOT a
    /// session (Start from detail begins play). The shatter is first-open now, not
    /// session-start. Locked decks never reach here (tapDeck routes to the paywall).
    func beginFirstOpen(_ id: String) {
        guard !isOpeningSession, summary(id) != nil else { return }
        ceremonyDeckID = id
    }

    /// Ceremony finished (or skipped): break the seal and open the detail carousel.
    /// The seal breaks regardless (so a joiner cover that took over mid-ceremony
    /// still counts as opened); detail only pops when no live cover outranks it.
    func ceremonyFinished() {
        guard let id = ceremonyDeckID else { return }
        ceremonyDeckID = nil
        markOpened(id)
        guard launch == nil else { return }   // a live session cover outranks detail
        openCarousel(id)
    }

    /// Skip the ceremony — same destination, minus the animation. MUST break the
    /// seal (spec §3) or "skip" silently becomes "defer" and re-nags.
    func skipFirstOpen() { ceremonyFinished() }

    func cancelBuilder() { builderDeck = nil }

    /// SEAM B (assembler ruling 1): the builder hands back the Codable
    /// SessionPlan struct; the row snapshot is `plan.draft` at the openSession
    /// call site. Open the row, then present the lobby cover.
    func builderDidFinish(_ plan: SessionPlan) {
        guard let deck = builderDeck, !isOpeningSession else { return }
        builderDeck = nil
        openSession(deck: deck, plan: plan)
    }

    /// "Try again" on the failed-open banner — re-runs the exact plan the user
    /// built, no rebuilding blind.
    func retryOpen() {
        guard let failed = failedOpen, !isOpeningSession else { return }
        openSession(deck: failed.deck, plan: failed.plan)
    }

    func dismissOpenError() {
        openError = nil
        failedOpen = nil
    }

    /// Thin caller: delegates the actual open/resume/conflict logic to
    /// `SessionOpener` (Task 3b extraction) and switches the result onto the
    /// same published state the old inline body used to write directly.
    private func openSession(deck: Deck, plan: SessionPlan) {
        openError = nil
        isOpeningSession = true
        Task { @MainActor in
            defer { isOpeningSession = false }
            let opener = SessionOpener(realtime: realtime)
            let result = await opener.open(
                deck: deck, plan: plan,
                coupleId: appState.coupleId,
                context: ModelContext(modelContainer)
            )
            switch result {
            case .launch(let launch):
                failedOpen = nil
                self.launch = launch
            case .debugLocal(let launch):
                self.launch = launch
            case .conflict(let dto):
                conflictSession = dto
                conflictPending = (deck, plan)
            case .failed(let message, let retryable):
                openError = message
                // Only a retryable (network) failure arms the retry with the
                // same plan; the deterministic hand-build failure does not.
                if retryable {
                    failedOpen = (deck, plan)
                }
            case .unavailable:
                // Release-build unpaired no-op: no error, no launch.
                return
            }
        }
    }

    // MARK: - Open-session conflict (spec §1.1: never dead-end on an existing row)

    /// "Resume" on the conflict dialog. Mirrors SessionEntryStore.resume():
    /// revalidate against the server first (the row may have ended between
    /// the conflict surfacing and this tap), rebuild the hand, then hand off
    /// to the existing launch → cover wiring (CoupleSessionStore.resumeIfNeeded
    /// picks the airlock-skip logic up from there).
    func resumeConflict() {
        guard let conflict = conflictSession, let coupleId = appState.coupleId else { return }
        Task { @MainActor in
            guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
                  dto.id == conflict.id,
                  dto.status == CuratedSessionStatus.active.rawValue
                    || dto.status == CuratedSessionStatus.paused.rawValue,
                  let deck = try? catalog.loadDeck(id: dto.deckId),
                  let myId = localProfileId()
            else {
                // The row resolved itself (partner ended it) — clear the
                // conflict and let the pending open the user actually asked
                // for proceed, rather than stranding them on a dead dialog.
                conflictSession = nil
                if let pending = conflictPending {
                    conflictPending = nil
                    openSession(deck: pending.deck, plan: pending.plan)
                }
                return
            }
            guard let hand = SessionLaunch.buildHand(cardIds: dto.cardIds, deck: deck) else {
                openError = SessionEntryStore.joinErrorMessage
                conflictSession = nil
                conflictPending = nil
                return
            }
            conflictSession = nil
            conflictPending = nil
            launch = SessionLaunch(
                hand: hand,
                entry: dto.initiatorId == myId ? .initiator : .joiner,
                role: role(for: myId), session: dto
            )
        }
    }

    /// "Start fresh" on the conflict dialog: abandon the blocking row, then
    /// re-run the retained plan. If the insert still fails (a race), the
    /// existing openError/retryOpen banner remains the fallback.
    func startFreshFromConflict() {
        guard let conflict = conflictSession, let pending = conflictPending else { return }
        conflictSession = nil
        conflictPending = nil
        Task { @MainActor in
            try? await realtime.setStatus(sessionId: conflict.id, status: .abandoned)
            openSession(deck: pending.deck, plan: pending.plan)
        }
    }

    /// "Cancel" on the conflict dialog: drop the conflict and the retained
    /// plan, no error shown — the user simply didn't want either option.
    func cancelConflict() {
        conflictSession = nil
        conflictPending = nil
    }

    func endSession() { launch = nil }

    /// SessionRole identity rule (spec 4.2, hard): derives from the local Couple
    /// row's partnerAId vs my LOCAL profile id. Never the supabase auth id.
    private func role(for profileId: UUID) -> SessionRole {
        SessionIdentity.role(context: ModelContext(modelContainer),
                              coupleId: appState.coupleId, profileId: profileId)
    }

    /// The local SwiftData profile id (auth-id vs profile-id convention: this is
    /// the PROFILE id, which is what couples rows reference).
    private func localProfileId() -> UUID? {
        SessionIdentity.localProfileId(context: ModelContext(modelContainer), coupleId: appState.coupleId)
    }

    /// The local SwiftData profile row (single-profile device convention).
    private func localProfile() -> UserProfile? {
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first
    }

    /// Locked deck → open the Core paywall (closes the carousel first).
    func requestUnlock(_ deck: DeckSummary) { closeCarousel(); paywallDeck = deck }
    func dismissPaywall() { paywallDeck = nil }

    // MARK: - Star state

    /// All `DeckUserState` rows for the active couple (empty when solo / no couple yet).
    private func fetchUserStates() -> [DeckUserState] {
        guard let coupleId = appState.coupleId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckUserState>(
            predicate: #Predicate { $0.coupleId == coupleId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Whether the local user has starred this deck (observable cache — a
    /// plain SwiftData fetch here would never invalidate the calling view).
    func isStarredByMe(_ deck: DeckSummary) -> Bool {
        starredIDs.contains(deck.id)
    }

    /// Whether starring is possible at all (needs a couple to hang the row on).
    var canStar: Bool { appState.coupleId != nil }

    private func refreshStars() {
        starredIDs = Set(fetchUserStates().filter(\.starredByMe).map(\.deckId))
    }

    /// Whether the partner has starred this deck. Real-time partner sync is a
    /// follow-up task — always false until that lands.
    func isStarredByPartner(_ deck: DeckSummary) -> Bool { false }

    /// The partner's display name for the "Starred by X" label.
    var partnerName: String? { coupleContext.partnerName }

    /// Toggle the local user's star on a deck. Writes to SwiftData immediately
    /// and mirrors into the observable cache so the view re-renders.
    func toggleStar(_ deck: DeckSummary) {
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        let deckId = deck.id
        let descriptor = FetchDescriptor<DeckUserState>(
            predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
        )
        let nowStarred: Bool
        if let existing = try? context.fetch(descriptor).first {
            existing.starredByMe.toggle()
            nowStarred = existing.starredByMe
        } else {
            let row = DeckUserState(deckId: deck.id, coupleId: coupleId)
            row.starredByMe = true
            context.insert(row)
            nowStarred = true
        }
        try? context.save()
        if nowStarred { starredIDs.insert(deck.id) } else { starredIDs.remove(deck.id) }
    }

    // MARK: - Last played

    /// The most recent completion date for this deck, or nil if never played.
    func lastPlayed(_ deck: DeckSummary) -> Date? {
        fetchProgress().first { $0.deckId == deck.id }?.completedAt
    }

    // MARK: - Start deck

    /// "Start" / "Play again" from a deck's detail (or the hero shortcut): enter
    /// the session-entry flow directly — NO first-open shatter (that fired at first
    /// open; spec §3). Sets the deck as featured, closes the carousel, and hands off
    /// to the SessionBuilder → Session Settings/Lobby → cover. Locked decks route to
    /// the paywall (defensive — a locked deck should never reach a Start button).
    func startDeck(_ deck: DeckSummary) {
        if isLocked(deck) { requestUnlock(deck); return }
        // Reaching Start means the deck is open; a hero shortcut can bypass the
        // wall tap, so mark the seal defensively.
        markOpened(deck.id)
        featuredID = deck.id
        featuredContinuity = continuity(forDeck: deck.id, in: fetchProgress())
        loadFeatured()
        closeCarousel()
        guard let full = try? catalog.loadDeck(id: deck.id) else { return }
        enterSessionSetup(full)
    }

    /// Hero shortcut → session setup for the featured (active/opener) deck. The
    /// featured deck is always owned+opened, so no ceremony.
    func startFeatured() {
        guard let f = featured else { return }
        startDeck(f)
    }

    /// Carousel "Settle in": open a session straight from the featured deck with
    /// the cards the user picked in the hero carousel — skips the (being-cut)
    /// builder. Lands on the existing `openSession` → cover path; the Session
    /// Settings step is inserted in a later segment. Locked deck → paywall,
    /// mirroring `startDeck`.
    func settleInFeatured(cardIds: [String]) {
        guard !cardIds.isEmpty, let f = featured else { return }
        if isLocked(f) { requestUnlock(f); return }
        guard let full = try? catalog.loadDeck(id: f.id) else { return }
        markOpened(f.id)
        closeCarousel()
        let plan = SessionPlan(
            deckId: f.id,
            cardIds: cardIds,
            perCardTimerSeconds: nil,
            globalTimerSeconds: nil,
            deckVariant: nil
        )
        openSession(deck: full, plan: plan)
    }

    /// Enter the session-entry flow for a deck (SessionBuilder → Settings/Lobby →
    /// cover), without the shatter. One guard: never stack a builder under a live
    /// cover or an already-open builder.
    private func enterSessionSetup(_ deck: Deck) {
        guard launch == nil, builderDeck == nil else { return }
        resolveBuilderStartIndex(deckId: deck.id)
        builderDeck = deck                    // SessionBuilderView presents (Seam B)
    }
}

#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog).
    @MainActor static var preview: PlayStore {
        let appState = AppState()
        let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: appState)
        return PlayStore(
            modelContainer: .previewContainer,
            appState: appState,
            entitlements: entitlements,
            coupleContext: CoupleContext(
                appState: appState,
                entitlements: entitlements,
                modelContainer: .previewContainer
            )
        )
    }
}
#endif
