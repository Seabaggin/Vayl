# 07 — Empty / Loading / Error State Sweep + Crash & Analytics SDK

**Goal:** one build-green pass that (a) extracts a single reusable `VaylEmptyState` view matching the CLAUDE.md empty-state contract, wires it into the reviewer-critical data screens (Learn, Map/Us, Home, Play, Pulse history, Desire reveal) with honest empty / loading / error copy, and (b) integrates a crash + analytics SDK (Firebase Crashlytics, default) initialized in `VaylApp`, under a strict "no PII / no intimate content" logging rule.

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

## Context Fable needs

- **This is a cross-cutting sweep + an SDK, not a redesign.** The scope is roadmap **A3**: give every
  reviewer-critical data screen an honest empty / loading / error state, and wire crash + analytics
  reporting. Touch only the screens a reviewer / week-one user actually hits. Do not restyle any screen.
- **A reusable empty-state component ALREADY EXISTS but is Play-specific.**
  `Vayl/Features/Play/Components/PlayEmptyState.swift` is a full icon + headline + sub-label + optional
  Retry CTA that already matches the contract — but it hard-codes deck copy ("No decks yet" /
  "Couldn't load decks") and lives in the Play feature. There is **no generic `VaylEmptyState`.**
  Segment 1 extracts a generic `VaylEmptyState` into `Vayl/Design/Components/State/`, then `PlayEmptyState`
  becomes a thin wrapper (or is deleted and its call site points at the generic view). Model the generic
  view on `PlayEmptyState.swift` verbatim — same VStack, same tokens, same press-state Retry button.
