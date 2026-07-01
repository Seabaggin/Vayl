# 09 · Session Entry, Lobby & Airlock — Real UI (roadmap S3)

**Goal:** Wire real entry into a couple card session from **Home** and the **Deck Library (Play)** — including an open-session fetch on appear / foreground and a partner "pending session" banner — replace the `#if DEBUG` presence harness with a real **`SessionLobbyView`** (the shape the joining partner consents to) feeding into the existing **`AirlockView`** (presence + bandwidth + hold + consent), persist the bandwidth reading via **`LockInSession`**, and reconcile `AppShell`'s local `@State selectedTab` with `appState.selectedTab` so a partner can actually be routed into a pending session. All built in one pass, compiling green, driving to a placeholder "active" screen locally.

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

## ⚠️ ONE-SHOT CAVEAT — the "both here" beat is a two-device handshake

Read this before you build. The Airlock's **"both here"** presence and the joining-partner's live
consent are a **two-device beat**. Fable builds the UI + local wiring in one pass, but the **real presence
handshake depends on S2 (plan 08 — realtime session service consumption)** and needs two physical
phones + Bryan's hands. Today `CoupleSessionStore` **mocks** partner presence and the partner's release
point (`armPresence()` flips `partnerPresent = true` after `presenceSeconds`; `AirlockView.release(...)`
fakes the partner's release with a random offset). **Do not try to make presence real here.** Keep the
mock; build the UI that will consume it.

**Definition of Done for this plan:**
- Build is green.
- From **Home** and from the **Deck Library**, a partner "pending session" banner appears when a mock
  open session exists, and tapping it presents the session `.vaylCover`.
- The new **`SessionLobbyView`** (session-shape consent screen for the joiner) drives into the existing
  **`AirlockView`**, which drives to a **placeholder "active" screen** locally (the `.session` phase's
  existing `SessionPlayerView` is fine as the placeholder — **do not rebuild the player here**).
- `LockInSession` is persisted with the pre-session bandwidth reading.
- The `#if DEBUG` `PresenceDebugView` harness is deleted (superseded by the real lobby).

**Two-device presence proof goes in Bryan's checklist, not this build.** The **Player is S4 (plan 10)** —
navigate to the existing `SessionPlayerView` as a placeholder; do not build or restyle the player.
**`PlayView`'s generative deck surface (masthead / hero / deck wall / ceremony) is off-limits** — you add
one banner and one open-session fetch, nothing else on that screen.

---

## Context Fable needs

- **What this is:** the *entry + airlock* half of the in-person couple card session (roadmap **S3**). The
  session itself is a single protected `.vaylCover` whose phase machine already exists:
  `airlock → transition → session → close → done`, owned by one store. This plan does not touch that
  machine's internals — it adds the *entry* into it (open-session fetch + pending banner + a lobby the
  joiner consents through) and the `LockInSession` write.
- **Current state — MOST OF THE SESSION UI ALREADY EXISTS (verified 2026-07-01).** The roadmap's old
  names (`AirlockStore`, `SessionStore`, `SessionView`) are **stale** — `AirlockStore` was never created,
  and the legacy stores were deleted. The real `Vayl/Features/Sessions/` folder is:
  - `CoupleSessionStore.swift` — `@Observable @MainActor final class`; owns the whole cover: phase enum
    `{ airlock, transition, session, close, done }`, `Bandwidth { light, open, deep }`, mock
    `partnerPresent` / `partnerBandwidth`, `armPresence()`, `setBandwidth(_:)`, `confirmSynced()`,
    `persistSession()`, `persistReflection()`. **This is the brain — model the lobby on it, extend it.**
  - `CardSessionContainerView.swift` — the single `.vaylCover` destination. Builds the store from the
    environment in `.task`, and `CoupleSessionFlow` switches `store.phase` → screen.
  - `AirlockView.swift` — **fully built**: 2×2 house-rules grid, a private bandwidth chip row
    (`store.bandwidth`), a hold-and-release **sync ring** (~3.2s fill, ±0.13 release tolerance), a
    presence row ("You" / "Partner"), and a tutorial `.vaylSheet`. It calls `store.armPresence()`,
    `store.setBandwidth(_:)`, `store.confirmSynced()`. **Do not rebuild it — feed it.**
  - `SessionPlayerView.swift` — the in-session player (S4 territory; use as the placeholder "active"
    screen, do not touch).
  - `SessionCloseView.swift`, `SessionAtmosphere.swift`, `SessionPlan.swift`, and
    `Debug/PresenceDebugView.swift` (the throwaway `#if DEBUG` presence harness to **delete**).
