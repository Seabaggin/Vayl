# Vayl — Design System Reference
**Platform:** iOS 26, SwiftUI, Swift 6. **V1 ships dark-only** (Views hard-locked to `.dark`); light-mode token *values* exist in the token layer but are not yet wired to render — see §7.
**Last updated:** 2026-07-10
**Companion doc:** [CLAUDE.md](CLAUDE.md) holds the non-negotiable *rules* (architecture, safe area, token contract, animation contract, presentation grammar). This doc is the *implementation reference* — real token values and real component APIs as they exist in the codebase today, verified against source rather than carried forward from memory. Where the two disagree, CLAUDE.md's rule wins and the drift is called out below (§10).

---

## 1. Visual Identity
Deep space / bioluminescent. Near-black backgrounds, a single spectrum gradient (cyan → purple → magenta) earned only on strokes, display text, and hero elements ≥24pt. Breathing, gravitational animation register — quiet dark room, not a dashboard. Gold is reserved exclusively for safe-word/warning surfaces, never decorative.

App name is **Vayl** (the old "Open Lightly" branding in earlier drafts of this doc no longer exists anywhere in the codebase).

---

## 2. Color Tokens — `AppColors.swift`
Source: `Vayl/App/Theme/AppColors.swift` (890 lines), built on `Vayl/App/Theme/VaylPrimitives.swift` (raw `UIColor` literals — internal, only `AppColors` may reference it directly).

