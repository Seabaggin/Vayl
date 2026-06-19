# Vayl — V1 Master Project Scope

> Single source of truth. Last updated June 2026 (2026-06-07).
> Codebase governs over this document when they conflict.
> Update this document when the codebase changes intentionally.
>
> Note: the shorter `Vayl — V1 Scope.md` and any external copy of this file
> are now stale relative to this version — re-sync them from here.

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

### State 1 — Unlinked

Completed onboarding. No partner linked yet.

**Available in State 1:**
- Desire Map — complete their own side privately
- Solo prep deck — 5 cards, free, no purchase required
  (intended to surface automatically for `partneredUndisclosed` context users)
- Learn tab — full, no gate
- Pulse — unlimited logging
- Onboarding-derived content routing based on NMStage and context

**Gated until partner links:**
- Card sessions with a partner
- Desire Map mutual reveal
- Lock In
- Full deck library
- Play tab game mechanics

The solo prep deck exists to help someone work through the conversation
they have not had yet. It is not a solo product — it is a bridge.
Its purpose is to get the user to link a partner.

### State 2 — Linked

Partner connected. Full V1 feature set active.

All features unlock. Both partners operate on a shared couple record
while maintaining individual profiles and private data.

---

## Onboarding

### Status: Built — 10-phase canvas flow

All 10 phases present and wired in sequence by `VaylDirector` over the
`OBPhase` enum (`Vayl/Core/Models/Enums/AppOBEnums.swift`). `appMode` and
`isOnboardingComplete` are set on completion via
`OnboardingStore.commit(data:)`, which calls `persist(data:)` (writes
SwiftData) and `mirrorIntoAppState(data:)` (sets AppState properties).

Onboarding is always completed alone. Partner linking never happens
during onboarding — always after. Both partners complete their own
onboarding independently before linking.

### Phase Sequence

Onboarding is a single continuous dealer-table "canvas," not 9 discrete
screens. Data fields are defined on `OnboardingData.swift` and persisted to
`UserProfile`.

| # | Phase (`OBPhase`) | View | Data Collected |
|---|---|---|---|
| 1 | `stat` | OnboardingCanvas | None — normalisation, shame reduction |
| 2 | `name` | `NamePhase` | `displayName`, `pronounsA` |
| 3 | `modeSelect` | `ModeSelectPhase` | `appMode` (`.together` / `.solo`) |
| 4 | `gender` | `GenderPhase` | `genderA` / `pronounsA` (+ `genderB` / `pronounsB` in together mode) — radio-tuner power-on + pronouns drum |
| 5 | `experienceLevel` | `ExperienceLevelPhase` | `nmStage` (`.curious` / `.exploring` / `.experienced`) |
| 6 | `context` | `ContextPhase` | `relationshipContext` + `situationalRegister` / `ageRange` / `relationshipTenure` (together) — 2×3 matrix carousel (see below) |
| 7 | `curiosity` | `CuriosityPhase` | `communicationGoals`, `learningGoals` → `curiositySelections` |
| 8 | `confirmation` | `ConfirmationPhase` + `CredentialEditorSheet` | Review / edit collected credentials — no new data (context + curiosity edit still stubbed) |
| 9 | `buildDeck` | `BuildDeckPhase` | Auto-advance ~7.5s; derives `openerDeckType` |
| 10 | `founderLetter` | `FounderLetterPhase` | Sets `onboardingCompletedAt`; commits via `OnboardingStore.commit(data:)` |

**Changed from the earlier 9-screen plan:**
- **Brand** (logo animation) — never built; cut.
- **Card reveal** / `nmCardResponse` — old flow only; no longer collected.
- **Ground rules** — moved out of onboarding. `groundRulesAcceptedAt` still
  exists on `UserProfile` but is never written during OB (code comment:
  "written from home screen flow"); `founderLetter` is the terminal phase.
- The old "Mode select" row conflated two things now split into separate
  phases: `modeSelect` (`appMode`) and `experienceLevel` (`nmStage`).
- **Gender** is now a dedicated phase (absent from the old table).

### Context Screen — 2×3 Matrix (NOT 3 Options)

The earlier 3-option model (`doingThisTogether` / `oneStepAhead` /
`partneredHidden`) **no longer exists**. Context is now a 2×3 matrix keyed on
**`AppMode` × `nmStage`** (6 cells), each surfacing ~4 concrete options plus an
"undecided" fallback — 26 `RelationshipContext` cases in total. Defined in
`ContextOption.swift` over the `RelationshipContext` enum (`AppEnums.swift`).
Each option carries `id` (snake_case string), `context`, `accent`, copy, and a
`derivedRegister` (`SituationalRegister`).

