# Couple Session — UI Design Prompt Pack

**Date:** 2026-06-20
**Source:** Distilled from the 2026-06-20 design-direction conversation (model selection → UI design path).
**Operates on:** [Design spec](2026-06-20-couple-session-quickplay-design.md) (8 wireframed screens) → feeds [Build plan](../plans/2026-06-20-couple-session-quickplay.md).
**What this is:** A 5-pass (+1 optional) prompt sequence for taking the session from "wireframes + a card carousel" to a settled visual look and a documented component set. Each pass is scoped to ONE skill and meant to run in a **fresh session** (matches the per-segment habit + keeps context lean).

---

## How to use

- Run the passes **in order**. Each one's output is the next one's input.
- Start each pass in a fresh chat. Paste the **Shared context** block, then the pass's prompt.
- The **anchor rule:** Pass 2 (the hero, Screen 3) is load-bearing — everything else inherits its chrome. Do **not** start Pass 4 until Pass 3 has converged the hero. A settled hero turns seven hard screens into seven easy ones; an unsettled hero turns them into ninety.
- Output of this pack = HTML protos (your house style) + a component spec. The **build plan's "Discuss UI/UX first" gates consume these** — this is the design phase that precedes code, not code itself.
- Swift-native feel moments (3-sec hold-glow ramp, breathing `✦` transition, simultaneous 3-2-1 reveal) are **not mockup passes** — build those on device. Flagged inline below.

## Skill order at a glance

| Pass | Skill | Produces | Model · effort |
|---|---|---|---|
| 1 | `imagegen-frontend-mobile` | Visual north-star board (vibe only, images) | Opus 4.8 · high |
| 2 | `mobile-ios-design` | Hero mockup — Screen 3, buildable HTML proto | Opus 4.8 · high |
| 3 | `design:design-critique` | Converged single hero direction (anti-sprawl gate) | Opus 4.8 · high |
| 4 | `mobile-ios-design` | The protected-cover family (airlock 1A/1B, transition, close) | Sonnet 4.6 · medium |
| 5 | `design:design-system` | Documented new-component set (6 components, states) | Sonnet 4.6 · medium |
| 6 *(opt)* | `design:accessibility-review` | WCAG / Dynamic Type findings on the full ribbon | Sonnet 4.6 · medium |

**Skip:** `frontend-design`, `high-end-visual-design`, `design-taste-frontend` — web/landing-page skills; taste transfers but the output format doesn't fit iOS screens.

---

## Shared context — paste into EVERY pass

```
PROJECT: Vayl — a SwiftUI couples app, iOS 26 / Swift 6, iOS 16+ baseline.

FEATURE: The in-person, two-device "quickplay" couple card session. Two partners
in the same room, each on their own phone, alternate drawing a card, reading it
aloud, and both answering the same prompt — eyes up, phone set down.

VISUAL REGISTER for the session (this is the new thing to establish):
calm · glanceable · eyes-up · warm-minimal · low-chrome. The prompt dominates;
the screen is never something to stare into. This is DELIBERATELY a different
register from our two existing polished surfaces:
  - Onboarding (OB) = ceremonial, dramatic, heavy glow. Reference its VOCABULARY,
    but the session is calmer and lower-chrome than OB.
  - Paywall = conversion, hierarchy. Reference its applied-token discipline.

AESTHETIC DNA: "void + spectrum + glass" — dark void background, a cyan→purple→
magenta spectrum gradient on strokes/accents, glass surfaces, aurora radial blobs
(AppColors.auroraBlob1/2). NOTE: AtmosphereView / .glassCard() / .hairline() do
NOT exist for the main app — use AppColors.auroraBlob1/2 and .cardStyle() /
SpectrumHairline.

NON-NEGOTIABLE TOKEN CONTRACT (see CLAUDE.md): every color, font, spacing, radius,
opacity, and duration must be expressible as a Vayl design token — AppColors,
AppFonts, AppSpacing (xxs2/xs4/sm8/md16/lg24/xl32/xxl48), AppRadius (container=20
for full cards), AppGlows, AppAnimation. Design in token-expressible values so the
HTML→SwiftUI translation is mechanical. No raw hex in the final layout rationale.

REFERENCE FILES (read before producing anything):
  - CLAUDE.md — the design-token contract (the constraint).
  - docs/superpowers/specs/2026-06-20-couple-session-quickplay-design.md — the 8
    wireframed screens, locked decisions, and the open questions a mockup resolves.
  - Vayl/Features/Monetization/Views/PaywallSheet.swift — most recent polished
    applied-token surface (spacing rhythm, hero treatment, button hierarchy).
  - Vayl/Design/Components/Cards/VaylCardFace.swift + CardStyle.swift +
    CardCarousel.swift — the built session card shell to EXTEND, not replace.
  - Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift +
    Vayl/Design/Components/Effects/GlowOrb.swift +
    Vayl/Design/Components/Text/LivingText.swift — the aesthetic ceiling
    (spectrum/glass DNA); session = "calmer, lower-chrome than this."
  - docs/prototypes/play-arcade.html + docs/prototypes/home-final.html — the
    house style + format new protos must match.
```

