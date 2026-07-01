# Plan 10 — Session Player Core (roadmap S4)

**Goal:** turn the already-built single-device couple-session player into a two-device, server-authoritative one: both phones render `card_ids[current_index]` in lockstep from a Realtime UPDATE stream, Next/Skip advance through a conditional update that can't double-fire, a synced gentle timer nudges (never hard-cuts), one Whisper reveal exchanges private answers that are never persisted, and safety cues (keep-awake, dim, safe word "red", pause, listener role) live on top. One build-green pass.

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

## ⚠️ ONE-SHOT CAVEAT — read before you claim done

This plan builds the **entire** Player transport in one pass, but three of its four pillars are
**two-device behaviors a single build cannot prove**:

1. **Lockstep** — that Device B's card actually follows Device A's advance through the Realtime UPDATE
   stream.
2. **No-double-advance under contention** — that two simultaneous taps produce exactly one advance. The
   guard is a Postgres conditional update (`.eq("current_index", expectedIndex)`); it is only exercisable
   when two clients race the same row.
3. **Simultaneous Whisper reveal** — that both sides seal, both fire the 3-2-1, and answers cross via
   Broadcast **without touching the database**.

None of these can be observed with one simulator. **They are Bryan's checklist, not yours.**

**Definition of Done for THIS pass = build-green + a single-device playthrough that persists a
`CardSession` / `CardResult` / `DeckProgress` (the existing save path still fires).** Everything else is
compile-correctness + wiring you hand off. When realtime is not injected (the default, `realtime == nil`),
the store must behave **exactly as it does today** (pure-local advance, mock partner) so the single-device
playthrough is real and green.

**Depends on:** plan **08** (S2 — realtime transport: presence + postgres-changes + Broadcast plumbing in
`RealtimeSessionService`, `AppState.coupleId`, `AuthService.userId`, role resolution) and plan **09**
(S3 — session entry: how the `.vaylCover` is opened with a real `curated_sessions` row and a `sessionRole`).
This plan assumes a `remoteSessionId` and a subscribed channel can exist; it consumes them. If 08/09 have
not landed a helper you need, build the minimal consumer surface here and flag the seam.

---

## Context Fable needs

- **What this is.** The couple card session is the app's most protected experience: a two-device,
  in-person, safe-worded flow presented as a single `.vaylCover`. The cover routes
  `airlock → transition → session → close → done`. **S4 is the `session` phase** — the in-session player.
- **It is already built for one device.** The heart exists and compiles today:
  `Vayl/Features/Sessions/SessionPlayerView.swift` (fan deck, hold-to-deal, drawer ceremony, hero prompt,
  care sheet, idle dim, keep-awake) driven by `CoupleSessionStore`
  (`Vayl/Features/Sessions/CoupleSessionStore.swift`). **You are not rebuilding this — you are making it
  two-device-aware.** Read both files before touching anything.
- **The realtime scaffold is half-wired.** `CoupleSessionStore` already has an injected
  `RealtimeSessionService?` (default `nil`), `sessionRole: SessionRole`, `initiatorId: UUID?`,
  `remoteSessionId`, and fire-and-forget **push** methods (`liveOpen`, `liveAdvance`, `liveComplete`) that
  no-op unless a service is injected (`CoupleSessionStore.swift:98-138, 251-313`). What's missing is the
  **consume** side: `startRemoteSync()` is a TODO stub (`CoupleSessionStore.swift:308-313`). This plan fills
  it in and adds timer + reveal + safety.
- **The transport service is real.** `Vayl/Core/Services/RealtimeSessionService.swift` already has
  `advance(sessionId:expectedIndex:)` as a **conditional update** (`.eq("current_index", expectedIndex)`,
  returns `Bool` = "did I move it", `RealtimeSessionService.swift:242-254`), plus `openSession`,
  `setPresence`, `setStatus`, `setBandwidth`, and the channel factory `sessionChannel(coupleId:userId:)` +
  `trackPresence` / `leaveChannel` (`RealtimeSessionService.swift:277-293`). The DTO
  (`CuratedSessionDTO`) already decodes `currentIndex`, `timerStartedAt`, `safeWordUsed`, `cardIds`,
  `perCardTimer` (`RealtimeSessionService.swift:62-106`). `reveal_state` (jsonb) exists in the table but is
  intentionally **not** on the DTO yet — this plan carries reveal over **Broadcast**, not the row, so you do
  not need to add it.
- **The DB row is the authority.** Table `curated_sessions` (baseline migration
  `supabase/migrations/20260101000000_baseline.sql:186-208`) has `card_ids jsonb`, `per_card_timer jsonb`,
  `global_timer_seconds`, `current_index`, `timer_started_at timestamptz`, `reveal_state jsonb`,
  `safe_word_used bool`, `status`. It is in the `supabase_realtime` publication with `REPLICA IDENTITY
  FULL` (baseline `:211, :600`) and RLS is couple-members-only (`:570`). **You add no migration** — every
  column S4 needs already exists.
