---
name: Vayl
description: Deep-space discovery instrument for couples exploring non-monogamy — quiet, gravitational, dark-only.
colors:
  spectrum-cyan: "#00C2FF"
  spectrum-purple: "#6C3AE0"
  spectrum-magenta: "#FF006A"
  spectrum-bridge: "#8B6FD4"
  page-background: "#030305"
  void: "#0A0810"
  card-background: "#12111A"
  card-bg-ob: "#120F1A"
  modal-background: "#1A1825"
  input-background: "#0C0C10"
  widget-background: "#08060A"
  text-primary: "#E8E8F0"
  text-bright: "#E6E6E6"
  safety-gold: "#C8960A"
  success: "#00CC88"
  destructive: "#FF4444"
typography:
  display:
    fontFamily: "ClashDisplay, Georgia, serif"
    fontSize: "64px"
    fontWeight: 700
    lineHeight: 1.0
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "ClashDisplay, Georgia, serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "normal"
  title:
    fontFamily: "ClashDisplay, Georgia, serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "normal"
  prompt:
    fontFamily: "ClashDisplay, Georgia, serif"
    fontSize: "17px"
    fontWeight: 500
    lineHeight: 1.35
    letterSpacing: "normal"
  body:
    fontFamily: "Switzer, -apple-system, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Switzer, -apple-system, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.16em"
rounded:
  micro: "2px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  container: "20px"
  xl: "24px"
  sheet: "57px"
  pill: "9999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  sm2: "10px"
  md2: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  card-standard:
    backgroundColor: "{colors.card-background}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "14px 16px"
  card-glass:
    backgroundColor: "rgba(255,255,255,0.03)"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.container}"
    padding: "16px"
  pill-selectable:
    backgroundColor: "rgba(255,255,255,0.04)"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.pill}"
    height: "46px"
    padding: "10px 16px"
  button-cta:
    backgroundColor: "{colors.card-background}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    height: "52px"
    padding: "0 32px"
  input-field:
    backgroundColor: "{colors.input-background}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
---

# Design System: Vayl

<!--
Native SwiftUI / iOS 26 project. This DESIGN.md follows the DESIGN.md spec format, but
values, radii, and "components" describe SwiftUI tokens and view modifiers, not CSS/HTML.
Source of truth is the Swift token layer in `Vayl/App/Theme/`; the full source-verified
extraction (with drift notes) lives in DESIGN_DOC.md. When they disagree, the token files win.
Colors below are the dark ("Midnight") values — the only appearance V1 renders.
No `.impeccable/design.json` sidecar is generated: it exists to feed the browser live panel,
which is skipped for native platforms.
-->

## 1. Overview

**Creative North Star: "The Bioluminescent Deep"**

Vayl is a near-black ocean floor where light is earned and rare. Backgrounds sit at true depth (`#030305`), and the single spectrum gradient (cyan → purple → magenta) surfaces only where it is deserved: on a stroke, on display text, on a hero element. Living surfaces breathe slowly, the way something alive does at pressure and in the dark; inert chrome pulses only to say it is still there. The register is a quiet dark room, not a dashboard, and a high-end instrument, not a wellness app. When in doubt, the system goes slower, softer, and darker.

Components are **calm at rest, alive on touch, and ceremonial when it matters.** A card, a pill, a button sits near-flat and quiet until a finger arrives; then it presses, glows, shimmers, and lifts. The rare heavy moments (a foil-open, a two-device seal, a reveal) earn full ceremony. Everything between stays restrained, because the ceremony only reads as ceremony against a quiet floor.

This system explicitly rejects engagement-maximizing consumer polish (streaks, confetti, notification bait), clinical or assessment-tool coldness, and bright gamified wellness dashboards. It is a small, optional, respected corner of a couple's life; the visual language carries that humility. It also rejects the reflexive "dark mode with purple gradient + neon + glass everywhere" cliché: glass is one canonical surface, not a default, and the gradient is a rare signature, not a wash.

**Key Characteristics:**
- Deep-space near-black floor; light is earned, never ambient decoration.
- One spectrum gradient (cyan → purple → magenta), reserved for strokes, display text, and hero elements ≥24pt.
- Two breathing tempos only: living surfaces at 5.4s, inert chrome at 2.0s.
- Directional color meaning: cyan = Me / private, magenta = Us / shared.
- Gold appears only for safety (safe-word, hard stops), never as decoration.
- Dark-only in V1; light ("Dawn") token values are authored but dormant.

## 2. Colors

A monochrome white-on-near-black text system lit by one earned three-color spectrum, with gold quarantined to safety.

### Primary
- **Electric Cyan** (`#00C2FF`): The leading spectrum edge and the primary accent (`accentPrimary`). Carries directional meaning: **cyan = Me / private.** Used for `textAccent`, focused inputs, selected states, and the start of every spectrum stroke.

