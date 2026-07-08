# Pulse Field Blob Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the check-in field's hard-clipped quarter-rectangle zone washes (which read as a
visible box + centre-cross seam on device, even after last round's screen-blend fix) with the
large-soft-circle "blob" technique already validated in `docs/prototypes/pulse-teach-landing.html`,
and extend screen blending to the quadrant labels too.

**Architecture:** Two sequential tasks in one file. Task 1 replaces `zoneBox` (a hard-clipped
quarter-rectangle) with `zoneBlob` (a large soft circle, 92% of the field, offset toward each
quadrant corner so the four overlap generously — full coverage, no deadzone at the corners or
centre — while still distinguishable rather than melting into one wash), wraps the group in
`.compositingGroup().blur(...)` so the blur feathers the composited result instead of each layer
blurring independently, and keeps the existing `.blendMode(.screen)`. Task 2 adds
`.blendMode(.screen)` to the quadrant labels, which currently sit flat on top with no blend at all
— the same gap the zones had before last round's fix.

**Tech Stack:** SwiftUI. No new dependencies, no model changes.

**Context:** Corrects `docs/superpowers/plans/2026-07-05-pulse-checkin-field-and-layering.md`'s
Task 3 (which added screen-blend to the *existing* hard-clipped zones) — on-device testing showed
that fix alone wasn't enough; the box/cross-seam problem is about the zone *shape*, not just the
blend mode. Approved directly against the reference mockup (`pulse-teach-landing.html`'s
`.zoneBlob`) rather than a fresh brainstorm, since the technique was already validated there.

**Adaptation note:** Feel/visual work — verification is an `xcodebuild` compile check (the agent
runs this) followed by Bryan's on-device pass, not automated tests.

---

## Task 1: Replace `zoneBox` with `zoneBlob`

**Files:**
- Modify: `Vayl/Features/Pulse/Components/PulseField.swift:82-123` (the `zones` property and the
  `zoneBox` function it calls)

- [ ] **Step 1: Replace the `zones` property and `zoneBox` function**

Find this in `PulseField.swift`:

```swift
    // MARK: - Zone washes

    private var zones: some View {
        // Four boxes that TILE the square rather than four floating discs: each colour is clipped
        // to its own quadrant rectangle, brightest at the outer field corner and fading toward the
        // centre. The rectangle edges — the outer boundary and the centre cross where the four
        // meet — do the shaping, so the field reads as a boxy grid with no drawn lines. Opacity is
        // luminance-compensated so the four read as EQUAL presence (cyan bright → down, rose dusty
        // → up). 🎚️ FEEL: opacities were tuned for soft blobs; a filled box covers more area, so
        // nudge down if any quadrant reads too hot on device.
        //
        // .blendMode(.screen): without this the zones alpha-composite as flat opaque patches on
        // top of OnboardingAtmosphere, reading as a separate layer stacked on the background
        // instead of light sitting inside the same atmosphere. Screen blending is the established
        // technique this codebase already uses for exactly this (VaylAppIcon, CardCarousel,
        // LivingText, HolographicShimmer) — it makes the zone colour read as emissive glow that
        // blends with whatever's behind it rather than a solid cutout.
        ZStack {
            zoneBox(AppColors.auraCoreMagenta, corner: .topLeading,     cx: 0.25, cy: 0.25, opacity: 0.20)  // Reactive
            zoneBox(AppColors.auraCoreCyan,    corner: .topTrailing,    cx: 0.75, cy: 0.25, opacity: 0.16)  // Expansive
            zoneBox(AppColors.auraCoreRose,    corner: .bottomLeading,  cx: 0.25, cy: 0.75, opacity: 0.32)  // Protective
            zoneBox(AppColors.auraCoreIndigo,  corner: .bottomTrailing, cx: 0.75, cy: 0.75, opacity: 0.23)  // Receptive
        }
        .frame(width: size, height: size)
        .blendMode(.screen)
    }

    private func zoneBox(_ color: Color, corner: UnitPoint, cx: CGFloat, cy: CGFloat, opacity: Double) -> some View {
        let half = size * 0.5
        return RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.opacity(opacity),        location: 0.0),
                .init(color: color.opacity(opacity * 0.62), location: 0.55),
                .init(color: .clear,                        location: 1.0)   // fades into the centre seam
            ]),
            center: corner,                 // anchored at the field's outer corner for this quadrant
            startRadius: 0,
            endRadius: half * 1.42           // reach diagonally across to the centre cross
        )
        .frame(width: half, height: half)    // hard rectangular clip = the boxy edge
        .position(x: cx * size, y: cy * size)
    }
```

Replace it with:

```swift
    // MARK: - Zone washes

    private var zones: some View {
        // Four large soft circular blobs (92% of the field, offset toward each corner) that
        // overlap generously — full coverage, no deadzone at the corners or centre — while each
        // still centres on its own quadrant point, so the four stay distinguishable rather than
        // melting into one indistinct wash. Ported from docs/prototypes/pulse-teach-landing.html's
        // `.zoneBlob` — replaces the previous hard-clipped quarter-rectangle approach, which showed
        // a visible box outline + centre-cross seam against the void on device even after adding
        // screen blend below. Opacity is luminance-compensated so the four read as EQUAL presence
        // (cyan bright → down, rose dusty → up). 🎚️ FEEL: tune opacities if any quadrant reads too
        // hot or too faint on device.
        //
        // .compositingGroup(): flattens the four overlapping blobs into one image BEFORE blurring,
        // so the blur feathers the composited result instead of each layer blurring independently
        // (which would otherwise let each blob's edge fade differently against its neighbours).
        // .blur(): softens the blob edges — no hard clip line against the void.
        // .blendMode(.screen): established technique this codebase already uses for glow-on-void
        // (VaylAppIcon, CardCarousel, LivingText, HolographicShimmer) — makes the zone colour read
        // as emissive light blending with whatever's behind it, not a flat opaque patch.
        ZStack {
            zoneBlob(AppColors.auraCoreMagenta, cx: 0.28, cy: 0.28, opacity: 0.20)  // Reactive
            zoneBlob(AppColors.auraCoreCyan,    cx: 0.72, cy: 0.28, opacity: 0.16)  // Expansive
            zoneBlob(AppColors.auraCoreRose,    cx: 0.28, cy: 0.72, opacity: 0.32)  // Protective
            zoneBlob(AppColors.auraCoreIndigo,  cx: 0.72, cy: 0.72, opacity: 0.23)  // Receptive
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .blur(radius: size * 0.05)
        .blendMode(.screen)
    }

    private func zoneBlob(_ color: Color, cx: CGFloat, cy: CGFloat, opacity: Double) -> some View {
        let d = size * 0.92
        return RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.opacity(opacity),       location: 0.0),
                .init(color: color.opacity(opacity * 0.5), location: 0.45),
                .init(color: .clear,                       location: 0.85)
            ]),
            center: .center,
            startRadius: 0,
            endRadius: d * 0.5
        )
        .frame(width: d, height: d)
        .clipShape(Circle())
        .position(x: cx * size, y: cy * size)
    }
```

Note the `cx`/`cy` values changed from 0.25/0.75 to 0.28/0.72 — this matches the reference mockup's
blob centring exactly (a 92%-sized blob offset -18% from each corner centres at 28%/72% of the
field, not 25%/75%). `zoneBox` is fully removed, not left as dead code.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build-blob` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Pulse/Components/PulseField.swift"
git commit -m "fix(pulse): replace hard-clipped zone boxes with soft overlapping blobs"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the check-in screen. Confirm: no visible box outline or centre-cross seam, no deadzone at
the field's corners or centre, and the four quadrants are still readable as distinct zones (not
one uniform wash). If the blur reads too strong (edges melt together) or too weak (edges still
crisp), `size * 0.05` in Step 1 is the value to retune.

---

## Task 2: Screen-blend the quadrant labels

**Files:**
- Modify: `Vayl/Features/Pulse/Components/PulseField.swift` (the `ghostLabel` function)

- [ ] **Step 1: Add `.blendMode(.screen)` to `ghostLabel`**

Find this in `PulseField.swift`:

```swift
    private func ghostLabel(_ name: String, _ color: Color, leading: Bool, yFrac: CGFloat, quadrant: PulseQuadrant) -> some View {
        let isActive = entries.contains { $0.quadrant == quadrant }
        return Text(name.uppercased())
            .font(AppFonts.display(size * 0.085, weight: .bold, relativeTo: .title2))
            .tracking(size * 0.004)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(color.opacity(isActive ? 0.34 : 0.17))
            .frame(width: size * 0.92, alignment: leading ? .leading : .trailing)
            .position(x: size * 0.5, y: size * yFrac)
    }
```

Replace it with:

```swift
    private func ghostLabel(_ name: String, _ color: Color, leading: Bool, yFrac: CGFloat, quadrant: PulseQuadrant) -> some View {
        let isActive = entries.contains { $0.quadrant == quadrant }
        return Text(name.uppercased())
            .font(AppFonts.display(size * 0.085, weight: .bold, relativeTo: .title2))
            .tracking(size * 0.004)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(color.opacity(isActive ? 0.34 : 0.17))
            .frame(width: size * 0.92, alignment: leading ? .leading : .trailing)
            .position(x: size * 0.5, y: size * yFrac)
            // Same gap the zones had before their screen-blend fix: flat opacity text sitting on
            // top of the atmosphere reads as stamped-on rather than glowing. Screen blending here
            // matches the same technique now used by `zones` above.
            .blendMode(.screen)
    }
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build-blob` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Pulse/Components/PulseField.swift"
git commit -m "fix(pulse): screen-blend the quadrant labels to match the zones"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Confirm the quadrant labels (REACTIVE/EXPANSIVE/PROTECTIVE/RECEPTIVE) now read as soft glowing
text sitting in the same atmosphere as the zones, not flat stamped-on text.

---

## Self-review notes

- **Spec coverage:** Task 1 covers the blob-technique replacement (no deadzone, no hard edge,
  zones still distinguishable). Task 2 covers the label-blend gap.
- **Out-of-scope respected:** `ghostLabels` layout (yFrac/leading values), `auraLayer`, `axisLabels`,
  `quadrantLabels`, `body`, and the orb are untouched — only `zones`/`zoneBox`→`zoneBlob` and
  `ghostLabel`'s modifier chain change.
- **No orphaned code:** `zoneBox` is deleted in the same edit that stops calling it — nothing left
  half-migrated.
- **Type consistency:** `zoneBlob(_:cx:cy:opacity:)`'s signature is used identically at all four
  call sites in `zones`; no mismatched parameter names between definition and call sites.
