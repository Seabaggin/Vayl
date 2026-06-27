-- Seg 8 (push) — device token registry for couple session invites.
-- STATUS: UNVERIFIED / NOT APPLIED. Review before running (CLI or MCP apply_migration).
--
-- ⚠️ VERIFY before applying: this references the project's auth-id vs profile-id
-- convention (see the backend↔app reconciliation notes). If user_profiles.id is NOT
-- auth.uid(), the RLS predicates below must be rewritten to join through whatever
-- column maps a profile to auth.uid() (the same pattern the existing scoped policies
-- use). Do not apply until the predicate matches the established convention.

create table if not exists public.device_tokens (
    token       text primary key,
    user_id     uuid not null references public.user_profiles(id) on delete cascade,
    platform    text not null default 'ios',
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index if not exists device_tokens_user_id_idx
    on public.device_tokens(user_id);

alter table public.device_tokens enable row level security;

-- A user manages only their own tokens. (See VERIFY note re: auth.uid() mapping.)
create policy "device_tokens_owner_select" on public.device_tokens
    for select using (auth.uid() = user_id);

create policy "device_tokens_owner_insert" on public.device_tokens
    for insert with check (auth.uid() = user_id);

create policy "device_tokens_owner_update" on public.device_tokens
    for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "device_tokens_owner_delete" on public.device_tokens
    for delete using (auth.uid() = user_id);

-- Sending pushes is service-role only (the edge function), never a client.
