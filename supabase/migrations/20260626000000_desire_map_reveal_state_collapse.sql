begin;

-- desire_matches: drop vestigial partner-raw + gap (privacy now structural) and dead revealed_at
alter table public.desire_matches
  drop column if exists partner_a_value,
  drop column if exists partner_b_value,
  drop column if exists gap_size,
  drop column if exists revealed_at;

-- desire_map_status: drop dead unlock mirror (derive from couples.access_tier / core_unlocked_at)
alter table public.desire_map_status
  drop column if exists full_reveal_unlocked,
  drop column if exists full_reveal_at;

-- couples: drop dead matches_revealed (redundant with access_tier)
alter table public.couples
  drop column if exists matches_revealed;

-- per-user reveal viewing state ("Seen"), server-authoritative + benign.
-- keyed (user_id, couple_id) so a re-pair replays the reveal for the new map.
-- own-user RLS: a person reads/writes ONLY their own row.
create table if not exists public.desire_reveal_progress (
  user_id             uuid not null references public.user_profiles(id) on delete cascade,
  couple_id           uuid not null references public.couples(id) on delete cascade,
  free_reveal_seen_at timestamptz,
  full_reveal_seen_at timestamptz,
  updated_at          timestamptz not null default now(),
  primary key (user_id, couple_id)
);
alter table public.desire_reveal_progress enable row level security;
create policy "own reveal progress - select" on public.desire_reveal_progress
  for select to authenticated
  using (user_id in (select id from public.user_profiles where auth_id = auth.uid()));
create policy "own reveal progress - insert" on public.desire_reveal_progress
  for insert to authenticated
  with check (user_id in (select id from public.user_profiles where auth_id = auth.uid()));
create policy "own reveal progress - update" on public.desire_reveal_progress
  for update to authenticated
  using (user_id in (select id from public.user_profiles where auth_id = auth.uid()));

commit;
