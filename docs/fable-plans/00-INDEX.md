# Fable One-Shot Plans — Master Index

_Generated 2026-07-01. A portfolio of self-contained, Fable-5-ready implementation plans that
break the app's remaining work into single-pass chunks. Each plan carries the **ONE-SHOT LICENSE**
(see `_SHARED-PREAMBLE.md`): it suspends the "one segment at a time, verify on device before the next"
pacing rule and authorizes Fable to build the whole plan end-to-end in one pass, while keeping every
quality rule (4-layer, tokens, iOS 26, presentation grammar, a11y, empty states) non-negotiable._

**How to use this:** hand Fable ONE plan file at a time (e.g. "implement `docs/fable-plans/01-dead-code-purge.md`").
It has everything it needs with zero prior context. After each pass, run that plan's "Bryan verifies on
device" checklist. Start with the shared preamble open so you know the license it's operating under.

Every plan was written by an agent that **read and verified the actual source** before writing — every
path, symbol, and line number was checked against the repo, and the drifts they found are captured below.

---

## Readiness tiers — build these in this order

Ranked by how cleanly Fable can one-shot each (build-provable → device-dependent). Within a tier, the
order is the suggested sequence.

### 🟢 Tier A — Clean one-shots (build-provable, little/no device risk). Do first.
| # | Plan | What it does | Notes |
|---|---|---|---|
| **01** | [Dead-code purge](01-dead-code-purge.md) | Delete 48 dead files + 3 coordinated card-faces + `HomeWidgetShell`; confirm legacy-session retirement | Pure mechanical. **C-2 is already done** — this is mostly deletion + a build. The cleanest possible one-shot; do it first so every later grep is clean. |
| **02** | [Correctness + a11y hardening](02-correctness-and-a11y-hardening.md) | `try?`-guard the markdown crash (H-1), `saveWithLogging()` the silent-loss saves (H-3), Reduce-Motion gate the ambient loops (H-5), iPhone-only device family | Small, high-confidence, removes a real crash + an a11y gap. |
| **06** | [Test target + invariants](06-test-target-and-invariants.md) | Add the money/privacy/gating invariant tests to the existing `VaylTests` | Corrects roadmap drift (`HomeState` has no `waiting`/`matchReady`; `notForMe` *does* sync). Pure logic — fully build-provable. |
| **07** | [Empty states + observability](07-empty-loading-error-and-observability.md) | Extract a generic `VaylEmptyState`, sweep the reviewer-critical screens, wire Firebase Crashlytics behind a PII-safe façade | App Store readiness (A3). Honest Map/Us empty state, no fake partner. |
| **03** | [Token-discipline sweep](03-token-discipline-sweep.md) | Repoint ~10 Pairing fonts + 2 spacing literals | **Near-noop by design** — the agent proved the token "debt" collapses to almost nothing once intentional/preview/felt values are excluded. Optional; do it only if you want the tidy. |

### 🟡 Tier B — Launch-blocker features (one-shot + a focused device pass).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **04** | [Settings + Account](04-settings-and-account.md) | `SettingsStore` (moves Services out of Views), real Settings page, **Delete Account edge fn + release Sign Out** | **Delete Account is a hard App Store blocker.** Delete cascade verified against the live prod FK graph. Biggest single launchward vertical. |
| **05** | [Free-tier gates](05-free-tier-gates.md) | Give `PlayStore` the entitlement read so locked decks unlock live on purchase | Deliberately small — most gating already shipped with M5/T2. Closes the "decks don't unlock until relaunch" gap + flags the `solo-prep` locked/free copy contradiction. |

### 🟠 Tier C — Core loop / Card Session (one-shot the code; MUST verify on two physical devices).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **16** | [Card sessions front-to-back](16-card-sessions-front-to-back.md) | **THE master session one-shot** — handshake + entry/lobby/airlock UI + player sync + five-mechanic RevealEngine + local living cards + builder + composition migration + the 12-deck launch catalog | Supersedes 08–11 + 15's deck authoring. Spec: `docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md`. Read its SEAM RECONCILIATION block first. Two-device proof mandatory. |
| ~~08~~ | ~~[Session realtime handshake](08-session-realtime-handshake.md)~~ | **SUPERSEDED by 16** (absorbed + updated: streams are session-id-filtered, reveal transport added) | Do not execute alongside 16. |
| ~~09~~ | ~~[Session entry + Airlock UI](09-session-entry-airlock-ui.md)~~ | **SUPERSEDED by 16** (airlock re-cut to the cover-family mockup; AppShell fix carried over) | Do not execute alongside 16. |
| ~~10~~ | ~~[Session player core](10-session-player-core.md)~~ | **SUPERSEDED by 16** (Whisper generalized into the RevealEngine; sync/timer/safe-word carried over) | Do not execute alongside 16. |
| ~~11~~ | ~~[Session builder](11-session-builder.md)~~ | **SUPERSEDED by 16** (builder emits the new `SessionPlan` struct; the SwiftData `@Model SessionPlan` is deleted) | Do not execute alongside 16. |

