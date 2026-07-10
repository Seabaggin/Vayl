-- Desire Map launch hardening (pre-TestFlight review 2026-07-09).
-- Canonical decisions: docs/handoffs/2026-07-09-desire-map-pretestflight-review.md
--
--  1) desire_matches.category — the LOCKED-STUB category (small categories pre-collapsed to
--     null by the edge fn) — the only teaser signal an un-entitled client receives.
--  2) get_couple_desire_matches() RPC — the entitlement-checked read path. Core couples get
--     full rows; free couples get the free match full + opaque stubs (category only).
--  3) Direct SELECT on desire_matches is REVOKED for authenticated — the RPC is the only
--     client read path (closes the client-side-only paywall).
--  4) desire_funnel_events — observability layer 1. PAYLOAD RULE: event name, ids, build,
--     error string ONLY. Never desire item ids or match names.
--  5) ops_alerts + desire_ops_sweep() — observability layers 2/3: invariant checks with
--     auto-reconciliation where the fix is known, alert rows where it isn't.
--  6) pg_cron schedule for the sweep (guarded — no-ops where pg_cron is absent).
--
-- All statements idempotent (same discipline as 20260617000000).

-- ── 1) Locked-stub category ─────────────────────────────────────────────────────
alter table public.desire_matches add column if not exists category text;

-- ── 2) Entitlement-checked read path ────────────────────────────────────────────
-- SECURITY DEFINER so it can read desire_matches after the client grant is revoked.
-- Membership is checked explicitly (the caller must be one of the couple's partners).
-- Locked rows for a free couple return NULL item id / alignment / bridge — the client
-- renders them as "A shared desire · CATEGORY" stubs. is_free_reveal and category are
-- always safe to return (category is pre-collapsed at write time).
create or replace function public.get_couple_desire_matches(p_couple_id uuid)
returns table (
  id uuid,
  desire_item_id text,
  alignment_level text,
  is_free_reveal boolean,
  bridge_card_id text,
  category text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    m.id,
    case when c.access_tier <> 'free' or m.is_free_reveal then m.desire_item_id end,
    case when c.access_tier <> 'free' or m.is_free_reveal then m.alignment_level end,
    m.is_free_reveal,
    case when c.access_tier <> 'free' or m.is_free_reveal then m.bridge_card_id end,
    m.category
  from public.desire_matches m
  join public.couples c on c.id = m.couple_id
  where m.couple_id = p_couple_id
    and exists (
      select 1 from public.user_profiles up
      where up.auth_id = auth.uid()
        and up.id in (c.user_a, c.user_b)
    )
  order by m.desire_item_id
$$;

revoke all on function public.get_couple_desire_matches(uuid) from anon;
grant execute on function public.get_couple_desire_matches(uuid) to authenticated;

-- ── 3) Close the direct read ────────────────────────────────────────────────────
drop policy if exists "Partners can view kink matches" on public.desire_matches;
revoke all on table public.desire_matches from authenticated;
revoke all on table public.desire_matches from anon;

-- ── 4) Funnel events (observability layer 1) ────────────────────────────────────
-- PAYLOAD RULE (privacy): event/detail carry NO desire content — no item ids, no match
-- names. Enforced by client convention; this table is the audit surface, not analytics.
create table if not exists public.desire_funnel_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.user_profiles(id) on delete set null,
  couple_id uuid references public.couples(id) on delete set null,
  event text not null,
  detail text,
  build text,
  created_at timestamptz not null default now()
);
create index if not exists desire_funnel_events_couple_idx
  on public.desire_funnel_events (couple_id, created_at);
create index if not exists desire_funnel_events_event_idx
  on public.desire_funnel_events (event, created_at);

alter table public.desire_funnel_events enable row level security;
revoke all on table public.desire_funnel_events from anon;
revoke all on table public.desire_funnel_events from authenticated;
grant insert on table public.desire_funnel_events to authenticated;

-- Insert-own only; nobody (client-side) can read the trail back.
drop policy if exists "Users can log own funnel events" on public.desire_funnel_events;
create policy "Users can log own funnel events"
  on public.desire_funnel_events for insert to authenticated
  with check (user_id in (
    select up.id from public.user_profiles up where up.auth_id = auth.uid()
  ));

-- ── 5a) Ops alerts (service-role only) ──────────────────────────────────────────
create table if not exists public.ops_alerts (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  subject_id uuid,
  detail text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
-- One OPEN alert per (kind, subject) — the sweep re-fires without spamming duplicates.
create unique index if not exists ops_alerts_open_unique
  on public.ops_alerts (kind, subject_id) where resolved_at is null;

alter table public.ops_alerts enable row level security;
revoke all on table public.ops_alerts from anon;
revoke all on table public.ops_alerts from authenticated;

-- ── 5b) Item meta for the SQL reconciler ────────────────────────────────────────
-- Mirrors match-logic.ts STUB_CATEGORIES (both mirror desire_items.json — regenerate
-- together on content changes). Only the reconciler reads this; clients never do.
create table if not exists public.desire_item_meta (
  item_id text primary key,
  stub_category text
);
alter table public.desire_item_meta enable row level security;
revoke all on table public.desire_item_meta from anon;
revoke all on table public.desire_item_meta from authenticated;

insert into public.desire_item_meta (item_id, stub_category) values
  ('opening', 'structures'),
  ('recalibrating', null),
  ('swinging', 'structures'),
  ('trips_apart', 'structures'),
  ('polyamory', 'structures'),
  ('hierarchy', 'structures'),
  ('emotional_connections', 'emotional'),
  ('nre', 'emotional'),
  ('partner_falling_in_love', 'emotional'),
  ('jealousy', 'emotional'),
  ('group_sexual', null),
  ('intimate_details', 'communication'),
  ('safer_sex', null),
  ('overnight_stays', 'logistics'),
  ('time_attention', 'logistics'),
  ('finances', 'logistics'),
  ('reconnection', 'emotional'),
  ('metamours', 'communication'),
  ('social_disclosure', 'communication')
