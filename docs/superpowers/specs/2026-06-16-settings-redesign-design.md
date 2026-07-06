# Settings Redesign — Design Spec

**Date:** 2026-06-16
**Status:** Draft for review
**Owner:** Bryan
**Branch context:** to be built on its own branch (current branch is `spec/contextphase-2x3-redesign`)

---

## 1. Goal

Redesign the existing `SettingsView` from the old form-style aesthetic
(`pageBackground` + `SettingsCard`) into the void / spectrum / glass language used
across Home, Map, Play, and Learn — **and** decide and document the full feature set
the screen carries, including net-new privacy features.

Settings is a **"back room"**, not a tab. It is reached via the **gear button** in the
Map header (and likely Home). It stays calm and utilitarian. The expressive identity
(avatar card, badges, share/invite, the Vault) lives in the **Map** tab and is **not**
duplicated here.

## 2. Scope

### In scope
- Full re-skin of `SettingsView` to void/spectrum/glass.
- Editable identity (the "YOU" section), incl. an editable "About you" subsection.
- Partner link management, incl. **unlink** (net-new).
- Privacy & Safety: **app lock** (net-new), app-switcher blur (net-new), screenshot
  protection (exists), review-ground-rules link.
- Notifications controls (net-new).
- Appearance (theme, haptics).
- Account & Data: sign out (exists), **delete account** (net-new, compliance),
  export data (scaffold).
- **Premium banner** at the top, state-dependent, scaffolding-only.
- About / legal.
- Architecture: introduce a `SettingsStore` and the new services, per the 4-layer rule.

### Out of scope (explicitly cut or owned elsewhere)
- **Discreet / alternate app icon** — cut. (Dedicated app-hiders do this better.)
- **Quick-exit / panic / decoy screen** — cut for V1. App lock + switcher blur cover
  the real threat model ("someone grabbed my phone").
- **The Vault** (Desire Map, Agreements, matches, consent unlocks) — lives in Map.
- **Expressive identity card / shareable card** — lives in Map.
- **Real StoreKit purchase logic** — premium banner is scaffolding-only per the
  monetization plan; real purchase flow is separate work.
- Invisible onboarding routing data (`emotionalRegister`, `agency`, `motivation`,
  `archetype`, `curiositySelections`, `openerDeckType`) — never surfaced.

## 3. Tag legend
- `[WIRED]` — already works in code.
- `[RE-SKIN]` — exists, needs the new aesthetic.
- `[NET-NEW]` — a real feature to build.
- `[COMPLIANCE]` — App Store requires it.
- `[SCAFFOLD]` — ships as visible UI, no real backing logic yet.

---

## 4. Information architecture (top → bottom)

A gear-accessed `NavigationStack` over `AppColors.void` + `AtmosphereView()`. Each
section is a glass card. Header is the name as a spectrum-gradient title (matches
Home/Map) — no avatar card.

```
SETTINGS  (overline)
Jordan.   (spectrum-gradient name title)

[ PREMIUM BANNER ]              top, state-dependent (Free = upgrade / Lifetime = member)
┌ YOU ───────────────────────┐ editable identity + About you
┌ PARTNER ───────────────────┐ link management (invite / join / unlink)
┌ PRIVACY & SAFETY ──────────┐ app lock · switcher blur · screenshot · ground rules
┌ NOTIFICATIONS ─────────────┐ reminders · partner nudges · discreet mode
┌ APPEARANCE ────────────────┐ theme · haptics
┌ ACCOUNT & DATA ────────────┐ sign out · export · delete account
  About · version · privacy · terms · support
```

---

## 5. Section detail

### 5.0 Premium banner — `[SCAFFOLD]`, top, state-dependent
Sits directly under the name header, above YOU. The one place a **spectrum-filled CTA**
is justified.
- **Free user** → upgrade card: "Unlock Vayl · Lifetime $24.99" + short value line.
  Tapping opens the paywall (primary conversion remains the Desire Map reveal; this is
  the persistent secondary entry).
- **Lifetime user** → collapses to a quiet "Vayl Lifetime ✓" member chip + **Restore
  purchases**.
- Entitlement state is read from a scaffolded source (debug-toggleable). No real
  StoreKit yet. Entitlement must never be a user-writable `user_profiles` column
  (per security posture: entitlements are service-role only).

