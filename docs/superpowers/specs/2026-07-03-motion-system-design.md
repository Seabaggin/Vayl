# Vayl Motion System — Three Staples, Three Registers

**Date:** 2026-07-03
**Status:** Design approved in principle (interactive reference feel-approved in browser; device pass pending)
**Feel reference:** `docs/prototypes/motion-system-staples.html` (all values below were tuned there)
**Decision record:** "Quiet echo" won a structured debate vs "separate iOS-native system", absorbing the losing side's guardrails (ceremony ban, native gesture mechanics, tab-cadence latency cap).

---

## 1. The system in one paragraph

Every transition in Vayl is one of **three staples** — Depth Handoff (screen-level change), Weighted
Arrival (objects entering), Charged Tap (input) — played in one of **two registers**: **Loud**
(OB + protected covers: sessions, check-in, desire rater, reveal) and **Quiet** (main app: tabs,
sheets, content swaps). The tap contract is shared verbatim across both. The physics never change
between registers; only the amplitude does.

## 2. Registers and hard guardrails

| Register | Where | Amplitude ceilings |
|---|---|---|
| Loud | OB canvas + `.vaylCover` contents | existing OB tokens, unchanged |
| Quiet | everything else | scale delta ≤ 2% · travel ≤ 16pt · duration ≤ 0.55s |

Laws (absorbed from the debate):
- **Ceremony ban.** Motifs and multi-second builds (crystallising cards, dealer voice, forge-class
  sequences) never leave OB/covers. The Quiet register carries physics grammar only.
- **Never replace platform gesture mechanics.** Sheets keep native interactive dismiss; pushes keep
  native slide + swipe-back (Learn drill-downs, Settings stay untouched). The system styles
  *arrival curves*, never gesture physics.
- **Tab cadence is sacred.** The most-repeated gesture stays ≤ 0.25s content, no added latency.

## 3. The staples (final values)