on conflict (item_id) do update set stub_category = excluded.stub_category;

-- ── 5c) The sweep: invariants + auto-reconciliation ─────────────────────────────
-- Runs as service role via pg_cron. Three invariants (review §1.6):
--   A. purchase ledger says active but couples.access_tier is still 'free'
--      → RECONCILE: set the tier (the exact fix grant-entitlement would apply), and
--        leave a resolved alert row for visibility.
--   B. desire_map_status says both complete, >1h old, but the couple has zero matches
--      → RECONCILE: recompute matches in SQL (same rules as match-logic.ts: both-rated,
--        notForMe dropped, mutual = E+E, adjacent = E+O/O+O, one free reveal preferring
--        a mutual; stub category from desire_item_meta). Leave a resolved alert row.
--   C. a purchase_succeeded funnel event with no unlock_rendered within 24h
--      → ALERT only (needs a human — the client never confirmed the unlock rendered).
create or replace function public.desire_ops_sweep()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  rec record;
  free_item text;
begin
  -- A. entitled but tier=free → reconcile via the CANONICAL resolver (payer-portable:
  -- a couple is Core if it holds the entitlement OR either member is purchased_by —
  -- 20260617130000_entitlement_payer_portable_resolution.sql). Single-sourced on
  -- recompute_couple_entitlement so the sweep can never drift from the grant path
  -- (review fix 2026-07-10: the first cut hand-rolled a couple_id-only check and
  -- missed portable entitlements after an unlink/re-pair).
  for rec in
    select c.id
    from couples c
    where c.access_tier = 'free'
      and public.resolve_couple_access_tier(c.id) <> 'free'
  loop
    perform public.recompute_couple_entitlement(rec.id);
    insert into ops_alerts (kind, subject_id, detail, resolved_at)
      values ('entitlement_tier_reconciled', rec.id,
              'resolver says entitled but tier was free; recomputed', now())
      on conflict do nothing;
  end loop;

  -- B. both complete >1h, zero matches → recompute in SQL
  for rec in
    select s.couple_id, c.user_a, c.user_b
    from desire_map_status s
    join couples c on c.id = s.couple_id
    where s.partner_a_complete and s.partner_b_complete
      and greatest(coalesce(s.partner_a_completed_at, 'epoch'::timestamptz),
                   coalesce(s.partner_b_completed_at, 'epoch'::timestamptz)) < now() - interval '1 hour'
      and not exists (select 1 from desire_matches m where m.couple_id = s.couple_id)
  loop
    insert into desire_matches (couple_id, desire_item_id, alignment_level, is_free_reveal, bridge_card_id, category, created_at)
    select rec.couple_id,
           a.desire_item_id,
           case
             when a.rating = 'excitedAboutIt' and b.rating = 'excitedAboutIt' then 'mutual'
             else 'adjacent'
           end,
           false,
           null,
           meta.stub_category,
           now()
    from desire_ratings a
    join desire_ratings b
      on b.desire_item_id = a.desire_item_id and b.user_id = rec.user_b
    left join desire_item_meta meta on meta.item_id = a.desire_item_id
    where a.user_id = rec.user_a
      and a.rating in ('excitedAboutIt', 'openToIt')
      and b.rating in ('excitedAboutIt', 'openToIt')
    order by a.desire_item_id;

    -- Exactly one free reveal: first mutual by item id, else first match. (No pin to
    -- honor here — this branch only runs when the couple has zero match rows.)
    select m.desire_item_id into free_item
    from desire_matches m
    where m.couple_id = rec.couple_id
    order by (m.alignment_level <> 'mutual'), m.desire_item_id
    limit 1;
    if free_item is not null then
      update desire_matches
        set is_free_reveal = true
        where couple_id = rec.couple_id and desire_item_id = free_item;
      insert into ops_alerts (kind, subject_id, detail, resolved_at)
        values ('desire_matches_reconciled', rec.couple_id,
                'both complete with zero matches >1h; recomputed in SQL', now())
        on conflict do nothing;
    end if;
  end loop;

  -- C. paid but unlock never rendered → open alert (human follow-up)
  for rec in
    select p.couple_id, min(p.created_at) as paid_at
    from desire_funnel_events p
    where p.event = 'purchase_succeeded'
      and p.created_at < now() - interval '24 hours'
      and p.couple_id is not null
      and not exists (
        select 1 from desire_funnel_events u
        where u.event = 'unlock_rendered'
          and u.couple_id = p.couple_id
          and u.created_at >= p.created_at
      )
    group by p.couple_id
  loop
    insert into ops_alerts (kind, subject_id, detail)
      values ('paid_unlock_not_rendered', rec.couple_id,
              'purchase_succeeded at ' || rec.paid_at || ' with no unlock_rendered within 24h')
      on conflict do nothing;
  end loop;
end;
$$;

revoke all on function public.desire_ops_sweep() from anon;
revoke all on function public.desire_ops_sweep() from authenticated;

-- ── 6) Schedule (guarded — pg_cron may be absent locally) ───────────────────────
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('desire-ops-sweep')
      where exists (select 1 from cron.job where jobname = 'desire-ops-sweep');
    perform cron.schedule('desire-ops-sweep', '*/30 * * * *', 'select public.desire_ops_sweep()');
  end if;
end;
$$;