- **Desire already has a private empty/loading state.** `DesireRevealView` has a private
  `emptyState(icon:title:message:)` helper and a `loadingView` (`ProgressView` + "Finding where you
  align…"), driven by `DesireRevealStore.Phase` (`.loading` / `.ready` / `.empty` / `.failed(String)`).
  This one is already correct — do **not** rebuild it. Just confirm it survives and (optionally) migrate
  its `.empty` / `.failed` branches to render `VaylEmptyState` for consistency (Segment 6, low-risk).
- **Content is bundle-first, so most screens are never truly "empty."** `LearnStore.load()` decodes
  bundled JSON in `init` (instant baseline), then `refresh()` overrides from Supabase when reachable.
  `ContentService` swallows every network error and returns `nil` so the bundled baseline stands. So the
  Learn empty state fires only if the **bundled decode itself fails** (`loadError != nil`), and the
  loading state is only a brief server-refresh shimmer. Design for that reality — do not invent a
  "no research" state that can't happen in a shipping build.
- **The Map Us layer is already honest about the missing partner.** `MapUsLayer` guards on
  `partnerPosition == nil` and shows "Pulse · together" + "Partner hasn't checked in yet today." with the
  `PulseCapsule` and the partner aura **hidden** — no fake partner. `MapStore.partnerPosition` is
  hardcoded `nil` today (Segment 7 wires real sync). `MapStore.partnerName = "Alex"` is set **only inside
  `#if DEBUG`**. Do not let a fake partner leak into release. This screen needs a light copy pass, not a
  rebuild.
- **Home's solo/pre-pair state is already modelled.** `HomeStore.partnerChipState: PartnerChipState`
  resolves `.none` / `.invitePending` / `.active(name:initial:)` off `appState.linkState` +
  `HomeStore.isPaired`; the `.none` case IS the graceful solo empty state (invite button, no fake name).
  `HomeStore.partnerName = "Alex"` appears **only inside `#if DEBUG`**. Home needs only a guard audit,
  not new empty UI.
- **Canonical patterns to imitate:** the generic empty state → model on `PlayEmptyState.swift`. The
  Store `loadError: String?` pattern → already in `PlayStore` and `LearnStore`; reuse the exact shape.
  Logging → the app already uses `os.Logger(subsystem: "com.vayl.app", category: …)` (see
  `PushService.swift`, `RealtimeSessionService.swift`); the analytics wrapper wraps that convention.
- **pbxproj auto-join:** `Vayl/` is a `PBXFileSystemSynchronizedRootGroup` (verified line ~89), so any
  new `.swift` file placed under `Vayl/` auto-joins the app target — **no pbxproj edit for source files.**
  New SPM packages and the `GoogleService-Info.plist` bundle resource DO require pbxproj / target changes
  (Segment 7). `VaylTests` is a manual `PBXGroup` — but this plan adds no test files.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Design/Components/State/VaylEmptyState.swift` | The single reusable empty / error state view (icon + headline + sub-label + optional Retry CTA), tokens only. Extracted from `PlayEmptyState`. |
| `Vayl/Design/Components/State/VaylLoadingState.swift` | A tiny shared loading placeholder (centered `ProgressView` + optional caption) for the brief server-refresh window. Tokens only. |
| `Vayl/Core/Services/Analytics.swift` | The analytics + crash façade. One `enum Analytics` with `configure()`, `log(_ event:)`, `setScreen(_:)`, `recordError(_:)`. Wraps Crashlytics/Analytics behind a Vayl-owned API so no view or store ever calls the SDK directly, and the "no PII" rule is enforced in one place. |

### Modify

| File | Change (with anchor) |
|---|---|
| `Vayl/Features/Play/Components/PlayEmptyState.swift` | Reduce to a thin wrapper over `VaylEmptyState` (keeps the existing call site + previews working). Lines 21–60 body → forward to `VaylEmptyState`. |
| `Vayl/Features/Learn/Store/LearnStore.swift` | Add `isRefreshing: Bool` (set around `refresh()`), so the Learn view can show the loading placeholder during the server override. Lines 21, 30–34. |
| `Vayl/Features/Learn/Views/LearnView.swift` | Branch the research area on `store.loadError` / `store.findings.isEmpty` → `VaylEmptyState`; show `VaylLoadingState` inline while `store.isRefreshing` and findings are still empty. Lines 26–32. |
| `Vayl/Features/Learn/Views/ResearchDatabaseView.swift` | Empty-list guard: when `store.findings.isEmpty`, render `VaylEmptyState` instead of an empty `ForEach`. Lines 30–35. |
| `Vayl/Features/Map/Components/MapUsLayer.swift` | Replace the ad-hoc nil-partner copy block with the honest `VaylEmptyState` beneath the field, so the "no partner yet" state reads as a designed empty state, not a stray caption. Lines 44–53, 61–71. |
| `Vayl/Features/Pulse/Components/PulseHistoryGrid.swift` | When `cells.isEmpty`, render a compact `VaylEmptyState` (no grid) instead of the label-over-nothing. Lines 31–43. |
| `Vayl/Features/Desire Map/Views/DesireRevealView.swift` | (Optional, low-risk) route the existing `.empty` / `.failed` branches through `VaylEmptyState` for visual consistency. The `.loading` branch stays as-is. |
| `Vayl/App/VaylApp.swift` | Call `Analytics.configure()` at the top of `init()` (before any store construction). Lines 26–38. |

### Delete

_None._ (`PlayEmptyState.swift` is kept as a thin wrapper so its existing `PlayView` call site and
previews keep compiling; deleting it would force a `PlayView` edit for no benefit.)

---

## Build steps (segments)

### Segment 1 — Extract the reusable `VaylEmptyState`

**One thing:** a single generic empty / error view, modelled verbatim on `PlayEmptyState`, tokens only.

Create `Vayl/Design/Components/State/VaylEmptyState.swift`:

```swift
//
//  VaylEmptyState.swift
//  Vayl — Design / State
//
//  The one reusable data-screen empty / error state, per the CLAUDE.md contract:
//  icon (textTertiary) + headline (cardTitle) + sub-label (caption) + optional
//  Retry CTA. Every data screen renders THIS instead of a silently blank view.
//  Extracted from the original Play-specific PlayEmptyState so the copy is
//  passed in, not baked in.
//

import SwiftUI

struct VaylEmptyState: View {

    /// SF Symbol for the illustration. Defaults to a neutral tray.
    var systemImage: String = "tray"
    /// The headline line (cardTitle).
    var title: String
    /// The supporting sub-label (caption). Keep it short, no em dashes.
    var message: String
    /// A retry label + action. When nil, no CTA is shown (a genuinely empty,
    /// non-error state). When set, a pressable Retry button appears.
    var retryTitle: String = "Try again"
    var onRetry: (() -> Void)? = nil

    @State private var pressed = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
                .foregroundStyle(AppColors.textTertiary)

            Text(title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: AppSpacing.xxl * 6)

            if let onRetry {
                Text(retryTitle)
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.cardBackground))
                    .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
                    .scaleEffect(pressed ? 0.96 : 1)
                    .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, now in now }
                    .onTapGesture { onRetry() }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in pressed = true }
                            .onEnded   { _ in pressed = false }
                    )
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Empty — no data") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylEmptyState(
            systemImage: "sparkles",
            title: "Nothing here yet",
            message: "New items will appear here as they arrive."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Error — with retry") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylEmptyState(
            systemImage: "exclamationmark.triangle",
            title: "Couldn't load",
            message: "Check your connection and try again.",
            onRetry: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
