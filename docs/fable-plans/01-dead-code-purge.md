# Plan 01 — Dead-Code Purge (single-pass deletion)

**Goal:** In one pass, delete 51 confirmed-dead Swift files (48 standalone + 3 coordinated card faces), remove the 3 matching `VaylCardFace` switch arms + `VaylCardContent` enum cases, drop the transitively-dead `HomeWidgetShell.swift`, and confirm the legacy card-session retirement (audit C-2) is complete — then prove the whole thing green with one `xcodebuild`. No production behavior changes: every file removed has **zero live references to any symbol it exports** (verified at the symbol level, not just type name).

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

## The cleanest possible one-shot

This is the safest, most mechanical plan in the set. There is **no new code** and no logic change — it is a set of file deletions plus two tiny surgical edits (three switch arms, three enum cases). It is impossible to get the "feel" wrong because nothing visible changes. The only failure mode is a build break, and the whole point of the final `xcodebuild` is to catch that. Delete confidently, then let the compiler be the judge.

Two facts make this a genuine one-shot rather than a staged cleanup:

1. **The app target uses a synchronized (folder-referenced) file group.** Deleting a `.swift` file from disk removes it from the build automatically — **no `.pbxproj` edit is needed.** (This applies to the `Vayl` app target only; `VaylTests` uses a manual PBXGroup, but none of the files here are test files, so it is untouched.)
2. **Everything is git-tracked**, so every delete is recoverable with `git checkout -- <path>`. That is the safety net; the `xcodebuild` at the end is the compiler-proof.

**Verification done for this plan (2026-07-01):** all 51 target files confirmed to exist on disk; every "REF" hit found by a symbol grep across the live tree was inspected and is either (a) a prose comment mentioning a retired symbol, (b) an internal dead↔dead chain where both ends are in the delete set, or (c) the coordinated `VaylCardFace` switch — never a live consumer. Details in each segment.

---

## Context Fable needs

- **What this is:** a repo hygiene pass turning the vetted dead-code list (`docs/audits/2026-06-30-dead-code-delete-list.md`, companion to `…-ios-codebase-audit.md` §1) into a single deletion changeset. §1 of the audit found ~18% dead code (~12.5k LOC); this purge removes ~11.5k LOC of it.
- **Where it sits:** cuts across `Vayl/Features/*` (Home, Progress, Pulse, Learn, Desire Map, Onboarding, Play) and `Vayl/Design/Components/*` (Cards, Effects, Navigation, Progress, Input, Text, Buttons) plus one `Vayl/App/Theme/` file. Nothing in the app's live render path is touched.
- **Current state (verified):** all 51 files present. `HomeRouterView.swift` is **already clean** of the legacy session wiring (audit C-2 is effectively done — see Segment 5). No dangling references to the already-deleted `SessionStore`/`SessionView` exist anywhere in the live tree.
- **Pattern to imitate:** none — there is no new code. Match the surrounding style only for the two edits in `VaylCardContent.swift` / `VaylCardFace.swift` (plain `case` removals inside an existing `enum` / `switch`).
- **Build target:** project `Vayl.xcodeproj`, scheme `Vayl` (the only scheme; targets `Vayl`, `VaylTests`, `VaylUITests`).
- **Recoverability:** all deletes are `git`-reversible; do them as real filesystem removals (`rm` / `git rm`), do not just comment code out.

---

## Files

### Delete — 48 standalone (grouped exactly as the vetted list)

**Home**

| File | LOC | Note |
|---|---|---|
| `Vayl/Features/Home/Views/HomeGateView.swift` | 297 | |
| `Vayl/Features/Home/Components/DesireMapIndicator.swift` | 298 | only ref is a comment (`HomeDashboardView.swift:320`, "retired from the dashboard") |
| `Vayl/Features/Home/Components/ReflectionCard.swift` | 708 | |
| `Vayl/Features/Home/Components/CardChestContainer.swift` | 30 | |
| `Vayl/Features/Home/Models/HomeEventEngine.swift` | 103 | |

