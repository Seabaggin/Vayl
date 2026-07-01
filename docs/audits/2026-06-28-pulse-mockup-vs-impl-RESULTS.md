# Pulse Mockup vs Implementation — Audit Results — 2026-06-28

Design-fidelity audit of three Pulse surfaces against their HTML mockups. Scope and
method per `docs/audits/2026-06-28-pulse-mockup-vs-impl.md`.

## Two facts that frame everything below

1. **The pre-seeded P0 (zone rectangle) is already fixed in code.** `PulseField.zones`
   (`PulseField.swift:50-66`) now renders the handoff's `zoneBlob` — `Circle()` +
   `.fill(opacity 0.16)` + `.blur(size * 0.105)` + `.position(0.30/0.70)`, no `.clipped()`.
   That is the documented fix verbatim. Status: **resolved in code, verify on device.**
   No other outstanding P0 exists on any surface.

2. **The mockup is a 288px phone standing in for a ~390pt device (≈1.33× scale).**
   `.phone{width:288px}` (map) / `300px` (home); `.field{width:248px}`. A mockup px maps
   to roughly `px × 1.33` pt on device. So I scaled every absolute-size comparison —
   doing this dissolves most "the font is bigger than the CSS" noise and leaves the gaps
   that survive scaling. **Within-field ratios** (aura-to-field, capsule-to-aura) are
   scale-invariant and are the truer comparison.

---

## Gap table (sorted P0 → P1 → P2 within surface)

| # | Surface | Element | Mockup spec | Current impl | Sev | Fix |
|---|---------|---------|-------------|--------------|-----|-----|
| C1 | All | Zone hard rectangle | 74% blurred circle, opacity .16, corner overflow | **Already fixed** — `PulseField.swift:50-66` `zoneBlob` matches handoff | ~~P0~~ ✅ | None — verify on device |
| C2 | Me + Us | Zone palette (Protective / Sovereign) | `.z-pro` rose `#C76A86`; `.z-sov` indigo `#8B5CF6` (`map-pulse-us.html:62-63`) | `pulseTierProtective`=magentaLight `#FF4D94` (`AppColors.swift:678`); `pulseTierSovereign`=purple `#6C3AE0` (`AppColors.swift:666`) | P1 | Point zone colors at the aura ramp (`auraCoreRose`/`auraCoreIndigo`) so zones, auras, mockup share one palette |
| C3 | Me + Home | "THE PULSE" eyebrow color | purple-light `#A78BFA` @ .7 (`map-pulse-final.html:42`, `home-pulse-aura.html:61`) | `textTertiary` = white .38 (`MapPulseHero.swift:77`, `HomePulseRail.swift:58,115`) | P1 | Tint the overline purple-light, not gray |
| S1-1 | Me | "Your map" time-window markers | now→1w→1m→3m dots + dashed connector + "Now" tag (`map-pulse-final.html:133-144`) | `MapFieldSheet` renders single current aura + copy only (`MapPulseHero.swift:122-183`) | P1 | Element appears unbuilt — scope decision, not a one-liner |
| S1-2 | Me | Axis labels | 7px, white .2, **outside** field, bottom = "Quiet" (`map-pulse-final.html:75-76`) | 10pt, white .70, **inside** field, bottom = "Depleted" (`PulseField.swift:140-155`) | P2* | Confirm — deliberate per commits `decbb76`/`385b809` |
| S1-3 | Me | Quadrant labels | 8.5px Clash, opacity .7, corners (`map-pulse-final.html:73-74`) | 22pt ghost text, opacity .08/.22, near-center (`PulseField.swift:70-87`) | P2* | Confirm — deliberate per commit `0ae99ec`; matching 8.5pt renderer exists unwired (`PulseField.swift:118-134`) |
| S2-1 | Us | Capsule glow | blue halo `0 0 12px 1px rgba(130,160,230,.18)` (`map-pulse-us.html:56`) | white `.018` near-invisible halo + `.opacity(0.82)` (`PulseCapsule.swift:72-73`) | P1 | Shadow color → bluish ~`rgba(130,160,230,.18)`; drop or raise the 0.82 |
| S2-2 | Us | Aura size vs field | aura = 17.7% of field (44/248) (`map-pulse-us.html:101`) | fixed `auraSize: 44` on ~342pt field = 12.9% (`MapUsLayer.swift:118,121`) | P2 | Size auras ≈ `0.17 × fieldSize` so they (and the capsule) scale |
| S3-1 | Home | Active state name | 14.5px Clash (`home-pulse-aura.html:62`) → ~19pt device | `cardTitle` = 22pt + `lineLimit(1)` (`HomePulseRail.swift:61`) | P1 | Use ~15-16pt display token; 22pt risks truncating "The Protective Space" |
| S3-2 | Home | Dormant ring opacity | dashed border white .22 (`home-pulse-aura.html:59`) | `borderSubtle.opacity(0.55)` ≈ white .033 (`HomePulseRail.swift:102-106`) | P2 | Raise dashed-ring alpha toward white .22 (~6.5× fainter now) |
| S3-3 | Home | Dormant breathe speed | 5.4s (`home-pulse-aura.html:51`) | `cardBreathe` = 3.2s (`HomePulseRail.swift:110`) | P2 | Drive dormant orb at 5.4s like the active aura |
| S3-4 | Home | Widget surface | bg white .06, border white .1, r 18px (`home-pulse-aura.html:53`) | glassSurface white .03, borderSubtle white .06, r 20 (`HomePulseRail.swift:36-41`) | P2 | Bg + border are ~half the mockup's presence |
| G1 | All | Glass-sweep glint cadence | ~8.5s (`map-pulse-final.html:48,182`) | `auraGlassSweep` = 17.0s (`AppAnimation.swift:810`, `PulseAura.swift:105`) | P2 | Halve to ~8.5s — 2× too slow everywhere |
| G2 | All | Aura body light/deep hex | `--cl #7FE0FF`, `--cd #0A8FD0` (`map-pulse-final.html:55`) | `cyanLight #4DD8FF`, `cyanDark #0891B2` (`VaylPrimitives.swift:29-30`) | P2 | Subtle: impl highlight less pale; optional |

