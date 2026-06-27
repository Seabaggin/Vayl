# Play Tab — Segments 2-4 Overnight Build (2026-06-24)

> Continues `docs/handoffs/2026-06-24-play-tab-top-redesign.md` (Segment 1 = the locked top: Cards masthead + continuity hero). The human asked to **one-shot the rest** of the Play redesign overnight to review in the morning. This doc records that autonomous run: Segments 2, 3, 4 built and **compiling** (`BUILD SUCCEEDED`), **device-unverified** (the human was asleep, so the per-segment device/feel gate could not run live). The deck-case art (Segment 2) is the one taste decision made without his eye: an HTML options board was produced so the design gate becomes his morning review.

---

## Status at a glance

- **Everything compiles.** `xcodebuild ... build` → `BUILD SUCCEEDED`, 0 errors.
- **Nothing is device-verified.** "Compiles" is not "feel is correct." The device checklist is below.
- **Branch:** `spec/contextphase-2x3-redesign`, uncommitted, among the human's in-flight files. No git, no pbxproj, no worktrees touched.
- **The one decision waiting on the human:** bless deck-case **Option A** (built) or redirect to **B / C** in `docs/prototypes/play-deck-case-options.html`.

---

## Segment 2 — static holo-hex deck case (the big visual win)

**Problem it fixes:** the old grid case was `MetallicCaseView(flat: true)` — the 3D animated case locked flat, which kills its tilt-driven foil band and renders near-blank dark boxes. That is why the wall *looked* empty.

**What was built:** `DeckCaseView` was rewritten as a **fully static** composition (no `.metal` shader, no `TimelineView`, no per-frame work — cheap to scroll a whole wall):
- hue-tinted anodized metal base (top glow in the deck colorway → deep void)
- a **debossed honeycomb lattice** drawn once in a `Canvas`, masked brighter at the top (lit-from-above read)
- a cool top **catch-light**
- the **2-pass spectrum frame** (blurred glow + crisp hairline), colorway-tinted
- the **category emblem** (reuses the existing `DeckGlyph`)
- aspect ratio moved to the mockup's **1 : 1.2** tuck-box (was 2 : 3)

Each deck's `DeckStyle.colorway` (category spectrum slice + per-deck hue nudge) tints the metal + frame, so no two cases look identical.

**Design decision made without the human (review this):** the catalog is almost entirely `comingSoon` today (only `the-opener` has real cards). Graying every coming-soon case would re-create the dead-wall look. So **tiering is by `isLocked`, not `comingSoon`:**
- **available** + **coming-soon** → full vivid foil (coming-soon gets a small `SOON` tag)
- **Core-locked** (the ~3 premium decks) → the sealed/dormant treatment (desaturated + `CORE` tag + ✦ foil seal band)

**Design artifact for the morning:** `docs/prototypes/play-deck-case-options.html` — **A** (built), **B** (bold colour wash), **C** (etched mono / quiet), plus the three-tier row. Real Midnight tokens, `file://`-viewable.

**Kept:** the real animated 3D `MetallicCaseView` is still used for the detail float + ceremony only (`DeckDetailView`).

**Files:** rewrote `Vayl/Features/Play/Components/DeckCaseView.swift` (now contains the static case + a private `HexFoil` Canvas). `DeckCellView` unchanged (still calls `DeckCaseView(summary:style:)`).

---

## Segment 3 — grid honesty (empty/error state + peek)

- **Empty/error state.** The catalog `catch` set `loadError` and emptied `summaries` *silently* → a blank wall. Added `PlayStore.isEmpty` + `retry()`, a new `PlayEmptyState` view (icon + headline + sub-label + Retry CTA, per the contract — error copy when `loadError`, "no decks yet" otherwise), and a branch in `PlayView`: when `store.isEmpty`, the masthead stays and the empty state replaces hero+wall (cleaner than a blank hero over a blank grid).
- **Peek cleanup.** `DeckWallView.peek` had raw `.frame(height: 300)` + `.frame(height: 64)` fade; tokenized to `AppSpacing.xxl * 6` (~288, ~2 rows of the new 1:1.2 cases) and `AppSpacing.xxl + AppSpacing.md` (64). The cases now render rich, so the peek reads as a real shelf.