| Cell (AppMode × nmStage) | Representative `RelationshipContext` cases |
|---|---|
| Solo × Curious | `singleCurious`, `partneredSupportiveCurious`, `partneredUndisclosed`, `partneredHesitantCurious`, `soloCuriousUndecided` |
| Solo × Exploring | `singleExploring`, `partneredHandsOff`, `multipleUndefined`, `soloExploringUndecided` |
| Solo × Experienced | `singleExperienced`, `partneredAware`, `soloPolyIndependent`, `soloExperiencedUndecided` |
| Couple × Curious | `coupleSymmetricCurious`, `coupleInitiatorCurious`, `coupleProcessingCurious`, `coupleStalledConversation`, `coupleCuriousUndecided` |
| Couple × Exploring | `coupleSolidifying`, `coupleReorienting`, `coupleParallelExploring`, `coupleExploringUndecided` |
| Couple × Experienced | `coupleFreshIntentional`, `coupleSkillBuilding`, `coupleEvolving`, `coupleExperiencedUndecided` |

`relationshipContext` is saved permanently on `UserProfile`. It is not
discarded after onboarding — it informs content tone and routing throughout
the user's history.

### NMStage

Collected during onboarding for every user (in the `experienceLevel` phase).
Persists on `UserProfile`. Drives content difficulty defaults and deck ordering.

| Value | Meaning | Default Content |
|---|---|---|
| `.curious` | Brand new to NM | Foundational, reassurance-first |
| `.exploring` | Some context, some conversations | Medium depth |
| `.experienced` | Actively practicing | Advanced, skips basics |

### Other Onboarding Fields (collected, previously undocumented)

Also collected during the flow and persisted on `UserProfile`:
`situationalRegister`, `emotionalRegister`, `ageRange`, `relationshipTenure`,
`agency`, `motivation`, `compassNotes`, `openerDeckType`, and an internal
archetype routing tag.

### Scoped Work

- Push notification permission request must be added (entirely absent
  from codebase)
- Solo prep deck must surface automatically for the `partneredUndisclosed`
  context (formerly `partneredHidden`) after onboarding completes

---

## Navigation — 4 Tabs

Home  |  Play  |  Map  |  Learn
Custom `RacetrackTabBar`. Animated pill draws/reverses between tabs
(0.35s per direction, 0.10s handoff overlap — verified). Haptic on
selection (verified).

**Tab locking:** Play and Map should be inaccessible in State 1 (unlinked)
and before Home reaches `.dashboard` state in State 2. The guard *logic*
exists — `HomeStore.isTabLocked(_:)` — but is **not wired into the UI**:
`AppShell` / `RacetrackTabBar` never call it, so all four tabs are always
selectable. Wiring + visual locked state must be added before V1.

---

## Tab 1 — Home

### Status: Built

Central daily dashboard. Scroll-driven greeting fades at scroll threshold.

### Entry Routing (HomeRouterView + HomeStore)

**State 1 — Unlinked:**

State-1 routing now resolves through `HomeState.soloUnpaired` (solo user,
OB complete, no partner yet) rather than the retired 3 context IDs. The
intended context-driven emphasis still holds:

