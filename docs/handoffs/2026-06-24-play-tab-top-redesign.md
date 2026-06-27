# Play Tab — Top Redesign Handoff & Continuation (2026-06-24)

> Continues `docs/handoffs/2026-06-23-play-tab-cleanup.md` (the original cleanup brief, still the source for the deck-case art §5.3, the grid §5.4, the §6 audit, and the working agreement). This doc captures the **design rethink done 2026-06-24**: the human asked to treat the Play tab as a real overhaul, and the **top of the tab (mode area + hero) was redesigned together and locked**. Decisions below are settled unless marked *pending*.

---

## 1. Working agreement (restated, unchanged)

- **Branch:** work on `spec/contextphase-2x3-redesign` directly. The human has ~138 unrelated in-flight files. Never `git add -A`, never commit `project.pbxproj`, no worktrees/branches. New files under `Vayl/Features/Play/` auto-join the app target. The human owns git.
- **Verify = compile + `#Preview`, not XCTest.** Build:
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ```
  `database is locked` = the human's Xcode is busy, wait and retry, not a code error.
- **You compile; the human runs on device and judges feel.** Make spec-faithful changes, then hand a specific device checklist.
- **Architecture is law (`CLAUDE.md`):** zero raw literals in views (tokens only), `.vaylCover`/`.vaylSheet` for modals, 4-layer (View, Store, Service, Model). iOS 26 / Swift 6, no `UIScreen.main`.
- **Build protocol:** confirm each segment's scope before writing code; feel is verified on device, "build succeeds" is not "done."
- **Reuse before you build.** Grep for an existing component first. Tokens are real, do not hallucinate (`AppColors.gold` does not exist).
- **No em dashes** in Vayl copy or in chat replies (use commas, periods, colons).

---

## 2. The reframe (why the top changed)

The first pass put an "invisible rotary" mode dial at the top. The human's complaint was it "sits too low," and the deeper read is that the whole approach fought the platform:

1. **Geometry:** the mockup's coordinates are absolute from the phone's physical top (glyph centre ~y86, just under the island). The Swift dial flowed below the safe area (~59pt) and then hung the glyph another ~78pt down, landing at ~137pt. Off by ~50pt, structural not a constant.
2. **Native conflict:** the mockup *simulates* a Dynamic Island with a static pill. The real island is live (calls, timers, music, Face ID expand it). HIG says keep that zone clear of competing custom UI. A glowing glyph hugging the island collides the moment a Live Activity fires.
3. **IA smell:** at launch only **Cards** is enabled (Simulator is Act-2 gated, `PlayFeatureFlags.simulatorEnabled = false`). An elaborate rotary that switches between one mode is ceremony with no payoff, and it is the single most space-eating, island-crowding element.

**Decision with the human:** cut the rotary for V1. Keep the two-world identity as a **premium, static, island-safe** element. Simulator returns post-launch.

---

## 3. LOCKED design decisions (V1 top)

### Masthead
- `Cards` wordmark, **Clash Display**, spectrum gradient text, left-aligned, with a short **spectrum underline** accent. No eyebrow.
- Sits **below the safe area** (island-safe), pulled tight to the hero so it reads as a header, not a sparse band.
- It is the tab's world identity. The `PlayMode` enum + `simulatorEnabled` flag **stay in code**, so the Simulator world drops back in beside `Cards` post-launch with no rework. We are hiding the switch, not deleting the engine.

### Hero
- **Model = single featured deck + spread.** Reuse `CardCarousel` **as-is** (its real strength: float, spread the deck's hand into a fan, lift, carousel of *that deck's cards*; tap a card = begin/resume). **No in-hero deck switching** and **no deck dots**, switching lives in the library grid below. This is an intentional divergence from the mockup's "swipe to switch decks," the human's latest call wins.
- **Header is continuity-aware:**
  - eyebrow: `Continue` (deck started) / `New deck` (fresh)
  - deck name (Clash), meta line: intensity dot + `intensity.difficultyLabel` + `N cards`
  - continuity line: started → slim **spectrum progress bar** + `X of N explored`; fresh → `Not started` in the same slot (keeps both states the same height so the hero does not jump).
- **Featured deck selection:** most-recent in-progress deck, else first available, so `Continue` is meaningful. *(pending final human confirm; the alternative is a fixed featured pick.)*

### Data (confirmed real, not aspirational)
- `DeckProgress` `@Model` (`currentCardIndex`, `firstOpenedAt`, `completedAt`, `isUnwrapped`) is **written** by `SessionStore.updateDeckProgress()` mid-session and `completedAt` on finish; `CoupleSessionStore` mirrors it. So the `Continue` state genuinely lights up.
- **Read pattern to copy:** `HomeStore.loadDeckProgress()` (`Vayl/Features/Home/Store/HomeStore.swift:238-260`) builds a `FetchDescriptor<DeckProgress>` filtered by `coupleId` + `deckId`. `coupleId` comes from `AppState.coupleId` (`Vayl/Core/Services/AppState.swift:66`).

---

## 4. Visual references (mockups)

- **`docs/prototypes/play-top-v1.html`** — CANONICAL V1 top. Masthead + continuity hero, both states (started vs fresh). This is the build target for the top.
- **`docs/prototypes/play-mode-switch-options.html`** — the exploration record: A glass twin-glyph switch / **B editorial masthead (chosen)** / C deck-of-modes. Also shows the post-launch two-world treatment for when Simulator ships.
- **`docs/prototypes/play-tab.html`** — the original full mockup. Still the truth for everything *below* the top: the deck library, the case art, pan/zoom canvas, detail, ceremony.

All mockups use the real Midnight tokens (void, spectrum cyan→purple→magenta, glass, Clash/Switzer). The human views them via `file://` or the port-7333 server in `docs/prototypes/`. Use HTML (not SVG) for UI design options; iterate complex Swift-rendered visuals (3D, shaders) directly in Swift on device.

