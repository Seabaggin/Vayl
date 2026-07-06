# Learn Tab — Stub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the redesigned Learn tab as compiling Swift stubs — 4-layer architecture, three color-coded sections (cyan quizzes / purple research / magenta content hub), research database + finding detail + resources overlay via `.vaylSheet`, all driven by seed JSON — so the structure is real and navigable, with feel-tuning and full logic deferred to a later pass.

**Architecture:** Mirror the Home tab's 4-layer pattern. `LearnRouterView` → `LearnRouterInnerView` (creates `LearnStore`, owns sheet state) → `LearnDashboardView` (three sections). Content is read-only, loaded from JSON via the existing `ContentLoader` into `Codable` models. Section color-coding uses a new single-color `SectionHairline`. Database browse + finding detail + resources are `.vaylSheet` presentations.

**Tech Stack:** SwiftUI, Swift 6, iOS 16+ baseline, `@Observable @MainActor` stores, `ContentLoader` JSON, design tokens only (AppColors / AppFonts / AppSpacing / AppRadius / AppGlows). No raw values in views.

**Reference (front-end feel source):** `docs/mockups/learn-tab.html`. The stubs establish structure only — the carousel feel, card polish, and filter logic come in the deeper pass, which per the Build Protocol must be prototyped in that mockup before Swift.

---

## Scope & boundaries

**In scope (this plan):** compiling stubs for the Learn tab front end + the read-only content data layer (models + seed JSON + loader use).

**Out of scope (deferred):**
- The automated research-ingestion pipeline (OpenAlex → Supabase staging → human review → publish) — parked sub-project; see memory `learn_research_pipeline`. This plan's JSON files are the hand-curated seed it will eventually replace.
- Carousel physics / paging feel, real card layouts, the database filter/sort logic, quiz flows, Learn→Play discussion-card routing — the "deeper pass."
- Personalization by Orientation-Map position — parked.

## Back-end / data layer

The Learn tab is read-only in V1; the "back end" is the content schema. Each model below defines the shape the future ingestion pipeline must emit. Tag/topic vocabulary and `FindingType` are the controlled vocabularies categories derive from (no hand-picked category list).

## File structure

```
Vayl/Core/Models/Learn/
  ResearchFinding.swift      # ResearchFinding + FindingType
  LearnMediaItem.swift       # LearnMediaItem + MediaKind
  Voice.swift                # Voice + VoiceKind
  SupportResource.swift      # SupportResource + ResourceTier
  LearnQuiz.swift            # LearnQuiz
Vayl/Core/Models/Learn/FindingType+Display.swift   # icon/color/label mapping
Vayl/Resources/Content/
  learn_quizzes.json
  research_findings.json
  learn_media.json
  voices.json
  support_resources.json
Vayl/Design/Components/Effects/SectionHairline.swift   # single-color hairline
Vayl/Features/Learn/Store/LearnStore.swift
Vayl/Features/Learn/Views/
  LearnRouterView.swift
  LearnDashboardView.swift
  ResearchDatabaseView.swift
  FindingDetailView.swift
  ResourcesOverlayView.swift
  Sections/
    QuizCarouselSection.swift
    ResearchSection.swift
    ContentHubSection.swift
Vayl/App/AppShell.swift      # MODIFY: .learn → LearnRouterView()
```

New `.swift` files auto-join the app target (confirmed) — no pbxproj edits. JSON files must be added to the target's Copy-Bundle-Resources; since `Vayl/Resources/Content/` already holds bundled JSON (`desire_items.json`), new files in that folder are picked up the same way — verify each appears in the build.

**Done-condition for every task:** `xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build` succeeds, and the file's `#Preview` renders in the Xcode canvas. Bryan device-confirms feel separately. Commit after each task.

Compile command used throughout (run from repo root):
```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
```

---

### Task 1: Content models

**Files:**
- Create: `Vayl/Core/Models/Learn/ResearchFinding.swift`
- Create: `Vayl/Core/Models/Learn/LearnMediaItem.swift`
- Create: `Vayl/Core/Models/Learn/Voice.swift`
- Create: `Vayl/Core/Models/Learn/SupportResource.swift`
- Create: `Vayl/Core/Models/Learn/LearnQuiz.swift`

- [ ] **Step 1: Create `ResearchFinding.swift`**

```swift
// Core/Models/Learn/ResearchFinding.swift
//
// A single research finding, presented as research (not a raw paper).
// `stat` is the optional headline number ("1 in 5"); when nil, the
// FindingType icon is the visual marker. `limitation` is the Layer-3
// intellectual-honesty line. `topics` + `type` are the controlled
// vocabularies the database categories derive from.

import Foundation

struct ResearchFinding: Codable, Identifiable, Hashable {
    let id: String
    let type: FindingType
    let stat: String?
    let headline: String        // short label for connected-research cards
    let finding: String         // full one-sentence finding
    let bullets: [String]       // "what they found → what it means"
    let limitation: String      // one honest limitation
    let citation: String
    let author: String
    let year: Int
    let topics: [String]        // controlled-vocab tags
    let connected: [String]     // ids of related findings
}

enum FindingType: String, Codable, CaseIterable {
    case prevalence
    case comparison
    case predictor
    case myth
    case mechanism
}
```

