# Vayl — Design System Review Brief (for Claude Design)

> **Purpose.** This is a self-contained handoff. You (Claude Design) have no prior
> context on Vayl. Read this brief, then take a pass at **suggested improvements to
> the design system, judged against current iOS (HIG / iOS 26) and UI-UX best
> practices.** Output recommendations, not code — see "What to deliver back."
>
> Prepared 2026-06-07 from a direct audit of the live SwiftUI codebase. Token
> values and component facts below are verified against source.

---

## 0. How to use this brief

1. Read §1–§6 to understand the product, the constraints, and the current system.
2. Use the **review lenses in §7** as your evaluation rubric.
3. Respect the **hard constraints in §3** — recommendations that violate the token
   contract, the 4-layer architecture, or iOS 26 API bans are not actionable.
4. Deliver the structured output described in §8. Prioritize ruthlessly; we want a
   short list of high-leverage changes, not an exhaustive nitpick.

---

## 1. Product context

**Vayl** is a private mutual-discovery iOS app for couples navigating consensual
non-monogamy (CNM). It is not therapy, not a dating app, not a community feed. The
emotional register is *intimate, calm, non-judgmental.*

A governing **product principle shapes every UX decision**: **"Vayl observes; the
user interprets."** The app reports what the user did and said they felt — it never
evaluates, validates, or reframes. Copy is always "You logged…" / "You noted…",
never "Your data suggests…". Treat this as a UX constraint, not just a content rule:
it rules out scores, verdicts, badges-as-judgment, and prescriptive nudges.

**Signature visual language ("the OB aesthetic"):** an "onboarding canvas" built as a
dealer's-table ceremony on an absolute near-black **void**, with card faces rendered
as **1-D spectrum outlines** (cyan → purple → magenta) that emerge from the void via
physics, over a living ambient atmosphere. This is the brand's strongest asset and
should be *preserved and propagated*, not flattened toward generic iOS chrome.

**Platform baseline:** Swift 6, iOS 16+ deployment, but **must compile and ship
against the iOS 26 SDK** (mandatory for App Store as of 2026). iOS 26 introduced the
system **"Liquid Glass"** material language — relevant tension noted in §7.

---

## 2. Architecture & token contract (why the system looks the way it does)

Vayl enforces a strict **4-layer architecture** (View → Store → Service → Model) and a
**zero-raw-values token contract**: views may not use raw colors, fonts, spacing,
radius, opacity, or animation literals. Everything resolves from a token file. This
is unusually disciplined and is a strength — your recommendations should work *within*
it (e.g., "add token X / rename token Y / re-map component Z"), not around it.

Token ownership:

| File | Owns |
|---|---|
| `AppColors` | Every color value (semantic, adaptive light/dark) |
| `AppFonts` | Every font + size (Dynamic Type via `relativeTo:`) |
| `AppSpacing` | Every spacing value (8pt grid) |
| `AppRadius` | Every corner radius (4pt grid) |
| `AppAnimation` | Every animation curve + duration |
| `AppLayout` | Geometry, derived once from `GeometryProxy` |
| `AppGlows` | Multi-layer emissive glows |
| `AppElevation` | Tinted shadows / OB card physics |
| `AppIcons` | Every SF Symbol / icon name string |

---

## 3. Hard constraints (do not violate)

- **Token contract:** no raw values in views. Propose token additions/edits instead.
- **iOS 26 banned APIs (hard compiler/review errors):** `UIScreen.main` /
  `UIApplication.shared.keyWindow` (use scene-based access via `AppLayout.from(geo)`);
  `UIWebView`, `NSURLConnection`; `UNAuthorizationOptionAlert`/`…Alert` presentation
  (use `.banner`). Don't recommend anything that reintroduces these.
- **4-layer separation:** views render + forward taps only; no service/network calls
  in views.
- **OB card-face rules:** 1-D outline only (no fills); spectrum gradient on every
  stroke; two render passes (blurred glow + crisp); all geometry proportional to
  card width/height; `.drawingGroup()` stays on the card face.
