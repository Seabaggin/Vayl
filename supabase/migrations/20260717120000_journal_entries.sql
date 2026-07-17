-- journal_entries: the private notebook. Owner-only in the strongest sense —
-- there is deliberately NO couple_id and NO partner-read clause anywhere in this
-- file. pulse_entries gates partner reads on a consent flag; the journal has no
-- such path by design: "Private to you. <Partner> can't access your journal in
-- Vayl" is a structural guarantee (RLS), not a UI choice. If a future feature
-- wants to share one entry, it copies content out — it never widens this policy.
--
-- prompt_id holds a bundle slug (Vayl/Resources/Content/journal_prompts.json),
-- not an FK: prompts are content, not user data, and retiring a prompt must never
-- cascade into someone's writing. Slugs are stable forever and never reused.
-- Nullable = a freeform entry with no prompt.
--
-- updated_at is client-set on update, matching pulse_entries house style (no trigger).

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete cascade,
  body text not null,
  prompt_id text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Newest-first list, scoped to the author. The only read pattern this table has.
create index if not exists journal_entries_profile_created_idx
  on public.journal_entries (profile_id, created_at desc);

alter table public.journal_entries enable row level security;

-- Idempotent: safe to re-run against a database where these already exist.
drop policy if exists "journal_entries read own" on public.journal_entries;
drop policy if exists "journal_entries insert own" on public.journal_entries;
drop policy if exists "journal_entries update own" on public.journal_entries;
drop policy if exists "journal_entries delete own" on public.journal_entries;

create policy "journal_entries read own"
  on public.journal_entries for select
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "journal_entries insert own"
  on public.journal_entries for insert
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "journal_entries update own"
  on public.journal_entries for update
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  )
  with check (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create policy "journal_entries delete own"
  on public.journal_entries for delete
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );
