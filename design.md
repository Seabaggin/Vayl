# Vayl — Design System Reference

> For Claude design sessions. All values are live from the codebase — do not invent alternatives.

---

## Identity

**Aesthetic:** Dark cosmic / neon aurora. Deep space backgrounds, chromatic spectrum accents, glass-morphism surfaces. Feels like a high-end instrument, not a wellness app.  
**Modes:** Full dark mode + warm aurora light mode. Most screens are dark-first.  
**Motion:** Intentional, physics-based. Spring animations, scroll-driven fades, sequential reveals.

---

## Color System (`AppColors.swift`)

### Core Spectrum — the 3 anchor colors

```
cyan    #00C2FF   — leading edge, electric blue
purple  #6C3AE0   — midpoint, deep violet
magenta #FF006A   — trailing edge, hot pink-red
```

Gradient direction: leading → trailing (horizontal) or topLeading → bottomTrailing (diagonal, 135°).

These three colors are the visual signature of Vayl. They appear on every card border, in keyword highlights, in the spectrum line, in glow bloom, and in the tab bar pill. They are never diluted to pastels in dark mode.

### Extended Spectrum

```
pink           #FF2D8A   — soft magenta, shimmer gradients
deepBlue       #0078FF   — glow field floor washes
electricViolet #8B5CF6   — orb layers, gradient midpoints
purpleVivid    #9333EA   — LivingText only
purpleBright   #C084FC

cyanLight      #4DD8FF   — keyword gradient text, badges
purpleLight    #A78BFA
magentaLight   #FF4D94

cyanDark       #0891B2
purpleDark     #1A1A5E
magentaDark    #BE185D
```

### Dark Mode Backgrounds

```
pageBg         #030305   — main app background (near-black with blue cast)
appIconBg      #090B17   — icon background only
widgetDarkFloor #08060A  — dark floor behind home widgets
cardBg         #12111A   — default card interior
surfaceBg      #1A1825   — elevated surfaces, sheets, modals
surfaceRaised  #0C0C10   — input fields, slightly raised elements
```

**Tinted card backgrounds** (intensity levels 5–8):
```
tintCyan       #061018
tintPurple     #080614
tintMagenta    #120610
tintNavy       #0A1018
tintIndigo     #0A0820
tintPlum       #180818

tintSupernovaA #081420
tintSupernovaB #0C0624
tintSupernovaC #1A0620
tintSupernovaD #1C0818
```

### Dark Mode Text

All text is white-family. Opacity lets the purple atmosphere bleed through — never introduce flat grey.

```
textPrimary    #E8E8F0          — prompt content, headings (near-white, subtle warm)
textSecondary  white @ 65%      — descriptions, labels
textTertiary   white @ 38%      — timestamps, meta (+ .italic() at usage site)
textHint       white @ 42%      — placeholders, helper copy
textMuted      white @ 20%      — disabled, ghost states
textBright     white @ 90% (absolute) — small labels on purple ambient backgrounds
```

### Dark Mode Borders

```
border         white @ 6%       — default subtle
borderHover    white @ 10%      — hover/active
borderActive   white @ 15%      — prominent
```

### Off-Spectrum

```
gold      #C8960A   — SAFETY SIGNALS ONLY (safe word button, hard stops)
goldLight #E2B93B
goldDark  #8B6914

gold at ≤8% opacity: acceptable in aurora atmosphere blobs
gold at visible opacity: safety use ONLY — never decorative
```

```
success     #00CC88
destructive #FF4444
```

### Gradient Tokens

```
AppColors.spectrumBorder   — cyan → purple → magenta, topLeading → bottomTrailing
                             Used on every prompt card border at full opacity

AppColors.spectrumText     — cyan → purpleLight → magenta, leading → trailing
                             Used with .foregroundStyle() on keyword Text views
```

### Light Mode ("Warm Aurora")

Background: `#F8F6EE` (warm cream — never change this).  
Palette: magenta, purple, gold — **no cyan** (reads too clinical on cream).

```
lightPageBg     #F8F6EE   — warm cream
lightCardBg     #FFFFFF   — card interiors
lightSurfaceBg  #F2EFE6   — inset fields
```

**Light mode text — wine scale:**
```
lightHeadline      #3D1A26   — darkest wine, display headers
lightBodyPrimary   #5C1F35   — mid wine, all body text
lightBodyAccent    #7A2D45   — lighter wine, accent / detail
lightBodyWineDark  #703040   — pill labels, CTA text

lightTextSecondary  lightBodyPrimary @ 60%
lightTextTertiary   lightBodyPrimary @ 38%  (+ .italic())
lightTextMuted      lightBodyPrimary @ 22%
```

