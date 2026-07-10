# Vayl UI Design Review — 2026-07-08

> **Orchestration note (2026-07-10, autonomous run):** The original
> `2026-07-08-ui-design-review.md` prompt file lives in the untracked `docs/` folder on the
> author's local machine and is not present in this fresh clone (docs/ was removed from git on
> 2026-07-07, commit `72dafa3`), nor recoverable from git history or Notion. Per the "do not
> stop for input" directive, this run reconstructs and executes the review from the detailed
> execution plan supplied with the scheduled task (Phases 1–6 + 8, Subagents A–G, verification
> gates). `docs/mockups/` and `docs/prototypes/` are likewise absent from this clone; the review
> is grounded in the codebase and CLAUDE.md contracts alone. All findings below are appended
> phase by phase, each followed by an orchestrator verification log entry.

---

# PASS 1 — FULL DESIGN REVIEW

# Subagent A — Orient + Inventory (Phases 1 & 2)

## Phase 1 — Orientation

### Token system summary (per file)

All token files live in `/home/user/Vayl/Vayl/App/Theme/`. Fifteen files exist — the eight named in CLAUDE.md plus seven more (AppMotion, AppSafeArea, AppTheme, ThemeManager, ThemeModifiers, VaylPrimitives, AppRootView).

| File | What it provides | Key token names |
|---|---|---|
| **AppColors.swift** (812 ln) | Tier-2 semantic colors; every token maps to `VaylPrimitives`; `Color.dynamic(light:dark:)` is **hard-locked to the dark value** (dark-only Act 1, light params retained for future Dawn mode). | Backgrounds (`pageBackground`, `cardBackground/-Raised`, `modalBackground`, `inputBackground`, `widgetBackground`), OB-exclusive (`void`, `cardBg`, `tableFelt*`, `tableAmberPool`), spectrum anchors (`spectrumCyan/Purple/Magenta/Bridge`), text hierarchy (`textPrimary/Body/Secondary/Tertiary/Hint/Muted/Bright/Accent/CardLabel/SectionLabel`), accents (`accentPrimary/Secondary/Tertiary`), borders (`borderSubtle/Default/Active/Accent/Purple`), feedback (`destructive`, `success`), gold safety (`safetyAccent`, `safetyAtmosphere` ≤8%), shadows/scrims (`shadowDeep`, `scrimHeavy`, `shadowMagenta/Purple/Gold`), glass (`glassFrostCard/Pill/PillSelected/CTA`, `glassSurface`, `whisperFill`), gradients (`spectrumBorder`, `spectrumText`; private `gradientStop1-3`), Pulse tiers + aura ramps (`pulseTier*`, `auraCore/Light/Deep/Glow` × cyan/indigo/magenta/rose/neutral/uncharted). |
| **AppFonts.swift** (243 ln) | ClashDisplay display set + Switzer body set, all via `Font.custom(_:size:relativeTo:)` (Dynamic Type–anchored); `display(_:weight:relativeTo:)` / `body(...)` constructors; Menlo for the founder letter. | `heroTitle`(42), `displayHero`(64), `statHero(size)`, `scoreDisplay`(32), `screenTitle`(24), `obPhaseTitle`(32), `cardTitle`(22), `cardTitleCompact`(16), `pulseWidgetTitle`(28), `sectionHeading`(20), `prompt`/`promptHighlight`(17), `ctaLabel`(17), `bodyText`(16), `bodyMedium`(15), `buttonLabel`(14), `caption`(13), `overline`(11), `tabLabel`/`label`/`badge`/`meta`(10), `founderLetter(_:)`. |
| **AppSpacing.swift** (52 ln) | Semantic spacing scale on an 8pt-ish grid; each token documents allowed/forbidden uses. | `xxs`(2), `xs`(4), `sm`(8), `md`(16), `lg`(24 — screen-edge margin), `xl`(32 — above sticky CTAs), `xxl`(48 — hero breathing). |
| **AppRadius.swift** (92 ln) | Corner radii on a 4pt grid, role-scoped. | `micro`(2), `sm`(8 chips), `md`(12 inputs), `lg`(16 cards/CTAs), `container`(20 OB cards/home widgets), `xl`(24 modals), `sheet`(57 native-style sheet corners), `pill`(∞); OB-only: `obCard`(14), `cornerCard`(4), `foilEdge`(16). |
| **AppLayout.swift** (472 ln) | Geometry resolved from `GeometryProxy` via `AppLayout.from(geo)` (UIScreen.main banned); device classes (`isSmallDevice` ≤375, `isLargeDevice` ≥428); derived widths (`cardWidth`, `fullWidth`, `contentMaxWidth` ≤460); screen-building constants (`screenHPad` 18, `screenVPad` 20, `cardHPad/VPad`, `ctaHeight` 52, `pillHeight` 32); Map (`mapPulseCardHeight` 218, `mapMeAuraSize`); OB card geometry (`obCardWidth` = min(0.72w, 320), `obCardHeight` = ×1.5, table/fan/session variants, landing slots, deal-point/table fractions, StatPhase hero sizing). | `from(geo)`, `obCardWidth/Height(in:)`, `sessionCardWidth/Height(in:)`, `obCardLandingSlots`, `tableHorizonYFrac`, `statHeroSize(...)`. |
| **AppAnimation.swift** (1176 ln) | Every animation token: reactive (`fast` .15s, `standard` .3s, `slow` .5s, `spring` .5/.85, `enter` .4, `exit` .2), `cinematic` 1.2s, ambient raw durations (`ambientPulse` 2s, `ambientDrift` 4s, `ambientShimmer` 1.2s), border-effect suite (`borderFill/GlowIn/GlowOut`, hairlines), splash sequence tokens, OB card-physics suite (`cardSlide/Settle/Center/Pocket/Flip/Lift`, `deckFan/Weave`, forge-ceremony tokens), Desire Map suite (`desireRevealBloom`, `desireDepthEnter/Exit`, ceremony budgets), Pulse aura (`auraBreathe` 5.4s, `auraCausticDrift` 7s, `auraGlassSweep` 8.5s), tab nav (`tabSwitch` .25s, `orbGlide` .38s), **motion system staples** (`depthQuiet` .26s + scale pairs, `arrive` .5s, `arriveCover` .55s, `cascadeRow/Stagger/Cap/Rise`, refusal, `commitDismissLag`), quiet-tier hard caps (`quietMaxScaleDelta` 0.02, `quietMaxTravel` 16pt). Plus `AppAnimation.lowPower` / `ambientMotionDisabled` gates, `Animation.reduceMotionSafe`, and `View.ambientAnimation(_:value:)`. |
| **AppGlows.swift** (414 ln) | Semantic emissive-glow tokens (multi-layer `GlowLayer` structs) + applier modifiers; elevation shadows explicitly excluded. | `spectrumBorder` (3-layer cyan/purple/magenta + stroke weights), `cornerDeck`, `cardBreathe`, `accentFocus`, `liftCopy`, `safety`, `compassStarGlow`, `tableRimInnerGlow`; modifiers `.spectrumBorderGlow(intensity:)`, `.cornerDeckGlow`, `.accentFocusGlow`, `.safetyGlow`, `.liftCopyGlow`. |
| **AppElevation.swift** (281 ln) | Page → Card → Modal shadow hierarchy, always tinted (never grey); OB card-physics shadow `cardShadow(elevation:)` lerping 0→1 lift. | `card.midnightShadow/Glow`, `modal.midnightShadow/Glow`, `citationPanel`, `.cardElevation()`, `.modalElevation()`, `cardShadow(elevation:)`. |
| **AppMotion.swift** (135 ln) | Thin stateless *appliers* for the motion staples (values live in AppAnimation), Reduce Motion baked in. | `AnyTransition.vaylDepth(.loud/.quiet)`, `.vaylCascade(index:shown:)`, `.vaylRefusal(trigger:)`, `VaylMotionRegister`. |
| **AppSafeArea.swift** (166 ln) | Safe-area helpers replacing hardcoded hardware paddings. | `.stickyBottomCTA{}`, `.bottomContentInset(_:)`, `.bottomClearance(_:includesTabBar:)`, `.topClearance(_:padding:)`, `homeIndicatorInset`, `topHardwareInset`, `@Environment(\.realSafeArea)`. |
| **AppTheme.swift** (39 ln) | `ThemeMode` enum (system/light/dark) retained only for persistence/migration; legacy AppPalette removed. |
| **ThemeManager.swift** (46 ln) | `@Observable` theme holder; `preferredColorScheme` **hard-returns `.dark`** (Act 1); migrates legacy "amoled"/"light" stored values to "dark". |
| **ThemeModifiers.swift** (112 ln) | `.themedRoot()` (applies color scheme), `.themedCard(selected:)` (opaque card chrome), `.vaylGlassCard(accent:radius:)` (canonical Map-tab translucent glass surface), `.if(condition)`. |
| **VaylPrimitives.swift** (173 ln) | Tier-1 raw hex UIColors (ink*, cyan/purple/magenta families, wine, gold, felt, frost, tints). Only referenced by AppColors. |
| **AppRootView.swift** (119 ln) | Not tokens — the top-level routing gate (splash → OB → auth → shell). Included here because it lives in Theme/. |

### Contract rubric (checklist)

The binding review rubric distilled from CLAUDE.md:

**Design tokens**
- [ ] Zero raw values in Views: no `.red`/`Color(hex:)`/`.font(.title)`/numeric spacing, radius, opacity, or animation-duration literals
- [ ] Read the relevant token file before using a token; never invent a token
- [ ] OB card sizing only via `AppLayout.obCardWidth/obCardHeight` (min(0.72w, 320) × 1.5)
- [ ] Layout from geometry only: `AppLayout.from(geo)`; `UIScreen.main.bounds` banned
- [ ] Every screen background = `AppColors.void` + `OnboardingAtmosphere` in a ZStack, both `.ignoresSafeArea()`
- [ ] Every card/surface uses `.themedCard()` or `.vaylGlassCard()` — never hand-rolled chrome
- [ ] Every tappable: press scale (0.96) + `.sensoryFeedback` haptic + action (all three)
- [ ] OB card faces: 1D outline only, spectrum gradient strokes, two render passes (glow + crisp), geometry proportional to cardWidth/Height, `.drawingGroup()` on VaylCardFace
- [ ] Empty state on every data screen: icon (`textTertiary`) + headline (`cardTitle`) + sub-label (`caption`) + optional CTA
- [ ] Glows via `AppGlows` modifiers, never raw `.shadow()`; elevation via `.cardElevation()`/`.modalElevation()`

**Animation feel**
- [ ] No raw curves/durations anywhere (Views, Stores, sequencers) — AppAnimation tokens only
- [ ] Screen/content transitions use a motion staple (`.vaylDepth`, `arrive`/`arriveCover`, tap contract) — never ad-hoc slides
- [ ] One animation per property per view; no repeating loop under 2s (exception: `ambientShimmer` 1.2s); no springs on ambient/`repeatForever` motion
- [ ] Glow breathing opacity 0.3→0.7 only, never 0→1; springs `dampingFraction ≥ 0.75` outside OB canvas
- [ ] Every loop via `.ambientAnimation(_:value:)`; ambient removed entirely under Reduce Motion AND Low Power Mode (`reduceMotion || AppAnimation.lowPower`); reactive/one-shot never LPM-gated
- [ ] Continuous `TimelineView(.animation)` needs a `minimumInterval` frame-rate cap
- [ ] Quiet-register ceilings: scale Δ ≤ 0.02, travel ≤ 16pt, duration ≤ 0.55s; ceremony motion banned outside OB canvas / `.vaylCover` contents

**Safe area & tab bar**
- [ ] Tab bar owns its clearance via AppShell's `.safeAreaInset(edge: .bottom)`; tab content adds NO bottom clearance
- [ ] Covers/sheets DO own bottom clearance: `.stickyBottomCTA` or `.bottomClearance(layout)`
- [ ] Top chrome via `.topClearance(layout)`; never `.padding(.top, 60)` / `.padding(.bottom, 34/100)` as hardware proxies
- [ ] Backgrounds bleed (`.ignoresSafeArea()`), content/chrome stay inside the safe area

**Presentation grammar**
- [ ] All modals via `.vaylCover` / `.vaylSheet`, never raw `.fullScreenCover`/`.sheet` in feature views
- [ ] Pattern matches mental state: inline expand (discovering) / push (real hierarchy: Learn→research→finding) / `.vaylSheet` (preview or discrete task; ALL Settings sub-screens are sheets) / `.vaylCover` (protected immersive: Card Session, Desire rater, Pulse check-in, OB)
- [ ] Card Session is ALWAYS a `.vaylCover` with dismiss-guard + confirm-on-exit; never a sheet

**Architecture & product (design-adjacent)**
- [ ] Views never call Services/network; no View writes `VaylCardModel`; OB phase changes only via `director.advance()`; `tableFade` written only by `VaylDirector`
- [ ] No iOS 26 banned APIs (`UIScreen.main`, `keyWindow`, `UNAuthorizationOptionAlert`, UIWebView, NSURLConnection)
- [ ] Right-sized features; nothing assuming Vayl is the center of the user's life; discovery tools name what the user said, never infer