\* = delta is real vs the mockup but appears to be a **deliberate post-mockup design change** (the mockup is stale, the code is the newer decision). Flagged for Bryan to confirm, not treated as a bug.

---

## P1 prose blocks

### C2 — Zone palette diverges for Protective & Sovereign (Me + Us)

The field has **two color systems that should be one.** Auras read `quadrant.capacityColor`
(cyan/indigo/magenta/rose — `AppPulseEnums.swift:131-136`), which matches the mockup.
The zone washes and ghost labels read `pulseTier*` tokens, which do **not**:

- **Protective** — mockup `.z-pro{background:radial-gradient(closest-side,var(--rose),transparent)}`
  where `--rose:#C76A86` (`map-pulse-us.html:62`). Impl `zoneBlob(AppColors.pulseTierProtective …)`
  (`PulseField.swift:54`) where `pulseTierProtective` dark = `VaylPrimitives.magentaLight` = `#FF4D94`
  (`AppColors.swift:678-681`). **Bright pink vs dusty rose — wrong hue family.**
- **Sovereign** — mockup `--indigo:#8B5CF6` (`map-pulse-us.html:63`); impl `pulseTierSovereign`
  dark = `VaylPrimitives.purple` = `#6C3AE0` (`AppColors.swift:666-669`). Both violet, but deeper/bluer.

Expansive (cyan `#00C2FF`) and Friction (magenta `#FF006A`) match.
**Fix:** make `zoneBlob` (and `ghostLabel`) read the aura ramp colors, or correct the two
`pulseTier` tokens, so the wash under each aura is the same hue as the aura.

### C3 — "THE PULSE" eyebrow is gray, mockup is purple-light (Me + Home)

- Mockup: `.ovl .k{…color:var(--purple-light);opacity:.7}` and `.pw .k{…color:var(--purple-light)…}`
  where `--purple-light:#A78BFA` (`map-pulse-final.html:42`, `home-pulse-aura.html:61`).
- Impl: `Text("The Pulse").font(AppFonts.overline).foregroundStyle(AppColors.textTertiary)` —
  `textTertiary` dark = white .38 (`MapPulseHero.swift:77-78`, `HomePulseRail.swift:58-60` & `115-117`).

Size is fine once scaled (`overline` 11pt ≈ 8.5px × 1.33). Only the **color** is off, and it's
off the same way in two places. **Fix:** a purple-light overline tint for these eyebrows.

### S1-1 — "Your map" time-window treatment is absent (Me)

Mockup "your map" (`map-pulse-final.html:133-144`) is the whole point of that panel:
a dashed connector `path` flowing up, plus three shrinking/fading markers
(`1w` 10px/.78, `1m` 8px/.5, `3m` 6px/.3) and a `Now` tag above the live aura.
Impl `MapFieldSheet` (`MapPulseHero.swift:122-183`) renders **only** the single
current-position aura + axis labels + read/desc copy. No markers, connector, or tag.
This is the largest single delta on the Me surface. It reads as **unbuilt**, so it's a
scope call rather than a tweak — noting it, not proposing the build.

### S2-1 — Capsule's blue halo is missing (Us)

- Mockup: `.capsule{…box-shadow:0 0 12px 1px rgba(130,160,230,.18)}` — a soft periwinkle
  glow is the capsule's signature (`map-pulse-us.html:56`).
- Impl: `.shadow(color: AppColors.borderSubtle.opacity(0.3), radius: 12)` where
  `borderSubtle` dark = white .06, so effective alpha ≈ **.018** and the hue is white,
  not blue (`PulseCapsule.swift:72`). On top, `.opacity(0.82)` (`PulseCapsule.swift:73`)
  dims the whole stroke. Net: the halo is essentially invisible.

**Fix:** give the shadow a bluish color near `rgba(130,160,230,.18)` (≈ white→indigo blend
token) and reconsider the blanket 0.82.

### S3-1 — Home active state name is oversized (Home)