```

**Done:** `VaylEmptyState` compiles and both previews render on the void.

---

### Segment 2 — A shared loading placeholder

**One thing:** a minimal centered loading state for the brief server-refresh window (Learn). Reuses the
existing `ProgressView` pattern already used in `DesireRevealView.loadingView`.

Create `Vayl/Design/Components/State/VaylLoadingState.swift`:

```swift
//
//  VaylLoadingState.swift
//  Vayl — Design / State
//
//  The shared loading placeholder for a data screen's brief in-flight window
//  (e.g. Learn's Supabase content override). Mirrors DesireRevealView.loadingView:
//  a tinted ProgressView over an optional caption. Tokens only.
//

import SwiftUI

struct VaylLoadingState: View {
    /// Optional caption under the spinner. No em dashes.
    var message: String? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColors.textTertiary)
            if let message {
                Text(message)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylLoadingState(message: "Refreshing research…")
    }
    .preferredColorScheme(.dark)
}
#endif
```

**Done:** `VaylLoadingState` compiles and previews.

---

### Segment 3 — Reduce `PlayEmptyState` to a wrapper

**One thing:** keep the existing `PlayView` call site and previews working, but route through the
generic view so there is exactly one empty-state layout in the app.

The current `PlayView` call site (verified, `PlayView.swift:55`) is:

```swift
PlayEmptyState(message: store.loadError) { store.retry() }
```

Keep that signature. Replace the **body** of `Vayl/Features/Play/Components/PlayEmptyState.swift`
(lines 21–60) so it forwards to `VaylEmptyState`, preserving the error-vs-empty distinction that was
baked into the original copy:

```swift
struct PlayEmptyState: View {
    /// A load-error message, or nil for a genuinely empty (but successful) catalog.
    var message: String?
    var onRetry: () -> Void

    private var isError: Bool { message != nil }

    var body: some View {
        VaylEmptyState(
            systemImage: isError ? "exclamationmark.triangle" : "rectangle.stack",
            title:       isError ? "Couldn't load decks" : "No decks yet",
            message:     message ?? "Decks will appear here as they become available.",
            onRetry:     isError ? onRetry : nil
        )
    }
}
```

Keep the two existing `#Preview` blocks at the bottom of the file unchanged (they call
`PlayEmptyState(message:…)`, which still compiles).

**Done:** `PlayView` still shows the same empty / error wall (no visual change), now sourced from
`VaylEmptyState`. Deck error still offers Retry; a genuinely empty catalog does not.

---

### Segment 4 — Learn: empty + loading + error

**One thing:** the research area of Learn shows the loading placeholder during the server refresh,
`VaylEmptyState` on a bundled-decode failure, and its normal content otherwise. Plus the "browse all"
database view gets an empty guard.

**4a. `LearnStore` gains an `isRefreshing` flag.** Modify `Vayl/Features/Learn/Store/LearnStore.swift`.
Add the property next to `loadError` (line 21):

```swift
    private(set) var loadError: String?
    /// True only while the Supabase content override is in flight. Drives the Learn
    /// loading placeholder during the brief server refresh after the bundled baseline.
    private(set) var isRefreshing = false
```

And wrap `refresh()` (lines 30–34):

```swift
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        if let f = await ContentService.shared.fetchFindings() { findings = f }
        if let t = await ContentService.shared.fetchGlossary() { lexiconTerms = t }
        if let q = await ContentService.shared.fetchQuotes()   { mediaQuotes = q }
    }
```

**4b. `LearnView` branches the research block.** Modify `Vayl/Features/Learn/Views/LearnView.swift`.
The current body (lines 26–32) unconditionally renders `ResearchSection`. Replace the `ResearchSection`
call with a state-aware `researchArea`:

```swift
    QuizCarouselSection(quizzes: store.quizzes)
    researchArea
    ContentHubSection(store: store)
```

and add, inside `LearnView`:

