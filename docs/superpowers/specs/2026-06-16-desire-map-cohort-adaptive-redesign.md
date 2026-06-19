# Desire Map — Cohort-Adaptive Redesign + Activation

**Date:** 2026-06-16
**Status:** D1–D3 + read-back BUILT (all compiled); the migration + `compute-desire-matches` edge fn are LIVE in prod (2026-06-17). D4 reveal + DA activation pending; two-phone device test pending. Supersedes the content/vocab **and privacy** portions of `2026-06-15-desire-map-implementation-spec.md`.
**Feel-proto:** `docs/prototypes/desire-rater.html` (live, canonical source for the copy; toggle Curious ↔ Established).

---

## Context

The Desire Map is Vayl's launch differentiator + primary conversion event. Mid-D1, research showed a single universal questionnaire is psychologically wrong for non-monogamy: a *curious* couple is answering aspirationally ("would we want this?") while an *established* couple is answering reflectively ("we've lived this — keep it, or change it?"). Forcing both through the same 18 questions makes some items nonsensical (an established couple can't be "excited to open up" — they already did).

So the Desire Map becomes **cohort-adaptive**: the experience-level the app already captures drives *which* questions a couple sees and *how the answers are worded* — while the stored rating stays a fixed 4-point weight so the compare engine is unaffected.