---

## Pass 1 — Visual north-star  ·  `imagegen-frontend-mobile`  ·  Opus 4.8 / high

**Goal:** Explore the session's visual register as premium concept images — settle the *vibe* before any layout. Images only, no code.

```
[Paste Shared context above.]

Use the imagegen-frontend-mobile skill.

Produce a small north-star board (3 distinct directions) for the couple session's
visual register. Focus the exploration on TWO moments only:
  1. The in-session card (Screen 3) — a single glanceable prompt, eyes-up, minimal
     chrome, set-the-phone-down calm.
  2. The airlock mood (Screen 1A/1B) — the warm friction gate, "settle in," the
     3-sec hold-to-lock-in moment.

Constraints:
  - Controlled palette derived from our void + cyan→purple→magenta spectrum DNA;
    calmer and lower-chrome than the OB canvas.
  - Premium, intimate, warm-minimal. NOT a dashboard, NOT busy, NOT a glow-heavy
    ceremony.
  - Frame each screen in a subtle phone mockup; keep focus on the app content.

For each of the 3 directions, give: the palette intent, the chrome philosophy
(how little can the card carry?), and one line on the emotional register. Do NOT
spec exact layout/pixels — this pass is feel, not blueprint.
```

**Done:** 3 vibe directions exist; you can point at one and say "that's the session." → feeds Pass 2.

---

## Pass 2 — Anchor the hero (Screen 3)  ·  `mobile-ios-design`  ·  Opus 4.8 / high

**Goal:** Turn the chosen vibe + the Screen 3 wireframe + the token contract into a **buildable** iOS layout. This sets the chrome vocabulary every other screen inherits.

```
[Paste Shared context above.]
[Paste the chosen direction from Pass 1.]

Use the mobile-ios-design skill.

Design the in-session card — Screen 3 from the spec ("the heart") — as a single
buildable HTML proto matching the house style of docs/prototypes/home-final.html.

It must define the chrome vocabulary the other 7 screens will inherit:
  - top meta row: "Card N · M" + a depth chip (◦ deepening) + a ⏸ pause affordance
  - the prompt, dominating, centered, AppFonts.prompt — glanceable enough to read
    aloud and set the phone down
  - a soft turn cue under the prompt ("✦ Alex's draw — read it aloud")
  - bottom row: "pass" (text button) + "we're ready →" (VaylButton .primary .compact)
  - NO countdown anywhere; eyes-up minimal chrome.

Requirements:
  - HIG-idiomatic; maps cleanly to VaylCardFace + .cardStyle() + VaylButton.
  - Every value annotated with its Vayl token (AppColors/AppFonts/AppSpacing/
    AppRadius). Full-card radius = AppRadius.container (20).
  - Resolve spec open questions #5 (responsiveness beat weight) and #7 (eyes-up
    layout) with a concrete recommendation, and explain the call.

Output: one HTML proto file + a short rationale (the chrome vocabulary the family
inherits). One direction, not a menu.
```

**Done:** One Screen 3 proto with a defined, token-mapped chrome vocabulary. → feeds Pass 3.

---

## Pass 3 — Converge the hero  ·  `design:design-critique`  ·  Opus 4.8 / high

**Goal:** Pressure-test the hero against the spec's intent and the design system; kill weak choices; lock one direction. **This is the anti-sprawl gate — don't generate more variants, converge.**

