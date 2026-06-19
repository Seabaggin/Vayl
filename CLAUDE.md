## Architecture Rules (Non-Negotiable)

### 4-Layer Architecture
| Layer | Role | Rules |
|---|---|---|
| **View** | Renders pixels, forwards taps | NEVER calls a Service, database, or network directly |
| **Store** | `@Observable @MainActor` class — owns state, makes decisions | Calls Services, publishes state to Views |
| **Service** | Handles network / I/O | Injected into Stores via initializer |
| **Model** | Pure data shape (`struct`) | No logic, no dependencies |

### Strict Separation of Concerns
- Views read from Stores and call Store methods only
- Stores call Services only
- Services have no reference to Stores or Views
- Models have no reference to anything
- `director.advance()` is the ONLY way to change OB phase
- `tableFade` is written ONLY by `VaylDirector`
- No View writes to `VaylCardModel` directly

## Build Protocol — Non-Negotiable

Never build a full feature in one pass.
Break every feature into named segments.
Each segment must have:

1. ONE thing it does
2. A done condition that is verified in the simulator
   before the next segment begins — not just "build succeeds"
3. A constraints list — files it may not touch

The AI must confirm what it is building before writing
any code. If the AI proposes changes beyond the current
segment's scope, stop it and redirect.

Timing and feel decisions must be verified in a React
demo or interactive reference before being written into
Swift. Never guess at a timing value — always feel it first.

A segment is not complete until it has been run on device
and the human has confirmed the feel is correct.
Build succeeds is not done. Feel is correct is done.
- 

---

## Product Reality Check — This App Is Not the Center of Anyone's Life

Vayl occupies a **small, optional corner** of a user's real life. People pick it up
occasionally; the relationship itself happens off-app, in the real world. Design from
that humility — this is minuscule in the grand scheme of someone living their life.

**When proposing any feature or system-design choice, contextualize it against how
humans actually live — not against an imagined user who is always in the app.** Most of
what matters to a couple happens where Vayl can't see it and doesn't need to.

- Don't build features that assume Vayl is the primary channel for relationship events,
  or that the user is always-on / dependent on it.
- A breakup does not need an in-app notification. People know they're broken up long
  before the app could tell them. If a feature only makes sense when you assume the app
  matters more than it does, **cut it.**
- Bias toward the **minimum necessary** feature set that earns a small, respected place.
  Avoid engagement-maximizing mechanics — streaks, push spam, "open the app to find out"
  hooks, self-important alerts.

**The test, before proposing a feature:** *In a realistic context — a couple living
their actual lives — is this genuinely necessary, or does it only make sense if Vayl is
the center of their world?* Default to the humbler answer.

---

## iOS 26 / Xcode 26 — Mandatory Compliance

Apple skipped versions 19–25 to align iOS 26 with the year 2026.
Most AI coding assistants are trained on data before this shift and are
unaware of these requirements. As of April 28, 2026, the iOS 26 SDK is
**mandatory for App Store submissions**. Several long-standing warnings
are now **hard compiler errors and App Review rejections**.

**When prompting:** tell the AI to "use Swift 6 and assume an iOS 16+ baseline"
to prevent hallucination of ancient APIs the iOS 26 compiler will reject.

### Global Singletons & Window Management — BANNED

| Deprecated | Use Instead |
|------------|-------------|
| `UIScreen.main` | `view.window?.windowScene?.screen` |
| `UIApplication.shared.keyWindow` | `UIWindowScene.windows.first(where: \.isKeyWindow)` |
| `AppDelegate.window` | `SceneDelegate.window` |

### User Notifications — BANNED

| Deprecated | Use Instead |
|------------|-------------|
| `UNNotificationPresentationOptionAlert` | `UNNotificationPresentationOptionBanner` |
| `UNAuthorizationOptionAlert` | `UNAuthorizationOptionBanner` |