- [ ] **Step 2: Create `LearnMediaItem.swift`**

```swift
// Core/Models/Learn/LearnMediaItem.swift
//
// A book / show / podcast in the Content Hub. `artworkURL` mirrors the
// iTunes/Apple cover URLs used in the mockup; production should cache
// approved images rather than hotlink long-term.

import Foundation

struct LearnMediaItem: Codable, Identifiable, Hashable {
    let id: String
    let kind: MediaKind
    let title: String
    let creator: String         // author / network / host
    let positioning: String     // one-line "why it's here"
    let tier: String?           // books only: "Start here" etc.
    let platform: String?       // shows/podcasts: "Netflix", "Spotify"
    let artworkURL: String?
    let link: String?
}

enum MediaKind: String, Codable, CaseIterable {
    case book
    case show
    case podcast
}
```

- [ ] **Step 3: Create `Voice.swift`**

```swift
// Core/Models/Learn/Voice.swift
//
// A person in the Content Hub "Voices" tab. `kind` drives the
// Creators ⇄ Researchers filter (lived-experience vs credentialed).

import Foundation

struct Voice: Codable, Identifiable, Hashable {
    let id: String
    let kind: VoiceKind
    let name: String
    let role: String            // "Educator", "Author · Educator", "Creator"
    let blurb: String
    let platform: String        // "Instagram", "Substack", "TikTok · IG"
    let link: String?
}

enum VoiceKind: String, Codable, CaseIterable {
    case creator
    case researcher
}
```

- [ ] **Step 4: Create `SupportResource.swift`**

```swift
// Core/Models/Learn/SupportResource.swift
//
// A row in the "Vayl isn't therapy" resources overlay. `tier`
// separates ongoing support from in-crisis. `action` is a URL the
// row opens — crisis rows use tel:/sms: so a tap dials/texts.

import Foundation

struct SupportResource: Codable, Identifiable, Hashable {
    let id: String
    let tier: ResourceTier
    let title: String
    let detail: String
    let action: String          // "tel:988", "sms:741741", "https://..."
    let icon: String            // SF Symbol name
}

enum ResourceTier: String, Codable, CaseIterable {
    case ongoing
    case crisis
}
```

- [ ] **Step 5: Create `LearnQuiz.swift`**

```swift
// Core/Models/Learn/LearnQuiz.swift
//
// A self-discovery quiz card in the cyan carousel. `kind` routes to
// the eventual quiz flow (flavor = the Orientation-Map-blended quiz;
// boundary = the is-this-a-boundary quiz).

import Foundation

struct LearnQuiz: Codable, Identifiable, Hashable {
    let id: String
    let kind: String            // "flavor" / "boundary"
    let title: String
    let subtitle: String
    let questionCount: Int
}
```

- [ ] **Step 6: Compile-verify**

