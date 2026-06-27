#!/usr/bin/env python3
import json, math, os

OUT_DIR = "/Users/bryanjorden/Documents/School/Code/Vayl/.understand-anything/intermediate"

# ---- Node + edge assembly --------------------------------------------------
# Each file node carries (id,type,name,filePath,summary,tags,complexity,[languageNotes])
# Sub-nodes (class/function) carry lineRange.

nodes = []
edges = []

def fnode(path, name, summary, tags, complexity, notes=None):
    n = {"id": f"file:{path}", "type": "file", "name": name, "filePath": path,
         "summary": summary, "tags": tags, "complexity": complexity}
    if notes: n["languageNotes"] = notes
    nodes.append(n)

def cnode(path, cls, summary, tags, lr, complexity="moderate"):
    nodes.append({"id": f"class:{path}:{cls}", "type": "class", "name": cls,
                  "filePath": path, "lineRange": lr, "summary": summary,
                  "tags": tags, "complexity": complexity})

def funcnode(path, fn, summary, tags, lr, complexity="moderate"):
    nodes.append({"id": f"function:{path}:{fn}", "type": "function", "name": fn,
                  "filePath": path, "lineRange": lr, "summary": summary,
                  "tags": tags, "complexity": complexity})

def e(src, tgt, typ, w):
    edges.append({"source": src, "target": tgt, "type": typ, "direction": "forward", "weight": w})

def contains(path, kind_id):
    e(f"file:{path}", kind_id, "contains", 1.0)

P = "Vayl/Features/Home/Components/DesireMapIndicator.swift"
fnode(P, "DesireMapIndicator.swift",
      "Dashboard component that renders the couple's Desire Map status across its many states (youDone, bothReady, freeRevealSeen, redoInProgress) with state-specific cards and CTAs.",
      ["view","component","ui"], "complex")
cnode(P, "DesireMapIndicator",
      "SwiftUI View switching on DesireMapState to show the right status card; each case card was extracted into its own property/function to keep type-checking fast.",
      ["view","component","ui"], [5,298], complexity="complex")
contains(P, f"class:{P}:DesireMapIndicator")
funcnode(P, "redoInProgressCard",
         "Builds the 'check-in / redo in progress' card showing your and the partner's redo status with a conditional remind CTA.",
         ["view","ui"], [212,273])

P = "Vayl/Features/Home/Components/GettingStartedEntryCard.swift"
fnode(P, "GettingStartedEntryCard.swift",
      "Compact dashboard entry card ('Your first steps') showing onboarding-path progress; carries the matched-geometry source that morphs into the full Path overlay when tapped.",
      ["view","component","ui"], "simple")
cnode(P, "GettingStartedEntryCard",
      "SwiftUI View rendering a progress ring + next-step title; source of the matchedGeometryEffect expand-to-Path morph.",
      ["view","component","ui"], [5,46])
contains(P, f"class:{P}:GettingStartedEntryCard")

P = "Vayl/Features/Home/Components/GravLiftView.swift"
fnode(P, "GravLiftView.swift",
      "Decorative tractor-beam 'grav lift' effect (layered cones, halo, and scan lines) that breathes with a phase input; non-interactive ambient visual behind the home hero card.",
      ["view","component","ui"], "moderate",
      "Pure layered LinearGradient/EllipticalGradient composition driven by a breathPhase sine; allowsHitTesting(false) + accessibilityHidden.")
cnode(P, "GravLiftView",
      "SwiftUI View composing the levitation light cone from gradient layers, opacity driven by a breathing sine wave.",
      ["view","component","ui"], [8,130])
contains(P, f"class:{P}:GravLiftView")

P = "Vayl/Features/Home/Components/HomeWidgetShell.swift"
fnode(P, "HomeWidgetShell.swift",
      "Reusable home-dashboard widget chrome: a generic container that wraps arbitrary content in a themed surface with inset shadows, a spectrum rim, and an underglow; also defines the OrbLayer ambient backdrop.",
      ["view","component","ui","container"], "complex",
      "Generic over Content: View; light/dark surfaces built as separate functions to keep the SwiftUI type-checker fast.")
