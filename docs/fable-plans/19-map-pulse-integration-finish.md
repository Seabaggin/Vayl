# 19 — Map Pulse Integration Finish (Pulse Phase E + "Your Map" time-window)

**Goal:** Close the one real remaining visual-fidelity gap between the Pulse mockups and the Map tab
— the "your map" time-window markers on the Me layer's field sheet — and confirm (not re-fix) everything
else the 2026-06-28 mockup-vs-impl audit flagged, most of which has already been fixed in code since
that audit ran. Depends on Plan 18 (needs `AppAnimation.pulseBallDrift` to exist) and coordinates with
Plan 14 (Us partner data — this plan does not duplicate it).

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

- **The 2026-06-28 audit (`docs/audits/2026-06-28-pulse-mockup-vs-impl-RESULTS.md`) is now mostly
  stale — re-verified against source on 2026-07-01. Do not re-fix any of these; they're already done:**
  - **C2 (zone palette split)** — already fixed. `PulseField.zones` (`PulseField.swift:56-59`) reads
    `AppColors.auraCoreRose/Magenta/Indigo/Cyan` — the same ramp the auras use — not the `pulseTier*`
    tokens the audit flagged.
  - **C3 (eyebrow gray instead of purple-light)** — already fixed on Map (`MapPulseHero.swift:80` uses
    `AppColors.textSectionLabel`, which resolves to purple-tinted, not `textTertiary`) and on Home
    (`HomePulseRail.swift` uses the same token, from this session's widget rebuild).
  - **S2-1 (capsule halo missing)** — already fixed. `PulseCapsule.swift:72` casts
    `AppColors.pulseCapsuleGlow` (`AppColors.swift:730`, periwinkle at 0.18 alpha) — matches the mockup's
    `rgba(130,160,230,.18)` almost exactly.
  - **S2-2 (fixed 44pt aura on a flexing field)** — already fixed. `MapUsLayer.swift:87` computes
    `auraSize = size * 0.177`, matching the mockup's 44/248 ratio proportionally.
  - **G1 (glass-sweep cadence 17s vs 8.5s)** — already correct. `AppAnimation.swift:811`:
    `auraGlassSweep: Double = 8.5`.
  - **S1-3 (quadrant label size/opacity/position)** — the audit itself flagged this as a **deliberate
    post-mockup decision** (commit `0ae99ec`), not a bug. Leave as-is.
- **The one gap still real: S1-1, "your map" time-window markers.** `MapFieldSheet`
  (`MapPulseHero.swift:124-204`) renders only the single current-position aura + read/desc copy — no
  echo of where you were 1 week / 1 month / 3 months ago, no dashed connector, no "Now" tag. This is the
  one item this plan actually builds.
- **Canonical pattern to imitate:** `PulseHistory.swift`'s carry-forward style (`pairedLastLogged`,
  lines 29-45) — "nearest entry on or before a cutoff date" — is the exact shape needed for "nearest
  entry ≥7/30/90 days ago." `PulseField`'s own `fieldPoint(for:in:)` (`PulseField.swift:129-134`) is the
  coordinate mapping every marker must replicate (openness → x, `1 - energy` → y) — this mapping is
  already independently duplicated in `PulseCapsule.swift:33-38` and `MapUsLayer.swift` (not shared via a
  helper anywhere in the codebase today) — follow that existing convention, don't introduce a new shared
  helper as part of this plan.

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Vayl/Features/Map/Components/MapPulseHero.swift` | Add time-window markers + dashed connector + "Now" tag to `MapFieldSheet` |
| Modify | `Vayl/Core/Models/PulseHistory.swift` | Add the nearest-prior-entry helper `nearestOnOrBefore` |

No other files change. This plan does not touch `MapUsLayer.swift`, `PulseCapsule.swift`, `PulseField.swift`,
or any Home surface — everything else the audit flagged is already fixed.

---

## Build steps

### Step 1 — Add the nearest-prior-entry helper

Add to `PulseHistory.swift`, alongside the existing functions:

```swift
/// The entry nearest to (on or before) `daysAgo` days before now — the same carry-forward
/// shape as `pairedLastLogged`, applied to a single time offset instead of a partner's stream.
/// nil if there's no entry that old yet.
static func nearestOnOrBefore(_ entries: [PulseEntry], daysAgo: Int, now: Date = Date()) -> PulseEntry? {
    guard let cutoff = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }
    return entries.last { $0.date <= cutoff }
}
```

*Done: `PulseHistory` has a single-stream time-offset lookup, mirroring the existing paired one.*

### Step 2 — Build the markers in `MapFieldSheet`

`MapFieldSheet` currently takes only `position`/`quadrant` (`MapPulseHero.swift:124-126`). Thread the
full entries array in from the caller. First, change `MapPulseHero.body`'s cover presentation
(`MapPulseHero.swift:67-69`):

```swift
.vaylCover(isPresented: $showMap, confirmOnExit: false) {
    MapFieldSheet(entries: pulse.entries, position: currentPosition, quadrant: currentQuadrant)
}
```

Then in `MapFieldSheet`, add the property and the marker model (`MapPulseHero.swift`, private struct
starting line 124):

```swift
private struct MapFieldSheet: View {
    let entries: [PulseEntry]
    let position: PulsePosition
    let quadrant: PulseQuadrant

    @Environment(\.vaylDismiss) private var dismiss

    /// One faded echo of a past reading on the way to "Now". 🎚️ FEEL: sizes/opacities below
    /// mirror the mockup's own spec (map-pulse-final.html) — confirm on device, don't re-derive.
    private struct TimeWindowMarker: Identifiable {
        let id: String
        let position: PulsePosition
        let dotSize: CGFloat
        let opacity: Double
    }