- **How a session is entered TODAY (two parallel `.vaylCover` sites, both present
  `CardSessionContainerView(hand:)`):**
  1. **Play** (`Vayl/Features/Play/PlayView.swift:83`) — `.vaylCover(isPresented: store.sessionHand != nil)`.
     `PlayStore.beginCeremony(_:)` → `ceremonyFinished()` sets `sessionHand = deck.orderedCards`;
     `endSession()` clears it. (`PlayStore` has no `beginSession` — the entry is `beginCeremony` →
     `ceremonyFinished`, plus a Reduce-Motion `begin(_:)` fallback.)
  2. **Home** (`Vayl/Features/Home/Views/HomeDashboardView.swift:267`) — a local
     `@State private var sessionHand: [Card]?`; the "Settle in" bar calls `settleIn()` (line 407) which
     sets `sessionHand = hand`; the `.vaylCover` presents `CardSessionContainerView(hand:)`.
  Both are **initiator-side** entries (you start a hand). Neither fetches an *open* session, and neither
  shows a **pending-session banner** for the *joining* partner. That is the gap S3 fills.
- **The routing bug S3 flags (verified):** `AppShell` (`Vayl/App/AppShell.swift:11`) switches on a
  **local** `@State private var selectedTab: AppTab = .home` and **never reads `appState.selectedTab`**.
  But `HomeRouterView` writes `appState.selectedTab = .map / .learn / .settings` for its nav actions
  (HomeRouterView lines 217-224). Those writes are **silently dead today** because AppShell ignores them.
  To route a *joining partner* into a pending session (or onto the tab that shows the banner), AppShell's
  `selectedTab` must reconcile with `appState.selectedTab`. `AppState` already has the field
  (`AppState.swift:80 var selectedTab: AppTab = .home`) and a proven transient-signal pattern next to it
  (`vaultOpenPending`, `AppState.swift:83`).
- **`LockInSession` EXISTS but is NOT persisted today** (`Vayl/Core/Models/LockInSession.swift`, registered
  in `App/ModelContainer.swift`). It's a device-only `@Model`: `cardSessionId`, `partnerABandwidth`,
  `partnerBBandwidth`, `bandwidthGap` (computed once), `isLDR`, timestamps, `init(cardSessionId:bandwidthA:bandwidthB:isLDR:)`.
  `CoupleSessionStore.persistSession()` currently writes `CardSession.lockInBandwidthA/B` **inline** but
  never creates a `LockInSession` row. This plan adds that write.
- **The open-session Service already exists** — `Vayl/Core/Services/RealtimeSessionService.swift`:
  `fetchOpenSession(coupleId:) async throws -> CuratedSessionDTO?` (line 176, filters status in
  `CuratedSessionStatus.openStatuses` = `["lobby","airlock","active","paused"]`), plus `openSession(...)`,
  `setPresence`, `setConsent`, `setBandwidth`, `setStatus`. **A View never calls this — a Store does.**
  For S3 the *fetch* is wired through a lightweight store, but stays a **mock** by default (no network) so
  the front-end is solo-verifiable, exactly like `CoupleSessionStore`'s realtime scaffold.
- **Canonical patterns to imitate:**
  - **Store:** model the new `SessionEntryStore` on `CoupleSessionStore.swift` (dependency-injected init,
    `@Observable @MainActor final class`, `ModelContext(modelContainer)` created fresh at write time,
    an injected default-nil `RealtimeSessionService` so the local path is pure).
  - **Lobby / airlock view chrome:** model `SessionLobbyView` on `AirlockView.swift` — same `boxBackground`,
    `AppColors.spectrumBorder`, presence chip, `.vaylSheet` tutorial idiom, and `.screenshotProtected()`.
  - **Presentation:** `.vaylCover` per `VaylPresentation.swift` (Card Session is always a cover).
  - **Empty / pending banner:** the reflection banner pattern in `HomeDashboardView.swift:363`
    (`reflectionBanner`, top-anchored, `.move(edge: .top)` transition) is the closest existing chrome.
  - **Screenshot protection:** `.screenshotProtected()` (`ScreenshotProtectionModifier.swift`), already
    used on `SessionPlayerView`, `DesireMapView`, `PaywallSheet`.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/SessionEntryStore.swift` | `@Observable @MainActor final class` — owns open-session polling for Home + Play. Injected `RealtimeSessionService?` (default nil ⇒ local mock), `AppState`, `ModelContainer`. Exposes `pendingSession: PendingSession?`, `refresh()` (call on appear + `scenePhase == .active`), and `enterHand: [Card]?` set when the user accepts a pending session. Mocks a pending session locally so the banner is solo-demoable. |
| `Vayl/Features/Sessions/SessionLobbyView.swift` | The **joining** partner's consent screen: the session *shape* (deck title, card count, who invited, est. time) + a single "I'm in" consent CTA. Rendered as the `.airlock` phase's **pre-roll** when the store enters as a joiner. `.screenshotProtected()`. Drives into `AirlockView` on consent. |
| `Vayl/Features/Sessions/Components/PendingSessionBanner.swift` | Top-anchored banner: "\(partner) started a session · tap to join". Reused by Home and the Deck Library. Press-state + haptic + action, per the tap contract. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/App/AppShell.swift` | `:11` (`@State private var selectedTab`), `:21-52` (`body`) | Reconcile the local `selectedTab` with `appState.selectedTab`: read `appState.selectedTab` to drive the switch, mirror it into the `RacetrackTabBar` binding, and `.onChange` sync both directions. This is what lets a joining partner be routed onto the tab that shows the pending banner. |
| `Vayl/Features/Sessions/CoupleSessionStore.swift` | init `:111-138`, `confirmSynced()` `:176-184`, `persistSession()` `:315-380` | Add an `entryRole` (`.initiator` / `.joiner`) so the container can show the lobby pre-roll for a joiner; add a `LockInSession` write in `persistSession()` (currently only sets `CardSession.lockInBandwidthA/B`). |
| `Vayl/Features/Sessions/CardSessionContainerView.swift` | `content` `:83-97`, `.airlock` case `:86-87` | For a **joiner**, render `SessionLobbyView` before `AirlockView` (a `store.consented` gate inside the `.airlock` phase — not a new `Phase` case). Initiator path unchanged. |
| `Vayl/Features/Home/Views/HomeDashboardView.swift` | banner region near `reflectionBanner` `:363`, `.task`/`scenePhase` | Add a `SessionEntryStore`, an `.onAppear`/`scenePhase == .active` `refresh()`, a `PendingSessionBanner` overlay when `pendingSession != nil`, and route accept → set the existing `sessionHand`. |
| `Vayl/Features/Play/PlayView.swift` | `content` `:46-101`, existing `.vaylCover` `:83` | Add the same `SessionEntryStore` + `refresh()` on appear/foreground + `PendingSessionBanner` overlay; accept → set `store.sessionHand`. **Do not touch the masthead / hero / deck wall / ceremony.** |

