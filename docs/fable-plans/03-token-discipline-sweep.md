# Plan 03 — Token Discipline Sweep (structural chrome only)

**Goal:** In one pass, retire a bounded set of *structural-chrome* token violations in active, non-Settings code — repointing reconstructed fonts to the `AppFonts` constructors, tokenizing the handful of genuine shadow-as-glow and animation/spacing literals that have an exact token match — **without touching a single hand-tuned felt value.** The finished pass compiles green and leaves every tuned aesthetic (gradients, shaders, ceremony timing, multi-radius glows) exactly as it was.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

## 🚨 SCOPE BOUNDARY — read this before you touch anything

**This is the most judgment-heavy of the debt plans.** The audit's §4 raw counts (~72 raw fonts, 75
shadow-as-glow, ~85 animation literals) are *inflated for this plan's purposes* because most of those
sites are one of: (a) dead code, (b) icon point-sizing on `Image(systemName:)` rather than typography,
(c) hand-tuned felt values the audit itself left "alone by design," or (d) `#Preview`-only. When
verified against the live tree on 2026-07-01, the genuinely-mechanical, exact-match swap surface is
**small**. This plan sweeps *only that small surface*.

### The one test that governs every edit in this plan

> **Swap structural chrome. Never touch a felt value.**
>
> A value is **structural chrome** (swap it) when it is a bookkeeping default that happens to be typed
> as a literal — a font that is literally `Font.custom` reconstructing an existing `AppFonts` token at
> the *exact* same family+size, a stack `spacing:` that *exactly* equals an `AppSpacing` step, a
> reactive animation that is *exactly* one of the reactive tokens.
>
> A value is **felt** (LEAVE IT) when someone sat with it on a device and dialed it: a gradient stop, a
> shader constant, a ceremony duration, a multi-layer glow with per-site radii, anything with a `FEEL`
> / `FEEL-GATE` / `// intentional` / `// was X → Y` / `// tune on device` comment, anything with no
> exact token that would need a *new* token or a *nearest-fit* substitution to land.

**If a swap requires you to invent a token, pick a "close enough" token, or change a number, it is NOT
in scope. Skip it and note it in Open Decisions.** Flattening tuned aesthetics into the nearest token
is the exact failure mode this plan exists to prevent.

### Two hard exclusions (do not plan or make any edit in these)

1. **Everything under `Vayl/Features/Settings/*`** is owned by plan `04-settings-and-account.md`. The
   Settings font/card-chrome cleanup (audit H-4) happens there, not here. `Vayl/Features/Pairing/*` is
   a *separate folder* and **is** in scope for this plan (the audit groups "Pairing views" with the
   font debt) — do not confuse `Pairing/PairingSettingsView.swift` (in scope) with the `Settings/`
   feature (excluded).
2. **The ~118 deliberately-tuned gradient / shader / ceremony stop-values** the color pass already
   left "alone by design" (audit §4 "Color cleanup — done"): `CandleCardFace`'s 26 gradient stops,
   `SplashScreenView` gradients, `DeckCaseView` gradients, `HolographicShimmer`'s 17. Felt, not debt.
   **`VaylCardFace` is entirely off-limits** (shell rule, CLAUDE.md).

### Coordination with sibling plans (do not duplicate their work)

- **`CardCarousel` Reduce-Motion gating** (the three `.repeatForever` idle loops at lines 110/117/123,
  and their sibling loops at 729) is owned by plan `02-correctness-and-a11y-hardening.md`. **This plan
  does not touch any `.repeatForever` loop or add any RM gate in CardCarousel.** Here we only consider
  *non-looping reactive* timing literals — and after verification (see Segment 3) there are effectively
  none left to swap, because they all carry `// intentional above ceiling` justifications.

---

## Context Fable needs

- **This is a debt sweep, not a feature.** No new screens, no behavior change. Every edit is a
  1-for-1 token substitution that produces identical pixels (same font family/size, same radius, same
  gap). If any edit would change how something looks or feels, it is out of scope by definition.
- **Token source of truth — read these first (already verified for you below):**
  `Vayl/App/Theme/AppFonts.swift`, `AppColors.swift`, `AppGlows.swift`, `AppAnimation.swift`,
  `AppSpacing.swift`. Exact token names are quoted inline in each segment. **Never invent a token.**