- **The save pattern to imitate — verbatim — is `CoupleSessionStore.persistSession()`
  (`CoupleSessionStore.swift:315-380`).** On completion it: creates a `CardSession(coupleId:deckId:)`, sets
  counts + `lockInBandwidthA/B`, computes `sessionNumber` from a fetch, inserts one `CardResult` per record
  (`sessionId:cardId:status:`), upserts `DeckProgress` (`completedAt` + `lastPlayedAt`), calls
  `context.saveWithLogging()` (NOT bare `try? save()`), sets `savedSessionId`, and `enqueueSync(...)`.
  `ModelContext(modelContainer)` is created **fresh at write time**, never stored on `self`. **Do not
  change this method's shape** — S4 already persists correctly. Your job is to make sure the two-device
  path funnels into it exactly once (the initiator writes; see Open Decisions).
- **Canonical patterns to imitate.** Channel lifecycle → `PresenceDebugStore`
  (`Vayl/Features/Sessions/Debug/PresenceDebugView.swift:38-93`): _register the stream before
  `subscribeWithError()`, `track` only after subscribed, consume via `for await`_. Safe word →
  `Vayl/Design/Components/Buttons/SafeWordButton.swift` (alert-confirm pattern, `AppColors.safetyAccent`).
  Keep-awake / capture via `connectedScenes` → `ScreenshotProtectionModifier`
  (`Vayl/Design/Components/Progress/ScreenshotProtectionModifier.swift:43-51`). Private input →
  `.screenshotProtected()` (already applied to sensitive cards at `SessionPlayerView.swift:47`).

**Verified Realtime API (supabase-swift 2.48.0, checked-out source):**
- `channel.postgresChange(UpdateAction.self, schema: "public", table: "curated_sessions", filter: RealtimePostgresFilter)` → `AsyncStream<UpdateAction>` (register BEFORE subscribe).
- `channel.broadcastStream(event: String)` → `AsyncStream<JSONObject>` (register BEFORE subscribe).
- `try await channel.broadcast(event: String, message: some Codable)` (send; only AFTER subscribed).
- `try await channel.subscribeWithError()`, `channel.presenceChange()`, `service.trackPresence(on:userId:)`, `service.leaveChannel(_)` — all already used in `PresenceDebugStore`.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/SessionSyncCoordinator.swift` | An `actor`-free `@MainActor` helper object owned by `CoupleSessionStore` that holds the subscribed `RealtimeChannelV2`, registers the three streams (presence, `curated_sessions` UPDATE, Broadcast), and pumps deltas back to the store via a closure. Keeps channel lifecycle out of the store body, mirroring `PresenceDebugStore`. Net-new consumer side of S2/S4. |
| `Vayl/Features/Sessions/Components/WhisperRevealView.swift` | The Whisper (D3) reveal surface: private `.screenshotProtected()` text field per side → seal → both-sealed → 3-2-1 → answers shown side by side. Renders inside the player when `store.currentCard?.type == .whisper`. Answers live in `@State` + arrive via Broadcast; never written to SwiftData or the row. |
| `Vayl/Features/Sessions/Components/SessionTimerBar.swift` | The synced gentle-timer ribbon: remaining derived from `store.timerRemaining`; at zero shows "wrap up" / "keep going" affordances (never auto-advances). Pure presentation; reads store, calls store methods. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Features/Sessions/CoupleSessionStore.swift` | `308-313` (`startRemoteSync` TODO), `140-158` (derived), `186-220` (session actions), `288-293` (`liveAdvance`) | Fill in `startRemoteSync()` to subscribe + consume the UPDATE/Broadcast/presence streams; add mirrored remote state (`remoteIndex`, `partnerPresentLive`, `timerStartedAt`, `safeWordUsed`, `isPaused`, reveal state); make `dealNext`/`pass` route through the server-authoritative advance when realtime is injected and **wait for the echoed UPDATE** rather than bumping `index` locally; add `timerRemaining`, `activeListener`, `raiseSafeWord()`, `togglePause()`, `keepGoing()`, and Whisper seal/reveal methods. All new remote behavior guarded by `realtime != nil` so the local path is byte-for-byte unchanged. |
| `Vayl/Features/Sessions/SessionPlayerView.swift` | `71-78` (keep-awake `onAppear/onDisappear`), `42-80` (body), `259-346` (controls) | Replace the bare `UIApplication.shared.isIdleTimerDisabled` keep-awake with a `connectedScenes`-scoped helper; add the `SessionTimerBar` overlay when a timer is set; add a safe-word affordance + pause state to the controls; render `WhisperRevealView` when the current card is a Whisper; render the active-listener role + turn cue. Do not disturb the hold-to-deal mechanic. |
| `Vayl/Features/Sessions/CardSessionContainerView.swift` | `35-43` (`.task` store build) | On store creation, if a realtime service + `remoteSessionId` were provided by plan 09's entry, call `store.startRemoteSync()`; ensure teardown (`leaveChannel`) on disappear. When nothing is injected (single-device default), unchanged. |

### Delete

_None._ (`PresenceDebugView.swift` is `#if DEBUG` throwaway but out of scope; leave it.)

---

## Build steps (segments)

> All four segments ship in one pass. They are ordered for reading. Every new remote code path is gated by
> `realtime != nil`; with no service injected the store must behave exactly as it does on `master` today.

### Segment D1 — Lockstep render + server-authoritative advance

**One thing:** when realtime is injected, both devices render `card_ids[current_index]` from the UPDATE
stream, and Next/Skip advance through the conditional update (no double-advance); completion persists via
the existing `persistSession()`.

**1a. New sync coordinator** — `Vayl/Features/Sessions/SessionSyncCoordinator.swift`. Owns the channel and
pushes decoded deltas to the store through typed callbacks. Modeled on `PresenceDebugStore` (register
streams before subscribe; `track` after subscribe; consume via `for await`).