Run: `xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: BUILD SUCCEEDED (models compile; no usages yet).

- [ ] **Step 7: Commit**

```bash
git add Vayl/Core/Models/Learn
git commit -m "feat(learn): content models — finding, media, voice, support, quiz"
```

---

### Task 2: Seed JSON content

**Files:**
- Create: `Vayl/Resources/Content/learn_quizzes.json`
- Create: `Vayl/Resources/Content/research_findings.json`
- Create: `Vayl/Resources/Content/learn_media.json`
- Create: `Vayl/Resources/Content/voices.json`
- Create: `Vayl/Resources/Content/support_resources.json`

JSON keys are snake_case (the decoder uses `.convertFromSnakeCase`). Seed is intentionally small — enough to render each section.

- [ ] **Step 1: `learn_quizzes.json`**

```json
[
  { "id": "flavor", "kind": "flavor", "title": "What's Your Flavor of NM?", "subtitle": "Where you actually land — not where you think you should.", "question_count": 12 },
  { "id": "boundary", "kind": "boundary", "title": "Where Are Your Lines?", "subtitle": "Boundaries as a spectrum, not a checklist.", "question_count": 12 }
]
```

- [ ] **Step 2: `research_findings.json`**

```json
[
  {
    "id": "haupert",
    "type": "prevalence",
    "stat": "1 in 5",
    "headline": "1 in 5 have explored CNM",
    "finding": "Roughly 1 in 5 Americans has engaged in consensual non-monogamy at some point in their lives.",
    "bullets": [
      "Evenly distributed across age, income, religion, race, and politics — a cross-section, not a subculture.",
      "Consistent across studies — a baseline, not a passing trend."
    ],
    "limitation": "Prevalence counts any lifetime experience; it can't tell us how many practice CNM currently or how satisfied they were.",
    "citation": "Haupert, M.L. et al. (2017). Journal of Sex & Marital Therapy, 43(5).",
    "author": "Haupert et al.",
    "year": 2017,
    "topics": ["prevalence", "normalization"],
    "connected": ["rubel", "conley"]
  },
  {
    "id": "conley",
    "type": "myth",
    "stat": null,
    "headline": "Monogamy myths",
    "finding": "Many assumed benefits of monogamy over CNM aren't supported by evidence — including around STI risk and jealousy.",
    "bullets": [
      "CNM practitioners tend to have more explicit safer-sex conversations and test more regularly.",
      "Stability correlates with communication quality, not structure."
    ],
    "limitation": "These are population-level comparisons; they don't predict how any individual relationship will fare.",
    "citation": "Conley, T.D. et al. (2013). Perspectives on Psychological Science, 8(2).",
    "author": "Conley et al.",
    "year": 2013,
    "topics": ["myths", "stigma"],
    "connected": ["rubel", "haupert"]
  },
  {
    "id": "rubel",
    "type": "comparison",
    "stat": null,
    "headline": "Wellbeing holds when chosen",
    "finding": "CNM relationships show no significant difference in wellbeing or relationship quality vs. monogamous ones — when genuinely consensual.",
    "bullets": [
      "Communication quality is higher in CNM relationships — the structure demands it.",
      "The biggest predictor of success is whether both people truly chose it."
    ],
    "limitation": "Mostly cross-sectional samples that may over-represent people already doing well in CNM.",
    "citation": "Rubel, A.N. & Bogaert, A.F. (2015). Journal of Sex Research, 52(9).",
    "author": "Rubel + Bogaert",
    "year": 2015,
    "topics": ["wellbeing", "normalization"],
    "connected": ["haupert", "johnson"]
  }
]
```

- [ ] **Step 3: `learn_media.json`**

```json
[
  { "id": "ethical-slut", "kind": "book", "title": "The Ethical Slut", "creator": "Easton + Hardy", "positioning": "The clearest map of the territory.", "tier": "Start here", "platform": null, "artwork_url": "https://is1-ssl.mzstatic.com/image/thumb/Publication111/v4/86/31/e0/8631e0ca-a683-aff6-d3a3-668926fd7243/9780399579677.jpg/400x400bb.jpg", "link": null },
  { "id": "polysecure", "kind": "book", "title": "Polysecure", "creator": "Jessica Fern", "positioning": "Why some thrive, others struggle.", "tier": "After first convo", "platform": null, "artwork_url": "https://is1-ssl.mzstatic.com/image/thumb/Publication221/v4/fe/8a/bb/fe8abbb2-2aa5-f564-8a46-eb6fab21ec4a/9781944934996.jpg/400x400bb.jpg", "link": null },
  { "id": "open-doc", "kind": "show", "title": "Open", "creator": "Netflix", "positioning": "Real couples navigating non-monogamy.", "tier": null, "platform": "Netflix", "artwork_url": null, "link": null },
  { "id": "multiamory", "kind": "podcast", "title": "Multiamory", "creator": "Multiamory", "positioning": "Practical tools for modern relationships.", "tier": null, "platform": "Apple · Spotify", "artwork_url": "https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/78/c4/1a/78c41afe-9800-6231-4d9f-04f56ce96f34/mza_17876877000416303257.jpg/600x600bb.jpg", "link": null }
]
```

- [ ] **Step 4: `voices.json`**

```json
[
  { "id": "schechinger", "kind": "researcher", "name": "Dr. Heath Schechinger", "role": "Researcher · Counseling Psychology", "blurb": "CNM-affirming psychology, research-backed.", "platform": "Instagram", "link": null },
  { "id": "fern", "kind": "researcher", "name": "Jessica Fern", "role": "Author · Psychotherapist", "blurb": "Attachment + non-monogamy, plainly.", "platform": "Substack", "link": null },
  { "id": "sawyers", "kind": "creator", "name": "Evita Sawyers", "role": "Creator", "blurb": "Lived-experience reflections on poly life.", "platform": "TikTok · IG", "link": null }
]
```

- [ ] **Step 5: `support_resources.json`**

```json
[
  { "id": "open-path", "tier": "ongoing", "title": "Open Path Collective", "detail": "Affordable therapy, sliding scale", "action": "https://openpathcollective.org", "icon": "heart.text.square" },
  { "id": "psych-today", "tier": "ongoing", "title": "Psychology Today", "detail": "Filtered for non-monogamy-affirming therapists", "action": "https://www.psychologytoday.com", "icon": "slider.horizontal.3" },
  { "id": "kap", "tier": "ongoing", "title": "Kink Aware Professionals", "detail": "Poly & kink-affirming directory", "action": "https://www.kapprofessionals.org", "icon": "checkmark.seal" },
  { "id": "988", "tier": "crisis", "title": "988 Suicide & Crisis Lifeline", "detail": "Call or text 988 · 24/7", "action": "tel:988", "icon": "phone.fill" },
  { "id": "crisis-text", "tier": "crisis", "title": "Crisis Text Line", "detail": "Text HOME to 741741", "action": "sms:741741", "icon": "message.fill" },
  { "id": "dv-hotline", "tier": "crisis", "title": "The Hotline · Domestic violence", "detail": "1-800-799-7233 · 24/7 confidential", "action": "tel:18007997233", "icon": "shield.lefthalf.filled" }
]
```

- [ ] **Step 6: Verify bundling + commit**

In Xcode, confirm each JSON shows in the Vayl target's Build Phases → Copy Bundle Resources (add if missing). Then:
```bash
git add Vayl/Resources/Content
git commit -m "feat(learn): seed JSON content for Learn tab"
```

---

### Task 3: FindingType display mapping

**Files:**
- Create: `Vayl/Core/Models/Learn/FindingType+Display.swift`

- [ ] **Step 1: Create the mapping**

```swift
// Core/Models/Learn/FindingType+Display.swift
//
// Maps each finding type to its fixed SF Symbol, spectrum color, and
// label. The icon is the always-present visual marker (a finding may
// have no stat). Closed set → there is always a symbol.

