//
//  HomeStore.swift
//  Vayl
//
//  Brain of the Home flow.
//  Owns all routing state, deck loading, and map completion tracking.
//  The view renders. The store decides.
//
//  Dependencies injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "HomeStore"
)

@Observable
@MainActor
final class HomeStore {

    // MARK: - Routing State

    /// The single computed state that drives all routing in HomeRouterView.
    /// View reads this. View never writes this.
    var homeState: HomeState { resolveHomeState() }

    // MARK: - Map Completion

    var myMapComplete: Bool = false
    var partnerMapComplete: Bool = false
    var revealDone: Bool = false
    var postReflectionDone: Bool = false
    var partnerName: String? = nil
    var reflectionStep: Int = 1

    // MARK: - Deck Loading

    var deck: Deck? = nil
    var deckLoadError: String? = nil
    var isLoadingDeck: Bool = false

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState

    // MARK: - Init

    init(modelContainer: ModelContainer, appState: AppState) {
        self.modelContainer = modelContainer
        self.appState = appState

        #if DEBUG
        // Development quick-jump — skip to dashboard state.
        // Production always starts at false.
        self.myMapComplete = true
        self.partnerMapComplete = true
        self.revealDone = true
        self.postReflectionDone = true
        self.partnerName = "Alex"
        #endif
    }

    // MARK: - Derived

    var isPaired: Bool {
        appState.appMode == .together
    }

    var isSolo: Bool {
        appState.appMode == .solo
    }

    var partnerChipState: PartnerChipState {
        isPaired ? .invitePending : .none
    }

    // MARK: - Routing

    /// Resolves the current HomeState from completion flags.
    /// Each guard gates the next state — order is intentional.
    private func resolveHomeState() -> HomeState {
        guard myMapComplete      else { return .gated }
        guard postReflectionDone else { return .postReflection }
        guard partnerMapComplete  else { return .waiting }
        guard revealDone          else { return .matchReady }
        return .dashboard
    }

    /// Whether a given tab should be locked in the current home state.
    func isTabLocked(_ tab: AppTab) -> Bool {
        switch homeState {
        case .dashboard:
            return false
        default:
            return tab == .play || tab == .map
        }
    }

    // MARK: - Actions

    func markPostReflectionDone() {
        postReflectionDone = true
    }

    func advanceReflectionStep() {
        reflectionStep += 1
    }

    // MARK: - Deck Loading

    func loadDeck() async {
        guard !isLoadingDeck else { return }
        isLoadingDeck = true
        deckLoadError = nil

        do {
            let loaded = try ContentLoader.loadDeck(id: "the-opener")
            deck = loaded
            logger.info("Deck loaded: \(loaded.id)")
        } catch {
            deckLoadError = error.localizedDescription
            logger.error("Deck load failed: \(error.localizedDescription)")
        }

        isLoadingDeck = false
    }
}