- **`AppFonts` has two constructors** — `AppFonts.display(_:weight:relativeTo:)` (ClashDisplay) and
  `AppFonts.body(_:weight:relativeTo:)` (Switzer) — plus named semantic tokens (`heroTitle` =
  `display(42,.bold,.largeTitle)`, `displayHero` = `display(64,.bold,.largeTitle)`, etc.). A
  `Font.custom("ClashDisplay-Bold", size: 64, relativeTo: .largeTitle)` in a view is *literally*
  `AppFonts.displayHero` reconstructed by hand — that is the canonical "repoint" case.
- **`AppGlows` exposes fixed, purpose-built modifiers**, not a generic "glow with color X radius Y."
  The real modifiers are `spectrumBorderGlow(intensity:)` (fixed 3-layer cyan/purple/magenta button
  glow), `accentFocusGlow(visible:)` (fixed 2-layer accentPrimary), `cornerDeckGlow(visible:)`,
  `safetyGlow(visible:)`, `liftCopyGlow()`. **None of them accepts an arbitrary color+radius**, so a
  single-purpose site like `.shadow(color: AppColors.spectrumPurple.opacity(0.6), radius: 18)` has *no
  drop-in modifier to land on.* This is the central judgment of the glow section (Segment 2) — read it
  carefully before editing.
- **Canonical patterns to imitate:** the Pairing views were *already* mid-sweep — `PairingInviteView`
  / `PairingJoinView` already carry `// was 8 → sm, exact` spacing swaps and `// was .system(size: 14…)`
  font annotations. Match that annotation style exactly (`// was <old> → <token>, exact`) on every edit
  so the diff is self-documenting and a reviewer can confirm each swap is 1-for-1.

---

## Files

### Create
_None. This plan writes no new files and adds no new tokens (see Segment 2 / Open Decision A for why
new glow tokens are deliberately deferred, not created here)._

### Modify

| File | Responsibility (this pass) |
|---|---|
| `Vayl/Features/Pairing/PairingInviteView.swift` | Repoint `Font.custom` sites that match an exact `AppFonts` token; leave size-48 icons (no token). |
| `Vayl/Features/Pairing/PairingJoinView.swift` | Same: repoint the size-64 ClashDisplay glyph to `AppFonts.displayHero`; leave size-48. |
| `Vayl/Features/Pairing/PairingSettingsView.swift` | Repoint the two `Font.custom("Switzer-Medium", …)` sites to `AppFonts.body(...)` at exact size/weight. |
| `Vayl/Features/Desire Map/Views/DesireMapView.swift` | Spacing: `VStack(spacing: 2)` → `AppSpacing.xxs` (line ~161). Glow line 814: leave (felt selection glow, no modifier fits — see Seg 2). |
| `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift` | Spacing: `VStack(spacing: 2)` → `AppSpacing.xxs` (line ~67). |

### Do NOT modify (verified out of scope — listed so you don't "helpfully" sweep them)