cnode(P, "HomeWidgetShell",
      "Generic SwiftUI container View providing the standard home widget surface (background, rim, shadows, underglow) around injected content.",
      ["view","component","container","ui"], [171,583], complexity="complex")
contains(P, f"class:{P}:HomeWidgetShell")
cnode(P, "OrbLayer",
      "SwiftUI View rendering a primary + secondary set of soft glowing orbs as an ambient backdrop inside home widgets.",
      ["view","component","ui"], [31,164])
contains(P, f"class:{P}:OrbLayer")
funcnode(P, "darkSurface",
         "Builds the dark-mode widget surface fill and layered gradients for the widget shell.",
         ["view","ui"], [233,330])
funcnode(P, "lightSurface",
         "Builds the light-mode widget surface fill and layered gradients for the widget shell.",
         ["view","ui"], [335,442])
funcnode(P, "rim",
         "Computes the spectrum rim overlay stroke that traces the widget edge.",
         ["view","ui"], [490,563])

P = "Vayl/Features/Home/Components/PartnerChip.swift"
fnode(P, "PartnerChip.swift",
      "Dashboard chip that renders the partner-presence affordance across states (no partner / invite-pending / active / multiple stub), using holographic shimmer for the invite states.",
      ["view","component","ui"], "complex")
cnode(P, "PartnerChip",
      "SwiftUI View switching on PartnerChipState to show an invite button, pending badge, or active partner capsule.",
      ["view","component","ui"], [5,219], complexity="complex")
contains(P, f"class:{P}:PartnerChip")
e(f"file:{P}", "file:Vayl/Design/Components/Effects/HolographicShimmer.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Effects/LightModeShimmer.swift", "depends_on", 0.6)

P = "Vayl/Features/Home/Components/PickUpCard.swift"
fnode(P, "PickUpCard.swift",
      "Dashboard 'pick up where you left off' list card rendering in-progress content items (timeline, article, judgment, autopsy) with a pulsing activity dot and a see-all action.",
      ["view","component","ui"], "moderate")
cnode(P, "PickUpCard",
      "SwiftUI View listing up to two PickUpItems with per-item tap callbacks; renders EmptyView when there is nothing in progress.",
      ["view","component","ui"], [5,107])
contains(P, f"class:{P}:PickUpCard")

P = "Vayl/Features/Home/Components/ReflectionBannerView.swift"
fnode(P, "ReflectionBannerView.swift",
      "Bottom-sheet reflection capture banner shown after a session: lets the user pick feeling pills or write a note, toggle sharing with the partner, and submit; drag-to-dismiss.",
      ["view","component","ui","input"], "complex")
cnode(P, "ReflectionBannerView",
      "SwiftUI View for the post-session reflection panel (inline pill grid + note editor + share toggle + full-pill sheet) with a drag-dismiss gesture.",
      ["view","component","ui","input"], [5,398], complexity="complex")
contains(P, f"class:{P}:ReflectionBannerView")
funcnode(P, "bannerPillButton",
         "Builds one selectable feeling-pill button with selected/unselected spectrum styling and haptics.",
         ["view","ui"], [225,280])

P = "Vayl/Features/Home/Components/ReflectionCard.swift"
fnode(P, "ReflectionCard.swift",
      "Large dashboard reflection card rendering the full reflection lifecycle (pending / waiting-on-partner / both-reflected / summary) with a paged, swipeable layout and a pill-selection sheet.",
      ["view","component","ui"], "complex")
cnode(P, "ReflectionCard",
      "SwiftUI View switching on ReflectionCardState to render the appropriate reflection card; each state is a dedicated builder function for type-check performance.",
      ["view","component","ui"], [5,689], complexity="complex")
contains(P, f"class:{P}:ReflectionCard")
funcnode(P, "pendingCard",
         "Builds the 'reflect on your last session' pending card with pill grid and CTA (the largest of the reflection card states).",
         ["view","ui"], [81,233])
funcnode(P, "bothReflectedCard",
         "Builds the both-partners-reflected comparison card showing each person's pills and notes side by side.",
         ["view","ui"], [303,379])