### 5.1 YOU — identity — `[RE-SKIN]`
Tappable rows; each opens a small edit sheet reusing the onboarding pickers.

Core four (editable):
- **Display name** `[WIRED]` → `ProfileService.updateIdentity`
- **Gender identity** `[WIRED]` → same option set as `GenderPhase`
- **Pronouns** `[WIRED]`
- **Experience stage** (`nmStage`: curious / exploring / experienced) `[WIRED]` — with a
  one-line note that this nudges default card intensity (`UserProfile.defaultIntensity`
  derives from it).

About you (editable subsection) `[RE-SKIN / NET-NEW edit UI]`:
- **Age range** (`AgeRange`) — editable.
- **Relationship context** (`relationshipContext` / `RelationshipTenure`) — editable.

Display-only:
- **Mode badge** (Solo Discovery / Linked) — reflects `appMode`; changed via the PARTNER
  section, never a free toggle.

### 5.2 PARTNER — link management — `[RE-SKIN + NET-NEW]`
State-dependent on `AppState.linkState`:
- **Solo / unlinked:**
  - "Invite a partner" → `PairingService.generateCode()` + system share sheet `[WIRED]`.
  - "Enter a code" → `PairingService.claimCode(_:)` `[WIRED]`. This is the solo→together
    on-ramp.
- **Linked:**
  - Partner identity card — name + pronouns from `PairingService.fetchPartner()` `[WIRED]`.
  - "Linked since {date}" from `UserProfile.linkedAt` `[WIRED]`.
  - **Unlink** `[NET-NEW]` — destructive, confirmation, careful copy. See §6.4.

### 5.3 PRIVACY & SAFETY — `[uses AppColors.safetyAccent / .safetyGlow]`
The differentiated heart of Settings for a sensitive-content app.
- **App lock** `[NET-NEW]` — Face ID / Touch ID / passcode gate. Toggle + grace period
  ("Immediately" / "After 1 minute"). See §6.1. Touches the app shell, not just Settings.
- **Blur in app switcher** `[NET-NEW]` — privacy snapshot overlay so the app-switcher
  thumbnail doesn't reveal content. Own toggle; defaults on when app lock is on. See §6.1.
- **Screenshot protection** `[WIRED]` — keep the toggle (`screenshotProtected()`).
  Migrate the `@AppStorage("screenshotProtectionEnabled")` key to a typed
  `UserDefaultsKey` (existing TODO in code).
- **Review ground rules** `[RE-SKIN]` — link back to the ground-rules / acknowledgement
  copy (`groundRulesAcceptedAt`, `acknowledgementAcceptedAt` exist).

### 5.4 NOTIFICATIONS — `[NET-NEW]`
- **Check-in reminder** — local notification on a cadence (daily / weekly) + time.
- **Partner nudges** — preference toggle (e.g. "Alex asked to open a conversation");
  actual delivery is a backend push, so the toggle is stored now and delivery wired when
  backend push exists `[SCAFFOLD for delivery]`.
- **Discreet mode** — generic notification text ("Vayl", no content preview). Safety
  tie-in.
- iOS 26: authorization **must** use `UNAuthorizationOptions.banner` (and `.sound` /
  `.badge`). `.alert` is a hard compiler error. See §6.2.

### 5.5 APPEARANCE — `[RE-SKIN]`
- **Theme** (light / dark / system via `ThemeManager`) `[WIRED]` — OB forces Midnight;
  light unlocks post-onboarding.
- **Haptic feedback** toggle `[RE-SKIN]` — currently a dead `@State`; wire to a real
  persisted setting in `SettingsStore`.

### 5.6 ACCOUNT & DATA
- **Sign out** `[WIRED]` → `AuthService.signOut()`.
- **Export my data** `[SCAFFOLD]` — button → "preparing…" → share sheet. Real export
  (profile, sessions, ratings, etc.) later.
- **Delete account** `[NET-NEW · COMPLIANCE]` — see §6.3. Distinct from the debug
  "Reset All Data", which returns behind `#if DEBUG`.

### 5.7 About
- App version `[WIRED]`.
- **Privacy Policy** + **Terms of Service** links `[NET-NEW · COMPLIANCE]`.
- Support / send feedback.

---

## 6. Net-new features — detail

