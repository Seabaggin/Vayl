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

A segment is not complete until it has run on device and the human has confirmed the feel.
Build succeeds is not done. Feel is correct is done.

---

## Product Principles (Non-Negotiable)

### Humility: Vayl is a small, optional corner of a user's life
The relationship happens off-app, in the real world. Design from that humility, not from an imagined always-on user. Don't build features that assume Vayl is the primary channel for relationship events. Avoid engagement-maximizing mechanics (streaks, push spam, "open to find out" hooks, self-important alerts; a breakup needs no in-app notification). Bias to the minimum feature set that earns a small, respected place.
**Test before proposing a feature:** is it genuinely necessary in a couple's real life, or does it only make sense if Vayl is the center of their world? Default to the humbler answer.

### The user journey: two temperatures, one path (not two types)
"Excited" and "anxious" are states of the same person, converging at the partner invite, not two populations. Anyone in the app is already curious-leaning and partner-cautious, not paralyzed (the truly anxious never installed it). The hesitation is rarely about NM itself; it's about the partner step, and about not yet knowing their own shape ("I want NM" is a direction, not a want).
- The solo lane is a genuine **self-discovery bridge** with standalone value (clarity in either direction), not a holding pen and not a funnel.
- Guiding a curious user toward the partner invite is **not funneling**: the core value (Desire Map, sessions) is dyadic, so helping them get there is the tool working as intended.
- But this persona bolts under pressure. **Guide by clarifying, not prompting**; the invite must feel like the user's own conclusion. Keep an honest off-ramp ("not now / not for me" is a respected outcome). That honesty is what makes the eventual yes durable.

### Discovery tools are NOT assessment
Vayl is not a clinical or therapy tool. It gives people **maps, vocabulary, and mirrors, and lets them make the determinations.** It never issues findings about a user.
**The bright line: name what the user said, never infer what they didn't.** Direct desire questions stay in naming; a personality/trait quiz that concludes an unstated trait is assessment. Only two operations on quiz data are permitted:
- **Compare two points** (e.g. the couples Desire Map: relational distance, led with overlap).
- **Rank or distribute one person's own answers.** A summary is fine only if it stays traceable to and descriptive of their answers, never an opaque verdict.
Labels are **wayfinding vocabulary, not assigned identity.** End every quiz with a door to content, never a conclusion.

**An assessment looks like (banned):**
> "You are an Explorer." / "Do you recharge alone? → You're an introvert." (infers an unstated trait and hands down a verdict about the person)

**A discovery tool looks like (the pattern):**
> "You said you want loving relationships outside your main one. That's often called polyamory, here's where to explore it." (names what they said, then hands them the vocabulary and a door)
> "Here's where you two meet, and where there's distance." (the Desire Map: compares two points, never characterizes either)

---

## iOS 26 / Xcode 26 — Mandatory Compliance

The iOS 26 SDK is mandatory for App Store submissions (Apple skipped 19-25 to align with 2026).
Use Swift 6 and an iOS 16+ baseline. Several long-standing warnings are now **hard compiler errors
and App Review rejections**:

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
| Drilling a real hierarchy | **push** (`NavigationStack`) | Learn → research → finding |
| Previewing something you return *from* | **`.vaylSheet`** | match preview, deck inspect, Pulse history |
| Completing a discrete task | **`.vaylSheet`** | profile edit, add agreement, pairing code, Settings sub-screens (Partner, Privacy, etc. — Settings has no NavigationStack; every sub-screen is a sheet) |
| Entering a protected, immersive mode | **`.vaylCover`** | Card Session, Desire rater, Pulse check-in, OB |

- **Card Session is always a `.vaylCover`, never a sheet.** It is the most protected
  experience in the app (two-device, safe-worded) — interactive-dismiss disabled,
  confirm-on-exit (Duolingo-lesson logic). A swipe-away sheet mid-session is a violation.
- `.vaylCover` = full-screen cover + dismiss-guard + confirm-on-exit.
  `.vaylSheet` = sheet + standard detents / background / grabber.
- Define/extend both in `Vayl/Design/Components/Navigation/VaylPresentation.swift`
  (front-end UX spec, 2026-06-17).

---

## Safe Area & Tab Bar Contract

**Anchor to the safe area, never the screen edge.** Proper placement is a relationship the
system already knows — ask it, don't hardcode a number. If you are reaching for a literal to
clear a piece of hardware or chrome, you are doing it wrong; find the inset.