P = "Vayl/Features/Home/Components/ResearchTicker.swift"
fnode(P, "ResearchTicker.swift",
      "Ambient, non-interactive ticker that cycles a curated list of CNM research facts, definitions, and reframes on a timer with a cross-fade.",
      ["view","component","ui"], "moderate")
cnode(P, "ResearchTicker",
      "SwiftUI View cycling a hardcoded ResearchFact array every 10s with an opacity cross-fade; decorative (hit-testing disabled).",
      ["view","component","ui"], [5,107])
contains(P, f"class:{P}:ResearchTicker")

P = "Vayl/Features/Home/Models/GettingStarted.swift"
fnode(P, "GettingStarted.swift",
      "Pure Model-layer derivation of the post-onboarding 'first steps' activation: resolves the ordered step list and their states (done/active/upcoming/locked) from the couple's flags.",
      ["data-model","state"], "moderate",
      "No SwiftUI; the displayed Path and entry card both read this derived value, which is never stored.")
cnode(P, "GettingStarted",
      "Equatable value type holding the ordered onboarding steps with progress/nextStep helpers and a static resolve() that derives state from completion flags.",
      ["data-model","state"], [48,86])
contains(P, f"class:{P}:GettingStarted")
funcnode(P, "resolve",
         "Static factory that derives the GettingStarted activation (exactly one .active step, reveal gated on both maps) from myMapComplete/isPaired/partnerMapComplete/revealDone.",
         ["data-model","factory","state"], [63,85])
contains(P, f"function:{P}:resolve")  # also exported sub-node
e(f"file:{P}", f"function:{P}:resolve", "exports", 0.8)

P = "Vayl/Features/Home/Models/HomeEventEngine.swift"
fnode(P, "HomeEventEngine.swift",
      "Pure logic struct that selects the home greeting's two-line sub-copy from a prioritized list of HomeEvents (partner events → milestones → time/absence → stage defaults).",
      ["data-model","utility"], "moderate")
cnode(P, "HomeEventEngine",
      "Stateless struct whose single static oneLiner() maps app/event state to one localized greeting string by priority.",
      ["data-model","utility"], [8,103])
contains(P, f"class:{P}:HomeEventEngine")
funcnode(P, "oneLiner",
         "Static function returning the greeting sub-copy by walking events in priority order, then falling back to stage-based defaults.",
         ["utility"], [14,102])
contains(P, f"function:{P}:oneLiner")
e(f"file:{P}", f"function:{P}:oneLiner", "exports", 0.8)

P = "Vayl/Features/Home/Models/HomeModels.swift"
fnode(P, "HomeModels.swift",
      "View-layer Model definitions for the Home screen: the ReflectionCardState and HomeState routing enums, reflection pill groups, pick-up items, research facts, and the HomeEvent enum.",
      ["data-model","type-definition"], "moderate",
      "No business logic and no SwiftData; pure structs/enums consumed by the Home views and HomeStore.")
# HomeState and ReflectionCardState are the load-bearing enums; emit one node for HomeState.
cnode(P, "HomeState",
      "Routing enum that drives HomeRouterView (dashboard / soloUnpaired / vestigial gated); computed by HomeStore, never set by the view.",
      ["data-model","state","type-definition"], [147,151])
contains(P, f"class:{P}:HomeState")
cnode(P, "ReflectionCardState",
      "Enum modeling the reflection card's lifecycle states (hidden / pendingYours / waitingOnPartner / bothReflected / summary) with their associated payloads.",
      ["data-model","state","type-definition"], [11,30])
contains(P, f"class:{P}:ReflectionCardState")

P = "Vayl/Features/Home/Store/HomeStore.swift"
fnode(P, "HomeStore.swift",
      "The Home feature's Store: an @Observable @MainActor brain that owns all routing state, derives HomeState/GettingStarted, loads profile/desire-status/deck-progress/reflection/deck data, and tracks the one-shot map-completion beat.",
      ["store","state","observable"], "complex",
      "Dependencies injected via init; ModelContext created fresh at write time; reads SwiftData (UserProfile/DeckProgress/CardSession) and remote DesireSyncService.")