---

## 5. Segment 1 — ready to build (awaiting human confirm)

**One thing it does:** kill the low rotary, add the `Cards` editorial masthead, and give the existing featured-deck hero a continuity-aware header driven by real `DeckProgress`.

**Files to touch:**
- **NEW** `Vayl/Features/Play/Components/PlayMastheadView.swift` — `Cards` Clash spectrum wordmark + underline. Tiny, presentational.
- **EDIT** `Vayl/Features/Play/Components/PlayHeroView.swift` — restructure the header to: eyebrow (Continue/New) → name → meta → continuity line (progress bar + `X of N` / `Not started`). Keep the `CardCarousel(cards: store.featuredCards)` block as-is.
- **EDIT** `Vayl/Features/Play/Store/PlayStore.swift` — add a `DeckContinuity` enum (`fresh` / `inProgress(index, total)` / `completed`) + a `featuredContinuity` resolved from a `DeckProgress` fetch (copy `HomeStore.loadDeckProgress`). Default `featuredID` to the most-recent in-progress deck, else first available.
- **EDIT** `Vayl/Features/Play/PlayView.swift` — replace `RotaryDial(...)` with `PlayMastheadView()` at top-leading.

**Constraints (do NOT touch):** `CardCarousel`, `VaylCardFace` (reuse, no shell edits) · the whole deck grid (`DeckWallView`, `DeckCellView`, `DeckCaseView`, `MetallicCaseView`, that is §5.3) · `SessionStore` / `CoupleSessionStore` / `DeckProgress` writes (read-only consumer) · no pbxproj, no git.

**Done (human verifies on device):** masthead top-left with spectrum + underline; content sits high (the "too low" is gone with the dial removed); featured deck shows `Continue` + progress bar or `New deck` + `Not started`; tapping a card still begins/resumes the deck.

---

## 6. Remaining segments (after Seg 1)

- **Segment 2 — the bespoke static deck case (§5.3, biggest visual win).** Replace `DeckCaseView`'s `MetallicCaseView(flat: true)` with a new **purpose-built static** deck view for the grid: 1D, no `.metal` shader, no `TimelineView`, no per-frame work. A Canvas/SwiftUI-shape composition that reads as foil/holo at a glance and is cheap to scroll. Study the mockup's `.dcase` recipe in `play-tab.html` (~lines 207-235: hex foil + 2-pass spectrum frame + top catch-light + emblem). Keep the **real animated 3D `MetallicCaseView` for the tap/detail and ceremony only.** This also fixes §5.4 (the grid only *looks* empty because the cases render near-blank, see below). This is a design task: do HTML mockups of the case first, then Swift.
- **Segment 3 — grid honesty (§5.4).** The data is fine: `deck-catalog.json` decodes all 14 rows (verified, `DeckCategory`/`CardIntensity` cover every value). The grid only *looks* empty because (a) the cases render blank and (b) the docked peek clips a 2-col grid of 2:3 cases to `.frame(height: 300).clipped()`. Add a visible empty/error state in `DeckWallView`/`PlayStore` (the `catch` currently empties `summaries` silently) and revisit the peek clipping.
- **Segment 4 — §6 audit.** `ZoomablePanView` (true 2-axis pan?), the hero-collapse canvas animation, the locked `Unlock with Core` CTA → real `PaywallSheet` wiring, Reduce Motion paths, residual per-frame work in the wall.

