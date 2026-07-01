# 08 — Session Realtime Handshake (the risky core)

**Goal:** In one pass, wire the two-device server-authoritative "both here → active" handshake for the couple card session over Supabase Realtime, with a poll fallback. Introduce a dedicated `AirlockStore` (`@Observable @MainActor`) that owns the `curated_sessions` realtime channel lifecycle (presence joins/leaves + postgres-changes UPDATE stream), derives its A/B `SessionRole` from the local `Couple`, and flips the row to `active` EXACTLY once when both partners are present and both consented. Add a `pollOpenSession` heartbeat fallback (modeled on `PairingService.pollForClaim`) that engages on subscribe failure without regressing the realtime path. Drive it all from a two-device debug harness (extending the existing `PresenceDebugView`). No Player, no Builder, no Lobby UI — handshake only. The app compiles green and the single-device state machine + poll path are exercisable in the simulator; the two-device behavior is proven by Bryan on physical devices.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

> ## ⚠️ ONE-SHOT CAVEAT — this segment cannot be proven by a build (read before you start)
>
> This is roadmap **S2**, the **highest-risk segment**: Supabase Realtime is NEW to this stack (the app
> has only ever polled, in `PairingService`). Fable can build ALL the code below in a single pass, and the
> single-device state machine + the poll fallback path ARE exercisable in one simulator. But the load-bearing
> two-device behaviors — presence join/leave across two phones, A-mutates-row → B-sees-it-in-~1s, the
> **exactly-once** `active` flip, and the poll fallback taking over when realtime is down — **cannot be
> proven by a build or by a single simulator instance.** They require two independent auth sessions on two
> devices talking to the live backend.
>
> **Therefore the build-green Definition of Done for this pass is deliberately narrow:** the project
> compiles, the `AirlockStore` state machine transitions correctly for a single device, and the poll path
> is reachable and exercisable. **The two-physical-device proof lives entirely in Bryan's checklist.** Also:
> **Simulator Sign-in-with-Apple is flaky** — the couple must be authenticated to pass RLS, so the final
> handshake MUST be verified on **at least one physical device** (ideally two). Never mark S2 "done" from a
> green build alone. This plan's job is to make the two-device test *possible and correct-by-construction*,
> not to declare it passed.

---

## Context Fable needs

- **What this is:** the two-device "tissue" for the couple card session's opening handshake. Two phones join
  one Supabase Realtime channel keyed by `couple_id`, announce presence, and watch the shared
  `curated_sessions` row. When both are present and both have consented, the row flips to `active` — and both
  devices observe that flip and reach `.active` locally. This is the ceremony that makes the session a shared
  event, not a slideshow.

- **Where it sits:** the session cover is `CardSessionContainerView` → `CoupleSessionStore` (phases:
  `airlock → transition → session → close → done`), with `AirlockView` as the first screen. **S2 is scoped to
  the handshake only** — no Player, no Builder, no real Lobby/Airlock UI (that is S3/S4). You will drive S2
  from a **debug harness**, extending the existing throwaway `PresenceDebugView`.

- **Current state (verified 2026-07-01) — the premise has drifted, read carefully:**
  - There is **NO `AirlockStore` class today.** The roadmap S2 text and the 06-16 spec both *named* an
    `AirlockStore`, but the 06-21 build **consolidated `AirlockStore` + `CuratedPlayerStore` into one
    `CoupleSessionStore`** (see `CoupleSessionStore.swift` header + the 06-21 spec build log, line ~157). The
    airlock is a *phase* inside `CoupleSessionStore`, rendered by `AirlockView.swift`. Partner presence there
    is a **local mock** (`CoupleSessionStore.partnerPresent`, armed by a timer in `armPresence()`).
  - `RealtimeSessionService.swift` (`Vayl/Core/Services/`) is **built and real**: DTO
    (`CuratedSessionDTO`), `SessionRole` (a/b, with `presenceColumn`/`consentColumn`/`bandwidthColumn`),
    `CuratedSessionStatus`, REST CRUD (`openSession`/`fetchOpenSession`/`setPresence`/`setConsent`/
    `setBandwidth`/`setStatus`/`advance` conditional-update), **and** the channel factory
    `sessionChannel(coupleId:userId:)` + `trackPresence(on:userId:)` + `leaveChannel(_:)`. The channel factory
    already documents the correct ordering (register listeners BEFORE subscribe, `track` AFTER subscribe).
  - `PresenceDebugView.swift` (`Vayl/Features/Sessions/Debug/`, `#if DEBUG`) already proves **B1 presence**:
    its `PresenceDebugStore` opens `sessionChannel`, registers `presenceChange()` before
    `subscribeWithError()`, tracks after, and maintains a present set from `change.joins.keys` /
    `change.leaves.keys`. This file compiles against the pinned SDK, so its exact call shapes are your ground
    truth. **This plan promotes that pattern into the real `AirlockStore` and adds postgres-changes + the
    active-flip + poll fallback on top.**

