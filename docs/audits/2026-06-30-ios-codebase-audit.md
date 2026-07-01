# Vayl iOS Codebase Audit

_Date: 2026-06-30_
_Scope: full `Vayl/` app target (342 Swift files, ~69k LOC), audited as a shipping iOS app._
_Method: four parallel investigators (dead-code reachability, architecture compliance, iOS 26 + correctness, design tokens + performance), each tracing from the live roots (`VaylApp @main → AppRootView → {OnboardingCanvasWrapper, SignInView, AppShell tabs}`) so that shelved experiments are separated from active code. Top findings spot-verified by hand._

---

## TL;DR

The core of this app is in genuinely good shape. The architecture discipline that matters most is intact: the onboarding director / `tableFade` / `VaylCardModel` contract is textbook-clean, all 15 Stores are correctly `@Observable @MainActor`, the Service layer has zero upward dependencies, and the iOS 26 banned-API surface is completely clean. The newest code (Pulse aura, DesireMap, Sessions, OnboardingProgressBar) is meticulous about tokens and Reduce Motion.

The debt is concentrated and legible:

1. **~18% of the target is dead code** (~61 files, ~12,500 LOC) left behind by successive reworks. This is the single biggest thing to act on, and it is what makes every other audit noisier than it should be.
2. **Two Critical issues** sit at load-bearing spots: a SwiftData container that rebuilds itself on every access, and a legacy card-session presented as a swipe-dismissable sheet in violation of the "Session is always a protected cover" rule.
3. **A pocket of older features (Settings, Pairing, legacy Sessions) predate the current token + layering discipline** and is where a focused cleanup pays off most.

Nothing here blocks App Store review on the banned-API front. The Critical items are correctness/contract issues, not compliance rejections.

---

## Project Configuration

These sit above any single file and are worth a deliberate decision.

| ID | Finding | Evidence | Severity | Recommendation |
|---|---|---|---|---|
| CFG-1 | Deployment target is **iOS 26.2**, contradicting the stated "iOS 16+ baseline" | `project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 26.2` | Medium | Decide intentionally. If iOS 26 is truly mandatory (per the CLAUDE.md iOS 26 section), update the "16+ baseline" language so the contract stops contradicting itself. If not, lower the target. As-is, the app installs on nothing below 26.2. |
| CFG-2 | **Swift 5 language mode**, not the "Swift 6" the contract assumes; no strict concurrency | `project.pbxproj`: `SWIFT_VERSION = 5.0`, no `SWIFT_STRICT_CONCURRENCY` | Medium | The `@MainActor` / data-race guarantees the 4-layer architecture leans on are **not compiler-enforced**. Every concurrency finding below is a real runtime risk rather than a build error. Consider moving to Swift 6 mode (or at least `-strict-concurrency=complete`) to let the compiler enforce what the architecture already assumes. |
| CFG-3 | Device family is **iPhone + iPad** (`"1,2"`) | `project.pbxproj`: `TARGETED_DEVICE_FAMILY = "1,2"` | Low | All layout is portrait-phone geometry (`AppLayout.from(geo)`, card aspect ratios). iPad is almost certainly shipping untested. Set to `"1"` (iPhone-only) for V1 unless iPad is a deliberate goal. |

---

## Master Priority List

The cross-dimension, ranked action spine. Detail for each lives in the sections below.

### Critical (fix before shipping)