**Progress (whole folder)**

| File | LOC | Note |
|---|---|---|
| `Vayl/Features/Progress/ProgressDashboardView.swift` | 207 | chain: `CardStyle ⇄ ProgressDashboardView`, `SectionHeader ← ProgressDashboardView` |

**Pulse (legacy check-in cluster)**

| File | LOC |
|---|---|
| `Vayl/Features/Pulse/PulseWidget.swift` | 31 |
| `Vayl/Features/Pulse/PulseCheckInCover.swift` | 36 |
| `Vayl/Features/Pulse/CheckInShell.swift` | 29 |
| `Vayl/Features/Pulse/DailyCheckInView.swift` | 33 |
| `Vayl/Features/Pulse/PulseSheetView.swift` | 25 |
| `Vayl/Features/Pulse/TierGuideSheet.swift` | 127 |

**Learn / Desire Map / Onboarding**

| File | LOC | Note |
|---|---|---|
| `Vayl/Features/Learn/Views/ConstellationNode.swift` | 772 | pulls `SparkField` with it (both dead) |
| `Vayl/Features/Desire Map/Views/Components/ConstellationField.swift` | 261 | only refs are comments in `AppAnimation.swift`, `DesireConstellationView.swift`, `DesireRevealView.swift` |
| `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift` | 765 | |
| `Vayl/Features/Onboarding/Layout/OnboardingLayout.swift` | 100 | |
| `Vayl/Features/Onboarding/Components/DeckWrapView.swift` | 65 | |

**Play**

| File | LOC |
|---|---|
| `Vayl/Features/Play/Components/ZoomablePanView.swift` | 52 |

**Design / Cards (abandoned shell chain)**

| File | LOC | Note |
|---|---|---|
| `Vayl/Design/Components/Cards/CardFrontView.swift` | 112 | chain: `PremiumCardShell → CardFrontView/PromptCard` |
| `Vayl/Design/Components/Cards/CardStyle.swift` | 50 | chain: `CardStyle ⇄ ProgressDashboardView` |
| `Vayl/Design/Components/Cards/PromptCard.swift` | 34 | |
| `Vayl/Design/Components/Cards/PremiumCardShell.swift` | 221 | |
| `Vayl/Design/Components/Cards/CuriosityFlipCard.swift` | 73 | chain: `CuriosityFlipCard → CuriosityCardBack → MazePatternView → TileOrbitView` |
| `Vayl/Design/Components/Cards/CuriosityCardBack.swift` | 160 | |
| `Vayl/Design/Components/Cards/CardRevealPillButton.swift` | 105 | |
| `Vayl/Design/Components/Cards/CategoryTileView.swift` | 90 | |

**Design / Effects**

| File | LOC | Note |
|---|---|---|
| `Vayl/Design/Components/Effects/FilamentMode.swift` | 876 | |
| `Vayl/Design/Components/Effects/SparkField.swift` | 628 | only ref is `ConstellationNode.swift` (also deleted) |
| `Vayl/Design/Components/Effects/AuroraGlowField.swift` | 313 | |
| `Vayl/Design/Components/Effects/TileOrbitView.swift` | 353 | in the CuriosityFlipCard chain |
| `Vayl/Design/Components/Effects/MazePatternView.swift` | 185 | in the CuriosityFlipCard chain |
| `Vayl/Design/Components/Effects/OrbitSparkBorderView.swift` | 58 | |
| `Vayl/Design/Components/Effects/GlowUnderline.swift` | 72 | |
| `Vayl/Design/Components/Effects/GlowUnderlineView.swift` | 59 | |
| `Vayl/Design/Components/Effects/GradBadge.swift` | 44 | |
| `Vayl/Design/Components/Effects/SectionHairline.swift` | 35 | |
| `Vayl/Design/Components/Effects/SectionHeader.swift` | 17 | chain: `SectionHeader ← ProgressDashboardView` |