### Staple 1 — Depth Handoff (screen transitions)
Screens never slide. Incoming settles forward from depth, outgoing recedes into it. One continuous
space, not a page stack.
- **Loud** (exists — OB `phaseHandoff`): 0.5s ease-out (`slow`), in scale 1.02→1, out 1→0.97.
- **Quiet** (new): 0.26s ease-out, in scale **1.01→1**, out **1→0.985**, opacity cross-fade.
- **Tab cadence** (Staple 1 floor): content in = 14pt drift from travel direction + fade,
  0.25s ease-out (`tabSwitch`, exists); out = fade in place. Orb: **glide replaces spring** —
  0.38s `timingCurve(0.3, 0, 0.15, 1)`, zero overshoot (retires `orbSnap`'s 15% overshoot;
  the halo burst re-times to the glide's landing).

### Staple 2 — Weighted Arrival (sheets, covers, objects)
Instant acceleration, sharp deceleration, one confident settle, zero bounce. The curve family is the
deal-physics deceleration `timingCurve(0, 0, 0.2, 1)`.
- **Sheet (Quiet):** rise 0.42s on the arrival curve + scrim to 62%. Native grabber/dismiss kept.
- **Cover (Loud):** rise 0.55s same curve, full-bleed; cover *content* settles from depth
  (scale 1.02→1 + fade, 0.5s) starting **0.18s behind** the container — Staple 1 nested inside
  Staple 2. The register shift IS the threshold cue into the table world.

### Staple 3 — Charged Tap (shared register, exists)
Press: scale 0.96 (`fast`) + hairline retract (0.12s) + spectrum arcs sweep to meet at bottom-center
(`borderFill`). Release: glow in 0.12s → hold 0.12s → out 0.28s + impact haptic + action. Cancel:
arcs retract 0.16s. Already built (`VaylBorderEffect` / `VaylButton` / `SelectablePill`); this spec
promotes it to THE tap contract at every register and adds one move:
- **Refusal (new):** invalid/disabled commit → ±3pt lateral shiver, 0.28s ease-out,
  `impact(.medium)`, arcs never fill.

## 4. Sequencing laws

1. **Enter/exit asymmetry.** Entrances decelerate (`enter`, 0.4s ease-out, ≤8pt rise); exits
   accelerate away at ~half the duration (`exit`, 0.2s ease-in). Any appear/disappear pair must be
   asymmetric this way.
2. **First-arrival cascade (new).** When a screen's data first lands, rows cascade as ONE wave:
   per-row 0.52s `timingCurve(0.25, 0.1, 0.15, 1)` (long-tail drift family), 14pt rise,
   **75ms stagger** (~85% overlap between neighbors), capped at 6 rows (rest arrive with row 6).
   Refreshes/re-fetches fade only — never cascade. The cascade is intentionally slower than
   `enter`: it is the entrance for the whole list, not per-element decoration.
3. **Commit vs cancel dismissal.** A sheet dismissed by completing its task carries the tap glow
   into the exit; a cancel just exits. *(OPEN — needs a feel prototype during implementation;
   ship cancel-style everywhere first, layer the commit glow after.)*
4. **Route-level swaps** (splash → OB → Home): Loud handoff / `cinematicFade`, unchanged.

## 5. Reduce Motion contract

- Staples 1–2: collapse to opacity cross-fade (0.15s ease-out), zero scale/travel — existing
  `.reduceMotionSafe` pattern.
- Staple 3: skip arcs/glow/shiver; keep the state change and the haptic (haptics are not motion).
- Cascade: all rows appear together with a single 0.2s fade.

## 6. Where it lives in the codebase

**Values → `Vayl/App/Theme/AppAnimation.swift`** (the token contract's single source). New
`// MARK: — Motion System (Staples & Registers)` section:

```
depthQuiet            .easeOut(duration: 0.26)
depthQuietScaleIn     1.01      depthQuietScaleOut  0.985
depthLoudScaleIn      1.02      depthLoudScaleOut   0.97    // promoted from OnboardingCanvasView literals
arrive                .timingCurve(0, 0, 0.2, 1, duration: 0.42)   // sheet rise
arriveCover           .timingCurve(0, 0, 0.2, 1, duration: 0.55)
arriveCoverContentLag 0.18
orbGlide              .timingCurve(0.3, 0, 0.15, 1, duration: 0.38) // replaces orbSnap
cascadeRow            .timingCurve(0.25, 0.1, 0.15, 1, duration: 0.52)
cascadeStagger        0.075     cascadeCap  6      cascadeRise  14
refusalShiver         0.28s, ±3pt keyframes
quietMaxScaleDelta    0.02      quietMaxTravel  16   // documented ceilings, cited in reviews
```

**Behavior → view-layer API, next to existing siblings:**
- `Vayl/Design/Components/Motion/VaylMotion.swift` (new): `AnyTransition.vaylDepth(_ register:)`,
  `.vaylCascade(index:trigger:)`, `.vaylRefusal(trigger:)` — each with Reduce Motion built in so
  call sites can't forget it.
- `VaylPresentation.swift` (existing): `.vaylSheet` adopts `arrive` + scrim value; `.vaylCover`
  adopts `arriveCover` + the content-lag choreography.
- `VaylBorderEffect` / `VaylButton` (existing): unchanged; refusal shiver added.
- `RacetrackTabBar`: `orbSnap` → `orbGlide`, halo re-timed. `orbSnap` token deleted (single
  consumer).

**OB is untouched.** It already speaks the Loud register; only the two scale literals in
`OnboardingCanvasView.phaseHandoff` get promoted to the new tokens.

**CLAUDE.md**: one line added to the Violation Checklist — screen/content transitions must use a
staple (`vaylDepth` / `arrive` / tap contract); no ad hoc slides.

## 7. Migration order (implementation plan input)

1. Tokens + `VaylMotion.swift` (no call sites yet — pure additive, build-verified).
2. Tab bar: orbGlide + drift (smallest visible surface, easiest to feel-verify).
3. `vaylSheet` / `vaylCover` arrival adoption.
4. Quiet depth handoff at tab-content swaps + any custom screen swaps found in audit.
5. Cascade on Home first-load + Learn directory; refusal on gated CTAs (paywall, invalid submits).
6. Promote OB handoff literals to tokens (no visual change).

Each step is device-feel-gated per the build protocol. Timing values in this spec came from the
HTML reference but are **starting points until the device pass confirms them**.

## 8. Open items

- Commit-vs-cancel glow dismissal (law 3) — prototype during step 3.
- Device feel pass on all Quiet values (especially cascade overlap and orb glide).
- Whether Map/Home hero moments (Pulse expand) count as covers (Loud) or in-place expands (Quiet)
  — decide when those screens are touched next.
