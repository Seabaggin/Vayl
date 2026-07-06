# 02 — Correctness & Accessibility Hardening

**Goal:** In one pass, close the audit's crash / silent-data-loss / Reduce-Motion findings: replace one `try!` markdown crash with a safe fallback, convert four data-loss-relevant `try? context.save()` sites to the mandated `saveWithLogging()`, gate five ungated looping animations behind Reduce Motion, and make the one safe project-config edit (iPhone-only device family). No feature behavior changes; the app compiles green with every crash path and silent-save removed and every ambient loop respecting Reduce Motion.

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

- **This is a hardening pass, not a feature.** It touches 6 existing files plus `project.pbxproj`. There
  are no new types, no new Stores, no new screens. Every edit is local and behavior-preserving except
  where the current behavior is the bug (a crash, a silent save, or motion that ignores Reduce Motion).
- **Source of the work list:** `docs/audits/2026-06-30-ios-codebase-audit.md` §3 (Correctness) and §4
  (Reduce Motion). Findings H-1, H-3, H-5, plus the smaller ambient-loop gaps and two low-severity
  save-consistency sites. Each was re-verified line-by-line on 2026-07-01.
- **The mandated save helper is `saveWithLogging()`**, defined at
  `Vayl/Core/Persistence/ModelContext+Extensions.swift:27`. It is `func saveWithLogging() throws` — it
  logs the error via `OSLog` and **rethrows**. So it must be called with `try`, inside a `do/catch`, or
  with `try?` only when a bare best-effort is genuinely acceptable (it is not, at any site in this plan).
  Canonical call form to imitate — `PairingStore.swift:260-264`:
  ```swift
  do {
      try context.saveWithLogging()
  } catch {
      // handle / log context-specific failure
  }
  ```
- **The mandated Reduce-Motion pattern** (copy it verbatim from the exemplary file
  `Vayl/Features/Pulse/Components/PulseAura.swift`): declare
  `@Environment(\.accessibilityReduceMotion) private var reduceMotion`, drive the looping state from an
  `.onAppear` that early-returns under Reduce Motion (`guard !reduceMotion else { return }`), and attach
  the loop with `.ambientAnimation(_:value:)` instead of a bare `.animation(...)`. The
  `.ambientAnimation(_:value:)` helper is defined at `Vayl/App/Theme/AppAnimation.swift:845-853`; it
  strips the animation from the transaction entirely when `UIAccessibility.isReduceMotionEnabled`, so
  attaching it is a *second* layer of safety on top of the `guard`. Use both, exactly like `PulseAura`.
- **Ambient duration tokens already exist** in `AppAnimation` for the values these loops use
  (`AppAnimation.ambientDrift` = 4.0, `AppAnimation.ambientPulse` = 2.0). Reuse them where the current
  code already references them; do **not** invent new tokens for the hand-tuned 3.2 / 8.0 / 9.5 second
  drifts — those are deliberate feel values (🎚️) and stay as inline durations, just now gated.
- **Verified path drift from the audit brief (trust the repo):**
  - `AtmosphericGhostDeck.swift` lives at `Vayl/Design/Components/Cards/AtmosphericGhostDeck.swift`
    (NOT under `CardPhysics/`).
  - `AppState.swift` lives at `Vayl/Core/Services/AppState.swift` (NOT under `Vayl/App/`).
  - The AppState reset method is named **`resetOnboarding(_:context:)`**, not `reset`.
- **What this pass does NOT do:** it does not sweep the cosmetic best-effort `try?` sites the audit lists
  (`DesireMapStore`, `MapStore`, `VaultStore`, etc. — UI writes with no data-loss trigger), does not
  touch dead code, does not resolve the dual-session grammar (C-2), and does not flip Swift 6 mode. Stay
  tight to the crash + data-loss + Reduce-Motion surface.

---

## Files

### Create
_None._ This is a hardening pass — no new files.

### Modify