```swift
    @ViewBuilder
    private var researchArea: some View {
        if store.findings.isEmpty {
            if let error = store.loadError {
                // Bundled decode failed — this is the only true "no research" path.
                VaylEmptyState(
                    systemImage: "books.vertical",
                    title:       "Research is taking a breather",
                    message:     "We couldn't open the research library. Pull down or try again in a moment.",
                    onRetry:     { store.load() }
                )
                .onAppear { Analytics.recordError(.contentDecodeFailed(detail: error)) }
            } else if store.isRefreshing {
                VaylLoadingState(message: "Loading research…")
            } else {
                VaylEmptyState(
                    systemImage: "books.vertical",
                    title:       "No research yet",
                    message:     "New findings will appear here as they publish."
                )
            }
        } else {
            ResearchSection(
                findings: store.findings,
                onOpenDatabase: { showDatabase = true },
                onOpenFinding: { selectedFinding = $0 }
            )
        }
    }
```

> Copy note: "Research is taking a breather" / "We couldn't open the research library. Pull down or try
> again in a moment." — no em dashes. In practice `loadError` almost never fires (bundled JSON ships in
> the app), but the branch must exist per the contract.

**4c. `ResearchDatabaseView` empty guard.** Modify `Vayl/Features/Learn/Views/ResearchDatabaseView.swift`.
Replace the bare `ForEach` (lines 31–34) so an empty list renders `VaylEmptyState`:

```swift
                    if store.findings.isEmpty {
                        VaylEmptyState(
                            systemImage: "magnifyingglass",
                            title:       "No findings",
                            message:     "The research library is empty right now. Try again shortly."
                        )
                        .padding(.top, AppSpacing.xl)
                    } else {
                        ForEach(store.findings) { f in
                            Button { onOpenFinding(f) } label: { row(f) }
                                .buttonStyle(PressableCardStyle())
                        }
                    }
```

**Store state that drives which branch (Learn):**
`store.findings.isEmpty` (empty) · `store.loadError != nil` (error, bundled decode failed) ·
`store.isRefreshing` (loading, server override in flight) · otherwise `ResearchSection` (content).

**Done:** Learn shows content normally; a forced bundled-decode failure shows the error state with a
working Retry that re-calls `store.load()`; the server-refresh window shows the loading placeholder only
when findings are still empty.

---

### Segment 5 — Map (Us), Pulse history

**One thing:** the Us layer's missing-partner state and the empty Pulse history grid both read as
designed empty states, honestly (no fake partner, no label-over-nothing). The Me-layer Pulse hero and
Home solo state are already correct and are only audited, not rebuilt.

**5a. Map Us layer.** Modify `Vayl/Features/Map/Components/MapUsLayer.swift`. Today (lines 44–53) the
missing-partner copy is an ad-hoc headline + caption. The field block (lines 75–119) already hides the
capsule and partner aura when `partnerPosition == nil` — keep that. Replace the `copyBlock` usage in the
body so that, when there is no partner, we show `VaylEmptyState` under the field instead of the stray
copy. Change the body (lines 61–71):

```swift
    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            fieldBlock
            if partnerPosition == nil {
                // Honest: no partner data exists yet. No fake capsule, no fake name.
                VaylEmptyState(
                    systemImage: "person.2",
                    title:       "Just you for now",
                    message:     "When your partner checks in, you'll see both of you here together."
                )
            } else {
                copyBlock
                if !usGridPairs.isEmpty {
                    PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
                        .padding(.top, AppSpacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
```

Leave `copyBlock`, `fieldBlock`, `headline`, `descCopy` as-is — they now only run when a real partner
exists, so the "Pulse · together" / "Partner hasn't checked in yet today." fallbacks in `headline` /
`descCopy` (lines 42–53) become dead but harmless. (Do not delete them; they document the intended
future copy and are cheap.)

> This preserves the CLAUDE.md solo rule: the Us layer must be honest until real partner data exists
> (`MapStore.partnerPosition` is `nil` in release; only `#if DEBUG` seeds "Alex"). A reviewer opening
> "Us" unpaired sees an intentional "Just you for now," not a fabricated couple.

**5b. Pulse history grid empty state.** Modify `Vayl/Features/Pulse/Components/PulseHistoryGrid.swift`.
Today (lines 31–43) it always renders the label and an empty `LazyVGrid` when `cells.isEmpty`. Guard it:

```swift
    var body: some View {
        if cells.isEmpty {
            VaylEmptyState(
                systemImage: "circle.grid.3x3",
                title:       "No check-ins yet",
                message:     "Your last 30 pulse check-ins will fill in here."
            )
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(label)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)

                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(cells.indices, id: \.self) { i in
                        AuraDot(tier: cells[i].mine, partner: cells[i].partner)
                    }
                }
            }
        }
    }
```

**Store state that drives which branch:**
- **Map Us:** `partnerPosition == nil` (empty: "Just you for now") vs non-nil (field + copy + grid).
  Source: `MapStore.partnerPosition` (release: always `nil` until Segment 7 sync).
- **Pulse history:** `cells.isEmpty`, derived from `PulseStore.entries: [PulseEntry]` (loaded from
  UserDefaults key `pulse.entries.v1`; empty on a fresh install). `PulseStore` has no loading/error
  state (synchronous local storage) — so Pulse needs an **empty** state only, no loading/error branch.

> **Do NOT touch** `MapPulseHero` (the Me-layer hero already renders a neutral 0.5/0.5 aura for a fresh
> user and conditionally hides its own history grid) or `PulseFullView` (an intentional stub, rebuilt in
> a later Pulse segment). Adding empty states there is out of scope for this sweep.

**Done:** an unpaired reviewer sees "Just you for now" in Us (no fake partner); a fresh user's Pulse
history shows "No check-ins yet" instead of an empty grid.

---

### Segment 6 — Home + Desire audit (guard only, minimal edits)

**One thing:** confirm the already-correct solo/pre-pair and reveal states hold, and (optionally) unify
Desire's empty/error branches on `VaylEmptyState`. No new empty UI is invented here.

**6a. Home — audit, no code change expected.** `HomeStore.partnerChipState` already returns `.none` for
the solo/unpaired user, and `PartnerChip`'s `.none` case renders the invite button (no fake name). The
only "Alex" in `HomeStore` is inside `#if DEBUG` (verified `HomeStore.swift:100`). **Action:** grep to
confirm no non-DEBUG "Alex" crept in, then leave Home untouched:

```
grep -n "Alex" Vayl/Features/Home/**/*.swift
```

Every hit must be inside a `#if DEBUG` block or a `#Preview`. If one is not, wrap it — but expect none.

**6b. Desire — optional consistency migration.** `DesireRevealView` already has a `loadingView`
(`ProgressView` + "Finding where you align…") and a private `emptyState(icon:title:message:)`, driven by
`DesireRevealStore.Phase` (`.loading` / `.ready` / `.empty` / `.failed(String)`). Leave `.loading`
as-is. For visual consistency, you MAY replace the private `emptyState(...)` body with a `VaylEmptyState`
call (same icon/title/message args), so all data screens share one layout. This is low-risk and
optional; if the private helper's layout differs enough that migrating risks a regression, skip it and
leave Desire's own state intact. The existing copy is already correct:
- `.empty` → "No shared matches yet" / "When you and your partner both finish your maps, what you share
  appears here."
- `.failed(msg)` → its current failure copy.

**Store state that drives which branch (Desire):** `DesireRevealStore.phase` —
`.loading` → `loadingView`; `.empty` → empty state; `.failed(String)` → error state; `.ready` →
the reveal ceremony. The "partner hasn't finished" case never reaches this view — it is gated upstream
in `HomeStore` (`desireMapState`), so no new state is needed here.

**Done:** Home solo state confirmed leak-free; Desire reveal states preserved (optionally unified).

---

### Segment 7 — Crash + analytics SDK (Firebase Crashlytics, default)

**One thing:** integrate a crash + analytics SDK behind a Vayl-owned `Analytics` façade, initialized in
`VaylApp`, under a strict no-PII rule.

**7a. Add the SPM package.** In Xcode: File → Add Package Dependencies. This is a project-file change
(the `Vayl/` group auto-joins source, but SPM packages must be added to the target explicitly).

- **Package URL:** `https://github.com/firebase/firebase-ios-sdk`
- **Dependency rule:** Up to Next Major, from `11.0.0` (use the latest 11.x resolved by Xcode).
- **Products to add to the `Vayl` app target (only these three — keep the binary lean):**
  - `FirebaseCrashlytics`
  - `FirebaseAnalytics`
  - `FirebaseCore` (pulled in transitively; add explicitly if Xcode does not).
