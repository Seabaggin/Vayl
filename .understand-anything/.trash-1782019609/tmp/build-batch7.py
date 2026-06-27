import json, math

P = "Vayl/Design/Components/Cards/"
PP = "Vayl/Design/Components/Cards/CardPhysics/"
EF = "Vayl/Design/Components/Effects/"

nodes = []
edges = []

def fnode(path, name, summary, tags, complexity, notes=None):
    n = {"id": f"file:{path}", "type": "file", "name": name, "filePath": path,
         "summary": summary, "tags": tags, "complexity": complexity}
    if notes: n["languageNotes"] = notes
    nodes.append(n)

def cnode(path, cname, summary, tags, complexity, lr):
    nodes.append({"id": f"class:{path}:{cname}", "type": "class", "name": cname,
                  "filePath": path, "lineRange": lr, "summary": summary,
                  "tags": tags, "complexity": complexity})

def funode(path, fname, summary, tags, complexity, lr):
    nodes.append({"id": f"function:{path}:{fname}", "type": "function", "name": fname,
                  "filePath": path, "lineRange": lr, "summary": summary,
                  "tags": tags, "complexity": complexity})

def edge(src, tgt, typ, w):
    edges.append({"source": src, "target": tgt, "type": typ, "direction": "forward", "weight": w})

def contains(path, kind, name):
    edge(f"file:{path}", f"{kind}:{path}:{name}", "contains", 1.0)

# ============================================================
# CardMirrorDeal.swift
p = PP+"CardMirrorDeal.swift"
fnode(p, "CardMirrorDeal.swift",
      "Mirror-deal card physics controller for the onboarding ModeSelectPhase, dealing two cards from opposite edges that land simultaneously, then handling lift, confirm, and reject animations.",
      ["store","state","observable","card-physics","animation"], "complex",
      "iOS 26 @Observable @MainActor controller driving SwiftUI transforms via withAnimation owned at the view layer.")
cnode(p, "MirrorDealState", "Equatable state machine enum for the mirror deal lifecycle (idle, dealing, resting, faceUp, lifted, confirming, exiting, done).",
      ["state","type-definition","enum"], "simple", [18,27])
cnode(p, "MirrorCard", "Equatable enum identifying the two mirror cards (left = Solo Discovery, right = Together).",
      ["type-definition","enum"], "simple", [29,32])
cnode(p, "CardMirrorDealController", "@Observable @MainActor controller owning the mirror-deal animation: deal, lift, switchLift, confirm, and cleanup of two simultaneously-traveling cards.",
      ["store","state","observable","card-physics","animation"], "complex", [34,344])
funode(p, "deal", "Fires the mirror deal: both cards travel simultaneously from opposite screen edges to resting positions with timed landing haptics and staggered face-up flips.",
       ["animation","card-physics","haptics"], "complex", [85,159])
funode(p, "lift", "Lifts the tapped card to a cinematic center position while receding and dimming the unchosen card; animation owned by the calling view.",
       ["animation","card-physics","interaction"], "moderate", [167,198])
funode(p, "switchLift", "Switches the lifted state to the other card using absolute (non-accumulated) transforms without returning to resting.",
       ["animation","card-physics","interaction"], "moderate", [203,229])
funode(p, "confirm", "Runs the confirm sequence: pockets the chosen card to the corner deck while the rejected card flips face-down and exits, firing onLanded then onConfirm at choreographed times.",
       ["animation","card-physics","haptics"], "complex", [245,336])
for nm in ["MirrorDealState","MirrorCard"]: contains(p, "class", nm)
contains(p, "class", "CardMirrorDealController")
for nm in ["deal","lift","switchLift","confirm"]: contains(p, "function", nm)

# ============================================================
# CarouselPhysics.swift
p = PP+"CarouselPhysics.swift"
fnode(p, "CarouselPhysics.swift",
      "Reusable orientation-agnostic 1-D scroll engine for card carousels, owning a continuous card-index position driven by display-synced SwiftUI springs.",
      ["store","state","observable","card-physics","scroll-engine"], "moderate",
      "Nested Sendable Config struct with nonisolated init; SwiftUI-native motion model with no manual integration loop.")