### Secondary
- **Deep Violet** (`#6C3AE0`): The spectrum midpoint and `accentSecondary`. Anchors glow bloom and the center of gradient strokes. **Spectrum Bridge** (`#8B6FD4`) is the mid-stop used when a gradient needs a softer handoff.

### Tertiary
- **Hot Magenta** (`#FF006A`): The trailing spectrum edge and `accentTertiary`. Carries directional meaning: **magenta = Us / shared.** Terminates every spectrum stroke and drives the magenta shadow bloom under elevated cards.

### Neutral
- **Page Floor** (`#030305`): The app background; near-black with a faint blue cast. The deepest surface.
- **OB Void** (`#0A0810`): The onboarding canvas floor, a hair warmer than the page floor.
- **Card Fill** (`#12111A`): Standard opaque card interior (`.themedCard()`). OB glass card is `#120F1A`.
- **Modal Fill** (`#1A1825`): Sheets and covers.
- **Input Fill** (`#0C0C10`): Text fields and raised inputs.
- **Widget Floor** (`#08060A`): Behind home widgets.
- **Near-White Ink** (`#E8E8F0`): `textPrimary`, prompt content and headings; a subtle warm near-white. Secondary/tertiary/muted text are white at 0.65 / 0.50 / 0.20 opacity so the dark atmosphere bleeds through. **Device-Absolute Ink** (`#E6E6E6`, `textBright`) is a deliberately untinted small-label color for use over purple ambient washes.
- **Glass Surface** (white @ 0.03): The canonical `.vaylGlassCard()` fill — the Map-tab translucent look. The frosted family adds `whisperFill` (white @ 0.04) and selected-pill frost (white @ 0.10).
- **Structural Borders**: `borderSubtle` white @ 0.06 (default), `borderDefault` white @ 0.10 (hover/focus), `borderActive` white @ 0.15.

### Off-spectrum — Safety
- **Safety Gold** (`#C8960A`): Safe-word and hard-stop surfaces only, at full opacity. As atmosphere it is permitted at ≤8% opacity, enforced at the call site.

### Feedback
- **Success** (`#00CC88`) and **Destructive** (`#FF4444`): Terminal and warning states only, never accents.

### Data-viz ramps (never UI accents)
Pulse tier colors and per-tier aura ramps (cyan / indigo / magenta / rose / lavender-silver / sage) exist solely for the Pulse circumplex. Card-intensity tints exist solely for the onboarding Context Card system. Do not reach for either family as a general UI accent.

### Named Rules
**The Earned Spectrum Rule.** The full cyan → purple → magenta gradient appears only on strokes, on display text, or on a hero element ≥24pt. Below that size it muddies; use a single accent (`textAccent` cyan) instead. Never use the gradient on body links.

**The Don't-Cross-the-Wires Rule.** Cyan means Me / private and magenta means Us / shared. This mapping is load-bearing; never swap them for visual variety.

**The Gold-Is-Sacred Rule.** Visible gold means safety, always. It is never decorative, never a highlight, never a "premium" accent.

## 3. Typography

**Display Font:** ClashDisplay (Bold / Semibold / Medium)
**Body Font:** Switzer (Regular / Medium / Semibold / Bold)
**Scoped exception:** Menlo, only on the founder-letter screen.

**Character:** A geometric display face against a neutral humanist sans — paired on a real contrast axis, not two look-alike sans. ClashDisplay carries prompts, titles, scores, and hero moments with quiet authority; Switzer carries all body, labels, and controls. Every glyph routes through `AppFonts.display(...)` or `AppFonts.body(...)`; the two constructors assert-fail on an unsupported weight rather than silently rendering wrong.

### Hierarchy
- **Display Hero** (ClashDisplay Bold, 64pt, line-height 1.0): Reserved for singular hero moments.
- **Hero / Masthead** (ClashDisplay Bold, 42–40pt): Screen-level hero and tab mastheads.
- **Score** (ClashDisplay Bold, 32pt): Score and stat callouts.
- **Screen / Sheet Title** (ClashDisplay Semibold, 24pt): Screen and sheet titles.
- **Card Title** (ClashDisplay Semibold, 22pt): Card headings.
- **Section Heading** (ClashDisplay Medium, 20pt): Section headers.
- **Prompt** (ClashDisplay Medium 17pt / Semibold 17pt for highlights): Prompt-card body and its highlighted words.
- **CTA Label** (Switzer Semibold, 17pt): Primary CTAs.
- **Body** (Switzer Regular, 16pt): Body copy. Cap prose at 65–75ch.
- **Caption** (Switzer Regular, 13pt): Captions and meta.
- **Overline / Label** (Switzer Semibold, 11pt, tracking 0.16em, uppercase via `.overlineTracked()`): The one tracked-uppercase label — deliberate, not sprinkled everywhere.

