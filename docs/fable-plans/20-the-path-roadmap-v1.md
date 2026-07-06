# 20 — The Path (Roadmap) V1

**Goal:** Build "The Path" — the couple's self-paced real-life roadmap — as the "Forward" pillar of the
Map tab's three-pillar skeleton (Now=Pulse / Forward=Path / Kept=Vault, per
`docs/prototypes/map-layout-blocking.html`), replacing the slot Plan 17 emptied out. V1 = Agency-ladder
Rung 1 only (one preset template, no customize/theorycraft) per
`docs/superpowers/specs/2026-06-27-couple-path-roadmap-design.md`. This is 100% greenfield — verified
zero Swift/Supabase symbols exist for it today.

**Sequencing: run this after Plan 17** (it fills the slot 17 empties) and independently of Plans 18/19
(different subsystem — Pulse — though The Path's own "capacity-informs-readiness" idea per the spec is
explicitly *ambient*, never a hard gate, so it does not need to wait on Pulse work to land).

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

## Context Fable needs

- **What this is, per the spec:** a couple's real-life-event roadmap, self-paced, territory-not-a-progress-bar
  (whole path visible, no percentage/streak, future nodes read "dim and inviting" not "locked"). Tapping a
  node opens a **Mission Brief**: The Event, one Golden Rule, optional toolkit links, and a mark action
  ("We did this" / "Not yet"). It is "fundamentally an Us artifact with Me lanes" — **one shared journey**,
  not two separate roadmaps for Me and Us (spec §4).
- **Nothing exists yet.** Confirmed by repo-wide grep: zero Swift symbols (`PathTemplate`, `PathNode`,
  `RoadmapPath`, `PathStore`, etc.), zero Supabase schema, zero hook point in `MapStore.swift`. This is a
  new vertical, not a finish-pass.
- **`GettingStartedPathView.swift` (`Vayl/Features/Home/Views/`) is a DIFFERENT feature** — a 3-step
  onboarding checklist bridge on Home, unrelated data model (`GettingStartedStep`). The spec explicitly
  says the new Path "extends the visual language already built in `GettingStartedPathView`" — reuse its
  rail/node visual idiom (spectrum rail, circular state nodes, `.done`/`.active`/`.upcoming` styling), do
  not confuse the two features or their data.
- **V1 scope = Agency-ladder Rung 1 only** (spec §9): one preset template (**Swinging**, since it's the
  one with real seeded content — see `docs/prototypes/map-roadmap-swinging.html`), no customize-a-preset,
  no theorycraft-from-scratch. Those are V1.x/V2.