cnode(p, "CarouselPhysics", "@Observable @MainActor scroll engine exposing continuous position, drag intents, and velocity-projected settle for carousel views.",
      ["store","state","observable","card-physics"], "moderate", [19,149])
cnode(p, "Config", "Sendable Equatable value type holding all tunable carousel feel constants (drag sensitivity, projection, max flick, spring response/damping).",
      ["type-definition","config"], "simple", [26,53])
funode(p, "settle", "Projects a target card from release velocity, clamps it to maxFlick and topology bounds, and snaps position; must be called inside withAnimation.",
       ["card-physics","scroll-engine","gesture"], "moderate", [120,131])
contains(p, "class", "CarouselPhysics")
contains(p, "class", "Config")
contains(p, "function", "settle")

# ============================================================
# ThreeCardFanController.swift
p = PP+"ThreeCardFanController.swift"
fnode(p, "ThreeCardFanController.swift",
      "Three-card-monte fan controller orchestrating SpriteKit deal flights, spread-turnover reveal, lift, and confirm physics for the candle/experience-level selection.",
      ["store","state","observable","card-physics","animation"], "complex",
      "Bridges a SpriteKit CardFlightScene for the deal, then hands off to SwiftUI card backs; respects Reduce Motion.")
cnode(p, "ThreeMonteState", "Equatable state machine enum for the three-card fan lifecycle, carrying CandleIntensity in its lifted/confirming/done cases.",
      ["state","type-definition","enum"], "simple", [13,40])
cnode(p, "ThreeCardFanController", "@Observable @MainActor controller managing three-card fan positions, flips, z-ordering, and the deal/reveal/lift/confirm sequences.",
      ["store","state","observable","card-physics","animation"], "complex", [42,335])
funode(p, "deal", "Flies three card backs one at a time from the dealer point into fan slots via the SpriteKit flight scene with correct z-ordering.",
       ["animation","card-physics","spritekit"], "complex", [63,130])
funode(p, "spreadTurnoverReveal", "Opens the fan into a spread, sweep-turns the cards face-up left to right, then re-collects them into the resting fan.",
       ["animation","card-physics"], "complex", [142,186])
funode(p, "lift", "Lifts the tapped card to a cinematic position while receding the other two cards.",
       ["animation","card-physics","interaction"], "moderate", [218,239])
funode(p, "confirm", "Pockets the chosen card to the corner deck, clears the non-selected cards, and fires onConfirm at landing.",
       ["animation","card-physics"], "complex", [254,306])
funode(p, "runEntrance", "Runs the full entrance sequence (deal, SpriteKit-to-SwiftUI handoff, flourish, reveal).",
       ["animation","card-physics","orchestration"], "moderate", [312,327])
for nm in ["ThreeMonteState","ThreeCardFanController"]: contains(p, "class", nm)
for nm in ["deal","spreadTurnoverReveal","lift","confirm","runEntrance"]: contains(p, "function", nm)

# ============================================================
# CardRevealPillButton.swift
p = P+"CardRevealPillButton.swift"
fnode(p, "CardRevealPillButton.swift",
      "Toggleable pill-shaped selection button for card reveal options, scaling when selected with a staggered entrance and dimming sibling pills.",
      ["view","component","ui","interaction"], "moderate")
cnode(p, "CardRevealPillButton", "SwiftUI View rendering a single selectable reveal pill with spectrum border, scale, staggered entrance, and accessibility traits.",
      ["view","component","ui"], "moderate", [1,105])
contains(p, "class", "CardRevealPillButton")

# ============================================================
# CardShadows.swift
p = P+"CardShadows.swift"
fnode(p, "CardShadows.swift",
      "View extension providing a reusable dual-shadow card modifier (accent color wash plus a black depth shadow), theme-aware.",
      ["design-system","view-modifier","ui"], "simple")

# ============================================================
# CardStyle.swift
p = P+"CardStyle.swift"
fnode(p, "CardStyle.swift",
      "Reusable card-shell ViewModifier and convenience extension applying background, rounded clip, and border stroke to eliminate repetition.",
      ["design-system","view-modifier","ui"], "simple")
cnode(p, "CardStyle", "ViewModifier applying background fill, rounded-rectangle clip, and border stroke for a standard card shell.",
      ["design-system","view-modifier","ui"], "simple", [1,50])
contains(p, "class", "CardStyle")

