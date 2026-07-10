-- Fast partner-disconnect detection for the live Card Session.
-- Presence alone (Phoenix socket heartbeat) takes 30s+ to notice a hard-killed
-- app; each device now stamps its own last_seen every few seconds and the
-- partner device polls it, flagging disconnect within ~10s.
-- Additive only. Nullable: NULL = this role has never heartbeated (session
-- start), and the client falls back to channel presence alone.

alter table public.curated_sessions
    add column if not exists a_last_seen timestamptz,
    add column if not exists b_last_seen timestamptz;

comment on column public.curated_sessions.a_last_seen is
    'Partner A liveness heartbeat — stamped by device A every ~4s while the session is live.';
comment on column public.curated_sessions.b_last_seen is
    'Partner B liveness heartbeat — stamped by device B every ~4s while the session is live.';