**V1 dark-mode only**
- [ ] No `@Environment(\.colorScheme)` checks in Views; no `preferredColorScheme()` in feature views; no light-mode assets/conditional colors. (Note: `AppColors.dynamic` retains ignored `light:` params by design; `AppElevation`'s modifiers and `PairingInviteView` DO read `colorScheme` — flag for the compliance pass.)

### Sources note (mockups/prototypes unavailable)

**`docs/mockups/` and `docs/prototypes/` do NOT exist in this clone** (verified: `ls` fails on both; only `docs/superpowers/` exists). Many source comments cite prototypes (`home-final.html`, `map-pulse-final.html`, `pulse-aura-glass.html`, `couple-session-hero-v2.html`, `settings-v2.html`, motion-system spec, etc.) as feel references — none can be consulted here. **Everything in this review is grounded in code only**; "mockup parity" claims in comments are unverifiable in this clone and should be treated as intent, not evidence.

---

## Phase 2 — Surface & State Inventory

### Surface list (numbered, with primary file per surface)

Root routing (`Vayl/App/Theme/AppRootView.swift`): Splash → (OB if incomplete) → (Sign-in if unauthenticated) → AppShell. Four tabs confirmed in `Vayl/Core/Models/Enums/AppTab.swift` (home, play, map, learn); tab shell in `Vayl/App/AppShell.swift` with `RacetrackTabBar` as a bottom `safeAreaInset`; Settings is a `.vaylCover` OVER the shell (AppShell.swift:39).

1. **Splash** — `Vayl/Design/Brand/SplashScreenView.swift` (once per cold launch; suppressed on foreground resume, AppRootView.swift:111-117)
2. **Sign In** — `Vayl/Features/Auth/Views/SignInView.swift`
3. **Onboarding canvas** (11 phases, `OBPhase` in `Vayl/Core/Models/Enums/AppOBEnums.swift:24-36`) — `Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift`; phases: Stat, Demo, Name, ModeSelect, Gender, ExperienceLevel, Context, Curiosity, Confirmation (+ `CredentialEditorSheet`), BuildDeck, FounderLetter — all in `Vayl/Features/Onboarding/Phases/`
4. **Home tab** — `Vayl/Features/Home/Views/HomeRouterView.swift` → `HomeDashboardView.swift` (greeting + partner chip, Getting Started entry card + Path overlay, Deck module, Pulse rail, Lexicon, reflection banner, pending-session banner, MapChartedMoment, PulseInfoSheet, SessionSettingsSheet)
5. **Play tab (Cards / deck grid)** — `Vayl/Features/Play/PlayView.swift` (masthead, hero, `DeckWallView`, `DeckDetailView` float-in-space inspect, `DeckBeginCeremony`, `PlayEmptyState`, open-error banner, `PendingSessionBanner`, `SessionBuilderView` sheet, `PaywallSheet`, session cover)
6. **Map tab** — `Vayl/Features/Map/MapView.swift` (name-toggle masthead = Me/Us switch, Us-reveal ceremony, Me layer: `MapPulseHero` + `MapRecord`; Us layer: `MapUsLayer` + `MapUsPulseCard` + `VaultDoorCard`)
7. **Vault sheet** — `Vayl/Features/Map/Vault/VaultSheet.swift` (Desire Map / Agreements / Log segments; `EventEntryEditor`, `DiscussionCardView`)
8. **Pulse check-in cover** — `Vayl/Features/Pulse/PulseCheckInView.swift`
9. **Pulse history / full pillar sheet** — `Vayl/Features/Pulse/PulseFullView.swift` (+ `PulseHistoryGrid`); **Map field cover** — `MapFieldSheet` inside `Vayl/Features/Map/Components/MapPulseHero.swift:104`
10. **Learn tab** — `Vayl/Features/Learn/Views/LearnView.swift` (QuizCarouselSection, ResearchSection, ContentHubSection; `ResearchDatabaseView` cover; `FindingDetailView` sheet; `ResourcesOverlayView` sheet)
11. **Card Session cover** — `Vayl/Features/Sessions/CardSessionContainerView.swift` (phase machine: `SessionLobbyView` → `AirlockView` → transition → `SessionPlayerView` → `SessionCloseView` / `SafeWordCloseView` → done; `SessionSettingsSheet`, care sheet, how-it-works sheet)
12. **Session Builder sheet** — `Vayl/Features/Sessions/Builder/SessionBuilderView.swift`
13. **Desire Map rater cover** — `Vayl/Features/Desire Map/Views/Components/DesireMapView.swift`
14. **Desire Reveal cover** — `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift` (+ `DesireStarDetailSheet`, `DesireMapListSheet`, inner paywall host)
15. **Settings cover** — `Vayl/Features/Settings/SettingsView.swift` + six sub-sheets: `SettingsIdentityView` ("You"), `SettingsPrivacyView`, `SettingsNotificationsView`, `SettingsAppearanceView`, `SettingsPartnerView`, `SettingsCompositionView`
16. **Pairing** — `Vayl/Features/Pairing/PairingInviteView.swift`, `PairingJoinView.swift`, `PairingSettingsView.swift` (sheets from Home, Settings)
17. **Paywall** — `Vayl/Features/Monetization/Views/PaywallSheet.swift` (three doors: reveal / settings / playDeck)
18. **Getting Started Path overlay** — `Vayl/Features/Home/Views/GettingStartedPathView.swift` (blur-over-Home overlay, not a cover)
19. **Map-charted moment** — `Vayl/Features/Home/Views/MapChartedMoment.swift` (one-shot celebration overlay)
20. **Orphaned / not-yet-wired surfaces** — `Vayl/Features/Map/MeCardSheet.swift`, `Vayl/Features/Map/Components/MeCardCompact.swift`, `Vayl/Features/Map/PrismView.swift`: no call sites outside their own files/previews found (Me Card "Seg 3" appears unlanded). Flag for the coherence pass.

### State inventory table

| Surface | State | Exists in code? (file:line or MISSING) | Notes |
|---|---|---|---|
| Splash | Full sequence (void→slit→ignition→zoom→tear) | Design/Brand/SplashScreenView.swift; timings AppAnimation.swift:258-334 | One-shot; RM fallback = crossfade |
| Splash | Resume-from-background suppression | App/Theme/AppRootView.swift:111-117 | splashDone forced on background |
| Sign In | Idle (wordmark + Apple CTA) | Features/Auth/Views/SignInView.swift:18-79 | |
| Sign In | Loading | SignInView.swift:78-88 (`authService.isLoading` disable/opacity/spinner) | |
| Sign In | Error | SignInView.swift:90-91 (`authService.error` text) | Inline text, no retry affordance beyond re-tap |
| Sign In | Legal doc sheet | SignInView.swift:14 (`legalDoc`) | SafariView |
| Onboarding (all phases) | Phase progression | Core/Models/Enums/AppOBEnums.swift:24-36; advance only via VaylDirector.advance (Canvas/VaylDirector.swift:81) | 11 phases: stat→demo→name→modeSelect→gender→experienceLevel→context→curiosity→confirmation→buildDeck→founderLetter |
| OB · StatPhase | Populated (hero + citation panel expand/collapse) | Phases/StatPhase.swift (citationToggle tokens AppAnimation.swift:100-112) | |
| OB · StatPhase | Empty/unavailable stat | Phases/StatPhase.swift:117, 266-271 (`emptyStateView`, "Stat unavailable") | Rare OB empty state; note raw `.system(size: 40)` with "token pending" comment |
| OB · NamePhase | Typing / greeting / swipe-submit / lift sequence | Phases/NamePhase.swift + Canvas/Sequencers/NameSequencer.swift:15 (`CardDealPhase`) | Empty-name guarded (`seq.name.isEmpty` tint, NamePhase.swift:196) |
| OB · Demo/Gender/Curiosity/ExperienceLevel/ModeSelect/Context | Interaction state machines | Sequencers/DemoSequencer.swift:14 (`DemoStage`); ExperienceLevelPhase.swift:55+ (monte `.lifted/.faceUp`); ModeSelectPhase.swift:220-233 (`.lifted/.exiting/.done`) | All per-phase card physics states |
| OB · Confirmation | Review fan + edit credential | Phases/ConfirmationPhase.swift:177 → `CredentialEditorSheet.swift` | |
| OB · BuildDeck / FounderLetter | Forge ceremony beats; letter rise + signature | Phases/BuildDeckPhase.swift; FounderLetterPhase.swift; tokens AppAnimation.swift:1016-1105 | Terminal commit → `finishOnboarding` |
| OB (whole flow) | Error / interruption / resume-mid-OB | **MISSING in code** — no persisted mid-OB resume; killing the app restarts OB from stat | Local-only flow, no network, so no error surface; still zero resume affordance |
| Tab shell | Tab switching (4 tabs) | App/AppShell.swift:20-34, 92-96; RacetrackTabBar.swift | Drift transition; orbGlide |
| Tab shell | Deck-engaged recede (bar dims + hit-testing off) | AppShell.swift:61-64 | |
| Home | Loading deck | Home/Views/HomeRouterView.swift:214-221 (ProgressView + "Loading your deck...") | |
| Home | Deck load error + retry | HomeRouterView.swift:192-213 | Icon+title+message+Try Again; uses `.borderedProminent` (off-pattern, flag) |
| Home | Populated dashboard | HomeRouterView.swift:223-262 → HomeDashboardView.swift | |
| Home | Routing states | Home/Models/HomeModels.swift:147-151 (`HomeState`: gated [vestigial], dashboard, soloUnpaired) | All three currently render the dashboard |
| Home · partner chip | none / invitePending / active / multipleActive / nudge | Home/Components/PartnerChip.swift:17,63,109,154,166 | Partner-not-paired = `.none`/invite CTA |
| Home · Desire Map progression | hidden/gated/yourTurn/youDone/waiting/bothReady/freeRevealSeen/matchReady/redoInProgress/revealed | Core/Models/Enums/AppDesireEnums.swift:14-24 | Surfaced via Getting Started + chip, not routing |
| Home · Getting Started | done/active/upcoming/locked per step (profile, mapDesires, invitePartner, seeReveal) | Home/Models/GettingStarted.swift:11-23, resolve():60+ | Entry card HomeDashboardView.swift:234; Path overlay HomeRouterView.swift:145-162 |
| Home · Pulse rail | Dormant (no check-in today: cycling aura + "How's your capacity?") vs active | Home/Components/HomePulseRail.swift:5,60 | Same dormant grammar reused on Map |
| Home · Reflection card | hidden / pendingYours / waitingOnPartner / bothReflected / summary | HomeModels.swift:11-30; ReflectionBannerView.swift (+ full-pill sheet :218) | |
| Home · Pending session (joiner) banner | Partner opened a lobby | HomeDashboardView.swift:631-651 + Sessions/Components/PendingSessionBanner.swift; accept → joiner cover :456-465 | |
| Home · one-shot map-charted moment | showCompletionBeat over blurred dashboard | HomeRouterView.swift:141,165-172; MapChartedMoment.swift | Auto-advance tokens AppAnimation.swift:804-818 |
| Home · covers/sheets | Rater cover :83, Reveal cover :101, pairing invite/join sheets :112/:118 (HomeRouterView); pulse check-in cover, PulseInfoSheet, SessionSettingsSheet (HomeDashboardView.swift:491-520) | | |
| Play | Loading (first fetch) | **Thin** — PlayView.swift:38 renders nothing until store built; no explicit spinner state | Store builds synchronously in `.task`; brief blank void |
| Play | Empty catalog OR load error | PlayView.swift:69-73 → PlayEmptyState.swift (message = `store.loadError`, retry); PlayStore.swift:23,102-105,201-205 | One shared empty/error surface |
| Play | Populated (hero + wall) | PlayView.swift:75-90 | Scroll-linked hero collapse; RM pins to 0 |
| Play | Deck inspect (float detail) | Play/Components/DeckDetailView.swift (locked blur previews :230-238, locked CTA :248-249) | Free-tier gate visible per deck |
| Play | Locked deck → paywall | PlayView.swift:165-176 (`paywallDeck` → PaywallSheet .playDeck) | |
| Play | Begin ceremony | PlayView.swift:95-99 → DeckBeginCeremony.swift | |
| Play | Session open FAILED (retryable banner) | PlayView.swift:101-111, 180-214; PlayStore.swift:44-46, 266-311 (`failedOpen`, `retryOpen`) | Plan kept; "Try again" re-runs |
| Play | Joiner pending banner | PlayView.swift:114-128 | |
| Play | Builder sheet / session cover | PlayView.swift:139-163 | |
| Session Builder | Populated | Sessions/Builder/SessionBuilderView.swift:30+ | |
| Session Builder | Empty deck ("Nothing to shape") | SessionBuilderView.swift:36, 283-300 | Icon+title+copy+Back CTA |
| Card Session cover | Phase machine: airlock → transition → session → close / safeClose → done | Sessions/CoupleSessionStore.swift:35; CardSessionContainerView.swift:82-110 | Cover is confirm-guarded (`.vaylCover` default) |
| Session · Lobby | Initiator waiting vs joiner "you're in the room" | Sessions/SessionLobbyView.swift:38-42 | |
| Session · Lobby | Failed handshake reason | SessionLobbyView.swift:44-48 (`case .failed(let reason)`) | Airlock states AirlockStore.swift:111-118 (waitingForPartner/bothPresent/consented/activating/active/failed) |
| Session · Airlock | Capacity mirror incl. partner-not-checked-in | AirlockView.swift:46-53 (`partnerNotCheckedIn`); CoupleCapacityStore.swift:26 | |
| Session · Airlock | Consent failed / waiting pulse / how-it-works sheet | AirlockView.swift:30-34, 78 | |
| Session · Airlock | Realtime → poll transport fallback | AirlockStore.swift:129-136 | Degraded-connectivity state |
| Session · Player | In-progress (hold-to-deal, turn tint, care sheet, idle dim) | SessionPlayerView.swift:23-50, 118 | Sensitive cards screenshot-protected :46 |
| Session · Reveal mechanics | composing/sealedMine/bothSealed/countdown/revealed | Sessions/RevealEngine.swift:53-59 | Two-device seal-and-reveal |
| Session · Reconnect after kill | Active/paused row skips airlock, rebuilds player | CardSessionContainerView.swift:12-14, 47-61 (`resumeIfNeeded`) | |
| Session · Abandon before active | onDisappear abandons zombie lobby | CardSessionContainerView.swift:63-73 | |
| Session · Close + reflection | Landing → auto-raised reflection sheet (swipe-down = skip) | SessionCloseView.swift:38-50 | |
| Session · Safe-word close | Neutral landing, both devices | SafeWordCloseView.swift (whole file) | No reflection, no stats — by design |
| Session · mid-session network loss (in player) | **Partially MISSING** — reconnect path exists, but no in-player "connection lost" UI state found | SessionSyncCoordinator.swift handles row sync; no visible degraded-state chrome in SessionPlayerView | Flag for gap audit |
| Map | Me layer (default) | MapView.swift:262-279 | |
| Map | Us layer (paired) / lens gate when unpaired | MapView.swift:264-266 (`hasUs` else meLayer), `enforceLensGate` | Partner-not-paired: Us lens unreachable |
| Map | Us first-reveal ceremony (stages 0-3) | MapView.swift:36-70 (revealStage; RM branch) | One-shot, marked before playing |
| Map | Partner name not yet loaded | MapView.swift:231 (name toggle hides partner segment) | Falls back to solo name |
| Map · Pulse hero | Never checked in (empty: cycling aura + "How's your capacity?") | Map/Components/MapPulseHero.swift:93, 156-179 | Mirrors Home dormant grammar |
| Map · Pulse hero | Has history: current space + stale/quiet dimming + weather line | MapPulseHero.swift:30-92 (staleOpacity :50, `canCheckInToday` :89) | Check-in vs Edit check-in pill :190 |
| Map · Pulse hero | Field map cover | MapPulseHero.swift:104-112 (`MapFieldSheet`, stale flags passed) | |
| Map · Record | Empty (no sessions) | Map/Components/MapRecord.swift:25 (`MapEmptyState`) | Shared MapEmptyState in MapPrimitives.swift:43 |
| Map · Us orb | wholeUnwritten / split(mine, partner: unwritten·current·quiet) | Pulse/Models/UsOrbState.swift:11-21 | Partner-never-checked-in covered |
| Vault | Desire segment: empty, revealed align, locked-more row (paywall), consent placeholder | Vault/Components/VaultDesireSection.swift:42, 85, 144-150, 176 | 3 MapEmptyState variants |
| Vault | Agreements: empty | VaultAgreementsSection.swift:119 | |
| Vault | Log: empty | VaultLogSection.swift:23 | Editor: EventEntryEditor.swift (VaultSheet.swift:64) |
| Vault | Per-segment lazy load | VaultSheet.swift:54-63 (`.task(id: store.segment)`) | No visible loading spinner per segment — **loading state MISSING in UI** |
| Pulse check-in cover | Q1-Q5 progression, revisit-behind-only step row | PulseCheckInView.swift:19-35 (`currentQ`, `answers`) | |
| Pulse check-in | Revealed (space named) | PulseCheckInView.swift:33, 65-71 | |
| Pulse check-in | Uncharted resolution (contradictory answers) | PulseCheckInView.swift:37-39 (unchartedFired/dissolve/drift); tokens AppAnimation.swift:843-853 | |
| Pulse full view | Me grid (last 30) / Us paired grid | PulseFullView.swift:37-45 | Lens writes back to shared MapStore.layer |
| Pulse full view | Partner hasn't checked in | PulseFullView.swift:216, 228, 275 ("hasn't checked in", compare prompt) | |
| Pulse full view | Never-checked-in self (fully empty history) | PulseHistoryGrid.swift:100-118 handles missing names; explicit self-empty grid state **not confirmed — verify in Phase-3 pass** | Default preview data injected (PulseFullView.swift:20 `myEntries = PulseEntry.previews` as default!) — flag |
| Learn | Populated (quizzes, findings, hub) | LearnView.swift:19-53 | Content from bundled JSON + server override (LearnStore.swift:28-46) |
| Learn | Load error | **MISSING in UI** — LearnStore.swift:21,46 sets `loadError`, but no Learn view reads it (grep: zero render sites) | Silent empty sections on corrupt bundle |
| Learn | Quiz tap → quiz flow | **MISSING** — QuizCarouselSection.swift:10 `onSelect` defaults to no-op and LearnView.swift:26 passes no handler; no quiz-runner view exists | "Take the quiz" CTA is dead |
| Learn · Research database | Populated list; filter/sort chips | ResearchDatabaseView.swift:4-5 — chips are **VISUAL ONLY**, filtering engine not implemented | Empty-results state N/A yet (MISSING once filters go live) |
| Learn · Finding detail / Resources overlay | Populated sheets | FindingDetailView.swift; ResourcesOverlayView.swift (LearnView.swift:45-52) | |
| Desire Map rater | start / rating / charted / mirror / ready | DesireMapView.swift:29 (`RaterPhase`), routing :114-140 | Resume-mid-rating :84-92 (`firstUnratedIndex`) |
| Desire Map rater | Load error | DesireMapView.swift:116-117, 638 (emptyState(error)); DesireMapStore.swift:35 | |
| Desire Map rater | Empty item set | DesireMapView.swift:118-119 ("No desire items to show.") | |
| Desire Map rater | Solo wait (mirror) / partner-finished (ready bar) | DesireMapView.swift:13-14, 29 | Partner-not-paired reachable (head-start hook, HomeRouterView.swift:40) |
| Desire Reveal | loading / ready / empty (no positive matches) / failed | DesireRevealStore.swift:30-35; DesireRevealView.swift:74-93 (loadingView, two emptyState variants) | |
| Desire Reveal | Beat ceremony: idle → beat1 (free star) → beat2 (locked teasers) → beat3 (paywall) → revealed | DesireRevealStore.swift:51-57; paywall only on explicit tap :44-49 | Core couples skip to revealed |
| Desire Reveal | Star detail / full-map / paywall inner sheets | DesireRevealView.swift:50-53, 63-65 (custom sheet host, deliberately not .vaylSheet) | |
| Paywall | Idle / purchasing / restoring / restore-failed alert / details pop-out / legal sheet | PaywallSheet.swift:37-42, 79-97 | Price falls back to catalog "$24.99" :61 |
| Paywall | Post-purchase unlocked | onUnlocked callbacks (PlayView.swift:174; MapView.swift:149-154) | |
| Settings root | Populated (You/Partner/App/Account/About/membership) | SettingsView.swift:43-57 | Cover, no NavigationStack — every sub-screen a sheet :74-99 ✓ contract |
| Settings | Account phases: idle / signingOut / deleting / unlinking / error | Store/SettingsStore.swift:26-32; error alert SettingsView.swift:124-134 | |
| Settings | Destructive confirms (unlink / sign out / delete) | SettingsView.swift:100-123 | |
| Settings · Appearance | Dark-only fixed "Midnight" row | SettingsAppearanceView.swift:17-30 | Placeholder until light mode |
| Settings · Partner | Unpaired (invite/join sheets) vs linked | SettingsPartnerView.swift:32, 41 | |
| Pairing invite | generating / waitingForPartner(code) / linked / error | PairingStore.swift:26-33 | |
| Pairing invite | Code expired → regenerate prompt | PairingStore.swift:69-72 (`codeExpired`) | |
| Pairing invite | Aged invite copy (≥3 days) | PairingInviteView.swift:60-70 (static caption, no live countdown — deliberate) | ⚠️ reads `colorScheme` :31-32 (dark-only violation, flag) |
| Pairing join | idle / joining / linked / error; empty-code disabled affordance | PairingJoinView.swift:159-162; PairingLinkState | |
| Getting Started Path overlay | Open over blurred Home; step states | GettingStartedPathView.swift; HomeRouterView.swift:145-162 | Only `.active` steps tappable |
| Me Card sheet / compact / Prism | Defined but unpresented | Map/MeCardSheet.swift, Components/MeCardCompact.swift, Map/PrismView.swift — **no external call sites found (orphaned)** | Me-Card "Seg 3" appears unlanded; exclude from taste review or flag as dead code |

**Cross-cutting gaps worth carrying into later phases:** (1) Learn is the only tab with a data source but zero error/loading UI; (2) Learn quizzes have no runner (dead CTA); (3) ResearchDatabaseView filters are visual-only; (4) Play has no first-load spinner (blank void flash); (5) Vault segments load without loading indicators; (6) PulseFullView defaults `myEntries` to preview data in its initializer; (7) no in-player connection-lost state in the two-device session; (8) OB has no mid-flow resume; (9) orphaned Me Card/Prism surfaces; (10) `colorScheme` reads in PairingInviteView and AppElevation modifiers vs. the V1 dark-only rule.

---

## Orchestrator Verification Log

**[VERIFIED: Subagent A — Phases 1 & 2]** All 8 CLAUDE.md-named token files read plus 7 additional Theme/ files discovered and summarized. Contract rubric covers all six contract areas. All 20 surfaces enumerated including three orphaned/unwired ones; the four tabs, OB (11 phases), both Desire covers, Card Session phase machine, Settings + six sub-sheets, pairing, paywall, and one-shot overlays are all present. State inventory includes loading/empty/error/first-run/feature-specific rows per surface, with explicit "MISSING in code" calls (OB resume, Learn error UI, Learn quiz runner, Play first-load, Vault segment loading, in-player connection loss) rather than silent happy-path coverage. Mockups/prototypes unavailability stated explicitly. Output accepted; Phase 3 may begin.

---

# Subagent B — Compliance Audit (Phase 3)

## Phase 3 — Compliance Audit

### Scan coverage
- **341** `.swift` files under `/home/user/Vayl/Vayl`; **190** contain SwiftUI views (`some View`) across `App/`, `Core/`, `Design/`, `Features/` — all 190 swept.
- Method: ripgrep pattern sweeps per category (colors, fonts, numerics, animation curves/timing literals, `.sheet`/`.fullScreenCover`, hardware padding, `repeatForever`/`TimelineView`, `colorScheme`, banned APIs, `.shadow`, tap-contract markers), then ~35 hit regions opened and read to confirm context.
- Exemptions applied: the 11 token files in `App/Theme/` (raw-value home); `#Preview` / `#if DEBUG` preview blocks (e.g. `OnboardingCanvasView.swift:355-390` DevWrapper, `DeckSummary.swift:43-52`, `CandleCardFace.swift:873`, all trailing `.preferredColorScheme(.dark)` preview hits); proportional OB card-face geometry; `VaylPresentation.swift` internals (the sanctioned `.fullScreenCover`/overlay implementation); debug-only tooling (`Core/Debug/*`, `#if DEBUG` overlays) noted separately, not counted.

---

### 1. Raw color literals

Feature-view violations (verified, non-preview):

| File:Line | Snippet | Why it violates | Suggested fix |
|---|---|---|---|
| Features/Learn/Views/LearnView.swift:77 | `.foregroundStyle(Color.white)` | Raw color in a feature view | `AppColors.textPrimary` |
| Features/Home/Views/GettingStartedPathView.swift:129 | `.foregroundColor(.white)` | Raw color | `AppColors.textPrimary` |
| Features/Map/Vault/Components/VaultAgreementsSection.swift:89 | `.foregroundStyle(.white)` | Raw color | token |
| Features/Map/Vault/Components/VaultDesireSection.swift:214, 274 | `.foregroundStyle(.white)` | Raw color | token |
| Features/Map/Vault/EventEntryEditor.swift:145 | `.foregroundStyle(.white)` | Raw color | token |
| Features/Map/Components/FlavorVisuals.swift:67 | `.foregroundStyle(.white)` | Raw color | token |
| Features/Map/Components/MapUsPulseCard.swift:228 | `.stroke(.white.opacity(seamOpacity)…)` | Raw color | token |
| Features/Desire Map/Views/Components/DesireAnswerPill.swift:90 | `.fill(.white)` | Raw color | token |
| Features/Desire Map/Views/Components/DesireMapView.swift:785 | `.fill(.white)` | Raw color | token |
| Features/Desire Map/Views/Components/DesireRevealView.swift:571 | `.fill(.white)` | Raw color | token |
| Features/Pulse/Components/PulseAura.swift:165, 169 | `.stroke(.white.opacity(0.42)…)` | Raw color + raw opacity | token |
| Features/Onboarding/Phases/DemoPhase.swift:270 | `.foregroundStyle(.white)` | Raw color | token |
| Features/Onboarding/Canvas/OnboardingCanvasView.swift:363, 385-387 | `.foregroundColor(.white)`, `Color.black.opacity(0.6)` | Inside `#if DEBUG #Preview` DevWrapper | preview-exempt, noted only |
| Features/Home/Views/HomeDashboardView.swift:816-819 | `Color.cyan`, `Color.white.opacity(0.4)`, `Color.black.opacity(0.4)` | `#if DEBUG` grid toggle | debug-only, noted |

Design-layer offenders (components, not token files — grey area but the contract says zero raw values in Views):

| File | Worst examples | Count |
|---|---|---|
| Design/Components/Effects/HolographicShimmer.swift | `Color(.sRGB, red: 32/255…)` at :227, :256, :263-269, :296, :337, :342 | 14 raw constructors |
| Design/Brand/VaylAppIcon.swift | `Color(hex: "3A1070")` :268-269; comment at :16 admits "no AppColors token" | 15+ |
| Design/Components/Effects/VaylBorderEffect.swift:128-133 | `Color(.sRGB, red: 48/255, green: 42/255, blue: 72/255)` x4 | 4 |
| Design/Components/Effects/VaylButton.swift:59, 88, 93 | `.fill(Color(.sRGB, red: 32/255…))`, `.tint(Color.white)` | 3 |
| Design/Components/Effects/FlameAura.swift:127-131, 167 | `Color(red: 1.0, green: 0.15, blue: 0.55)` etc. | 5 |
| Design/Components/Effects/LightAuraBloom.swift:83+ | `Color(red: 1.00, green: 0.40, blue: 0.60)` | several |
| Design/Brand/SplashScreenView.swift:212, 318, 384, 542 | `Color.black`, `Color(red: 0.902…)`, `Color.white.opacity(0.80)` | 6 |
| Features/Learn/Views/LearnCardStyle.swift:44 | `.fill(Color.white.opacity(fillOpacity))` | 1 |
| Design/Components/Cards/CardFaces/SnapshotCardFace.swift:70 | `.foregroundStyle(.white)` | 1 |

Documented exception (accepted): `SpectrumBulletRow.swift:12` declares its `Color.white` a specular rendering constant. `Features/Play/Models/DeckStyle.swift:87-97` uses `UIColor(AppColors.…)` only to interpolate tokens — compliant in spirit.

### 2. Raw font literals

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Pulse/PulseFullView.swift:121, 151, 270, 368 | `.font(.system(size: 13/28/28/9 …))` | Raw system fonts | `AppFonts` constructors |
| Features/Map/Vault/Components/VaultDesireSection.swift:114, 122, 148, 230, 238, 251 | `.font(.system(size: 11-13))` | 6 raw fonts in one file | `AppFonts.caption`/`body(…)` |
| Features/Map/Vault/Components/VaultAgreementsSection.swift:45; VaultLogSection.swift:52 | `.font(.system(size: 18/10))` | Raw | token |
| Features/Learn/Views/LearnSegmented.swift:34 | `.font(.system(size: 15, weight: .medium))` | Raw | token |
| Features/Learn/Views/ResourcesOverlayView.swift:18; ContentHubSection.swift:224; ResearchDatabaseView.swift:129; FindingDetailView.swift:81 | `.font(.system(size: 19/20/20/4))` | Raw | token |
| Features/Map/MeCardSheet.swift:120; MeCardCompact.swift:55; MapPrimitives.swift:51; MapPulseHero.swift:300; FlavorVisuals.swift:62, 83 | `.font(.system(size: 8-26 …))` | Raw | token |
| Features/Home/Components/PartnerChipExpand.swift:103, 110, 136, 141, 161, 173; PartnerChip.swift:55, 101, 136, 204 | `.font(.caption)` / `.font(.system(size: 9, weight: .bold))` | Raw Dynamic-Type styles and system fonts | `AppFonts.caption` |
| Features/Sessions/Components/RitualPills.swift:72; Features/Pulse/Components/PulseField.swift:241 | `.font(.system(size: 9/10, weight: .bold))` | Raw | token |
| Features/Auth/Views/SignInView.swift:64 | `.font(.body.weight(.semibold))` | Raw | token |
| Design/Components/Navigation/RacetrackTabBar.swift:108 | `Font.custom("Switzer-Regular", size: 24…)` | Bypasses `AppFonts` constructors | `AppFonts.body(24,…)` |
| Design/Components/Cards/CardBackView.swift:171 | `Font.custom("Switzer-Regular", size: 28…)` | Same | `AppFonts.body(28,…)` |
| Design/Components/Progress/ScoreRing.swift:53, 62; ScreenshotProtectionModifier.swift:19; OnboardingProgressBar.swift:1156; OnboardingFooter.swift:17; PartnerAvatarView.swift:22 | `.font(.system(…))` / `.font(.largeTitle)` / `.font(.caption)` | Raw | token |

Self-documented "intentional" exceptions found (left for the human to ratify): `ProgressRingView.swift:40` (geometric badge), `InteractiveField.swift:20` (emoji icon), `StatPhase.swift:269` ("token pending"), `StatPhase.swift:403` ("FEEL-GATE"). Preview-only: `DeckSummary.swift:47-49`, `DragDebugView`, `DiagnosticOverlay` (debug).

### 3. Raw spacing / radius / opacity numerics

Non-zero spacing/padding/cornerRadius literals in **Features/: 36 hits across 15 files** (`spacing: 0` treated as structural, not counted); **Design/: 22 more**. Verified examples:

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Settings/SettingsView.swift:187, 201 | `.padding(.vertical, 5)` | Off-scale literal | `AppSpacing.xxs`(2)/`xs` |
| Features/Home/Components/HomeLexicon.swift:567, 571, 574 | `.padding(36)`, `cornerRadius: 28`, `.padding(14)` | Raw values (offscreen 360×640 share-image render — still untokenized) | tokens or documented render constants |
| Features/Learn/Views/FindingDetailView.swift:81 | `.padding(.top, 7)` | Off-scale literal | `AppSpacing.xs` |
| Features/Sessions/SessionPlayerView.swift:197 | `.padding(.bottom, 150)` | Also a Cat-6 violation | `.bottomClearance(layout)` |
| Worst files (count) | OnboardingCanvasView (8, mostly DEBUG wrapper), VaultDesireSection (3), MapRecord (3), HomeLexicon (3), PulseHistoryGrid (2), DeckCellView (2) | | |

Opacity literals (`.opacity(0.x)`): **408 hits in Features/, 253 in Design/**. Not individually adjudicable; worst offenders: `HomeWidgetShell.swift` (58), `PrismView.swift` (48), `TableSurfaceView.swift` (20), `DeckCaseView.swift` (17), `ReflectionBannerView.swift` (15), `DesireMapView.swift` (14), `SettingsView.swift` (13), `DesireStarView.swift` (13), `SessionPlayerView.swift` (11), `DesireRevealView.swift` (11). Many are gradient/glow alphas inside custom renderers (the contract's grey zone), but none are tokens; there is no opacity scale in `App/Theme/` to point them at — a token-system gap worth recording.

### 4. Raw animation curves / durations

**72** raw curve constructions outside `App/Theme/`. Ones built with token durations (`.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(…)`) are the sanctioned loop idiom — not counted. Numeric-literal violations:

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Design/Brand/SplashScreenView.swift:622, 637, 648, 650, 655, 659, 660, 665 | `withAnimation(.easeInOut(duration: 0.30))` etc. — each carries a `/* TODO: AppAnimation token — spec gap */` | 8 acknowledged untokenized durations | mint splash tokens |
| Design/Components/Effects/VaylButton.swift:68, 97, 111 | `.easeInOut(duration: 0.20)`, `.easeOut(duration: 0.15)` | Raw press/loading timing | `AppAnimation.fast`/`exit` |
| Design/Components/Cards/CardCarousel.swift:119, 750 | `.easeInOut(duration: 3.2).repeatForever` | Raw ambient duration | `ambientDrift` or new token |
| Design/Components/Cards/CardCarousel.swift:351, 700 | `.spring(response: 0.4, dampingFraction: 0.6)` / `(0.6, 0.7)` | Raw springs **and** damping < 0.75; CardCarousel runs outside OB (PlayHeroView, DeckPedestal, HomeDashboardView, PulseField) | `AppAnimation.spring` |
| Design/Components/Cards/CardCarousel.swift:206, 402, 704, 737 | `.spring(response: 0.85-0.95, …)` | Raw spring literals | tokens |
| Features/Sessions/SessionPlayerView.swift:65 | `.animation(.easeInOut(duration: dimmed ? 1.7 : 0.4)…)` | Raw durations | tokens |
| Features/Sessions/SessionAtmosphere.swift:106 | `.animation(.easeInOut(duration: 1.2), value: turn)` | Raw | token |
| Design/Components/Cards/VaylCardFace.swift:483 | `.easeInOut(duration: 2.6)` loop | Raw ambient duration | token |
| Design/Components/Cards/AtmosphericGhostDeck.swift:38, 52 | `.easeInOut(duration: 8.0 / 9.5)` | Raw | tokens |
| Design/Components/Cards/ConversationCard.swift:86, 266 | `.easeInOut(duration: 2.0)`, `.easeIn(duration: 0.4)` | Raw | tokens |
| Design/Components/Text/HolographicText.swift:214-215 | `.easeInOut(duration: 2.0)`, `(0.9)` | Raw | tokens |
| Features/Desire Map/Views/Components/DesireMapView.swift:813-817 | `.easeOut(duration: 0.45/0.35)` | Raw | tokens |
| Features/Pulse/Components/PulseField.swift:296 | `.easeOut(duration: 1.6).repeatForever` | Raw + sub-2s loop (see Cat 7) | token ≥ 2s |
| Core/Models/Enums/AppOBEnums.swift:182, 189 | `static let floatAwayAnim: Animation = .easeOut(duration: 0.55)` | Animation constants defined outside `App/Theme/` | move to `AppAnimation` |
| Design/Components/Progress/OnboardingProgressBar.swift:604 | `.easeInOut(duration: animationDuration)` | Locally-owned duration | token |

Timing literals used for UI choreography (contract: "no raw durations anywhere — Views, Stores, sequencers"):
- `DispatchQueue.main.asyncAfter`: **CardCarousel.swift:619, 673, 702, 708, 733, 745** (0.35-0.9s); InfiniteCarousel.swift:88 (0.45); HomeLexicon.swift:471 (1.4); HomeDashboardView.swift:856 (0.12); ScreenshotProtectionModifier.swift:55 (1.5).
- `Task.sleep` choreography: **CardMirrorDeal.swift** (12 sites, :112-329), **ThreeCardFanController.swift** (10 sites, :128-321, some marked FEEL-GATE), ConfirmationPhase.swift:203-242 (incl. 6000 ms), CuriosityPhase.swift:130-390, GenderPhase.swift:98-100, ConversationCard.swift:351-355, SessionPlayerView.swift:593 (3.6 s), SessionCloseView.swift:41 (1.5 s), CardSessionContainerView.swift:111, BreathGuide.swift:61, PulseCheckInView.swift:336/364, DeckBeginCeremony.swift:52/56, HomeLexicon.swift:409.
- Store-level: CoupleSessionStore.swift:569 (1 s), :630 (15 s — network pacing, not animation; acceptable).

### 5. Raw presentation

`.vaylCover`/`.vaylSheet` are defined in `Design/Components/Navigation/VaylPresentation.swift` (whitelisted internals). 38 compliant call sites found. Raw call sites:

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Auth/Views/SignInView.swift:124 | `.sheet(item: $legalDoc) { SafariView(url:…) }` | Raw `.sheet` in a feature view (legal docs) | `.vaylSheet` (or document a system-browser exception) |
| Features/Home/Components/HomeLexicon.swift:180 | `.sheet(item: $shareImage) { ActivityView(…) }` | Raw `.sheet` (share sheet) | same |
| Features/Pairing/PairingSettingsView.swift:66, 75 | `.sheet(isPresented: $showInviteView/JoinView)` | Raw sheets, plus this view has its own `NavigationStack`/`navigationTitle` (:55-56) — both against the Settings grammar. **File appears orphaned** (only self/preview references; `SettingsPartnerView` is the live path) | delete or migrate |

**Card Session verified compliant**: `PlayView.swift:156` and `HomeDashboardView.swift:456` (joiner) present `CardSessionContainerView` via `.vaylCover` with default `confirmOnExit: true` (interactive dismiss disabled, confirm dialog in `VaylCoverModifier`). `HomeDashboardView.swift:443` couch-mode cover is DEBUG-only. Settings-over-shell (`AppShell.swift:39`), raters, Pulse check-in, OB all route correctly.

### 6. Hardcoded hardware padding / tab-content clearance

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Sessions/SessionPlayerView.swift:197 | `.padding(.bottom, 150)` | Hardcoded bottom clearance inside a cover (covers own their clearance, but via helpers) | `.bottomClearance(layout)` / `.stickyBottomCTA` |
| Features/Home/Views/HomeDashboardView.swift:823 | `.bottomContentInset(layout)` | Tab content adding bottom clearance — banned by the tab-bar contract. `#if DEBUG` grid toggle only | remove; AppShell inset already reserves it |
| Features/Home/Views/HomeRouterView.swift:375 | `.bottomContentInset(layout)` | Same, DEBUG reveal menu | remove |
| Features/Onboarding/Canvas/OnboardingCanvasView.swift:390 | `.padding(.top, 60)` | Inside `#if DEBUG #Preview` DevWrapper | preview-exempt, noted |

Structural check passed: `AppShell.swift:48-73` attaches `RacetrackTabBar` via `.safeAreaInset(edge: .bottom)`; `TabContentWrapper` adds only the fade mask, no inset. One stale comment: `LearnView.swift:36` still says "tab-bar clearance is TabContentWrapper's job" — the code is right, the comment is wrong.

### 7. Looping animations — gating

Overall discipline is strong: nearly all `repeatForever` sites use `.ambientAnimation(_:value:)` or a manual `guard !reduceMotion, !AppAnimation.lowPower` start guard (verified in CardCarousel, PulseAura, StatPhase, AirlockView, HolographicText, AtmosphericGhostDeck, SessionAtmosphere, RevealCardChrome, LocalCardFaceView, CardSessionContainerView, DemoPhase, MapUsPulseCard, DeckPedestal, VaylFlourishView, GlassSpecularSweep, VaylCardFace, VaylCardCarousel, ConversationCard, SessionLobbyView, BuildDeckPhase, LightModeShimmer). No `.spring()` on `.repeatForever()` anywhere.

Violations:

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Home/Components/HomeWidgetShell.swift:76-91 | `if reduceMotion { EmptyView() } else { … TimelineView(.animation) }` | Gated on Reduce Motion but **not Low Power Mode** (`lowPower` appears nowhere in the file), and `TimelineView(.animation)` has **no `minimumInterval:`** for a slow orb wander — exactly the "slow drift never needs display rate" case | gate on `AppAnimation.ambientMotionDisabled`; add `minimumInterval: 1/30` |
| Features/Pulse/Components/PulseField.swift:296 | `.easeOut(duration: 1.6).repeatForever(autoreverses: false)` | Loop under 2 s (only `ambientShimmer` 1.2 s is exempt) | slow to ≥ 2 s or tokenize an exception |
| Design/Components/Cards/FuseTimerView.swift:44 | `TimelineView(.animation(paused: completed))` | No frame cap; a burning-fuse spark plausibly needs high rate and it is reactive/one-shot — borderline, flag for the motion owner | add cap if 30 fps reads the same |

Acceptable-with-caveat (gated on RM+LPM but uncapped, fast specular/particle motion): `SpectrumSparkField.swift:42`, `MetallicCaseView.swift:313`, `HolographicShimmer.swift:239`. Properly capped examples for reference: `LightAuraBloom.swift:65`, `LivingText.swift:67`, `SpectrumBulletRow.swift:50`, `ContextCardFace.swift:130`, `PulseAura.swift:289`, `PulseField.swift:262`, `ExperienceLevelPhase.swift:162`, `PulseHistoryGrid.swift:200`.

### 8. Empty states / loading / error UI

| File:Line | Finding | Severity |
|---|---|---|
| Features/Learn/Store/LearnStore.swift:21, 46 + Features/Learn/Views/LearnView.swift | **Confirmed**: `loadError` is set on bundle-load failure and rendered nowhere (only references in the store). LearnView has no empty/error state — a failed load renders header + hollow sections silently. Also `refresh()` (Supabase override) has no loading or failure surface. | Violation |
| Features/Play/PlayView.swift:69-73 | Phase-2 suspicion moderated: `PlayEmptyState(message: store.loadError) { store.retry() }` exists and doubles as the error state; the catalog load is synchronous bundled JSON, so a first-load spinner is genuinely unnecessary. | OK |
| Features/Map/Vault/ | `MapEmptyState` used correctly (VaultLogSection.swift:23, VaultAgreementsSection.swift:119, VaultDesireSection.swift:42, 85, 176). **No loading indicator anywhere in Vault** (zero `isLoading`/`ProgressView` hits) — acceptable for local SwiftData reads, but sync-refresh has no pending surface. | Low |
| Features/Pulse/PulseFullView.swift:20 | **Confirmed**: `var myEntries: [PulseEntry] = PulseEntry.previews` — a production view defaulting to preview fixture data. The sole live call site (Features/Map/MapView.swift:129-135) passes real entries, but any future caller omitting the argument ships fake history. | Footgun — change default to `[]` |

### 9. Dark-mode-only (V1) violations

The contract requires zero light-mode references/infrastructure. Confirmed live light-mode code (non-preview):

| File:Line | Snippet | Notes |
|---|---|---|
| Features/Pairing/PairingInviteView.swift:31-32 | `@Environment(\.colorScheme)` + `isLight` | Confirmed (known suspect) |
| Features/Pairing/PairingJoinView.swift:31-32 | same | |
| Features/Pairing/PairingSettingsView.swift:19-20 | same | (orphaned file) |
| Features/Map/PrismView.swift:77-78 | `isLight = colorScheme == .light` | drives light branches through the file |
| Features/Home/Components/ReflectionBannerView.swift:11, 25-58, 65, 93, 118, 146, 235-333 | ~17 `colorScheme == .light` branches | heaviest feature offender |
| Design/Components/Effects/LightModeShimmer.swift (entire file) | "cream surfaces" shimmer | light-mode component, **actively referenced** by SelectablePill and RacetrackTabBar |
| Design/Components/Buttons/SelectablePill.swift:34-35; Design/Components/Navigation/RacetrackTabBar.swift:11, 60-103; Design/Components/Navigation/OnboardingFooter.swift:11, 18; Design/Components/Input/InteractiveField.swift:12, 28, 36; Design/Components/Effects/GlowOrb.swift:13, 18; Design/Components/Text/LivingText.swift:12-70; Design/Components/Text/GradientText.swift:12, 19; Design/Components/Cards/AtmosphericGhostDeck.swift:19-83 | `colorScheme` reads + light palettes | design-layer light infra |
| Design/Components/Progress/OnboardingProgressBar.swift:400, 415-492, 709, 803 | ~25 dark/light ternaries | largest single file of light infra |
| Features/Home/Components/HomeWidgetShell.swift:174+ | `let isLight: Bool` parameter with full light surface path (`lightSurface(…)` :186) | light rendering path kept alive |
| App/Theme/ThemeManager.swift:13-45 + AppTheme.swift | full `ThemeMode` persistence/migration machinery; `preferredColorScheme` hard-returns `.dark` | infrastructure the contract says should not exist in V1 (token-file oddity, noted) |
| App/Theme/AppElevation.swift:223-248; App/Theme/ThemeModifiers.swift:30, 45 | `colorScheme == .dark` branches | known suspect confirmed (token files, noted) |
| App/VaylApp.swift:56; Design/Brand/SplashScreenView.swift:132 | `.preferredColorScheme(.dark)` in production code | letter-of-contract violation; in practice the force-dark root is what enforces V1 — but it is triple-redundant with ThemeModifiers:17 and ThemeManager |

Not violations: `HomeLexicon.swift:37` reads `colorSchemeContrast` (accessibility, not theme); `HomeLexicon.swift:479` *writes* `.environment(\.colorScheme, .dark)` for the share render; ~150 `.preferredColorScheme(.dark)` hits are inside `#Preview` blocks; `CardCarousel.swift:393` hardcodes `isLight: false` with a compliance comment.

### 10. iOS 26 banned APIs

**No violations found.** The only `UIScreen.main` / `keyWindow` matches are prohibition comments (`AppLayout.swift:27, 114`; `GenderSequencer.swift:194`). Zero hits for `UNAuthorizationOptionAlert`, `UNNotificationPresentationOptionAlert`, `UIWebView`, `NSURLConnection`.

### 11. Raw `.shadow(` used for glows

| File:Line | Snippet | Why | Fix |
|---|---|---|---|
| Features/Desire Map/Views/Components/DesireStarView.swift:121-122, 230-232 | `.shadow(color: AppColors.spectrumMagenta.opacity(0.82), radius: 7)` + purple radius-15 layer | Multi-layer colored glow built from `.shadow()` — exactly what AppGlows exists for | `.spectrumBorderGlow` / AppGlows layer spec |
| Features/Home/Components/HomeWidgetShell.swift:198-216 | 5 stacked `.shadow(…)` mixing black elevation with accent-colored glow layers (plus `isLight` branches) | Glow-via-shadow + hand-rolled elevation | `AppElevation.cardShadow` + AppGlows |
| Design/Components/Buttons/SelectablePill.swift:337-351 | 7 stacked `.shadow(…)` glow layers | Component-level glow stack bypassing AppGlows | consolidate into an AppGlows modifier |
| Features/Home/Components/DeckPedestal.swift (2), Features/Map/PrismView.swift (2), Features/Desire Map/Views/Components/DesireMapView.swift (3), DesireRevealView.swift (1), DesireAnswerPill.swift (1), Features/Sessions/SessionPlayerView.swift (2), Features/Pulse/* (3) | accent-colored `.shadow` singles | Same pattern, lower intensity | AppGlows |

Positive example: `Features/Map/Components/MapHeroAmbientGlow.swift:13` explicitly documents "Implemented as gradients, not `.shadow()`". `Design/Components/Cards/CardShadows.swift` is the sanctioned card-shadow home.

### 12. Tap contract (press-scale + haptic + action) — sampled

Two sanctioned implementations exist: `VaylButton` (scale + soft/medium `UIImpactFeedbackGenerator`, VaylButton.swift:46-47, 149, 181) and `PressableCardStyle` (LearnCardStyle.swift:22-31), the latter used widely (SettingsView applies it to all 17 rows). Misses found:

| File:Line | Snippet | Missing |
|---|---|---|
| Features/Map/Vault/Components/VaultAgreementsSection.swift:81-82 | `Button("Not now") { decide(p, approve: false) }.buttonStyle(.plain)` | scale + haptic (its sibling "Approve" at :86 is compliant) |
| Features/Home/Components/PartnerChip.swift:60, 106, 151, 209 | `.buttonStyle(.plain)` chips, no scale/haptic anywhere in file | scale + haptic |
| Features/Home/Views/GettingStartedPathView.swift:113-114 | `.contentShape(Rectangle()).onTapGesture(perform: onTap)` | scale + haptic on the step rows |
| Features/Home/Views/MapChartedMoment.swift:61-62 | `.onTapGesture { dismiss() }` | haptic + press state |
| Features/Pulse/PulseFullView.swift:83-129 | layer-toggle and close buttons: manual haptic present, `.buttonStyle(.plain)` — **no press-scale** | scale |
| Features/Onboarding/Phases/CredentialEditorSheet.swift (3 taps), NamePhase.swift, DemoPhase.swift, Features/Play/Components/DeckBeginCeremony.swift | `onTapGesture` sites, zero haptic references in file | haptic (+ scale) |
| Systemic | **64 `.buttonStyle(.plain)` sites across Features/** (SessionBuilderView ×7, SessionCloseView ×3, MapPulseHero ×5, ReflectionBannerView ×6, Vault ×6, PaywallSheet ×2, MapView ×2, …) — each is only compliant if its label hand-rolls press feedback; most sampled do not | adopt `PressableCardStyle` as the default in place of `.plain` |

---

### Summary counts

| # | Category | Verified violations | Worst offenders |
|---|---|---|---|
| 1 | Raw colors | 16 feature-view sites + ~50 design-layer constructors | HolographicShimmer (14), VaylAppIcon (15), FlameAura, VaylBorderEffect |
| 2 | Raw fonts | ~40 sites | VaultDesireSection (6), PulseFullView (4), PartnerChip/Expand (10), RacetrackTabBar + CardBackView `Font.custom` |
| 3 | Raw spacing/radius/opacity | 36 spacing/radius (Features) + 22 (Design); 661 opacity literals | HomeWidgetShell (58 op.), PrismView (48), TableSurfaceView (20) |
| 4 | Raw animation curves/durations | ~45 numeric-literal curve sites + ~45 timing literals (asyncAfter/Task.sleep) | SplashScreenView (8, self-flagged), CardCarousel (12 incl. springs at 0.6/0.7 damping outside OB), CardMirrorDeal (12), ThreeCardFanController (10) |
| 5 | Raw presentation | 4 raw `.sheet` sites (2 in orphaned PairingSettingsView); Card Session cover **compliant** | PairingSettingsView |
| 6 | Hardware padding / tab clearance | 1 production (`SessionPlayerView:197`), 2 DEBUG (`bottomContentInset` in Home tab) | SessionPlayerView |
| 7 | Loop gating | 2 real (HomeWidgetShell LPM gate + frame cap; PulseField 1.6 s loop), 1 borderline (FuseTimerView) — otherwise exemplary | HomeWidgetShell |
| 8 | Empty states | 1 confirmed (Learn loadError never rendered), 1 footgun (PulseFullView previews default); Play/Vault suspicions largely cleared | LearnView |
| 9 | Dark-mode-only | ~20 files with live light-mode branches + full ThemeManager infra + LightModeShimmer component in active use | OnboardingProgressBar (~25 branches), ReflectionBannerView (~17), LightModeShimmer |
| 10 | iOS 26 banned APIs | **0** | — |
| 11 | `.shadow` glows | ~12 files | DesireStarView, HomeWidgetShell, SelectablePill |
| 12 | Tap contract | 10+ specific misses; 64 `.buttonStyle(.plain)` sites systemically at risk | PartnerChip, Vault sections, PulseFullView (no press-scale) |

**Cross-cutting worst-offender files**: `Design/Components/Cards/CardCarousel.swift` (cats 4, 7-adjacent springs), `Features/Home/Components/HomeWidgetShell.swift` (cats 3, 7, 9, 11), `Features/Home/Components/ReflectionBannerView.swift` (cats 3, 9, 12), `Design/Components/Progress/OnboardingProgressBar.swift` (cats 1, 2, 4, 9), `Features/Pairing/PairingSettingsView.swift` (cats 5, 9 — and it appears to be dead code that should simply be deleted), `Design/Brand/SplashScreenView.swift` (cats 1, 4, 9). The two healthiest contracts are iOS 26 API hygiene (clean) and ambient-loop gating (near-universal `.ambientAnimation` / RM+LPM guards).

---

## Orchestrator Verification Log

**[VERIFIED: Subagent B — Phase 3]** Scan denominator stated (190 view-bearing files of 341 swept). All 12 mandated categories reported, none skipped; clean categories (iOS 26 APIs) declared explicitly rather than omitted. Citations are file:line-specific and context-verified (~35 hit regions opened); preview/DEBUG/token-file exemptions were applied and disclosed rather than silently dropped. Phase-2 suspicions were re-tested rather than copied (Play first-load and Vault loading correctly moderated; Learn error UI and PulseFullView preview-default confirmed). Notable systemic discoveries beyond the checklist: no opacity token scale exists, 64 `.buttonStyle(.plain)` sites at tap-contract risk, and live light-mode infrastructure across ~20 files despite the V1 dark-only rule. Output accepted; Phase 4 may begin.

---

# Subagent C — Design Taste Critique (Phase 4)

## Phase 4 — Design Taste Critique

### 1. Home dashboard
**Working:** The collapsed composition (wordmark header → deck-on-pedestal hero → pulse rail → lexicon type layer) is a genuinely calm single screen; the deck-engaged recede (blur 6 + opacity 0.25 on everything else) is the right depth move, and the pulse rail's spectrum top hairline with clear end-stops is the card-chrome language at its best.

**Findings:**
- [motion] Before: entrance cascade uses four raw inline delays — `.delay(0.10)/.delay(0.30)/.delay(0.62)/.delay(0.78)` (HomeDashboardView.swift:784-787) — four separately-timed layers reads staged, and the values are untokened → After: collapse to two beats (greeting+hero at 0s, pulse+lexicon together at one named delay), and hoist the delays into `AppAnimation` (e.g. `homeCascadeBeat`) so the choreography is a token, not four magic numbers.
- [color & restraint] Before: the corner-deck count badge fills an 18pt circle with the full three-stop `AppColors.spectrumBorder` gradient (HomeDashboardView.swift:767-772) — the app's highest-value signature on its smallest element, where three stops resolve to mud → After: `Circle().fill(AppColors.accentPrimary)` with the `AppColors.void` numeral; reserve the full spectrum for strokes and heroes.
- [typography] Before: deck header count "N / M explored" wears `AppFonts.bodyMedium` (15 medium) in `textTertiary` (HomeDashboardView.swift:260-262) — metadata in a body font → After: `AppFonts.caption` (13), same `textTertiary`.
- [motion] Before: `SettingsCogButton` fires `action()` on tap-down and fakes the press by resetting `isPressed` via `DispatchQueue.asyncAfter(0.12)` (HomeDashboardView.swift:853-859) → After: replace with the shared `PressableStyle`/`PressableCardStyle` ButtonStyle (as in DeckDetailView) so `isPressed` tracks the real gesture and the haptic gains the `{ _, pressed in pressed }` condition.
- [rhythm] Before: `pedestalDropY: CGFloat = 191` (HomeDashboardView.swift:209) and a second bare `.offset(y: 191)` in PlayHeroView.swift:35, both coupled to CardCarousel's private `cardW = 300` via `cardHalfWidth = 150` (HomeDashboardView.swift:184) → After: hoist one `DeckPedestal.heroDropY` (or AppLayout constant) consumed by both call sites so Home and Play can't drift.
- [hierarchy — router states] Before: HomeRouterView's loading state is a bare `ProgressView` + text with no screen background, and the error state uses stock `Button("Try Again").buttonStyle(.borderedProminent)` (HomeRouterView.swift:193-221) — the only stock-system CTA on a root tab, on a background that violates the void+atmosphere contract → After: wrap both states in `AppColors.void` + `OnboardingAtmosphere(config: .stat)` and swap the button for `VaylButton(label: "Try again")`.

### 2. Getting Started Path overlay
**Working:** The rail-and-node metaphor with done/active/upcoming/locked states is instantly legible, the matched-geometry morph from the entry card is the right presentation, and the copy ("Each one brings the two of you closer…") stays warm without selling.

**Findings:**
- [typography] Before: "Begin together" is `AppFonts.overline` with `spectrumText` but no tracking or uppercase (GettingStartedPathView.swift:14-17), unlike every other overline in the app → After: add `.tracking(1.5)` + `.textCase(.uppercase)`.
- [emotional fit] Before: "🔒 Private to you — …" uses a literal emoji padlock (GettingStartedPathView.swift:50) — the only color-emoji glyph in the app's chrome; every other lock is an SF Symbol → After: `HStack { Image(systemName: "lock.fill").font(AppFonts.meta).foregroundColor(AppColors.textMuted); Text(...) }`.
- [color] Before: "Start →" is raw `AppColors.spectrumCyan` (GettingStartedPathView.swift:104-107) → After: `AppColors.textAccent` (the semantic tappable-link token; same cyan in Midnight, survives Dawn).
- [color] Before: node checkmark is raw `.foregroundColor(.white)` (GettingStartedPathView.swift:129) → After: `AppColors.textBody`.
- [depth & restraint] Before: the card carries BOTH a full-opacity 2pt spectrum top bar (lines 62-67) AND a spectrum stroke around the whole card at 0.45 opacity (lines 68-72) — double signature chrome on one surface → After: drop the top bar; keep the 0.5-opacity spectrum stroke as the single accent (or keep the bar but taper it with clear end-stops like HomePulseRail's hairline and drop the full stroke).

### 3. Play tab
**Working:** Shelf grammar (flat case + title/meta underneath), the scroll-linked hero receding into 3D depth, and a to-the-letter contract-compliant empty/error state. The Begin ceremony is properly reserved (plays only on Begin, cross-fades under RM/LPM).

**Findings:**
- [rhythm] Before: DeckCellView uses raw `VStack(spacing: 3)` and `HStack(spacing: 6)` (DeckCellView.swift:35, 43) → After: `AppSpacing.xs` (4) for both — the 1-2pt difference is invisible; the off-grid literal isn't.
- [color] Before: the "WHEN TO USE" paragraph renders in `AppColors.spectrumCyan.opacity(0.65)` italic (DeckDetailView.swift:52-57) — prose in translucent accent breaks the text ladder and 0.65 is a raw opacity → After: body in `AppFonts.bodyText.italic()` + `AppColors.textSecondary`; if the section wants accent, put it on the "WHEN TO USE" label via `AppColors.textCardLabel`.
- [hierarchy] Before: detail section labels use `AppColors.textMuted` (20% — the disabled tier) (DeckDetailView.swift:98-102) → After: `AppColors.textSectionLabel` (the lavender grouping-label token).
- [rhythm] Before: ceremony hint "tap the seal to open" is positioned with a bare `.offset(y: 200)` (DeckBeginCeremony.swift:38-43) → After: lay it out in a `VStack(spacing: AppSpacing.xl)` under the 310pt case frame — placement from layout, not a screen-magic offset.
- [emotional fit] Before: locked-deck CTA reads "Purchase Lifetime Access" (DeckDetailView.swift:251) — transactional voice, and it duplicates the paywall's own job one tap later → After: `VaylButton(label: "Unlock all decks")`, letting the PaywallSheet carry the price story (the caption below it already shows the price).

### 4. Map tab — Me layer
**Working:** The aura hero → space name → descriptor column is the app's strongest ambient hero; stale ("As of 2 days ago") vs quiet (opacity) discipline is exemplary honesty; the empty state deliberately reuses Home's dormant language instead of inventing a second one.

**Findings:**
- [hierarchy] Before: two tappable header affordances, "History" and "tap to map →", both `AppFonts.caption` + `AppColors.textMuted` (MapPulseHero.swift:126-146) — live controls at the disabled tier, competing with each other while the aura itself already opens the map → After: keep only "History", at `AppColors.textTertiary`; delete "tap to map →" (redundant with the tappable aura).
- [color] Before: the weather line renders in raw `AppColors.spectrumCyan` (MapPulseHero.swift:72-77) → After: `AppColors.textAccent`.
- [typography] Before: MapFieldSheet copy uses ad-hoc constructors — `AppFonts.display(15, …)` headline over `AppFonts.body(11, …)` description (MapPulseHero.swift:276-286); 11pt Switzer for a full sentence is below the caption floor → After: headline → `AppFonts.cardTitleCompact` (16), description → `AppFonts.caption` (13).
- [typography] Before: MapFieldSheet dismiss xmark is raw `.font(.system(size: 13, weight: .medium))` (MapPulseHero.swift:299-300) → After: `AppFonts.caption` (the rater/reveal close-button pattern).
- [rhythm] Before: MapRecord rows use `spacing: 1`, `spacing: 3`, and `.padding(.vertical, AppSpacing.sm + 2)` (MapRecord.swift:96, 111, 122) → After: `AppSpacing.xxs` for the micro-gaps and a clean `AppSpacing.sm` vertical row padding — kill the +2.

### 5. Map tab — Us layer
**Working:** SplitOrbView is the best data-honesty visual in the app — diagonal seam, ember desaturation for quiet halves, cycling half dimmed so "no answer" never outshines an answer, and the shared halo only when both readings are real.

**Findings:**
- [color & restraint] Before: "THE PULSE · TOGETHER" header in full `AppColors.spectrumMagenta` (MapUsPulseCard.swift:71-75) while the Me twin whispers in `textSectionLabel` — one lens shouts, its sibling doesn't → After: `AppColors.textSectionLabel`; let the masthead's lens caption and lens tint carry the magenta identity.
- [motion] Before: the split orb's container breathes on `.easeInOut(duration: AppAnimation.ambientPulse)` (2s) (MapUsPulseCard.swift:248-253) while PulseAura itself breathes at `auraBreathe` (5.4s) — the couple's orb pulses ~2.7× faster than the personal orb it mirrors → After: `.easeInOut(duration: AppAnimation.auraBreathe)`.
- [color] Before: seam and rim use raw whites — `.white.opacity(0.22)` and `.white.opacity(0.14)` (MapUsPulseCard.swift:226-233) → After: `AppColors.borderActive` (white 0.15) for the rim; source the seam from the same token.
- [rhythm] Before: the Us column mixes three micro-gaps — `VStack(spacing: AppSpacing.xs)` + pill `.padding(.top, AppSpacing.xxs)` + vault door `.padding(.top, AppSpacing.sm)` (MapUsLayer.swift:63-71) — while Me separates its sections with `AppSpacing.xl` → After: one `VStack(spacing: AppSpacing.sm)` with the per-item paddings deleted, and `AppSpacing.xl` before the vault door so the two lenses share a vertical rhythm.
- [typography] Before: "Open ›" uses `AppFonts.caption.bold()` (VaultDoorCard.swift:59-61) — weight-modified token instead of the semantic one → After: `AppFonts.buttonLabel`, same `spectrumMagenta`.

### 6. Vault sheet
**Working:** Consistent `vaylGlassCard` row language across all three segments, contract-complete empty states with genuinely warm copy, and the consent flow ("Pass, and they are never told it was a no") is the product's privacy ethic made visible.

**Findings:**
- [hierarchy] Before: the sheet title "The Vault" is `AppFonts.sectionHeading` (20 medium) (VaultSheet.swift:30-32) — a screen-level surface titled at section tier, same size as the MapSectionHeaders below it → After: `AppFonts.screenTitle` (24 semibold).
- [color] Before: Approve / Ask / "Open it" capsule CTAs use raw `.foregroundStyle(.white)` (VaultDesireSection.swift:214-217, 274-277; VaultAgreementsSection.swift:88-92) → After: `AppColors.textBody`.
- [typography] Before: row icons are raw system fonts — `.system(size: 13)`, `.system(size: 11)`, `.system(size: 10)`, `.system(size: 18)` (VaultDesireSection.swift:113-115, 121-123; VaultLogSection.swift:51-53; VaultAgreementsSection.swift:44-46) → After: `AppFonts.caption` for 13pt icons, `AppFonts.meta` for 10-11pt chevrons/locks, `AppFonts.bodyMedium` for the lifepreserver.
- [rhythm] Before: off-grid arithmetic scattered through rows — `.padding(.vertical, AppSpacing.sm + 2)`, `.padding(.vertical, AppSpacing.xs + 1)`, `.padding(.vertical, AppSpacing.xxs + 1)`, `.padding(.vertical, 2)` (VaultDesireSection.swift:126, 139, 216; VaultLogSection.swift:71) → After: rows at `AppSpacing.sm` vertical, badges at `AppSpacing.xxs` — delete every +1/+2.
- [emotional fit] Before: the locked-more row pairs `lockedCount` copy with "Unlock the full map" in `AppColors.accentPrimary` `AppFonts.overline` (VaultDesireSection.swift:144-163) — an upsell accent shouting inside the couple's private vault list → After: `AppFonts.caption` in `AppColors.textAccent`, no overline treatment; the row's lock icon already says the rest.

### 7. Learn tab
**Working:** The three-hue sectioning (cyan quizzes, purple research, magenta hub) gives the tab a clear internal map; the research card structure (type chip → stat → finding → citation, plus "One honest limitation" in the detail) is intellectually honest and on-brand.

**Findings:**
- [product principle — assessment line] Before: the flavor quiz teaser shows four archetype pills — "The Explorer", "The Architect", "The Catalyst", "The Anchor" (QuizCarouselSection.swift:62-78) — persona-noun verdicts, literally the CLAUDE.md banned pattern ("You are an Explorer") advertised on the card → After: replace the four pills with the quiz's topic vocabulary ("Openness · Structure · Pace · Anchoring" or the actual question themes) — wayfinding words, never assigned identities.
- [typography] Before: all three section headers hand-build `AppFonts.display(16, weight: .semibold, relativeTo: .title3)` (QuizCarouselSection.swift:14-16; ResearchSection.swift:17-19; ContentHubSection.swift:36-38) → After: `AppFonts.cardTitleCompact` — the identical token already exists.
- [typography] Before: "Learn." masthead is `AppFonts.heroTitle` (42) (LearnView.swift:64-66) while Home ("VAYL.") and Play ("Cards.") mastheads are `AppFonts.display(40, weight: .bold, relativeTo: .largeTitle)` → After: match the shared 40pt display treatment (better: extract one `tabMasthead` token all four use).
- [color] Before: Resources and Browse pill labels are raw `Color.white` (LearnView.swift:75-78; ResearchSection.swift:26-28) → After: `AppColors.textBody`.
- [motion & emotional fit] Before: two auto-advancing carousels cycle at 5s and 5.5s on one screen (QuizCarouselSection.swift:18; ResearchSection.swift:38) — ticker cadence against the "slow, breathing" register (Home's Lexicon deliberately dwells 12s) → After: raise both `interval:` values to 12, phase-offset so they never swap simultaneously.
- [hierarchy — honesty] Before: ResearchDatabaseView ships a fake search field (static placeholder Text, lines 65-78) and visual-only sort/Filters controls (lines 101-119) — dead affordances styled as live → After: remove the search field and the sort/Filters row until the filter engine ships; keep the topic chips (they can filter the list locally today).

### 8. Pulse check-in cover
**Working:** The orb drifting across the field with each answer is the app's thesis in one interaction; the Uncharted resolution (field fades, colour dissolves to Sage Deep last, drift as the landing signal) is superbly judged; the step-numbers-as-navigation replaces a counter with something quietly useful.

**Findings:**
- [hierarchy] Before: the reveal's descriptor line — the moment's payoff copy — renders in `AppColors.textMuted` (20%, the disabled tier) (PulseCheckInView.swift:233-236) → After: `AppColors.textSecondary`.
- [depth] Before: the "Done" CTA is a hand-rolled 1pt accent-gradient outline capsule (PulseCheckInView.swift:242-263) — a bespoke primary-CTA treatment when `VaylButton` is the app's one CTA voice → After: `VaylButton(label: "Done")`.
- [motion] Before: the active step dot glows with a raw `.shadow(color: …opacity(0.35), radius: 8)` (PulseCheckInView.swift:148-155) — AppGlows explicitly owns glows; raw `.shadow()` for glow is a listed violation → After: drop the shadow and let the 2pt `textSectionLabel` ring carry "current", or use the AppGlows modifier family if a glow is wanted.

### 9. Pulse full view
**Working:** Carrying the exact name-toggle masthead grammar into the sheet at interior size keeps one mental model; the 30-check-ins split-bead grid with tap-for-callout is quiet, honest data display.

**Findings:**
- [emotional fit — data honesty] Before: when the partner has never checked in, a waiting aura is placed at a fabricated field coordinate `PulsePosition(energy: 0.30, openness: 0.30)` with "‹name› · not yet" (PulseFullView.swift:317-327) — a made-up low-energy/low-openness position rendered as if it were a reading, the exact fabrication `hasHistory` guards against elsewhere → After: park the waiting `PulseCyclingAura` at field center (0.5, 0.5) or move it out of the field entirely (a caption row below), keeping "not yet" — never a corner coordinate that reads as data.
- [typography] Before: aura labels use raw `.font(.system(size: 9, weight: .bold))` (PulseFullView.swift:367-372) — sub-floor size, off-family → After: `AppFonts.label` (10pt Switzer semibold) with the existing tracking/uppercase.
- [typography] Before: copyBlock repeats the ad-hoc `display(15)` / `body(11)` pair (PulseFullView.swift:375-386) → After: `AppFonts.cardTitleCompact` + `AppFonts.caption` (same fix as MapFieldSheet — do them together).
- [typography] Before: empty-state icons use raw `.font(.system(size: 28))` (PulseFullView.swift:150-152, 269-271) → After: `AppFonts.screenTitle` on the symbol (matches the rater/reveal empty-state icon treatment).

### 10. Card Session (lobby, airlock, player, close, safe-word close)
**Working:** One voice across the whole family — lowercase ✦ overlines, honest mechanism copy ("each partner holds their own ring"), safe word always reachable in gold with no confirm. SafeWordCloseView is perfect as-is: zero guilt, no stats, "Good call." The hold-to-deal pull-from-fan is the app's best interaction theater.

**Findings:**
- [motion] Before: the idle dim animates with raw inline durations — `.animation(.easeInOut(duration: dimmed ? 1.7 : 0.4), value: dimmed)` (SessionPlayerView.swift:62-67) → After: `AppAnimation.cinematicFade` (1.2s) for the dim-in, `AppAnimation.enter` (0.4s) for the wake — or mint a named `idleDim` token; no bare 1.7.
- [emotional fit] Before: the care sheet mixes glyph systems — "🤍" color emoji beside text glyphs ❚❚ ✦ ◦ ⤼ ✓ (SessionPlayerView.swift:476-493) — the emoji renders in system color and breaks the monochrome register of the most protected screen → After: SF Symbols throughout (`pause.fill`, `heart`, `sparkle`, `circle`, `arrow.uturn.forward`, `checkmark`) in `AppColors.textSecondary`, `spectrumMagenta` for "End well".
- [depth] Before: the reflection "Save" button fills a full-width rectangle with the raw `AppColors.spectrumBorder` gradient and void text (SessionCloseView.swift:210-224) — the only large CTA in the app not routed through VaylButton → After: `VaylButton(label: "Save")` beside the plain "Skip".
- [hierarchy — error state] Before: an airlock failure reason renders as `AppFonts.caption` + `AppColors.textSecondary` directly under the lobby title (SessionLobbyView.swift:44-49) — a failure indistinguishable from a subtitle → After: same size, `AppColors.destructive`, so a failed room reads as a state, not a caption.

### 11. Session Builder
**Working:** Honest, functional shaping — ceremonial cards labeled "RITUAL"/"CLOSING · STAYS" with a lock and explanation, trimmed cards recoverable, "Not tonight" as a respected exit.

**Findings:**
- [hierarchy] Before: the sheet title "Shape tonight" is `AppFonts.sectionHeading` (SessionBuilderView.swift:65-75) — same section-tier-title problem as the Vault → After: `AppFonts.screenTitle`.
- [color & restraint] Before: "Quick start" / "Same as last time" chips carry the full `AppColors.spectrumBorder` stroke (SessionBuilderView.swift:96-111) — shortcut chips wearing the signature while the actual primary CTA (VaylButton "Start with N cards") sits below → After: `Capsule().stroke(AppColors.borderDefault)` with `AppColors.textSecondary` labels; spectrum stays on Start.
- [rhythm] Before: empty-state icon at `AppFonts.displayHero` (64pt) (SessionBuilderView.swift:284-287) — twice the size of every other empty-state icon → After: `AppFonts.scoreDisplay` (32).

### 12. Desire Map rater
**Working:** Depth-push question transitions synced to rising stars, the phyllotaxis star sky that only remembers enthusiasm, privacy footers on every screen, and mirror groups on canonical glass with emotion hairlines — the flow feels private and celestial without preciousness.

**Findings:**
- [motion] Before: `_ChartedLine` animates with raw inline curves — `.easeOut(duration: 0.45)`, `.easeInOut(duration: 0.35)`, `.easeOut(duration: 0.35)` (DesireMapView.swift:805-820) — while `AppAnimation.desireHesitantSketch` (4.2s, documented as the loop for exactly this) goes unused, and the one-shot never restarts, so the spec's "lines draw partway, pull back, and restart — never locking" state doesn't actually happen → After: drive a repeating sketch loop from `AppAnimation.desireHesitantSketch` with per-line phase offsets; express the sub-beats as fractions of that token.
- [color] Before: progress track base is raw `Color.white.opacity(0.08)` (DesireMapView.swift:377) → After: `Capsule().fill(AppColors.borderDefault)`.
- [depth] Before: readyBar hand-rolls its chrome — magenta/purple gradient fill at raw 0.12/0.18 plus a 0.45 stroke (DesireMapView.swift:605-633) — ten lines above `_MirrorGroup` rows using the canonical `.vaylGlassCard(accent:)` → After: `.vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.md)` on the readyBar content.

### 13. Desire Reveal
**Working:** The three-beat ceremony (free star → locked teasers → paywall) with tap-anywhere advance is confident storytelling; the locked rows' blur-only treatment with the hero row legible — and the explicit refusal to repeat lock icons — is real restraint.

**Findings:**
- [color — legibility floor] Before: "N more aligned desires" renders in raw `Color.white.opacity(0.18)` (DesireRevealView.swift:496-499) — below even `textMuted` (0.20), on load-bearing copy → After: `AppColors.textTertiary`.
- [color] Before: the ✦ marks and hairlines rebuild inline cyan→magenta LinearGradients three times (DesireRevealView.swift:245-249, 283-287, 294-301) → After: `.foregroundStyle(AppColors.spectrumText)` / `.fill(AppColors.spectrumText)` — the token exists for exactly this.
- [color] Before: locked-row text is raw `Color.white.opacity(0.30)` (DesireRevealView.swift:531-532) → After: `AppColors.textTertiary` (0.38); the 5pt blur already carries "locked".
- [rhythm] Before: the same spectrum-hairline motif is 56pt wide in the revealed caption (line 294-301) and 60pt in the locked section (line 499-506) → After: one shared 56pt constant for both.

### 14. Settings (+ six sub-sheets)
**Working:** The presentation grammar is honored to the letter (no NavigationStack; every sub-screen a sheet through the shared shell); glass cards + lavender `SettingsSectionLabel` + the gradient name header make Settings feel like the same room as the rest of the app, and the dark-only Appearance row is honestly labeled "Dark only · Act 1".

**Findings:**
- [color] Before: the name header and `spectrumBadge` rebuild the cyan→purple→magenta LinearGradient inline (SettingsView.swift:163-170, 180-186) → After: `.foregroundStyle(AppColors.spectrumText)`.
- [rhythm] Before: badges use raw `.padding(.vertical, 5)` (SettingsView.swift:187, 201) → After: `AppSpacing.xs`.
- [emotional fit & restraint] Before: the non-Core membership card stacks three chromes — a spectrum-tinted gradient fill + `vaylGlassCard` + the blurred `premiumHairline` glow (SettingsView.swift:273-288) — making the upsell the loudest object in a utility room → After: drop the gradient fill layer; keep glass card + hairline, matching the visual weight of the Core confirmation card.
- [hierarchy] Before: the close ✕ lives inside the ScrollView content (SettingsView.swift:43-56, 140-160), so the modal's exit scrolls off-screen → After: pin the header row with `.safeAreaInset(edge: .top)` (content scrolls under it) so the exit is always reachable.
- [hierarchy — honesty] Before: the About rows (Privacy policy / Terms / Support) are `Button {}` with empty actions but full nav-row styling (SettingsView.swift:485-505) → After: wire Privacy/Terms to the existing `SafariView` + `LegalDoc` (already used by Paywall and SignIn) and remove Support until it has a destination.

### 15. Pairing
**Working:** Complete state coverage (generating / waiting / linked / error / expired), and the static "Sent 2 days ago" caption replacing a live countdown is exactly the quiet-room register. The code display gets a proper hero treatment.

**Findings:**
- [dark-only contract] Before: both views read `@Environment(\.colorScheme)` and branch on `isLight` (PairingInviteView.swift:31-32, 149, 197, 207; PairingJoinView.swift:31-32, 152, 176) — a V1 hard ban ("No `@Environment(\.colorScheme)` checks in Views") → After: delete the environment + all ternaries; keep the dark-side tokens (`modalBackground` pills, `whisperFill` code card, `textTertiary` footer).
- [depth] Before: "Try Again" and "Generate new code" are stock `.buttonStyle(.borderedProminent)` (PairingInviteView.swift:282-288, 315-322) — system chrome inside a branded ceremony → After: `VaylButton(label:)` for both.
- [motion] Before: the waiting pill breathes on `AppAnimation.cardBreathe` (PairingInviteView.swift:151-152) — a token documented as OB-canvas-exclusive card breathe — while a ProgressView spinner runs inside it, doubling the waiting signal → After: drop the spinner; breathe the pill via `.ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true), value:)`.
- [depth] Before: a bespoke one-Ellipse atmosphere (PairingInviteView.swift:337-355) instead of the app-wide background language → After: `AppColors.void` + `OnboardingAtmosphere(config: .stat)` like every other surface.

### 16. Paywall
**Working:** The most carefully art-directed sheet in the app — GlowOrb bloom tracking the hook, spectrum bullets with cascading shimmer, ViewThatFits accessibility backstop, wired legal trio, and "covers both of you, your partner pays nothing" is honest, warm selling.

**Findings:**
- [typography] Before: "Explore with less guesswork" is `AppFonts.body(18, weight: .bold)` uppercased in `spectrumPurple` (PaywallSheet.swift:177-183) — a brand-new uppercase voice (the app's uppercase register is 11pt overline) → After: `AppFonts.overline` + `.tracking(1.5)` in `AppColors.textSectionLabel`, or keep the size and drop the uppercase via `AppFonts.cardTitleCompact`.
- [hierarchy] Before: bullets render at `body(20, weight: .medium)` (PaywallSheet.swift:206-214) — identical to the subheader (lines 167-171), so the value list doesn't step down from the pitch → After: bullets → `AppFonts.bodyText` (16); the 20pt subheader then leads cleanly.
- [color] Before: details pop-out scrim is raw `Color.black.opacity(0.62)` (PaywallSheet.swift:257) → After: `AppColors.scrimHeavy` — the token documented for "a surface the user is actively inside".

### 17. Sign In
**Working:** One decision on screen; wordmark + tagline + a quiet monochrome Apple button; loading and error states transition on tokens and the legal links open in-app.

**Findings:**
- [depth] Before: a hand-rolled three-RadialGradient atmosphere with raw offsets (SignInView.swift:131-172) — background-language drift from the first screen the user ever sees → After: replace `atmosphereLayer` with `OnboardingAtmosphere(config: .stat).ignoresSafeArea()` so launch, sign-in, and OB share one sky.
- [typography] Before: the Apple logo uses raw `.font(.body.weight(.semibold))` (SignInView.swift:63-64) → After: `AppFonts.ctaLabel`, matching the label beside it.

### 18. Onboarding (StatPhase · NamePhase · ConfirmationPhase · FounderLetterPhase)
**Working:** The crown jewel — near-total token discipline, every feel value annotated FEEL-GATE with rationale, complete reduce-motion paths, and the StatPhase arrival ignition (sweep + bloom + soft haptic as the numeral seats) is cinema with restraint. Confirmation's swipe-right-to-confirm-yourself is the best gesture-as-meaning in the app.

**Findings:**
- [typography] Before: StatPhase's citation ⓘ is raw `.font(.system(size: 23.5, weight: .regular))` (StatPhase.swift:402-404) and the citation source line is a one-off `AppFonts.body(12.5, …)` (line 448-450) → After: ⓘ → `AppFonts.body(24, weight: .regular, relativeTo: .title3)` (rides the 22pt sentence, no `.system` escape); source line → `AppFonts.caption.italic()`.
- [color] Before: citation scrim is raw `Color.black.opacity(0.62)` (StatPhase.swift:160-162) → After: `AppColors.scrimHeavy` (same fix as the paywall pop-out — they're the same pattern).
- [typography] Before: StatPhase empty-state icon is `.font(.system(size: 40))` with a "token pending" comment (StatPhase.swift:268-270) → After: `AppFonts.heroTitle` on the symbol.
- [emotional fit — copy] Before: FounderLetter paragraph 2 — "most relationship conflicts boil down to information asymmetry…" (FounderLetterPhase.swift:84-86) — is the one lecture-toned beat in an otherwise personal letter, and it's what forces the 13pt Menlo floor on sub-700pt screens (lines 63-69) → After: cut paragraph 2 and raise the smallest tier from `founderLetter(13)` to `founderLetter(14)`; three paragraphs breathe, the sign-off stays on-page.

### 19. Splash
**Working:** The sequence doc-block with absolute timings, every beat a named `AppAnimation.splash*` token with a documented reduce-motion crossfade — this is how the whole app's motion should be specified.

**Findings:**
- [typography] Before: wordmark size branches on raw device widths — `if screenW <= 375 { 70 }; if screenW >= 428 { 96 }; return 84` (SplashScreenView.swift:27-31) → After: hoist to `AppLayout.splashWordmarkSize(screenWidth:)` alongside `statHeroSize`, so the brand's largest rendering isn't three literals in a view file.

### 20. One-shot overlays (MapChartedMoment · PendingSessionBanner)
**Working:** MapChartedMoment auto-advances and tap-skips — a moment, never a hostage — and correctly keeps the "waiting" status in the partner pill instead of lingering. PendingSessionBanner is one quiet line with a dismiss; no push-your-partner energy.

**Findings:**
- [motion] Before: MapChartedMoment ships three unchosen copy entrances as a `CaseIterable` enum + two ViewModifiers (`MomentCopyEntrance`, `CopyTransition`, `TitleGlow` — MapChartedMoment.swift:17-30, 127-163) — an undecided design shipping as configuration → After: commit to `.focusResolve` (the on-theme one: clarity emerging from the veil) and delete the enum + both modifiers' branches.
- [color] Before: PendingSessionBanner's 8pt status dot fills with the full `AppColors.spectrumBorder` gradient (PendingSessionBanner.swift:22-24) — three stops across 8pt reads as mud → After: `Circle().fill(AppColors.accentPrimary)`.
- [motion] Before: `.sensoryFeedback(.impact(weight: .light), trigger: isPressed)` with no condition (PendingSessionBanner.swift:55-56) fires the haptic on press AND release — a double tick → After: add the press-only condition `{ _, pressed in pressed }` (the PlayEmptyState/DeckDetailView pattern).

---

**Cross-cutting patterns worth one fix each (recurring in the findings above):** raw `Color.white`/`.black.opacity(…)` in views (Vault, Learn, Reveal, MapUs, rater, scrims → tokens exist for every case); the ad-hoc `display(15)/body(11)` copy pair (MapFieldSheet + PulseFullView → `cardTitleCompact`/`caption`); sheet titles at `sectionHeading` instead of `screenTitle` (Vault, Builder); inline spectrum LinearGradients where `AppColors.spectrumText/spectrumBorder` exist (Settings, Reveal, PulseCheckIn); and `AppSpacing.x + n` micro-arithmetic (Vault, MapRecord, PlayView) — settle on the grid.

---

## Orchestrator Verification Log

**[VERIFIED: Subagent C — Phase 4]** All 20 surfaces from the Phase 2 inventory are covered, each with a "Working" note and findings. Every finding is a concrete before→after: the before cites file:line and the current token/value; the after names a real token (`AppFonts.cardTitleCompact`, `AppColors.textAccent`, `AppAnimation.auraBreathe`, `.vaylGlassCard(accent:)`) or a precisely described change. No vague language detected (no "improve/polish/consider" findings). Non-visual dimensions are represented: emotional-fit findings (Vault upsell, care-sheet emoji, "Purchase Lifetime Access" voice), a product-principle catch (Learn archetype pills = the banned assessment pattern), and data-honesty catch (PulseFullView fabricated partner coordinate). States beyond happy path were judged (Home router loading/error, airlock failure, empty states, locked/paywall states). Output accepted; Phase 5 may begin.

---

# Subagent D — Cross-Surface Coherence (Phase 5)

## Phase 5 — Cross-Surface Coherence

### Axis 1: Headers & mastheads

**The masthead treatment is consistent by copy-paste, not by token — and the one tab that uses a token is the one that drifts.** Three tabs hand-build the identical constructor: Home `AppFonts.display(40, weight: .bold, relativeTo: .largeTitle)` (HomeDashboardView.swift:571, "VAYL."), Play the same (PlayMastheadView.swift:20, "Cards.", with a comment claiming "Consistent header treatment across tabs"), Map the same (MapView.swift:253, name toggle). Learn alone uses a named token — `AppFonts.heroTitle` (42) at LearnView.swift:64 — so it renders 2pt larger with heroTitle's semibold instead of bold. The de facto masthead spec exists only as three duplicated ad-hoc calls; `AppFonts` has no `tabMasthead` token to hold it.

**Sheet/cover titles sit at four different tiers with no rank rule** (consolidating Phase 4's Vault/Builder finding into the full set): `sectionHeading` (20) — VaultSheet.swift:30, SessionBuilderView.swift:68, DesireMapListSheet.swift:101, FindingDetailView.swift:27; `screenTitle` (24) — ResearchDatabaseView.swift:56, SettingsView.swift:163; ad-hoc `display(22, .bold, relativeTo: .title2)` — PulseFullView.swift:111 (a fourth size invented for the interior masthead grammar); ad-hoc `display(38)` / `display(30)` — PaywallSheet.swift:163, 232. Nothing maps "how immersive is this surface" to a title tier.

**NEW — the settings entry exists on exactly one tab, against the code's own contract.** `AppTab.swift:7` promises a "gear on every tab" and SettingsComponents.swift:7 calls `SettingsGearButton` "the single settings entry, shared by every tab header" — but the only call site is MapView.swift:204. Home reaches Settings indirectly (HomeRouterView.swift:249, 260 via callbacks); Play and Learn have no path to Settings at all (grep `settingsPresented`: zero hits in either feature). Meanwhile Home ships a *duplicate* gear component — the private `SettingsCogButton` (HomeDashboardView.swift:836-859, spectrum-tinted, fake press via `asyncAfter(0.12)`) — that opens a *different* sheet (session settings). Same glyph, two components, two behaviors, three tabs with no exit to Settings.

**Masthead accessory grammar differs per tab with no rule:** Home = wordmark + PartnerChip (HomeDashboardView.swift:565-591, no subtitle); Map = name + caption subtitle + gear (MapView.swift:174-205); Learn = title + caption subtitle + shimmer "Resources" capsule (LearnView.swift:60-86); Play = bare wordmark, nothing else (PlayMastheadView.swift:16-23).

### Axis 2: Spacing rhythm

**NEW — two parallel, contradictory spacing systems, one of them dead.** AppLayout.swift:126-159 defines a "Standard Screen Spacing" block — `screenHPad` 18 ("Applied to the outer ScrollView or VStack container of every screen"), `screenVPad` 20, `cardHPad` 16, `cardVPad` 14, `cardGap` 10, `sectionGap` 24 — with the warning "Do not override these values per-screen." Actual adoption: `screenHPad` has ONE call site in the entire app (ProjectedTextView.swift:68, OB); `screenMargin`/`ctaHorizontalMargin` appear only in StatPhase.swift:115, 147, 168; `cardGap`/`sectionGap`/`cardHPad`/`cardVPad` have **zero** feature call sites. Every real screen edge uses `AppSpacing.lg` (24) instead: PlayView.swift:71/78, MapView.swift:100, LearnView.swift:34, SettingsView.swift:54, HomeDashboardView.swift:334, SignInView.swift:77. The token file's documented screen-edge margin (18) and the shipped one (24) disagree by 6pt, and the doc is the lie.

**The scale is missing its 10 and 12 steps, so three composition idioms coexist for the same row rhythm:**
- `AppSpacing.sm + 2` (=10): VaultDesireSection.swift:126, 159; MapRecord.swift:121
- `AppSpacing.sm + AppSpacing.xxs` (=10): PlayView.swift:205; AirlockView.swift:225
- `AppSpacing.sm + AppSpacing.xs` (=12): SettingsComponents.swift:59, 80, 118, 133, 161; SettingsCompositionView.swift:32, 45
- plus off-grid `xs + 1` (=5): VaultAgreementsSection.swift:91, EventEntryEditor.swift:126, MeCardSheet.swift:126, VaultDesireSection.swift:216, 276; and `xxs + 1` (=3): FlavorVisuals.swift:69, VaultDesireSection.swift:139.

Net effect: Settings rows breathe at 12, Vault rows at 10, Play's retry banner at 10 — equivalent list structures on three private grids, all built by arithmetic the token file never sanctioned.

**Sheet interior margins split md/lg with no rule:** Session Builder and ResearchDatabase content sits at `md` 16 (SessionBuilderView.swift:92-274; ResearchDatabaseView.swift:74, 89, 114) while Vault, Settings, and DesireMapListSheet sit at `lg` 24 (SettingsView.swift:54; DesireMapListSheet.swift:53; MapPrimitives.swift:64).

### Axis 3: Spectrum discipline

**The semantic accent layer exists and nobody uses it.** `AppColors.textAccent` has **4** call sites app-wide (BreathGuide.swift:36, AirlockView.swift:202, 205, HomeLexicon.swift:388) against **201** raw `spectrumCyan/Purple/Magenta` uses across 50+ feature files. The de facto rule is "grab an anchor color," which is why Phase 4 kept finding raw cyan on links (GettingStartedPathView.swift:104, MapPulseHero.swift:72) — those aren't isolated slips, they're the system.

**A real hue-semantics rule exists but is written nowhere:** cyan = Me/private, magenta = Us/shared (MapView.swift:186-190 lens captions; VaultDoorCard/MapUsPulseCard magenta; Desire rater cyan→magenta arc), plus Learn's three-hue sectioning (cyan quizzes / purple research / magenta hub). Because it's unwritten, it collides with arbitrary anchor grabs (Paywall's purple uppercase hook PaywallSheet.swift:177-183, Learn segment tint).

**Full-gradient-on-tiny-elements is systemic — six sites, not the two Phase 4 caught:** HomeDashboardView.swift:771 (18pt count badge), PendingSessionBanner.swift:23 (8pt dot), **NEW** SessionLobbyView.swift:57-59 (9pt waiting dot), **NEW** GettingStartedPathView.swift:127 (node fill), **NEW** CapacityMirror.swift:42-44 (32×2pt connector), **NEW** SessionPlayerView.swift:434 (capsule fill at 0.32). Three gradient stops cannot resolve below ~20pt; there is no minimum-size rule for the signature.

**NEW — a second primary-CTA voice made of spectrum-filled capsules lives inside the Session cover:** `Capsule().fill(AppColors.spectrumBorder)` as the seal/commit button in WhisperRevealView.swift:110, MirrorRevealView.swift:84, SnapshotRevealView.swift:82, UnspokenSliderView.swift:65, ContextBeatOverlayView.swift:46, plus SessionCloseView.swift:221 (Save) and :250 (toggle) — while `VaylButton` is used two phases earlier in the *same cover* (AirlockView.swift:152) and in the builder (SessionBuilderView.swift:239). PaywallSheet.swift:150, 312 repeats the pattern. The app has two primary-CTA languages and switches mid-flow.

### Axis 4: Motion register

**NEW — the motion-staple system has effectively zero adoption.** Of the three staples in AppMotion.swift (spec 2026-07-03): `.vaylDepth` has **one** call site in the app (OnboardingCanvasView.swift:314); `.vaylCascade(index:shown:)` has **zero**; `.vaylRefusal` has **zero**. Meanwhile the checklist mandates staples for all screen/content transitions. Every entrance in the app is bespoke: Home's 4-beat cascade with raw delays 0.10/0.30/0.62/0.78 (HomeDashboardView.swift:784-787), Play's per-cell stagger `delay(Double(index % 6) * 0.04)` (DeckCellView.swift:60), StatPhase's raw 0.5/1.0/1.4 (StatPhase.swift:302-304). The choreography vocabulary shipped as tokens (`cascadeRow`/`cascadeStagger`, AppAnimation.swift:933, 938) and then nobody was made to use it.

**Entrance inequality between tabs:** Home choreographs four beats; Play staggers cells; Learn, Map (Me layer), Vault, and Settings simply appear (grep: zero `withAnimation…delay` in Learn). Switching tabs feels like switching apps' motion budgets.

**NEW — token arithmetic breaks the 2s loop floor inside the most protected surface.** `.easeInOut(duration: AppAnimation.ambientPulse / 1.5)` = **1.33s** repeating loops at SessionLobbyView.swift:62 and AirlockView.swift:276 — under the hard "nothing repeats under 2s" rule, produced by dividing a compliant token. This is the motion twin of `AppSpacing.sm + 2`: arithmetic on tokens as an unpoliced escape hatch (also `ambientDrift * 2.5` SessionAtmosphere.swift:113 — 10s, benign but same idiom).

**Three breathing tempos with no assignment rule:** the personal aura at `auraBreathe` 5.4s (PulseAura.swift:85); most chrome at `ambientPulse` 2s (MapUsPulseCard.swift:250 — Phase 4's 2.7× mismatch — plus RevealCardChrome.swift:39, LocalCardFaceView.swift:84, CardSessionContainerView.swift:168, AirlockView.swift:358, DemoPhase.swift:222); and the 1.33s arithmetic loops above. The calm register degrades monotonically the deeper the user goes into the session flow — backwards from the product's intent.

**Carousel cadence: the register rule lives in one file's private comment.** HomeLexicon.swift:56 — `interval: TimeInterval = 12.0 // slow, ambient dwell (not a ticker)` — is the correct register, stated privately; Learn runs two tickers at 5s and 5.5s (QuizCarouselSection.swift:18, ResearchSection.swift:38). No `ambientDwell` token exists for any of them to share.

### Axis 5: The `display(n)` / `body(n)` escape hatch (NEW as a system finding)

The `AppFonts.display(size:weight:relativeTo:)` constructor appears **~50 times in Features/ with ~24 distinct sizes** — 8, 8.5, 11, 12, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 34, 38, 40, 46, 48, 62, 120 (RevealCardChrome.swift:65, PulseField.swift:220, RitualPills.swift:76, PulseFullView.swift:378, VaultDoorCard.swift:47, ResearchSection.swift:18, MeCardSheet.swift:39, HomeLexicon.swift:273/300/542, PaywallSheet.swift:163…). "Zero raw values in Views" passes grep because every number is laundered through the AppFonts wrapper. This single loophole is the *root cause* of Axis 1's masthead and sheet-title drift, Phase 4's `display(15)/body(11)` pair, and Learn's hand-built section headers. Same disease in letterspacing: **15 distinct `.tracking()` values (0.2 → 7) across Features** with no tracking token at all — the uppercase overline register is canonically tracking-2 only inside `SettingsSectionLabel` (SettingsComponents.swift:37), while Sessions uses 2/3/4/7, Map/Vault use 0.4-1.8, Home uses 1.4-2.5, and GettingStartedPathView.swift:14 uses none.

### Axis 6: Shared-control fragmentation (close buttons, empty states, card chrome)

**NEW — eleven hand-rolled close (✕) buttons, no two identical.** Frame: none / 28 / 30 / 32 / 36pt. Glyph font: `AppFonts.caption` (PlayView.swift:198, DesireMapView.swift:209/365/539, DesireRevealView.swift:104, GettingStartedPathView.swift:19, SettingsView.swift:151), `body(13, .semibold)` (DeckDetailView.swift:110), `buttonLabelSmall` (PendingSessionBanner.swift:38), raw `.system(size: 13, weight: .medium)` (PulseFullView.swift:120, MapPulseHero.swift:299). Color: textTertiary / textMuted / textSecondary / textPrimary. Background: none / `glassFrostPill` / `glassSurface` / `cardBg.opacity(0.55)` / `cardBackground`. The most-touched recurring affordance in the app has five sizes and four color tiers.

**The compliant empty-state component exists and only Map uses it.** `MapEmptyState` (MapPrimitives.swift:43-66) implements the CLAUDE.md spec exactly and serves all six Map/Vault call sites — but Desire Reveal (DesireRevealView.swift:429, icon `screenTitle` 24, headline in textPrimary), the rater (DesireMapView.swift:638), Session Builder (SessionBuilderView.swift:283, icon `displayHero` 64), StatPhase (StatPhase.swift:266, `.system(40)`), and PulseFullView (:150, `.system(28)`) each hand-roll their own, with icon sizes spanning 24-64 and headline colors split textSecondary/textPrimary.

**Three card-chrome systems by neighborhood:** `.themedCard()`/`.vaylGlassCard()` — 26 uses in 11 files, nearly all Map/Vault/Settings/Learn; Home's dashboard cards run on the hand-rolled `HomeWidgetShell` (58 opacity literals, 5-stack shadow, HomeWidgetShell.swift:198-216); Play and Sessions hand-roll per component. The "canonical surface" rule holds on exactly one tab's territory.

---

### Top system fixes (ranked)

1. **Close the `display(n)`/`body(n)` loophole: extend the AppFonts ramp with the ~6 missing named tokens (`tabMasthead` = display 40 bold, `sheetTitle` = screenTitle mapped by rule, `overlineTracked` with baked `.tracking(2)` + uppercase, plus the recurring 15/16/26/28 tiers) and ban ad-hoc size constructors in Features/.** — Repairs: all four tab mastheads (HomeDashboardView.swift:571, PlayMastheadView.swift:20, MapView.swift:253, LearnView.swift:64), every drifted sheet title (VaultSheet.swift:30, SessionBuilderView.swift:68, PulseFullView.swift:111, PaywallSheet.swift:163/232, DesireMapListSheet.swift:101), the `display(15)/body(11)` pair (MapPulseHero.swift:276-286, PulseFullView.swift:375-386), Learn's section headers, the 15-value tracking sprawl, and ~50 constructor call sites. — Highest leverage because it is the *root cause*, not a symptom: Axes 1 and 5 are both downstream of this one hole, it touches every surface in the app, and one lint rule (`display\(\d` in Features/) keeps it fixed forever.

2. **One motion rule: choreography values are named tokens applied through the staples — no arithmetic on animation tokens, entrances via `.vaylCascade`, and a new `ambientDwell` (12s) token for anything that auto-advances.** — Repairs: the 1.33s sub-floor loops in the protected session flow (SessionLobbyView.swift:62, AirlockView.swift:276 — severity: hard-rule violation), Home's four raw cascade delays (HomeDashboardView.swift:784-787), Play's raw stagger (DeckCellView.swift:60), StatPhase's raw delays (:302-304), Learn's ticker carousels (QuizCarouselSection.swift:18, ResearchSection.swift:38 → `ambientDwell`, matching HomeLexicon.swift:56), and the entrance inequality between tabs (Learn/Map/Vault adopt `.vaylCascade` and stop being motion have-nots). — Outranks #3 because it fixes actual register *violations* (frantic pulses where the app promises calm, in its most sacred surface) plus finally gives the shipped-but-orphaned AppMotion system its adopters; the fix is one enforceable rule, not per-screen tuning.

3. **One shared `VaylCloseButton` component (32pt circle, `glassSurface` fill, `borderSubtle` ring, `AppFonts.caption` xmark in `textTertiary`, `PressableCardStyle` — i.e., the existing SettingsGearButton chrome with an ✕) adopted at every dismiss site.** — Repairs: 11 sites across 9 surfaces (PlayView.swift:198, DeckDetailView.swift:110, PulseFullView.swift:120, MapPulseHero.swift:299, DesireMapView.swift:209/365/539, DesireRevealView.swift:104, GettingStartedPathView.swift:19, SettingsView.swift:151, PendingSessionBanner.swift:38), kills two raw `.system()` fonts and the textMuted-on-a-live-control tier in the process, and pairs naturally with fixing the duplicate gear (retire Home's private `SettingsCogButton`, HomeDashboardView.swift:836-859). — Outranks #4 because the exit affordance is touched on every modal by every user; five sizes and four colors on the *same* control is the most user-visible incoherence on this list, and one component erases it.

4. **One spectrum rule written into AppColors: the full gradient (`spectrumBorder`/`spectrumText`) appears only on strokes, display text, and hero surfaces — never on elements under ~24pt (small indicators use `accentPrimary`); interactive/link text always uses `textAccent`; and document the hue semantics (cyan = Me/private, magenta = Us/shared) as the only sanctioned raw-anchor use.** — Repairs: six gradient-on-tiny sites (HomeDashboardView.swift:771, PendingSessionBanner.swift:23, SessionLobbyView.swift:57, GettingStartedPathView.swift:127, CapacityMirror.swift:42, SessionPlayerView.swift:434), the raw-cyan links (GettingStartedPathView.swift:104, MapPulseHero.swift:72), and gives the 201 raw anchor uses a written test to migrate against. — Outranks #5 because it protects the brand's single most valuable asset (the spectrum signature reads as mud exactly where it's most repeated) while #5 is invisible-but-real rhythm hygiene.

5. **Reconcile the spacing system: delete AppLayout's dead "Standard Screen Spacing" block (AppLayout.swift:126-159), add the missing `AppSpacing` step(s) (12; optionally bless 10), and ban arithmetic on spacing tokens.** — Repairs: the 18-vs-24 screen-edge contradiction between AppLayout's docs and every shipped screen, the three composition idioms across ~16 sites (SettingsComponents.swift:59-161, SettingsCompositionView.swift:32/45, PlayView.swift:205, AirlockView.swift:225, VaultDesireSection.swift ×5, MapRecord.swift:121, VaultAgreementsSection.swift:91, EventEntryEditor.swift:126, FlavorVisuals.swift:69), and unifies Settings' 12pt vs Vault's 10pt row rhythm. — Last only because each individual site is low-severity; but it removes a token file that actively lies about being the source of truth, which is the cheapest credibility repair on the list.

---

## Orchestrator Verification Log

**[VERIFIED: Subagent D — Phase 5]** Every finding spans ≥2 surfaces with file:line evidence — nothing here is a single-screen note. All four mandated axes covered plus two additional (the `display(n)` constructor loophole; shared-control fragmentation), and materially new discoveries beyond Phases 3-4 are flagged NEW: the settings gear existing on one tab against the code's own doc, the dead "Standard Screen Spacing" block contradicting shipped margins, zero adoption of the AppMotion staples, token-arithmetic producing 1.33s loops inside the session flow, six (not two) gradient-on-tiny sites, a second spectrum-capsule CTA voice inside the Session cover, and eleven divergent close buttons. Exactly 5 system fixes, ranked with explicit leverage rationale (root-cause first), each naming the surfaces/files it repairs. Output accepted; Phase 6 may begin.

---

# Subagent E — Accessibility (Phase 6)

## Phase 6 — Accessibility

### 6.1 VoiceOver

**Coverage stats** (Features/ + Design/, 251 Swift files): 43 files carry VoiceOver semantic modifiers, 144 total occurrences — `accessibilityLabel` 51, `accessibilityHidden` 43, `accessibilityAddTraits` 20, `accessibilityHint` 14, `accessibilityElement` 13, `accessibilityAction` 5, `accessibilityAdjustableAction` 2, `accessibilityValue` 1, `accessibilitySortPriority` 0. Coverage is strong in Onboarding (StatPhase 13, BuildDeckPhase 10), Pairing (15), Paywall (10), Settings (16), RacetrackTabBar (label + hint + selected trait, `RacetrackTabBar.swift:126-128`) and HoldToLockInRing (`HoldToLockInRing.swift:80-83` — the model pattern: label + hint + `.isButton` + `accessibilityAction` alternative). **Two entire features have zero VoiceOver semantics: Learn (0 modifiers in any file) and Desire Map (0 across all 9 component files — only `reduceMotion` environment reads).** Verified passes worth recording: the safe word is a real one-tap `Button` with a full label (`SessionPlayerView.swift:398-416`), `PulseAura.swift:89` is `accessibilityHidden(true)`, DeckBeginCeremony exposes "Open deck" with an `accessibilityAction` (`DeckBeginCeremony.swift:33-36`), ConfirmationPhase's swipe-to-confirm has a named action fallback (`ConfirmationPhase.swift:81-82`), PulseCheckInView's back button and step dots are labeled (`PulseCheckInView.swift:105, 159-160`).

| Surface | Issue (file:line) | Fix |
|---|---|---|
| 9 of 11 hand-rolled ✕ close buttons | Icon-only `Image(systemName: "xmark")` with no label — VO reads "xmark" or "button": `PlayView.swift:196-201`, `DeckDetailView.swift:105-116`, `PulseFullView.swift:123-136`, `GettingStartedPathView.swift:26-33`, `MapPulseHero.swift:303-315`, `DesireMapView.swift:212-222` (rater), `:372-377` (progress row), `:546-555` (mirror), `DesireRevealView.swift:100-115`. Only 2 of 11 are labeled (`SettingsView.swift:166`, `PendingSessionBanner.swift:52`) | Add `.accessibilityLabel("Close")` (or context-specific: "Leave rating", "Close reveal") to each — copy the SettingsView pattern |
| Card Session — hold-to-deal | `proceedButton` is a `ZStack` + `DragGesture(minimumDistance: 0)` (`SessionPlayerView.swift:454-458`) — not a button to VO, no label, and a VO/Switch Control user **cannot advance the session at all** | Mirror HoldToLockInRing: `.accessibilityLabel(store.isLastCard ? "Hold to finish" : "Deal next card")` + `.accessibilityAddTraits(.isButton)` + `.accessibilityAction { pendingPrompt = nextPromptText(); commitDeal() }` |
| Card Session — care mark | Icon-only `circle.hexagongrid` button, no label (`SessionPlayerView.swift:364-376`) | `.accessibilityLabel("If you need a beat — pause and care options")` |
| Card Session — fan deck | 5 decorative fan cards each contain a "VAYL" `Text` (`SessionPlayerView.swift:126-135, 157`) — VO reads "VAYL" five times before the real content | `.accessibilityHidden(true)` on the fan `ZStack`; the "N cards left" text (`:137-143`) already carries the information |
| Card Session — care sheet glyphs | Literal glyph Texts `"❚❚"`, `"🤍"`, `"⤼"`, `"✦"` read aloud by VO (`SessionPlayerView.swift:476-495, 508-510`) | In `careOption`, `.accessibilityElement(children: .combine)` on the Button label and `.accessibilityHidden(true)` on the glyph `Text` |
| Airlock | Back chevron unlabeled (`AirlockView.swift:87-95`) | `.accessibilityLabel("Back")` |
| Desire reveal — constellation | Stars are tappable only via `.onTapGesture` (`DesireConstellationView.swift:79`) with zero accessibility elements — VO users cannot open any star detail | Per star: `.accessibilityElement()` + `.accessibilityLabel("\(star.name), \(locked ? "locked" : "shared desire")")` + `.accessibilityAddTraits(.isButton)` |
| Desire reveal — locked teasers | Blurred, paywalled item names are still plain `Text` (`DesireRevealView.swift:541-545`) — **VoiceOver reads the locked content in full**, defeating both the blur and the paywall | `.accessibilityLabel("Locked desire")` on `_LockedPreviewRow` when `!isRevealed` (or `.accessibilityHidden(true)`) |
| Home — session settings cog | `SettingsCogButton` is an `Image` + `.onTapGesture`, not a `Button` (`HomeDashboardView.swift:841-860`) — no button trait, no label | Convert to `Button` (also fixes the tap-contract) + `.accessibilityLabel("Session settings")` |
| Home — partner chip | `.none` invite state is an icon-only shimmer circle, no label (`PartnerChip.swift:17-60`) | `.accessibilityLabel("Invite your partner")`; label the other states with partner name + status |
| Pulse history grid | Color-only dots tappable via `.onTapGesture` (`PulseHistoryGrid.swift:51-57`), no labels — dates/spaces invisible to VO and the data is color-only | `.accessibilityLabel(calloutText(for: i))` + `.accessibilityAddTraits(.isButton)` on each `AuraDot` |
| OB NamePhase — hand-back swipe | The card hand-back is swipe-only (`NamePhase.swift:62-76`); name submit has a Done-key alternative (`NameSequencer.swift:221`) but `waitingForCardReturn` does not — VO users stall mid-onboarding | `.accessibilityAction(named: "Hand the card back") { seq.endHandBack(/* committed value */) }` on the phase container |
| Map charted moment | Dismiss is tap-anywhere `.onTapGesture` (`MapChartedMoment.swift:62`) with no accessible affordance and a 2.8s auto-advance | `.accessibilityAction(named: "Continue") { dismiss() }` + `.accessibilityElement(children: .combine)` on the copy block |
| Learn tab | Entire feature has zero VoiceOver modifiers (mitigated: rows are text `Button`s) | Add labels to any icon-only chrome during the Learn pass; audit finding-type icons (`FindingType+Display.swift`) |

### 6.2 Dynamic Type

**Constructors:** every `AppFonts` token passes `relativeTo:` — `display`/`body` constructors (`AppFonts.swift:28-70`), `statHero` (`:90-92`), `founderLetter` (`:222-229`). No gaps in the token file itself. No `.dynamicTypeSize(...upTo:)` caps exist in production code (the only occurrence is the AX5 *preview* at `PaywallSheet.swift:462`). The paywall is the one surface engineered for AX sizes: `ViewThatFits` with a ScrollView backstop + a dedicated AX5 preview (`PaywallSheet.swift:106, 453-462`) — good.

| Surface | Issue (file:line) | Fix |
|---|---|---|
| Close buttons (2) | Raw `.font(.system(size: 13, weight: .medium))` — does not scale at all (`PulseFullView.swift:129`, `MapPulseHero.swift:308`) | Replace with `AppFonts.caption` (also a token-contract violation) |
| Card Session — dealing card | Prompt text inside fixed `.frame(width: 300, height: 212)` (`SessionPlayerView.swift:270, 284-288`) — clips at AX sizes | Derive from `AppLayout.sessionCardHeight(in:)` and add `.minimumScaleFactor(0.7)` on the prompt overlay |
| Card Session — proceed pill | `"hold to deal"` label in fixed `.frame(height: 44)` capsule (`SessionPlayerView.swift:447`) | `.frame(minHeight: 44)` and let the capsule grow |
| Desire rater — answer pills | Answer text in fixed `.frame(height: 62)` (`DesireAnswerPill.swift:64`); locked rows fixed `height: 46` + `.lineLimit(1)` (`DesireRevealView.swift:545, 550`) | `minHeight:` on both; drop `lineLimit(1)` or add `.minimumScaleFactor(0.8)` |
| Sign-in CTA | `.frame(height: AppLayout.ctaHeight)` — fixed 52pt on a text CTA (`SignInView.swift:69`, token at `AppLayout.swift:167`) | `.frame(minHeight: AppLayout.ctaHeight)` |
| OB card faces | Fixed proportional card geometry (`AppLayout.obCardWidth` = `min(w*0.72, 320)`, height ×1.5) while fonts scale via `relativeTo:` — `minimumScaleFactor(0.75)` (`VaylCardFace.swift:649`) cannot absorb AX5's ~1.9-3.1× growth; card text clips | Lower the floor to 0.5 on card body text, or gate OB card copy at `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` and surface the same copy in the dealer line (which wraps freely) |
| Deck wall cells | Deck titles `.lineLimit(2)` in aspect-ratio cells (`DeckCellView.swift:42`, `DeckCaseView.swift:82`) — truncates at AX sizes | Add `.minimumScaleFactor(0.8)`; acceptable if `DeckDetailView` shows the full title (it does) |
| Founder letter sheet | Fixed `.frame(height: 420)` text region (`FounderLetterSheet.swift:49`) | Wrap in ScrollView or use `maxHeight` |
| Map pulse card | `mapPulseCardHeight` 218 is used as `minHeight` (`MapPulseHero.swift:103`, `MapUsPulseCard.swift:53`) — **pass**, no fix needed | — |

### 6.3 Reduce Motion + Low Power

The two Phase-3 exceptions are confirmed; every one-shot ceremony audited has a correct RM alternative (crossfade/static-complete, never frozen or missing content).

| Surface | Issue (file:line) | Fix |
|---|---|---|
| Home widget orbs | `OrbLayer` body gates on `reduceMotion` only — **no `AppAnimation.lowPower` check** — and drives `TimelineView(.animation)` uncapped at display rate for a slow drift (`HomeWidgetShell.swift:75-93`) | `if reduceMotion \|\| AppAnimation.lowPower { EmptyView() }` (or use `AppAnimation.ambientMotionDisabled`) + `TimelineView(.animation(minimumInterval: 1.0/30))` |
| Fuse timer | `TimelineView(.animation(paused: completed))` uncapped (`FuseTimerView.swift:44`) — a slow border burn never needs 120Hz | `.animation(minimumInterval: 1.0/30, paused: completed)`; reactive one-shot, so no RM gate needed |
| Splash | **Pass** — dedicated `runReducedMotionSequence()` static wordmark + 250ms crossfade to destination (`SplashScreenView.swift:147-153, 676-693`) | — |
| Us reveal ceremony | **Pass** — RM branch swaps layer with `AppAnimation.enter` crossfade, line still shown (`MapView.swift:56-62`) | — |
| MapChartedMoment | **Pass** — RM sets `draw = 1; copyT = 1` (static complete), auto-advance preserved (`MapChartedMoment.swift:84-86, 104-106`) | — |
| DeckBeginCeremony | **Pass** — `skipsMotion` includes LPM (`DeckBeginCeremony.swift:21`) | — |
| Desire reveal | **Pass** — beat holds collapse to 0 under RM (`DesireRevealStore.swift:232`); locked rows use `.reduceMotionSafe` (`DesireRevealView.swift:476, 489`) | — |
| OB deal/flip | **Pass** — ConfirmationPhase shows cards from first frame under RM (`ConfirmationPhase.swift:187-191`); all per-card animations route through RM branches (`:271-297`) | — |
| `.vaylDepth` / arrive | **Pass** — pure `.opacity` under RM (`AppMotion.swift:48`), `.reduceMotionSafe` in VaylPresentation (`VaylPresentation.swift:170-199`). Minor: `UIAccessibility.isReduceMotionEnabled` is read statically per transition build rather than via environment — fine while bodies re-evaluate, but fragile | Optionally thread `@Environment(\.accessibilityReduceMotion)` into the call sites |
| Pulse check-in transitions | Question swap and reveal use `.transition(.opacity.combined(with: .offset/.scale))` un-gated (`PulseCheckInView.swift:214-217, 265`) — residual travel under RM | Gate the `.offset`/`.scale` halves on `reduceMotion`, or use `.vaylDepth(.quiet)` |
| Session idle dim | Raw `.easeInOut(duration: dimmed ? 1.7 : 0.4)` (`SessionPlayerView.swift:65`) — opacity-only so RM-acceptable, but an untokened duration | Move to an `AppAnimation` token |

### 6.4 Contrast

Computed from `VaylPrimitives.swift` hexes; void = `#0A0810`, pageBackground = `#030305`, cardBackground = `#12111A` (dark-only app). AA = 4.5:1 body, 3:1 large (≥18pt regular / ≥14pt bold).