- **The decision this plan makes (and why):** rather than thread realtime into `CoupleSessionStore` (which
  owns the whole local cover and would blur the S2/S3 boundary), introduce a **dedicated `AirlockStore`** that
  owns ONLY the handshake — the channel, presence, the row stream, role, and the active-flip. This matches the
  roadmap's S2 language verbatim ("`AirlockStore` … orchestrating `lobby → airlock → active`, role from
  `Couple.partnerAId == myUserId`"), respects the S2 constraint ("Handshake only — no Player, debug UI only"),
  and leaves `CoupleSessionStore`'s verified local flow **completely untouched**. Wiring `AirlockStore` into
  the real `CoupleSessionStore` cover is deliberately left to **S3** (Entry + Airlock UI). Model the new store
  on **`PairingStore.swift`** (state enum + `@Observable @MainActor` + injected service + a `Task` you cancel)
  and its service methods on the existing **`PairingService.pollForClaim`** (the poll template) and the
  already-real **`RealtimeSessionService`** helpers.

- **Backend is confirmed present (this was S1, marked done — verified 2026-07-01):** `curated_sessions` exists
  as a table in `supabase/migrations/20260101000000_baseline.sql` with columns `couple_id`, `initiator_id`,
  `status` (check constraint: lobby/airlock/active/paused/complete/abandoned), `current_index`, `a_present`,
  `b_present`, `a_consented`, `b_consented`, `a_bandwidth`, `b_bandwidth`, `timer_started_at`, `reveal_state`,
  `safe_word_used`, timestamps. It has `REPLICA IDENTITY FULL` (line 211 — required for postgres-changes UPDATE
  payloads to carry the full row), the partial unique index `curated_sessions_one_open_per_couple` (one open
  session per couple), RLS policy `"couple members manage their curated session"` via `is_couple_member`, and
  crucially **is in the realtime publication**: `ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY
  "public"."curated_sessions"` (baseline line 600). **No new migration is needed for S2.** If, when you build,
  any of these is missing (e.g. a linked-prod drift), that is a **hard prerequisite** — stop and flag it; do
  not attempt to `apply_migration` from this plan.

- **SDK version (verified):** `supabase-swift` is pinned at **2.48.0** (`Package.resolved`), **not 2.41.1** as
  the roadmap note states. The listener-before-subscribe / track-after-subscribe ordering and the
  `presenceChange()` / `postgresChange(AnyAction.self, …, filter: .eq(…))` / `subscribeWithError()` /
  `channel.track(_:)` / `channel.untrack()` API shapes are all present and correct in 2.48.0 (confirmed
  against the checked-out sources and against the compiling `PresenceDebugStore`). Use those exact shapes.

