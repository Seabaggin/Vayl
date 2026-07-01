# Card Sessions Front-to-Back: Master Spec

**Date:** 2026-07-01
**Status:** Approved design, ready for writing-plans
**Supersedes:** fable-plans 08 (realtime handshake), 09 (entry + airlock UI), 10 (player core), 11 (session builder). Mark all four SUPERSEDED in `docs/fable-plans/00-INDEX.md` pointing here.
**Build mode:** Fable one-shot (ONE-SHOT LICENSE applies; segment pacing rule overridden per portfolio convention).
**Source docs reconciled:** "Vayl: Card Architecture Handoff", "Vayl: Living Card Library", "Vayl: Deck Architecture & Content Bible" (all April 25, 2026), plus `docs/roadmap/vayl-build-roadmap.html` sessions phase.

---

## 1. Goal

A paired couple plays the card game front to back on two devices:

Play tab → deck detail → shape tonight's session (builder or fast path) → lobby/invite → Lock In (airlock) on both devices → play through discussion cards, context beats, card backs, reveal-core living cards, local living cards, with synced timer, safe word, and pause → close with private reflection + bandwidth capture feeding Pulse → deck position persists → next sitting resumes where they left off.

Plus: all 12 launch decks fully authored to Opener quality.

### Out of scope (explicit)

- Solo lane (SoloSession, solo-prep deck): Act 2 per V1 positioning. `solo-prep` leaves the couple catalog.
- Shared Creation cards (sharedCanvas, spectrum, wordCloud): deferred, remain enum-only.
- Memory & Time cards (timeCapsule, echo, callback, beforeAfter): deferred, need persistence + scheduled notifications.
- M/M and F/F gendered card copy variants: follow-up content pass (bible says research first); `flexible` variant serves those couples until then.
- Live Activities / Dynamic Island, SharePlay/iMessage invites, push notifications.
- Single-device "couch mode": couple sessions are strictly two-device. The current mocked-partner local flow survives only behind DEBUG/preview.

---

## 2. Decisions log

| # | Decision | Choice |
|---|---|---|
| D1 | Living card scope | Reveal core (whisper, unspoken, mirror, snapshot, whatIf) + local no-sync cards (dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause). Shared Creation + Memory/Time deferred. |
| D2 | Content scope | Full bible launch slate: 12 decks, full copy, catalog re-cut. |
| D3 | Plan shape | One master spec; fable-plans 08-11 superseded. |
| D4 | Device model | Two-device required. Realtime handshake always; poll fallback on realtime failure. |
| D5 | Composition | `connectionComposition` added to Couple + remote couples table; derived from both partners' OB gender answers, one-tap confirm at pairing, `flexible` fallback. |
| D6 | Reveal sync | Hybrid: seal/reveal FLAGS in `curated_sessions.reveal_state` jsonb (reconnect-safe); answer PAYLOADS Broadcast-only, ephemeral, never persisted. |
| D7 | Advance authority | Server-authoritative `current_index`; either partner may advance; both devices follow the row. |
| D8 | Free tier | the-opener + the-check-in free; other 10 decks Core-locked ($24.99 couple lifetime per monetization spec). |

---

## 3. Current state (what exists, verified 2026-07-01)

**Built:** Card/Deck/CardSession/CardResult/DeckProgress/LockInSession/SessionReflection/Couple models; CardType enum with all 23 variants; 14 deck JSON files (the-opener full at 10 cards, rest 1-3 card stubs); `curated_sessions` table (RLS, one-open-per-couple partial unique index, realtime publication, REPLICA IDENTITY FULL); `RealtimeSessionService` row CRUD + channel factory; single-device local session flow (CoupleSessionStore airlock→transition→session→close→done, AirlockView, SessionPlayerView, SessionCloseView) launched via `.vaylCover` from a real PlayView (masthead, hero, deck wall, detail, ceremony, paywall).

**Stubbed:** `CoupleSessionStore.startRemoteSync()` (TODO), postgres-changes/broadcast stream consumers, AirlockStore, SessionLobbyView, all reveal views, SessionTimerBar, SessionBuilderStore/View.

**Known drifts folded into this spec (section 10):** AppShell dead tab wiring; PlayStore never reads EntitlementStore; solo-prep locked/free copy contradiction; dead content files.

