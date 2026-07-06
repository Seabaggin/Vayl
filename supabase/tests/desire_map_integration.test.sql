-- supabase/tests/desire_map_integration.test.sql
--
-- INTEGRATION test for the Desire Map privacy + access model. Unlike the unit tests (which
-- mock the seam) and the invariants test (which checks that policies EXIST), this seeds two
-- real linked accounts + an outsider, then queries the database AS each user — proving the RLS
-- boundary actually BLOCKS a cross-partner read, on realistic two-partner data.
--
-- Runs on the LOCAL stack only, inside a transaction that ROLLS BACK — it creates throwaway
-- synthetic users and never touches prod or any real account:
--   supabase start && supabase test db
--
-- Impersonation: auth.uid() reads the `request.jwt.claim.sub` GUC, so we set that + `role
-- authenticated` to become a given user, capture what they can see into test.* GUCs (which
-- survive `reset role` within the txn), then assert as superuser at the end.

begin;
create extension if not exists pgtap with schema extensions;
set search_path to extensions, public;

-- ── Synthetic identities (no FK to auth.users, so plain UUIDs are fine) ──
--   A + B are a linked couple; C is an unrelated outsider. Fixed UUIDs throughout:
--     auth_a a0a0a0a0-…  prof_a a1a1a1a1-…
--     auth_b b0b0b0b0-…  prof_b b1b1b1b1-…
--     auth_c c0c0c0c0-…  prof_c c1c1c1c1-…   couple c0117e00-…

-- ── Seed (as superuser — bypasses RLS) ─────────────────────────────────
-- Disable FK triggers ONLY while seeding so we needn't populate Supabase's internal
-- auth.users (synthetic identities). Reset to 'origin' before any impersonation, so RLS is
-- fully enforced for the reads that matter.
set local session_replication_role = 'replica';

insert into public.user_profiles (id, auth_id) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'a0a0a0a0-0000-0000-0000-000000000001'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'b0b0b0b0-0000-0000-0000-000000000002'),
  ('c1c1c1c1-0000-0000-0000-000000000003', 'c0c0c0c0-0000-0000-0000-000000000003');

insert into public.couples (id, user_a, user_b, access_tier, is_founding_member) values
  ('c0117e00-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001', 'b1b1b1b1-0000-0000-0000-000000000002', 'free', false);

-- Both partners' raw ratings (4 items each). Expected compute result:
--   item_1  E + E  → mutual    (the free reveal)
--   item_2  E + O  → adjacent
--   item_3  notForMe + E → EXCLUDED (boundary, never surfaced)
--   item_4  O + probablyNot → no match
insert into public.desire_ratings (user_id, desire_item_id, rating) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'item_1', 'excitedAboutIt'),
  ('a1a1a1a1-0000-0000-0000-000000000001', 'item_2', 'excitedAboutIt'),
  ('a1a1a1a1-0000-0000-0000-000000000001', 'item_3', 'notForMe'),
  ('a1a1a1a1-0000-0000-0000-000000000001', 'item_4', 'openToIt'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'item_1', 'excitedAboutIt'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'item_2', 'openToIt'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'item_3', 'excitedAboutIt'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'item_4', 'probablyNot');

-- Computed matches as the edge function would write them (alignment-only; one free reveal).
-- The compute MATH is covered by the Deno tests; here we seed its output to test the read path.
insert into public.desire_matches (couple_id, desire_item_id, alignment_level, is_free_reveal) values
  ('c0117e00-0000-0000-0000-000000000001', 'item_1', 'mutual',   true),
  ('c0117e00-0000-0000-0000-000000000001', 'item_2', 'adjacent', false);

set local session_replication_role = 'origin';   -- FK + trigger enforcement back ON

-- ── Capture what each user can SEE (queries run under RLS as that user) ──

