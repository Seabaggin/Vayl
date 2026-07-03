# 23 — Session Practice Hand (the dealer returns)

**Goal:** Implement teaching decision **1A** from the decided teaching-strategy spec
(`docs/superpowers/specs/2026-07-03-feature-teaching-strategy-design.md`): a couple's FIRST card
session opens with a short, dealer-voiced guided beat sequence that teaches the four things the
airlock's words cannot demonstrate — the two-device table, whose-draw-reads-aloud, the care
mark/safe word, and the hold-to-deal gesture (practiced for real, not described) — then dissolves
into card 1. Repeat sessions never see it.

**Architecture:** one new View (the overlay), one presentation hook in `SessionPlayerView`. NO
store changes, NO sync-protocol changes, NO new UserDefaults key (reuses
`hasCompletedCoupleSession`). The overlay is per-device chrome, deliberately outside the shared
session state.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Same license as plans 16-22: implement this ENTIRE plan in ONE pass, build-green, no per-segment
> device stops. Still mandatory: 4-layer architecture, tokens only, `.vaylCover`/`.vaylSheet`
> grammar, iOS 26 compliance, Reduce Motion fallbacks, press+haptic+action on every tap target.
> Every path/symbol below verified against the repo on **2026-07-03**. If reality differs, trust
> the repo and note the drift.
>
> Verification is deferred to Bryan's two-device pass. Items marked 🎚️ are feel/copy values.

---

## Context Fable needs

### The one architectural rule this plan is built around

**The practice beat must NOT be a card in the shared hand.** Both devices derive the session from
the same deck and keep their `index` in lockstep (`CoupleSessionStore.advanceOrFinish` does an
optimistic local bump plus a conditional remote write against `expectedIndex`; the drawer
alternates off `index % 2`). Prepending a practice card client-side, gated on a LOCAL
UserDefaults flag, would make the two devices disagree about what index N means the moment one
partner has the flag and the other doesn't (re-pair, reinstall, one partner's second couple).
That is a silent desync of the most protected experience in the app. So the practice hand is a
**per-device overlay** rendered above the player: it never touches `index`, `effectiveHand`,
records, or the realtime row. The teaching cost of that choice (the practice hold advances a
LOCAL replica, not the real shared deck) is bought back in the copy: the final beat says the real
control moves both screens.

### Existing machinery this plan rides (all verified 2026-07-03)

- **`SessionPlayerView.swift`** is the in-session player. Its `ZStack` already layers, in order:
  `fanDeck` → `screenLayer` → `dealingCard` → `warpFlash` → `controls` → idle-dim → pause overlay →
  `ContextBeatOverlayView` at `.zIndex(10)`. The practice overlay slots above everything at
  `.zIndex(20)`.
- **The hold-to-deal mechanic** (`startHold`/`endHold`/`commitDeal`, lines ~518-560): a
  `DragGesture(minimumDistance: 0)` on `proceedButton`, a 16ms loop filling `fill` over
  `holdSeconds` (0.85), release-early resets with `AppAnimation.standard`, commit fires a `.rigid`
  haptic. The practice replica mirrors this exactly (same timings, same capsule look from
  `proceedButton`, lines ~419-447) but drives only local overlay state.
- **The care mark** is the `circle.hexagongrid` button in `leftStack` (~line 353); **the safe word**
  is the `safetyAccent` capsule below it (`store.safeWordLabel`). The practice overlay ECHOES their
  look (non-functional replicas inside the overlay) rather than spotlighting the real ones — no
  coach-mark geometry, per the teaching spec's banned-patterns list.
- **Turn language already exists:** `drawerRow` renders "Your draw, read it aloud" /
  "Partner's draw, read it aloud", and the room's ambient color leans magenta-for-you /
  cyan-for-partner (SessionPlayerView header comment). The practice copy names what the player
  already shows.
- **The first-run flag:** `UserDefaultsKey.hasCompletedCoupleSession` is set true in
  `CoupleSessionStore.finishSession` (`CoupleSessionStore.swift:695`) and read by `AirlockView`
  (line 32) to collapse the house rules. The practice overlay gates on the SAME flag: one flag,
  one meaning ("this device has finished a couple session"), airlock collapse and practice hand
  stay in sync by construction. An abandoned first session re-teaches next time: harmless, correct.
- **The pause overlay** (~lines 70-95 of SessionPlayerView) is the in-file precedent for a
  full-surface scrim: `Rectangle().fill(AppColors.void).opacity(0.72).ignoresSafeArea()`.
- **Dealer voice:** the OB dealer is the app's established teacher. Copy below is drafted in that
  register (lowercase, direct, unhurried) and marked 🎚️ for Bryan's editorial pass.

### Accepted edges (do not fix)

- **The soft session timer runs during the practice (~30-45s).** The timer never advances anything
  (`CoupleSessionStore` comment: "soft: NEVER advances"); losing under a minute of a first session's
  timer to teaching is fine. Do not pause/extend the shared timer for this — that WOULD be a sync
  change.