# ============================================================
# CategoryTileView.swift
p = P+"CategoryTileView.swift"
fnode(p, "CategoryTileView.swift",
      "Home-screen category grid tile displaying an emoji, title, completion count, and progress bar with theme-aware styling.",
      ["view","component","ui"], "moderate")
cnode(p, "CategoryTileView", "SwiftUI View rendering a category tile with emoji icon, title, card-count label, and a completion progress bar.",
      ["view","component","ui"], "moderate", [1,90])
contains(p, "class", "CategoryTileView")

# ============================================================
# ConversationCard.swift
p = P+"ConversationCard.swift"
fnode(p, "ConversationCard.swift",
      "3D-flipping conversation card with a question/fuse-timer front and a response pill-grid back, managing flip state, pill selection, encouragement, and ghost-deck atmosphere.",
      ["view","component","ui","card"], "complex")
cnode(p, "ConversationCard", "SwiftUI View for a flippable conversation card composing front and back faces, pill selection handling, and optional fuse timer and ghost deck.",
      ["view","component","ui","card"], "complex", [1,423])
funode(p, "highlightedQuestion", "Builds an AttributedString question with markdown highlighting applied to a specific target phrase.",
       ["ui","text","formatting"], "moderate", [297,327])
funode(p, "handlePillSelection", "Records the selected pill, invokes onPillSelected, then schedules the encouragement display and onContinue callback on delays.",
       ["interaction","ui","state"], "moderate", [339,354])
contains(p, "class", "ConversationCard")
for nm in ["highlightedQuestion","handlePillSelection"]: contains(p, "function", nm)
# cross-file deps within batch
edge(f"file:{p}", f"file:{P}FuseTimerView.swift", "depends_on", 0.6)
edge(f"file:{p}", f"file:{P}ConversationCardTypes.swift", "imports", 0.7)
edge(f"file:{p}", f"file:{P}AtmosphericGhostDeck.swift", "depends_on", 0.6)

# ============================================================
# ConversationCardTypes.swift
p = P+"ConversationCardTypes.swift"
fnode(p, "ConversationCardTypes.swift",
      "Model types backing the conversation card: OBCard onboarding data, pill/response enums, content discriminators, and fuse/ghost-deck configuration.",
      ["data-model","type-definition","models"], "simple")
cnode(p, "OBCard", "Model struct holding onboarding card data: overline, question, highlighted phrase, and back-face content.",
      ["data-model","type-definition"], "simple", [1,54])
cnode(p, "CardRevealPill", "String-backed CaseIterable Identifiable enum of response pill labels (ready, figuring, scared, almostSaid, noApology).",
      ["data-model","type-definition","enum"], "simple", [1,54])
cnode(p, "ConversationCardContent", "Enum discriminating the conversation card content source (free prompt vs onboarding OBCard).",
      ["data-model","type-definition","enum"], "simple", [1,54])
cnode(p, "GhostDeckMode", "Enum configuring the background card-deck atmosphere (none, atmospheric, navigable).",
      ["data-model","type-definition","enum"], "simple", [1,54])
for nm in ["OBCard","CardRevealPill","ConversationCardContent","GhostDeckMode"]: contains(p, "class", nm)

# ============================================================
# CuriosityCardBack.swift
p = P+"CuriosityCardBack.swift"
fnode(p, "CuriosityCardBack.swift",
      "Face-down side of the curiosity picker card rendering a laser-engraved maze texture with an embedded orbit animation that stops on flip.",
      ["view","component","ui","card"], "moderate")
cnode(p, "CuriosityCardBack", "SwiftUI View drawing the curiosity card back: gradient base, ambient glow, maze pattern with orbit, corner marks, and spectrum border.",
      ["view","component","ui","card"], "moderate", [1,160])
contains(p, "class", "CuriosityCardBack")
edge(f"file:{p}", f"file:{EF}MazePatternView.swift", "depends_on", 0.6)

# ============================================================
# CuriosityFlipCard.swift
p = P+"CuriosityFlipCard.swift"
fnode(p, "CuriosityFlipCard.swift",
      "Generic 3D flip container for curiosity picker cards: a maze/orbit back face and caller-supplied front content, orchestrating the flip and orbit lifecycle.",
      ["view","component","ui","card"], "moderate")
