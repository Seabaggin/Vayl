# Card Sessions — Closeout & Verification Spec (what remains)

**Date:** 2026-07-02
**Supersedes-status-of:** `2026-07-01-card-sessions-front-to-back-design.md` (the build spec) + fable-plan `16-card-sessions-front-to-back.md`. Those defined the build; this defines the finish line.
**Verdict up front:** the build is **code-complete and prod-deployed.** Nothing in the master spec is unbuilt. A four-part audit (transport/stores, views, content, backend/pairing/fixes/tests) found **zero ❌ MISSING and zero ⏭️ SIMPLIFIED items** in scope, and the one dependency the audits couldn't see (the reveal-merge function in prod) is **confirmed live**. So this is not another Fable one-shot. What is left is verification a build cannot prove, plus your editorial read, plus two optional micro-polish items.

---

## 1. What is already done (proven, not claimed)

- **Transport + stores** (commits `5e8309e`, `ba31ab3`): `RealtimeSessionService` seal/reveal merge ops + the three streams; `AirlockStore` full state machine (idempotent active-flip on the row, 10s→poll fallback, presence heartbeat); `CoupleSessionStore.startRemoteSync()` real via `SessionSyncCoordinator` (no longer a TODO); advance / timer / pause / safe-word / 15s grace / reconnect-rebuild-from-row; `RevealEngine` (all 5 mechanics, both seal-race orders, 5s resend, reconnect restore). `SessionRole` derives from local `UserProfile.id`, never the auth id. Old `@Model SessionPlan` deleted, replaced by the struct.
- **Views** (commits `ba31ab3`, `c51103a`): builder, lobby, joiner banner (Home + Play), real `AirlockView` (mock is DEBUG-only), timer bar, all four reveal views, context beats, card-back flip, all nine local card faces, safe-word close, and the full cover-family treatment (six house rules + collapse, 3-detent bandwidth, 3s hold-to-lock arc, 2.5s "look at each other" transition with "put your phones down" correctly cut). `sessionStatLine` emits all three of cards · depth · duration (`CoupleSessionStore.swift:214`). Session is `.vaylCover`, builder is `.vaylSheet`, everything tokenized + Reduce-Motion gated.
- **Content** (commit `a26e86e`): all 12 launch decks are real authored content (no stubs); catalog re-cut done; 7 removed decks + 4 absorbed stubs gone; dead files (`assessment_questions.json`, `cards.json`, `deck-index.json`) deleted; `ContentLintTests.swift` enforces the structural gates. Spot-read of the 5 highest-stakes decks rates the voice genuinely strong.
- **Backend + pairing + fixes** (commits `5e8309e`, `eb76830`, `a26e86e`): the composition + reveal-merge migration and the composition write-path migration exist in `supabase/migrations/`; `Couple.connectionComposition` + `GenderDynamic.proposal(...)` derivation + one-tap confirm card (both pairing views) + Settings row + `Deck.cards(for:)` consumption; all four folded-in fixes (AppShell tab sync, PlayStore live entitlement read, solo-prep removal, opener card-2 revision).
- **Prod, verified live 2026-07-02 via MCP:** `couples.connection_composition` (+ exact `mf/mm/ff/flexible` check), `curated_sessions.reveal_state` jsonb, `user_profiles.gender_identity`, and both RPCs `update_reveal_state` + `set_connection_composition` present, `SECURITY DEFINER`, `is_couple_member`-guarded.
- **Tests:** all session test files (`AirlockStoreTests` 7, `RevealEngineTests` 10, `SessionBuilderStoreTests` 10, `CompositionDerivationTests` 5, `ContentLintTests` 12) are wired into the VaylTests pbxproj (AA convention, high-water `AA00000G`) and cover every case the master spec §11 lists. Passing status is inventoried, not run (no sim from Claude).

---

## 2. What remains (the actual finish line)

Four items. Owner and acceptance criteria on each. Only R4 is code, and it is optional.

### R1 — Two-device device walk (the real done condition). Owner: **Bryan (hardware).**
The master spec §11 is explicit: build success is not done; the done condition is a two-device run on your hardware. Walk this, on two physical devices (sim Sign-in-with-Apple is flaky), fixing anything that breaks:

- [ ] Pair (or use the existing linked couple). At link, confirm the composition one-tap card appears and sets the right variant (or defaults `flexible` silently for non-binary/declined).
- [ ] Initiator: Play → deck detail → builder (try Quick start AND a custom trim/timer) → lobby.
- [ ] Joiner: the "…set up a session" banner appears on Home + Play → tap → lobby → both auto-advance to airlock.
- [ ] Airlock: six house rules (first session) → bandwidth 3-detent set privately → 3s hold-to-lock → both present + consented flips the row to `active` exactly once. Confirm the depth-ceiling trims the hand (set mismatched bandwidths; the gentler wins; closing ritual survives).
- [ ] Transition: ~2.5s "look at each other" beat.
- [ ] Player: advance from either device moves both; simultaneous taps do not double-advance; per-card timer chime + "keep going" clears it for both; pause/resume; context beats; a card-back flip.
- [ ] **One reveal of each mechanic** (the master spec requires all five somewhere): Whisper (the Opener's), plus Unspoken, Mirror, Snapshot, WhatIf from any deck. Confirm: neither sees the other until both seal; simultaneous 3-2-1; answers never persist (check `curated_sessions.reveal_state` shows only flags, no payloads).
- [ ] Safe word: raise it → both exit immediately to the neutral close, no reflection, no guilt.
- [ ] Reconnect: force-kill mid-reveal → reopen → rebuilds from the row; a lost pre-reveal payload re-prompts compose ("that one got lost in the air").
- [ ] Close: stat line (cards · depth · duration) + one word + "how full are you now" → persists `CardSession`/`CardResult`/`LockInSession`/`SessionReflection`/`DeckProgress`; the next sitting resumes where you left off; bandwidth feeds Pulse.
- [ ] **Feel pass** on the 🎚️ values: hold-to-lock 3.0s ramp, 2.5s transition, timer chime (currently haptic-only, see R4).

### R2 — Run the automated suites (substantiate green). Owner: **Bryan (one command each).**
- [ ] `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (a **clean** build first if you hit phantom test-host SIGSEGVs, per this session's build note). Confirms the 131-green claim.
- [ ] `supabase test db` (or run `supabase/tests/card_sessions_invariants.test.sql` on the local stack) to execute the pgTAP: composition constraint, reveal-merge sibling-preservation, non-member rejection.
- [ ] Optional but recommended: `supabase db diff --linked` to reconcile the known prod-vs-migrations drift now that the July-01 migrations are live (so a fresh `db reset` matches prod).

### R3 — Editorial read of the decks. Owner: **Bryan (your read, the one gate only a human passes).**
The lint suite guarantees structure; the four editorial gates (Bar Conversation, Dual Register, Non-Assumption, Temporal) + the style rules are yours. The 5 highest-stakes decks were already read and pass. Remaining:
- [ ] **Priority: `sex-and-pleasure` and `jealousy`** — highest intensity + gendered mf/flexible copy; read every card.
- [ ] Then `communication-intimacy`, `flavors-discovery`, `before-tonight`, `the-first-time` (structurally validated, not yet read line-by-line).
- [ ] Confirm the re-authored **opener card-2** interstitial (the boundary line that replaced the flagged "that's not a red flag" copy) reads right.

### R4 — Optional micro-polish (the only code left, and it is optional). Owner: **one-shottable / Bryan device.**
Neither blocks launch; both are judgment calls flagged by the audits.
- [ ] **Opening rituals on `sex-and-pleasure` (intensity 6) and `jealousy` (intensity 5).** The authoring mandate says "opening ritual where heavy"; these two open with grounding prompts but no formal `openingRitual` card. If you want the mandate honored literally, add one ritual card each (content-only edit, then bump `schemaVersion`; the lint suite will keep it honest). One-shottable in a few minutes; skip if the grounding prompts already feel like enough.
- [ ] **Audio chime on the per-card timer.** Currently haptic-only (`SessionTimerBar.swift:46-47`, left as a deliberate device-tune). Add a soft sound if the haptic feels too quiet on device. Your call on the device pass.

---

## 3. Not in scope (unchanged from the master spec — listed so they are not mistaken for gaps)

Solo lane / SoloSession · Shared Creation cards (sharedCanvas, spectrum, wordCloud) · Memory & Time cards (timeCapsule, echo, callback, beforeAfter) · mm/ff gendered copy variants · Live Activities / Dynamic Island / SharePlay / iMessage invites / push · single-device couch mode. All deferred by design (master spec §1.2, decision D1).

---

## 4. Done condition

Card Sessions is **done** when: R1 completes on two devices with feel confirmed, R2's two suites are green, and R3's priority decks (`sex-and-pleasure`, `jealousy`) have passed your read. R4 is optional. Nothing else in the master spec is outstanding.

_Dev-install note: `SchemaV1` changed during the build (`@Model SessionPlan` removed, `Couple.connectionComposition` added), so a dev device may need a delete-reinstall to migrate cleanly._