---

## 4. Architecture

Standard 4-layer. No View touches a Service; Stores own decisions; RealtimeSessionService stays store-ignorant.

### 4.1 Models

**Unchanged:** Card, Deck, CardSession, CardResult, DeckProgress, LockInSession, SessionReflection, SoloSession (untouched, out of scope).

**Couple (extend):**
- `connectionComposition: GenderDynamic` (mf | mm | ff | flexible), default `.flexible`.
- Remote: `couples.connection_composition text` column, same CHECK set, migration in section 8.
- Set at pairing: derived from both partners' OB gender answers; the second-to-link partner sees a one-tap confirm ("Playing as: you two" style, wayfinding not identity per product principles); either can change it later in Settings.
- Consumed by `Deck.cards(for:)` (already built) to filter gendered cards.

**SessionPlan (new struct, `Core/Models/SessionPlan.swift`):**
```swift
struct SessionPlan: Codable, Sendable {
    let deckId: String
    let cardIds: [String]          // tonight's order, subset allowed
    let perCardTimerSeconds: [String: Int]?   // nil = untimed card
    let globalTimerSeconds: Int?   // nil = no session budget
    let deckVariant: String?       // nil = authored order
}
```
Maps 1:1 onto the existing `card_ids` / `per_card_timer` / `global_timer_seconds` / `deck_variant` columns.

**RevealEnvelope (new struct, `Core/Models/RevealEnvelope.swift`):** the Broadcast payload for reveal mechanics.
```swift
struct RevealEnvelope: Codable, Sendable {
    let cardId: String
    let role: SessionRole          // sender
    let body: Body
    enum Body: Codable, Sendable {
        case text(String)          // whisper, whatIf, mirror answers
        case position(Double)      // unspoken slider 0.0-1.0
        case word(String)          // snapshot single word
    }
}
```
Never persisted. Sent only after local seal; buffered in the store until reveal fires.

### 4.2 Service layer

`RealtimeSessionService` (extend, no new service):
- Existing CRUD kept: openSession, fetchOpenSession, setBandwidth, setConsent, setStatus, advance.
- New row ops (all merge-writes, never whole-column overwrite):
  - `setSealed(sessionId:cardId:role:)` merges `{cardId: {"<role>_sealed": true}}` into `reveal_state`.
  - `setRevealed(sessionId:cardId:)` merges `{cardId: {"revealed": true}}`.
  - Merge via a single `update_reveal_state` Postgres function (section 8) so concurrent seals from both partners cannot clobber each other. Client sends only its delta.
- New streams (async sequences the coordinator consumes):
  - `presenceChanges(on:)` joins/leaves.
  - `rowUpdates(on:)` postgres-changes UPDATE on curated_sessions filtered by id, decoding the full DTO **including `reveal_state`** (DTO gains that field).
  - `revealBroadcasts(on:)` broadcast stream decoding RevealEnvelope.
  - `sendReveal(_:on:)` broadcast send.
- Identity rule (hard): `SessionRole` derives from `couple.partnerAId == myProfileId` where `myProfileId` is local SwiftData `UserProfile.id`. Never `supabase.auth.session.user.id`.

### 4.3 Stores

**AirlockStore (new, `Features/Sessions/AirlockStore.swift`)** — the handshake, absorbing plan 08:
- States: `waitingForPartner → bothPresent → bandwidthSet(mine) → consented(mine) → activating → active` plus `failed(reason)`.
- Inputs: presence stream, rowUpdates, own UI actions (bandwidth slider commit, consent tap).
- Flip to active: when the row shows both `*_present` and both `*_consented`, EITHER device calls `setStatus(.active)`; the write is idempotent and the partial unique index makes duplicates harmless. Both devices react to the row UPDATE, never to their own optimistic write.
- Poll fallback: if channel subscribe fails or no presence event within 10s, fall back to polling `fetchOpenSession(coupleId:)` every 2s; same state machine, worse latency, identical behavior.
- Presence heartbeat: on channel join also write `*_present = true`; on clean exit write false.