### 🔵 Tier D — Map / Vault (one-shot the scaffold; feel + RLS pass).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **12** | [Map dashboard + Me layer](12-map-dashboard-me-layer.md) | Finish/harden the Me dashboard; promote `LearnSegmented` → shared `VaylSegmented` | Me layer is already ~80% built → a verify-finish-harden pass. **Its Seg 3 (Me Card polish) conflicts with Plan 17 — skip Seg 3 if 17 runs first, or treat Seg 3's work as superseded if 12 already ran.** |
| **13** | [Vault: Agreements + Event Log + consent](13-vault-agreements-eventlog-consent.md) | **Deploy + verify** the already-built Vault (Swift is committed; prod is missing all 5 tables + 2 edge fns) | The consent "decline never discloses" invariant is the load-bearing, testable core. |
| **14** | [Map Us layer + Pulse partner](14-map-us-layer-and-pulse-partner.md) | Track the pulse prod-drift migration, upgrade the shared row to a 2D position, wire partner fetch | **Top open decision:** ship Me-only + honest Us empty state for V1 and defer this? |
| **17** | [Shelve the Me Card](17-shelve-me-card.md) | Remove the "Your card" identity/Flavor section from Map's Me layer — no backend, purely local | Trivial, do first among 17-20 — frees the "Forward" slot 20's Path needs. Re-verified: zero Supabase surface, no Us-card ever existed. |
| **18** | [Pulse foundations + ball feel](18-pulse-foundations-and-feel.md) | One position-mapping source of truth, position-is-the-only-color-source, drift/idle-float/silver-to-start, `.vaylSheet`→`.vaylCover` check-in, dead-code purge (6 files + `PulseTier`) | **DONE** — built 2026-07-01/02. Its own "Phase D done, no action" note is now further stale: Phase G ("PulseStore stays UserDefaults-only, out of scope") has since been superseded too — full Supabase sync (`pulse_entries`) shipped since. See Plan 21. |
| **19** | [Map Pulse integration finish](19-map-pulse-integration-finish.md) | Builds the "your map" time-window trail on the Me field sheet — the one real gap left from the 2026-06-28 mockup-vs-impl audit | Re-verified: C2/C3/S2-1/S2-2/G1 from that audit are **already fixed in code** — don't re-fix them. Depends on Plan 18 (done). **Still not built — still an open, unanswered decision** (2026-07-03: Bryan confirmed Plan 20/The Path is the separate roadmap feature; this trail is a distinct, still-open call). Independent of Plan 21. |
| **20** | [The Path (Roadmap) V1](20-the-path-roadmap-v1.md) | Greenfield: `PathNode`/`PathStore`/trail/Mission Brief, Swinging preset seeded, wired as Map's "Forward" pillar for both Me and Us | 100% unbuilt before this — zero prior Swift/Supabase symbols. Depends on Plan 17 (fills the slot it empties). Agency-ladder Rung 1 only (preset, no customize/theorycraft); straight rail, not the mockup's serpentine curve — see its Context section. |
| **21** | [Pulse finalization](21-pulse-finalization.md) | **Superseded as the primary driver** by `docs/handoffs/2026-07-03-pulse-finalization-goal.md` — kept as a reference appendix (verified-once concrete code sketches), not "the plan" | Fable/agent-driven work on remaining Pulse gaps should start from the goal/handoff doc (outcomes + a rigorous Definition of Final), which better fits an agent needing less prescriptive direction. This file's code sketches are a starting hypothesis for several of that doc's gaps, not a spec — re-verify against source first. **2026-07-03: the goal doc's A-E are all checked/built; only Bryan's on-device pass (F) remains.** |
| **22** | [Pulse teaching](22-pulse-teaching.md) | Teaching decision 3B: real `PulseInfoSheet` door (Home dormant + Map hero entry points) + a once-ever two-beat field annotation on the first check-in landing | From the decided teaching-strategy spec (`docs/superpowers/specs/2026-07-03-feature-teaching-strategy-design.md`). Land BEFORE Bryan's Pulse on-device pass so the check-in surface is verified once. 2A (Desire Map) needed no plan — already built in `DesireMapView.startScreen`. |
| **23** | [Session practice hand](23-session-practice-hand.md) | Teaching decision 1A: dealer-voiced four-beat practice overlay on a couple's first-ever session (turns, care mark/safe word, real hold-to-deal practice) | Per-device chrome ONLY — deliberately NOT a card in the shared hand (a locally-gated prepend would desync the two devices' index lockstep). Reuses `hasCompletedCoupleSession`; zero store/sync changes. Fold verification into the plan-16 two-device proof. 4B (The Path framing) lives in plan 20 Step 9, not here. |