cnode(p, "CuriosityFlipCard", "Generic SwiftUI View flipping between a CuriosityCardBack and arbitrary front content with a spring rotation3D animation.",
      ["view","component","ui","card"], "moderate", [1,73])
contains(p, "class", "CuriosityFlipCard")
edge(f"file:{p}", f"file:{P}CuriosityCardBack.swift", "depends_on", 0.6)

# ============================================================
# FuseTimerView.swift
p = P+"FuseTimerView.swift"
fnode(p, "FuseTimerView.swift",
      "Canvas-drawn fuse/spark countdown timer that travels a glowing spark along a rounded-rectangle border with a progressive burn effect.",
      ["view","component","ui","animation"], "moderate")
cnode(p, "FuseTimerView", "SwiftUI View rendering an animated fuse spark via Canvas with unburned-segment, ember, and multi-layer spark-head passes.",
      ["view","component","ui","animation"], "moderate", [1,141])
contains(p, "class", "FuseTimerView")

# ============================================================
# PremiumCardShell.swift
p = P+"PremiumCardShell.swift"
fnode(p, "PremiumCardShell.swift",
      "Generic glass-morphic card container wrapping arbitrary content in an eight-layer premium composition with optional fuse-burn progress animation.",
      ["view","component","ui","design-system"], "complex")
cnode(p, "PremiumCardShell", "Generic SwiftUI View composing base fill, specular and internal reflections, ambient orbs, premium border, and an optional fuse spark over content.",
      ["view","component","ui","design-system"], "complex", [1,221])
contains(p, "class", "PremiumCardShell")

# ============================================================
# PromptCard.swift
p = P+"PromptCard.swift"
fnode(p, "PromptCard.swift",
      "Simple prompt card displaying a card type, prompt text, and optional intensity label inside a PremiumCardShell.",
      ["view","component","ui"], "simple")
cnode(p, "PromptCard", "SwiftUI View rendering a prompt card's type, body text, and intensity using the PremiumCardShell container.",
      ["view","component","ui"], "simple", [1,34])
contains(p, "class", "PromptCard")
edge(f"file:{p}", f"file:{P}PremiumCardShell.swift", "depends_on", 0.6)

# ============================================================
# SettingsCard.swift
p = P+"SettingsCard.swift"
fnode(p, "SettingsCard.swift",
      "Generic reusable container that wraps Settings-screen content in padded rounded-card styling.",
      ["view","component","ui"], "simple")
cnode(p, "SettingsCard", "SwiftUI View applying padding and the shared cardStyle modifier to wrap arbitrary settings content.",
      ["view","component","ui"], "simple", [1,15])
contains(p, "class", "SettingsCard")
edge(f"file:{p}", f"file:{P}CardStyle.swift", "depends_on", 0.6)

# ============================================================
# VaylCardAction.swift
p = P+"VaylCardAction.swift"
fnode(p, "VaylCardAction.swift",
      "Action enum describing the gestures and state changes a card face reports upward to Phases, which forward intents to VaylDirector.",
      ["data-model","type-definition","interaction"], "simple")
cnode(p, "VaylCardAction", "Enum of card-face intents (tapped, swipedUp/Down, dragChanged/Ended, confirmed, identitySelected) used as the face-to-phase communication contract.",
      ["data-model","type-definition","enum"], "simple", [1,22])
contains(p, "class", "VaylCardAction")

# ============================================================
# VaylCardBack.swift
p = P+"VaylCardBack.swift"
fnode(p, "VaylCardBack.swift",
      "Canvas-rendered back face of a Vayl onboarding card: void base, atmosphere gradients, multi-pass VAYL wordmark, counter-rotated hex moire grid, and spectrum frames, with parameterized dissolution.",
      ["view","component","ui","card","canvas"], "complex",
      "Pure render component with no flipping, animation, gestures, or state; the caller (VaylCardRenderer) owns all transforms.")
cnode(p, "VaylCardBack", "SwiftUI View drawing the layered Vayl card back via Canvas, accepting dissolution overrides for hex angle, hex spacing, and wordmark opacity.",
      ["view","component","ui","card","canvas"], "complex", [1,426])