**Design / Navigation, Progress, Input, Text, Buttons, Theme**

| File | LOC | Note |
|---|---|---|
| `Vayl/Design/Components/Navigation/NavArrow.swift` | 296 | chain: `OnboardingNavBar → NavArrow` |
| `Vayl/Design/Components/Navigation/OnboardingNavBar.swift` | 117 | |
| `Vayl/Design/Components/Progress/OrbitIndicator.swift` | 695 | |
| `Vayl/Design/Components/Progress/SpectrumBar.swift` | 18 | |
| `Vayl/Design/Components/Input/ToggleRow.swift` | 28 | |
| `Vayl/Design/Components/Text/KeywordHighlightText.swift` | 66 | |
| `Vayl/Design/Components/Buttons/CriticalButton.swift` | 50 | |
| `Vayl/Design/Components/Buttons/SafeWordButton.swift` | 59 | |
| `Vayl/App/Theme/AppGrid.swift` | 119 | |

### Delete — transitively dead (Segment 3)

| File | LOC | Why |
|---|---|---|
| `Vayl/Features/Home/Components/HomeWidgetShell.swift` | 702 | only consumer is `PrismView` (itself dead). Mutual dead↔dead chain — must go together with the PrismView decision (Open Decisions). |

### Delete + coordinated edit — 3 card faces (Segment 2)

| Delete file | Also remove switch arm in `VaylCardFace.swift` | Also remove enum case in `VaylCardContent.swift` |
|---|---|---|
| `Vayl/Design/Components/Cards/CardFaces/SlotMachineCardFace.swift` | `case .slotMachine:` (:158) | `case slotMachine` (:45) |
| `Vayl/Design/Components/Cards/CardFaces/CompassOptionCardFace.swift` | `case .compassOption(let label):` (:196) | `case compassOption(label: String)` (:66) |
| `Vayl/Design/Components/Cards/CardFaces/CompassSliderCardFace.swift` | `case .compassSlider(let value, let dragging):` (:202) | `case compassSlider(value: Double, dragging: Bool)` (:72) |

> ⚠️ **Real paths differ from the source list.** The vetted list wrote `Design/Components/Cards/CardFaces/…` and `Design/Components/Cards/CardFaces/VaylCardFace.swift`. On disk (verified 2026-07-01): the three face files ARE under `Vayl/Design/Components/Cards/CardFaces/`, but the **switch/enum files are one level up** at `Vayl/Design/Components/Cards/VaylCardFace.swift` and `Vayl/Design/Components/Cards/VaylCardContent.swift` (NOT inside `CardFaces/`). The line numbers below are re-verified against those actual files.

### Modify

| File | Lines | Change |
|---|---|---|
| `Vayl/Design/Components/Cards/VaylCardFace.swift` | 158–162, 196–201, 202–208 | remove the three `.slotMachine` / `.compassOption` / `.compassSlider` switch arms |
| `Vayl/Design/Components/Cards/VaylCardContent.swift` | 44–45, 64–66, 68–72 | remove the three matching enum cases (+ their doc comments) |

### Do NOT touch (guardrail — all verified present, all live or intentionally-kept)

| File | Why it stays |
|---|---|
| `Vayl/Features/Map/Components/FlavorVisuals.swift` | LIVE — `FlavorChip`/`FlavorPortrait`/`DrawnTagChip` used by `MeCardSheet`/`MeCardCompact`. (Partial-dead sigils inside may be pruned later; keep the file.) |
| `Vayl/Features/Onboarding/Phases/CredentialEditorSheet.swift` | LIVE — exports `CredentialEditorOverlay`, presented by the OB canvas (`OnboardingCanvasView:194,381`). |
| `Vayl/Core/Services/PushService.swift` | Unbuilt feature (T1 notifications), NOT dead. Keep. |
| `Vayl/Core/Debug/DiagnosticOverlay.swift`, `Vayl/Core/Debug/DragDebugView.swift`, `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` | Dev tools. Keep. |
| `Vayl/Design/Brand/VaylAppIcon.swift`, `Vayl/AppIconRetreival.swift` | Icon-export dev tooling. Keep. |
| `Vayl/Core/Models/SessionRecord.swift` | Open-Lightly-era `@Model`, likely dead but NOT verified clean against `SessionSyncService` — out of scope here. Do NOT delete in this pass. |

