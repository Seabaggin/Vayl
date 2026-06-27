# Backend tests — Desire Map

Two layers cover the DM backend. Neither runs in CI yet; both run locally.

## 1. Edge-function logic (Deno)

Pure match logic extracted to `functions/compute-desire-matches/match-logic.ts`
(`index.ts` imports it, so there is one source of truth). Tests the positive-match
rule, the `notForMe` exclusion, alignment-only output, and the single free reveal.

```sh
deno test supabase/functions/compute-desire-matches/match-logic.test.ts
```

## 2. RLS + schema invariants (pgTAP)

`tests/desire_map_invariants.test.sql` asserts the privacy + access contract that RLS
and the schema enforce: RLS on every DM table, no raw partner-value columns on
`desire_matches`, service-role-only writes to computed tables, own-only `desire_ratings`,
and the fully-sealed `entitlements` ledger.

Requires the local Supabase stack (it ships pgTAP and the `anon` / `authenticated` roles):

```sh
supabase start
supabase test db          # runs every *.test.sql under supabase/tests/
```

Or against any database directly:

```sh
psql "$DATABASE_URL" -f supabase/tests/desire_map_invariants.test.sql
```

> Verified green against prod (project `vayl`) on 2026-06-26. The assertions mirror the
> live schema as of that date; update them alongside any DM migration.