### The dark/light mechanism (read this before touching color)
Every adaptive token routes through `Color.dynamic(light: UIColor, dark: UIColor)`. Right now `.dynamic` **always resolves to `dark`** — `light:` is accepted and stored but never read. This is intentional (see CLAUDE.md's V1 dark-only mandate): the light-mode palette is fully authored so post-launch light-mode work is "just wire up Views," but until that wiring happens, every token below renders its dark value regardless of device appearance. Internally the two modes are named **Midnight** (dark, active) and **Dawn** (light, inert).

Not every token is adaptive — some are fixed `Color(uiColor:)` literals with no light/dark split at all, because the value isn't meant to change: the shimmer palette, flourish colors, spectrum anchors, card-intensity tints, aura ramps, flame/warm-aura ramp, vault-rose ramp. These are called out per-section below.

### Backgrounds (elevation hierarchy, dark values shown)
| Token | Hex | Use |
|---|---|---|
| `pageBackground` | `#030305` | Screen floor |
| `cardBackground` | `#12111A` | Standard card fill |
| `cardBackgroundRaised` | rgba(22,20,36,.92) | Elevated card |
| `modalBackground` | `#1A1825` | Sheet/cover fill |
| `inputBackground` | `#0C0C10` | Text fields |
| `widgetBackground` | `#08060A` | Home widgets |
| `void` | `#0a0810` | OB canvas floor |
| `cardBg` | `#120f1a` | OB card glass |

### Spectrum & accent (fixed, not adaptive)
| Token | Hex |
|---|---|
| `spectrumCyan` | `#00C2FF` |
| `spectrumPurple` | `#6C3AE0` |
| `spectrumMagenta` | `#FF006A` |
| `spectrumBridge` | `#8B6FD4` (mid-spectrum bridge stop) |

`spectrumBorder` / `spectrumText` gradients: cyan → purple → magenta, evenly distributed stops (no explicit positions), `.topLeading→.bottomTrailing` for borders, `.leading→.trailing` for text. `accentPrimary` = cyan, `accentSecondary` = purple, `accentTertiary` = magenta (dark values).

### Text hierarchy
| Token | Dark value |
|---|---|
| `textPrimary` | `#E8E8F0` |
| `textBody` | white |
| `textSecondary` | white @ 0.65 |
| `textTertiary` | white @ 0.50 (pair with `.italic()` at call site) |
| `textHint` | white @ 0.60 |
| `textMuted` | white @ 0.20 |
| `textBright` | `UIColor(white: 0.90)` — deliberately untinted, "device-absolute" |
| `textAccent` | cyan |
| `textCardLabel` | cyan @ 0.75 |
| `textSectionLabel` | purpleBright @ 0.85 |

### Borders
`borderSubtle` white@0.06 (default/static) · `borderDefault` white@0.10 (hover/focus) · `borderActive` white@0.15 · `borderAccent` cyan@0.20 · `borderPurple` purple@0.14.

### Safety — never decorative
`safetyAccent` = `#C8960A` gold, full opacity, safe-word/hard-stop surfaces only. `safetyAtmosphere` — same gold, but the token carries a comment mandating ≤8% opacity *enforced at call sites*, not baked into the token itself.

### Feedback & shadow
`destructive` `#FF4444` · `success` `#00CC88` · `shadowDeep` black@0.50 · `scrimHeavy` black@0.75 · `scrimWhisper` black@0.10 · `shadowMagenta` magenta@0.10 · `shadowPurple` purple@0.08 · `shadowGold` gold@0.04.

### Card intensity tints (fixed hex)
`cardIntensityTint{Cyan/Purple/Magenta/Navy/Indigo/Plum}` + four Supernova variants — used exclusively by the Context Card intensity system (§9).

### Glass fills
`glassSurface` white@0.03 is the **canonical `.vaylGlassCard()` fill** (the Map-tab translucent look). `glassFrostCard`, `glassFrostPill`, `glassFrostPillSelected` (white@0.10), `glassFrostCTA`, `whisperFill` (white@0.04) round out the frosted-surface family.

### Data-viz ramps (never UI accents)
Pulse tier colors (`pulseTierExpansive/Sovereign/Friction/Protective`) and per-tier aura ramps (core/light/deep/glow, one ramp each for Cyan/Indigo/Magenta/Rose/Lavender-Silver/Sage-Deep) exist solely for the Pulse circumplex visualization — do not reach for these outside Map/Pulse. A 5-step check-in scale adds `pulseAnswerScaleOrange` (`#E07020`, added 2026-07-09).

---

## 3. Typography — `AppFonts.swift`
Families: **ClashDisplay** (Bold/Semibold/Medium — headings, prompts, scores) and **Switzer** (Regular/Medium/Semibold/Bold — body, labels, buttons). One sanctioned exception: `microBadge` uses raw `Font.system(size: 9, weight: .bold)` — everything else goes through `Font.custom`. `Menlo` (Regular/Bold) is scoped exclusively to the founder-letter screen.

```swift
AppFonts.display(_ size: CGFloat, weight: .bold/.semibold/.medium, relativeTo: Font.TextStyle) -> Font  // ClashDisplay
AppFonts.body(_ size: CGFloat, weight: .regular/.medium/.semibold/.bold, relativeTo: Font.TextStyle) -> Font  // Switzer
```
Both assert-fail on an unsupported weight and fall back (Bold / Regular respectively) rather than silently rendering wrong.

### Display scale (ClashDisplay)
| Token | Size | Weight |
|---|---|---|
| `heroTitle` | 42 | bold |
| `tabMasthead` | 40 | bold |
| `displayHero` | 64 | bold |
| `obPhaseTitle` | 32 | semibold |
| `scoreDisplay` | 32 | bold |
| `screenTitle` / `sheetTitle` | 24 | semibold |
| `cardTitle` | 22 | semibold |
| `pulseWidgetTitle` | 28 | semibold |
| `sectionHeading` | 20 | medium |
| `cardTitleCompact` | 16 | semibold |
| `prompt` | 17 | medium |
| `promptHighlight` | 17 | semibold |
| `sectionLabelSmall` | 13 | medium |

### Body scale (Switzer)
| Token | Size | Weight |
|---|---|---|
| `ctaLabel` | 17 | semibold |
| `bodyText` | 16 | regular |
| `bodyMedium` | 15 | medium |
| `buttonLabel` | 14 | semibold |
| `caption` | 13 | regular |
| `overline` | 11 | semibold |
| `buttonLabelSmall` | 11 | medium |
| `tabLabel` / `label` / `badge` / `meta` | 10 | medium/semibold/medium/regular |
| `microBadge` | 9 | bold (system font) |

`.overlineTracked()` = `.overline` + uppercase + tracking 2. `.vaylDisplayTracking(size)` applies negative optical tracking above 34pt (0 below 20pt, ramping to `-0.02 × size`).

---

## 4. Spacing & Radius
`AppSpacing.swift` — semantic scale, not a clean power-of-two ladder (two half-steps inserted deliberately):

| Token | pt | Use |
|---|---|---|
| `xxs` | 2 | Micro-adjustments (drag handle gaps) |
| `xs` | 4 | Icon-to-label |
| `sm` | 8 | Compact gaps, pill internal padding |
| `sm2` | 10 | Chip vertical padding (half-step) |
| `md2` | 12 | Structural half-step |
| `md` | 16 | Default structural gap, card-edge padding |
| `lg` | 24 | Section separation, screen-edge margin |
| `xl` | 32 | Above sticky CTAs |
| `xxl` | 48 | Hero/top-of-screen breathing room |

`AppRadius.swift` — 4pt grid, independent of the spacing grid:

| Token | pt | Use |
|---|---|---|
| `micro` | 2 | Drag handles, hairline end-caps |
| `sm` | 8 | Chips, tags, badges |
| `md` | 12 | Inputs, secondary buttons |
| `lg` | 16 | Cards, primary CTAs |
| `container` | 20 | OB cards, home widgets, pairing surfaces |
| `xl` | 24 | Modals, sheets, large overlays |
| `pill` | `.infinity` | Capsules |
| `sheet` | 57 | Native-style Dynamic-Island-device sheet corners |

OB-exclusive (never leave the onboarding boundary): `obCard` 14pt (VaylCardFace shell clip), `cornerCard` 4pt (corner-deck mini stack), `foilEdge` 16pt (BuildDeck foil wrapper).

> Note: CLAUDE.md's "Two border radius values only (8/20, exception 16 for inputs)" rule describes an earlier, coarser version of this scale. The actual token file now has a fuller ladder (`micro`/`sm`/`md`/`lg`/`container`/`xl`/`pill`/`sheet` + 3 OB-only values) — treat the token file as current truth; CLAUDE.md's line should be reconciled to match on its next pass.

---

## 5. Layout & Safe Area
`AppLayout.swift` — `AppLayout.from(geometry: GeometryProxy)` is the only sanctioned way to get screen geometry. Verified: no `UIScreen.main` reference anywhere in the file. Produces `screenWidth`, `screenHeight`, `safeAreaInsets`, `isSmallDevice` (≤375pt), `isLargeDevice` (≥428pt).

**OB card sizing (mandatory, 3:2 ratio):**
```swift
obCardWidth(in:)      = min(screenWidth * 0.72, 320)
obCardHeight(in:)      = obCardWidth * 1.5
obTableCardWidth(in:)  = min(screenWidth * 0.30, 195)   // resting on the felt
obFanCardWidth(in:)    = min(screenWidth * 0.42, 280)   // ExperienceLevel fanned hand
sessionCardWidth(in:)  = min(screenWidth * 0.88, 480)   // Card Session
sessionCardHeight(in:) = sessionCardWidth * 0.708
```
Standard spacing: `screenHPad` 18 · `screenMargin` 24 (OB canvas) · `ctaHorizontalMargin` 32 · `cardHPad` 16 · `cardVPad` 14 · `cardGap` 10 · `sectionGap` 24. Components: `ctaHeight` 52 · `pillHeight` 32 · `iconBtnSize` 30. Map: `mapPulseCardHeight` 218, `mapMeAuraSize` = `mapPulseCardHeight × 0.62`.

`AppSafeArea.swift` — the only file allowed to call `.safeAreaInset(edge:)` directly:
| Modifier | Purpose |
|---|---|
| `.stickyBottomCTA(cta:)` | Pins a CTA via `.safeAreaInset(edge: .bottom)`, `.ultraThinMaterial`, bleeds to the physical bezel |
| `.bottomContentInset(layout)` | Scroll content with no CTA (never combine with `stickyBottomCTA`) |
| `.bottomClearance(layout, includesTabBar:)` | Floating/overlay content |
| `.topClearance(layout, padding:)` | Replaces hardcoded `.padding(.top, 60/120)` hardware proxies |

`AppLayout.homeIndicatorInset` / `.topHardwareInset` / `.hasHomeIndicator` / `.hasNotchOrIsland` (top inset > 20pt) round out the hardware-aware helpers.

---

## 6. Elevation, Glow & Opacity
`AppOpacity.swift` — the small, load-bearing opacity vocabulary: `whisper` 0.04 · `hairline` 0.08 · `border` 0.15 · `dim` 0.25 · `stroke` 0.45 · `glowFloor` 0.30 · `glowPeak` 0.70. The floor/peak pair encodes the animation contract's "glow opacity never leaves 0.3→0.7" rule for *animated intensity multipliers* — it is not enforced on the static per-glow token opacities below (several of those sit outside 0.3–0.7 by design, since they're fixed layered compositions, not breathing values).