### Other Hard Errors
- **32-bit slices** — `armv7` / `armv7s` block compilation
- **Legacy Core Data** — deprecated `NSPersistentStore` option keys now throw errors
- **`UIWebView`** — rejected. Use `WKWebView`
- **`NSURLConnection`** — rejected. Use `URLSession`

### Already Compliant in Vayl
- `AppLayout.from(geo)` — never uses `UIScreen.main.bounds` ✅
- Scene-based window access already enforced in AppLayout ✅

---

## Presentation Grammar — Navigation Contract

**The presentation pattern must match the user's mental state.** Choose by what the user
is doing, not by habit. Route every modal through the `.vaylCover` / `.vaylSheet`
modifiers — never raw `.fullScreenCover` / `.sheet` in feature views (same discipline as
tokens: no raw primitives).

| Mental state | Pattern | Use for |
|---|---|---|
| Scrolling / discovering | inline expand | Home dashboard, Getting Started, deck grid |
| Drilling a real hierarchy | **push** (`NavigationStack`) | Learn → research → finding · Settings → pairing |
| Previewing something you return *from* | **`.vaylSheet`** | match preview, deck inspect, Pulse history |
| Completing a discrete task | **`.vaylSheet`** | profile edit, add agreement, pairing code |
| Entering a protected, immersive mode | **`.vaylCover`** | Card Session, Desire rater, Pulse check-in, OB |

- **Card Session is always a `.vaylCover`, never a sheet.** It is the most protected
  experience in the app (two-device, safe-worded) — interactive-dismiss disabled,
  confirm-on-exit (Duolingo-lesson logic). A swipe-away sheet mid-session is a violation.
- `.vaylCover` = full-screen cover + dismiss-guard + confirm-on-exit.
  `.vaylSheet` = sheet + standard detents / background / grabber.
- Define/extend both in `Vayl/Design/Components/Navigation/VaylPresentation.swift`
  (front-end UX spec, 2026-06-17).

---

## Design Token Contract

**Zero raw values in Views.** Never use `.red`, `Color(hex:)`, `.font(.title)`,
or numeric literals for spacing, radius, opacity, or animation duration.