funode(p, "drawWordmark", "Multi-pass Canvas render of the VAYL wordmark: outer bloom, inner glow, emboss shadow and highlight, and a sharp spectrum-gradient core.",
       ["canvas","rendering","ui"], "complex", [155,249])
funode(p, "drawHexLayer", "Draws a single rotated hex-grid layer at a given angle, color, and opacity for the moire interference effect.",
       ["canvas","rendering","ui"], "moderate", [259,324])
funode(p, "drawAtmosphere", "Draws three radial-gradient blobs (cyan, magenta, purple) behind the wordmark for atmospheric depth.",
       ["canvas","rendering","ui"], "moderate", [97,148])
contains(p, "class", "VaylCardBack")
for nm in ["drawWordmark","drawHexLayer","drawAtmosphere"]: contains(p, "function", nm)

# ============================================================
# VaylCardCarousel.swift
p = P+"VaylCardCarousel.swift"
fnode(p, "VaylCardCarousel.swift",
      "Generic reusable card carousel rendering arbitrary card content in a stacked peek pile, with browse/exit gestures paired to the CarouselPhysics scroll engine.",
      ["view","component","ui","card","carousel"], "complex")
cnode(p, "VaylCardCarousel", "Generic SwiftUI View driving a stacked card carousel: per-slot transforms, browse gestures, confirm highlight, and breathing animation backed by CarouselPhysics.",
      ["view","component","ui","carousel"], "complex", [20,302])
cnode(p, "StackLayout", "Equatable peek-geometry config (spacing, opacity falloff, rotation, blur per card distance) for the stacked carousel layout.",
      ["type-definition","config","ui"], "simple", [303,319])
funode(p, "transform", "Maps a card's scroll-distance slot into x/y offset, scale, rotation, opacity, and blur for the stacked layout.",
       ["ui","layout","card"], "moderate", [198,226])
contains(p, "class", "VaylCardCarousel")
contains(p, "class", "StackLayout")
contains(p, "function", "transform")
edge(f"file:{p}", f"file:{PP}CarouselPhysics.swift", "depends_on", 0.6)

# ============================================================
# VaylCardContent.swift
p = P+"VaylCardContent.swift"
fnode(p, "VaylCardContent.swift",
      "Public enum describing every content type a Vayl card face can render (portal, mode, context, curiosity, candle, compass, snapshot, and onboarding symbols), written onto VaylCardModel by the Director.",
      ["data-model","type-definition","enum"], "moderate")
cnode(p, "VaylCardContent", "Equatable enum enumerating all Vayl card face content variants consumed by VaylCardRenderer and VaylCardFace.",
      ["data-model","type-definition","enum"], "moderate", [1,86])
cnode(p, "ModeMotifStyle", "Equatable enum selecting the glass-bar motif style (single vs dual) for mode-selection cards.",
      ["data-model","type-definition","enum"], "simple", [1,86])
for nm in ["VaylCardContent","ModeMotifStyle"]: contains(p, "class", nm)

# ============================================================
# VaylCardFace.swift
p = P+"VaylCardFace.swift"
fnode(p, "VaylCardFace.swift",
      "Front face of a Vayl card: owns the shell, spectrum diamond, corner marks, and question text, and routes VaylCardContent cases to their specific content-face builders.",
      ["view","component","ui","card"], "complex",
      "Router-pattern View dispatching to 12+ private content-face builders; caller owns frame, scale, rotation, opacity, offset, and shadow.")
cnode(p, "VaylCardFace", "SwiftUI View for the Vayl card front, composing shell plus content and dispatching VaylCardContent to the matching content face.",
      ["view","component","ui","card"], "complex", [29,225])
cnode(p, "ModeFaceContent", "Private SwiftUI View rendering the ModeSelectPhase glass-bar motif (single or dual bars) via an eight-pass Canvas.",
      ["view","component","ui","canvas"], "complex", [370,640])
cnode(p, "FaceAtmosphere", "Private SwiftUI View drawing three low-opacity radial-gradient blobs as the card-front atmospheric background.",
      ["view","component","ui"], "simple", [264,306])
cnode(p, "QuestionText", "Private SwiftUI View rendering vertically centered question text with padding zones.",
      ["view","component","ui","text"], "simple", [307,342])