cnode(P, "HomeStore",
      "@Observable @MainActor Store deciding all Home routing and loading; the view renders, the store decides.",
      ["store","state","observable"], [22,323], complexity="complex")
contains(P, f"class:{P}:HomeStore")
funcnode(P, "resolveHomeState",
         "Derives the current HomeState from completion + link flags; Home always leads with the dashboard, soloUnpaired only when solo and unlinked.",
         ["store","state"], [126,138])
funcnode(P, "loadAll",
         "Async entry point that loads profile, desire status, deck progress, reflection state, and the deck in one pass on appear.",
         ["store","data-loading"], [176,182])
funcnode(P, "loadProfile",
         "Reads the local UserProfile to resolve map completion and the derived DesireMapState.",
         ["store","data-loading"], [198,218])
funcnode(P, "loadReflectionState",
         "Reads the most recent completed CardSession to derive the reflection card state (pendingYours when a finished session exists).",
         ["store","data-loading"], [267,303])
funcnode(P, "loadDeck",
         "Loads 'the-opener' deck via ContentLoader, publishing loading/error state for the dashboard.",
         ["store","data-loading"], [307,322])
# cross-file Store->Service / Store->Model-loader calls
e(f"file:{P}", "file:Vayl/Core/Services/ContentLoader.swift", "calls", 0.8)
e(f"file:{P}", "file:Vayl/Core/Services/DesireSyncService.swift", "calls", 0.8)
e(f"file:{P}", "file:Vayl/Features/Home/Models/HomeModels.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Home/Models/GettingStarted.swift", "depends_on", 0.6)

P = "Vayl/Features/Home/Views/GettingStartedPathView.swift"
fnode(P, "GettingStartedPathView.swift",
      "The expanded 'Path' overlay listing the couple's first steps to their reveal; destination of the matched-geometry morph from GettingStartedEntryCard, presented over a blurred Home.",
      ["view","component","ui","onboarding"], "moderate")
cnode(P, "GettingStartedPathView",
      "SwiftUI View rendering the spectrum step rail and copy for the Getting Started Path; only .active steps are tappable.",
      ["view","component","ui"], [5,75])
contains(P, f"class:{P}:GettingStartedPathView")
cnode(P, "PathStepRow",
      "Private SwiftUI View for one Path node: a spectrum rail segment plus a state-styled node (done/active/upcoming/locked) and step copy.",
      ["view","component","ui"], [78,145])
contains(P, f"class:{P}:PathStepRow")
e(f"file:{P}", "file:Vayl/Features/Home/Models/GettingStarted.swift", "depends_on", 0.6)

P = "Vayl/Features/Home/Views/HomeDashboardView.swift"
fnode(P, "HomeDashboardView.swift",
      "The main Home dashboard view: composes the greeting, card chest/carousel hero, desire-map indicator, reflection card, pick-up list, partner chip, and ambient prism/constellation zones into the scrolling home surface with a choreographed entrance.",
      ["view","component","ui","entry-point"], "complex",
      "Pure render layer fed entirely by HomeStore-derived inputs via initializer args; orchestrates many sub-components.")
cnode(P, "HomeDashboardView",
      "SwiftUI View assembling the full home dashboard from injected state and callbacks; owns the entrance animation and ambient-zone layout but no business logic.",
      ["view","component","ui"], [15,597], complexity="complex")
contains(P, f"class:{P}:HomeDashboardView")
funcnode(P, "runEntranceAnimations",
         "Drives the staggered entrance choreography for the dashboard's elements.",
         ["view","ui","animation"], [580,596])
