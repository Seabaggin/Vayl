# Turnkey Fix List — companion to `contract-architecture-audit-2026-06-23.md`

Exact, hand-verified file:line + before→after for the **safe mechanical** subset. Apply on a clean branch off `master` (worktree) so it never tangles with the `spec/contextphase-2x3-redesign` diff. Say "do Section A" (etc.) to greenlight.

All sites below were confirmed by grep against current source on 2026-06-23.

---

## Section A — `Font.custom(...)` → `AppFonts` constructor (ZERO rendering change)

**Why this is safe:** `AppFonts.body(_:weight:relativeTo:)` and `AppFonts.display(_:weight:relativeTo:)` return the *exact same* `Font.custom(...)` call internally (verified in `AppFonts.swift:49-70` / `28-47`). These swaps just route through the token API — byte-identical output, no feel change, compile-verifiable. The contract explicitly sanctions these constructors for custom sizes.

**Transformation rule:**
- `Font.custom("Switzer-{Regular|Medium|Semibold|Bold}", size: N, relativeTo: T)` → `AppFonts.body(N, weight: .{regular|medium|semibold|bold}, relativeTo: T)`
- `Font.custom("ClashDisplay-{Bold|Semibold|Medium}", size: N, relativeTo: T)` → `AppFonts.display(N, weight: .{bold|semibold|medium}, relativeTo: T)`

| File:line | Replace with |
|---|---|
| `Features/Settings/SettingsView.swift:140` | `AppFonts.body(16, weight: .medium, relativeTo: .body)` |
| `Features/Settings/SettingsView.swift:181` | `AppFonts.body(15, weight: .regular, relativeTo: .body)` |
| `Features/Home/Components/ReflectionCard.swift:633` | `AppFonts.body(9, weight: .regular, relativeTo: .caption2)` |
| `Features/Home/Components/ReflectionCard.swift:650` | `AppFonts.body(9, weight: .regular, relativeTo: .caption2)` |
| `Features/Home/Views/HomeDashboardView.swift:494` | `AppFonts.body(22, weight: .regular, relativeTo: .title3)` |
| `Features/Pairing/PairingJoinView.swift:187` | `AppFonts.displayHero` *(= display(64,.bold,.largeTitle), exact match)* |
| `Features/Pairing/PairingJoinView.swift:212` | `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)` |
| `Features/Learn/Views/ConstellationNode.swift:371` | `AppFonts.body(13, weight: .semibold, relativeTo: .caption)` *(file is orphaned — see audit §Low; fix only if keeping)* |
| `Features/Pairing/PairingSettingsView.swift:171` | `AppFonts.body(20, weight: .medium, relativeTo: .body)` |
| `Features/Pairing/PairingSettingsView.swift:192` | `AppFonts.body(12, weight: .medium, relativeTo: .caption)` |
| `Features/Pairing/PairingInviteView.swift:179` | `AppFonts.body(14, weight: .medium, relativeTo: .caption)` |
| `Features/Pairing/PairingInviteView.swift:223` | `AppFonts.displayHero` |
| `Features/Pairing/PairingInviteView.swift:248` | `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)` |
| `Features/Pairing/PairingInviteView.swift:281` | `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)` |
| `Features/Progress/ProgressDashboardView.swift:102` | `AppFonts.body(16, weight: .regular, relativeTo: .body)` → or `AppFonts.bodyText` *(exact match)* |
| `Features/Sessions/SessionView.swift:73` | `AppFonts.body(18, weight: .semibold, relativeTo: .body)` |
| `Features/Sessions/SessionView.swift:96` | `AppFonts.body(18, weight: .semibold, relativeTo: .body)` |
| `Features/Sessions/SessionView.swift:149` | `AppFonts.body(14, weight: .regular, relativeTo: .callout)` |
| `Features/Sessions/SessionView.swift:168` | `AppFonts.body(18, weight: .regular, relativeTo: .body)` |
| `Features/Sessions/SessionView.swift:185` | `AppFonts.body(18, weight: .regular, relativeTo: .body)` |
| `Features/Sessions/SessionView.swift:216` | `AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)` |
| `Features/Map/PrismView.swift:265` | `AppFonts.bodyText` *(orphaned file — see audit; fix only if keeping Map)* |
| `Features/Map/PrismView.swift:365` | `AppFonts.body(12, weight: .regular, relativeTo: .caption)` *(orphaned)* |
| `Design/Components/Input/ToggleRow.swift:14` | `AppFonts.body(15, weight: .regular, relativeTo: .body)` |
| `Design/Components/Cards/CategoryTileView.swift:26` | `AppFonts.display(28, weight: .bold, relativeTo: .title)` *(orphaned file)* |
| `Design/Components/Cards/CardBackView.swift:171` | `AppFonts.body(28, weight: .regular, relativeTo: .title)` |
| `Design/Components/Effects/SparkField.swift:561` | `AppFonts.display(120, weight: .bold, relativeTo: .largeTitle)` |
| `Design/Components/Navigation/RacetrackTabBar.swift:144` | `AppFonts.body(24, weight: .regular, relativeTo: .title3)` |