| # | Issue | File | Fix |
|---|---|---|---|
| C-1 | ~~`ModelContainer.appContainer` is a computed `static var`~~ **FIXED 2026-06-30.** Converted to an immediately-invoked-closure `static let`, so the container is built once and cached; every caller now shares the same instance. Build-verified green. | `Vayl/App/ModelContainer.swift:74` | Done. |
| C-2 | Legacy card session presented as a raw, swipe-dismissable `.sheet`, violating "Card Session is always a `.vaylCover`". **REVISED after tracing (2026-06-30, see "Dual card-session resolution" below): the legacy path is unreachable in the current build** (Home's carousel runs in `selecting` mode and never emits `.startSession`; HomeDashboardView never invokes `onCardAction`). Severity downgraded from Critical to **cleanup** — it is orphaned scaffolding, not a live grammar breach. | `Vayl/Features/Home/Views/HomeRouterView.swift:38,75,244-251` | Retire the legacy `SessionStore`/`SessionView` engine (delete 2 files + 3 edits in HomeRouterView). |

### High

| # | Issue | File | Fix |
|---|---|---|---|
| H-1 | `try! AttributedString(markdown: "**\(card.highlightedPhrase)**")` on content-driven text: unbalanced markdown metacharacters (`*`, `[`, `\`) in a phrase will crash. Reachable via Vault (Map tab). | `Vayl/Design/Components/Cards/ConversationCard.swift:311` | Use `try?` with a plain-text fallback. |
| H-2 | Views reaching the Service/DB layer directly: `HomeLexicon` calls `ContentService.shared.fetch...` in `.task`; `SettingsPrivacyView` calls `SyncManager.shared.pushSharePulse`; `SettingsIdentityView` calls `SyncManager.shared.push...` plus `context.save()` plus pronoun-parsing business logic, all inside the View. | `HomeLexicon.swift:160`, `SettingsPrivacyView.swift:41`, `SettingsIdentityView.swift:222-238` | Introduce a `SettingsStore` and route content fetch through `HomeStore`/`LearnStore`. This is the biggest 4-layer debt pocket. |
| H-3 | `SyncManager` durable queue uses bare `try? context.save()`: if the save after `context.delete(task)` fails, the deletion is silently lost and the task re-processes next launch (duplicate push); a failed retry-count bump silently loses retry accounting. Violates the project's own `saveWithLogging()` rule. | `SyncManager.swift:289,317,320` | Use `saveWithLogging()` like the feature stores do. |
| H-4 | `SettingsView` bypasses `AppFonts` wholesale (~11 raw `.system(size:weight:)`) and mixes `.vaylGlassCard()` with hand-rolled `RoundedRectangle` chrome; Pairing views reconstruct fonts via `Font.custom` that AppFonts already tokenizes; `SessionView` (the protected cover) has 6 raw `Font.custom`. | `SettingsView.swift`, `Pairing/*`, `SessionView.swift` | Token cleanup pass on the three pre-discipline features. |
| H-5 | `CardCarousel` fires three `.repeatForever` idle loops (borderRotation, floatOffset, bloomOpacity) unconditionally, ignoring Reduce Motion, on a component used across Home/Play/OB. | `CardCarousel.swift:109-125` | Gate behind `accessibilityReduceMotion` / `.ambientAnimation`. Top accessibility fix. |

### Medium / Low
Rolled into the per-dimension sections below (dead-code cleanup, remaining presentation-grammar sheets, scrim-token gap, smaller RM loops, silent-save consistency).

---

## 1. Dead Code & Reachability (the spine)

The developer's own `filetracker.md` already flags two intentional keeps (`RotaryDial`, `TabContentWrapper`); everything below was traced by whole-tree zero-reference sweep plus transitive dead-consumer resolution, with dynamic/indirect-use caveats checked rather than assumed.

**Totals:** ~55 files confirmed dead (~11,300 LOC), ~6 shelved (~1,260 LOC), 4 partial-file. **~61 files / ~12,500 LOC deletable if all buckets confirmed (~18% of the target).**

### Confirmed dead (safe to delete) — top items

Biggest single wins first:

| File | LOC | Note |
|---|---|---|
| `Design/Components/Effects/FilamentMode.swift` | 876 | Largest dead file; 0 refs. |
| `Features/Map/PrismView.swift` | 833 | Matches your own "PrismView dead, kept to mine visually" note. |
| `Features/Learn/Views/ConstellationNode.swift` | 772 | Superseded by `DesireConstellationView`/`DesireStarView`. |
| `Features/Onboarding/Canvas/OBDeepCardFace.swift` | 765 | 0 refs. |
| `Features/Home/Components/ReflectionCard.swift` | 708 | Not instantiated. |
| `Design/Components/Progress/OrbitIndicator.swift` | 695 | 0 refs. |
| `Design/Components/Effects/SparkField.swift` | 628 | Only a comment ref in dead `ConstellationNode`. |

Full confirmed-dead set (~55 files) also includes, grouped:

- **Home:** `HomeGateView` (297, routing superseded), `DesireMapIndicator` (298, "retired" per its own comment), `CardChestContainer` (30), `HomeEventEngine` (103).
- **Pulse legacy cluster:** `PulseWidget`, `PulseCheckInCover`, `CheckInShell`, `DailyCheckInView`, `PulseSheetView`, `TierGuideSheet` — all superseded by `PulseCheckInView` and the split Pulse components.
- **Onboarding:** `OnboardingLayout` (100), `DeckWrapView` (65), `CredentialEditorSheet` (373, comment-only refs).
- **Cards shell chain (abandoned shell):** `PremiumCardShell` (221) → `CardFrontView` (112) / `PromptCard` (34), plus `CardStyle`, `CardRevealPillButton`, `CategoryTileView`, `CuriosityFlipCard` → `CuriosityCardBack`.
- **Card faces (preview-only, never wired):** `SlotMachineCardFace` (374), `CompassOptionCardFace` (69), `CompassSliderCardFace` (109). Note: the live one is `CompassCardFace` (rendered for `.curiosity`) — do not confuse the three.
- **Effects:** `AuroraGlowField` (313), `MazePatternView` (185) → `TileOrbitView` (353), `OrbitSparkBorderView` (58), `GlowUnderline` + `GlowUnderlineView` (both dead, two takes on one idea), `GradBadge`, `SectionHairline`, `SectionHeader`.
- **Navigation/Progress/Input/Text/Buttons:** `NavArrow` (8 types, 296) → `OnboardingNavBar` (117), `SpectrumBar`, `ToggleRow` (live type is the different `SettingsToggleRow`), `KeywordHighlightText`, `CriticalButton`, `SafeWordButton` (comment-only refs), `AppGrid` (119, unused theme file).
- **Progress feature:** `ProgressDashboardView` (207) — whole `Features/Progress/` folder orphaned, and it is the only consumer of `DataStore`, which itself references models not in `SchemaV1` (latent crash if ever wired; see Correctness).

### Likely shelved (confirm intent, then delete) — ~6 files, ~1,260 LOC

| File | LOC | Note |
|---|---|---|
| `Core/Debug/DiagnosticOverlay.swift` | 179 | Dev measurement overlay; per memory, used ad hoc during sim debugging. Keep if still useful. |
| `Core/Debug/DragDebugView.swift` | 79 | Dev-only. |
| `Features/Sessions/Debug/PresenceDebugView.swift` | 196 | Dev-only session-presence debug screen; also instantiates `RealtimeSessionService()` directly in a View. |
| `Design/Brand/VaylAppIcon.swift` + `AppIconRetreival.swift` | 717 | Icon-export dev tooling; `VaylAppIcon` is referenced only by the unwired `AppIconRetreival`. |
| `Core/Services/PushService.swift` | 89 | **Not superseded — genuinely unwired.** Zero refs including pbxproj; no `registerForRemoteNotifications`. This is the T1 notification tier waiting to be built, not dead. Keep, but track it as unbuilt. |

### Ambiguous (partial-file: keep the file, prune the member)

| File | Dead member | Caveat |
|---|---|---|
| `Core/Models/Enums/AppPulseEnums.swift` | `PulseSource` enum | Verify no `Codable` decode path from SwiftData/backend before removing. |
| `Features/Play/Store/PlayStore.swift` | `DeckContinuity` | Verify it is not part of a persisted snapshot. |
| `Features/Home/Views/MapChartedMoment.swift` | `MomentCopyEntrance` | Helper unused; parent is live. |
| `Design/Components/Cards/CardFaces/CandleCardFace.swift` | `FlameCfg`, `CandleNoise`, `CandlePalette` | `CandleCardFace` is LIVE; verify the renderer does not use these internally. |

### Competing / duplicate implementations (resolve which is canonical)

- **Carousels (all live, keep all):** `CardCarousel` (Home/Play), `VaylCardCarousel` (OB), `InfiniteCarousel` (Learn). Distinct consumers, not dupes.
- **Card shell:** live = `VaylCardFace` + `VaylCardBack`; dead = the `PremiumCardShell → CardFrontView/PromptCard` chain.
- **Hairlines:** live = `SpectrumHairline` + `VaylBorderEffect`'s `HairlineView`; dead = `SectionHairline`.
- **Section headers:** live = `MapSectionHeader`; dead = `SectionHeader`.
- **Constellations:** live = `DesireConstellationView`/`DesireStarView`; dead = `ConstellationField` + `ConstellationNode`.
- **Pulse check-in:** live = `PulseCheckInView` + split components; dead legacy cluster listed above.

> Deleting the confirmed-dead set removes the HIGH-severity `OrbLayer` raw-timestamp shader bug and the `DataStore`/`SchemaV1` latent crash for free, since both live only in dead code.

### Correction after symbol-level verification (2026-06-30)

A symbol-level re-check (every exported type, func, and extension method, not just the type name) found **three misclassifications** in the Confirmed-Dead set above. The type-name sweep missed them because the live reference is to a differently-named symbol.

- **`Features/Map/Components/FlavorVisuals.swift` is LIVE, not dead.** Its `FlavorChip` / `FlavorPortrait` / `DrawnTagChip` are used by `MeCardSheet` (`MapView:85`) and `MeCardCompact` (`MapView:201`) on the Map tab. The original sweep searched for the *sigil/crest* types (`FlavorSigil`, `CoupleCrestSigil`, `CoupleCrestPortrait`), which may be dead — so this is a **partial-dead file**: keep it, optionally prune the unused crest/sigil types after verifying.
- **`Features/Onboarding/Phases/CredentialEditorSheet.swift` is LIVE, not dead.** The file is named "Sheet" but exports `CredentialEditorOverlay`, presented by the live onboarding canvas at `OnboardingCanvasView:194,381` (driven by `director.editingCredential`). Keep it.
- **`SlotMachineCardFace` / `CompassOptionCardFace` / `CompassSliderCardFace` are runtime-dead but compile-coupled.** `VaylCardFace.swift` (the central live renderer) instantiates all three in its `switch` (`:158,196,202`); their content-enum cases are never *constructed* by live data. To delete, remove the file AND the matching `VaylCardFace` switch arms AND the enum cases together, or the build breaks. Not a standalone `rm`.

All other Confirmed-Dead entries survived the symbol-level check (their apparent hits were name collisions with unrelated private helpers). Net cleanly-deletable set: **48 files** (the 53 minus these 2 live files and 3 coordinated-deletion files).

---

## 2. Architecture Compliance

**Verdict: mostly compliant, with one Critical and a concentrated debt pocket in Settings + Home-Lexicon.**

### Clean (positive confirmation)

- **Onboarding director discipline is textbook.** All 10 `tableFade =` writes are inside `VaylDirector.swift`; every other reference is a read or comment. Phase advancement routes through the director. No View writes `VaylCardModel` directly.
- **All 15 Stores are `@Observable @MainActor final class`.** Services carry no SwiftUI import and no `*View`/`*Store` reference (the one `Store` grep hit is Apple's `AppStore.sync()`).
- **Models effectively pure.** SwiftData `@Model` classes are the deliberate persistence-backed Model layer; a few enums `import SwiftUI` for `var color: Color` mapping (presentation vocabulary on a domain enum, low severity).

### Violations (active code)

| Severity | Issue | File |
|---|---|---|
| Critical | Legacy card session as raw `.sheet` (see C-2). Two parallel card-session systems exist: newer `CoupleSession` (cover, correct, `HomeDashboardView:280`) and legacy `SessionStore`/`SessionView` (sheet, wrong). Still reachable via `CardCarousel.startSession`. | `HomeRouterView.swift:75` |
| High | `HomeLexicon` View calls `ContentService.shared` directly in `.task`. | `HomeLexicon.swift:160-162` |
| High | `SettingsPrivacyView` View calls `SyncManager.shared.pushSharePulse`. | `SettingsPrivacyView.swift:41` |
| High | `SettingsIdentityView` does network sync + `context.save()` + pronoun-parsing business logic in the View's save handler. | `SettingsIdentityView.swift:222-238` |
| Medium | `AuthService` called directly from `SignInView`/`SettingsView`. Gray-area: `AuthService` is intentionally the app-wide reactive auth-state surface with no `AuthStore` by design. Note as an accepted seam. | `SignInView.swift:60`, `SettingsView.swift:90` |
| Medium | Raw `.sheet` for legal/Safari sheets, off the `.vaylSheet` grammar. | `SignInView.swift:124`, `PaywallSheet.swift:87` |
| Medium | Raw `.sheet` presenting `PairingInviteView`/`PairingJoinView`/`IdentityEditSheet`. | `SettingsView.swift:72,76`, `SettingsIdentityView.swift:74` |
| Low | Raw `.sheet` for the OS share `ActivityView`. | `HomeLexicon.swift:155` |

Dead-code violations (`ProgressDashboardView` builds `DataStore` in-View; `PresenceDebugView` drives `RealtimeSessionService()` in-View; `PairingSettingsView` raw sheets) are noted but not counted, since those files are orphaned.

**The dual card-session system is the highest-value thing to resolve** — it fixes the Critical grammar breach and removes the ambiguity of which session engine is canonical.

### Dual card-session resolution (traced 2026-06-30)

Both session engines were traced end-to-end. Result: **canonical = `CoupleSessionStore` / `CardSessionContainerView`; retire the legacy `SessionStore` / `SessionView`.**

| | Legacy | Canonical |
|---|---|---|
| Store / View | `SessionStore` (239) + `SessionView` (280) | `CoupleSessionStore` (406) + `CardSessionContainerView` (149) + Airlock/Player/Close/Atmosphere |
| Presentation | raw `.sheet` (HomeRouterView:75) | `.vaylCover` (HomeDashboardView:285, PlayView:87) |
| Model | single-device deck playthrough | two-device ceremony: airlock → phones-down → player → close + reflection → done |
| Realtime | none | `RealtimeSessionService?` injected (presence mocked, "Seg 6/7" swap pending) |
| Persistence | `CardSession` + `CardResult` + `DeckProgress` | **superset**: same + `SessionReflection` + `enqueueSync(SessionRecordPayload)` |
| Reachability | **unreachable** — Home carousel is `selecting`-mode (emits `onToggleSelect`, not `.startSession`); HomeDashboardView never invokes `onCardAction`; `activeSession` is never set | **live** — Home "Settle in" (`settleIn()` → `sessionHand`) and Play (`PlayStore.beginSession`) both present it |

The canonical engine is the actively-developed, spec-backed (`docs/superpowers/specs/2026-06-21-couple-session-quickplay-implementation-spec.md`), correct-grammar, superset-persistence path, and it is already the only engine users can actually reach.

**Retirement scope (isolated, low-risk):**
1. Delete `Vayl/Features/Sessions/SessionStore.swift` and `Vayl/Features/Sessions/SessionView.swift` (~519 LOC).
2. In `HomeRouterView.swift`: remove `@State activeSession` (:38), the `.sheet(item: $activeSession)` (:75-77), and the `.startSession` case in `handleCardAction` (:244-251). Keep `.navigateToPlay`.
3. **Keep** `CardCarousel`'s `.startSession` emission (Play's `PlayHeroView:24` still consumes it), `SessionRecordPayload`, and `SessionSyncService` (used by the canonical store's sync).

Open product question (not a reason to keep legacy): the canonical engine bakes in couple ceremony (airlock, "phones down", partner presence). Play currently routes solo decks through it too. If a distinct solo-session feel is wanted for V1, that is a separate design decision on the canonical engine, not an argument for the generic single-device legacy one.

---

## 3. iOS 26 Compliance & Correctness

**Verdict: banned-API surface fully clean; correctness mostly solid with one Critical and one High.**

### iOS 26 banned APIs: all absent (confirmed)

`UIScreen.main` / `.bounds` (only in do-not-use comments), `UIApplication.shared.keyWindow` (scene-based pattern used correctly at `AppLayout.swift:100-101` and `ScreenshotProtectionModifier.swift:44`), `UIWebView`, `NSURLConnection`, `AppDelegate.window`, deprecated Core Data keys, and armv7/armv7s slices are all absent. `PushService`/`SettingsNotificationsView` use the correct authorization options. CLAUDE.md's compliance claims hold up.

### Correctness findings

| Severity | Issue | File |
|---|---|---|
| Critical | `appContainer` computed `static var` (see C-1). | `ModelContainer.swift:74` |
| High | `try! AttributedString(markdown:)` on content data (see H-1). | `ConversationCard.swift:311` |
| Medium | `SyncManager` durable queue bare `try?` saves; silent data loss on retry/dedupe (see H-3). | `SyncManager.swift:289,317,320` |
| Medium | `DataStore` inserts/fetches `SessionRecord`/`RatingRecord`/`StreakRecord`, none registered in `SchemaV1`. Fetching an unregistered `@Model` traps. Currently unreachable (only `ProgressDashboardView`, dead), so it cannot fire today — delete both, or register the models. | `DataStore.swift`, `ModelContainer.swift:23-46` |
| Low | `EntitlementStore.updatesTask` (`Transaction.updates`) never cancelled. Benign in practice (app-lifetime `@State`, and the listener is `[weak self]`). | `EntitlementStore.swift:56,81` |
| Low | `AppState.markOnboardingComplete/reset` use bare `try? context.save()` on the completion write: a silent failure plus the launch reconcile (which trusts `UserProfile`) could revert the user to onboarding. | `AppState.swift:153,163` |
| Low | Widespread `try? context.save()` against the `saveWithLogging()` mandate (best-effort UI writes, no data-loss trigger): `DesireMapStore:133,159`, `MapStore:217,224`, `VaultStore:180,195,223`, `EntitlementStore:198`, `SettingsIdentityView:229`, `DesireMapView:1053`. Consistency cleanup. |
| Low | DEBUG-only state forcing (Home always shows fully-progressed dashboard; seeded `partnerName = "Alex"`) can mask real routing during on-device "feel" verification. Intentional dev quick-jump. | `HomeStore.swift:93-101`, `AppState:98-102`, `MapStore:121-125`, `PulseStore:25-29` |

**Exemplary patterns worth preserving:** `DesireRevealStore.autoAdvanceTask` (`[weak self]`, cancels on supersede, documents the `@MainActor` isolated-deinit gotcha), `PairingStore.pollTask` cancellation, `AuthService`'s `nonisolated` delegate hopping back via `Task { @MainActor in }`, and the explicit `fatalError`-on-schema-mismatch philosophy in `ModelContainer`.

---

## 4. Design Tokens & Performance

**Verdict: strong foundations (radius/animation/card-face discipline is real; the newest code is meticulous). Debt concentrated in an unavoidable color-overlay pattern and three pre-discipline features.**

### Token violations (active code only; dead-code violations excluded)

| Area | Finding | Severity |
|---|---|---|
| **Color (the dominant gap)** | ~212 active `.white/.black.opacity()` overlays. Semi-legitimate glass/scrim on void, but **there is no semantic scrim/overlay token to land them on.** Worst: `HomeWidgetShell`, `VaylCardFace` (18), `PremiumCardShell` (17, dead), `VaylSheet` (10). | Medium (High as a systemic pattern) |
| Color | ~50 active raw RGB/hex: `ConstellationNode` (dead), `AuroraGlowField` (dead), `CandleCardFace` (26 gradient stops where a spectrum token exists), `HolographicShimmer` (17). | Medium |
| **Fonts** | ~72 raw `.font(.system/.title/...)` + ~26 `Font.custom` outside AppFonts. Worst live: `SettingsView` (whole feature), Pairing views (reconstruct AppFonts via `Font.custom`), `SessionView` (6 in the protected cover). | High |
| Radius | Essentially clean — only 2 numeric `.cornerRadius`, both in Debug. | Compliant |
| Spacing | Padding contained (42, mostly legit geometry). Stack `spacing:` literals (91) are the real gap: only ~7 match an exact `AppSpacing` value; the rest are off-scale tuning. | Medium |
| Animation | ~85 inline `.easeInOut/.spring/.linear(duration:)` literals instead of `AppAnimation` tokens. Worst: `BuildDeckPhase` (16), `CardCarousel` (11), `SplashScreenView` (8). | Medium |
| Shadow-as-glow | 75 raw `.shadow()` used for glows against the "use `AppGlows`, never `.shadow()` for glows" rule. Active: `SelectablePill` (7), `NavArrow`, `DesireStarView`, `DeckPedestal`, `PulseCapsule`, `PulseAura`, `DesireMapView:814`, `HomeLexicon:529`. | Medium |
| Card chrome | `SettingsView` mixes `.vaylGlassCard()` with hand-rolled `RoundedRectangle` chrome (lines 157/171/189/249). | Medium |
| Tap trio | Content taps missing press-state + haptic: `HomeLexicon:228` (routes), `MeCardCompact:76`, DesireMap rater. Background-dismiss and card-flip taps are legitimate exceptions. | Medium/Low |

> **Recommended sequence for the color cleanup:** add scrim/overlay tokens to `AppColors` *first*, then sweep the ~212 overlays onto them. Sweeping before the token exists has nowhere clean to land.

### Color cleanup — done (2026-06-30)

Re-verified before touching anything: the live-only count (excluding all now-confirmed-dead files, including `HomeWidgetShell.swift` — see the dead-code correction above, its only consumer is the dead `PrismView`) was **136 sites across 49 files**, not 212. `VaylCardFace` (13 sites) was excluded entirely — it's explicitly off-limits per the "no VaylCardFace shell modifications" rule.

The remaining distribution was genuinely scattered, not clustered into 3-4 tiers, because most of it is hand-tuned gradient-stop values inside effects (`PremiumCardShell`-style foil sheens, `SplashScreenView`, `DeckCaseView` gradients) — deliberately felt, not sloppy, consistent with this project's "feel it first, never guess a value" discipline. Forcing all 136 into a rigid token set would have flattened that. Instead, only the **repeating structural chrome** (found by symbol/context inspection, not just opacity value) got tokenized:

- Discovered `AppColors.borderSubtle` / `borderDefault` / `borderActive` **already existed** and covered the hairline-border idiom — it just wasn't being used. No new token needed; 6 call sites repointed at existing tokens (`ConversationCard` ×2, `PulseHistoryGrid`, `DesireRevealView`, `DeckCaseView`, `ConversationCard` pill border).
- Added **`AppColors.scrimHeavy`** (`AppColors.swift`, next to `shadowDeep`) — full-screen backdrop dim behind an elevated/engaged surface, heavier than the existing modal-scrim token. Values sourced from `CardCarousel`'s already-tuned dynamic default (light 0.35 / dark 0.75). 2 call sites: `CardCarousel` (preserves its per-caller `dimOpacity` override), `DesireRevealView` (this one was a **latent light-mode bug** — hardcoded `.black.opacity(0.55)` with no light/dark branch at all; now correctly adapts).
- Added **`AppColors.whisperFill`** (next to `glassSurface`) — translucent tonal wash on both appearances (unlike `glassSurface`, which is opaque-frost in light mode). 10 call sites across `ConversationCard`, `InteractiveField`, `DesireRevealView`, `LearnSegmented`, `ResearchDatabaseView` ×2, `ContentHubSection`, `DesireMapView`, `PairingJoinView`, `PairingInviteView`. Several of these paired an already-correct `AppColors.borderSubtle` stroke with a raw, non-adapting fill — a repeated latent light-mode inconsistency fixed as a side effect.

Net: 2 new tokens, 18 call sites swept, 1 real light-mode bug fixed, 1 duplicate-in-same-file literal removed (`ReflectionBannerView` — deferred, file wasn't touched this pass since its own duplication is separate from the cross-file sweep). Build-verified green. Remaining ~118 sites are intentionally-tuned gradient/shader values, left alone by design.

### Reduce Motion / ambient-animation gaps (active)

| File | Gap | Severity |
|---|---|---|
| `CardCarousel.swift:109-125` | Three `.repeatForever` loops fire unconditionally (see H-5). Widely used. | Medium (High for a11y) |
| `AtmosphericGhostDeck.swift:37,51` | Two 8-9.5s drifts, no RM gate. Active via `ConversationCard`. | Medium |
| `ConversationCard.swift:84` | 2s pulse ternary is on `pulsing`, not `reduceMotion`. | Medium |
| `LightModeShimmer`, `AuroraGlowField:278`, `ConstellationNode:177` | Ungated `repeatForever` (last two are dead). | Medium |
| `DesireMapView.starField:250` | 15fps star-twinkle Canvas not RM-gated, though the rest of the file is meticulous. | Low/Medium |

**Exemplary (leave as-is):** `OnboardingProgressBar`, `PulseAura`/`PulseField`, `CandleCardFace`, `Sessions/*`, `ConstellationField` all correctly gate via `guard !reduceMotion` / `.ambientAnimation`.

### Performance

- **Shaders: the live app is clean.** The one active shader (`MetallicCaseView.hexFoilSurface`, Play deck ceremony) is tilt-driven, not time-driven, and documents "no absolute timestamps reach the GPU." The float-precision violations — `OrbitSparkBorderView`, `OBDeepCardFace`, and the HIGH-severity `HomeWidgetShell.OrbLayer` raw-timestamp loop — are **all in dead code** and vanish when it is deleted.
- **Heaviest live element:** `PulseAura.causticLayer` (`PulseAura.swift:55-94`) stacks 3 radial-gradient shadings + `.compositingGroup` + `.clipShape` + `.shadow` + screen-blend Canvas + 2 blurred rims per aura instance, with multiple auras on one `PulseField`. Static per-frame (driven by discrete `.ambientAnimation` flips, not TimelineView), so not per-frame cost, but the multi-instance blur/shadow stacking is the Map Pulse hero's heaviest element. Watch on older devices. Medium.
- **Minor:** `DesireMapView.ratedItemsByGroup:680` does `.filter` + `Dictionary(grouping:)` in a body-read computed property (fine at current N, would matter if the desire deck grows). `CandleCardFace.draw` is heavy but dormant (default `time: 0`, static).

---

## Recommended Sequencing

A finish-first ordering that de-risks the rest:

1. **Delete the confirmed-dead set (~55 files).** This is the highest-leverage move: it removes ~11k LOC, eliminates two latent bugs (`OrbLayer` shader, `DataStore`/`SchemaV1` crash) for free, and makes every future audit and grep dramatically cleaner. Confirm the 4 partial-file members and the 6 shelved dev tools separately. Keep `PushService` (unbuilt, not dead).
2. **Fix C-1 (`static let appContainer`)** — one line, load-bearing.
3. **Resolve the dual card session (C-2):** pick the canonical engine, retire or convert the legacy `SessionStore`/`SessionView` sheet to `.vaylCover`.
4. **Fix H-1 (`try?` markdown)** — cheapest crash removal.
5. **Introduce a `SettingsStore`** and move the `SyncManager.shared` / `ContentService.shared` / `context.save()` calls out of Settings + HomeLexicon views (H-2), and switch `SyncManager`'s durable-queue saves to `saveWithLogging()` (H-3).
6. **Add scrim/overlay tokens, then sweep color; token-clean Settings/Pairing/Sessions (H-4).**
7. **Gate the ambient loops on Reduce Motion (H-5 + the smaller ones).**
8. **Decide CFG-1/2/3** (deployment target, Swift 6 mode, iPhone-only) as deliberate config choices.

---

_Generated by a four-investigator parallel audit. Findings with file:line references were spot-verified; dead-code reachability was traced from live roots with dynamic-use caveats checked, not assumed._