| Token (dark value) | on void | on cardBackground | Verdict |
|---|---|---|---|
| textPrimary `#E8E8F0` | 16.33:1 | 15.37:1 | PASS |
| textBody `white` | 19.90:1 | 18.74:1 | PASS |
| textSecondary `white@0.65` | 8.46:1 | 8.25:1 | PASS |
| textHint `white@0.42` | 4.04:1 | 4.09:1 | **FAIL body** (−0.4); borderline |
| textTertiary `white@0.38` | 3.49:1 | 3.57:1 | **FAIL body** — used at 10-13pt app-wide (captions, eyebrows, "N cards left" `SessionPlayerView.swift:137-143`); only large-text legal |
| textMuted `white@0.20` | **1.76:1** | **1.84:1** | **FAIL everything** (needs 4.5, deficit ~2.6×) |
| textAccent / spectrumCyan `#00C2FF` | 9.63:1 | 9.07:1 | PASS |
| textCardLabel `cyan@0.60` | 3.96:1 | 3.91:1 | **FAIL** at overline 11pt |
| textSectionLabel `purpleBright@0.55` | **2.95:1** | **2.95:1** | **FAIL even large** — used at `SettingsView.swift:154`, `MapPulseHero.swift:119-123` ("The Pulse"), `AirlockView.swift:316`, `PulseCheckInView.swift:151` |
| spectrumPurple `#6C3AE0` | 3.15:1 | **2.96:1** | Large-only on void; **fails on cards** — mid-stop of `spectrumText` gradient dips below AA on any small gradient text |
| spectrumMagenta `#FF006A` | 5.17:1 | 4.87:1 | PASS (barely) |
| safetyAccent gold `#C8960A` (safe word) | 7.41:1 | 6.98:1 | PASS — safe word text is solid |
| destructive `#FF4444` | 5.84:1 | 5.50:1 | PASS |