- **Reduce Motion:** every looping/ambient animation must have a fallback; ambient
  effects disable entirely under Reduce Motion.

---

## 4. Design tokens — current state

### Color (`AppColors`) — adaptive light ("Dawn") / dark ("Midnight")
- **OB-exclusive surfaces:** `void` (#0a0810, table floor), `cardBg` (#120f1a, card
  glass). The main app does **not** use these (see §6 gap).
- **Spectrum (fixed, non-adaptive):** `spectrumCyan` #00C2FF, `spectrumPurple`
  #6C3AE0, `spectrumMagenta` #FF006A; gradient tokens `spectrumBorder`,
  `spectrumText`. Used for hairlines, glows, gradient text.
- **Surfaces:** `pageBackground`, `cardBackground`, `cardBackgroundRaised`,
  `modalBackground`, `inputBackground`, `widgetBackground`.
- **Text hierarchy (7 levels):** `textPrimary`, `textBody`, `textSecondary`,
  `textTertiary`, `textHint`, `textMuted`, `textBright` (+ `textAccent`,
  `textCardLabel`).
- **Accent:** `accentPrimary` / `accentSecondary` / `accentTertiary` (flip between
  schemes — Midnight cyan-led, Dawn magenta/gold-led).
- **Feedback / safety:** `success`, `destructive`, `safetyAccent`, `safetyAtmosphere`.
- **Glass fills:** `glassFrostCard`, `glassFrostPill`, `glassFrostPillSelected`,
  `glassFrostCTA`. **Shimmer palette** (6 muted orbs) for `HolographicShimmer`.
- Plus 10 card-intensity tints, pulse-tier colors, icon-badge colors, table-felt
  rendering colors.

### Typography (`AppFonts`) — ClashDisplay (display) + Switzer (body)
- **Display:** `heroTitle` 42 · `displayHero` 64 · `scoreDisplay` 32 · `screenTitle`
  24 · `obPhaseTitle` 32 · `cardTitle` 22 · `sectionHeading` 20 · `prompt` 17.
- **Body:** `ctaLabel` 17 · `bodyText` 16 · `bodyMedium` 15 · `buttonLabel` 14 ·
  `caption` 13 · `overline` 11 · `tabLabel` 10 · `label`/`badge`/`meta` 10.
- All scale with Dynamic Type (`relativeTo:` on every token — 35 usages). Constructors
  `AppFonts.display(_:weight:relativeTo:)` / `.body(…)` for custom sizes.

### Spacing (`AppSpacing`, 8pt grid)
`xxs` 2 · `xs` 4 · `sm` 8 · `md` 16 · `lg` 24 · `xl` 32 · `xxl` 48.

### Radius (`AppRadius`, 4pt grid)
`micro` 2 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 24 · `container` 20 · `pill` ∞.
OB: `obCard` 14 · `cornerCard` 4 · `foilEdge` 16.

### Motion (`AppAnimation`)
Reactive: `fast` .15 · `standard` .3 · `slow` .5 · `spring` · `enter` .4 · `exit` .2 ·
`cinematic` 1.2. Ambient (Reduce-Motion-gated): `ambientPulse` 2.0 · `ambientDrift`
4.0 · `ambientShimmer` 1.2. Plus a large library of OB card-physics curves
(`cardSlide`, `cardSettle`, `cardFlip`, `deckFan`, `foilDissolve`, …).

### Layout (`AppLayout`) — geometry from `GeometryProxy` (never `UIScreen.main`)
- `contentMaxWidth` = min(cardWidth, 460) — readability cap on large screens.
- **Component sizing:** `ctaHeight` **52** · `pillHeight` **32** · `iconBtnSize`
  **30** (comment: "minimum hit target") · `dragHandle` 36×4.
- Extensive OB card geometry (proportional card sizing, deal points, landing slots).

### Glows (`AppGlows`) & Elevation (`AppElevation`)
- Glows are always **multi-layer** (tight inner + diffuse outer), never a single
  shadow: `spectrumBorderGlow`, `cardBreathe`, `accentFocusGlow`, `cornerDeckGlow`,
  `safetyGlow`. Modifier-based API.
