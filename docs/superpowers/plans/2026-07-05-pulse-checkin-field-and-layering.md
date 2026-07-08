# Pulse Check-In Field Size, Header Chrome, and Layering Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On-device testing of the Pulse check-in screen found it didn't match its mockup — the
2D circumplex field reads too small, the header chrome (back button + step tracker) competes with
it for vertical room, and the field's zone color washes don't blend correctly with the background
atmosphere behind them (visible flat-layer seam instead of one coherent glow).

**Architecture:** Three independent, sequential fixes, each a small tuning/technique change to
existing code — no new components, no model changes. Task 1 grows the field. Task 2 shrinks the
header chrome's footprint so it recedes rather than competing with the bigger field. Task 3 adds
`.blendMode(.screen)` to the field's zone washes — the same technique already used throughout this
codebase (`VaylAppIcon`, `CardCarousel`, `LivingText`, `HolographicShimmer`) whenever a glow layer
needs to blend luminously into the void instead of sitting as a flat opaque patch.

**Tech Stack:** SwiftUI, existing `AppColors` / `AppFonts` / `AppSpacing` / `AppLayout` token files.
No new dependencies.

**Adaptation note:** This is feel/visual tuning, not logic. Per `CLAUDE.md`'s Build Protocol,
size/opacity/blend values here are starting points explicitly flagged for Bryan's on-device pass
(the codebase's own `🎚️ FEEL` convention), not final numbers — the agent's job is a clean compile,
not a pixel-perfect guess.

---

## Task 1: Grow the field

**Files:**
- Modify: `Vayl/Features/Pulse/PulseCheckInView.swift:50-53`

- [ ] **Step 1: Bump the field-size multiplier**

Find this in `PulseCheckInView.swift`:

```swift
                // The field owns the top of the screen, running nearly edge-to-edge (capped at a
                // square by the screen width). 🎚️ FEEL: 0.42 of the height — tune 0.40–0.46 on
                // device so the five pills always clear the bottom without the field shrinking.
                let fieldSize = min(layout.screenWidth, geo.size.height * 0.42)
```

Replace it with:

```swift
                // The field owns the top of the screen, running nearly edge-to-edge (capped at a
                // square by the screen width). 🎚️ FEEL: 0.50 of the height (was 0.42) — the field
                // read too small against its mockup on device; tune further from here so the five
                // pills always clear the bottom without the field shrinking.
                let fieldSize = min(layout.screenWidth, geo.size.height * 0.50)
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Pulse/PulseCheckInView.swift"
git commit -m "fix(pulse): grow the check-in field (0.42 -> 0.50 of height)"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the check-in screen. Confirm the field reads noticeably bigger and the five answer pills
still clear the bottom of the screen comfortably. If the pills feel cramped, this is the value to
dial back toward 0.46; if there's still room, push it further.

---

## Task 2: Shrink the header chrome's footprint

**Files:**
- Modify: `Vayl/Features/Pulse/PulseCheckInView.swift` (the `backButton` and `stepDot` sections,
  plus `headerChrome`'s top clearance)

- [ ] **Step 1: Shrink the back button**

Find this in `PulseCheckInView.swift`:

```swift
    private var backButton: some View {
        Button { onClose() } label: {
            Image(systemName: "chevron.left")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppColors.cardBackground))
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leave check-in")
    }
```

Replace it with:

```swift
    private var backButton: some View {
        Button { onClose() } label: {
            Image(systemName: "chevron.left")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppColors.cardBackground))
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leave check-in")
    }
```

- [ ] **Step 2: Shrink the step dots**

Find this in `PulseCheckInView.swift` (inside `stepDot(_:)`):

```swift
                .frame(width: isNow ? 22 : 18, height: isNow ? 22 : 18)
```

Replace it with:

```swift
                .frame(width: isNow ? 20 : 16, height: isNow ? 20 : 16)
```

- [ ] **Step 3: Tighten the header's top clearance**

Find this in `PulseCheckInView.swift` (in `body`):

```swift
                // Header chrome floats over the top edge of the field (per the mockup) — it
                // reclaims the row the enlarged field now occupies, so the graph can breathe.
                headerChrome
                    .padding(.horizontal, AppSpacing.lg)
                    .topClearance(layout, padding: AppSpacing.xs)
