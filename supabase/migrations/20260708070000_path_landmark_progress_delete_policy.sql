-- Follow-up to 20260708060208_path_node_state_tables.sql (Task 9 review fix).
--
-- PathStore.restore() calls PathTransport.deleteProgress(...) to remove a
-- landmark's progress row outright (`.untouched` is never persisted — see
-- PathLandmarkProgress.swift). PathSyncService issues a real `.delete()`
-- against path_landmark_progress, but the original migration only granted
-- SELECT/INSERT/UPDATE policies on that table. Under Postgres RLS, a DELETE
-- with no matching policy affects 0 rows and returns success with no error —
-- so restore() would locally clear progressByLandmark and show `.untouched`
-- immediately, while the remote `.skipped` row survived and resurfaced on the
-- next load() (relaunch, pull-to-refresh, partner's realtime sync). This adds
-- the missing couple-scoped DELETE policy, mirroring the existing
-- SELECT/INSERT/UPDATE policies on the same table.

create policy "Partners can delete path progress"
  on public.path_landmark_progress for delete
  using (
    couple_id in (
      select couples.id from public.couples
      where couples.user_a in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
         or couples.user_b in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
    )
  );
