# BuildDeck Ceremony Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Implement the confirmation→buildDeck→founderLetter ceremony per `docs/superpowers/specs/2026-06-10-builddeck-ceremony-design.md`.

**Architecture:** Eight feel-gated segments (Build Protocol). Motion segments are
feel-iterated on device, so segments 2–8 are planned in detail ONLY after the
preceding segment passes its feel gate — this file grows as gates pass. Each
segment ends in a commit.

**Build command (pinned DerivedData):**
```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,id=1A610585-FBCA-47EC-8519-C0F1C5426D56' \
  -derivedDataPath /tmp/vayl-foil-dd build -quiet
```
Clean build after any `.metal` edit. Install/launch via simctl from the same path.

---

### Segment 1: Seam stitch

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/ConfirmationPhase.swift` (exit choreography)
- Modify: `Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift` (DeckStack prop)

Both sides of the phase boundary meet at: face-down · obCard scale · table
center (`exitDeckPoint == feltCenter == (w/2, obTableCardCenterY)`) · angle 0.

- [ ] **Step 1: ConfirmationPhase — flip + scale during exit**
  - `scl` exit value: `0.5` → `AppLayout.obCardWidth(in: size.width) / cardWidth(in: size.width)`
  - Wrap the card in the CuriosityFlipCard idiom (two pre-rotated faces,
    opacity crossfade, driven by `exiting` through the existing exit animation):
    front = `VaylCardFace` rotating 0→−180, back = `VaylCardBack` rotating 180→0.
- [ ] **Step 2: BuildDeckPhase — real deck prop**
  - `DeckStack`'s stroked RoundedRectangles → `VaylCardBack()` per layer, same
    offsets, same frame.
- [ ] **Step 3: Build (incremental, no metal), install, launch**
- [ ] **Step 4: USER FEEL GATE** — tap "This is me": cards flip face-down as
  they square up at full deck scale; BuildDeck opens on an identical deck; no
  detectable boundary. Tune `exitDuration`/easing on device if the flip+growth
  feels chaotic with six cards.
- [ ] **Step 5: Commit** `feat(ob): seam stitch — confirmation collapse flips face-down into the real deck`

### Segments 2–8 (planned after each preceding gate)

2. Dissolve-down through felt · 3. Table hero moment · 4. Arrival (dissolve-up,
flat→vertical, float; lattice fades in during rise) · 5. Invitation (LiftHalo)
· 6. Crack wiring (face-space tears) · 7. Reveal carousel (placeholder content)
· 8. Sheet-peek handoff (expand fully, then advance).
