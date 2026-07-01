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
| **08** | [Session realtime handshake](08-session-realtime-handshake.md) | Dedicated `AirlockStore` + Supabase Realtime presence/postgres-changes + poll fallback | **Highest-risk segment.** Realtime is new to this stack. Build-green ≠ done; two-device proof is mandatory. |
| **09** | [Session entry + Airlock UI](09-session-entry-airlock-ui.md) | Home/Deck entry + joiner banner + `SessionLobbyView`; fixes the dead `AppShell` tab wiring | Depends on 08 for real presence. |
| **10** | [Session player core](10-session-player-core.md) | Consumer-side sync coordinator, synced timer, Whisper reveal, safe-word/pause/keep-awake | `startRemoteSync()` is a TODO stub today. Whisper answers cross via Broadcast only, never persisted. Depends on 08+09. |
| **11** | [Session builder](11-session-builder.md) | `SessionBuilderStore/View` producing real `SessionPlan`s; fast paths | Mostly single-device → **the most one-shottable of the four.** Zero transport/Player edits. |

### 🔵 Tier D — Map / Vault (one-shot the scaffold; feel + RLS pass).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **12** | [Map dashboard + Me layer](12-map-dashboard-me-layer.md) | Finish/harden the Me dashboard; promote `LearnSegmented` → shared `VaylSegmented` | Me layer is already ~80% built → a verify-finish-harden pass. Includes an "Explorer Type" → "Your card" product-principle fix. |
| **13** | [Vault: Agreements + Event Log + consent](13-vault-agreements-eventlog-consent.md) | **Deploy + verify** the already-built Vault (Swift is committed; prod is missing all 5 tables + 2 edge fns) | The consent "decline never discloses" invariant is the load-bearing, testable core. |
| **14** | [Map Us layer + Pulse partner](14-map-us-layer-and-pulse-partner.md) | Track the pulse prod-drift migration, upgrade the shared row to a 2D position, wire partner fetch | **Top open decision:** ship Me-only + honest Us empty state for V1 and defer this? |

### ⚪ Tier E — Content (Fable drafts; you edit).
| # | Plan | What it does | Notes |
|---|---|---|---|
| **15** | [Content authoring](15-content-authoring.md) | Draft the launch deck set (2 decks drafted in full), lock desire/pulse content, delete dead placeholder JSON | 13 of 16 decks are 1-card stubs today. Retires the dead `assessment_questions.json` + `cards.json` "clinical" placeholders. |

---

## Recommended critical path to launch

The roadmap's launch-blocker set is `D4, M2, M3, M5, S2, S3, S4, T3, T5, C1, C2, V1, V2, A1, A2, A3, A4`.
Mapped to these plans and sequenced finish-first:

1. **01** (clean the tree) → **02** (hardening) — a day of pure de-risking, everything downstream gets cleaner.
2. **04** (Settings + **Delete Account**, the hard App Store blocker) → **05** (gates).
3. **06** (tests — lock the money/privacy invariants before you refactor) → **07** (empty states + crash SDK).
4. **Card Session 08 → 09 → 10 → 11** (the core loop; budget real two-device time here).
5. **Map 12 → 13 → 14** (13 is deploy-and-verify; 14 is a scope decision).
6. **15** (content — the 30–50h authoring track; start early, don't compress into the final week).
7. **Then the manual work below** (V1/V2 device walks, A2 legal, A4 submit).

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
- **Pulse feature** — already has its own one-shot plan: `docs/handoffs/2026-06-30-pulse-audit-and-one-shot-plan.md`
  (Phases A–G). Plan **14** here is its Phase F (the couple/Us layer). Keep them consistent.

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

---

_Portfolio produced by 15 parallel verification agents + this index. Each plan is standalone; the shared
license + format live in `_SHARED-PREAMBLE.md`._
