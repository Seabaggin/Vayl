# Performance & Power Audit — 2026-07-04

Full-app SwiftUI performance and power-efficiency pass, **code-first only**. No Instruments
traces were captured: every finding below is a **code-backed hypothesis, not a trace-backed
conclusion**. Nothing here is "confirmed fixed" for CPU/GPU/thermal until Bryan profiles on
device — see the Instruments checklist at the end.

Constraints held: zero visual/feel changes, zero shader-math or timing-constant edits, the
OB perf-pass contracts (commit `320ef9b`: TableSurface 3-canvas split, TopoField cache,
SpriteView `shouldRender` gate, FrameClock, CardBackRaster) untouched — their pattern was
extended, not regressed. Build verified (compile only, per the no-sim rule):
`xcodebuild -scheme Vayl` → **BUILD SUCCEEDED**.

---

## The new contract: Low Power Mode = second ambient gate

There was **no** `isLowPowerModeEnabled` check anywhere in the app (verified by grep before
the pass). Decorative ambient animation is exactly the discretionary cost Low Power Mode
exists to cut, so LPM now rides the same rails Reduce Motion already uses:

- **`AppAnimation.lowPower`** and **`AppAnimation.ambientMotionDisabled`**
  (RM ∨ LPM) added in [AppAnimation.swift](../../Vayl/App/Theme/AppAnimation.swift).
- **`.ambientAnimation(_:value:)`** now nil-outs under RM **or** LPM — this one edit covers
  every loop already routed through the contract modifier (~30 call sites).
- Every manual ambient mount/start guard (`guard !reduceMotion` / `if reduceMotion` branches)
  was extended to `reduceMotion || AppAnimation.lowPower` — 16 files (list below).

Scope line drawn deliberately:
- **LPM gates**: continuous per-frame surfaces (TimelineView/Canvas) and `repeatForever` loops.
- **LPM does NOT gate**: reactive animations (user feedback always plays — `reduceMotionSafe`
  is untouched), one-shot effects (e.g. `triggerSpecularGlint`), and the OB gesture-teaching
  hint loops (intermittent, near-zero cost, and pedagogically load-bearing).

Known limitation (same semantics as the existing RM static check): the flag is read at
body-evaluation time. A mid-session LPM toggle takes effect on the next re-render/appear of
each surface; there is no `NSProcessInfoPowerStateDidChange` observer forcing an app-wide
re-evaluation. Acceptable for V1; noted here so it isn't rediscovered as a bug.

---

## Findings & fixes

### F1 — PulseCyclingAura ticked at display rate for a 3.6s-per-space colour tour ⭐ highest impact
- **Symptom (hypothesis):** sustained GPU/CPU load and battery drain on Home and the Map tab —
  the dormant orb is mounted in three live places (HomePulseRail, MapPulseHero, MapUsLayer).
- **Cause:** `TimelineView(.animation)` at full display rate (up to 120Hz on ProMotion),
  re-lerping four `AuraColors` ramps (8 `UIColor.getRed` calls each) and re-rendering the whole
  `PulseAura` subtree (Canvas caustic layer included) **every frame**, to drive a colour drift
  that crosses one space every 3.6 seconds.
- **Fix:** capped to `.animation(minimumInterval: 1/30)` + LPM added to the existing RM branch.
  Wall-clock drive untouched — identical cycle, sampled at 30Hz.
  [PulseAura.swift](../../Vayl/Features/Pulse/Components/PulseAura.swift)
- **Measure:** GPU utilisation + CPU % while idling on Home and on Map-Us, before/after.

### F2 — HolographicShimmer ran unconditionally, including on the tab bar
- **Symptom (hypothesis):** a permanent full-rate TimelineView on `RacetrackTabBar` (visible on
  every tab, all session long), plus VaylButton, SelectablePill, PartnerChip, and two Learn
  surfaces — with **no Reduce Motion fallback at all** (a Cat-4 contract gap, not just a power
  issue). Each tick recomputes value-noise, moves a 2×-width gradient, and re-poses blurred orbs.
- **Fix:** inside the component (one fix covers all six hosts): the frame renderer was extracted
  to `shimmerFrame(t:size:)`; under RM/LPM it renders **one static frame** (sweep parked, orbs
  posed by the per-instance phase offset, no TimelineView mounted). Live path unchanged.
  [HolographicShimmer.swift](../../Vayl/Design/Components/Effects/HolographicShimmer.swift)
- **Not done on purpose:** no frame-rate cap on the live path — the noise-driven sweep is a
  tuned surface; capping is a candidate follow-up **after** Bryan measures it.