### Delete

| File | Why |
|---|---|
| `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` | The throwaway `#if DEBUG` B1 presence harness (its own header says "Delete once AirlockStore (B3) owns the real channel lifecycle"). `SessionLobbyView` + the real entry supersede it. Confirm no non-DEBUG references before deleting (it is `#if DEBUG`-guarded, so there should be none). |

---

## Build steps (segments)

> All segments are built in ONE pass. They are ordered for readability. Real tokens throughout — read
> `Vayl/App/Theme/*` before using any token; the ones named below (`AppColors.spectrumBorder`,
> `AppColors.cardBg`, `AppColors.textPrimary/Secondary/Body`, `AppFonts.sectionHeading/caption/screenTitle/buttonLabelSmall`,
> `AppSpacing.*`, `AppRadius.container/lg`, `AppAnimation.slow/spring/enter`) are all verified present.

### Segment 1 — `SessionEntryStore` (open-session fetch, local-mocked)

**One thing:** a small store both Home and Play own that answers "is there an open session to join?" —
mocked locally by default, real `fetchOpenSession` behind an injected service.

Create `Vayl/Features/Sessions/SessionEntryStore.swift`:

```swift
//
//  SessionEntryStore.swift
//  Vayl
//
//  Answers one question for Home + the Deck Library: "is there an open session
//  waiting to be joined?" Owns the open-session poll (on appear + on foreground)
//  and the accepted hand.
//
//  FRONT-END / LOCAL: partner-started sessions are MOCKED here by default (no
//  Realtime). Injecting a RealtimeSessionService swaps fetchOpenSession in as a
//  one-layer change — the views never learn the difference. Mirrors the mock
//  discipline in CoupleSessionStore. See
//  docs/superpowers/specs/2026-06-21-couple-session-quickplay-implementation-spec.md.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionEntryStore")

@Observable
@MainActor
final class SessionEntryStore {

    /// The shape a joiner sees before consenting — enough to decide, nothing more.
    struct PendingSession: Identifiable, Equatable {
        let id: UUID
        let initiatorName: String
        let deckTitle: String
        let hand: [Card]
        var cardCount: Int { hand.count }
        var estimatedMinutes: Int { max(1, hand.count * 2) }
    }

    /// Non-nil ⇒ a partner-started session is waiting. Drives the pending banner.
    private(set) var pendingSession: PendingSession?

    /// Set when the user accepts the pending session — the host view presents the cover.
    var acceptedHand: [Card]?

    // MARK: - Dependencies
    private let modelContainer: ModelContainer
    private let appState: AppState
    /// Default nil = pure-local (mock). Injected real service = live fetchOpenSession.
    private let realtime: RealtimeSessionService?
    /// Resolves a deck's cards from its id (the mock + the real path both need it).
    private let loadDeck: (String) -> [Card]

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        realtime: RealtimeSessionService? = nil,
        loadDeck: ((String) -> [Card])? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.realtime = realtime
        self.loadDeck = loadDeck ?? { deckId in
            (try? DeckCatalogService().loadDeck(id: deckId))?.orderedCards ?? []
        }
    }

    /// Poll for an open session. Call on appear and when the scene becomes active.
    func refresh() {
        guard let coupleId = appState.coupleId else { pendingSession = nil; return }

        // Real path (injected service, Realtime segments). One-layer swap.
        if let realtime {
            Task { @MainActor in
                do {
                    guard let dto = try await realtime.fetchOpenSession(coupleId: coupleId) else {
                        pendingSession = nil; return
                    }
                    let hand = loadDeck(dto.deckId)
                    guard !hand.isEmpty else { pendingSession = nil; return }
                    pendingSession = PendingSession(
                        id: dto.id,
                        initiatorName: appState.partnerDisplayName ?? "Your partner",
                        deckTitle: hand.first?.deckId ?? dto.deckId,
                        hand: hand
                    )
                } catch {
                    logger.warning("fetchOpenSession failed: \(error.localizedDescription)")
                    pendingSession = nil
                }
            }
            return
        }

        // Local mock path (default): no partner has "started" anything, so no banner.
        // Bryan flips `debugSeedPending` in a #if DEBUG control to feel the banner solo.
        #if DEBUG
        if debugSeedPending, pendingSession == nil {
            let hand = loadDeck("the-opener")
            if !hand.isEmpty {
                pendingSession = PendingSession(
                    id: UUID(),
                    initiatorName: appState.partnerDisplayName ?? "Your partner",
                    deckTitle: hand.first?.deckId ?? "the-opener",
                    hand: hand
                )
            }
        }
        #endif
    }

    /// Accept the pending session — the host view reads `acceptedHand` and presents the cover.
    func accept() {
        guard let pending = pendingSession else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        acceptedHand = pending.hand
    }

    func dismissBanner() { pendingSession = nil }

    #if DEBUG
    /// Debug-only: seed a fake pending session so the banner is feelable on one device.
    var debugSeedPending = false
    #endif
}
```

