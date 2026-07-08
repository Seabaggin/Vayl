# Partner Chip + Pairing — Handoff

**Date:** 2026-07-05
**Status:** 10/11 plan tasks merged and reviewed. 3 real on-device issues found in
post-merge testing, unresolved. Task 11 blocked on a concurrent session's
uncommitted work. Stopping here per Bryan's request rather than continuing to
guess at fixes — this doc is for whoever (or whichever future session) picks
this back up.

**Read first:**
- Design spec: `docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md`
- Implementation plan: `docs/superpowers/plans/2026-07-05-partner-chip-and-pairing-plan.md`
- Mockup: `docs/prototypes/partner-chip-and-pairing.html`
- Companion (not started): `docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md`

## What's actually merged and working

All 11 of the first plan's tasks landed, each spec-reviewed and code-quality-reviewed
(commits `4ffe610` through `58ad8a2`, plus two follow-up fixes `d9fdcfa`/`ba252ae`):

- Icon tokens, `UserProfile.firstInviteSentAt` lifecycle, `HomeStore`'s nudge
  threshold, `DesireMapState`/Pulse tile copy mapping — all confirmed correct by
  build + targeted unit tests (several with mutation-tested regression proof).
- The original bug (flat-grey `.active` chip avatar) — fixed, code-verified.
- Pairing sheet consolidated to one component reached from Home and Settings.
- Settings linked-state enrichment ("Paired with [name] · Since [date]"),
  consolidated into `CoupleContext` (not a bespoke store) — a real staleness bug
  was caught here (stale paired-since date surviving a same-session re-pair) and
  fixed with an empirical regression test.
- `PartnerAvatarView` (`Vayl/Design/Components/PartnerAvatarView.swift`) is the
  one shared avatar component now used by `PartnerChip`, `PartnerChipExpand`, and
  `SettingsPartnerView` — confirmed unchanged from what was reviewed, still has a
  genuine solid `LinearGradient` fill (cyan → purple → magenta), no border, no
  dimming modifier.

## Unresolved — 3 real issues from on-device testing

### 1. `PartnerChipExpand` popover renders off-screen (NOT resolved, actively wrong)

Two fix attempts landed (`d9fdcfa`, then `ba252ae` after the first was found to
have a fundamentally broken zIndex assumption — zIndex doesn't compose across
different `ZStack` containers, so the dismiss tap-catcher and the popover had to
become siblings in the same outer `ZStack` for the ordering to mean anything).
The second attempt was code-reviewed and the zIndex/hit-test reasoning was
confirmed sound by an independent pass — **but on-device testing (screenshot from
Bryan) shows the popover is still positioned wrong / off-screen.**

**Current code** (`Vayl/Features/Home/Views/HomeDashboardView.swift`, the outer
`ZStack(alignment: .top)` starting ~line 195):

```swift
if isChipExpanded, case .active = partnerChipState {
    PartnerChipExpand(...)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .offset(
            x: -(layout.screenWidth - chipFrame.maxX),
            y: chipFrame.maxY + AppSpacing.xs
        )
        .transition(.scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity))
        .zIndex(2)
}
```

`chipFrame` comes from a `ChipFrameKey` `PreferenceKey`, reported by `PartnerChip`
(deep inside `greetingBlock`, inside the `ScrollView`) via a `GeometryReader` in
the **`"homeRoot"` named coordinate space**:

```swift
.coordinateSpace(name: "homeRoot")   // line ~388, on the OUTER ZStack
.onPreferenceChange(ChipFrameKey.self) { chipFrame = $0 }
...
.frame(width: layout.screenWidth, alignment: .center)   // line ~394, applied AFTER
```

**My best current hypothesis, not yet verified**: `.coordinateSpace(name: "homeRoot")`
is declared on the outer `ZStack` **before** the later `.frame(width:
layout.screenWidth, alignment: .center)` re-centering clamp is applied in the
modifier chain. That later clamp exists specifically because of a **previously
documented, different bug** (see the comment right above it, lines 390-393): a
child was inflating the ZStack wider than the real screen and shifting everything
~13pt right, which the `.frame(width:)` clamp corrects. If the named coordinate
space is registered against the ZStack's *pre-clamp* geometry, `chipFrame`
(measured through that coordinate space) may not agree with `layout.screenWidth`
(the corrected, post-clamp value used directly in the offset math) — a subtle
mismatch between two "screen width" ideas that could easily produce a wrong `x`
offset, and depending on magnitude, push the popover partly or fully off the
visible edge.