import SwiftUI

extension FindingType {
    var sfSymbol: String {
        switch self {
        case .prevalence: return "chart.pie"
        case .comparison: return "arrow.left.arrow.right"
        case .predictor:  return "point.3.connected.trianglepath.dotted"
        case .myth:       return "xmark.circle"
        case .mechanism:  return "lightbulb"
        }
    }

    var tint: Color {
        switch self {
        case .prevalence, .myth: return AppColors.spectrumCyan
        case .comparison, .mechanism: return AppColors.spectrumPurple
        case .predictor: return AppColors.spectrumMagenta
        }
    }

    var label: String {
        switch self {
        case .prevalence: return "Prevalence"
        case .comparison: return "Comparison"
        case .predictor:  return "Predictor"
        case .myth:       return "Myth-buster"
        case .mechanism:  return "Mechanism"
        }
    }
}
```

- [ ] **Step 2: Compile-verify + commit**

```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
git add Vayl/Core/Models/Learn/FindingType+Display.swift
git commit -m "feat(learn): finding-type icon/color/label mapping"
```

---

### Task 4: SectionHairline (single-color)

**Files:**
- Create: `Vayl/Design/Components/Effects/SectionHairline.swift`

The existing `SpectrumHairline` is always the full cyan→purple→magenta gradient. The Learn sections need single-color hairlines (cyan / purple / magenta), so add a tinted variant.

- [ ] **Step 1: Create the component**

```swift
// Design/Components/Effects/SectionHairline.swift
//
// A thin single-color hairline (clear → color → clear), the
// Learn-section colour-coding affordance: cyan = quizzes,
// purple = research, magenta = content hub.

import SwiftUI

struct SectionHairline: View {
    let color: Color
    var thickness: CGFloat = 1.5

    var body: some View {
        LinearGradient(
            colors: [.clear, color.opacity(0.9), color, color.opacity(0.9), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: thickness)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            SectionHairline(color: AppColors.spectrumCyan)
            SectionHairline(color: AppColors.spectrumPurple)
            SectionHairline(color: AppColors.spectrumMagenta)
        }
        .padding()
    }
}
```

- [ ] **Step 2: Compile-verify + commit**

```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
git add Vayl/Design/Components/Effects/SectionHairline.swift
git commit -m "feat(learn): single-color SectionHairline"
```

---

### Task 5: LearnStore

**Files:**
- Create: `Vayl/Features/Learn/Store/LearnStore.swift`

Read-only content store. No SwiftData / appState needed for V1 stubs (Learn is not gated and holds no per-user state yet); deps can be added later. Mirrors the `@Observable @MainActor` shape of `HomeStore`.

- [ ] **Step 1: Create the store**

```swift
// Features/Learn/Store/LearnStore.swift
//
// Owns the Learn tab's read-only content, loaded once from bundled
// JSON via ContentLoader. View layer reads these arrays; derived
// accessors shape them for each section.

import Foundation

@Observable
@MainActor
final class LearnStore {

    private(set) var quizzes: [LearnQuiz] = []
    private(set) var findings: [ResearchFinding] = []
    private(set) var media: [LearnMediaItem] = []
    private(set) var voices: [Voice] = []
    private(set) var supportResources: [SupportResource] = []
    private(set) var loadError: String?

    init() { load() }