| File | Line anchors (2026-07-01) | Responsibility of the edit |
|---|---|---|
| `Vayl/Design/Components/Cards/ConversationCard.swift` | `:311` (crash), `:82-87` (pulse loop) | Replace `try!` markdown with `try?` + plain-text fallback; gate the 2s scale pulse behind Reduce Motion. |
| `Vayl/Core/Services/SyncManager.swift` | `:289`, `:317`, `:320` | Convert three bare `try? context.save()` in the durable push queue to `saveWithLogging()` with logged failure handling. |
| `Vayl/Design/Components/Cards/CardCarousel.swift` | `:88` (env already present), `:106-126` (three loops) | Gate the three `.repeatForever` idle loops (`borderRotation`, `floatOffset`, `bloomOpacity`) behind Reduce Motion. |
| `Vayl/Design/Components/Cards/AtmosphericGhostDeck.swift` | `:37`, `:51` (drifts), `:55-57` (onAppear) | Add `reduceMotion` env; gate the two 8s / 9.5s ghost-card drifts; swap bare `.animation` → `.ambientAnimation`. |
| `Vayl/Features/Desire Map/Views/DesireMapView.swift` | `:25` (env already present), `:249-268` (starField), `:69` (consumer) | Hold the star-twinkle Canvas static under Reduce Motion (skip the `TimelineView` periodic loop). |
| `Vayl/Core/Services/AppState.swift` | `:153`, `:163` | Convert the two onboarding-completion `try? context.save()` writes to `saveWithLogging()` (silent failure + launch reconcile could revert the user to onboarding). |
| `Vayl.xcodeproj/project.pbxproj` | `:558`, `:595` (+ test targets `:615`,`:636`,`:655`,`:674`) | CFG-3 only: `TARGETED_DEVICE_FAMILY = "1,2"` → `"1"` (iPhone-only for V1). |

### Delete
_None._

---

## Build steps (segments)

Built in one pass; ordered here for readability. Each segment is behavior-preserving except where the
current behavior is the bug.

---

### Segment 1 — H-1: kill the `try!` markdown crash in `ConversationCard`