`AppElevation.swift` — `Page` (no shadow) → `Card` → `Modal`, each with a `midnightShadow`/`midnightGlow` pair (dawn pairs also defined, dormant per §2). Card: shadowDeep r16/y8 + shadowMagenta r24/y4. Modal: shadowDeep r32/y16 + shadowMagenta r48/y8. `.cardElevation()` / `.modalElevation()` apply these. OB card physics gets its own non-clamped lerp (`cardShadow(elevation:)`): opacity 0.50→0.16 while radius grows 8→32 and y grows 4→20 as a card lifts off the felt, deliberately inverting opacity-vs-radius to mimic an overhead point light.

`AppGlows.swift` — every glow is a `{color, radius, x:0, y:0}` layer (offsets belong to Elevation, not Glow). Key ones: `spectrumBorder` (3-layer cyan/purple/magenta halo, the `VaylButton` border-arc glow), `cardBreathe` (purple@0.22 r18, OB idle card, removed under Reduce Motion), `accentFocus` (focused input/selected pill), `safety` (safe-word surfaces only). `spectrumBorderGlow(intensity:)` exposes a live 0–1 multiplier to call sites — nothing in the token itself clamps that multiplier into the 0.3–0.7 band, so call sites are responsible for honoring the contract.

---

## 7. Theme Coordination
`AppTheme.swift` defines `ThemeMode` (`.system/.light/.dark`) purely for persistence/migration continuity — a comment confirms the old parallel `AppPalette` system was removed in the dark-only consolidation. `ThemeManager` (`@Observable`) persists the mode to `UserDefaults` but `preferredColorScheme` **always returns `.dark`**, regardless of stored value or device setting, by design (reversible later). `ThemeModifiers.swift` applies this at the root via `ThemedRootModifier`, and also defines `.themedCard(selected:)` and `.vaylGlassCard(accent:radius:)` — **these two live here, not under `Design/Components/Cards/`.**

