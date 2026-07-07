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

**A named tension, resolved on purpose, not by omission:** an experienced couple can
mark several landmarks "already ours" in their first minutes on the trail, and the
trail visually fills in as a result — the same *feeling* a progress bar produces,
without the number. Adversarial review flagged this as worth acknowledging rather than
leaving as a blind spot. The call: **this is accepted, not gated.** Rate-limiting how
fast someone can mark a truthful self-report would itself be paternalistic — treating
the user's own account of their relationship as suspect — which is a worse violation of
the humility principle than the visual-fill tension it would be solving. The
distinction that keeps this from being the banned pattern: it is never expressed as a
fraction, a percent, or a count against a total. A dense trail reads as "you've lived a
lot of this already," which is true; it never reads as "8/13."

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

**Lifecycle rules (added after adversarial review — these were previously undefined and
would have been improvised badly at implementation time):**
- **Decline reverts to Future, silently.** No message back to the proposer beyond the
  pending state simply clearing — no "[partner] didn't confirm this one." A visible
  decline-notice reads as pressure/guilt on a relationship claim, which the humility
  principle rules out; a silent revert costs the proposer a closure loop, and that's the
  correct trade here, not an oversight.
- **No expiry, no reminder, no badge decay.** Stated explicitly so a future contributor
  doesn't add a nudge mechanic to "help" this along — that would violate the
  no-engagement-maximizing-mechanics principle. A pending confirmation waits exactly as
  long as the couple takes, same as everything else on this trail.
- **Conflicting simultaneous writes** (Partner A sets already-ours while Partner B sets
  skip on the same landmark) do not silently last-write-wins. Any write that lands while
  a pending-confirmation already exists on that landmark surfaces to **both** partners
  rather than overwriting — consistent with "no unilateral progress claims" already
  established for We did this.
- **Unlink/deletion while a confirmation is pending**: see the new §3.4.

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

### 3.4 Unlink and account deletion

The parent Map dashboard spec's unlink behavior (§2.3: partner name leaves, lens snaps
to Me-only, reveal flag resets) is about identity/reveal state, not progress data — it
was never extended to Path, and adversarial review flagged this as a real gap, not a
minor one, since couple-scoped state that isn't explicitly re-keyed on unlink is a
data-leak risk between relationships, not just a UX rough edge. Extending it:

- **Per-couple landmark progress is couple-scoped and does not transfer.** If a couple
  unlinks and either partner later re-pairs with someone new, the new pairing starts a
  fresh trail — it never inherits the old couple's walked/already-ours/skipped state.
- **A pending already-ours confirmation orphaned by unlink or account deletion
  auto-resolves the same way a decline does** (§3.1) — reverts to Future, silently. This
  is the same class of bug `PlayStore`'s existing self-heal (abandoning a stale lobby
  the current user opened) already exists to prevent; a pending confirmation with no one
  left to confirm it needs the same discipline, not a new pattern.
- **Private per-user stance and note data (§5.1, §7 item 3) persists with the individual** —
  it's Me-layer, owned by the person, not the couple, so it survives an unlink exactly
  the way the rest of that person's account does. It is not carried into a future
  pairing automatically (see §9's open item on the solo→paired transition, which is a
  separate, deliberately undecided question from this one).

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
  journal entry exist for the same landmark, a compare-two-points prompt becomes
  *available* for both. **Corrected after adversarial review**: the original wording
  ("a snippet from each side" surfacing automatically) contradicted this same document's
  own rule two sections earlier — §5.1 states private content is "never shown... unless
  the user chooses to share it later." A journal entry is exactly that kind of private
  content, and auto-surfacing a snippet across the Active/Support boundary without an
  explicit share action is a sharper privacy move than the precedent this spec already
  committed to. The corrected flow: **each partner sees only that they have an entry for
  this landmark and that their partner does too** ("You both wrote about this"), with
  **no snippet, no content preview** — tapping in prompts each person to explicitly
  share their own entry (or not) before anything crosses the boundary, the same
  consent-to-share gate §5.1 already establishes for private stances. This is what keeps
  Support from being a spectator screen without quietly bypassing the app's own privacy
  rule to do it. **Mechanism: reuses §6's quick-session/discussion-card path** (a
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
- **Missing-card fallback, required, not optional.** Content authoring is unlikely to
  reach 1:1 landmark-to-card coverage at launch (13 landmarks, card count unspecified).
  "Add a discussion card" **must not silently no-op** when a landmark has no tagged
  card — that's the failure mode most likely to ship by default if unaddressed, per
  adversarial review. The entry point either hides itself entirely for an untagged
  landmark (preferred — a user never discovers an affordance that does nothing) or, if
  content coverage turns out patchy enough that hiding it reads as inconsistent
  landmark-to-landmark, falls back to a generic (untagged) prompt from the same deck.
  Decide which once real card-count/coverage is known; either is acceptable, silence is
  not.

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
- **Inherits the stale-lobby self-heal — required, not optional.** `PlayStore` already
  abandons a lobby/airlock row the current user opened and walked away from, before
  opening a fresh one (self-heal against bricking the one-open-session index). Quick
  play is, by its own design, the *more* impulsive and lower-friction entry point — no
  builder step, no detour through Play — which makes it plausibly **more** likely to be
  tapped in a moment of curiosity and abandoned mid-flow, not less. Adversarial review
  flagged that the spec cited the self-heal precedent without actually extending it to
  this new entry point; it applies here identically, not by inference.
- **Concurrent invites — one open pending session at a time.** If both partners tap
  quick-play on two different landmark cards at the same moment, the second attempt is
  blocked with a toast ("[Partner] just started a session — join theirs, or try again
  after"), not silently overwritten and not left for the single-slot `pendingSession`
  signal (§8) to arbitrarily pick one. This keeps the partner-pill invite's "one first
  row" design in §8 honest — it was built assuming exactly one pending session can exist
  at a time, and this rule is what makes that assumption true rather than accidental.

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

1. **Already-ours mutual-confirmation UI** (§3.1) — the lifecycle rules are now decided
   (decline/expiry/race-condition, §3.1); the actual confirm/decline screen itself still
   has no design.
2. **Add-your-own-landmark** (§3.3) — no design beyond the entry row; recommend
   deferring past launch unless prioritized.
3. **`QuickSessionView`'s store** (§6.1) — reuse `AirlockStore` vs. a dedicated
   presence-only store.
4. **Map dashboard widget** (§0) — deliberately excluded from this doc; Bryan is
   reconsidering the container.
5. **Solo → paired transition — genuinely open, needs Bryan's call, not a default to
   guess at.** If a solo/third user has set private stances on landmarks (§5.1), then
   later pairs and switches to a symmetric couple path, does any of that private
   pre-partner data ever surface — e.g., as a "your past private stance vs. your
   partner's current one" comparison, which would actually be a legitimate use under the
   discovery-not-assessment rule (comparing two points, not inferring anything) — or is
   it fully discarded on the role switch? The data model (§7 item 3, stance/note, and
   item 4, role) already makes either answer possible; the product behavior isn't
   decided, and adversarial review flagged that leaving it open risks it getting built
   accidentally (because the data happens to be there) rather than deliberately.
6. **Missing-card fallback exact behavior** (§6) — hide-the-entry-point vs.
   generic-card-fallback is named as the choice; which one depends on real content
   coverage numbers not yet known, so pick once Swinging's card set is actually
   authored, not before.

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
