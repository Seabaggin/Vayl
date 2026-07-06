# Vayl — Couple Curated-Session System (Segmented Build Plan)

## Context

Onboarding is ~90% done; this builds the Card/Deck **session** system (couple-first; solo derived later). Exploration showed the **data layer already exists** (`Card`, `Deck`, `DeckProgress`, `CardSession`, `LockInSession`, `Couple`, `ContentLoader`, `CardCarousel`, a thin `SessionStore`/`SessionView`). The real work is the **experience flow** + the **two-device real-time tissue** — and real-time is new to this stack (it has only ever polled). So the sequence below **de-risks real-time first**, then layers UI, Player, Builder, and post-session.

Reconciled with two existing specs: the **Deck Content Bible** (deck anatomy, living-card taxonomy = the `CardType` enum, 32-deck slate, the Play-tab-is-generative rule) and the **LDR & Remote Session Architecture** (Supabase Realtime transport, "Lock In" handshake, Dynamic Island/Live Activities, session-link invites).

Each segment below is: **Does** (one thing) · **Build** · **Done** (verified on device/sim or Supabase dashboard — *not* "build succeeds") · **May not touch** (constraints). A segment is complete only when its Done condition is observed.

---

## Foundations (reference the segments build on)

**Session model:** a deck played in its **authored recommended order** (opening ritual → cards → closing ritual) by default; the user may **reorder/trim** (not forced). Optional **gentle per-card timers**, synced + server-authoritative (nudge, never hard-cut). **One Airlock** per session. **Couple-owned, server-authoritative** (no party leader). Entry lives on **Home / Deck Library** (Play = generative tools, off-limits here).

**Data shapes:**
- `SessionPlan` (new SwiftData `@Model`): `id, coupleId?, deckId, deckVariant?, title, orderedCardIds (defaults to deck.orderedCards), perCardTimerSeconds, globalTimerSeconds?, isPreset, isLDR, createdAt, lastUsedAt?`.
- `curated_sessions` (new Supabase table, authoritative live row): `id, couple_id, initiator_id, deck_id, deck_variant, card_ids(jsonb), per_card_timer(jsonb), global_timer_seconds, status(lobby/airlock/active/paused/complete/abandoned), current_index, a_present, b_present, a_bandwidth, b_bandwidth, a_consented, b_consented, timer_started_at, reveal_state(jsonb), safe_word_used, created_at, updated_at`. Partial unique index on `couple_id WHERE status IN ('lobby','airlock','active','paused')`.
- **Answer privacy:** reveal answers ephemeral (Broadcast at reveal); memory cards (Echo/Callback/Time Capsule) persist **with consent** — content-track, not core.

**Verified Realtime API (supabase-swift 2.41.1):** `client.channel("session:<coupleId>") { $0.presence.key = userId }`; register `postgresChange(UpdateAction.self, table:"curated_sessions", filter:.eq("couple_id",…))`, `presenceChange()`, `broadcastStream(event:)` **before** `subscribeWithError()`; `track(_:)` only **after** subscribed; `broadcast(event:message:)`; `unsubscribe()`+`removeChannel()` to tear down. Anon key works for the spike; tighten RLS before ship; `receiveOwnBroadcasts` defaults false.

**Reuse templates:** `PairingStore` (state-machine + `pollTask` + `reset`/`teardown`), `PairingService.pollForClaim` (poll loop), `HomeRouterView` (`.sheet(item:)` + Store-in-view), `SessionStore.saveSession()` (SwiftData write), `LockInSession` (bandwidth), `ScreenshotProtectionModifier` (`connectedScenes` for keep-awake/dim).

