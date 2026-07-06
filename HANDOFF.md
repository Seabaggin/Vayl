# Handoff — Home deck / card carousel

Date: 2026-06-22
Status: **Mostly final.** One task remains (see "Next task"), to start in the next chat.

(Replaces an older 2026-05-30 OB Compass/Context handoff — recoverable from git history.)

---

## What it is (the interaction)

The Home "deck" is the floating card. Tapping it makes the deck **elevate in place**
(no cover, nothing slides up): it spreads → lifts → becomes a browsable carousel,
and the rest of Home fades softly behind it. Tapping a card **adds it to tonight's
hand** (check badge + a card flies to the corner pile). A **"Settle in · N →"** bar
at the bottom carries the hand into the session.

Phase sequence (owned by `CardCarousel`): `floating → spread → lifted → carousel`.

---

## Architecture (where things live)

- **`Vayl/Design/Components/Cards/CardCarousel.swift`** — the real, in-place elevating
  deck. It owns the floating card, the spread/lift/carousel physics, the **screen dim**
  (a 3000×3000 `.background` rectangle that fades in — this is what "envelops the
  screen"; there is **no** `fullScreenCover`, because a cover always slides up), the
  swipe/drag, the fly-to-corner ghost, and selecting-mode (`onToggleSelect`).
  - The only change made here is an **additive** `dimOpacity: Double?` param
    (default `nil` = original behavior). OB phases use a **different** component
    (`VaylCardCarousel`), so `CardCarousel` is Home-only and safe to touch.
  - The "tap to add" hint sits **below** the card (`selectHint` overlay, `.offset(y: 30)`).
- **`Vayl/Features/Home/Views/HomeDashboardView.swift`** — owns the deck *state* and
  *chrome*:
  - `@State deckPhase` (from `CardCarousel.onPhaseChange`)
  - `@State handIDs: [String]` — tonight's hand
  - `@State deckReset: Int` — bumped on settle to rebuild the carousel back to floating
  - `deckEngaged` = `deckPhase != .floating && != .spread` → drives the room recede
  - `deckChrome(layout:)` — the corner "tonight" deck (explicitly `.position`ed,
    top-right) + the "Settle in" bar (bottom)
  - `toggleHand(_:)`, `settleIn()` (sets `sessionHand` → the `.vaylCover` session)
- **`Vayl/Features/Home/Components/CardChestContainer.swift`** — collapsed to just
  `NoiseTexture` (the old chest reinventions were deleted).

---

## Tunable dials (current values)

| Thing | Where | Value |
|---|---|---|
| Screen dim when open | `HomeDashboardView` → `CardCarousel(dimOpacity:)` | `0.15` |
| Room fade (greeting + Pulse/Lexicon) | `HomeDashboardView` | `opacity 0.25`, `blur 6` |
| Corner deck position | `deckChrome` → `cornerDeck.position(...)` | `x: screenWidth - 48`, `y: safeTop + 24` |
| "tap to add" offset below card | `CardCarousel.carouselCard` | `.offset(y: 30)` |

---

## Carryover — DONE (2026-06-22), awaiting device feel

**Clicking out of the carousel now CLEARS tonight's hand (start over).** Implemented
in `HomeDashboardView`'s `CardCarousel.onPhaseChange` (`if phase == .floating { handIDs = [] }`).
Build-verified. Device check: add a card → tap out → reopen should show an empty hand
+ empty corner pile.

---

## Home look-refinement (in progress, 2026-06-22)

Focus shifted from the deck (settled) to the **resting Home** look. Bar: "vibrant but
measured, premium iOS, with my own flair." Working mode: full spec → approve → build →
Bryan feel-checks on device.

**Composition pass — BUILT (awaiting device feel).** Replaced the top-stacked column
(all slack pooled in one bottom Spacer = dead space) with a **floated-block rhythm**:
header pinned top; hero + Pulse + Lexicon float as ONE group centered in the void below
the header (two equal flex `Spacer(minLength: lg)` top & bottom share the leftover
height). Two FIXED internal gaps encode the hierarchy on every device:
`heroIsolation = screenHeight * 0.085` (the deck's "sun" void) and
`horizonVoid = screenHeight * 0.060` (Pulse → Lexicon separator, replaces the old uniform
`xl` spacing). `lowerModules` is now `lowerModules(horizonVoid:)`. All values dial-able.
Files: only `HomeDashboardView.swift`.

**Depth-ontology hierarchy — BUILT (awaiting device feel).** Organizing principle for
making Pulse/Lexicon 2nd/3rd fiddle WITHOUT muting them: hierarchy by DEPTH + ANIMACY,
not opacity. Three layers — (1) hero = OBJECT above the surface (border+shadow+lift+
pedestal+float; the ONLY element allowed a border/drop-shadow), (2) Pulse = LIGHT in the
surface (no border/shadow/lift), (3) Lexicon = TYPE on the surface (flat, can be richly
set). A floating object beats a flat glow regardless of brightness, so secondaries keep
full detail. The earlier "axis collision" is now INTENTIONAL (layers may hold different
axes). Hero sole-object audit = CLEAN.

**Pulse redesign — BUILT (`HomePulseRail` only; PulseWidget/PulseGraph untouched).**
Dissolved the widget chrome (no "THE PULSE" overline / chevron / bold title). Graph LEADS
+ an `AreaShape` melts the line down into the atmosphere bloom (purple→clear). Quick
reference = the current `PulseTier` (`.label` + `.sublabel`, e.g. "The Sovereign Space /
Grounded · Secure") from the user's LATEST real check-in; 0 entries → "Check in to begin"
(no faked Space). Ember is state-aware (`EmberNode(inviting:)` = hollow ring when today
is unchecked, filled when checked-in-today). Worded "CHECK IN →" affordance when
!checkedInToday.

**Check-in routing — interim wired, shared sheet DEFERRED to the PulseWidget pass.**
Bryan's intent: both Home AND Map open the SAME check-in sheet IN PLACE (no tab-yank) =
"what DailyCheckIn will become". `onCheckIn` callback added
(HomePulseRail→HomeDashboardView→HomeRouterView); interim routes to `.map`. Swap to the
in-place shared sheet when it exists. `CheckInShell` is coupled to PulseWidget (camera
bindings + PulseGraph + onComplete) so cannot be hosted from Home this session.

**Optional remaining tune:** a NEW `.home` AtmosphereConfig to peak the bloom behind the
Pulse (NEVER mutate `.stat`; shared with OB StatPhase + LearnView). NOT built on purpose:
atmosphere is a feel value, not a guess (the old custom HomeAtmosphere read flat), and
the vibrancy-inversion is largely resolved already (lively Pulse now lives in the bloom,
calm Lexicon in its tail). Tune from a screenshot if wanted.

### Resting-Home tensions — status
1. ~~Axis collision~~ — resolved by the depth ontology (intentional layer axes).
2. ~~Vertical rhythm / dead space~~ — composition pass.
3. ~~Lower modules different quiet-languages~~ — Pulse chrome dissolved (now light).
4. ~~Vibrancy inverted~~ — largely resolved (Pulse-in-bloom); optional `.home` tune remains.

---

## Deferred / watch items

- **Pedestal light-strip** (the `home-final` "pedestal of light" under the resting
  card) was dropped — `CardCarousel` brings its own aurora glow. Re-add if wanted.
- **Fly-to-corner ghost** flies to a fixed point in `CardCarousel`
  (`.offset(x: 130, y: -40 + progress * -150)`). The corner deck is now pinned at
  `(screenWidth - 48, safeTop + 24)`. If the ghost doesn't land on the deck, line up
  the ghost target to that spot.
- **Greeting dim** relies on the carousel backdrop + the explicit fade; confirm it
  reads consistently with the Pulse/Lexicon fade.

---

## Constraints honored

- `RacetrackTabBar` — untouched.
- `PulseWidget` / `PulseGraph` (the real pulse instrument) — untouched. The Home Pulse
  rail is a separate lightweight component.
- `CardCarousel` — only an additive `dimOpacity` param; OB (which uses
  `VaylCardCarousel`) is unaffected.

Spec (superseded by the `CardCarousel` approach, but states/decisions still hold):
`docs/superpowers/specs/2026-06-22-deck-punch-out-design.md`.