**Specific findings:**
- **`textMuted` on live controls and meaningful copy (systemic, 28 usage sites):** "History" and "tap to map →" are tappable Buttons at 1.76:1 (`MapPulseHero.swift:126-146`, exact styles at `:133`, `:143`); close buttons at `MapPulseHero.swift:301` and `PulseFullView.swift:122`; the space **descriptor copy in the Pulse reveal** (`PulseCheckInView.swift:233-236`); `MapUsPulseCard.swift:78`; and a full screen title (`HomePulseRail.swift:215`, PulseInfoSheet). Fix: `textSecondary` (8.46:1) for anything tappable or informative; `textMuted` only for true disabled/ghost states per its own doc comment (`AppColors.swift:268-272`).
- **`DesireRevealView.swift:498`** — "N more aligned desires" count in `Color.white.opacity(0.18)` = **1.63:1**. This is real information. Fix: `AppColors.textSecondary`, or `textTertiary` minimum.
- **`DesireRevealView.swift:532`** — locked rows `white.opacity(0.30)` = 2.58:1, additionally 5px-blurred (`:544`). Intentional obscuring, contrast-exempt as decoration — but see the VoiceOver leak in 6.1.
- **Opacity stacking:** `MapView.swift:186-190` lens caption `spectrumMagenta.opacity(0.8)` composites to **3.58:1** at 13pt — FAIL (cyan@0.8 = 6.36:1 passes). The safe-word capsule border `safetyAccent.opacity(0.25)` (`SessionPlayerView.swift:410-412`) = 1.46:1, under the 3:1 non-text minimum (WCAG 1.4.11) — bump to 0.5 (≈3.9:1) so the control boundary survives.
- **Increase Contrast:** `colorSchemeContrast` is read exactly once in the app (`HomeLexicon.swift:37`) — nowhere else. Given tertiary/hint/card-label all hover at 3.4-4.1:1, add an increase-contrast branch **at the token level** in `AppColors.swift` (e.g. tertiary 0.38→0.55, hint 0.42→0.60, sectionLabel 0.55→0.85 when `UIAccessibilityDarkerSystemColorsEnabled`), fixing every call site at once.

