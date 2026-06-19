# Desire Map — Implementation Spec

**Date:** 2026-06-15
**Phase:** 2 of 6 — "the magic moment" (Build Playbook: `docs/roadmap/vayl-build-roadmap.html`)
**Status:** Model layer real and well-designed. UI unrouted, sync uncalled, no match edge function, Map tab is a stub. Not started.
**Goal:** The launch differentiator works end-to-end — rate desires → sync → compute match → reveal vs partner (couple-symmetric for V1).

> **Fresh chat:** self-contained. `CLAUDE.md` + `MEMORY.md` auto-load. The monetization gate for the reveal lives in the **Monetization** spec (M5) — this spec builds the reveal *mechanic*; M5 gates it. Verify prod claims before acting.

---

## Why this matters most

Per `[[v1_strategic_positioning]]`, couple richness **is** the Desire Map, and per `[[monetization_paywall_spec]]` the reveal is the **primary conversion event** (1 free match → paywall the rest). It cannot be copied by any other app because it requires both partners to have completed the assessment. So this phase is simultaneously the product's emotional peak and its main revenue driver.

---

## Current state — the model layer is FAR more built than it looks

The build assessment under-reported this. The **correct, well-architected model layer already exists** (dated ~5/22–6/xx). The work is wiring, an edge function, the reveal UI, and a schema/vocab reconciliation — not modeling from scratch.

**Already built (good):**
- [`DesireMapEntry`](../../../Vayl/Core/Models/DesireRating.swift) — `@Model`, one person's private rating: `userId` (PRIVATE, never crosses), `itemId` (one of 17), `rating: DesireRatingValue`, `completedAt`. `isSyncable` returns false for `notForUs` (never leaves device). **This replaces the old `DesireRating`** (the file still declares a `DesireRating` *stub* — delete once `DesireMapEntry` is wired).
- `DesireMapStatus` (same file) — per-**couple** completion: `partnerAComplete/BComplete`, `fullRevealUnlocked`, `fullRevealAt`, **`waitingStateSince`** (scaffolding for the deferred 7-day timer). `bothComplete` / `waitingForPartner` computed.
- [`DesireMatch`](../../../Vayl/Core/Models/DesireMatch.swift) — `@Model`, computed by edge function only: `coupleId`, `itemId`, `matchType` (mutual/adjacent), **`isFreeReveal`** (server-authoritative — client cannot set true, or the paywall is bypassed), `revealedAt` (nil until paywall cleared).
- [`AppDesireEnums`](../../../Vayl/Core/Models/Enums/AppDesireEnums.swift) — `DesireRatingValue` (yes/curious/notForUs), `DesireMatchType` (mutual/adjacent), and the rich `DesireMapState` machine (hidden/gated/yourTurn/youDone/waiting/bothReady/freeRevealSeen/matchReady/redoInProgress/revealed/fullyUnlocked).
- [`DesireSyncService`](../../../Vayl/Core/Services/DesireSyncService.swift) — `syncRatings(_:authId:)` is written **correctly**: resolves the PROFILE id via `ProfileService.ensureProfileExists`, maps to `SupabaseDesireRating` (`user_id = profileId`), batch-inserts to `desire_ratings`. BUT it takes the stub `DesireRating` type and **has zero callers**.

**Stubbed / missing:**
- `DesireMapView` is unrouted (`onStartMap` is a comment stub in `HomeRouterView`) and uses a **hardcoded 12-item placeholder** saving to the generic `RatingRecord`/`DataStore` — bypassing `DesireMapEntry` entirely. `DesireMapStore.swift` is ~7 empty lines.
- **No match-computation edge function** exists (`supabase/functions/` has only create-pair / lookup-code / rapid-task).
- **No reveal / compare UI** anywhere; `DesireMapState` is defined but nothing renders it.
- **Map tab = stub** — `MapView` just renders `PairingSettingsView` ("temporary P2 test harness"). `PrismView` is an unrelated Home widget with mock data, not the compare surface.

**Content:** `desire_items.json` = **17 items** (all `isFree: true`); `assessment_questions.json` = 20 (some placeholder-flagged). Both are loaded by `ContentLoader.loadDesireItems/loadAssessmentQuestions` — which currently have **no callers**.