**One thing:** `try! AttributedString(markdown:)` on content-driven text crashes on unbalanced markdown
metacharacters (`*`, `[`, `\`) in the highlighted phrase. Reachable via the Vault (Map tab). Make it a
safe `try?` with a plain-text fallback so a malformed phrase degrades to unstyled text instead of a trap.

**Exact change** — `Vayl/Design/Components/Cards/ConversationCard.swift`, inside
`highlightedQuestion(card:)` (the `.overlay(alignment: .topLeading)` closure, currently `:309-319`):

BEFORE:
```swift
                .overlay(alignment: .topLeading) {
                    let prefix = AttributedString(parts[0])
                    let highlighted = try! AttributedString(markdown: "**\(card.highlightedPhrase)**")
                    var combined = prefix
                    combined += highlighted

                    return Text(combined)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
```

AFTER:
```swift
                .overlay(alignment: .topLeading) {
                    let prefix = AttributedString(parts[0])
                    // Content-driven phrase: unbalanced markdown metachars (*, [, \) would
                    // trap on try!. Fall back to a plain (unstyled) phrase rather than crash.
                    let highlighted = (try? AttributedString(markdown: "**\(card.highlightedPhrase)**"))
                        ?? AttributedString(card.highlightedPhrase)
                    var combined = prefix
                    combined += highlighted

                    return Text(combined)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
```

**Done:** no `try!` remains in `ConversationCard.swift`; a phrase containing an unbalanced `*` renders as
plain text instead of crashing.

---

### Segment 2 — H-3: stop silent data loss in `SyncManager`'s durable queue

**One thing:** the durable `SyncTask` push queue uses bare `try? context.save()` at three points. If the
save after `context.delete(task)` fails, the deletion is silently lost and the task re-processes next
launch (duplicate push). A failed retry-count bump silently loses retry accounting. Route all three
through `saveWithLogging()` so failures are visible in the log instead of swallowed.

**Site A — `enqueueSyncTask`, currently `:285-294`.**

BEFORE:
```swift
    func enqueueSyncTask(taskType: String, entityId: String, payload: Data? = nil) {
        let context = ModelContext(ModelContainer.appContainer)
        let task = SyncTask(taskType: taskType, entityId: entityId, payload: payload)
        context.insert(task)
        try? context.save()
        logger.info("Enqueued SyncTask: \(taskType) for entity \(entityId)")

        // Trigger a process run in the background
        Task { await processTaskQueue() }
    }
```

AFTER:
```swift
    func enqueueSyncTask(taskType: String, entityId: String, payload: Data? = nil) {
        let context = ModelContext(ModelContainer.appContainer)
        let task = SyncTask(taskType: taskType, entityId: entityId, payload: payload)
        context.insert(task)
        do {
            try context.saveWithLogging()
            logger.info("Enqueued SyncTask: \(taskType) for entity \(entityId)")
        } catch {
            logger.error("Failed to enqueue SyncTask (\(taskType), entity \(entityId)): \(error.localizedDescription)")
        }

        // Trigger a process run in the background
        Task { await processTaskQueue() }
    }
```

**Site B + C — `processTaskQueue`, the `for` loop currently `:304-323`.** The success-path delete save
(`:317`) and the retry-count bump save (`:320`) both need it. Note the loop is `for task in tasks` with a
`do/catch` around the network push — keep that outer `do/catch` and add nested handling for the saves.

BEFORE:
```swift
        for task in tasks {
            do {
                switch task.taskType {
                case "sync_session":
                    if let payload = task.payload {
                        try await SessionSyncService.shared.pushSession(payload: payload)
                    }
                default:
                    logger.warning("Unknown taskType in queue: \(task.taskType)")
                }

                // On success, remove from queue
                context.delete(task)
                try? context.save()
            } catch {
                task.retryCount += 1
                try? context.save()
                logger.error("SyncTask failed (\(task.taskType), retries: \(task.retryCount)): \(error.localizedDescription)")
            }
        }
```

AFTER:
```swift
        for task in tasks {
            do {
                switch task.taskType {
                case "sync_session":
                    if let payload = task.payload {
                        try await SessionSyncService.shared.pushSession(payload: payload)
                    }
                default:
                    logger.warning("Unknown taskType in queue: \(task.taskType)")
                }

                // On success, remove from queue. If this save fails the delete is lost and the
                // task re-processes next launch (duplicate push) — so surface the failure.
                context.delete(task)
                do {
                    try context.saveWithLogging()
                } catch {
                    logger.error("Failed to persist SyncTask deletion (\(task.taskType)): \(error.localizedDescription)")
                }
            } catch {
                task.retryCount += 1
                // Persist the retry-count bump; a lost save silently drops retry accounting.
                do {
                    try context.saveWithLogging()
                } catch {
                    logger.error("Failed to persist SyncTask retry bump (\(task.taskType)): \(error.localizedDescription)")
                }
                logger.error("SyncTask failed (\(task.taskType), retries: \(task.retryCount)): \(error.localizedDescription)")
            }
        }
```

**Done:** no bare `try? context.save()` remains in `SyncManager.swift`; every save failure in the durable
queue is logged.

---

### Segment 3 — H-5: gate `CardCarousel`'s three idle loops behind Reduce Motion

**One thing:** `CardCarousel.onAppear` fires three `.repeatForever` loops (`borderRotation`,
`floatOffset`, `bloomOpacity`) unconditionally. This component renders across Home / Play / OB, so it's
the highest-value a11y fix. The View **already** has
`@Environment(\.accessibilityReduceMotion) private var reduceMotion` at `:88` — just guard the loops.

**Exact change** — `Vayl/Design/Components/Cards/CardCarousel.swift`, the `.onAppear` in `body`
(currently `:106-126`).

BEFORE:
```swift
        .onAppear {
            onPhaseChange?(.floating)

            // Border rotation — ambient loop, 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.linear(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: false)) {
                borderRotation = 360.0
            }

            DispatchQueue.main.async {
                // Float loop — 3.2s intentional, slightly below ambientDrift (4.0s).
                // Gives card a faster, more responsive idle breath.
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    floatOffset = -6
                }
            }

            // Bloom pulse — 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                bloomOpacity = 0.75
            }
        }
```

AFTER:
```swift
        .onAppear {
            onPhaseChange?(.floating)

            // Ambient idle loops — disabled entirely under Reduce Motion (the static
            // resting state must read without motion). The phase callback above always fires.
            guard !reduceMotion else { return }

            // Border rotation — ambient loop, 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.linear(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: false)) {
                borderRotation = 360.0
            }

            DispatchQueue.main.async {
                // Float loop — 3.2s intentional, slightly below ambientDrift (4.0s).
                // Gives card a faster, more responsive idle breath.
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    floatOffset = -6
                }
            }

            // Bloom pulse — 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                bloomOpacity = 0.75
            }
        }