- **Do NOT add** Firestore, Auth, Messaging, Remote Config, or any other Firebase product. This app uses
  Supabase for data/auth/push; Firebase is crash + anonymized analytics only.

**7b. Add the config file.** Download `GoogleService-Info.plist` from the Firebase console for the
`com.vayl.app`-matching bundle id and drop it at the repo root of the app group
(`Vayl/GoogleService-Info.plist`), added to the `Vayl` target's **Copy Bundle Resources** build phase.
Because `Vayl/` is a synchronized root group, placing the file there should auto-join; verify it appears
in the target's resources. (If Bryan hasn't created the Firebase project yet, this is the one manual
prerequisite — flagged in Open Decisions.)

**7c. Crashlytics build phase (dSYM upload).** Add a Run Script build phase to the `Vayl` target, after
"Copy Bundle Resources", so symbolicated crash reports upload:

```
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

with Input Files:

```
${DWARF_DSYM_FOLDER_PATH}/${TARGET_NAME}.app.dSYM/Contents/Resources/DWARF/${TARGET_NAME}
$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
```

(Standard Firebase Crashlytics setup; if the checkout path differs on Bryan's machine, trust the repo
layout under `SourcePackages/checkouts/`.)

**7d. The `Analytics` façade.** Create `Vayl/Core/Services/Analytics.swift`. This is the ONLY place the
Firebase SDK is imported — no view or store ever calls Firebase directly. It also enforces the no-PII
rule structurally: events are a closed `enum` with no free-form user-content parameters.

```swift
//
//  Analytics.swift
//  Vayl
//
//  The single façade over crash + analytics reporting. NOTHING else in the app
//  imports FirebaseAnalytics / FirebaseCrashlytics — they go through here so the
//  privacy rule below is enforced in one place.
//
//  PRIVACY RULE (non-negotiable — intimate-data app):
//  Never log PII or intimate content. The event enum is CLOSED and carries only
//  anonymized, structural values (screen names, error type tags, counts). It is
//  intentionally impossible to pass a desire answer, a pulse value, a name, or
//  any partner data through this API.
//
//    ALLOWED   : screen names ("map_us", "learn"), anonymized error TYPES
//                ("content_decode_failed"), non-identifying counts (deck count).
//    BANNED    : desire ratings / item names, pulse energy/openness/quadrant
//                values, the user's or partner's name, pairing codes, couple ids,
//                message/journal text, session card content, email, auth ids.
//
//  If you need a new event, add a case to `Event` / `AppError` — do NOT add a
//  String parameter that could carry user content.
//

import Foundation
import OSLog
#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
#endif

enum Analytics {

    private static let logger = Logger(subsystem: "com.vayl.app", category: "Analytics")

    // MARK: - Closed event vocabulary (no free-form user content)

    /// Screen a user landed on. Names are static, non-identifying route labels.
    enum Screen: String {
        case home, play, mapMe = "map_me", mapUs = "map_us", learn
        case pulseCheckIn = "pulse_checkin", desireReveal = "desire_reveal"
        case researchDatabase = "research_database", vault, settings
    }

    /// Anonymized, structural events. No parameter may carry user content.
    enum Event {
        case screenView(Screen)
        case retryTapped(Screen)          // user hit a Retry CTA on an error state
        case emptyStateShown(Screen)      // a data screen rendered empty (product signal)
    }

    /// Anonymized error TYPES. `detail` is developer-facing (error.localizedDescription
    /// / a code) and must never contain user content — callers pass SDK/decoder text only.
    enum AppError {
        case contentDecodeFailed(detail: String)
        case pulseLoadFailed(detail: String)
        case syncFailed(area: String, detail: String)
    }

    // MARK: - Lifecycle

