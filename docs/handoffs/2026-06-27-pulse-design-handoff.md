# Handoff: Pulse redesign (Map tab) + the stuck capsule detail

Date: 2026-06-27
For: a fresh chat continuing the Pulse visual design.
Status: Pulse is ~95% designed and agreed. One fiddly render bug is blocking final sign-off (the Us "capsule" connector). Everything else is settled and just needs to be written into a spec.

---

## 0. Read these first
- This handoff (you are here).
- `docs/superpowers/specs/2026-06-27-couple-path-roadmap-design.md` — the sibling feature ("The Path"); gives the Map-tab context Pulse lives in.
- The mockups in `docs/prototypes/` listed in §6.
- Memory: `path_roadmap_feature.md`, and the user-preference memories (no em dashes, don't over-engineer, don't reach to connect features, design-consultant-not-lackey, Bryan runs on device / Claude compile-verifies only).

## 1. Where this sits
We are designing the **Map tab**. It finalized to **three pillars, same on both lenses: The Pulse → The Path → The Vault**, with the masthead Me/Us name-toggle (`Jordan.` / `Jordan & Alex.`). **Pulse is the hero.** We have spent this whole session finalizing **Pulse's visual design**. The Path feature already has a written spec (see above). The Vault is later.

## 2. Pulse — SETTLED decisions (do NOT relitigate)
Pulse = the daily emotional **capacity** check-in. Hero of the Map. Lens-aware (Me = you; Us = you + partner).

**The model (settled after a debate + red-team, both summarized in this session):**
- Capacity is a **2D circumplex** (the "How We Feel" Mood Meter model): vertical axis = **energy** (Quiet↔Charged), horizontal = **openness** (Guarded↔Open). The four quadrants ARE the existing `PulseTier` states:
  - top-right charged+open = **Expansive** (cyan) · "Connected · Adventurous"
  - top-left charged+guarded = **Friction** (magenta)
  - bottom-left quiet+guarded = **Protective** (rose)
  - bottom-right quiet+open = **Sovereign** (indigo)
- Tier colors are the real `PulseCapacityColor`: cyan=Abundant, indigo=Good, magenta=Low, rose=Empty.
- A graph (the old 2-line capacity-over-time) was REJECTED as too "stock chart." The aura+2D map won the debate. Red-team confirmed it survives with hard guardrails (below).

**The aura form (FINAL — took many rounds):**
- It is a **glowing circle**, NOT a 3D ball (the glossy off-center highlight made it a "billiard ball"), NOT a soft nebula (color went muddy), NOT a faceted gem/diamond (felt forced).
- FINAL = **"living caustic under glass"** (`docs/prototypes/pulse-aura-glass.html`, the approved one): a clear tier-color body + a **caustic interior** (light drifting like sun through water, `mix-blend:screen` light blobs) + a **glass specular sweep** + a soft inner **rim**.
- The glass sweep is the real **StatPhase "1 in 5" recipe** from `Vayl/Design/Components/Text/HolographicText.swift` (a soft white diagonal band, primary + softer secondary). It is **incremental**: crosses once every ~8s then rests (NOT a constant loop — it lives on Home, must not be attention-bait).
- Color must read CLEARLY through the glass; verified across all four tiers.

**The three views:**
1. **Glance (hero):** the aura + named state ("The Expansive Space · Connected · Adventurous") + a weather one-liner + the weather grid.
2. **Your map (Me):** the 2D field showing your **current position only**. NO history plotted in the field (a dot-trail and time-window markers were both REJECTED — see §3).
3. **Us:** two auras in the field + the **capsule** connector + the split-circle grid.