---

## 🐞 Two reconciliations that block the data flow

1. **Rating-vocab mismatch (hard blocker for D2).** Swift `DesireRatingValue` = `yes` / `curious` / `notForUs`. The **live** `desire_ratings.rating` CHECK constraint = `['love','curious','neutral','hardNo']` (an older vocab). Syncing `rating:"yes"` will **violate the constraint and fail the insert**. Fix: update the DB CHECK to the synced vocab (`yes`, `curious` — `notForUs` never syncs) in the P5/baseline migration before D2. Pick ONE vocab and make Swift + DB + content agree.
2. **No server home for couple completion/reveal state.** `DesireMapStatus` is local SwiftData only — there is no `desire_map_status` table, and `couples` has only `matches_revealed`. The reveal flow needs both partners to read `partnerXComplete` + reveal state, so D3/D4 need a server table (`desire_map_status`) or columns on `couples`. Decide and add in D3.

---

## Target data shape (live + to-build)

Live tables (verified 2026-06-15): `desire_ratings` (id, user_id→profiles.id, desire_item_id, rating [CHECK — see bug #1], created_at) and `desire_matches` (id, couple_id, desire_item_id, alignment_level, partner_a_value, partner_b_value, gap_size, bridge_card_id, created_at). RLS: `desire_ratings` has a correct own-profile policy (+ duplicate wrong ones to drop in P5); `desire_matches` has a correct couple-read policy (+ wrong `auth.uid()` ones to drop). **Reads work today; the duplicates are noise.**

To build: a `desire_map_status` table (per couple) OR completion/reveal columns on `couples`; the match-computation edge function that writes `desire_matches` and sets exactly one `isFreeReveal = true`.

---

## The privacy model (non-negotiable — `notForUs` 3-layer enforcement)

`notForUs` is the most sensitive value in the app. All three must hold:
1. **Swift:** `notForUs` is never in a sync payload (`DesireMapEntry.isSyncable == false` → filter before building the DTO).
2. **Edge function:** filters `notForUs` before writing `desire_matches` (a `notForUs` combination never produces a match).
3. **Supabase RLS:** a partner can never query the other's raw ratings — `desire_ratings` SELECT is own-profile only (already correct). Individual ratings never cross to the partner; only computed `desire_matches` (positives) are shared.

---

## Segments

| # | Does (one thing) | Done — on device | May not touch |
|---|---|---|---|
| **D1** | Route + rebind the rater to `DesireMapEntry` + `desire_items.json` (17); reconcile rating vocab | Rater reachable from Home; rates real items; saves to `DesireMapEntry` | sync, edge fn, reveal |
| **D2** | Wire `DesireSyncService` (switch to `DesireMapEntry`, filter `isSyncable`, call on completion) | A user's `yes/curious` ratings appear in prod `desire_ratings`, couple-scoped | reveal UI, edge fn |
| **D3** | Match edge function + couple completion/reveal store | Both rated → `desire_matches` rows appear; exactly one `isFreeReveal` | reveal UI |
| **D4** | Reveal / compare UI — couple-symmetric magic moment | Two rated partners → reveal feels like a moment; 1 free match, rest gated (M5) | edge fn, Map tab |
| **D5** | Map tab houses the compare (replace `PairingSettingsView` stub) | Map tab shows the couple's desire map + reveal entry | reveal mechanic |

### D1 — Route + rebind rater
Move data access out of the View (Store layer), point it at `DesireMapEntry` and the real `desire_items.json` (17), route `onStartMap` (`HomeRouterView`) to it. Reconcile the rating vocab (bug #1) so the UI's options match Swift + DB. Delete the `RatingRecord` placeholder path and the `DesireRating` stub once `DesireMapEntry` compiles in.
**Files:** `DesireMapView.swift`, `DesireMapStore.swift` (build it out), `HomeRouterView.swift` (route), `ContentLoader.loadDesireItems` (call it).
**Done:** open the rater from Home, rate 17 real items, ratings persist to `DesireMapEntry`.

### D2 — Wire sync
Change `DesireSyncService.syncRatings` to accept `[DesireMapEntry]`, filter `isSyncable` (drop `notForUs`), then its existing profile-id + batch-insert logic is correct. Call it on rate-completion (Store), with offline-retry via `SyncManager` (mirror the profile-sync pattern). **Prereq: vocab fix (bug #1)** or the insert 400s on the CHECK constraint.
**Done:** a user's `yes`/`curious` ratings land in prod `desire_ratings` with `user_id` = profile id.

### D3 — Match edge function + completion store
New `supabase/functions/compute-desire-matches` (service role): when both partners' ratings exist, compute positives (mutual = both yes; adjacent = one yes + one curious), **exclude any `notForUs`**, write `desire_matches`, and set exactly **one** `isFreeReveal = true` (the free match). Add a `desire_map_status` table (or `couples` columns) for `partnerXComplete` + `fullRevealUnlocked` + `fullRevealAt` so both partners can read completion/reveal state. Define the trigger (recommend: on second partner's completion).
**Done:** both rated → `desire_matches` populated; one free-reveal flagged; completion state readable by both.

### D4 — Reveal / compare UI (couple-symmetric)
Build the reveal from `desire_matches` driving the `DesireMapState` machine (yourTurn → waiting → bothReady → revealed). **Couple-symmetric only:** both free → both see the 1 free match → one buys (Monetization M5) → both unlock all. **Prototype the motion first** (Build Protocol: feel before Swift) — held-breath unveil, spectrum prism, never a table of rows. The asymmetric Option-C waiting/7-day/nudge is **deferred** (Monetization M6) — but note the model already scaffolds it (`DesireMapStatus.waitingStateSince`), so don't delete that.
**Done:** two rated partners trigger a reveal that lands emotionally; 1 free match visible, rest blurred pending M5.

### D5 — Map tab
Replace `MapView`'s `PairingSettingsView` stub with the real couples surface that hosts D4's reveal + the ongoing desire map. Compose D4 — don't duplicate reveal logic. (`PrismView` is unrelated Home chrome — leave it.)
**Done:** Map tab shows the couple's desire map + entry to the reveal.

---

## Open questions (Bryan decides)
- **Vocab:** final rating set — `yes/curious/notForUs` (Swift, recommended) and update the DB CHECK to match? Confirm `desire_items.json` uses the same.
- **D3 trigger:** compute on the second partner's completion, or on an explicit "reveal" tap?
- **D3 store:** `desire_map_status` table vs columns on `couples`?
- **D4 visual:** side-by-side / blended prism / progressive unveil? (needs a feel reference)
- **D4 partial:** does compare require BOTH complete, or show a partial/waiting state for one-done?
- **Content:** are the 17 desire items + 20 assessment questions final? Gendered / NM-flavor variants for V1?
- **Map tab:** what else lives there beyond the compare (shared agreements, session history, safe word)?

## Architecture contracts (from CLAUDE.md)
- Data access moves to `DesireMapStore` (Store) — the View only renders + forwards taps. No View → Service/DB.
- Matches are computed **server-side only** (`isFreeReveal` never client-set).
- `notForUs` 3-layer privacy (above) holds at all times.
- Reveal surfaces use void + spectrum + glass tokens; press-state + haptic on taps; `.ambientAnimation()` on loops; Reduce Motion fallbacks.

## References
- Playbook cards D1–D5: `docs/roadmap/vayl-build-roadmap.html`
- Monetization gate: `docs/superpowers/specs/2026-06-15-monetization-implementation-spec.md` (M5)
- Memory: `[[monetization_paywall_spec]]`, `[[v1_strategic_positioning]]`
- Models: `Vayl/Core/Models/DesireRating.swift` (DesireMapEntry + DesireMapStatus), `DesireMatch.swift`, `Enums/AppDesireEnums.swift`; service `DesireSyncService.swift`; content `Vayl/Resources/Content/desire_items.json` (17), `assessment_questions.json` (20).

## How to execute (fresh chat)
"Work Desire Map Segment D1 from `docs/superpowers/specs/2026-06-15-desire-map-implementation-spec.md`. Read the segment + named files, verify prod, fix the rating-vocab mismatch first, confirm scope per the Build Protocol, answer the open questions with me, build to the done-condition, update playbook status + log decisions."