```

**Note:** `onPhaseChange?(.floating)` must stay **above** the `guard` — it is a state callback, not an
animation, and the carousel must still emit its phase under Reduce Motion. The rest of the file already
gates its reactive animations correctly; only these three ambient loops were ungated.

**Done:** with Reduce Motion on, the carousel renders static (no rotating border, no float breath, no
bloom pulse) and still reports `.floating`.

---

### Segment 4 — ambient RM: gate `AtmosphericGhostDeck`'s two ghost-card drifts

**One thing:** the two ghost cards behind a conversation card drift on 8.0s / 9.5s `.repeatForever`
loops with no Reduce-Motion gate. This view is active via `ConversationCard`. Add the `reduceMotion`
environment (the file does **not** have it yet), gate the `drifting = true` trigger, and swap the two
bare `.animation(...)` modifiers for `.ambientAnimation(_:value:)` so the transaction also strips the
animation under Reduce Motion.

**Change 4a — add the environment.** `Vayl/Design/Components/Cards/AtmosphericGhostDeck.swift`,
currently `:19-20`:

BEFORE:
```swift
    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false
```

AFTER:
```swift
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false
```

**Change 4b — swap the two drift animations to `.ambientAnimation`.** Ghost 1 (currently `:36-39`) and
Ghost 2 (currently `:50-53`).

Ghost 1 BEFORE:
```swift
                .animation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )
```

Ghost 1 AFTER:
```swift
                .ambientAnimation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )
```

Ghost 2 BEFORE:
```swift
                .animation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
```

Ghost 2 AFTER:
```swift
                .ambientAnimation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
```

**Change 4c — gate the drift trigger.** The `.onAppear` currently `:55-57`:

BEFORE:
```swift
        .onAppear {
            drifting = true
        }
```

AFTER:
```swift
        .onAppear {
            guard !reduceMotion else { return }
            drifting = true
        }
```

The 8.0s / 9.5s durations are deliberate feel values (🎚️) — leave them inline; they are not tokens.

**Done:** with Reduce Motion on, the two ghost cards hold their static offset/rotation and do not drift.

---

### Segment 5 — ConversationCard pulse: key the 2s scale pulse on Reduce Motion

**One thing:** the card's `scaleEffect(pulsing ? 1.02 : 1.0)` runs a 2s `.repeatForever` ternary keyed on
`pulsing`, not on Reduce Motion. `ConversationCard` does **not** currently declare the `reduceMotion`
environment — add it, then fold it into the animation ternary so the pulse is `.default` (no repeat)
under Reduce Motion while still confirming the state change.

**Change 5a — add the environment.** `Vayl/Design/Components/Cards/ConversationCard.swift`, in the
`// MARK: - State` block (currently `:20-24`):

BEFORE:
```swift
    @State private var isFlipped = false
    @State private var arrowVisible = false
    @State private var pulsing = false
    @State private var selectedPill: CardRevealPill? = nil
    @State private var showEncouragement = false
```

