# Backend tests — Desire Map

Two layers cover the DM backend. Neither runs in CI yet; both run locally.

## 1. Edge-function logic (Deno)

Pure match logic extracted to `functions/compute-desire-matches/match-logic.ts`
(`index.ts` imports it, so there is one source of truth). Tests the positive-match
rule, the `notForMe` exclusion, alignment-only output, and the single free reveal.

```sh
deno test supabase/functions/compute-desire-matches/match-logic.test.ts
```

## 2. RLS + schema invariants + integration (pgTAP)

Two files, both run by `supabase test db`:

- **`desire_map_invariants.test.sql`** (structural, 25 assertions) — the privacy + access
  contract that RLS and the schema enforce: RLS on every DM table, no raw partner-value columns
  on `desire_matches`, service-role-only writes to computed tables, own-only `desire_ratings`,
  and the fully-sealed `entitlements` ledger.
- **`desire_map_integration.test.sql`** (behavioral, 13 assertions) — seeds two real linked
  accounts + an outsider with real ratings, then queries the DB AS each user (via the
  `request.jwt.claim.sub` GUC + `role authenticated`) to prove RLS actually BLOCKS a
  cross-partner read, not just that a policy exists. Runs in a transaction that rolls back and
  uses synthetic identities, so it never touches a real account. Local stack only.

Requires the local Supabase stack (it ships pgTAP and the `anon` / `authenticated` roles):

```sh
supabase start
supabase test db          # runs every *.test.sql under supabase/tests/  → 38 tests, PASS
supabase stop             # when done
```

> Invariants verified green against prod (project `vayl`) 2026-06-26; integration verified
> green on the local stack 2026-06-26. NOTE: prod has drifted from migrations (see the
> backend-reconciliation spec) — e.g. `user_profiles.share_pulse_with_partner` exists in prod
> but not in the migrations. The integration test targets the migration schema (the local DB).