| File / site | Why it's excluded |
|---|---|
| `Vayl/Features/Settings/*` (all) | Owned by plan `04`. |
| `Vayl/Design/Brand/SplashScreenView.swift` (8 anim literals) | Each already carries a `/* TODO: AppAnimation.<x> — no token, spec gap */` comment. Felt ceremony timing with **no token to swap to**. Leave. |
| `Vayl/Design/Components/Cards/CardCarousel.swift` (all anim/glow) | RM loops owned by plan `02`; the reactive literals carry `// intentional above AppAnimation.spring ceiling` — felt. Leave. |
| `Vayl/Design/Components/Buttons/SelectablePill.swift` (7 `.shadow`) | Intensity-driven (`.dim`/`.warm`/`.alive`) per-site multi-radius glow. No modifier fits; felt. Leave (see Seg 2). |
| `Vayl/Features/Desire Map/Views/Components/DesireStarView.swift` (5 `.shadow`) | Per-star multi-layer white+magenta+purple bloom, hand-tuned radii. Felt. Leave. |
| `Vayl/Features/Home/Components/DeckPedestal.swift` (2 `.shadow`) | Two-layer purple+cyan pedestal glow, tuned radii. Felt. Leave. |
| `Vayl/Features/Pulse/Components/PulseCapsule.swift` `.shadow(...pulseCapsuleGlow, radius: 12)` | Carries `// soft periwinkle halo (map-pulse-us.html)` — felt, mockup-sourced. Leave. |
| `Vayl/Features/Pulse/Components/PulseAura.swift` `.shadow(...ramp.glow, radius: size*0.27)` | Carries `// FEEL: tune on device`. Leave. |
| `Vayl/Features/Home/Components/HomeLexicon.swift:529` `.shadow(...spectrumPurple.opacity(0.6), radius: 18)` | Single purple text-glow, no modifier fits (see Seg 2 / Open Decision A). Leave this pass. |
| `Vayl/Features/Desire Map/Views/DesireMapView.swift:814` | Single purple selection glow, no modifier fits. Leave. |
| Any `.font(.system(size:…))` on an `Image(systemName:)` | Icon point-sizing, not typography — no text-role token applies (see Seg 1). |
| Dead files (`CategoryTileView`, `ToggleRow`, `OnboardingNavBar`, `SafeWordButton`, `ScoreRing`, `MapPrimitives`, `FilamentMode`, `PrismView`, `ConstellationNode`, `SparkField`, `HomeGateView`, `DesireMapIndicator`, `PartnerChip`*, `TierGuideSheet`, `ProgressDashboardView`, `DiagnosticOverlay`, `DragDebugView`, …) | Retired by plan `01` (dead-code delete). Do not edit dead code. |
| `#Preview` blocks (e.g. `VaylButton.swift:281` `spacing: 32`, `VaylBorderEffect.swift:403` `spacing: 48`) | Preview-only, not shipped. Leave. |

\* `PartnerChip` reachability is ambiguous in the audit; treat as out of scope for this pass regardless.

### Delete
_None._

---

## Build steps (segments)

All four segments ship in one pass. They are ordered for readability. Every edit uses a real, verified
token and carries a `// was <old> → <token>, exact` annotation.

---

### Segment 1 — Fonts: repoint reconstructed `AppFonts` in the Pairing views

**One thing it does:** where a Pairing view spells out a `Font.custom(...)` whose family+size+relativeTo
*exactly* equal an existing `AppFonts` token or constructor call, replace it with the token. Where no
exact token exists (e.g. size 48 ClashDisplay — there is no 48pt display token), **leave it and annotate
why.**

**Why this is the only font work in scope (verified 2026-07-01):** The audit's "~72 raw fonts" almost
entirely resolve to `.font(.system(size:…))` on `Image(systemName:)` icons — `MeCardCompact:55`,
`MeCardSheet:120`, `VaultDesireSection:113/121/147`, `VaultAgreementsSection:44`, `VaultLogSection:52`,
`ContentHubSection:224`, `ResearchDatabaseView:129`, `LearnSegmented:34`, `MapPulseHero:172`,
`MapUsLayer:144` — these size a glyph, not text, and the text-role `AppFonts` scale has no token to map
them onto. The remaining true-text raw fonts (`PulseField:171` axisText 10pt-bold-uppercase,
`CardBackView:171` the ∞ glyph at 28pt, `MapUsLayer:144` 9pt-bold-uppercase tag) have **no exact
`AppFonts` match** (nearest is `overline` at 11pt semibold — a *different* size and weight), so swapping
them would change the render. Those are Open Decision B, not this segment.

The clean, exact-match font swaps are exactly the Pairing `Font.custom` reconstructions.

**AppFonts sizes available for the match (verified in `AppFonts.swift`):**
- `AppFonts.displayHero` = `display(64, .bold, relativeTo: .largeTitle)` = `Font.custom("ClashDisplay-Bold", 64, .largeTitle)` — **exact match** for the size-64 sites.
- There is **no** 48pt display token and **no** `display(48, .bold, .largeTitle)` semantic name. The
  generic constructor `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)` produces the
  identical font, so size-48 sites *can* be routed through the constructor (still "tokens only" — it is
  an `AppFonts` call, not a raw `Font.custom`). That is the correct, non-inventive move.
- `AppFonts.body(14, weight: .medium, relativeTo: .caption)` — exact match for `Font.custom("Switzer-Medium", 14, .caption)`.
- `AppFonts.body(20, weight: .medium, relativeTo: .body)` / `body(12, weight: .medium, relativeTo: .caption)` — exact for the `PairingSettingsView` sites.

