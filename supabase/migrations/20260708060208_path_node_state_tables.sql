-- path_landmark_progress: sparse, couple-scoped. No row = untouched.
create table public.path_landmark_progress (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  path_style text not null default 'swinging',
  landmark_id text not null,
  state text not null check (state in ('curious', 'discussed', 'planning', 'did_it', 'skipped')),
  discussed_via text check (discussed_via in ('session', 'manual')),
  did_it_date timestamptz,
  set_by uuid references public.user_profiles(id),
  updated_at timestamptz not null default now(),
  unique (couple_id, path_style, landmark_id)
);

alter table public.path_landmark_progress enable row level security;

create policy "Partners can view path progress"
  on public.path_landmark_progress for select
  using (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );

create policy "Partners can insert path progress"
  on public.path_landmark_progress for insert
  with check (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );

create policy "Partners can update path progress"
  on public.path_landmark_progress for update
  using (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  )
  with check (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );

-- path_activity_log: append-only. No update/delete policy exists on purpose.
create table public.path_activity_log (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  path_style text not null default 'swinging',
  landmark_id text not null,
  actor_id uuid not null references public.user_profiles(id),
  kind text not null,
  detail jsonb,
  created_at timestamptz not null default now()
);

alter table public.path_activity_log enable row level security;

create policy "Partners can view path activity"
  on public.path_activity_log for select
  using (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );

create policy "Partners can insert path activity"
  on public.path_activity_log for insert
  with check (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );

-- path_private_marks: single-owner, NEVER couple-scoped. This is the private
-- Curious mark from spec §4 — it must not be reachable via any couple_id check.
create table public.path_private_marks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id),
  couple_id uuid references public.couples(id),
  path_style text not null default 'swinging',
  landmark_id text not null,
  marked_at timestamptz not null default now(),
  unique (profile_id, path_style, landmark_id)
);

alter table public.path_private_marks enable row level security;

create policy "Owner can view own private marks"
  on public.path_private_marks for select
  using (profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid()));

create policy "Owner can insert own private marks"
  on public.path_private_marks for insert
  with check (profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid()));

create policy "Owner can delete own private marks"
  on public.path_private_marks for delete
  using (profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid()));