```swift
//
//  SessionSyncCoordinator.swift
//  Vayl
//
//  Consumer side of the two-device session: subscribes ONE curated_sessions
//  channel, registers the UPDATE / presence / broadcast streams BEFORE
//  subscribing (ordering matters, per PresenceDebugStore), tracks presence
//  AFTER, and pumps typed deltas back to CoupleSessionStore via callbacks.
//
//  This keeps channel lifecycle out of the store body. The store owns state;
//  this owns the socket. Nothing here writes SwiftData or reads Views.
//
//  UNVERIFIED against two devices — see plan 10 one-shot caveat.
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionSyncCoordinator")

/// A private broadcast payload. Timer + reveal cross the wire here, NEVER the DB.
struct SessionBroadcast: Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case timerWrapUp        // per-card timer hit zero
        case timerKeepGoing     // a side cleared the anchor
        case revealSeal         // one side sealed their whisper
        case revealCountdown    // both sealed → run 3-2-1 on both
        case revealAnswer       // the sealed answer text, exchanged AT reveal only
    }
    let kind: Kind
    let role: String            // SessionRole.rawValue of the sender
    let text: String?           // only set for .revealAnswer
}

@MainActor
final class SessionSyncCoordinator {

    private let service: RealtimeSessionService
    private let coupleId: UUID
    private let userId: UUID
    private let sessionId: UUID

    private var channel: RealtimeChannelV2?
    private var tasks: [Task<Void, Never>] = []

    /// Callbacks into the store. Each fires on the MainActor.
    var onRowUpdate: ((CuratedSessionDTO) -> Void)?
    var onPresence: ((Set<String>) -> Void)?
    var onBroadcast: ((SessionBroadcast) -> Void)?

    init(service: RealtimeSessionService, coupleId: UUID, userId: UUID, sessionId: UUID) {
        self.service = service
        self.coupleId = coupleId
        self.userId = userId
        self.sessionId = sessionId
    }

    /// Register streams → subscribe → track. Idempotent-ish: guarded by `channel == nil`.
    func start() {
        guard channel == nil else { return }
        let channel = service.sessionChannel(coupleId: coupleId, userId: userId)
        self.channel = channel

        // Register BEFORE subscribe (ordering matters — see PresenceDebugStore).
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "curated_sessions",
            filter: .eq("couple_id", value: coupleId.uuidString)
        )
        let presence = channel.presenceChange()
        let broadcasts = channel.broadcastStream(event: "session")

        tasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                try await channel.subscribeWithError()
                try await self.service.trackPresence(on: channel, userId: self.userId)
            } catch {
                logger.warning("session channel subscribe failed (unverified): \(error.localizedDescription)")
                return
            }
        })

        tasks.append(Task { [weak self] in
            for await update in updates {
                guard let self else { return }
                // UpdateAction.record is the new row as [String: AnyJSON]; decode to DTO.
                guard let dto = try? update.decodeRecord(as: CuratedSessionDTO.self, decoder: JSONDecoder()),
                      dto.id == self.sessionId else { continue }
                self.onRowUpdate?(dto)
            }
        })

        tasks.append(Task { [weak self] in
            var present: Set<String> = []
            for await change in presence {
                guard let self else { return }
                present.formUnion(change.joins.keys)
                present.subtract(change.leaves.keys)
                self.onPresence?(present)
            }
        })

        tasks.append(Task { [weak self] in
            for await json in broadcasts {
                guard let self else { return }
                guard let data = try? JSONEncoder().encode(json),
                      let payload = try? JSONDecoder().decode(SessionBroadcast.self, from: data)
                else { continue }
                self.onBroadcast?(payload)
            }
        })
    }

    /// Send a private broadcast (timer / reveal). Only after subscribe; errors swallowed.
    func send(_ payload: SessionBroadcast) {
        guard let channel else { return }
        Task { try? await channel.broadcast(event: "session", message: payload) }
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        if let channel {
            self.channel = nil
            Task { await service.leaveChannel(channel) }
        }
    }
}
```

> Note the two API details Fable must confirm against 2.48.0 at build time and adjust if drifted:
> `UpdateAction.decodeRecord(as:decoder:)` is the documented decode path for a postgres UPDATE payload; if
> the checked-out signature differs (e.g. `record` is a `JSONObject` you decode manually), decode manually
> and keep the DTO shape. `broadcastStream(event:)` yields `JSONObject`; the encode/decode round-trip above
> is the portable way to reach a `Codable`. If a direct `AnyJSON`→`Codable` helper exists, prefer it.

**1b. Store — mirror the row and gate advance on the echo.** In `CoupleSessionStore`, add remote-mirror
state and rewrite `startRemoteSync()` (currently the stub at `:308-313`). When realtime is live, `index`
is driven by the **echoed** `current_index`, not local mutation — this is what makes it lockstep and what
makes the conditional-update guard meaningful.

```swift
// MARK: - Remote mirror (Seg D1 — realtime-only; nil-service path untouched)

/// True once the channel is subscribed and we're mirroring the row.
private(set) var isLive = false
/// Partner presence from the channel (replaces the airlock mock once live).
private(set) var partnerPresentLive = false
/// The session's coordinator — nil in the pure-local path.
private var coordinator: SessionSyncCoordinator?

/// Server-authoritative advance in flight; blocks local index bumps while we
/// wait for the echoed UPDATE so both devices move on the same row write.
private var advanceInFlight = false
```