### Scope decisions (Bryan, this session)
1. **Two tracks, not three.** `exploring` + `experienced` merge into one **Established** track. Cohorts: **Curious** / **Established**.
2. **Couple-focused.** No curated solo Desire Map experience in V1 (the "Starting Point" self-knowledge doc → Expansion Atlas). Solo users get **solo cards + learning resources + a funnel to pair**.
3. **Unpaired users CAN complete the map** as a head-start hook ("invite someone to see what you share"); it becomes their half on pairing. Strongest coupling incentive.
4. **4-point scale**, the Safety-doc vocab: `excitedAboutIt / openToIt / probablyNot / notForMe`. (Privacy reframed — see "The compare + reveal model" below: `notForMe` is **not** a device-only secret; it syncs and is obscured at the compare, never withheld.)
5. **Activation = a "Getting Started" checklist** (fuller new-player pattern), couple-focused, funneling to the reveal (the paywall). Game *structure*, not game *tone* — rewards are the existing "Moments," never points/XP/badges (per the Safety doc's "therapist, not video game" rule).

---

## 1. Cohort model

- **Track signal:** `UserProfile.nmStage` (already captured in onboarding's candle phase). `.curious` → Curious track; `.exploring`/`.experienced` → Established track. No new onboarding capture; `RelationshipTenure` stays unused.
- **Couple resolution (for the compare):** if **either** partner is Curious → the couple uses the **Curious 18** (so both answer the same set and overlap fully). Only when **both** are Established → the **Established 12**. This resolution needs both partners' `nmStage`, so it lands at compare time (D3/D4). In **D1** (local rater) the track is resolved from the **local** user's own `nmStage`.
- **Invariant — weight direction is cohort-independent.** Position ①=`excitedAboutIt` … ④=`notForMe` always means the same pro→anti gradient for a given item, regardless of track wording. This is what lets a mixed-cohort couple be compared on a shared weight.
- **Invariant — item identity is shared.** `id`, `category`, `sensitivity` are cohort-neutral. Only `name`/`description` *may* differ (only item #1 does, below) and the **4 answers** differ by track.

### The compare + reveal model (revised 2026-06-17, Bryan)

The compare is a **celebration of alignment**, never a scorecard — couples never see each other's raw maps.
- **Shown:** where they align wholeheartedly + where they're **1–2 points off** ("mostly aligned").
- **Hidden:** big mismatches (gap 3, e.g. a 1 vs a 4) — not shown by default.
- **Request:** a user who wants a hidden question surfaced sends a **request**; even then the UI shows only THEIR OWN answer + the request — **never the partner's score**.
- This is the **product model, not a privacy/secrecy layer** — privacy falls out of it: RLS keeps raw rows own-profile, the edge fn writes only alignment, and the client never reads partner raw values or gaps. So `notForMe` syncs freely; it's simply never surfaced as a match.

---

## 2. Content (locked — canonical copy lives in the proto)

Answer columns are in fixed weight order: **① excitedAboutIt · ② openToIt · ③ probablyNot · ④ notForMe.**

### Curious track — 18 items (aspirational / future tense)

| id | Item | ① | ② | ③ | ④ |
|---|---|---|---|---|---|
| opening | Exploring an Open Relationship | Yes — I want to start exploring | Curious, but slowly | Just the idea for now | I'm only ready to think about it |
| swinging | Swinging or Playing Together | Yes — that excites me | I'm curious to try it | I'm nervous about it | Not for me |
| trips_apart | Taking Trips Apart | I'd love that freedom | Open to small steps first | The idea makes me anxious | I need us together for those |
| polyamory | Polyamory — Loving More Than One | This really calls to me | I'm curious about it | Probably not for me | Not for me |
| hierarchy | Our Relationship Comes First | Yes — we always come first | Mostly, with some flex | I'd rather not rank it | I don't want a hierarchy |
| emotional_connections | Emotional Connections With Others | Yes — I want that depth | I'm open to it | I'd keep it lighter | Not for me |
| nre | New Relationship Energy (NRE) | I welcome it | I can work with it | It's hard for me | I can't be okay with it |
| partner_falling_in_love | Your Partner Falling in Love | I'd be happy for them | I could grow into it | That scares me | I couldn't accept that |
| jealousy | Handling Jealousy Together | Let's face it as a team | I'll bring things to you | I tend to hide it | I'd rather deal with it alone |
| group_sexual | Group Sexual Experiences | Excited to explore | I'm curious | Probably not | Not for me |
| intimate_details | Hearing the Intimate Details of Dates | Tell me everything | The general picture | Just the essentials | I'd rather not know |
| safer_sex | Safer Sex Boundaries | Non-negotiable for me | Important to me | Somewhat flexible | I'm relaxed about it |
| overnight_stays | Overnight Stays With Others | Totally fine with me | I'm open to it | I'd prefer not | Not okay with me |
| time_attention | Time and Attention | I trust we'll balance it | We can work it out | I worry about it | This is a dealbreaker |
| finances | Joint Finances for Outside Dates | Shared money is fine | Okay, with a budget | I'd prefer separate fun money | Outside dates must be self-funded |
| reconnection | Reconnection Time After a Date | I'll want to reconnect right away | A check-in would help | I think I'll need space | Leave me alone afterward |
| metamours | Meeting Your Partner's Other Connections | I'd love to | I'm open to it | I'd keep my distance | I'd rather not |
| social_disclosure | Who Knows About Us | Fully open about it | Some people can know | Keep it very private | No one can know |

### Established track — 12 items (reflective / past tense)

Drops the "what flavor of NM are we" discovery items (an established couple has settled those); keeps the recurring maintenance/emotional/logistical ones. Item #1 is the consolidated forward/contentment question.

| id | Item | ① | ② | ③ | ④ |
|---|---|---|---|---|---|
| recalibrating | Where We Take This Next | Let's keep growing it | Happy holding where we are | I want to slow things down | I need us to de-escalate |
| nre | New Relationship Energy (NRE) | I ride it well now | I manage it with reassurance | Past NRE destabilized us | I won't go through that again |
| partner_falling_in_love | Your Partner Falling in Love | I've seen it and we're solid | Okay, with our usual support | It's been hard before | I can't do that again |
| jealousy | Handling Jealousy Together | Our teamwork carries us | I self-soothe, then share | I've learned to process alone | I expect full emotional independence |
| intimate_details | Hearing the Intimate Details of Dates | I still want the full story | High-level summaries are enough | Less detail than before | Only what affects my health |
| safer_sex | Safer Sex Boundaries | Still non-negotiable | Firm, with trusted exceptions | More flexible than we were | We're relaxed about it now |
| overnight_stays | Overnight Stays With Others | Completely comfortable | Fine with a heads-up | I've found it hard | I'd rather they didn't |
| time_attention | Time and Attention | We balance it well | Mostly good, needs tending | It's been a strain | I need more of your time back |
| finances | Joint Finances for Outside Dates | Our shared system works | Works, but let's revisit budgets | I've felt resentment about it | We need separate finances for this |
| reconnection | Reconnection Time After a Date | Our rituals ground me | I like it, don't need it | I just decompress alone now | I won't do forced rituals |
| metamours | Meeting Your Partner's Other Connections | I value knowing them | Open, case by case | I prefer more separation now | I keep metamours at arm's length |
| social_disclosure | Who Knows About Us | We're openly out | Out to our circle | More private than before | I need this kept private |

> Item descriptions are cohort-neutral (see the proto for the current copy). All items: `isFree: true`, `layer: "core"` for V1.

---

## 3. Architecture

- **`DesireItem` (new `Codable` model):** `id, name, description, category, sensitivity, sortOrder, isFree`, plus cohort answers:
  - `tracks: [String]` — which cohorts show the item (`["curious"]`, `["established"]`, or both).
  - `answers: [String: [String]]` keyed by track (`"curious"`, `"established"`) → 4 strings in weight order. (Typed `CohortAnswers` is fine too.)
- **`desire_items.json`** is restructured to this shape (Curious 18 + Established 12, sharing 11 items with two answer sets). Loaded via `ContentLoader.load(DesireItem.self, from:)`.
- **`DesireMapStore`** resolves the track from `UserProfile.nmStage`, filters items by `tracks`, renders the track's answers, and upserts one `DesireMapEntry` per `(userId, itemId)` with the chosen **weight** (`DesireRatingValue`). No Service calls (local).
- **`DesireRatingValue`** → 4 cases `excitedAboutIt/openToIt/probablyNot/notForMe`. (`isSyncable` no longer filters — ALL weights sync; see Privacy below.)
- **Sync — D2 (built):** `DesireSyncService.syncRatings` takes a `[DesireMapEntry]` snapshot and upserts ALL weights (incl. `notForMe`) on `(user_id, desire_item_id)` by profile id; also syncs `nm_stage`. Fires on completion via `SyncManager.syncDesireMap` (+ `pendingDesireSync` retry on next rater open).
- **Match edge fn — D3 (deployed):** `compute-desire-matches` (service role) marks the caller complete in `desire_map_status`, resolves the couple track from both `nm_stage` (either Curious → Curious; else Established), and on both-complete computes mutual/adjacent positives over both-rated items, EXCLUDING any item where either said `notForMe`, writing `desire_matches` with exactly one `is_free_reveal`. Stores **no raw partner values / gap** (the partner's answer never reaches the client).
- **Read-back (built):** `DesireSyncService.fetchMatches` / `fetchStatus` read `desire_matches` (safe columns only) + `desire_map_status`; `HomeStore` derives `partnerMapComplete` from `bothComplete` (waiting → match-ready).
- **DB schema (applied to prod):** `kink_ratings_rating_check` → `desire_ratings_rating_check` (4 weights); added `desire_matches.is_free_reveal`/`revealed_at` + the `desire_map_status` table + couple-scoped RLS. Applied via MCP `execute_sql` (CLI `db push` was blocked on `SUPABASE_DB_PASSWORD`); repo file `supabase/migrations/20260617000000_desire_map_backend.sql` — reconcile history with `supabase migration repair --status applied 20260617000000` when the CLI's linked.
- **Privacy (reframed):** NOT a "3-layer never leaves device." `notForMe` syncs. Privacy is the **compare model** (above) — RLS keeps raw rows own-profile, the edge fn writes only alignment, the client never reads partner raw values/gaps, and the reveal celebrates alignment + hides big gaps (request shows the user's own answer only). The "Boundaries Respected: N" counter is deferred.

---

## 4. Activation — "Getting Started" banner + a Pulse that pulls

**Philosophy (Bryan):** don't gate Home down to a chore list. Show the full dashboard from day one and make it *pull* the user in — the animated-but-empty Pulse is the carrot, a slim banner is the gentle guide. No points/XP; completions fire warm **Moments**.

**Getting Started banner.** A slim banner directly under the `Name.` / partner-chip top bar, above the daily-prompt card. Shows overall progress + the next action ("Get started · next: Map your desires →"); tapping **expands the full checklist**. Persists until the blocking steps are done, then collapses. The dashboard (prompt card, Pulse, research) renders underneath it the whole time.

Checklist steps (couple): ✓ Set up your profile (OB) · ◯ Map your desires (→ unlocks Map tab) · ◯ Invite your partner (auto-✓ if paired in OB) · 🔒 See what you share (reveal/paywall — teased-locked from the start).

**Pulse that comes alive.** Before there's data, the Pulse graph is **not** empty — it runs a **punched-up version of the real `PulseGraph.drawDemo`**: the same straight-segment EKG demo line (demo scores `[2.5,3.0,2.2,3.2,2.8,3.5]`) but **spectrum-tinted + brighter + a breathing end node**, kept **dashed** to signal "preview," drawing itself in → holding → fading → redrawing on a ~6.5s loop. Tease: "Your Pulse comes alive as you map your desires." After **~3–5 days of real data**, it's replaced by the actual 7-day trend (spectrum line + tier guides + dots, per the screenshot). The animated placeholder IS the conversion pull. **Build note:** this is a change to the real `PulseGraph.drawDemo` (today it's a faint white dashed ghost with no tint/node) — DA applies the spectrum + breathing-node treatment. *(Pulse data source — what the 7-day trend measures — is a separate decision; see `[[map_tab_direction]]`.)*

**Solo (unpaired):** no curated solo flow. Home funnels to pairing; solo cards + learning remain. The map *can* be completed and banked (head-start) — "Saved — invite someone to see what you share."

*Motion note:* the Pulse placeholder animation is a feel-before-Swift item (Build Protocol) — prototype it before writing the Swift.

---

## 5. Re-scoped build segments

The original D1–D5 still hold; the changes are: D1 content is now two-track + cohort-resolved, and a new activation segment (call it **DA**) wraps the entry. The rater is the anchor either way.

- **D1 ✅ built — Route + rebind the two-track rater.** Vocab rename (4-point) + DB CHECK migration; `DesireItem` w/ `tracks` + per-track answers; restructure `desire_items.json` (Curious 18 / Established 12); build `DesireMapStore` (resolve track from `nmStage`, upsert `DesireMapEntry`); rewrite `DesireMapView` to the proto's card rater; route from Home (reachable for unpaired users too). **Done:** open rater from Home (paired *or* solo), rate the track's items, persists to `DesireMapEntry`; toggling `nmStage` changes the set + wording. *(Compiled; two-phone device test pending.)*
- **DA — Getting Started checklist.** Make the implicit Home gate an explicit couple checklist with Moments; reuse `isTabLocked`. (Can follow D1; D1 launches from the existing gate in the interim.)
- **D2 ✅ built** — sync ALL weights (no `notForMe` filter) + `nm_stage` + offline retry. **D3 ✅ deployed** — match edge fn + couple cohort-resolution + `desire_map_status`; raw partner values not stored. **Read-back ✅ built** — fetch matches/status + wire `HomeStore.partnerMapComplete`. **D4** — reveal (celebration of alignment + request; needs the "what does a request DO" decision + a feel-proto first). **D5** — Map tab hosts the compare. **Companion-card stubs ✅** — `CompanionCard` + `CompanionCardStore` + `bridgeCardId`.

---

## 6. Verification
- **Proto:** `localhost:7333/desire-rater.html` — Curious 18 / Established 12 verified, toggle + advance + completion working, no console errors.
- **Build:** `xcodebuild` compile-verify (Claude); Bryan device-tests — open rater from Home, confirm the track matches `nmStage`, rate items, re-open to confirm `DesireMapEntry` persistence (upsert, not duplicate).
- **Migration:** re-query `pg_get_constraintdef` for the 4-weight `desire_ratings_rating_check`; `get_advisors` clean. ✅ done 2026-06-17.
- **Backend (live):** `compute-desire-matches` deployed (HTTP 401 guard confirmed). The end-to-end check (both partners rate → `desire_matches` rows appear, one `is_free_reveal`, no `notForMe` surfaced, `desire_map_status` both-complete) is the **two-phone device test** — query prod to confirm rows after.
