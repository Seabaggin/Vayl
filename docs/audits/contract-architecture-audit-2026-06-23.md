# Vayl — Contract & Architecture Compliance Audit

**Date:** 2026-06-23 (run overnight)
**Branch:** `spec/contextphase-2x3-redesign` (audited working-tree state, including your uncommitted redesign diff)
**Scope:** 274 Swift files under `Vayl/` + `Vayl.xcodeproj`
**Method:** 6 parallel read-only audit agents, one per contract dimension, then spot-verification by hand on the highest-stakes findings. No files were edited.

Legend: **✓ verified** = I confirmed it directly (grep/read), not just agent-reported. Unmarked = agent-reported, line numbers approximate — confirm before editing.

---

## Executive summary

The codebase is in **good architectural health**. The 4-layer discipline, OB phase/`tableFade` ownership, and screen-background conventions are followed consistently. The real debt is concentrated in two places: the **design-token layer** (a few hundred raw values in Views) and a handful of **presentation-grammar slips** — one of which touches the most-protected experience in the app.

**Headline good news:** iOS 26 / Xcode 26 compliance is a **clean bill of health** — zero banned APIs. You're submission-ready on that axis.

**Headline risk:** the **Card Session is presented two different ways** — correctly as a `.vaylCover` in `HomeDashboardView`, but as a swipe-dismissible `.sheet` in the *live* `HomeRouterView`. That directly contradicts the "Card Session is always a `.vaylCover`, never a sheet" rule.

**Meta-finding:** the contract itself (`CLAUDE.md`) has **drifted from the code** in a few places — most importantly it mandates `.glassCard()` and `.hairline()` modifiers that **do not exist**. Fixing the contract is as important as fixing the code, because you and I both write against it as the source of truth.

| Dimension | Verdict |
|---|---|
| iOS 26 banned APIs | ✅ **Clean** — 0 violations |
| 4-layer architecture | ✅ Strong — 3 localized findings |
| Presentation grammar | ⚠️ 11 raw modal sites; 2 contract-critical |
| Required view patterns | ⚠️ Tap-triad / empty-state / ambient gaps + contract drift |
| Design tokens | ⚠️ ~200+ raw values in Views |
| Code hygiene | 🧹 ~40 orphan candidates (likely WIP), ~55 unused tokens |

---

## 🔴 Critical — contract-breaking

### C1. Card Session presented as a `.sheet` in the live home router ✓ verified
- **`Vayl/Features/Home/Views/HomeRouterView.swift:74`** — `.sheet(item: $activeSession) { SessionView(store: session) }`
- `HomeRouterView()` is the **live** Home tab (`Vayl/App/AppShell.swift:20`), and `activeSession` is really assigned (`HomeRouterView.swift:226`). This is not dead code.
- The contract is explicit: *"Card Session is always a `.vaylCover`, never a sheet… interactive-dismiss disabled, confirm-on-exit. A swipe-away sheet mid-session is a violation."*
- **Nuance to resolve first:** there are **two session surfaces**. `HomeRouterView` presents `SessionView(store: SessionStore)` via `.sheet`; `HomeDashboardView:247` presents `CardSessionContainerView(hand:)` via `.vaylCover` (compliant). Confirm whether `SessionView` is a protected card session (two-device / safe-worded) — if so, this is a true Critical and must move to `.vaylCover`. If `SessionView` is a lighter solo surface, decide its grammar deliberately. Either way the inconsistency is a smell worth resolving.
- **Fix direction:** if it's a card session → `.vaylCover`. Possibly the two entry points should be unified onto the one-engine Card Session model.

### C2. Pulse check-in presented as `.fullScreenCover`, not `.vaylCover` ✓ verified
- **`Vayl/Features/Pulse/PulseWidget.swift:79`** — `.fullScreenCover(isPresented: $showCheckIn) { CheckInShell(...) }`
- The contract's mental-state table lists **"Pulse check-in"** explicitly as a `.vaylCover` (protected, immersive). Raw `.fullScreenCover` skips the dismiss-guard / confirm-on-exit.
- **Fix:** convert to `.vaylCover`. Mechanical, but verify the exit/confirm behavior on device.

> iOS 26: **no Critical findings.** All scene-based window access is compliant (`AppLayout.swift:102`, `ScreenshotProtectionModifier.swift`, `ConversationCard.swift`). No `UIScreen.main`, `keyWindow`, `UIWebView`, `NSURLConnection`, `UNAuthorizationOptionAlert`, or armv7 slices. SwiftData (not legacy Core Data) is in use.

---

## 🟠 High

### H1. Raw modal primitives bypass the presentation contract ✓ verified (11 live sites)
All of these should route through `.vaylSheet` / `.vaylCover`:

