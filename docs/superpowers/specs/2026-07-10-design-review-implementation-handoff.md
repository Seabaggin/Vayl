# Design-Review Implementation — Handoff

**Date:** 2026-07-10
**Branch:** `claude/amazing-einstein-fdp08u`
**Source of truth for findings:** `docs/superpowers/specs/2026-07-08-ui-design-review.md` (131 punch items across Pass 1 + Pass 2)
**This doc:** the *execution plan* — ordering, batching, dependencies, verification gates, and constraints — that the review document itself does not contain.

---

## 0. Why this doc exists — read first

The 2026-07-08 review produced **131 tagged, ranked punch items**. This document turns that flat list into an **ordered, segmented build plan** you can execute one batch at a time.

**Hard environment note.** The review *and* the first implementation tranche were done in a Linux session with **no Xcode, no Swift toolchain, no simulator**. Nothing committed so far is build-verified. This directly conflicts with the CLAUDE.md **Build Protocol** (Non-Negotiable):

> Never build a full feature in one pass. Break every feature into named segments … A segment is not complete until it has run on device and the human has confirmed the feel. Build succeeds is not done. Feel is correct is done.

**Therefore: execute this plan from a machine with Xcode 26 + an iOS 26 simulator.** Each batch below is written as a Build-Protocol segment: one job, an explicit done-condition, and a constraints list of files it may not touch. After each batch: build, run the affected surface in the simulator, confirm, commit. Do not start the next batch until the current one builds and reads correctly on device.

**What "verified by inspection" means in the commits so far:** token/symbol names were confirmed to exist by grepping the real source, and edits matched surrounding patterns — but the compiler has never seen them. Treat every pre-existing commit on this branch as *needs a build pass*.

---

## 1. Status

### Done — tranche 1 (commit `4549e50`, pushed, UNVERIFIED against a build)
| Item | File | Change |
|---|---|---|
| Contrast floor (P0) | `App/Theme/AppColors.swift` | dark alphas lifted: `textTertiary` 0.38→0.50, `textHint` 0.42→0.60, `textCardLabel` 0.60→0.75, `textSectionLabel` 0.55→0.85 |
| Relative-date bug (P0) | `Features/Home/Components/HomePulseRail.swift` | `relativeTime` now returns "N days ago" instead of "yesterday" for any age ≥24h |
| Preview-data footgun (P0) | `Features/Pulse/PulseFullView.swift` | `myEntries` default `PulseEntry.previews` → `[]` |
| Double haptic (P1) | `Features/Sessions/Components/PendingSessionBanner.swift` | added press-only condition `{ _, pressed in pressed }` |

**First action for the next executor:** open the project, build, and confirm those four compile and render before adding anything. The contrast lift is the one to eyeball on device — it shifts many surfaces at once (captions, section labels, eyebrows). If any label now reads *too* hot, tune the alpha rather than reverting.

### Remaining: 127 items. The rest of this doc sequences them.

---

## 2. Execution principle — foundation before call-sites

Roughly 60% of the punch list is "swap a raw value / bespoke thing for a token / shared component." Those swaps have **no target to point at until the token or component exists.** So the ordering is strictly:

```
Batch 1 (tokens+components, additive)  ──►  Batches 2–N (migrate call-sites onto them)
                                       ──►  high-blast-radius refactors
                                       ──►  human-decision gates
```

Additive foundation first means: adding a new `static let`/`struct` cannot break existing code, so Batch 1 is the lowest-risk large batch and unblocks the most downstream work. Do it first, build it, *then* the mechanical sweeps become safe find-replace-verify loops.

---

## 3. The batches

Each batch: **Goal · Files · Changes · Done-condition · May-not-touch.** Batches are ordered; within a batch, items are independent unless noted. Priorities (P0/P1/P2) and sources map back to the review doc's Phase 8 + Pass 2 lists.

