# Desire Map — Backend Reconciliation (Supabase ↔ final flow)

**Date:** 2026-06-26
**Status:** Design approved, ready for implementation plan.
**Mockup (source of truth for the flow):** `docs/prototypes/desire-map-flow-family.html`
**Supabase project:** `vayl` / `ynhjlabjzauamntbyxdp` (ACTIVE, Postgres 17)

**Purpose:** Bring the live Supabase backend into line with the now-final Desire Map flow. This is a *reconcile-and-fix* pass, not a rebuild: the data model, RLS, and both edge functions are already real and mostly correct. This spec resolves one latent bug and four ratified decisions into the smallest coherent delta.

---

## 1. The frame

The backend is ~90% built and the privacy architecture is solid:

- `desire_ratings` — own-only RLS (a partner physically cannot read your ratings), unique `(user_id, desire_item_id)`, CHECK = the four weights.
- `compute-desire-matches` (edge fn, service-role) — marks the caller complete, resolves the couple track, and on both-complete computes positive matches over items *both* rated, excluding `notForMe` either side, picking exactly one server-set `is_free_reveal`.
- `grant-entitlement` (edge fn, service-role) — the only path that grants Core; writes the `entitlements` ledger and flips `couples.access_tier` via `recompute_couple_entitlement`. One purchase covers both partners.
- `desire_matches` / `desire_map_status` — couple-read RLS, no client write.

The four answer weights are **not** changing. `DesireRatingValue` = `excitedAboutIt`, `openToIt`, `probablyNot`, `notForMe`, matching the `desire_ratings.rating` CHECK. The mockup is being corrected to show four pills, not three.

## 2. The latent bug this pass fixes

Three columns are **read by the app for real logic but never written to a meaningful value**:

| Column | Read by | Written `true` by |
|---|---|---|
| `desire_map_status.full_reveal_unlocked` | `HomeStore.swift:222` → `revealDone` | nobody (compute fn only re-preserves the old value) |
| `desire_matches.revealed_at` → `isRevealed` | `MapStore.swift:193,246`, `VaultStore.swift:73` | nobody (compute fn writes `null`) |
| `couples.matches_revealed` | `Couple.swift` model | nobody (only ever set `false` in create-pair / rapid-task) |

Consequence today: a couple buys Core, `grant-entitlement` correctly flips `access_tier = core`, but Home's `revealDone`, the Map "Us" align layer, and the Vault all read different flags that stay frozen at `false`. **Unlock works at the entitlement layer and is invisible everywhere else.**

`DesireRevealStore` already does it the right way: `isLocked = !entitlements.isCore && !isFreeReveal` (DesireRevealStore.swift:86). This pass makes every other read site follow that same proven pattern.

## 3. The model: two sources of truth, everything else derives

- **Unlocked?** → `couples.access_tier == 'core'` (sole writer: `grant-entitlement`). Surfaced client-side as `EntitlementStore.isCore`.
- **Both finished?** → `desire_map_status.partner_a_complete && partner_b_complete` (sole writer: `compute-desire-matches`).

**The single shown/locked rule, used everywhere:**

```
shown  = isCore || isFreeReveal
locked = !isCore && !isFreeReveal
```

`revealDone` (Home) = `isCore`. No per-match `revealed_at`, no `full_reveal_unlocked` mirror, no `matches_revealed`. The free match is always visible (the proof); the rest reveal on Core.

## 4. Ratified decisions (2026-06-26)

