# Open Lightly — Canonical Naming Reference

Generated: March 9, 2026  
Purpose: Single source of truth for all type names, property names, and init signatures.
**Before writing any code that calls a property or method on a type, look it up here.**

---

## Content Models

### Prompt (`Models/Prompt.swift`)
| Property | Type | Notes |
|----------|------|-------|
| id | UUID | Auto-generated |
| text | String | The prompt question text |
| highlightWords | [String] | Words to highlight (displayed cyan in GradientText) |
| category | PromptCategory | See PromptCategory enum below |
| difficulty | PromptDifficulty | See PromptDifficulty enum below |
| meta | String | Derived from whoStarts.displayText if empty |
| isSensitive | Bool | Drives screenshot protection |
| canSkip | Bool | Whether this card can be skipped |
| whoStarts | WhoStarts | See WhoStarts enum below |
| intensity | CardIntensity (computed) | Derived from difficulty.rawValue via CardIntensity.from(difficulty:) — **exists but PromptDifficulty visual extensions are preferred in UI** |

**Init:**
```swift
Prompt(
    id: UUID = UUID(),
    text: String,
    highlightWords: [String] = [],
    category: PromptCategory = .prompt,
    difficulty: PromptDifficulty = .easy,
    meta: String = "",
    isSensitive: Bool = false,
    canSkip: Bool = true,
    whoStarts: WhoStarts = .partnerA
)
```

**Static data:** `Prompt.samples` — [Prompt]

---

### Card (`Models/Card.swift`)
| Property | Type | Notes |
|----------|------|-------|
| id | UUID | |
| category | CategoryType | |
| cardType | CardType | |
| prompt | String | |
| educationText | String? | nil for plain prompts |
| title | String? | |
| followUp | String? | |
| turnOrder | TurnOrder | |
| difficulty | Difficulty | **Note: This is AppEnums.Difficulty (easy/medium/deep), NOT PromptDifficulty** |
| sortOrder | Int | |
| isFree | Bool | |

**Static data:** `Card.allPlaceholders` — [Card]

---

## Enums

### PromptDifficulty (`Models/Prompt.swift`)
| Case | Raw Value | sortOrder |
|------|-----------|-----------|
| .easy | "Easy" | 0 |
| .light | "Light" | 1 |
| .medium | "Medium" | 2 |
| .deep | "Deep" | 3 |
| .sensitive | "Sensitive" | 4 |
| .ultimate | "Ultimate" | 5 |

**Properties:** `displayName: String`, `sortOrder: Int`  
**Visual extensions (added in PromptCard.swift):** `backgroundTint: Color`, `borderOpacity: Double`, `glowColor: Color`, `glowRadius: CGFloat`  
**Used by:** `Prompt.difficulty`, PromptCard, SessionView (via `prompt.difficulty.glowColor`)

---

### CardIntensity (`App/Theme/AppColors.swift`)
| Case | Raw Value |
|------|-----------|
| .void | 1 |
| .deepOcean | 2 |
| .emberFloor | 3 |
| .split | 4 |
| .nebula | 5 |
| .auroraBand | 6 |
| .deepSpace | 7 |
| .supernova | 8 |

**Properties:** `id: Int`, `backgroundColor: Color`, `backgroundGradient: LinearGradient?`, `usesGradientBackground: Bool`, `cyanWash`, `magentaWash`, `glowRadius: CGFloat`, `glowMultiplier: Double`, `cyanGlowOpacity: Double`, `magentaGlowOpacity: Double`, `displayName: String`, `difficultyLabel: String`  
**Static methods:** `CardIntensity.from(difficulty: String) -> CardIntensity`, `CardIntensity.from(score: Int) -> CardIntensity`  
**Used by:** `Prompt.intensity` (computed). **CardIntensity does NOT have: backgroundTint, borderOpacity, glowColor — these are on PromptDifficulty.**  
**Status:** Partially redundant with PromptDifficulty. See Conflicts section.

