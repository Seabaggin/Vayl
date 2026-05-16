# Open Lightly — Design System Reference
**Platform:** iOS 26, SwiftUI, dark mode + light mode. No hardcoded colors/fonts ever.
**Last updated:** 2026-03-22

---

## 1. Visual Identity
Deep space / bioluminescent. Dark backgrounds, spectrum glow (cyan → purple → magenta), breathing animations. Premium wellness feel — never clinical, never sterile.

---

## 2. Color Tokens — `AppColors`

### Dark Mode

```swift
// Core Spectrum
AppColors.accentPrimary          // #00C2FF — primary accent
AppColors.accentSecondary        // #6C3AE0 — mid-spectrum
AppColors.accentTertiary       // #FF006A — emotion accent
AppColors.accentTertiary          // #FF2D8A — shimmer layers
AppColors.accentSecondary      // #0078FF — atmospheric washes

// Variants
AppColors.accentPrimary     // #4DD8FF
AppColors.accentSecondary   // #A78BFA — focused label text
AppColors.accentTertiary  // #FF4D94
AppColors.accentPrimary      // #0891B2
AppColors.accentSecondary    // #1A1A5E
AppColors.accentTertiaryDark   // #BE185D

// Backgrounds (darkest → lightest)
AppColors.pageBackground        // #030305
 AppColors.cardBackground        // #050507
AppColors.modalBackground     // #08080C

// Tinted card backgrounds
 AppColors.cardBackgroundCyanTint    // #061018
 AppColors.cardBackgroundPurpleTint  // #080614
 AppColors.cardBackgroundMagentaTint // #120610
 AppColors.cardBackgroundDeepNavy    // #0A1018
 AppColors.cardBackgroundDeepIndigo  // #0A0820
 AppColors.cardBackgroundDeepPlum    // #180818

// Text
AppColors.textPrimary   // #E8E8F0 — headings, prompt text
AppColors.textSecondary // #AAAABC — labels, descriptions
AppColors.textTertiary  // #666680 — timestamps, meta
AppColors.textMuted     // white @ 20%
AppColors.textBadge     // #5BB8CC

// Borders
AppColors.borderSubtle        // white @ 6% — default
AppColors.borderDefault   // white @ 10% — hover/focus

// Safety — NEVER decorative
AppColors.safetyAccent          // #C8960A — safe word + warnings ONLY

// Gradients
AppColors.spectrumBorder  // cyan→purple→magenta, topLeading→bottomTrailing
AppColors.spectrumText    // cyan→purpleLight→magenta, leading→trailing
AppColors.btnPrimaryFill  // cyan 12%→magenta 10%, subtle fill
AppColors.btnMaxFill      // cyan→purple→magenta, full-intensity CTA

// Glow
AppColors.glowCyan      // cyan @ 10%
AppColors.glowMagenta   // magenta @ 8%
AppColors.glowPurple    // purple @ 6%
AppColors.shadowDeep    // black @ 50%
Spectrum Gradient — Brand SignatureOrder: Cyan → Purple → Magenta — always.
Use on: selected borders, CTA buttons, progress fills, gradient text, completion states.
Never on: static/decorative backgrounds, body text.Bloom Layer Opacity PatternAtmo (outermost): purple 0.30/0.60, magenta 0.80
Mid:              cyan 0.18/0.50, purple 0.90, magenta 0.60/0.30
Core (innermost): cyan 0.25/0.90, purple 0.80, magenta 0.90/0.65
Track/Rail Opacity
Normal: Color.white.opacity(0.18)
High contrast: Color.white.opacity(0.50)
Always Color.white, never Color(.systemFill)
Particle → Gradient Position MappingFill positionColor0–25%AppColors.accentPrimary25–60%AppColors.accentSecondary60–90%AppColors.accentTertiary90–100%AppColors.accentPrimary (echo)3. Light Mode Color TokensPage / SurfaceElementTokenValuePage backgroundlightPageBg#F8F6EE warm creamCard filllightCardFill#FFF4F6 barely-blushGlass cardlightFrostCard#FFFFFF @ 58%Frost pill (unselected)lightFrostPill#FFFFFF @ 55%Frost pill (selected)lightFrostPillSel#FFFFFF @ 75%CTA button filllightFrostCTA#FFFFFF @ 70%Inset field bglightSurfaceBg#F2EFE6Pure white cardlightCardBg#FFFFFFTextRoleTokenValueHeadline / screen titlelightCardTitle#5B1E35 wine darkCard titlelightCardTitle#5B1E35Card detaillightCardDetail#792C45 mid wineBody primarylightTextPrimary#1A1A1EBody secondarylightTextSecondary#1A1A1E @ 50%Body tertiarylightTextTertiary#1A1A1E @ 30%Button / pill labelwineDark#70122E — enabled AND disabledFocused labellightLabelFocused#BE185D (magentaDark)Hint textlightHintText#BE185D @ 50%Overline / italic accentgradientmagenta #FF006A → gold #C8960AKeyword gradient textwarmAuroraTextpurple→purpleLight→magentaLightBorders & ShadowsTokenValuelightBorder#000000 @ 6%lightBorderHover#000000 @ 10%lightShadowMagenta#FF006A @ 18%lightShadowPurple#6C3AE0 @ 12%lightShadowGold#C8960A @ 7%Light Mode Gradient Modifiers
.warmAuroraBorder() — purple→magenta→gold, topLeading→bottomTrailing
.magentaGoldBorder() — magenta→orangeHot(#E07020)→gold, topLeading→bottomTrailing
Light Mode ShimmerAppColors.lightShimmerColors: purple 11%, magenta 10%, gold 8%, magenta 8%, purple 11%Light Mode Atmosphere
Top bloom: RadialGradient magenta 12% → gold 6% → clear, blur 80
Bottom warmth: LinearGradient purple 8% → clear, height 200
Component: AuroraGlowField (NOT OnboardingAtmosphere)
Particles: SparkField with per-screen config
4. DO NOT USE in Light ModeTokenReasonpageBg / cardBg / surfaceBgNear-black dark mode backgroundsAppColors.accentPrimary as textClinical on creamAppColors.accentPrimary mode accent onlyColor.white as textInvisible on creamColor.white.opacity(x) borders/fillsDark mode only — use lightBorder/lightFrost*OnboardingAtmosphereUse AuroraGlowField.preferredColorScheme(.dark)Follows system in light modetextPrimary/Secondary/TertiaryUse lightText* equivalentsAppColors.borderSubtle/borderHoverWhite borders on cream — use lightBorderAppColors.spectrumTextUse warmAuroraText5. Typography Tokens — AppFontsFamilies: Clash Display (headings, prompts, scores) · Switzer (body, labels, buttons)// Parametric
AppFonts.display(_ size: CGFloat, weight: .bold/.semibold/.medium) // ClashDisplay
AppFonts.body(_ size: CGFloat, weight: .semibold/.medium/.regular) // Switzer

// Semantic tokens
AppFonts.heroTitle       // ClashDisplay Bold 42
AppFonts.screenTitle     // ClashDisplay Semibold 24
AppFonts.cardTitle       // ClashDisplay Semibold 22
AppFonts.sectionHeading  // ClashDisplay Medium 20
AppFonts.bodyText        // Switzer Regular 16
AppFonts.bodyMedium      // Switzer Medium 15
AppFonts.caption         // Switzer Regular 13
AppFonts.ctaLabel        // Switzer Semibold 16
AppFonts.buttonLabel     // Switzer Semibold 14
AppFonts.overline        // Switzer Semibold 11
AppFonts.prompt          // ClashDisplay Medium 17
AppFonts.promptHighlight // ClashDisplay Semibold 17
AppFonts.scoreDisplay    // ClashDisplay Bold 32
AppFonts.badge           // Switzer Medium 10
AppFonts.tabLabel        // Switzer Medium 10
Brand Identity Exception (BrandView wordmark only — never replace with AppFonts):.custom("Zodiak-Extrabold", size: 58)    // "Open"
.custom("Zodiak-Bold", size: 54)         // "Lightly"
.custom("GeneralSans-Regular", size: 15) // Tagline
6. Design Rules — Never Break
Zero hardcoded colors. Every color via AppColors. Need a new one? Add to AppColors.swift first.
Zero hardcoded fonts. Every font via AppFonts.
Dark mode: .preferredColorScheme(.dark) on every dark screen's root view.
Gold = safety only. AppColors.safetyAccent reserved for safe word + critical warnings.
Spectrum gradient = interaction reward. .pillBorder() only on selected/active/confirmed states. Static non-interactive cards use AppColors.borderSubtle + plain .stroke.
Color is earned. Unselected/static = muted (white 6% borders, textSecondary). Selected/active = full spectrum.
No external packages. SwiftUI primitives only.
No ! force-unwrap on values that could realistically be nil.
No onChange(of:perform:) — always onChange(of:) { _, newValue in }.
Light mode disabled state: container .opacity(0.45) ONLY — all other visual properties (gradient, shimmer, shadows) render identically.
Two border radius values only: cornerRadius 100 (all pill/CTA shapes) · cornerRadius 20 (all card/tile shapes). Exception: cornerRadius 16 for text input fields only. Never use 14, 24, or any other value for card shapes.
7. Shared Style Modifiers.cardStyle()     // cardBg fill + cornerRadius(20) + border stroke @ 6%
.pillBorder()    // Spectrum gradient stroke + blur + shadow — selected states only
.screenshotProtected()  // Sensitive content

// Light mode only
.warmAuroraBorder()     // purple→magenta→gold gradient border
.magentaGoldBorder()    // magenta→orangeHot→gold gradient border
8. Component Style ReferenceHoloCTAButton
Shape: full-width pill, cornerRadius 100, height 56
Dark — disabled: muted, no glow · enabled: spectrum shimmer + breathing bloom
Light — fill: lightFrostCTA, border: .warmAuroraBorder() @ 3pt/0.90, label: wineDark
Light — shimmer: lightShimmerColors, shadows: magenta/purple/gold stack
.padding(.horizontal, AppSpacing.lg) from parent
SelectablePill// Four intensity states
.unselected  // border 1.5pt white 6%
.dim         // muted text, border 1.5pt
.warm        // warm tint, border 2pt
.alive       // spectrum gradient border + glow, border 2.5pt
OnboardingProgressBar
Track: Color.white.opacity(0.18) normal · 0.50 high contrast
Fill: cyan→purple (normal) · cyan→purple→magenta (final step)
Final step activates: bloom (3-layer Canvas), shimmer sweep, 6 particles
Reduce motion: static bar, no effects
PromiseCard
Background: RoundedRectangle fill white 5% (dark) · lightCardFill (light)
Border: AppColors.borderSubtle stroke 1pt — plain static, NOT .pillBorder()
Icon badge: Circle fill cyan 20%→purple 16% gradient · SF Symbol cyan→purple foreground
Title: bodyMedium / textPrimary · Detail: caption / textSecondary
Background Stack (Screens 3–6, dark mode)ZStack {
    AppColors.pageBackground
    Ellipse() // purple 0.3 → deepBlue 0.15 → clear, blur 80, offset y: -80
    OnboardingAtmosphere() // .allowsHitTesting(false), never over content
}
.ignoresSafeArea()
9. Card Intensity SystemsContext Cards (Onboarding only)IntensityBG TintBorder %Internal GlowExternal Shadowembernone40%nonecyan 4%/10pxsparkcyan 4%@70%50%cyan 10%/100pxcyan 6%/15pxflamecyan 6%@50%60%purple 15%/130pxpurple 8%/20pxblazepurple 8%@40%70%purple 20%/150pxpurple 12%/25pxinfernomagenta 6%@30%80%magenta 20%/170pxmagenta 10%/30pxnovamagenta 10%@20%90%magenta 30%/200pxmagenta 16%/35pxCard: 300×340pt, cornerRadius 20, spectrum border always at intensity.borderOpacity.
Confirmed state: spectrum border @ 100% / 2pt + cyan 0.3/r8 + magenta 0.2/r12 shadows.Prompt Cards (Sessions)IntensityNameDescription1voidPure black2deepOcean+ cyan corner wash3emberFloor+ magenta bottom glow4splitcyan ↗ + magenta ↙5nebulaFull diagonal spectrum6auroraBandHorizontal spectrum stripe7deepSpaceRich tinted + dual wash8supernovaMax saturationSpectrum border is always full opacity on prompt cards. Opacity scales by intensity on context cards only.10. Animation Curve ReferenceUseCurveEntrance stagger (opacity + offset).easeOut(duration: 0.4–0.5)Pill/card selection toggle.easeInOut(duration: 0.2)Custom field swap, deselect hint.easeInOut(duration: 0.25)Wordmark landing.spring(response: 0.6, dampingFraction: 0.82)Card stack snap.spring(response: 0.5, dampingFraction: 0.85)Section expansion.spring(response: 0.55, dampingFraction: 0.82)CTA entrance.spring(response: 0.45, dampingFraction: 0.82)Pill toggle.spring(response: 0.3, dampingFraction: 0.7)Breathing / shimmer loops.easeInOut(duration: 5–6).repeatForever(autoreverses: true)Blob orbits.linear(duration: 8–14).repeatForever(autoreverses: false)Exits (always accelerate).easeIn(duration: 0.3–0.7)Atmospheric transitions.easeInOut(duration: 2.0)Entrance stagger timing:OrderDelayOffset1st (nav/header)0.10–0.15s-8pt (slides down)2nd (content)0.25–0.30s12pt up3rd (secondary)0.40–0.55s12pt upCTA0.48–0.55sspringTimed animations: DispatchQueue.main.asyncAfter only. Never Timer or Combine.11. Light Mode Canonical RulesLM-01: Page bg           → lightPageBg (#F8F6EE)
LM-02: Screen title      → lightCardTitle (#5B1E35)
LM-03: Body primary      → lightTextPrimary (#1A1A1E)
LM-04: Body secondary    → lightTextSecondary (#1A1A1E @ 50%)
LM-05: Caption/label     → lightTextSecondary
LM-06: Hint/overline     → gradient(magenta #FF006A → gold #C8960A)
LM-07: Button label      → wineDark (#70122E) — enabled AND disabled
LM-08–09: Pill labels    → wineDark (selected = unselected in light)
LM-10: Card fill         → lightCardFill (#FFF4F6)
LM-11: Card title        → lightCardTitle (#5B1E35)
LM-12: Card detail       → lightCardDetail (#792C45)
LM-13: Glass card        → lightFrostCard (#FFFFFF @ 58%)
LM-14: Frost pill        → lightFrostPill (#FFFFFF @ 55%)
LM-15: Card border       → .magentaGoldBorder()
LM-16: Button border     → .warmAuroraBorder() — always rendered, no isEnabled branch
LM-17: Button fill       → lightFrostCTA (#FFFFFF @ 70%) — always rendered
LM-18: Disabled state    → container .opacity(0.45) ONLY
LM-19: Overline text     → gradient mask (magenta @ 0.0 → gold @ 1.0)
LM-20: Italic accent     → gradient(magenta → gold)
LM-21: Atmosphere        → AuroraGlowField
LM-22: Particles         → SparkField (per-screen config)
LM-23: Inset field bg    → lightSurfaceBg (#F2EFE6)
LM-24: Focused label     → lightLabelFocused (#BE185D)
LM-25: Hint text         → lightHintText (#BE185D @ 50%)
LM-26: Shadows           → lightShadowMagenta/Purple/Gold
LM-27: Pill selected bg  → lightFrostPillSel (#FFFFFF @ 75%)
LM-28: Border default    → lightBorder (#000000 @ 6%)
LM-29: Border hover      → lightBorderHover (#000000 @ 10%)
LM-30: Gradient keyword  → warmAuroraText (purple→purpleLight→magentaLight)
LM-31: Shimmer           → lightShimmerColors
12. File LocationsApp/Theme/
  AppColors.swift       — All color tokens
  AppFonts.swift        — All typography tokens

Design/Components/
  Buttons/HoloCTAButton.swift
  Cards/ContextCard.swift · ContextCardStack.swift · ContextIntensity.swift
  Navigation/OnboardingNavBar.swift · OnboardingFooter.swift
  Progress/OnboardingProgressBar.swift
  Effects/OnboardingAtmosphere.swift

Features/Onboarding/Views/
  OnboardingFlowView.swift     (coordinator)
  OnboardingStatView.swift     (Screen 1)
  OnboardingBrandView.swift    (Screen 2)
  OnboardingNameView.swift     (Screen 3)
  OnboardingModeSelectView.swift (Screen 4)
  OnboardingContextView.swift  (Screen 5)
  OnboardingCuriosityPickerView.swift (Screen 6)
  OnboardingBuildingPathView.swift    (Screen 7)
  OnboardingGroundRulesView.swift     (Screen 8)
