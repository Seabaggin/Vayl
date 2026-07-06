-- P5d — Revoke anon from default privileges (close the future-table exposure gap)
-- Pairing spec: docs/superpowers/specs/2026-06-15-pairing-implementation-spec.md (Segment P5)
-- Apply with: supabase db push   (NOT the MCP apply_migration tool — that records
-- server-side timestamps that don't match local filenames and re-tangles history.)
--
-- Why: P5b revoked anon from EXISTING tables, but the project's DEFAULT privileges
-- still auto-grant ALL on NEW tables/functions/sequences to the anon role. So any
-- future table (e.g. the M1 entitlement/tier tables) would silently re-expose to the
-- public anon key. This revokes anon from the defaults so future objects start
-- locked. `authenticated` + `service_role` defaults are untouched (the API still
-- works for signed-in users; RLS remains the row-level gate).

alter default privileges for role postgres in schema public revoke all on tables    from anon;
alter default privileges for role postgres in schema public revoke all on functions  from anon;
alter default privileges for role postgres in schema public revoke all on sequences  from anon;

-- Also drop the one residual existing grant the baseline surfaced: anon could execute
-- the curated_sessions trigger function via RPC. It's a SECURITY INVOKER trigger
-- (harmless to call directly, and revoking EXECUTE does NOT affect trigger firing),
-- but anon has no reason to hold it.
revoke all on function public.set_curated_sessions_updated_at() from anon;