funode(p, "contentFace", "ViewBuilder routing each VaylCardContent case to its corresponding content-face builder (typewriter, slotMachine, radioTuner, controller, mode, candle, compass, snapshot, etc.).",
       ["ui","routing","card"], "complex", [130,225])
contains(p, "class", "VaylCardFace")
contains(p, "class", "ModeFaceContent")
contains(p, "class", "FaceAtmosphere")
contains(p, "class", "QuestionText")
contains(p, "function", "contentFace")

# ============================================================
# VaylCardRenderer.swift
p = P+"VaylCardRenderer.swift"
fnode(p, "VaylCardRenderer.swift",
      "Single source of truth translating VaylCardModel physics state into pixels, applying all transforms and choosing VaylCardBack vs VaylCardFace by flip progress.",
      ["view","component","ui","card"], "simple")
cnode(p, "VaylCardRenderer", "SwiftUI View that reads VaylCardModel and renders the flipped card with shadow, scale, rotation, and position transforms.",
      ["view","component","ui","card"], "simple", [1,55])
contains(p, "class", "VaylCardRenderer")
edge(f"file:{p}", f"file:{P}VaylCardBack.swift", "depends_on", 0.6)
edge(f"file:{p}", f"file:{P}VaylCardFace.swift", "depends_on", 0.6)
edge(f"file:{p}", f"file:Vayl/Features/Onboarding/Models/VaylCardModel.swift", "depends_on", 0.6)

# ============================================================
# VaylDeckStack.swift
p = P+"VaylDeckStack.swift"
fnode(p, "VaylDeckStack.swift",
      "Renders a squared deck of six card backs at rest whose per-layer offsets mirror ConfirmationPhase exit positions, reused by CuriosityPhase and BuildDeckPhase.",
      ["view","component","ui","card"], "simple")
cnode(p, "VaylDeckStack", "SwiftUI View stacking six VaylCardBack instances with incremental offsets to depict a deck of Vayl cards at rest.",
      ["view","component","ui","card"], "simple", [1,24])
contains(p, "class", "VaylDeckStack")
edge(f"file:{p}", f"file:{P}VaylCardBack.swift", "depends_on", 0.6)

# ============================================================
# AuroraGlowField.swift
p = EF+"AuroraGlowField.swift"
fnode(p, "AuroraGlowField.swift",
      "Warm Aurora atmospheric blob field of nine animated radial-gradient blobs for light-mode screens, with phase-drifted fade-in and looping sine modulation.",
      ["view","component","ui","effect","animation"], "complex")
cnode(p, "AuroraGlowField", "SwiftUI View rendering the nine-blob Aurora atmosphere across top/mid/lower tiers with staggered entrance and continuous phase animation.",
      ["view","component","ui","effect"], "complex", [87,313])
cnode(p, "AuroraConfig", "Equatable config of per-tier and global opacity multipliers with named presets for each onboarding phase background.",
      ["type-definition","config","ui"], "simple", [39,86])
funode(p, "startAtmosphere", "Kicks off staggered phase-drifted fade-in animations for all nine blobs plus their continuous looping phase animations.",
       ["animation","effect"], "moderate", [262,300])
contains(p, "class", "AuroraGlowField")
contains(p, "class", "AuroraConfig")
contains(p, "function", "startAtmosphere")

# ============================================================
# FilamentMode.swift
p = EF+"FilamentMode.swift"
fnode(p, "FilamentMode.swift",
      "Canvas-based three-orbit filament particle system: a state machine cycling parametric patterns and color sets across three trails, rendered with glow, core, and connection passes.",
      ["view","component","ui","effect","animation"], "complex",
      "Combines an ObservableObject state machine (FilamentState) with a Canvas FilamentView and eight parametric path enums.")
cnode(p, "FilamentState", "ObservableObject state machine advancing three orbit trails, cycling patterns and color transitions, and handling spiral-contraction exit.",
      ["store","state","observable","effect"], "complex", [166,452])
cnode(p, "FilamentView", "Canvas-based SwiftUI View rendering the three-orbit filament system with multi-pass glow/core strokes and inter-trail connection arcs.",
      ["view","component","ui","effect","canvas"], "complex", [453,737])
cnode(p, "FilamentPattern", "Int-backed CaseIterable enum of parametric orbital patterns (figure8, lemniscate, sCurve, weave, circle, spiral, drift, pendulum), each mapping t to a point.",
      ["type-definition","enum","effect"], "moderate", [22,99])
