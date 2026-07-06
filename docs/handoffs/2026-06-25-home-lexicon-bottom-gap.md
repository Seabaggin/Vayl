# Handoff: persistent gap between the Home Lexicon and the tab bar

**Status:** ✅ RESOLVED 2026-06-26. Root cause found by measuring on a booted iPhone 17 Pro
simulator (not the preview). Two compounding bugs; both fixed. See "Resolution" below.
**Scope:** Home tab only. Do not change other tabs, the OB flow, or the session/cover code.

---

## Resolution (2026-06-26)

The "screen-level gap" framing was a misdiagnosis. Measured on device, the column already
filled the screen — a content-bottom marker landed 2.7pt from the physical bottom. There were
**two compounding bugs**, neither of which the preview revealed:

**Bug 1 — the Lexicon pager was stuck at its 268pt fallback (the real visible gap).**
`HomeLexicon`'s adaptive `pageHeights` measurement was defeated: every page view
(`heroWord`/`sentence`/`culture`) ended with `Spacer(minLength: 0)`, which *flexed to fill*
the 268pt pager frame during measurement, so each page reported 268 instead of its true
~130pt content height. The pager never shrank → ~136pt of dead space sat below the CTA, where
the tab bar floats, reading as "the Lexicon floats with dead space beneath it." This is
exactly the internal-gap fix the prior session thought it had landed; it never worked.
**Fix:** removed the trailing `Spacer(minLength: 0)` from all three page kinds. Each page now
reports its natural height, and the pager animates to the current item's true height.