### Priority accessibility fixes (top 5)

1. **Make the Card Session driveable by VoiceOver** — the hold-to-deal control is invisible/inoperable to VO (`SessionPlayerView.swift:454-458`); add label + `.isButton` + `.accessibilityAction` mirroring `HoldToLockInRing.swift:80-83`, and label the care mark (`:364-376`). The app's most protected flow is currently its least accessible.
2. **Retire `textMuted` from live UI** — replace with `textSecondary` at `MapPulseHero.swift:133/143/301`, `PulseCheckInView.swift:235`, `PulseFullView.swift:122`, `MapUsPulseCard.swift:78`, `HomePulseRail.swift:215`. Worst contrast deficit in the app (1.76:1 vs 4.5:1) on tappable/meaningful elements.
3. **Label the icon-only chrome sweep** — the 9 unlabeled ✕ buttons, Airlock back chevron, `SettingsCogButton` (also convert to `Button`), and PartnerChip invite. ~12 one-line `.accessibilityLabel` edits.
4. **Desire Map VoiceOver pass** — expose constellation stars as buttons (`DesireConstellationView.swift:79`), stop VO from reading paywalled locked desires (`DesireRevealView.swift:541-545`), label the rater close/progress chrome. The feature currently has zero semantics.
5. **Lift the failing text tokens in one pass at `AppColors.swift`** — `textSectionLabel` 0.55→0.85 alpha, `textCardLabel` 0.60→0.75, `textTertiary` 0.38→0.50, plus an increase-contrast branch keyed off `colorSchemeContrast`/darker-colors; and cap the two runaway `TimelineView(.animation)` surfaces (`HomeWidgetShell.swift:75-93` + LPM gate, `FuseTimerView.swift:44` `minimumInterval`).