---

## 7. Working-tree state to know

- `RotaryDial.swift` was rebuilt this session into a proper hub-anchored pendulum (compiles), but the **dial is being cut for V1**, so Segment 1 unmounts it. Treat the rebuild as throwaway for V1 (the post-launch switch is the masthead two-world treatment, not a rotary). The file can stay in the repo or be reverted, the human's call.
- `PlayView.swift` currently still mounts `RotaryDial` (with a `.padding(.top)` tweak from this session). Segment 1 swaps that for `PlayMastheadView`.
- Both are uncommitted edits living among the ~138 in-flight files. Do not revert anyone else's work.

---

## 8. Continuation prompt for the new chat

```
You are a senior iOS engineer continuing a redesign of the Play tab in Vayl
(SwiftUI, Swift 6, Xcode 26, iOS 16+). A prior session redesigned the TOP of the
tab WITH the human and locked the decisions. Build on those improvements, do not
re-litigate them, and keep brainstorming the parts still open (the deck library and
its case art), then implement in small device-verified segments.

READ FULLY, in this order, before touching code:
1. docs/handoffs/2026-06-24-play-tab-top-redesign.md  (this session's locked
   decisions + the ready-to-build Segment 1 + the remaining segments).
2. docs/handoffs/2026-06-23-play-tab-cleanup.md  (the original cleanup brief: still
   the source for the §5.3 case art, §5.4 grid, §6 audit, and the working agreement).
3. docs/prototypes/play-top-v1.html  (the canonical V1 top) and
   docs/prototypes/play-tab.html  (the full mockup, still the truth for the library,
   grid, detail, and ceremony below the top).
4. CLAUDE.md  (architecture law: zero raw literals, tokens only, .vaylCover/.vaylSheet,
   4-layer; and the build protocol: confirm each segment's scope before code, verify
   feel on device).

LOCKED (do not redesign without the human):
- Rotary is cut for V1. Top of Play = a "Cards" editorial masthead (Clash spectrum +
  underline), island-safe. Simulator returns post-launch; the PlayMode engine stays.
- Hero = single featured deck, reuse CardCarousel as-is (spread/preview, tap a card =
  begin). No in-hero deck switching. Continuity header from real DeckProgress
  (Continue + progress bar / New + Not started). Featured = most-recent in-progress
  deck (pending the human's final confirm).
  Full spec is in section 5 of the handoff.

HARD CONSTRAINTS:
- Branch spec/contextphase-2x3-redesign directly. ~138 unrelated in-flight files.
  Never git add -A, never commit project.pbxproj, no worktrees/branches. New files
  under Vayl/Features/Play/ auto-join the target.
- Verify = compile + #Preview, not XCTest. Build:
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ("database is locked" = the human's Xcode is busy, retry.)
- You compile; the human runs on device and judges feel. Make spec-faithful changes,
  then hand the human an exact device checklist.
- Reuse before you build. Grep for an existing component first. Tokens are real, do
  not hallucinate (AppColors.gold does not exist).
- No em dashes in copy or replies (commas, periods, colons).

FIRST MOVES:
1. Confirm the Segment 1 scope (handoff section 5) with the human, then build it
   (Cards masthead + continuity hero + unmount the dial) and compile. Hand over a
   device checklist. Do not claim it "works", say "compiles, here is what to verify."
2. Then brainstorm Segment 2 with the human off this foundation: the bespoke STATIC
   holo-hex deck case for the grid (1D, no shader, no TimelineView, cheap to scroll),
   which also fixes the perceived-empty grid. Use the mobile-ios-design skill as the
   lens and HTML mockups (real Midnight tokens, viewed via file://) for the design
   options BEFORE any Swift. Keep the real animated MetallicCaseView for tap/detail only.

Use the brainstorming + mobile-ios-design skills for the open design work. Confirm
scope before each segment.
```