1. **Match tiers — show both, distinctly.** Keep computing `mutual` (both Excited) and `adjacent` (E+O / O+O). The reveal/Map render the tier distinction. No backend change: the read path already returns `alignment_level`. (Mockup needs the visual tier treatment added — Bryan's domain.)
2. **Name gating — soft (client blur).** The read path keeps returning `desire_item_id` for every match; the client blurs locked names. Acceptable for a $24.99 one-time; no server change.
3. **Partner-finished signal — poll on foreground (V1).** The app re-fetches `desire_map_status` on foreground / Map open; the one quiet banner fires client-side when the partner's flag flips. No DB trigger, no push infra.
4. **Privacy — ratify "syncs, obscured" + drop vestigial columns.** `notForMe` does sync to `desire_ratings` (RLS protects it; the edge fn excludes it from matches). Fix the stale "never leaves device" comment, and drop the never-populated partner-raw / gap columns so the guarantee is *structural*.

## 5. The delta

### 5.1 Migration (new: `supabase/migrations/20260626000000_desire_map_reveal_state_collapse.sql`)

Forward-only. All dropped columns are dead or vestigial (`desire_matches` has 0 rows; the flags never flip true), so there is no meaningful data loss.

```sql
begin;

-- desire_matches: drop vestigial partner-raw + gap (privacy now structural) and dead revealed_at
alter table public.desire_matches
  drop column if exists partner_a_value,
  drop column if exists partner_b_value,
  drop column if exists gap_size,
  drop column if exists revealed_at;

-- desire_map_status: drop dead unlock mirror (derive from couples.access_tier / core_unlocked_at)
alter table public.desire_map_status
  drop column if exists full_reveal_unlocked,
  drop column if exists full_reveal_at;

-- couples: drop dead matches_revealed (redundant with access_tier)
alter table public.couples
  drop column if exists matches_revealed;

commit;
```

After applying, run `get_advisors(security)` + `get_advisors(performance)` to confirm no policy/view/trigger referenced the dropped columns.

### 5.2 Edge function `compute-desire-matches`

- Remove `full_reveal_unlocked` and `full_reveal_at` from the `status` object + upsert (currently index.ts:103-104). Keep `couple_id`, `track`, `partner_a/b_complete`, `partner_a/b_completed_at`, `waiting_state_since`.
- Remove `partner_a_value`, `partner_b_value`, `gap_size`, `revealed_at` from the match `rows.push` object (currently index.ts:144-149). Keep `couple_id`, `desire_item_id`, `alignment_level`, `bridge_card_id`, `is_free_reveal`, `created_at`.
- Keep both tiers and the one-mutual-preferred free-reveal pick unchanged.
- **Re-rating now self-heals:** because unlock lives on the couple, the existing delete+insert recompute can no longer wipe unlock state. No special preserve logic needed (resolves the old "re-rating wipes reveal" concern).

### 5.3 Edge functions `create-pair` + `rapid-task`

- Remove `matches_revealed: false` from the `couples` insert in each (create-pair/index.ts:100, rapid-task/index.ts:95).

### 5.4 Swift rewire

All edits replace dead-flag reads with the §3 rule.

- **`DesireSyncService.swift`**
  - `fetchMatches` select: drop `revealed_at` (line 185).
  - `DesireMatchRow`: drop `revealedAt`, `isRevealed` (lines 209, 217, 222).
  - `fetchStatus` select: drop `full_reveal_unlocked` (line 195).
  - `DesireMapStatusRow`: drop `fullRevealUnlocked` (lines 230, 236).
  - `SupabaseDesireMatch` DTO: drop `partnerAValue`/`partnerBValue`/`gapSize` (lines 80-93). If the struct has no remaining caller, delete it.
- **`DesireMatch.swift`** (local @Model): drop `revealedAt` + `isRevealed` (lines 38, 54, 60-62). Keep `isFreeReveal`, `matchType`, `bridgeCardId`.
- **Server→local match sync** (wherever `DesireMatchRow` maps into the local `DesireMatch` @Model): drop the `revealedAt` mapping. (Touch point to locate during planning.)
- **`HomeStore.swift:222`**: `revealDone = status.fullRevealUnlocked` → `revealDone = entitlements.isCore` (ensure `HomeStore` can read `EntitlementStore.isCore`).
- **`MapStore.swift`** `drawnTags` (line 193) + `loadUs` (line 246): replace `m.isRevealed` with the §3 rule (`shown = isCore || m.isFreeReveal`). `drawnTags` is `static` and takes `context`; thread `isCore` in. `loadUs` resolves `isCore` from the entitlement layer.
- **`VaultStore.swift:73`**: same substitution.
- **`Couple.swift`**: drop `matchesRevealed` (lines 39, 81).
- **`AppDesireEnums.swift`**: rewrite the `DesireRatingValue` doc comment from "notForMe NEVER leaves the device, 3-layer enforcement" to the accurate posture: all four weights sync to `desire_ratings`; `notForMe` is protected by own-only RLS and excluded from `desire_matches` by the edge fn (obscured at the match layer, not withheld at upload).

## 6. What is explicitly NOT changing

- The four answer weights and the `desire_ratings` CHECK / unique key / RLS.
- The match computation (both tiers, `notForMe` exclusion, one server-set free reveal).
- Couple-level entitlement, `access_tier`, `grant-entitlement`, `recompute_couple_entitlement` ("covers both, Alex pays nothing").
- The soft name-gate, foreground polling, and the tier distinction (all already supported or client-only).
- `desire_map_status.waiting_state_since` stays (it powers the 7-day waiting timer in `DesireRating.swift`). **Flag, separate from this delta:** the mockup says "no rush, no race," so confirm whether a countdown nudge still belongs against the humility principle. Not resolved here.

## 7. Out of scope (later segments)

- `bridge_card_id` population + the "tap any star to talk about it" discussion tool (Segment 3).
- Vault hosting UI for the unlocked map (Segment 3).
- Realtime / APNs upgrade of the partner-finished signal (post-V1; polling ships first).

## 8. Risk + verification

- **Destructive migration, but safe:** dropped columns are never-written; row counts are 0 (`desire_matches`) and 1 (`desire_map_status`, `couples`). `drop column if exists` is idempotent.
- **No RLS dependency:** the pulled policies key off couple membership, not the dropped columns. Re-check with advisors post-apply.
- **Edge fn redeploy** required for `compute-desire-matches`, `create-pair`, `rapid-task`.
- **Done = on-device proof, not compile:** with the rewire, after a couple completes both maps and clears the paywall (admin-grant path until M2), Home `revealDone`, the Map "Us" layer, and the Vault must all show the shared desires. Per the build protocol, Bryan confirms the felt result on device.

## 9. Reference

- Handoff: `docs/handoffs/2026-06-25-desire-map-implementation-handoff.md`
- Reveal/paywall: `docs/superpowers/specs/2026-06-24-desire-reveal-segment1-build.md`
- Monetization: memory `monetization_m1_backend_built`, `monetization_paywall_spec`
- Security posture: memory `supabase_security_posture` (entitlements service-role-only)
