# Desire Map UI — Implementation Plan

**Date:** 2026-06-26
**Audience:** an implementing agent (Claude Sonnet, high effort). Follow this top to bottom. Build in the numbered segments. Do not free-style past a segment's scope.
**Visual source of truth:** `docs/prototypes/desire-map-flow-family.html` (the ten-screen storyboard, open it and match it). Felt-timing references: `docs/prototypes/desire-reveal-constellation.html` (reveal + star + sparkle) and `docs/prototypes/desire-rater-flow.html` (rater entrance, depth-push, star-rise, charted finish).
**Architecture:** Vayl 4-layer (View → Store → Service → Model). Views never call Services. Stores are `@Observable @MainActor`. Read `CLAUDE.md` first; every rule there is binding.

---

## 0. The ten screens and where each is built

| # | Screen | Where it lives | Phase |
|---|---|---|---|
| 1 | Start (the invitation) | `DesireMapView` (rater cover) | 2 |
| 2 | Rate (4-point + sky fills) | `DesireMapView` | 2 |
| 3 | Charted (finish beat) | `DesireMapView` → transition | 2 |
| 4 | Wait (first finisher mirror) | `DesireMapView` | 2 |
| 5 | Ready (re-entry + reveal bar) | `DesireMapView` | 2 |
| 6 | Reveal (free star) | `DesireRevealView` (reveal cover) | 1 |
| 7 | Star detail (sheet) | `DesireRevealView` host | 1 |
| 8 | The ask (paywall) | `DesireRevealView` host | 1 |
| 9 | Full map (list) = the Vault view | shared list view, reused in `VaultDesireSection` | 1 |
| 10 | Unlocked (your sky) | `DesireRevealView` | 1 |