**Files:** new `Vayl/Features/Play/Components/PlayEmptyState.swift`; edited `PlayStore.swift`, `PlayView.swift`, `DeckWallView.swift`.

---

## Segment 4 — audit (safe items only)

- **Paywall wiring (was a TODO).** The locked "Unlock with Core" CTA in `DeckDetailView` used to just `closeDetail()`. It now calls `store.requestUnlock(deck)` → `PlayStore.paywallDeck` → `PlayView` presents the real `PaywallSheet(entry: .playDeck(name:))` via `.vaylSheet` (heightFraction 0.92). `PaywallSheet` already had a purpose-built `.playDeck(name:)` entry, and `EntitlementStore` is injected app-wide (`VaylApp.swift:51`), so the Play tab has it. `PlayView`'s `#Preview` now injects `EntitlementStore` too.
- **Reduce Motion.** The new static case + empty state have no animation, so they are RM-safe by construction. No new looping animations were added.

**Files:** edited `PlayStore.swift` (`paywallDeck`, `requestUnlock`, `dismissPaywall`), `DeckDetailView.swift` (CTA action), `PlayView.swift` (the `.vaylSheet` + preview env).

---

## Deferred — needs the human's eye or is out of safe scope

1. **Deck-case Option A vs B vs C** — bless or redirect (`play-deck-case-options.html`). If A is close-but-off, the Swift is parameterized enough (colorway opacities, hex columns, frame widths) to nudge quickly.
2. **Canvas pan/zoom feel** (`ZoomablePanView` true 2-axis pan) and the **hero-collapse animation** when the wall expands — both motion/feel decisions, not guessed at overnight. Still the docked-peek-then-expand model from before.
3. **Post-purchase lock reflection.** `DeckSummary.isLocked` is static catalog data; after a Core purchase the grid won't auto-unlock until `PlayStore` consults `EntitlementStore` to re-derive lock state (would mean injecting `EntitlementStore` into `PlayStore`). The paywall *presents* correctly; reflecting the unlock in the grid is the follow-up.
4. **Dead `flat` param** on `MetallicCaseView` — `DeckCaseView` was its only `flat: true` caller, so it is now dead. Left in place (removing from the shared OB component is risky and out of scope). Safe to remove later.
5. **`DeckCellView` minor raw literals** (dot sizes, `spacing: 3`) — left untouched to avoid feel changes; tokenize in a cleanup pass.

---

## Device checklist (the human verifies all of this)

**Segment 1 (top):**
- [ ] `Cards` masthead top-left, Clash + spectrum gradient + short underline, sitting just below the safe area (not crowding the island, not "too low").
- [ ] Fresh featured deck → `New deck` (cyan, sparkles) + `Not started`. Started deck → `Continue` (purple) + spectrum bar + `X of N explored`, at the real resume point. Hero must not jump height between the two.
- [ ] Tapping a card still begins/resumes (spread → lift → carousel → ceremony → session).

**Segment 2 (cases):**
- [ ] The wall reads **full and rich** — vivid, distinct, colorway-tinted foil cases, not dark boxes. Scrolling stays smooth (no per-frame cost).
- [ ] Coming-soon decks look vivid with a small `SOON` tag; the ~3 Core decks look sealed (desaturated + `CORE` + ✦ seal).
- [ ] Compare against `play-deck-case-options.html`: is Option A right, or do you want B (bolder) / C (quieter)?

**Segment 3 (honesty):**
- [ ] The peek shows ~2 rows of cases with the bottom fade; "tap the shelf" expands the full gallery.
- [ ] (Hard to hit normally) if the catalog ever fails to load, you get the empty/error state with Retry, not a blank screen.

**Segment 4 (paywall):**
- [ ] Open a **Core-locked** deck's detail (e.g. The Audit / Metamour / Unfinished Business) → tap **Unlock with Core** → the real `PaywallSheet` rises as a `.vaylSheet`. Scrim/handle dismiss returns you cleanly. (Note: completing a purchase won't visually unlock the grid yet — deferred item #3.)

---

## Build command

```
xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
```
`database is locked` = Xcode busy, retry.

## Full file manifest (Segments 1-4, this session)