    func load() {
        do {
            quizzes          = try ContentLoader.load(LearnQuiz.self,       from: "learn_quizzes")
            findings         = try ContentLoader.load(ResearchFinding.self, from: "research_findings")
            media            = try ContentLoader.load(LearnMediaItem.self,  from: "learn_media")
            voices           = try ContentLoader.load(Voice.self,           from: "voices")
            supportResources = try ContentLoader.load(SupportResource.self, from: "support_resources")
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Derived

    var featuredFinding: ResearchFinding? { findings.first }
    var carouselFindings: [ResearchFinding] { Array(findings.dropFirst().prefix(2)) }
    var findingCount: Int { findings.count }

    func media(_ kind: MediaKind) -> [LearnMediaItem] { media.filter { $0.kind == kind } }
    func voices(_ kind: VoiceKind) -> [Voice] { voices.filter { $0.kind == kind } }
    func finding(id: String) -> ResearchFinding? { findings.first { $0.id == id } }
    func resources(_ tier: ResourceTier) -> [SupportResource] { supportResources.filter { $0.tier == tier } }
}
```

- [ ] **Step 2: Compile-verify + commit**

```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
git add Vayl/Features/Learn/Store/LearnStore.swift
git commit -m "feat(learn): LearnStore content loading"
```

---

### Task 6: Section stubs (cyan / purple / magenta)

**Files:**
- Create: `Vayl/Features/Learn/Views/Sections/QuizCarouselSection.swift`
- Create: `Vayl/Features/Learn/Views/Sections/ResearchSection.swift`
- Create: `Vayl/Features/Learn/Views/Sections/ContentHubSection.swift`

Stubs render the real structure with placeholder card bodies. Carousels use a horizontal `ScrollView` (paging feel deferred). Each carries its section hairline.

- [ ] **Step 1: `QuizCarouselSection.swift` (cyan)**

```swift
// Features/Learn/Views/Sections/QuizCarouselSection.swift
//
// Section 1 — self-discovery quizzes as a horizontal carousel. STUB:
// a horizontal ScrollView of quiz cards; paging/snap feel is deferred.

import SwiftUI

struct QuizCarouselSection: View {
    let quizzes: [LearnQuiz]
    var onSelect: (LearnQuiz) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHairline(color: AppColors.spectrumCyan)
            Text("DISCOVER YOURSELF")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(quizzes) { quiz in
                        Button { onSelect(quiz) } label: { quizCard(quiz) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func quizCard(_ quiz: LearnQuiz) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("QUIZ · \(quiz.questionCount) QUESTIONS")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.spectrumCyan)
            Text(quiz.title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(quiz.subtitle)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(width: 260, height: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(AppColors.spectrumCyan.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        QuizCarouselSection(quizzes: [
            LearnQuiz(id: "flavor", kind: "flavor", title: "What's Your Flavor of NM?", subtitle: "Where you actually land.", questionCount: 12),
            LearnQuiz(id: "boundary", kind: "boundary", title: "Where Are Your Lines?", subtitle: "Boundaries as a spectrum.", questionCount: 12)
        ])
        .padding()
    }
}
```

- [ ] **Step 2: `ResearchSection.swift` (purple)**

```swift
// Features/Learn/Views/Sections/ResearchSection.swift
//
// Section 2 — research. STUB: featured finding card + a horizontal
// carousel of the next findings + a "browse all" row into the
// database. Purple hairline.

import SwiftUI

struct ResearchSection: View {
    let featured: ResearchFinding?
    let carousel: [ResearchFinding]
    let totalCount: Int
    var onOpenDatabase: () -> Void = {}
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHairline(color: AppColors.spectrumPurple)
            Text("THE RESEARCH")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            if let featured {
                Button { onOpenFinding(featured) } label: { featuredCard(featured) }
                    .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(carousel) { finding in
                        Button { onOpenFinding(finding) } label: { miniCard(finding) }
                            .buttonStyle(.plain)
                    }
                }
            }

            Button(action: onOpenDatabase) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(AppColors.spectrumPurple)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Browse all research")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(totalCount) findings · filter by topic, author, year")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppColors.spectrumPurple.opacity(0.7))
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColors.spectrumPurple.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.spectrumPurple.opacity(0.2), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func typeChip(_ f: ResearchFinding) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: f.type.sfSymbol)
            Text(f.type.label.uppercased())
        }
        .font(AppFonts.label)
        .foregroundStyle(f.type.tint)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(Capsule().fill(f.type.tint.opacity(0.1)))
    }

    private func featuredCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            if let stat = f.stat {
                Text(stat)
                    .font(AppFonts.scoreDisplay)
                    .foregroundStyle(AppColors.spectrumPurple)
            }
            Text(f.finding)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
            Text(f.citation)
                .font(AppFonts.caption).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: AppRadius.xl).fill(AppColors.cardBackground))
    }

    private func miniCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            Text(f.finding)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(4)
            Spacer(minLength: 0)
            Text("\(f.author) · \(String(f.year))")
                .font(AppFonts.meta).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .frame(width: 230, height: 150, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

#Preview {
    let sample = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: [], limitation: "", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    return ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchSection(featured: sample, carousel: [sample], totalCount: 32).padding()
    }
}
```

- [ ] **Step 3: `ContentHubSection.swift` (magenta)**

```swift
// Features/Learn/Views/Sections/ContentHubSection.swift
//
// Section 3 — Content Hub. STUB: a segmented control (Books / Watch /
// Listen / Voices); Voices carries a Creators ⇄ Researchers filter.
// Magenta hairline.

