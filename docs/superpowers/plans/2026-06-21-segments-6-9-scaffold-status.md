# Segments 6–9 — Scaffold Status (UNVERIFIED)

**Date:** 2026-06-21
**Decision:** You chose "scaffold 6–9 unverified." This is the honest map of what landed, what is **not** proven, and what only **you** can finish (two devices, Apple Push config, prod DB). The app **BUILDS** and the local playthrough test still **PASSES** — but none of the realtime/push/breakup paths below have run against the backend or a second device.

**Guardrail kept:** every scaffold is **off by default**. The verified single-device front end is unchanged — realtime only activates if a `RealtimeSessionService` is injected into `CoupleSessionStore`, push is not wired into launch, and no migration/edge-function was applied or deployed.

---

## Seg 6 — Live session wiring · scaffolded, compiles, UNVERIFIED

- `CoupleSessionStore` gained injected `realtime: RealtimeSessionService?`, `sessionRole`, `initiatorId` (all default nil/.a → pure-local).
- Push side wired: `liveOpen()` (on sync → `openSession` + presence + bandwidth + status), `liveAdvance(expectedIndex:)` (on each deal/pass → server-authoritative conditional advance), `liveComplete()` (on close → presence false + status complete).
- **Not proven:** no call has hit `curated_sessions`. Needs auth + a real couple row + the injection flag.
- **Your action:** inject a `RealtimeSessionService` (behind a debug flag) where the cover is presented, with the real `initiatorId` (your profile id) and the `sessionRole` resolved from couple membership (A vs B).

## Seg 7 — Two-device realtime · STUBBED, the genuine unverifiable core

- `startRemoteSync()` exists as the entry point. The **consume** side (subscribe to `sessionChannel`, `trackPresence`, and mirror remote `current_index`/presence/status into this store via `presenceChange()` / postgres-changes) is a documented `TODO` — it is a **no-op today**.
- **Why stubbed:** this cannot be written correctly or verified without two physical devices observing each other. Building it blind would be guessing.
- **Your action:** a session with two devices, together, to implement + tune the consume side. This is the part the whole front-end-first plan deferred for exactly this reason.

## Seg 8 — Push invite · scaffolded (client + backend files), UNVERIFIED, NOT wired/applied

- **Client:** `Vayl/Core/Services/PushService.swift` — auth request + APNs register + `handleDeviceToken` upsert to `device_tokens`. **Not** wired into launch (no `AppDelegate` added — kept the verified launch path clean).
- **Backend (files only, not applied/deployed):** `supabase/migrations/20260621180000_session_push_tokens.sql` (device_tokens + RLS) and `supabase/functions/send-session-invite/index.ts` (token lookup + **stubbed** APNs send).
- **Your actions (need an Apple Developer account + a real device):**
  1. Add the **Push Notifications capability** (aps-environment entitlement).
  2. Add a `UIApplicationDelegateAdaptor` forwarding `didRegisterForRemoteNotificationsWithDeviceToken` → `PushService.shared.handleDeviceToken`.
  3. Create an **APNs .p8 key**, store APNS_* secrets for the function.
  4. **Verify the migration's RLS** against the project's auth-id vs profile-id convention (noted in the SQL), then apply it.
  5. Implement `sendAPNs()` (provider JWT + POST) and `supabase functions deploy send-session-invite`.
- iOS 26 correction found while scaffolding: `UNAuthorizationOptions` has **no** `.banner` (the `.alert`→`.banner` change is foreground *presentation* only). Authorization requests sound/badge for now; set the banner presentation style in the notification delegate when wired.

## Seg 9 — Breakup / archival · cascade fix DONE + verified, unlink scaffolded

- **Fixed + compiles:** `Couple` relationships changed `.cascade` → `.nullify` (desireMatches/cardSessions/deckProgress). This matches the model's own "archived not deleted" contract — a dissolved couple no longer wipes all history. No data migration needed (no users yet).
- **Scaffolded:** `AppState.unlink()` clears the local link (coupleId/linkState) without deleting the Couple or history.
- **Not done:** remote archival (mark the couples row dissolved, tear down any open `curated_session`, revoke the partner's device tokens) + any unlink UX entry point. Needs the backend work + a decision on where unlink lives in the UI.

---

## What "launch ready" still needs beyond 6–9 (found this pass)

- 🔴 **VaylDirector deinit double-free** (SIGABRT on onboarding-canvas teardown) — separate task chip spawned. Candidate launch blocker; verify on device.
- 🟠 **No `PrivacyInfo.xcprivacy`** — iOS 26 / App Store requirement; needs your data-practice input (UserDefaults required-reason at minimum, plus Supabase data-collection disclosures).
- Not audited here: StoreKit/paywall completeness (M2), App Store assets/screenshots, real deck content, the App Store blockers in the routing map.

## Verification status

- `xcodebuild build` → **BUILD SUCCEEDED** (all scaffold compiles; PushService import + the UNAuthorizationOptions issue fixed).
- `VaylTests/CoupleSessionPlaythroughTests` → **3/3 PASS** after the realtime wiring (local path un-regressed).
- Realtime / push / breakup-remote paths → **NOT RUN** (require backend + two devices + Apple config).
