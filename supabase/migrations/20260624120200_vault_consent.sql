-- Vault Phase C — Consent exchange ("open a conversation"). STATUS: UNVERIFIED / NOT
-- APPLIED. Author-only; apply on a Supabase branch, run the privacy test (asker can NEVER
-- distinguish a decline from pending), then merge to prod.
--
-- THE INVARIANT — a decline never discloses:
--   * consent_requests only ever holds 'pending' / 'opened' and is couple-readable.
--     A decline does NOT change this row, so from the asker's side a declined item stays
--     exactly 'pending', indistinguishable from genuinely waiting.
--   * consent_declines records the decline. Its SELECT policy is scoped to decided_by,
--     so ONLY the decliner can read their own declines (to hide already-declined incoming
--     requests). The asker is never decided_by, so the asker can never read a decline.
--   * All writes go through the consent-ask / consent-respond Edge Functions (service role).
--
-- Convention: profile id via user_profiles.auth_id = auth.uid(). Tier: free (rides on Desire access).

create table if not exists public.consent_requests (
  id                 uuid primary key default gen_random_uuid(),
  couple_id          uuid not null references public.couples(id),
  item_id            text not null,
  asker_id           uuid not null references public.user_profiles(id),
  status             text not null default 'pending' check (status in ('pending','opened')),
  discussion_card_id text,
  created_at         timestamptz not null default now(),
  opened_at          timestamptz
);
create unique index if not exists consent_requests_couple_item_idx
  on public.consent_requests (couple_id, item_id);
alter table public.consent_requests enable row level security;

-- the couple reads requests (only ever pending / opened). No client write policy: only
-- the Edge Functions (service role) write here.
create policy "consent_requests_couple_read" on public.consent_requests
  for select to authenticated
  using (couple_id in (
    select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

create table if not exists public.consent_declines (
  id          uuid primary key default gen_random_uuid(),
  couple_id   uuid not null references public.couples(id),
  item_id     text not null,
  decided_by  uuid not null references public.user_profiles(id),
  created_at  timestamptz not null default now()
);
alter table public.consent_declines enable row level security;

-- ONLY the decliner can read their own declines. The asker (never decided_by) cannot.
-- No insert/update/delete policy: only the service role (consent-respond) writes declines.
create policy "consent_declines_read_own" on public.consent_declines
  for select to authenticated
  using (decided_by in (select id from user_profiles where auth_id = auth.uid()));