Rewrite `startRemoteSync()`:

```swift
/// Seg D1: consume presence + row UPDATEs + broadcast. Server-authoritative:
/// `index` follows the echoed `current_index`, never a local bump, once live.
func startRemoteSync() {
    guard let realtime, let coupleId = appState.coupleId,
          let userId = currentUserId, let sid = remoteSessionId else { return }

    let coordinator = SessionSyncCoordinator(
        service: realtime, coupleId: coupleId, userId: userId, sessionId: sid
    )
    self.coordinator = coordinator

    coordinator.onRowUpdate = { [weak self] dto in
        guard let self else { return }
        self.applyRemoteRow(dto)
    }
    coordinator.onPresence = { [weak self] present in
        guard let self, let userId = self.currentUserId else { return }
        // Anyone present who isn't me = the partner is here.
        self.partnerPresentLive = present.contains { $0 != userId.uuidString }
    }
    coordinator.onBroadcast = { [weak self] payload in
        self?.applyBroadcast(payload)
    }
    coordinator.start()
    isLive = true
}

/// Mirror the authoritative row onto local state. The index is the source of truth.
private func applyRemoteRow(_ dto: CuratedSessionDTO) {
    if dto.currentIndex != index, hand.indices.contains(dto.currentIndex) {
        index = dto.currentIndex
        advanceInFlight = false
    }
    timerStartedAtRaw = dto.timerStartedAt
    if dto.safeWordUsed, !safeWordUsed { handleRemoteSafeWord() }
    safeWordUsed = dto.safeWordUsed
    isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
    if dto.status == CuratedSessionStatus.complete.rawValue, phase == .session {
        finishSession()   // partner completed → follow to close
    }
}
```

`currentUserId` is `appState`-adjacent; per S2 it should come from the injected auth surface. If plan 08
did not thread a user id into the store, add an injected `currentUserId: UUID?` to the init (defaulted
`nil`) rather than reaching for `AuthService.shared` — services/state are injected, not fetched. Flag this
in Open Decisions.

Now gate the advance. `dealNext()` / `pass()` currently record + `liveAdvance` + `advanceOrFinish()`
(`:189-200`). Change `advanceOrFinish` so that **when live**, it does not bump `index` locally — it lets the
echoed UPDATE do it:

```swift
private func advanceOrFinish() {
    if isLastCard {
        finishSession()
        return
    }
    if isLive {
        // Server-authoritative: the row write (liveAdvance) echoes back an
        // UPDATE that sets `index`. Don't bump locally — that's what keeps two
        // devices in lockstep and lets the conditional update reject a race.
        advanceInFlight = true
    } else {
        index += 1   // pure-local path, unchanged
    }
}
```

`liveAdvance(expectedIndex:)` already issues the conditional update (`:288-293`) and already no-ops when
`realtime == nil`. It returns the `Bool` from `RealtimeSessionService.advance`; a `false` means the partner
already advanced this row, in which case the echoed UPDATE still arrives and drives `index`. No extra work
needed on the losing side — the guard plus the mirror gives exactly-one-advance for free.

Completion already funnels into `persistSession()` via `finishSession()` (`:245-249`), which is correct as
written. **Only the initiator writes** — see Open Decisions for the guard.

**done:** with a service injected, `index` only changes via an echoed `current_index`; with no service,
`dealNext()`/`pass()` bump `index` locally exactly as on `master`; a single-device playthrough still writes
`CardSession`/`CardResult`/`DeckProgress`. Compiles.

---

### Segment D2 — Synced gentle timer

**One thing:** a per-card countdown, identical on both devices, derived from `timer_started_at` +
`per_card_timer[cardId]`; at zero it softly nudges ("wrap up" / "keep going") over Broadcast and **never
auto-advances or hard-cuts.**

**2a. Store — derive remaining, drive a tick.** Add to `CoupleSessionStore`:

```swift
// MARK: - Timer (Seg D2)

/// ISO timestamp the current card's timer started (from the row). nil = no timer running.
private(set) var timerStartedAtRaw: String?
/// Per-card limits, seeded from the plan draft (seconds). Empty = no timers.
private let perCardTimerSeconds: [String: Int]
/// The wall-clock deadline, recomputed when the anchor or card changes.
private(set) var timerRemaining: TimeInterval?
/// True after the timer hit zero for this card (drives the wrap-up nudge, not a cut).
private(set) var timerElapsed = false
private var timerTask: Task<Void, Never>?

private static let iso: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

/// Seconds allotted to the current card, if any.
private var currentCardLimit: Int? {
    guard let id = currentCard?.id else { return nil }
    return perCardTimerSeconds[id]
}

/// Recompute + start ticking whenever the card or anchor changes.
func refreshTimer() {
    timerTask?.cancel()
    timerElapsed = false
    guard let limit = currentCardLimit,
          let raw = timerStartedAtRaw,
          let started = Self.iso.date(from: raw) else {
        timerRemaining = nil
        return
    }
    let deadline = started.addingTimeInterval(TimeInterval(limit))
    timerTask = Task { @MainActor in
        while !Task.isCancelled {
            let remaining = deadline.timeIntervalSinceNow
            timerRemaining = max(0, remaining)
            if remaining <= 0, !timerElapsed {
                timerElapsed = true
                // Soft nudge only — NEVER advance. Tell the other side to chime too.
                coordinator?.send(SessionBroadcast(kind: .timerWrapUp, role: sessionRole.rawValue, text: nil))
                break
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}

/// "keep going" — clear the wrap-up nudge on BOTH devices (the anchor stays; we
/// just stop nagging). Broadcast so the partner's chime clears too.
func keepGoing() {
    timerElapsed = false
    coordinator?.send(SessionBroadcast(kind: .timerKeepGoing, role: sessionRole.rawValue, text: nil))
}
```

