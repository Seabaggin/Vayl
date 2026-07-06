-- Tightens pulse_entries partner visibility to position-only. The original
-- "pulse_entries read" policy (20260702160443) let a partner SELECT the full row,
-- including the raw Q1-Q5 text answers (nervous_system/focus/feeling/capacity/
-- speed) — that contradicts the existing Settings promise ("Your partner sees your
-- Pulse capacity, not your answers.", SettingsPrivacyView.swift). Nothing in the Us
-- layer ever reads the text columns (only resolvedPosition.quadrant), so nothing
-- observable changes — this closes a privacy surface that was never needed.
--
-- Own reads still see everything (needed for reinstall/device-switch hydration).
-- Partner reads now go ONLY through get_partner_pulse_positions(), a SECURITY
-- DEFINER function (same pattern as the existing is_couple_member helper) that
-- returns just profile_id/entry_date/energy/openness/capacity_score.

drop policy if exists "pulse_entries read" on public.pulse_entries;

create policy "pulse_entries read own"
  on public.pulse_entries for select
  using (
    profile_id in (select user_profiles.id from public.user_profiles where user_profiles.auth_id = auth.uid())
  );

create or replace function public.get_partner_pulse_positions()
returns table (
  profile_id     uuid,
  entry_date     timestamp with time zone,
  energy         real,
  openness       real,
  capacity_score real
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select pe.profile_id, pe.entry_date, pe.energy, pe.openness, pe.capacity_score
  from public.pulse_entries pe
  join public.user_profiles me on me.auth_id = auth.uid()
  where pe.profile_id != me.id
    and pe.couple_id is not null
    and pe.couple_id = me.couple_id
    and exists (
      select 1 from public.user_profiles owner
      where owner.id = pe.profile_id
        and owner.share_pulse_with_partner = true
    );
end;
$$;

grant execute on function public.get_partner_pulse_positions() to authenticated;
