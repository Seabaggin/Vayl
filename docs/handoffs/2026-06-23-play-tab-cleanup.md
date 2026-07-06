# Play Tab — Handoff & Cleanup Brief (2026-06-23)

> **You are a senior iOS engineer inheriting a feature a junior AI built in one fast pass.** It compiles, the bones are right, and *more is working than not* — but treat every line as **unverified and suspect until you prove otherwise on device**. Do not assume the prior author understood the codebase, the mockup, or the architecture. Re-derive, don't trust. Where this brief states a "finding," verify it yourself before relying on it.

The previous author already made (and the human caught) several avoidable mistakes: it hand-rolled a floating-card container instead of reusing the existing one, shipped a cheap gradient "deck case" instead of the real art, and animated ~20 Metal-shader views in a scroll grid without thinking about cost. Assume there are more like these. **Find them.**

---

## 1. What this is

The **Play tab** — a deck library + launcher. Lives in `Vayl/Features/Play/`. It replaced a stub (`PlayView` was a placeholder). Wired into `AppShell.swift` (`case .play: PlayView()`).

**The visual target is the mockup:** `docs/prototypes/play-tab.html` (open it in a browser — it's the source of truth for layout/feel). The design plan is `docs/superpowers/plans/2026-06-23-play-tab.md` (read for intent, but the plan diverges from the mockup in places — when they conflict, **the mockup wins**, that's the human's latest call).

**Screen anatomy (top → bottom):** an "invisible rotary" mode dial → a floating active-deck **hero** card → the **deck wall** (docked peek that expands to a pan/zoom grid). Tapping a deck floats a 3D detail; Begin → ceremony → Card Session.

---

## 2. How to work here (non-negotiable, learned the hard way)

- **Branch:** work on the current branch `spec/contextphase-2x3-redesign` directly. The human has ~138 unrelated in-flight files; **do not** create worktrees/branches, **do not** `git add -A`, **do not** commit `project.pbxproj`. The human owns git. New source files under `Vayl/Features/Play/` auto-join the app target (synchronized group) — no pbxproj edits needed.
- **Verification = compile, not XCTest.** Don't add XCTest files (wiring them edits the human's dirty `project.pbxproj` and risks breaking the project). Verify with a build + `#Preview` + the human runs device. Build command (no sim, ~15-20s incremental):
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ```
  If you hit `database is locked`, the human's Xcode is building previews — wait and retry; it's not a code error.
- **You compile; the human runs on device and judges feel.** You cannot judge pixels/animation yourself. Make spec-faithful changes, then hand specific things to test.
- **Architecture is law** (`CLAUDE.md`): zero raw literals in views — only `AppColors / AppFonts / AppSpacing / AppRadius / AppAnimation`. Present modals via `.vaylCover` / `.vaylSheet` only. 4-layer: View → Store (`@Observable @MainActor`) → Service → Model. iOS 26 / Swift 6, iOS 16+ baseline, no `UIScreen.main`.
- **Reuse before you build.** The mistakes above were all "reinvented something that existed." Before writing any visual component, grep for an existing one (`CardCarousel`, `VaylCardFace`, `MetallicCaseView`, `DeckPedestal`, `OnboardingAtmosphere`, the `Foil*` types).
- **`AppColors.gold` does not exist** (the prior author used `accentTertiary`). Don't hallucinate tokens — grep `AppColors`/`AppFonts` first.

---

## 3. Current state — the files (all in `Vayl/Features/Play/`)

| File | Role | Trust level |
|---|---|---|
| `Store/PlayMode.swift` | `PlayMode` enum + `PlayFeatureFlags.simulatorEnabled = false` (Cards-only at launch; rotary engine built, Simulator gated) | OK |
| `Models/DeckSummary.swift` | Lightweight catalog row + a "Catalog decodes" `#Preview` | OK |
| `Resources/Decks/deck-catalog.json` | 14-deck manifest (only `the-opener` has real cards; rest `comingSoon`) | OK (verified bundled) |
| `Services/DeckCatalogService.swift` | loads summaries + a full `Deck` | OK |
| `Models/DeckStyle.swift` | **generated** identity: category→colorway legend + per-deck hash hue/holo | OK, but unverified visually |
| `Components/DeckGlyph.swift` | 6 monoline category marks | OK |
| `Store/PlayStore.swift` | all state: catalog, featured deck + its cards, dial mode, canvas/detail/ceremony/session | review |
| `Components/DeckCaseView.swift` | **the bad one** — wraps the real `MetallicCaseView(flat:true)` | **REPLACE (see §5.3)** |
| `Components/DeckCellView.swift` | case + title/meta underneath | review |
| `Components/PlayHeroView.swift` | hero = `CardCarousel` + title header | **REWORK (see §5.2)** |
| `Components/RotaryDial.swift` | the dial (`RotaryMath` + swinging glyph) | **REPOSITION (see §5.1)** |
| `Components/DeckWallView.swift` | docked peek → `ZoomablePanView` grid | review |
| `Components/ZoomablePanView.swift` | `UIScrollView`-backed pinch/pan host | review |
| `Components/DeckDetailView.swift` | float-in-space detail (real 3D `MetallicCaseView`) → Begin | review |
| `Components/DeckBeginCeremony.swift` | `MetallicCaseView` dissolve + reduce-motion fallback | review |
| `PlayView.swift` | tab root + screen (merged content), `#Preview` injects `AppState()` + `.previewContainer` | OK |