Handle the two timer broadcasts in `applyBroadcast(_:)` (added in D3 below): `.timerWrapUp` → set
`timerElapsed = true`; `.timerKeepGoing` → set `timerElapsed = false`.

Wire `refreshTimer()`: call it in `applyRemoteRow` (anchor changed) and on `index` change. The cleanest hook
is a `didSet` on `index` is not possible (`private(set) var`), so call `refreshTimer()` at the end of
`applyRemoteRow`, and once in `startRemoteSync` after subscribe. In the pure-local path there is no anchor,
so `timerRemaining` stays `nil` and the bar renders nothing — correct.

Seed `perCardTimerSeconds` from the draft. `init` currently takes no timer map; add a defaulted param:

```swift
perCardTimerSeconds: [String: Int] = [:],
```
and store it. Plan 09's entry passes the plan's `perCardTimerSeconds`; default empty keeps existing
callers (previews, single-device) compiling.

**2b. View — the ribbon.** `Vayl/Features/Sessions/Components/SessionTimerBar.swift`:

```swift
//
//  SessionTimerBar.swift
//  Vayl
//
//  The synced gentle-timer ribbon. A calm shrinking line + mm:ss; at zero it
//  offers "wrap up" / "keep going" — it NEVER advances the card. Presentation
//  only: reads the store, calls store methods.
//

import SwiftUI

struct SessionTimerBar: View {

    @Bindable var store: CoupleSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let remaining = store.timerRemaining {
            VStack(spacing: AppSpacing.sm) {
                if store.timerElapsed {
                    HStack(spacing: AppSpacing.md) {
                        Text("no rush, wrap up when you're ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            store.keepGoing()
                        } label: {
                            Text("keep going")
                                .font(AppFonts.buttonLabelSmall)
                                .foregroundStyle(AppColors.spectrumText)
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                } else {
                    Text(mmss(remaining))
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
            .animation(reduceMotion ? AppAnimation.fast : AppAnimation.standard, value: store.timerElapsed)
            .padding(.top, AppSpacing.md)
        }
    }

    private func mmss(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
```

