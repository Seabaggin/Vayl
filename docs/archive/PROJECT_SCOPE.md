# Vayl — V1 Master Project Scope

> Single source of truth. Last updated 2026-07-05, after a full codebase
> re-audit (four parallel investigations across Home/Play/Map/Learn,
> Desire Map/Pulse/Sessions, Onboarding/Pairing/Settings, and
> Monetization). The previous version (2026-06-07) was badly stale —
> Play, Map, and Learn were documented as stubs but are fully built;
> StoreKit was documented as "not started" but is wired end to end;
> the Desire Map reveal design in the old doc (mutual-waiting state,
> 7-day escape hatch, nudge tool) was superseded by a simpler beat-ceremony
> reveal and no longer exists in code.
>
> Codebase governs over this document when they conflict.
> Update this document when the codebase changes intentionally.
>
> Note: the shorter `Vayl — V1 Scope.md` and any external copy of this file
> are stale relative to this version — re-sync them from here.

---

## What Vayl Is

Vayl is a private mutual discovery tool for couples navigating consensual
non-monogamy. It gives couples a structured way to have the conversations
they have been avoiding, surfaces what they actually agree on, and builds
a record of how their relationship evolves over time.

**It is not therapy. It is not a dating app. It is not a community platform.**

It is what you use when you want to have the conversation but do not know
how to start without it becoming an accusation.

**The one sentence:**
> The tool couples have been looking for since the first conversation
> they could not finish.

---

## V1 Scope Boundary

V1 is Act 1 only. A focused NM companion for couples — new and
experienced — who want to do the work together. It ships as a lifetime
purchase.

Act 2 introduces Vayl Pro — the Relationship OS. That is a different
product built on the same foundation. Nothing in this document scopes
Act 2 or Act 3 features.

**Primary V1 user:** Two people in a committed relationship, curious
about or actively practicing consensual non-monogamy, who want a
structured way to explore together.

**Solo user model:** Everyone starts unlinked. Onboarding is always
completed alone. The solo/unlinked state is not a separate product — it
is a universal starting state. Full features unlock when a partner links.
Solo experience in Act 2/3 (independent NM management, solo poly tools)
is a separate product released later. V1 does the coupled experience
exceptionally well.

---

## Product Philosophy

Vayl observes. The user interprets. This is non-negotiable.

The app tracks what people do (sessions completed, cards discussed,
decks started) and how they say they feel (pulse check-ins, reflections,
post-session notes). That data belongs to the user. What it means is
for the user to decide. The app never decides for them.

**Cards** ask questions. They do not frame the answer. Every card passes
the bar conversation test: a wise, well-read friend could say this over
a drink without it feeling clinical.

**Insights** are observations, never evaluations.
- Correct: "You logged high energy on Tuesdays more than any other day."
- Wrong: "Your relationship is healthiest on Tuesdays."

**Pulse and check-ins** record what the user reports feeling. The app
does not validate, challenge, or reframe that feeling.

**Reflections** are private. The app surfaces the user's own words.
It never interprets them.

**Language rules — everywhere in the product:**
- Never: "Your data suggests..." / "This pattern indicates..."
- Always: "You logged..." / "You noted..." / "You mentioned..."

> "We show you what you did and what you said you felt.
> What that means is yours to decide."

---

## User States

Everyone who uses Vayl V1 passes through two states in sequence.
There is no way to skip the first.

### State 1 — Unlinked (`soloUnpaired`)

Completed onboarding. No partner linked yet.

**Available in State 1:**
- Desire Map — complete their own side privately
- Learn tab — full, no gate
- Pulse — unlimited logging
- Getting Started path on Home (deck sampling, first-session prep)
- Onboarding-derived content routing based on `nmStage` and `relationshipContext`

**Gated until partner links:**
- Card sessions with a partner (two-device lock-in)
- Desire Map mutual reveal (beat ceremony requires both sides complete)
- Full deck library beyond the forged opener
- Play tab's featured/session flow in its linked form

### State 2 — Linked (`dashboard`)

Partner connected. Full V1 feature set active.

All features unlock. Both partners operate on a shared couple record
while maintaining individual profiles and private data.

**Reality check on the state machine:** `HomeStore.resolveHomeState()`
now effectively collapses to two live states — `.soloUnpaired` and
`.dashboard`. The previously documented intermediate states
(`.gated`, `.postReflection`, `.waiting`, `.matchReady`) are vestigial:
per an explicit code comment, "Home ALWAYS leads with the card
dashboard." Desire Map completion/reveal is now surfaced as an overlay
step inside the Getting Started path and a `DesireMapState` enum
(`.hidden` / `.yourTurn` / `.bothReady` / `.youDone` / `.freeRevealSeen`
/ `.fullyUnlocked`) on the partner chip, not as a separate Home screen.

**Tab locking is still not wired.** `HomeStore.isTabLocked(_:)` computes
which tabs should be locked in State 1, but nothing in `AppShell` or
`RacetrackTabBar` calls it — all four tabs are always freely tappable
regardless of link state. This remains an open issue (see below).

---

## Onboarding

### Status: Built — 11-phase canvas flow (not 10)

All 11 phases present and wired in sequence by `VaylDirector` over the
`OBPhase` enum (`Vayl/Core/Models/Enums/AppOBEnums.swift`). `appMode` and
`isOnboardingComplete` are set on completion via
`OnboardingStore.commit(data:)`, which calls `persist(data:)` (writes
SwiftData) and `mirrorIntoAppState(data:)` (sets AppState properties).

