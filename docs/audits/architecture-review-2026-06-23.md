# Vayl — Architecture Review & Cleanup Plan (2026-06-23)

Companion to the contract audit. Answers four questions: (1) is the architecture efficient / where has it drifted, (2) do the Onboarding files need splitting, (3) unused-element use-or-delete triage, (4) senior-dev opinion on the View-Store model & organization. All deletion candidates below were **hand-verified** for zero external references.

---

## Q1 — Architecture conformance & drift

**Verdict: the architecture is sound and genuinely followed (≈8.5/10).** View→Store→Service→Model holds; Stores are uniformly `@Observable @MainActor`; Services are injected; Models are pure; zero legacy iOS anti-patterns. The drift is at the edges, not structural.

### Layer scorecard
| Layer | Status | Note |
|---|---|---|
| View | Conforming (1 exception) | No tokens/Service calls in production views. Exception: `PlayView.swift:75,77` instantiates `RealtimeSessionService()`/`ProfileService()` in a `#if DEBUG` harness. |
| Store | Conforming | All `@Observable @MainActor` except `PulseStore` (missing `@MainActor`) and `SyncManager` (still `ObservableObject`/`@Published`). |
| Service | Conforming | No View imports, no Store refs. |
| Model | Conforming | Pure structs; SwiftData `@Model` types appropriate. |

### Drift findings (ranked)
1. **`SyncManager` is the lone `ObservableObject` + `static let shared` singleton.** Stores reach for `SyncManager.shared` directly (`SessionStore:197`, `PairingStore:221`, `DesireMapStore:156`). Pragmatically fine for a fire-and-forget sync orchestrator, but it's the one spot that breaks both "Stores use `@Observable`" and "Services are injected." **Fix:** migrate `SyncManager` to `@Observable @MainActor`; either inject a sync closure into the stores or formally document the singleton as an allowed infrastructure exception in CLAUDE.md. Pick one and be consistent.
2. **`PulseStore` missing `@MainActor`** (`PulseStore.swift:9-10`) — one-line fix, also uses UserDefaults directly vs SwiftData like the others.
3. **`DataStore.swift` (222 LOC) is dead** — a full CRUD persistence class from the "Open Lightly" era, referenced only by the orphaned `ProgressDashboardView`. Every live store uses a fresh `ModelContext` directly. Delete with ProgressDashboardView.
4. **`PlayView` DEBUG service instantiation** — move behind a `SessionDebugStore` (low urgency, DEBUG-only).
5. **`AppState`** does routing + UserDefaults I/O inline. Acceptable as a documented exception (fast-startup routing cache); no change needed.
6. **`ForEach(Array(enumerated()), id: \.offset)`** in ~13 spots — fine where position drives animation timing; switch to `\.element.id` where identity is what matters (avoids redraw on reorder).

**The real risk is scale, not rot:** `VaylDirector` (395) + lazy sequencers and `NamePhase` (937) are creeping. Refactor-when-it-hurts, and that point is near for the OB phases (see Q2).

---

## Q2 — Do the Onboarding files need splitting?

**Verdict: the OB subsystem (11,672 LOC / 45 files) is well-organized; ~3 files need splitting, not all of them.** The fix is to apply the pattern you already invented — `GenderSequencer` (445 LOC, all state/orchestration extracted; `GenderPhase` is then a pure renderer) — to the phases that still embed their controllers inline.

### Split these (extract the embedded controller; mirror GenderSequencer)
| File | LOC | Why | Extract |
|---|---|---|---|
| `NamePhase.swift` | 937 | 5 concerns in one file | `NameInputController` (field/reveal/submit) + `CardDealController` (deal/flip/center/collect) |
| `DemoPhase.swift` | 654 | composition mechanic crammed in | `DemoCompositionController` (verb drum / noun field / sentence melt / seal) — ideally a `DemoSequencer` in `Canvas/Sequencers/` |
| `BuildDeckPhase.swift` | 633 | crack ceremony is a subsystem | `CrackCeremonyController` (armed/charge/recoil/sparks/burst) |

### Leave as-is (cohesive single-concern, just long)
- `TableSurfaceView.swift` (850) — 6 draw passes of one canvas, no logic.
- `OBDeepCardFace.swift` (765) — pure shader/particle rendering.
- `StatPhase` (619), `GenderPhase` (553), `ModeSelect/ExperienceLevel/Curiosity/Context` phases — already thin renderers delegating to director/sequencers. **These are the model to copy.**

### Folder organization
- **One inconsistency worth fixing:** `GenderSequencer` lives in `Canvas/Sequencers/` but `CuriositySequencer` lives in `Director/`. Move `CuriositySequencer` → `Canvas/Sequencers/` so all phase orchestrators sit together; keep `Director/` for the director + ceremony/projector utilities only.
- Otherwise the structure (Phases / Canvas / Director / Renders / Components / Models / Store) is coherent.

**Priority:** (1) move CuriositySequencer (5-min clarity win), (2) split NamePhase, (3) DemoPhase, (4) BuildDeckPhase. Each is a feel-sensitive refactor → segment it and verify on device per the build protocol.

---

## Q3 — Unused elements: use, or label for deletion

