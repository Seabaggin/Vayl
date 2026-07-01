# Fable One-Shot Plan 04 — Settings & Account (T5 · H-2 · A1 · H-4)

**Goal:** In one pass, finish the Settings vertical end to end — introduce a `SettingsStore` that pulls every Service/DB call out of the Settings views, make profile edits (name / pronouns) actually push to remote `user_profiles`, ship a real **Delete Account** path (new service-role edge function + Swift + destructive confirm) plus a release-safe **Sign Out**, and clean the Settings token debt (AppFonts, `.vaylGlassCard()`, `.vaylSheet`).

---

## ⚡ ONE-SHOT LICENSE — convention override (read first)

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

## Context Fable needs

- **What this is.** Settings is a **route, not a tab** for most surfaces, but it also renders as the
  Settings *tab* content (`AppShell.swift:34` → `TabContentWrapper { SettingsView(isTab: true) }`). It is
  the biggest launch-blocker cleanup: it must (a) get Services out of the views, (b) make profile edits
  reach the server, (c) ship **Delete Account** (a HARD App Store rejection without it) and a real Sign
  Out, and (d) remove its token debt.
- **Current state (verified 2026-07-01).** The Settings views are already ~80% styled in the void +
  spectrum + glass idiom and most sub-screens already use `.vaylSheet`. But three views still call
  Services / the DB directly (the H-2 debt), profile edits save locally + push identity but the flow is
  buried in the view, Delete Account is a no-op stub (`SettingsView.swift:94-101`, comment "deferred to
  V1.1"), and there are raw `.sheet` presentations + `.system(size:)` fonts + hand-rolled card chrome
  left over.
- **The three in-view Service calls to move (H-2), verified:**
  - `SettingsPrivacyView.swift:40-42` — `.onChange(of: shareCapacity) { Task { await SyncManager.shared.pushSharePulse(newValue) } }`.
  - `SettingsIdentityView.swift:214-240` — the `save()` method in the private `IdentityEditSheet`: pronoun
    comma-parsing + `try? context.save()` + a `Task { await SyncManager.shared.pushDisplayIdentity / pushNMStage }`.
  - `HomeLexicon.swift:158-167` — the `.task { let f = await ContentService.shared.fetchFindings() … }` block
    that overrides the bundled daily-5 pool from Supabase. (Not a Settings file, but the same H-2 pocket.)
- **`saveWithLogging()` exists** — `Vayl/Core/Persistence/ModelContext+Extensions.swift:27`,
  `func saveWithLogging() throws` on `ModelContext` (logs + rethrows). PairingStore / CoupleSessionStore /
  OnboardingStore already use it. **Use it for every context save in the new Store** (replaces the
  `try? context.save()` at `SettingsIdentityView.swift:229`).
- **Canonical patterns to imitate:**
  - **Store shape:** model `SettingsStore` on `HomeStore.swift` and `PairingStore.swift` — `@Observable
    @MainActor final class`, deps injected via `init(modelContainer:appState:)`, `ModelContext(modelContainer)`
    created fresh at write time (never stored on `self`), OSLog `Logger(subsystem:"com.vayl.app",category:"SettingsStore")`.
  - **Service reads/writes:** `ProfileService.updateIdentity` / `updateNMStage` / `updateSharePulse`
    (`ProfileService.swift:204-242`) are the existing partner-visible pushes; `SyncManager`
    (`SyncManager.swift:125-157`) is the orchestrator the views currently reach. Route the Store through
    `SyncManager.shared` exactly as `PairingStore.syncIdentityToRemote()` does (`PairingStore.swift:218-222`).
  - **Edge function structure:** copy `supabase/functions/get-partner/index.ts` verbatim for the
    two-client pattern (a `serviceClient` on the service-role key + a `userClient` on the anon key with the
    caller's `Authorization` header to validate identity, CORS + `json()` helper). `grant-entitlement`
    and `rapid-task` (slug for "create-couple") use the identical shape.
- **The couple ↔ profile shape (delete cascade — verified against prod schema, project `ynhjlabjzauamntbyxdp`):**
  - `couples.user_a` / `couples.user_b` are **FKs to `user_profiles.id`** (PROFILE ids, not auth ids),
    `ON DELETE SET NULL`. `user_profiles.couple_id` is an FK to `couples.id`. `user_profiles.auth_id` maps
    to the Supabase auth user.
  - **Children of `couples` (`ON DELETE CASCADE`):** `card_progress`, `couple_session_records`,
    `curated_sessions`, `desire_map_status`, `desire_matches`, `desire_reveal_progress`, `entitlements`.
  - **Children of `user_profiles` (`ON DELETE CASCADE`):** `assessment_responses`, `assessment_results`,
    `desire_ratings`, `desire_reveal_progress`. (`entitlements.purchased_by` → `user_profiles.id` is `SET NULL`.)
  - **Net:** delete a caller's `user_profiles` row and Postgres already cascades that person's own
    per-user artifacts. The couple must be handled explicitly (see Segment 5).

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Settings/Store/SettingsStore.swift` | `@Observable @MainActor final class SettingsStore` — owns profile-edit save + remote push, share-capacity push, sign-out, and delete-account. The only object the Settings views call. |
| `Vayl/Core/Services/AccountService.swift` | Thin Service wrapping the `delete-account` edge-function invoke + `supabase.auth.signOut()` + local-store wipe helper. Injected into `SettingsStore`. |
| `supabase/functions/delete-account/index.ts` | Service-role edge function: hard-delete the caller's `user_profiles` row, revert the partner to unpaired/free, delete the `couples` row when it empties. Modeled on `get-partner/index.ts`. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Features/Settings/SettingsView.swift` | 72-79 | Raw `.sheet(isPresented: $showInvite/$showJoin)` → `.vaylSheet`. |
| `Vayl/Features/Settings/SettingsView.swift` | 88-101 | Wire Sign Out + Delete Account confirmations to `SettingsStore` (real, not stubs). Ensure Sign Out is unconditional (release-safe). |
| `Vayl/Features/Settings/SettingsView.swift` | 120, 186-194, 222-224, 249-260, 301, 329 | Replace `.system(size:weight:)` with `AppFonts.*`; replace the two hand-rolled `RoundedRectangle` card-chrome blocks in `membershipCard` with `.vaylGlassCard()`. |
| `Vayl/Features/Settings/SettingsView.swift` | 8-32, body | Inject / construct `SettingsStore`; drive the two account actions and the delete confirmation through it. |
| `Vayl/Features/Settings/SettingsIdentityView.swift` | 74 | Raw `.sheet(item: $editField)` → `.vaylSheet`. |
| `Vayl/Features/Settings/SettingsIdentityView.swift` | 86-241 | `IdentityEditSheet.save()` no longer touches `context`/`SyncManager` — it calls `store.saveIdentity(...)`. Pass the `SettingsStore` in. |
| `Vayl/Features/Settings/SettingsPrivacyView.swift` | 40-42 | `.onChange` no longer calls `SyncManager.shared`; calls `store.setShareCapacity(newValue)`. |
| `Vayl/Features/Settings/SettingsPartnerView.swift` | 23, 32 | Raw `.sheet(isPresented: $showInvite/$showJoin)` → `.vaylSheet`. |
| `Vayl/Features/Settings/SettingsComponents.swift` | 61, 88, 114 | Replace `.system(size: 15/11, weight:)` on the icon glyph + chevron with `AppFonts.*`. |
| `Vayl/Features/Settings/SettingsAppearanceView.swift` | 22 | Replace `.system(size: 15, weight: .medium)` on the moon glyph with `AppFonts.bodyMedium`. |
| `Vayl/Features/Home/Components/HomeLexicon.swift` | 84-167 | Remove the `ContentService.shared.fetch…` `.task`; accept an injected remote pool from `HomeStore`. |
| `Vayl/Features/Home/Store/HomeStore.swift` | 56-102, `loadAll()` | Add `lexiconRemotePool` + `loadLexiconContent()` that calls `ContentService`; call it in `loadAll()`. |
| `Vayl/Features/Home/Views/HomeDashboardView.swift` | 323 | Pass `store.lexiconRemotePool` into `HomeLexicon(remotePool:onOpen:)`. |

### Delete

_None._ (This vertical is cleanup + additive; nothing is removed.)

---

## Build steps (segments)

Built in ONE pass. Segments are for readability.

### Segment 1 — `AccountService` (the delete + sign-out I/O seam)

**One thing:** a Service that invokes the `delete-account` edge function, signs the user out of Supabase,
and wipes the local SwiftData store — no state, no UI, injected into the Store.

`Vayl/Core/Services/AccountService.swift` (new):

```swift
//
//  AccountService.swift
//  Vayl
//
//  I/O for irreversible account actions: delete-account (service-role edge function)
//  and sign-out. No state, no UI knowledge — injected into SettingsStore.
//  Mirrors PairingService: async/await only, errors rethrown, never swallowed.
//

import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AccountService")

@MainActor
final class AccountService {

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    /// Invokes the `delete-account` edge function. The server hard-deletes the caller's
    /// `user_profiles` row (Postgres cascades their own per-user artifacts), reverts any
    /// partner to unpaired/free, and deletes the couple when it empties. Throws on failure —
    /// the caller must NOT sign out or wipe local data unless this succeeds.
    func deleteRemoteAccount() async throws {
        struct DeleteResponse: Decodable { let deleted: Bool }
        let response: DeleteResponse = try await supabase.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions()
        )
        guard response.deleted else {
            throw AccountError.deletionRejected
        }
        logger.info("Remote account deleted")
    }

    /// Ends the Supabase session. Best-effort — a local session teardown must still proceed
    /// even if the network call fails (the app must not be stuck signed-in).
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            logger.info("Signed out of Supabase")
        } catch {
            logger.warning("Supabase signOut failed (non-fatal): \(error.localizedDescription)")
        }
    }

    /// Wipes every local SwiftData row so no stale profile / session survives a sign-out or
    /// account deletion. Uses the shared app container so it clears the same store the app reads.
    /// Also clears the cached remote profile id + pending-sync flags in UserDefaults.
    func wipeLocalStore(container: ModelContainer) {
        let context = ModelContext(container)
        for model in SchemaV1.models {
            try? context.delete(model: model)
        }
        try? context.saveWithLogging()
        for key in ["supabaseProfileId", "pendingProfileSync", "pendingOnboardingSync", "pendingDesireSync"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        logger.info("Local store wiped")
    }

    enum AccountError: LocalizedError {
        case deletionRejected
        var errorDescription: String? {
            switch self {
            case .deletionRejected: return "Your account could not be deleted. Please try again."
            }
        }
    }
}
```

> Note: `SchemaV1.models` is the registered-model array (`ModelContainer.swift:23`). `context.delete(model:)`
> is the SwiftData batch delete-by-type — the cleanest full wipe without hand-listing every `@Model`.

**Done:** `AccountService` compiles; `deleteRemoteAccount()`, `signOut()`, `wipeLocalStore(container:)` exist.

---

### Segment 2 — `SettingsStore` (H-2: the only object the Settings views call)

**One thing:** an `@Observable @MainActor` Store owning identity-save + push, share-capacity push,
sign-out, and delete-account. Every Service/DB call the views used to make now lives here.

`Vayl/Features/Settings/Store/SettingsStore.swift` (new):

```swift
//
//  SettingsStore.swift
//  Vayl
//
//  Brain of the Settings vertical. Owns profile-edit persistence + remote push,
//  the share-capacity preference push, sign-out, and account deletion.
//  The views render and forward taps; the Store decides and does I/O.
//
//  Deps injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//  Modeled on HomeStore / PairingStore.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SettingsStore")

@Observable
@MainActor
final class SettingsStore {

    // MARK: - Account-action state (drives the view's confirmations + progress)

    enum AccountPhase: Equatable {
        case idle
        case signingOut
        case deleting
        case error(String)
    }

    private(set) var accountPhase: AccountPhase = .idle

    /// Set true after a successful sign-out or delete so the view can route the user
    /// back out of the app shell. The router reads AuthService/AppState; this is a
    /// belt-and-suspenders signal the SettingsView uses to dismiss immediately.
    private(set) var didLeaveAccount = false

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let authService: AuthService
    private let accountService: AccountService

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        authService: AuthService,
        accountService: AccountService = AccountService()
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.authService = authService
        self.accountService = accountService
    }

    // MARK: - Identity edit (name / pronouns / experience)

    enum IdentityField { case name, pronouns, experience }

    /// Persists an identity edit to local SwiftData, mirrors the name into AppState so the
    /// header + routing update instantly, then pushes the partner-visible fields to remote
    /// `user_profiles`. This is the T5 profile-edit → remote propagation path (the old P3 gap):
    /// name/pronouns push through SyncManager.pushDisplayIdentity, experience through pushNMStage.
    func saveIdentity(field: IdentityField, rawText: String, stage: NMStage) {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            logger.error("saveIdentity — no UserProfile found")
            return
        }

        switch field {
        case .name:
            let trimmed = rawText.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            profile.displayName = trimmed
            appState.displayName = trimmed        // instant header + routing update
        case .pronouns:
            let trimmed = rawText.trimmingCharacters(in: .whitespaces)
            profile.pronouns = trimmed.isEmpty ? [] : trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        case .experience:
            profile.nmStage = stage
        }

        do {
            try context.saveWithLogging()
        } catch {
            logger.error("saveIdentity — local save failed: \(error.localizedDescription)")
            return
        }

        // Remote push (partner-visible fields). Best-effort — SyncManager logs + retries.
        let capturedField = field
        Task {
            switch capturedField {
            case .name, .pronouns:
                await SyncManager.shared.pushDisplayIdentity(localProfile: profile)
            case .experience:
                await SyncManager.shared.pushNMStage(stage.rawValue)
            }
        }
    }

    // MARK: - Privacy preference (share capacity with partner)

    /// Pushes the "share capacity with partner" preference to remote `user_profiles`.
    /// Was called directly from SettingsPrivacyView (H-2 violation) — now routed here.
    func setShareCapacity(_ value: Bool) {
        Task { await SyncManager.shared.pushSharePulse(value) }
    }

    // MARK: - Sign out

    /// Signs out of Supabase and wipes the local store, then returns the user to the
    /// sign-in / onboarding root. Release-safe (no #if DEBUG gate).
    func signOut() async {
        accountPhase = .signingOut
        await accountService.signOut()
        accountService.wipeLocalStore(container: modelContainer)
        resetAppStateAfterLeaving()
        await authService.signOut()   // flips authService.isAuthenticated → false (reactive routing)
        accountPhase = .idle
        didLeaveAccount = true
        logger.info("Sign-out complete")
    }

    // MARK: - Delete account (A1 — hard App Store blocker)

    /// Irreversibly deletes the account. Server hard-deletes the caller's profile row (and
    /// cascades their own artifacts), reverts any partner to unpaired/free, and deletes the
    /// couple when it empties. Only on success do we sign out + wipe local + route out.
    func deleteAccount() async {
        accountPhase = .deleting
        do {
            try await accountService.deleteRemoteAccount()
        } catch {
            accountPhase = .error(error.localizedDescription)
            logger.error("Delete account failed: \(error.localizedDescription)")
            return
        }
        accountService.wipeLocalStore(container: modelContainer)
        resetAppStateAfterLeaving()
        await accountService.signOut()
        await authService.signOut()
        accountPhase = .idle
        didLeaveAccount = true
        logger.info("Account deleted + local cleared")
    }

    // MARK: - Private

    /// Clears in-memory routing so the root re-renders to onboarding / sign-in cleanly.
    private func resetAppStateAfterLeaving() {
        appState.coupleId = nil
        appState.linkState = .unlinked
        appState.displayName = ""
        appState.resetOnboarding(nil, context: nil)   // clears the surface + cache (no profile left)
    }
}
```

**Done:** `SettingsStore` compiles; it exposes `saveIdentity`, `setShareCapacity`, `signOut`,
`deleteAccount`, `accountPhase`, `didLeaveAccount`; no Settings view needs `SyncManager`/`ContentService`
after Segments 3-6.

---

### Segment 3 — Rewire the three Settings views onto `SettingsStore` (H-2)

**One thing:** the views stop calling Services; they hold a `SettingsStore` and call its methods.

**3a. `SettingsView.swift`** — construct + own the Store, drive the two account confirmations through it.

Add near the other `@Environment` declarations (currently `SettingsView.swift:11-15`):

```swift
    @Environment(AppState.self)          private var appState
    @Environment(EntitlementStore.self)  private var entitlements
    @Environment(AuthService.self)       private var authService
    @Environment(\.dismiss)              private var dismiss
    @Environment(\.modelContext)         private var modelContext

    @State private var store: SettingsStore?
```

Materialize the Store once the environment is available (SwiftUI can't build it in a property
initializer because it needs `modelContext.container` + `appState` + `authService`). Add an `.onAppear`
inside the outer `ZStack` in `body`:

```swift
            .onAppear {
                if store == nil {
                    store = SettingsStore(
                        modelContainer: modelContext.container,
                        appState: appState,
                        authService: authService
                    )
                }
            }
            .onChange(of: store?.didLeaveAccount ?? false) { _, left in
                if left, !isTab { dismiss() }   // route out of the pushed Settings; tab-mode root re-renders reactively
            }
```

Replace the Sign-Out confirmation (`SettingsView.swift:88-93`) so it calls the Store and is
unconditional (release-safe — the current working tree already renders it unconditionally; keep it that
way and never re-add a `#if DEBUG` gate around Sign Out):

```swift
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Task { await store?.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can sign back in anytime with the same Apple ID.")
            }
```

Replace the Delete-Account stub (`SettingsView.swift:94-101`) with a real destructive confirmation
(no em dashes in copy):

```swift
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Delete account", role: .destructive) {
                    Task { await store?.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your profile, your Desire Map answers, and your sessions. If you have a partner, they keep their own data and return to being unpaired. This cannot be undone.")
            }
```

Surface a delete/sign-out error (the Store sets `.error`) with an overlaid alert so a failed deletion
isn't silent. Add after the delete alert:

```swift
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { if case .error = store?.accountPhase { return true } else { return false } },
                    set: { _ in store?.clearError() }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if case .error(let message) = store?.accountPhase { Text(message) }
            }
```

Add the tiny helper to `SettingsStore` (Segment 2 class):

```swift
    func clearError() { if case .error = accountPhase { accountPhase = .idle } }
```

**3b. `SettingsView.swift` raw `.sheet` → `.vaylSheet` (H-4).** Replace `SettingsView.swift:72-79`:

```swift
            .vaylSheet(isPresented: $showInvite, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                PairingInviteView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                    .environment(appState)
            }
            .vaylSheet(isPresented: $showJoin, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                PairingJoinView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                    .environment(appState)
            }
```

**3c. `SettingsPrivacyView.swift` (H-2).** It needs the Store. Add a parameter and route `.onChange`
through it (replaces `SettingsPrivacyView.swift:40-42`):

```swift
struct SettingsPrivacyView: View {
    let store: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("screenshotProtectionEnabled") private var screenshotProtection: Bool = true
    @AppStorage("shareCapacityWithPartner")    private var shareCapacity: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Privacy & safety", onBack: { dismiss() }) {
            // … unchanged card content …
        }
        .onChange(of: shareCapacity) { _, newValue in
            store.setShareCapacity(newValue)
        }
    }
}
```

And pass it at the presentation site (`SettingsView.swift:60-62`):

```swift
            .vaylSheet(isPresented: $showPrivacy, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store { SettingsPrivacyView(store: store) }
            }
```

**Done:** No Settings view references `SyncManager` or `ContentService`; `grep -rn "SyncManager\|ContentService" Vayl/Features/Settings` is empty.

---

### Segment 4 — Identity edit sheet: save through the Store, and `.vaylSheet` (H-2 + H-4)

**One thing:** `IdentityEditSheet.save()` no longer touches `context` or `SyncManager`; it calls
`store.saveIdentity(...)`. The presenting `.sheet(item:)` becomes `.vaylSheet`.

`SettingsIdentityView.swift` — thread the Store down. Change the view + the private edit sheet:

```swift
struct SettingsIdentityView: View {
    let store: SettingsStore
    @Environment(AppState.self)  private var appState
    @Environment(\.dismiss)      private var dismiss

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    @State private var editField: IdentityField? = nil
    // … enum + pronounsDisplay unchanged …

    var body: some View {
        SettingsSubScreenShell(title: "You", onBack: { dismiss() }) {
            // … the same Identity card, unchanged …
        }
        .vaylSheet(
            isPresented: Binding(
                get: { editField != nil },
                set: { if !$0 { editField = nil } }
            ),
            heightFraction: 0.5
        ) {
            if let field = editField {
                IdentityEditSheet(field: field, profile: profile, store: store) {
                    editField = nil
                }
            }
        }
    }
}
```

> `.vaylSheet` takes `isPresented: Binding<Bool>`, not `item:` (`VaylPresentation.swift:224`). Bridge the
> `IdentityField?` with the get/set binding above; the content reads the current `editField`.

Rewrite the private `IdentityEditSheet` so `save()` is a single Store call (replaces
`SettingsIdentityView.swift:214-240`; drop the `context` property + the whole `Task { … SyncManager … }`):

```swift
private struct IdentityEditSheet: View {
    let field: SettingsIdentityView.IdentityField
    let profile: UserProfile?
    let store: SettingsStore
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedStage: NMStage = .curious

    // … body / editTextField / experiencePicker / loadCurrentValue unchanged …

    private func commit() {
        let storeField: SettingsStore.IdentityField
        switch field {
        case .name:       storeField = .name
        case .pronouns:   storeField = .pronouns
        case .experience: storeField = .experience
        }
        store.saveIdentity(field: storeField, rawText: text, stage: selectedStage)
        onDone()
        dismiss()
    }
}
```

Point the Save button at `commit()` (was `save(); onSave(); dismiss()` at `SettingsIdentityView.swift:125-129`).

Pass the Store at the presentation site (`SettingsView.swift:57-59`):

```swift
            .vaylSheet(isPresented: $showYou, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store { SettingsIdentityView(store: store) }
            }
```

**Done:** `IdentityEditSheet` has no `ModelContext` / `SyncManager` reference; editing name pushes to
remote `user_profiles` (via `SettingsStore` → `SyncManager.pushDisplayIdentity`), and the header updates
instantly because `saveIdentity` mirrors the name into `appState.displayName`.

---

### Segment 5 — `delete-account` edge function (A1: the hard blocker)

**One thing:** a service-role Deno function that hard-deletes the caller's profile, handles the couple,
and leaves the partner intact-but-unpaired-and-free.

**Semantics (see Open Decision A — recommended default, implemented here):**
1. Resolve caller `authId` from the JWT (userClient), then their `user_profiles` row (`id`, `couple_id`).
2. If in a couple: revert the OTHER member to unpaired/free and **delete the `couples` row**. Deleting the
   couple cascades the couple-scoped tables (`desire_matches`, `desire_map_status`, `desire_reveal_progress`,
   `entitlements`, `card_progress`, `couple_session_records`, `curated_sessions`) — this is correct: shared
   artifacts belong to the dissolved couple, and the partner's own per-user rows
   (`desire_ratings`, `assessment_*`) survive because they FK to `user_profiles`, not `couples`.
   Because `couples.user_a/user_b` are `ON DELETE SET NULL`, we delete the couple row **before** the
   profile so we don't leave a half-null couple.
3. Null the partner's `couple_id` / `is_linked` explicitly (the couple delete does not touch
   `user_profiles`).
4. Delete the caller's `user_profiles` row — Postgres cascades the caller's own `desire_ratings`,
   `assessment_*`, `desire_reveal_progress`.
5. Delete the caller's Supabase **auth** user with the service-role admin API so the same Apple ID starts
   fresh (otherwise a re-sign-in resurrects a ghost auth user with no profile).

`supabase/functions/delete-account/index.ts` (new):

```typescript
// supabase/functions/delete-account/index.ts
//
// Slug: delete-account
//
// HARD-deletes the caller's account (App Store requirement). Service-role so it can
// write cross-partner + delete the auth user. The caller is resolved from their JWT —
// a caller can only ever delete THEIR OWN account (never a target id from the body).
//
// What it touches (verified against prod FKs, project ynhjlabjzauamntbyxdp):
//   • If in a couple: the OTHER member is reverted to unpaired/free (couple_id=null,
//     is_linked=false), then the `couples` row is DELETED. That delete cascades the
//     couple-scoped tables (desire_matches, desire_map_status, desire_reveal_progress,
//     entitlements, card_progress, couple_session_records, curated_sessions).
//   • The caller's `user_profiles` row is DELETED — cascades their own per-user rows
//     (desire_ratings, assessment_responses, assessment_results, desire_reveal_progress).
//   • The caller's auth user is deleted so the same Apple ID re-onboards clean.
// The partner's own artifacts (their desire_ratings, assessment_*) survive.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing authorization header" }, 401)

    // Service client bypasses RLS for the cross-partner + delete writes.
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } },
    )
    // User client validates the caller's identity from their JWT.
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) return json({ error: "Unauthorized" }, 401)
    const callerAuthId = user.id

    // ── Caller's profile (id + couple) ────────────────────────────────
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", callerAuthId)
      .single()
    // No profile row yet? Still delete the auth user so the account is gone.
    if (meErr || !me) {
      await serviceClient.auth.admin.deleteUser(callerAuthId).catch(() => {})
      return json({ deleted: true }, 200)
    }

    // ── Handle the couple (if any) ────────────────────────────────────
    if (me.couple_id) {
      const { data: couple } = await serviceClient
        .from("couples")
        .select("user_a, user_b")
        .eq("id", me.couple_id)
        .single()

      if (couple) {
        const partnerProfileId = couple.user_a === me.id ? couple.user_b : couple.user_a
        if (partnerProfileId) {
          // Revert the partner to unpaired/free. Their own rows are untouched.
          await serviceClient
            .from("user_profiles")
            .update({ couple_id: null, is_linked: false })
            .eq("id", partnerProfileId)
        }
      }

      // Delete the couple BEFORE the profile (user_a/user_b are ON DELETE SET NULL,
      // so deleting the profile first would leave a half-null couple). This cascades
      // all couple-scoped tables.
      const { error: coupleDelErr } = await serviceClient
        .from("couples")
        .delete()
        .eq("id", me.couple_id)
      if (coupleDelErr) return json({ error: "Could not dissolve couple" }, 500)
    }

    // ── Delete the caller's profile (cascades their own per-user rows) ─
    const { error: profileDelErr } = await serviceClient
      .from("user_profiles")
      .delete()
      .eq("id", me.id)
    if (profileDelErr) return json({ error: "Could not delete profile" }, 500)

    // ── Delete the auth user so the same Apple ID re-onboards clean ────
    const { error: authDelErr } = await serviceClient.auth.admin.deleteUser(callerAuthId)
    if (authDelErr) {
      // Profile is already gone; a lingering auth user with no profile is recoverable
      // (ensureRemoteProfile recreates one). Log server-side, still report success.
      console.error("delete-account: auth user delete failed:", authDelErr.message)
    }

    return json({ deleted: true }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
```

**Deploy (Bryan runs — MCP is read-only from Fable):**
```
supabase functions deploy delete-account --project-ref ynhjlabjzauamntbyxdp
```

**Done:** the function is written; a caller can only delete their own account; the partner survives
unpaired/free; an emptied couple + its shared artifacts are gone; the caller's auth user is removed.

---

### Segment 6 — HomeLexicon content fetch → HomeStore (H-2, same debt pocket)

**One thing:** `HomeLexicon` stops calling `ContentService` in a `.task`; `HomeStore` fetches the remote
pool and injects it. **Why HomeStore, not LearnStore:** `HomeLexicon` lives under `Features/Home/`, is
instantiated only by `HomeDashboardView` (`HomeDashboardView.swift:323`), and `HomeStore` already owns
`loadAll()` for exactly this screen's data. Routing it through `HomeStore` keeps one owner per surface;
`LearnStore` never renders the Lexicon.

**6a. `HomeStore.swift`** — add the fetched pool + a loader, call it in `loadAll()`:

```swift
    // MARK: - Lexicon (Home "Today") content

    /// Server-overridden daily-5 content, fetched once per Home appearance. Nil → HomeLexicon
    /// uses its bundled baseline. Owned here so the view never calls ContentService (H-2).
    var lexiconRemotePool: LexiconRemotePool? = nil
```

Add a struct (top-level in the file, near HomeStore) carrying the three fetched arrays so the view stays
declarative:

```swift
/// The three server content arrays HomeLexicon needs to rebuild its pool. Nil arrays mean
/// "no server override for this kind"; the view falls back to bundled JSON per kind.
struct LexiconRemotePool {
    let findings: [ResearchFinding]?
    let terms:    [LexiconTerm]?
    let quotes:   [MediaQuote]?
}
```

Add the loader and call it from `loadAll()` (`HomeStore.swift:180-187`):

```swift
    func loadAll() async {
        await loadProfile()
        await loadDesireStatus()
        resolveRecentDeck()
        await loadDeckProgress()
        await loadReflectionState()
        await loadDeck()
        await loadLexiconContent()
    }

    /// Fetches server-driven daily-5 content. Best-effort — leaves lexiconRemotePool nil on
    /// any failure so HomeLexicon keeps its bundled baseline.
    private func loadLexiconContent() async {
        let f = await ContentService.shared.fetchFindings()
        let t = await ContentService.shared.fetchGlossary()
        let q = await ContentService.shared.fetchQuotes()
        if f != nil || t != nil || q != nil {
            lexiconRemotePool = LexiconRemotePool(findings: f, terms: t, quotes: q)
        }
    }
```

**6b. `HomeLexicon.swift`** — accept the pool, drop the `.task`. Replace the `remotePool` `@State` +
`.task` block (`HomeLexicon.swift:84-89` and `:158-167`):

```swift
struct HomeLexicon: View {

    /// Server-overridden content, injected from HomeStore (nil → bundled baseline).
    var remotePool: LexiconRemotePool? = nil
    /// Tapping a page routes to its destination (the dossier / Learn).
    var onOpen: (() -> Void)? = nil

    // … existing @Environment / @State …

    // Bundled is the instant baseline + offline fallback; the injected remotePool overrides
    // it when present, so the daily-5 can change without an app build.
    private var pool: [Item] {
        guard let remotePool else { return Self.bundledPool }
        return Self.buildPool(
            remoteFindings: remotePool.findings,
            remoteTerms:    remotePool.terms,
            remoteQuotes:   remotePool.quotes
        )
    }
```

Delete the `@State private var remotePool: [Item]? = nil` line and the entire `.task { … ContentService … }`
modifier on `body` (`HomeLexicon.swift:158-167`). Keep the `.sheet(item: $shareImage)` for now — the share
sheet is a system `UIActivityViewController` presentation, out of scope for this plan (flag it, do not
convert it here; see Constraints).

> `buildPool` already takes `remoteFindings/remoteTerms/remoteQuotes` (`HomeLexicon.swift:91-93`), so the
> only change is where the arrays come from.

**6c. `HomeDashboardView.swift:323`** — pass the pool:

```swift
            HomeLexicon(remotePool: store.lexiconRemotePool, onOpen: onOpenLexicon)
```

**Done:** `grep -rn "ContentService" Vayl/Features/Home` matches only `HomeStore.swift`; the Lexicon
still shows bundled content offline and server content when reachable.

---

### Segment 7 — Settings token cleanup (H-4)

**One thing:** replace the ~11 raw `.system(size:)` fonts and the hand-rolled card chrome in Settings.

**7a. `SettingsView.swift` fonts.** Map each `.system(size:weight:)` glyph to the closest AppFonts token
(read `AppFonts.swift` for exact names — `bodyMedium` 15, `caption` 13, `overline` 11, `label` 10):

| Location | Was | Use |
|---|---|---|
| `:120` close X | `.system(size: 13, weight: .semibold)` | `AppFonts.caption` |
| `:186` membership check glyph | `.system(size: 16, weight: .medium)` | `AppFonts.bodyMedium` |
| `:223` sparkles glyph | `.system(size: 13, weight: .medium)` | `AppFonts.caption` |
| `:301` person.fill glyph | `.system(size: 15, weight: .medium)` | `AppFonts.bodyMedium` |
| `:329` chevron | `.system(size: 11, weight: .semibold)` | `AppFonts.overline` |

(Glyphs are decorative SF Symbols; the token sizes are visually equivalent and are what the rest of the
Settings components already use.)

**7b. `SettingsView.swift` hand-rolled card chrome → `.vaylGlassCard()`.** The `membershipCard`'s
locked-state branch (`:249-263`) hand-rolls a `RoundedRectangle(cornerRadius: AppRadius.container)` fill
under `.vaylGlassCard`. Keep the spectrum tint fill (it is intentional premium art, not chrome) but the
badge helpers `spectrumBadge`/`plainBadge` (`:157-176`) hand-roll `Capsule().fill().overlay(strokeBorder)`
— leave those (they are pills, not cards). The two genuinely hand-rolled **card** blocks to convert are
the membership check-icon badge (`:189-194`) and the icon badge only — these are icon chips at
`AppRadius.sm`, not the container card, so they stay. **Net: the only card chrome already goes through
`.vaylGlassCard()`** (`:213`, `:261`, `:336`). The H-4 card-chrome item is therefore satisfied by (i)
confirming every full-width surface uses `.vaylGlassCard()` and (ii) not introducing new raw chrome. If a
raw `RoundedRectangle` container card remains after the font pass, wrap its content in `.vaylGlassCard(radius: AppRadius.container)` and delete the raw fill+overlay.

> This block is deliberately conservative: the file was mid-redesign on 2026-07-01 and already uses
> `.vaylGlassCard()` for its cards. Do not "convert" the icon chips (`AppRadius.sm` badges) or the pill
> capsules — those are not cards. Trust the repo; only replace genuine full-width card chrome.

**7c. `SettingsComponents.swift` + `SettingsAppearanceView.swift` fonts.** These have `.system(size:)`
on decorative glyphs too — convert for consistency:

- `SettingsComponents.swift:61` (nav-row icon) → `AppFonts.bodyMedium`
- `SettingsComponents.swift:88` (nav-row chevron) → `AppFonts.overline`
- `SettingsComponents.swift:114` (toggle-row icon) → `AppFonts.bodyMedium`
- `SettingsAppearanceView.swift:22` (moon glyph) → `AppFonts.bodyMedium`

**7d. `SettingsPartnerView.swift:23,32` raw `.sheet` → `.vaylSheet`** (same treatment as 3b). Read the
file first; it presents `PairingInviteView`/`PairingJoinView` — convert both to `.vaylSheet(isPresented:heightFraction:0.92,screenHeight:…)`.

**Done:** `grep -rn "\.system(size" Vayl/Features/Settings` is empty; `grep -rn "\.sheet(" Vayl/Features/Settings`
returns nothing (the only remaining `.sheet` was `SettingsIdentityView:74`, now `.vaylSheet`).

---

### Segment 8 — Preview + injection wiring

**One thing:** keep the previews compiling with the new Store parameters.

`SettingsView.swift` `#Preview` (`:550-561`) already injects `AppState` / `EntitlementStore` /
`AuthService` / `modelContainer`; no change needed (the Store is built in `.onAppear`). But the
sub-views now REQUIRE a `store:` argument — give their standalone previews one:

```swift
#if DEBUG
#Preview("Identity") {
    let state = AppState()
    let store = SettingsStore(
        modelContainer: .previewContainerWithProfile,
        appState: state,
        authService: AuthService()
    )
    return SettingsIdentityView(store: store)
        .preferredColorScheme(.dark)
        .environment(state)
        .modelContainer(.previewContainerWithProfile)
}
#endif
```

Add an equivalent `store:`-injected preview for `SettingsPrivacyView` if it has one (it currently does
not — no new preview required, just don't leave a broken one).

**Done:** the whole target compiles, including previews.

---

## Definition of Done (build-green)

- [ ] `Vayl/Features/Settings/Store/SettingsStore.swift`, `Vayl/Core/Services/AccountService.swift`, and
      `supabase/functions/delete-account/index.ts` exist and compile.
- [ ] `grep -rn "SyncManager\|ContentService\|\.save()" Vayl/Features/Settings` returns nothing (all
      Service/DB calls moved into `SettingsStore`; the only save is `saveWithLogging` inside the Store).
- [ ] `grep -rn "ContentService" Vayl/Features/Home` matches only `HomeStore.swift`.
- [ ] `grep -rn "\.system(size" Vayl/Features/Settings` returns nothing.
- [ ] `grep -rn "\.sheet(" Vayl/Features/Settings` returns nothing (all `.vaylSheet`).
- [ ] Editing name in Settings updates the header instantly (Store mirrors into `appState.displayName`)
      AND calls `SyncManager.pushDisplayIdentity` (remote `user_profiles.name` updated — the P3 gap closed).
- [ ] Sign Out is present in release (no `#if DEBUG` around it) and routes back to sign-in / onboarding.
- [ ] Delete Account presents a destructive confirmation with no em dashes, calls the edge function, and
      on success wipes local + signs out + routes out; on failure shows an error alert (not silent).
- [ ] The `delete-account` function resolves the caller from the JWT (never a body id), deletes the couple
      before the profile, reverts the partner to unpaired/free, and deletes the auth user.
- [ ] HomeLexicon still renders bundled content with no server (nil pool) and server content when
      `HomeStore.lexiconRemotePool` is set.

---

## Bryan verifies on device

- [ ] Settings tab + pushed Settings both render; header shows the current display name.
- [ ] **Profile edit:** change name → header updates immediately. Confirm remotely that
      `user_profiles.name` changed for your auth id (Supabase table view). Change pronouns → the row
      updates. Change Experience → `nm_stage` updates.
- [ ] **Share capacity** toggle flips `user_profiles.share_pulse_with_partner`.
- [ ] **Sign Out** → returns to Sign In; signing back in with the same Apple ID lands you correctly
      (profile re-hydrates or re-onboards).
- [ ] **Delete Account** (two-device, use a throwaway paired couple):
      - Delete on device A → device A returns to onboarding/sign-in with a clean local store.
      - Device B (partner) is now unpaired + free; device B's own Desire Map answers still exist; the
        shared match/reveal is gone.
      - Confirm in Supabase: device A's `user_profiles` row, the `couples` row, and device A's auth user
        are all gone; device A's `desire_ratings` are gone; device B's `desire_ratings` remain.
      - Re-sign-in on device A with the same Apple ID starts a fresh account (no ghost).
- [ ] 🎚️ Sheet heights + the delete-confirm copy feel right (defaults: identity edit `0.5`, others `0.92`).
- [ ] Reduce Motion on: sheets + Lexicon still behave (no animation regressions from the rewire).

---

## Constraints / do-not-touch

- **Views call `SettingsStore` only.** No Settings view may import `Supabase`, reference `SyncManager`,
  `ProfileService`, `ContentService`, or call `context.save()` after this pass.
- **Do not touch** `VaylPresentation.swift`, `AppFonts.swift`, `AppColors.swift`, `SyncManager.swift`,
  `ProfileService.swift`, `PairingService.swift`, or the pairing edge functions. This plan consumes them,
  it does not modify them. (`ProfileService.updateIdentity/updateNMStage/updateSharePulse` already do
  exactly what's needed.)
- **Do not convert** the `HomeLexicon` `.sheet(item: $shareImage)` (system share sheet) or its bundled
  content pipeline — only the `ContentService` fetch moves. The share sheet stays.
- **Do not add bottom clearance** in any Settings view — `AppShell`'s `.safeAreaInset` owns the tab-bar
  inset; the sub-screens are `.vaylSheet` overlays, which own their own layout.
- **Keep Sign Out unconditional** (release-safe). Never re-introduce a `#if DEBUG` gate around it.
- **`recompute_couple_entitlement`** is NOT called from `delete-account` — the couple is deleted outright,
  so there's no couple left to recompute. (Grant/pairing paths still use it; unchanged.)
- **No new SwiftData model, no schema migration.** The wipe uses `context.delete(model:)` over the
  existing `SchemaV1.models`.

---

## Open decisions (each with a recommended default — Fable proceeds on the default and flags it)

**A. Couple-deletion semantics: dissolve the couple, or keep it half-populated?**
_Recommendation (implemented): **dissolve** — delete the `couples` row and revert the partner to
unpaired/free._ The alternative (null one side of `couples`, keep the row) leaves a permanently
half-populated couple that every partner-facing query (`get-partner`, entitlement resolve) has to defend
against, and strands the shared entitlement in an un-recomputable state. Dissolving is cleaner and matches
the product stance ("a breakup needs no in-app fanfare; quiet data hygiene"). The partner's OWN artifacts
survive because they FK to `user_profiles`, not `couples`. **Flag for Bryan:** this means the partner
loses the shared match/reveal and the couple's Core entitlement (payer-portable: if the partner was the
buyer, their StoreKit ownership re-grants Core on their next pairing via `recompute_couple_entitlement`;
if the DELETED user was the buyer, the entitlement is gone with them — acceptable for V1, App Store
compliant). If Bryan wants the partner to retain Core, that needs a separate "transfer entitlement on
dissolve" story — out of scope here.

**B. Hard delete vs anonymize.**
_Recommendation (implemented): **hard delete** for V1._ Simpler, cleaner compliance story (App Review and
GDPR/CCPA both accept "we delete your data"), and Vayl has no analytics dependency on retained rows. The
anonymize path (blank the PII, keep the row for referential integrity) buys nothing here because the
schema already cascades cleanly and there are no aggregate reports keyed on deleted users. **Flag:** if a
future need arises to keep couple-level aggregates after one partner leaves, revisit — but do not
pre-build it.

**C. Delete the Supabase auth user, or just the profile?**
_Recommendation (implemented): **delete the auth user too** (`auth.admin.deleteUser`)._ Leaving the auth
user orphaned means a re-sign-in with the same Apple ID resurrects a session with no profile;
`ensureRemoteProfile` would recreate a blank profile, which reads as "my account came back." Deleting the
auth user makes the same Apple ID a genuinely fresh account. **Flag:** if Apple's Sign-in-with-Apple
token revocation is later required for full compliance (revoking the app's token server-side), that's an
additional `POST` to Apple's `revoke` endpoint — note it as a possible follow-up; the local + Supabase
deletion already satisfies the App Store "delete account" requirement.

**D. `pairing_codes` schema drift (informational, not blocking).**
`create-pair/index.ts` (legacy) uses `pairing_codes.user_id` + a `used` column; the live `rapid-task`
(the slug the app actually invokes) uses `created_by` + `claimed_by is null` + deletes the code.
`ProfileService.lookupPairingCode` also uses `created_by`. This plan does not touch pairing, but **flag**
that `create-pair` is dead/stale relative to `rapid-task` — a separate cleanup, not this pass.
**Resolved 2026-07-01:** verified no callers (app invokes `rapid-task`; no edge function or Swift code
references `create-pair`), then deleted `supabase/functions/create-pair/` and its `config.toml` block.
If the function is still deployed on prod project `ynhjlabjzauamntbyxdp`, undeploy it manually
(`supabase functions delete create-pair`); MCP is read-only.