**Light mode glass fills (opaque — use these, not white @ X%):**
```
lightFrostCard      rgb(0.989, 0.985, 0.972)  — warm near-white card fill
lightFrostPill      rgb(0.910, 0.875, 0.945)  — unselected pill
lightFrostPillSel   rgb(0.958, 0.875, 0.925)  — selected pill, rose-blush lift
lightFrostCTA       rgb(0.992, 0.990, 0.980)  — CTA button
lightCTAFill        rgb(0.98, 0.91, 0.93)     — opaque rose CTA base
```

**Light mode border gradient:**
```
AppColors.warmAuroraBorder  — purple → magenta → gold, topLeading → bottomTrailing
AppColors.warmAuroraText    — purple → purpleLight → magentaLight, leading → trailing
```

---

## Typography (`AppFonts.swift`)

Two fonts. No system fonts in production UI.

**Display:** Clash Display (Bold, Semibold, Medium)  
**Body:** Switzer (Regular, Medium, Semibold, Bold)

### Semantic Tokens

| Token | Font | Size | Weight | Use |
|---|---|---|---|---|
| `displayHero` | Clash Display | 64pt | Bold | Hero moments only |
| `heroTitle` | Clash Display | 42pt | Bold | Screen-level hero |
| `scoreDisplay` | Clash Display | 32pt | Bold | Score / stat callouts |
| `screenTitle` | Clash Display | 24pt | Semibold | Screen titles |
| `cardTitle` | Clash Display | 22pt | Semibold | Card titles |
| `sectionHeading` | Clash Display | 20pt | Medium | Section headers |
| `prompt` | Clash Display | 17pt | Medium | Prompt card body |
| `promptHighlight` | Clash Display | 17pt | Semibold | Highlighted words in prompts |
| `sectionLabelSmall` | Clash Display | 13pt | Medium | Small section labels |
| `ctaLabel` | Switzer | 16pt | Semibold | Primary CTA buttons |
| `bodyText` | Switzer | 16pt | Regular | Body copy |
| `bodyMedium` | Switzer | 15pt | Medium | Secondary body |
| `buttonLabel` | Switzer | 14pt | Semibold | Secondary buttons |
| `caption` | Switzer | 13pt | Regular | Captions |
| `overline` | Switzer | 11pt | Semibold | Overline labels |
| `buttonLabelSmall` | Switzer | 11pt | Medium | Small buttons |
| `tabLabel` | Switzer | 10pt | Medium | Tab bar labels |
| `label` | Switzer | 10pt | Semibold | Compact labels |
| `badge` | Switzer | 10pt | Medium | Badges |
| `meta` | Switzer | 10pt | Regular | Timestamps, meta |

---

## Card System

### Card Intensity (8 levels mapped from difficulty)

| Level | Name | Difficulty | Background |
|---|---|---|---|
| 1 | Void | Easy | `cardBg` |
| 2 | Deep Ocean | Easy | `cardBg` |
| 3 | Ember Floor | Medium | `cardBg` |
| 4 | Split | Medium | `cardBg` |
| 5 | Nebula | Deep | `tintCyan → tintPurple → tintMagenta` gradient |
| 6 | Aurora Band | Deep | `cardBg` |
| 7 | Deep Space | Sensitive | `tintNavy → tintIndigo → tintPlum` gradient |
| 8 | Supernova | Ultimate | 4-stop supernova gradient |

Levels 5+ use gradient backgrounds. Glow radius scales 30pt → 60pt. All cards get `spectrumBorder` (cyan → purple → magenta).

### Card Components

- `PremiumCardShell` — master shell with glass aesthetic, specular highlight, ambient orbs, fuse animation
- `PromptCard` — prompt text with difficulty indicator, keyword highlighting
- `CardFrontView` / `CardBackView` — flip states
- `CardCarousel` — horizontal scroll session container (used in Play and Home deck)
- `CardChestContainer` — fanned home deck, tap → gathered → carousel
- `AtmosphericGhostDeck` — floating deck atmosphere effect
- `CuriosityFlipCard` — onboarding curiosity picker card
- `ConversationCard` — scenario cards for Play/Simulations
- `CategoryTileView` — category selector grid
- `FuseTimerView` — in-card countdown timer animation
- `CardRevealPillButton` — pill trigger for card reveal

---

## Effects Library

All effects are in `Design/Components/Effects/`.

| Component | Description |
|---|---|
| `AuroraGlowField` | General background glow field (aurora blobs) |
| `HomeGlowField` | Home-specific glow, scroll-reactive |
| `OnboardingGlowField` | Onboarding atmosphere |
| `FloatingCard` | Single floating card with physics |
| `FloatingStack` | Stacked floating cards |
| `GlowOrb` | Radial glow orb, composable |
| `GlowUnderline` / `GlowUnderlineView` | Neon underline with bloom |
| `HolographicShimmer` | Diagonal shimmer sweep, dark mode |
| `LightModeShimmer` | Warm aurora shimmer sweep, light mode |
| `LightAuraBloom` | Soft light bloom layer |
| `FlameAura` | Flame-like animated aura |
| `SparkField` | Particle spark field |
| `TileOrbitView` | Tiles orbiting a center point |
| `MazePatternView` | Grid pattern background texture |