#### 1a. `PairingJoinView.swift`

Site at line ~187 (`linkedState`), a decorative checkmark glyph sized 64pt ClashDisplay:

```swift
// BEFORE
Image(AppIcons.checkmarkCircle)
    .font(
        Font.custom("ClashDisplay-Bold", size: 64, relativeTo: .largeTitle)
    )                                   // was .system(size: 64)
    .foregroundStyle(AppColors.accentPrimary)
    .accessibilityHidden(true)

// AFTER
Image(AppIcons.checkmarkCircle)
    .font(AppFonts.displayHero)         // was Font.custom("ClashDisplay-Bold", 64, .largeTitle) → displayHero, exact
    .foregroundStyle(AppColors.accentPrimary)
    .accessibilityHidden(true)
```

Site at line ~212 (`errorState`), the 48pt glyph — route through the constructor (no 48 semantic token):

```swift
// BEFORE
    .font(
        Font.custom("ClashDisplay-Bold", size: 48, relativeTo: .largeTitle)
    )                                   // was .system(size: 48)

// AFTER
    .font(AppFonts.display(48, weight: .bold, relativeTo: .largeTitle))  // was Font.custom("ClashDisplay-Bold", 48, .largeTitle) → AppFonts.display, exact
```

#### 1b. `PairingInviteView.swift`

- Line ~179: `Font.custom("Switzer-Medium", size: 14, relativeTo: .caption)` on the "Copy code" icon →
  `AppFonts.body(14, weight: .medium, relativeTo: .caption)  // was Font.custom("Switzer-Medium", 14, .caption) → AppFonts.body, exact`
- Line ~223: `Font.custom("ClashDisplay-Bold", size: 64, relativeTo: .largeTitle)` → `AppFonts.displayHero  // …→ displayHero, exact`
- Lines ~248 and ~281: `Font.custom("ClashDisplay-Bold", size: 48, relativeTo: .largeTitle)` →
  `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)  // …→ AppFonts.display, exact` (×2)

#### 1c. `PairingSettingsView.swift`

- Line ~171: `Font.custom("Switzer-Medium", size: 20, relativeTo: .body)` →
  `AppFonts.body(20, weight: .medium, relativeTo: .body)  // was Font.custom("Switzer-Medium", 20, .body) → AppFonts.body, exact`
- Line ~192: `Font.custom("Switzer-Medium", size: 12, relativeTo: .caption)` →
  `AppFonts.body(12, weight: .medium, relativeTo: .caption)  // …→ AppFonts.body, exact`

> Note: verify each `Font.custom` string against the live file before editing — the sites were spot-checked
> on 2026-07-01, but the Pairing views were mid-refactor and line numbers may have drifted a line or two.
> The **string content** (`"ClashDisplay-Bold", size: 64` etc.) is the anchor, not the line number.

**Done:** every `Font.custom` in the three Pairing files either references an `AppFonts` token/constructor
at the identical family+size+relativeTo, or is annotated as intentionally left (there are none left after
this segment — all Pairing `Font.custom` sites have an exact `AppFonts` route). Rendered pixels are
byte-identical. `grep -rn 'Font.custom' Vayl/Features/Pairing/` returns nothing.

---

### Segment 2 — Shadow-as-glow: the honest finding (mostly LEAVE, tokenize nothing this pass)

**One thing it does:** apply the "use `AppGlows`, never `.shadow()` for glows" rule *only where an
existing `AppGlows` modifier is a genuine drop-in.* After verifying every audit-named glow site against
`AppGlows.swift` on 2026-07-01, **that set is empty** — so this segment makes **zero `.shadow` edits**
and instead documents, per site, why each is felt or blocked. This is the correct outcome, not a punt:
forcing these onto the wrong modifier would change the render.

**The mechanical fact that governs this segment:** `AppGlows`' View modifiers are *fixed-purpose*, not
parametric. Read from `AppGlows.swift`:

- `spectrumBorderGlow(intensity:)` — hard-codes a 3-layer cyan(0.90)/purple(0.65)/magenta(0.40) glow at
  radii 3/8/16. Only correct for a *spectrum border arc*, not a single-color halo.
- `accentFocusGlow(visible:)` — hard-codes accentPrimary 0.50/0.18 at radii 3/10. Only for input-field /
  pill focus rings.