**28 sites.** ~6 are in orphaned files (`ConstellationNode`, `PrismView`, `CategoryTileView`) — skip those unless you're keeping the file. The other ~22 are live and safe.

---

## Section B — one-line fixes (verified)

| Item | File:line | Change | Risk |
|---|---|---|---|
| `PulseStore` consistency (audit M1) | `Features/Pulse/Store/PulseStore.swift:9-10` | add `@MainActor` line between `@Observable` and `final class PulseStore` | none (matches every other Store) |
| Crash-safety (audit Low) | `Design/Components/Cards/ConversationCard.swift:311` | `try!` → `try?` with a plain-text fallback for the unparsed string | none (host currently orphaned) |
| Dead file (audit Low) | `Vayl/AppIconRetreival.swift` | delete (entire file is commented out) | none |
| Stale comment | `App/Theme/AppSafeArea.swift:106` | drop `GravLiftView` from the consumer comment (file deleted) | none |
| Stale comment | `Features/Learn/Views/ConstellationNode.swift:718` | drop the 28-line dead `ResearchTicker()` integration comment | none |

---

## Section C — presentation-grammar conversions (apply, then device-verify)

These are mechanical edits but they **change interaction behavior** (dismiss-guard, confirm-on-exit, detents) — so not "zero feel." Apply, then verify the dismiss/confirm feel on device. See audit C1/C2/H1.

- `Features/Pulse/PulseWidget.swift:79` `.fullScreenCover` → `.vaylCover` (check-in is a contract cover)
- `Features/Pulse/PulseWidget.swift:66` `.sheet` → `.vaylSheet`
- `Features/Pulse/PulseGraph.swift:137` `.sheet` → `.vaylSheet`
- `Features/Home/Components/ReflectionCard.swift:230` `.sheet` → `.vaylSheet`
- `Features/Home/Components/ReflectionBannerView.swift:218` `.sheet` → `.vaylSheet`
- `Features/Pairing/PairingSettingsView.swift:66,75` `.sheet` → `.vaylSheet`
- `Features/Auth/Views/SignInView.swift:124` `.sheet` → `.vaylSheet`
- `Features/Home/Views/HomeRouterView.swift:77,80` `.fullScreenCover` → `.vaylCover` (Desire Map rater / reveal)
- `Features/Home/Views/HomeRouterView.swift:74` `.sheet` (session) → **needs the C1 decision first** — confirm whether `SessionView` is a protected card session before converting.

---

## Section D — `.font(.system(...))` sites: classification (NOT turnkey)

Converting `.system` → `AppFonts` changes the typeface (SF Pro → Switzer/Clash) — a real visual change. Most of these are legitimately exempt:

**Leave as-is (icons / numerals / marked intentional):**
- `SafeWordButton.swift:17` — comment: intentional fixed-size safety icon
- `ProgressRingView.swift:40` — comment: intentional computed geometric badge
- `InteractiveField.swift:20` — comment: intentional emoji/symbol size
- `StatPhase.swift:500` — comment: `FEEL-GATE`, do not touch
- `PulseGraph.swift:431`, `TierGuideSheet.swift:76` — monospaced numeral displays (`.monospaced`), intentional
- `FindingDetailView.swift:81` (`circle.fill` size 4), `ResearchDatabaseView.swift:129`, `ResourcesOverlayView.swift:18`, `ContentHubSection.swift:224`, `ScoreRing.swift:53,62`, `CardCarousel.swift:473` — SF Symbol icons sized by point; system font is correct for symbols

**Worth a look (likely real text):**
- `HomePulseRail.swift:156` (`size 15, .semibold`) — confirm whether this is a label vs an icon
- `LearnSegmented.swift:34` (`size 15, .medium`) — likely a segment label → `AppFonts.bodyMedium`
- `StatPhase.swift:269` (`size 40`) — comment says "token pending AppLayout"; needs the AppLayout sizing token, not a font token

---

## Section E — proposed `CLAUDE.md` contract patch (the meta-finding)

In **"Required View Patterns → Every card / surface"**, replace the non-existent API:

```diff
- myCard
-     .glassCard()
-     .hairline(.resting)  // or .hairline(.active)
+ myCard
+     .themedCard()        // ThemeModifiers.swift:54
+     // hairlines are properties, not a modifier:
+     // AppGlows.spectrumBorder.hairlineHeight / .hairlineOpacity
```

And in the Violation Checklist, the line `Every OB card: VaylCardFace + AppLayout.obCardWidth/Height + .hairline()` should drop `.hairline()` (or restate it as the AppGlows property). Optionally add an "effect/shader/brand files are a documented raw-color exemption zone" note so the token audit has a clean boundary.