Onboarding is always completed alone. Partner linking never happens
during onboarding — always after. Both partners complete their own
onboarding independently before linking.

### Phase Sequence

Onboarding is a single continuous dealer-table "canvas," not discrete
screens. Data fields are defined on `OnboardingData.swift` and persisted to
`UserProfile`.

| # | Phase (`OBPhase`) | View | Data Collected |
|---|---|---|---|
| 1 | `stat` | OnboardingCanvas | None — normalisation, shame reduction |
| 2 | `demo` | Demo teach beat | None persisted directly — teaches the tap-lift→swipe-up gesture via a snapshot sentence ("I [need/want/desire] [noun]"), which triangulates `emotionalRegister` |
| 3 | `name` | `NamePhase` | `displayName`, `pronounsA` |
| 4 | `modeSelect` | `ModeSelectPhase` | `appMode` (`.together` / `.solo`) |
| 5 | `gender` | `GenderPhase` | `genderA` / `pronounsA` (+ `genderB` / `pronounsB` in together mode) — radio-tuner power-on + pronouns drum |
| 6 | `experienceLevel` | `ExperienceLevelPhase` | `nmStage` (`.curious` / `.exploring` / `.experienced`) |
| 7 | `context` | `ContextPhase` | `relationshipContext` + `situationalRegister` / `ageRange` / `relationshipTenure` (together) — 2×3 matrix carousel (see below) |
| 8 | `curiosity` | `CuriosityPhase` | `communicationGoals`, `learningGoals` → `curiositySelections` |
| 9 | `confirmation` | `ConfirmationPhase` + `CredentialEditorSheet` | Review / edit collected credentials |
| 10 | `buildDeck` | `BuildDeckPhase` | Runs the Living Case ceremony; derives `openerDeckType` |
| 11 | `founderLetter` | `FounderLetterPhase` | Sets `onboardingCompletedAt`; commits via `OnboardingStore.commit(data:)` |