---

## Orchestrator Verification Log

**[VERIFIED: Subagent E — Phase 6]** All four mandated categories covered with quantified coverage (144 VoiceOver modifier occurrences across 43 of 251 files; two features at zero), computed WCAG ratios from the actual VaylPrimitives hex values (not estimates), and per-finding surface + file:line + concrete fix. Passes are recorded alongside failures (splash/ceremony RM paths verified good; safe word confirmed accessible and 7.41:1), which protects good work from being "fixed." Highest-severity catches: the hold-to-deal control is inoperable under VoiceOver in the app's most protected flow; VoiceOver reads paywalled locked-desire content through the blur; `textMuted` (1.76:1) is used on tappable controls; `textSectionLabel` fails AA even as large text. Phase-3's two loop-gating exceptions were independently re-confirmed. Output accepted; Phase 8 (Delivery) may begin.

---

# Subagent F — Delivery (Phase 8)

## Phase 8 — Delivery: Prioritized Punch List

Compiled from Phases 2–6 of this document only. Every actionable finding appears exactly once below (deduped across phases, all sources cited); everything else considered lands in "Deliberately leaving as-is." Item format: `- [tag] file:line or surface — what → fix. (source)`.

### P0 (grouped by theme)

**Product-principle & data honesty**
- [taste] Learn / QuizCarouselSection.swift:62-78 — archetype pills ("The Explorer / Architect / Catalyst / Anchor") advertise the CLAUDE.md-banned assessment pattern on the quiz card → replace the four persona pills with the quiz's topic vocabulary (wayfinding words, never assigned identities). (source: Phase 4 §7)
- [taste] PulseFullView.swift:317-327 — never-checked-in partner rendered as a waiting aura at a fabricated field coordinate (energy 0.30 / openness 0.30) that reads as a real reading → park the waiting `PulseCyclingAura` at field center (0.5, 0.5) or move it out of the field to a caption row; keep "not yet." (source: Phase 4 §9)