> **Note on `appState.partnerDisplayName`:** verify this exists on `AppState`. If it does NOT (only
> `displayName` is confirmed at `AppState.swift:37`), fall back to `"Your partner"` and drop the
> optional — do **not** invent a property. See Open Decisions.

**Done:** compiles; `refresh()` returns nil in the pure-local path (no banner), and a `#if DEBUG`
`debugSeedPending` toggle produces one.

---

### Segment 2 — `PendingSessionBanner` (shared, top-anchored)

**One thing:** the banner that tells a joining partner a session is waiting — one component, reused by
Home and Play. Models the reflection-banner idiom.

Create `Vayl/Features/Sessions/Components/PendingSessionBanner.swift`:

```swift
//
//  PendingSessionBanner.swift
//  Vayl
//
//  "Your partner started a session · tap to join." Top-anchored, dismissible,
//  reused by Home and the Deck Library. Purely presentational — the accept /
//  dismiss decisions live in SessionEntryStore.
//

import SwiftUI

struct PendingSessionBanner: View {

    let initiatorName: String
    let cardCount: Int
    let estimatedMinutes: Int
    let onJoin: () -> Void
    let onDismiss: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(initiatorName) started a session")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Text("\(cardCount) \(cardCount == 1 ? "card" : "cards") · ~\(estimatedMinutes) min · tap to join")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .sensoryFeedback(.impact(.light), trigger: isPressed)
        .contentShape(Rectangle())
        .onTapGesture { onJoin() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview("Pending banner") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PendingSessionBanner(
            initiatorName: "Alex",
            cardCount: 8,
            estimatedMinutes: 16,
            onJoin: {},
            onDismiss: {}
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
```

**Done:** the banner renders top-anchored with a spectrum edge; tap fires `onJoin`, the x fires
`onDismiss`; press-state + haptic present.

---

### Segment 3 — `SessionLobbyView` (the joiner's consent screen)

**One thing:** before the sync ring, a joining partner sees the *shape* they're consenting to (deck, count,
who invited, est. time) and taps one "I'm in". Models `AirlockView`'s chrome; `.screenshotProtected()`.

Create `Vayl/Features/Sessions/SessionLobbyView.swift`:

```swift
//
//  SessionLobbyView.swift
//  Vayl
//
//  Pre-roll of the couple session cover for the JOINING partner: the session
//  shape they consent to before the airlock. Deck, card count, who invited,
//  est. time — then one "I'm in". Consent flips the store into the airlock's
//  sync ring. The initiator skips this screen (they already chose the hand).
//
//  Models AirlockView's chrome (boxBackground, spectrumBorder, presence idiom).
//  Faithful in spirit to the airlock house-rules card. .screenshotProtected().
//

import SwiftUI

struct SessionLobbyView: View {

    @Bindable var store: CoupleSessionStore

    @Environment(\.vaylDismiss) private var vaylDismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            header

            Text("You've been invited in")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.md)

            shapeCard

            Spacer(minLength: 0)

            consentCTA
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .screenshotProtected()
    }

    private var header: some View {
        HStack {
            Button { vaylDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.cardBackground))
                    .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("The Opener · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards")")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var shapeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            shapeRow(icon: "rectangle.stack", label: "Deck", value: "The Opener")
            shapeRow(icon: "square.grid.2x2", label: "Cards",
                     value: "\(store.hand.count)")
            shapeRow(icon: "clock", label: "Roughly",
                     value: "~\(max(1, store.hand.count * 2)) min")
            shapeRow(icon: "person.2", label: "Together", value: "in person, phones down")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 0.8)
                )
        )
    }

    private func shapeRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.spectrumText)
                .frame(width: 22)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
        }
    }

    private var consentCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(AppAnimation.slow) { store.consentToJoin() }
        } label: {
            Text("I'm in")
                .font(AppFonts.ctaLabel)
                .foregroundStyle(AppColors.void)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(AppColors.spectrumBorder)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Session Lobby") {
    ZStack {
        SessionAtmosphere()
        SessionLobbyView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ))
    }
    .preferredColorScheme(.dark)
}
```

