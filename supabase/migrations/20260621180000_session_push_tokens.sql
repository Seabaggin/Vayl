-- Seg 8 (push) — device token registry for couple session invites.
-- STATUS: UNVERIFIED / NOT APPLIED. Review before running (CLI or MCP apply_migration).
--
-- user_id stores a user_profiles.id (a generated UUID), NOT auth.uid() — same
-- convention as every other scoped table in this codebase. Policies join through
-- user_profiles.auth_id = auth.uid() accordingly.

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

-- A user manages only their own tokens.
create policy "device_tokens_owner_select" on public.device_tokens
    for select using (
        user_id in (select id from public.user_profiles where auth_id = auth.uid())
    );

create policy "device_tokens_owner_insert" on public.device_tokens
    for insert with check (
        user_id in (select id from public.user_profiles where auth_id = auth.uid())
    );

create policy "device_tokens_owner_update" on public.device_tokens
    for update using (
        user_id in (select id from public.user_profiles where auth_id = auth.uid())
    ) with check (
        user_id in (select id from public.user_profiles where auth_id = auth.uid())
    );

create policy "device_tokens_owner_delete" on public.device_tokens
    for delete using (
        user_id in (select id from public.user_profiles where auth_id = auth.uid())
    );

-- Sending pushes is service-role only (the edge function), never a client.