- **The tab bar owns its own clearance.** It is attached as `.safeAreaInset(edge: .bottom)` in
  `AppShell` — SwiftUI positions the pill above the home indicator AND reserves its measured
  height as a bottom inset for every tab automatically. **Tab content must NOT add its own
  bottom clearance** (no `.bottomContentInset`, no `.padding(.bottom, …)` for the bar); it is
  already reserved. Re-deriving the bar height anywhere else (the old `TabContentWrapper`
  `.contentMargins(.bottom, 62 …)`) is the bug, not the fix.
- **Covers / sheets** (outside the tab shell) have no AppShell inset, so they DO own their
  bottom clearance: `.stickyBottomCTA` for a pinned CTA, else `.bottomClearance(layout)`.
- **Top chrome** clears the Dynamic Island via `.topClearance(layout)` — never `.padding(.top, 60)`.
- **Backgrounds bleed, content insets.** Atmospheres / fills use `.ignoresSafeArea()`; content
  and chrome stay inside the safe area.
- Never `.padding(.bottom, 34 / 100)` or `.padding(.top, 60 / 120)` as a hardware proxy. Helpers
  live in `AppSafeArea.swift`; raw insets in `AppLayout` (`homeIndicatorInset`, `topHardwareInset`).

---

## Design Token Contract

**Zero raw values in Views.** Never use `.red`, `Color(hex:)`, `.font(.title)`,
or numeric literals for spacing, radius, opacity, or animation duration.

**Token source of truth: `Vayl/App/Theme/`.** Exact names live in those files. Read the relevant one before using a token, and never invent a token or a raw value.

| Token | File | Provides |
|---|---|---|
| `AppColors` | `AppColors.swift` | void / cardBg, spectrum (cyan · purple · magenta), surfaces, text, accent, feedback, shadows |
| `AppFonts` | `AppFonts.swift` | ClashDisplay display set + Switzer body set + `.display(_:weight:relativeTo:)` / `.body(...)` constructors |
| `AppSpacing` | `AppSpacing.swift` | `xxs`(2) to `xxl`(48) scale |
| `AppRadius` | `AppRadius.swift` | `sm`(8) to `pill`, plus OB (`obCard` 14 / `cornerCard` / `foilEdge`) |
| `AppLayout` | `AppLayout.swift` | `from(geo)` geometry + OB card sizing |
| `AppAnimation` | `AppAnimation.swift` | reactive (`fast`/`standard`/`spring`/`enter`/`exit`), OB physics, ambient durations |
| `AppGlows` | `AppGlows.swift` | glow modifiers (`.spectrumBorderGlow` etc.); use these, never `.shadow()` for glows |
| `AppElevation` | `AppElevation.swift` | `.cardElevation()` / `.modalElevation()` / `cardShadow(elevation:)` |

### Rules that aren't a single token
- **OB card sizing (mandatory, no exceptions):** `AppLayout.obCardWidth(in: screenWidth)` = `min(screenWidth * 0.72, 320)`; `obCardHeight` = `obCardWidth * 1.5`.
- **Layout from geometry only:** `AppLayout.from(geo)`, never `UIScreen.main.bounds` (iOS 26 banned).
- **Looping animations** require `.ambientAnimation(_:value:)` with a Reduce Motion fallback.

### Required View Patterns
Every screen background:
```swift
ZStack {
    AppColors.void.ignoresSafeArea()
    OnboardingAtmosphere(config: .stat).ignoresSafeArea()
    // content
}
```
Every card / surface (pick one, never hand-roll card chrome):
```swift
myCard.themedCard()      // opaque card
myCard.vaylGlassCard()   // translucent glass surface (canonical Map-tab look)
```
Every tappable element (all three required):
```swift
myButton
    .scaleEffect(isPressed ? 0.96 : 1.0)
    .sensoryFeedback(.impact(.light), trigger: isPressed)
    .onTapGesture { store.doSomething() }
```

### OB Card Face Visual Rules
- 1D outline only, no fills
- Spectrum gradient on every stroke: cyan → purple → magenta
- Two render passes: glow (blurred, low opacity) + crisp (full opacity)
- All geometry proportional to cardWidth/cardHeight, no fixed pixels

### Empty States (required on every data screen)
Icon (`AppColors.textTertiary`) + headline (`AppFonts.cardTitle`) + sub-label (`AppFonts.caption`) + optional CTA

## Animation Feel Contract

**Default register: slow, breathing, gravitational.** Quiet dark room, not a dashboard.
When in doubt, go slower and softer. Never guess a duration — pick a token.