### Named Rules
**The Optical Tracking Rule.** `.vaylDisplayTracking(size)` applies negative optical tracking above 34pt (ramping to −0.02 × size); below 20pt tracking is 0. Large display type tightens; small type never does.

**The No-System-Font Rule.** Production UI uses ClashDisplay and Switzer only. The single sanctioned raw system font is `microBadge` (9pt). Everything else goes through the two constructors.

## 4. Elevation

Depth is built from two independent materials: **shadow-plus-glow layers** for surfaces, and **breathing bioluminescent glow** for living elements. Surfaces are near-flat at rest and gain elevation through paired shadow + colored glow, never a plain grey drop shadow. `Page` carries no shadow; `Card` and `Modal` each carry a deep black shadow plus a magenta bloom.

### Shadow Vocabulary
- **Card** (`.cardElevation()`): black @ 0.50 blur 16 / y 8, plus magenta @ 0.10 blur 24 / y 4. The standard raised-card depth.
- **Modal** (`.modalElevation()`): black @ 0.50 blur 32 / y 16, plus magenta @ 0.10 blur 48 / y 8. Sheets and covers.
- **OB Card Physics** (`cardShadow(elevation:)`): a non-clamped lerp where opacity falls 0.50 → 0.16 while radius grows 8 → 32 as a card lifts off the felt — deliberately inverting opacity-vs-radius to mimic an overhead point light. OB-exclusive.

### Glow Vocabulary
Glows are `{color, radius, x:0, y:0}` layers via `AppGlows` (offsets belong to Elevation, never Glow). Use the glow modifiers (`.spectrumBorderGlow`, `.accentFocus`, etc.); **never** hand-roll `.shadow()` for a glow.

### Named Rules
**The Breathing-Band Rule.** Animated glow intensity never leaves 0.3 → 0.7 (`AppOpacity.glowFloor`/`glowPeak`), and glow opacity never animates 0 → 1. Static layered glow compositions may sit outside that band by design, but any *breathing* value honors it at the call site.

**The Two-Tempos Rule.** Exactly two ambient breathing speeds: **living surfaces** (auras, presence, a heartbeat) breathe at 5.4s (`auraBreathe`); **inert chrome** (a waiting dot, a status pulse) pulses at 2.0s (`ambientPulse`). There is no third tempo — if a loop wants one, it is wrong.

## 5. Components

Every tappable element is calm at rest and comes alive on touch. Do not hand-roll the press choreography; reach for the shared modifiers.

### Buttons
- **Shape:** CTAs use `lg` (16pt); pills are fully rounded (`pill`); secondary buttons use `md` (12pt).
- **Primary CTA (`VaylButton`):** The heavyweight, 52pt tall. Hand-rolled press choreography drives `VaylBorderEffect` — a tapered hairline resolves into a two-sided crisp spectrum stroke, then the glow bursts and settles. Never add `.drawingGroup()` to the border effect; it collapses the outward halo mask.
- **Standard tap targets:** `.buttonStyle(.vaylPressable)` for `Button`-based controls, `.vaylPressableTap(scale:action:)` for non-`Button` targets (press visual lands on touch-down, 12pt release slop). Both bake in `.scaleEffect` + `.sensoryFeedback(.impact(.light))`. This is current practice; the three-modifier tap snippet in CLAUDE.md is only the conceptual baseline.
- **Haptic weight maps to consequence:** light = navigate/select, medium = commit, rigid = two-device seal, heavy = safe-word only, success = terminal.

### Pills / Chips
- **`SelectablePill`:** 46pt default height, fully rounded. Renders `HolographicShimmer` in the background (kept out of `.overlay` so text stays crisp), a `FlameAura` behind selected non-dim pills, and `.pillBorder()` when selected.
- **Intensity** is a shared 3-case vocabulary (`.dim` 0.15 / `.warm` 0.5 default / `.alive` 1.0) used by pill, flame, and aura alike. There is no 4-state difficulty model and no difficulty label — decks mix light and heavy by design.

### Cards / Containers
- **Corner Style:** `lg` (16pt) for standard cards; `container` (20pt) for OB cards, home widgets, and settings surfaces.
- **`.themedCard(selected:)`:** Opaque `#12111A` fill plus a conditional accent border and shadow when selected. The default opaque card.
- **`.vaylGlassCard(accent:radius:)`:** `glassSurface` (white @ 0.03) fill plus a hairline stroke (optionally accent-tinted). The canonical Map-tab translucent surface. Both modifiers live in `App/Theme/ThemeModifiers.swift`.
- **`VaylCardFace`:** The onboarding card face — `.drawingGroup()` is load-bearing and must never be removed; `VaylCardModel` is written only by `VaylDirector`/`GenderSequencer` and read only by rendering views.
- **Pick a card, never hand-roll card chrome.** Use `.themedCard()` (opaque) or `.vaylGlassCard()` (glass).

