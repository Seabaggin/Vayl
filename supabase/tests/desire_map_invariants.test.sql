-- supabase/tests/desire_map_invariants.test.sql
--
-- pgTAP tests for the Desire Map backend invariants — the privacy + access contract
-- that RLS and the schema enforce. These are the rules a migration could silently break.
--
-- Run (local Supabase stack, which ships pgTAP + the anon/authenticated roles):
--   supabase test db
-- or directly:
--   psql "$DATABASE_URL" -f supabase/tests/desire_map_invariants.test.sql
--
-- Verified against prod (project vayl) 2026-06-26 — every assertion below reflects the
-- live schema at that time.

begin;
create extension if not exists pgtap with schema extensions;
set search_path to extensions, public;

select plan(25);

-- ── 1. The DM tables exist ───────────────────────────────────────────
select has_table('public', 'desire_ratings',         'desire_ratings exists');
select has_table('public', 'desire_matches',         'desire_matches exists');
select has_table('public', 'desire_map_status',      'desire_map_status exists');
select has_table('public', 'desire_reveal_progress', 'desire_reveal_progress exists');
select has_table('public', 'entitlements',           'entitlements exists');

-- ── 2. RLS is enabled on every DM table (no table is wide open) ───────
select ok((select relrowsecurity from pg_class where oid = 'public.desire_ratings'::regclass),
          'RLS enabled on desire_ratings');
select ok((select relrowsecurity from pg_class where oid = 'public.desire_matches'::regclass),
          'RLS enabled on desire_matches');
select ok((select relrowsecurity from pg_class where oid = 'public.desire_map_status'::regclass),
          'RLS enabled on desire_map_status');
select ok((select relrowsecurity from pg_class where oid = 'public.desire_reveal_progress'::regclass),
          'RLS enabled on desire_reveal_progress');
select ok((select relrowsecurity from pg_class where oid = 'public.entitlements'::regclass),
          'RLS enabled on entitlements');

-- ── 3. Privacy: desire_matches NEVER stores raw partner answers ──────
-- These columns were dropped in the reveal-state-collapse migration; their return
-- would re-open a partner-value leak. The read path is alignment-only.
select hasnt_column('public', 'desire_matches', 'partner_a_value', 'no partner_a_value (privacy)');
select hasnt_column('public', 'desire_matches', 'partner_b_value', 'no partner_b_value (privacy)');
select hasnt_column('public', 'desire_matches', 'gap_size',        'no gap_size (privacy)');
select has_column('public',  'desire_matches', 'alignment_level',  'alignment_level is the shared signal');
select has_column('public',  'desire_matches', 'is_free_reveal',   'is_free_reveal gates the conversion');

-- ── 4. Computed tables are service-role-write-only ───────────────────
-- The client may READ its couple's matches/status but never write them; only the
-- service-role edge function does. A write policy here would let a client forge matches
-- or flip is_free_reveal (bypassing the paywall).
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='desire_matches' and cmd <> 'SELECT'),
          0, 'desire_matches has no client write policy (service-role only)');
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='desire_map_status' and cmd <> 'SELECT'),
          0, 'desire_map_status has no client write policy (service-role only)');

-- ── 5. desire_ratings is own-only, no delete path ────────────────────
-- A partner can never read your ratings; you can insert/update your own; nobody deletes.
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='desire_ratings' and cmd='SELECT'),
          1, 'desire_ratings has exactly one (own-only) SELECT policy');
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='desire_ratings' and cmd='DELETE'),
          0, 'desire_ratings exposes no DELETE policy');

-- ── 6. desire_reveal_progress is own-only ────────────────────────────
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='desire_reveal_progress' and cmd='SELECT'),
          1, 'desire_reveal_progress has exactly one (own-only) SELECT policy');

-- ── 7. entitlements is fully sealed from clients ─────────────────────
-- The money ledger (transaction_id, purchased_by) is service-role-only: RLS on with
-- ZERO policies, and no table grants to anon/authenticated.
select is((select count(*)::int from pg_policies
           where schemaname='public' and tablename='entitlements'),
          0, 'entitlements has zero policies (clients denied all rows)');
select ok(not has_table_privilege('authenticated', 'public.entitlements', 'SELECT'),
          'authenticated cannot read entitlements');
select ok(not has_table_privilege('anon', 'public.entitlements', 'SELECT'),
          'anon cannot read entitlements');

-- ── 8. Tier resolution + rating vocabulary ───────────────────────────
select has_function('public', 'resolve_couple_access_tier', ARRAY['uuid'],
                    'resolve_couple_access_tier(uuid) exists (portable entitlement)');
select ok((select count(*) > 0 from pg_constraint
           where conrelid = 'public.desire_ratings'::regclass and contype = 'c'),
          'desire_ratings constrains the rating vocabulary (4-point weight)');

select * from finish();
rollback;