**Also touched (shared component — verify you agree with it):** `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift` got an additive `flat: Bool = false` param (forces rise pose 0 + renders once via the existing reduce-motion static path). This was meant to make flat grid cases cheap. **It is implicated in the bad rendering — see §5.3.**

**Builds clean** (BUILD SUCCEEDED, 0 errors). **Nothing has been confirmed on device.**

---

## 4. What's going RIGHT (don't break these)

- The data spine is sound: `DeckSummary` + `deck-catalog.json` + `DeckCatalogService` + the **generated** `DeckStyle` (category colorway legend + per-deck hash variation). The "decouple browse from card-content authoring via lightweight summaries" approach is correct.
- The rotary *engine* + gating (`PlayFeatureFlags.simulatorEnabled`) is the right shape — build once, drop the 2nd game in later.
- Session launch is wired correctly: Begin → `.vaylCover { CardSessionContainerView(hand: deck.orderedCards) }`.
- The detail/ceremony reuse the **real** `MetallicCaseView` (3D, animated) — correct place for it.
- The overall IA matches intent: dial → hero → wall → detail → ceremony → session.

---

## 5. What's WRONG — the human's notes (priority order)

### 5.1 The rotary renders too low
The dial glyph sits far lower than the mockup. The human's hypothesis: **the card-container bounds that are perfect for Home are wrong for Play.** Suspect `RotaryDial` is laid out in a `VStack` with `.frame(height: 150)` while its internal wheel uses fragile nested `rotationEffect` + hard-coded `.offset(y: 36/50)` — re-derive the geometry. **Mockup target (px from phone top):** glyph centre ≈ y86, glow ≈ y84 (120px cyan radial), labels ≈ y128, content starts ≈ y168 (see `docs/prototypes/play-tab.html` `:root` dial vars + the `.dialHub/.activeGlow/.dialLabels` rules). Rebuild the dial so the glyph hangs just under the status bar, not halfway down the screen. Consider whether the dial should be pinned/absolute rather than flowing in a `VStack`.

### 5.2 The hero card container must be DIFFERENTIATED from Home
Right now `PlayHeroView` just drops in Home's `CardCarousel` verbatim. The human wants Play's container to be **visibly its own thing** — carry the **deck title** and other deck-relevant info (intensity, card count, progress, etc.) so a user can tell it apart from Home's hand-builder. (Note: the prior author *over-corrected* here — it was told "stop reinventing, reuse `CardCarousel`," which was right, but reuse ≠ identical. The job is: reuse the card *face/physics*, **present it differently** for Play.) Decide with the human whether Play even needs the full spread→lift→carousel behavior or a calmer "one featured deck" presentation. Also revisit the bounds (`CardCarousel` uses `.frame(height: cardH + 120)` = 310, tuned for Home) — likely too tall here and part of why the dial reads low.