- **A veteran partner paired with a first-timer** (flag true on one device only): the veteran sees
  card 1 immediately and could deal while the first-timer is mid-practice; the first-timer then
  lands on whatever card is current. Rare (couples' first sessions are usually first for both), and
  the presence/pause machinery already tolerates partners being momentarily out of step. Accepted.
- **The practice hold does not advance the real deck.** Deliberate (see the architectural rule).

## Files

| Action | File | Responsibility |
|---|---|---|
| Create | `Vayl/Features/Sessions/Components/DealerPracticeOverlayView.swift` | The four-beat dealer overlay, incl. the local practice hold |
| Modify | `Vayl/Features/Sessions/SessionPlayerView.swift` | Present the overlay at `.zIndex(20)` on first-ever session |

No other files change. No store, service, model, or schema edits anywhere.

## Build steps

### Step 1 — `DealerPracticeOverlayView`

Create `Vayl/Features/Sessions/Components/DealerPracticeOverlayView.swift`:

```swift
//
//  DealerPracticeOverlayView.swift
//  Vayl
//
//  The dealer's practice hand (teaching decision 1A, spec 2026-07-03): a
//  per-device, four-beat guided opening shown once, on a couple's first-ever
//  session, above the live player. Beats 1-3 are worded and tap-advanced;
//  beat 4 is the hold-to-deal gesture practiced for real against a local
//  replica of the proceed control. Never touches CoupleSessionStore — the
//  shared session state (index, hand, records, realtime row) is invisible to
//  this view by design; a locally-gated shared-hand card would desync the
//  two devices' indices.
//

import SwiftUI

struct DealerPracticeOverlayView: View {

    /// Fired when the practice hold commits — the host removes the overlay.
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var beat = 1

    // Practice-hold state — mirrors SessionPlayerView's real mechanic
    // (holdSeconds, 16ms fill loop, release-early reset) 1:1 so the gesture
    // the user practices is exactly the gesture they'll use.
    @State private var fill: CGFloat = 0
    @State private var holding = false
    private let holdSeconds: Double = 0.85
    private let capsuleWidth: CGFloat = 168

    var body: some View {
        ZStack {
            Rectangle()
                .fill(AppColors.void)
                .opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                dealerLine
                    .id(beat)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 0, y: 6)),
                        removal:   .opacity.combined(with: .offset(x: 0, y: -6))
                    ))

                if beat == 3 { careEcho }
                if beat == 4 { practiceHold } else { tapHint }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .animation(reduceMotion ? AppAnimation.fast : AppAnimation.standard, value: beat)
    }

    // MARK: - Beats

    private var dealerLine: some View {
        Text(copy(for: beat))
            .font(AppFonts.prompt)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // 🎚️ Dealer copy — Bryan's editorial pass. No em dashes.
    private func copy(for beat: Int) -> String {
        switch beat {
        case 1:  return "Two devices, one table. When either of you deals, both screens move together."
        case 2:  return "The room tells you whose draw it is. Whoever draws reads the card aloud."
        case 3:  return "If anything gets heavy: the care mark, bottom left. Either of you, any time, no reason needed. The safe word ends the night, one tap, no questions."
        default: return "Hold to deal. Release early and nothing happens. Try it, and your first card is waiting."
        }
    }

    private var tapHint: some View {
        Text("tap to continue")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
    }

    private func advance() {
        guard beat < 4 else { return }   // beat 4 completes by holding, not tapping
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        beat += 1
    }

    // MARK: - Care echo (beat 3) — non-functional replicas, not a spotlight

    private var careEcho: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "circle.hexagongrid")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 54, height: 54)
                .background(Circle().fill(AppColors.cardBackground))
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))

            Text("VAYL")   // matches the default safeWordLabel treatment
                .font(AppFonts.buttonLabelSmall)
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(AppColors.safetyAccent)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule().fill(AppColors.safetyAccent.opacity(0.08))
                        .overlay(Capsule().strokeBorder(
                            AppColors.safetyAccent.opacity(0.25), lineWidth: 1))
                )
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - Practice hold (beat 4) — the real gesture, local consequences

    private var practiceHold: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(AppColors.spectrumBorder.opacity(0.32))
                .frame(width: max(0, capsuleWidth * fill))
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.display(13, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(AppColors.spectrumText)
                Text(holding ? "keep holding…" : "hold to deal")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textBody)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .frame(width: capsuleWidth, height: 44)
        .background(Capsule().fill(AppColors.cardBackground.opacity(0.6)))
        .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: 1))
        .clipShape(Capsule())
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startPracticeHold() }
                .onEnded { _ in endPracticeHold() }
        )
        .accessibilityLabel("Hold to deal. Practice the gesture to begin the session.")
    }

    private func startPracticeHold() {
        guard !holding else { return }
        holding = true
        fill = 0
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let start = Date()
        Task { @MainActor in
            while holding {
                let elapsed = Date().timeIntervalSince(start)
                fill = min(1, CGFloat(elapsed / holdSeconds))
                if fill >= 1 {
                    holding = false
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    onComplete()
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endPracticeHold() {
        guard holding else { return }
        holding = false
        withAnimation(AppAnimation.standard) { fill = 0 }
    }
}
```

Verify against source while building: the capsule/haptic/timing values above were copied from
`SessionPlayerView.proceedButton` + `startHold`/`endHold` on 2026-07-03 — if that file's values
have drifted, MATCH THE FILE, don't keep the plan's copy. Same for the care-mark/safe-word replica
treatments (copied from `leftStack`). If `store.safeWordLabel`'s default is not "VAYL", match
whatever the real default is (check `CoupleSessionStore`).

### Step 2 — Present it in `SessionPlayerView`

Add state (beside the other `@State` properties, ~line 34):

```swift
/// The dealer's practice hand (plan 23): shown once, on this device's first-ever
/// couple session — same flag the airlock uses to collapse its house rules, so
/// "first time" means the same thing everywhere. Read once at init; never
/// re-evaluated mid-session.
@State private var showPractice = !UserDefaults.standard.bool(
    forKey: UserDefaultsKey.hasCompletedCoupleSession
)
```

In `body`'s `ZStack`, after the `ContextBeatOverlayView` block (`.zIndex(10)`):

```swift
if showPractice {
    DealerPracticeOverlayView {
        withAnimation(AppAnimation.exit) { showPractice = false }
    }
    .zIndex(20)
    .transition(.opacity)
}
```

Do NOT write `hasCompletedCoupleSession` here — it stays owned by
`CoupleSessionStore.finishSession` (a completed session is what flips it; an abandoned first
session re-teaching next time is intended).

Also gate the idle-dim's `scheduleIdle()` interaction: no change needed (the overlay's
`onTapGesture` sits above the player's `wake()` tap; the idle dim behind an opaque-ish scrim is
invisible anyway). Verify the overlay does not block `store.isPaused`'s partner-away overlay
logically: pause sits at the player's own layer below zIndex 20, which is fine — a partner pausing
mid-practice resolves the moment the practice ends.