### 6.1 App lock (+ app-switcher blur)
**Service — `BiometricLockService`** (Service layer, no Store/View refs):
- `capability() -> BiometricCapability` (faceID / touchID / none) via
  `LAContext.canEvaluatePolicy(.deviceOwnerAuthentication)`.
- `authenticate(reason:) async throws -> Bool` via
  `LAContext.evaluatePolicy(.deviceOwnerAuthentication, ...)` — biometrics with passcode
  fallback.

**Settings state** (in `SettingsStore`, persisted):
- `appLockEnabled: Bool`
- `appLockGrace: GracePeriod` (`.immediate` / `.oneMinute`)
- `switcherBlurEnabled: Bool` (default true when lock on)

**App-shell lock gate** (NOT in Settings — lives in `AppRootView` / `AppShell`):
- Observe `scenePhase`. On `.background`: record timestamp; show the privacy cover
  overlay if `switcherBlurEnabled`.
- On `.active`: if `appLockEnabled` and elapsed since background > grace, present a
  full-screen `LockView` and call `BiometricLockService.authenticate`. Dismiss on success.
- Scene-based window access only (iOS 26: no `UIApplication.shared.keyWindow`).

**Risk / dependency:** this is the one feature that touches the app shell, not just the
Settings screen. Build the Settings toggle and the gate as one segment so they stay
consistent.

### 6.2 Notifications
**Service — `NotificationService`**:
- `requestAuthorization() async -> Bool` with `UNAuthorizationOptions` = `[.banner,
  .sound, .badge]` (never `.alert`).
- `scheduleCheckInReminder(cadence:time:discreet:)` — `UNNotificationRequest`; discreet =
  generic title, no body preview.
- `cancelAll()` and re-schedule on change.
- Partner-nudge delivery is backend push (out of scope to deliver now; store the pref).

### 6.3 Delete account `[COMPLIANCE]`
Required by App Store guideline 5.1.1(v) because the app supports account creation
(Sign in with Apple).

**Server contract** (Supabase edge function / RPC, service-role; Supabase MCP is
read-only so Bryan deploys):
- Delete the user's `user_profiles` row and owned data rows.
- **Unlink the partner**: clear the partner's `isLinked` / `coupleId` — do **not** delete
  the partner's data.
- Revoke / invalidate the session.

**Client**:
- Call delete endpoint → on success: `AuthService.signOut()` + wipe local SwiftData
  (`UserProfile`, sessions, etc.) + clear relevant `UserDefaults` keys + clear keychain
  token → route back to sign-in / onboarding.
- Confirmation: destructive alert; copy states the partner is unaffected and the user's
  own data is permanently removed.

### 6.4 Unlink partner
**Service — `PairingService.unlink() async throws`** `[NET-NEW]`:
- Server clears `coupleId` / `isLinked` reciprocally on both rows.
- Client updates `AppState.linkState` → `.unlinked`, `appMode` → `.solo`.
- Confirmation with careful copy (this is emotionally loaded for new-NM couples).

### 6.5 Export / Restore — `[SCAFFOLD]`
- Export: button → "preparing…" → share sheet. Stub payload now.
- Restore purchases: visible in the Lifetime-member state; no-op stub until StoreKit.

---

## 7. Architecture (4-layer compliance)

Today `SettingsView` holds `@State` / `@AppStorage` and calls services inline — this
violates View → Store → Service.

**Introduce `SettingsStore`** (`@Observable @MainActor`):
- **Owns:** editable identity draft state; toggles (`appLockEnabled`, `appLockGrace`,
  `switcherBlurEnabled`, `screenshotProtection`, `haptics`, notification prefs); theme
  (delegated to `ThemeManager`); pairing display state; scaffolded entitlement state.
- **Methods:** `updateIdentity(...)`, `invitePartner()`, `joinPartner(code:)`,
  `unlinkPartner()`, `signOut()`, `deleteAccount()`, `setAppLock(...)`,
  `setNotifications(...)`, `exportData()`, `restorePurchase()`.
- **Injects services:** `AuthService`, `PairingService`, `ProfileService`,
  `BiometricLockService` (new), `NotificationService` (new).
- The View goes dumb: reads `SettingsStore`, calls its methods only.

The app-lock **gate** is intentionally separate from the app-lock **setting** — the gate
lives in the shell (`AppRootView` / `AppShell`), the setting in `SettingsStore`.

