# The Path — the couple's roadmap, and the Map tab as the record

Status: design (brainstorm complete, pending user review)
Date: 2026-06-27
Author: Bryan + Claude
Visual references:
- `docs/prototypes/map-roadmap-path.html` (the path + topology + journal loop)
- `docs/prototypes/map-me-us.html` (the Me/Us lens, capacity-framed Pulse, lens-sorted Vault)
- `docs/prototypes/map-vault-options.html` (Vault presentation studies)

---

## 0. Two features, split (read first)

This work is **two features that were being carried as one**, and they must be named and built separately. The breakthrough is the split itself: separate *"where are we right now?"* (assessment) from *"what do we do next?"* (progression). Mashed together they overwhelm; split they form a looping journey.

- **The Alignment Map** (assessment / snapshot) answers *"are we aligned, are we both ready."* Solo plots your comfort against your curiosity; couple overlays both plots and makes the gap visible. A compass / grid, **not** a path. It relates to the parked Orientation / "flavor of NM" read and the existing `Curiosity Compass` card-face spec (`docs/superpowers/specs/2026-06-10-curiosity-compass-cardface-design.md`). **Specced separately. Not this document.**
- **The Pathway** (progression / roadmap) answers *"we want to do this, what's next, how do we start without blowing up the relationship."* The real-life-event roadmap. **This document.**

The three altitudes of "us" nest like a telescope, not a pile: **Alignment Map** (oriented and ready?) zooms to **Desire Map** (which specific things do we both want? already built) zooms to **The Pathway** (how do we go do it, step by step?). The first two are the Map tab's *where we are*; the Pathway is *where we're going*. The Pathway lives in the **Map tab** (the other source thread put everything on one Home screen; Vayl has tabs, do not reshape the IA to match a different app).

## 1. Summary

**The Pathway** is a self-paced, branching roadmap a couple uses to navigate opening their relationship. It renders the journey from "we're curious" to "we're doing this" as a vertical map of real-life landmarks, so the road stops feeling unclear. It is a **tracking and recording** feature, not an activity: the milestones happen off-app, in the world, and the couple comes back to mark them and write how it felt.

The Path is the centerpiece that gives the **Map tab** a single, coherent identity it has been missing: **the Map is the relationship's record over time.** Three faces of one job (*track us*):