> Verify `AppColors.spectrumText`, `AppFonts.ctaLabel`, `AppColors.cardBackground`, `AppColors.borderDefault`
> against the theme files — all appear in `AirlockView`, so they exist, but confirm before use. If any
> token differs, trust the theme file, not this snippet.

**Done:** the lobby renders the session shape; "I'm in" calls `store.consentToJoin()`; back calls
`vaylDismiss()`; `.screenshotProtected()` is applied.

---

### Segment 4 — `CoupleSessionStore`: entry role, consent gate, `LockInSession` write

**One thing:** teach the store who is entering (initiator vs joiner), a `consented` gate for the lobby
pre-roll, and add the missing `LockInSession` persistence.

In `Vayl/Features/Sessions/CoupleSessionStore.swift`:

**(a)** Add the entry role + consent state near the airlock state (after line 62):

```swift
    /// Who is entering this cover. A joiner sees the lobby consent pre-roll before
    /// the airlock; an initiator (chose the hand) goes straight to the airlock.
    enum EntryRole { case initiator, joiner }
    let entryRole: EntryRole

    /// The joiner consented in the lobby → show the airlock. Always true for an initiator.
    private(set) var consented: Bool

    /// The lobby's "I'm in" — cross from the lobby pre-roll into the airlock.
    func consentToJoin() {
        guard phase == .airlock, entryRole == .joiner else { return }
        consented = true
    }
```

**(b)** Thread `entryRole` through the init (add a parameter with an initiator default so existing
call sites are unaffected). In the init signature (line ~111) add:

```swift
        entryRole: EntryRole = .initiator,
```

and in the body (after `self.hand = hand`, line ~123) add:

```swift
        self.entryRole = entryRole
        self.consented = (entryRole == .initiator)
```

**(c)** In `persistSession()` (line 315), after the existing `try context.saveWithLogging()` and
`savedSessionId = session.id` (line ~367), add the `LockInSession` write against the just-saved session:

```swift
            // Pre-session bandwidth reading, device-only (never synced). One Lock In
            // feeds CardSession.lockInBandwidthA/B (above) AND its own row for Pulse history.
            let lockIn = LockInSession(
                cardSessionId: session.id,
                bandwidthA: partnerBandwidth.fraction,
                bandwidthB: bandwidth.fraction,
                isLDR: false
            )
            lockIn.completedAt = Date()
            context.insert(lockIn)
            try context.saveWithLogging()
            logger.info("lock-in saved — gap \(lockIn.bandwidthGap)")
```

> The `CardSession` write already sets `lockInBandwidthA = partnerBandwidth.fraction` and
> `lockInBandwidthB = bandwidth.fraction` (lines 330-331) — the `LockInSession` mirrors that same A/B
> convention so the two never disagree.

**Done:** store compiles; an initiator has `consented == true`; a joiner starts `false` until
`consentToJoin()`; finishing a session writes a `LockInSession` row alongside the `CardSession`.

---

### Segment 5 — `CardSessionContainerView`: lobby pre-roll for a joiner

**One thing:** in the `.airlock` phase, show `SessionLobbyView` until a joiner consents, then the existing
`AirlockView`. Initiator path is byte-for-byte unchanged.

In `Vayl/Features/Sessions/CardSessionContainerView.swift`, thread `entryRole` into the store build
(`.task`, line 35) and branch the `.airlock` case (line 86).

**(a)** Give the container an `entryRole` (default `.initiator` so the existing Home/Play call sites need
no change):

```swift
struct CardSessionContainerView: View {

    /// Tonight's hand, dealt from the carousel.
    let hand: [Card]
    /// Who is entering — a joiner sees the lobby pre-roll; an initiator skips it.
    var entryRole: CoupleSessionStore.EntryRole = .initiator
```

and pass it into the store:

```swift
        .task {
            if store == nil {
                store = CoupleSessionStore(
                    hand: hand,
                    modelContainer: modelContext.container,
                    appState: appState,
                    entryRole: entryRole
                )
            }
        }
```

**(b)** In `CoupleSessionFlow.content` (line 83), branch the `.airlock` case on `store.consented`:

```swift
        case .airlock:
            if store.consented {
                AirlockView(store: store).transition(.opacity)
            } else {
                SessionLobbyView(store: store).transition(.opacity)
            }
```

**Done:** an initiator sees the airlock immediately (unchanged); a joiner sees the lobby, and "I'm in"
transitions to the airlock; the ring drives to `.session` (the existing `SessionPlayerView` placeholder)
via the store's mock `confirmSynced()`.

---

### Segment 6 — Home entry: open-session fetch + pending banner

**One thing:** Home fetches an open session on appear + foreground and shows the `PendingSessionBanner`;
accepting sets the existing `sessionHand`. **The initiator "Settle in" flow stays exactly as-is.**

In `Vayl/Features/Home/Views/HomeDashboardView.swift`:

**(a)** Add the entry store + scene phase near the existing `@State private var sessionHand` (line 101).
The view already receives `AppState` + a model container in its preview seam (see the file's footer note
at line 599) — build the store the same way the `.vaylCover`'s `CardSessionContainerView` already reads
those from the environment. Add:

```swift
    @Environment(\.scenePhase) private var scenePhase
    @State private var entryStore: SessionEntryStore?
```

Build it once (mirror how the file already threads `appState` / model container for the cover). In the
outer view that owns `appState` + `modelContext` (the same scope that presents the `.vaylCover` at line
267), on `.onAppear`:

```swift
            .onAppear {
                if entryStore == nil {
                    entryStore = SessionEntryStore(
                        modelContainer: modelContext.container,
                        appState: appState
                    )
                }
                entryStore?.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { entryStore?.refresh() }
            }
            .onChange(of: entryStore?.acceptedHand) { _, hand in
                if let hand { sessionHand = hand; entryStore?.acceptedHand = nil }
            }
```

**(b)** Overlay the banner above the dashboard (top-anchored, like `reflectionBanner` at line 363):

```swift
    @ViewBuilder
    private var pendingSessionBanner: some View {
        if let pending = entryStore?.pendingSession {
            VStack {
                PendingSessionBanner(
                    initiatorName: pending.initiatorName,
                    cardCount: pending.cardCount,
                    estimatedMinutes: pending.estimatedMinutes,
                    onJoin: { entryStore?.accept() },
                    onDismiss: { entryStore?.dismissBanner() }
                )
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal:   .move(edge: .top).combined(with: .opacity)
            ))
            .animation(AppAnimation.spring, value: entryStore?.pendingSession)
            .zIndex(2)
        }
    }
```

and add `pendingSessionBanner` to the same ZStack that hosts `reflectionBanner`.