---

## Build steps (segments)

All segments are built in one pass. Ordered so no intermediate state has a dangling reference — but since the final proof is one build, order matters only for your own sanity. Prefer `git rm <path>` (or Finder/`rm`) for every deletion.

### Segment 1 — delete the 48 standalone files (and internal chains together)

**One thing it does:** removes all 48 zero-reference files in one batch.

The dead↔dead chains are all fully inside this set, so batch-deleting the whole 48 keeps every intermediate reference resolved:

- `CardStyle ⇄ ProgressDashboardView` — both deleted here.
- `PremiumCardShell → CardFrontView / PromptCard` — all three deleted here.
- `CuriosityFlipCard → CuriosityCardBack → MazePatternView → TileOrbitView` — all four deleted here.
- `OnboardingNavBar → NavArrow` — both deleted here.
- `SectionHeader ← ProgressDashboardView` — both deleted here.
- `ConstellationNode → SparkField` — both deleted here.

Delete every path in the **"Delete — 48 standalone"** tables above. Example (run from repo root; do it in one commit so a chain never half-exists):

```bash
git rm \
  "Vayl/Features/Home/Views/HomeGateView.swift" \
  "Vayl/Features/Home/Components/DesireMapIndicator.swift" \
  "Vayl/Features/Home/Components/ReflectionCard.swift" \
  "Vayl/Features/Home/Components/CardChestContainer.swift" \
  "Vayl/Features/Home/Models/HomeEventEngine.swift" \
  "Vayl/Features/Progress/ProgressDashboardView.swift" \
  "Vayl/Features/Pulse/PulseWidget.swift" \
  "Vayl/Features/Pulse/PulseCheckInCover.swift" \
  "Vayl/Features/Pulse/CheckInShell.swift" \
  "Vayl/Features/Pulse/DailyCheckInView.swift" \
  "Vayl/Features/Pulse/PulseSheetView.swift" \
  "Vayl/Features/Pulse/TierGuideSheet.swift" \
  "Vayl/Features/Learn/Views/ConstellationNode.swift" \
  "Vayl/Features/Desire Map/Views/Components/ConstellationField.swift" \
  "Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift" \
  "Vayl/Features/Onboarding/Layout/OnboardingLayout.swift" \
  "Vayl/Features/Onboarding/Components/DeckWrapView.swift" \
  "Vayl/Features/Play/Components/ZoomablePanView.swift" \
  "Vayl/Design/Components/Cards/CardFrontView.swift" \
  "Vayl/Design/Components/Cards/CardStyle.swift" \
  "Vayl/Design/Components/Cards/PromptCard.swift" \
  "Vayl/Design/Components/Cards/PremiumCardShell.swift" \
  "Vayl/Design/Components/Cards/CuriosityFlipCard.swift" \
  "Vayl/Design/Components/Cards/CuriosityCardBack.swift" \
  "Vayl/Design/Components/Cards/CardRevealPillButton.swift" \
  "Vayl/Design/Components/Cards/CategoryTileView.swift" \
  "Vayl/Design/Components/Effects/FilamentMode.swift" \
  "Vayl/Design/Components/Effects/SparkField.swift" \
  "Vayl/Design/Components/Effects/AuroraGlowField.swift" \
  "Vayl/Design/Components/Effects/TileOrbitView.swift" \
  "Vayl/Design/Components/Effects/MazePatternView.swift" \
  "Vayl/Design/Components/Effects/OrbitSparkBorderView.swift" \
  "Vayl/Design/Components/Effects/GlowUnderline.swift" \
  "Vayl/Design/Components/Effects/GlowUnderlineView.swift" \
  "Vayl/Design/Components/Effects/GradBadge.swift" \
  "Vayl/Design/Components/Effects/SectionHairline.swift" \
  "Vayl/Design/Components/Effects/SectionHeader.swift" \
  "Vayl/Design/Components/Navigation/NavArrow.swift" \
  "Vayl/Design/Components/Navigation/OnboardingNavBar.swift" \
  "Vayl/Design/Components/Progress/OrbitIndicator.swift" \
  "Vayl/Design/Components/Progress/SpectrumBar.swift" \
  "Vayl/Design/Components/Input/ToggleRow.swift" \
  "Vayl/Design/Components/Text/KeywordHighlightText.swift" \
  "Vayl/Design/Components/Buttons/CriticalButton.swift" \
  "Vayl/Design/Components/Buttons/SafeWordButton.swift" \
  "Vayl/App/Theme/AppGrid.swift"
```