---

### PromptCategory (`Models/Prompt.swift`)
| Case | Raw Value |
|------|-----------|
| .prompt | "Prompt" |
| .reflect | "Reflect" |
| .deepDive | "Deep Dive" |
| .explore | "Explore" |
| .fantasy | "Fantasy" |
| .kinkMap | "Kink Map" |
| .ultimate | "Ultimate" |

**Properties:** `displayName: String`  
**Usage in code:** `prompt.category.rawValue` for display (rawValue is already human-readable)

---

### WhoStarts (`Models/Prompt.swift`)
| Case | Raw Value |
|------|-----------|
| .partnerA | "partnerA" |
| .partnerB | "partnerB" |
| .either | "either" |
| .both | "both" |

**Properties:** `displayText: String`

---

### CategoryPhase (`Models/Enums/AppEnums.swift`)
Cases: `.foundation`, `.exploration`, `.framework`, `.planning`  
**Properties:** `displayName: String`, `color: Color`

---

### CategoryType (`Models/Enums/AppEnums.swift`)
Cases: `.relationshipHealth`, `.insecurities`, `.sexualSatisfaction`, `.compatibility`, `.boundaries`, `.nmLogistics`  
**Properties:** `displayName: String`, `cardPrefix: String`, `icon: String`, `phase: CategoryPhase`, `sortOrder: Int`, `requiresUnlock: Bool`

---

### CardType (`Models/Enums/AppEnums.swift`)
Cases: `.prompt`, `.education`, `.educationPrompt`, `.coolOff`  
**Properties:** `displayName: String`

---

### CardStatus (`Models/Enums/AppEnums.swift`)
Cases: `.notStarted`, `.discussed`, `.skipped`, `.bookmarked`  
**Properties:** `displayName: String`

---

### Difficulty (`Models/Enums/AppEnums.swift`)
**⚠️ NOTE: This is a SEPARATE enum from PromptDifficulty.**  
Cases: `.easy`, `.medium`, `.deep`  
**Properties:** `displayName: String`, `color: Color`  
**Used by:** `Card.difficulty` (the content model card, not Prompt)

---

### Sensitivity (`Models/Enums/AppEnums.swift`)
Cases: `.low`, `.medium`, `.high`  
**Properties:** `displayName: String`

---

### Rating (`Models/Enums/AppEnums.swift`)
Cases: `.love`, `.curious`, `.neutral`, `.hardNo`  
**Properties:** `label: String`, `emoji: String`  
**Note:** Uses `label` not `displayName` — this is intentional.

---

### MatchType (`Models/Enums/AppEnums.swift`)
Cases: `.mutualYes`, `.exploreZone`, `.worthDiscussing`  
**Properties:** `displayName: String`

---

### SessionStatus (`Models/Enums/AppEnums.swift`)
Cases: `.notStarted`, `.inProgress`, `.paused`, `.completed`  
**Properties:** `displayName: String`

---

### TurnOrder (`Models/Enums/AppEnums.swift`)
Cases: `.partnerA`, `.partnerB`, `.together`  
**Properties:** `displayName: String`

---

### PartnerLabel (`Models/Enums/AppEnums.swift`)
Cases: `.partnerA`, `.partnerB`  
**Properties:** `displayName: String`, `opposite: PartnerLabel`

---

### ReadinessLevel (`Models/Enums/AppEnums.swift`)
Cases: `.thriving`, `.ready`, `.someGaps`, `.significantConcerns`, `.notReady`  
**Properties:** `displayName: String`, `scoreRange: ClosedRange<Int>`, `color: Color`  
**Static:** `ReadinessLevel.level(for: Int) -> ReadinessLevel`

---

### AssessmentDomain (`Models/Enums/AppEnums.swift`)
Cases: `.communication`, `.trust`, `.emotionalSecurity`, `.sexualOpenness`, `.boundaryAwareness`  
**Properties:** `displayName: String`, `weight: Double`