- Elevation uses **tinted** shadows (never neutral grey/black) — Card and Modal
  levels per scheme, plus a continuous `cardShadow(elevation:)` for OB physics.

---

## 5. Components & patterns — current state

| Component | Role | States / variants | Notes |
|---|---|---|---|
| `VaylCardFace` | OB card shell | flip/lift/pocket physics | 1-D spectrum outline, two passes, `.drawingGroup()` |
| `AtmosphereView` / `OBVoidBloom` | Ambient background | per-phase intensity | tri-color bloom rising from screen base |
| `glassCard()` / `.hairline(.resting/.active)` | Surface treatment | resting / active | spectrum hairline borders |
| `SelectablePill` | Choice chips | dim / warm / alive intensity; selected | holographic fill + flame aura + spectrum glow |
| `HolographicShimmer` | Premium surface fill | configurable sweep | 6-layer (specular, orbs, grain, vignette) |
| `VaylButton` | Primary CTA | resting / active / glowing; pressed | animated spectrum border-fill + glow |
| `RacetrackTabBar` | Tab nav (Home/Play/Map/Learn) | animated pill (0.35s), haptic | tab-lock logic exists but **not wired to UI** |
| `PulseWidget` / `PulseGraph` | Data viz | inline check-in; 7-day graph | Canvas render + breath animation |
| Empty states | required on every data screen | icon + headline + sub + CTA | mandated by the system |

**Interaction convention (every tappable element):** press scale (`0.96`) +
`.sensoryFeedback(.impact(.light))` + action. Haptics are used deliberately.

---

## 6. Known tensions & open questions (seed — do not treat as conclusions)

These are observations from the audit. Validate or overturn them; they're starting
points, not a verdict.

1. **OB ↔ main-app coherence gap (biggest one).** The onboarding canvas is a
   bespoke void + spectrum-outline + glass world. The built main-app screens (Home
   `HomeDashboardView`, `SettingsView`) instead use elevated `cardBackground` /
   `modalBackground` with breathing orb glows — spectrum *accents* but **no void
   base, no spectrum hairlines, no glass/shimmer finish.** Play & Learn are bare
   stubs; Map is a temporary harness. How should the OB language translate into
   day-to-day surfaces *without* the daily app feeling as heavy/ceremonial as
   onboarding? Where is the line between "signature" and "exhausting"?
2. **Touch targets below HIG minimum.** `iconBtnSize` 30pt and `pillHeight` 32pt are
   under the 44×44pt HIG minimum (`ctaHeight` 52 is fine). Recommend a hit-target
   strategy (visual size vs tappable area).
3. **Contrast on the void.** Seven text levels descend to `textHint` / `textMuted`;
   spectrum strokes sit at 0.5–0.6 opacity by design. Audit against **WCAG AA** on
   the dark void and on glass cards — flag any text/control that fails 4.5:1 (3:1 for
   large) and the "decorative vs informational" line for low-opacity hairlines.
4. **Custom glass vs iOS 26 Liquid Glass.** Vayl ships its own glass/shimmer system.
   iOS 26's system Liquid Glass is now the platform default for chrome. Should Vayl
   adopt/blend system materials anywhere (e.g., tab bar, sheets) for native feel and
   automatic accessibility (Reduce Transparency / Increase Contrast), or hold the
   bespoke look? Where's the right mix?
5. **Dynamic Type at large sizes vs fixed card geometry.** Fonts scale, but OB card
   faces are proportional to fixed card dimensions. Stress-test AX5 / accessibility
   sizes: do prompts truncate or overflow inside cards?
6. **Light mode ("Dawn") parity.** The system is dark-first ("Midnight"). Is Dawn a
   first-class, fully-considered theme or a port? Audit spectrum-on-light contrast and
   glow legibility in light mode.