# depends_on the components it renders
for tgt in [
    "Vayl/Features/Home/Components/GettingStartedEntryCard.swift",
    "Vayl/Features/Home/Components/CardChestContainer.swift",
    "Vayl/Features/Home/Components/DesireMapIndicator.swift",
    "Vayl/Features/Home/Components/ReflectionCard.swift",
    "Vayl/Features/Home/Components/PickUpCard.swift",
    "Vayl/Features/Home/Components/GravLiftView.swift",
    "Vayl/Features/Home/Components/ReflectionBannerView.swift",
    "Vayl/Features/Home/Components/HomeWidgetShell.swift",
    "Vayl/Features/Home/Components/PartnerChip.swift",
    "Vayl/Features/Pulse/PulseWidget.swift",
    "Vayl/Features/Map/PrismView.swift",
    "Vayl/Features/Learn/Views/ConstellationNode.swift",
    "Vayl/Design/Components/Effects/AuroraGlowField.swift",
    "Vayl/Design/Components/Effects/HomeGlowField.swift",
    "Vayl/Design/Components/Text/LivingText.swift",
]:
    e(f"file:{P}", f"file:{tgt}", "depends_on", 0.6)

P = "Vayl/Features/Home/Views/HomeGateView.swift"
fnode(P, "HomeGateView.swift",
      "Retired-from-routing gate screen that pitched the Desire Map as 'step 1 of 2' with a privacy info card and a choreographed entrance; kept on disk but no longer in the Home routing flow.",
      ["view","component","ui"], "complex",
      "ViewThatFits with a scroll fallback for SE/large-text; entrance stagger preserved.")
cnode(P, "HomeGateView",
      "SwiftUI View for the (now vestigial) pre-map gate, with overline/headline/info-card content and a Start-Your-Desire-Map CTA.",
      ["view","component","ui"], [12,297], complexity="complex")
contains(P, f"class:{P}:HomeGateView")

P = "Vayl/Features/Home/Views/HomeRouterView.swift"
fnode(P, "HomeRouterView.swift",
      "Thin Home routing view: owns appState/modelContext, constructs HomeStore, and switches on store.homeState to render the dashboard while hosting the session sheet, desire-map rater, reveal cover, Path overlay, and completion beat.",
      ["view","ui","entry-point"], "complex",
      "All routing/state lives in HomeStore; this file only renders and wires presentation + action handlers.")
cnode(P, "HomeRouterView",
      "Outer SwiftUI View that reads the environment and hands appState + modelContainer to the inner router.",
      ["view","ui"], [14,25], complexity="simple")
contains(P, f"class:{P}:HomeRouterView")
cnode(P, "HomeRouterInnerView",
      "Private SwiftUI View that constructs and drives HomeStore, presents the session/map/reveal/path/beat surfaces, and routes card and getting-started actions.",
      ["view","ui","state"], [27,308], complexity="complex")
contains(P, f"class:{P}:HomeRouterInnerView")
funcnode(P, "handleCardAction",
         "Routes a dashboard card action: starts a SessionStore-backed session resuming from progress, or switches to the Play tab.",
         ["view","event-handler"], [216,234])
funcnode(P, "handleStep",
         "Routes a tapped Getting Started Path step to its surface (open the desire-map rater, switch to pairing on Map, present the reveal, or no-op for profile).",
         ["view","event-handler"], [240,258])
funcnode(P, "handleRaterDismiss",
         "On rater close, refreshes Home and fires the one-shot completion beat when the map just flipped to complete.",
         ["view","event-handler"], [267,275])
# View depends on Store + presents other Stores/Views
e(f"file:{P}", "file:Vayl/Features/Home/Store/HomeStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Monetization/Store/EntitlementStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Sessions/SessionStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Sessions/SessionView.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Desire Map/Store/DesireMapStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Desire Map/Views/DesireMapView.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Desire Map/Store/DesireRevealStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Desire Map/Views/DesireRevealView.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Home/Views/HomeDashboardView.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Home/Views/GettingStartedPathView.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Features/Home/Views/MapCompletionBeatView.swift", "depends_on", 0.6)

P = "Vayl/Features/Home/Views/MapCompletionBeatView.swift"
fnode(P, "MapCompletionBeatView.swift",
      "A brief one-shot celebration beat shown over the Home dashboard the moment the user finishes their Desire Map; tap to continue, reusing the reveal's prism emblem motif.",
      ["view","component","ui"], "moderate")
cnode(P, "MapCompletionBeatView",
      "Transient SwiftUI overlay View that dims the dashboard, shows a pulsing prism emblem and forward-looking copy, and calls onDone on tap.",
      ["view","component","ui"], [15,92])