## 8. iOS 26 compliance touchpoints
- Notifications → `UNAuthorizationOptions.banner`, never `.alert`.
- Any UIKit bridging (biometric prompt presentation) → scene-based window, never
  `UIApplication.shared.keyWindow`.
- `LocalAuthentication` (`LAContext`) — allowed, no banned APIs.

## 9. Design / token notes
- Background: `AppColors.void` + `AtmosphereView()` on every screen.
- Cards: use the project's real glass-card modifier. **Verify the actual name in code
  before building** — CLAUDE.md lists `.glassCard()` / `.hairline()`, but those may not
  exist; `.themedCard` is the known-good modifier. Confirm first.
- Name title: spectrum gradient (`AppColors.spectrum*`) like Home/Map.
- Section headers: `AppFonts.overline` / `.sectionHeading`, `AppColors.textTertiary`.
- Premium card: spectrum-filled CTA (the one allowed place).
- Privacy & Safety: `AppColors.safetyAccent` / `.safetyGlow` for app-lock / safety
  emphasis.
- Every tappable row: press scale (`.scaleEffect(0.96)`) +
  `.sensoryFeedback(.impact(.light), trigger:)` + action — all three, per the tap
  contract.
- Toggles: reuse the existing `ToggleRow` component.
- Spacing / radius: `AppSpacing`, `AppRadius` tokens only — zero raw values.

---

## 10. Segmented build plan

Per the Build Protocol: each segment does ONE thing, has a done condition verified **on
device by Bryan** (build-success is not done — feel/behavior is done), and a constraints
list. Claude build-verifies (compile) only; Bryan runs on device.

1. **Shell re-skin + `SettingsStore` scaffold.** New void/glass `SettingsView` shell +
   `SettingsStore` wired to existing wired actions (identity read, theme, screenshot,
   sign out, haptics persistence).
   *Done:* opens from the gear, renders the new aesthetic, theme + screenshot + sign out
   work on device.
   *Constraints:* do not touch the app shell / lock gate; no new services yet.

2. **YOU — identity editing.** Edit sheets for the core four + "About you" (age range,
   relationship context) via `ProfileService`.
   *Done:* edits persist locally and sync; verified on device.
   *Constraints:* identity only; no partner / privacy changes.

3. **PARTNER.** Re-skin invite / join; add **Unlink** (`PairingService.unlink()` +
   backend reciprocity).
   *Done:* linked / unlinked states render; unlink works end-to-end across two devices.
   *Constraints:* pairing only.

4. **App lock.** `BiometricLockService` + Privacy & Safety toggles + app-shell lock gate
   + switcher blur.
   *Done:* enabling lock gates the app on relaunch / foreground with Face ID on device;
   switcher thumbnail is blurred.
   *Constraints:* touches `AppRootView` / `AppShell` — keep the gate isolated and behind
   the setting.

5. **Notifications.** `NotificationService` (banner auth) + check-in reminder scheduling
   + discreet mode + stored partner-nudge pref.
   *Done:* a scheduled reminder fires on device; discreet mode hides content.
   *Constraints:* local notifications only; no backend push delivery.

6. **Account & Data.** Delete account (edge function + client wipe + partner unlink) +
   export scaffold.
   *Done:* delete account removes the account and returns to sign-in on device; partner
   is unlinked, partner data intact.
   *Constraints:* requires the backend edge function deployed first.

7. **Premium banner.** State-dependent top banner (Free upgrade card / Lifetime chip +
   Restore), scaffolded entitlement (debug toggle).
   *Done:* both states render correctly via debug toggle; no real StoreKit.
   *Constraints:* scaffolding only; entitlement never a user-writable column.

8. **About / legal.** Version, Privacy Policy + Terms links, support / feedback.
   *Done:* links open; renders in the new aesthetic.

**Cross-cutting dependencies:**
- Segments 3 & 6 need backend edge functions (unlink, delete) — Supabase MCP is
  read-only, so Bryan deploys them.
- Segment 4 is the only one that modifies the app shell.

---

## 11. Open questions / future
- Final premium-banner copy and exact paywall entry behavior (depends on monetization
  work).
- Whether partner nudges get real push delivery in V1 or stay a stored pref.
- Export payload format (JSON vs. human-readable) when it becomes real.