    /// Call once, first thing in VaylApp.init(). Safe if the plist is missing:
    /// FirebaseApp.configure() no-ops without crashing in that case; we log locally.
    static func configure() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        // Only collect crashes in Release; keep dev noise out of the dashboard.
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(true)
        #endif
        #endif
        logger.info("Analytics configured")
    }

    // MARK: - Reporting

    static func log(_ event: Event) {
        switch event {
        case .screenView(let s):     send("screen_view", ["screen": s.rawValue])
        case .retryTapped(let s):    send("retry_tapped", ["screen": s.rawValue])
        case .emptyStateShown(let s): send("empty_state_shown", ["screen": s.rawValue])
        }
    }

    static func setScreen(_ screen: Screen) {
        log(.screenView(screen))
    }

    static func recordError(_ error: AppError) {
        let (domain, detail): (String, String)
        switch error {
        case .contentDecodeFailed(let d): (domain, detail) = ("content_decode_failed", d)
        case .pulseLoadFailed(let d):     (domain, detail) = ("pulse_load_failed", d)
        case .syncFailed(let area, let d):(domain, detail) = ("sync_failed_\(area)", d)
        }
        logger.error("AppError \(domain, privacy: .public): \(detail, privacy: .private)")
        #if canImport(FirebaseCore)
        // domain is a static tag; detail is treated as non-user diagnostic text only.
        let nsError = NSError(domain: "com.vayl.\(domain)", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: detail])
        Crashlytics.crashlytics().record(error: nsError)
        #endif
    }

    // MARK: - Private

    private static func send(_ name: String, _ params: [String: String]) {
        logger.info("event \(name, privacy: .public) \(params, privacy: .public)")
        #if canImport(FirebaseCore)
        FirebaseAnalytics.Analytics.logEvent(name, parameters: params)
        #endif
    }
}
```

> Note: the `#if canImport(FirebaseCore)` guards mean the file compiles even before the SPM package is
> resolved, so you can write the façade and its call sites first and the build stays green; once the
> package is added, the real calls light up. This also keeps CI / preview builds that lack the plist from
> crashing.

**7e. Initialize in `VaylApp`.** Modify `Vayl/App/VaylApp.swift`. `Analytics.configure()` must run
before any store is constructed. Add it as the first line of `init()` (before `let appState = AppState()`
on line 27):

```swift
    init() {
        Analytics.configure()

        let appState = AppState()
        _appState = State(initialValue: appState)
        // …unchanged…
    }
```

**7f. Wire the two safe call sites already referenced.** The Learn error branch (Segment 4b) already
calls `Analytics.recordError(.contentDecodeFailed(detail: error))`. Optionally add a screen-view ping
where each tab appears (`.task { Analytics.setScreen(.learn) }` etc.) — but keep it to the closed
`Screen` enum; do not thread any name/value through. Screen pings are optional polish; the crash
reporting + the one error hook are the required deliverable.

**Done:** `FirebaseApp.configure()` runs at launch; a forced test crash symbolicates in the Crashlytics
dashboard (Bryan verifies on device); no user content can reach the analytics API by construction.

---

## Definition of Done (build-green)

- [ ] `VaylEmptyState` and `VaylLoadingState` exist under `Vayl/Design/Components/State/`, tokens only,
      and preview on the void.
- [ ] `PlayEmptyState` is a thin wrapper over `VaylEmptyState`; `PlayView`'s existing call site and
      previews compile unchanged; deck error still offers Retry, empty catalog does not.
- [ ] `LearnStore` has `isRefreshing`; `LearnView.researchArea` branches empty / loading / error /
      content off `findings.isEmpty` / `loadError` / `isRefreshing`; the error Retry re-calls
      `store.load()`. `ResearchDatabaseView` guards its empty list with `VaylEmptyState`.
- [ ] `MapUsLayer` shows `VaylEmptyState` ("Just you for now") when `partnerPosition == nil` and never
      renders a fake capsule / partner aura / partner name in that state.
- [ ] `PulseHistoryGrid` shows `VaylEmptyState` ("No check-ins yet") when `cells.isEmpty` instead of a
      label over an empty grid.
- [ ] Home's solo/unpaired state is confirmed leak-free (no non-DEBUG "Alex"); Desire reveal's
      `.loading` / `.empty` / `.failed` branches are preserved (optionally unified on `VaylEmptyState`).
- [ ] Firebase SDK (Crashlytics + Analytics + Core only) added via SPM; `GoogleService-Info.plist` in
      the `Vayl` target resources; Crashlytics dSYM run-script phase present.
- [ ] `Analytics.configure()` is the first line of `VaylApp.init()`; the SDK is imported ONLY in
      `Analytics.swift`; the event/error API is a closed enum with no user-content parameters.
- [ ] All copy is em-dash-free; every new empty/loading view uses `AppColors` / `AppFonts` / `AppSpacing`
      tokens (no raw literals); project compiles green.

## Bryan verifies on device