### ⚪ Tier E — Content (Fable drafts; you edit).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **15** | [Content authoring](15-content-authoring.md) | **PARTIALLY SUPERSEDED by 16** — all deck authoring + dead-JSON deletion now lives in 16's Section 4 (12-deck bible-aligned catalog). Still live here: the desire/pulse content-lock segments only. | Run only 15's non-deck segments; the deck slate + catalog belong to 16. |

---

## Recommended critical path to launch

The roadmap's launch-blocker set is `D4, M2, M3, M5, S2, S3, S4, T3, T5, C1, C2, V1, V2, A1, A2, A3, A4`.
Mapped to these plans and sequenced finish-first:

1. **01** (clean the tree) → **02** (hardening) — a day of pure de-risking, everything downstream gets cleaner.
2. **04** (Settings + **Delete Account**, the hard App Store blocker) → **05** (gates).
3. **06** (tests — lock the money/privacy invariants before you refactor) → **07** (empty states + crash SDK).
4. **Card Session 16** (the core loop, one master pass replacing 08 → 09 → 10 → 11; budget real two-device time here).
5. **Map 12 → 13 → 14** (13 is deploy-and-verify; 14 is a scope decision).
6. **17 → 18 → 21 → 20** (Pulse + Map + The Path — 17 first to free the slot, 18 and 21 finish Pulse,
   20 after 17). **19** (the "your map" time-window trail) is independent and still an open decision —
   slot it in whenever Bryan confirms he wants it; it doesn't block or get blocked by 20/21.
7. **15** (content — the 30–50h authoring track; start early, don't compress into the final week).
8. **Then the manual work below** (V1/V2 device walks, A2 legal, A4 submit).

---

## Not a Fable plan (your work / manual — listed so nothing is lost)

These are launch-blockers that a code one-shot can't do. No plan file; tracked here for completeness:
- **D4 reveal styling/motion** — your Xcode canvas feel pass (the reveal is built + device-verified).
- **M2 server-grant verification** — sign into a real paired account, StoreKit config = None, confirm the
  `entitlements` row + `couples.access_tier = core`. (Client is built + locally verified.)
- **V1 solo path walk / V2 couple path walk** — end-to-end on device(s). Plans 01–15 remove the dead ends;
  these are the walks that prove it.
- **A2 legal** — privacy policy + ToS authoring/hosting + nutrition label. The paywall + sign-in already
  have the tappable stubs waiting for the URLs.
- **A4 assets + TestFlight + submit** — screenshots, icon audit, age rating, 3–5 day TestFlight.
- **Pulse feature** — the 2026-06-30 handoff's Phases A-G are all superseded now: **18** did A-C,
  **14**'s scope (Phase F, the couple/Us layer) shipped alongside a full Supabase backend that goes
  beyond Phase G's original "stays local" call, and **21** finishes the remaining gaps (staleness
  honesty + a sync-loop hole + one dead method). Only **19** (Phase E, the "your map" time-window
  trail) remains genuinely unbuilt and undecided.

---

## Cross-plan discoveries (real bugs + drift the agents found while verifying)

Worth acting on regardless of which plans you run — these are facts about the current tree, not proposals:

- **Legacy card-session retirement (C-2) is already done.** `HomeRouterView` has no `activeSession`,
  no session `.sheet`, no `.startSession` case; the two legacy files are gone with zero dangling refs. (01)
