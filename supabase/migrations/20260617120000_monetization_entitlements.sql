-- Monetization M1 — couple-level entitlements (couple-core).
-- Spec: docs/superpowers/specs/2026-06-15-monetization-implementation-spec.md (Segment M1)
--
-- Apply path: idempotent DDL applied to prod via MCP execute_sql (the linked CLI can't auth —
-- missing SUPABASE_DB_PASSWORD — and the MCP `apply_migration` tool re-tangles history with
-- server-side timestamps). execute_sql does NOT write supabase_migrations history; reconcile
-- once the CLI is linked:
--   supabase migration repair --status applied 20260617120000
-- Every statement is idempotent, so a later `db push` is safe either way.
--
-- Model parity: mirrors EntitlementRecord (the ledger) + Couple.entitlementTier / coreUnlockedAt
-- / isFoundingMember (the denormalized resolved tier).
--
-- Security posture:
--  • entitlements is SERVER-AUTHORITATIVE and SERVICE-ROLE-ONLY. There is no authenticated grant
--    and no RLS policy → only the service role (the grant-entitlement edge function) can read or
--    write it. The raw ledger holds purchased_by + transaction_id, both "support only — never
--    shown to either partner," so the client must never be able to read it.
--  • The client-facing tier is the denormalized couples.access_tier (couples already has a
--    partner SELECT policy, no UPDATE policy → read-only to clients). couples carries ONLY
--    non-sensitive resolved state (tier, unlocked-at, founding flag) — NOT who paid.
--  • p5d revoked anon from default privileges, so these objects start locked from the public key.

-- ── 1) entitlements ledger (service-role-only) ─────────────────────────────────
-- One row per validated purchase. Couple-level: one Core purchase covers BOTH partners.
create table if not exists public.entitlements (
  id                 uuid primary key default gen_random_uuid(),
  couple_id          uuid not null references public.couples(id) on delete cascade,
  product_id         text not null,                                    -- e.g. com.vayl.core.lifetime
  transaction_id     text not null,                                    -- StoreKit transaction id
  purchased_by       uuid references public.user_profiles(id) on delete set null,  -- support only; NEVER client-readable
  purchased_at       timestamptz not null default now(),
  is_active          boolean not null default true,                    -- false on confirmed refund
  expires_at         timestamptz,                                      -- null = lifetime (Core is lifetime)
  is_founding_member boolean not null default false,                   -- first-year-free Pro when Act 2 lands
  created_at         timestamptz not null default now(),
  -- Idempotent grant / restore: the same transaction can only ever produce one row.
  constraint entitlements_transaction_unique unique (transaction_id)
);

create index if not exists entitlements_couple_id_idx on public.entitlements (couple_id);

-- RLS enabled, NO policy → authenticated + anon are denied all rows (defense in depth on top of
-- the revoked grant). The service role bypasses RLS and is the only reader/writer.
alter table public.entitlements enable row level security;
drop policy if exists "Partners can view their entitlements" on public.entitlements;  -- (idempotent cleanup)
revoke all on public.entitlements from anon;
revoke all on public.entitlements from authenticated;

-- ── 2) couples — denormalized resolved tier (client-readable, non-sensitive only) ──
-- The single value every gate + RLS reads (no join to entitlements). Written ONLY by the edge
-- function (service role); couples has no client UPDATE policy, so clients read but never set
-- their own tier. Deliberately does NOT carry "who paid" — that stays in entitlements.
alter table public.couples add column if not exists access_tier text not null default 'free';
alter table public.couples drop constraint if exists couples_access_tier_check;
alter table public.couples add constraint couples_access_tier_check
  check (access_tier in ('free', 'core', 'pro'));
alter table public.couples add column if not exists core_unlocked_at   timestamptz;
alter table public.couples add column if not exists is_founding_member boolean not null default false;

-- (core_unlocked_by is intentionally NOT stored on couples — buyer identity is support-only and
--  lives solely in entitlements.purchased_by, which is service-role-only.)