### BATCH 1 — Foundation tokens & components (additive, no call-site changes)
**Goal:** create every new token/component the migrations depend on. Nothing here changes an existing view; it only adds definitions.
**Files (all in `App/Theme/` or `Design/Components/`):**
1. `AppFonts.swift` — add the missing named tiers so the `display(n)`/`body(n)` constructors can be banned from Features/:
   - `tabMasthead` = `display(40, weight: .bold, relativeTo: .largeTitle)` (the three hand-built tab titles + Learn's drifted 42)
   - `sheetTitle` = `display(24, weight: .semibold, relativeTo: .title)` (alias of screenTitle, but named for the sheet-title rule)
   - `overlineTracked` — an overline that **bakes in `.textCase(.uppercase)` + `.tracking(2)`** so source strings stay sentence case (see Pass 2 G.5 #3). Note: SwiftUI `Font` can't carry tracking/case — implement as a `ViewModifier` or `Text` extension `.overlineTracked()`, not a `Font` var.
   - recurring body tiers observed in the wild: 15, 26, 28 (name them, e.g. `bodyLargeMedium`/`cardTitleLarge` — match the review's Axis-5 size census before naming).
2. `AppSpacing.swift` — add `md2: CGFloat = 12` (the missing step behind all the `sm + xs` arithmetic). Optionally bless `sm2 = 10`. Then the arithmetic sites in Batch 4 have a target.
3. **New** `App/Theme/AppOpacity.swift` — the ramp Pass 2 G.6 #2 specified:
   `whisper 0.04 · hairline 0.08 · border 0.15 · dim 0.25 · stroke 0.45 · glowFloor 0.30 · glowPeak 0.70`.
4. `AppAnimation.swift` — add `ambientDwell: TimeInterval = 12` (auto-advance carousels) and `recedeOpacity 0.25` / `recedeBlur 6` (deck-engaged recede). Do **not** delete anything yet.
5. **New** `Design/Components/Navigation/VaylCloseButton.swift` — 32pt circle, `AppColors.glassSurface` fill, `AppColors.borderSubtle` ring, `AppFonts.caption` xmark in `AppColors.textTertiary`, `PressableCardStyle`, built-in `.accessibilityLabel("Close")` (label overridable). This is the Top-5 fix #4 enabler.
6. **New** `Design/Components/VaylEmptyState.swift` — extract `MapEmptyState` (currently `Features/Map/Components/MapPrimitives.swift:43-66`) verbatim as `VaylEmptyState(icon:headline:sub:cta:)`, then `typealias MapEmptyState = VaylEmptyState` so Map/Vault sites don't churn.
7. **New** `Design/Components/VaylHairline.swift` — one hairline primitive (Pass 2 G.5 #7); `SpectrumHairline` already exists for the signature variant.
8. `AppColors.swift` — add a `scrimWhisper` token (`pureBlack @ 0.10`) beside `scrimHeavy`; add an **increase-contrast branch** at the token level keyed off `UIAccessibilityDarkerSystemColorsEnabled` for tertiary/hint/cardLabel/sectionLabel (deferred from tranche 1 — needs a build to tune).
9. Add a `.vaylRecede(_ engaged: Bool)` view modifier consuming `recedeOpacity`/`recedeBlur`.
**Done-condition:** project builds; a throwaway `#Preview` renders `VaylCloseButton`, `VaylEmptyState`, `VaylHairline`, and one label in each new font tier. No existing surface changed yet.
**May not touch:** any file under `Features/` (except reading), any existing view body.

### BATCH 2 — Motion rules & written specs (docs + token adoption)
**Goal:** turn the motion/spectrum/haptic *rules* into code + a written spec so later batches have a test.
- Fix the two **hard-rule motion violations** (P0): `SessionLobbyView.swift:62` and `AirlockView.swift:276` — replace `ambientPulse / 1.5` (1.33s loop) with a full-token loop (`ambientPulse` or `auraBreathe`). **Ban arithmetic on animation tokens** — grep `AppAnimation\.\w+ *[*/]` and fix each.
- `HomeWidgetShell.swift:75-93` (P0): gate the `TimelineView(.animation)` on `AppAnimation.ambientMotionDisabled` (adds the missing Low-Power gate) **and** add `minimumInterval: 1.0/30`.
- Adopt `ambientDwell` at the two Learn carousels (`QuizCarouselSection.swift:18`, `ResearchSection.swift:38`) **and** at the `InfiniteCarousel.swift:21` default (Pass 2 G.3 #9 — fixing call-sites without the default leaves the trap armed).
- Write the rules into CLAUDE.md / AppAnimation header comments: **breathing tempo** (living surfaces `auraBreathe` 5.4s, inert chrome `ambientPulse` 2s, no third tempo, no arithmetic); **haptic scale** (light=select/navigate, medium=commit, rigid=two-device seal, heavy=safe-word only, success=terminal); **spectrum discipline** (full gradient only on strokes/display-text/hero ≥24pt; `textAccent` for links; cyan=Me/private, magenta=Us/shared).
**Done-condition:** session lobby + airlock loops read calm on device; Home widget orbs stop under Low Power; Learn carousels dwell ~12s. Build green.
**May not touch:** color/typography call-sites (later batches).

### BATCH 3 — Mechanical color/token sweep (safe find-verify loop)
**Goal:** migrate raw color/scrim/gradient literals onto tokens. Highest count, lowest individual risk — but do it in a build loop, ~10 files at a time.
- Raw `Color.white`/`.foregroundStyle(.white)` in feature views → `AppColors.textBody`: the 16 sites in Phase 3 cat 1 + Phase 4 (Learn, Vault, Reveal, MapUs, rater, DemoPhase). Site list in review Phase 8 "Raw color sweep".
- Raw `Color.black.opacity(0.62)` scrims → `AppColors.scrimHeavy`: `StatPhase.swift:160`, `PaywallSheet.swift:257`. The two `0.10`/`0.6` scrims (`CredentialEditorSheet.swift:333`, `SingleGreetingSheet.swift:17`) → `scrimWhisper`.
- Inline spectrum `LinearGradient`s → `AppColors.spectrumText`/`spectrumBorder`: `SettingsView.swift:163-186`, `DesireRevealView.swift:245-301`.
- Full-gradient-on-tiny (≥24pt rule) → `AppColors.accentPrimary`: `HomeDashboardView.swift:771` (badge), `PendingSessionBanner.swift:23` (dot), `SessionLobbyView.swift:57`, `GettingStartedPathView.swift:127`, `CapacityMirror.swift:42`, `SessionPlayerView.swift:434`, `CredentialEditorSheet.swift:44-47` (grabber → `borderDefault`).
- Raw-cyan links → `AppColors.textAccent`: `GettingStartedPathView.swift:104`, `MapPulseHero.swift:72`.
- Opacity literals → `AppOpacity.*` where they map cleanly (worst files: `HomeWidgetShell`, `TableSurfaceView`, `DeckCaseView`) — opportunistic, not exhaustive.
**Done-condition:** each ~10-file sub-batch builds; spot-check 2-3 surfaces on device per sub-batch for unchanged appearance (these should be visually identical, just tokenized).
**May not touch:** typography, layout, motion.

### BATCH 4 — Mechanical typography + spacing sweep
**Goal:** migrate raw fonts + off-grid spacing onto the Batch-1 tokens.
- The ~40 raw-font sites (Phase 3 cat 2 list) → `AppFonts` tokens; the two non-scaling close-button `.system(size:13)` (`PulseFullView.swift:129`, `MapPulseHero.swift:308`) get fixed for free by Batch 6's `VaylCloseButton` adoption — skip here.
- The `display(15)/body(11)` copy pair → `cardTitleCompact`/`caption`: `MapPulseHero.swift:276-286`, `PulseFullView.swift:375-386`.
- Tab mastheads → `tabMasthead`: `HomeDashboardView.swift:571`, `PlayMastheadView.swift:20`, `MapView.swift:253`, `LearnView.swift:64`.
- Sheet titles → `sheetTitle`/`screenTitle`: `VaultSheet.swift:30`, `SessionBuilderView.swift:68`, `PulseFullView.swift:111`, `PaywallSheet.swift:163/232`.
- Overlines → `.overlineTracked()`; convert pre-uppercased string literals back to sentence case (Pass 2 G.5 #3 list).
- Spacing arithmetic (`AppSpacing.sm + n`) → `AppSpacing.md2`/`sm2`: the ~16 sites in Phase 5 fix 5 list. Off-scale literals (`5`,`7`,`3`,`6`) → nearest token.
- Delete the dead "Standard Screen Spacing" block `AppLayout.swift:126-159` (verify zero remaining references first — only `ProjectedTextView.swift:68` and `StatPhase` use `screenHPad`/`screenMargin`; migrate them to `AppSpacing.lg` then delete).
**Done-condition:** builds; mastheads and sheet titles visually consistent tab-to-tab on device; no clipped/rewrapped labels.
**May not touch:** color, motion, component structure.

### BATCH 5 — Tap contract + Dynamic Type
- Replace `.buttonStyle(.plain)` with `PressableCardStyle` at the confirmed-miss sites (Phase 3 cat 12 list: `VaultAgreementsSection.swift:81`, `PartnerChip` chips, `GettingStartedPathView.swift:113`, `MapChartedMoment.swift:61`, `PulseFullView.swift:83-129`, `CredentialEditorSheet` ×3, `NamePhase`, `DemoPhase`, `DeckBeginCeremony`). Verify each still triggers its action.
- Convert `SettingsCogButton` (`HomeDashboardView.swift:836-859`) to a real labeled `Button` + `PressableCardStyle` (kills the fake `asyncAfter(0.12)` press).
- Dynamic-Type frames (Phase 6.2 list): fixed `.frame(height:)` on text rows → `minHeight:`; `SessionPlayerView.swift:270/447`, `DesireAnswerPill.swift:64`, `DesireRevealView.swift:545/550`, `SignInView.swift:69`, `VaylCardFace.swift:649` (lower `minimumScaleFactor` floor to 0.5 on card body), `FounderLetterSheet.swift:49` (→ ScrollView).
**Done-condition:** every migrated tappable shows press-scale + haptic on device; set simulator to AX5 text size and confirm the listed frames don't clip.
**May not touch:** color, motion.

### BATCH 6 — Component consolidation (the Top-5 structural wins)
**Goal:** collapse the duplicated affordances onto single components. Higher risk — one component, many call-sites — so build after *each* component's rollout.
- **`VaylCloseButton`** → all 11 close-button sites (Phase 8 list). Fixes coherence + Dynamic Type + VoiceOver at once.
- **`VaylEmptyState`** → the 5 hand-rolled empty states (DesireReveal, rater, SessionBuilder 64pt→32, StatPhase, PulseFullView).
- **`VaylButton` as the one CTA voice** → the spectrum-capsule CTAs inside the Session cover (`WhisperRevealView`/`MirrorRevealView`/`SnapshotRevealView`/`UnspokenSliderView`/`ContextBeatOverlayView`, `SessionCloseView.swift:210/250`), `PaywallSheet.swift:150/312`, `PulseCheckInView.swift:242-263`, `PairingInviteView` stock buttons, `EventEntryEditor.swift:143` (accentSecondary capsule), `ReflectionBannerView.swift:345`. Rule: `.fullWidth` for commits, `size: .compact` for in-flow pills.
- **Settings gear on every tab** (`SettingsGearButton` → Play, Learn, Home) + retire the duplicate `SettingsCogButton`; wire Play/Learn to `settingsPresented`.
- **`SettingsCard`** → `SpectrumHairline` (or drop the hairline; recommend `borderSubtle`).
- **`HomeWidgetShell`** → rebuild on `vaylGlassCard` + `AppElevation.cardShadow` + AppGlows, keep only the orb layer custom.
- **`VaylHairline`** → the five divider dialects.
- **`heightFraction` → named detents** in `VaylPresentation` (`.compact 0.5 / .standard 0.66 / .tall 0.92`), resolve `screenHeight` internally.
- `.shadow()`-as-glow → AppGlows (DesireStarView, SelectablePill 7-stack, PulseCheckIn step dot, etc.).
**Done-condition:** every close button / empty state / primary CTA in the app is the shared component; each rollout built + spot-checked before the next.
**May not touch:** unrelated features while a given component is mid-rollout (avoid cross-batch merge pain).

### BATCH 7 — VoiceOver + one-shot motion + honesty fixes
- **P0 VoiceOver:** hold-to-deal operable (`SessionPlayerView.swift:454` — label + `.isButton` + `.accessibilityAction`, mirror `HoldToLockInRing.swift:80-83`); care mark label; constellation stars as buttons (`DesireConstellationView.swift:79`); locked-desire leak (`DesireRevealView.swift:541` — `.accessibilityLabel("Locked desire")`); NamePhase hand-back action; session reflection slider/chips operable (`SessionCloseView.swift:255/359`); Airlock back + PartnerChip labels; fan-deck `accessibilityHidden`; pulse-grid dots labeled; SessionSettingsSheet/SettingsIdentity `.isSelected` (copy `SettingsCompositionView.swift:49`).
- **One-shot motion:** banner exits opacity-only (`PlayView.swift:126`, `HomeDashboardView.swift:621/647`); lens swaps → `.vaylDepth(.quiet)` (`MapView.swift:221/234`, `PulseFullView.swift:85/97`); Vault segment swap → `.vaylDepth(.quiet)`; SessionBuilder trim/restore → `withAnimation(.standard)`; PulseCheckIn RM-gate the offset/scale halves.
- **Honesty:** `PulseFullView.swift:317` fabricated partner coordinate → field center or caption; ReflectionBannerView drop the in-sheet NavigationStack; Learn archetype pills → topic vocabulary (product-principle P0); degraded-connectivity chrome in the player (Pass 2 G.6 #1 concretion).
**Done-condition:** VoiceOver walkthrough of Session, Desire Reveal, and reflection completes end-to-end; RM on → no residual travel on the listed transitions.
**May not touch:** anything not in the list; these are surgical.

### BATCH 8 — Dark-only purge (HIGH BLAST RADIUS — gated, see §4)
Only after the human decision in §4.1. Strip feature-layer light branches (`PairingInviteView`, `PairingJoinView`, `ReflectionBannerView` ~17 branches, `HomeWidgetShell` `isLight` path) and design-layer light infra (`LightModeShimmer` + call-sites, `SelectablePill`, `RacetrackTabBar`, `OnboardingProgressBar` ~25 ternaries, etc.). Delete `PairingSettingsView.swift` (orphan) and other §4.2 files if the decision is delete. **Build after every 3-4 files — this is where unverified edits break the tree.**

### BATCH 9 — P2 hygiene
Timing-literal hoists (~45 `asyncAfter`/`Task.sleep` → tokens), design-layer raw color constructors → VaylPrimitives/file-private palettes, laundered constants (Pass 2 G.3 list: `HomeWidgetShell:179`, `CardLayout:31`, `LearnCardStyle:36`, `VaylSheet:38/41`, etc.), CTA casing → sentence case, stale comments, AppIcons adopt-or-delete, sheet-background rule, selection-checkmark color, double-space layout hacks. Low priority, do opportunistically.

---

## 4. Human-decision gates — DO NOT execute without a ruling

### 4.1 Dark-only token infrastructure (blocks Batch 8's scope)
`ThemeManager`, `AppTheme`, `AppColors.dynamic`'s ignored `light:` params, `AppElevation.swift:223-248` + `ThemeModifiers.swift:30/45` `colorScheme` branches. **Decision:** hard-purge per the V1 dark-only contract, **or** retain as scaffolding for the future "Dawn" light mode. Feature/design-layer light *branches* are punch-listed for removal regardless; this is specifically about the token-layer infra. → **Owner: Bryan.**

### 4.2 Orphaned files — land or delete
`MeCardSheet.swift`, `MeCardCompact.swift`, `PrismView.swift` (Me-Card "Seg 3", unlanded) and `SyncMatch.swift` — zero external call-sites. Delete, or wire up? → **Owner: Bryan.** (If delete: their internal violations vanish with them and drop out of Batches 3-9.)

### 4.3 FEEL-GATE constants
Author-annotated device-physics literals (`MapView.swift:32-47`, `SessionPlayerView.swift:30-31`, etc.) laundered past the token grep. Only tokenize if you de-ratify FEEL-GATE. → **Owner: Bryan.** Default: leave.

---

## 5. Deferred — missing features, not UI cleanup (out of scope for this pass)
These are dead affordances because the feature behind them doesn't exist. The review gates the affordance (hide/remove) until the feature ships; **building the feature is separate product work.**
- **Learn quiz runner** — `QuizCarouselSection` "Take the quiz" CTA is a no-op; no runner view exists. Interim: gate the section out (Pass 2 G.6 #5).
- **ResearchDatabaseView filters** — search field + sort/Filters are visual-only. Interim: remove them; keep topic chips (wire to local filter).
- **PulseInfoSheet copy** — shipped stub (title-only). Needs real two-paragraph explainer written in the app's voice, or remove the entry point. **Do not auto-generate this copy** — it's voice-sensitive couples-app product copy; Bryan writes it.

---

## 6. Item → batch cross-reference
Every review finding maps to a batch:
- Phase 8 P0 → Batches 1 (contrast, done), 2, 6, 7 + §4/§5 gates
- Phase 8 P1 → Batches 3, 4, 5, 6, 7
- Phase 8 P2 → Batch 9
- Pass 2 net-new P0 → Batch 7 (VoiceOver reflection, relativeTime[done], PulseInfoSheet[§5])
- Pass 2 net-new P1/P2 → Batches 2, 3, 4, 6, 9
- Dark-only (Phase 3 cat 9) → Batch 8 behind §4.1
- Orphans / FEEL-GATE / features → §4.2, §4.3, §5

Full per-item detail (before→after, file:line, source phase) lives in `2026-07-08-ui-design-review.md` §"Phase 8" and §"Net-new punch items". This doc is the *order and verification wrapper* around that list.

---

## 7. Suggested working rhythm
1. Pull branch, open in Xcode 26, build. Fix any tranche-1 breakage first.
2. Batch 1 (foundation) in one sitting → build → commit `feat(tokens): design-review foundation`.
3. Batches 2-7 in order, each as its own commit, **building + device-checking the named surface before moving on.** Small commits — one batch, one message.
4. Stop at Batch 8; get the §4.1 ruling; then purge with a build after every few files.
5. Batch 9 whenever; §5 features are separate tickets.

Nothing here is urgent or destructive except Batch 8 and the §4.2 deletions — those need Bryan's word and a build in the loop. Everything else is a steady tokenize-and-verify grind that the review already did the thinking for.
