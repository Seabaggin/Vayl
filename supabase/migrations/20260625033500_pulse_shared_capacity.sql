-- Reconciliation backfill (2026-07-16, TestFlight blocker B4): pulse_shared_capacity
-- exists in prod (created 2026-06-25 via dashboard migrations "pulse_shared_capacity"
-- + "pulse_shared_capacity_delete_policy") but had no local migration file. Superseded
-- by pulse_entries (2026-07-02) as the source of truth, but still present in prod.
-- Faithful transcription of prod introspection: PK on profile_id, NO foreign keys
-- (prod has none — do not add them here), no extra indexes, no triggers, RLS enabled,
-- four policies. Idempotent so it is safe to run against prod where objects exist.

create table if not exists public.pulse_shared_capacity (
  profile_id uuid primary key,
  couple_id uuid,
  capacity_score real not null,
  updated_at timestamp with time zone not null default now()
);

alter table public.pulse_shared_capacity enable row level security;

drop policy if exists "pulse_shared_capacity insert own" on public.pulse_shared_capacity;
create policy "pulse_shared_capacity insert own"
  on public.pulse_shared_capacity for insert
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

drop policy if exists "pulse_shared_capacity update own" on public.pulse_shared_capacity;
create policy "pulse_shared_capacity update own"
  on public.pulse_shared_capacity for update
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  )
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

drop policy if exists "pulse_shared_capacity delete own" on public.pulse_shared_capacity;
create policy "pulse_shared_capacity delete own"
  on public.pulse_shared_capacity for delete
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

drop policy if exists "pulse_shared_capacity read" on public.pulse_shared_capacity;
create policy "pulse_shared_capacity read"
  on public.pulse_shared_capacity for select
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    or (
      couple_id in (
        select couples.id from public.couples
        where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
           or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
      )
      and profile_id in (select user_profiles.id from public.user_profiles where user_profiles.share_pulse_with_partner = true)
    )
  );