**CoupleSessionStore (extend)** — the player:
- `startRemoteSync()` implemented via a new `SessionSyncCoordinator` (plain helper class owned by the store, `Features/Sessions/SessionSyncCoordinator.swift`): owns channel lifecycle (subscribe, track presence, leave), fans the three streams into async loops, pumps typed deltas back to the store on the MainActor. Coordinator has no UI knowledge; store makes all decisions.
- Advance: user taps continue → store calls `advance(sessionId:to:)` (server-side `current_index` write) → BOTH devices move on the row UPDATE. Local optimistic advance allowed with rollback if the row disagrees (last write wins; index only moves forward).
- Timer: `timer_started_at` + the plan's per-card seconds define the deadline; each device computes remaining locally from the shared timestamp (no tick sync). At zero: soft chime + "wrap up / keep going" affordances; "keep going" clears the card's timer for both (row write nulls that card's entry).
- Pause: either partner; `setStatus(.paused)`; player dims with a held state; resume flips back to `.active`.
- Safe word: a discreet always-available control (uses `couple.sharedSafeWord` for its label); tap → `setStatus(.abandoned)` + `safe_word_used = true`; both devices exit immediately to a neutral, no-guilt close screen; no reflection prompt, no progress penalty beyond cards already recorded.
- Partner presence loss mid-session: after a 15s grace, auto `paused` + banner ("waiting for <name>"); their return resumes.
- Reconnect/app kill: on cover appear with no live channel, `fetchOpenSession(coupleId:)`; if an open row exists, rebuild state from the row (status, current_index, reveal_state) and resubscribe. In-flight broadcast answers lost pre-reveal cause the reveal card to re-prompt compose (seal flags reset for that card via merge-write); copy acknowledges it plainly ("that one got lost in the air, type it again").
- Persistence at close (already built, kept): CardSession + CardResults + LockInSession + SessionReflection + DeckProgress.currentCardIndex/lastPlayedAt; bandwidth feeds Pulse as today.

**RevealEngine (new, owned by CoupleSessionStore, `Features/Sessions/RevealEngine.swift`)** — ONE state machine serving all five reveal mechanics:
- States: `composing → sealedMine → bothSealed → countdown(3-2-1) → revealed`.
- My seal: freeze input, `setSealed`, send RevealEnvelope over broadcast, hold payload locally too.
- Partner seal: seen via rowUpdates (`reveal_state[cardId].<other>_sealed`). Partner payload: buffered from broadcast whenever it arrives (may precede or follow the flag; engine requires flag AND payload before `bothSealed`; if flag set but payload missing after 5s, request a re-send via a lightweight `resend(cardId)` broadcast).
- Both sealed → auto countdown → simultaneous reveal on both screens → `setRevealed`.
- Reconnect: flags from the row restore the phase; missing partner payload triggers the resend path; if the partner is gone, the grace-pause takes over.
- Mechanic-specific bodies only differ in compose UI and reveal presentation; the engine is identical. whatIf = whisper with different framing copy.

**SessionBuilderStore (new, `Features/Sessions/SessionBuilderStore.swift`)** — absorbing plan 11:
- Input: a Deck (already composition-filtered). Output: a `SessionPlan`.
- Default: authored order, untimed, full remaining hand (from DeckProgress.currentCardIndex).
- Tools: reorder, trim (min 3 cards; closing ritual cannot be trimmed if present in tonight's slice), per-card or global timer.
- Fast paths: "Quick start" (defaults, one tap), "Same as last time" (persist last SessionPlan per deck in UserDefaults keyed by deckId).
- Handoff: builder output goes to `openSession` (writes the plan columns) then into the lobby.

**PlayStore (extend):** observes `EntitlementStore`; lock state recomputes live (fixes the unlock-after-purchase drift). Begin flow becomes: detail → ceremony → **builder (or fast path)** → lobby, replacing the direct hand-capture.

### 4.4 Views

All presentation through `.vaylCover` for the session (protected, confirm-on-exit), tokens only, standard background/card/tap contracts. New/changed:

| View | Job |
|---|---|
| `SessionBuilderView` | Plan shaping + fast paths; sheet-hosted inside the pre-session flow |
| `SessionLobbyView` | Initiator waits, session shape summary, cancel; joiner arrives here from the banner |
| Joiner entry banner | On Home + Play while a row sits in `lobby`/`airlock` for your couple: "<name> set up a session" → join |
| `AirlockView` (make real) | Existing UI rewired from mocked presence to AirlockStore |
| `SessionTimerBar` | Deadline countdown from `timer_started_at`; chime + wrap-up/keep-going |
| `WhisperRevealView` | Compose (`.screenshotProtected()`) → seal → 3-2-1 → side-by-side reveal, color-coded per partner; whatIf reuses with its framing |
| `UnspokenSliderView` | Slider compose → seal → reveal both positions on one spectrum |
| `MirrorRevealView` | Role-aware prompt (A: about you / B: what did A say) → seal → gap reveal |
| `SnapshotRevealView` | One-word field → seal → two words land together |
| Context beat overlays | banner: 1-2 lines over dimmed card, auto-dismiss 5s, tap-through; interstitial: full-screen, user-dismissed. Driven by `contextBeatType` before the card presents |
| Card back flip | `backCopy` cards get a flip affordance after discussion, before advance |
| Local living card faces | dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause: prompt-engine rendering with per-type face treatment (distinct accent/iconography/pacing; pause = no prompt, held breath screen). No sync |
| Safe-word close screen | Neutral, warm, zero-guilt; both devices |

Special-card treatment (animated gradient border, particles) applies to reveal-mechanic cards per the handoff doc's ceremony spec; reuse existing glow/border components (AppGlows, VaylBorderEffect), no new primitives.

---

## 5. Realtime protocol summary

- One channel per session: `session:<couple_id>`, presence key = profile id.
- Three streams: presence (join/leave), postgres-changes UPDATE on the session row (status, current_index, bandwidth, consent, presence booleans, timer_started_at, reveal_state), broadcast (RevealEnvelope + resend requests).
- Row is the source of truth for everything durable; broadcast carries only ephemeral answer payloads.
- Every state the UI cares about must be reconstructable from `fetchOpenSession` alone (poll fallback proves this by construction).

### Lifecycle
1. Initiator: builder → `openSession` (status `lobby`, plan columns) → lobby.
2. Joiner: banner → lobby → both devices auto-advance to `airlock` when both present.
3. Airlock: bandwidth + consent per AirlockStore; flip to `active`.
4. Play: advance/timer/pause/reveals per section 4.3.
5. Close: last card (closing ritual) → `setStatus(.complete)` → each device runs its own private reflection → local persistence.
6. Abandon: safe word or confirmed exit → `abandoned`.

---

## 6. `reveal_state` shape

```json
{
  "card-07": { "a_sealed": true, "b_sealed": true, "revealed": true },
  "card-10": { "a_sealed": true, "b_sealed": false }
}
```
Merged server-side via `update_reveal_state(session_id, delta jsonb)` SECURITY DEFINER function with an `is_couple_member` guard; clients never write the whole column.

---

## 7. Content spec

### 7.1 Catalog re-cut (canonical launch slate, 12 decks)

| id | Title | Category | Tier | Notes |
|---|---|---|---|---|
| `the-opener` | The Opener | foundationEntry | Free | Exists; fix the flagged "that's not a red flag" line on card 2's interstitial |
| `the-check-in` | The Check-In | foundationEntry | Free | 5-6 cards, repeatable ritual deck |
| `communication-intimacy` | Communication & Intimacy | relationshipCore | Core | Rename/absorb existing `communication` stub |
| `sex-and-pleasure` | Sex & Pleasure | relationshipCore | Core | Absorb `desire-and-fantasy` stub where copy fits |
| `jealousy` | Jealousy & What It's Telling You | nmSpecific | Core | Absorb `jealousy-compersion` stub |
| `flavors-discovery` | Flavors: Discovery Edition | nmSpecific | Core | Absorb `the-styles` stub |
| `swinging` | The Swinging Deck | styleSpecific | Core | |
| `before-tonight` | Before Tonight | experienceArc | Core | Exists as stub |
| `after-last-night` | After Last Night | experienceArc | Core | New; the most-needed deck |
| `the-first-time` | The First Time | experienceArc | Core | New |
| `when-it-gets-hard` | When It Gets Hard | experienceArc | Core | New |
| `appreciation` | The Appreciation Deck | wildcard | Core | New; explicitly not hard |

Removed from catalog (files kept only if content is being absorbed, else deleted): `boundaries` (folds into the-opener/communication territory; its usable copy may seed communication-intimacy), `trust-repair`, `right-now`, `metamour`, `the-audit`, `unfinished-business` (all later waves), `solo-prep` (solo out of scope). Safe pre-launch: no live users, DeckProgress keys by deckId.

Dead files deleted outright: `assessment_questions.json`, `cards.json`, `deck-index.json` (zero callers, flagged in fable-plans 15).

### 7.2 Authoring mandate

Every deck: 10-11 cards (the-check-in 5-6; that is its design), 6-7 discussion + 3-4 living cards chosen via the dispatch matrix from the ALLOWED set only (reveal core + local cards), unique closing ritual per deck (never reused), opening ritual where the deck is heavy or milestone, context beats wherever copy would crowd the card face, gendered His/Her pair in applicable decks (M/F copy + experience-based flexible variant; mm/ff variants explicitly deferred), `backCopy` where a branch on the couple's answer earns it.

Quality gates per card (all four): Bar Conversation Test, Dual Register Test, Non-Assumption Test, Temporal Test. Style rules from the handoff doc apply verbatim, including: no clinical language, no "that's not X, it's Y" constructions, intentional line breaks, both-partners-answer reminder pattern, and the repo-wide no-em-dash rule.

Content lives in the existing per-deck JSON schema (no schema changes needed; all required fields already exist on Card). `schemaVersion` bumps on every touched deck.

### 7.3 Intensity & ordering

Deck-level `intensity` set honestly per deck job (appreciation low, when-it-gets-hard high). Card ordering follows the temporal lens where the subject has depth across time; safety before depth in every deck (Resentment-style excavation ordering discipline applies to when-it-gets-hard).

---

## 8. Migration

One migration file:
1. `couples.connection_composition text not null default 'flexible' check (connection_composition in ('mf','mm','ff','flexible'))`.
2. `update_reveal_state(p_session_id uuid, p_delta jsonb)` function: deep-merge delta into `curated_sessions.reveal_state`, guard `is_couple_member`, bump `updated_at`.
3. pgTAP: composition check constraint; update_reveal_state merges without clobbering sibling keys; non-member call rejected.

Process guard: run `supabase db diff --linked` first (known prod-vs-migrations drift; reconcile before adding).

---

## 9. Pairing touchpoint

At link completion, if both partners' OB gender answers are binary and complementary/matching, propose the derived composition with a one-tap confirm; otherwise default `flexible` silently. A Settings row lets the couple change it anytime. Copy is wayfinding ("which card variants you'll see"), never identity assignment.

---

## 10. Folded-in fixes

1. AppShell reads `appState.selectedTab` (kill the dead local `@State`), so "join session" banners can route to Play.
2. PlayStore observes EntitlementStore (live unlock after purchase).
3. solo-prep contradiction resolved by catalog removal.
4. Opener card-2 interstitial line revised per style guide.

---

## 11. Testing & verification

- **Unit (VaylTests, remember manual pbxproj wiring, AA00000N convention):** AirlockStore state machine against a mock RealtimeSessionService (presence orders, poll fallback path, idempotent active flip); RevealEngine (seal orders, payload-before-flag and flag-before-payload, resend path, reconnect restore); SessionBuilderStore (trim floor, closing-ritual protection, same-as-last persistence); SessionPlan round-trip to row columns.
- **pgTAP:** section 8 items.
- **Content lint (build-time or test):** every catalog deck file parses to Deck; 12 decks; card counts in range; every deck has exactly one closingRitual; living-card count 3-4 (check-in exempt); no card uses a deferred CardType; gendered cards have both mf and flexible coverage in applicable decks; no em dash anywhere in card copy.
- **Compile:** Claude build-verifies only (no sim runs per working agreement).
- **Done condition:** two-device run on Bryan's hardware, full Opener session front to back including the Whisper ceremony, plus one reveal of each remaining mechanic from any deck; feel confirmed by Bryan. Build success is not done.

---

## 12. Risks

- **Realtime is new to the stack** (was plan 08's flag): the poll fallback and "row reconstructs everything" rule are the mitigations; supabase-swift 2.48.0 confirmed to carry all needed APIs.
- **Content volume** (~120 cards to Opener standard) is the largest single work item; the lint suite keeps structure honest, but the quality gates are editorial and land on Bryan's read.
- **Broadcast delivery is best-effort:** the resend path + seal-flag authority cover loss; worst case a reveal card re-prompts.