### ✅ Safe to delete now — VERIFIED zero external references
1. `Vayl/AppIconRetreival.swift` (entire file commented out; also uses banned `UIApplication.shared`)
2. `Vayl/Design/Components/Cards/CardFrontView.swift`
3. `Vayl/Design/Components/Cards/PromptCard.swift`
4. `Vayl/Design/Components/Cards/CardRevealPillButton.swift`
5. `Vayl/Design/Components/Cards/CategoryTileView.swift`
6. `Vayl/Design/Components/Effects/GlowUnderline.swift`
7. `Vayl/Design/Components/Effects/GlowUnderlineView.swift`
8. `Vayl/Design/Components/Text/KeywordHighlightText.swift`
9. `Vayl/Design/Components/Navigation/OnboardingNavBar.swift`
10. `Vayl/Features/Onboarding/Layout/OnboardingLayout.swift`
11. `Vayl/Features/Home/Components/ReflectionCard.swift` (708 LOC; superseded by the LIVE `ReflectionBannerView`)
12. `Vayl/Design/Components/Effects/OrbitSparkBorderView.swift` — also remove `OrbitSpark.metal` *after* confirming no other shader consumer
13. **Pair:** `Vayl/Features/Progress/ProgressDashboardView.swift` + `Vayl/Core/Persistence/DataStore.swift` — ProgressDashboardView is orphaned and is DataStore's only consumer; streaks/sessions dashboard also contradicts the product's no-streaks stance (Map = Pulse). Delete together.

> ⚠️ **Correction to agent triage:** `CardStyle.swift` / `.cardStyle()` is **NOT dead** — it's used by `SessionView`, `SettingsCard`, `ProgressDashboardView`. Keep it (it's a parallel modifier to `.themedCard()`; consider consolidating later, but don't delete).

### 🟡 KEEP-WIP — real scaffolding for active roadmap (don't delete, do track)
- `SettingsView.swift` — the real Settings screen, just not routed yet (on the routing roadmap).
- `SectionHairline.swift` — committed yesterday, awaiting wiring into Learn section headers.
- `DeckWrapView.swift` — shelved alt from the in-flight BuildDeck ceremony.
- `OBDeepCardFace.swift` — recent, polished; competes with `VaylCardFace` for NamePhase's face. Decide NamePhase's face, then keep or cut.

### 🔵 USE-or-DELETE — too much quality to sit idle (your call)
- `FilamentMode.swift` (876 LOC orbital-trail system) — adopt as an ambient field (Map/Pulse/splash) or cut.
- `PrismView.swift` (833) — built for the retired home stack; **harvest its Agreements pane** for the Map Vault, then delete the widget.
- `ConstellationView` / `ConstellationNode.swift` (772) — **harvest the curated glossary content** (compersion, NRE, metamour, "1 in 5"…) into Learn, then delete the viz.
- `ConversationCard.swift` — polished OB question-card stub; delete if the OB question-card redesign is dropped, else KEEP-WIP and fix the `try!` at line 311 first.

### Carousels — all three LIVE (no dead one)
`CardCarousel` (Home), `VaylCardCarousel` (Onboarding), `InfiniteCarousel` (Learn) each own one tab. Prior "duplicate" suspicion was unfounded.

### Unused design tokens (~63)
- **KEEP (contract-mandated):** `AppRadius.micro`, `AppRadius.foilEdge`, `AppAnimation.deckFan`, `AppAnimation.deckWeave`, and the OB/coach-mark animation token group — these are the contract surface mid-redesign ("unused" = consumption gap).
- **DELETE candidates (no consumer, no roadmap home):** the 10 `cardIntensityTint*` colors (feature never shipped), the 6 named `shimmer*` colors (superseded by `lightShimmerColors`), `debugFontList`, and one-off colors `constellationNodeCore`, `appIconBackground`, `iconBadgeAmber/Gold/Magenta`, `gradientStop1/2/3`, `glassFrostCTA`, `inputLabelFocused`, `pillGlow`, `pillSurfaceBottom`. (Two-second grep each before pruning.)

---

## Q4 — Senior-dev opinion: keep View-Store, or reorganize?

**Keep it. The View→Store(`@Observable`)→Service→Model model is the correct, modern choice for this app — it IS current idiomatic SwiftUI** (Apple's Observation framework is built for exactly this "MV with observable stores" shape). For a solo dev shipping a relationship app of this complexity, this is the right altitude:

- **Don't adopt TCA / VIPER / Clean.** They'd add ceremony and boilerplate that slow a solo dev without buying you anything here — you don't have the multi-team scale or the strict-audit requirements that justify them. Your current model already gives you testable Stores and dumb Views.
- **Feature-first folders are right.** `Features/<X>/{Store,Views,Models}` + a shared `Design/` system + `Core/{Services,Models,Persistence}` is exactly how I'd organize this. Keep it.
- **Where it's stronger than typical:** the design-token contract, the single phase-advance authority (`VaylDirector`), and uniform `@Observable @MainActor` stores are more disciplined than most indie codebases I see.

**The 5 things I'd actually do (in order):**
1. Make `SyncManager` consistent — `@Observable @MainActor`, and decide injected-closure vs documented-singleton. Right now it's the one architectural inconsistency that'll spread if copied.
2. Add `@MainActor` to `PulseStore`.
3. Delete the verified dead files (Q3) — clears ~3,500+ LOC of "Open Lightly"-era noise that makes the codebase look bigger/messier than it is.
4. Apply the `GenderSequencer` pattern to NamePhase/DemoPhase/BuildDeckPhase (Q2).
5. Standardize a Store convention: every feature's store under `Features/<X>/Store/` (a few live at the feature root, e.g. `CoupleSessionStore`, `SessionStore`).

Net: this is a clean, well-architected codebase. It doesn't need reorganizing — it needs a dead-code sweep and three OB phase splits. Don't rewrite what's working.