**Dead affordances**
- [taste] ResearchDatabaseView.swift:65-119 — fake search field (static placeholder Text) and visual-only sort/Filters controls styled as live → remove search + sort/Filters until the filter engine ships; keep topic chips and wire them to filter the list locally. (source: Phase 2, Phase 4 §7)
- [taste] SettingsView.swift:485-505 — About rows (Privacy policy / Terms / Support) are `Button {}` with empty actions and full nav-row styling → wire Privacy/Terms to the existing `SafariView` + `LegalDoc` (Paywall/SignIn pattern); remove Support until it has a destination. (source: Phase 4 §14)
- [taste] Learn / QuizCarouselSection.swift:10 + LearnView.swift:26 — "Take the quiz" CTA is dead: `onSelect` defaults to no-op, no handler passed, no quiz-runner view exists → gate or remove the CTA until a runner ships (runner itself is a product decision). (source: Phase 2)

**Empty / error states**
- [system fix] LearnStore.swift:21,46 + LearnView.swift — `loadError` is set on bundle-load failure and rendered nowhere; a failed load shows header + hollow sections silently, and `refresh()` has no failure surface → add a contract empty/error state (adopt `MapEmptyState` + retry) to LearnView. (source: Phase 2, Phase 3 cat 8)

**VoiceOver — blocked flows and leaks**
- [system fix] SessionPlayerView.swift:454-458 — hold-to-deal is a ZStack + DragGesture: invisible and inoperable to VoiceOver/Switch Control; a VO user cannot advance the session → mirror HoldToLockInRing.swift:80-83: `.accessibilityLabel` + `.isButton` + `.accessibilityAction { commitDeal() }`. (source: Phase 6.1)
- [system fix] SessionPlayerView.swift:364-376 — care mark is an icon-only `circle.hexagongrid` button with no label → `.accessibilityLabel("If you need a beat — pause and care options")`. (source: Phase 6.1)
- [system fix] DesireConstellationView.swift:79 — constellation stars tappable only via `.onTapGesture`, zero accessibility elements; VO users cannot open any star detail → per star: `.accessibilityElement()` + label ("\(name), locked/shared desire") + `.isButton`. (source: Phase 6.1)
- [system fix] DesireRevealView.swift:541-545 — VoiceOver reads paywalled locked-desire names in full through the blur, defeating blur and paywall → `.accessibilityLabel("Locked desire")` (or hidden) on `_LockedPreviewRow` when not revealed. (source: Phase 6.1)
- [system fix] NamePhase.swift:62-76 — card hand-back is swipe-only with no VO alternative; VO users stall mid-onboarding → `.accessibilityAction(named: "Hand the card back")` on the phase container. (source: Phase 6.1)
- [system fix] AirlockView.swift:87-95 + PartnerChip.swift:17-60 — unlabeled icon-only chrome (back chevron; invite shimmer circle) → `.accessibilityLabel("Back")` / `.accessibilityLabel("Invite your partner")` + labeled partner states. (source: Phase 6.1)

**Contrast floor**
- [system fix] AppColors.swift — failing text tokens app-wide: `textSectionLabel` 2.95:1 (fails even large), `textCardLabel` 3.96:1, `textTertiary` 3.49:1, `textHint` 4.04:1 → lift at the token level (sectionLabel 0.55→0.85, cardLabel 0.60→0.75, tertiary 0.38→0.50, hint 0.42→0.60) and add an increase-contrast branch keyed off darker-system-colors — one file fixes every call site. (source: Phase 6.4)
- [system fix] `textMuted` (1.76:1) on live controls and meaningful copy, ~28 sites — MapPulseHero.swift:126-146 (tappable "History"/"tap to map →"; also delete the redundant "tap to map →" per Phase 4), PulseCheckInView.swift:233-236 (the reveal's payoff descriptor), PulseFullView.swift:122, MapUsPulseCard.swift:78, HomePulseRail.swift:215, DeckDetailView.swift:98-102 (section labels → `textSectionLabel`) → `textSecondary` for anything tappable/informative; reserve `textMuted` for true disabled/ghost per its own doc comment. (source: Phase 4 §3/§4/§8, Phase 6.4)
- [taste] DesireRevealView.swift:496-499 — "N more aligned desires" in raw `white.opacity(0.18)` = 1.63:1 on load-bearing copy → `AppColors.textSecondary` (`textTertiary` minimum). (source: Phase 4 §13, Phase 6.4)

**Motion register — hard violations**
- [system fix] SessionLobbyView.swift:62 + AirlockView.swift:276 — `ambientPulse / 1.5` = 1.33s repeating loops, under the hard 2s floor, inside the most protected flow → use full `ambientPulse` (or `auraBreathe`); ban arithmetic on animation tokens. (source: Phase 5 axis 4)

**Loop gating**
- [system fix] HomeWidgetShell.swift:75-93 — ambient orb `TimelineView(.animation)` gated on Reduce Motion only (no Low Power gate) and uncapped at display rate for a slow drift → gate on `AppAnimation.ambientMotionDisabled` + `minimumInterval: 1/30`. (source: Phase 3 cat 7, Phase 6.3)

**Component consolidation — the close button**
- [system fix] Eleven divergent hand-rolled ✕ buttons, 9 unlabeled to VO, 2 on non-scaling raw `.system(size: 13)` fonts — PlayView.swift:196-201, DeckDetailView.swift:105-116, PulseFullView.swift:120-136, MapPulseHero.swift:299-315, DesireMapView.swift:209/365/539, DesireRevealView.swift:100-115, GettingStartedPathView.swift:26-33, SettingsView.swift:151, PendingSessionBanner.swift:38 → one `VaylCloseButton` (32pt circle, `glassSurface` fill, `borderSubtle` ring, `AppFonts.caption` xmark in `textTertiary`, `PressableCardStyle`, built-in `.accessibilityLabel("Close")`) adopted at every dismiss site. (source: Phase 3 cat 2, Phase 4 §4/§9, Phase 5 fix 3, Phase 6.1/6.2)

**Contract surfaces**
- [system fix] HomeRouterView.swift:193-221 — loading/error states on the root tab have no void+atmosphere background and use stock `.borderedProminent` (the only stock-system CTA on a root tab) → wrap both states in `AppColors.void` + `OnboardingAtmosphere(config: .stat)`; swap for `VaylButton("Try again")`. (source: Phase 2, Phase 4 §1)

### P1 (grouped by theme)

**Typography escape hatch & ramp**
- [system fix] AppFonts — close the `display(n)`/`body(n)` loophole: ~50 ad-hoc constructor calls with ~24 distinct sizes plus 15 distinct `.tracking()` values across Features/ → extend the ramp with the ~6 missing named tokens (`tabMasthead` = display 40 bold, `sheetTitle`, `overlineTracked` with baked tracking-2 + uppercase, recurring 15/16/26/28 tiers) and ban ad-hoc size constructors in Features/ (lint: `display\(\d`). (source: Phase 5 fix 1/axis 5)
- [system fix] Sheet/cover titles at four unranked tiers — VaultSheet.swift:30, SessionBuilderView.swift:68, DesireMapListSheet.swift:101, FindingDetailView.swift:27 (`sectionHeading`), PulseFullView.swift:111, PaywallSheet.swift:163/232 (ad-hoc) vs ResearchDatabaseView.swift:56, SettingsView.swift:163 (`screenTitle`) → one `sheetTitle` rule mapping immersion to tier; Vault + Builder → `screenTitle` now. (source: Phase 4 §6/§11, Phase 5 axis 1)
- [system fix] Tab mastheads consistent only by copy-paste — HomeDashboardView.swift:571, PlayMastheadView.swift:20, MapView.swift:253 hand-build `display(40, .bold)`; LearnView.swift:64 drifts to `heroTitle` (42) → all four adopt the new `tabMasthead` token. (source: Phase 4 §7, Phase 5 axis 1)
- [system fix] Raw font sweep (~40 sites) — PulseFullView.swift:151/270/368 (aura labels → `label`; empty icons → `screenTitle`), VaultDesireSection.swift ×6, VaultAgreementsSection.swift:45, VaultLogSection.swift:52, LearnSegmented.swift:34, ResourcesOverlayView.swift:18, ContentHubSection.swift:224, ResearchDatabaseView.swift:129, FindingDetailView.swift:81, MapPrimitives.swift:51, FlavorVisuals.swift:62/83, PartnerChip.swift ×4 + PartnerChipExpand.swift ×6, RitualPills.swift:72, PulseField.swift:241, SignInView.swift:64 (→ `ctaLabel`), RacetrackTabBar.swift:108 + CardBackView.swift:171 (`Font.custom` bypass → `AppFonts.body(…)`), ScoreRing.swift:53/62, ScreenshotProtectionModifier.swift:19, OnboardingProgressBar.swift:1156, OnboardingFooter.swift:17, PartnerAvatarView.swift:22 → AppFonts tokens throughout. (source: Phase 3 cat 2, Phase 4 §9)
- [system fix] MapPulseHero.swift:276-286 + PulseFullView.swift:375-386 — the ad-hoc `display(15)`/`body(11)` copy pair (11pt body prose below the caption floor) → `AppFonts.cardTitleCompact` + `AppFonts.caption`, fixed together. (source: Phase 4 §4/§9)
- [system fix] StatPhase.swift:402-404 + :448-450 — citation ⓘ raw `.system(size: 23.5)` and one-off `body(12.5)` source line → `AppFonts.body(24, .regular, relativeTo: .title3)` + `AppFonts.caption.italic()`. (source: Phase 3 cat 2 exception, Phase 4 §18)
- [system fix] GettingStartedPathView.swift:14-17 — "Begin together" overline missing tracking/uppercase, unlike every other overline → `.tracking(1.5)` + `.textCase(.uppercase)` (or the new `overlineTracked`). (source: Phase 4 §2)
- [system fix] HomeDashboardView.swift:260-262 — deck count "N / M explored" metadata in `bodyMedium` → `AppFonts.caption`, same `textTertiary`. (source: Phase 4 §1)
- [system fix] VaultDoorCard.swift:59-61 — "Open ›" as weight-modified `caption.bold()` → `AppFonts.buttonLabel`, same magenta. (source: Phase 4 §5)
- [taste] PaywallSheet.swift:177-183 — "Explore with less guesswork" as a brand-new 18pt bold uppercase voice in `spectrumPurple` (which also fails AA on cards, 2.96:1) → `AppFonts.overline` + tracking in `textSectionLabel`, or keep size and drop uppercase via `cardTitleCompact`. (source: Phase 4 §16, Phase 6.4)
- [taste] PaywallSheet.swift:206-214 — bullets at `body(20, .medium)` identical to the subheader, so the value list doesn't step down → bullets → `AppFonts.bodyText` (16). (source: Phase 4 §16)

**Spectrum & color discipline**
- [system fix] AppColors — write the spectrum rule: full gradient (`spectrumBorder`/`spectrumText`) only on strokes, display text, hero surfaces, never under ~24pt (small indicators use `accentPrimary`); interactive/link text always `textAccent` (currently 4 uses vs 201 raw anchors); document hue semantics (cyan = Me/private, magenta = Us/shared). Repairs the six gradient-on-tiny sites — HomeDashboardView.swift:767-772 (18pt badge), PendingSessionBanner.swift:22-24 (8pt dot), SessionLobbyView.swift:57-59, GettingStartedPathView.swift:127, CapacityMirror.swift:42-44, SessionPlayerView.swift:434 — and the raw-cyan links GettingStartedPathView.swift:104-107, MapPulseHero.swift:72-77 → `textAccent`. (source: Phase 4 §1/§2/§4/§20, Phase 5 fix 4)
- [system fix] Inline spectrum LinearGradients rebuilt where tokens exist — SettingsView.swift:163-170/180-186, DesireRevealView.swift:245-249/283-287/294-301 → `.foregroundStyle(AppColors.spectrumText)` / `.fill(AppColors.spectrumText)`. (source: Phase 4 §13/§14)
- [system fix] Raw color sweep in feature views (16 sites) — LearnView.swift:75-78 + ResearchSection.swift:26-28 (pill whites → `textBody`), GettingStartedPathView.swift:129 (checkmark → `textBody`), VaultAgreementsSection.swift:88-92 + VaultDesireSection.swift:214-217/274-277 (capsule CTAs → `textBody`), EventEntryEditor.swift:145, FlavorVisuals.swift:67, MapUsPulseCard.swift:226-233 (seam/rim → `borderActive`), DesireAnswerPill.swift:90, DesireMapView.swift:377 (progress track → `borderDefault`) + :785, DesireRevealView.swift:571, PulseAura.swift:165/169, DemoPhase.swift:270 → tokens. (source: Phase 3 cat 1, Phase 4 §2/§5/§6/§12)
- [system fix] StatPhase.swift:160-162 + PaywallSheet.swift:257 — raw `Color.black.opacity(0.62)` scrims (same pattern twice) → `AppColors.scrimHeavy`. (source: Phase 4 §16/§18)
- [system fix] MapUsPulseCard.swift:71-75 — "THE PULSE · TOGETHER" header shouts in full `spectrumMagenta` while its Me twin whispers → `AppColors.textSectionLabel`; lens caption/tint carries the magenta. (source: Phase 4 §5)
- [system fix] MapView.swift:186-190 — lens caption `spectrumMagenta.opacity(0.8)` composites to 3.58:1 at 13pt → raise to full opacity or a brighter anchor so the composite clears 4.5:1. (source: Phase 6.4)
- [system fix] SessionPlayerView.swift:410-412 — safe-word capsule border `safetyAccent.opacity(0.25)` = 1.46:1, under the 3:1 non-text minimum → bump to 0.5 (≈3.9:1). (source: Phase 6.4)
- [taste] DeckDetailView.swift:52-57 — "WHEN TO USE" prose in translucent accent cyan italic → `AppFonts.bodyText.italic()` + `textSecondary`; accent goes on the label via `textCardLabel` if wanted. (source: Phase 4 §3)

**Motion register**
- [system fix] Adopt the shipped-but-orphaned motion staples (`.vaylDepth` 1 call site, `.vaylCascade`/`.vaylRefusal` zero) — Home's four raw cascade delays (HomeDashboardView.swift:784-787 → two beats on a named `homeCascadeBeat`), Play's raw stagger (DeckCellView.swift:60 → `cascadeStagger`), StatPhase.swift:302-304 raw delays; Learn/Map/Vault/Settings adopt `.vaylCascade` so tabs stop having unequal motion budgets. (source: Phase 4 §1, Phase 5 fix 2/axis 4)
- [system fix] Mint an `ambientDwell` (12s) token — Learn's two ticker carousels at 5s/5.5s (QuizCarouselSection.swift:18, ResearchSection.swift:38) → 12s, phase-offset; HomeLexicon.swift:56's private `12.0` adopts the token. (source: Phase 4 §7, Phase 5 axis 4)
- [system fix] Breathing-tempo rule — MapUsPulseCard.swift:248-253 breathes at 2s while the personal aura it mirrors breathes at `auraBreathe` 5.4s → `.easeInOut(duration: AppAnimation.auraBreathe)`; document the aura-vs-chrome tempo assignment. (source: Phase 4 §5, Phase 5 axis 4)
- [system fix] Raw curve/duration sweep (~45 sites) — CardCarousel.swift:351/700 springs at damping 0.6/0.7 (hard-rule breach outside OB) + :119/206/402/704/737/750 raws; VaylButton.swift:68/97/111 (→ `fast`/`exit`); SessionPlayerView.swift:65 idle dim (→ `cinematicFade`/`enter` or a minted `idleDim`); SessionAtmosphere.swift:106; VaylCardFace.swift:483; AtmosphericGhostDeck.swift:38/52; ConversationCard.swift:86/266; HolographicText.swift:214-215; PulseField.swift:296 (also a sub-2s loop → ≥2s); AppOBEnums.swift:182/189 (animation constants outside Theme/ → move to AppAnimation); OnboardingProgressBar.swift:604 → AppAnimation tokens throughout. (source: Phase 3 cats 4/7, Phase 4 §10, Phase 6.3)
- [system fix] PulseCheckInView.swift:214-217, 265 — question-swap/reveal transitions keep `.offset`/`.scale` travel under Reduce Motion → gate the moving halves on `reduceMotion` or use `.vaylDepth(.quiet)`. (source: Phase 6.3)
- [system fix] SplashScreenView.swift:27-31 — wordmark size branches on three raw device-width literals → hoist to `AppLayout.splashWordmarkSize(screenWidth:)` beside `statHeroSize`. (source: Phase 4 §19)
- [taste] DesireMapView.swift:805-820 — `_ChartedLine` raw inline curves while `desireHesitantSketch` (4.2s, documented for exactly this) goes unused, and the spec'd draw-pull-back-restart loop never actually loops → drive a repeating sketch loop from the token with per-line phase offsets. (source: Phase 3 cat 4, Phase 4 §12)
- [taste] PairingInviteView.swift:151-152 — waiting pill breathes on OB-exclusive `cardBreathe` while a ProgressView spinner doubles the waiting signal → drop the spinner; breathe via `.ambientAnimation` on `ambientPulse`. (source: Phase 4 §15)
- [taste] MapChartedMoment.swift:17-30, 127-163 — three unchosen copy entrances shipping as a CaseIterable enum + two modifiers → commit to `.focusResolve` and delete the enum + branches. (source: Phase 4 §20)

**Component consolidation**
- [system fix] One primary-CTA voice — spectrum-filled capsules inside the Session cover (WhisperRevealView.swift:110, MirrorRevealView.swift:84, SnapshotRevealView.swift:82, UnspokenSliderView.swift:65, ContextBeatOverlayView.swift:46, SessionCloseView.swift:210-224 "Save" + :250), PaywallSheet.swift:150/312, PulseCheckInView.swift:242-263 hand-rolled "Done", PairingInviteView.swift:282-288/315-322 stock `.borderedProminent` → `VaylButton` everywhere (or bless one named capsule component); the app currently switches CTA languages mid-flow. (source: Phase 4 §8/§10/§15, Phase 5 axis 3)
- [system fix] Empty-state component adoption — `MapEmptyState` (MapPrimitives.swift:43-66) implements the contract exactly but only Map/Vault uses it; DesireRevealView.swift:429, DesireMapView.swift:638, SessionBuilderView.swift:283-287 (64pt icon → 32), StatPhase.swift:266-271 (`.system(40)` → token), PulseFullView.swift:150/269 (`.system(28)` → token) each hand-roll → adopt (or extract) the shared component. (source: Phase 3 cat 2, Phase 4 §9/§11/§18, Phase 5 axis 6)
- [system fix] Card-chrome consolidation — Home runs on hand-rolled `HomeWidgetShell` (58 opacity literals; 5-stack `.shadow` mixing elevation with glow, HomeWidgetShell.swift:198-216), Play/Sessions hand-roll per component, while `.themedCard()`/`.vaylGlassCard()` holds only on Map/Vault/Settings/Learn → migrate HomeWidgetShell's shadows to `AppElevation.cardShadow` + AppGlows and converge on the two canonical surfaces (or bless a tokenized HomeWidgetShell). (source: Phase 3 cats 3/11, Phase 5 axis 6)
- [system fix] Settings entry — the gear exists on one tab (MapView.swift:204) despite AppTab.swift:7 and SettingsComponents.swift:7 promising it on every tab; Play and Learn have no path to Settings, and Home ships a duplicate private `SettingsCogButton` (HomeDashboardView.swift:836-859 — not a `Button`, fake press via `asyncAfter(0.12)`, unlabeled, opens a different sheet) → put `SettingsGearButton` on all four tabs; retire `SettingsCogButton` (rebuild the session-settings entry as a real labeled `Button` with `PressableCardStyle`). (source: Phase 4 §1, Phase 5 axis 1, Phase 6.1)
- [system fix] HomeDashboardView.swift:209 + PlayHeroView.swift:35 — duplicated bare `191` pedestal drop offsets coupled to CardCarousel's private `cardW = 300` → one shared `DeckPedestal.heroDropY`/AppLayout constant consumed by both. (source: Phase 4 §1)
- [system fix] `.shadow()`-as-glow sweep → AppGlows: DesireStarView.swift:121-122/230-232, SelectablePill.swift:337-351 (7-layer stack), PulseCheckInView.swift:148-155 (step dot), DeckPedestal ×2, DesireMapView ×3, DesireRevealView, DesireAnswerPill, SessionPlayerView ×2, Pulse ×3 → AppGlows modifiers / consolidated glow specs. (source: Phase 3 cat 11, Phase 4 §8)

**Tap contract**
- [system fix] Adopt `PressableCardStyle` as the default in place of `.buttonStyle(.plain)` (64 at-risk sites) — confirmed misses: VaultAgreementsSection.swift:81-82 ("Not now"), PartnerChip.swift:60/106/151/209, GettingStartedPathView.swift:113-114, MapChartedMoment.swift:61-62, PulseFullView.swift:83-129 (haptic but no scale), CredentialEditorSheet ×3, NamePhase, DemoPhase, DeckBeginCeremony (no haptics) → press scale + haptic + action on all. (source: Phase 3 cat 12)
- [system fix] PendingSessionBanner.swift:55-56 — `.sensoryFeedback` without a press-only condition fires on press AND release → add `{ _, pressed in pressed }`. (source: Phase 4 §20)

**Spacing rhythm**
- [system fix] Reconcile the spacing system — delete AppLayout.swift:126-159's dead "Standard Screen Spacing" block (its 18pt screen edge contradicts the shipped `AppSpacing.lg` 24 everywhere), add the missing 12 step (optionally bless 10), ban arithmetic on spacing tokens — repairs ~16 sites: SettingsComponents.swift:59-161, SettingsCompositionView.swift:32/45, PlayView.swift:205, AirlockView.swift:225, VaultDesireSection.swift ×5, MapRecord.swift:121, VaultAgreementsSection.swift:91, EventEntryEditor.swift:126, FlavorVisuals.swift:69. (source: Phase 4 §4/§6, Phase 5 fix 5)
- [system fix] Off-scale literal sweep — SettingsView.swift:187/201 (`5` → `xs`), FindingDetailView.swift:81 (`7` → `xs`), DeckCellView.swift:35/43 (`3`/`6` → `xs`), MapRecord.swift:96/111, PulseHistoryGrid ×2 → grid tokens. (source: Phase 3 cat 3, Phase 4 §3/§4)
- [taste] MapUsLayer.swift:63-71 — Us column mixes three micro-gaps while Me sections breathe at `xl` → one `VStack(spacing: .sm)` + `xl` before the vault door so the lenses share a rhythm. (source: Phase 4 §5)
- [taste] DeckBeginCeremony.swift:38-43 — ceremony hint placed by bare `.offset(y: 200)` → lay out in a `VStack(spacing: AppSpacing.xl)` under the case frame. (source: Phase 4 §3)

**Safe area**
- [system fix] SessionPlayerView.swift:197 — `.padding(.bottom, 150)` hardcoded clearance inside a cover → `.bottomClearance(layout)` / `.stickyBottomCTA`. (source: Phase 3 cats 3/6)

**Dark-only purge (feature + design layers)**
- [system fix] Feature-layer light-mode code — PairingInviteView.swift:31-32/149/197/207, PairingJoinView.swift:31-32/152/176 (`colorScheme` + `isLight` ternaries, a V1 hard ban), ReflectionBannerView.swift (~17 light branches), HomeWidgetShell.swift:174+ (`isLight` param + live `lightSurface` path) → delete the environment reads and every light branch; keep the dark-side tokens. (source: Phase 3 cat 9, Phase 4 §15)
- [system fix] Design-layer light infrastructure — LightModeShimmer.swift (entire light-mode component, actively referenced), SelectablePill.swift:34-35, RacetrackTabBar.swift:11/60-103, OnboardingFooter.swift:11/18, InteractiveField.swift:12/28/36, GlowOrb.swift:13/18, LivingText.swift:12-70, GradientText.swift:12/19, AtmosphericGhostDeck.swift:19-83, OnboardingProgressBar.swift:400-803 (~25 ternaries) → strip `colorScheme` reads and light palettes; delete LightModeShimmer and its call sites. (source: Phase 3 cat 9)

**Dead code / presentation**
- [system fix] PairingSettingsView.swift — orphaned (superseded by SettingsPartnerView) yet carries two raw `.sheet`s (:66/:75), its own NavigationStack against the Settings grammar (:55-56), and `colorScheme` reads (:19-20) → delete the file. (source: Phase 3 cats 5/9)

**Depth & chrome**
- [taste] SignInView.swift:131-172 — hand-rolled three-RadialGradient atmosphere on the first screen the user sees → replace with `OnboardingAtmosphere(config: .stat)` so launch, sign-in, and OB share one sky. (source: Phase 4 §17)
- [taste] PairingInviteView.swift:337-355 — bespoke one-Ellipse atmosphere → `AppColors.void` + `OnboardingAtmosphere(config: .stat)`. (source: Phase 4 §15)
- [taste] DesireMapView.swift:605-633 — readyBar hand-rolls gradient/stroke chrome ten lines above rows on canonical glass → `.vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.md)`. (source: Phase 4 §12)
- [taste] GettingStartedPathView.swift:62-72 — double signature chrome (full-opacity spectrum top bar AND 0.45 spectrum stroke) on one card → keep one accent (drop the bar, or taper it and drop the stroke). (source: Phase 4 §2)
- [taste] SettingsView.swift:273-288 — non-Core membership card stacks three chromes, making the upsell the loudest object in a utility room → drop the gradient fill; keep glass card + hairline. (source: Phase 4 §14)
- [taste] SettingsView.swift:43-56, 140-160 — the modal's close ✕ scrolls off-screen with the content → pin the header row via `.safeAreaInset(edge: .top)`. (source: Phase 4 §14)
- [taste] VaultDesireSection.swift:144-163 — locked-more row's "Unlock the full map" in accent overline shouts an upsell inside the couple's private vault → `AppFonts.caption` in `textAccent`, no overline. (source: Phase 4 §6)
- [taste] SessionBuilderView.swift:96-111 — "Quick start"/"Same as last time" chips wear the full spectrum stroke while the real primary CTA sits below → `borderDefault` stroke + `textSecondary` labels; spectrum stays on Start. (source: Phase 4 §11)
- [taste] SessionLobbyView.swift:44-49 — airlock failure reason styled as a subtitle (`caption` + `textSecondary`) → same size in `AppColors.destructive` so a failed room reads as a state. (source: Phase 4 §10)

**Voice & emotional fit**
- [taste] DeckDetailView.swift:251 — "Purchase Lifetime Access" transactional voice duplicating the paywall's job → `VaylButton("Unlock all decks")`; the PaywallSheet carries the price story. (source: Phase 4 §3)
- [taste] SessionPlayerView.swift:476-495, 508-510 — care sheet mixes a color "🤍" emoji with text glyphs ❚❚ ✦ ◦ ⤼ ✓ on the most protected screen, and VO reads the glyphs aloud → SF Symbols throughout in `textSecondary`/`spectrumMagenta`, `.accessibilityElement(children: .combine)` per option with glyphs hidden. (source: Phase 4 §10, Phase 6.1)
- [taste] GettingStartedPathView.swift:50 — literal 🔒 emoji, the only color-emoji glyph in app chrome → `Image(systemName: "lock.fill")` + text. (source: Phase 4 §2)
- [taste] FounderLetterPhase.swift:84-86, 63-69 — lecture-toned paragraph 2 ("information asymmetry…") forces the 13pt Menlo floor on small screens → cut paragraph 2; raise the smallest tier to `founderLetter(14)`. (source: Phase 4 §18)

**Dynamic Type**
- [system fix] SessionPlayerView.swift:270, 284-288 — prompt text in a fixed 300×212 frame clips at AX sizes → derive from `AppLayout.sessionCardHeight(in:)` + `.minimumScaleFactor(0.7)` on the prompt. (source: Phase 6.2)
- [system fix] SessionPlayerView.swift:447 — "hold to deal" label in a fixed 44pt capsule → `.frame(minHeight: 44)`. (source: Phase 6.2)
- [system fix] DesireAnswerPill.swift:64 (fixed 62) + DesireRevealView.swift:545/550 (fixed 46 + `lineLimit(1)`) → `minHeight:` on both; drop `lineLimit(1)` or add `.minimumScaleFactor(0.8)`. (source: Phase 6.2)
- [system fix] SignInView.swift:69 — CTA fixed at `ctaHeight` 52 → `.frame(minHeight: AppLayout.ctaHeight)`. (source: Phase 6.2)
- [system fix] VaylCardFace.swift:649 + OB card geometry — `minimumScaleFactor(0.75)` can't absorb AX5 growth inside the fixed-proportion cards; text clips → lower the floor to 0.5 on card body text, or gate OB card copy at `…xxxLarge` and surface the same copy in the free-wrapping dealer line. (source: Phase 6.2)

**VoiceOver (non-blocking)**
- [system fix] SessionPlayerView.swift:126-135, 157 — decorative fan cards make VO read "VAYL" five times before content → `.accessibilityHidden(true)` on the fan ZStack; "N cards left" already carries the info. (source: Phase 6.1)
- [system fix] PulseHistoryGrid.swift:51-57 — color-only tappable dots invisible to VO → `.accessibilityLabel(calloutText(for: i))` + `.isButton` per dot. (source: Phase 6.1)
- [system fix] MapChartedMoment.swift:62 — tap-anywhere dismiss with no accessible affordance → `.accessibilityAction(named: "Continue")` + combined copy block (auto-advance already preserved). (source: Phase 6.1)

**Data & state integrity**
- [system fix] PulseFullView.swift:20 — production view defaults `myEntries = PulseEntry.previews`; any future caller omitting the argument ships fake history → default to `[]`. (source: Phase 2, Phase 3 cat 8)
- [taste] SessionPlayerView / SessionSyncCoordinator — no in-player "connection lost" state in the two-device session (reconnect path exists; airlock has transport fallback, the player shows nothing) → design a quiet degraded-connectivity chrome for the player. (source: Phase 2)

### P2 (grouped by theme)

**Motion hygiene (invisible-to-most)**
- [system fix] Choreography timing-literal hoist (~45 `asyncAfter`/`Task.sleep` sites; values unchanged, just named) — CardCarousel ×6, InfiniteCarousel.swift:88, HomeLexicon.swift:409/471, ScreenshotProtectionModifier.swift:55, HomeDashboardView.swift:856, CardMirrorDeal ×12, ThreeCardFanController ×10 (FEEL-GATE annotated), ConfirmationPhase.swift:203-242, CuriosityPhase, GenderPhase.swift:98-100, ConversationCard.swift:351-355, SessionPlayerView.swift:593, SessionCloseView.swift:41, CardSessionContainerView.swift:111, BreathGuide.swift:61, PulseCheckInView.swift:336/364, DeckBeginCeremony.swift:52/56 → AppAnimation tokens per the "no raw durations anywhere" contract. (source: Phase 3 cat 4)
- [system fix] SplashScreenView.swift:622-665 — 8 self-flagged `/* TODO: AppAnimation token */` durations in the one-shot splash → mint the missing splash tokens. (source: Phase 3 cat 4)

**Color / token hygiene**
- [system fix] Design-layer raw color constructors (~50, effect internals) — HolographicShimmer (14), VaylAppIcon (15+, self-admits "no AppColors token"), VaylBorderEffect (4), VaylButton (3), FlameAura (5), LightAuraBloom, SplashScreenView (6), LearnCardStyle.swift:44, SnapshotCardFace.swift:70 → promote to VaylPrimitives or named local render constants. (source: Phase 3 cat 1)
- [system fix] No opacity scale exists in App/Theme/ (661 raw opacity literals in Features+Design have nothing to point at) → mint an opacity token ramp; migrate worst files (HomeWidgetShell 58, TableSurfaceView 20, DeckCaseView 17) opportunistically. (source: Phase 3 cat 3)
- [system fix] HomeLexicon.swift:567-574 — untokenized `36`/`28`/`14` in the offscreen 360×640 share-image render → tokens or documented render constants. (source: Phase 3 cat 3)

**Presentation**
- [system fix] SignInView.swift:124 + HomeLexicon.swift:180 — raw `.sheet` hosting system UI (SafariView / ActivityView) → route through `.vaylSheet` or document a system-browser/share-sheet exception in VaylPresentation. (source: Phase 3 cat 5)

**DEBUG-only (clearly marked)**
- [system fix] **DEBUG-only:** HomeDashboardView.swift:823 + HomeRouterView.swift:375 — `.bottomContentInset(layout)` on tab content (banned by the tab-bar contract) inside `#if DEBUG` tooling → remove; AppShell's inset already reserves it. (source: Phase 3 cat 6)

**Comments & redundancy**
- [system fix] LearnView.swift:36 — stale comment claiming "tab-bar clearance is TabContentWrapper's job" (code is right, comment lies) → fix the comment. (source: Phase 3 cat 6)
- [system fix] VaylApp.swift:56 + SplashScreenView.swift:132 — `.preferredColorScheme(.dark)` in production, triple-redundant with ThemeModifiers:17 and ThemeManager → collapse to one enforcement point. (source: Phase 3 cat 9)

**Spacing / layout rules**
- [taste] Sheet interior margins split `md` 16 (SessionBuilderView, ResearchDatabaseView) vs `lg` 24 (Vault, Settings, DesireMapListSheet) with no rule → pick one and write it down. (source: Phase 5 axis 2)
- [taste] Masthead accessory grammar differs per tab with no rule (Home wordmark+chip, Map name+subtitle+gear, Learn title+subtitle+capsule, Play bare) → define the accessory slots once (pairs with the gear-on-every-tab fix). (source: Phase 5 axis 1)
- [system fix] DesireRevealView.swift:294-301 vs :499-506 — the same spectrum-hairline motif at 56pt and 60pt → one shared 56pt constant. (source: Phase 4 §13)

**Dynamic Type**
- [system fix] DeckCellView.swift:42 + DeckCaseView.swift:82 — deck titles `lineLimit(2)` truncate at AX sizes → add `.minimumScaleFactor(0.8)` (mitigated: DeckDetailView shows the full title). (source: Phase 6.2)
- [system fix] FounderLetterSheet.swift:49 — fixed 420pt text region → ScrollView or `maxHeight`. (source: Phase 6.2)

**Accessibility hygiene**
- [system fix] AppMotion.swift:48 / VaylPresentation.swift:170-199 — `UIAccessibility.isReduceMotionEnabled` read statically per transition build (works, but fragile) → optionally thread `@Environment(\.accessibilityReduceMotion)` into call sites. (source: Phase 6.3)
- [system fix] Learn feature — zero VoiceOver modifiers (mitigated: rows are text Buttons) → label icon-only chrome and audit finding-type icons (`FindingType+Display.swift`) during the Learn pass. (source: Phase 6.1)

### Top 5 highest-leverage refinements

1. **Close the `AppFonts.display(n)`/`body(n)` escape hatch** (Phase 5 fix 1) — the root cause, not a symptom: ~50 laundered constructor calls, 24 phantom sizes, and 15 tracking values are what created the masthead, sheet-title, and copy-pair drift on every surface; ~6 new tokens plus one lint rule fixes it and keeps it fixed.
2. **Lift the contrast floor at the token level in AppColors** (Phase 6.4 + priority fixes 2/5, merged) — `textSectionLabel`/`textCardLabel`/`textTertiary`/`textHint` fail WCAG on every one of their hundreds of call sites, and `textMuted` (1.76:1) sits on live controls; editing one file plus a ~28-site `textMuted` retirement is the largest user-facing legibility gain per line changed in the whole review.
3. **One motion rule: named tokens through the staples, no token arithmetic, `ambientDwell` for auto-advance** (Phase 5 fix 2) — fixes actual hard-rule violations (1.33s loops inside the protected session flow, sub-0.75 springs), equalizes tab entrances, and finally gives the shipped-but-orphaned AppMotion system its adopters via one enforceable rule.
4. **`VaylCloseButton` + the icon-chrome labeling sweep** (Phase 5 fix 3 + Phase 6 fix 3, merged) — the most-touched affordance in the app has five sizes, four color tiers, two non-scaling fonts, and nine unlabeled instances; one component erases visual incoherence, a Dynamic Type failure, and a VoiceOver gap simultaneously.
5. **Write the spectrum rule into AppColors** (Phase 5 fix 4) — the brand's single most valuable asset currently resolves to mud on six sub-24pt elements while the semantic `textAccent` layer sits at 4 uses vs 201 raw anchors; a minimum-size rule + link-token rule + documented hue semantics gives every future accent decision a test. *(Phase 5's fix 5 — spacing reconciliation — is demoted to the P1 list: real, but invisible-to-most hygiene next to these five.)*

