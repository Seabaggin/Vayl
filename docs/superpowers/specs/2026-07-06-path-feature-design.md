# The Path Feature — Design

**Date:** 2026-07-06
**Status:** Draft from design session (Bryan + Claude) — covers everything except the
Map dashboard entry-point widget, which is deliberately excluded (see §0).
**Prototypes:** `docs/prototypes/map-roadmap-*.html`, `map-path-me-us.html`,
`map-path-zoom.html`, `path-family-set-a-trail-everywhere.html`,
`path-family-set-b-the-ledger.html`, `path-full-flow.html`,
`partner-pill-session-invite.html`.
**Prior context:** `docs/superpowers/specs/2026-07-05-map-tab-dashboard-design.md`
(the Map dashboard this pillar lives inside; Path was deferred there, now being
speced on its own).

---

## 0. Explicitly out of scope for this doc

**The Map dashboard's Path widget — the collapsed card a user sees and taps *before*
opening the feature — is NOT specced here.** Bryan is reconsidering the container
(possibly not the `pathfs` full-bleed-trail-slice card shown in the family mockups).
Every screen in this doc is what exists *after* that tap. When the widget is
settled, it gets its own short addendum; nothing below depends on its shape beyond
"tapping it opens the trail."

## 1. Launch scope

- **One style at launch: Swinging**, fully authored (13 landmarks, 5 phases — see
  `map-roadmap-swinging.html`, the geometric/content ground truth for the trail).
- **All other styles ship locked**, visible in the path picker (§4) as a name + one-line
  teaser + a lock, no landmark content shown (no spoiler preview of locked content).
- **Two additional relationship *shapes* are architected for, not authored, at launch:**
  Solo/Third (a person exploring joining existing couples, self-attested, no partner)
  and Active/Support (hotwife/hothusband — one partner active on the path, one
  supporting). Both need the data model to support them (§7 `role`) so post-launch is
  "add content + assign a role," not "redesign the model." Neither ships with real
  landmark content at launch.
- This scope call exists to bound content-authoring risk — see the brainstorming
  session's discussion of why Path was nearly cut from launch entirely, then reinstated
  specifically because the Me/Us lens needed a second pillar to justify itself before
  Act 2. Locking non-Swinging styles is what keeps that reinstatement cheap.

## 2. The trail — geometry and content

The full trail is a literal, coordinate-for-coordinate port of `map-roadmap-swinging.html`'s
SVG — the 360×1140 stage, the AHEAD (dashed, dim) and TRAVELED (bright, glow+crisp,
two-pass) bezier paths, the terminal fork (the one branch point, where a solo night
splits off), node sizes (`done` 18×18 three-layer glow, `now` 23×23 with a pulsing ring,
`future` 13×13), the five phase-divider offsets, and all 13 landmark labels/copy. This
geometry is **not to be redrawn or approximated** — every implementation of the trail
(dashboard preview excepted, per §0) scales this exact path data, never re-derives it.