| File:line | Primitive | Should be |
|---|---|---|
| `HomeRouterView.swift:74` | `.sheet` (session) | `.vaylCover` — see C1 |
| `HomeRouterView.swift:77` | `.fullScreenCover` (Desire Map rater) | `.vaylCover` |
| `HomeRouterView.swift:80` | `.fullScreenCover` (Desire reveal) | `.vaylCover` (or deliberate) |
| `PulseWidget.swift:79` | `.fullScreenCover` (check-in) | `.vaylCover` — see C2 |
| `PulseWidget.swift:66` | `.sheet` | `.vaylSheet` |
| `PulseGraph.swift:137` | `.sheet` (TierGuide) | `.vaylSheet` |
| `ReflectionCard.swift:230` | `.sheet` (pill picker) | `.vaylSheet` |
| `ReflectionBannerView.swift:218` | `.sheet` (pill picker) | `.vaylSheet` |
| `PairingSettingsView.swift:66` | `.sheet` (invite) | `.vaylSheet` |
| `PairingSettingsView.swift:75` | `.sheet` (join) | `.vaylSheet` |
| `SignInView.swift:124` | `.sheet` (legal/Safari) | `.vaylSheet` |

`VaylPresentation.swift` exists and correctly defines both modifiers — adoption is just inconsistent. (The hits in `DesireMapStore`, `DesireRevealStore`, `TierGuideSheet`, `SafariView`, `OnboardingCanvasView` are comments/docstrings, not violations.)

### H2. Contract drift — `.glassCard()` / `.hairline()` do not exist ✓ verified
- `CLAUDE.md` ("Every card / surface") mandates `.glassCard()` + `.hairline(.resting/.active)`. **Neither modifier exists** in the codebase. The real API is **`.themedCard(selected:)`** (`ThemeModifiers.swift:54`), and hairlines are *properties* (`AppGlows.spectrumBorder.hairlineHeight` / `hairlineOpacity`), not a modifier.
- Anyone (you or me) following the contract literally writes code that won't compile. **Fix the contract**, and standardize cards on `.themedCard()`. (This corroborates your existing `ob_contract_gotchas` memory.)

### H3. View calls Services directly (DEBUG path) ✓ verified
- **`Vayl/Features/Play/PlayView.swift:75,77`** — inside `#if DEBUG`, the View does `RealtimeSessionService()` and `try await ProfileService().ensureProfileExists(...)`. Violates "Views never call a Service directly," even in a debug harness.
- **Fix:** move the harness behind a small `SessionDebugStore`. Low urgency (DEBUG-only), but it's the one place the layer boundary leaks.

### H4. Missing empty states on primary data screens (agent-reported)
- `LearnView` (research/findings empty), `PulseFullView` (no entries). Contract requires icon + headline + sub-label on every data screen. `ProgressDashboardView` and `DesireMapView` already do this correctly — match their pattern. Verify the exact `isEmpty` branches before adding.

---

## 🟡 Medium

### M1. `PulseStore` missing `@MainActor` ✓ verified
- `Vayl/Features/Pulse/Store/PulseStore.swift:9-10` is `@Observable final class` with no `@MainActor`. Every other Store has both. It mutates `entries` and persists — add `@MainActor` for consistency and to close a potential race. One-line fix.

### M2. `SyncManager` uses `ObservableObject`/`@Published` (agent-reported)
- `Vayl/Core/Services/SyncManager.swift` is the lone `ObservableObject + @Published + static let shared` holdout. Functionally fine (only Stores call it), but inconsistent with the `@Observable @MainActor` standard. Refactor when convenient.

### M3. Design-token violations in Views — ~200+ raw values (agent-estimated)
Counts are approximate and **line numbers must be confirmed before editing** (agents drift on exact lines). Breakdown:

| Category | Approx | Notes |
|---|---|---|
| Raw colors (`.white/.black.opacity`, `Color(red:…)`) | ~98 | Many in gradient stops |
| Raw fonts (`Font.custom`, `.font(.system)`) | ~28 | Most mechanical to fix |
| Raw spacing/frame literals | ~47 | Some are legit proportional math |
| Raw opacity | ~22 | Bare `.opacity()` on `.white`/`.black` |
| Raw shadow / radius | ~8 | |
| Raw animation literals | ~4 | |

**Top offenders:** `HomeWidgetShell.swift` (~35), `CandleCardFace.swift` (~26), `HolographicShimmer.swift` (~17), `OBDeepCardFace.swift` (~13). 

**Judgment calls:** card-face and shader/effect files (`CandleCardFace`, `HolographicShimmer`, `OBDeepCardFace`, brand assets `VaylAppIcon`/`SplashScreenView`) use raw RGB for visual-effect reasons. These may warrant a *documented exemption* (an "effect palette") rather than forced tokenization. The clear wins are the `Font.custom`/`.font(.system)` swaps and bare `.white/.black.opacity` in plain UI chrome.

