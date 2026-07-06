# Monetization M1 — Entitlement Security Rule

**Date:** 2026-06-16
**Status:** Design constraint for the Monetization (M1) work. Surfaced during the P5 security audit.
**Parent:** Monetization paywall spec (Act 1 lifetime $24.99 + free tier); [`2026-06-15-pairing-implementation-spec.md`](2026-06-15-pairing-implementation-spec.md) P5.

---

## The rule (non-negotiable)

Entitlement / subscription / tier / usage state MUST be **server-authoritative and service-role-write-only**. It must **never** be a client-writable column.

Concretely:
- Store entitlements in a **dedicated table with no client INSERT/UPDATE policy** — only the service role (or a verified edge function) writes it. This is the exact pattern `public.couples` already uses: clients can SELECT their couple but cannot write `matches_revealed`.
- Do **not** add a `tier` / `is_premium` / `usage_limit` / `matches_remaining` column to `user_profiles` (or any table that has a client UPDATE policy).

---

## Why — the concrete hole

`user_profiles` has an UPDATE policy `auth_id = auth.uid()` with **no column restriction** (verified in the P5 audit). RLS in Postgres gates **which rows** a user may update, but **not which columns**. So a user can update *every column of their own row*.

If an entitlement column lived on `user_profiles`, a user could set it themselves with a single PATCH using the **public anon key** → free unlimited usage / self-granted premium. This is the classic "Supabase + AI" monetization-bypass failure, and it's the exact scenario Bryan flagged ("being able to make their account have unlimited usage on their subscription").

---

## Verified-safe today (2026-06-16)

- **No** entitlement/tier table exists in the backend yet (M1 is local-only scaffolding) — nothing to tamper with server-side.
- The one live paywall gate — `couples.matches_revealed` (Desire Map reveal) — sits on `couples`, which has **no client write policy**. Only the service role flips it. ✅ **This is the pattern to copy.**

---

## What M1 must do

1. New `entitlements` (or `connection_entitlements`) table: `{ user_id | couple_id, tier, source, granted_at, expires_at, … }`.
2. RLS: SELECT scoped to the owner/couple; **no INSERT/UPDATE/DELETE policy** for clients.
3. Writes happen **only** via a verified edge function (e.g. validating an App Store / RevenueCat receipt server-side) running as the service role.
4. The client **reads** entitlement state and gates UI; it never writes it.
5. **Verify post-build:** attempt a direct PATCH of the entitlement row with a user JWT → must be rejected by RLS. (And a SELECT of another user's entitlement → rejected.)

---

## Verify before shipping M1

- Re-run `get_advisors(security)` after adding the table — confirm no new client-write exposure / missing-RLS error.
- Confirm `anon` has zero grant on the new table. P5d revoked anon from the **postgres**-owned default privileges, so a migration-created table starts locked — but verify (and remember the `supabase_admin`-owned defaults still grant anon for supabase_admin-created objects; user tables are postgres-created, so this is fine, but confirm the table owner).
- Apply via `supabase db push` (the CLI) — **not** the MCP `apply_migration` tool, which records mismatched timestamps and re-tangles migration history.

---

## References
- Memory: `[[supabase_security_posture]]` (the audit), `[[monetization_paywall_spec]]` (the product side).
- Pairing spec P5 — the audit that surfaced this rule.
