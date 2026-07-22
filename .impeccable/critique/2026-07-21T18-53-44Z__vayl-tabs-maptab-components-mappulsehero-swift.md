---
target: Map tab Me lens
total_score: 29
p0_count: 1
p1_count: 3
timestamp: 2026-07-21T18-53-44Z
slug: vayl-tabs-maptab-components-mappulsehero-swift
---
Method: dual-agent (A: design review from Swift source + mockup · B: detector + browser measurement)

## Design Health Score — 29/40 (Good)

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | `canCheckInToday == false` removes both the invite line and the tap (MapPulseHero.swift:55-60,152-160) with nothing in their place. A locked hero is pixel-identical to a live one. |
| 2 | Match System / Real World | 4 | "Charged/Depleted", "How's your capacity?" — human, non-clinical. PulseInfoSheet.swift:90-94 explicitly retired "system" as clinical language. |
| 3 | User Control and Freedom | 3 | The largest target on the tab (the whole hero) opens a full-screen cover. Cheap to escape (confirmOnExit: false) but biggest target = most committal action. |
| 4 | Consistency and Standards | 3 | Strong internally, but check-in is a bordered pill in Us (MapUsLayer.swift:135-148) and plain caption text in Me (MapPulseHero.swift:156). One verb, two grammars, one lens flip apart. |
| 5 | Error Prevention | 3 | The `hasHistory` guard against fabricating an Expansive reading is excellent. Gap is the locked-entry dead zone. |
| 6 | Recognition Rather Than Recall | 2 | The hero names one space; the six-space vocabulary that makes the name mean anything is behind a 15pt textTertiary glyph. This is what the emptiness actually is. |
| 7 | Flexibility and Efficiency | 3 | Me has no route into PulseFullView at all; Us does. The private lens has less depth into the user's own data than the shared one. |
| 8 | Aesthetic and Minimalist Design | 4 | The tab's best axis, and why the premise is suspect. Nothing to remove. |
| 9 | Error Recovery | 2 | `lastHydrateFailed` surfaces only inside the empty state (MapPulseHero.swift:230). A stale-only failure has no path and no retry. |
| 10 | Help and Documentation | 3 | PulseInfoSheet is genuinely good documentation. Deduction is discoverability: one 15pt low-contrast glyph. |
| **Total** | | **29/40** | **Good** |

## Anti-Patterns Verdict

**Not AI slop.** The artifacts a generator cannot fake are present throughout: rejected alternatives recorded with reason and measurement (MapPulseHero.swift:73-76 documents textMuted at 1.76:1 replaced by textTertiary at 5.32:1, framed as "a correctness fix, not a cosmetic one"); a felt orb fraction with an explicit instruction not to "improve it by arithmetic" (AppLayout.swift:220-226); retired tokens carrying post-mortems.

**Deterministic scan:** 27 advisory findings, all `design-system-*`. None of the three sanctioned patterns fired — no gradient-text, no glass-surface, no uppercase-label finding. The caveat was moot. Roughly 8 are mockup chrome (page title, device bezel, inline styles in Us frames); one (`.orb-label`) is dead CSS never applied to any element.

The real signal is token drift in the mockup itself: nine distinct type steps (11/12/13/15/20/22/28/32/40px) where the contract has a fixed ramp; radius 3px on history dots and 10px on the CTA, neither on the scale (8/12/16); and an off-palette purple `#9B59B6` in `.orb.aura.peaceful` and `.orb.split` at 0.4 alpha — a fourth hue entering a strictly three-hue spectrum. Also: the mockup's cycling orb animates at 4s, which matches neither sanctioned tempo (ambientPulse 2s, auraBreathe 5.4s), violating the Two-Tempos Rule.

**No overlay was presented.** Script injection succeeded in the file:// pane, but no live server or user-visible overlay was run; all measurements come from getBoundingClientRect(), not from images.

## Overall Impression

The premise is half right, and located in the wrong place.