**Bug 2 — `safeContentH` double-subtracted the safe-area insets (a latent bug that masked Bug 1's fix).**
Measured: this GeometryReader (`HomeDashboardView`'s, nested inside `HomeRouterView`'s) reports
`geo.size.height` = **698** (already the safe-area-reduced viewport: full 874 − top 62 − bottom 114),
yet `geo.safeAreaInsets` still reports the non-zero **62 / 114**. The old
`screenHeight − insets.top − insets.bottom` subtracted them a *second* time → `minHeight` = 522,
**176pt shorter than the real viewport (698)**. It never visibly mattered before because the
inflated Lexicon made content (794) exceed even 522, so the floor never bound. After Bug 1's
fix shrank content below the viewport, the correct floor became load-bearing.
**Fix:** `let safeContentH = layout.screenHeight` (the GR already excludes the insets; the
viewport *is* `screenHeight`). The flexible hero `Spacer` then binds and bottom-anchors the
Lexicon just above the bar — verified to flex by probing `minHeight = screenHeight + 150`
(the column stretched). Confirmed the Spacer *does* flex when `minHeight` > content; the prior
session's "Spacer may not flex" doubt came from only ever testing the case where content > floor.

**Both fixes are required** — the Lexicon fix alone underfills for short pages; the
`safeContentH` fix alone does nothing while the Lexicon is inflated. Together the column
bottom-anchors the Lexicon just above the bar across all page heights (verified on a short
culture quote and a tall research finding; expanded-Pulse state scrolls correctly).

Files changed: `Vayl/Features/Home/Components/HomeLexicon.swift` (removed 3 spacers; `pageHeight`
re-commented as a first-frame fallback only, lowered 268→180), `Vayl/Features/Home/Views/HomeDashboardView.swift`
(`safeContentH`). The tab-bar `safeAreaInset` refactor was untouched.

**Open feel-tune (for Bryan, on device):** the Lexicon now rests right at the safe-area edge
(~14pt above the pill). If that reads too tight, subtract a token from the floor, e.g.
`safeContentH = layout.screenHeight - AppSpacing.xl`, to lift it a touch.

---

## The problem (one sentence)

On the Home screen, there is a visible empty gap between the bottom of the **Lexicon** (the daily "From the Research" word/quote block, its CTA is the lowest element) and the top of the floating **tab bar**. The Lexicon should sit just above the tab bar; instead it floats with dead space beneath it.

It has shown up in several forms across the session and has never fully gone away. The most recent screenshot still shows the gap in the **collapsed** Pulse state (deck card up top, "The Sovereign Space" collapsed Pulse, then the Lexicon quote, then a gap, then the tab bar).

---

## What the Home screen is

`Vayl/Features/Home/Views/HomeDashboardView.swift` renders, top to bottom, inside a single `ScrollView`:

1. **Greeting** ("VAYL." wordmark + partner chip) — sometimes a "Getting Started" card on day 1.
2. **The Deck** — `CardCarousel`, a hero card ("What are the anchors…").
3. **A void** (the "hero isolation").
4. **The Pulse** — `HomePulseRail` (`Vayl/Features/Home/Components/HomePulseRail.swift`): a title ("The Sovereign Space"), a "+" check-in button, an "i" info button, and a spectrum line **graph**. The graph is **collapsed by default**; tapping the rail toggles `pulseExpanded` and the graph animates open.
5. **A gap.**
6. **The Lexicon** — `HomeLexicon` (`Vayl/Features/Home/Components/HomeLexicon.swift`): a static "FROM THE RESEARCH" overline + a **horizontal auto-advancing carousel** of daily items. Item kinds are research / term / sentence / culture, and **each item is a different height** (a punchy stat vs a long research finding vs a multi-line quote). It auto-advances every 12s and can be swiped. Its lowest element is a CTA ("SEE THE RESEARCH →", "EXPLORE IN LEARN →", etc.).

The Lexicon is the **last element** in the scroll column.

## The tab bar

`RacetrackTabBar` (`Vayl/Design/Components/Navigation/RacetrackTabBar.swift`) is a floating pill. It is attached in `Vayl/App/AppShell.swift` via:

```swift
.safeAreaInset(edge: .bottom, spacing: 0) {
    RacetrackTabBar(selection: $selectedTab)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
}
```

Because it's a `safeAreaInset`, the bar's height **is part of `safeAreaInsets.bottom`** for the tab content. So any view inside Home reads `layout.safeAreaInsets.bottom` = home indicator + tab bar. `TabContentWrapper` (`Vayl/Design/Components/Navigation/TabContentWrapper.swift`) is now a near-passthrough (Home passes `fade: false`).

---

## Current code state (the parts that matter)

In `HomeDashboardView.body`, inside `GeometryReader { geo in let layout = AppLayout.from(geo) … }`:

```swift
let heroIsolation = layout.screenHeight * 0.12
let safeContentH  = layout.screenHeight - layout.safeAreaInsets.top - layout.safeAreaInsets.bottom
let maxGraphHeight = layout.screenHeight * 0.38   // graph height when expanded
let expansion = pulseExpanded ? 1.0 : 0.0
```

The column:

```swift
ScrollView {
    VStack(spacing: 0) {
        greetingBlock
        // optional GettingStartedEntryCard
        Color.clear.frame(height: layout.screenHeight * 0.04)   // top void
        CardCarousel(…)                                          // the deck
        Spacer(minLength: heroIsolation)                         // FLEXIBLE hero void
        pulseModule(expansion: expansion, maxGraphHeight: maxGraphHeight, …)
        Color.clear.frame(height: layout.screenHeight * 0.06)   // gap
        lexiconModule
    }
    .padding(.horizontal, AppSpacing.lg)
    .padding(.top, AppSpacing.md)
    .frame(maxWidth: .infinity, minHeight: safeContentH, alignment: .top)
}
.scrollIndicators(.hidden)
```

The intent of the last two lines: fill the visible area (`minHeight: safeContentH`) so the flexible `Spacer` takes the slack and pushes the Pulse + Lexicon to the bottom (collapsed). When the graph expands and the content exceeds one screen, the Spacer collapses to its min and the ScrollView scrolls. **This does not currently remove the gap.**

`HomeLexicon` pager: each page is now its **own content height** (no fixed page frame), measured via a `PageHeightKey` preference, and the pager sizes to `pageHeights[index]` (animated). This was added to kill a *separate* gap (a fixed 268pt page height left empty space under short items' CTAs). That internal-gap fix may or may not be working; the screen-level gap persists regardless.

---

## History — what has been tried (so it isn't repeated)

The Pulse graph reveal went through a long evolution. Knowing the dead ends matters:

1. **Scroll-driven reveal (abandoned).** Originally the graph grew as you scrolled, pushing the Lexicon down. This produced a "warp" (the Lexicon was pinned while the rest scrolled → the screen appeared to scissor) and a gap below the Lexicon. Many variants were tried and rejected: reserve-a-fixed-slot + opacity fade ("awful, doesn't look like a reveal"); two-phase "expand then scroll"; bounded concurrent grow; a `ScrollTargetBehavior` snap to two positions; deriving the graph height from the safe area with hand-tuned reserves. Each fixed one symptom and exposed another. The whole scroll-driven approach was eventually **abandoned**. (See memory `pulse_reveal_must_grow`.)

2. **Tab bar refactor (kept, good).** The tab bar used to be a `ZStack` overlay with hardcoded clearance (`TabContentWrapper` had `.contentMargins(.bottom, 62 + …)` with a guessed bar height that drifted). It was moved to `.safeAreaInset(edge: .bottom)` so clearance is automatic and `safeAreaInsets.bottom` includes the bar. This is a real improvement and should stay. (See memory `tab_bar_safe_area_refactor`, CLAUDE.md "Safe Area & Tab Bar Contract".)

3. **Pivot to tap-to-expand (current).** All scroll-reveal machinery (`scrollY`, `onScrollGeometryChange`, the snap, the `minHeight: screenHeight + expandRange` floor, the derived fit constants) was deleted. The Pulse is collapsed by default; tapping expands the graph. The home became a plain `ScrollView`.

4. **Adaptive Lexicon page height (current).** Fixed the carousel's fixed-page-height internal gap by measuring each page.

5. **`minHeight: safeContentH` + flexible hero `Spacer` (current).** Added to anchor the Lexicon at the bottom in the collapsed state. **This is the latest attempt and the gap still shows.**

---

## Important caveats for whoever takes this

- **Verification has been almost entirely in the Xcode canvas PREVIEW**, not a simulator run or device. The screenshots are the Xcode preview pane. The preview's safe-area handling (and how `safeAreaInset` + `GeometryReader` resolve there) may differ from a real device, so the gap seen in the preview may not equal the gap on-device, and `safeContentH` may resolve differently. **Confirm the symptom on a booted simulator / device before trusting it.**
- It is unverified whether, in this context, `layout.screenHeight` (= `geo.size.height` from `AppLayout.from(geo)`) is the **full** screen height or an inset height, and whether `safeAreaInsets.bottom` actually includes the bar at the point where `safeContentH` is computed. The whole `minHeight: safeContentH` fix rests on those being what we assume.
- It is unverified whether the flexible `Spacer(minLength:)` actually flexes inside a `ScrollView` with a `minHeight` frame, or whether it collapses to its minimum (in which case the column never fills and the Lexicon floats).
- The "gap" has had **two distinct sources** at different times (the carousel's fixed page height; the column not filling the screen). It is possible the remaining gap is a third thing, or one of those two not actually fixed.
- The build compiles (`xcodebuild -scheme Vayl … build` succeeds). This is a layout/visual problem, not a compile problem.

## Reproduction

Run Home (`#Preview("Home — Linked")` in `AppShell.swift`, or boot the app to the Home tab). Pulse collapsed. Observe the space between the Lexicon's CTA and the floating tab bar. Cycle the Lexicon (it auto-advances) and try the expanded state too (tap the Pulse rail).

## Files

- `Vayl/Features/Home/Views/HomeDashboardView.swift` — the screen + the column + `pulseModule`.
- `Vayl/Features/Home/Components/HomeLexicon.swift` — the carousel (adaptive page height, `PageHeightKey`).
- `Vayl/Features/Home/Components/HomePulseRail.swift` — the Pulse rail + graph (`expansion` drives height/opacity).
- `Vayl/App/AppShell.swift` — the tab bar `safeAreaInset`.
- `Vayl/Design/Components/Navigation/TabContentWrapper.swift` — passthrough + optional fade.
- `Vayl/App/Theme/AppLayout.swift`, `AppSafeArea.swift` — geometry + safe-area helpers.

Memory: `pulse_reveal_must_grow`, `tab_bar_safe_area_refactor`, `home_dashboard_redesign`.
