## Design Context

- **PRODUCT.md** (root) — strategic who/what/why: register, users, purpose, positioning, brand personality, anti-references, design principles. Read first for intent.
- **DESIGN_DOC.md** (root) — source-verified visual system: real token values and component APIs. Read for how it looks. (`DESIGN.md` is a leaner companion; when they disagree, this file and CLAUDE.md's rules win.)

---

## Architecture Rules (Non-Negotiable)

### 4-Layer Architecture
| Layer | Role | Rules |
|---|---|---|
| **View** | Renders pixels, forwards taps | NEVER calls a Service, database, or network directly |
| **Store** | `@Observable @MainActor` class — owns state, makes decisions | Calls Services, publishes state to Views |
| **Service** | Handles network / I/O | Injected into Stores via initializer |
| **Model** | Pure data shape (`struct`) | No logic, no dependencies |

### Tabs vs Features — File Tree Ownership
**A tab is NOT a feature.** It is a composition surface. The 4 layers above describe what lives *inside* a module; this describes *where the module lives*.

| Category | What it is | Home |
|---|---|---|
| **Tab** | Composes capabilities. One per `AppTab` case (home/play/map/learn) | `Vayl/Tabs/<Name>Tab/` — composition + tab-specific chrome ONLY |
| **Capability** | Self-contained domain, owns its Views/Store/Services/Models | `Vayl/Features/<Name>/` — flat sibling, NEVER nested under a tab |
| **Flow** | Bounded, self-driving, gated sequence in a cover; composed by no one | `Vayl/Features/<Name>/` (Onboarding, Card Session, Pairing) |

- **Invariant: `Tabs/` may import `Features/`. `Features/` must NEVER import from `Tabs/`.** One direction, always. A tab composes capabilities; a capability never reaches up into a tab.
- **A new capability is born flat in `Features/`**, even if only one tab presents it today (Journal → `Features/Journal`). Never nest it under the tab that happens to show it.
- `Features/` → `Features/` is allowed, but watch for cycles.
- Presenting a feature (`.vaylCover { FeatureView() }`) is composition, not ownership. Routing to a tab (`appState.selectedTab = .map`) or reading another feature's Store is not ownership either.
- A thin tab is correct. `Tabs/MapTab` holding only `MapView` + `MapStore` (lens state) + chrome is the target shape, not a smell.

### Strict Separation of Concerns
- Views read from Stores and call Store methods only
- Stores call Services only
- Services have no reference to Stores or Views
- Models have no reference to anything
- `director.advance()` is the ONLY way to change OB phase
- `tableFade` is written ONLY by `VaylDirector`
- No View writes to `VaylCardModel` directly

## Build Protocol — Non-Negotiable

**Discipline lives at plan-time, not execution-time.** A feature is not sliced into
sequential segments gated one-by-one; it is *planned as a whole suite up front*, then
executed as a **phase-gated pipeline** where subagents parallelize *within* a phase and the
human gates *between* phases. Segment-by-segment was training wheels — it kept Claude in the
loop because the plan couldn't be trusted to carry the feature. With a strong upfront plan,
that gate is pure latency. The rigor moves earlier, it does not disappear.

**The load-bearing rule: a weak plan makes parallel execution WORSE, not better.** Fan-out
amplifies whatever the plan got wrong instead of catching it mid-stream. So Phase 1–2 (below)
carry the weight. If the screens come out weak, the failure was upstream in planning, not in
the agents.

### The Pipeline

| Phase | Unit of work | Parallel? | Gate to advance (human-owned) |
|---|---|---|---|
| **1. Function-in-practice** | conversation (Claude + Bryan) | no | Bryan approves the mental model of how the feature behaves in real use |
| **2. Screen suite + edge cases + competitor scan** | screens mapped as a family; mockups to `docs/mockups/` | research fans out (WebSearch on how peer apps solve the moment) | Bryan approves the screen list, the flow, and the per-screen data contract |
| **3. Frontend** | ONE subagent per screen, built against **stubbed Stores/Services** | yes | build-clean + renders with stub data; Bryan sees the flow |
| **3.5 Reconciliation** | one reviewer agent diffs all screens vs the Screen Brief | no | no token/motion/grammar drift; no invented visual elements |
| **4. Backend** | per Store/Service, fills the same contract the frontend renders against | yes | routes + persists/reads correctly against real schema |
| **5. Verify** | build + unit tests (+ XcodeBuildMCP only if explicitly asked) | yes | green build, tests pass with exact counts reported |

### Rules that hold the pipeline together
- **Confirm before code.** Claude states what it is building and the authoritative reference
  (on-disk mockup path, DESIGN_DOC section) before writing anything. If Claude proposes work
  beyond the approved plan, stop it and redirect. Never invent a flow, screen, or visual
  element (glow, hairline, accent) not present in the reference.
- **The Screen Brief is the anti-drift anchor.** End of Phase 2, write ONE file holding the
  token/motion/presentation decisions plus each screen's data contract and definition-of-done.
  Every Phase 3 subagent reads ONLY its screen brief + the token contract — never the other
  screens' code. Clean context, single source of truth, no room to hallucinate a dialect of
  the design system.
- **Data-contract-first.** Frontend builds against stubbed Stores returning fake data (Bryan
  sees the whole flow immediately); backend fills the identical contract later without touching
  Views. Verify the contract against the **real Supabase schema** in Phase 2 so a stub never
  promises data the DB can't store. This is the rework-killer.
- **Reconciliation is mandatory after every parallel fan-out.** Parallel agents each drift a
  little from the token/motion contract; segments never had this because Bryan reconciled each
  step. Phase 3.5 makes the reconciler explicit and adversarial.
- **Never guess timing/feel.** Feel it first in an HTML/interactive reference (or in Swift on
  device for 3D/shader work), never a raw literal into Swift.

### Feel is still Bryan's, and it moves to a real gate
Parallel work batches feel-verification instead of checking it per-segment. That is fine only
if feel is its own owned pass: **Phase 3's gate is "renders correctly," NOT "feels right."**
Build-clean is never "done." Bryan confirms feel on device before Phase 4. Do not let
automation assert a feel verdict.

### Right-size the pipeline
The full 6-phase rail is for a feature suite. A single-view polish or a bugfix does not need
Phase 1–2 fan-out — run the relevant tail (build against the locked reference, verify) and
skip the ceremony. Match the process to the work; don't perform the pipeline on a one-liner.

### XcodeBuildMCP Usage Gatekeeping — READ THIS BEFORE REACHING FOR THE SIM

**XcodeBuildMCP is a last resort, not a first tool. Claude can almost always infer behavior
from code — do that first.** Driving the sim to "see" a change is NOT a substitute for reading
the code and reasoning about it, and it is not a default verification step. Aggressive,
unrequested sim-driving is a violation of this protocol, not diligence.

**The bar to touch XcodeBuildMCP — ALL must be true:**
1. Static reasoning has genuinely run out (you have read the code, the contracts, and the
   relevant mock/logs), AND
2. Either Bryan **explicitly asked in the current message** ("run this," "take a screenshot,"
   "drive the sim through X"), OR you are at **final build/test verification** (Phase 5), OR
   you are **3+ failed fix attempts deep** on the same bug with code review + logs exhausted.

**Forbidden (these are the patterns that have crept in — stop them):**
- Launching the sim after a routine edit to see if it "just works"
- Using it as the reflexive next step after reading or editing code
- Reaching for it before HTML mocks, logs, and static code review have been tried
- Inferring permission from a prior message ("you had me run it earlier, I'll run it again")
- Treating "I can see it" as more authoritative than "I reasoned about the code"

**Progression (in order, stop as soon as you have your answer):**
1. Read code + CLAUDE.md contracts and reason from them
2. Write/analyze an HTML mock or interactive reference (timing, layout, feel)
3. Static code review (types, logic, token usage, architecture)
4. `build_sim` / `test_sim` for a compile + test verdict (no UI driving)
5. Only if still unsure AND the bar above is met: request explicit approval to drive the sim

A build + test verdict is the ceiling Claude reaches on its own. UI driving, screenshots, and
snapshot_ui are opt-in only. When Bryan does ask for a sim run, report findings honestly
(screenshots, logs, anomalies) rather than asserting a visual/feel verdict from automation.

### Subagent Fan-Out at Scale — Don't Torch the Session Budget

Large batch jobs (analyze N files, transform M records, fan out reviewers) blow the session usage
limit when launched carelessly, and a mid-run limit-hit kills in-flight agents. These rules are
learned from a run that failed twice before finishing:

- **Throttle waves; never fan out everything at once.** Launch small waves (default 4–6 agents,
  fewer if Bryan says so), wait for the wave to finish, then launch the next. A single 30-agent
  burst is what trips the limit. Match wave size to the work's weight, not to how many items exist.
- **Resume from disk, never redo.** Each agent writes its result to its own output file; the
  orchestrator checks which outputs already exist and only launches the missing ones. A limit-hit
  or restart then costs nothing already done. Report progress from the output files on disk, not by
  reading agent transcripts (those overflow context).
- **Pre-chunk the data; forbid agents from touching the raw source.** Split the big input into
  small per-agent batch files up front. Tell each agent to read ONLY its batch file, never the
  original multi-hundred-MB dump, and never to write extraction/verification scripts. One agent
  re-reading a giant raw file is the single biggest token blowout.
- **Pretty-print batch files (multi-line JSON).** A batch written as one giant single-line array
  gets truncated on Read, the agent thinks data is missing, and it goes hunting in the raw source —
  the exact failure above. Multi-line JSON is immune.
- **Keep agent replies tiny.** Agents write output to disk and reply with only a count + validity
  confirmation + a sentence or two. Never have them echo the full payload back into the orchestrator.
- **Validate mechanically after aggregation.** Concatenate in batch order, then check count, schema,
  enum membership, and (for quoted data) exact-substring provenance with a script — don't eyeball it.
- **Workflow tool is opt-in.** Multi-agent orchestration via the Workflow tool requires Bryan's
  explicit ask ("ultracode", "use a workflow"). Absent that, use the Agent tool in throttled waves.

---

## HTML & Mockup Protocol

**Never use the Artifact tool for HTML mockups.** Write HTML files directly to disk instead.
Artifacts reduce functionality (authentication gates, inspection tools, copy accessibility).

- For design mockups, prototypes, or UI exploration: write `.html` files to `/docs/mockups/` or scratchpad
- HTML files can be opened locally, inspected via DevTools, iterated fast, and version-controlled
- Reference existing mockups in docs/mockups/ for feel/timing validation before Swift implementation

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
- **The Void Rule (heroes), 2026-07-17.** Two clauses, both mandatory. **(1) A hero never wears card chrome** — it floats on `AppColors.void` + `OnboardingAtmosphere`; `.vaylGlassCard()` / `.themedCard()` / `.learnCard()` are for secondary content only. Play's tab screen has zero card calls, Home has one (a popover), and that is the target shape. **(2) A hero sizes off `AppLayout.from(geo)`, never a constant** — a fixed hero height cannot breathe across devices and outlives whatever justified it (`mapPulseCardHeight = 218` was named for a card that never rendered and sized for a grid that had moved away; it survived a year because the rule was unwritten). If you are typing a literal for a hero's height, stop. Full rule + the tuning caveat for glowing heroes: DESIGN_DOC §5, `docs/design/2026-07-17-void-rule-and-map-hero-scale.md`.
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
- **No arithmetic on animation tokens.** `AppAnimation.ambientPulse / 1.5` (a 1.33s loop) is banned — it hides the real tempo and slips under the 2s floor. If you need a different duration, it is a new named token, not a division. (Grep guard: `AppAnimation\.\w+ *[*/]` should return only unit conversions and within-one-animation keyframe subdivisions.)

### Breathing tempo — two speeds, no third
- **Living surfaces** (auras, a heart, a real presence) breathe at `auraBreathe` (5.4s).
- **Inert chrome** (a waiting dot, a status pulse) pulses at `ambientPulse` (2s).
- There is no third ambient tempo. If a loop wants one, it is wrong — pick living or inert.

### Haptic scale — weight maps to consequence
`light` = select / navigate · `medium` = commit · `rigid` = two-device seal (airlock, sync lock-in) · `heavy` = safe-word only · `success` = terminal (a thing finished). Never reach past the consequence: a tab tap is `light`, not `medium`.

### Spectrum discipline — the full gradient is earned
- Full cyan→purple→magenta gradient only on **strokes**, **display text**, or a **hero element ≥24pt**. Below that it muddies — use a single accent.
- Links / tappable accent body text → `AppColors.textAccent`, never the gradient.
- Directional meaning: **cyan = Me / private**, **magenta = Us / shared**. Don't cross the wires.

---

## V1 Launch Scope — Dark Mode Only (Views), Token Infrastructure Ready

**V1 ships dark-only.** Post-launch light-mode work is separate. The split is precise:

### Dark-Only Enforcement (V1 Views)
Views must be dark-only, period. No mode-switching logic:
- **Forbidden in Views:** `@Environment(\.colorScheme)` checks, `preferredColorScheme()` modifiers, conditional branches on `.dark` / `.light`
- **Forbidden in Info.plist:** `UIUserInterfaceStyle = Light`, appearance overrides, light-mode accent definitions
- **Forbidden assets:** app icons with light variants, image sets with both dark/light slices

### Token Layer — Light-Mode Infrastructure REQUIRED
Token files (`AppColors.swift`, etc.) **must** include light-mode color definitions even though V1 Views ignore them. Why: post-launch light-mode work only needs to wire up Views; the color palette is already there. This trades a small upfront cost (one round of token design) for dramatically cheaper post-launch implementation.

Token example:
```swift
// AppColors.swift — both defined from day one, Views only use .dark variants in V1
static let void = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "000000"))
// Views: AppColors.void (reads .dark automatically in V1)
// Post-launch: Views add mode check, both variants used
```

### Rationale
- **Simplifies V1 ship:** no mode-switching logic, consistent dark aesthetic, faster review
- **Enables fast post-launch:** the palette is done; implementation is just wiring Views to use both variants
- **Honest architecture:** tokens are infrastructure; Views are behavior. Separate them clearly.

The dark-only constraint keeps V1 coherent and ship-focused. The token infrastructure keeps post-launch cheap.

---

## Violation Checklist
- [ ] No raw colors, fonts, spacing, radius, or opacity in Views
- [ ] No raw animation curves/durations anywhere (Views, Stores, sequencers) — AppAnimation tokens only; screen/content transitions use a motion staple (`.vaylDepth` / `arrive` / tap contract), never ad hoc slides (spec: docs/superpowers/specs/2026-07-03-motion-system-design.md)
- [ ] No UIScreen.main or UIApplication.shared.keyWindow (iOS 26 banned)
- [ ] No UIWebView or NSURLConnection (iOS 26 hard errors)
- [ ] No UNAuthorizationOptionAlert, use .Banner variant
- [ ] No UIScreen.main.bounds, use AppLayout.from(geo)
- [ ] Void Rule: no card chrome on a hero; no constant sizing a hero (derive from `AppLayout.from(geo)`)
- [ ] Tab content adds NO bottom clearance (AppShell `.safeAreaInset` owns it); covers/sheets use `.bottomClearance` / `.stickyBottomCTA`
- [ ] No hardcoded hardware padding (`.padding(.top, 60)` / `.padding(.bottom, 34/100)`); use `.topClearance` / safe-area insets
- [ ] No Service/network calls in Views
- [ ] No View writes to VaylCardModel
- [ ] No capability nested under a tab; new capabilities born flat in `Features/`
- [ ] No `Features/` file importing from `Tabs/` (one direction only)
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
