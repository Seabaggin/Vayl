-- pushEntry's own delete-then-insert already enforces one row per profile per
-- day from the client side, but nothing in the schema itself stops a future
-- bug (or a second call site) from ever inserting a duplicate. This makes "one
-- entry per profile per day" a database guarantee, not just an app-level
-- convention. Truncated in UTC as an approximation of the client's
-- Calendar.current (device-local) day boundary — the two won't always agree
-- exactly at a day edge, but this is a backstop against accidental
-- duplication, not a strict mirror of the client's day logic.
create unique index if not exists pulse_entries_one_per_day
  on public.pulse_entries (profile_id, (date_trunc('day', entry_date at time zone 'utc')));
