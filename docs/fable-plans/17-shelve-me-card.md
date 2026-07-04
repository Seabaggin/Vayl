# 17 — Shelve the Me Card (playing-card identity feature)

**Goal:** Remove the "Your card" (Me Card / Flavor identity) section from the Map tab's Me
layer so it stops occupying the slot `docs/prototypes/map-layout-blocking.html`'s three-pillar
layout (Now=Pulse / Forward=Path / Kept=Vault) needs for Plan 20's Path feature. No backend
change — this feature never had one.

---

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

## Context Fable needs

- **What it is:** an identity/flavor "card" (`MeCardCompact` + `MeCardSheet`) letting the user pick a
  `Flavor` (e.g. `.explorer`) and a title, plus a "Drawn to" tag list derived from Desire Map ratings.
  It renders in `MapView.meLayer` under the eyebrow "Your card". There is **no Us/paired version** —
  `CoupleCrestSigil`/`CoupleCrestPortrait` in `Vayl/Features/Map/Components/FlavorVisuals.swift:104-142`
  are unused dead scaffolding for a couple card that was never built.
- **Why it's being shelved:** `docs/prototypes/map-layout-blocking.html` (the target Map skeleton both
  Plan 12 and Plan 20 build toward) defines exactly three pillars for both Me and Us — **Now (Pulse) /
  Forward (Path) / Kept (Vault)** — with no card/identity pillar at all. It isn't deferred within that
  layout; it's simply absent. `docs/superpowers/specs/2026-06-27-couple-path-roadmap-design.md` §14 also
  states the Me Card / identity Flavor work "stays shelved and separate" as an explicit non-goal.
- **Known tension to flag, not silently resolve:** `docs/fable-plans/12-map-dashboard-me-layer.md`
  Segment 3 actively *deepens* the Me Card (reword the eyebrow, add an empty-state hint, harden saves).
  If Plan 12 already ran before this plan, its Seg 3 work becomes dead code the moment this plan lands
  — that's fine (nothing breaks), but **do not re-run Plan 12 Seg 3 after this plan**, and if Plan 12
  hasn't run yet, skip its Seg 3 entirely. See Open Decisions.
- **Backend:** none. `flavor`/`chosenTitle` are local-only `UserProfile` columns (SwiftData), no
  Supabase migration touches them. This is a pure View-layer change.
- **The Record is unaffected.** `MapRecord(sessions:shares:)` (`MapView.swift:203`) is a separate
  section slated to move *inside* the Vault later (a different, future refactor) — do not touch it here.

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Vayl/Features/Map/MapView.swift` | Remove the "Your card" section, `showMeCard` state, and its `.vaylSheet` |
| Leave as-is (no changes) | `MapStore.swift`, `MeCardCompact.swift`, `MeCardSheet.swift`, `Flavor.swift`, `FlavorVisuals.swift`, `UserProfile.flavor`/`.chosenTitle` | Dead but harmless — see Constraints |

No deletions in this plan. Deleting the now-unreferenced files is a separate future cleanup pass (like
Plan 01's dead-code purge), not part of shelving.

---

## Build steps

### Step 1 — Remove the section from `meLayer`

Current (`MapView.swift:193-206`):

```swift
private var meLayer: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        MapPulseHero(
            onCheckIn: { startCheckIn() },
            onOpenHistory: { showPulseSheet = true }
        )
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Your card")
            MeCardCompact(card: store.meCard, onTap: { showMeCard = true })
        }
        MapRecord(sessions: store.sessions, shares: store.categoryShares)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

Replace with:

```swift
private var meLayer: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        MapPulseHero(
            onCheckIn: { startCheckIn() },
            onOpenHistory: { showPulseSheet = true }
        )
        MapRecord(sessions: store.sessions, shares: store.categoryShares)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

*Done: `meLayer` no longer references `MeCardCompact` or `store.meCard`.*

### Step 2 — Remove the sheet presentation and its state

Delete the `showMeCard` declaration (`MapView.swift:26`):

```swift
@State private var showMeCard = false
```

Delete the sheet block (`MapView.swift:80-90`):

```swift
.vaylSheet(
    isPresented: $showMeCard,
    heightFraction: 0.9,
    screenHeight: layout.screenHeight
) {
    MeCardSheet(
        card: store.meCard,
        onChooseTitle: { store.setTitle($0, context: modelContext) },
        onChooseFlavor: { store.setFlavor($0, context: modelContext) }
    )
}
```

*Done: `MapView.swift` no longer references `MeCardSheet`, `showMeCard`, `setTitle`, or `setFlavor`.*

---

## Definition of Done (build-green)

- [ ] `MapView.swift` compiles with zero references to `MeCardCompact`, `MeCardSheet`, `showMeCard`,
      `store.meCard`, `store.setFlavor`, `store.setTitle`.
- [ ] `meLayer` renders Pulse hero → Record, with no gap or dead space where the card used to sit.
- [ ] `MapStore.swift`, `MeCardCompact.swift`, `MeCardSheet.swift`, `Flavor.swift`, `FlavorVisuals.swift`
      are untouched and still compile (they're just unreferenced from `MapView` now).
- [ ] No raw literals introduced; `meLayer`'s spacing is still `AppSpacing.xl`.

## Bryan verifies on device

- Open the Map tab, Me layer: confirm the Pulse hero flows straight into the Record with sensible
  spacing, no visible seam where the card was.
- Confirm nothing else on Home/Onboarding/Desire Map referenced the Me Card (it shouldn't — this was
  Map-tab-only per the audit) — a quick skim of the app is enough, not an exhaustive test pass.

## Constraints / do-not-touch

- Do not delete `MeCardCompact.swift`, `MeCardSheet.swift`, `Flavor.swift`, `FlavorVisuals.swift`, or the
  `MapStore` card-related code (`meCard`, `loadMeCard`, `drawnTags`, `setFlavor`, `setTitle`, lines
  55-226 and 278-294) in this plan. Leaving them dead in the tree is intentional — a future dead-code
  pass (à la Plan 01) can remove them once Bryan confirms the feature is truly gone for good, not just
  post-launch.
- Do not touch `MapRecord`, `MapPulseHero`, or `MapStore.loadRecord`/`loadPulse`-adjacent code — out of
  scope for this plan.
- Do not touch `UserProfile.flavor`/`.chosenTitle` (SwiftData schema) — no migration needed either
  direction.

## Open decisions

1. **Plan 12 Segment 3 overlap.** Plan 12 deepens the Me Card (eyebrow reword, empty-state hint,
   `saveWithLogging()` hardening) in the same area this plan removes. **Recommended default: skip Plan
   12 Seg 3 entirely if it hasn't run yet; if it already ran, this plan's removal simply makes that work
   dead code — no action needed, don't revert it.** Either way, run this plan (17) after or instead of
   Plan 12 Seg 3, never before it expecting Seg 3 to still apply.
2. **Delete vs. leave dead.** Recommended default: leave dead (per Constraints) — deleting is a separate,
   lower-risk pass once Bryan is certain the feature won't return in a different form post-launch.
