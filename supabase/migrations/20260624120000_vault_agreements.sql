-- Vault Phase A — Agreements (dual-lock: propose -> partner approves).
-- STATUS: UNVERIFIED / NOT APPLIED. Author-only; apply on a Supabase branch, run the
-- RLS tests, then merge to prod. Do NOT apply straight to prod.
--
-- Convention: user_profiles.id is NOT auth.uid(); auth maps to a profile via
-- user_profiles.auth_id = auth.uid(). All scoped policies join through that, matching
-- the live couples / desire_matches / desire_ratings policies (NOT the device_tokens
-- file, whose `auth.uid() = user_id` form is flagged unverified).
--
-- Tier: FREE (safety primitive; no entitlement gate).

create table if not exists public.agreements (
  id          uuid primary key default gen_random_uuid(),
  couple_id   uuid not null references public.couples(id),
  text        text not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.agreements enable row level security;

create table if not exists public.agreement_proposals (
  id                  uuid primary key default gen_random_uuid(),
  couple_id           uuid not null references public.couples(id),
  target_agreement_id uuid references public.agreements(id),   -- null = propose-create
  action              text not null check (action in ('create','edit','retire')),
  proposed_text       text,                                    -- for create / edit
  proposed_by         uuid not null references public.user_profiles(id),
  status              text not null default 'pending' check (status in ('pending','approved','declined')),
  created_at          timestamptz not null default now(),
  decided_at          timestamptz
);
alter table public.agreement_proposals enable row level security;

-- agreements: the couple reads; clients NEVER write directly. The only writer is the
-- SECURITY DEFINER trigger below (applies an approved proposal). No insert/update/delete
-- policy is intentional.
create policy "agreements_couple_read" on public.agreements
  for select to authenticated
  using (couple_id in (
    select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- proposals: the couple reads.
create policy "proposals_couple_read" on public.agreement_proposals
  for select to authenticated
  using (couple_id in (
    select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- propose: I insert a proposal as myself, in my couple.
create policy "proposals_propose" on public.agreement_proposals
  for insert to authenticated
  with check (
    proposed_by in (select id from user_profiles where auth_id = auth.uid())
    and couple_id in (
      select couples.id from couples
      where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
         or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- decide (THE DUAL LOCK): only the NON-proposer can move a pending proposal to
-- approved/declined. The proposer cannot self-approve.
create policy "proposals_partner_decides" on public.agreement_proposals
  for update to authenticated
  using (
    status = 'pending'
    and proposed_by not in (select id from user_profiles where auth_id = auth.uid())
    and couple_id in (
      select couples.id from couples
      where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
         or couples.user_b in (select id from user_profiles where auth_id = auth.uid())))
  with check (status in ('approved','declined'));

-- withdraw: a proposer may delete their own still-pending proposal.
create policy "proposals_withdraw_own" on public.agreement_proposals
  for delete to authenticated
  using (
    status = 'pending'
    and proposed_by in (select id from user_profiles where auth_id = auth.uid()));

-- Apply an approved proposal to agreements, atomically, as the table owner (definer).
create or replace function public.apply_agreement_proposal()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status = 'pending' then
    if new.action = 'create' then
      insert into public.agreements (couple_id, text) values (new.couple_id, new.proposed_text);
    elsif new.action = 'edit' then
      update public.agreements set text = new.proposed_text, updated_at = now()
        where id = new.target_agreement_id;
    elsif new.action = 'retire' then
      update public.agreements set is_active = false, updated_at = now()
        where id = new.target_agreement_id;
    end if;
    new.decided_at = now();
  elsif new.status = 'declined' and old.status = 'pending' then
    new.decided_at = now();
  end if;
  return new;
end $$;

drop trigger if exists trg_apply_agreement_proposal on public.agreement_proposals;
create trigger trg_apply_agreement_proposal
  before update on public.agreement_proposals
  for each row execute function public.apply_agreement_proposal();
