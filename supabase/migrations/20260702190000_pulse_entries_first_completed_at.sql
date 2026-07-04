-- Anchors the client's 2-hour edit window across relaunch/hydration. Without this,
-- a hydrateFromServer() merge after a same-day edit would fall back to entry_date
-- (the edit's timestamp, not the original), silently extending the window on every
-- relaunch. This column always holds the TRUE first-completion moment.
alter table public.pulse_entries
  add column if not exists first_completed_at timestamp with time zone not null default now();
