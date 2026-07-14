//
//  SessionOpener.swift
//  Vayl — Play
//
//  Shareable "open a curated session" flow, extracted verbatim from
//  PlayStore.openSession(deck:plan:) (Task 3b, pure refactor) so Home can
//  eventually open a session the same way Play does. The body/guards/order
//  are UNCHANGED from PlayStore — only the destination of the result moved,
//  from direct state writes to a returned SessionOpenResult.
//

import Foundation
import SwiftData

/// The outcome of a session-open attempt. The caller (a Store) switches this
/// onto its own published state — this type carries no UI/state itself.
enum SessionOpenResult {
    case launch(SessionLaunch)              // opened → present cover
    case conflict(CuratedSessionDTO)        // active/paused row exists
    case debugLocal(SessionLaunch)          // unpaired DEBUG couch path
    case failed(message: String, retryable: Bool)  // user-facing error; retryable = re-run the same plan
    case unavailable                        // release-build unpaired: silently no-op (no error, no launch)
}

/// Opens (or resumes/conflicts on) a curated session for a deck + plan.
/// `realtime` is `PlaySessionOpening` — the same minimal seam PlayStore
/// already depends on (openSession + fetchOpenSession + setStatus); no
/// widening to the concrete `RealtimeSessionService`.
struct SessionOpener {
    let realtime: PlaySessionOpening

    /// Mirrors `PlayStore.openSession(deck:plan:)`'s body exactly, guard for
    /// guard, in the same order. Callers own `isOpeningSession` bracketing
    /// and the `Task { @MainActor }` wrapper — this function is pure async.
    func open(deck: Deck, plan: SessionPlan, coupleId: UUID?, context: ModelContext) async -> SessionOpenResult {
        guard let coupleId, let myId = SessionIdentity.localProfileId(context: context, coupleId: coupleId) else {
            // Solo / unpaired: keep the local single-device path behind DEBUG only.
            #if DEBUG
            return .debugLocal(SessionLaunch(hand: deck.orderedCards, entry: .localDebug,
                                              role: .a, session: nil))
            #else
            // RELEASE: the original guard silently did nothing here (no error,
            // no launch). Explicit no-op case — the caller does nothing.
            return .unavailable
            #endif
        }
        guard let hand = SessionLaunch.buildHand(cardIds: plan.cardIds, deck: deck) else {
            // Low risk here (the plan came straight from this device's local
            // deck), but validate anyway for symmetry with the joiner paths
            // (spec 2026-07-09 §1.8) — never launch a shortened hand. Not
            // retryable: re-running the same plan would fail identically.
            return .failed(message: SessionEntryStore.joinErrorMessage, retryable: false)
        }
        let draft = plan.draft
        do {
            // Self-heal: a lobby/airlock row I opened earlier and walked
            // away from would violate the one-open-session index and brick
            // every future open. Abandon it first; a partner-initiated
            // fresh row surfaces as the pending banner instead.
            if let existing = try? await realtime.fetchOpenSession(coupleId: coupleId) {
                if existing.status == CuratedSessionStatus.lobby.rawValue
                    || existing.status == CuratedSessionStatus.airlock.rawValue,
                   existing.initiatorId == myId {
                    try? await realtime.setStatus(sessionId: existing.id, status: .abandoned)
                } else if existing.status == CuratedSessionStatus.active.rawValue
                            || existing.status == CuratedSessionStatus.paused.rawValue {
                    // A genuinely unfinished couple session — inserting a new
                    // row would violate the one-open-per-couple index and
                    // dead-end on a generic error the user can never fix by
                    // retrying. Surface the conflict instead of attempting.
                    return .conflict(existing)
                }
            }
            let dto = try await realtime.openSession(
                coupleId: coupleId, initiatorId: myId, draft: draft
            )
            let role = SessionIdentity.role(context: context, coupleId: coupleId, profileId: myId)
            return .launch(SessionLaunch(hand: hand, entry: .initiator, role: role, session: dto))
        } catch {
            // Network/open failure — retryable: re-running the same plan may succeed.
            return .failed(message: "Couldn't start the session. Try again.", retryable: true)
        }
    }
}