- [ ] Fresh install (no partner, no check-ins): Map → Us shows "Just you for now" (no fake partner);
      Pulse history shows "No check-ins yet". 🎚️ Confirm the empty-state vertical placement feels
      centered under the field / in the sheet.
- [ ] Learn: normal launch shows research content (bundled). Force a bundled-decode failure (rename a
      JSON, or Bryan's usual scheme) → the "Research is taking a breather" error with a working Try again.
      Airplane mode → content still shows (bundled), no error, no spinner stuck on. 🎚️ Confirm the brief
      refresh spinner doesn't flash annoyingly on a fast connection.
- [ ] Play: with decks present, normal wall; simulate a catalog error → "Couldn't load decks" + Retry
      recovers.
- [ ] Desire reveal: `.loading` spinner, `.empty` ("No shared matches yet"), and a `.failed` state all
      still render correctly.
- [ ] Crashlytics: trigger a test crash (`fatalError()` behind a debug button, or `Crashlytics`'s test
      crash), relaunch, confirm the symbolicated report appears in the Firebase dashboard.
- [ ] Privacy spot-check: open the Analytics DebugView / console and confirm only screen names + error
      tags appear — no names, no desire/pulse values, no pairing codes.

## Constraints / do-not-touch

- **Do not restyle any screen.** This is a state sweep; content layouts, heroes, and mastheads stay as-is.
- **Do not rebuild** `MapPulseHero` (Me-layer hero already handles a fresh user), `PulseFullView` (an
  intentional stub for a later Pulse segment), or `DesireRevealView`'s `.loading` branch.
- **Do not import Firebase anywhere but `Analytics.swift`.** No view / store touches the SDK.
- **Do not add any Firebase product beyond Crashlytics + Analytics + Core.** No Firestore/Auth/Messaging.
- **Do not add a String (or any) parameter to the `Analytics` API that could carry user content.** The
  closed enums are the guardrail; keep them closed.
- **Do not let a fake partner leak into release.** `#if DEBUG`-only "Alex" seeds stay `#if DEBUG`.
- **Do not touch `VaylCardFace`** or remove any `.drawingGroup()`.
- Tokens only in every new/edited view; presentation via `.vaylCover` / `.vaylSheet` (no new modals are
  introduced by this plan anyway).

## Open decisions

1. **Crash + analytics SDK — Crashlytics vs Sentry vs TelemetryDeck.**
   **Recommended default: Firebase Crashlytics + Firebase Analytics** (this plan builds on it).
   - **Firebase Crashlytics** — free, best-in-class crash symbolication, mature iOS SDK, zero backend to
     run; tradeoff: it's Google, pulls a chunky SDK, and analytics defaults are engagement-flavored (we
     disable all of that and log only the closed event set).
   - **Sentry** — excellent crash + performance + breadcrumb tooling and a clean privacy posture (easy to
     scrub PII), single dashboard for crashes and errors; tradeoff: paid past a modest free tier, one more
     vendor.
   - **TelemetryDeck** — privacy-first by design (no PII leaves the device, Swift-native, App-Store-review
     friendly for an intimate app); tradeoff: analytics-only — it is NOT a crash reporter, so you'd still
     need a second SDK (or MetricKit) for crashes.
   Fable proceeds on **Crashlytics + Analytics** and flags this. If Bryan prefers the strongest privacy
   story for an intimate-data app, the swap is TelemetryDeck (analytics) + Sentry or MetricKit (crashes) —
   the `Analytics` façade is designed so only its internals change, not any call site.

2. **Firebase project + `GoogleService-Info.plist` may not exist yet.** The one manual prerequisite is a
   Firebase project registered to the app's bundle id, producing the plist. If it doesn't exist, the
   `#if canImport(FirebaseCore)` guards keep the build green and `configure()` no-ops (logging locally);
   crash/analytics simply stay dark until the plist is added. **Default:** ship the façade + call sites
   now; Bryan adds the plist when ready. Flagged so it isn't mistaken for a bug.

3. **Screen-view analytics pings — ship now or defer.** The required deliverable is crash reporting + the
   one Learn error hook. Per-tab `Analytics.setScreen(...)` pings are optional polish. **Default:** add
   the four tab pings (home/play/map/learn) since they're trivially safe (closed `Screen` enum), but skip
   deeper funnel events for V1 — those risk scope creep and, if done carelessly, PII. Flagged.