| Context group | Emphasis |
|---|---|
| `partneredUndisclosed` (curious, hasn't brought it up) | Solo prep deck prominent, partner invite CTA |
| Ready-to-link contexts (e.g. `partneredSupportiveCurious`) | Partner invite CTA prominent, Desire Map available |
| Couple contexts (`couple*`) | Partner invite CTA, Desire Map available |

All unlinked users can access their Desire Map side, the solo prep deck
(if applicable), Learn tab, and Pulse. Card sessions with a partner
are not available until linked.

**State 2 — Linked:**

| State | Condition | Screen |
|---|---|---|
| `.soloUnpaired` | Solo user, OB complete, no partner yet | starter deck reachable, Desire Map gated |
| `.gated` | Desire Map not started | `HomeGateView` |
| `.postReflection` | Map complete, reflection pending | `PostMapReflectionView` |
| `.waiting` | Reflection done, partner not complete | `HomeWaitingView` |
| `.matchReady` | Both complete, reveal not triggered | `HomeMatchReadyView` |
| `.dashboard` | Fully unlocked | `HomeDashboardView` |

Resolution logic (`HomeStore.resolveHomeState()`, evaluated in order):
if isSolo && unlinked    → .soloUnpaired   ← checked first
guard myMapComplete      → .gated
guard postReflectionDone → .postReflection
guard partnerMapComplete → .waiting
guard revealDone         → .matchReady
→ .dashboard
**Not yet reachable from real data:** `partnerMapComplete` is never updated
from `DesireMapStatus` (TODO in `HomeStore`), so `.waiting` / `.matchReady`
only occur via the debug overrides below.

**Debug override risk:** `HomeStore.init()` hardcodes all completion flags
to `true` in `#if DEBUG` (lines ~74–82). The full state progression is never
exercised in debug builds. Remove before release testing.

### Dashboard Widgets (State 2, top to bottom)

**The Deck** — `CardChestContainer`
Fanned card deck. Tap → gathered → lifted → carousel. Tapping a card
in carousel triggers `onCardAction(.startSession)` → `HomeRouterView`
creates `SessionStore` and presents `SessionView`.

**The Pulse** — `PulseWidget`
7-day graph. Inline check-in expansion (never a fullScreenCover).
Backed by `PulseStore` (UserDefaults, migrating to SwiftData before V1).

**Pick Up** — `PickUpCard`
Content recommendation cards driven by `HomeEventEngine`.

**Research Ticker** — `ResearchTicker`
Auto-cycling research facts. Tap expands to full content in Learn tab.

---

## Tab 2 — Play

### Status: Stub (`Text("Play")` only)

### V1 Scope

Full build required. Four sections:

**Card Sessions** — Deck selection entry point. Current deck highlighted.
All available decks browsable in a grid. Deck 2+ require Vayl Lifetime.

**Pre-Flight** — 3-question diagnostic (event type, nervous system state,
biggest fear) that generates a custom emotional preparation summary.

**Games** — Interactive relationship games. Free tier: 1 unlock.
Vayl Lifetime: all games.

**Archive** — Searchable grid of all unlocked card categories and
completed session history.

State 1 users see a prompt to link a partner before Play unlocks.

---

## Tab 3 — Map

### Status: Temporary harness (renders `PairingSettingsView` as P3 test)

### V1 Scope

Full build required. Two-panel toggle.

**Couple View** (default for linked users)
- Constellation showing the couple and all active connections
- Add connection, view connection history
- Partner linking and code entry

**Network View** (unlocked by $7.99 additional connection)
- Full connection constellation
- Multi-connection management
- Connection close flow with data sovereignty

State 1 users see their own profile only and a partner linking prompt.

---

## Tab 4 — Learn

### Status: Stub (`Text("Learn")` only)

### V1 Scope

Full build required. Fully free — no paywall on any Learn content.
Available in all states including State 1.

| Section | Contents |
|---|---|
| Dossiers | Long-form research-backed relationship concept guides. Research Ticker items deep-link here. |
| Lexicon | NM-specific terminology, alphabetical |
| Library | Curated external reading references |
| Ground Crew | CNM-affirming therapist directory, peer support links, therapist interview guide |

All four sections require content authoring before V1 ships.

---

## Solo Prep Deck

### Triggers

Intended to surface automatically after onboarding completes for users with
`partneredUndisclosed` context (formerly `partneredHidden`). Also accessible
to other solo/curious "ready-to-link" contexts (e.g.
`partneredSupportiveCurious`) who want to do solo preparation before their
partner joins. (Auto-surface wiring is still scoped work — see below.)

### Properties

- 5 cards
- Always free, no purchase required
- Designed to help someone work through the conversation they have
  not had with their partner yet
- Cards are oriented toward self-clarification, not couple exercises

### Lifecycle

- Available in State 1 (unlinked)
- When partner links, the deck archives — its results inform profile
  routing but it does not disappear entirely
- `nmCardResponse` and solo session data are saved permanently to
  `UserProfile` — context is never discarded
- In State 2, the deck is not surfaced as an active session but its
  completion record is accessible in session history

### Content Requirement

5 cards must be authored before V1 ships. Deck ID: `solo-prep`.

---

## Card Sessions

### Content Inventory

| Deck | Cards | Tier | Status |
|---|---|---|---|
| `the-opener` — The Opener | 10 | Free (first sitting) then Deck 2 gate | Bundled JSON, real production content |
| `solo-prep` — Solo Prep | 5 | Always free | ❌ Not authored — no JSON in bundle |

Only `the-opener.json` is currently bundled; `Resources/Decks/deck-index.json`
lists `["the-opener"]` alone. The solo prep deck, Deck 2, and Deck 3–N for
couple sessions must still be authored — Deck 2 is required for the primary
conversion moment.

### Session Lifecycle

1. `SessionStore` initialised with a `Deck` and `startIndex`
2. `recordAndAdvance(status:)` records a `CardResult`, increments index
3. `updateDeckProgress()` persists resume position to `DeckProgress`
4. On last card: `saveSession()` writes `CardSession` + all `CardResult`
   records and sets `DeckProgress.completedAt`

Session entry points:
- **Home** — tapping active card in carousel → `onCardAction(.startSession)`
- **Play tab** — deck selection from grid

### Card Actions

| Action | Button | Meaning |
|---|---|---|
| We Discussed This | Primary CTA | Partners talked about this card |
| Not Ready | Secondary | Not ready for this topic yet |
| Bookmark | Icon button | Save to revisit later |

### Silent Failure — Must Fix Before V1

`SessionStore.saveSession()` logs a warning and returns if `coupleId` is nil.
The entire session is lost with no user-visible error or notification (a log
line is not a user surface). Must surface a user-visible error state before
V1 ships.

---

## Lock In

### Status: Architecture-only

`LockInSession` `@Model` compiles and is in SchemaV1. No UI exists.
Not wired into the session flow. `CardSession` already carries
`lockInBandwidthA` / `lockInBandwidthB` fields for this, but they are never
set by any code.

Lock In is always free — never paywalled. Any feature that facilitates
the conversation is free.

### V1 Scope

- Pre-session entry ritual UI
- Bandwidth and nervous system check-in for both partners before a session
- `LockInSession` written to DataStore on completion
- Associated with the `CardSession` record that follows

---

## Desire Map

### Status: Input partially built, reveal not built

`DesireMapView` presents 4 categories × 3 items (12 items, placeholder
content). Ratings save per-user. Partner data saves independently —
correct for mutual independent completion.

Available in State 1 (users complete their own side alone).
Mutual reveal requires both partners to be linked and both sides complete.

**Not built:**
- `DesireMapStatus` never written after completion
- HomeState flags not updated on map completion (`partnerMapComplete` TODO)
- Reveal flow does not exist (`HomeMatchReadyView` has a CTA stub only — no
  reveal detail / match-list view)
- Match calculation does not exist (deferred to Supabase Edge Function)
- Paywall gate does not exist

**Architecture debt:**
- `DesireMapStore.swift` exists but is **empty** (header comment only);
  `DesireMapView` still reads/writes through `DataStore` directly (TODO).
- `DesireMapEntry` `@Model` exists and is registered but **unused** — a second
  persistence path parallel to the legacy `DataStore` ratings.
- `DesireMapView` references `AppIcons.chevronDown`, which is **not yet
  defined** in `AppIcons` (will not compile until added).

### Content Requirement

Final 17 desire items must replace the current 12 placeholder items.

---

### Desire Map Reveal — State Machine (Option C, Final)

The most important UX flow in the product. These decisions are final.
The mutual premise — reveal data belongs to both people — governs
every branch.

**Why Option C:**
Option A (paid sees all, free sees one) breaks the mutual premise.
Option B (both see one until free upgrades) punishes a paying user for
another person's financial decision.
Option C — mutual waiting state with 7-day escape hatch — is correct.

---

#### State Map: Person A (paid) + Person C (free) after Desire Map

BOTH SEE IMMEDIATELY
└── 1 confirmed mutual match (same match, same moment, both devices)PERSON A SEES
├── "You have X more matches waiting."
├── Clean waiting state — no locked-out language
├── [Send Person C a nudge]
│   └── Generates pre-written iMessage/WhatsApp text:
│       "We did our Desire Map on Vayl and there's a match
│        waiting for us. I can't see it until you unlock
│        your account. [link]"
└── No blur — Person A paid; their view is resolved pending CPERSON C SEES
├── X matches blurred below the free reveal
├── "You have X more mutual matches."
├── "Own your experience — not just participate in it."
├── $24.99 upgrade CTA
└── Never "pay to unlock" — always "buy your own account"WHEN PERSON C UPGRADES
├── Full reveal triggers simultaneously on both devices
├── Designed moment — not a navigation transition
├── Both people experience it together
└── The wait made it more valuable, not less
---

#### 7-Day Escape Hatch

Without a deadline the waiting state collapses into Option B.
Anticipation decays into resentment at approximately one week.

**Why 7 days:** Connections often see each other once a week or less.
48 hours punishes connection cadence. 7 days equals one full calendar
cycle — at least one realistic opportunity to connect.

Day 1–2   Natural anticipation. Person A sends organic nudge.
Day 3–4   App sends one gentle reminder to Person C. Maximum one.
Day 5–6   Person A can see the waiting state is aging.
One final manual nudge available.
Day 7     Resolution state surfaces to Person A.
**Day 7 Resolution — Person A:**
"It's been a week.Person C hasn't unlocked their account yet —
and that's okay. Not every moment lands
at the same time for both people.Your Desire Map responses are yours.
[View my individual responses]The full reveal is still waiting if
Person C decides to join.
[Send one last nudge]Or start fresh with a different connection.
[Add a connection]"
**Why Person A receives individual responses, not match results:**
Match results are mutual data. A match only exists because two people
answered. Revealing matches unilaterally misrepresents what they are.
Person A's individual ratings are entirely theirs and are returned.
Mutual results require mutual consent. Match data stays in amber —
not deleted — waiting indefinitely for Person C.

**The nudge belongs to Person A, not Vayl:**
Vayl provides the message text. Person A provides the relationship.

---

#### Implementation Requirements

1. Write `DesireMapStatus` on completion for both users
2. Match calculation service comparing both partner ratings
3. Reveal screen: first match visible, rest blurred, count displayed
4. Person A waiting state: match count shown, no match content
5. Nudge tool: share sheet with pre-written copy and deep link
6. 7-day timer: Day 3–4 notification, Day 7 resolution state
7. Simultaneous reveal signal on Person C upgrade (Supabase Realtime)
8. "View my individual responses" path: own ratings only, no mutual data

---

## Pulse

### Status: Logging built, insights deferred

| Component | Status |
|---|---|
| `PulseStore` | Built — UserDefaults-backed, must migrate to SwiftData |
| `PulseWidget` | Built — inline check-in, 7-day graph |
| `PulseGraph` | Built — real data, Canvas rendering, breath animation |
| Pulse Insights | Deferred — Act 2 |

Available in State 1 and State 2.
Free tier: unlimited logging. Insights locked (lock state UI needed).

---

## Settings

### Status: Partially built

| Setting | Status |
|---|---|
| Profile — name input | ✅ Built |
| Partner pairing — code display, entry, Link Partner | ✅ Built |
| Appearance — theme picker, haptic toggle | ✅ Built |
| Privacy — screenshot protection toggle | ✅ Built (raw `@AppStorage` key; TODO migrate to `UserDefaultsKey` enum) |
| Data — Export My Data | ✅ Built |
| Danger Zone — Reset All Data | ✅ Built |
| App info footer | ✅ Built |
| Debug — Log Out & Reset Onboarding | ✅ Debug only |
| Delete Account | ❌ Not built — required for App Store |
| Restore Purchases | ❌ Not built — requires StoreKit first |

**New in-flight infrastructure (untracked by earlier versions of this doc):**
- `UserDefaultsKey.swift` (`Core/Models/Enums/`) — canonical enum for
  UserDefaults string keys (currently houses `hasCompletedOnboarding`).
- `CredentialEditorSheet.swift` (`Features/Onboarding/Phases/`) — edit
  half-sheets for the `confirmation` phase (name / gender / mode / experience
  working; context + curiosity edit stubbed).

---

## Paywall Structure

### Tier Structure

| Tier | Price | What It Covers |
|---|---|---|
| Free | $0 | Full onboarding, Desire Map input + 1 mutual match, solo prep deck (5 cards), Deck 1 full, Deck 2 after first sitting (unwrap ceremony), 1 game unlock, Lock In (always free), unlimited pulse logging, unlimited journaling, full Learn tab |
| Vayl Lifetime | $24.99 | Full Desire Map reveal, all couple decks at launch + all future Act 1 decks forever, all games, pulse insights, agreements vault, roadmap, post-session reflection data |
| Additional Connection | $7.99 | Infinite card sessions with that connection, multi-person decks (Network Session + Metamour Deck), shared Lock In, Desire Map input with that connection. Full reveal requires both parties to hold paid accounts. Retired when Vayl Pro launches. |

**One purchase covers two partners.** The app belongs to the couple,
not one person. One purchase, two full accounts, one couple.

**All future Act 1 decks included forever.** This is a commitment.
Act 1 purchasers never pay for Act 1 content again.

### Free Tier Rationale

**Lock In is never paywalled.** Paywalling the session ritual means
free users cannot properly start a session. Vayl charges for content
and infrastructure, never for the act of connection itself.

**Learn tab is fully free.** Information is less gatekept. A couple
who finds something that names what they have been feeling earns
trust before it earns money.

**Solo prep deck is always free.** Its job is to get someone to link
a partner. Paywalling the bridge defeats the purpose.

**Unlimited pulse logging, insights locked.** Free users build a data
asset they can only fully understand with the insight layer. They own
the data. The tool to interpret it is premium.

**1 match reveal, not 2.** The gap between "we saw one thing we agree
on" and "we want to see everything" is the conversion driver.

**Deck 2 unlocks after first sitting, not after completing Deck 1.**
Gating Deck 2 behind completing Deck 1 could take weeks. The right
conversion moment is after the first sitting completes.

---

### Primary Conversion Moments

#### Moment 1 — The Deck 2 Unwrap

Trigger:   First couple sitting completes (2–3 cards discussed)
What shows: Deck 2 unwrap visible on Home
Gate:      Reach for Deck 2 → unwrap ceremony → paywall sheet
Copy:      "You're ready for this one."
"Unlock everything — $24.99, yours forever."
Escape:    "Not yet" — no guilt, no re-prompt
Desire before friction. Card faces are partially visible before the
paywall sheet appears.

#### Moment 2 — The Desire Map Full Reveal

Trigger:   Both partners complete Desire Map independently
What shows: 1 free match reveals simultaneously on both devices
Ask:       Full picture blurred below the free reveal
"You have X more mutual matches."
"Unlock everything — $24.99, yours forever."
The Desire Map is the primary conversion event. Any user who sees
the free match has already invested in the product. The paywall lands
at peak intent — the exact moment both people want more.

---

### Person C Free Tier Experience

THE INVITE
└── Premium link: "Person A wants to sync with you on Vayl."ONBOARDING
└── Frictionless — no paywalls on arrival
└── Full onboarding experienceCARD SESSIONS
├── Full participation — sees cards, inputs answers
├── Cannot initiate sessions (requires paid account)
└── Feels like a premium app, not a demoDESIRE MAP
├── Fills out their side completely
├── Sees 1 mutual match
└── Remaining matches blurred
"You have X more mutual matches.
Upgrade to own your experience."THE UPGRADE SELL
├── Autonomy — "Own your experience, not just participate in it"
├── Their account survives any change in their relationship with Person A
└── No financial discount — the trusted invite is the value
---

### Multi-Partner Pricing

| Scenario | Cost |
|---|---|
| New couple (A + B) | Either person pays $24.99. Both have full access. |
| Solo poly (A + connections B, C, D) | A pays $24.99 + $7.99 per additional connection above 1. B, C, D each pay $24.99. |
| Triad (A + B + C, all interconnected) | Each pays $24.99 + $7.99 per additional connection above 1. |

No person is the owner. Everyone pays for their own account. The $7.99
is paid by the person adding the connection — never imposed on the
person being added.

---

### Multi-Person Decks (Unlocked by $7.99)

**The Network Session** — three or more people, one card, everyone
answers. Cards designed around dynamics that only exist with multiple
connected people present.

**The Metamour Deck** — two people who share a partner but are not
romantically connected to each other. The most underserved dynamic in
NM. No existing app addresses this. Inherently shareable in NM
communities.

---

### The $7.99 Permanent Bill of Rights

For users who purchase an additional connection in Act 1, these
features are permanently theirs regardless of Vayl Pro launch:
- Infinite card sessions with that specific connection
- Multi-person decks for that specific configuration
- Shared Lock In with that connection
- Desire Map input with that connection

Nothing from Act 1 ever moves behind Vayl Pro for users who
purchased it. One-time purchase means one-time purchase. Forever.

---

### Founding Member Benefit

Vayl Lifetime purchasers receive the first full year of Vayl Pro free
when Pro launches with Act 2. No timer. No conditions. After year one,
standard monthly rate.

---

### North Star Principles

> **1. Vayl charges for content and infrastructure, never for the
> act of connection itself.**

> **2. Vayl holds the mutual premise as sacred. Data created together
> belongs to both people. No monetization decision overrides that —
> including when one person has paid and the other has not.**

---

## Data Sovereignty — Connection Close

*Architecture scoped for V1 Map tab build.*

### Three Data Categories

| Category | Contents | Behavior at Close |
|---|---|---|
| Always Private | Individual Desire Map ratings, pulse logs, journal entries, solo prep deck results, Lock In individual responses | Never shared. Unchanged at close. |
| Mutually Created | Desire Map match results, shared session history, agreements, shared Lock In records | Each person chooses independently |
| Metadata | Session timestamps, deck completion records, connection duration | Stays with each person's history |

### Sovereignty Choice

Each person independently chooses for mutually created data:
[Archive it]   — saved privately, not visible day to day
[Release it]   — removed from your experience
[Keep it]      — stays in your timeline as is
Neither person's choice affects the other's.

### One-Sided Close Flow

Person A closes connection
└── Removed from Person A's view immediately
└── Person A makes sovereignty choice
└── Person C receives notification:
"[Person A] has closed this connection on Vayl."
└── Person C given their own sovereignty choice
└── Shared data held in interim state until Person C responds
No "are you sure?" confirmation. One moment of weight, then clean
execution.

---

## Push Notifications

### Status: Completely unimplemented

No `UNUserNotificationCenter` reference exists anywhere in the codebase.

### V1 Required Notifications

| Notification | Trigger | Recipient | Delivery |
|---|---|---|---|
| Partner completed Desire Map | Person C finishes map | Person A | Push |
| Desire Map nudge (Day 1–2) | Person A taps nudge | Person C | Share sheet — Person A sends via iMessage/WhatsApp. Vayl provides copy. |
| 7-day reminder | Day 3–4 of waiting state | Person C | Push — maximum once |
| Session invite | Partner initiates session | Person C | Push |

Maximum one push notification per day per user. All notifications
adjustable in Settings.

### Scoped Work

- `UNUserNotificationCenter` authorization during onboarding
- Remote push entitlement in `Vayl.entitlements` — currently holds only
  `applesignin` + `default-data-protection` (NSFileProtectionComplete); no
  `aps-environment` key yet
- Notification payloads for all four triggers above

---

## Paywall Client Infrastructure

### Status: Architecture-only, no client implementation

| Component | Status |
|---|---|
| `EntitlementRecord` SwiftData model | ✅ Exists |
| `ConnectionEntitlement` SwiftData model | ✅ Exists |
| StoreKit import | ❌ Not present anywhere |
| Product fetching | ❌ Not implemented |
| Purchase flow | ❌ Not implemented |
| Entitlement check on gated content | ❌ Not implemented |
| Restore Purchases | ❌ Not implemented |
| Paywall UI | ❌ No Paywall folder exists yet — must be created |

### Scoped Work

- Product IDs: `com.vayl.lifetime` ($24.99), `com.vayl.connection` ($7.99)
  ⚠️ **Mismatch to reconcile:** `EntitlementRecord.swift` currently hardcodes
  `com.vayl.core.lifetime`, not `com.vayl.lifetime`. Pick one canonical ID
  before StoreKit wiring.
- Purchase flow UI — paywall sheets at Deck 2 gate and Desire Map reveal
- `EntitlementRecord` write on successful purchase
- Server-side receipt validation
- Entitlement checks before gated content is served
- Restore Purchases in Settings

---

## Sync Infrastructure

| Service | Status |
|---|---|
| Profile sync | ✅ Implemented |
| Onboarding flag sync | ✅ Implemented |
| Retry on launch | ✅ Implemented |
| Desire rating batch sync | ✅ Implemented |
| Session record sync | ❌ Stub — DTOs only, no methods |
| create-couple Edge Function | ✅ Called from `PairingService.claimCode()` |
| DesireMapStatus sync | ❌ Not implemented |
| Real-time partner completion signal | ❌ Not implemented |

### Scoped Work

- `SessionSyncService` full implementation
- `DesireMapStatus` sync so completion propagates to partner's device
- Supabase Realtime subscription for simultaneous Desire Map reveal

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

### Banned Patterns

Rule, then current compliance reality:

- `UIScreen.main` — use `GeometryReader` + `AppLayout.from(geo)`.
  ✅ **Compliant** — 0 uses (only referenced in comments).
- `@Published` + `ObservableObject` — use `@Observable`.
  ✅ **Compliant** — 0 uses; all stores use `@Observable`.
- `DispatchQueue.main.async` — prefer `@MainActor` / `await MainActor.run`.
  ⚠️ **~39 instances remain** (animation sequencing in `RacetrackTabBar` + OB
  phases). Acceptable for V1; modernization candidate.
- `try? context.save()` — use throwing saves with error propagation.
  ❌ **7 instances in `DataStore.swift`** (legacy module); newer code uses
  `saveWithLogging()`. See Open Issues.
- Force unwrap `!` on anything that can realistically be nil.
  ⚠️ ~10 instances; most safe (guaranteed-non-empty arrays, guarded nils), a
  few worth auditing (`try! AttributedString(markdown:)` in `ConversationCard`,
  slot lookup in `CardFlightEngine`).
- Hardcoded colors, fonts, spacing, or animation values in view files.
  ✅ Broadly compliant via the token system.

### SwiftData Rules

- Explicit store URL: `Application Support/Vayl.store`
- `NSFileProtectionComplete` entitlement set
- `AppMigrationPlan` updated for any non-additive model change (currently
  empty stages — pre-launch)
- All saves throw and propagate errors — no silent failures (aspirational;
  `DataStore.swift` still uses `try?` — see Open Issues)

**SchemaV1 registered `@Model`s** (`App/ModelContainer.swift`, 14 total):
`Couple`, `DesireMatch`, `UserProfile`, `CardSession`, `CardResult`,
`SoloSession`, `DeckProgress`, `DesireMapEntry`, `DesireMapStatus`,
`EntitlementRecord`, `ConnectionEntitlement`, `LockInSession`,
`AcknowledgementRecord`, `MilestoneRecord`.

### Security Rules

- Supabase credentials in `Config.xcconfig` only — never in source
- `desire_map_entries` — RLS: only owner can read their own rows
- `DesireMatch` computed by Edge Function only — never client-side
- `notForUs` items never leave the device — three enforcement layers:
  client (never included in payload), Edge Function (filtered before
  writing to `desire_matches`), database (RLS on `desire_matches`)

---

## V1 Deferred — Not In Scope

| Feature | Status | When |
|---|---|---|
| Solo NM management (independent solo exp) | Architecture routing present | Act 2/3 |
| Vayl Pro subscription | `EntitlementRecord` has `expiresAt` + `isFoundingMember` (no subscription field yet — needs a new model in Act 2) | Act 2 |
| Jealousy mapping | Not in codebase | Act 2 |
| Agreements evolution timeline | Scoped, not built | Act 2 |
| AI coach | Not in codebase | Act 3 |
| Connection cards network management | Map tab stub | Act 2 |
| Anonymous community feed | Not in codebase | Act 3 |
| Annual retrospective | Not in codebase | Act 3 |
| Pulse pattern insights | Logging built, insight layer absent | Act 2 |
| Constellation carousel full view | Map tab stub | Act 2 |
| Post-conversation replay / communication coaching | Not in codebase | Act 2+ |
| `SoloSession` SwiftData model | Registered, never instantiated | Act 2/3 |
| Per-deck metallic case finishes | Foil-Open ceremony ships with one finish (Vayl spectrum metallic) for the OB starter deck; each unlocked deck should later get its own metallic multichrome derived from `Deck.intensity`. `MetallicCaseView` already takes a `finish` input — wire per-deck finishes when the deck library/unlock flow is built. | Act 2 |

---

## Open Issues Before V1 Ship

| Issue | Severity | Location | Fix Required |
|---|---|---|---|
| Silent session loss when `coupleId` is nil | HIGH | `SessionStore.saveSession()` | Throw error, surface to user |
| 7× silent `try? context.save()` | HIGH | `DataStore.swift` lines 126, 189, 203, 218, 224, 232, 260 | Replace with throwing saves |
| `deleteAllData()` partial deletion | CRITICAL | `DataStore.swift:260` | Throw on failure, warn user |
| Debug overrides mask full state machine | HIGH | `HomeStore.init():74–82` | Remove before release testing |
| `DesireMapStatus` never written | HIGH | `DesireMapView.swift` | Write completion flags on map save |
| Tab locking logic exists but not wired to UI | MEDIUM | `HomeStore.isTabLocked()` defined; no call sites in `AppShell`/`RacetrackTabBar` | Wire guard + visual locked state |
| Push notifications entirely absent | HIGH | Entire codebase | `UNUserNotificationCenter` + onboarding permission |
| StoreKit entirely absent | HIGH | Entire codebase | Full purchase flow implementation |
| `SessionSyncService` is a stub | MEDIUM | `SessionSyncService.swift` | Implement session record sync |
| Real-time partner signal absent | HIGH | Sync layer | Required for simultaneous Desire Map reveal |
| `PulseStore` on UserDefaults | MEDIUM | `PulseStore.swift` | Migrate to SwiftData |
| Only 1 couple deck in bundle | HIGH | `Vayl/Resources/Decks/` | Author and bundle Deck 2+ |
| Solo prep deck not authored | HIGH | Content | Author 5 cards, bundle as `solo-prep.json` |
| Desire Map items are placeholders | HIGH | `DesireMapView.swift` | Replace with final 17 items |
| Learn tab is a stub | HIGH | `LearnView.swift` | Full build + content authoring |
| Play tab is a stub | HIGH | `PlayView.swift` | Full build |
| Map tab is a test harness | HIGH | `MapView.swift` | Full build |
| Delete Account missing | MEDIUM | `SettingsView.swift` | Required for App Store compliance |
| Restore Purchases missing | MEDIUM | `SettingsView.swift` | Add after StoreKit is wired |
| `partneredUndisclosed` (was `partneredHidden`) does not trigger solo prep deck | HIGH | Post-onboarding routing | Wire solo prep deck surface logic |
| `DesireMapStore` empty; `DesireMapEntry` unused (parallel persistence) | MEDIUM | `DesireMapStore.swift`, `DesireMapView.swift` | Move data access into store; unify on one persistence path |
| `AppIcons.chevronDown` referenced but undefined | HIGH | `DesireMapView.swift`, `AppIcons.swift` | Add token (blocks compile of Desire Map) |
| `CredentialEditorSheet` context + curiosity edit stubbed | MEDIUM | `CredentialEditorSheet.swift` | Implement remaining two editors |
| Product-ID mismatch (`com.vayl.core.lifetime` vs doc's `com.vayl.lifetime`) | MEDIUM | `EntitlementRecord.swift` | Pick canonical ID before StoreKit wiring |