### M4. Pattern gaps in feature views (agent-reported, feel-sensitive)
- **Tap-triad** (`scaleEffect` + `sensoryFeedback` + action) missing on ~5 custom tap targets: `HomeLexicon`, `MapCompletionBeatView`, `ConstellationNode`, `PulseGraph`, `SessionPlayerView`. Design-system buttons follow it; feature `.onTapGesture` sites don't. Consider a `Pressable` view modifier to kill the boilerplate.
- **Ambient animations** (~6) use `withAnimation(...repeatForever())` directly instead of `.ambientAnimation()`: `DeckPedestal`, `HomeGateView`, `ConstellationNode`, `PulseGraph`, `SessionAtmosphere`. Most already have a reduce-motion guard, so this is a consistency/structure fix.
- `.drawingGroup()` on `VaylCardFace` ✅ present. Screen backgrounds ✅ compliant.

---

## ⚪ Low — hygiene (triage, don't bulk-delete)

> **Strong caveat:** you're mid-migration. Many "orphans" are almost certainly WIP scaffolding for the redesign, not abandoned code. Treat this as a triage list to check against your roadmap, not a delete list.

- **~40 orphaned files/types** (zero references outside self + previews). Highest-signal cluster: the **Map tab still renders `PairingSettingsView` as a "Temporary P2 test harness"**, which orphans the real `PrismView.swift` (787 lines) and `ConstellationNode.swift`. Resolve the Map tab and those stop being orphans. Other notable orphans: `SettingsView` (not in any tab), an `Effects/` cluster (`GlowUnderline(+View)`, `OrbitSparkBorderView`, `SectionHairline`, `GradBadge`, `FilamentMode`), and several `Cards/` shells (`CardFrontView`, `CategoryTileView`, `PromptCard`, `CardStyle`).
- **`Vayl/AppIconRetreival.swift`** — entire file is commented out. Safe to delete (one-off icon exporter).
- **~55 defined-but-unused design tokens** across `AppColors/AppFonts/AppRadius/AppAnimation`. Note: several are **contract-mandated** (e.g. `AppRadius.micro`, `deckFan`/`deckWeave`) — so "unused" means "not yet consumed," a consumption gap, not dead code. Don't prune the contract surface.
- **1 genuinely risky `try!`** — `Vayl/Design/Components/Cards/ConversationCard.swift:311`, `try! AttributedString(markdown:)` on runtime content. Should be `try?` with plain-text fallback. (Host is currently itself an orphan, so not live — fix before reuse.) All other `fatalError`/`assertionFailure` are standard boot-time fail-fast — fine.
- **2 stale comments** referencing deleted files (`GravLiftView` in `AppSafeArea.swift:106`; `ResearchTicker` in `ConstellationNode.swift:718`). No build impact.
- **31 TODO/FIXME** notes inventoried (see agent output if you want the full list).
- No stale `.pbxproj` references — the project uses filesystem-synchronized groups, so deleted files cleaned up cleanly and new untracked files will compile.

---

## Meta-finding: update the contract (`CLAUDE.md`)

The contract is the source of truth we both code against, so its drift is a first-class bug:

1. **`.glassCard()` / `.hairline()` → don't exist.** Replace with `.themedCard(selected:)` and document hairlines as `AppGlows.spectrumBorder.hairlineHeight/Opacity`. (H2)
2. **Several mandated tokens are unused.** Either wire them or mark them aspirational so "unused token" audits don't keep flagging the contract surface.
3. Consider adding a note that **effect/shader/brand files** are an explicit exemption zone for raw color (with an "effect palette" convention), so the token audit has a clear boundary.

---

## Prioritized remediation plan

**Phase 0 — decisions only (you, ~10 min):**
- Confirm whether `SessionView`/`HomeRouterView` is a protected card session → sets C1 severity.
- Confirm which orphans are WIP vs truly abandoned (Map tab is the big one).

**Phase 1 — safe + mechanical, compile-verifiable, low feel-risk (I can do on a clean branch off `master`, won't touch your redesign diff):**
- C2 + H1 presentation-primitive conversions → `.vaylSheet`/`.vaylCover`.
- M1 `PulseStore` `@MainActor`.
- `Font.custom`/`.font(.system)` → `AppFonts` swaps (the ~28 font violations).
- Bare `.white/.black.opacity` in plain UI chrome → tokens.
- `ConversationCard` `try!` → `try?`.
- Delete `AppIconRetreival.swift`; remove the 2 stale comments.
- Fix the contract (the meta-finding) in `CLAUDE.md`.

**Phase 2 — feel-sensitive, needs your device pass (I draft, you verify feel):**
- C1 session-grammar unification.
- H4 empty states on Learn/Pulse.
- M4 tap-triad + ambient-animation migration.
- Card-face/effect color extraction (or a documented exemption).

**Phase 3 — cleanup against the roadmap:**
- Map-tab resolution → reclaims `PrismView`/`ConstellationNode`.
- Orphan triage + unused-token prune.

---

*Audit produced read-only. Nothing was committed or modified. Design-token line numbers are agent-estimated — re-confirm each before editing. Items marked "✓ verified" were hand-checked against current source.*