**Deliberately absent, permanently:** a progress bar, a "4 of 13" counter, any
percentage-complete meter. Wayfinding is the trail itself (phase names, "at your own
pace" copy); a completion score is the gamification the product principles ban.

### 2.1 Two readings of the same data

- **Spatial (primary)** — the trail as described above.
- **Ledger (list)** — the same landmarks as a scrollable phase-grouped list (icon dot +
  title + state caption per row). Reached via a **☰ toggle in the trail's own header**
  (top-right; top-left is `‹ Map`, a real back action, not part of the excluded widget).
  Toggling **preserves scroll position** — landing on the same landmark you were looking
  at, not resetting to the top. This exists because the spatial trail is ~950pt tall;
  orienting via 13 landmarks of scrolling every visit is real friction the list view
  solves for a "let me just scan this" moment. Spatial stays the default on every fresh
  open — list is a utility view, never a home.

## 3. Node states

Five states, five different visual and semantic meanings — the last two are new
relative to the original reference and were added specifically to answer "we already go
to strip clubs for fun, that's not a milestone for us, but it should stay editable, not
hidden":

| State | Meaning | Rendering | Dated? |
|---|---|---|---|
| **Walked** | Done via Vayl, through this path | Solid gradient node | Yes — "3 wks ago" |
| **Already ours** | True for the couple before/outside Vayl — no ceremony needed | Teal diamond-ring node | No — nothing to date |
| **Now** | The current step | Glowing node, pulsing ring | — |
| **Future** | Ahead, untouched | Dim outline node | — |
| **Skipped** | Explicitly not for this couple | **Removed from the default trail entirely** (see §3.2) | — |

### 3.1 Already ours requires mutual confirmation

Established for "We did this" earlier in this project (progress in Us is never
unilateral — one partner can't declare "we walked past X" alone) and **the same rule
applies to Already ours**, because it is also a progress claim ("this landmark is
complete/true for us"). One partner marking a landmark already-ours creates a
**pending-confirmation** sub-state — visible to the proposing partner as "waiting on
[partner]" and to the other partner as something to confirm or decline. **This UI was
never mocked in the design session and needs its own pass before implementation** — the
closest existing precedent is the partner-invite pattern (§8), but a landmark-level
confirmation is a different shape (per-node, not per-session) and should not be assumed
identical without a design pass.

### 3.2 Skip is a real removal, with a recovery path

Tapping Skip — not for us takes the landmark **off the default trail view**, not a
permanently-visible struck-through ghost. A toast confirms: *"Removed from your path.
Undo or find it later in Edit your path."* This is the ONE place removed landmarks live
in full: **Edit your path** (§3.3) is reached from the toast's link or from the list
view's own overflow.

### 3.3 Edit your path

A dedicated screen: every landmark in the style, including anything skipped, each with
a toggle to bring it back on. Restoring a landmark returns it to its original phase
position (the trail's shape is stable; only membership toggles). A "+ Add your own
landmark" entry point exists here but **has no design beyond the entry row** — free text
vs. a phase picker vs. a lighter Mission-Brief-style form is unresolved; treat as
post-launch unless prioritized.

## 4. The path picker (selection + swap)

One screen, doubling as both first-choice and later-switch:

- **Active path**: full color, shown as the dashboard entry (excluded per §0, but its
  *state* — which path is active — is owned here).
- **Locked paths**: dim, name + one-line teaser, no landmark content visible, a
  "notify me" affordance. No preview of locked content — that's the whole point of
  locking it.
- **Paused/archived paths**: a couple can switch active paths. Switching **archives, it
  never deletes** — the old path's walked/already-ours/skipped state stays intact,
  visible as a dimmed "paused" entry with its record preserved, consistent with "Map =
  record" as an identity this whole tab is built around. Only one path is active on the
  dashboard at a time.

## 5. NodeView — the Mission Brief

Tapping a node opens the **exact Mission Brief from the reference, unmodified**: The
Event, The Golden Rule, three tool links (deck / Agreements / journal), "We did this" /
"Not yet." This is the emotional core of the feature and nothing here changes.

**The only addition: a small ⋯ in the header**, opening a three-option menu — Edit this
step / Mark already ours / Skip — not for us. These three management actions were
originally designed as a competing, simpler sheet; that was a mistake corrected during
the design session — they belong folded into the real Brief, tucked out of the way of
the emotional content, never replacing it.

### 5.1 Solo framing (same screen, different content — not a different screen)

- No golden rule ("about the two of you" doesn't apply to one person).
- "Where you stand" replaces The Event: the four private stance flags (Into it /
  Curious / Let's talk first / Not yet) — self-chosen, never computed, never shown to a
  future partner unless the user chooses to share it later.
- Primary action is **"I did this"** (self-attested — no partner to confirm with) /
  "Not yet."
- Tools collapse to one link: **Journal about this** (→ `EventEntryEditor`/
  `VaultLogSection`, tagged to this landmark). Deck and Agreements links are dropped —
  nothing to check against without a partner.

### 5.2 Couple framing

- Golden Rule stays.
- Tools keep all three links: deck, Agreements, journal.
- Primary action is **"We did this"** (requires mutual presence via the session/Airlock
  gate, not this screen's concern — see §8) / "Not yet."
- **New: "Add a discussion card"** — see §6. This is the couple's equivalent of solo's
  journal link: where the couple processes a landmark together rather than each
  privately.

### 5.3 Active/Support framing (hotwife/hothusband — architecture only, no content at launch)

- **Active** partner gets the full couple Brief (event, golden rule, tools, actions) —
  they're the one walking the landmark.
- **Support** partner gets a **read-only** version of the trail (no kebab menu, no
  actions) plus their own entry point: **journal about how you're feeling**, tagged to
  the same landmark. Support cannot mark walked/already-ours/skip — only Active
  controls the map.
- **Us tab** (the couple-level lens, separate from either individual's Path view) reads
  "how are you both doing in your roles" — reuses the Map dashboard's existing Us-lens
  pattern (comparing two points, per the app's discovery-not-assessment rule), not new
  architecture.
- **The conversation-prompt mechanic**: once both Active's landmark entry and Support's
  journal entry exist for the same landmark, a compare-two-points prompt surfaces for
  both — *"You both wrote about this — want to talk?"* with a snippet from each side and
  a "start the conversation" action. This is what keeps Support from being a spectator
  screen. **Mechanism: reuses §6's quick-session/discussion-card path** (a
  landmark-tagged card, queued once both entries exist), not a bespoke chat UI.

## 6. Discussion cards — Path × Sessions

Rather than inventing a new "conversation" UI, a landmark's "talk about this" moment is
a **real Vayl session card**, reusing infrastructure that already exists:

- **`ThePathSwingingDeck`** — a real `Deck` (fits the existing `DeckCategory.styleSpecific`
  category, no new category needed), containing a pool of landmark-tagged discussion
  cards. Tagging an individual card to a landmark needs a new per-card field (`Deck.tags`
  is deck-level only — verify `Card`'s schema has room before assuming this is free).
- **Two ways to engage a landmark's card, both offered from NodeView:**
  1. **Add to queue** (default, low-friction): silently adds the card to the couple's
     pending set for `ThePathSwingingDeck`, confirmed with a toast — no session starts.
     Next time the couple opens that deck normally (via Play), the queued card(s) are
     pre-selected in the `SessionBuilder`'s trim/restore flow (`SessionBuilderStore`
     already supports exactly this operation — select/deselect a subset of a deck's
     cards — it just needs to be pre-seeded from persisted queue state, which does not
     exist yet and is new).
  2. **Quick play now** — see §6.1.
- **The persisted queue is new state.** `SessionBuilderStore.persistAsLast` only
  remembers the *last started* plan (for "same as last time" convenience) — it does not
  accumulate cards queued across multiple separate Path visits before anyone plays
  anything. A small new persisted structure (queued card ids per couple per deck) is
  required.

### 6.1 Quick play — the one-card exception

`SessionBuilderStore.minimumCards = 3` blocks a single card from becoming its own
session today — a deliberate floor, protecting the closing-ritual structure of a normal
sitting. Quick play is a **named, bounded exception**, not a change to that floor:

- **Launches directly from Map** (or wherever NodeView lives) — no detour through Play
  or the SessionBuilder, since there's nothing to build with one card.
- **Routes to a new `QuickSessionView`**, not `CardSessionContainerView`. Routing
  conditional: extend `SessionLaunch` (which already has an `entry: Entry` case —
  `.initiator/.joiner/.localDebug` — the exact mechanism for "how did this session
  start") with a Map-originated case or sibling `origin` field, and the presentation
  layer checks it.
- **Still genuinely gated** — reuses the real presence signal `AirlockStore` already
  runs in production (Supabase presence channel + poll-mode fallback), not a shortcut.
  What it skips is ceremony, not the gate itself:
  ```
  waitingForPartner → bothPresent → active
  ```
  (vs. the full `waitingForPartner → bothPresent → consented → activating → active`).
  No lock-in ring, no bandwidth mirror, no breathing ritual — once both are present, the
  card shows directly.
- **Copy while waiting**: the same honest, named pattern the real Airlock already uses —
  *"Waiting for [partner's name] to arrive…"* — not a generic error, not silence.
- **Open architecture question, unresolved:** does `QuickSessionView` reuse
  `AirlockStore` itself (short-circuiting past `consented`/`activating`), or a smaller
  dedicated presence-only store? Reusing `AirlockStore` keeps one source of truth for
  partner-presence detection; a dedicated store avoids teaching a currently
  single-purpose state machine two modes. **Decide before implementation starts** —
  this affects the shape of both the store and its tests.

## 7. Data model (net-new)

Nothing below exists today; each needs to be designed to the level the Map dashboard
build was (SwiftData model + Supabase table/RLS + sync service), not assumed trivial:

1. **`PathStyle` content** — JSON-authored (matching the `Deck`/`DeckCatalogService`
   pattern), landmarks grouped into ordered phases, per style. Swinging's 13/5 split is
   the only fully authored instance at launch.
2. **Per-couple landmark progress** — state (walked/already-ours/now/future/skipped),
   who set it, when, and the pending-confirmation sub-state from §3.1. This is the real
   center of the feature.
3. **Private per-user stance + note** — the Me-lens layer (§5.1's "where you stand"),
   never synced to partner, never inferred, only what the user explicitly set.
4. **A `role` concept, independent of `style`** — symmetric / solo / active-support.
   Architected now even though only symmetric ships content, so post-launch additions
   don't require a data-model migration.
5. **Card→landmark tagging** on `ThePathSwingingDeck`'s cards (§6).
6. **Queued-card persistence** per couple per deck (§6).

## 8. The partner-pill invite (session-agnostic — serves both normal sessions and quick play)

Replaces `PendingSessionBanner` (and its two render sites, `HomeRouterView` and
`PlayView`) entirely — **not additive, a removal**.

- **Trigger**: unchanged from today's real mechanism —
  `PlayStore.builderDidFinish(_:)` → `realtime.openSession(...)` for a normal session;
  the quick-play tap itself for §6.1 (no builder step to confirm). Both produce the same
  kind of `lobby`-status row `SessionEntryStore.fetchOpenSession` already polls for.
- **`PartnerChipState` is unchanged** (`none/invitePending/nudge/active/multipleActive`
  — pairing status only). A pending invite is orthogonal state
  (`SessionEntryStore.pendingSession`), threaded into `PartnerChip`/`PartnerChipExpand`
  as a separate signal, not a new case in that enum.
- **The pill**: at rest, unchanged (today's real `.active` glass capsule). Pending: one
  soft blurred spectrum-gradient glow behind the pill, screen-blended, breathing
  opacity — reusing `AppGlows.spectrumBorder`'s existing colour language (cyan/purple/
  magenta), not a new red/urgent accent, and not layered box-shadow rings (renders as
  hard edges, not a smooth halo).
- **The popover** (`PartnerChipExpand`): the invite is a new **first row**, generic copy
  only — **"[Name] wants to start a session"**, no deck/landmark title, no preview
  (details live in the session itself, once joined — sessions never spoil their cards
  before they start, this is consistent with that). Icon is a small fanned-deck symbol
  (`VaylDeckStack`'s real offset-stack style — small diagonal offset per card, not a wide
  rotated fan — ported at icon scale, using the real `VaylCardBack` look, not a flat
  rectangle). Text renders via `LivingText`, **animated** — the opposite choice from
  Home's static "VAYL." wordmark, deliberately: that precedent avoids animation for
  *identity* text specifically; this is transient notification text, which is what
  animated Living Text is for. Everything else already in the popover (Desire Map
  status, Manage pairing, the Pulse quick-view) is unchanged, just pushed down one row
  while an invite is pending.
- **Rationale for pill-over-banner**: two-device sessions already assume co-presence —
  the whole premise of the lock-in ring is "you're both here, choosing this
  together" — so a banner interrupting each person's own screen separately makes less
  sense than one shared, glanceable spot both partners would naturally check sitting
  next to each other.

## 9. Open items requiring a decision before implementation

1. **Already-ours mutual-confirmation UI** (§3.1) — no design exists yet.
2. **Add-your-own-landmark** (§3.3) — no design beyond the entry row; recommend
   deferring past launch unless prioritized.
3. **`QuickSessionView`'s store** (§6.1) — reuse `AirlockStore` vs. a dedicated
   presence-only store.
4. **Map dashboard widget** (§0) — deliberately excluded from this doc; Bryan is
   reconsidering the container.

## 10. Explicitly rejected during design

- **Zoom-as-lens** (Me zoomed in/forward, Us zoomed out/retrospective —
  `map-path-zoom.html`) as the Me/Us differentiator. Superseded by the **annotation
  layer** (§5.1/5.2: identical trail geometry, private stance + notes overlaid for Me,
  clean shared trail for Us) — the annotation approach is what every later, more
  definitive mockup (`map-path-me-us.html` onward, `path-full-flow.html`) actually
  implements. Zoom-as-lens is preserved in the prototypes folder as a rejected
  alternative, not a parallel option still on the table.
- **A separate invented NodeView editor sheet**, competing with the real Mission Brief.
  Corrected to the ⋯-menu-inside-the-real-Brief pattern (§5).
- **A permanently-visible struck-through "skipped" node.** Corrected to real removal +
  Edit-your-path as the recovery surface (§3.2/3.3).
- **A bespoke chat-bubble conversation widget** for Active/Support. Corrected to reusing
  the discussion-card/session mechanism (§5.3, §6) — no new UI paradigm.