Add a **soft chime** at zero. There is no audio-capture involved (a chime is playback, allowed). Use a
`.sensoryFeedback` on the elapsed transition in the player, or `AudioServicesPlaySystemSound` behind a
Reduce-Motion-agnostic gate. Simplest, token-free-safe: `.sensoryFeedback(.impact(weight: .light),
trigger: store.timerElapsed)` on the player root (matches the app's haptic idiom). 🎚️ Whether it's a
haptic tap or an actual chime sound is Bryan's call on device — default to the haptic.

Mount `SessionTimerBar(store: store)` in `SessionPlayerView` at the top of the deck zone (below the fan,
above the prompt), so it reads as ambient, not a countdown clock.

**done:** with a timer set on the row, both devices show the same mm:ss and reach "wrap up" together; "keep
going" clears the nudge on both; nothing auto-advances. With no timer, the bar renders nothing. Compiles.

---

### Segment D3 — One reveal mechanic (Whisper)

**One thing:** on a `.whisper` card, each side types privately (`.screenshotProtected()`), both seal, a
simultaneous 3-2-1 runs on both devices, then answers are exchanged **over Broadcast and never persisted.**

**3a. Store — reveal state + the seal/reveal machine.** Add:

```swift
// MARK: - Whisper reveal (Seg D3 — answers NEVER persisted)

enum RevealPhase: Equatable { case composing, sealed, counting(Int), revealed }
private(set) var revealPhase: RevealPhase = .composing
/// My private answer — @State on the view mirrors this; here only to broadcast at reveal.
var myWhisperText: String = ""
/// The partner's answer — arrives ONLY at reveal via Broadcast. Never stored.
private(set) var partnerWhisperText: String?
private(set) var partnerSealed = false
private var iSealed = false

/// Seal my answer. When both are sealed, run the shared countdown.
func sealWhisper() {
    guard !iSealed else { return }
    iSealed = true
    revealPhase = .sealed
    coordinator?.send(SessionBroadcast(kind: .revealSeal, role: sessionRole.rawValue, text: nil))
    if partnerSealed { beginRevealCountdown() }
}

/// Both sealed → 3-2-1 on both, then exchange answers.
private func beginRevealCountdown() {
    // Only ONE side should drive the countdown broadcast to avoid a double 3-2-1.
    // The initiator (sessionRole == .a) drives; both run the local ticker.
    if sessionRole == .a {
        coordinator?.send(SessionBroadcast(kind: .revealCountdown, role: sessionRole.rawValue, text: nil))
    }
    runCountdownThenExchange()
}

private func runCountdownThenExchange() {
    Task { @MainActor in
        for n in [3, 2, 1] {
            revealPhase = .counting(n)
            try? await Task.sleep(for: .seconds(1))
        }
        // Exchange: broadcast my sealed text; show mine immediately.
        coordinator?.send(SessionBroadcast(
            kind: .revealAnswer, role: sessionRole.rawValue, text: myWhisperText
        ))
        revealPhase = .revealed
    }
}

/// Reset when moving off the whisper card.
private func resetWhisper() {
    revealPhase = .composing
    myWhisperText = ""
    partnerWhisperText = nil
    partnerSealed = false
    iSealed = false
}
```

`applyBroadcast(_:)` — the single broadcast router (also handles the D2 timer kinds):

```swift
private func applyBroadcast(_ payload: SessionBroadcast) {
    // Ignore my own echoes (receiveOwnBroadcasts defaults false, but be safe).
    guard payload.role != sessionRole.rawValue || payload.kind == .revealAnswer else {
        // Never process my own non-answer echoes; my answer echo is also ignored below.
        if payload.role == sessionRole.rawValue { return }
        return
    }
    switch payload.kind {
    case .timerWrapUp:     timerElapsed = true
    case .timerKeepGoing:  timerElapsed = false
    case .revealSeal:
        partnerSealed = true
        if iSealed { beginRevealCountdown() }
    case .revealCountdown:
        if sessionRole != .a { runCountdownThenExchange() }   // follower runs its ticker
    case .revealAnswer:
        partnerWhisperText = payload.text   // held in memory only — never written
    }
}
```

Call `resetWhisper()` from `applyRemoteRow` when the index moves (and in the local path, extend
`advanceOrFinish`'s local branch). **Invariant to encode as a comment and honor:** `partnerWhisperText` and
`myWhisperText` are `@State`/in-memory only. They must never touch `CardResult`, `SessionReflection`, the
`curated_sessions` row, or `enqueueSync`. `persistSession()` writes only `status` (discussed/skipped) — it
already does not touch answer text. Do not add answer text to any persisted model.

**3b. View — the reveal surface.** `Vayl/Features/Sessions/Components/WhisperRevealView.swift`:

```swift
//
//  WhisperRevealView.swift
//  Vayl
//
//  The Whisper reveal (D3). Private input per side, screenshot-protected; both
//  seal; a simultaneous 3-2-1; then answers shown side by side. Answers cross
//  the wire via Broadcast at reveal and are NEVER persisted — held only in the
//  store's in-memory @State. See CoupleSessionStore reveal invariant.
//

import SwiftUI

struct WhisperRevealView: View {

    @Bindable var store: CoupleSessionStore
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            switch store.revealPhase {
            case .composing, .sealed:
                composer
            case .counting(let n):
                Text("\(n)")
                    .font(AppFonts.displayHero)
                    .foregroundStyle(AppColors.spectrumText)
            case .revealed:
                revealed
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("just for this reveal · private until you both seal")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField("type it, then seal…", text: $store.myWhisperText, axis: .vertical)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(3, reservesSpace: true)
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(store.revealPhase == .sealed)
                .screenshotProtected()

            HStack {
                if store.partnerSealed {
                    Text("partner sealed · waiting on you")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.spectrumText)
                } else if store.revealPhase == .sealed {
                    Text("sealed · waiting on partner")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    store.sealWhisper()
                } label: {
                    Text(store.revealPhase == .sealed ? "sealed" : "seal")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
                .disabled(store.myWhisperText.trimmingCharacters(in: .whitespaces).isEmpty
                          || store.revealPhase == .sealed)
            }
        }
    }

    private var revealed: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            whisperBlock("you", store.myWhisperText, tint: AppColors.spectrumMagenta)
            whisperBlock("partner", store.partnerWhisperText ?? "…", tint: AppColors.spectrumCyan)
        }
    }

    private func whisperBlock(_ who: String, _ text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(who)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg)
        )
    }
}
```

In `SessionPlayerView.body`, when `store.currentCard?.type == .whisper`, render `WhisperRevealView(store:
store)` **in place of** the hero prompt/hold-to-deal layer (the reveal replaces the normal deal ceremony for
that one card). After `.revealed`, the normal proceed control returns so the couple advances off it via the
usual `dealNext()`. (`Card.type == .whisper` is a real enum case — `Card.isRevealMechanic`,
`Card.swift:39-46`, and the sample card `opener-10` is a Whisper.)

**done:** on a Whisper card each side types privately; neither text is visible to the other until both seal;
a 3-2-1 runs; answers show side by side; grep confirms no code path writes `myWhisperText` /
`partnerWhisperText` to any `@Model` or the row. Compiles.

---

### Segment D4 — Keep-awake + dim + safety + presence cues

**One thing:** the screen stays awake and dims on idle via `connectedScenes` (not `UIScreen.main`); safe
word "red" sets `safe_word_used` and exits both devices gracefully; pause works; the active-listener role +
soft turn cue render per card.

**4a. Replace the keep-awake with a scene-scoped helper.** `SessionPlayerView.swift:71-78` currently uses
`UIApplication.shared.isIdleTimerDisabled` directly. `isIdleTimerDisabled` on `UIApplication` is not the
banned API (`UIScreen.main`/`keyWindow` are), but the contract (build plan §7, `spec:128`) says do keep-awake
via `connectedScenes`. Resolve the active window scene the same way `ScreenshotProtectionModifier` does
(`:43-51`) and set the scene's behavior there. Concretely, add a small helper and call it on
appear/disappear:

```swift
/// Keep-awake scoped to the foreground window scene (never UIScreen.main).
private func setKeepAwake(_ on: Bool) {
    // The idle timer is an application-level flag; gate it on having an active
    // foreground scene so we only hold the screen while genuinely presented.
    guard UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .contains(where: { $0.activationState == .foregroundActive }) else { return }
    UIApplication.shared.isIdleTimerDisabled = on
}
```

Replace the two call sites (`onAppear` → `setKeepAwake(true)`, `onDisappear` → `setKeepAwake(false)`). The
idle **dim** overlay already exists (`SessionPlayerView.swift:61-67, 471-486`) and is correct — leave it.

**4b. Safe word "red" + pause.** Add store methods:

```swift
// MARK: - Safety (Seg D4)

private(set) var safeWordUsed = false
private(set) var isPaused = false

/// Safe word "red" — the hard stop. Sets the row flag, ends gracefully on both.
func raiseSafeWord() {
    safeWordUsed = true
    if let realtime, let sid = remoteSessionId {
        Task { @MainActor in try? await realtime.setSafeWord(sessionId: sid) }
    }
    // Graceful dual exit: record the current card as skipped and close cleanly.
    endEarly()   // already: records skipped → finishSession → .close
}

/// A remote device raised "red" — follow to a clean close.
private func handleRemoteSafeWord() {
    guard phase == .session else { return }
    endEarly()
}

/// Pause holds the room on both devices (status → paused / active).
func togglePause() {
    isPaused.toggle()
    guard let realtime, let sid = remoteSessionId else { return }
    let status: CuratedSessionStatus = isPaused ? .paused : .active
    Task { @MainActor in try? await realtime.setStatus(sessionId: sid, status: status) }
}
```

`RealtimeSessionService` has no `setSafeWord` yet — add a one-column mutator mirroring `setStatus`
(`RealtimeSessionService.swift:230-236`):

```swift
/// Sets safe_word_used = true (one-way — the session's hard stop).
func setSafeWord(sessionId: UUID) async throws {
    try await supabase
        .from(SupabaseTable.curatedSessions)
        .update(["safe_word_used": true])
        .eq("id", value: sessionId.uuidString)
        .execute()
}
```

The row's `safe_word_used` flip echoes back through the UPDATE stream; `applyRemoteRow` (D1) already calls
`handleRemoteSafeWord()` when it sees `dto.safeWordUsed` go true. That is the dual exit.

**4c. Surface safe word + pause + listener cue in the player.** The care sheet already has "Pause" and "End
well" (`SessionPlayerView.swift:363, 376-379`). Add a distinct, unmissable **safe-word** affordance to the
care sheet (or the controls) that says "red" plainly and calls `store.raiseSafeWord()`, styled with
`AppColors.safetyAccent` per `SafeWordButton`. Wire the existing "Pause" care option to `store.togglePause()`
instead of just dismissing the sheet.

Active-listener role + turn cue: the drawer already alternates (`store.currentDrawer`,
`CoupleSessionStore.swift:147`) and the drawer row renders "Your draw / Partner's draw"
(`SessionPlayerView.swift:146-167`). Add the **complement** as the listener cue — a soft line under the
drawer row:

```swift
Text(store.currentDrawer == .you ? "partner is listening" : "you're listening, reflect it back")
    .font(AppFonts.caption)
    .foregroundStyle(AppColors.textTertiary)
```

This is the "active-listener role + soft per-card turn cue" the roadmap asks for — no new state, derived
from the existing drawer.

**done:** the screen stays awake and dims on idle (via `connectedScenes`); a safe-word affordance is
present and unmissable; "red" sets `safe_word_used`, records the card skipped, and lands both devices in the
close; pause toggles `status`; each card shows who draws and who listens. Compiles.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

1. **Local path unchanged.** With no `RealtimeSessionService` injected (`realtime == nil`, the default),
   `CoupleSessionStore` behaves exactly as on `master`: `dealNext()`/`pass()` bump `index` locally, the
   airlock mock partner works, a full playthrough writes `CardSession` + `CardResult` + `DeckProgress` via
   `persistSession()` → `saveWithLogging()` + `enqueueSync`. **This is the DoD anchor.**
2. **Lockstep wiring compiles.** `SessionSyncCoordinator` subscribes the channel (streams registered before
   `subscribeWithError()`, `track` after), pumps UPDATE/presence/Broadcast to the store; when live, `index`
   changes only via an echoed `current_index`; `dealNext`/`pass` set `advanceInFlight` instead of bumping.
3. **Advance guard present.** Advance routes through `RealtimeSessionService.advance(sessionId:expectedIndex:)`
   (conditional `.eq("current_index", expectedIndex)`); the losing side of a race still lands on the right
   card via the echo.
4. **Timer.** `timerRemaining` derives from `timer_started_at` + `per_card_timer[cardId]`; at zero →
   soft nudge + "keep going" over Broadcast; **no auto-advance / hard-cut** anywhere.
5. **Whisper.** Private per-side input is `.screenshotProtected()`; both-seal → 3-2-1 → answers over
   Broadcast; a grep of the reveal fields (`myWhisperText`, `partnerWhisperText`) shows **zero** writes to
   any `@Model`, the row, or `enqueueSync`.
6. **Safety.** Keep-awake + dim via `connectedScenes` (no `UIScreen.main`); `raiseSafeWord()` sets
   `safe_word_used` and closes both sides; pause toggles `status`; listener/turn cue renders per card.
7. **Contracts.** No raw tokens in the new views; `.vaylSheet`/`.vaylCover` only; Reduce-Motion honored on
   the new animated bits; no mic/audio capture; `couple_session_records` untouched; no `VaylCardFace` shell
   edits.

---

## Bryan verifies on device (the two-device / feel checklist)

These need two phones — a build cannot prove them:

- [ ] **Lockstep.** Device A holds-to-deal; Device B's card advances to the same prompt within ~1s.
- [ ] **No double-advance.** Both tap advance at the same instant on the same card → the couple moves
      forward exactly one card (not two). Repeat a few times.
- [ ] **Partner-completes-follows.** A finishes the last card → B lands in the close too; exactly one
      `CardSession` is written (the initiator's), not two.
- [ ] **Timer sync.** With a per-card timer set, both phones show the same mm:ss; both reach "wrap up"
      together; "keep going" on one clears the nudge on both; nothing ever auto-advances. 🎚️ Chime vs
      haptic at zero — pick the feel.
- [ ] **Whisper.** Both type privately; neither sees the other before both seal; 3-2-1 fires on both at
      once; answers appear side by side; confirm nothing about the answers shows up later in Map/history.
- [ ] **Safe word.** One side raises "red" → both land gracefully in the close; the row's `safe_word_used`
      is true in the dashboard.
- [ ] **Pause.** Pause on one holds the room on both; resume restores.
- [ ] **Keep-awake / dim.** Screen never sleeps mid-session; dims after idle; a tap restores. 🎚️ idle-dim
      delay (default 3.6s) and dim opacity (default 0.52).
- [ ] **Presence.** Presence dots reflect the real partner join/leave, not the mock.

---

## Constraints / do-not-touch

- **Player only.** Do not touch the airlock's sync-ring mechanic, the close/reflection, or the carousel
  entry beyond what D1–D4 name. The airlock's mock partner presence stays for the pure-local path; when
  live, `partnerPresentLive` supersedes it — do not rip the mock out.
- **Never touch `couple_session_records` or `SessionSyncService`** (that is the legacy completed-session
  sync; the live row is `curated_sessions`). `persistSession()`'s `enqueueSync` already routes there and is
  correct — leave it.
- **No `UIScreen.main` / `keyWindow`.** Resolve scenes via `connectedScenes` (mirror
  `ScreenshotProtectionModifier`).
- **No mic / audio capture.** A soft chime is playback, allowed; do not add any `AVAudioRecorder` /
  input-tap / diarization.
- **Reveal answers must never persist.** `myWhisperText` / `partnerWhisperText` are in-memory only. Not in
  `CardResult`, not in `SessionReflection`, not in the row, not in `enqueueSync`. This is a privacy
  invariant, not a nicety.
- **No new migration.** Every column S4 uses (`current_index`, `timer_started_at`, `per_card_timer`,
  `safe_word_used`, `status`) already exists in the baseline.
- **`persistSession()` shape is frozen.** Do not restructure the save; only ensure the two-device path
  reaches it once (initiator).
- **`VaylCardFace` shell** untouched; `.drawingGroup()` stays; onboarding untouched.

---

## Open decisions (each with a default so you are never blocked)

1. **Who writes `CardSession` on completion?** Both devices reach `.close`, but only one should persist to
   avoid a duplicate couple session. **Default: the initiator (`sessionRole == .a`) writes; the follower
   skips `persistSession()` when live** (guard `persistSession` with `if isLive && sessionRole != .a {
   return }`). In the pure-local path (`!isLive`) it always writes. Flag for Bryan — the alternative is a
   server-side de-dupe, out of scope here.
2. **Where does `currentUserId` come from?** The store needs the signed-in user id to key presence and to
   tell "partner present" from "me". **Default: add an injected `currentUserId: UUID?` param to
   `CoupleSessionStore.init` (defaulted `nil`), passed from plan 09's entry (which has `AuthService.userId`
   in hand).** Do not reach for a singleton. If 09 already threads it, use that.
3. **Countdown driver for the reveal.** Two devices both firing a 3-2-1 broadcast could double-drive.
   **Default: the initiator (`.a`) broadcasts `revealCountdown`; both run their local ticker; the follower
   starts its ticker on receipt.** Small clock skew is acceptable (it's a shared breath, not a race).
4. **Chime vs haptic at timer zero.** **Default: `.sensoryFeedback(.impact(weight: .light))` haptic** (the
   app's established idiom, no new asset). Bryan can swap to a real chime sound on device — mark 🎚️.
5. **`UpdateAction` decode surface.** supabase-swift 2.48.0's exact `UpdateAction` → `Codable` decode helper
   may differ from `decodeRecord(as:decoder:)`. **Default: try `decodeRecord`; if the checked-out signature
   differs, decode the record `JSONObject`/`AnyJSON` manually into `CuratedSessionDTO` and keep the DTO
   shape.** Note any drift inline.
6. **Timer seed source.** `perCardTimerSeconds` is seeded from the plan draft. Until plan 09 threads a real
   plan in, **default: empty map (no timers), so the timer bar renders nothing** — the single-device DoD is
   unaffected.
