-- supabase/tests/card_sessions_invariants.test.sql
--
-- pgTAP invariants for the Card Sessions backend (spec 2026-07-01 §8):
--   1. couples.connection_composition exists, defaults to flexible, and the
--      check constraint rejects anything outside mf/mm/ff/flexible.
--   2. update_reveal_state deep-merges the delta: sibling flags within a card
--      and sibling card keys are preserved, never clobbered.
--   3. A non-member of the couple cannot call update_reveal_state (the
--      SECURITY DEFINER guard, since RLS does not apply inside it).
--
-- Runs on the LOCAL stack inside a transaction that rolls back:
--   supabase start && supabase test db
--
-- Impersonation: is_couple_member reads auth.uid(), which resolves from the
-- request.jwt.claim.sub GUC -- setting the GUC is sufficient (no role switch
-- needed because the function under test is SECURITY DEFINER, not RLS-gated).

begin;
create extension if not exists pgtap with schema extensions;
set search_path to extensions, public;

select plan(11);

-- ── Seed (as superuser; FK triggers off while inserting synthetic identities) ──
set local session_replication_role = 'replica';

insert into public.user_profiles (id, auth_id) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'a0a0a0a0-0000-0000-0000-000000000001'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'b0b0b0b0-0000-0000-0000-000000000002'),
  ('c1c1c1c1-0000-0000-0000-000000000003', 'c0c0c0c0-0000-0000-0000-000000000003');

insert into public.couples (id, user_a, user_b) values
  ('c0117e00-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001',
   'b1b1b1b1-0000-0000-0000-000000000002');

insert into public.curated_sessions
  (id, couple_id, initiator_id, deck_id, status, reveal_state) values
  ('5e551011-0000-0000-0000-000000000001',
   'c0117e00-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001',
   'the-opener', 'active',
   '{"card-1": {"a_sealed": true}}'::jsonb);

set local session_replication_role = 'origin';

-- ── 1–4. connection_composition column + constraint ──────────────────────────

select has_column('public', 'couples', 'connection_composition',
  'couples.connection_composition exists');

-- Note: this stack renders the default as the bare literal (not 'flexible'::text).
select col_default_is('public', 'couples', 'connection_composition',
  'flexible',
  'connection_composition defaults to flexible');

select throws_ok(
  $$update public.couples
      set connection_composition = 'xy'
      where id = 'c0117e00-0000-0000-0000-000000000001'$$,
  '23514', null,
  'connection_composition rejects values outside mf/mm/ff/flexible');

select lives_ok(
  $$update public.couples
      set connection_composition = 'mm'
      where id = 'c0117e00-0000-0000-0000-000000000001'$$,
  'connection_composition accepts mm');

-- ── 5–6. update_reveal_state exists and is SECURITY DEFINER ──────────────────

select has_function('public', 'update_reveal_state', array['uuid', 'jsonb'],
  'update_reveal_state(uuid, jsonb) exists');

select is_definer('public', 'update_reveal_state', array['uuid', 'jsonb'],
  'update_reveal_state is SECURITY DEFINER (so the member guard is load-bearing)');

-- ── 7–10. Merge semantics as partner B: deltas merge, siblings survive ───────

select set_config('request.jwt.claim.sub', 'b0b0b0b0-0000-0000-0000-000000000002', true);

select lives_ok(
  $$select public.update_reveal_state(
      '5e551011-0000-0000-0000-000000000001',
      '{"card-1": {"b_sealed": true}, "card-2": {"a_sealed": true}}'::jsonb)$$,
  'a couple member can call update_reveal_state');

select is(
  (select reveal_state -> 'card-1' ->> 'a_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge preserves the sibling flag inside the same card (a_sealed untouched)');

select is(
  (select reveal_state -> 'card-1' ->> 'b_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge lands the delta flag (b_sealed now true)');

select is(
  (select reveal_state -> 'card-2' ->> 'a_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge adds a new card key without touching card-1');

-- ── 11. Non-member rejected ──────────────────────────────────────────────────

select set_config('request.jwt.claim.sub', 'c0c0c0c0-0000-0000-0000-000000000003', true);

select throws_ok(
  $$select public.update_reveal_state(
      '5e551011-0000-0000-0000-000000000001',
      '{"card-1": {"revealed": true}}'::jsonb)$$,
  'P0001', 'not a member of this couple',
  'a non-member of the couple cannot mutate reveal_state');

select * from finish();
rollback;
