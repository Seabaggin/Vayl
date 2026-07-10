-- The old uniqueness guarantee keyed on the UTC-truncated entry_date, but the
-- client's "one entry per day" is a LOCAL-calendar-day concept. A local day can
-- straddle two UTC days (Mon 9pm EDT is Tue 01:00 UTC), so a same-local-day
-- replace could land on a different UTC day than the row it meant to replace:
-- the delete missed, the insert hit the unique index, the error was swallowed
-- client-side, and that day never synced. Fix: store the local calendar day
-- explicitly (stamped by the client from its own Calendar) and key uniqueness
-- on that, so the client can upsert on (profile_id, entry_day) directly.
-- updated_at rides along for the client's newest-wins merge on hydrate.

alter table public.pulse_entries add column if not exists entry_day date;

-- Backfill from the UTC day of entry_date. An approximation for existing rows
-- (their true local day is unrecoverable server-side), acceptable: the next
-- client push for any of these days upserts the correct local value.
update public.pulse_entries
  set entry_day = (entry_date at time zone 'utc')::date
  where entry_day is null;

alter table public.pulse_entries alter column entry_day set not null;

alter table public.pulse_entries add column if not exists updated_at timestamp with time zone not null default now();

drop index if exists public.pulse_entries_one_per_day;

create unique index if not exists pulse_entries_one_per_local_day
  on public.pulse_entries (profile_id, entry_day);