The single most important finding is that the screen being critiqued does not exist yet. `meLayer` (MapView.swift:370-384) currently renders `MapPulseHero` **plus `MapRecord`** — a full glass card. There is no unpaired branch. The Us lens is still `VaultDoorCard`. The emptiness is created by removing the Record, and the Record has not left. The real question is not "add explainer content," it is "what replaces the Record's slot."

Measured, the emptiness is real but confined:

| Frame | State | Dead space below content |
|---|---|---|
| 1 | Me · paired · has history | 305px (36.1%) |
| 2 | Me · paired · dormant | 382px (45.3%) |
| 3 | Me · unpaired · Pulse + Desire | 44px (5.2%) |
| 4 | Me · unpaired · Pulse only | **435px (51.5%)** |
| 5-6 | Us | overflows 844 — frame 6 needs 967px |

Two things fall out. First, the top 409px are byte-identical across all four Me states; every state difference lives in the bottom half, which is also the empty half. Second, Me under-fills while Us **overflows** — and the mockup has no tab bar, so in the real AppShell both are worse.

The biggest opportunity is not filling space. It is that the three most reassuring sentences in the feature — "There's no score and no right answer," "your partner sees your capacity, not your answers," "There's no streak to keep" (PulseInfoSheet.swift:60,70,76) — are all behind the glyph, while the Me lens surfaces only the terser, more alarming half of that promise ("Your read also appears in your shared orb") at the very bottom, after the tap.

## What's Working

1. **The masthead-as-lens-switch** (MapView.swift:313-358). Selection encoded in typography that was already going to be on screen. The detail that makes it work is the double dim on the inactive name (line 337-342): textTertiary *and* 0.45 opacity, because colour alone read as ambiguous rather than "off."
2. **The four-targets-to-two rework** (MapPulseHero.swift:11-16). The prior layout had the most obviously tappable element opening the least important destination. The history strip is deliberately a sibling, not a child (line 66-69), avoiding the nested-target gesture conflict.
3. **Empty states that refuse to fabricate.** `hasHistory` exists because dead-centre resolves to `.expansive` via tie-break and would show a real-looking reading to someone who logged nothing (lines 258-261). Both this and `lastHydrateFailed` are cases most products get wrong in the direction of looking fuller — the exact instinct that should govern this question.

## Priority Issues

**[P0] The locked hero is a silent dead zone**
- Why: When `canCheckInToday == false`, `CheckInTap` removes the gesture (MapPulseHero.swift:308-327) and `inviteLine` renders nothing (152-160). Identical pixels, no response. The "is it broken?" moment, on the surface whose job is calm.
- Fix: add an `else` to `inviteLine` — textTertiary caption, "Checked in today" plus relative time. Absence of a target must be stated.
- Command: /impeccable harden

**[P1] The privacy promise arrives after the decision**
- Why: the reassuring half is sheet-only; Me carries only "Your read also appears in your shared orb" (MapPulseHero.swift:76) at the bottom, below the hero the user already tapped. For the partner-cautious persona this is the sentence the tap depends on.
- Fix: surface "Your Pulse is yours. Your partner sees your capacity, not your answers." under the section label, above the hero.
- Command: /impeccable clarify

**[P1] The dormant state says "check in" three times and teaches nothing**
- Why: `emptyStateBlock` (224-245) renders title + descriptor + invite as three restatements of one idea. Measured 382-435px of void beneath. This is the genuinely empty state and the most common first-run view.
- Fix: add the two axis lines from PulseInfoSheet.swift:95-98 to the empty state only. ~60px, self-deleting the moment hasHistory flips.
- Command: /impeccable onboard

**[P1] Us overflows while Me under-fills**
- Why: frames 5/6/7/9 exceed the 844pt frame; frame 6 needs 967px, and no tab bar is modelled. The shelf was designed as three cards without checking they fit.
- Fix: condense the Us Pulse card, or accept scroll deliberately rather than by accident.
- Command: /impeccable layout