- **`AppShell` tab-switch is silently dead.** It uses a local `@State selectedTab` and never reads
  `appState.selectedTab`, so `HomeRouterView`'s programmatic tab switches do nothing. Fixed in 09; matters
  for any deep-link/routing. (09)
- **`PlayStore` never reads `EntitlementStore`** → locked decks don't unlock after purchase until relaunch;
  and **`solo-prep` is `is_locked: true`** in `deck-catalog.json` while paywall copy says solo decks are free. (05)
- **Pulse prod schema drift is untracked in the repo.** `pulse_shared_capacity` +
  `user_profiles.share_pulse_with_partner` exist in prod but in **no** migration — a fresh `db reset` breaks
  shipping sync code. (14)
- **The Vault is fully built in Swift but not deployed.** All 5 tables + both consent edge functions are
  committed in the repo yet **absent from prod**. (13)
- **`assessment_questions.json` and `cards.json` are dead** (zero callers) and hold the only remaining
  "clinical"/placeholder markers — deleting them makes the tree honest. Pulse questions are hardcoded in
  `PulseAnswers.swift`, not JSON. `deck-index.json` is also dead. (15)
- **Version/naming drift:** supabase-swift is **2.48.0** (roadmap said 2.41.1); `AppState.reset` is actually
  `resetOnboarding`; `saveWithLogging()` lives at `Core/Persistence/ModelContext+Extensions.swift:27`;
  `VaylCardFace` is at `Cards/` not `Cards/CardFaces/`; a live tier-name "Contracted" in `TierGuideSheet`
  diverges from the canonical `PulseQuadrant` "Friction". (02, 08, 15)
- **`HomeState` has only `.gated / .dashboard / .soloUnpaired`** — the roadmap's `waiting`/`matchReady`
  states never existed. **`notForMe` legitimately syncs** (sync-all posture); the real privacy invariant is
  the closed 5-key write DTO + the structurally alignment-only read DTO. (06)
- **Token debt is not real.** Once intentional/preview/felt values are excluded, the audit's 72 fonts /
  75 glows / 85 animations collapse to ~10 font repoints + 2 spacing swaps. Don't spend a big pass on it. (03)
- **Most of the 2026-06-28 Pulse mockup-vs-impl audit is now stale (fixed in code since).** Re-verified
  2026-07-01: the zone-palette split (C2), the gray "THE PULSE" eyebrow (C3), the missing capsule glow
  (S2-1), the fixed-44pt Us aura (S2-2), and the 17s glass-sweep cadence (G1) are **all already fixed**.
  Only the "your map" time-window trail (S1-1) is still a real gap — that's all Plan 19 builds. (18, 19)
- **The Me Card ("playing card" identity feature) has zero backend surface** — `flavor`/`chosenTitle`
  are local-only `UserProfile` columns, no migration, no Us-card ever existed (only unused
  `CoupleCrestSigil`/`CoupleCrestPortrait` scaffolding). Shelving it (Plan 17) is a pure View change. The
  design spec (`2026-06-27-couple-path-roadmap-design.md` §14) already lists this as a non-goal — Plan
  12 Seg 3 (which deepens the Me Card) is the one place that tension surfaces; see Plan 17's Open
  Decisions. (17)
- **The Path (Roadmap) is 100% unbuilt** — zero Swift symbols, zero Supabase schema, no hook in
  `MapStore`, confirmed by repo-wide grep. `GettingStartedPathView` (Home's onboarding checklist) is a
  confirmed DIFFERENT feature — same visual idiom, unrelated data. (20)
- **Pulse's backend/edit-window/partner-sync build (this session, 2026-07-01/02) landed well ahead of
  its own docs** — by the time Plan 21 was written, `PulseStore`/`MapStore`/`MapUsLayer` already had a
  full `pulse_entries` sync loop, a 2-hour edit window, and real partner-history grid pairing, none of
  which any prior plan doc described. Verified fresh against source rather than trusted from prose — a
  reminder that these docs drift fast on an actively-worked feature; re-verify before building, don't
  assume a plan's "current state" section is still accurate once time has passed. (21)

---

_Portfolio produced by 15 parallel verification agents + this index. Each plan is standalone; the shared
license + format live in `_SHARED-PREAMBLE.md`._