- `cornerDeckGlow(visible:)`, `safetyGlow(visible:)`, `liftCopyGlow()` — each purpose-locked to one call site.

None accepts an arbitrary `(color, radius)`. So:

| Audited site | Actual shadow | Why no modifier fits → verdict |
|---|---|---|
| `SelectablePill.swift:327-341` (7) | intensity-scaled magenta/purple/gold + accent glows, radii 6→70 via `pick()` | Per-state `.dim/.warm/.alive` multipliers, per-radius `pick()`. This is a bespoke tuned glow system. **Leave.** |
| `DesireStarView.swift:104-105, 203-205` (5) | black-outline + magenta + purple + white core, radii 2/3/5/7/15 | Multi-layer per-star bloom, hand-tuned. **Leave.** |
| `DeckPedestal.swift:73-74` (2) | purple(0.85)@7 + cyan(0.60)@2 | Two-color pedestal glow, tuned radii. **Leave.** |
| `PulseCapsule.swift:72` | `pulseCapsuleGlow`@12 `// map-pulse-us.html` | Mockup-sourced felt. **Leave.** |
| `PulseAura.swift:48` | `ramp.glow`@`size*0.27` `// FEEL: tune on device` | Felt. **Leave.** |
| `DesireMapView.swift:814` | purple(0.28)@11 selection glow (else `.clear`) | Single tuned selection glow; no parametric modifier. **Leave.** |
| `DesireMapView.swift:908-909` | magenta(0.80)@3 + purple(0.40)@7 | Two-layer star glow, tuned. **Leave.** |
| `HomeLexicon.swift:529` | purple(0.6)@18 on the keyword text | Single tuned text-glow; no modifier fits. **Leave.** |

**Do not make any `.shadow` edit in this segment.** The correct long-term fix (adding a small parametric
glow modifier or a `spectrumTextGlow` token to `AppGlows`) is a *token-file change with a felt component*
(someone must confirm the tokenized radii still look right on device), which is exactly the kind of
feel-gated work this one-shot debt sweep must not guess at. It is captured as **Open Decision A** with a
recommended default (defer), so this plan proceeds cleanly.

**Done:** zero `.shadow` lines changed; the table above is the record of why each named site was left,
so a future reviewer does not re-flag them as un-swept oversight.

---

### Segment 3 — Animation literals: swap only exact reactive-token matches (verified: none in scope)

**One thing it does:** replace inline `.easeInOut/.easeIn/.easeOut/.spring/.linear(duration:)` literals
with the reactive `AppAnimation` tokens (`fast` 0.15 · `standard` 0.3 · `slow` 0.5 · `spring` · `enter`
0.4 · `exit` 0.2) **only where the literal is byte-identical to a token AND the site is a non-looping
reactive animation.** After verification, the two "worst active" files the audit named resolve as:

- **`SplashScreenView.swift` (8 literals):** every one already carries
  `/* TODO: AppAnimation.<name> — no token, spec gap */`. These are the splash ceremony's own timings
  (0.30/0.22/0.10/0.25/0.35/0.08 etc.) with **no matching `AppAnimation` token** — the existing splash
  tokens (`splashLineAppear`, `splashReveal`, `splashBloomIgnite`, `splashTear`, …) cover the *other*
  splash beats, and these remaining ones are documented spec gaps. Swapping them to `fast`/`standard`
  would change the ceremony feel. **Leave all 8** (they are self-documenting; do not remove the TODOs).
- **`CardCarousel.swift` (11 literals):** the `.repeatForever` idle loops (110/117/123/729) are owned by
  plan `02`. The remaining non-looping literals are each justified in-comment as intentionally *above*
  the `AppAnimation.spring` ceiling for physical weight — e.g. `:349` `// Intentional low-damping aurora
  spring (0.4 / 0.6)`, `:400` `// Backing card spring — intentional above AppAnimation.spring ceiling`,
  `:652` `.timingCurve(0.4,0,0.6,1, 0.75)` fan-specific, `:686`/`:719` drag-fan springs. None equals a
  reactive token; all are felt. **Leave all.**

**Net verified in-scope animation swaps across active non-Settings code: 0.** There is no active site
where an inline literal is *exactly* a reactive token AND not already justified as felt or RM-looping.
So this segment, like Segment 2, makes **no edits** — and that is the correct, verified result, not an
omission. (The audit's "~85" count is dominated by dead code — `FilamentMode`, `AuroraGlowField`,
`OrbitIndicator` — plus OB-physics/ceremony tokens that are felt by design.)

