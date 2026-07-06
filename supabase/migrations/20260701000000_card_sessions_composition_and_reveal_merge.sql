-- Card Sessions front-to-back, master segment A (spec 2026-07-01 §8).
--
-- 1. couples.connection_composition — which gendered card variants the couple
--    sees (Deck.cards(for:) filter). Wayfinding vocabulary, not identity.
-- 2. update_reveal_state — server-side deep merge for curated_sessions.reveal_state.
--    Clients only ever send their DELTA ({"card-07": {"a_sealed": true}}); the
--    function merges per-card sub-objects so concurrent seals from both partners
--    never clobber each other. SECURITY DEFINER (bypasses RLS to read+write the
--    row), therefore the explicit is_couple_member guard is load-bearing.

-- ── 1. connection_composition ────────────────────────────────────────────────

alter table "public"."couples"
  add column if not exists "connection_composition" text not null default 'flexible';

alter table "public"."couples"
  add constraint "couples_connection_composition_check"
  check ("connection_composition" in ('mf', 'mm', 'ff', 'flexible'));

comment on column "public"."couples"."connection_composition" is
  'Which gendered card variants this couple sees: mf | mm | ff | flexible. Default flexible. Set at pairing (one-tap confirm), changeable in Settings.';

-- ── 2. update_reveal_state ───────────────────────────────────────────────────
-- Merge semantics: for each card key in p_delta, the existing per-card object
-- and the delta's per-card object are merged (existing || delta), then the
-- result is merged over the whole column (existing || merged-cards). Sibling
-- card keys and sibling flags within a card are always preserved.
-- SELECT ... FOR UPDATE serializes two simultaneous seals on the same row.

create or replace function "public"."update_reveal_state"(
  "p_session_id" uuid,
  "p_delta" jsonb
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_couple_id uuid;
begin
  select couple_id into v_couple_id
  from curated_sessions
  where id = p_session_id
  for update;

  if v_couple_id is null then
    raise exception 'session not found';
  end if;

  if not is_couple_member(v_couple_id) then
    raise exception 'not a member of this couple';
  end if;

  if p_delta is null or jsonb_typeof(p_delta) <> 'object' then
    raise exception 'delta must be a jsonb object';
  end if;

  update curated_sessions cs
  set reveal_state = cs.reveal_state || coalesce(
        (
          select jsonb_object_agg(
                   d.key,
                   coalesce(cs.reveal_state -> d.key, '{}'::jsonb) || d.value
                 )
          from jsonb_each(p_delta) as d(key, value)
        ),
        '{}'::jsonb
      ),
      updated_at = now()
  where cs.id = p_session_id;
end;
$$;

alter function "public"."update_reveal_state"(uuid, jsonb) owner to "postgres";

revoke all on function "public"."update_reveal_state"(uuid, jsonb) from public;
revoke all on function "public"."update_reveal_state"(uuid, jsonb) from anon;
grant execute on function "public"."update_reveal_state"(uuid, jsonb) to authenticated;
grant execute on function "public"."update_reveal_state"(uuid, jsonb) to service_role;