**This is a hypothesis, not a confirmed diagnosis.** It needs actual on-device
inspection (print the real `chipFrame` value vs. `layout.screenWidth` when the
popover opens, or view it with Xcode's view debugger) to confirm before writing
another fix — two prior attempts were each individually "reasoned through" and
still wrong, so the next attempt should verify with real runtime values, not
another desk-check.

**Also worth checking**: whether `PartnerChipExpand`'s own `.frame(maxWidth: .infinity,
maxHeight: .infinity, alignment: .topTrailing)` is actually being sized against the
real screen bounds, given the outer ZStack sits inside a `ScrollView` region whose
content can be taller than the viewport — if that frame doesn't cleanly resolve to
literal on-screen pixel bounds, `.offset()` on top of it won't behave as intended
either.

### 2. Avatar/pill styling still doesn't look right on-device

Code is confirmed correct and unchanged (`PartnerAvatarView.swift` — solid
gradient fill, no stroke, no dimming modifier; `PartnerChip.swift`'s `.active`
case uses it directly with no wrapping opacity/blend modifier). On-device
screenshots show the avatar circle looking dark/muted with what reads as a
gradient **border** around the outer pill edge — not a border that exists
anywhere in this code.

**Two live hypotheses, neither confirmed:**
1. **Stale build on the test device** — asked Bryan to try a clean build
   (Product → Clean Build Folder / delete DerivedData) and re-check. Unclear if
   this has been tried yet.
2. **iOS 26 Liquid Glass material** (`.glassEffect(.regular, in: Capsule())` on
   the pill, `PartnerChip.swift` `.active` case) may be compositing/desaturating
   content underneath it as a system rendering effect, not something visible by
   reading source. If a clean build doesn't fix it, the likely next step is
   rendering the avatar as a separate `.overlay()` layered *above* the glass
   material rather than as normal content subject to whatever vibrancy/blur pass
   the system applies — but this needs on-device confirmation of the actual
   cause first, not a blind swap.

### 3. Debug HUD panel visually overlapping content — confirmed pre-existing, NOT caused by this work

Traced to `debugControls(store:layout:)` in `Vayl/Features/Home/Views/HomeRouterView.swift`
(lines ~330-374), wired as `.overlay(alignment: .bottomTrailing)` on `routedContent`
(line ~181). It's `#if DEBUG`-gated only — always visible in any DEBUG build,
unconditionally, no launch-arg gate. It sits in `HomeRouterView`'s tree via
`.overlay`, structurally outside `HomeDashboardView`'s own subtree — confirmed via
git-blame that neither the `d9fdcfa` nor `ba252ae` commits touched anything near
it. **This is not a regression from this plan's work** — it's pre-existing dev
tooling that happened to be visible in the screenshots. If it's genuinely getting
in the way now, that's a separate, small follow-up (gate it more tightly or
reposition it), unrelated to the partner-chip feature.

## Task 11 — code done, commit blocked

`SettingsView.swift`'s `partnerSection` duplication has already been consolidated
(the working-tree diff exists, verified to build). It hasn't been committed
because the same file also has an **unrelated, uncommitted refactor** from a
concurrent session (`isTab` removal / `SettingsGearButton` migration) mixed into
its working-tree diff. Bryan asked to wait for that session to commit first
rather than bundle or split the diff. As of this handoff, `git status --short` on
`Vayl/Features/Settings/SettingsView.swift` and `SettingsComponents.swift` still
shows both dirty; the concurrent session's recent commits are all unrelated
(Pulse/Map/desire-map work), so there's no signal on when/whether it'll land.

**To finish Task 11**: check `git status`/`git diff` on those two files; once the
concurrent session's `isTab` work is committed (or if Bryan decides to proceed
another way), the Task 11 consolidation diff should isolate cleanly and can be
committed with message `refactor(settings): consolidate partnerSection's
invite/join rows onto the shared pairing sheet`, then spec + code-quality
reviewed per the pattern used for every other task in this plan.

## Deep-link plan — not started

`docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md` (the "Send the app
instead" Universal Links capability) has not been touched at all. Genuinely
independent of everything above.

## Process notes for whoever continues this

- This session shares a git working tree with at least one other active session
  (no worktree isolation — a deliberate choice Bryan made). Always `git status
  --short` before staging anything, and only `git add <exact path>` — never `-A`
  or a bare `.`. This caught real problems twice already (one cross-contaminated
  commit, one undisclosed scope-add) before this handoff.
- Two "the code reasoning is sound" reviews on the popover positioning turned out
  to still be wrong on-device. Treat any further fix attempt here with real
  skepticism of desk-checked SwiftUI layout math — verify with actual runtime
  values (print statements, Xcode's view/layout debugger) before calling it done,
  not just another read-through.