### Inputs / Fields
- **Style:** `inputBackground` (`#0C0C10`) fill, `md` (12pt) radius, subtle hairline border at rest.
- **Focus:** `accentFocus` glow and cyan border shift; never a plain blue ring.

### Navigation & Presentation
- **`RacetrackTabBar`:** Sliding-capsule tab bar with an animated arc stroke on the selected pill; haptic on selection. (Known holdover: still branches on `colorScheme` in places — do not copy that into new views.)
- **Presentation grammar is mandatory:** route every modal through `.vaylCover` (protected, immersive, interactive-dismiss disabled, confirm-on-exit — Card Session, raters, OB) or `.vaylSheet` (previews and discrete tasks). Never raw `.fullScreenCover` / `.sheet` in feature views.
- **`VaylCloseButton`:** A 32pt glass circle — the one sanctioned dismiss affordance for sheet/cover chrome.

### Signature effects
- **`HolographicShimmer`:** The canonical dark-surface shimmer (specular sweep + drifting color orbs + procedural grain); static fallback under Reduce Motion / Low Power.
- **`LivingText`:** Three-tone breathing gradient text (screen-blended bloom + glow, 30fps-capped) for hero and greeting emphasis words. `HighlightText` is its calm, static sibling for in-prompt highlighted words.
- **`VaylMark`:** The brand aperture mark (nested concave-diamond rings + igniting core), on waiting cards and card backs.
- **`StarVeil`:** A deterministic, seeded twinkling starfield; static under Reduce Motion / Low Power.

### Empty & structural
- **`VaylEmptyState(icon:headline:message:cta:)`:** Every data screen uses this — icon (`textTertiary`) → headline (`cardTitle`) → message (`caption`) → optional CTA.
- **`VaylHairline`:** The one quiet structural divider (`borderSubtle`). `SpectrumHairline` is its ceremonial gradient counterpart — never reach for the branded line where a plain rule belongs.

## 6. Do's and Don'ts

### Do:
- **Do** anchor every screen on `AppColors.pageBackground` (`#030305`) or the OB `void`, with an `OnboardingAtmosphere` behind content.
- **Do** reserve the cyan → purple → magenta gradient for strokes, display text, and hero elements ≥24pt; use a single cyan accent below that.
- **Do** keep cyan = Me / private and magenta = Us / shared, always.
- **Do** use exactly two ambient tempos: 5.4s for living surfaces, 2.0s for inert chrome.
- **Do** gate every looping animation through `.ambientAnimation(_:value:)`, and disable ambient motion entirely under both Reduce Motion and Low Power Mode (remove the loop, not just slow it). Reactive feedback always plays.
- **Do** reach for `.vaylPressable` / `.vaylPressableTap` for taps, and match haptic weight to consequence (light → success).
- **Do** route every card through `.themedCard()` or `.vaylGlassCard()`, and every modal through `.vaylCover` / `.vaylSheet`.
- **Do** pull layout from `AppLayout.from(geo)` and anchor to safe-area insets via `AppSafeArea` helpers.

### Don't:
- **Don't** introduce flat grey text; all text is white-family at graded opacity so the atmosphere bleeds through.
- **Don't** use visible gold for anything but safety (safe-word, hard stops); atmosphere gold stays ≤8% opacity.
- **Don't** default to glassmorphism — glass is one canonical surface (`.vaylGlassCard()`), not decoration sprinkled everywhere.
- **Don't** animate glow opacity 0 → 1, or breathe it outside 0.3 → 0.7.
- **Don't** add a third breathing tempo, a difficulty label, or a 4-state pill intensity — all three are dead by decision.
- **Don't** build engagement-maximizing mechanics (streaks, confetti, notification bait) or bright gamified wellness-dashboard chrome — Vayl is a small, optional, respected corner, not the center of the user's world.
- **Don't** issue a verdict about a person anywhere in the UI; name what they said, compare or rank their own answers, and end every quiz with a door to content, never a conclusion.
- **Don't** use `UIScreen.main` / `UIScreen.main.bounds`, raw `.sheet` / `.fullScreenCover`, or hardcoded hardware padding (`.padding(.top, 60)` / `.padding(.bottom, 34)`) — use the sanctioned helpers.
- **Don't** copy the surviving `@Environment(\.colorScheme)` branches (`RacetrackTabBar`, elevation modifiers) into new views; V1 views are dark-only with no mode-switching logic.
- **Don't** remove `.drawingGroup()` from `VaylCardFace`, or add it to `VaylBorderEffect`.