### AppColors
```swift
// OB Canvas (OB only)
AppColors.void / AppColors.cardBg
AppColors.spectrumCyan / AppColors.spectrumPurple / AppColors.spectrumMagenta
AppColors.spectrumBorder / AppColors.spectrumText   // LinearGradient tokens

// Surfaces
AppColors.pageBackground / AppColors.cardBackground / AppColors.modalBackground

// Text
AppColors.textPrimary / AppColors.textBody / AppColors.textSecondary
AppColors.textTertiary / AppColors.textHint / AppColors.textMuted

// Accent
AppColors.accentPrimary / AppColors.accentSecondary / AppColors.accentTertiary

// Feedback
AppColors.success / AppColors.destructive / AppColors.safetyAccent

// Shadows
AppColors.shadowDeep / AppColors.shadowMagenta / AppColors.shadowPurple
AppFonts// Display — ClashDisplay
AppFonts.heroTitle / AppFonts.displayHero / AppFonts.screenTitle
AppFonts.cardTitle / AppFonts.sectionHeading / AppFonts.prompt

// Body — Switzer
AppFonts.ctaLabel / AppFonts.bodyText / AppFonts.bodyMedium
AppFonts.buttonLabel / AppFonts.caption / AppFonts.overline

// Constructors for custom sizes:
AppFonts.display(_ size:, weight:, relativeTo:)
AppFonts.body(_ size:, weight:, relativeTo:)
AppSpacingAppSpacing.xxs(2) / .xs(4) / .sm(8) / .md(16) / .lg(24) / .xl(32) / .xxl(48)
AppRadiusAppRadius.micro(2) / .sm(8) / .md(12) / .lg(16) / .xl(24) / .container(20) / .pill
// OB: AppRadius.obCard(14) / .cornerCard(4) / .foilEdge(16)
AppLayout// Always resolve from GeometryProxy — never UIScreen.main.bounds (iOS 26: banned)
AppLayout.from(geo) → layout.screenWidth / .screenHeight / .cardWidth / .safeAreaInsets

// OB card sizing — mandatory for all OB cards, no exceptions:
AppLayout.obCardWidth(in: screenWidth)   // min(screenWidth * 0.72, 320)
AppLayout.obCardHeight(in: screenWidth)  // obCardWidth * 1.5

// OB geometry: .dealPointYFrac(.32) / .tableHorizonYFrac(.32)
// Corner deck: .cornerDeckWidth(30) / .cornerDeckHeight(45)
AppAnimation// Reactive
AppAnimation.fast / .standard / .slow / .spring / .enter / .exit

// OB Card Physics
AppAnimation.cardSlide / .cardSettle / .cardPocket / .cardFlip
AppAnimation.cardLift / .deckFan / .deckWeave / .foilDissolve
AppAnimation.tableRecede / .deckReceive / .textProject / .cardBreathe

// Ambient durations (Double, not Animation)
AppAnimation.ambientPulse(2.0) / .ambientDrift(4.0) / .ambientShimmer(1.2)

// Reduce Motion
animation.reduceMotionSafe
.ambientAnimation(_ animation:, value:)  // REQUIRED on all looping animations
AppGlows// Use modifiers — never call .shadow() directly for glows
.spectrumBorderGlow(intensity: Double)
.cornerDeckGlow(visible: Bool)
.accentFocusGlow(visible: Bool)
.safetyGlow(visible: Bool)
AppElevation.cardElevation()   // card shadow for current color scheme
.modalElevation()  // modal shadow for current color scheme
AppElevation.cardShadow(elevation: Double)  // OB physics — 0.0 flat → 1.0 lifted
Required View PatternsEvery screen backgroundZStack {
    AppColors.void.ignoresSafeArea()
    AtmosphereView()
    // content
}
Every card / surfacemyCard
    .glassCard()
    .hairline(.resting)  // or .hairline(.active)
Every tappable element — ALL THREE requiredmyButton
    .scaleEffect(isPressed ? 0.96 : 1.0)
    .sensoryFeedback(.impact(.light), trigger: isPressed)
    .onTapGesture { store.doSomething() }
OB card face visual rules
1D outline only — no fills
Spectrum gradient on every stroke — cyan → purple → magenta
Two render passes — glow (blurred, low opacity) + crisp (full opacity)
All geometry proportional to cardWidth/cardHeight — no fixed pixels
Empty states — required on every data screenIcon (AppColors.textTertiary) + headline (AppFonts.cardTitle) + sub-label (AppFonts.caption) + optional CTAViolation Checklist
 No raw colors, fonts, spacing, radius, or opacity in Views
 No UIScreen.main or UIApplication.shared.keyWindow — iOS 26 banned
 No UIWebView or NSURLConnection — iOS 26 hard errors
 No UNAuthorizationOptionAlert — use .Banner variant
 No UIScreen.main.bounds — use AppLayout.from(geo)
 No Service/network calls in Views
 No View writes to VaylCardModel
 No phase change without director.advance()
 No VaylCardFace shell modifications
 Every OB screen: AppColors.void + AtmosphereView()
 Every OB card: VaylCardFace + AppLayout.obCardWidth/Height + .hairline()
 Every tap: press state + haptic + action
 All looping animations: .ambientAnimation()
 All OB card face geometry proportional
 .drawingGroup() on VaylCardFace — never remove
 Reduce Motion fallbacks on all animations
 Empty state on every data screen
 Presentation via .vaylCover / .vaylSheet — never raw .fullScreenCover / .sheet
 Card Session is a .vaylCover (protected, confirm-on-exit) — never a sheet
 Right-size every feature — none that assumes Vayl is the center of the user's life