7. **Accessibility coverage is partial.** `accessibilityLabel` appears in ~27 files;
   traits/hidden/value in ~58 places — real but incomplete. The heavily-decorative,
   Canvas-rendered OB cards are a VoiceOver risk (announce the *content*, hide the
   decoration). Reduce Motion is handled; **Reduce Transparency / Increase Contrast**
   handling for the glass/glow layers is unverified.
8. **Glow/shimmer performance & restraint.** Multi-layer blurs + Canvas particles are
   GPU-heavy. Beyond perf, is the glow *vocabulary* applied with enough restraint to
   preserve hierarchy, or does everything glow?
9. **UX: silent failure & error surfaces.** The system mandates empty states but
   error/failure states are thin (e.g., a session can fail to save with only a log
   line). Recommend an error/feedback pattern consistent with "observe, don't judge."
10. **Token semantics.** Some tokens are named by *role* (good) and some by *visual*
    (e.g., shimmer/felt). Flag any naming that will fight future theming.

---

## 7. Review lenses (your evaluation rubric)

Evaluate the system against each. Cite specific tokens/components.

**iOS HIG / platform fit**
- 44pt minimum touch targets; comfortable hit areas; one-handed reach for primary
  actions; bottom-anchored CTAs.
- SF Symbols vs custom icons — consistency, weight matching, scaling, semantic use.
- Native navigation/sheet/modal patterns; `.presentationDetents` for half-sheets;
  swipe-back; safe-area + Dynamic Island/home-indicator respect.
- iOS 26 Liquid Glass: where system materials would improve native feel + free
  accessibility, vs where the bespoke look is worth keeping.
- Haptics: appropriate, not overused.

**Accessibility (WCAG 2.1 AA + Apple)**
- Color contrast on void and glass; don't rely on color/glow alone to convey state.
- Dynamic Type to AX5 without truncation/overlap; respect `contentMaxWidth`.
- VoiceOver: meaningful labels, decoration hidden, logical focus order, especially on
  Canvas-rendered cards and the tab bar.
- Reduce Motion (handled — verify), Reduce Transparency, Increase Contrast, Bold Text.

**Visual design / system health**
- Type scale rhythm (two families, ~17 sizes — is it too granular?).
- Spacing/radius grid adherence; elevation legibility; glow hierarchy & restraint.
- Token coverage & naming (role-based vs visual); duplication; gaps.
- Light/dark parity.

**UX / interaction**
- Cognitive load & length of the 10-phase onboarding ceremony vs payoff.
- Clarity of gating/locked states (tab locking, paywall moments) without shaming.
- Empty / loading / error states across all data screens.
- Microcopy alignment with "observe, don't interpret."
- Consistency of the press-scale + haptic + action interaction contract.

---

## 8. What to deliver back

Produce a prioritized review, structured as:

1. **Executive summary** — top 5 highest-leverage improvements, each one line.
2. **Findings by lens** (§7), each finding as: *Observation → Why it matters (cite
   HIG/WCAG/UX principle) → Specific recommendation (token/component-level) →
   Effort (S/M/L) → Risk to the brand aesthetic.*
3. **Token-level proposals** — concrete additions/renames/re-mappings (e.g., "add
   `AppColors.surfaceVoidElevated`", "raise `iconBtnSize` hit area to 44 while keeping
   30pt glyph"), expressed so they slot into the existing token files.
4. **New components / patterns** — if a gap warrants one, spec it (problem, API,
   variants, states, tokens used, accessibility) per design-system conventions.
5. **OB → main-app translation guidance** — a concrete proposal for carrying the void
   + spectrum + glass language into Home/Play/Map/Learn at *daily-use* intensity
   (this is the #1 ask).
6. **Migration notes** — what changes are non-breaking vs require a coordinated pass.

**Honor these as intentional (don't "fix" them):** the spectrum brand (cyan→purple→
magenta), the void-first dark aesthetic, the 1-D outline card faces, the onboarding
ceremony's emotional weight, the zero-raw-values token contract, and the
"observe-don't-interpret" voice. Improve *within* these, or make an explicit,
well-argued case if you believe one should bend.