- **V1 rendering simplification (flag this, don't hide it):** the mockup's full trail is a hand-tuned
  serpentine SVG bezier curve. Reproducing that exact curve in SwiftUI is a real feel-driven build in its
  own right (the kind of thing CLAUDE.md says must be felt on a device reference before being written into
  Swift, not guessed). **V1 builds a straight vertical rail** (`GettingStartedPathView`'s existing visual
  idiom — the pattern the spec itself says to extend) instead of the serpentine curve. The phase-grouping,
  node states, and Mission Brief are otherwise faithful to the mockup. The serpentine trail is a follow-up
  polish pass once Bryan can feel-reference it on device, not part of this plan's Definition of Done.
- **Content copy is Fable-drafted, not final** — same convention as Plan 15 ("Fable drafts, Bryan edits").
  The Event/Golden Rule copy seeded below is placeholder prose grounded in the mockup's one fully-written
  node ("The strip club"); the other 12 nodes' Event/Golden Rule text needs Bryan's editorial pass before
  shipping. This is content-authoring work, not a build blocker.
- **Canonical patterns to imitate:**
  - `CardSession`/`SoloSession` (`Vayl/Core/Models/CardSession.swift`) for the SwiftData progress-record
    shape: couple-owned row, `String` content-id reference (never a UUID FK to bundled JSON).
  - `MapStore.swift` for the Store shape (`@MainActor @Observable final class`, `load(appState:context:)`
    idempotent, `private(set)` published state).
  - `ContentLoader.loadSingle(_:from:)` (`Vayl/Core/Services/ContentLoader.swift:41-65`) for bundled JSON,
    `snake_case` keys auto-converted.
  - `PulseHistory.nearestOnOrBefore`-style carry-forward reads are NOT needed here — Path completion is a
    direct per-node lookup, simpler than Pulse's time-series.

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Create | `Vayl/Core/Models/PathModels.swift` | `PathTemplate`, `PathTopology`, `PathNode`, `PathTemplateContent` (pure models) |
| Create | `Vayl/Core/Models/PathNodeMark.swift` | `@Model` SwiftData progress record |
| Create | `Vayl/Features/Map/PathStore.swift` | Store: loads content + marks, derives current node / completion |
| Create | `Vayl/Features/Map/Components/ThePathTeaser.swift` | Collapsed "Forward" section for `meLayer`/`usLayer` |
| Create | `Vayl/Features/Map/Components/ThePathTrailView.swift` | The full rail (straight, V1) |
| Create | `Vayl/Features/Map/Components/PathMissionBriefSheet.swift` | Event / Golden Rule / mark actions |
| Create | `Vayl/Resources/Content/path_swinging.json` | The 13-node Swinging preset content |
| Modify | `Vayl/App/ModelContainer.swift` | Register `PathNodeMark.self` in `SchemaV1.models` |
| Modify | `Vayl/Features/Map/MapView.swift` | Add `PathStore`, wire the teaser into `meLayer`/`usLayer`, present the trail + brief |

---

## Build steps

### Step 1 — Pure models

`Vayl/Core/Models/PathModels.swift`:

```swift
// Vayl/Core/Models/PathModels.swift
//
// Pure data shapes for The Path (the couple's real-life roadmap). No logic beyond
// Codable + the small helpers below — decisions live in PathStore.

import Foundation

/// The preset the couple started from. V1 ships Swinging only (Agency-ladder Rung 1);
/// the others exist in the type so content can be added without a model change.
enum PathTemplate: String, Codable, CaseIterable {
    case open, polyamorous, swinging, monogamish
}

/// How a node's completion is confirmed. Named after the spec's own topology legend:
///   synced      (O)  — one shared couple state, either partner marks it for both.
///   dualVerify  (OO) — both partners individually confirm; merges once both have.
///   individual  (O/O) — the rail forks; each partner has their own mark, no merge.
enum PathTopology: String, Codable {
    case synced, dualVerify, individual
}

/// One real-life landmark. Never a conversation or in-app task — always something
/// that happens outside the app.
struct PathNode: Identifiable, Codable {
    let id: String
    let phase: Int
    let phaseTitle: String
    let title: String
    let event: String
    let goldenRule: String
    let topology: PathTopology
    /// Optional short sub-label shown under the title on the rail (e.g. "just watch").
    var sublabel: String? = nil
}

/// One preset's full content — the bundled-JSON shape.
struct PathTemplateContent: Codable {
    let template: PathTemplate
    let nodes: [PathNode]
}
```

*Done: pure, dependency-free models compile.*

### Step 2 — SwiftData progress record

`Vayl/Core/Models/PathNodeMark.swift`:

```swift
//
//  PathNodeMark.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - PathNodeMark
// One "we/I did this" mark against a Path node. Couple-owned (never userId-only, even
// for a dualVerify/individual node — the couple's shared journey is the join key;
// userId distinguishes WHICH partner marked it, for topologies that need that).
// nodeId is a String reference to the bundled JSON content id, mirroring
// CardSession.deckId — never a UUID FK.

@Model
final class PathNodeMark {

    var id: UUID
    var coupleId: UUID
    var nodeId: String
    /// nil for a `.synced` node (one mark speaks for the couple).
    /// Set to the marking user's UserProfile.id for `.dualVerify`/`.individual` nodes.
    var userId: UUID?
    var markedAt: Date

    init(coupleId: UUID, nodeId: String, userId: UUID? = nil) {
        self.id = UUID()
        self.coupleId = coupleId
        self.nodeId = nodeId
        self.userId = userId
        self.markedAt = Date()
    }
}
```

Register in `Vayl/App/ModelContainer.swift`'s `SchemaV1.models` array, after `EventLogEntry.self`:

```swift
EventLogEntry.self,
PathNodeMark.self
```

*Done: `PathNodeMark` is a SwiftData model, schema-registered, compiles.*

### Step 3 — The Store

`Vayl/Features/Map/PathStore.swift`:

```swift
//
//  PathStore.swift
//  Vayl
//
//  The Path's state owner (4-layer: View -> Store -> Service -> Model). Loads the
//  couple's preset content + progress marks, derives the current node and each
//  node's completion state. Views only read.

import Foundation
import SwiftData

@MainActor
@Observable
final class PathStore {

    private(set) var nodes: [PathNode] = []
    private(set) var template: PathTemplate = .swinging

    /// nodeId -> the marks recorded against it (0-2 rows: the couple-wide synced mark,
    /// or up to one per partner for dualVerify/individual).
    private var marks: [String: [PathNodeMark]] = [:]

    // MARK: - Load

    /// Idempotent — safe to call on every appear.
    func load(appState: AppState, context: ModelContext) {
        let content = try? ContentLoader.loadSingle(PathTemplateContent.self, from: "path_swinging")
        nodes = content?.nodes ?? []
        template = content?.template ?? .swinging

        guard let coupleId = appState.coupleId else {
            marks = [:]
            return
        }
        let fetch = FetchDescriptor<PathNodeMark>(predicate: #Predicate { $0.coupleId == coupleId })
        let all = (try? context.fetch(fetch)) ?? []
        marks = Dictionary(grouping: all, by: { $0.nodeId })
    }

    // MARK: - Derived state

    /// The node the couple is currently at — the first incomplete node, or the last
    /// node if everything is complete.
    var currentNode: PathNode? {
        nodes.first { !isComplete($0) } ?? nodes.last
    }

    func isComplete(_ node: PathNode) -> Bool {
        let nodeMarks = marks[node.id] ?? []
        switch node.topology {
        case .synced:
            return !nodeMarks.isEmpty
        case .dualVerify, .individual:
            // V1: complete once two DISTINCT partners have marked it. See Open Decisions —
            // this does not yet surface "your partner marked it, waiting on you" as its own
            // state; it only distinguishes not-started vs both-done.
            return Set(nodeMarks.compactMap(\.userId)).count >= 2
        }
    }

    /// Whether the CURRENT device's user has already marked this node (for dualVerify/
    /// individual nodes, so the UI doesn't let the same partner "double mark").
    func hasMyMark(_ node: PathNode, myUserId: UUID?) -> Bool {
        guard let myUserId else { return false }
        return (marks[node.id] ?? []).contains { $0.userId == myUserId }
    }

    // MARK: - Mark

    func mark(_ node: PathNode, appState: AppState, context: ModelContext) {
        guard let coupleId = appState.coupleId else { return }
        let userId: UUID? = node.topology == .synced
            ? nil
            : (try? context.fetch(FetchDescriptor<UserProfile>()).first)?.id

        let record = PathNodeMark(coupleId: coupleId, nodeId: node.id, userId: userId)
        context.insert(record)
        context.saveWithLogging()
        marks[node.id, default: []].append(record)
    }
}
```

*Done: `PathStore` loads the Swinging preset + the couple's marks, derives `currentNode`, and can mark a
node. Idempotent `load`, matching `MapStore`'s own convention.*

### Step 4 — Bundled content

`Vayl/Resources/Content/path_swinging.json` — the 13-node Swinging preset, phase-grouped exactly per
`docs/prototypes/map-roadmap-swinging.html`'s own phase dividers and node order:

```json
{
  "template": "swinging",
  "nodes": [
    { "id": "fantasy-talk",    "phase": 1, "phase_title": "Safe Harbor",       "title": "Fantasy talk",          "event": "Talk openly about the fantasy, no pressure to act on it yet.", "golden_rule": "Curiosity only, no obligation.", "topology": "synced" },
    { "id": "watch-together",  "phase": 1, "phase_title": "Safe Harbor",       "title": "Watch together",        "event": "Watch something together that touches the theme, and talk about it after.", "golden_rule": "Talk about how it felt, not just what happened.", "topology": "synced" },
    { "id": "virtual-hellos",  "phase": 1, "phase_title": "Safe Harbor",       "title": "Virtual hellos",         "event": "Say hello to the lifestyle community online, together, at your own pace.", "golden_rule": "Looking is not committing.", "topology": "synced" },
    { "id": "strip-club",      "phase": 2, "phase_title": "Proximal Energy",   "title": "The strip club",         "event": "Go to a strip club together. Start with no lap dance; if it feels right, a lap dance. You're learning what it's like to watch each other enjoy the room.", "golden_rule": "You leave together, and the night stays about the two of you.", "topology": "synced" },
    { "id": "flirt-at-a-bar",  "phase": 2, "phase_title": "Proximal Energy",   "title": "Flirt at a bar",         "event": "Flirt with others at a bar together, in the same room, checking in with each other as you go.", "golden_rule": "Stay in eyesight of each other.", "topology": "synced" },
    { "id": "nm-mixer",        "phase": 2, "phase_title": "Proximal Energy",   "title": "An NM mixer",            "event": "Attend a non-monogamy social mixer together and meet others exploring the same thing.", "golden_rule": "You came as a couple; you leave as a couple.", "topology": "synced" },
    { "id": "lifestyle-club",  "phase": 3, "phase_title": "Threshold",         "title": "Lifestyle club",         "event": "Visit a lifestyle club together. Just watch this time.", "golden_rule": "Watching only, no exceptions tonight.", "topology": "synced", "sublabel": "just watch" },
    { "id": "seen-as-couple",  "phase": 3, "phase_title": "Threshold",         "title": "Seen, as a couple",      "event": "Let others at the club see you as a couple exploring together.", "golden_rule": "Check in with each other before anything changes.", "topology": "synced" },
    { "id": "dinner-couple",   "phase": 4, "phase_title": "Engagement",        "title": "Dinner with a couple",   "event": "Have dinner with another couple you've connected with.", "golden_rule": "This is about connection first, nothing else is assumed.", "topology": "synced" },
    { "id": "same-room",       "phase": 4, "phase_title": "Engagement",        "title": "Same room",              "event": "Be intimate with your partner in the same room as another couple, in parallel.", "golden_rule": "Parallel, not shared, unless you both choose otherwise in the moment.", "topology": "synced", "sublabel": "parallel play" },
    { "id": "soft-swap",       "phase": 4, "phase_title": "Engagement",        "title": "Soft swap",              "event": "Swap partners for everything except intercourse.", "golden_rule": "Either partner can pause it, no explanation needed.", "topology": "synced" },
    { "id": "full-swap",       "phase": 4, "phase_title": "Engagement",        "title": "Full swap",              "event": "Swap partners fully, with another couple you both trust.", "golden_rule": "Agreements from your Vault apply here above all else.", "topology": "synced" },
    { "id": "solo-night",      "phase": 5, "phase_title": "Advanced",          "title": "A solo night",           "event": "Each of you spends a night with someone else, on your own.", "golden_rule": "Come back to each other after, always.", "topology": "individual", "sublabel": "your paths split here" }
  ]
}
```

*Done: 13 nodes across 5 phases, matching the mockup's node order and phase grouping; the final node
is `.individual`, every other node is `.synced` (no `.dualVerify` node in this preset — the type exists
for future presets/content, not used here).*

### Step 5 — Teaser (collapsed "Forward" section)

`Vayl/Features/Map/Components/ThePathTeaser.swift`:

```swift
// Features/Map/Components/ThePathTeaser.swift
//
// The Path's collapsed "Forward" section — Map's middle pillar (Now=Pulse /
// Forward=Path / Kept=Vault, per docs/prototypes/map-layout-blocking.html).
// Tapping it expands to the full trail (ThePathTrailView).

import SwiftUI

struct ThePathTeaser: View {
    let currentNode: PathNode?
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("The Path")
                        .font(AppFonts.overline)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(AppColors.textSectionLabel)
                    Spacer()
                    Text("chevron.right")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                if let currentNode {
                    Text(currentNode.phaseTitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(currentNode.title)
                        .font(AppFonts.cardTitleCompact)
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    ThePathEmptyState()
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .vaylGlassCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(currentNode.map { "The Path, currently at \($0.title)" } ?? "The Path")
        .accessibilityHint("Opens your full path")
    }
}

/// Empty state — no preset chosen yet (V1 has no template picker; this only shows if
/// content fails to load, so it's the honest fallback, not a live V1 flow).
private struct ThePathEmptyState: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "map")
                .foregroundStyle(AppColors.textTertiary)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Your path hasn't started")
                    .font(AppFonts.cardTitleCompact)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Chart your own course together")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Teaser") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ThePathTeaser(
            currentNode: PathNode(
                id: "strip-club", phase: 2, phaseTitle: "Proximal Energy",
                title: "The strip club", event: "", goldenRule: "", topology: .synced
            ),
            onTap: {}
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
```

*Done: a glass-card teaser matching the block-layout mockup's "Forward" pillar, showing the current
phase + node, with an honest empty state if content fails to load.*

### Step 6 — Full trail (V1: straight rail, per Context's flagged simplification)

`Vayl/Features/Map/Components/ThePathTrailView.swift`:

```swift
// Features/Map/Components/ThePathTrailView.swift
//
// The Path's full trail — V1 renders a straight vertical rail (GettingStartedPathView's
// existing visual idiom, which the design spec explicitly says to extend), grouped by
// phase. The mockup's serpentine bezier trail is a future feel-driven polish pass, not
// part of V1 (see Plan 20's Context section for why).

import SwiftUI

struct ThePathTrailView: View {
    let nodes: [PathNode]
    let store: PathStore
    var onSelect: (PathNode) -> Void
    var onDismiss: () -> Void

    private var phases: [(title: String, nodes: [PathNode])] {
        let grouped = Dictionary(grouping: nodes, by: \.phase)
        return grouped.keys.sorted().map { phase in
            (title: grouped[phase]?.first?.phaseTitle ?? "", nodes: grouped[phase] ?? [])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack(alignment: .top) {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        ForEach(phases, id: \.title) { phase in
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(phase.title.uppercased())
                                    .font(AppFonts.overline)
                                    .tracking(1.6)
                                    .foregroundStyle(AppColors.textSectionLabel)
                                ForEach(phase.nodes) { node in
                                    nodeRow(node)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, layout.safeAreaInsets.top + AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 32, height: 32)
                        .background(AppColors.glassSurface)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, layout.safeAreaInsets.top + AppSpacing.sm)
                .padding(.trailing, AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func nodeRow(_ node: PathNode) -> some View {
        let isDone = store.isComplete(node)
        let isNow  = store.currentNode?.id == node.id
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect(node)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(isDone ? AppColors.spectrumText : AppColors.glassSurface)
                    .overlay(Circle().strokeBorder(isNow ? AppColors.spectrumCyan : AppColors.borderSubtle, lineWidth: isNow ? 2 : 1))
                    .frame(width: isNow ? 20 : 14, height: isNow ? 20 : 14)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(node.title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(isDone || isNow ? AppColors.textPrimary : AppColors.textTertiary)
                    if let sublabel = node.sublabel {
                        Text(sublabel)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                Spacer()
                if isNow {
                    Text("Now")
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.spectrumCyan)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(node.title)\(isDone ? ", done" : isNow ? ", current" : "")")
        .accessibilityHint("Opens the mission brief")
    }
}
```

*Done: a scrollable, phase-grouped rail; done nodes glow, the current node is highlighted and tagged
"Now", future nodes are dim (never "locked") — matching the spec's territory-not-progress-bar rule.*

### Step 7 — Mission Brief sheet

`Vayl/Features/Map/Components/PathMissionBriefSheet.swift`:

```swift
// Features/Map/Components/PathMissionBriefSheet.swift
//
// Tapping a Path node opens this: The Event, one Golden Rule, and a mark action.
// Never a checklist row — a "here's what this is, here's the one rule, mark it when
// you've lived it" moment. Presented as a .vaylSheet (a discrete task), not a cover.

import SwiftUI

struct PathMissionBriefSheet: View {
    let node: PathNode
    let isComplete: Bool
    var onMark: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(node.phaseTitle.uppercased())
                .font(AppFonts.overline)
                .tracking(1.6)
                .foregroundStyle(AppColors.textSectionLabel)

            Text(node.title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            if isComplete {
                Label("Marked", systemImage: "checkmark.circle.fill")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.spectrumCyan)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("THE EVENT")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                Text(node.event)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("THE GOLDEN RULE")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumMagenta)
                Text(node.goldenRule)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.spectrumMagenta.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.spectrumMagenta.opacity(0.32), lineWidth: 1)
            )

            if !isComplete {
                Button(action: onMark) {
                    Text("We did this")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accentPrimary.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                }
                .buttonStyle(.plain)
            }

            Text("No timeline. Sit here as long as you need.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(AppSpacing.lg)
    }
}
```

*Done: a half-sheet with Event, Golden Rule, mark action (only shown if not already complete), matching
the mockup's Mission Brief shape. No in-app "toolkit links" in V1 — see Open Decisions.*

### Step 8 — Wire into `MapView`

Add state (near the existing `@State private var vaultStore = VaultStore()`, `MapView.swift:29`):

```swift
@State private var pathStore = PathStore()
@State private var showPathTrail = false
@State private var pathBriefNode: PathNode? = nil
```

Add to the `.task` block (`MapView.swift:109-113`), alongside the existing loads:

```swift
pathStore.load(appState: appState, context: modelContext)
```

Add the teaser to both layers. `meLayer` (`MapView.swift:193-206`, after Plan 17's edit removes the Me
Card):

```swift
private var meLayer: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        MapPulseHero(
            onCheckIn: { startCheckIn() },
            onOpenHistory: { showPulseSheet = true }
        )
        ThePathTeaser(currentNode: pathStore.currentNode, onTap: { showPathTrail = true })
        MapRecord(sessions: store.sessions, shares: store.categoryShares)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

`usLayer` (`MapView.swift:208-217`) — same teaser, added after the Pulse Us layer:

```swift
private var usLayer: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        MapUsLayer(
            stats:            store.usStats,
            align:            store.alignItems,
            lockedAlignCount: store.lockedAlignCount,
            onOpenVault:      { showVault = true },
            partnerPosition:  store.partnerPosition,
            partnerName:      store.partnerName
        )
        ThePathTeaser(currentNode: pathStore.currentNode, onTap: { showPathTrail = true })
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

Add the two presentations (near the other `.vaylSheet`s, `MapView.swift:91-107`):

```swift
.vaylSheet(
    isPresented: $showPathTrail,
    heightFraction: 0.92,
    screenHeight: layout.screenHeight
) {
    ThePathTrailView(
        nodes: pathStore.nodes,
        store: pathStore,
        onSelect: { pathBriefNode = $0 },
        onDismiss: { showPathTrail = false }
    )
}
.vaylSheet(
    isPresented: Binding(
        get: { pathBriefNode != nil },
        set: { if !$0 { pathBriefNode = nil } }
    ),
    heightFraction: 0.7,
    screenHeight: layout.screenHeight
) {
    if let node = pathBriefNode {
        PathMissionBriefSheet(
            node: node,
            isComplete: pathStore.isComplete(node),
            onMark: {
                pathStore.mark(node, appState: appState, context: modelContext)
                pathBriefNode = nil
            },
            onDismiss: { pathBriefNode = nil }
        )
    }
}
```

*Done: both Me and Us show the same Path teaser (one shared journey, not two roadmaps), tapping it opens
the full trail, tapping a node opens its Mission Brief, marking it persists via `PathStore.mark` and
updates the trail/teaser live.*

### Step 9 — First-open framing moment (teaching decision 4B, spec 2026-07-03)

Per the decided teaching strategy (`docs/superpowers/specs/2026-07-03-feature-teaching-strategy-design.md`,
Path = 4B): the FIRST time a user opens the full trail, and only then, `ThePathTrailView` leads with a
short worded framing before the trail itself renders — because The Path's dangerous failure mode is a
conceptual misread (every mainstream prior says "progress bar," and a couple reading their Path as a
progress bar imports exactly the comparison/guilt mechanic the design rejects).

- **Three beats, worded, in the trail's own visual language** (not a separate screen, not a slide deck —
  the beats resolve into the trail, the way the reveal's beats resolve into the constellation):
  1. "This is territory, not a checklist. Nothing here is owed."
  2. "It flexes with your capacity." (Pulse vocabulary — already taught by the time anyone reaches here.)
  3. "You choose what exists on your map."
- **Once ever:** gate on a new `UserDefaultsKey.hasSeenPathFraming` sibling key (same pattern as
  `hasCompletedCoupleSession`). Not server-persisted — a lost flag on reinstall means one harmless
  re-teach.
- **Skippable by tap** (any tap advances the beats; the third tap lands in the trail). No progress dots,
  no "skip tutorial" button chrome — it's a framing moment, not a tutorial to escape from.
- **Plus the standard Tier 4 door:** a quiet "what is this?" affordance on the trail header opening a
  `.vaylSheet` with the topology vocabulary (O / OO / O–O) and the same three framing lines, reachable
  forever (the `PulseInfoSheet`-template door component from the teaching spec).

*Done: first-ever trail open shows the three beats then lands in the trail; every later open goes
straight to the trail; the "what is this?" door is always reachable from the trail header.*

---

## Definition of Done (build-green)

- [ ] `PathModels.swift`, `PathNodeMark.swift`, `PathStore.swift` compile; `PathNodeMark` is registered
      in `SchemaV1.models`.
- [ ] `path_swinging.json` loads via `ContentLoader.loadSingle(PathTemplateContent.self, from:)` with
      zero decode errors (13 nodes, 5 phases, snake_case keys resolve correctly).
- [ ] `ThePathTeaser` renders in both `meLayer` and `usLayer`, reading the same `PathStore` instance.
- [ ] Tapping the teaser opens `ThePathTrailView`; tapping a node opens `PathMissionBriefSheet`; tapping
      "We did this" persists a `PathNodeMark`, closes the brief, and the trail/teaser reflect it live
      without needing a re-launch.
- [ ] The final node ("A solo night", `.individual` topology) requires two distinct `userId`s marked
      before `isComplete` returns true — verify with two `PathNodeMark` rows with different `userId`s.
- [ ] No progress meter, percentage, or streak copy anywhere — future nodes render dim, never "locked".
- [ ] First-ever trail open shows the Step 9 three-beat framing exactly once (`hasSeenPathFraming`);
      the trail-header "what is this?" door opens its `.vaylSheet` on every visit.
- [ ] Zero raw literals in any new View; all colors/fonts/spacing are tokens.
- [ ] `MeCardCompact`/`MeCardSheet` are NOT reintroduced — this plan assumes Plan 17 already ran.

## Bryan verifies on device

- Open Map → Me: confirm "The Path" teaser shows the current phase + node where "Your card" used to be.
- Tap through to the full trail: confirm phase grouping reads clearly, the current node is visually
  distinct (glow + "Now" tag), completed nodes read done, future nodes read dim/inviting (not locked).
- Tap a node, read the Mission Brief, tap "We did this": confirm it marks, the sheet closes, and the
  trail immediately shows that node as done and advances "current" to the next one.
- Switch to Us: confirm the SAME current node and progress show (one shared journey, not a second,
  independent Us roadmap).
- First-ever trail open: confirm the three framing beats read as Vayl (not preachy), taps advance them,
  and a second open goes straight to the trail. Open the "what is this?" door and gut-check the
  topology vocabulary copy.
- 🎚️ Feel-check the straight-rail V1 trail against the mood of `map-roadmap-swinging.html` and flag
  whether the serpentine-trail follow-up pass is worth prioritizing, or whether the straight rail reads
  fine as-is.
- Editorial pass: read all 13 nodes' Event/Golden Rule copy and rewrite anything that doesn't sound like
  Vayl (this plan's seeded copy is a draft, not final).

## Constraints / do-not-touch

- Do not build the customize-a-preset or theorycraft-from-scratch flows (Agency-ladder Rungs 2/3) — V1
  is preset-only, per spec §9.
- Do not build a template picker — V1 hardcodes the Swinging preset. A picker is new scope the spec
  doesn't fully resolve for V1 either (see Open Decisions).
- Do not build the serpentine bezier trail — the straight rail is the deliberate V1 choice (see Context).
- Do not wire the "implicit toolkit" links (pre-game deck, Agreements Vault, post-game journal) in the
  Mission Brief — those are real cross-feature integrations (Play decks, Vault agreements, Vault journal)
  that need their own scoping pass, not a one-line addition here. The brief works fully without them.
- Do not touch `GettingStartedPathView.swift` or its data model — confirmed unrelated, leave it alone.
- Requires Plan 17 to have already run (this plan's `meLayer`/`usLayer` code assumes the Me Card section
  is already gone).

## Open decisions

1. **Template picker for V1.** Recommended default: none — hardcode Swinging (the only preset with
   seeded content). If Bryan wants couples to pick their own preset in V1, that's new scope (a picker UI
   + at least one more preset's content) beyond this plan.
2. **`dualVerify`/`individual` completion UX** (currently silent — no "waiting on your partner" state
   surfaces anywhere). Recommended default: ship as-is for V1 (the Swinging preset only has one
   `.individual` node, at the very end, so this gap has minimal exposure); add a "waiting on partner"
   state to `PathStore`/the Mission Brief in a follow-up if more presets lean on dual/individual nodes.
3. **Content copy.** Recommended default: ship the seeded draft copy, Bryan edits before it's user-facing
   (same pattern as Plan 15's content authoring) — not a build blocker.
4. **The Vault-absorbs-Record refactor** (per `map-layout-blocking.html`, "Kept" should include the
   session Record, which today is its own section in `meLayer`). Recommended default: out of scope here
   — Plan 17 only removed the card, this plan only adds the Path; folding the Record into the Vault is a
   separate, later structural pass so this plan doesn't also touch Vault internals.