### Step 3 — Compile check

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug build`
green. Grep-verify: `DealerPracticeOverlayView` has exactly one caller (SessionPlayerView), no
store/service imports beyond SwiftUI, and zero writes to `hasCompletedCoupleSession` outside
`CoupleSessionStore.swift:695`.

## Definition of Done (build-green)

- [ ] `DealerPracticeOverlayView` exists as pure View chrome: no `CoupleSessionStore` reference,
      no realtime/service reference, no shared-state mutation of any kind.
- [ ] First-ever session (flag false): the player loads card 1 underneath, the overlay plays
      beats 1→2→3 (tap-advanced, care/safe-word echoes on beat 3) → beat 4's practice hold, and a
      committed hold dissolves the overlay into the live session.
- [ ] Releasing the practice hold early resets its fill and nothing else happens (the
      release-to-cancel lesson is the mechanic itself).
- [ ] Repeat sessions (flag true): the overlay never constructs; the player is pixel-identical to
      today.
- [ ] The shared session state is provably untouched: `index`, `effectiveHand`, `records`, the
      realtime row, and the timer all behave exactly as before on both devices.
- [ ] Reduce Motion: beat transitions use `AppAnimation.fast`; the hold works unchanged (it is a
      gesture, not an animation).
- [ ] Tokens only; every tappable has press feedback + haptic + action; no em dashes in copy.

## Bryan verifies on device (two-device pass — fold into the plan-16 proof session)

- Fresh flag on both devices: start a first session; confirm both partners get the practice
  independently, the beats read as the dealer (not as a corporate tutorial), and the practice hold
  feels identical to the real one.
- Confirm the first REAL deal after the practice works normally and both screens advance together.
- Veteran + first-timer mix (clear one device's flag only): confirm nothing desyncs; the
  first-timer lands on the current card after practicing.
- Safe word and care mark during a first session: confirm both still work while the overlay is up
  is NOT required (the overlay precedes real play), but confirm they work immediately after.
- 🎚️ Dealer copy editorial pass; 🎚️ scrim opacity (0.72, matches pause) and beat pacing.

## Constraints / do-not-touch

- NO changes to `CoupleSessionStore.swift`, `SessionSyncCoordinator.swift`,
  `RealtimeSessionService.swift`, `AirlockView.swift`/`AirlockStore.swift`, `RevealEngine.swift`,
  or any reveal view. The overlay is chrome; the session engine is finished (plan 16) and in its
  two-device proof window.
- Do not inject a practice card into the hand, the deck content, or the realtime protocol — the
  index-lockstep rule above is the whole reason this plan is shaped the way it is.
- Do not add a skip button; beats tap through in seconds and the hold is the exit. (Duolingo-lesson
  logic: the first session is protected, not skimmable.)
- Card Session presentation stays a `.vaylCover`; nothing here changes presentation grammar.

## Open decisions

1. 🎚️ Dealer copy register (drafted lowercase-dealer; Bryan may want it warmer or drier).
2. Whether beat 3's echoes should pulse once (a single soft glow) to draw the eye: default NO
   (static echo is calm; a pulse flirts with coach-mark energy). Revisit on device only.
3. Whether the practice should ALSO appear for a solo/local DEBUG session (`airlock == nil` mock
   path): default YES (it keys off the flag, not the path), which conveniently makes it testable
   on one device.
