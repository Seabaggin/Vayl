-- Composition write path (spec §9 behavior; section-1 migration shipped the column).
--
-- 1. user_profiles.gender_identity — the OB GenderPhase answer, pushed by the
--    app's identity sync so get-partner can return it at link completion.
--    user_profiles RLS is unchanged (SELECT stays auth_id = auth.uid(); the
--    partner reads it ONLY through the column-scoped get-partner function).
-- 2. set_connection_composition — the only client write path to
--    couples.connection_composition. SECURITY DEFINER + is_couple_member guard,
--    because couples has no member UPDATE policy on purpose (a blanket one
--    would let clients write access_tier — entitlements are service-role-only).

-- ── 1. gender_identity ───────────────────────────────────────────────────────

alter table "public"."user_profiles"
  add column if not exists "gender_identity" text;

comment on column "public"."user_profiles"."gender_identity" is
  'Raw OB GenderPhase answer (Man / Woman / Trans Man / Trans Woman / Non-binary), nil if declined. Partner-visible via get-partner only.';

-- ── 2. set_connection_composition ────────────────────────────────────────────

create or replace function public.set_connection_composition(
  p_couple_id uuid,
  p_value     text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_couple_member(p_couple_id) then
    raise exception 'not a member of couple %', p_couple_id
      using errcode = '42501';
  end if;
  if p_value not in ('mf', 'mm', 'ff', 'flexible') then
    raise exception 'invalid connection_composition %', p_value
      using errcode = '23514';
  end if;

  update public.couples
     set connection_composition = p_value
   where id = p_couple_id;
end;
$$;

revoke all on function public.set_connection_composition(uuid, text) from public, anon;
grant execute on function public.set_connection_composition(uuid, text) to authenticated;