**[P2] Mockup token drift**
- Why: off-palette `#9B59B6`, nine type steps, radius 3/10px, a 4s tempo matching neither sanctioned speed. If Phase 3 agents build against this file, they inherit a dialect of the design system.
- Fix: correct the mockup before it becomes the Screen Brief's reference.
- Command: /impeccable polish

## Persona Red Flags

**Jordan (Confused First-Timer)** — lands on frame 4 or 2, the tab's actual first impression. The 15pt textTertiary glyph is the only door to what any of this means, and at that size reads as decoration. "Exploring · 14 weeks on Vayl" is a status Jordan never set. Tapping the hero commits to five questions with no preview.

**Casey (Distracted Mobile User)** — the entire hero is one undifferentiated tap zone inside a ScrollView; a scroll-flick that registers as a tap opens a full-screen cover. Measured, every "tap"-labelled text element is under half the 44pt minimum: `.expand-hint` 15pt, `.history-dot` 18pt (6pt gaps), `.invite` 17pt. Only the orb clears.

**Rowan (curious, partner-cautious, alone at 11pm)** — derived from PRODUCT.md. The highest-stakes sentence for Rowan is textTertiary caption at the very bottom, after the tap. Their partner's name sits permanently on their private page at 0.45 opacity, one accidental tap from switching lenses. Every sentence that would settle them is behind the glyph they will not find. For Rowan the Me lens is not too empty — it is missing the one paragraph that makes it safe to use.

## Minor Observations

- MapView.swift:131-139 — a `#if DEBUG` Path button renders above the hero inside the Me column, polluting every debug-build feel-check of this exact screen.
- MapPulseHero.swift:117 and :150 — two unresolved FEEL markers (label→orb gap; invite colour). This tab has not had its feel pass; some of "too empty" may resolve to "the label→orb gap is wrong."
- MapRecord.swift:28 — "the Map begins to learn the shape of your conversations" is a register outlier and implies the app learns about the user. Moot once it moves to Play.
- Contrast: nothing in the Me lens fails 4.5:1. `--ink-3` clears at 5.32 but with ~18% headroom, applied at the two smallest sizes. `.expand-hint` is smallest × lowest × italic — the lowest-legibility combination present. `--ink-muted` at 1.76 is a hard fail if ever used for text; it is not.
- Reduced motion in the mockup is correct: 1 animation, 1 covering block, removes the loop rather than slowing it.
- Fonts load correctly; `document.fonts.check('16px ClashDisplay')` returning false is a weight-400 query artifact, not a fallback.

## Verdict on the proposed fix

**Reject as stated. Salvage the instinct.** Inlining PulseInfoSheet under a "More about Pulse" divider costs:

1. It makes read-once content permanent. An explainer has a read-once lifespan; a hero is for every visit.
2. It orphans the glyph, reversing a just-completed four-targets-to-two consolidation.
3. **It undoes the distillation on the distillation's own logic.** PulseInfoSheet.swift:24-26 cut the last-check-in copy because "the hero it opens from is already showing exactly that, two taps of nothing away." Proximity was the reason to cut. Inlining maximizes proximity.
4. Volume: ~300-360px. Me stops being a one-screen mirror and becomes a scrolling doc page with a hero as its header.
5. Register: the six-space legend directly under a hero naming *one* space converts a legend into a scale you have been placed on. In a sheet it is a key; inline under your own reading it is a ranking.
6. The divider advertises the thinness. "More about Pulse" — more than what?

**It does NOT break the Void Rule.** That rule governs chrome and constant-sizing, not content volume. Cite the Void Rule against this and you lose the argument; cite humility and you win it. It also does not violate "don't reach to connect features" — a Pulse explainer under a Pulse hero is the same feature.

**Alternatives, ranked:** (A1) two axis lines in the dormant state only, self-deleting on first check-in, ~60px. (A2) promote the reassurance sentence above the hero, demote the exposure warning, ~32px, one moved string. (A3) expand the paired history strip by default — one boolean, ~120px of the user's own record rather than the app's explanation of itself. (A4) do nothing to frame 1; seven pieces of information under a glowing orb is not empty.