---

### AssessmentQuestionType (`Models/Enums/AppEnums.swift`)
Cases: `.scale`, `.multiSelect` (raw: "multi_select")  
**Properties:** `displayName: String`

---

### PurchaseTier (`Models/Enums/AppEnums.swift`)
Cases: `.free`, `.core`, `.complete`  
**Properties:** `displayName: String`  
**Methods:** `includesCategory(_ category: CategoryType) -> Bool`

---

### NMFlavor (`Models/Enums/AppEnums.swift`)
Cases: `.swinging`, `.openRelationship`, `.polyamory`, `.relationshipAnarchy`, `.monogamish`, `.unsure`  
**Properties:** `displayName: String`

---

## AppColors Canonical Names (`App/Theme/AppColors.swift`)

| Token | Property Name | Value |
|-------|--------------|-------|
| Page background | `AppColors.background` | alias for `pageBg` = #030305 |
| Card background | `AppColors.card` | alias for `cardBg` = #050507 |
| Elevated card | `AppColors.cardElevated` | alias for `surfaceRaised` = #0C0C10 |
| Border | `AppColors.border` | `Color.white.opacity(0.06)` |
| Primary text | `AppColors.textPrimary` | #E8E8F0 |
| Secondary text | `AppColors.textSecondary` | #AAAABC |
| Tertiary text | `AppColors.textTertiary` | #666680 |
| Muted text | `AppColors.textMuted` | `Color.white.opacity(0.20)` |
| Cyan | `AppColors.cyan` | #00C2FF |
| Purple | `AppColors.purple` | #6C3AE0 |
| Magenta | `AppColors.magenta` | #FF006A |
| Gold (safety only) | `AppColors.gold` | #C8960A |
| Spectrum gradient | `AppColors.spectrumGradient` | cyan -> purple -> magenta, topLeading -> bottomTrailing |
| Spectrum border | `AppColors.spectrumBorder` | identical to spectrumGradient (legacy name) |
| Glow cyan | `AppColors.glowCyan` | #00C2FF |
| Glow magenta | `AppColors.glowMagenta` | #FF006A |
| Glow purple | `AppColors.glowPurple` | #6C3AE0 |

**Also available (original names, still valid):**
`pageBg`, `cardBg`, `surfaceBg`, `surfaceRaised`, `tintCyan`, `tintPurple`, `tintMagenta`, `tintNavy`, `tintIndigo`, `tintPlum`, `borderHover`, `borderActive`, `badgeBg`, `success`, `destructive`

---

## AppFonts Canonical Names (`App/Theme/AppFonts.swift`)

| Token | Property | Notes |
|-------|----------|-------|
| Hero display | `AppFonts.heroTitle` | ClashDisplay-Bold 42pt |
| Card title | `AppFonts.cardTitle` | ClashDisplay-Semibold 22pt |
| Section heading | `AppFonts.sectionHeading` | ClashDisplay-Medium 20pt |
| Body text | `AppFonts.bodyText` | Switzer-Regular 16pt |
| Body medium | `AppFonts.bodyMedium` | Switzer-Medium 15pt |
| Caption | `AppFonts.caption` | Switzer-Regular 13pt |
| Overline | `AppFonts.overline` | Switzer-Semibold 11pt — use with `.tracking(2)` and `.textCase(.uppercase)` |
| Button label | `AppFonts.buttonLabel` | Switzer-Semibold 14pt — **NOTE: has a syntax error in source, see below** |

**Functions:** `AppFonts.display(_ size: CGFloat, weight: Font.Weight) -> Font`  
`AppFonts.body(_ size: CGFloat, weight: Font.Weight) -> Font`

---

## AppPalette (Theme Environment) (`Design/Theme/AppTheme.swift`)