- **Measure:** SwiftUI instrument "View Body" counts + GPU while sitting on any tab with RM off,
  then with RM on (should drop to zero ticks).

### F3 — SparkField: persistent 30fps particle system with no RM gate
- **Symptom (hypothesis):** every screen hosting a `SparkField` pays a 30fps Canvas raster +
  particle-system update for the whole time it's mounted, even under Reduce Motion.
- **Fix:** under RM/LPM the field no longer mounts (renders `Color.clear`) — the ember motes are
  pure decoration; the scenes they dress are visually complete without them (same rationale as
  the existing `SpectrumSparkField` RM branch). The existing 1/30 cap on the live path kept.
  [SparkField.swift](../../Vayl/Design/Components/Effects/SparkField.swift)
- **Measure:** CPU on StatPhase / hosts of `.statView`-config fields with RM on.

### F4 — UnchartedDrift: display-rate TimelineView for a ±5pt, 6-second wander
- **Cause:** full-rate `TimelineView(.animation)` computing three sinusoids per frame to move
  the Uncharted orb ~5pt over 6s.
- **Fix:** capped to 1/30 + LPM added to the RM/active guard. Drift path identical.
  [PulseField.swift](../../Vayl/Features/Pulse/Components/PulseField.swift)

### F5 — BloomRing used a raw `.animation()` loop (contract deviation)
- **Fix:** switched to `.ambientAnimation()` (behaviour-identical when motion is allowed; now
  also LPM-gated), and the `onAppear` trigger guard extended. Same file as F4.

### F6 — Reduce Motion drift (Cat 4): five loops had lost / never had an RM fallback
Re-audit of every `repeatForever` + ambient TimelineView app-wide (the e193684 regression class).
~54 loops audited; the compliant ones are unchanged. Gaps fixed:
- **LightModeShimmer** — two `repeatForever` sweeps in `onAppear`, no RM guard; live via
  PartnerChip / RacetrackTabBar / SelectablePill. Guard added (gradients rest at phase 0).
- **AuroraGlowField** — nine drift loops scheduled with no RM guard (HomeGateView, Learn's
  ConstellationNode). Loops no longer scheduled under RM/LPM; the opacity-only fade-IN stays
  (permitted under RM).
- **LightAuraBloom** — TimelineView **plus** a 60Hz `Timer` publisher advancing `@State phase`
  (a double engine — each tick invalidates twice), no RM gate. Under RM/LPM it now renders one
  static bloom frame with neither engine. (Double-engine cleanup flagged below, not fixed —
  the phase-advance rate is a feel value.)