- NEW `Vayl/Features/Play/Components/PlayMastheadView.swift`
- NEW `Vayl/Features/Play/Components/PlayEmptyState.swift`
- REWRITE `Vayl/Features/Play/Components/DeckCaseView.swift`
- EDIT `Vayl/Features/Play/Components/PlayHeroView.swift`
- EDIT `Vayl/Features/Play/Components/DeckWallView.swift`
- EDIT `Vayl/Features/Play/Components/DeckDetailView.swift`
- EDIT `Vayl/Features/Play/Store/PlayStore.swift`
- EDIT `Vayl/Features/Play/PlayView.swift`
- NEW `docs/prototypes/play-deck-case-options.html`

---

## Audit pass — applied (2026-06-24)

A self-review against the spec found one real bug the compiler hid, plus quality items. All fixes below are applied and compiling.

**Headline bug (was masking as "done"):** all 3 `isLocked` decks are *also* `comingSoon`, and `DeckDetailView.cta` checked `comingSoon` first → the "Unlock with Core" paywall I wired in Segment 4 was **unreachable**, and the case showed a `CORE` badge while the detail said "Coming soon" (case/detail disagreed). The original device-checklist step 4 was therefore wrong.

**Decision (human):** **locked wins.** A Core deck offers the paywall now, even though its cards are still being written (forward-looking). `DeckDetailView.cta` reordered to `isLocked` → `comingSoon` → available, which now agrees with `DeckCaseView`'s tiering. **Checklist step 4 is now valid** (The Audit / Metamour / Unfinished Business show `CORE` on the case and "Unlock with Core" in the detail). Post-purchase content/unlock is still deferred item #3.

**Quality fixes applied:**
- **Scroll perf:** `DeckCaseView` now `.drawingGroup()`-rasterizes the static case to one texture (shadow kept outside the group).
- **Dynamic Type:** the continuity bar + label use `ViewThatFits` (fold row→stack) so nothing clips at large accessibility sizes.
- **Spec gap closed:** masthead underline now carries the mockup glow via `.spectrumBorderGlow(intensity:)`.
- **Cleanup:** dropped the unused `w` param in `metalBase`; replaced token-gaming math (`AppSpacing.xxl * 6` etc.) with named constants (`peekHeight`, `peekFadeHeight`, `barWidth`, `underlineWidth`).

**Still open after the audit:** verify scroll smoothness + the locked→paywall transition + the 0.92 sheet height on device; the raw opacity/size literals in `DeckCaseView` (rendering-primitive gray area vs the contract); a11y (tappable Texts not exposed as buttons; deck cell not a single element); dead `flat` param on `MetallicCaseView`; post-purchase lock reflection (deferred #3).

---

## Model change — coming-soon retired, free vs Core (2026-06-24)

The human corrected the product model: **there is no "coming soon" at launch.** Every stub becomes a real deck, and non-free decks are **Vayl Core** (the one-time purchase unlocks them). `comingSoon` was a content-stub artifact (Play-only) and is gone.

**Tiers now:** **free starter set** = the 3 `foundationEntry` decks (The Opener, The Check-In, Boundaries); **Core** = the other 11 (`is_locked: true`, `required_entitlement: "core"`). Decision: **free starter set** + **locked cases stay vivid with a gold CORE tag** (no desaturation/seal — an enticing "what Core unlocks" gallery).

**Applied:**
- `deck-catalog.json` rewritten: 3 free + 11 Core; `coming_soon` key removed from every row.
- `DeckSummary`: `comingSoon` field removed.
- `PlayStore.resolveFeatured`: "playable" is now `!isLocked` (was `!comingSoon`), so the hero only ever features a free deck.
- `DeckCaseView`: dropped the desaturation/brightness, the ✦ seal band, and the SOON tag; locked = vivid + CORE tag. (The `tag`/`HexFoil` helpers stay.)
- `DeckDetailView`: CTA is `isLocked` → "Unlock with Core" → paywall, else "Begin"; `sealedNotice` is locked-only.
- Options board tier row updated to free-vs-Core.

**Interim content gap (known):** only The Opener has authored cards. The other 2 free decks show "Begin" but have no cards yet, so Begin does nothing until they're authored; Core decks route to the paywall (no cards needed to show it). This is the build-toward-launch state, not a bug. Builds: `BUILD SUCCEEDED`.