import SwiftUI

struct ContentHubSection: View {
    let store: LearnStore

    @State private var tab: HubTab = .books
    @State private var voiceFilter: VoiceKind = .creator

    enum HubTab: String, CaseIterable, Identifiable {
        case books = "Books", watch = "Watch", listen = "Listen", voices = "Voices"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHairline(color: AppColors.spectrumMagenta)
            Text("CONTENT HUB")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            Picker("", selection: $tab) {
                ForEach(HubTab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch tab {
            case .books:  list(store.media(.book).map(\.title))
            case .watch:  list(store.media(.show).map(\.title))
            case .listen: list(store.media(.podcast).map(\.title))
            case .voices: voicesPanel
            }
        }
    }

    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Picker("", selection: $voiceFilter) {
                Text("Creators").tag(VoiceKind.creator)
                Text("Researchers").tag(VoiceKind.researcher)
            }
            .pickerStyle(.segmented)
            list(store.voices(voiceFilter).map(\.name))
        }
    }

    private func list(_ titles: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(titles, id: \.self) { title in
                HStack {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColors.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.spectrumMagenta.opacity(0.16), lineWidth: 1))
                )
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ContentHubSection(store: LearnStore()).padding()
    }
}
```

- [ ] **Step 4: Compile-verify + commit**

```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
git add Vayl/Features/Learn/Views/Sections
git commit -m "feat(learn): section stubs — quizzes/research/content-hub"
```

---

### Task 7: Sheet views (database / detail / resources)

**Files:**
- Create: `Vayl/Features/Learn/Views/ResearchDatabaseView.swift`
- Create: `Vayl/Features/Learn/Views/FindingDetailView.swift`
- Create: `Vayl/Features/Learn/Views/ResourcesOverlayView.swift`

- [ ] **Step 1: `ResearchDatabaseView.swift`**

```swift
// Features/Learn/Views/ResearchDatabaseView.swift
//
// The "browse all research" database. STUB: a scrollable list of
// findings (topic chips + filter sheet deferred). Tapping a row opens
// the finding detail.

import SwiftUI

struct ResearchDatabaseView: View {
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("The Research")
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(store.findingCount) findings")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                ForEach(store.findings) { f in
                    Button { onOpenFinding(f) } label: { row(f) }
                        .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.modalBackground)
    }

    private func row(_ f: ResearchFinding) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let stat = f.stat {
                Text(stat).font(AppFonts.cardTitle).foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 64, alignment: .leading)
            } else {
                Image(systemName: f.type.sfSymbol)
                    .font(.system(size: 20)).foregroundStyle(f.type.tint)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(f.type.tint.opacity(0.08)))
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(f.finding).font(AppFonts.caption).foregroundStyle(AppColors.textBody)
                Text("\(f.type.label) · \(f.author) · \(String(f.year))")
                    .font(AppFonts.meta).foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

#Preview {
    ResearchDatabaseView(store: LearnStore())
}
```

- [ ] **Step 2: `FindingDetailView.swift`**

```swift
// Features/Learn/Views/FindingDetailView.swift
//
// A single finding presented as research: stat / finding / bullets /
// honest limitation / citation / connected research. STUB layout.

import SwiftUI

