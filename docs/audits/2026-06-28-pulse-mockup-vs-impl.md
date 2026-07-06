# Pulse Mockup vs Implementation Audit — 2026-06-28

You are doing a design-fidelity audit. Read the HTML mockups and the Swift
implementation files, then produce a gap report: what the mockup specifies
vs what the code actually does, with a concrete fix for each gap.

---

## Scope

Three surfaces. Audit each independently.

### 1. Map tab — Me layer (single-user circumplex field)

**Mockup:** `docs/prototypes/map-pulse-final.html`
**Swift files to read:**
- `Vayl/Features/Pulse/Components/PulseField.swift`
- `Vayl/Features/Map/Components/MapPulseHero.swift`

### 2. Map tab — Us layer (two-aura comparison)

**Mockup:** `docs/prototypes/map-pulse-us.html`
**Swift files to read:**
- `Vayl/Features/Pulse/Components/PulseField.swift`
- `Vayl/Features/Pulse/Components/PulseCapsule.swift`
- `Vayl/Features/Map/Components/MapUsLayer.swift`

### 3. Home tab — Pulse rail widget (dormant + active states)

**Mockup:** `docs/prototypes/home-pulse-aura.html`
**Swift files to read:**
- `Vayl/Features/Home/Components/HomePulseRail.swift`
- `Vayl/Features/Pulse/Components/PulseAura.swift`

---

## How to audit each surface

Read the HTML first: extract the exact CSS values (colors, opacity, blur, font
sizes, spacing, animation timing, border-radius, layout structure). Then read
the Swift and check whether the implementation matches.

For each gap, record:

| # | Surface | Element | Mockup spec | Current impl | Severity | Fix |
|---|---------|---------|-------------|--------------|----------|-----|

**Severity:**
- `P0` — visually broken or wrong shape/color; can't ship
- `P1` — clearly off vs mockup on direct comparison
- `P2` — subtle, needs a feel pass to confirm

---

## Known gap (pre-seeded — do not re-derive)

**P0 — Zone rendering creates hard rectangular boundary (all three surfaces)**

The HTML `.zone` is a 74%-wide circle with `border-radius: 50%`,
`filter: blur(26px)`, `opacity: .16`, positioned at `-7%` from its corner
so it overflows the field boundary. The field has no background.

The Swift `PulseField.zones` uses `RadialGradient` fills that paint the entire
`frame(width: size, height: size)` rectangle. The rectangle is why the field
reads as a hard square on every surface.

Fix is fully documented in:
`docs/handoffs/2026-06-28-pulse-field-zones-fix.md`

Do not spend time re-deriving this one. Note it in your table as pre-confirmed
P0 and move on.

---

## What to produce

A markdown report with:

1. **Gap table** — one row per finding, sorted P0 → P1 → P2 within each surface.

2. **For each P0/P1 gap:** a short prose block with:
   - The exact HTML value (CSS property + value)
   - The exact Swift value (file:line, code snippet)
   - A one-sentence fix description

3. **Per-surface summary** — one paragraph per surface: overall fidelity score
   (rough %), biggest visual delta, and the single most impactful fix.

4. **Global summary** — what pattern of gaps appears across all three surfaces
   (e.g. "opacity values are consistently 1.5× too high", "blur is missing
   everywhere").

Do not propose new features. Do not audit anything outside the listed files.
Do not comment on architecture or code quality — only visual fidelity gaps.