### 5.3 The deck case renderings are bad — build a bespoke static deck view for Play
The current grid case = real `MetallicCaseView(flat: true)`, and it **renders with no visible design** at grid scale (the flat static pose kills the tilt-driven foil band, the metal is dark, detail is lost in a small cell → near-blank dark boxes). **The human's decision: stop using `MetallicCaseView` for the grid.** Instead **create a new, purpose-built static deck view for Play**: a high-level, **1D, static** render with a **honeycomb (hex) effect that looks holographic but is NOT animated** (no `.metal` shader, no `TimelineView`, no per-frame work — a Canvas/SwiftUI-shape composition that reads as foil/holo at a glance and is cheap to scroll). Keep the **real animated 3D `MetallicCaseView` for the tap/detail** only. This is a design task as much as code — study the mockup's `.dcase` recipe (hex foil + 2-pass spectrum frame + top catch-light + emblem, `docs/prototypes/play-tab.html` lines ~207-235) and the foil look in `MetallicCaseView` / `HolographicShimmer.metal`, then reproduce the *look* statically. Question whether the `flat` param added to `MetallicCaseView` should even stay (it may be dead once the grid stops using it).

### 5.4 The grid is "not rendering the placeholder decks"
The human expected ~14 placeholder decks in the grid and didn't see them. **Finding (verify):** `deck-catalog.json` *is* in the app bundle (confirmed in the built `.app`, next to `the-opener.json`), and `ContentLoader.load` resolves it via `Bundle.main.url(forResource:"deck-catalog", withExtension:"json", subdirectory:nil)`. So this is **not** a missing-data bug. Likely causes to chase: (a) the cases render so blank (§5.3) the grid *looks* empty; (b) a decode error swallowed by `PlayStore.load()`'s `catch` (it sets `loadError` and empties `summaries` silently — add a visible error/empty state and check `loadError`); (c) a layout bug in the docked peek (`DeckWallView.peek` clips a `LazyVGrid` inside a fixed `.frame(height:300).clipped()` — verify cells actually lay out) or the expanded `ZoomablePanView` (the `UIScrollView` + `UIHostingController` host is unproven; confirm content size/zoom actually work). **First diagnostic:** run the "Catalog decodes" `#Preview` in `DeckSummary.swift` — if it lists 14 rows, data is fine and the bug is render/layout.

---

## 6. Open / lower-priority items to scrutinize

- **Wall structure** was just changed from category clusters → one flat grid to match the mockup. Confirm the human wants flat (the *plan* said "spatial clusters," the *mockup* is flat; mockup won). The docked peek + bottom fade + "tap the shelf" hint approximates the mockup's `.libCanvas` dock — but the mockup's exact model is an absolutely-positioned canvas that resizes (`top: var(--dockTop)` → `top:6;bottom:0`) with the hero collapsing out (`.cardLayer` opacity/scale). The SwiftUI version does NOT replicate that collapse animation — consider it.
- **`ZoomablePanView`** pins content width to the frame (vertical scroll + zoom only); the mockup pans a wider-than-screen 3-col plane. Decide if true 2-axis pan is wanted.
- **Locked "Unlock with Core" CTA** in `DeckDetailView` just closes the sheet — real `PaywallSheet` wiring is a TODO (flagged, not silent).
- **Reduce Motion** paths exist but are unverified.
- **Performance:** even after §5.3, audit for any remaining per-frame work in the wall.

---

## 7. References

- **Mockup (visual truth):** `docs/prototypes/play-tab.html` — open it; serve `docs/prototypes/` (there's a `server.js`, port 7333) or `file://`.
- **Plan (intent, diverges from mockup):** `docs/superpowers/plans/2026-06-23-play-tab.md`
- **Architecture + tokens:** `CLAUDE.md` (root).
- **Reuse these, don't rebuild:** `Vayl/Design/Components/Cards/CardCarousel.swift`, `VaylCardFace.swift`; `Vayl/Features/Home/Components/DeckPedestal.swift`; `Vayl/Design/Components/Effects/FoilOpen/` (`MetallicCaseView.swift`, `FoilDeckTheme.swift`, `HolographicShimmer.metal`); `Vayl/Features/Onboarding/Components/OnboardingAtmosphere.swift`; `Vayl/Features/Sessions/CardSessionContainerView.swift`.
- **How Home wires the card container (the reference pattern):** `Vayl/Features/Home/Views/HomeDashboardView.swift` (search `CardCarousel(`).

## 8. Suggested first moves

1. Open the mockup and the app side by side; reproduce the human's three visual complaints yourself before changing anything.
2. Run the "Catalog decodes" preview → settle §5.4 (data vs render).
3. Fix §5.1 (dial position) — it's the most jarring and likely small.
4. Design + build the bespoke static holo-hex deck case (§5.3) — biggest visual win.
5. Differentiate the hero (§5.2) with the human in the loop on behavior.
6. Re-check everything in §6 with a skeptic's eye. Assume the prior author missed things.