- **A subtle identity gotcha (auth id vs profile id — from Bryan's backend-reconciliation notes):** the remote
  `couples` table keys `user_a`/`user_b` to `user_profiles.id` (the **profile id**), and `is_couple_member`
  maps `auth.uid()` → `user_profiles.id` → membership. The **local** SwiftData `Couple.partnerAId` /
  `partnerBId` are those same profile ids. So role derivation compares the **profile id**, not the auth id:
  `role = (couple.partnerAId == myProfileId) ? .a : .b`. Resolve `myProfileId` from local SwiftData
  `UserProfile.id` (the durable source of truth), NOT from `supabase.auth.session.user.id` (that is the auth
  id). See Segment 3 for the exact resolution.

- **Canonical patterns to imitate:**
  - Store shape + poll-task lifecycle + state enum → **`Vayl/Features/Pairing/PairingStore.swift`**.
  - Poll loop over a realtime channel with a timeout race → **`PairingService.pollForClaim`**
    (`Vayl/Core/Services/PairingService.swift`).
  - Channel lifecycle (listeners → subscribe → track) + present-set maintenance →
    **`PresenceDebugStore`** in `Vayl/Features/Sessions/Debug/PresenceDebugView.swift`.
  - Realtime helpers + DTO + role + REST mutators → **`Vayl/Core/Services/RealtimeSessionService.swift`**
    (extend it, don't reinvent).

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/AirlockStore.swift` | The S2 handshake brain. `@Observable @MainActor final class`. Owns the channel + presence set + row stream + poll fallback; derives `SessionRole`; runs `lobby → airlock → active`; flips `active` exactly once when both present + both consented. Modeled on `PairingStore`. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Core/Services/RealtimeSessionService.swift` | after the presence extension (ends ~L293) | Add `curatedSessionUpdates(on:)` (postgres-changes UPDATE stream → `CuratedSessionDTO`) + `applyPresenceAndStatus(...)` convenience is NOT needed; add a small `flipToActiveIfBoth(sessionId:)` conditional-update guard + `heartbeatOpenSession(coupleId:role:)` poll helper. Pure data access only. |
| `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` | whole `#if DEBUG` body | Repoint the debug harness at the real `AirlockStore` (replace the throwaway `PresenceDebugStore` internals) so two devices can drive the full handshake (open/join → present → consent → active) and a "Disable realtime (force poll)" toggle. Still `#if DEBUG`, still throwaway. |

### Delete

_None._ (`PresenceDebugStore` is repurposed in place; keep it `#if DEBUG`. The real channel lifecycle now lives in `AirlockStore`, so once S3 lands, `PresenceDebugView` can be deleted — but not in this pass.)

---

## Build steps (segments)

> All segments are built in ONE pass. They are ordered for readability only.

### Segment 1 — Service: postgres-changes UPDATE stream + poll/flip helpers

**One thing it does:** extends `RealtimeSessionService` with (a) a postgres-changes UPDATE stream that decodes
each changed `curated_sessions` row into a `CuratedSessionDTO`, (b) a poll helper that reads the open session
and writes this device's presence heartbeat, and (c) a conditional "flip to active" guard. Pure data access —
no state, no UI.

**Exact changes** — append to the existing `extension RealtimeSessionService` block at the bottom of
`Vayl/Core/Services/RealtimeSessionService.swift` (the file already `import Supabase`, has the private
`SupabaseTable.curatedSessions` constant, `CuratedSessionDTO`, `SessionRole`, and the `sessionChannel` /
`trackPresence` / `leaveChannel` helpers):

```swift
// MARK: - Realtime: postgres-changes (B2) + poll fallback + active-flip guard
// B2 adds the UPDATE stream so a device sees the partner's row mutations in ~1s.
// The stream is registered on the SAME channel as presence (B1); the CONSUMER
// (AirlockStore) registers BOTH listeners BEFORE subscribeWithError(), then
// tracks. The service stays a pure factory + helpers.

extension RealtimeSessionService {

    /// A single decoded UPDATE to this couple's session row. `nil` means an UPDATE
    /// arrived that did not decode (logged, skipped) — the consumer re-fetches on nil.
    /// Filter is scoped to this couple so we never see another couple's traffic
    /// (RLS also blocks it, but the filter keeps the stream tight).
    func curatedSessionUpdates(
        on channel: RealtimeChannelV2,
        coupleId: UUID
    ) -> AsyncStream<CuratedSessionDTO> {
        // Snake_case columns are handled by CuratedSessionDTO's explicit CodingKeys,
        // so a plain decoder is correct here (no keyDecodingStrategy).
        let decoder = JSONDecoder()
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: SupabaseTable.curatedSessions,
            filter: .eq("couple_id", value: coupleId.uuidString)
        )
        return AsyncStream { continuation in
            let task = Task {
                for await change in changes {
                    // We only care about the post-image of INSERT/UPDATE.
                    guard let record = try? change.decodeRecord(
                        as: CuratedSessionDTO.self, decoder: decoder
                    ) else {
                        logger.warning("curated_sessions change did not decode — consumer will re-fetch")
                        continue
                    }
                    continuation.yield(record)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Flips the row to `active` ONLY if it is still an open pre-active status
    /// (lobby/airlock) AND both partners are present AND both consented. Conditional
    /// on the server so a race between the two devices resolves to exactly one write.
    /// Returns true if THIS call performed the flip, false if it was already active
    /// (or the guard failed). Mirrors `advance(sessionId:expectedIndex:)`.
    @discardableResult
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        let flipped: [CuratedSessionDTO] = try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["status": CuratedSessionStatus.active.rawValue])
            .eq("id", value: sessionId.uuidString)
            .in("status", values: [CuratedSessionStatus.lobby.rawValue,
                                   CuratedSessionStatus.airlock.rawValue])
            .eq("a_present", value: true)
            .eq("b_present", value: true)
            .eq("a_consented", value: true)
            .eq("b_consented", value: true)
            .select()
            .execute()
            .value

        return !flipped.isEmpty
    }

    /// Poll fallback (no realtime). Writes this device's presence heartbeat, then
    /// reads the couple's open session back. Called on a timer by AirlockStore when
    /// the realtime subscribe fails. Modeled on `PairingService.pollForClaim`'s
    /// re-fetch-per-tick shape, but stateless (the loop lives in the Store).
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        // Announce presence for this device via the row (not the channel).
        if let open = try await fetchOpenSession(coupleId: coupleId) {
            try await setPresence(sessionId: open.id, role: role, present: true)
        }
        return try await fetchOpenSession(coupleId: coupleId)
    }
}
```

**done:** `RealtimeSessionService` compiles with the three new helpers; `curatedSessionUpdates` returns an
`AsyncStream<CuratedSessionDTO>`, `flipToActiveIfBoth` is a conditional update returning `Bool`, and
`heartbeatOpenSession` writes presence then re-reads. No `Store`/`View`/SwiftData references leaked into the
service.

---

### Segment 2 — `AirlockStore`: state machine + role + dependencies (no realtime yet)

**One thing it does:** creates the `@Observable @MainActor` store with its public state enum, role derivation,
dependencies (injected `RealtimeSessionService`, `coupleId`, `myProfileId`, `role`, `initiatorId`), and the
idempotent local transitions — but not yet the channel. Modeled on `PairingStore` (state enum + injected
service + cancelable task).

**Exact changes** — create `Vayl/Features/Sessions/AirlockStore.swift`:

```swift
//
//  AirlockStore.swift
//  Vayl
//
//  S2 — the two-device "both here → active" handshake brain. Owns ONLY the
//  handshake: the curated_sessions realtime channel (presence + postgres-changes
//  UPDATE stream), this device's SessionRole, and the server-authoritative flip to
//  `active` when BOTH partners are present AND both consented. It does NOT own the
//  local card flow — that stays in CoupleSessionStore. Wiring this into the real
//  .vaylCover is S3; today it is driven by the debug harness.
//
//  Modeled on PairingStore (state enum + @Observable @MainActor + injected service +
//  a cancelable Task). The channel lifecycle (listeners BEFORE subscribe, track AFTER)
//  is promoted from the proven PresenceDebugStore pattern. Adds postgres-changes, the
//  exactly-once active-flip, and a poll fallback on top.
//

import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AirlockStore")

// MARK: - HandshakeState

enum HandshakeState: Equatable {
    case lobby                       // channel not yet live
    case airlock                     // channel live, waiting on presence + consent
    case active(sessionId: UUID)     // both present + both consented → row is `active`
    case error(String)

    static func == (lhs: HandshakeState, rhs: HandshakeState) -> Bool {
        switch (lhs, rhs) {
        case (.lobby, .lobby):                     return true
        case (.airlock, .airlock):                 return true
        case (.active(let a), .active(let b)):     return a == b
        case (.error(let a), .error(let b)):       return a == b
        default:                                   return false
        }
    }
}

// MARK: - AirlockStore

@Observable
@MainActor
final class AirlockStore {

    // MARK: - Public state (read surfaces for the harness / S3 UI)

    private(set) var state: HandshakeState = .lobby
    /// Live transport mode. Flips to `.poll` if realtime subscribe fails.
    private(set) var transport: Transport = .realtime
    /// Whether the partner is present (from presence OR the row heartbeat).
    private(set) var partnerPresent: Bool = false
    /// Whether THIS device has consented. Mirrors the row column for `role`.
    private(set) var selfConsented: Bool = false
    /// Whether the PARTNER has consented (from the row).
    private(set) var partnerConsented: Bool = false
    /// The current session row, once opened/fetched.
    private(set) var session: CuratedSessionDTO?

    enum Transport: String { case realtime, poll }

    // MARK: - Identity

    let coupleId: UUID
    let myProfileId: UUID
    let role: SessionRole
    private let initiatorId: UUID

    /// The OTHER slot — used when reading the partner's presence/consent from the row.
    private var partnerRole: SessionRole { role == .a ? .b : .a }

    // MARK: - Dependencies

    private let service: RealtimeSessionService

    // MARK: - Private lifecycle

    private var channel: RealtimeChannelV2?
    private var presenceTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    /// Guards the local no-op after the first `.active` — the SERVER flip is already
    /// idempotent (conditional update); this just avoids re-issuing it locally.
    private var didRequestFlip = false

    // MARK: - Init

    init(
        coupleId: UUID,
        myProfileId: UUID,
        role: SessionRole,
        initiatorId: UUID,
        service: RealtimeSessionService? = nil
    ) {
        self.coupleId = coupleId
        self.myProfileId = myProfileId
        self.role = role
        self.initiatorId = initiatorId
        self.service = service ?? RealtimeSessionService()
    }

    /// Resolves this device's role from the LOCAL Couple (profile-id keyed) and builds
    /// the store. `partnerAId == myProfileId → .a`, else `.b`. Returns nil if the
    /// couple / profile can't be resolved locally (caller shows an empty/error state).
    static func make(
        coupleId: UUID,
        modelContainer: ModelContainer,
        service: RealtimeSessionService? = nil
    ) -> AirlockStore? {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            logger.error("make — no local UserProfile")
            return nil
        }
        var coupleFetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        coupleFetch.fetchLimit = 1
        guard let couple = try? context.fetch(coupleFetch).first else {
            logger.error("make — no local Couple \(coupleId)")
            return nil
        }
        let role: SessionRole = (couple.partnerAId == profile.id) ? .a : .b
        // The initiator is whoever opens the row; for the harness, this device.
        return AirlockStore(
            coupleId: coupleId,
            myProfileId: profile.id,
            role: role,
            initiatorId: profile.id,
            service: service
        )
    }

    // MARK: - Consent (this device)

    /// Mark this device consented — pushes the row column, then re-checks the flip.
    func consent() async {
        guard let sid = session?.id else { return }
        selfConsented = true
        do {
            try await service.setConsent(sessionId: sid, role: role, consented: true)
            await tryFlipToActive()
        } catch {
            logger.warning("consent push failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Teardown

    func leave() {
        presenceTask?.cancel(); presenceTask = nil
        updatesTask?.cancel(); updatesTask = nil
        pollTask?.cancel(); pollTask = nil
        if let channel {
            self.channel = nil
            Task { await service.leaveChannel(channel) }
        }
        // Best-effort: mark this device gone in the row.
        if let sid = session?.id {
            let role = self.role
            Task { try? await self.service.setPresence(sessionId: sid, role: role, present: false) }
        }
    }
}
```

**done:** `AirlockStore.swift` compiles; `HandshakeState` is `Equatable`; `make(coupleId:modelContainer:)`
resolves `role` from `Couple.partnerAId == UserProfile.id`; `consent()` and `leave()` exist. No realtime yet
(Segment 3 fills `start()` + `tryFlipToActive()` + the poll loop).

---

### Segment 3 — `AirlockStore`: channel start (presence + updates), active-flip, poll fallback

**One thing it does:** adds the realtime `start()` (open-or-fetch the row, register BOTH listeners before
subscribe, track after), the row-derived presence/consent mirroring, the **exactly-once** active flip, and the
poll fallback that engages on subscribe failure. This is the load-bearing core.

**Exact changes** — add this extension to the bottom of `Vayl/Features/Sessions/AirlockStore.swift`:

```swift
// MARK: - Realtime lifecycle + flip + poll

extension AirlockStore {

    /// Entry point. As initiator, opens the row; either way subscribes to presence +
    /// updates on the couple channel. On subscribe failure, falls back to polling.
    /// Ordering is load-bearing: register presenceChange() AND curatedSessionUpdates()
    /// BEFORE subscribeWithError(), and trackPresence() ONLY AFTER it succeeds.
    func start() async {
        state = .airlock

        // 1) Ensure a row exists. Initiator opens; joiner fetches. If a row already
        //    exists (one-open-per-couple index), openSession would violate it, so the
        //    joiner path just fetches. The harness picks who is initiator.
        do {
            if let existing = try await service.fetchOpenSession(coupleId: coupleId) {
                session = existing
                applyRow(existing)
            } else {
                let draft = CuratedSessionDraft(
                    deckId: "debug", deckVariant: nil,
                    cardIds: [], perCardTimer: [:], globalTimerSeconds: nil
                )
                let opened = try await service.openSession(
                    coupleId: coupleId, initiatorId: initiatorId, draft: draft
                )
                session = opened
                applyRow(opened)
            }
        } catch {
            logger.warning("open/fetch failed, falling back to poll: \(error.localizedDescription)")
            startPollFallback()
            return
        }

        // 2) Build the channel and register BOTH listeners before subscribing.
        let channel = service.sessionChannel(coupleId: coupleId, userId: myProfileId)
        self.channel = channel
        let presence = channel.presenceChange()
        let updates  = service.curatedSessionUpdates(on: channel, coupleId: coupleId)

        do {
            try await channel.subscribeWithError()
            try await service.trackPresence(on: channel, userId: myProfileId)
            // Announce presence in the row too (so poll-mode partners still see us).
            if let sid = session?.id {
                try await service.setPresence(sessionId: sid, role: role, present: true)
            }
            transport = .realtime
        } catch {
            logger.warning("subscribe failed, falling back to poll: \(error.localizedDescription)")
            await service.leaveChannel(channel)
            self.channel = nil
            startPollFallback()
            return
        }

        // 3a) Presence: partner appears/disappears. Keys are profile ids.
        presenceTask = Task { [weak self] in
            guard let self else { return }
            for await change in presence {
                let joined  = change.joins.keys.map(String.init)
                let left    = change.leaves.keys.map(String.init)
                let mine    = self.myProfileId.uuidString
                if joined.contains(where: { $0 != mine }) { self.partnerPresent = true }
                if left.contains(where:   { $0 != mine }) { self.partnerPresent = false }
                await self.tryFlipToActive()
            }
        }

        // 3b) Row updates: mirror presence/consent/status, then check the flip.
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await row in updates {
                self.session = row
                self.applyRow(row)
                await self.tryFlipToActive()
            }
        }
    }

    /// Copies the row's partner-side presence/consent + status into local state.
    /// Row presence is a backstop to channel presence (poll-mode partners set it).
    private func applyRow(_ row: CuratedSessionDTO) {
        let partnerPresentInRow = (partnerRole == .a) ? row.aPresent : row.bPresent
        let partnerConsentInRow = (partnerRole == .a) ? row.aConsented : row.bConsented
        if partnerPresentInRow { partnerPresent = true }
        partnerConsented = partnerConsentInRow
        selfConsented    = (role == .a) ? row.aConsented : row.bConsented

        if row.status == CuratedSessionStatus.active.rawValue {
            state = .active(sessionId: row.id)
        }
    }

    /// The EXACTLY-ONCE active flip. The server update is conditional (both present +
    /// both consented + still pre-active), so if both devices call it simultaneously
    /// exactly one write lands. `didRequestFlip` just avoids re-issuing locally.
    private func tryFlipToActive() async {
        guard case .airlock = state else { return }
        guard let sid = session?.id else { return }
        guard partnerPresent, selfConsented, partnerConsented, !didRequestFlip else { return }
        didRequestFlip = true
        do {
            let didFlip = try await service.flipToActiveIfBoth(sessionId: sid)
            logger.info("flipToActive requested — thisDeviceWon=\(didFlip)")
            // Whether we won or the partner did, the UPDATE stream (or poll) delivers
            // status=active and applyRow(...) moves us to .active. If realtime is down,
            // set it locally here too so poll-only devices still advance.
            if didFlip, transport == .poll { state = .active(sessionId: sid) }
        } catch {
            didRequestFlip = false   // allow a retry on the next signal
            logger.warning("flipToActive failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Poll fallback (no realtime)

    /// Engaged when subscribe fails. Every ~2s: write our presence heartbeat, re-read
    /// the row, mirror it, and check the flip. Adding poll must NOT regress realtime —
    /// it only runs when `transport == .poll` and the channel is nil. Modeled on
    /// PairingService.pollForClaim's re-fetch-per-tick loop.
    private func startPollFallback() {
        transport = .poll
        state = .airlock
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    if let row = try await self.service.heartbeatOpenSession(
                        coupleId: self.coupleId, role: self.role
                    ) {
                        self.session = row
                        self.applyRow(row)
                        await self.tryFlipToActive()
                        if case .active = self.state { break }
                    }
                } catch {
                    logger.warning("poll tick failed: \(error.localizedDescription)")
                }
                try? await Task.sleep(for: .seconds(2))   // 🎚️ heartbeat interval
            }
        }
    }

    /// Debug/testing hook: force the poll path even if realtime is available.
    func forcePollMode() async {
        presenceTask?.cancel(); presenceTask = nil
        updatesTask?.cancel(); updatesTask = nil
        if let channel { self.channel = nil; await service.leaveChannel(channel) }
        startPollFallback()
    }
}
```

**done:** `start()` opens-or-fetches the row, registers `presenceChange()` + `curatedSessionUpdates()` BEFORE
`subscribeWithError()`, tracks AFTER; presence + row updates both drive `tryFlipToActive()`; the flip is
server-conditional and locally guarded by `didRequestFlip`; a subscribe failure engages `startPollFallback()`;
`forcePollMode()` exists for the harness toggle. Compiles.

---

### Segment 4 — Debug harness: drive the full handshake on two devices

**One thing it does:** repoints the existing `#if DEBUG` `PresenceDebugView` at the real `AirlockStore` so two
physical devices can run the whole handshake — open/join, presence, consent, active — plus a "Force poll"
toggle to exercise the fallback. Still throwaway, still `#if DEBUG`. Uses tokens only.

**Exact changes** — replace the body of `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` (keep the
`#if DEBUG` wrapper and imports). The store becomes a thin driver around `AirlockStore`:

```swift
#if DEBUG
import SwiftUI
import SwiftData
import Supabase

// MARK: - Driver
// THROWAWAY S2 harness. Two devices, SAME couple, DISTINCT auth. One taps "Open"
// (initiator), the other "Join". Both tap "Consent". Row flips `active` exactly once;
// both reach .active. "Force poll" exercises the no-realtime path. Delete when S3 owns
// the real Airlock UI.

@Observable
@MainActor
final class AirlockHarnessDriver {

    var coupleIdText: String = ""
    var status: String = "idle"
    private(set) var store: AirlockStore?

    private let modelContainer: ModelContainer
    init(modelContainer: ModelContainer) { self.modelContainer = modelContainer }

    func start() {
        let trimmed = coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let coupleId = UUID(uuidString: trimmed) else {
            status = "Couple ID must be a valid UUID."; return
        }
        guard let s = AirlockStore.make(coupleId: coupleId, modelContainer: modelContainer) else {
            status = "Could not resolve local Couple / UserProfile."; return
        }
        store = s
        status = "role \(s.role.rawValue) · starting…"
        Task { await s.start() }
    }

    func consent() { Task { await store?.consent() } }
    func forcePoll() { Task { await store?.forcePollMode() } }
    func leave() { store?.leave(); store = nil; status = "left" }
}

// MARK: - View

struct PresenceDebugView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var driver: AirlockHarnessDriver?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                Text("Airlock Handshake · S2")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Run on TWO physical devices, SAME Couple ID, each signed in as its own partner. One taps Open, the other Join. Both tap Consent. The row flips to active exactly once and both show ACTIVE. Force poll to test the no-realtime path.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)

                if let driver {
                    InteractiveField(placeholder: "Couple ID (UUID)", icon: "👥",
                                     text: Binding(get: { driver.coupleIdText },
                                                   set: { driver.coupleIdText = $0 }))

                    HStack(spacing: AppSpacing.md) {
                        VaylButton(label: "Open / Join", size: .compact) { driver.start() }
                        VaylButton(label: "Consent", style: .secondary, size: .compact) { driver.consent() }
                    }
                    HStack(spacing: AppSpacing.md) {
                        VaylButton(label: "Force poll", style: .secondary, size: .compact) { driver.forcePoll() }
                        VaylButton(label: "Leave", style: .secondary, size: .compact) { driver.leave() }
                    }

                    stateReadout(driver)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.pageBackground.ignoresSafeArea())
        .navigationTitle("Airlock Handshake")
        .task {
            if driver == nil {
                driver = AirlockHarnessDriver(modelContainer: modelContext.container)
            }
        }
    }

    @ViewBuilder
    private func stateReadout(_ driver: AirlockHarnessDriver) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(driver.status)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)

            if let store = driver.store {
                row("transport", store.transport.rawValue)
                row("state", stateLabel(store.state))
                row("partner present", store.partnerPresent ? "yes" : "no")
                row("you consented", store.selfConsented ? "yes" : "no")
                row("partner consented", store.partnerConsented ? "yes" : "no")
            } else {
                // Empty state (required on every data screen).
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundColor(AppColors.textTertiary)
                    Text("No handshake yet")
                        .font(AppFonts.cardTitle)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Enter a Couple ID and tap Open or Join.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(AppFonts.caption).foregroundColor(AppColors.textTertiary)
            Spacer()
            Text(v).font(AppFonts.caption).foregroundColor(AppColors.textBody)
        }
    }

    private func stateLabel(_ s: HandshakeState) -> String {
        switch s {
        case .lobby:            return "lobby"
        case .airlock:          return "airlock"
        case .active:           return "ACTIVE"
        case .error(let m):     return "error: \(m)"
        }
    }
}
#endif
```

> **Token verification note (do this while building, not from memory):** the harness uses
> `AppColors.pageBackground / textPrimary / textSecondary / textTertiary / textBody`, `AppFonts.screenTitle /
> caption / bodyMedium / cardTitle`, `AppSpacing.lg / md / sm / xs`, and `VaylButton` / `InteractiveField`.
> Every one of these is used by the current `PresenceDebugView.swift`, so they exist — but **read the token
> file before each use** and, if any name differs, use the real one and note the drift (never invent a token).

**done:** the harness compiles under `#if DEBUG`, builds an `AirlockStore` from a pasted Couple ID + local
profile, and exposes Open/Join · Consent · Force poll · Leave with a live state readout including an empty
state. Release builds exclude it entirely.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles, ALL of these are true:

- [ ] `Vayl/Features/Sessions/AirlockStore.swift` exists: `@Observable @MainActor final class`, `HandshakeState`
      is `Equatable` (`lobby / airlock / active(sessionId:) / error`), and `make(coupleId:modelContainer:)`
      derives `role` from `Couple.partnerAId == UserProfile.id` (profile id, not auth id).
- [ ] `AirlockStore.start()` opens-or-fetches the `curated_sessions` row, then registers **both**
      `presenceChange()` and `curatedSessionUpdates(on:coupleId:)` **before** `subscribeWithError()`, and calls
      `trackPresence` **only after** subscribe succeeds.
- [ ] The active flip is **server-conditional** (`flipToActiveIfBoth` updates only when status ∈ {lobby,airlock}
      AND `a_present && b_present && a_consented && b_consented`) and **locally guarded** (`didRequestFlip`), so
      it fires exactly once even if both devices trigger it together.
- [ ] Presence changes AND row UPDATEs both funnel into `tryFlipToActive()`; `applyRow(_:)` mirrors the
      partner's presence/consent and sets `.active` when the row status is `active`.
- [ ] On subscribe (or open/fetch) failure, `startPollFallback()` engages a ~2s heartbeat loop
      (`heartbeatOpenSession`) that mirrors the row and can reach `.active` with realtime OFF — and the poll
      path is only entered on failure/force, so it does **not** regress the realtime path.
- [ ] `RealtimeSessionService` gained `curatedSessionUpdates`, `flipToActiveIfBoth`, and `heartbeatOpenSession`;
      it remains pure data access (no Store/View/SwiftData, no `@Observable`).
- [ ] `PresenceDebugView` (`#if DEBUG`) drives the real `AirlockStore` (Open/Join · Consent · Force poll ·
      Leave) with a live readout + an empty state; it is excluded from release builds.
- [ ] `CoupleSessionStore.swift`, `AirlockView.swift`, `CardSessionContainerView.swift`, `SessionPlayerView`,
      `SessionCloseView`, and the local mock flow are **unchanged**.
- [ ] No new migration was added (S1 already shipped the table + publication in the baseline); no banned iOS-26
      APIs; no raw tokens in the harness view.
- [ ] The project compiles green; the single-device state machine is exercisable in one simulator (Open →
      airlock; Consent flips `selfConsented`; Force poll switches transport) and the poll loop is reachable.

---

## Bryan verifies on device (S2 is NOT done until this passes)

> These require **two physical devices** (or one physical + one that reliably authenticates). **Simulator
> Sign-in-with-Apple is flaky and the couple must be authenticated to pass the `curated_sessions` RLS**, so at
> least one leg MUST be a physical device. A green build proves none of this.

- [ ] **Presence join/leave:** both devices Open/Join the same Couple ID → each shows `partner present = yes`.
      Background/Leave one → the other flips to `partner present = no` within ~1–2s.
- [ ] **A-mutates → B-sees (~1s):** one device taps Consent → the other's `partner consented` flips to `yes`
      within ~1s (postgres-changes UPDATE stream working end to end).
- [ ] **Exactly-once active flip:** both present + both consented → the row flips to `active` exactly once
      (check Supabase dashboard: `status='active'`, one row) and **both** devices show `state = ACTIVE`. Try
      tapping the second Consent near-simultaneously on both — still exactly one flip, no double-advance error.
- [ ] **Poll fallback (no realtime regression):** on one device tap **Force poll** (or disable network's
      websocket path) → that device still reaches `ACTIVE` via the ~2s heartbeat while the other stays on
      realtime. Confirm the realtime device is unaffected (no slowdown, no dropped presence).
- [ ] **RLS holds:** a device signed in as a NON-member of the couple cannot open/read the row (the harness
      shows an error / empty, not another couple's data).
- [ ] 🎚️ **Heartbeat interval** (default 2s) feels responsive-enough in poll mode without hammering the API —
      tune in `startPollFallback()` if needed.

---

## Constraints / do-not-touch

- **Handshake only.** No Player, no Builder, no real Lobby/Airlock UI — those are S3/S4. The only View touched
  is the `#if DEBUG` `PresenceDebugView`.
- **Do NOT modify** `CoupleSessionStore.swift`, `AirlockView.swift`, `CardSessionContainerView.swift`,
  `SessionPlayerView.swift`, `SessionCloseView.swift`, `SessionPlan.swift`, or the local mock flow. The
  local→real swap (wiring `AirlockStore` into the real cover) is **S3**, out of scope here. Leave the
  scaffold methods in `CoupleSessionStore` (`liveOpen`/`liveAdvance`/`startRemoteSync`) as-is.
- **Do NOT add or edit a migration.** The `curated_sessions` table, the partial unique index, RLS, and the
  `supabase_realtime` publication are already in `20260101000000_baseline.sql` (verified). If any is missing
  when you build (prod drift), STOP and flag it as a hard prerequisite — do not `apply_migration`.
- **`PlayView` is off-limits** (reserved for generative tools) — irrelevant here but noted per the roadmap.
- **`RealtimeSessionService` stays pure data access** — no state, no `@Observable`, no SwiftData, no
  Store/View references. The channel *lifecycle* lives in `AirlockStore`, not the service.
- **Adding poll must not regress realtime:** the poll loop runs only on subscribe/open failure or explicit
  `forcePollMode()`, guarded by `transport == .poll`.
- **Do NOT touch** the legacy `couple_session_records` table or `SessionSyncService` (unrelated end-of-session
  sync).

---

## Open decisions (each has a recommended default — proceed on it, flag it)

1. **Who is the initiator when both devices race to Open?**
   **Default (implemented):** whoever's `openSession` lands first creates the row; the second device's
   `openSession` would violate the one-open-per-couple partial unique index, so the harness's "Join" path calls
   `fetchOpenSession` instead. In the harness, Bryan picks one device to Open and the other to Join, so the
   race is avoided. If Fable wants robustness, wrap `openSession` in a `catch` that falls back to
   `fetchOpenSession` on a unique-violation — safe and additive. **Flag if implemented.**

2. **Role from local `Couple` vs. a server round-trip.**
   **Default (implemented):** derive `role` locally from `Couple.partnerAId == UserProfile.id`, since the local
   `Couple` mirrors the backend `user_a`/`user_b` (profile ids). This avoids a network hop and matches the
   roadmap's stated derivation. If the local `Couple` is ever absent (edge case), `make(...)` returns nil and
   the harness shows an error — acceptable for a debug harness; S3 can add a remote resolve.

3. **Presence key: profile id vs. auth id.**
   **Default (implemented):** the channel presence key is `myProfileId` (matching the local role identity), and
   presence join/leave deltas are compared against `myProfileId.uuidString`. The existing `PresenceDebugStore`
   used an arbitrary UUID; using the profile id makes "who is present" attributable to the actual partner. If
   the RLS/realtime layer needs the auth id as the presence key instead, switch to
   `supabase.auth.session.user.id` in `start()` and note it — but presence keying is cosmetic to RLS (which is
   enforced server-side on the row), so profile id is the safer, more legible default.

4. **Does the row heartbeat `setPresence` belong in realtime mode too?**
   **Default (implemented):** yes — `start()` writes `setPresence(true)` on the row even in realtime mode, so a
   poll-only partner can still detect us via `applyRow`. This is a cheap belt-and-suspenders that makes mixed
   realtime/poll pairs work. Flag if Bryan prefers channel-presence-only.