- **Pulse** — where you are right now (your capacity, and your partner's).
- **The Path** — where you've been and where you could go.
- **The Vault journal** — what you've felt and kept along the way.

The Path ships in three rungs of agency: a **preset** path (V1), the ability to **customize a preset** (V1.x), and **theorycraft from scratch** (V2).

---

## 2. The problem it solves

The Map tab was the least-resolved of the four tabs. Diagnosis from the design conversation: Play and Learn draw strength from rich content, imagery, and forward desire (deck art, media covers, a library to browse). The Map cannot and should not fake that — a relationship is not a content library, and faking abundance breaks the humility line. The Map's authentic strength is **aliveness and intimacy**: it is the only tab that is about *them*. But its centerpieces (a thin Pulse graph, a list of matches) were rendered as utilities, not as the soul of the tab, and the tab read as a junk drawer of unrelated widgets.

Naming the Map as **the record**, with the Path as its spine, fixes this. It hands the tab one job, distinct from Play (*do*) and Learn (*understand*). The Map is where you *track us*.

---

## 3. Product principles and guardrails (non-negotiable)

This feature lives one inch from two of Vayl's brightest lines. The whole design is shaped to stay on the safe side of both. These are not optional polish; they are the reason the feature is allowed to exist.

### 3.1 Discovery, not assessment
> Vayl gives people maps, vocabulary, and mirrors, and lets them make the determinations. It never issues findings about a user.

- The Path is **a map of territory**, never a route Vayl commands. It shows landmarks; the couple chooses whether and when to walk them.
- Vayl never concludes a user's NM structure for them. **The couple picks their own starting path** (self-identification, a door to content), Vayl does not assess them into one. See §6.
- The clinical scaffolding in the source blueprint (mandatory protocols, audits, prescribed ordering) is **rewritten into warm, optional, non-clinical wayfinding voice**. See §8.2.

### 3.2 Humility, not engagement mechanics
> No streaks, no engagement-maximizing mechanics. Vayl is a small, optional corner of a user's life. The relationship happens off-app.

- The Path is **a territory map, not a progress bar.** The future is dim open road, never "you're behind." No completion percentage, no XP, no streaks, no nudges to advance.
- Marking a node is **looking back warmly**, not scoring. A new couple sees a few warm landmarks and open territory ahead, which is honest and inviting, not an empty meter.
- **Capacity frames everything** (§5.6). A Map read through capacity can never become a "advance!" game, because it always says "move when you're resourced," the opposite of a streak. Capacity is the guardrail that makes the path safe to build at all.

### 3.3 The voice line
The source blueprint is clinically framed and, for some variants (e.g. cuckolding's "Interview / humiliation debrief," STI protocols), explicit and intense. Every label and blurb gets a warm, non-judgmental, non-clinical pass before it ships. This is real content work, scoped in §8.2.

### 3.4 Earned celebration, not engagement bait
Marking a node should *feel* rewarding, and that is allowed, but only the on-principle kind. **Keep:** the earned-celebration animation (the glowing line draws to the next node, honoring a real-world act they had to leave the house to do); self-pacing (sit on a node for weeks, no "you're behind"); and optionally a quiet, private acknowledgment of the journey. **Drop, banned by humility:** streaks, XP, leaderboards, badge-grinding, completion meters, and especially the "open the app to see how close you are to the next milestone" retention hook (an open-to-find-out engagement bait). If achievements exist at all, they read as acknowledgment of a real journey, never a score. This is the line between expert guide and cheap mobile game, and it is the same line Vayl draws everywhere else.

---

## 4. The Map tab as the container

The Path does not live alone; it reorganizes the Map tab around the record identity. The Map already has the Me/Us lens built (`MapStore.Layer { me, us }`, the name-as-toggle masthead: `Jordan.` lit with `& Alex` faded in Me, `Jordan & Alex.` both lit in Us, period travels). The feature keeps that masthead exactly and fills the layers.

**Vertical structure (both lenses):**
1. **Masthead** — the Me/Us name toggle (existing).
2. **Pulse** — the hero/frame. Capacity. Lens-aware: your arc in Me, both arcs crossing in Us (§5.6).
3. **The Path** — the largest content on the tab, read in the light of capacity.
4. **The Vault** — the kept things, lens-sorted: the journal in Me; agreements in Us; and the Desire Map's two readings (your private summary in Me, where you align in Us). The Path (item 3 above) is a separate, larger element, **not** inside the Vault; the Desire alignment is a snapshot, the Path is the journey.

**The Me/Us lens applied to the Path:** the Path is fundamentally an **Us artifact with Me lanes.** One shared journey; the `O/O` forks are where your lane and your partner's read individually. Your *progress* is the Me reading; the *shared journey* is the Us reading. It is not duplicated as two separate roadmaps.

The hero question is settled: **capacity-framed Pulse sits at the top as the frame; the Path is the biggest content beneath it, read through that frame.** Capacity is the lens, the Path is what you read through it.

---

## 5. The Path

### 5.1 What it is
A vertical, branching map of landmarks for a chosen NM structure. It extends the visual language already built in `GettingStartedPathView` / `GettingStarted.swift` (a spectrum rail with state-styled circular nodes), but rendered as a **flowing serpentine trail with two-pass glow** (see `docs/prototypes/map-roadmap-path-v2.html`), not a rigid straight rail. The branching *is* the couple logic.

**Nodes are real-life EVENTS, not conversations or in-app tasks.** A node is a physical experience or threshold the couple crosses in the world (a lifestyle club night, a date with another couple, a soft swap), self-reported when actually done. The app is the **prep room and the debrief room**, never the journey itself: conversations, decks, and journaling are the *toolkit around* a node, never the node. This is the speed limit that prevents the number-one NM failure (skipping steps, e.g. doing a full swap on the first night out), and it is what keeps Vayl a companion to a real-world life rather than a workbook that demands screen time.

### 5.2 Topology (the keystone)
Three node/segment types, taken from the source blueprint's `(O) / (OO) / (O/O)` legend. This is the two-device couple model rendered as a path that physically splits and merges, and it is the same Me/Us weave as the lens, unrolled over time.

- **Synced `(O)`** — a single node on the center rail. A shared beat the couple moves through together. One progress state for the couple.
- **Dual-verify `(OO)`** — the rail pinches into two adjacent dots; **both partners must individually confirm** before the path continues, then it merges. A both-agree gate, drawn as a pinch, never a checkbox. Progress is per-partner until both confirm.
- **Individual `(O/O)`** — the rail forks into two parallel lanes (you / partner) for a stretch of nodes; **each lane advances at its own pace** and the lanes are allowed to be uneven (one partner ahead is fine, not a race), then merges at the next gate. Progress is per-partner-per-node within the lane.

### 5.3 Node states
Reuse the existing path-node visual states, extended:
- **done** — spectrum-filled node (matches `GettingStarted` `.done`).
- **now** — cyan glow ring ("you are here"; matches `.active`). There can be more than one "now" across forked lanes.
- **future** — dim subtle outline (matches `.upcoming`). This is **open territory**, not "locked."

Crucially there is **no `locked` state in the user's mental model.** A future node a couple has not reached is dim and inviting, not barred. (The model may still gate dual-verify continuation internally, but it is never presented as "you can't.")

### 5.4 Territory-map behavior
- **The whole path is visible from the start.** It is a map you can see the end of, which is what makes the road clear instead of unclear. This is the decided framing (territory, not a one-at-a-time compass).
- **Self-paced.** Mark a node when it happens; skip nodes that do not apply; hide nodes that are not for you.
- **No progress meter.** No percentage, no "X of Y," no streak.

### 5.5 The node detail is a Mission Brief
Tapping a node opens a half-sheet (`.vaylSheet`) structured as a mission brief, not a checklist row:
- **The Event** — the specific real-life outing/experience, in warm plain language.
- **The Golden Rule** — the *one* hard boundary the couple commits to for *this* outing (e.g. "You leave together; no playroom with anyone else"). Singular, memorable, safety-forward without being preachy.
- **The implicit toolkit** — *"things that might help,"* never required: a pre-game deck to review (loads the relevant prompts in Play), the Agreements Vault, and the post-game journal/Pulse to debrief. Implicitly linked, never a forced in-app task.
- **The mark** — "We're here now" / "I'm here now" (lane) / "I'm ready" (dual-verify, awaiting partner); secondary "Not yet."

Marking a node is the **same gesture** that offers the post-game journal entry (§7), and it triggers the **earned-celebration** animation: the glowing line draws forward to the next node, honoring a real-world act (they left the house and faced their nerves). This is celebration, not a grind reward. See §3.4.

### 5.6 Capacity framing (ambient, decided)
Pulse (capacity) sets the weather at the top of the Map. Its connection to the Path is **ambient, not active**: capacity informs how the couple reads their readiness to take a step, but it does **not** hard-gate or dim path nodes. Vayl does not say "we won't let you advance" — that tips back toward Vayl-as-authority. In the Us lens, both capacity arcs crossing are exactly the honest read before a shared step ("are we *both* in a place for this"). The couple draws the connection themselves.

(Active gating — softening the next-step affordance when capacity is low — is explicitly **rejected** for now. Revisit only if real use shows couples pushing past depletion.)

---

## 6. Path selection without an assessment engine

The preset paths are keyed on **NM structure** (open / poly / swinging / monogamish, plus swinging's hotwifing / cuckolding variants). That signal does **not** exist in the data model. The existing `Flavor` enum is the identity typology (explorer/anchor/catalyst/architect) tied to the shelved Me Card, and the SCT-grounded orientation engine that could derive structure is parked.

**Decision: the couple picks their own starting path.** When they begin the Path, they choose from the structures in their own words ("Which of these maps where you're heading?"), with each option a plain description, plus **"Build your own."** This is not a dodge of missing tech; it is the most on-principle answer:
- It is **self-identification, a door to content**, never Vayl assessing or concluding a structure about them (§3.1).
- It dovetails with the agency ladder (§9): picking a preset and building your own are the same gesture at different depths.

The chosen structure is stored as a new `PathTemplate` value on the couple (not on `UserProfile.flavor`, which is the identity axis). It is decoupled from both the identity `Flavor` and the parked orientation engine. If an orientation/flavor-of-NM signal is ever built, it can *suggest* a default selection, but the couple's pick always wins.

---

## 7. The journal loop (the Vault)

The Vault's journal is the **lived record of walking the path** and the third face of the record. It extends the existing `VaultLogSection` (per-entry private/shared marker, mood, tags).

- **Entry kinds:** a **date** (something that happened), a **feeling** (a new emotion they want out of their head), something they are **scared** about. (These map onto and extend the existing milestone event vocabulary: date / play / metamour / milestone / hardConvo / reconnection.)
- **Private to you (Me layer).** The journal is the clearest "only you see this" surface. It never syncs to the partner.
- **The loop:** marking a path node ("we're here now") is the same tap that offers "how did it feel?", which writes an entry optionally linked to that node. Entries can also be written free-standing (no node). The path is the territory; the journal is the record of having walked it.

---

## 8. Preset content

### 8.1 The four templates
Content is authored from the source blueprint (the four roadmaps: Swinging incl. hotwifing/cuckolding variants, Open Relationship, Polyamory, Monogamish), each as an ordered list of nodes carrying a topology marker.

**Build order (one flavor first, per the build protocol):**
1. **Swinging first.** The content is ready and the topology is the *simplest*: per the blueprint Swinging is almost all synced single nodes `(O)`, with one fork at the very end (the solo date `O/O`) and a couple of small branches (strip-club no-lapdance to lapdance; the optional legal sex worker). Shipping the synced path + phases + branches on Swinging proves the core render without the hardest topology.
2. Then **Polyamory / Open** in V1.x, which add the heavy fork + dual-verify rendering.
3. Then **Monogamish**.

**The Swinging path groups into 5 phases (Worlds), ~13 nodes.** Phases keep a long path from overwhelming: the Map renders a **window** (last done node, current node, next node) under its phase header, with the full path one scroll/tap deeper. Each node is a real-life event (§5.1) with a Mission Brief (§5.5).
- **Phase 1, Safe Harbor** (internal, no physical risk): fantasy / dirty talk about a third; watching X-rated content together with intention; virtual interactions (messaging a couple or third with real intent).
- **Phase 2, Proximal Energy** (out, no contact): the strip club (branch: no lap dance, then with lap dance); flirting at a vanilla bar / social; an NM social mixer, no play. *Optional branch: a legal sex worker.*
- **Phase 3, Threshold** (lifestyle spaces): show up to a lifestyle club / party, observe only; exhibitionism (physical as a couple, only being watched).
- **Phase 4, Engagement** (direct): a date with another couple (drinks / dinner, no play); parallel play (same room, own partner); soft swap; full swap.
- **Phase 5, Advanced Frontier**: the solo date (one partner plays independently, the `O/O` fork).

Each node carries a single **Golden Rule** (its one hard boundary) and implicit pre/post toolkit links, authored alongside the warm-voice pass.

### 8.2 The voice pass (required, real work)
Every node label and blurb is rewritten from the clinical source into Vayl's warm, non-clinical, non-judgmental voice, and audited for the no-em-dashes rule and the OB-voice "address one person" conventions where applicable. Examples of the shift:
- "Drafting the Guardrails (mandatory safety protocol)" → "Your shared guardrails."
- "The Reconnection Debrief (both partners must verify a structured, non-defensive debrief)" → "Come back together."
- "The Six-Month Vibe Check (mandatory, dual-verified sit-down)" → "Check in on the whole thing."

The intense variant content (cuckolding's Interview/humiliation beats, explicit power-dynamic debriefs, STI logistics) needs the most careful, sex-positive, non-judgmental framing and should be drafted and reviewed deliberately, not bulk-generated.

---

## 9. The agency ladder (preset → customize → theorycraft)

This is what makes the feature unimpeachable on the assessment line: Vayl provides the **vocabulary** (node types, the synced / dual-verify / individual topology) and a **starting template**, and the couple makes the determination.

- **Rung 1 — Preset (V1).** The chosen structure's recommended path, self-paced; mark / skip / hide nodes.
- **Rung 2 — Customize a preset (V1.x).** Start from the recommended path and adapt it: add your own landmarks, remove ones that do not apply, reorder. The template as clay.
- **Rung 3 — Theorycraft from scratch (V2).** A blank canvas plus the node vocabulary; set each node's topology. UX rule baked into the order: **start-from-template beats blank-canvas** — even "custom" should usually mean "fork the preset and edit," not an empty grid.

---

## 10. Architecture (4-layer)

Follows the project's View → Store → Service → Model rules. Names are proposals for the plan to refine.

### 10.1 Models (pure data, no SwiftUI)
- `PathTemplate` — enum of NM structures (`open, poly, swinging, monogamish`) with a variant axis for swinging (`standard, hotwifing, cuckolding`). Decoupled from `Flavor`.
- `PathTopology` — `synced, dualVerify, individual`.
- `PathNode` — id, title, blurb, topology, lane (for forks), `Codable`.
- `PathNodeProgress` — per-couple for synced; per-partner for dualVerify and individual.
- `RoadmapPath` — ordered nodes + template metadata; a derived view-model analogous to `GettingStarted` but, unlike it, **progress is stored, not derived.**
- Preset content lives as data (a Swift resource or JSON), one definition per template+variant.

### 10.2 Store
- `PathStore` (`@Observable @MainActor`) — owns the couple's selected template, the resolved path, node progress, the mark/confirm actions, and (later) custom-path edits. Calls `PathService`. Publishes to the Map views. Reads capacity from `PulseStore` only to *display* the frame, never to gate.
- Integrates under the existing `MapStore` lens (`layer`), or as a sibling store the Map view composes.

### 10.3 Service
- `PathService` — loads preset content, persists progress and custom paths, and syncs **dual-verify confirmations** and **per-lane progress** between partners via Supabase (RLS-gated, mirroring `PulseSyncService`'s fire-and-forget + local-source-of-truth pattern). No reference to stores or views.

### 10.4 Views
- The path renderer: a **flowing serpentine trail with two-pass glow** (per `map-roadmap-path-v2.html`), single nodes, dual-verify gates as pinches, fork lanes that weave. Done-node medallion fill follows `OrbitIndicator.swift`'s `.complete` state: a `LinearGradient` fill (accentPrimary / secondary / tertiary) plus a stacked three-shadow spectrum glow (accentPrimary r5, accentTertiary r11, accentSecondary@0.13 r18). "Now" nodes use a pulsing spectrum ring; future nodes a dim outline.
- A phase-window summary (last done / now / next under a phase header) for the Map's default view, expanding to the full path.
- The node detail sheet (`.vaylSheet`).
- The template picker (`.vaylSheet`).
- The journal entry composer (extends the Vault log).
- The custom-path editor (V1.x / V2).
- Map-tab integration: capacity-framed Pulse on top, Path below, Vault journal in the Me layer.

### 10.5 Backend (Supabase, project `ynhjlabjzauamntbyxdp`)
New tables (names for the plan):
- couple path selection + (optional) custom path definition.
- per-couple node progress for synced nodes.
- per-user node confirmations (dual-verify) and per-user lane progress (forks), RLS-scoped to the owner, partner visibility gated like capacity sharing.
- journal entries (extend or mirror the Vault log), **owner-only RLS, never partner-visible.**

Dual-verify is genuine two-device sync work: a node continues only when both partners' confirmation rows exist.

---

## 11. Data and privacy

- **Journal:** owner-only, never synced to the partner. The most private surface in the Map.
- **Capacity (Pulse):** already synced under the existing `shareCapacity` setting + RLS; the Path only reads it to render the frame.
- **Path progress:** shared within the couple (it is a shared journey), with dual-verify confirmations and lane progress visible to both partners so the gates and forks render honestly. Subject to the same partner-vs-partner RLS discipline as the rest of the app (server-authoritative, online-first).
- **Custom path definitions:** shared within the couple.
- No raw partner *journal* content ever crosses; the path shares *state* (where each is on the map), not private reflections.

---

## 12. Scope and segmentation

Per the build protocol: named segments, each with one job and a device-verified "feel" done-condition (not just "build succeeds").

**V1 — the record spine + one preset path**
- Map-tab restructure: capacity-framed Pulse on top, Path below, Vault journal in Me.
- The Path renderer with all three topologies, node states (done/now/future), territory behavior, self-paced marking.
- Preset content for **Swinging only** (simplest topology, content ready), warm-voiced, grouped into its 5 phases.
- Template picker (self-pick, incl. "build your own" stub).
- The path↔journal loop (mark a node → entry) and the Vault journal (date/feeling/scared).
- Backend: template selection, node progress, dual-verify sync, journal entries.

**V1.x — full content + customize**
- Remaining presets (Poly, Monogamish, Swinging + variants) with the full voice pass.
- Customize-a-preset (add / remove / reorder nodes).

**V2 — theorycraft**
- Custom path editor from scratch (fork-the-preset first; blank canvas second).

Each preset/topology beat is verified for *feel* on device before the next begins. Timing of the path draw, the pinch/merge of dual-verify, and the fork are prototyped in the existing HTML reference and confirmed before Swift.

---

## 13. Dependencies and open questions

- **Alignment Map vs Desire Map (sets scope, decide first):** is "are we aligned and ready" already answered by the **Desire Map** (it shows where you meet and where there is distance), making the Alignment Map a light front-door compass, or is the Alignment Map the parked Orientation / `Curiosity Compass` engine finally getting built? This decides whether the assessment side is one new feature or none. The Alignment Map is specced separately either way (§0).
- **NM-structure signal:** resolved for V1 by self-pick (§6). A real orientation/flavor-of-NM engine remains parked; if built, it only *suggests*.
- **Voice pass:** required content workstream (§8.2); the intense variants need deliberate, reviewed drafting.
- **Capacity ↔ path:** ambient, decided (§5.6). Active gating rejected for now.
- **Hero placement:** capacity-framed Pulse top, Path below, decided (§4).
- **Play cross-links** (node → relevant deck): deferred polish, not V1-blocking.
- **Pulse capacity arc realness:** Pulse currently persists locally + syncs capacity; the "both arcs crossing" Us visual and the 7-day arc need the partner-capacity read wired (overlaps existing Pulse sync work).
- **Where exactly the Path sits relative to the Desire Map's "where you align"** (both are Map content): both live on the Map; the Path is the journey, the desire alignment is the snapshot. Confirm they coexist without crowding when the Map top is built.

---

## 14. Non-goals (out of scope)

- Not in Play. The Path is tracking, not an activity (the milestones happen off-app).
- No gamification: no streaks, XP, completion meter, leaderboards, or advance-nudges.
- No assessment: Vayl never concludes a user's structure, traits, or readiness.
- No active capacity gating in V1.
- No partner-visible journal.
- The Me Card / identity `Flavor` work stays shelved and separate.