struct FindingDetailView: View {
    let finding: ResearchFinding
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: finding.type.sfSymbol)
                    Text(finding.type.label.uppercased())
                }
                .font(AppFonts.label)
                .foregroundStyle(finding.type.tint)

                if let stat = finding.stat {
                    Text(stat).font(AppFonts.displayHero).foregroundStyle(AppColors.spectrumPurple)
                }
                Text(finding.finding)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)

                ForEach(finding.bullets, id: \.self) { b in
                    Label(b, systemImage: "circle.fill")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textBody)
                        .labelStyle(BulletStyle())
                }

                Text("One honest limitation")
                    .font(AppFonts.overline).foregroundStyle(AppColors.textSecondary)
                Text(finding.limitation)
                    .font(AppFonts.caption).foregroundStyle(AppColors.textBody)

                Text(finding.citation)
                    .font(AppFonts.caption).italic()
                    .foregroundStyle(AppColors.textTertiary)

                if !finding.connected.isEmpty {
                    Text("CONNECTED RESEARCH")
                        .font(AppFonts.overline).foregroundStyle(AppColors.textSecondary)
                        .padding(.top, AppSpacing.sm)
                    ForEach(finding.connected, id: \.self) { id in
                        if let c = store.finding(id: id) {
                            Button { onOpenFinding(c) } label: { connectedRow(c) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.modalBackground)
    }

    private func connectedRow(_ c: ResearchFinding) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: c.type.sfSymbol).foregroundStyle(c.type.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.type.label).font(AppFonts.label).foregroundStyle(AppColors.textSecondary)
                Text(c.headline).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

private struct BulletStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "circle.fill").font(.system(size: 4)).padding(.top, 7)
            configuration.title
        }
    }
}

#Preview {
    let f = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: ["Evenly distributed.", "Consistent across studies."], limitation: "Lifetime counts only.", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    return FindingDetailView(finding: f, store: LearnStore())
}
```

- [ ] **Step 3: `ResourcesOverlayView.swift`**

```swift
// Features/Learn/Views/ResourcesOverlayView.swift
//
// "Vayl isn't therapy" — the persistent resources sheet. Two tiers:
// ongoing support (cyan) and in-crisis (gold). Crisis rows open
// tel:/sms: actions.

import SwiftUI

struct ResourcesOverlayView: View {
    let resources: [SupportResource]
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    Image(systemName: "lifepreserver")
                        .font(.system(size: 19)).foregroundStyle(AppColors.spectrumCyan)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Vayl isn't therapy")
                            .font(AppFonts.cardTitle).foregroundStyle(AppColors.textPrimary)
                        Text("And it isn't trying to be. Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a line if you ever need one.")
                            .font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                    }
                }

                tier("Looking for ongoing support?", .ongoing, AppColors.spectrumCyan)
                tier("In crisis right now?", .crisis, AppColors.safetyAccent)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.modalBackground)
    }

    private func tier(_ heading: String, _ which: ResourceTier, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(heading.uppercased())
                .font(AppFonts.overline).foregroundStyle(accent)
                .padding(.top, AppSpacing.sm)
            ForEach(resources.filter { $0.tier == which }) { r in
                Button { if let url = URL(string: r.action) { openURL(url) } } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: r.icon).foregroundStyle(accent)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(accent.opacity(0.08)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.title).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textPrimary)
                            Text(r.detail).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: which == .crisis ? "arrow.right" : "arrow.up.right")
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(which == .crisis ? accent.opacity(0.05) : AppColors.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(accent.opacity(which == .crisis ? 0.2 : 0.12), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ResourcesOverlayView(resources: LearnStore().supportResources)
}
```

- [ ] **Step 4: Compile-verify + commit**

```bash
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build
git add Vayl/Features/Learn/Views
git commit -m "feat(learn): database / detail / resources sheet stubs"
```

---

### Task 8: Dashboard + Router + tab wiring

**Files:**
- Create: `Vayl/Features/Learn/Views/LearnDashboardView.swift`
- Create: `Vayl/Features/Learn/Views/LearnRouterView.swift`
- Modify: `Vayl/App/AppShell.swift` (the `.learn` case)
- Replace: `Vayl/Features/Learn/Views/LearnView.swift` (old stub) — leave the file but it is no longer routed; the Router supersedes it. (Optionally delete in a later cleanup.)

- [ ] **Step 1: `LearnDashboardView.swift`**

```swift
// Features/Learn/Views/LearnDashboardView.swift
//
// The Learn tab content: header (title + Resources pill) over three
// colour-coded sections, on the OB atmosphere. Reads the store; all
// navigation is forwarded via closures to the Router.

import SwiftUI

struct LearnDashboardView: View {
    let store: LearnStore
    var onOpenDatabase: () -> Void = {}
    var onOpenResources: () -> Void = {}
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }
    var onSelectQuiz: (LearnQuiz) -> Void = { _ in }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    QuizCarouselSection(quizzes: store.quizzes, onSelect: onSelectQuiz)
                    ResearchSection(
                        featured: store.featuredFinding,
                        carousel: store.carouselFindings,
                        totalCount: store.findingCount,
                        onOpenDatabase: onOpenDatabase,
                        onOpenFinding: onOpenFinding
                    )
                    ContentHubSection(store: store)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 120)   // clears the floating RacetrackTabBar
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Learn.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.spectrumText)
                Text("Build your frame before you need it")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
            Button(action: onOpenResources) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lifepreserver").foregroundStyle(AppColors.spectrumCyan)
                    Text("Resources").font(AppFonts.buttonLabel).foregroundStyle(AppColors.textBody)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Capsule().fill(AppColors.cardBackground)
                    .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1)))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    LearnDashboardView(store: LearnStore())
}
```

- [ ] **Step 2: `LearnRouterView.swift`**

```swift
// Features/Learn/Views/LearnRouterView.swift
//
// Thin router: creates the LearnStore and owns sheet presentation for
// the research database, finding detail, and resources overlay.
// Mirrors the Home tab's Router pattern.