**Done:** no animation literal changed; this segment's value is the verification record above, so the
"CardCarousel (11) / SplashScreen (8)" audit line is not mistaken for un-done work.

---

### Segment 4 — Spacing: swap stack `spacing:` literals that EXACTLY equal an `AppSpacing` step

**One thing it does:** replace `VStack`/`HStack`/`LazyV*`/`ForEach` `spacing:` **literals that exactly
match** an `AppSpacing` value (`xxs` 2 · `xs` 4 · `sm` 8 · `md` 16 · `lg` 24 · `xl` 32 · `xxl` 48) with
the token, **in active non-Settings, non-Preview production code only.** Off-scale hand-tuned gaps
(e.g. `spacing: 15`, `spacing: 7`) are left untouched — they are felt.

**Verified exact-match `spacing:` sites in active production code (2026-07-01):**

| Site | Literal | Token | Verdict |
|---|---|---|---|
| `DesireMapView.swift:161` `VStack(spacing: 2)` | 2 | `AppSpacing.xxs` | **Swap** — title/subtitle micro-gap. |
| `VaultDesireSection.swift:67` `VStack(spacing: 2)` | 2 | `AppSpacing.xxs` | **Swap** — count-chip value/label gap. |
| `MapRecord.swift:54` `HStack(spacing: 2)` | 2 | `AppSpacing.xxs` | **Judgment — LEAVE.** This is the inter-segment gap of a distribution bar built inside a `GeometryReader` with `max(2, geo.size.width * fraction)` widths; the `2` is a geometry constant coupled to the `max(2, …)` floor, not a layout gap. Felt/geometry — do not swap. |
| `VaylButton.swift:281` `VStack(spacing: 32)` | 32 | — | **LEAVE** — inside `#Preview`. |
| `VaylBorderEffect.swift:403` `VStack(spacing: 48)` | 48 | — | **LEAVE** — inside `#Preview`. |
| `DragDebugView` / `DiagnosticOverlay` (`spacing: 2/4`) | — | — | **LEAVE** — dead/debug, retired by plan `01`. |

So the two production swaps are:

```swift
// DesireMapView.swift ~161
VStack(spacing: AppSpacing.xxs) {   // was 2 → xxs, exact
    Text("See where your desires")
    // …
}
```

```swift
// VaultDesireSection.swift ~67
VStack(spacing: AppSpacing.xxs) {   // was 2 → xxs, exact
    Text(value)
    // …
}
```

**Done:** the two exact-match production `spacing: 2` sites reference `AppSpacing.xxs`; `MapRecord`'s
geometry-coupled `2` and both `#Preview` gaps are left with the annotations above. No off-scale gap was
touched.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

1. **Fonts:** `grep -rn 'Font.custom' Vayl/Features/Pairing/` returns **nothing** — all Pairing
   `Font.custom` sites now reference an `AppFonts` token or the `AppFonts.display/body(...)` constructor
   at the identical family+size+relativeTo. Every edit carries a `// was … → …, exact` annotation.
2. **Fonts (rendered identity):** no font size, weight, or family changed — every swap is byte-identical
   to what it replaced (verified: 64→`displayHero`, 48→`display(48,.bold,.largeTitle)`,
   14/20/12 Switzer-Medium→`body(…)`).
3. **Glows:** **zero** `.shadow(` lines changed. Segment 2's table is the record of why each audited
   glow site was left (all felt / no-fitting-modifier). No new token was added to `AppGlows`.
4. **Animation:** **zero** animation literals changed. No `.repeatForever` loop touched (plan `02` owns
   CardCarousel RM). No SplashScreen ceremony timing touched.
5. **Spacing:** exactly **two** production swaps (`DesireMapView:161`, `VaultDesireSection:67`), both
   `spacing: 2 → AppSpacing.xxs`. `MapRecord`'s geometry `2`, both `#Preview` gaps, and all off-scale
   gaps untouched.
6. **Scope walls held:** no file under `Vayl/Features/Settings/*` edited; `VaylCardFace`,
   `SplashScreenView`, `CardCarousel`, `SelectablePill`, `DesireStarView`, `DeckPedestal`,
   `CandleCardFace`, `HolographicShimmer`, `DeckCaseView`, and all dead files untouched.