> The synchronized file group means no `.pbxproj` edit is required — the removed files leave the build automatically. If any path above errors as "did not match any files," it was already gone; note the drift and continue.

**Done:** all 48 paths are absent from disk (and staged for deletion in git).

### Segment 2 — the 3 coordinated card-face removals

**One thing it does:** removes each runtime-dead card face together with the two `VaylCardFace`/`VaylCardContent` symbols that name it, so the build stays resolved.

Each face needs **three** edits done together (delete file + switch arm + enum case). The `VaylCardFace` `contentFace(for:)` switch ends in `default: EmptyView()` (line 234), so it stays exhaustive after any of these removals — but remove the arms anyway so the dead face files can go.

**2a. Delete the three face files:**

```bash
git rm \
  "Vayl/Design/Components/Cards/CardFaces/SlotMachineCardFace.swift" \
  "Vayl/Design/Components/Cards/CardFaces/CompassOptionCardFace.swift" \
  "Vayl/Design/Components/Cards/CardFaces/CompassSliderCardFace.swift"
```

**2b. In `Vayl/Design/Components/Cards/VaylCardFace.swift`, delete these three switch arms** (anchor on the symbol, not the line number — earlier removals shift later lines):

Remove (currently :158–162):
```swift
        case .slotMachine:
            SlotMachineCardFace(
                cardWidth:  size.width,
                cardHeight: size.height
            )
```

Remove (currently :196–201):
```swift
        case .compassOption(let label):
            CompassOptionCardFace(
                cardWidth:  size.width,
                cardHeight: size.height,
                label:      label
            )
```

Remove (currently :202–208):
```swift
        case .compassSlider(let value, let dragging):
            CompassSliderCardFace(
                cardWidth:  size.width,
                cardHeight: size.height,
                value:      value,
                dragging:   dragging
            )
```

**2c. In `Vayl/Design/Components/Cards/VaylCardContent.swift`, delete the three enum cases (with their doc comments):**

Remove (currently :44–45):
```swift
    /// Slot machine symbol face — used during GenderPhase.
    case slotMachine
```

Remove (currently :64–66):
```swift
    /// CompassPhase Q1/Q2 answer card — one option label per card.
    /// Revealed by the flip cascade after the 2×2 grid settles.
    case compassOption(label: String)
```

Remove (currently :68–72):
```swift
    /// CompassPhase Q3 register card — felt-state slider on the card face.
    /// `value` 0.0 ("I want to feel safer") → 1.0 ("I want to feel more alive").
    /// `dragging` scales the thumb while the user is actively dragging.
    /// The drag gesture itself is an overlay owned by the phase — this only draws.
    case compassSlider(value: Double, dragging: Bool)
```