```

Replace it with:

```swift
                // Header chrome floats over the top edge of the field (per the mockup) — it
                // reclaims the row the enlarged field now occupies, so the graph can breathe.
                // Shrunk (back button 32->28, step dots 22/18->20/16) and pulled to the bare
                // safe-area clearance (no extra padding) so it recedes into a slimmer strip
                // instead of competing with the now-bigger field for vertical room.
                headerChrome
                    .padding(.horizontal, AppSpacing.lg)
                    .topClearance(layout, padding: 0)
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add "Vayl/Features/Pulse/PulseCheckInView.swift"
git commit -m "fix(pulse): shrink and tighten the check-in header chrome"
```

- [ ] **Step 6: Device-pass checkpoint (Bryan, not the agent)**

Confirm the back button and step tracker read smaller/more compact and no longer compete
visually with the field for attention or vertical space, and that the back button and step dots
are still comfortably tappable (28pt and 20pt both clear the 44pt HIG minimum tap target via
their surrounding hit area — if they feel too small to tap reliably, that's the value to grow
back toward the original 32/22).

---

## Task 3: Blend the field's zone washes with the background

**Files:**
- Modify: `Vayl/Features/Pulse/Components/PulseField.swift:84-99`

- [ ] **Step 1: Add screen blending to the zone washes**

Find this in `PulseField.swift`:

```swift
    private var zones: some View {
        // Four boxes that TILE the square rather than four floating discs: each colour is clipped
        // to its own quadrant rectangle, brightest at the outer field corner and fading toward the
        // centre. The rectangle edges — the outer boundary and the centre cross where the four
        // meet — do the shaping, so the field reads as a boxy grid with no drawn lines. Opacity is
        // luminance-compensated so the four read as EQUAL presence (cyan bright → down, rose dusty
        // → up). 🎚️ FEEL: opacities were tuned for soft blobs; a filled box covers more area, so
        // nudge down if any quadrant reads too hot on device.
        ZStack {
            zoneBox(AppColors.auraCoreMagenta, corner: .topLeading,     cx: 0.25, cy: 0.25, opacity: 0.20)  // Reactive
            zoneBox(AppColors.auraCoreCyan,    corner: .topTrailing,    cx: 0.75, cy: 0.25, opacity: 0.16)  // Expansive
            zoneBox(AppColors.auraCoreRose,    corner: .bottomLeading,  cx: 0.25, cy: 0.75, opacity: 0.32)  // Protective
            zoneBox(AppColors.auraCoreIndigo,  corner: .bottomTrailing, cx: 0.75, cy: 0.75, opacity: 0.23)  // Receptive
        }
        .frame(width: size, height: size)
    }
```

Replace it with:

```swift
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
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Pulse/Components/PulseField.swift"
git commit -m "fix(pulse): screen-blend the field's zone washes with the background atmosphere"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the check-in screen. Confirm the zone colors now read as glowing light sitting inside the
same atmosphere as the background, not a separate flat-colored layer stacked on top of it. Since
`.blendMode(.screen)` only ever brightens (never darkens), also confirm none of the four quadrants
now reads uncomfortably hot/blown-out against the void — if one does, that quadrant's `opacity`
value in `zoneBox(...)` (currently 0.16–0.32) is the value to dial down.

---

## Self-review notes

- **Spec coverage:** Task 1 covers the field-size request. Task 2 covers "push the back
  button/step tracker back." Task 3 covers the background/field blending complaint. All three
  points from the conversation are covered.
- **Scope discipline:** No changes to the field's zone rendering *technique* (still the tiled-box
  approach, per the explicit decision to keep it) — Task 3 only adds a blend mode, it doesn't
  touch `zoneBox`'s gradient math, positions, or opacities. No changes to the orb, aura layer, or
  ghost labels in any task.
- **Type/property consistency:** `fieldSize`, `backButton`, `stepDot(_:)`, `headerChrome`, and
  `zones` are all existing names in their respective files — no renames, no new properties
  introduced by this plan.
- **No orphaned code:** All three tasks are pure in-place edits to existing code — nothing added
  that isn't wired to something, nothing removed that's referenced elsewhere.