    private var timeWindowMarkers: [TimeWindowMarker] {
        var markers: [TimeWindowMarker] = []
        if let w = PulseHistory.nearestOnOrBefore(entries, daysAgo: 7) {
            markers.append(.init(id: "1w", position: w.resolvedPosition, dotSize: 10, opacity: 0.78))
        }
        if let m = PulseHistory.nearestOnOrBefore(entries, daysAgo: 30) {
            markers.append(.init(id: "1m", position: m.resolvedPosition, dotSize: 8, opacity: 0.50))
        }
        if let q = PulseHistory.nearestOnOrBefore(entries, daysAgo: 90) {
            markers.append(.init(id: "3m", position: q.resolvedPosition, dotSize: 6, opacity: 0.30))
        }
        return markers
    }

    /// Same coordinate mapping as PulseField.fieldPoint — replicated per-file, matching the
    /// existing convention in PulseCapsule.swift and MapUsLayer.swift.
    private func fieldPoint(for pos: PulsePosition, in size: CGFloat) -> CGPoint {
        CGPoint(x: pos.openness * size, y: (1 - pos.energy) * size)
    }
```

### Step 3 — Render the connector + dots + "Now" tag over the field

Replace the `PulseField(...)` call in `MapFieldSheet.body` (`MapPulseHero.swift:141-145`) with an
overlay that draws the trail underneath the existing field:

```swift
ZStack {
    PulseField(
        entries: [PulseFieldEntry(position: position, auraSize: 60)],
        size: w,
        showAxisLabels: true
    )
    timeWindowOverlay(fieldSize: w)
}
.padding(.top, layout.safeAreaInsets.top + AppSpacing.xl)
```

Add the overlay builder:

```swift
@ViewBuilder
private func timeWindowOverlay(fieldSize: CGFloat) -> some View {
    let markers = timeWindowMarkers
    let trail = (markers.reversed() + [TimeWindowMarker(id: "now", position: position, dotSize: 0, opacity: 0)])
        .map { fieldPoint(for: $0.position, in: fieldSize) }

    if trail.count > 1 {
        Path { path in
            path.move(to: trail[0])
            for point in trail.dropFirst() { path.addLine(to: point) }
        }
        .stroke(AppColors.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        .allowsHitTesting(false)
    }

    ForEach(markers) { marker in
        let pt = fieldPoint(for: marker.position, in: fieldSize)
        Circle()
            .fill(marker.position.quadrant.capacityColor.auraCore)
            .frame(width: marker.dotSize, height: marker.dotSize)
            .opacity(marker.opacity)
            .position(x: pt.x, y: pt.y)
    }

    let nowPoint = fieldPoint(for: position, in: fieldSize)
    Text("Now")
        .font(AppFonts.overline)
        .foregroundStyle(AppColors.textSectionLabel)
        .position(x: nowPoint.x, y: nowPoint.y - 44)
        .allowsHitTesting(false)
}
```

*Done: with 2+ weeks of check-in history, the field sheet shows a dashed trail from the oldest available
marker (3mo → 1mo → 1wk, whichever exist) into the current aura, tagged "Now"; with less than a week of
history, no markers/trail render (graceful, not an error) and the sheet looks exactly as it does today.*

---

## Definition of Done (build-green)

- [ ] `PulseHistory.nearestOnOrBefore` exists and compiles.
- [ ] `MapFieldSheet` takes `entries:` and renders 0-3 time-window dots + a dashed connector + a "Now"
      label, sized/opacity per the 🎚️ defaults above.
- [ ] With zero or one total entries, the sheet renders exactly as before (no dots, no connector, no
      crash) — this is the existing empty/sparse-history behavior, don't regress it.
- [ ] No raw literals introduced (dash pattern `[2, 4]` and marker sizes are the one exception —
      🎚️ feel constants, consistent with how `AppAnimation`/`PulseAura` already inline FEEL values).
- [ ] Zero changes to `MapUsLayer.swift`, `PulseCapsule.swift`, `PulseField.swift`, or any Home file —
      confirm nothing outside `MapPulseHero.swift`/`PulseHistory.swift` was touched.

## Bryan verifies on device

- With a fresh/short history (0-2 entries): confirm the field sheet looks unchanged from today.
- With 2+ weeks of varied check-ins: confirm the trail reads clearly (dashed line, shrinking/fading
  dots, "Now" tag over the live aura) and doesn't visually collide with the axis labels or read/desc
  copy below the field.
- 🎚️ Tune dot sizes/opacities/dash pattern and the "Now" tag's `-44` vertical offset if it crowds the aura.

## Constraints / do-not-touch

- Do not re-touch any of the "already fixed" items listed in Context — verify them, don't rework them.
- Do not build the Us layer's equivalent of this (a "your map" trail for two people) — S1-1 was scoped
  to the Me layer only in the mockup; a Us version isn't specified anywhere and would be new scope.
- Requires Plan 18 to have landed first (this plan doesn't use `pulseBallDrift` directly, but Plan 18's
  `PulseField.auraLayer` animation change must already be in place so the trail doesn't fight the aura's
  own position animation).

## Open decisions

1. **Time windows (7/30/90 days) vs. the mockup's exact "1w/1m/3m" framing.** Recommended default: as
   written (7/30/90 is the closest faithful reading of "1w/1m/3m" in days). No action needed unless
   Bryan wants different windows.
2. **Should this apply to the Us layer too?** Recommended default: no, Me-only for V1 (see Constraints)
   — revisit only if Bryan explicitly wants a couple-trail feature, which would need its own design pass
   (two trails, or a shared one — not specified anywhere today).
