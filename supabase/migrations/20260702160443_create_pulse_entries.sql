-- pulse_entries: full daily check-in history. Supersedes pulse_shared_capacity's
-- single-scalar-only model (left in place, untouched, now unused going forward).
-- Local device cache stays UserDefaults for speed/offline; this table becomes the
-- source of truth, so history survives reinstall/device switch. RLS mirrors
-- pulse_shared_capacity's exact proven shape: owner full access, partner read-only
-- gated on same couple + owner's existing share_pulse_with_partner consent flag.

create table if not exists public.pulse_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete cascade,
  couple_id uuid references public.couples(id) on delete set null,
  entry_date timestamp with time zone not null,
  energy real not null,
  openness real not null,
  capacity_score real not null,
  nervous_system text not null,
  focus text not null,
  feeling text not null,
  capacity text not null,
  speed text not null,
  created_at timestamp with time zone not null default now()
);

create index if not exists pulse_entries_profile_date_idx
  on public.pulse_entries (profile_id, entry_date desc);

create index if not exists pulse_entries_couple_date_idx
  on public.pulse_entries (couple_id, entry_date desc)
  where couple_id is not null;

alter table public.pulse_entries enable row level security;

create policy "pulse_entries insert own"
  on public.pulse_entries for insert
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "pulse_entries update own"
  on public.pulse_entries for update
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  )
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "pulse_entries delete own"
  on public.pulse_entries for delete
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "pulse_entries read"
  on public.pulse_entries for select
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