### Deliberately leaving as-is

- **SpectrumBulletRow.swift:12** — `Color.white` declared as a specular rendering constant; documented exception stands. (Phase 3)
- **DeckStyle.swift:87-97** — `UIColor(AppColors.…)` used only to interpolate between tokens; compliant in spirit. (Phase 3)
- **PairingInviteView.swift:60-70** — static "Sent 2 days ago" aged-invite caption with no live countdown; deliberate quiet-room register, not a missing feature. (Phase 2, Phase 4)
- **CoupleSessionStore.swift:569, :630** — timing literals in a Store that are network pacing (15s poll, 1s settle), not animation choreography. (Phase 3)
- **DesireRevealView.swift:531-532, :544** — locked-row `white.opacity(0.30)` + 5px blur: intentional paywall obscuring, contrast-exempt as decoration (Phase 6.4); the accompanying VoiceOver leak is fixed at P0. Phase 4's suggested lift to `textTertiary` is superseded by the intentional-obscuring ruling.
- **SafeWordCloseView** — as-designed: neutral landing, no reflection, no stats, zero guilt; safe-word text verified 7.41:1 and one-tap accessible. Do not "fix." (Phase 4, Phase 6)
- **FuseTimerView.swift:44** — uncapped `TimelineView(.animation)` on a reactive one-shot; a burning-fuse spark plausibly needs high frame rate. Borderline: cap to 1/30 only if the motion owner confirms 30fps reads identically. (Phase 3, Phase 6.3)
- **ThemeManager.swift / AppTheme.swift / AppColors.dynamic ignored `light:` params / AppElevation.swift:223-248 + ThemeModifiers.swift:30/45 `colorScheme` branches** — token-level light-mode retention held pending a human decision: hard-purge per the V1 dark-only contract vs retain for the future Dawn mode. Feature/design-layer light *branches* are punch-listed (P1); the token infra is the deliberate open question. (Phase 1, Phase 3 cat 9)
- **MeCardSheet.swift, MeCardCompact.swift, PrismView.swift** — orphaned Me-Card "Seg 3" surfaces with no external call sites; pending a product decision to land or delete. Their internal violations (PrismView colorScheme reads + 48 opacity literals + shadows; MeCardSheet/Compact raw fonts) are not punch-listed individually — fold into the sweeps if kept, delete if not. (Phase 2, Phase 3)
- **Preview/`#if DEBUG` raw values** — OnboardingCanvasView.swift:355-390 DevWrapper (colors, `.padding(.top, 60)`), HomeDashboardView.swift:816-819 grid-toggle colors, DeckSummary.swift:43-52, CandleCardFace.swift:873, DragDebugView/DiagnosticOverlay, ~150 preview-only `.preferredColorScheme(.dark)` — preview/debug-exempt per the Phase 3 scan rules. (The two DEBUG `bottomContentInset` sites are the exception and sit at P2.) (Phase 3)
- **Play tab first-load spinner** — deliberately absent: catalog load is synchronous bundled JSON; `PlayEmptyState` doubles as the error surface. Phase 2 suspicion cleared. (Phase 3 cat 8)
- **Vault per-segment loading indicator** — absent by acceptance: local SwiftData reads are effectively instant; revisit only if sync-refresh gains real latency. (Phase 3 cat 8)
- **SpectrumSparkField.swift:42, MetallicCaseView.swift:313, HolographicShimmer.swift:239** — uncapped but RM+LPM-gated fast specular/particle motion that plausibly needs display rate; accepted with caveat. (Phase 3 cat 7)
- **DesireRevealView.swift:50-53, 63-65** — custom inner sheet host deliberately not `.vaylSheet` (beat-ceremony host); documented intent. (Phase 2)
- **The token-duration loop idiom** — `.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(…)` and kin: sanctioned, not raw values. (Phase 3 cat 4)
- **ProgressRingView.swift:40 (geometric badge) + InteractiveField.swift:20 (emoji icon)** — self-documented intentional font exceptions, left for the human to ratify. (StatPhase's two "exceptions" were overridden by Phase 4 fixes and are punch items.) (Phase 3 cat 2)
- **CardCarousel.swift:393 (`isLight: false` hardcode with compliance comment); HomeLexicon.swift:37 (`colorSchemeContrast` accessibility read) and :479 (dark-scheme write for share render)** — verified non-violations. (Phase 3 cat 9)
- **OB mid-flow resume** — no persisted resume; killing the app restarts OB. Local-only, short, no network/error surface; adding resume machinery fails the humility test for a one-time flow. Product call, deliberately not punch-listed. (Phase 2)

### Count check

- **Total punch items: 102**
- By priority: **P0 = 19** · **P1 = 67** · **P2 = 16**
- By tag: **[system fix] = 73** (P0 14 · P1 45 · P2 14) · **[taste] = 29** (P0 5 · P1 22 · P2 2)
- Leaving-as-is entries: **18**. Clean categories with zero items: iOS 26 banned APIs (Phase 3 cat 10). Every finding from Phases 2–6 is accounted for as exactly one punch item (with all duplicate sightings cited) or one leaving-as-is entry; nothing was silently dropped.

---

## Orchestrator Verification Log

**[VERIFIED: Subagent F — Phase 8]** Every punch item is tagged ([system fix] 73 / [taste] 29) and ranked (P0 19 / P1 67 / P2 16), grouped by theme, with source-phase citations; duplicate sightings across phases were merged into single items citing all sources (e.g. the close-button item merges Phase 3 cat 2, Phase 4 §4/§9, Phase 5 fix 3, Phase 6.1/6.2). The top 5 are all cross-surface system fixes — Phase 5's ranked fixes and Phase 6's token-level contrast fix merged and re-ranked with stated rationale, including an explicit demotion of the spacing fix. The leaving-as-is list is explicit (18 entries, each with a reason), covering every considered-but-not-actioned finding including two pending-human-decision items (token-level light-mode infra; orphaned Me-Card surfaces). DEBUG-only findings are marked. Count check present and internally consistent. Pass 1 is complete; Pass 2 (Gap & Edge Case Audit) may begin.

---
