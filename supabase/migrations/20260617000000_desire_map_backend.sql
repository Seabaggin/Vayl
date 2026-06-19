-- Desire Map backend (D2/D3): 4-point rating vocab + reveal columns + couple completion table.
--
-- Apply path: normally `supabase db push`. On 2026-06-17 the CLI couldn't auth to remote
-- (missing SUPABASE_DB_PASSWORD), so this was applied to prod via MCP execute_sql (which does
-- NOT write supabase_migrations history). To reconcile once the CLI is linked:
--   supabase migration repair --status applied 20260617000000
-- All statements are idempotent, so a later `db push` is safe either way.

-- 1) Rating vocab → 4-point weight (replaces the stale kink_* vocab). desire_ratings is 0 rows.
alter table public.desire_ratings drop constraint if exists kink_ratings_rating_check;
alter table public.desire_ratings drop constraint if exists desire_ratings_rating_check;
alter table public.desire_ratings add constraint desire_ratings_rating_check
  check (rating = any (array['excitedAboutIt'::text, 'openToIt'::text, 'probablyNot'::text, 'notForMe'::text]));

-- 2) desire_matches: free-reveal / paywall columns the reveal mechanic needs (Swift model already expects them).
alter table public.desire_matches add column if not exists is_free_reveal boolean not null default false;
alter table public.desire_matches add column if not exists revealed_at timestamptz;

-- 3) desire_map_status: per-couple completion + reveal state. Both partners SELECT; writes are
--    service-role only (the edge function), exactly like desire_matches.
create table if not exists public.desire_map_status (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  track text,
  partner_a_complete boolean not null default false,
  partner_b_complete boolean not null default false,
  partner_a_completed_at timestamptz,
  partner_b_completed_at timestamptz,
  full_reveal_unlocked boolean not null default false,
  full_reveal_at timestamptz,
  waiting_state_since timestamptz,
  created_at timestamptz not null default now(),
  constraint desire_map_status_couple_unique unique (couple_id)
);

alter table public.desire_map_status enable row level security;

drop policy if exists "Partners can view desire map status" on public.desire_map_status;
create policy "Partners can view desire map status"
  on public.desire_map_status for select to authenticated
  using (couple_id in (
    select couples.id from public.couples
    where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
       or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  ));