> **Joiner presents the lobby, not "Settle in".** The Home `.vaylCover` (line 267) currently builds
> `CardSessionContainerView(hand: sessionHand ?? [])` with the default `.initiator` role. Because the
> accept-path here comes from a *partner-started* session, pass `entryRole: .joiner` on that cover so the
> lobby pre-roll shows. Distinguish the two by adding a sibling `@State private var joinerHand: [Card]?`
> set on accept (and clearing `sessionHand`'s initiator use), OR a single `@State private var entryRole`
> flag set alongside `sessionHand`. Recommended default: a `@State private var sessionEntryRole: CoupleSessionStore.EntryRole = .initiator`
> set to `.joiner` in the `onChange(of: acceptedHand)` handler, then
> `CardSessionContainerView(hand: sessionHand ?? [], entryRole: sessionEntryRole)`.

**Done:** with a seeded pending session, Home shows the banner; tapping it presents the cover into the
lobby → airlock; the initiator "Settle in" path is unchanged.

---

### Segment 7 — Deck Library (Play) entry: same fetch + banner

**One thing:** the Deck Library gets the identical open-session fetch + `PendingSessionBanner`, accepting
into `store.sessionHand`. **Touch nothing else on `PlayView`.**

In `Vayl/Features/Play/PlayView.swift`, add to the `content(_:)` ZStack (line 46) — parallel to Home:

```swift
    @Environment(\.scenePhase) private var scenePhase
    @State private var entryStore: SessionEntryStore?
    @State private var sessionEntryRole: CoupleSessionStore.EntryRole = .initiator
```

Wire the fetch on the same `.task`/appear that builds `PlayStore` (line 38) — build `entryStore` next to
it and call `refresh()`; re-`refresh()` on `scenePhase == .active`; on accept set
`store.sessionHand = hand` and `sessionEntryRole = .joiner`. Overlay the banner top-anchored inside the
`ZStack(alignment: .top)` (line 47) with `.zIndex(20)` (above the ceremony's `.zIndex(10)`):

```swift
            if let pending = entryStore?.pendingSession {
                VStack {
                    PendingSessionBanner(
                        initiatorName: pending.initiatorName,
                        cardCount: pending.cardCount,
                        estimatedMinutes: pending.estimatedMinutes,
                        onJoin: { entryStore?.accept() },
                        onDismiss: { entryStore?.dismissBanner() }
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(AppAnimation.spring, value: entryStore?.pendingSession)
                .zIndex(20)
            }
```

Update the existing session cover (line 83) to pass the role:

```swift
        .vaylCover(isPresented: Binding(
            get: { store.sessionHand != nil },
            set: { if !$0 { store.endSession(); sessionEntryRole = .initiator } }
        )) {
            CardSessionContainerView(hand: store.sessionHand ?? [], entryRole: sessionEntryRole)
        }
```

Add the accept handler where the entry store is built:

```swift
            .onChange(of: entryStore?.acceptedHand) { _, hand in
                if let hand {
                    store.sessionHand = hand
                    sessionEntryRole = .joiner
                    entryStore?.acceptedHand = nil
                }
            }
```

**Done:** the Deck Library shows the pending banner and joins into the lobby; the ceremony / masthead /
hero / deck wall are untouched.

---

### Segment 8 — `AppShell` routing reconcile (the tricky bit)

**One thing:** make `AppShell` honor `appState.selectedTab` so a joining partner (or any code that writes
`appState.selectedTab`) actually switches tabs. Today AppShell's local `@State selectedTab` shadows it and
the writes are dead.

The fix must (1) keep the `RacetrackTabBar`'s `$selectedTab` binding working (it mutates the binding on
tap), and (2) let `appState.selectedTab` drive the shell. The clean approach: keep the local `@State` as
the tab bar's source of truth for its animation, but **two-way sync** it with `appState.selectedTab`.

In `Vayl/App/AppShell.swift`:

```swift
struct AppShell: View {

    @Environment(AppState.self) private var appState

    @State private var selectedTab: AppTab = .home

    // …existing tabTrimValues / tabAnimating unchanged…

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                TabContentWrapper(fade: false) { HomeRouterView() }
            case .play:
                TabContentWrapper { PlayView() }
            case .map:
                TabContentWrapper { MapView() }
            case .learn:
                TabContentWrapper { LearnView() }
            case .settings:
                TabContentWrapper { SettingsView(isTab: true) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RacetrackTabBar(
                selection: $selectedTab,
                trimValues: $tabTrimValues,
                isAnimating: $tabAnimating
            )
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xs)
        }
        // Honor programmatic tab routing (HomeRouterView's appState.selectedTab writes,
        // and — for S3 — routing a joining partner onto the banner's tab). AppShell's
        // local @State stays the tab bar's animation source of truth; these two .onChange
        // keep it and appState.selectedTab in lockstep, both directions.
        .onAppear { selectedTab = appState.selectedTab }
        .onChange(of: appState.selectedTab) { _, newTab in
            if selectedTab != newTab {
                withAnimation(AppAnimation.spring) { selectedTab = newTab }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if appState.selectedTab != newTab { appState.selectedTab = newTab }
        }
    }
}
```

> **Why two `@State` + `appState` and not just `$appState.selectedTab` bound straight into the tab bar?**
> `RacetrackTabBar` drives its trim animation off `selectedTab` mutations and the hoisted
> `tabTrimValues`/`tabAnimating`; re-pointing its binding at `@Bindable var appState` risks changing the
> re-render cadence that comment at `AppShell.swift:13` warns about ("so `.safeAreaInset` re-renders
> don't reset the animation state mid-sequence"). The mirror keeps the tab bar's local state intact while
> making `appState.selectedTab` authoritative for programmatic routing. This also **fixes the latent dead
> writes** in `HomeRouterView` (`onInvitePartner`/`onPulseTap`/`onOpenLexicon`/`onOpenSettings`), which is
> a real, verified bug today — call it out to Bryan.
>
> `@Environment(AppState.self)` on `AppShell` is safe: `AppState` is already injected at the root (the
> previews inject it, and every tab reads it).

**Done:** writing `appState.selectedTab = .play` (e.g. to route a joiner to the Deck Library banner)
switches the shell to Play; tapping a tab still animates and updates `appState.selectedTab`; the existing
`HomeRouterView` nav actions (Map / Learn / Settings) now actually navigate.

---

### Segment 9 — Delete the debug presence harness

**One thing:** remove the throwaway `#if DEBUG` presence harness, now superseded.

- Confirm no references outside its own `#if DEBUG` block:
  ```
  grep -rn "PresenceDebugView\|PresenceDebugStore" Vayl/
  ```
  (It is entirely `#if DEBUG`-guarded, so expect only its own file.)
- Delete `Vayl/Features/Sessions/Debug/PresenceDebugView.swift`.
- If `Vayl/Features/Sessions/Debug/` is now empty, remove the empty group.

**Done:** the file is gone; the project still compiles (no dangling references).

---

## Definition of Done (build-green)

- Project compiles green (all new files added to the app target; note `VaylTests` is a manual PBXGroup —
  no test files are added here, so no pbxproj test wiring needed).
- `SessionEntryStore` exists; `refresh()` is a no-op (nil banner) in the pure-local path; a `#if DEBUG`
  `debugSeedPending` produces a mock pending session.
- **Home** and the **Deck Library** each: build a `SessionEntryStore`, `refresh()` on appear + on
  `scenePhase == .active`, show `PendingSessionBanner` when `pendingSession != nil`, and on accept present
  the session `.vaylCover` with `entryRole: .joiner`.
- The session `.vaylCover` for a joiner shows `SessionLobbyView` (session shape + "I'm in") →
  `AirlockView` (existing) → drives via the store's mock `confirmSynced()` to `.session` (the existing
  `SessionPlayerView` **placeholder**). Initiator entries ("Settle in" / ceremony) are unchanged.
- `CoupleSessionStore.persistSession()` writes a `LockInSession` row (bandwidth A/B, `bandwidthGap`,
  `completedAt`) alongside the existing `CardSession`.
- `SessionLobbyView` is `.screenshotProtected()`.
- `AppShell` honors `appState.selectedTab` (two-way mirror); the previously-dead `HomeRouterView` tab
  writes now navigate.
- `Debug/PresenceDebugView.swift` is deleted with no dangling references.
- Zero raw tokens in the new views; `.vaylCover` (never raw `.fullScreenCover`) for the session; no iOS-26
  banned APIs; press-state + haptic on every new tappable; empty/pending banner is dismissible.

---

## Bryan verifies on device

- [ ] 🎚️ **Banner feel:** the pending banner slides in from the top and reads at a glance; the copy
      ("{partner} started a session · N cards · ~M min · tap to join") is right. Tune the wording.
- [ ] 🎚️ **Lobby feel:** the session-shape card gives *enough* to consent to and no more; "I'm in" lands;
      the transition into the sync ring feels continuous, not a jump.
- [ ] **Initiator unchanged:** "Settle in" from Home and the Play ceremony still open straight into the
      airlock (no lobby pre-roll), exactly as before.
- [ ] **Tab routing:** from Home, tapping the partner pill / Pulse / Lexicon / Settings entries now
      actually switches tabs (this was silently broken before — confirm it's fixed and nothing else
      regressed in tab switching / the racetrack animation).
- [ ] **`LockInSession` persisted:** after finishing a session, a `LockInSession` row exists with the
      right A/B bandwidth and gap (inspect via the DB, or a temporary debug readout).
- [ ] **`scenePhase` refresh:** backgrounding and returning re-checks for an open session (no stale/dupe
      banner).
- [ ] **TWO-DEVICE (deferred to S2 / plan 08 + realtime segments):** a real partner-started session
      appears on the other phone; "both here" presence is real (not the mock auto-present); mutual
      hold-to-sync works; the joiner's consent propagates. **This build does not prove this — it's the S2
      handshake.** Confirm with two phones once plan 08 lands.
- [ ] **A11y:** Reduce Motion — the banner/lobby transitions degrade gracefully; the airlock's ring
      breathe already has its Reduce-Motion guard (unchanged here).

---

## Constraints / do-not-touch

- **`SessionPlayerView` (the S4 player):** navigate to it as the placeholder "active" screen; **do not
  build, restyle, or extend it.** The Player is plan 10 (S4).
- **`PlayView`'s generative surface:** the masthead, `PlayHeroView`, `DeckWallView`, `DeckDetailView`,
  `DeckBeginCeremony` are **off-limits**. You add exactly one banner + one entry store + the role flag on
  the existing cover. Nothing else.
- **The airlock sync-ring mechanic** (`AirlockView` hold/release/tolerance) is built and feel-approved —
  do not retune it. The `partnerPresent` / partner-release-point **mocks stay mocked** (real presence is
  S2).
- **`VaylCardFace` shell** — no edits; `.drawingGroup()` stays.
- **Presentation grammar** — the session is a `.vaylCover`; never a raw `.sheet`/`.fullScreenCover`.
- **`RealtimeSessionService`** — a View never calls it; only `SessionEntryStore`/`CoupleSessionStore` do,
  and only behind an injected (default-nil) service. The default build path stays pure-local.
- **`CoupleSessionStore.Phase`** — do **not** add a new phase case for the lobby; gate it inside the
  existing `.airlock` phase via `consented`. (The store's phase machine is one unit; the lobby is a
  pre-roll of the same airlock phase, not a new phase.)
- **`AppState`** — reuse `selectedTab`; do not add new routing fields (the two `.onChange` mirror is
  enough). Do not invent `partnerDisplayName` if it isn't there (see Open Decisions).

---

## Open decisions (each with a default so Fable is never blocked)

1. **`appState.partnerDisplayName` may not exist.** Only `AppState.displayName` (`AppState.swift:37`) is
   verified; the partner's name lives on `HomeStore.partnerName` (`HomeStore.swift:48`), not `AppState`.
   **Default:** in `SessionEntryStore`, use a plain `"Your partner"` string for the banner/lobby initiator
   name rather than reaching for a property that may not exist. If `AppState` *does* expose a partner name,
   use it; otherwise the literal is correct and honest (V1 solo/couple must degrade gracefully — no
   hardcoded "Alex" in release). Flag which you used.

2. **One entry `.vaylCover` or two per host?** Home already has an initiator cover (line 267) keyed on
   `sessionHand`; Play has one (line 83) keyed on `store.sessionHand`. **Default:** reuse the *same* cover
   per host and carry the role via `sessionEntryRole` `@State` (as specified in Segments 6-7) — do not add
   a second cover. One cover, one hand, one role flag is the least-surface change and matches the "one
   store owns the whole cover" principle.

3. **Deck title in the lobby/banner.** `Card` carries `deckId` (a String content id), not a display title;
   resolving the pretty title needs `DeckCatalogService`/`DeckSummary`. **Default:** the lobby's `shapeCard`
   hardcodes "The Opener" as the V1 deck label (the only shipping deck for sessions), and
   `PendingSession.deckTitle` carries `deckId` for now. If Bryan wants the resolved title, thread a
   `DeckSummary` lookup through `SessionEntryStore.loadDeck` (it already has the catalog service in hand).
   Flag it as a V1.1 polish, not a blocker.

4. **Dual initiator entry points (Home "Settle in" + Play ceremony) are a pre-existing open decision**
   (the "dual session presentation grammar" question in Bryan's notes). **Default:** this plan does **not**
   consolidate them — it only *adds* the joiner banner to both. Leave the initiator duplication as-is;
   consolidating it is out of S3 scope. Flag that it remains open.
