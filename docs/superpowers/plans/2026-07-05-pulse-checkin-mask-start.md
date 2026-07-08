# Pulse Check-In Atmosphere Mask Start Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Soften the hard void-to-color seam at the top of the Pulse check-in screen — the
atmosphere's ambient glow is currently masked to pure void until 46% down the screen, and against
tonight's much more vivid field it now reads as a stark black band rather than a smooth transition.

**Architecture:** One-line tuning change. `PulseCheckInView`'s `atmosphereMaskStart` (already a
per-screen override of `OnboardingAtmosphere`'s app-wide 0.52 default) moves lower, letting the
ambient atmosphere bleed in higher up the screen. This is a screen-local override — it does not
touch `OnboardingAtmosphere.swift` or any other screen using the `.stat` config.

**Tech Stack:** SwiftUI. No new dependencies.

**Adaptation note:** Feel tuning — the agent's job is a clean compile, not the final number;
Bryan confirms the actual feel on device.

---

## Task 1: Lower the atmosphere mask start

**Files:**
- Modify: `Vayl/Features/Pulse/PulseCheckInView.swift:41-43`

- [ ] **Step 1: Lower `atmosphereMaskStart`**

Find this in `PulseCheckInView.swift`:

```swift
    /// The trail-in mask starts ~6% earlier than the app-wide 52% default — see
    /// OnboardingAtmosphere.maskStart. 🎚️ FEEL: confirm on device.
    private let atmosphereMaskStart: CGFloat = 0.46
```

Replace it with:

```swift
    /// The trail-in mask starts well earlier than the app-wide 52% default — see
    /// OnboardingAtmosphere.maskStart. Lowered from 0.46: against the field's now much more
    /// vivid blob coverage, the void held that long read as a hard black band rather than a
    /// smooth trail-in. 🎚️ FEEL: confirm on device, tune further from here.
    private let atmosphereMaskStart: CGFloat = 0.30
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build-mask` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Pulse/PulseCheckInView.swift"
git commit -m "fix(pulse): lower the check-in atmosphere mask start (0.46 -> 0.30)"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the check-in screen. Confirm the top of the screen no longer reads as a hard black band —
the atmosphere's ambient glow should now bleed in higher, behind the header, softening the
transition into the field. If it now bleeds too much color too close to the status bar/Dynamic
Island (competing with system UI legibility), `0.30` is the value to nudge back up; if it still
feels too black up top, nudge it lower.

---

## Self-review notes

- **Scope:** Single constant, single file, screen-local override — does not touch
  `OnboardingAtmosphere.swift` or any other screen's mask behavior.
- **No orphaned code, no placeholders.**