-- Partner A
select set_config('request.jwt.claim.sub', 'a0a0a0a0-0000-0000-0000-000000000001', true);
set local role authenticated;
select set_config('test.a_own',        (select count(*)::text from public.desire_ratings where user_id='a1a1a1a1-0000-0000-0000-000000000001'), true);
select set_config('test.a_own_nfm',    (select count(*)::text from public.desire_ratings where user_id='a1a1a1a1-0000-0000-0000-000000000001' and rating='notForMe'), true);
select set_config('test.a_sees_b',     (select count(*)::text from public.desire_ratings where user_id='b1b1b1b1-0000-0000-0000-000000000002'), true);
select set_config('test.a_matches',    (select count(*)::text from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001'), true);
select set_config('test.a_match_nfm',  (select count(*)::text from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001' and desire_item_id='item_3'), true);
reset role;

-- Partner B
select set_config('request.jwt.claim.sub', 'b0b0b0b0-0000-0000-0000-000000000002', true);
set local role authenticated;
select set_config('test.b_own',     (select count(*)::text from public.desire_ratings where user_id='b1b1b1b1-0000-0000-0000-000000000002'), true);
select set_config('test.b_sees_a',  (select count(*)::text from public.desire_ratings where user_id='a1a1a1a1-0000-0000-0000-000000000001'), true);
select set_config('test.b_matches', (select count(*)::text from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001'), true);
reset role;

-- Outsider C (unrelated, not in the couple)
select set_config('request.jwt.claim.sub', 'c0c0c0c0-0000-0000-0000-000000000003', true);
set local role authenticated;
select set_config('test.c_matches',      (select count(*)::text from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001'), true);
select set_config('test.c_sees_ratings', (select count(*)::text from public.desire_ratings where user_id in ('a1a1a1a1-0000-0000-0000-000000000001','b1b1b1b1-0000-0000-0000-000000000002')), true);
reset role;

-- ── Assert (as superuser) ──────────────────────────────────────────────
select plan(13);

-- Each partner sees their OWN ratings (incl. their own notForMe — visible to self, not withheld)
select is(current_setting('test.a_own')::bigint,     4::bigint, 'Partner A sees their own 4 ratings');
select is(current_setting('test.a_own_nfm')::bigint, 1::bigint, 'Partner A sees their own notForMe rating (self only)');
select is(current_setting('test.b_own')::bigint,     4::bigint, 'Partner B sees their own 4 ratings');

-- The privacy crown jewel: neither partner can read the other's raw ratings
select is(current_setting('test.a_sees_b')::bigint, 0::bigint, 'Partner A CANNOT read partner B raw ratings (RLS blocks it)');
select is(current_setting('test.b_sees_a')::bigint, 0::bigint, 'Partner B CANNOT read partner A raw ratings (RLS blocks it)');

-- Both partners see the SAME couple-shared matches; the notForMe item never appears
select is(current_setting('test.a_matches')::bigint,   2::bigint, 'Partner A sees the couple''s 2 matches');
select is(current_setting('test.b_matches')::bigint,   2::bigint, 'Partner B sees the same 2 matches (couple-shared)');
select is(current_setting('test.a_match_nfm')::bigint, 0::bigint, 'The notForMe item is never surfaced as a match');

-- An outsider sees nothing of this couple
select is(current_setting('test.c_matches')::bigint,      0::bigint, 'Outsider sees NONE of the couple''s matches (couple-scoped)');
select is(current_setting('test.c_sees_ratings')::bigint, 0::bigint, 'Outsider sees NONE of either partner''s ratings');

-- Stored shape (superuser view): alignment-only, exactly one free reveal, the mutual
select is((select count(*) from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001' and is_free_reveal),
          1::bigint, 'Exactly one match is the free reveal');
select is((select alignment_level from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001' and is_free_reveal),
          'mutual', 'The free reveal is the mutual match');
select ok((select bool_and(alignment_level in ('mutual','adjacent'))
           from public.desire_matches where couple_id='c0117e00-0000-0000-0000-000000000001'),
          'All stored matches are alignment-only (mutual / adjacent)');

select * from finish();
rollback;