Access via `@Environment(\.theme) private var t`

| Property | Type | Notes |
|----------|------|-------|
| t.bg | Color | Page background |
| t.bgElevated | Color | |
| t.surface1 | Color | |
| t.surface2 | Color | |
| t.surface3 | Color | |
| t.border | Color | |
| t.borderSubtle | Color | |
| t.text | Color | Primary text |
| t.textSecondary | Color | |
| t.textMuted | Color | |
| t.success | Color | |
| t.successDim | Color | |
| t.error | Color | |
| t.errorDim | Color | |
| t.cyan | Color | |
| t.magenta | Color | |
| t.navy | Color | |
| t.gold | Color | Safety only |
| t.glowOpacity | Double | |
| t.glowCyan | Color | |
| t.glowMagenta | Color | |
| t.glowGold | Color | |
| t.isAmoled | Bool | |
| t.spectrumGradient | LinearGradient | cyan -> magenta -> navy |
| t.buttonGradient | LinearGradient | cyan -> magenta |
| t.ringGradient | AngularGradient | |
| t.cardBorder | Color | Computed from isAmoled |

---

## Component Init Signatures

| Component | Init Parameters |
|-----------|----------------|
| `GradientText` | `fullText: String, keywords: [(text: String, type: String)], font: Font = AppFonts.cardTitle, baseColor: Color = AppColors.textPrimary` |
| `PromptCard` | `prompt: Prompt` |
| `RatingButtonGroup` | `@Binding selected: Rating?` |
| `CategoryTileView` | `emoji: String, title: String, completedCards: Int, totalCards: Int` |
| `ProgressRingView` | `progress: Double, lineWidth: CGFloat = 6, size: CGFloat = 60` |
| `SafeWordButton` | `onActivate: () -> Void` |
| `GlowOrb` | `color: Color, size: CGFloat = 200` |
| `GradientButton` | `title: String, action: () -> Void = {}` |
| `GradBadge` | `text: String` |
| `CriticalButton` | `title: String, icon: String, style: CriticalStyle = .neutral, action: () -> Void = {}` |
| `InteractiveField` | `placeholder: String, icon: String, @Binding text: String` |
| `ProgressBar` | `value: Double, max: Double` |
| `SpectrumBar` | `height: CGFloat = 3` |
| `ScoreRing` | `score: Int, size: CGFloat = 110, lineWidth: CGFloat = 9` |
| `ScreenshotProtectionModifier` | (used via `.screenshotProtected()` extension on View) |

---

## Conflicts and Issues

### CONFLICT 1: Two separate difficulty systems
- **`PromptDifficulty`** (in `Models/Prompt.swift`): Used by `Prompt.difficulty`. 6 cases. Has visual extensions (backgroundTint, borderOpacity, glowColor, glowRadius) added in PromptCard.swift.
- **`Difficulty`** (in `Models/Enums/AppEnums.swift`): Used by `Card.difficulty` (content card model). 3 cases (easy/medium/deep). Has `color: Color` property.
- **`CardIntensity`** (in `App/Theme/AppColors.swift`): 8-level visual scale. Derived from PromptDifficulty via `CardIntensity.from(difficulty: String)`. Lives in AppColors.swift, not Enums.
- **Resolution:** These serve different purposes. Do NOT merge them. Use:
  - `PromptDifficulty` for `Prompt` model difficulty
  - `Difficulty` for `Card` (content model) difficulty
  - `CardIntensity` only if needing the 8-level visual system explicitly (currently unused in UI — PromptDifficulty visual extensions cover UI needs)

### CONFLICT 2: CardIntensity visual properties don't exist
`CardIntensity` does NOT have: `backgroundTint`, `borderOpacity`, `glowColor` (as a direct property).  
These are defined on `PromptDifficulty` in the extension in PromptCard.swift.  
**Never call these on CardIntensity.**