import SwiftUI

struct LearnRouterView: View {
    var body: some View { LearnRouterInnerView() }
}

private struct LearnRouterInnerView: View {
    @State private var store = LearnStore()
    @State private var showDatabase = false
    @State private var showResources = false
    @State private var selectedFinding: ResearchFinding?

    var body: some View {
        LearnDashboardView(
            store: store,
            onOpenDatabase: { showDatabase = true },
            onOpenResources: { showResources = true },
            onOpenFinding: { selectedFinding = $0 }
        )
        .vaylSheet(isPresented: $showDatabase, heightFraction: 0.92) {
            ResearchDatabaseView(store: store, onOpenFinding: { f in
                showDatabase = false
                selectedFinding = f
            })
        }
        .vaylSheet(isPresented: $showResources, heightFraction: 0.82) {
            ResourcesOverlayView(resources: store.supportResources)
        }
        .vaylSheet(isPresented: detailBinding, heightFraction: 0.85) {
            if let f = selectedFinding {
                FindingDetailView(finding: f, store: store, onOpenFinding: { selectedFinding = $0 })
            }
        }
    }

    private var detailBinding: Binding<Bool> {
        Binding(get: { selectedFinding != nil },
                set: { if !$0 { selectedFinding = nil } })
    }
}

#Preview {
    LearnRouterView()
}
```

- [ ] **Step 3: Wire `AppShell.swift`**

Modify the `.learn` case:
```swift
case .learn:
    TabContentWrapper { LearnRouterView() }
```

- [ ] **Step 4: Compile-verify**

Run: `xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: BUILD SUCCEEDED. Open the Learn tab — three colour-coded sections render, the Resources pill and "Browse all" open sheets, a finding row opens detail, connected research navigates.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Learn/Views/LearnDashboardView.swift Vayl/Features/Learn/Views/LearnRouterView.swift Vayl/App/AppShell.swift
git commit -m "feat(learn): dashboard + router + tab wiring"
```

---

## Deeper-pass backlog (NOT this plan)

Captured so nothing is lost; each is its own later segment, and per the Build Protocol the feel items must be prototyped in `docs/mockups/learn-tab.html` before Swift:

- Carousel **feel** — replace the stub horizontal `ScrollView`s with real paging/snap (evaluate `VaylCardCarousel` vs `ScrollView.scrollTargetBehavior(.viewAligned)`).
- Real card layouts matching the mockup (gradient stats, spectrum hairline-on-card, book covers, platform badges, circular avatars).
- Database **filters** — topic chips (from corpus tags), sort, and the author/year/type filter sheet.
- Quiz flows — the Flavor-of-NM quiz blended with the Orientation Map (SCT split + compass reveal; see memory `flavor_orientation_map_blend`) and the boundary quiz; results route generated cards to **Play**.
- Learn→Play handoff for discussion/conversation guide cards.
- Floating-tab-bar bottom inset tuning; `OnboardingAtmosphere` config selection.
- Replace seed JSON with the ingestion pipeline output (`learn_research_pipeline`, parked).

---

## Self-review

- **Spec coverage:** three colour-coded sections (cyan/purple/magenta) ✓ (Tasks 4, 6); Voices split as a Creators/Researchers filter ✓ (Task 6, `voicesPanel`); "Content Hub" rename ✓ (Task 6 heading); research featured + carousel + browse-all ✓ (Task 6 `ResearchSection`); database + detail + resources via `.vaylSheet` ✓ (Tasks 7–8); finding-type icon system ✓ (Task 3); honest-limitation line ✓ (model + detail). Carousel *feel* intentionally deferred (stubs) and logged in the backlog.
- **Type consistency:** `ResearchFinding` fields used in `ResearchSection`, `ResearchDatabaseView`, `FindingDetailView`, `LearnStore` match the Task-1 definition; `FindingType.sfSymbol/tint/label` (Task 3) used consistently; `LearnStore` accessors (`featuredFinding`, `carouselFindings`, `findingCount`, `media(_:)`, `voices(_:)`, `finding(id:)`, `supportResources`) match call sites.
- **Placeholders:** none — every file has complete stub code.
- **Risk to verify during execution:** the `.vaylSheet` signature (`isPresented:heightFraction:showsGrabber:content:`) and whether new `Resources/Content/*.json` auto-add to Copy-Bundle-Resources — confirm both on the first build; `ContentLoader.load(_:from:)` resolves bundle-flattened JSON the same way `desire_items.json` does.