AFTER:
```swift
    @State private var isFlipped = false
    @State private var arrowVisible = false
    @State private var pulsing = false
    @State private var selectedPill: CardRevealPill? = nil
    @State private var showEncouragement = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**Change 5b — gate the pulse animation.** The `.animation` on the card frame (currently `:81-87`):

BEFORE:
```swift
            .scaleEffect(pulsing ? 1.02 : 1.0)
            .animation(
                pulsing
                    ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
```

AFTER:
```swift
            .scaleEffect((pulsing && !reduceMotion) ? 1.02 : 1.0)
            .animation(
                (pulsing && !reduceMotion)
                    ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
```

Gating the `scaleEffect` value too (not just the animation) means the card holds at `1.0` under Reduce
Motion rather than snapping to a static `1.02` — the resting state is the un-pulsed frame.

**Done:** with Reduce Motion on, the conversation card does not breathe; without it, the 2s pulse is
unchanged.

---

### Segment 6 — starField: hold the twinkle static under Reduce Motion

**One thing:** `DesireMapView.starField` runs a `TimelineView(.periodic(from: .now, by: 0.067))` (~15fps)
Canvas twinkle with no Reduce-Motion gate. The rest of the file is meticulous about it and already has
`@Environment(\.accessibilityReduceMotion) private var reduceMotion` in scope (`:25`). Under Reduce
Motion, render one static frame (each star at its `base` opacity, twinkle amplitude collapsed) instead of
the periodic loop.

**Exact change** — `Vayl/Features/Desire Map/Views/DesireMapView.swift`, the `starField` computed
property (currently `:249-268`).

BEFORE:
```swift
    private var starField: some View {
        TimelineView(.periodic(from: .now, by: 0.067)) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1000)
                for (idx, star) in DesireMapView._bgStars.enumerated() {
                    let (xr, yr, d, base, period) = star
                    let opacity: Double = period > 0
                        ? 0.2 + (sin((elapsed / period + Double(idx) * 0.37) * .pi * 2) * 0.5 + 0.5) * 0.6
                        : base
                    let x = size.width * xr
                    let y = size.height * yr
                    let r = d / 2
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: d, height: d)),
                             with: .color(.white.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
```

AFTER:
```swift
    private var starField: some View {
        Group {
            if reduceMotion {
                // Reduce Motion: one static frame — no periodic twinkle loop. Twinkling stars
                // (period > 0) hold at their base opacity; the sky reads fully without motion.
                Canvas { ctx, size in
                    for star in DesireMapView._bgStars {
                        let (xr, yr, d, base, _) = star
                        let x = size.width * xr
                        let y = size.height * yr
                        let r = d / 2
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: d, height: d)),
                                 with: .color(.white.opacity(base)))
                    }
                }
            } else {
                TimelineView(.periodic(from: .now, by: 0.067)) { timeline in
                    Canvas { ctx, size in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 1000)
                        for (idx, star) in DesireMapView._bgStars.enumerated() {
                            let (xr, yr, d, base, period) = star
                            let opacity: Double = period > 0
                                ? 0.2 + (sin((elapsed / period + Double(idx) * 0.37) * .pi * 2) * 0.5 + 0.5) * 0.6
                                : base
                            let x = size.width * xr
                            let y = size.height * yr
                            let r = d / 2
                            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: d, height: d)),
                                     with: .color(.white.opacity(opacity)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
```

Note the twinkling stars carry a `base` opacity value in their tuple (position 4) already — the static
frame uses it directly, so no new values are invented. `starField` is consumed at `:69`
(`starField.ignoresSafeArea()`), which is unaffected by this change.

**Done:** with Reduce Motion on, the Desire Map background stars are painted once and hold; without it,
the ~15fps twinkle is unchanged.

---

### Segment 7 — low-sev save consistency: `AppState` onboarding-completion writes

**One thing:** `markOnboardingComplete` and `resetOnboarding` persist the durable onboarding-completion
truth with bare `try? context.save()`. A silent failure here plus the launch reconcile
(`hydrateOnboardingState`, which trusts `UserProfile`) could revert the user back into onboarding. These
are the only two save sites in `AppState` where a failed save corrupts routing state — convert both to
`saveWithLogging()`. (Do NOT sweep the cosmetic best-effort `try?` sites elsewhere; those are out of
scope.)

**Site A — `markOnboardingComplete`, currently `:150-155`.**

BEFORE:
```swift
    func markOnboardingComplete(_ profile: UserProfile, context: ModelContext) {
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt  = Date()
        try? context.save()
        isOnboardingComplete = true   // didSet writes the UserDefaults cache
    }
```

AFTER:
```swift
    func markOnboardingComplete(_ profile: UserProfile, context: ModelContext) {
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt  = Date()
        do {
            try context.saveWithLogging()
        } catch {
            // A lost completion save + the launch reconcile (which trusts UserProfile) could
            // revert the user to onboarding. Surface the failure rather than swallow it.
            logger.error("Failed to persist onboarding completion: \(error.localizedDescription)")
        }
        isOnboardingComplete = true   // didSet writes the UserDefaults cache
    }
```

**Site B — `resetOnboarding`, currently `:160-165`.**

BEFORE:
```swift
    func resetOnboarding(_ profile: UserProfile?, context: ModelContext?) {
        profile?.hasCompletedOnboarding = false
        profile?.onboardingCompletedAt  = nil
        if let context { try? context.save() }
        isOnboardingComplete = false
    }
```

AFTER:
```swift
    func resetOnboarding(_ profile: UserProfile?, context: ModelContext?) {
        profile?.hasCompletedOnboarding = false
        profile?.onboardingCompletedAt  = nil
        if let context {
            do {
                try context.saveWithLogging()
            } catch {
                logger.error("Failed to persist onboarding reset: \(error.localizedDescription)")
            }
        }
        isOnboardingComplete = false
    }
```

**Verify a `logger` is in scope in `AppState.swift`.** If the file already declares an `OSLog.Logger`
(most `Core/Services` files do), reuse it. If it does not, add near the top of the file, matching the
existing subsystem convention seen in `ModelContext+Extensions.swift:17-20`:
```swift
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AppState")
```
Only add this if `logger` is not already present — do not create a duplicate.

**Done:** both onboarding-completion writes go through `saveWithLogging()`; a failed save is logged, not
silently dropped.

---

### Segment 8 — CFG-3: device family → iPhone-only

**One thing:** `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad). All layout is portrait-phone geometry
(`AppLayout.from(geo)`, fixed card aspect ratios); iPad is shipping untested. For V1, set iPhone-only.
This is the ONE safe project-config edit in this plan.

**Exact change** — `Vayl.xcodeproj/project.pbxproj`. Six occurrences of:
```
				TARGETED_DEVICE_FAMILY = "1,2";
```
at lines `:558`, `:595` (the app target Debug / Release) and `:615`, `:636`, `:655`, `:674` (the Tests
and UITests targets). Change **all six** to:
```
				TARGETED_DEVICE_FAMILY = "1";
```
The app-target pair (558 / 595) is what makes the shipped app iPhone-only; keeping the test targets in
sync avoids a device-family mismatch warning between the app and its test bundles. A `replace_all` of the
literal `TARGETED_DEVICE_FAMILY = "1,2";` → `TARGETED_DEVICE_FAMILY = "1";` is safe — every occurrence is
this same setting.

**Done:** `grep -n 'TARGETED_DEVICE_FAMILY' Vayl.xcodeproj/project.pbxproj` shows only `"1"`; the project
still opens and builds.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

- [ ] `grep -n 'try!' Vayl/Design/Components/Cards/ConversationCard.swift` → **no match** (Segment 1).
- [ ] A conversation-card highlighted phrase containing an unbalanced `*` renders as plain text, no crash.
- [ ] `grep -n 'try? context.save()' Vayl/Core/Services/SyncManager.swift` → **no match** (Segment 2).
- [ ] All three `SyncManager` durable-queue saves go through `saveWithLogging()` with a logged catch.
- [ ] `CardCarousel.onAppear` returns early under Reduce Motion after firing `onPhaseChange?(.floating)`;
      none of the three loops start (Segment 3).
- [ ] `AtmosphericGhostDeck` declares `reduceMotion`, its two drifts use `.ambientAnimation`, and
      `drifting` is gated (Segment 4).
- [ ] `ConversationCard` declares `reduceMotion`; the 2s scale pulse holds at `1.0` under Reduce Motion
      (Segment 5).
- [ ] `DesireMapView.starField` renders one static frame under Reduce Motion (no `TimelineView` loop);
      the twinkle path is unchanged otherwise (Segment 6).
- [ ] `grep -n 'try? context.save()' Vayl/Core/Services/AppState.swift` → **no match**; both
      onboarding-completion writes use `saveWithLogging()` (Segment 7).
- [ ] `grep -n 'TARGETED_DEVICE_FAMILY' Vayl.xcodeproj/project.pbxproj` shows only `"1"` (Segment 8).
- [ ] Project compiles green (no new warnings introduced by these edits).

---

## Bryan verifies on device

- **Reduce Motion, everywhere it now matters.** Turn on Settings → Accessibility → Motion → Reduce
  Motion, then walk: Home (carousel static — no rotating border, no float, no bloom pulse), Play (same
  carousel static), any `ConversationCard` (no breathe, ghost cards behind it hold still), Desire Map
  background (stars painted once, no twinkle). Then turn Reduce Motion off and confirm all four are lively
  again. 🎚️ The 3.2 / 8.0 / 9.5s idle-drift feel is unchanged — you're only confirming the on/off gate.
- **Vault crash path (H-1).** In the Vault (Map tab), open a conversation card whose highlighted phrase
  contains a literal `*` or `[` if any such content exists; confirm it renders (unstyled phrase is fine),
  no crash. If no such content exists yet, this is latent-safe — nothing to feel.
- **Onboarding completion still routes.** Complete onboarding once, force-quit, relaunch — you land in
  the app, not back in onboarding. (The save is now logged on failure, so if it ever *does* fail you'll
  see it in Console rather than silently reverting.)
- **iPad is gone (CFG-3).** After the device-family change, the app no longer offers an iPad install
  target. Confirm iPhone install/run is unaffected. If you decide you *do* want iPad later, this is a
  one-line revert — see Open decisions.

---

## Constraints / do-not-touch

- **`VaylCardFace` shell:** untouched. `.drawingGroup()` stays. None of these edits go near it.
- **No token invention.** The 3.2 / 8.0 / 9.5s idle durations stay as inline feel values — do NOT coin
  new `AppAnimation` tokens for them. Reuse `AppAnimation.ambientDrift` only where the code already does.
- **No behavior change beyond the fix.** Segments 3–6 must be pure Reduce-Motion gates: with Reduce Motion
  OFF, every animation is byte-for-byte the same as before. Do not "improve" timings, easing, or feel.
- **Scope discipline.** Do NOT sweep the cosmetic best-effort `try?` sites the audit lists as UI writes
  (`DesireMapStore:133,159`, `MapStore:217,224`, `VaultStore:180,195,223`, `EntitlementStore:198`,
  `SettingsIdentityView:229`, `DesireMapView:1053`). This plan only hardens the sites where a failed save
  corrupts state (SyncManager queue, AppState onboarding).
- **Do NOT touch** `IPHONEOS_DEPLOYMENT_TARGET` or `SWIFT_VERSION` in `project.pbxproj` (see CFG-1 / CFG-2
  in Open decisions — decisions only, no code change this pass).
- **Do NOT resolve** the dual card-session grammar (C-2) or delete any dead code here — separate passes.

---

## Open decisions

Each has a recommended default so Fable is never blocked.

- **CFG-3 — device family (iPhone vs iPhone + iPad).** RECOMMENDED and included as Segment 8: set
  `TARGETED_DEVICE_FAMILY = "1"` (iPhone-only) for V1. All layout is portrait-phone geometry and iPad is
  shipping untested, so shipping an iPad target invites layout bugs on a device you haven't verified. This
  is a safe, one-line-per-occurrence, trivially reversible edit. **Fable proceeds on iPhone-only.** If
  Bryan wants iPad as a deliberate V1 goal, revert the six occurrences back to `"1,2"` and schedule an
  iPad layout audit — but that is not this pass.

- **CFG-1 — deployment target wording (iOS 26.2 vs "iOS 16+ baseline").** DECISION ONLY, no code change.
  The project targets `IPHONEOS_DEPLOYMENT_TARGET = 26.2`, which contradicts the "iOS 16+ baseline"
  language in `CLAUDE.md`. Per the CLAUDE.md iOS-26 mandate section, the iOS-26 target is the intentional
  choice (the app installs on nothing below 26.2). RECOMMENDED: reconcile the *wording* — update the
  "iOS 16+ baseline" phrasing in `CLAUDE.md` to state the intentional iOS-26 target, so the contract stops
  contradicting itself. **Do NOT change the deployment target or edit CLAUDE.md in this pass** (this is a
  code-hardening one-shot; the wording fix is a doc edit for Bryan to make deliberately). Flagged, not
  acted on.

- **CFG-2 — Swift language mode (Swift 5 vs Swift 6).** DECISION ONLY, no code change, and explicitly
  DEFERRED. The project is `SWIFT_VERSION = 5.0` with no strict concurrency, while the 4-layer
  architecture assumes the `@MainActor` / data-race guarantees that only Swift 6 (or
  `-strict-concurrency=complete`) actually enforces. RECOMMENDED: **defer.** Flipping to Swift 6 mode in
  this one-shot would surface strict-concurrency errors app-wide (every `@MainActor` boundary, every
  Service hop, every `nonisolated` delegate) and is its own multi-day project — it does not belong in a
  correctness/a11y hardening pass. **Fable does NOT change `SWIFT_VERSION`.** Risk of deferring: the
  concurrency findings in the audit remain real *runtime* risks rather than compile errors until the
  migration happens. Track it as a standalone future pass.