cnode(p, "FilamentColorSet", "Value type holding a primary/light/glow color triplet for a filament orbit, with dark and light preset sets.",
      ["type-definition","config","effect"], "simple", [100,165])
cnode(p, "FilamentMode", "Enum selecting filament behavior (solo vs duo) controlling trail offset parameters.",
      ["type-definition","enum"], "simple", [13,21])
funode(p, "advance", "Advances all three trails each frame: updates t, cycles patterns (frozen during exit), lerps transitions, trims trail history, and cycles colors.",
       ["effect","animation","state"], "complex", [284,430])
funode(p, "drawFilament", "Renders one filament trail in three Canvas passes: glow halo, mid and core strokes, and a white-hot head dot.",
       ["canvas","rendering","effect"], "complex", [558,650])
funode(p, "drawConnection", "Draws a quad-curve arc between two trail heads with glow, core, and proximity-based spark dots.",
       ["canvas","rendering","effect"], "moderate", [651,737])
for nm in ["FilamentState","FilamentView","FilamentPattern","FilamentColorSet","FilamentMode"]: contains(p, "class", nm)
for nm in ["advance","drawFilament","drawConnection"]: contains(p, "function", nm)

# ============================================================
# FlameAura.swift
p = EF+"FlameAura.swift"
fnode(p, "FlameAura.swift",
      "Canvas-based wisp-flame renderer where each wisp rises and wobbles via stacked sines and color-shifts magenta-to-purple, with wisp count and height driven by a selected intensity.",
      ["view","component","ui","effect","animation"], "moderate")
cnode(p, "FlameAura", "SwiftUI View drawing rising wisp flames via Canvas, with per-wisp turbulence, birth/death fade, and intensity-driven wisp count and height.",
      ["view","component","ui","effect","canvas"], "moderate", [1,244])
funode(p, "drawWisp", "Renders a single rising wisp with seeded turbulence, eased rise, base taper, and a two-pass outer-glow plus tight-core fill.",
       ["canvas","rendering","effect"], "complex", [76,183])
funode(p, "taperedWispPath", "Builds a tapered ribbon path for a wisp using cubic-bezier sides converging to a point at the tip.",
       ["canvas","rendering","effect"], "moderate", [184,217])
contains(p, "class", "FlameAura")
for nm in ["drawWisp","taperedWispPath"]: contains(p, "function", nm)

# ============================================================
# Partition + write
# Build set of file paths in alpha order
file_paths = sorted({n["filePath"] for n in nodes if "filePath" in n})

node_count = len(nodes)
edge_count = len(edges)
print(f"TOTAL nodes={node_count} edges={edge_count} files={len(file_paths)}")

if node_count <= 60 and edge_count <= 120:
    out = {"nodes": nodes, "edges": edges}
    with open(".understand-anything/intermediate/batch-7.json","w") as f:
        json.dump(out, f, indent=2)
    print("WROTE single batch-7.json")
else:
    parts = math.ceil(max(node_count/60, edge_count/120))
    per = math.ceil(len(file_paths)/parts)
    groups = [file_paths[i:i+per] for i in range(0, len(file_paths), per)]
    # node id set per group
    written = []
    for k, grp in enumerate(groups, start=1):
        grpset = set(grp)
        gnodes = [n for n in nodes if n.get("filePath") in grpset]
        gnodeids = {n["id"] for n in gnodes}
        gedges = [e for e in edges if e["source"] in gnodeids]
        out = {"nodes": gnodes, "edges": gedges}
        fn = f".understand-anything/intermediate/batch-7-part-{k}.json"
        with open(fn,"w") as f:
            json.dump(out, f, indent=2)
        written.append((fn, len(gnodes), len(gedges)))
        print(f"WROTE {fn} nodes={len(gnodes)} edges={len(gedges)}")
    # validation: total nodes/edges preserved
    tn = sum(w[1] for w in written); te = sum(w[2] for w in written)
    print(f"VALIDATE sum nodes={tn} (expect {node_count}); sum edges={te} (expect {edge_count})")
    assert tn == node_count, "node count mismatch across parts"
    assert te == edge_count, "edge count mismatch across parts"
    print("PARTITION OK")
