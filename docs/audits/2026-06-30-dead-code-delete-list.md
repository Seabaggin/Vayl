# Dead-Code Delete List (vetted)

_Date: 2026-06-30. Companion to `2026-06-30-ios-codebase-audit.md`._

**How this was verified:** every confirmed-dead file was re-checked at the **symbol level** (all exported types, funcs, extension methods, and typealiases grepped against all live files), not just by its type name. That caught 3 misclassifications the type-name sweep missed. The 48 in the "safe" section have zero live references to any symbol they export.

**Belt-and-suspenders before you delete:** the app target uses a synchronized file group, so deleting a file from disk removes it from the build (no `.pbxproj` edit). Everything is git-tracked, so any delete is recoverable with `git checkout -- <path>`. After a batch, a simulator build is the compiler-proof that nothing live depended on them.

---

## 1. DO NOT DELETE — verified live (audit was wrong)

| File | Why it stays |
|---|---|
| `Vayl/Features/Map/Components/FlavorVisuals.swift` | `FlavorChip` / `FlavorPortrait` / `DrawnTagChip` are used by `MeCardSheet` (`MapView:85`) and `MeCardCompact` (`MapView:201`). **Partial-dead only** — `FlavorSigil` / `CoupleCrestSigil` / `CoupleCrestPortrait` inside it may be unused; prune those individually later if you want, but keep the file. |
| `Vayl/Features/Onboarding/Phases/CredentialEditorSheet.swift` | Exports `CredentialEditorOverlay`, presented by the live OB canvas at `OnboardingCanvasView:194,381` (driven by `director.editingCredential`). |

---

## 2. DELETE ONLY WITH A COORDINATED EDIT — 3 card faces

These are runtime-dead (no live data ever builds their content case) but the **live** `VaylCardFace` renderer names them, so a standalone `rm` breaks the build. Do all three edits per face, together:

| Delete file | Remove switch arm | Remove enum case |
|---|---|---|
| `Design/Components/Cards/CardFaces/SlotMachineCardFace.swift` | `VaylCardFace.swift:158` (`case .slotMachine:`) | `VaylCardContent.swift:45` (`case slotMachine`) |
| `Design/Components/Cards/CardFaces/CompassOptionCardFace.swift` | `VaylCardFace.swift:196` (`case .compassOption(let label):`) | `VaylCardContent.swift:66` (`case compassOption(label:)`) |
| `Design/Components/Cards/CardFaces/CompassSliderCardFace.swift` | `VaylCardFace.swift:202` (`case .compassSlider(let value, let dragging):`) | `VaylCardContent.swift:72` (`case compassSlider(value:dragging:)`) |

After removing the enum cases, the `VaylCardFace` switch stays exhaustive (only that one switch references them — verified). Note: line numbers will shift as you edit; anchor on the symbol names.

---

## 3. SAFE TO DELETE — 48 files (~10.8k LOC)

Zero live references to any exported symbol. Delete the whole set together (or whole feature-groups) so internal dead-references-dead chains go together. Known chains, all fully inside this set: `CardStyle ⇄ ProgressDashboardView`, `PremiumCardShell → CardFrontView/PromptCard`, `CuriosityFlipCard → CuriosityCardBack → MazePatternView → TileOrbitView`, `OnboardingNavBar → NavArrow`, `SectionHeader ← ProgressDashboardView`.

### 3a. Two are compiler-safe but you previously marked them "keep for reference" — your call
- [ ] `Vayl/Features/Map/PrismView.swift` (833) — you noted "keep to mine visually."
- [ ] `Vayl/Features/Play/Components/RotaryDial.swift` (166) — filetracker: "archived pattern, kept for reference."

### 3b. Home
- [ ] `Vayl/Features/Home/Views/HomeGateView.swift` (297)
- [ ] `Vayl/Features/Home/Components/DesireMapIndicator.swift` (298)
- [ ] `Vayl/Features/Home/Components/ReflectionCard.swift` (708)
- [ ] `Vayl/Features/Home/Components/CardChestContainer.swift` (30)
- [ ] `Vayl/Features/Home/Models/HomeEventEngine.swift` (103)

### 3c. Progress (whole folder)
- [ ] `Vayl/Features/Progress/ProgressDashboardView.swift` (207)

### 3c-bis. Home (correction added 2026-06-30)
- [ ] `Vayl/Features/Home/Components/HomeWidgetShell.swift` (702) — **not on the original list; found during token-debt work.** Its only consumer is `PrismView` (already confirmed dead above), so it's transitively dead too — the original sweep didn't chain through a preview-only instantiation correctly. 33 raw opacity literals live here that don't count toward any live token debt.