`.themedCard(selected:)` — opaque fill + conditional accent border/shadow when selected.
`.vaylGlassCard(accent:radius:)` — `glassSurface` fill + hairline stroke (optionally accent-tinted); the canonical Map-tab translucent surface.

**Known exception:** `AppElevation`'s `CardElevationModifier`/`ModalElevationModifier` and `ThemeModifiers`' `ThemedCardModifier` still branch on live `@Environment(\.colorScheme)` to pick shadow sets. Since `ThemeManager` forces `.dark` app-wide these always resolve to dark in practice, but they are the last surviving colorScheme reads in the theme layer — flagged here rather than silently treated as a pattern to copy (see §10).

---

## 8. Animation & Motion — `AppAnimation.swift` + `AppMotion.swift`
Two classes only, per file header: **Reactive** (user-driven, never cancelled) and **Ambient** (continuous, must fully disable under Reduce Motion — not just slow down — and under Low Power Mode).

### Reactive core
| Token | Value |
|---|---|
| `fast` | `.easeOut(0.15)` — button press, toggle |
| `standard` | `.easeOut(0.3)` — state transitions from user action |
| `slow` | `.easeOut(0.5)` — deliberate transitions (OB steps, modals) |
| `spring` | `.spring(response: 0.5, dampingFraction: 0.85)` — card lifts, drag release |
| `enter` | `.easeOut(0.4)` |
| `exit` | `.easeIn(0.2)`, opacity only |

### Ambient core
| Token | Value | Use |
|---|---|---|
| `ambientPulse` | 2.0s | inert-chrome breathe (waiting dot, status pulse) |
| `ambientDrift` | 4.0s | aurora blob drift |
| `ambientShimmer` | 1.2s | the one decorative exception under the 2s floor |
| `auraBreathe` | 5.4s | living-surface breathe (Pulse aura, presence) |