**Global constraints (every segment):** 4-layer (View→Store→Service→Model; Services never import Views/Stores; Stores make fresh `ModelContext` at write time). Design tokens only — no raw colors/fonts/spacing/radius; `.cardStyle()`/`.themedCard()`/`SpectrumHairline` (NOT `.glassCard()`/`.hairline()`/`AtmosphereView` — they don't exist). No `UIScreen.main`/`keyWindow` (iOS-26 banned). **Never touch:** Onboarding (`Vayl/Features/Onboarding/**`), `VaylCardFace` shell, `VaylCardModel`, `couple_session_records`/`SessionSyncService` (legacy), `PlayView` (reserved for generative).

---

## Phase A — Data & schema groundwork

**A1 · SessionPlan model + schema registration**
- *Does:* Add the `SessionPlan` `@Model` and register it.
- *Build:* `Vayl/Features/Sessions/SessionPlan.swift` (+ `SessionPlan.stub` factory: `the-opener`, 3 ids); add `SessionPlan.self` to `SchemaV1.models` in `Vayl/App/ModelContainer.swift`.
- *Done:* App launches with no migration crash; a debug call creates + fetches `SessionPlan.stub` in SwiftData (console-verified).
- *May not touch:* existing model fields; any View; any Service.

**A2 · `curated_sessions` table + RLS + Realtime publication (Supabase)**
- *Does:* Create the live-session table, RLS, and enable realtime for it.
- *Build:* SQL for the table + partial unique index + RLS (couple-members only) + add to publication `supabase_realtime`. Save as a versioned migration file (schema is currently un-versioned).
- *Done:* From the dashboard, insert a row for a test couple; confirm RLS allows the couple and the table appears under Realtime. (No Swift yet.)
- *May not touch:* other tables; any Swift.

**A3 · `RealtimeSessionService` — row CRUD (no realtime channel yet)**
- *Does:* Service can open/fetch/mutate a session row over Supabase REST.
- *Build:* `Vayl/Core/Services/RealtimeSessionService.swift` with `CuratedSessionDTO`/`SessionPresence`; methods `openSession`, `fetchOpenSession`, `setBandwidth`, `setConsent`, `setStatus`, `advance(sessionId:expectedIndex:)` (conditional update).
- *Done:* A temporary debug trigger runs `openSession` (lobby row appears in dashboard), `fetchOpenSession` returns it, mutators change it (dashboard-verified). Async/await only.
- *May not touch:* realtime channel APIs (next phase); Stores; Views beyond a temporary debug button; pairing code.

## Phase B — Real-time handshake (the risky core, de-risked in testable bits)

**B1 · Channel + presence ("both here")**
- *Does:* Subscribe to a per-couple channel; track + observe presence.
- *Build:* `channel(coupleId:)` + presence helpers in `RealtimeSessionService`; a debug presence indicator.
- *Done:* Two devices/sims in one couple each see the other join (presence `joins`), and `leaves` on teardown — console/indicator verified.
- *May not touch:* row/session logic; production UI.

**B2 · Postgres-changes subscription (shared row state)**
- *Does:* Stream `curated_sessions` UPDATEs for the couple, decoded to DTO.
- *Build:* `sessionRowUpdates(coupleId:)` (listener registered before subscribe).
- *Done:* Device A mutates the row (A3 methods); Device B receives the update within ~1s and logs new state.
- *May not touch:* Airlock UI; advance-conflict logic.

**B3 · AirlockStore state machine (debug UI)**
- *Does:* Orchestrate `lobby → airlock → active` from presence + row updates + service.
- *Build:* `Vayl/Features/Sessions/AirlockStore.swift` (`@Observable @MainActor`, `AirlockState` enum, tasks) modeled on `PairingStore`; role A/B via `Couple.partnerAId == myUserId`; idempotent active-flip when both present + both consented.
- *Done:* On two devices via a debug UI: initiator→lobby, partner sees pending, both present, both bandwidth+consent, row flips `active` **exactly once**, both Stores reach `.active`.
- *May not touch:* Player; Builder; production Airlock visuals (debug only).

**B4 · Poll fallback**
- *Does:* Complete the handshake when Realtime is unavailable.
- *Build:* `pollOpenSession` (per `PairingService.pollForClaim`) + `a_present/b_present` heartbeat mirror; `AirlockStore` switches to poll on subscribe failure.
- *Done:* With Realtime disabled (force-fail/network toggle), two devices still complete the handshake via poll; presence falls back to row booleans.
- *May not touch:* the realtime path (no regression); production UI.

## Phase C — Entry + Airlock UI

**C1 · Home / Deck Library entry + pending-session banner**
- *Does:* Real entry (start stub session) + partner pending banner.
- *Build:* entry on the Home/Deck Library surface; `fetchOpenSession` on `.task`/`scenePhase==.active`; present via `.sheet(item:)` (per `HomeRouterView`).
- *Done:* Device A starts from Home; Device B's Home shows a pending banner that opens the lobby.
- *May not touch:* `PlayView`; Player logic; Builder.

**C2 · Lobby + Airlock real UI (bandwidth + consent)**
- *Does:* Replace debug UI with real `SessionLobbyView` + `AirlockView`.
- *Build:* lobby shows session shape to consent to; Airlock shows presence "both here" + bandwidth sliders + ~3s hold + consent; `.screenshotProtected()`; persist bandwidth via `LockInSession`.
- *Done:* Two devices run the full Airlock with real UI to `active`; `LockInSession` rows written.
- *May not touch:* Player internals (navigate to a placeholder "active" screen); design-token rules.

## Phase D — Player core

**D1 · Synced card display + advance**
- *Does:* Both devices render the same card; advance is server-authoritative.
- *Build:* `Vayl/Features/Sessions/CuratedPlayerStore.swift` + extend `SessionView`; render `card_ids[current_index]` from the update stream; Next/Skip → `advance` (conditional update); completion writes `CardSession` via the `saveSession` pattern.
- *Done:* Two devices show the same stub card; either advances; both move together; simultaneous taps don't double-advance; completion persists `CardSession`/`CardResult`/`DeckProgress`.
- *May not touch:* timers/reveal (next); Airlock; `couple_session_records`.

**D2 · Synced gentle timer**
- *Does:* Per-card countdown, synced; soft end, never hard-cut.
- *Build:* derive remaining from `timer_started_at`+`per_card_timer`; soft chime + "wrap up" + "keep going" (clears anchor) via Broadcast.
- *Done:* Both devices show the same countdown; at zero → chime + "wrap up" (no auto-advance); "keep going" clears on both.
- *May not touch:* force-advance behavior; reveal logic.

**D3 · One reveal mechanic (Whisper)**
- *Does:* Private text → both seal → simultaneous reveal.
- *Build:* use `reveal_state` flags + a "3-2-1" Broadcast; answers exchanged at reveal, not stored.
- *Done:* Two devices type privately; neither sees the other until both seal; simultaneous reveal with countdown; answers not persisted.
- *May not touch:* other living-card mechanics (pending content); answer persistence.

**D4 · Keep-awake + dim + safety + balance cues**
- *Does:* Presence-respecting screen behavior + safety + balance.
- *Build:* dim overlay + idle-timer-off via `connectedScenes`; safe word "red" (sets `safe_word_used`, graceful dual exit) + pause; render active-listener role + soft turn cue per card.
- *Done:* Screen stays awake, dims after inactivity, restores on tap; "red" ends the session on both devices; pause works; cues render per card.
- *May not touch:* `UIScreen.main`; any mic/audio capture.

## Phase E — Builder + fast paths

**E1 · Authored-order session (replace the stub)**
- *Does:* Produce a real `SessionPlan` from a deck's authored order.
- *Build:* `Vayl/Features/Sessions/SessionBuilderStore.swift` + `SessionBuilderView.swift`; seed `orderedCardIds` from `deck.orderedCards` (rituals included); `openSession` snapshots it.
- *Done:* Build + play a real "the-opener" session in authored order, replacing the stub, with **zero** transport/Airlock changes.
- *May not touch:* the transport/Airlock interfaces; multi-deck.

**E2 · Reorder/trim + per-card timers + settings**
- *Does:* Let the user customize without feeling forced.
- *Build:* reorder/drop cards (authored order is the default); per-card/global timers; global settings (depth ceiling, together/apart→`isLDR`, sensitive, safe word); live time estimate; soft over-length nudge + opt-in firm cap.
- *Done:* A custom session reflects the user's order/timers/settings in the Player; rituals remain by default; the cap nudge fires when long.
- *May not touch:* authored-order default behavior; fast paths (next).

**E3 · Fast paths**
- *Does:* Quick / Save & reuse / Same-as-last / Presets.
- *Build:* quick auto-pick (by depth+length); save persists a `SessionPlan`; same-as-last reuses by `lastUsedAt`; presets clone authored decks.
- *Done:* Each fast path produces a valid `SessionPlan` that plays identically downstream.
- *May not touch:* the Player/Airlock.

## Phase F — Post-session

**F1 · Reflection + bandwidth capture + progress**
- *Does:* Close the loop after the last card.
- *Build:* post-session screen; capture reflection + per-partner bandwidth into `CardSession`; update progress; offer save/reuse.
- *Done:* Completing a session shows post-session; data persists; progress reflects it.
- *May not touch:* LDR/notifications.

## Phase G — Later (deferred / content-gated)

**G1 · LDR & presence surfaces** — session-link deep-link invites (iMessage/Discord); Live Activities / Dynamic Island (`VaylSessionAttributes`) incl. **evaluating the "eyes-up" presence mode as a possible default for all couples**; SharePlay; push/APNs. (Decision on DI-as-default happens here, after the Player exists.)

**G2 · Solo derivation** — derive the solo experience from the couple model.

**G3 · Full living-card engine** — the remaining mechanics (emotional-temperature, playful, memory with consented persistence + scheduled notifications, real-time co-creation: Word Cloud/Shared Canvas/Spectrum). **Gated by the content track** — scope decided once more decks are authored.

---

## Parallel content track (you, not engineering)
Author decks per the Content Bible: 32-deck slate, Act-1 launch list, the 4 content tests (Bar/Dual-Register/Non-Assumption/Temporal), the temporal framework, dual registers, gendered His/Her cards + variants. **Gates Phase G3** but **does not block A–F.** Resolve the naming nit: Bible "The Starting Line" vs code `"the-opener"`.

## Future (post-core)
Web companion (Act 2), iPad target, multi-person decks ("Additional Connection" $7.99), opt-in private post-session talk-balance sensing (only if on-device diarization becomes reliable).

## Risks & prerequisites
1. **RLS + anon key:** `curated_sessions` RLS must fit the connecting role; tighten to the couple's two ids before ship; reveal answers unreadable pre-reveal. **A2 (table + RLS + publication) is a hard prerequisite** for Phase B.
2. **Un-versioned schema:** capture A2 as a migration to avoid drift.
3. **Two-device sim limits:** Sign-in-with-Apple flaky in Simulator; de-risk Phase B on the anon key; final handshake on ≥1 physical device.
4. **Conflict/listener ordering:** conditional-update advance guard; register listeners before subscribe; `track` after subscribe.
5. **`AppShell` uses local `@State selectedTab`** (not `appState.selectedTab`) — may need wiring to route a partner into a pending session (C1).
6. **Don't build on `SyncManager`'s 1s launch `Task.sleep`** — drive session realtime from the View's `.task`/`scenePhase`.
7. **Phase G3 scope is content-gated** — don't over-build the Player before content exists.