contains(P, f"class:{P}:MapCompletionBeatView")

P = "Vayl/Features/Learn/Views/ConstellationNode.swift"
fnode(P, "ConstellationNode.swift",
      "The Learn 'constellation' visualization: a model for stat/term nodes plus the floating, tappable node views, proximity connection lines, a detail bottom sheet, and the container ConstellationView.",
      ["view","component","ui","data-model"], "complex",
      "Mixes a small data model (ConstellationNode/Satellite) with several private views and a ViewModifier; nodes float and fire a burst on tap.")
cnode(P, "ConstellationView",
      "Main SwiftUI View laying out constellation nodes over a canvas with proximity links, tap handling, a legend, and a detail sheet.",
      ["view","component","ui"], [483,712], complexity="complex")
contains(P, f"class:{P}:ConstellationView")
cnode(P, "ConstellationNodeView",
      "Private SwiftUI View for a single floating constellation node with shimmer and a tap burst animation.",
      ["view","component","ui"], [190,329])
contains(P, f"class:{P}:ConstellationNodeView")
cnode(P, "ConstellationSheet",
      "Private bottom-sheet View showing a tapped node's header, body, source, and satellite detail cards.",
      ["view","component","ui"], [335,477])
contains(P, f"class:{P}:ConstellationSheet")
cnode(P, "ConstellationNode",
      "Identifiable data model for one constellation node (stat or term) and its satellites.",
      ["data-model","type-definition"], [37,48])
contains(P, f"class:{P}:ConstellationNode")
funcnode(P, "constellationCanvas",
         "Builds the node + connection-line canvas, positioning each node and drawing proximity links.",
         ["view","ui"], [569,618])

P = "Vayl/Features/Learn/Views/LearnView.swift"
fnode(P, "LearnView.swift",
      "Placeholder Learn tab screen showing only a 'Learn' title over the page background; the real Learn content hub is not yet built.",
      ["view","ui","entry-point"], "simple")
cnode(P, "LearnView",
      "Minimal SwiftUI View stub for the Learn tab.",
      ["view","ui"], [14,23], complexity="simple")
contains(P, f"class:{P}:LearnView")

P = "Vayl/Features/Map/MapView.swift"
fnode(P, "MapView.swift",
      "Temporary Map tab harness that renders PairingSettingsView for partner-linking verification; to be replaced by the real Map / Desire Map implementation.",
      ["view","ui","entry-point"], "simple")
cnode(P, "MapView",
      "Thin SwiftUI View wrapper that currently shows the pairing settings screen.",
      ["view","ui"], [22,26], complexity="simple")
contains(P, f"class:{P}:MapView")
e(f"file:{P}", "file:Vayl/Features/Pairing/PairingSettingsView.swift", "depends_on", 0.6)

P = "Vayl/Features/Map/PrismView.swift"
fnode(P, "PrismView.swift",
      "The Map-tab 'prism' widget: a mode-switching surface (Journal / Reflect / Agreements) with time-aware prompts, a solo-card draw, cursor-blink journaling, and expandable agreement rows, wrapped in the HomeWidgetShell chrome.",
      ["view","component","ui"], "complex",
      "Large multi-mode view; each mode is a separate ViewBuilder for type-check performance.")
cnode(P, "PrismView",
      "SwiftUI View rendering the three-mode prism widget with a pill switcher and per-mode content.",
      ["view","component","ui"], [69,769], complexity="complex")
contains(P, f"class:{P}:PrismView")
cnode(P, "PrismMode",
      "CaseIterable enum for the prism's modes (journal/reflect/agreements) carrying label, color, private label, and a time-aware prompt.",
      ["data-model","type-definition"], [15,65])
contains(P, f"class:{P}:PrismMode")
funcnode(P, "journalContent",
         "Builds the journaling mode UI (prompt, cursor-blink text entry, solo card draw).",
         ["view","ui"], [231,403])
funcnode(P, "reflectContent",
         "Builds the reflect mode UI surface for the prism widget.",
         ["view","ui"], [408,583])