---

## Buttons

| Component | Use |
|---|---|
| `HoloCTAButton` | Primary CTA — holographic gradient, specular |
| `GradientButton` | Standard gradient-filled button |
| `CriticalButton` | Destructive / high-stakes action |
| `SafeWordButton` | Gold only — safety signals, hard stops |
| `SelectablePill` | Mode/option pills with selected state |

---

## Navigation

### RacetrackTabBar
- 4 tabs: Home, Play, Map, Learn
- Animated pill: old tab reverses (0.35s), new tab draws (0.35s), 0.1s handoff overlap
- Prevents interruption via `isAnimating` flag
- Haptic feedback on selection

### TabContentWrapper
- Wraps every tab's root view
- Bottom padding for tab bar clearance (~78–90pt)
- Gradient fade mask at scroll floor before bar
- Adjusts scroll indicator inset

### Onboarding Navigation
- `OnboardingNavBar` — top bar with back + progress
- `OnboardingFooter` — CTA + skip
- `OnboardingProgressBar` — step-by-step fill

---

## Progress & Data Visualization

| Component | Description |
|---|---|
| `ProgressBar` | Linear fill, spectrum-colored |
| `ProgressRingView` | Circular ring progress |
| `ScoreRing` | 3-color polyam sweep ring |
| `SpectrumBar` | Gradient spectrum horizontal bar |
| `OrbitIndicator` | Orbit-style radial indicator |
| `PulseGraph` | 7-day (and extended) neon line graph |
| `PulseDotSummary` | Dot grid summary of check-in history |

---

## Text Components

| Component | Description |
|---|---|
| `GradientText` | Foreground gradient over text |
| `KeywordHighlightText` | Inline keyword highlighting with `spectrumText` gradient |
| `LivingText` | Animated, breathing text |

---

## Structural Components

| Component | Description |
|---|---|
| `HomeWidgetShell` | Standard glass-card container for home widgets |
| `SectionHeader` | Section title row |
| `PillBorder` | Spectrum or warm aurora pill outline |
| `OrbitSparkBorderView` | Border with animated spark particles |
| `NavArrow` | Directional navigation arrow |
| `CardStyle` | Card styling utilities (applied as modifiers) |
| `FilamentMode` | Display mode enum (affects rendering pass) |
| `ScreenshotProtectionModifier` | Blocks OS screenshots on sensitive screens |

---

## Input

| Component | Description |
|---|---|
| `InteractiveField` | Styled text input with floating label |
| `RatingButtonGroup` | Horizontal rating selector (1–N) |
| `ToggleRow` | Labeled toggle row |

---

## Theming System

`AppTheme.swift` defines `ThemeMode` (`.system`, `.light`, `.dark`) and `AppPalette` with full semantic token sets for both modes.

`ThemeManager` — `@Observable`, drives palette from user setting.  
`ThemedRootModifier` (`.themedRoot()`) — inject into root.  
`ThemedCardModifier` (`.themedCard(selected:)`) — card selection state.

Dark palette is the primary design surface. Light mode uses warm aurora palette. Do not mix tokens across modes.

---

## Spacing & Shape

No formal spacing scale is defined in code — use contextual judgment from surrounding components.

**Corner radii in use:**
- App icon: `size * 0.225`
- Cards: ~12–16pt
- Pills: fully rounded (`.capsule()`)
- Sheets/modals: 20–24pt

**Layout patterns:**
- Safe area respected via `ignoresSafeArea(.container, edges: .bottom)` only where intentional
- Scroll content padded for `RacetrackTabBar` clearance via `TabContentWrapper`
- Home scroll uses `coordinateSpace` for offset tracking, driving opacity/parallax effects

---

## Animation Principles

- **Spring physics** for all interactive transitions (card lift, tab selection)
- **Sequential reveals** on screen entry — elements stagger in, not all at once
- **Scroll-driven opacity** — greeting fades, elements appear as user scrolls
- **No jarring cuts** — even state transitions use crossfade or slide
- **Reduce Motion respected** — all sequences have a `reduceMotion` branch that delivers a valid static end-state
- **Haptics** — `.selection` on tab changes, `.impact` on significant interactions, `.notification` on completion

---

## Brand Component

`VaylAppIcon` (`Design/Brand/VaylAppIcon.swift`)  
- Parameterized by `size: CGFloat`  
- Background: `#090B17`  
- Wordmark: "VAYL" in ClashDisplay-Bold, split horizontally at 50% — top half cold white (#E7EEFF @ 97%), bottom half spectrum gradient (cyan → purple → magenta)  
- Spectrum line: runs from V's ink left edge to L's horizontal midpoint, with 3-layer bloom glow  
- Grain, vignette, border applied as layers  
- Works at 40pt, 60pt, 120pt, 280pt
