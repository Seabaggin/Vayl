-- Companion to 20260714120000. Same class of bug: three Path FKs referenced
-- user_profiles with NO ACTION, so deleting a profile (and therefore the whole
-- account, since user_profiles.auth_id is ON DELETE CASCADE from auth.users)
-- would 500 for any user who had Path data. The tables are empty today, but this
-- makes account deletion robust before the Path feature ships.
--
--   path_activity_log.actor_id     NOT NULL  -> CASCADE  (an actor's log entries die with them)
--   path_landmark_progress.set_by  NULLABLE  -> SET NULL (keep shared progress, forget who set it)
--   path_private_marks.profile_id  NOT NULL  -> CASCADE  (the user's own private marks)
--
-- Applied to prod ynhjlabjzauamntbyxdp 2026-07-14; verified zero blocking FKs
-- remain against auth.users or user_profiles.

alter table public.path_activity_log
  drop constraint path_activity_log_actor_id_fkey,
  add  constraint path_activity_log_actor_id_fkey
    foreign key (actor_id) references public.user_profiles(id) on delete cascade;

alter table public.path_landmark_progress
  drop constraint path_landmark_progress_set_by_fkey,
  add  constraint path_landmark_progress_set_by_fkey
    foreign key (set_by) references public.user_profiles(id) on delete set null;

alter table public.path_private_marks
  drop constraint path_private_marks_profile_id_fkey,
  add  constraint path_private_marks_profile_id_fkey
    foreign key (profile_id) references public.user_profiles(id) on delete cascade;