### 3d. Pulse (legacy check-in cluster)
- [ ] `Vayl/Features/Pulse/PulseWidget.swift` (31)
- [ ] `Vayl/Features/Pulse/PulseCheckInCover.swift` (36)
- [ ] `Vayl/Features/Pulse/CheckInShell.swift` (29)
- [ ] `Vayl/Features/Pulse/DailyCheckInView.swift` (33)
- [ ] `Vayl/Features/Pulse/PulseSheetView.swift` (25)
- [ ] `Vayl/Features/Pulse/TierGuideSheet.swift` (127)

### 3e. Learn / Desire Map / Onboarding
- [ ] `Vayl/Features/Learn/Views/ConstellationNode.swift` (772)
- [ ] `Vayl/Features/Desire Map/Views/Components/ConstellationField.swift` (261)
- [ ] `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift` (765)
- [ ] `Vayl/Features/Onboarding/Layout/OnboardingLayout.swift` (100)
- [ ] `Vayl/Features/Onboarding/Components/DeckWrapView.swift` (65)

### 3f. Play
- [ ] `Vayl/Features/Play/Components/ZoomablePanView.swift` (52)

### 3g. Design / Cards (abandoned shell chain)
- [ ] `Vayl/Design/Components/Cards/CardFrontView.swift` (112)
- [ ] `Vayl/Design/Components/Cards/CardStyle.swift` (50)
- [ ] `Vayl/Design/Components/Cards/PromptCard.swift` (34)
- [ ] `Vayl/Design/Components/Cards/PremiumCardShell.swift` (221)
- [ ] `Vayl/Design/Components/Cards/CuriosityFlipCard.swift` (73)
- [ ] `Vayl/Design/Components/Cards/CuriosityCardBack.swift` (160)
- [ ] `Vayl/Design/Components/Cards/CardRevealPillButton.swift` (105)
- [ ] `Vayl/Design/Components/Cards/CategoryTileView.swift` (90)

### 3h. Design / Effects
- [ ] `Vayl/Design/Components/Effects/FilamentMode.swift` (876)
- [ ] `Vayl/Design/Components/Effects/SparkField.swift` (628)
- [ ] `Vayl/Design/Components/Effects/AuroraGlowField.swift` (313)
- [ ] `Vayl/Design/Components/Effects/TileOrbitView.swift` (353)
- [ ] `Vayl/Design/Components/Effects/MazePatternView.swift` (185)
- [ ] `Vayl/Design/Components/Effects/OrbitSparkBorderView.swift` (58)
- [ ] `Vayl/Design/Components/Effects/GlowUnderline.swift` (72)
- [ ] `Vayl/Design/Components/Effects/GlowUnderlineView.swift` (59)
- [ ] `Vayl/Design/Components/Effects/GradBadge.swift` (44)
- [ ] `Vayl/Design/Components/Effects/SectionHairline.swift` (35)
- [ ] `Vayl/Design/Components/Effects/SectionHeader.swift` (17)

### 3i. Design / Navigation, Progress, Input, Text, Buttons, Theme
- [ ] `Vayl/Design/Components/Navigation/NavArrow.swift` (296)
- [ ] `Vayl/Design/Components/Navigation/OnboardingNavBar.swift` (117)
- [ ] `Vayl/Design/Components/Progress/OrbitIndicator.swift` (695)
- [ ] `Vayl/Design/Components/Progress/SpectrumBar.swift` (18)
- [ ] `Vayl/Design/Components/Input/ToggleRow.swift` (28)
- [ ] `Vayl/Design/Components/Text/KeywordHighlightText.swift` (66)
- [ ] `Vayl/Design/Components/Buttons/CriticalButton.swift` (50)
- [ ] `Vayl/Design/Components/Buttons/SafeWordButton.swift` (59)
- [ ] `Vayl/App/Theme/AppGrid.swift` (119)

---

## 4. NOT in the 48 — shelved, decide separately (do NOT blind-delete)

- `Vayl/Core/Services/PushService.swift` — **unbuilt feature, not dead** (T1 notifications, waiting to be wired). Keep.
- `Vayl/Core/Debug/DiagnosticOverlay.swift`, `Vayl/Core/Debug/DragDebugView.swift`, `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` — dev tools. Keep if still useful.
- `Vayl/Design/Brand/VaylAppIcon.swift` + `Vayl/AppIconRetreival.swift` — icon-export dev tooling.
- `Vayl/Core/Models/SessionRecord.swift` — Open-Lightly-era `@Model`, not in `SchemaV1`; likely dead but verify against `SessionSyncService` before removing.

---

## 5. After deleting

Build to confirm nothing live depended on the set:
```
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/vayl-dd -quiet build CODE_SIGNING_ALLOWED=NO
```
Green = compiler-proof the deletions were safe. (Use a scratch `-derivedDataPath` if Xcode is open, so you don't race its cache.)
