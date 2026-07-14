-- Account deletion left an orphaned auth.users row (email/PII), breaking the
-- App Store 5.1.1(v) "delete my account" requirement. Root cause: GoTrue's admin
-- deleteUser 500'd because pairing_codes had two FKs to auth.users with NO ACTION
-- (SQLSTATE 23503). The delete-account edge fn swallowed the error and still
-- reported success, so the failure was invisible.
--
-- Fix: make both FKs self-heal on user deletion.
--   created_by  is NOT NULL  -> ON DELETE CASCADE  (a pairing code dies with its creator)
--   claimed_by  is NULLABLE  -> ON DELETE SET NULL (keep the code, just un-claim it)
--
-- Applied to prod ynhjlabjzauamntbyxdp 2026-07-14; verified GoTrue deleteUser now
-- hard-deletes the auth user cleanly.

alter table public.pairing_codes
  drop constraint pairing_codes_created_by_fkey,
  add  constraint pairing_codes_created_by_fkey
    foreign key (created_by) references auth.users(id) on delete cascade;

alter table public.pairing_codes
  drop constraint pairing_codes_claimed_by_fkey,
  add  constraint pairing_codes_claimed_by_fkey
    foreign key (claimed_by) references auth.users(id) on delete set null;