**History / movement (settled):**
- The field is **NOW only**.
- History = the **weather-calendar grid**. It tracks the **last 30 *check-ins* (logged), NOT 30 calendar days.** Missing days NEVER appear — this is not a habit/fitness tracker and must never read like a streak (humility line, explicit user instruction).
- Movement over time = a **one-line text cue** ("more open than last week"), not plotted dots.
- **Me grid** = solid single-color cells (your tier each check-in). **Us grid** = **split circles** (half your tier / half Alex's; solid when you shared a space; one half if only one of you logged that time). Tapping a cell would open that day's field.

**The Us comparison (settled, except the render bug in §4):**
- The **capsule is the ONLY connector** (no line/thread).
- It **encloses both orbs** at its rounded ends — `(O.        O)` — stretches with the distance, and **collapses to a tight ring** when the two are in the same space.
- Copy: headline "A wide day between you" / "Close today", then descriptive "**You're in the Expansive space; Alex is in the Protective space.**" Names each person's own state, never a verdict.

**The Home tab:** the Pulse Module (Module 2 of Home's Deck→Pulse→Lexicon) swaps its old expanding-graph for a **compact aura widget** (`docs/prototypes/home-pulse-aura.html`): dim/dashed "tap to check in" when dormant, the live aura when active. The check-in **ceremony** (the old matched-geometry expansion) becomes: tap → the aura expands into the 2D field → answering pills move your aura into a quadrant → on the last answer the aura **blooms** (replaces the old "ink line draw") → collapses back. Solo only; the comparison is a separate Map view.

**Guardrails (non-negotiable, from the red-team):**
- Never aggregate history into a "type"/verdict (assessment line). Show, do not analyze. Trail-style accumulation is banned (this is why we dropped in-field history).
- No streaks, no calendar-gaps, no completion/XP. Last-N-logged only.
- Weather language, never identity ("an Expansive day", never "you are Expansive").

## 3. Things already TRIED and REJECTED for in-field history (don't redo)
- A fading dot-**trail** of past check-ins — confusing, and the assessment-risk vector.
- **Time-window markers** (1w/1m/3m clusters) — breaks across usage (daily logger = cloud, rare logger = nothing), and is the same assessment risk.
- Conclusion: **no history in the field.** Grid + text cue only.

## 4. THE STUCK POINT (the immediate task)
File: `docs/prototypes/map-pulse-us.html`. Two phone frames: "a wide day" and "same space".

**Requirement:** the capsule/oval must be a slim rounded-stadium that **closes around each orb at its rounded caps with clearance** (`(O        O)`), line NOT cutting through the orbs; stretches with distance; collapses to a snug ring when the orbs are close.

**What went wrong (the rabbit hole):** the capsule kept rendering misaligned with the orbs (the line slicing through them). I tried SVG `<rect>` (rotated stadium), SVG `<ellipse>` (tapers and slices), many sizes. The math (cap-center distance == orb-center distance) checked out every time, but the render disagreed.

**Two real causes found:**
1. **Glow collision:** the orb's box-shadow glow made the *visible* orb radius ≈ body 22 + glow ~13 = **35**, larger than the cap radius (30). So the line at 30 sat *inside* the glowing orb. Fix applied: tightened the field-orb glow to `0 0 6px 0`.
2. **Coordinate mismatch (the likely main bug):** the orbs are positioned in **CSS percentages of the 248px field**, while the capsule was an **SVG with `viewBox="0 0 248 248"`**. They did not render 1:1 (the SVG caps landed inward of the orbs). 

**Latest attempt (UNVERIFIED — Bryan called it before confirming):** I rebuilt the capsule as a **plain CSS div** (`.capsule`, gradient-border-via-mask, transparent interior) positioned in the SAME coordinate system as the orbs:
- centered on the two orbs' **midpoint** (wide: `left:50% top:50%`; same-space: `left:65% top:35%`), `transform: translate(-50%,-50%) rotate(-45deg)`.
- size: `width = 2*(orbDist + capRadius)`, `height = 2*capRadius`, `border-radius:999px`. Wide: 216×62. Same: 97×62. cap radius ~31, orb visible ~28 → should clear.

**What the next chat must do:** OPEN IT IN A BROWSER and look (do not trust the math — there is a render gotcha). If the CSS capsule still misaligns, the bulletproof move is to render the **orbs AND the capsule inside ONE SVG** (so they share the viewBox exactly), e.g. orbs as `<circle>` with gradient/glow filters and the capsule as a stadium `<path>` built directly from the two circle centers. Field is 248×248px; wide orbs at field 72%/28% and 28%/72% (centers (178.56,69.44) and (69.44,178.56), r=22); same-space orbs at 70%/30% and 60%/40%.

## 5. After the capsule is fixed
1. Update `docs/prototypes/map-pulse-final.html`'s Us panel to match (capsule + split-circle last-30-logged grid).
2. **Write Pulse into the spec** — either a Pulse section appended to the Path spec or a new `docs/superpowers/specs/2026-06-27-pulse-design.md`: the circumplex model, the living-caustic-under-glass aura (+ the StatPhase recipe ref), field-is-now, the capsule, the split grid (last-30-logged), the Home widget, the ceremony, and the guardrails.
3. Return to the rest of the **Map tab** (build The Path per its spec; then The Vault).

## 6. Files (state)
- `docs/prototypes/map-pulse-us.html` — the **stuck** Us mock (capsule).
- `docs/prototypes/pulse-aura-glass.html` — **the approved final aura** (living caustic under glass, incremental glass sweep, 4 tiers).
- `docs/prototypes/map-pulse-final.html` — 3-panel Pulse (glance / your-map-NOW / Us); Us panel needs the final capsule + split grid.
- `docs/prototypes/home-pulse-aura.html` — Home Pulse widget (dormant/active).
- `docs/prototypes/map-layout-blocking.html` — Map tab 3-pillar blocking (Pulse hero).
- Exploration history (context only): `map-pulse-resolved.html`, `pulse-aura-forms.html`, `pulse-aura-forms-v2.html`, `pulse-aura-forms-v3.html`, `pulse-aura-circles.html`, `pulse-aura-circles-v2.html`, `map-me-us.html`, `map-vault-options.html`, `map-roadmap-*.html`.

## 7. Real tokens / code refs (use these, not approximations)
- Colors (`Vayl/App/Theme/VaylPrimitives.swift`): cyan `#00C2FF`, cyanLight `#4DD8FF`, purple `#6C3AE0`, spectrumBridge `#8B6FD4`, magenta `#FF006A`, magentaLight `#FF4D94`, electricViolet/indigo `#8B5CF6`, rose ≈ `#C76A86`; inkVoid `#0a0810`, inkCardOB `#120f1a`, inkText `#E8E8F0`.
- Fonts (`AppFonts.swift`): Clash Display (display), Switzer (body).
- `Vayl/Design/Components/Text/HolographicText.swift` — the StatPhase "1 in 5" glass recipe (the glass sweep).
- `Vayl/Design/Components/Progress/OrbitIndicator.swift` `.complete` — gradient fill + 3-layer spectrum glow (node treatment ref).
- `Vayl/Core/Models/Enums/AppPulseEnums.swift` — `PulseCapacityColor` (rose/magenta/indigo/cyan) + `PulseTier` (Protective/Friction/Sovereign/Expansive, named "Spaces").
- `Vayl/Features/Pulse/Store/PulseStore.swift` (@Observable, entries w/ capacityScore + glowColor) + `PulseSyncService` (capacity sharing, RLS-gated).
- Home structure: `Vayl/Features/Home/Views/HomeDashboardView.swift` (Deck → Pulse → Lexicon), `Vayl/Features/Pulse/PulseWidget.swift` (the old graph widget being replaced; note it already has an `OrbLayer .pulse`).

## 8. Working style (Bryan's preferences)
- No em dashes in copy or in replies (commas/colons/periods).
- Mock in HTML → feel it → port to Swift. Bryan runs on device; Claude compile-verifies only.
- Use the real design tokens.
- Do NOT over-engineer / overthink (he flagged this on the aura). Slim, simple, intentional.
- Don't reach to connect features unprompted.
- He has strong visual taste: surface options, push back as a real design consultant, never sycophantic. Verify visuals in the browser, do not trust math alone (this whole capsule saga is why).