```
[Paste Shared context above.]
[Paste the Pass 2 hero proto + rationale.]

Use the design:design-critique skill.

Critique the Screen 3 hero proto against:
  - the spec's intent: eyes-up, minimal chrome, no countdown, glanceable, read-aloud
  - the design-token contract (anything not token-expressible is a finding)
  - hierarchy: does the prompt truly dominate? is any chrome stealing attention?
  - the inheritance test: is this chrome vocabulary clean enough for 7 other screens
    to adopt without contortion?

Deliver: prioritized findings, then a SINGLE converged hero direction with the
specific edits to make. Do not propose alternative looks — the job is to converge,
not branch.
```

**Done:** A single locked hero. Apply the edits. **Do not proceed to Pass 4 until this is settled.**

---

## Pass 4 — Radiate the protected-cover family  ·  `mobile-ios-design`  ·  Sonnet 4.6 / medium

**Goal:** Inherit the settled hero chrome; design the airlock + transition + close as one cohesive `.vaylCover` space — a family, not one-offs.

```
[Paste Shared context above.]
[Paste the locked hero (converged Screen 3 proto + chrome vocabulary).]

Use the mobile-ios-design skill.

Design the protected-cover family as HTML protos that INHERIT the locked hero's
chrome vocabulary. Same house style, same token mapping. Cover:
  - Screen 1A — airlock house rules (SpectrumBulletRow ×6 → "We're ready")
  - Screen 1B — bandwidth slider + hold-to-lock-in + "waiting for Alex…" state
  - Screen 2 — transition ("put your phones down. look at each other." + breathing ✦)
  - Screen 7 — close / post-session (reflection word + post-bandwidth + save/done)

Requirements:
  - All four share the .vaylCover chrome; they should feel like one continuous space.
  - Token-mapped values; HIG-idiomatic.
  - Resolve spec open questions #6 (airlock gesture/form) and #8 (bandwidth form:
    slider vs low/med/high; informs vs caps) with a recommendation.

FLAG, do not mock: the 3-sec hold-glow RAMP and the breathing ✦ TIMING are
Swift-native feel moments — note where they live and leave them for on-device build.

Output: four HTML protos + a one-paragraph note on how the family coheres.
```

**Done:** Four protos that read as one space with the hero. → feeds Pass 5.

---

## Pass 5 — Componentize  ·  `design:design-system`  ·  Sonnet 4.6 / medium

**Goal:** Formalize the new pieces into a consistent, documented component set so they're reused, not redrawn per screen.

```
[Paste Shared context above.]
[Paste the locked hero + the family protos.]

Use the design:design-system skill.

From the hero + family protos, extract and document the new session components as a
consistent set that fits the existing Vayl design system. For each: variants, states,
token mapping, and which screens use it.
  - PresetCard (Home entry)
  - BandwidthSlider (airlock + close)
  - HoldToConfirm (airlock)
  - SessionProgressBar (in-session)
  - WhisperField (whisper card)
  - ReCenterSheet (pause)

Requirements:
  - Each component spec'd once, reused everywhere — flag any inconsistency across the
    protos and resolve to one definition.
  - Token-only; note the empty/disabled/active/waiting states each needs.

Output: a component spec sheet that the build plan's segments can build against.
```

**Done:** A documented component vocabulary feeding the build plan. → optional Pass 6, or hand to the build plan.

---

## Pass 6 *(optional)* — Accessibility  ·  `design:accessibility-review`  ·  Sonnet 4.6 / medium

**Goal:** Run the WCAG / Dynamic Type / touch-target pass on the full ribbon (you did this on the paywall — same bar here).

```
[Paste Shared context above.]
[Paste the locked hero + family protos + component sheet.]

Use the design:accessibility-review skill.

Audit the full session ribbon (Home entry → airlock → transition → in-session →
close) for WCAG 2.1 AA: spectrum-on-void contrast, Dynamic Type scaling (the prompt
must scale without clipping), touch-target sizes, Reduce-Motion fallbacks on the
transition + any looping mark, and screen-reader order on the whisper/private inputs.

Output: prioritized findings with the specific token/layout fix for each.
```

**Done:** A11y findings folded back into the protos/components before the build plan runs.