e(f"file:{P}", "file:Vayl/Features/Home/Components/HomeWidgetShell.swift", "depends_on", 0.6)

P = "Vayl/Features/Monetization/Store/EntitlementStore.swift"
fnode(P, "EntitlementStore.swift",
      "Monetization Store: the central @Observable read surface for the couple's access tier (isCore/tier), OR-ing the couple's server tier with local StoreKit ownership, and driving purchase/restore and background transaction updates.",
      ["store","state","observable","service"], "complex",
      "Couple-level entitlement: one purchase unlocks both partners; Views read isCore and call purchase()/restore() while StoreKitService + EntitlementService do the I/O.")
cnode(P, "EntitlementStore",
      "@Observable @MainActor Store resolving Core entitlement from server + StoreKit, exposing isCore/corePriceText and running purchase()/restore()/bootstrap().",
      ["store","state","observable"], [19,206], complexity="complex")
contains(P, f"class:{P}:EntitlementStore")
funcnode(P, "bootstrap",
         "App-launch entry: loads the Core product, resolves the tier, and starts the StoreKit transaction-updates listener.",
         ["store","service"], [77,86])
funcnode(P, "refresh",
         "Re-resolves isCore from local StoreKit ownership and the couple's server tier, keeping the last tier on a network blip.",
         ["store","service"], [92,106])
funcnode(P, "purchase",
         "Runs the Core purchase, unlocks the buyer locally, pushes the signed JWS to the server so the partner unlocks too, then re-resolves.",
         ["store","service"], [114,140])
funcnode(P, "restore",
         "Explicit Restore Purchases path: re-syncs from the App Store, re-grants the couple server-side if Core is owned, then re-resolves.",
         ["store","service"], [145,159])
e(f"file:{P}", "file:Vayl/Core/Services/EntitlementService.swift", "calls", 0.8)
e(f"file:{P}", "file:Vayl/Core/Services/StoreKitService.swift", "calls", 0.8)

P = "Vayl/Features/Monetization/Views/PaywallSheet.swift"
fnode(P, "PaywallSheet.swift",
      "The reusable Vayl paywall: one Core-scoped bottom sheet ($24.99 one-time, both unlock) presented from three doors (reveal / settings / play-deck) whose only difference is the hook header; purchase and restore run through EntitlementStore.",
      ["view","ui","api-handler"], "complex",
      "ViewThatFits content-height with a scroll backstop for large Dynamic Type; legal links open an in-app Safari sheet.")
cnode(P, "PaywallSheet",
      "SwiftUI View for the paywall sheet, composing hook header, value bullets, price row, CTA, and legal footer; calls EntitlementStore.purchase()/restore().",
      ["view","ui"], [14,428], complexity="complex")
contains(P, f"class:{P}:PaywallSheet")
funcnode(P, "purchase",
         "Kicks off the Core purchase via EntitlementStore and invokes onUnlocked when it succeeds.",
         ["view","event-handler"], [392,400])
funcnode(P, "restorePurchases",
         "Runs EntitlementStore.restore(), opening the gate on success or showing a 'nothing to restore' alert.",
         ["view","event-handler"], [404,417])
e(f"file:{P}", "file:Vayl/Features/Monetization/Store/EntitlementStore.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Effects/VaylButton.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Text/LivingText.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Text/SpectrumBulletRow.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Effects/GlowOrb.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Effects/SpectrumHairline.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Navigation/SafariView.swift", "depends_on", 0.6)

P = "Vayl/Features/Onboarding/Canvas/Engines/CardFlightEngine.swift"
fnode(P, "CardFlightEngine.swift",
      "Onboarding card-deal engine: owns the OB card landing-slot pool and bridges SwiftUI to the SpriteKit CardFlightScene, flying card-back snapshots from off-screen to natural resting slots and returning their final offset/angle.",
      ["service","animation","sequencer"], "moderate",
      "@MainActor class holding a weak VaylDirector; uses ImageRenderer to snapshot VaylCardBack and async/await over the scene's rest callback.")
cnode(P, "CardFlightEngine",
      "@MainActor engine that claims landing slots and deals single cards through the director's CardFlightScene, resolving rested positions via a checked continuation.",
      ["service","animation","sequencer"], [5,147])
