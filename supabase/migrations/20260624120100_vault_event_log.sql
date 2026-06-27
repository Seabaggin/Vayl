-- Vault Phase B — Event Log (private or shared, per entry).
-- STATUS: UNVERIFIED / NOT APPLIED. Author-only; apply on a Supabase branch, run the
-- RLS tests (esp. "a partner cannot read a private entry"), then merge to prod.
--
-- One table holds both private and shared entries. A compound read policy makes
-- private rows readable ONLY by the author, and shared rows readable by the couple.
-- "Remote backed-up" does not mean not-private: the author-scoped RLS is the guarantee.
-- Convention: profile id via user_profiles.auth_id = auth.uid() (not auth.uid() = id).
-- Tier: FREE.

create table if not exists public.event_log_entries (
  id           uuid primary key default gen_random_uuid(),
  author_id    uuid not null references public.user_profiles(id),
  couple_id    uuid references public.couples(id),     -- set on shared entries
  occurred_on  date not null,
  title        text not null,
  note         text,
  mood         text,
  tags         jsonb not null default '[]'::jsonb,
  who          text,
  visibility   text not null default 'private' check (visibility in ('private','shared')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
alter table public.event_log_entries enable row level security;

-- read: my own (any visibility) OR shared rows in my couple
create policy "event_log_read" on public.event_log_entries
  for select to authenticated
  using (
    author_id in (select id from user_profiles where auth_id = auth.uid())
    or (visibility = 'shared' and couple_id in (
        select couples.id from couples
        where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
           or couples.user_b in (select id from user_profiles where auth_id = auth.uid()))));

-- write: author only (a partner can never insert/edit/delete your entries)
create policy "event_log_insert" on public.event_log_entries
  for insert to authenticated
  with check (author_id in (select id from user_profiles where auth_id = auth.uid()));

create policy "event_log_update" on public.event_log_entries
  for update to authenticated
  using (author_id in (select id from user_profiles where auth_id = auth.uid()))
  with check (author_id in (select id from user_profiles where auth_id = auth.uid()));

create policy "event_log_delete" on public.event_log_entries
  for delete to authenticated
  using (author_id in (select id from user_profiles where auth_id = auth.uid()));
