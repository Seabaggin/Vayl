-- Monetization — payer-portable + refund-aware entitlement resolution.
-- Spec: docs/superpowers/specs/2026-06-15-monetization-implementation-spec.md (M6 entitlement-lifecycle, 2026-06-17)
--
-- Decided 2026-06-17: the Core tier FOLLOWS THE PURCHASER. A couple is `core` if it holds an
-- active entitlement OR a member is the `purchased_by` of one — so when the buyer re-pairs, the
-- new couple inherits Core automatically, and a refund (is_active=false) drops BOTH partners by
-- the same rule. These functions centralize that resolution; couples.access_tier becomes a cache
-- the edge functions recompute at grant + at pairing.
--
-- Apply path: idempotent; applied to prod via execute_sql (see 20260617120000 header).
-- Reconcile: supabase migration repair --status applied 20260617130000
--
-- Security: SECURITY INVOKER (callers are the service-role edge functions, which already bypass
-- RLS and can read the service-role-only entitlements table). EXECUTE is revoked from PUBLIC and
-- granted only to service_role, so authenticated/anon can never call them — no info leak, no
-- tamper. Avoids the SECURITY DEFINER "public-callable" trap.

-- Pure resolver: 'core' iff this couple has any qualifying active, non-expired entitlement —
-- tied to the couple directly, OR held by one of its two members as the purchaser (portable).
create or replace function public.resolve_couple_access_tier(p_couple_id uuid)
returns text
language sql
stable
security invoker
set search_path to 'public'
as $$
  select case when exists (
    select 1
    from public.couples c
    join public.entitlements e
      on e.is_active
     and (e.expires_at is null or e.expires_at > now())
     and (e.couple_id = c.id or e.purchased_by = c.user_a or e.purchased_by = c.user_b)
    where c.id = p_couple_id
  ) then 'core' else 'free' end;
$$;

-- Writer: recompute the denormalized couples cache (tier + unlocked-at + founding) from the
-- ledger. Returns the resolved tier. Idempotent. Call after any entitlement or membership change
-- (grant, refund, pairing, unlink).
create or replace function public.recompute_couple_entitlement(p_couple_id uuid)
returns text
language plpgsql
security invoker
set search_path to 'public'
as $$
declare
  v_tier     text;
  v_founding boolean;
begin
  v_tier := public.resolve_couple_access_tier(p_couple_id);

  select coalesce(bool_or(e.is_founding_member), false)
    into v_founding
  from public.couples c
  join public.entitlements e
    on e.is_active
   and (e.expires_at is null or e.expires_at > now())
   and (e.couple_id = c.id or e.purchased_by = c.user_a or e.purchased_by = c.user_b)
  where c.id = p_couple_id;

  update public.couples
     set access_tier       = v_tier,
         is_founding_member = (v_tier = 'core' and v_founding),
         core_unlocked_at   = case
                                when v_tier = 'core' and core_unlocked_at is null then now()
                                else core_unlocked_at
                              end
   where id = p_couple_id;

  return v_tier;
end;
$$;

-- NOTE: revoke from authenticated + anon too, not just PUBLIC — Supabase default privileges
-- grant EXECUTE to `authenticated` explicitly on new functions (p5d only revoked `anon`).
revoke all on function public.resolve_couple_access_tier(uuid)   from public, authenticated, anon;
revoke all on function public.recompute_couple_entitlement(uuid) from public, authenticated, anon;
grant execute on function public.resolve_couple_access_tier(uuid)   to service_role;
grant execute on function public.recompute_couple_entitlement(uuid) to service_role;