### Reach for these first
| Situation | Token |
|---|---|
| Looping ambient | `ambientPulse` (2s) or `ambientDrift` (4s) via `.ambientAnimation()` |
| Screen swap | `.vaylDepth(.quiet)` + `depthQuiet` |
| Sheet/cover entry | `arrive` / `arriveCover` |
| Element appears | `enter` (0.4s ease-out) |
| Element leaves | `exit` (0.2s ease-in), opacity only |
| Tap press/release | `fast` down, `spring` (0.5/0.85) up |
| Glow breathe | `ambientPulse` or `auraBreathe`, opacity 0.3→0.7 only — never 0→1 |

### Three causes of jitter — ban all three
1. **Competing animations on the same property** — one animation per property per view
2. **Short loops** — nothing repeating under 2s; `ambientShimmer` (1.2s) is the one decorative exception
3. **Springs on ambient motion** — springs are for user-initiated interactions only; ambient always uses `.easeInOut`, never `.spring()` on `.repeatForever()`

### Hard rules
- Glow opacity range: 0.3→0.7. Never 0→1.
- Springs: `dampingFraction` ≥ 0.75 outside the OB canvas
- Every loop: `.ambientAnimation(_:value:)`, never raw `.animation()`
- Ambient animations disabled entirely under Reduce Motion — remove the loop, not just slow it
- Ambient animations also disabled under **Low Power Mode** (added 2026-07-04): `.ambientAnimation()` gates it automatically; manual mount/start guards must check `reduceMotion || AppAnimation.lowPower` (or `AppAnimation.ambientMotionDisabled`). Reactive animations and one-shot effects are never LPM-gated — user feedback always plays
- Continuous `TimelineView(.animation)` surfaces need a frame-rate cap matched to their motion (`minimumInterval:`) — a colour drift or slow wander never needs display rate

---

## V1 Launch Scope — Dark Mode Only

**Light mode is deferred to post-launch.** The V1 codebase must contain zero light mode
references, colors, or infrastructure. This includes:
- No `@Environment(\.colorScheme)` checks in Views
- No conditional light/dark color definitions in `AppColors` or token files
- No `preferredColorScheme()` modifiers
- No light mode assets or accent definitions

The dark-only constraint simplifies V1 ship, keeps design coherent, and establishes
intent for future: post-launch light-mode work is a separate, comprehensive pass.

---

## Violation Checklist
- [ ] No raw colors, fonts, spacing, radius, or opacity in Views
- [ ] No raw animation curves/durations anywhere (Views, Stores, sequencers) — AppAnimation tokens only; screen/content transitions use a motion staple (`.vaylDepth` / `arrive` / tap contract), never ad hoc slides (spec: docs/superpowers/specs/2026-07-03-motion-system-design.md)
- [ ] No UIScreen.main or UIApplication.shared.keyWindow (iOS 26 banned)
- [ ] No UIWebView or NSURLConnection (iOS 26 hard errors)
- [ ] No UNAuthorizationOptionAlert, use .Banner variant
- [ ] No UIScreen.main.bounds, use AppLayout.from(geo)
- [ ] Tab content adds NO bottom clearance (AppShell `.safeAreaInset` owns it); covers/sheets use `.bottomClearance` / `.stickyBottomCTA`
- [ ] No hardcoded hardware padding (`.padding(.top, 60)` / `.padding(.bottom, 34/100)`); use `.topClearance` / safe-area insets
- [ ] No Service/network calls in Views
- [ ] No View writes to VaylCardModel
- [ ] No phase change without director.advance()
- [ ] No VaylCardFace shell modifications
- [ ] Every OB screen: AppColors.void + OnboardingAtmosphere
- [ ] Every OB card: VaylCardFace + AppLayout.obCardWidth/Height
- [ ] Every tap: press state + haptic + action
- [ ] All looping animations: .ambientAnimation()
- [ ] All OB card face geometry proportional
- [ ] .drawingGroup() on VaylCardFace, never remove
- [ ] Reduce Motion fallbacks on all animations
- [ ] Empty state on every data screen
- [ ] Presentation via .vaylCover / .vaylSheet, never raw .fullScreenCover / .sheet
- [ ] Card Session is a .vaylCover (protected, confirm-on-exit), never a sheet
- [ ] Right-size every feature; none that assumes Vayl is the center of the user's life
- If using XcodeBuildMCP, use the installed XcodeBuildMCP skill before calling XcodeBuildMCP tools.