**"Two breathing tempos, no third" — status:** `ambientPulse` (2.0s) and `auraBreathe` (5.4s) are both confirmed exactly as CLAUDE.md's contract states. The rule itself, however, is **not code-enforced** — the file also contains `cardBreathe` (3.2s, OB table-idle card) and `flourishBreath` (4.0s), neither of which reduces to either canonical tempo. Treat these two as a known cleanup candidate rather than a sanctioned third tempo; don't add more like them.

`.ambientAnimation(_:value:)` gates on `AppAnimation.ambientMotionDisabled = UIAccessibility.isReduceMotionEnabled || lowPower` (confirmed — both Reduce Motion and Low Power Mode covered). `Animation.reduceMotionSafe` is the reactive-token equivalent for use outside a View context.

### OB Card Physics (OB-exclusive)
`cardSlide` 0.85s, `cardSettle`/`cardCenter` (critically-damped springs), `cardFlip` 0.58s (+ half-variants), `cardLift` 0.95s, `deckFan` spring(0.70, 0.88), `foilDissolve` 0.65s, and ~15 more — all scoped to onboarding/BuildDeck. Don't reach for these outside the OB canvas.

### Motion System — the three staples (`AppMotion.swift`)
Spec: `docs/superpowers/specs/2026-07-03-motion-system-design.md`. Two registers — **Loud** (OB + `.vaylCover`) and **Quiet** (everywhere else, hard ceiling: scale delta ≤0.02, travel ≤16pt, duration ≤0.55s):

1. **Depth Handoff** — `AnyTransition.vaylDepth(.quiet | .loud)`. `depthQuiet` 0.26s easeOut; RM collapses to pure opacity.
2. **Weighted Arrival** — `arrive` 0.50s (`.vaylSheet`) / `arriveCover` 0.55s deal-curve (`.vaylCover`) / `arriveSpring` critically-damped interruptible companion.
3. **Charged Tap / refusal** — `View.vaylRefusal(trigger:)`, a 4-leg decaying shiver (28pt/4 legs); RM drops the shiver, keeps the haptic.

`AppMotion` is deliberately the *stateless applier* layer — it bakes RM handling into each function so call sites can't forget it. `AppAnimation` holds raw values; `AppMotion` holds the View-facing surface. Also here: `View.vaylCascade(index:shown:)` (first-arrival row cascade, RM → single 0.2s fade) and `Animation.vaylFlick(momentum:)` (velocity-carry spring for drag release, interpolating response between 0.26–0.48 by momentum).

---

## 9. Card Intensity Systems
Two independent systems sharing the word "intensity" — don't conflate them.

**Context Cards (onboarding only)** — `ContextIntensity` drives border opacity, background tint, and internal/external glow across 7 named levels (ember → nova). Confirmed cards are 300×340pt, `cornerRadius(20)`, spectrum border always present at `intensity.borderOpacity`.

**`SelectablePill.Intensity`** (pill/flame/aura shared vocabulary) — only **3** cases exist: `.dim` (0.15), `.warm` (0.5, default), `.alive` (1.0). The old 4-state pill difficulty model referenced in earlier drafts of this doc, and the standalone "difficulty" label concept, are both confirmed dead — decks mix light/heavy by design, per project history. `FlameAura` and `LightAuraBloom` both key off this same enum, confirming it's shared vocabulary across effects, not pill-local.

---

## 10. Component Library

### Buttons — `Design/Components/Buttons/`
- **`SelectablePill`** — `init(label:isSelected:intensity: Intensity = .warm:height: CGFloat = 46:fontSize: CGFloat = 15:showFlame: Bool = true:fillWidth: Bool = true:tint: Color? = nil:action:)`. Renders `HolographicShimmer` in `.background` (kept out of `.overlay` so text stays crisp), `FlameAura` behind selected non-dim pills, `.pillBorder()` when selected.
- **`VaylPressableStyle`** — `ButtonStyle`, exposed as `.buttonStyle(.vaylPressable)` / `.vaylPressable(scale:)`. Drives `.scaleEffect` + `.sensoryFeedback(.impact(.light))` off `configuration.isPressed`. **This — not the raw three-line snippet — is current practice for `Button`-based controls.**
- **`VaylPressableTap`** — the non-`Button` counterpart: `.vaylPressableTap(scale: 0.96, action:)`, driven by a `minimumDistance: 0` `DragGesture` so the press visual lands on touch-down (12pt release slop). Use this for tap targets that aren't `Button`.