`VaylDirector.advance(to:)` remains the sole phase-change entry point
(debounced, hides the dealer line, 50ms hold, then dispatches to
`handlePhaseEntry`) — the architecture rule ("director.advance() is the
ONLY way to change OB phase") holds.

**Changed from the earlier plan:**
- **`demo` phase added** between `stat` and `name` — not present in
  earlier documentation.
- **Brand** (logo animation) — never built; cut.
- **Card reveal** / `nmCardResponse` — old flow only; no longer collected.
- **Ground rules** — moved out of onboarding entirely; `groundRulesAcceptedAt`
  still exists on `UserProfile` but is never written during OB.
- The old "Mode select" row conflated two things now split into separate
  phases: `modeSelect` (`appMode`) and `experienceLevel` (`nmStage`).

### The BuildDeck "Living Case" Ceremony — Built, not stubbed

`BuildDeckCeremony.swift` (an `@Observable` state machine — tap count,
erupt-start, held-breath, escalating stress tables) and `BuildDeckPhase.swift`
(822 lines) together implement a real 7-beat sequence: melt-through-felt →
table rim performs → case rises/dolly-zooms → dealer invitation/arms →
3-tap negotiation (recognition/resistance/release) → held breath →
lattice "flower peel" (centre-out) → fixed-stage reveal (name rise → fan
bloom → flip wave → carousel) → founder-letter hand-off. It drives
`MetallicCaseView.swift` (2200+ lines, plus dedicated Metal shader work),
which is also reused in Play (`DeckDetailView`, `DeckCaseView`,
`DeckBeginCeremony`) as the shared case-opening module. Mechanics are
fully wired; feel/timing tuning against a real device is the remaining
work, per the Build Protocol in `CLAUDE.md`.

### Context Screen — 2×3 Matrix (NOT 3 Options)

The earlier 3-option model no longer exists. Context is a 2×3 matrix keyed
on **`AppMode` × `nmStage`** (6 cells), each surfacing ~4 concrete options plus
an "undecided" fallback — 26 `RelationshipContext` cases in total. Defined
in `ContextOption.swift` over the `RelationshipContext` enum (`AppEnums.swift`).

| Cell (AppMode × nmStage) | Representative `RelationshipContext` cases |
|---|---|
| Solo × Curious | `singleCurious`, `partneredSupportiveCurious`, `partneredUndisclosed`, `partneredHesitantCurious`, `soloCuriousUndecided` |
| Solo × Exploring | `singleExploring`, `partneredHandsOff`, `multipleUndefined`, `soloExploringUndecided` |
| Solo × Experienced | `singleExperienced`, `partneredAware`, `soloPolyIndependent`, `soloExperiencedUndecided` |
| Couple × Curious | `coupleSymmetricCurious`, `coupleInitiatorCurious`, `coupleProcessingCurious`, `coupleStalledConversation`, `coupleCuriousUndecided` |
| Couple × Exploring | `coupleSolidifying`, `coupleReorienting`, `coupleParallelExploring`, `coupleExploringUndecided` |
| Couple × Experienced | `coupleFreshIntentional`, `coupleSkillBuilding`, `coupleEvolving`, `coupleExperiencedUndecided` |

`relationshipContext` is saved permanently on `UserProfile`. It informs
content tone and routing throughout the user's history.

### NMStage

Collected during onboarding for every user (in the `experienceLevel` phase).
Persists on `UserProfile`. Drives content difficulty defaults, deck track
filtering (Desire Map items key on `curious`/`established` tracks derived
from this), and deck ordering.

| Value | Meaning | Default Content |
|---|---|---|
| `.curious` | Brand new to NM | Foundational, reassurance-first |
| `.exploring` | Some context, some conversations | Medium depth |
| `.experienced` | Actively practicing | Advanced, skips basics |

### Other Onboarding Fields

Also collected during the flow and persisted on `UserProfile`:
`situationalRegister`, `emotionalRegister`, `ageRange`, `relationshipTenure`,
`agency`, `motivation`, `compassNotes`, `openerDeckType`, and an internal
archetype routing tag.

---

## Navigation — 4 Tabs

Home  |  Play  |  Map  |  Learn
Custom `RacetrackTabBar`. Animated pill draws/reverses between tabs
(0.35s per direction, 0.10s handoff overlap). Haptic on selection.

**Tab locking is a known open issue, not a design intent.** `HomeStore.isTabLocked(_:)`
exists and computes the correct answer, but no call site exists in
`AppShell`/`RacetrackTabBar` — all four tabs are always selectable
regardless of link state. All four tabs are, in practice, already fully
built and independently useful in State 1, which somewhat lowers the
urgency of this — but Play's session-initiation flow and Map's reveal
content are meant to be gated and currently are not enforced at the tab
level (only within their own Stores' entitlement checks).

---

## Tab 1 — Home

### Status: Built — mature, production-grade

Central daily dashboard. Not a static screen — `HomeStore.loadAll()`
(run in `.task`) pulls: couple identity refresh, `UserProfile` map
completion, Desire Map status from the server, the partner's Pulse
position, the most-recently-played deck, deck progress count, the most
recent `CardSession` (drives a reflection-pending banner), that deck's
cards, and server/bundled Lexicon content — then resolves `HomeState`
(effectively `.soloUnpaired` vs `.dashboard`, see User States above).

**Layout, top to bottom:**
- Wordmark ("VAYL.") + `PartnerChip` (tap → `PartnerChipExpand` popover
  for linked users, or routes to pairing invite/join sheets when
  unlinked)
- Getting Started path entry card (shown until the path is complete —
  guides a new user through Desire Map input, first session, etc.)
- Deck carousel / pedestal (`CardChestContainer`) — tap fans the deck
  out (floating → spread → lifted → carousel), building "tonight's
  hand"; tapping a card launches a session (`.vaylCover` in DEBUG,
  routes to Play in release)
- Pulse rail (`HomePulseRail`) — condensed Pulse position, taps out to
  the fuller Map-tab Pulse hero
- Lexicon module (`HomeLexicon`) — daily-5 "Today" motif cards from the
  research corpus

**Overlays:** reflection-pending banner, pending-partner-session banner
(via `SessionEntryStore`, which polls for a partner-initiated session
someone can join), a one-shot completion beat, the Getting Started path
detail overlay, and debug controls (DEBUG builds only).

**Desire Map integration:** the rater and the reveal are both launched
as `.vaylCover`s from Getting Started path steps, not as separate Home
states. `raterDismissOutcome` decides whether reveal, a one-shot
"MapChartedMoment" celebration, or nothing happens next.

---

## Tab 2 — Play

### Status: Built — NOT a stub

Four real sections behind a masthead/hero/wall/detail structure.

- **Masthead + Hero** (`PlayMastheadView`, `PlayHeroView`) — featured
  deck hero, continuity-aware (fresh / in-progress / completed).
  `PlayStore.load()` resolves the featured deck as: most-recent
  in-progress deck (real `DeckProgress`), else the user's forged
  opener until it's completed, else the first available deck. Loads
  that deck's real cards for the hero carousel and fetches connection
  composition (gender dynamic) for card filtering.
- **Deck Wall** (`DeckWallView`) — category-clustered grid of all
  available decks. Locked decks show lock state; tapping one routes to
  `PaywallSheet` via `requestUnlock`.
- **Deck Detail** (`DeckDetailView`) — zoom-in float detail overlay for
  a tapped deck.
- **Begin Ceremony → Session** — tapping a deck's "begin" runs
  `DeckBeginCeremony` (shared `MetallicCaseView` open animation), then
  `SessionBuilderView` (`.vaylSheet`) to shape tonight's plan, then
  opens a realtime session row (`RealtimeSessionService`) and presents
  `CardSessionContainerView` as a `.vaylCover` (lobby-first).
- **Joiner banner** (`PendingSessionBanner`) — same
  `SessionEntryStore` pattern as Home, for joining a partner-initiated
  session.

State 1 users can browse decks and preview content; initiating a
two-device session requires a linked partner (enforced by the session
builder/airlock flow, not by a tab-level gate).

---

## Tab 3 — Map

### Status: Built — NOT a temporary harness

Me / Us toggle, doubled up as the masthead name-toggle (no separate
pill/chevron control).

- **Masthead** — name/Us toggle + settings gear; resolves tenure stage
  and subtitle.
- **Me layer:**
  - `MapPulseHero` — check-in entry + Pulse history access
  - `MapRecord` — personal session history + category-share breakdown,
    derived from real `CardSession` rows
  - Me Card (`MeCardCompact` / `MeCardSheet`) — flavor/title/tags
    derived from positive Desire Map ratings
- **Us layer:**
  - Couple stats — tenure, session count, weeks on Vayl
  - Align/matches list + locked-count teaser, gated by
    `CoupleContext.canRevealAll` (server-authoritative entitlement, not
    the local Couple mirror)
  - Partner's Pulse position + history
  - Vault entry point (`VaultSheet` — desire section, agreements
    section, log section, discussion cards)
- **Sheets:** full Pulse history, Vault, Paywall (on Vault/reveal
  unlock). Pulse check-in itself is a `.vaylCover`.

State 1 users see their own Me layer and a partner-linking prompt in
place of the Us layer's couple content.

---

## Tab 4 — Learn

### Status: Built — NOT a stub

Fully free — no paywall on any Learn content, in any state.

- **Header** — "Learn." wordmark + Resources button + settings gear
- **Quiz carousel** (`QuizCarouselSection`) — flavor/orientation quiz
  entries
- **Research section** (`ResearchSection`) — opens `ResearchDatabaseView`
  (`.vaylCover`, full corpus browse) or a single finding's detail
  (`.vaylSheet`)
- **Content hub** (`ContentHubSection`) — tabbed books / watch / listen
  / voices directory
- **Resources overlay** — sheet with CNM-affirming therapist directory,
  peer support links, interview guide

`LearnStore` loads bundled JSON instantly on init (quizzes, findings,
lexicon terms, media quotes/items, voices, support resources), then
async-refreshes findings/glossary/quotes from Supabase if reachable,
overriding the bundled baseline. Deliberately has no routing state
machine (unlike Home) — Learn has zero dependency on link state or
entitlements.

---

## Card Sessions

### Purpose

A synchronized two-device experience: pick a deck, both partners
complete a lock-in ritual, cards reveal in sync, the session closes with
a reflection or a safe-word exit.

### Content Inventory

`Vayl/Resources/Decks/deck-catalog.json` lists 16 decks. Older decks
(`the-opener.json`, `jealousy.json`, etc.) carry real, finished 10–11
card content. Four newer decks — `opener-opening.json`,
`opener-return.json`, `opener-steady.json`, `opener-wider.json` — are
**explicitly tagged `"stub"`** in their JSON, 6–7 cards each; they are
placeholder replacements for the single old opener and still need real
copy before shipping.

### Session Lifecycle (built)

1. `SessionBuilderStore` / `SessionBuilderView` — shape tonight's plan
   (deck, card count/filter)
2. `AirlockView` / `AirlockStore` + `HoldToLockInRing` — the two-device
   lock-in: a real 3-second hold gesture per partner, calling
   `store?.consent()` against Supabase before the session can start
3. `CardSessionContainerView` — phase router for the live session
4. `SessionPlayerView` / `RevealEngine` — card display and advance logic
5. `SessionCloseView` / `SafeWordCloseView` — completion with
   reflection, or an immediate safe-word exit
6. `RealtimeSessionService` — real Supabase-backed session row +
   Realtime presence/broadcast channels, not a stub

### Card Actions

| Action | Button | Meaning |
|---|---|---|
| We Discussed This | Primary CTA | Partners talked about this card |
| Not Ready | Secondary | Not ready for this topic yet |
| Bookmark | Icon button | Save to revisit later |

### Test Coverage

`CoupleSessionPlaythroughTests.swift`, `SessionBuilderStoreTests.swift`,
`SessionSettingsTests.swift` (Swift), plus
`supabase/tests/card_sessions_invariants.test.sql` — real, non-trivial
assertions across the flow.

### Remaining Work

- Author real content for the four stub opener decks
- Two-device hardware feel pass (Bryan, on real devices — never
  simulator; timing/feel decisions are verified against a reference,
  not guessed)
- Solo prep deck (see below) still needs authoring

---

## Solo Prep Deck

### Status: Not authored — no JSON in bundle

Intended purpose unchanged from earlier scoping: a 5-card, always-free
deck oriented toward self-clarification, meant to surface automatically
for `partneredUndisclosed`-context users after onboarding, and to help
someone work through the conversation they have not had with their
partner yet. When a partner links, the deck's results inform profile
routing but the deck itself is not discarded — its completion record
stays accessible in session history.

**Content requirement:** 5 cards must be authored and bundled as
`solo-prep.json`; the automatic surface-on-`partneredUndisclosed` wiring
also still needs to be built.

---

## Lock In

### Status: Built as part of the session airlock, not a separate architecture-only model

The pre-session lock-in ritual described in earlier scoping is now live
inside the Card Session flow (`AirlockView`/`AirlockStore` +
`HoldToLockInRing`, see Card Sessions above), not a dormant
`LockInSession` model waiting for UI. Lock In is always free — never
paywalled. Any feature that facilitates the conversation is free.

---

## Desire Map

### Status: Input and reveal both fully built; reveal design has changed from earlier scoping

**Purpose:** each partner privately rates a shared list of desire items;
a server-side match computation compares both sets, and a reveal screen
shows the overlaps as a constellation, with a free/paid split on how much
of the result set is visible.

### Input Flow (built)

`DesireMapStore` loads `DesireItem`s from
`Vayl/Resources/Content/desire_items.json` — **19 real, authored items**
(not placeholders) across 6 categories: `structures`, `emotional`,
`sexual`, `communication`, `health`, `logistics`. Each item is
cohort-adaptive: filtered by `track` (`curious` / `established`,
resolved from `nmStage`), with 4 weighted answer strings per track and
couple-framed "meaning" copy for mutual/adjacent alignment. Ratings
persist locally-first via SwiftData `DesireMapEntry`, then sync to
Supabase (`desire_ratings` table) via `SyncManager` /
`DesireSyncService`.

On completion, `markProfileComplete()` sets
`UserProfile.hasCompletedDesireMap = true` — this local flag, not the
SwiftData `DesireMapStatus` model, is what `HomeStore.myMapComplete`
actually reads. Available in State 1 (each partner completes their own
side alone).

### Reveal Flow (built — replaces the old mutual-waiting design)

`DesireRevealStore` fetches computed matches
(`DesireSyncService.fetchMatches`, backed by a `compute-desire-matches`
Supabase edge function), splits results into free vs. locked by
entitlement, and drives a real 3-beat ceremony:

1. **Beat 1** — the one free match reveals
2. **Beat 2** — locked teasers stagger in, blurred
3. **Beat 3** — paywall rises

Rendered as a star-map constellation (`DesireConstellationView` /
`ConstellationLayout`). `HomeStore.resolveDesireMapState()` drives a
`DesireMapState` enum (`.hidden` / `.yourTurn` / `.bothReady` /
`.youDone` / `.freeRevealSeen` / `.fullyUnlocked`) surfaced on the
partner chip, not as a dedicated Home screen.

**What no longer exists (superseded, not merely unbuilt):** the earlier
"Option C" design — a mutual-waiting state with a 7-day escape hatch and
a partner nudge tool (pre-written share-sheet text) — has been replaced
entirely by the simpler `youDone`/`bothReady` states plus the
beat-ceremony reveal above. There is no nudge mechanic, no 7-day timer,
and no explicit "waiting for partner" screen anywhere in current code.
If that behavior is still wanted, it needs to be re-scoped as new work,
not "finished" — do not assume the old design doc's mechanics still
apply.

### Architecture Notes

- The `DesireMapStatus` SwiftData `@Model` is dead scaffolding: modeled,
  registered in `ModelContainer`, deleted on unlink, but **never
  constructed or written anywhere in production code** — every write
  site is inside preview-only example helpers. The real completion
  source of truth is `UserProfile.hasCompletedDesireMap` (local) plus
  the `desire_map_status` / `desire_matches` Postgres tables (remote,
  read via `DesireSyncService`).
- `DesireMapEntry` is the live SwiftData persistence path;
  `DesireMapStore.swift` now reads/writes through it directly (the
  earlier "empty store" architecture debt is resolved).
- `notForUs` items never leave the device — enforced client-side, at
  the edge function, and via RLS on `desire_matches`.

---

## Pulse

### Status: Redesign built and live — old "7-day graph" description is dead code

**Purpose:** a daily capacity/openness check-in, visualized as a 2D
field rather than a line graph, with a couple-comparison "Us" view.

Built (`Vayl/Features/Pulse/Components/`):
- `PulseField` — 2-axis plot (`PulsePosition(energy:, openness:)`),
  four quadrant zones, bloom-ring
- `PulseAura` — "caustic aura" `Canvas`-based radial-gradient layered
  effect (body/caustic/glass-sweep/rim layers), ported from an HTML
  motion reference before being written into SwiftUI (per the Build
  Protocol's "feel first" rule)
- `PulseCapsule` — the "Us-capsule," a stadium shape connecting both
  partners' positions
- `PulseHistoryGrid` — 10-column grid of the last 30 check-ins (not
  calendar days)
- `UsOrbState` — real per-half state machine: `.wholeUnwritten` /
  `.split(mine:partner:)`, a `quietAfterDays = 4` quiet window, and an
  `allowsLiveComparison` headline guard

All four are wired live into `MapPulseHero` and condensed into
`HomePulseRail` on Home.

`PulseStore` persists to UserDefaults as a local cache; a real
`PulseSyncService` pushes/pulls from Supabase (`pulse_entries` table +
`get_partner_pulse_positions` RPC), with `hydrateFromServer()` merging
on launch — server is the source of truth, not UserDefaults alone.

Available in State 1 and State 2. Free tier: unlimited logging.
Pulse pattern insights remain deferred to Act 2.

**Known dead stub:** `PulseFullView.swift` is explicitly marked "to be
rebuilt" — likely the origin of the earlier "7-day graph" description.
That code path is gutted and should not be referenced as current.

---

## Pairing / Partner Linking

### Status: Server-side flow built; deep link is plan-only

**Purpose:** connect two individually-onboarded profiles into one
couple record.

Built (`Vayl/Features/Pairing/`, `Vayl/Core/Services/PairingService.swift`):
- **Generate invite** — `PairingStore.generateInvite()` inserts a
  `pairing_codes` row via Supabase; state machine
  `.idle → .generating → .waitingForPartner(code:)`
- **Poll, expire, regenerate** — a Realtime channel watches
  `user_profiles.couple_id`; on timeout the code expires
  (`PairingError.expiredCode`) and can be regenerated
- **Redeem** — `joinWithCode(_:)` → `claimCode(_:)` invokes the
  `create-couple` Edge Function (server-authoritative)
- **On link** — writes the local SwiftData profile, sets
  `AppState.linkState = .linked`, calls `get-partner` to refresh, and
  hits a `set_connection_composition` RPC for gender-composition
  routing
- **Home partner chip** (`PartnerChip.swift`) — states `.none` /
  `.invitePending` / `.nudge` / `.active(name:)` / `.multipleActive`
  (V1.1 stub). Tap opens `PartnerChipExpand` (inline popover per
  presentation grammar — not a sheet/cover): shows Desire Map status +
  Pulse position tiles + a "Manage pairing" row into
  `PairingSettingsView`.

**Entry mechanism today is manual code entry only.** No share-link
redemption exists in shipped code — `docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md`
is a full plan (Universal Links, Cloudflare Worker, AASA, `onOpenURL`,
`ShareLink`) but zero corresponding Swift code exists yet.

---

## Settings

### Status: Mostly built; three real remaining stubs

| Setting | Status |
|---|---|
| Profile — name input (`SettingsIdentityView`) | ✅ Built |
| Partner pairing — code display/entry, card wording, unlink | ✅ Built |
| Privacy & safety | ✅ Built |
| Notifications | ✅ Built (routes to sheet — verify against actual push-permission wiring, see Push Notifications below) |
| Appearance — theme picker, haptic toggle | ✅ Built |
| Sign out | ✅ Built |
| Delete Account | ✅ Built — real destructive copy, `deleteAccount()` wired to a live `delete-account` Edge Function |
| Restore Purchases button | ❌ Stub — empty action, explicitly commented "Not wired in V1" |
| Paywall upsell card tap | ❌ Stub — empty action, explicitly commented "Not wired in V1" |
| Privacy Policy / Terms of Service / Support rows | ❌ Dead taps — empty `Button {}` closures, no destination |

---

## Paywall / Monetization

### Status: Built further than earlier documentation suggested — StoreKit 2 is live in code

**Purpose:** one lifetime purchase per couple unlocks Deck 2+, the full
Desire Map reveal, all games, Pulse insights, and the agreements vault;
an additional per-connection purchase extends multi-person features.

### Client (built)

- `StoreKitService.swift` — genuine StoreKit 2: `Product.products(for:)`,
  `product.purchase()`, verified-transaction finish, a live
  `Transaction.updates` background listener, and `AppStore.sync()` for
  restore. Product ID currently `com.vayl.core.lifetime`.
- `EntitlementStore.swift` — `@Observable @MainActor`, resolves
  `isCore` as server tier OR local StoreKit ownership; calls
  `service.grantCore(signedTransaction:)` after a verified purchase so
  the partner unlocks server-side too. Injected app-wide at
  `VaylApp.swift` root and bootstrapped on launch; read by
  `SettingsStore`, `HomeStore`, `MapStore`, `PlayStore`,
  `DesireRevealStore`, `VaultStore`, `DeckDetailView`.
- `PaywallSheet.swift` — real purchase/restore buttons wired through
  `EntitlementStore`, correctly delegating (never touches StoreKit
  directly, matching the View→Store layer rule).

### Backend (built)

- `supabase/migrations/20260617120000_monetization_entitlements.sql` —
  service-role-only `entitlements` ledger (deny-all to clients via RLS),
  `couples.access_tier` (`free`/`core`/`pro`), `core_unlocked_at`,
  `is_founding_member`
- `supabase/migrations/20260617130000_entitlement_payer_portable_resolution.sql` —
  payer-portable tier resolution
- Edge function `grant-entitlement` — verifies Apple StoreKit 2 JWS via
  `SignedDataVerifier`, fail-closed behind an `APPLE_VERIFICATION_ENABLED`
  flag until certs/bundle ID are configured server-side; also supports
  an admin/support-secret grant path
- Edge function `appstore-notifications` — App Store Server
  Notifications webhook (refund/revocation handling)

**Open question, not a build gap:** whether `APPLE_VERIFICATION_ENABLED`
and the associated Apple root certs/bundle ID secrets are actually set
in the deployed Supabase project. Until confirmed, the real
Apple-receipt path fails closed and only the admin/support-secret path
grants entitlements in production. Confirm via Supabase secrets before
considering this fully live for real users.

### Tier Structure

| Tier | Price | What It Covers |
|---|---|---|
| Free | $0 | Full onboarding, Desire Map input + 1 mutual match, Deck 1 full, Deck 2 after first sitting (unwrap ceremony), 1 game unlock, Lock In (always free), unlimited pulse logging, unlimited journaling, full Learn tab |
| Vayl Lifetime | $24.99 | Full Desire Map reveal, all couple decks at launch + all future Act 1 decks forever, all games, pulse insights, agreements vault, roadmap, post-session reflection data |
| Additional Connection | $7.99 | Infinite card sessions with that connection, multi-person decks (Network Session + Metamour Deck), shared Lock In, Desire Map input with that connection. Full reveal requires both parties to hold paid accounts. Retired when Vayl Pro launches. |

**One purchase covers two partners.** The app belongs to the couple,
not one person. One purchase, two full accounts, one couple.

**All future Act 1 decks included forever.** Act 1 purchasers never pay
for Act 1 content again.

### Free Tier Rationale

- **Lock In is never paywalled** — free users must be able to properly
  start a session.
- **Learn tab is fully free** — information earns trust before it earns
  money.
- **Unlimited pulse logging, insights locked** — free users build a
  data asset; the insight layer to interpret it is premium.
- **1 match reveal, not 2** — the gap between "we saw one thing we
  agree on" and "we want to see everything" is the conversion driver.
- **Deck 2 unlocks after first sitting, not after completing Deck 1** —
  gating behind full Deck 1 completion could take weeks; the right
  conversion moment is right after the first sitting.

### Primary Conversion Moments

**Moment 1 — The Deck 2 Unwrap.** Trigger: first couple sitting
completes (2–3 cards discussed). Deck 2's unwrap ceremony (shared
`MetallicCaseView`) becomes visible on Home; reaching for it opens the
paywall sheet. Escape: "Not yet" — no guilt, no re-prompt.

**Moment 2 — The Desire Map Reveal.** Trigger: both partners complete
Desire Map independently. Beat 1 of the reveal ceremony shows the one
free match on both devices simultaneously; beats 2–3 tease the locked
remainder and raise the paywall. This is the primary conversion event —
the paywall lands at peak intent.

### Multi-Partner Pricing

| Scenario | Cost |
|---|---|
| New couple (A + B) | Either person pays $24.99. Both have full access. |
| Solo poly (A + connections B, C, D) | A pays $24.99 + $7.99 per additional connection above 1. B, C, D each pay $24.99. |
| Triad (A + B + C, all interconnected) | Each pays $24.99 + $7.99 per additional connection above 1. |

No person is the owner. Everyone pays for their own account. The $7.99
is paid by the person adding the connection — never imposed on the
person being added.

### Multi-Person Decks (Unlocked by $7.99)

**The Network Session** — three or more people, one card, everyone
answers.

**The Metamour Deck** — two people who share a partner but are not
romantically connected to each other.

### The $7.99 Permanent Bill of Rights

For users who purchase an additional connection in Act 1: infinite
card sessions with that connection, multi-person decks for that
configuration, shared Lock In, Desire Map input with that connection —
all permanent, never moved behind Vayl Pro.

### Founding Member Benefit

Vayl Lifetime purchasers receive the first full year of Vayl Pro free
when Pro launches with Act 2 (`is_founding_member` is already tracked
server-side).

### North Star Principles

> **1. Vayl charges for content and infrastructure, never for the
> act of connection itself.**

> **2. Vayl holds the mutual premise as sacred. Data created together
> belongs to both people. No monetization decision overrides that —
> including when one person has paid and the other has not.**

---

## Data Sovereignty — Connection Close

*Architecture scoped for the Map tab build; UI status not re-verified
in this pass — confirm against `MapStore`/pairing-close code before
treating as fully built.*

### Three Data Categories

| Category | Contents | Behavior at Close |
|---|---|---|
| Always Private | Individual Desire Map ratings, pulse logs, journal entries, Lock In individual responses | Never shared. Unchanged at close. |
| Mutually Created | Desire Map match results, shared session history, agreements, shared Lock In records | Each person chooses independently |
| Metadata | Session timestamps, deck completion records, connection duration | Stays with each person's history |

### Sovereignty Choice

Each person independently chooses for mutually created data:
[Archive it] — saved privately, not visible day to day.
[Release it] — removed from your experience.
[Keep it] — stays in your timeline as is.
Neither person's choice affects the other's.

### One-Sided Close Flow

Person A closes connection → removed from Person A's view immediately →
Person A makes sovereignty choice → Person C receives notification
("[Person A] has closed this connection on Vayl.") → Person C given
their own sovereignty choice → shared data held in interim state until
Person C responds. No "are you sure?" confirmation. One moment of
weight, then clean execution.

---

## Push Notifications

### Status: Not re-verified this pass — treat prior "completely unimplemented" claim as unconfirmed

No audit this round searched specifically for `UNUserNotificationCenter`.
Settings does have a "Notifications" row routing to a sheet (see
Settings above), which suggests at least a permission-request surface
may exist now. **Confirm directly before relying on either the old
"completely unimplemented" claim or assuming it's done.**

### V1 Required Notifications (unchanged intent)

| Notification | Trigger | Recipient | Delivery |
|---|---|---|---|
| Partner completed Desire Map | Person C finishes map | Person A | Push |
| Session invite | Partner initiates session | Person C | Push |

Note: the earlier "Desire Map nudge" and "7-day reminder" notifications
are tied to the mutual-waiting/nudge design that no longer exists (see
Desire Map above) — do not scope these without first deciding whether
that mechanic is being reintroduced.

Maximum one push notification per day per user. All notifications
adjustable in Settings.

---

## Sync Infrastructure

| Service | Status |
|---|---|
| Profile sync | ✅ Implemented |
| Onboarding flag sync | ✅ Implemented |
| Retry on launch | ✅ Implemented |
| Desire rating batch sync | ✅ Implemented (`DesireSyncService.syncRatings`) |
| Desire match computation | ✅ Implemented (`compute-desire-matches` edge function) |
| Session record sync | ✅ Implemented (`RealtimeSessionService`, Realtime presence/broadcast) — earlier "stub" status is stale |
| create-couple Edge Function | ✅ Called from `PairingService.claimCode()` |
| Pulse sync | ✅ Implemented (`PulseSyncService`, `pulse_entries` table + `get_partner_pulse_positions` RPC) |
| Entitlement grant/verify | ✅ Implemented (`grant-entitlement`, `appstore-notifications` edge functions) |
| Real-time partner completion signal | Present for sessions (Realtime channels); not separately verified for Desire Map completion this pass |

---

## Architecture Rules

### Layer Pattern

Views     — render only. No business logic. No network calls.
Stores    — decide. Own state. Created where dependencies live.
Services  — fetch. Network, persistence, external systems.
Models    — shape. Data structures. No behaviour.
Data flows down. Actions bubble up.

### Token System

| Token file | Owns |
|---|---|
| `AppColors` | Every color value |
| `AppFonts` | Every font and size |
| `AppSpacing` | Every spacing value |
| `AppRadius` | Every corner radius |
| `AppAnimation` | Every animation curve and duration |
| `AppLayout` | Geometry, derived once at screen root |
| `AppIcons` | Every SF Symbol name string |

No hardcoded values anywhere in view files.

### SwiftData Rules

- Explicit store URL: `Application Support/Vayl.store`
- `NSFileProtectionComplete` entitlement set
- `AppMigrationPlan` updated for any non-additive model change
- All saves should throw and propagate errors — no silent failures
  (aspirational; legacy `DataStore.swift` still uses `try?` in places —
  see Open Issues)

**SchemaV1 registered `@Model`s** (`App/ModelContainer.swift`):
`Couple`, `DesireMatch`, `UserProfile`, `CardSession`, `CardResult`,
`SoloSession`, `DeckProgress`, `DesireMapEntry`, `DesireMapStatus`
(dead — see Desire Map section), `EntitlementRecord`,
`ConnectionEntitlement`, `LockInSession`, `AcknowledgementRecord`,
`MilestoneRecord`.

### Security Rules

- Supabase credentials in `Config.xcconfig` only — never in source
- `desire_map_entries` — RLS: only owner can read their own rows
- `DesireMatch` computed by Edge Function only — never client-side
- `notForUs` items never leave the device — enforced client-side, at
  the edge function, and via RLS on `desire_matches`
- Entitlement writes are service-role-only; `access_tier` is never
  client-settable

---

## V1 Deferred — Not In Scope

| Feature | Status | When |
|---|---|---|
| Solo NM management (independent solo exp) | Architecture routing present | Act 2/3 |
| Vayl Pro subscription | `EntitlementRecord` has `expiresAt` + `isFoundingMember` (no subscription field yet) | Act 2 |
| Jealousy mapping | Not in codebase (a `jealousy.json` deck exists but is a card deck, not a mapping feature) | Act 2 |
| Agreements evolution timeline | Scoped, not built | Act 2 |
| AI coach | Not in codebase | Act 3 |
| Connection cards network management | Map tab shows single-couple view only; multi-connection network view not built | Act 2 |
| Anonymous community feed | Not in codebase | Act 3 |
| Annual retrospective | Not in codebase | Act 3 |
| Pulse pattern insights | Logging + full 2D field built, insight layer absent | Act 2 |
| Post-conversation replay / communication coaching | Not in codebase | Act 2+ |
| `SoloSession` SwiftData model | Registered, never instantiated | Act 2/3 |
| Pairing deep link (Universal Links / share sheet) | Fully planned (`docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md`), zero code | Near-term, not yet started |
| Desire Map mutual-waiting state / 7-day escape hatch / nudge tool | Superseded by the beat-ceremony reveal — would need re-scoping, not resumption | Re-evaluate |
| Per-deck metallic case finishes | `MetallicCaseView` ships with one finish (Vayl spectrum metallic); per-deck multichrome finishes keyed on `Deck.intensity` not yet wired | Act 2 |

---

## Open Issues Before V1 Ship

| Issue | Severity | Location | Fix Required |
|---|---|---|---|
| Tab locking logic exists but not wired to UI | MEDIUM | `HomeStore.isTabLocked()` defined; no call sites in `AppShell`/`RacetrackTabBar` | Wire guard + visual locked state |
| Four opener decks are stub content | HIGH | `Vayl/Resources/Decks/opener-{opening,return,steady,wider}.json` | Author real card copy |
| Solo prep deck not authored | HIGH | Content | Author 5 cards, bundle as `solo-prep.json`; wire auto-surface for `partneredUndisclosed` |
| `DesireMapStatus` SwiftData model is dead scaffolding | LOW | `DesireRating.swift` | Either wire real writes or remove the unused model to reduce confusion |
| Restore Purchases button not wired | MEDIUM | `SettingsView.swift` | Wire to `EntitlementStore.restore()` (StoreKit path already exists) |
| Paywall upsell card tap not wired | MEDIUM | `SettingsView.swift` | Wire to `PaywallSheet` presentation |
| Privacy Policy / Terms / Support rows are dead taps | MEDIUM | `SettingsView.swift` | Add real destinations (web link or in-app content) |
| Apple receipt verification may not be enabled server-side | HIGH (blocks real purchases) | `grant-entitlement` edge function, `APPLE_VERIFICATION_ENABLED` flag | Confirm/set Apple certs + bundle ID secrets in deployed Supabase project |
| Pairing deep link not implemented | MEDIUM | Entire codebase (plan exists, no code) | Implement per `docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md` |
| Push notification status unverified | UNKNOWN | Entire codebase | Re-audit: confirm whether `UNUserNotificationCenter` exists and what it's wired to |
| Data sovereignty / connection-close UI status unverified | UNKNOWN | Map tab / pairing close flow | Re-audit against current `MapStore`/pairing code |
| Legacy `try? context.save()` silent-failure pattern | MEDIUM | `DataStore.swift` (legacy module) | Replace remaining instances with throwing saves; audit for any still-present silent session-loss path in `SessionStore` |
| `PulseFullView` known dead stub | LOW | `Vayl/Features/Pulse/Views/PulseFullView.swift` | Rebuild against the new 2D-field Pulse components, or remove if superseded by `MapPulseHero` |