**Verified:** these three cases are referenced ONLY by the `VaylCardFace` switch you are editing — no live data ever builds them, and no other file matches the case names (2026-07-01 grep). Do **not** touch the shell, `.drawingGroup()`, or `FaceGestures`.

**Done:** the three face files are gone; `VaylCardFace.swift` and `VaylCardContent.swift` no longer name them; the switch still compiles (exhaustive via its `default`).

### Segment 3 — delete the transitively-dead `HomeWidgetShell.swift`

**One thing it does:** removes the 702-LOC shell whose only consumer, `PrismView`, is itself dead.

`HomeWidgetShell.swift` ↔ `PrismView.swift` form a mutual dead↔dead chain (each references only the other, plus dead symbols). `HomeWidgetShell` also carries 33 raw-opacity literals that were inflating apparent token debt.

- If the **PrismView decision** (Open Decisions below) is **DELETE**, remove both together — they resolve each other's references.
- If the decision is **KEEP PrismView** (the default), then `HomeWidgetShell` cannot be deleted on its own without leaving `PrismView` referencing a missing type. **In that case, keep `HomeWidgetShell.swift` too** (it stays dead-but-compiling as PrismView's dependency). Do not delete one without the other.

```bash
# ONLY if PrismView is also being deleted (see Open Decisions):
git rm "Vayl/Features/Home/Components/HomeWidgetShell.swift" \
       "Vayl/Features/Map/PrismView.swift"
```

**Done:** either both `HomeWidgetShell.swift` + `PrismView.swift` are gone, or both remain (default) — never a half-chain.

### Segment 4 — confirm the legacy card-session retirement (audit C-2) is already complete

**One thing it does:** verifies — and does NOT re-do — the C-2 cleanup, because the repo is already in the finished state.

**Verified on 2026-07-01:**
- `Vayl/Features/Sessions/SessionStore.swift` and `SessionView.swift` are **already deleted** (git status shows them `D`).
- `Vayl/Features/Home/Views/HomeRouterView.swift` is **already clean**: it has **no** `@State … activeSession`, **no** `.sheet(item: $activeSession)` block, and **no** `.startSession` case in `handleCardAction`. `handleCardAction` today handles only `case .navigateToPlay: appState.selectedTab = .play` with a `default: break`. There are **no dangling references** to `SessionStore`/`SessionView` anywhere in the live tree (the only `SessionStore`/`SessionView` string hits are prose comments in `SessionRecord.swift` / `CoupleSessionStore.swift`, and matches on the **different, live** class `CoupleSessionStore`).

**So there is nothing to edit here.** The brief's expected surgery (remove `activeSession`, the `.sheet(item:)`, the `.startSession` case) was already applied before this pass. **KEEP** all of:
- `.navigateToPlay` in `handleCardAction` (live).
- `CardCarousel`'s `.startSession` emission (`CardCarousel.swift:22` enum case, emitted at :537 and :640) — still consumed by the live `PlayHeroView.swift:24` (`if case .startSession = action …`). Do not remove.
- `SessionRecordPayload` + `SessionSyncService` (`Vayl/Core/Services/SessionSyncService.swift`, used by `SyncManager.swift` and `CoupleSessionStore.swift`) — live.

**Done:** confirmed clean; no code change. If (and only if) a residual `activeSession`/`SessionStore` reference somehow surfaces during the build, remove exactly that reference and note the drift — but the verified state is that none exists.

### Segment 5 — prove green

**One thing it does:** compiles the whole app with all deletions applied, which is the compiler-proof that nothing live depended on the removed set.

Run the exact command from the delete list (scratch `-derivedDataPath` so it does not race an open Xcode cache):

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/vayl-dd -quiet build CODE_SIGNING_ALLOWED=NO
```

**Done:** `** BUILD SUCCEEDED **`. Green = every deletion was safe.

---

## Definition of Done (build-green)

- [ ] All 48 standalone files (Home / Progress / Pulse / Learn+Desire+OB / Play / Design-Cards / Design-Effects / Design-Nav+Progress+Input+Text+Buttons+Theme) are deleted from disk.
- [ ] The 3 card-face files are deleted AND their 3 switch arms (`VaylCardFace.swift`) AND 3 enum cases (`VaylCardContent.swift`) are removed; the `contentFace(for:)` switch still compiles (exhaustive via `default`).
- [ ] `HomeWidgetShell.swift` handled per the PrismView decision (both deleted, or both kept — never a half-chain).
- [ ] `HomeRouterView.swift` confirmed clean (no `activeSession`, no session `.sheet`, no `.startSession` case); `.navigateToPlay`, `CardCarousel.startSession`, `SessionRecordPayload`, `SessionSyncService` all still present.
- [ ] No file in the "Do NOT touch" guardrail was deleted or edited.
- [ ] `xcodebuild … build` → `** BUILD SUCCEEDED **`.
- [ ] No `.pbxproj` edit was needed for the app target (synchronized group).

---

## Bryan verifies on device

Deletions can't be "felt," but a quick pass confirms nothing live vanished:

- [ ] Launch the app; walk the four tabs (Home, Play/Cards, Map, Learn) + Settings — nothing missing or blank.
- [ ] Home dashboard renders (hero card, Pulse rail, Getting Started) — the retired `DesireMapIndicator`/`ReflectionCard`/`HomeGateView` were already off-screen; confirm no regression.
- [ ] Open a Card Session from Play — the live `CoupleSessionStore` flow (Airlock → Player → Close) still works (this is the KEPT session system, distinct from the retired one).
- [ ] Onboarding still deals cards and runs its phases (the OB card faces you kept — Typewriter, RadioTuner, Compass, Candle, Snapshot, Mode, Context — are untouched; only the never-built Slot / CompassOption / CompassSlider faces were removed).
- [ ] Desire Map reveal + rater still present and animate.

---

## Constraints / do-not-touch

- **No new code, no logic changes.** The only edits are three switch-arm removals and three enum-case removals; everything else is a file delete.
- **Do not edit** the `VaylCardFace` shell, `.drawingGroup()`, `FaceGestures`, `FaceAtmosphere`, or any face other than the three named.
- **Do not delete** any file in the guardrail table (FlavorVisuals, CredentialEditorSheet, PushService, the three debug tools, VaylAppIcon, AppIconRetreival, SessionRecord).
- **Do not** delete `HomeWidgetShell.swift` unless `PrismView.swift` is deleted in the same change.
- **Do not** touch `CardCarousel`'s `.startSession` case/emissions or `PlayHeroView` — the live Play flow uses them.
- **Do not** hand-edit `Vayl.xcodeproj/project.pbxproj` for the app target — the synchronized group handles removals. (`VaylTests` is manual, but no test file is in scope, so it needs no change.)
- If any path is already missing or already edited, **note the drift and continue** — do not re-create anything to match the plan.

---

## Open decisions

1. **`PrismView.swift` (833) + `HomeWidgetShell.swift` (702) — delete or keep?**
   **Recommended default: KEEP both.** They are compiler-safe to delete, but Bryan flagged PrismView "keep to mine visually," and `HomeWidgetShell` is only reachable as PrismView's dependency — so they stand or fall together. Default action: leave both in place (dead-but-compiling). Proceed on KEEP unless Bryan says otherwise; if he says delete, remove **both** in Segment 3.

2. **`RotaryDial.swift` (166) — delete or keep?**
   **Recommended default: KEEP.** Filetracker note: "archived pattern, kept for reference." Compiler-safe to delete but harmless to keep. Default action: leave it. (It has zero live references, so deleting it later is a one-liner whenever Bryan wants.)

Both defaults keep the purge maximally safe: the 48 + 3 faces + the confirmed-clean C-2 state ship regardless, and the two reference-keep files are a separate, reversible call.