> CLAUDE.md's "Required View Patterns" tap-contract snippet is the conceptual baseline; in practice every tappable element should reach for `.vaylPressable` (Button) or `.vaylPressableTap` (non-Button) rather than hand-rolling the three modifiers.

### Presentation & Navigation — `Design/Components/Navigation/`
- **`.vaylCover(isPresented:confirmOnExit: Bool = true:onExit:content:)`** — wraps `.fullScreenCover`, unconditionally `.interactiveDismissDisabled(true)`, injects a `\.vaylDismiss` environment action content must call instead of `dismiss()`. Surfaces a `.confirmationDialog` before closing when `confirmOnExit` is set.
- **`.vaylSheet(isPresented:heightFraction: CGFloat = 0.55:showsGrabber: Bool = true:content:)`** — **not** a real `.sheet` (real sheets inset unpredictably on iOS 26); a custom overlay with scrim, spectrum-tinted grabber, drag-to-dismiss (0.25× height threshold or a >240pt fling), spring-back via `vaylFlick`.
- **`VaylSheetChrome`** / `.vaylSheetChrome(widen:signature:)` — the shell `.vaylSheet` applies automatically; `VaylSheetSignature.hairline` (default) vs `.full` (spectrum top-edge, reserved for ceremonial sheets like the paywall).
- `.vaylSafariSheet(item:url:)` / `.vaylShareSheet(item:items:)` — sanctioned exemptions for system view controllers, still routed through this file.
- **`RacetrackTabBar`** — sliding-capsule tab bar with an animated arc stroke on the selected pill. **Known exception:** still branches on `@Environment(\.colorScheme)` in several places — a pre-dark-only-mandate holdover, not a pattern to copy.
- **`TabContentWrapper`** — role has narrowed to a top-of-bar fade mask only (`fadeHeight: 110`). Bottom clearance now belongs solely to `AppShell`'s `.safeAreaInset(edge: .bottom)` — do not reintroduce a bottom `.contentMargins` here.
- **`ScrollTopEdgeFade`** — `.scrollTopEdgeFade(fadeHeight: 40, engageDistance: 44)`, the scroll-proportional counterpart to `TabContentWrapper`'s static top fade (iOS 18+ `onScrollGeometryChange`).
- **`VaylCloseButton`** — 32pt glass circle, the one sanctioned dismiss affordance for sheet/cover chrome.

### Effects — `Design/Components/Effects/`
- **`VaylButton`** — the heavyweight CTA. Hand-rolled press choreography (not `.vaylPressable`) drives `VaylBorderEffect`'s fill/glow/hairline through a scheduled sequence: border fills, then glow bursts and settles.
- **`PillBorder`** — `.pillBorder(cornerRadius:lineWidth: 1.0:glowRadius: 5:opacity: 0.85)` (dark/spectrum) and `.magentaGoldBorder(...)` (light/Dawn, dormant per §7).
- **`SpectrumHairline`** / **`TaperedSpectrumHairline`** — the *ceremonial* branded divider (cyan→purple→magenta), distinct from the quiet structural `VaylHairline` below.
- **`HolographicShimmer(duration: 6)`** — the canonical dark-surface shimmer (`SelectablePill`, `VaylButton`, `RacetrackTabBar`): specular sweep + 5 drifting color orbs + procedurally-generated grain, static fallback under RM/Low Power.
- **`VaylBorderEffect`** — the low-level engine `VaylButton` drives: tapered hairline → resting angular-gradient stroke → two-sided crisp spectrum stroke with an outward-only masked halo. Never add `.drawingGroup()` here — it collapses the mask.
- **`VaylMark`** — the brand aperture mark (nested concave-diamond rings + igniting core), used on waiting cards and card backs.
- **`StarVeil`** — deterministic, seeded twinkling starfield, 15fps, static under RM/Low Power.