contains(P, f"class:{P}:CardFlightEngine")
funcnode(P, "dealSingleCard",
         "Snapshots a VaylCardBack, picks a far-enough landing slot, decides overshoot, and flies the card via SpriteKit, returning its resting offset/angle/flightID.",
         ["animation","sequencer"], [79,141])
funcnode(P, "sailCard",
         "Flies a single card image through the SpriteKit scene between two points and awaits its rested position and rotation.",
         ["animation","sequencer"], [37,74])
e(f"file:{P}", "file:Vayl/Features/Onboarding/Canvas/VaylDirector.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Cards/CardPhysics/CardFlightScene.swift", "depends_on", 0.6)
e(f"file:{P}", "file:Vayl/Design/Components/Cards/VaylCardBack.swift", "depends_on", 0.6)

# ---- Validate ids unique, no self edges ------------------------------------
ids = [n["id"] for n in nodes]
assert len(ids) == len(set(ids)), "DUPLICATE NODE IDS: " + str([x for x in ids if ids.count(x) > 1])
for ed in edges:
    assert ed["source"] != ed["target"], "SELF EDGE: " + str(ed)

node_ids = set(ids)

# Scan-result paths for cross-file target validation
scan = json.load(open("/Users/bryanjorden/Documents/School/Code/Vayl/.understand-anything/intermediate/scan-result.json"))
scan_paths = set(f["path"] for f in scan["files"])

def target_ok(tid):
    if tid in node_ids:
        return True
    if tid.startswith("file:"):
        return tid[len("file:"):] in scan_paths
    # function:/class: sub-node targets must be in our own nodes
    return False

bad = [ed for ed in edges if not target_ok(ed["source"]) or not target_ok(ed["target"])]
assert not bad, "BAD EDGE TARGETS:\n" + "\n".join(json.dumps(b) for b in bad)

print(f"nodes={len(nodes)} edges={len(edges)}")

# ---- Partition into parts (<=60 nodes / <=120 edges) -----------------------
batch_files = sorted(set(n["filePath"] for n in nodes if "filePath" in n))
nodeCount, edgeCount = len(nodes), len(edges)
if nodeCount <= 60 and edgeCount <= 120:
    parts = 1
else:
    parts = math.ceil(max(nodeCount/60.0, edgeCount/120.0))

print(f"files={len(batch_files)} parts={parts}")

if parts == 1:
    out = {"nodes": nodes, "edges": edges}
    path = os.path.join(OUT_DIR, "batch-10.json")
    json.dump(out, open(path, "w"), indent=2)
    # validate
    json.load(open(path))
    print("WROTE", path, "nodes", len(nodes), "edges", len(edges))
else:
    per = math.ceil(len(batch_files) / parts)
    groups = [batch_files[i:i+per] for i in range(0, len(batch_files), per)]
    # node belongs to part if its filePath in group; sub-nodes use filePath too (always set here)
    written = []
    for k, group in enumerate(groups, start=1):
        gset = set(group)
        gnodes = [n for n in nodes if n.get("filePath") in gset]
        gnode_ids = set(n["id"] for n in gnodes)
        gedges = [ed for ed in edges if ed["source"] in gnode_ids]
        out = {"nodes": gnodes, "edges": gedges}
        path = os.path.join(OUT_DIR, f"batch-10-part-{k}.json")
        json.dump(out, open(path, "w"), indent=2)
        json.load(open(path))  # validate JSON
        # per-part edge validation
        for ed in gedges:
            s_ok = ed["source"] in gnode_ids
            t = ed["target"]
            t_ok = (t in node_ids) or (t.startswith("file:") and t[5:] in scan_paths)
            assert s_ok and t_ok, f"part {k} bad edge {ed}"
        written.append((path, len(gnodes), len(gedges)))
    for path, nn, ee in written:
        print("WROTE", path, "nodes", nn, "edges", ee)
    print("TOTAL parts", len(written),
          "nodes", sum(w[1] for w in written),
          "edges", sum(w[2] for w in written))