**Build order:** Phase 0 (shared primitives) → **Phase 1 (the reveal, screens 6–10 — this is the app's primary paywall, do it first)** → Phase 2 (the rater reskin, screens 1–5) → Phase 3 (wiring, branch, Vault reuse, edges).

---

## 1. What ALREADY EXISTS — reuse, do not rebuild

Verified in the codebase. Touch only where this plan says to.

**Data layer (do NOT modify):**
- `DesireRatingValue` (`Core/Models/Enums/AppDesireEnums.swift`): `case excitedAboutIt, openToIt, probablyNot, notForMe`. `.displayName` exists. All four sync; `notForMe` is obscured server-side, never withheld at upload, partner-vs-partner privacy is RLS-enforced.
- `DesireMatchType` (same file): `case mutual, adjacent`. `.displayName` exists.
- `DesireMatch` (@Model, `Core/Models/DesireMatch.swift`): `coupleId, itemId, computedAt, matchType, isFreeReveal, bridgeCardId`.
- `DesireMapEntry` (@Model, `Core/Models/DesireRating.swift`): `userId, itemId, rating, completedAt`.
- `DesireMapStatus` (@Model, same file): `partnerAComplete, partnerBComplete, …`, computed `bothComplete`, `waitingForPartner`.
- `DesireItem` (`Core/Models/DesireItem.swift`): `id, name, description, category, sensitivity, sortOrder, tracks, answers: [String:[String]]`. Answers are ordered `[excitedAboutIt, openToIt, probablyNot, notForMe]`. `func answers(for track:)`. 19 items, tracks `"curious"` / `"established"`.
- `DesireSyncService` (`Core/Services/DesireSyncService.swift`): `fetchMatches(coupleId:) -> [DesireMatchRow]`, `fetchStatus(coupleId:) -> DesireMapStatusRow?`, `fetchRevealProgress(coupleId:) -> RevealProgressRow?`, `markRevealSeen(coupleId:, full:)`, `syncRatings(_:)`, `computeMatches()`. `DesireMatchRow`: `id, desireItemId, alignmentLevel ("mutual"|"adjacent"), isFreeReveal, bridgeCardId, var matchType: DesireMatchType?`. This is the **alignment-only read path — it never carries raw partner values.**

**Stores / services (reuse):**
- `DesireMapStore` (`Features/Desire Map/Store/DesireMapStore.swift`): `items: [DesireItem]`, `ratings: [String: DesireRatingValue]`, `track`, `totalCount`, `ratedCount`, `isComplete`, `load()`, `rate(itemId:rating:)`. Sets `UserProfile.hasCompletedDesireMap` and triggers sync on completion. **Reuse as-is for the rater data**; only the View reskins. You will add a small amount of *presentation* state (below), not rating logic.
- `DesireRevealStore` (`Features/Desire Map/Store/DesireRevealStore.swift`): `phase (.loading/.ready/.empty/.failed)`, `matches: [RevealMatch]`, `unlockedMatches`, `lockedMatches`, `lockedCount`, `isFullyUnlocked` (`entitlements.isCore`), `load()`, `unlockAll()`. `RevealMatch`: `id, itemName, alignment: DesireMatchType?, isLocked, bridgeCardId, var celebration`. **Extend (do not rewrite).**
- `EntitlementStore` (`Features/Monetization/Store/EntitlementStore.swift`): `isCore`, `corePriceText`, `purchase() async -> Bool`, `restore() async -> Bool`. Injected via `@Environment(EntitlementStore.self)`.
- `VaultStore` (`Features/Map/Vault/VaultStore.swift`): `@Observable`, segment `.desire/.agreements/.log`, `desire: DesireSummary`, `align: [MapStore.AlignItem]`, `lockedAlignCount`, `loadDesire(appState:context:) async`. Data is REAL, the desire-list visuals are STUBBED — **screen 9's list is built here and reused by the reveal.**
- `AppState` (`Core/Services/AppState.swift`): `coupleId`, `displayName`, `selectedTab`. `partnerName` and `partnerMapComplete` live in `HomeStore` (derived from `DesireMapStatusRow.bothComplete`).

**Components (do NOT modify):**
- `PaywallSheet(entry: .reveal, onUnlocked:)` — final copy, restore + legal wired, custom bottom sheet (`vaylSheetChrome`). Host it; never edit it.
- `VaylButton(label:style:size:isLoading:isDisabled:action:)` — styles `.primary/.secondary/.ghost/.gold`; sizes `.fullWidth/.compact/.pill(width:)`.
- `SelectablePill(label:isSelected:intensity:height:fontSize:showFlame:action:)` — `Intensity.dim/.warm/.alive`.
- `GlowOrb(color:size:)`, `SpectrumHairline()`, `LivingText(text:font:animated:)`, `SpectrumBulletRow(text:phaseOffset:font:)`, `FlameAura(intensity:)`, `OrbitSparkBorderView(size:cornerRadius:borderWidth:colorScheme:)`.
- Modifiers: `.spectrumBorderGlow(intensity:)`, `.vaylGlassCard(accent:radius:)`, `.themedCard(selected:)`, `.ambientAnimation(_:value:)`, `.screenshotProtected()`, `.topClearance(_:padding:)`, `.bottomClearance(_:includesTabBar:)`, `.bottomContentInset(_:)`, `.stickyBottomCTA(cta:)`.
- Presentation: `.vaylCover(isPresented:confirmOnExit:onExit:content:)` and `.vaylSheet(isPresented:heightFraction:screenHeight:showsGrabber:content:)` in `Design/Components/Navigation/VaylPresentation.swift`. The guarded-dismiss action is `@Environment(\.vaylDismiss)`.
- The custom-sheet-inside-a-cover host pattern: copy `CredentialEditorOverlay` in `Features/Onboarding/Phases/CredentialEditorSheet.swift` (`ZStack(alignment: .bottom)` = scrim + sheet pinned bottom, `.transition(.move(edge: .bottom))`).
- The node/glow recipe to mirror: `Features/Learn/Views/ConstellationNode.swift` (core `#0A0814`, radial inner highlight, colored stroke, ambient halo, label dual-shadow, burst rings). **Reproduce the warm-desire version, do not import the Learn one.**

---

## 2. PHASE 0 — Shared foundations

Build these first; screens 2, 3, 6, 9, 10 depend on them.

### 0a. New animation tokens — `App/Theme/AppAnimation.swift`

Add a `// MARK: — Desire Map` block. No raw durations may appear in the Desire Map views; they all reference these. Recommended starting values (Bryan feels final on device — these came from the mockups):

```
// Reveal
desireRevealBloom      = 0.80s  (spectrum-bloom entrance wash; .easeOut-ish)
desireStarIgnite       = 0.72s  (free star glow blooms in)
desireLineDraw         = 0.76s  (confident constellation lines draw on at the reveal)
desireSheetRise        = 0.50s  (detail / full-map / paywall sheet rise)
// Star sparkle (one-shot keyframe, see DesireStarView)
desireSparkleDuration  = 0.95s
desireSparkleFreeRate  = 3.5s   (free/active star cadence; randomize 0.55–1.6×)
desireSparkleLockedRate= 7.0s   (locked/gentle cadence)
// Rater
desireDepthExit        = 0.20s  (question recedes: scale .93 + translateY 7 + fade)
desireDepthEnter       = 0.34s  (next question emerges: scale 1.07 → 1 + fade)
desireStarRise         = 0.56s  (answer star rises into the sky; sync with depthExit)
// Finish beat
desireFinishFade       = 0.35s  (last question fades out)
desireFinishFlair      = 0.80s  (last star rises with extra ignite + sparkle)
desireChartedFadeIn    = 0.60s  ("Your map is charted" + hesitant lines fade in)
desireChartedHold      = 2.0s   (hold before auto-advance; tap-to-skip allowed)
desireHesitantSketch   = 4.2s   (hesitant line loop; one pass for the finish)
```

Provide each with the `.reduceMotionSafe` story (reactive ones fall back to `.easeOut(duration: 0.15)`; ambient ones disable entirely). Match the file's existing comment discipline.

### 0b. New shape — `SparkleStar` (create file `Design/Components/Effects/SparkleStar.swift`)

No sparkle Shape exists; create one. A 4-point pinched star (matches the mockup's `clip-path: polygon(50% 0, 53% 47, 100% 50, 53% 53, 50% 100, 47% 53, 0 50, 47% 47)`):

```swift
struct SparkleStar: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: rect.minX + fx*w, y: rect.minY + fy*h) }
        var path = Path()
        path.move(to: p(0.50, 0.00))
        path.addLine(to: p(0.53, 0.47)); path.addLine(to: p(1.00, 0.50)); path.addLine(to: p(0.53, 0.53))
        path.addLine(to: p(0.50, 1.00)); path.addLine(to: p(0.47, 0.53)); path.addLine(to: p(0.00, 0.50)); path.addLine(to: p(0.47, 0.47))
        path.closeSubpath()
        return path
    }
}
```

### 0c. New component — `DesireStarView` (create `Features/Desire Map/Views/Components/DesireStarView.swift`)

ONE warm star. The reusable atom for the rater sky and the reveal constellation. Composition (all proportional to a `size` param, mirror `ConstellationNode.swift` but warm and with the sparkle):

- **halo** — `Circle` radial gradient `magenta@0.16 → purple@0.08 → clear`, `.blur(17)`, big.
- **glow** — `Circle` radial `white@0.85 → magenta@0.42 → purple@0.13 → clear`, `.blur(5)`.
- **core** — small white `Circle` with a layered warm glow via `.shadow` stack: white(r3) + magenta(r7, ~0.82) + purple(r15, ~0.42). (This is the warm version of `AppGlows.spectrumBorder`; do NOT use cyan.)
- **resting cross** — two thin `Rectangle`s (h + v) filled with a white linear gradient that fades at both ends, opacity ~0.38 when lit / ~0.20 when dim. This is the star's permanent character.
- **sparkle overlay** — a `SparkleStar().fill(white radial)` driven by `.keyframeAnimator(initialValue:trigger:)` (parallel `CubicKeyframe` tracks: scale 0→1→0.55, opacity 0→1→0, slight rotation, total `desireSparkleDuration`). A `.task` sleeps a randomized interval (`desireSparkleFreeRate` or `…LockedRate`, ±wide) then bumps the trigger `Int`. The free/active star sparkles often (attractor); locked ones rarely.

Params: `size` (one scale that derives halo/glow/core/cross/sparkle sizes), `state: .dim | .lit`, `label: String?`, `cadence: .free | .locked`, `colorway` (default warm). Reduce Motion: skip the sparkle `.task` entirely; keep the static cross + glow. **Never wrap this in `.drawingGroup()`** — the sparkle keyframe must re-render only its own layer.

### 0d. New component — `ConstellationField` (create `Features/Desire Map/Views/Components/ConstellationField.swift`)

Lays out a set of `DesireStarView`s at deterministic positions and draws lines. Inputs: `nodes: [(id, point, size, state, label)]`, `lineMode: .hidden | .hesitant | .confident`.
- **Layout:** positions are a pure function of index/count (a fixed scatter / gentle radial). For 1 node → single hero star, no web (graceful). For many → spread without crowding. (This solves the sparse/crowded edges.)
- **Lines:** a `Canvas` (or `Path`s) between proximate nodes.
  - `.hesitant` — thin, white, opacity ~0.18, an animation that draws partway, pulls back, fades, loops (`desireHesitantSketch`). It never fully connects. (Finish beat; honesty — connections aren't confirmed until the reveal.)
  - `.confident` — opacity ~0.34, draws on once (`desireLineDraw`) and holds. (The unlocked reveal.)
- Reduce Motion: lines hold static (hesitant = faint partial, confident = full).

---

## 3. PHASE 1 — THE REVEAL (screens 6–10) — the priority

Restructure `DesireRevealView` + extend `DesireRevealStore` + repoint `HomeRouterView`. The whole reveal is **one `.vaylCover`**; the detail / full-map / paywall are custom bottom sheets hosted **inside** it over a scrim (mirror `CredentialEditorOverlay`). Unlock happens in place.

### 1a. `DesireRevealStore` — add interaction state (keep `load()` / `unlockAll()`)

Add: `selectedMatch: RevealMatch?` (detail sheet), `showFullMap: Bool`, `showPaywall: Bool`. Methods: `selectStar(_ match)` (free → set `selectedMatch`; locked → `showPaywall = true`), `openFullMap()`, `dismissSheets()`, `closePaywall()`.

**Seen-stamping (RECONCILE, do not duplicate):** `load()` ALREADY stamps a single `markRevealSeen(coupleId:, full: entitlements.isCore)` (~line 92). **Replace** that one line with two distinct stamps: always stamp **free** (`full: false`) when the reveal resolves to `.ready`, and additionally stamp **full** (`full: true`) on `unlockAll()` success. Adding these alongside the existing line double-wires. The two-stamp model also closes a latent edge: an already-Core couple opening the reveal currently stamps only `full`, leaving `free_reveal_seen_at` null, so `HomeStore.revealDone` (= `hasSeenFree`) never trips and the "See what you share" step never completes. (Service calls stay in the Store, never the View.)

### 1b. `DesireRevealView` — the cover content

`ZStack`:
1. `AppColors.void.ignoresSafeArea()`
2. `OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()`
3. content: top bar (`X` left → `\.vaylDismiss`; `Full map` pill right → `store.openFullMap()`), overline `"Where you meet"`, `ConstellationField`, caption.
4. sheet host layer (scrim + the active sheet pinned bottom), shown when `selectedMatch != nil || showFullMap || showPaywall`.

Screen mapping:
- **6 Reveal:** `phase == .ready`, free star `.lit` (ignite on appear via `desireStarIgnite`, then sparkles), other matches present as `.dim` locked stars (names blurred). Caption `"You both marked this"`, hint `"tap to read · or open the full map"`. Count templated to `store.lockedCount`.
- **7 Star detail:** tap a free/unlocked star → `DesireStarDetailSheet` over a dimmed constellation. Shows category, name, a `mutual`/`adjacent` badge (mutual = magenta "You both want this"; adjacent = purple "Worth exploring"), the `match.celebration` meaning, a `Talk about this →` button (stub action) and `Explore in Learn →`. **This same card body is reused by the full-map list (1d) — extract it as `DesireMatchDetail`.**
- **8 The ask:** tap a locked star (or the list's unlock CTA) → `PaywallSheet(entry: .reveal, onUnlocked: { store.unlockAll() })` hosted the same way over the scrim. On unlock: sheet falls, `store.load()` re-resolves to Core, all stars light **in place** (no navigation).
- **10 Unlocked:** Core couple → whole sky lit, names resolve, `ConstellationField(lineMode: .confident)`, caption `"N desires you share"`, `"tap any star to talk about it"`.

Branches: already-Core on open → go straight to screen 10 (celebration, no paywall). `phase == .empty` → empty state. 1 match / 0 locked → free star + gentle close, no gap, no paywall.

### 1c. The sheet host (inside the cover)

A `ZStack(alignment: .bottom)` overlay: `Color.black.opacity(0.55)` scrim (tap → `store.dismissSheets()` / `closePaywall()`) + the active sheet (`DesireStarDetailSheet`, `DesireMapListSheet`, or `PaywallSheet`) with `.transition(.move(edge: .bottom))`, animated `desireSheetRise`. **Do NOT use `.vaylSheet` or `.sheet`** for these (double-chrome + width bug). PaywallSheet is content-height already; just pin it bottom (its preview does exactly this).

### 1d. Screen 9 — the matches list, built ONCE and shared with the Vault

Create `DesireMapListSheet` (or `DesireMapListView`): "Where you meet" header, `"1 revealed · N more you share"` sub, then matches as expandable cards — free one open/readable (reuses `DesireMatchDetail` from 1b), locked ones blurred name + lock, one `Unlock the full map · $24.99` CTA (`corePriceText`). Tapping a card expands it; locked → paywall. This is the **same view the Vault renders** in `VaultDesireSection`; build it to take `[RevealMatch]`/`MapStore.AlignItem` so `VaultStore.align` can feed it. (Wire the Vault reuse in Phase 3; here, build the view + use it in the reveal's Full-map sheet.)

### 1e. `HomeRouterView` — repoint the reveal presenter

Change the reveal from `.fullScreenCover(item: $activeReveal)` to `.vaylCover(isPresented: <Binding off activeReveal != nil>, confirmOnExit: false) { if let s = activeReveal { DesireRevealView(store: s) } }`. The `X` inside calls `\.vaylDismiss`, not `@Environment(\.dismiss)`. Leave `.sheet(item: $activeSession)` and `.fullScreenCover(item: $activeMap)` (the rater) alone in this phase.

**Phase 1 done:** free couple opens the reveal → free star ignites + sparkles → tap a star → detail sheet → tap a locked star (or Full map → list) → paywall → purchase unlocks in place, whole sky lights. Already-Core skips to lit. Compiles; matches the storyboard screens 6–10; Bryan confirms feel on device.

---

## 4. PHASE 2 — THE RATER reskin (screens 1–5)

Reskin `DesireMapView` into the void/star world. **Reuse `DesireMapStore` for all rating data** (`load()`, `rate(itemId:rating:)`, `isComplete`); add only presentation state (current index, the accumulated sky, the finish phase) in the View or a thin view-state, never new rating logic.

- **Screen 1 Start:** centered start over void + atmosphere + starfield. Copy is locked:
  Headline `"See where your desires meet"` ("meet" in the warm spectrum). Body `"It's about opening up your relationship: the desires that are hard to say first. Answer privately, and where you and Alex overlap becomes a map you explore together."` Privacy line `"You answer only for yourself. Only your mutual matches are revealed, never your private nos."` `Begin` CTA. `"17 questions · about 3 minutes"`. On `Begin`: the **spectrum-bloom entrance** (a `GlowOrb`-style spectrum bloom expands from center, the start recedes/fades, Q1 emerges from depth and the answer rows rise in staggered). Use `desireRevealBloom`-paced timing; this is the one ceremonial entrance.
- **Screen 2 Rate:** progress bar (`ratedCount`/`totalCount`), `qcat` (item.category), `qtext` (item.name/description — match storyboard), the four `DesireRatingValue` options as rows/pills. **Answer-dot colors (from the storyboard, keep them):** excitedAboutIt = cyan, openToIt = purple, probablyNot = tertiary/grey, notForMe = magenta (Bryan's reasoning: red/magenta = "no"). On tap → `store.rate(itemId:rating:)` + advance with the **depth-push** (`desireDepthExit`/`desireDepthEnter`) AND a star rises into the sky above (`ConstellationField` in accumulate mode, `desireStarRise`, synced to the exit). A positive answer (excited/open) adds a bright star; probablyNot/notForMe add no star (the sky = what you want). A small private-note line at the bottom.
- **Screen 3 Charted (finish beat) — a transition, not a screen.** After the final `rate()` makes `store.isComplete` true: (1) final question + rows fade out (`desireFinishFade`); (2) the last star rises with extra flair — brighter ignite + a sparkle (`desireFinishFlair`), the sky settles complete; (3) `"Your map is charted."` + `"All 17. The lines find Alex's once they finish theirs."` fade in (`desireChartedFadeIn`) and `ConstellationField(lineMode: .hesitant)` begins one tentative sketch (the lines draw partway and never lock — the real connection waits for the reveal); (4) hold `desireChartedHold` (~2s, tap-anywhere-to-skip from the flair onward); (5) **auto-advance** by branch (below). No glyph, no `✦` — the mark is the user's own forming constellation. (See storyboard screen 3.)
- **Screen 4 Wait (first finisher):** the solo mirror. Overline `"just for you"`, `"Everything you said"`, sub `"Your full read, kept private. Where it meets Alex's appears once they finish theirs."` Then **all** their answers grouped by `DesireRatingValue` (Excited / Open / Probably not / Not for me), each a row with the rating accent bar + the item name + a `›` door to Learn (probablyNot/notForMe rows muted). A `"No rush, and no race…"` wait line. **This is a list/mirror, NOT a constellation** (the constellation is reserved for the couple reveal), and it shows **every** answer, not just the positive ones, and never any partner comparison.
- **Screen 5 Ready (re-entry):** the same mirror with a bright `"Alex finished. Your map is ready."` bar pinned at top (tap → present the reveal). This appears when `partnerMapComplete` polls true on re-entry.

**Phase 2 done:** Begin → spectrum-bloom entrance → rate 17 with depth-push + star-rise → charted finish with hesitant lines → mirror (solo). Compiles; matches storyboard 1–5; Bryan confirms feel.

---

## 5. PHASE 3 — Wiring, branch, Vault reuse, edges

- **The finish branch (who finishes second):** on `store.isComplete`, the rater calls `service.fetchStatus(coupleId:)` (via the store, not the view) to read `bothComplete`:
  - **second finisher** (`bothComplete == true`) → the charted beat auto-advances **into the reveal**: dismiss the rater cover and present the reveal (`activeReveal = …`). The personal sky's matching stars converging into the shared constellation is the Swift-native morph (flag it; build the simple cross-dissolve first, the morph is a polish pass).
  - **first finisher** (`false`) → charted auto-advances to the **wait mirror** (screen 4), staying in the rater cover.
  - **re-entry** when `partnerMapComplete` later polls true → the mirror shows the **Ready bar** (screen 5); tapping it presents the reveal.
- **Notification:** push is **stubbed** (`PushService` is unverified scaffold — do NOT wire it). Partner completion is learned by **polling** (`HomeStore` loads `bothComplete` on Home appear). The Ready bar is driven by `partnerMapComplete`. That is the V1 behavior; do not build push.
- **Vault reuse (screen 9 = the Vault desire list):** point `VaultDesireSection` at the shared `DesireMapListView` from 1d, fed by `VaultStore.align` + `lockedAlignCount`. Build the list once, render it in both the reveal's Full-map sheet and the Vault. (If Vault wiring risks scope-creep, ship the reveal's copy first and leave a `// reuse in VaultDesireSection` seam.)
- **Edge states:** already-Core (skip paywall, lit sky), 0 matches (graceful empty), 1 match (free star only, gentle close), Reduce Motion (every animation a static fallback; still purchasable).
- **HomeRouterView:** the rater stays its own presenter for now (the nav-grammar cleanup of the rater is out of scope); only the reveal moved to `.vaylCover` in Phase 1. The branch sets `activeReveal` to hand off rater → reveal.

---

## 6. Constraints — files you must NOT touch

- `PaywallSheet.swift` body / copy / layout / bloom knobs (use `entry: .reveal` + `onUnlocked:`).
- `DesireSyncService`, the `compute-desire-matches` edge fn, `EntitlementStore`, and every model/enum in §1. No schema or logic changes.
- `DesireMapStore`'s rating logic — reuse `load()` / `rate()` / `isComplete`; do not duplicate or alter the persistence/sync path.
- `vaylSheetChrome` / `VaylPresentation` — extend only if strictly forced; never restyle.
- `ConstellationNode.swift` (Learn) — mirror its recipe in `DesireStarView`, do not import or edit it.

---

## 7. Gotchas — read before each segment

1. **`.vaylCover` is `isPresented:`-based**, defaults `confirmOnExit: true`. For the reveal pass `confirmOnExit: false` (re-openable, not destructive). Drive it off a `Binding<Bool>` mapped from `activeReveal != nil`; unwrap the store inside. The `X` calls `\.vaylDismiss`, never `@Environment(\.dismiss)`.
2. **Sheets inside the cover are custom** (scrim + bottom-pinned + `.move(edge:.bottom)`), mirroring `CredentialEditorOverlay`. Do NOT present them via `.vaylSheet`/`.sheet` (double-chrome + iOS-26 width inset bug). The exception: the Vault's own `.vaylSheet` host stays as-is.
3. **Never `.drawingGroup()` the animating star/constellation.** The sparkle `keyframeAnimator` must re-render only its layer; the resting cross is static; the one-shot ignite is cheap. (Contrast: `VaylCardFace` is `.drawingGroup`-rasterized — that contract is for the OB card, not these stars.)
4. **`notForMe` privacy:** the reveal read path (`DesireMatchRow`) is alignment-only and carries no raw partner values. `notForMe` **syncs** (it is not withheld at upload) but is **excluded from every shared/couple view** server-side, and surfaces ONLY in the user's own mirror (screen 4/5). Never gate a couple view on a rating that could leak the partner's answer. Do NOT re-derive a "never leaves the device" model — that is the retired posture.
5. **Warm desire colorway:** the stars are magenta-led → purple, **no cyan** (cyan is the cool, non-desire identity). The rater *answer-dot* colors are a separate concern (cyan/purple/grey/magenta per the storyboard) and are fine.
6. **Reduce Motion:** every ambient loop (twinkle, sparkle, blooms, line sketch) disables to a complete static state; every reactive animation falls back to a fast opacity confirm. Use `.ambientAnimation`, `.reduceMotionSafe`, and `@Environment(\.accessibilityReduceMotion)`.
7. **Tokens only.** No raw colors/fonts/spacing/radius/opacity/duration literals in the views. Add durations to `AppAnimation` (§0a). Reference `AppColors`/`AppFonts`/`AppSpacing`/`AppRadius`/`AppGlows`.
8. **Build the matches list once** (1d) and reuse it in the reveal Full-map sheet and `VaultDesireSection`. Do not fork two list views.
9. **Empty/sparse layout:** `ConstellationField` must degrade — 1 match is a single hero star, not a lonely web; many matches spread without crowding.

---

## 8. Segment checklist (each is "done" only when it compiles AND matches the storyboard AND Bryan confirms the feel on device — not "build succeeds")

- **S0.1** AppAnimation Desire Map tokens. *Done:* compiles, names match §0a.
- **S0.2** `SparkleStar` + `DesireStarView` (with sparkle keyframe + reduce-motion). *Done:* a preview shows the warm star with the resting cross and an occasional sparkle.
- **S0.3** `ConstellationField` (layout + hesitant/confident lines + sparse degrade). *Done:* previews for 1, 3, 5 nodes in each line mode.
- **S1.1** `DesireRevealStore` interaction state + `markRevealSeen`. *Done:* compiles, no behavior change to `load`/`unlockAll`.
- **S1.2** `DesireRevealView` constellation + free star (screen 6) + the in-cover sheet host. *Done:* screen 6 matches the storyboard.
- **S1.3** `DesireMatchDetail` + `DesireStarDetailSheet` (screen 7). *Done:* tapping a star opens the detail.
- **S1.4** Paywall host + unlock-in-place (screen 8 → 10). *Done:* purchase lights the sky without leaving the cover.
- **S1.5** `DesireMapListView` Full-map sheet (screen 9). *Done:* top-right Full map opens the gated list.
- **S1.6** `HomeRouterView` reveal → `.vaylCover`. *Done:* reveal presents via the cover, X closes cleanly, edges (Core / 0 / 1) graceful.
- **S2.1** Start screen + spectrum-bloom entrance (screen 1).
- **S2.2** Rate screen: 4-point rows + depth-push + star-rise accumulation (screen 2).
- **S2.3** Charted finish beat: fade → flair → charted + hesitant lines → hold → auto-advance hook (screen 3).
- **S2.4** Solo mirror (screen 4) + Ready re-entry bar (screen 5).
- **S3.1** Finish branch (second → reveal handoff; first → mirror; re-entry → ready bar) via `fetchStatus`.
- **S3.2** Vault reuse of the list (`VaultDesireSection`) + edge states + reduce-motion sweep.

Stop after each segment for Bryan's device confirmation before starting the next (Vayl build protocol: feel is the done condition, not compilation).

---

## 9. Reference index

- Storyboard (visual truth): `docs/prototypes/desire-map-flow-family.html`
- Felt timings: `docs/prototypes/desire-reveal-constellation.html`, `docs/prototypes/desire-rater-flow.html`
- Reveal stub to restructure: `Features/Desire Map/Views/DesireRevealView.swift`, `…/Store/DesireRevealStore.swift`
- Rater to reskin: `Features/Desire Map/Views/DesireMapView.swift`, `…/Store/DesireMapStore.swift`
- Node recipe to mirror: `Features/Learn/Views/ConstellationNode.swift`
- Sheet-in-cover host: `Features/Onboarding/Phases/CredentialEditorSheet.swift` (`CredentialEditorOverlay`)
- Presentation: `Design/Components/Navigation/VaylPresentation.swift`
- Paywall: `Features/Monetization/Views/PaywallSheet.swift`
- Vault list target: `Features/Map/Vault/VaultStore.swift`, `VaultDesireSection.swift`
- Tokens: `App/Theme/AppAnimation.swift`, `AppColors.swift`, `AppGlows.swift`, `AppFonts.swift`, `AppSpacing.swift`, `AppRadius.swift`
- Rules: `CLAUDE.md`
```