### Text — `Design/Components/Text/`
- **`HighlightText`** — the calm, static sibling of `LivingText`. `HighlightText.highlighted(_:words:baseFont:highlightFont:baseColor:) -> Text` builds one folded `Text` via string interpolation (not the deprecated `Text + Text`), gradient-styling matched substrings. This is the real `highlightWords` implementation, consumed by `VaylCardFace` and `CardCarousel`.
- **`LivingText`** — three-tone breathing gradient text (outer bloom + inner glow, both screen-blended, 30fps-capped) for hero/greeting emphasis words. `animated: false` or `AppAnimation.ambientMotionDisabled` collapses to static.
- **`HolographicText`** / **`HolographicTextCore`** — the StatPhase "1 in 5" recipe; `Core` is the pure non-animating pixel logic, `HolographicText` is the self-animating consumer.
- **`GradientText`** — plain two-stop gradient, no animation, no third tone (three-tone is `LivingText`'s job).
- **`SpectrumBulletRow`** — a spectrum-gradient disc marker (deliberately not a checkmark — it signals "possibilities," not guaranteed delivery), cascading via `phaseOffset`. Used in the paywall bullet list.

### Progress — `Design/Components/Progress/`
Three distinct rings/bars — pick by purpose, not by habit:
- **`ProgressBar`** — plain 4pt linear capsule fill. The workhorse.
- **`ProgressRingView`** — generic circular progress from a 0–1 fraction, small/inline use.
- **`ScoreRing`** — purpose-built for an `Int` "score out of 100" result display (not a generic ring).
- **`OnboardingProgressBar`** — the elaborate OB/hero-moment bar (bloom, shimmer, particles, VoiceOver milestone announcements). Confirmed live in exactly `GettingStartedEntryCard`, `PlayHeroView`, `ContextPhase` — not a general-purpose default.

`ScreenshotProtectionModifier` (`.screenshotProtected()`) also lives in this directory but is unrelated to progress UI — a filing artifact, not a naming pattern.

### Cards — `Design/Components/Cards/` (+ `App/Theme/ThemeModifiers.swift`)
- **`VaylCardFace`** — both CLAUDE.md contracts confirmed live: `.drawingGroup()` is present and commented as load-bearing; `VaylCardModel` is only ever *written* by `VaylDirector`/`GenderSequencer` (non-View orchestrators) and only ever *read* by rendering Views — enforced by convention, not the compiler.
- **`CardBackView`** / **`VaylDeckStack`** — deck-back decoration; `VaylDeckStack` is the shared source of truth for "a deck at rest," used by both `CuriosityPhase`'s exit deck and (partially — see §10 drift) `BuildDeckPhase`'s felt deck.
- **`SettingsCard`** — thin `.vaylGlassCard(radius: AppRadius.container)` wrapper with a top spectrum hairline; the Settings list container.
- **`.themedCard()`** / **`.vaylGlassCard()`** — both defined in `App/Theme/ThemeModifiers.swift`, not under `Cards/`. See §7 for signatures.

### Empty state & hairline
- **`VaylEmptyState(icon:headline:message:cta:)`** — icon → headline (`cardTitle`) → message (`caption`) → optional CTA, matching CLAUDE.md's empty-state contract exactly. Canonical across Map, Vault, Desire Reveal, Session builder, Pulse.
- **`VaylHairline(color: AppColors.borderSubtle)`** — the one quiet structural divider (collapsed five prior hand-rolled dividers into this). `SpectrumHairline` is its ceremonial counterpart — don't reach for the branded gradient line where a plain rule is what's needed.

---

## 11. Known Drift (things this doc found that don't match the stated rules)
Keep this section honest and current — it's more useful than pretending everything is clean.

1. **`RacetrackTabBar`** still branches on `@Environment(\.colorScheme)` in multiple places — predates the V1 dark-only View mandate. Don't copy this pattern into new Views.
2. **`ConversationCard.cardWidth`** derives from `UIWindowScene.screen.bounds.width` rather than `AppLayout.from(geo)` — the same class of anti-pattern the "no `UIScreen.main`" rule targets, even though it's not literally `UIScreen.main`.
3. **`AppElevation`'s `CardElevationModifier`/`ModalElevationModifier`** and **`ThemeModifiers`' `ThemedCardModifier`** read live `@Environment(\.colorScheme)` to pick shadow sets. Harmless while `ThemeManager` forces `.dark`, but they're the last colorScheme branches in the theme layer.
4. **Ambient breathing tempos** — `cardBreathe` (3.2s) and `flourishBreath` (4.0s) exist alongside the canonical `ambientPulse`/`auraBreathe` pair and don't reduce to either. The "two tempos, no third" rule is real intent but not yet code-enforced or fully applied.
5. **`AppGlows`** static per-glow opacities are frequently outside the 0.3–0.7 band by design (they're fixed layered compositions); the band is a contract for *animated* intensity, enforced only at call sites via `AppOpacity.glowFloor/glowPeak`, not inside `AppGlows.swift` itself.
6. **Radius scale** — CLAUDE.md's "only two radius values" line is stale; the real `AppRadius` ladder has 8 general tokens plus 3 OB-only ones (§4).
7. **`BuildDeckPhase`'s felt deck** still has its own private `DeckStack` implementation separate from the shared `VaylDeckStack` — flagged as unfinished consolidation, not a second sanctioned pattern.
8. **`HolographicShimmer.metal`** sits next to `HolographicShimmer.swift`, but the live view renders via pure SwiftUI `Canvas`, not the shader — confirm wiring before assuming the `.metal` file is active.

---

## 12. File Locations
```
App/Theme/
  AppColors.swift / AppFonts.swift / AppSpacing.swift / AppRadius.swift
  AppLayout.swift / AppSafeArea.swift / AppOpacity.swift
  AppElevation.swift / AppGlows.swift / AppAnimation.swift / AppMotion.swift
  AppTheme.swift / ThemeManager.swift / ThemeModifiers.swift
  VaylPrimitives.swift    — Tier 1 raw color literals, AppColors-only consumer
  AppRootView.swift       — splash-then-route gate (onboarding → auth → AppShell)

Design/Components/
  Buttons/    SelectablePill.swift · VaylPressableStyle.swift · VaylPressableTap.swift
  Cards/      VaylCardFace.swift · VaylCardBack.swift · VaylCardRenderer.swift · VaylCardContent.swift
              CardBackView.swift · VaylDeckStack.swift · SettingsCard.swift · ConversationCard.swift
              CardFaces/ · CardPhysics/
  Navigation/ VaylPresentation.swift · VaylSheet.swift · RacetrackTabBar.swift
              TabContentWrapper.swift · ScrollTopEdgeFade.swift · VaylCloseButton.swift · OnboardingFooter.swift
  Effects/    VaylButton.swift · VaylBorderEffect.swift · PillBorder.swift · SpectrumHairline.swift
              HolographicShimmer.swift · GlowOrb.swift · VaylMark.swift · StarVeil.swift · FlameAura.swift
              LightAuraBloom.swift · GlassSpecularSweep.swift · PartnerAvatarView.swift
              FoilOpen/ (FoilDeckTheme, MetallicCaseView, SpectrumSparkField)
  Text/       GradientText.swift · HighlightText.swift · HolographicText.swift · LivingText.swift · SpectrumBulletRow.swift
  Progress/   ProgressBar.swift · ProgressRingView.swift · ScoreRing.swift · OnboardingProgressBar.swift
              ScreenshotProtectionModifier.swift
  VaylEmptyState.swift · VaylHairline.swift

Features/Onboarding/
  Director/      VaylDirector.swift          — the ONLY writer of OB phase state
  Models/        VaylCardModel.swift
  Canvas/        TableSurface/ · Engines/ · Sequencers/ · Math/
  Store/         onboarding state store
  Phases/        StatPhase · GenderPhase · NamePhase · ModeSelectPhase · DemoPhase
                 ExperienceLevelPhase · ContextPhase · CuriosityPhase · BuildDeckPhase
                 ConfirmationPhase · FounderLetterPhase · CredentialEditorSheet

Features/  Auth/ · Desire Map/ · Home/ · Learn/ · Map/ · Monetization/ · Play/ · Settings/
```