- Mockup: `.pw .st{font-size:14.5px}` (`home-pulse-aura.html:62`) → ~19pt device-scaled.
- Impl: `Text(quadrant.spaceName).font(AppFonts.cardTitle)` where `cardTitle` = 22pt semibold
  (`AppFonts.swift:117-119`), with `.lineLimit(1)` (`HomePulseRail.swift:61-64`).

22pt vs ~19pt scaled is +14%, and at 22pt the longer names ("The Protective Space",
"The Expansive Space") will crowd or truncate inside the rail's middle column next to a 50pt
orb and a trailing chevron. **Fix:** a ~15-16pt display token for this label.

---

## Per-surface summaries

**Surface 1 — Me (`map-pulse-final.html`): ~80% fidelity.** The glance is strong — 148pt aura
(`MapPulseHero.swift:32`) matches the mockup's 148px, with state name, sublabel, and the
"Brighter than yesterday" weather line all present. Biggest delta: the **"your map"
time-window treatment is entirely absent** (S1-1) — the tap-through shows a static single-aura
field, not the now→1w→1m→3m story. Axis and quadrant labels also differ, but those read as
deliberate post-mockup decisions (commits `decbb76`/`0ae99ec`), so the mockup is stale there,
not the code. **Most impactful fix:** decide whether the time-window markers ship; that panel
is the surface's headline idea.

**Surface 2 — Us (`map-pulse-us.html`): ~75% fidelity.** Two auras + capsule + split grid are
all wired, and the capsule geometry (capH = aura × 1.42, collapses to a ring when coincident —
`PulseCapsule.swift:46,50`) faithfully mirrors the CSS. Biggest visual delta: the **capsule's
periwinkle halo is missing** (S2-1) — it's the connector's whole personality and currently reads
as a thin near-flat stroke. Compounding it, the fixed 44pt aura makes both orbs and the capsule
proportionally thin on a full-width field (S2-2), plus the Protective zone is pink not rose (C2).
**Most impactful fix:** restore the capsule's blue glow.

**Surface 3 — Home (`home-pulse-aura.html`): ~85% fidelity.** Structurally the closest match —
dormant↔active swap, "2h ago", chevron, "Check in" CTA, and "A quick check-in" copy all line up,
and using the real `PulseAura` for the active orb (`HomePulseRail.swift:54`) is *more* faithful to
intent than the mockup's simplified 2-stop orb ("the live aura," per the mockup's own caption).
Biggest delta: the **active state name at 22pt** (S3-1) is heavier than the mockup's 14.5px and
risks truncation. Secondary: the glass container, dormant ring, and dormant breathe are all a bit
fainter/faster than spec (S3-2/3/4). **Most impactful fix:** drop the state name to ~15-16pt.

---

## Global summary — the patterns across all three

1. **One palette split into two.** Zones + ghost labels use `pulseTier*`; auras use
   `capacityColor`. They agree only on Expansive/Friction. Protective (pink #FF4D94 vs rose
   #C76A86) and Sovereign (purple #6C3AE0 vs indigo #8B5CF6) drift from both the mockup and the
   auras sitting on top of them. **Unifying the palette fixes the single most repeated color gap.**

2. **Glass and borders run ~half strength everywhere.** `glassSurface` = white .03 vs mockup
   glass .06; `borderSubtle` = white .06 vs mockup border .10. The same root makes the capsule
   halo (.018 vs .18) and the dormant ring (.033 vs .22) nearly invisible. If anything reads
   "too subtle / washed out" on device, this token gap is why.

3. **The accent that's missing is purple-light.** The "THE PULSE" eyebrow is the mockup's one
   purple-light flourish (#A78BFA); impl renders it gray on both Home and Map.

4. **Fixed pt where the mockup is proportional.** `auraSize: 44` is passed as a literal onto
   fields that flex to screen width, so auras (and the capsule derived from them) shrink relative
   to a large field. Mockup sizes are all `%`/ratio.

5. **Two timings are off.** Glass-sweep glint is 17s vs the mockup's ~8.5s (2× slow, all auras);
   the dormant orb breathes at 3.2s (`cardBreathe`) vs 5.4s. Body breathe and caustic drift
   (5.4s / 7.0s) are correct.

6. **Font sizes are mostly fine once scaled — don't mass-shrink them.** Applying the 288px→390pt
   1.33× factor, `overline`, `caption`, and the glance `screenTitle` all land on spec. The real
   size outlier is Home `cardTitle` (S3-1).

7. **Some "gaps" are the mockup being stale, not the code wrong.** The big ghost quadrant labels
   (`0ae99ec`) and the Charged/Depleted axis labels at white .70 (`decbb76`/`385b809`) are newer
   deliberate decisions. Treat those as "update the mockup," and confirm before reverting.

**If you fix three things:** (1) unify the zone/aura palette [C2], (2) restore the glass/border
token strength so the capsule halo and dormant ring return [pattern 2 / S2-1 / S3-2], (3) drop the
Home state name to ~15pt [S3-1]. That closes the highest-impact visual deltas across all three.