7. **Build compiles green** (Swift 5 mode, iOS 26 SDK). No behavior, layout, or feel change anywhere —
   this is a pure token-identity sweep.

---

## Bryan verifies on device

_(A pure-token sweep should be visually invisible; the device pass is a regression check, not a feel
check. Nothing here is a 🎚️ feel value — that's the point.)_

- [ ] **Pairing invite screen** (Settings → pairing → generate code): the copy-code icon, the linked
      checkmark, and the error/expiry glyphs render at the same size and weight as before. No layout shift.
- [ ] **Pairing join screen** ("You're linked!" state and the error state): checkmark (64pt) and warning
      (48pt) glyphs unchanged.
- [ ] **Pairing settings row** (linked-partner row): the two Switzer-Medium labels (20pt / 12pt) unchanged.
- [ ] **Desire Map intro** ("See where your desires…" hero): title/subtitle gap looks identical.
- [ ] **Vault → Desire section** count chips (value over label): the 2pt gap looks identical.
- [ ] Spot-confirm nothing regressed on the Map Pulse hero, Deck pedestal, SelectablePill selection glow,
      or Desire stars — those were deliberately **not** touched and must look exactly as before.

---

## Constraints / do-not-touch

- **No `Vayl/Features/Settings/*` edits** — plan `04` owns Settings token cleanup.
- **No `.shadow` edits** anywhere this pass (Segment 2 verdict).
- **No animation-literal edits** anywhere this pass (Segment 3 verdict).
- **No `.repeatForever` loop or RM gate in `CardCarousel`** — plan `02` owns it.
- **No new tokens** added to any `Vayl/App/Theme/*` file (Open Decision A defers the glow-token work).
- **`VaylCardFace` shell untouched**; `.drawingGroup()` stays.
- **No felt value changed** — no gradient stop, shader constant, ceremony duration, multi-radius glow,
  off-scale spacing, or `#Preview` literal. If a swap needs a new/nearest-fit token or a number change,
  it is out of scope — skip and note it.
- **Every edit is 1-for-1 and annotated** `// was <old> → <token>, exact`. If you cannot write "exact"
  truthfully, do not make the edit.
- Verify each site's **string content** against the live file before editing (Pairing views were
  mid-refactor; line numbers may have drifted ±2).

---

## Open decisions

**A. The single-color / text glows (`HomeLexicon:529`, `DesireMapView:814`, and the two-layer star/deck
glows) have no `AppGlows` modifier to land on. Add a parametric glow token now, or defer?**
→ **Recommended default: DEFER (this plan adds no token, changes no `.shadow`).** Introducing a
`spectrumTextGlow` / parametric `.glow(color:radius:)` to `AppGlows` is a token-file change whose radii
have a felt component — it must be confirmed on device, which a one-shot debt sweep must not guess at.
Proceed with zero glow edits; flag this as the natural follow-up for a dedicated `AppGlows` extension
pass that Bryan feel-gates. Fable proceeds on this default without blocking.

**B. Three genuine *text* raw-font sites (`PulseField:171` axis label 10pt-bold-uppercase,
`MapUsLayer:144` tag 9pt-bold-uppercase, `CardBackView:171` the ∞ glyph 28pt Switzer-Regular) have no
*exact* `AppFonts` token.** The nearest, `AppFonts.overline` (11pt semibold, uppercase-tracked), is a
*different size and weight* — mapping to it would change the render.
→ **Recommended default: LEAVE all three this pass** (they fail the "exact" test). If Bryan wants the
axis/tag labels folded into a shared `overline`-family token, that is a small typography decision with a
visible size change — surface it separately, don't silently flatten. Fable leaves them and notes it.

**C. `MapRecord:54` `HStack(spacing: 2)` — swap to `AppSpacing.xxs` or leave as geometry?**
→ **Recommended default: LEAVE.** The `2` is coupled to the same-view `max(2, geo.size.width * fraction)`
segment-width floor; it reads as a geometry constant, not a design gap. Swapping it implies a design
relationship that isn't there. Leave; if Bryan wants distribution-bar gaps tokenized, that's a
Map-component decision, not a mechanical sweep.