### CONFLICT 3: AppColors vs AppPalette (t.)
Some components use `AppColors.xxx` (static struct), others use `t.xxx` (theme environment).  
- `AppColors` = static values, AMOLED only, no light mode adaptation
- `t` = theme-adaptive, responds to ThemeManager  
- **Rule:** New components should use `t.xxx`. Legacy/background components may use `AppColors.xxx`.  
- PromptCard.swift uses `AppColors` directly (no `t`) — this is intentional for now.

### CONFLICT 4: AppFonts.buttonLabel has a syntax error
Line: `static var buttonLabel: Font { body(14, weight: weight: .semibold) }`  
Has a duplicate `weight:` label. This will cause a compile error if used.  
**Fix needed in AppFonts.swift.**

### ISSUE 5: Prompt.intensity exists but is rarely needed in UI
`Prompt.intensity` returns `CardIntensity`, derived from `difficulty.rawValue`.  
In SessionView and PromptCard, `prompt.difficulty.glowColor` is used directly instead.  
`Prompt.intensity` is available if the full 8-level system is ever needed.

---

## Batch 8 — SwiftData Persistence

### Models (in Models/Persistence/)

#### SessionRecord (@Model)
| Property | Type | Notes |
|----------|------|-------|
| id | UUID | Auto-generated |
| date | Date | Defaults to .now |
| category | String | Raw string of category |
| difficulty | String | Raw string of PromptDifficulty |
| promptsShown | [String] | Prompt texts shown |
| durationSeconds | Int | Session length |
| partnerName | String? | nil for solo |
| completedFully | Bool | false if safe-worded |
| ratings | [RatingRecord] | @Relationship(deleteRule: .cascade) |

#### RatingRecord (@Model)
| Property | Type | Notes |
|----------|------|-------|
| id | UUID | Auto-generated |
| date | Date | Defaults to .now |
| promptText | String | Prompt text or kink item id |
| category | String | Raw string category |
| reaction | String | "liked" / "disliked" / "skipped" or Rating.rawValue |
| session | SessionRecord? | nil for kink map ratings |

#### StreakRecord (@Model)
| Property | Type | Notes |
|----------|------|-------|
| id | UUID | Auto-generated |
| currentStreak | Int | Consecutive days, resets on gap |
| lastActiveDate | Date | Defaults to .distantPast |
| longestStreak | Int | All-time best |
| totalSessions | Int | Lifetime count |
| totalPromptsRated | Int | Lifetime count |

### DataStore (in Data/Store/)

| Method | Parameters | Returns | Called From |
|--------|-----------|---------|------------|
| init(context:) | ModelContext | — | All screens |
| saveSession(...) | category, difficulty, promptsShown, durationSeconds, reactions, partnerName?, completedFully | Void | SessionView |
| fetchAllSessions() | — | [SessionRecord] | HomeView, ProgressDashboard |
| fetchSessions(forCategory:) | String | [SessionRecord] | ProgressDashboard |
| fetchRatings(byReaction:) | String | [RatingRecord] | KinkMapView, Progress |
| fetchRatings(forCategory:) | String | [RatingRecord] | KinkMapView, Progress |
| fetchOrCreateStreak() | — | StreakRecord | HomeView, ProgressDashboard |
| deleteSession(_:) | SessionRecord | Void | Future history screen |
| deleteAllData() | — | Void | SettingsView |

### ModelContainer+App (in Data/)

| Property | Type | Notes |
|----------|------|-------|
| .appContainer | ModelContainer (static) | Production — persists to disk |
| .previewContainer | ModelContainer (static) | In-memory — previews and tests |

### Screen Integration

| Screen | What it reads | What it writes |
|--------|--------------|---------------|
| SessionView | — | saveSession() on end |
| HomeView | streak, lastSession | — |
| ProgressDashboardView | streak, allSessions, ratings per category | — |
| KinkMapView | saved kink ratings on appear | saveRating per tap |