- **TileOrbitView** — comet orbits (via CuriosityCardBack's MazePatternView) ran under RM. Now
  falls back to the same static resting arc the inactive state draws.
- **ConversationCard** — pulse loop was functionally RM-safe (value-guarded) but raw; LPM added
  to both condition sites.
- Note: the agent-assisted audit initially reported OrbitIndicator's sheen loop as RM-safe; on
  verification its guard is `!sheenAnimating`, **not** `!reduceMotion` — a real gap, but the
  component is dead code (no instantiation sites), so it's flagged in F10 instead of fixed.

### F7 — Low Power Mode wired at every remaining ambient guard site (Cat 3)
One-line `|| AppAnimation.lowPower` extensions at: SessionAtmosphere (breath loop),
DeckPedestal, RotaryDial, CardCarousel idle loops, VaylCardCarousel breathing, VaylCardFace
holoShift, StarVeil (static-frame branch), SpectrumSparkField, SpectrumBulletRow sweep,
MetallicCaseView (`reduceMotion || flat || lowPower` — the existing `flat` static pass is the
fallback; shader math untouched), DesireMapView twinkle field, OnboardingProgressBar completion
shimmer, LivingText (static check → `ambientMotionDisabled`), ExperienceLevelPhase candle
`t`-freeze, BuildDeckPhase forge rim/sway oscillations, GlassSpecularSweep mount+trigger,
PulseAura `startAmbient`, PulseHistoryGrid `isAnimatedBorder`.

### F8 — Invalidation fan-out (Cat 1)
- **ReflectionCard** ([ReflectionCard.swift](../../Vayl/Features/Home/Components/ReflectionCard.swift)) —
  `Date.relativeString` built a fresh `DateFormatter` per read, read from `body` on the
  always-visible dashboard → cached static formatter.
- **OnboardingProgressBar** — `percentValue` built a fresh `NumberFormatter` per read; it feeds
  the accessibility value inside a body that re-evaluates at 30fps during the completion
  effect → cached static formatter.
- **PulseHistoryGrid** — `cells` (a full map of the 30-entry history) was a computed property
  subscripted **per dot inside the ForEach** → O(n²) re-derivation per render. Hoisted to one
  local copy per body evaluation.
- **ForEach identity sweep:** the 62 `id: \.self` sites are almost all fixed ranges,
  `allCases`, or constant arrays (harmless). Two low-priority notes, not changed:
  PulseHistoryGrid keys dots by index (a mid-session history shift could point the tap-callout
  at the wrong cell — switch to `id: \.date` if that ever manifests), and
  FindingDetailView's `bullets`/`connected` strings could collide if content ever duplicates.
- **`.equatable()`** was applied nowhere — no site was found where equality is demonstrably
  cheaper than the subtree it would guard.
- **@Observable fan-out:** no high-frequency writer feeding broadly-read stores was found.
  PulseStore's O(n) computed scans are fine at n≈30 (revisit if history grows to years).

### F9 — Image / main-thread decode (Cat 5) — clean
- HomeLexicon's `ImageRenderer` share-card runs on user tap, not in body — correct.
- CardBackRaster is cached + prewarmed on an idle beat (the 320ef9b contract) — correct.
- No `UIImage(data:)` / `UIImage(contentsOf:)` decodes during view update anywhere.
- Nothing flagged, nothing changed.

### F10 — Flagged, deliberately NOT fixed
1. **Dead code carrying ambient engines** (deletion candidates — ties into the 2026-06-30
   audit's ~12.5k dead LOC): `PrismView` + `HomeWidgetShell`/`OrbLayer` (full-rate TimelineView
   repositioning three 18–24pt-blur ellipses per frame — if ever revived it MUST get the
   F1-style cap), `OrbitSparkBorderView`, `OrbitIndicator` (sheen loop also missing its RM
   guard), `DeckWrapView`, `GlowUnderline`, `GlowUnderlineView` (both missing RM guards).
2. **LightAuraBloom double engine** (Timer + TimelineView) — redundant invalidation; fixing
   properly means re-deriving `phase` from wall-clock, which touches a feel value. Also
   light-mode-only, so dormant in dark-only V1.
3. **Covered-not-removed TimelineViews:** a `.vaylCover` presented over Map/Home leaves the
   underlying tab's TimelineViews ticking (SwiftUI doesn't pause covered-but-mounted
   timelines). The F1 cap halves the cost; a real fix needs visibility plumbing. Revisit only
   if Instruments shows it mattering during long covers (Card Session).
4. **HomeLexicon 12s auto-scroll / InfiniteCarousel auto-advance** — intermittent Task loops,
   negligible power; left un-gated by LPM on purpose.
5. **ResearchDatabaseView `topics`** (flatMap+Set+sort per render) — sheet renders rarely; fix
   only if the corpus grows.

---

## Instruments checklist for the next device pass

Capture on device, Release-ish config if possible, one change-set at a time:

1. **Baseline idle burn (F1/F2):** Time Profiler + SwiftUI instrument, 60s sitting still on
   (a) Home dashboard, (b) Map-Us. Look at: `View Body` invocation counts for PulseAura /
   HolographicShimmer hosts (should be ~30/s and ~display-rate respectively, not 120/s), GPU
   "Device Utilization %", and Energy Log's CPU/GPU bands. This is the single most important
   capture — it validates or falsifies the two biggest hypotheses.
2. **RM sanity (F2/F3/F6):** same 60s Home capture with Reduce Motion ON — HolographicShimmer,
   SparkField, LightModeShimmer, AuroraGlowField should contribute **zero** periodic view-body
   activity. Any residual tick = a loop I missed.
3. **LPM contract (F7):** toggle Low Power Mode, cold-launch, repeat capture 1 — ambient
   view-body activity should match the RM capture. (Remember the known limitation: toggle
   BEFORE launch; mid-session toggles apply lazily.)
4. **Pulse check-in flow:** SwiftUI instrument through a full check-in — confirm the
   `pulseBallDrift` interactions aren't fighting the (now 30fps) ambient layers, and no
   unexpected invalidation storms from PulseStore.
5. **Covered-cover leak (F10.3):** open a Card Session cover from Map, capture 60s — measure
   what the buried Map hero still costs. Decides whether visibility plumbing is worth it.
6. **OB regression check:** one BuildDeck + ExperienceLevel run-through — the 320ef9b contracts
   plus today's LPM additions should show no new frame drops (nothing on those paths changed
   except gate conditions).

File any deltas back into this doc so the hypotheses become conclusions.
