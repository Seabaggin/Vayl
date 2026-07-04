-- CREATE FUNCTION grants EXECUTE to PUBLIC (including anon) by default. Close
-- that off explicitly — this SECURITY DEFINER function should only ever run for
-- a signed-in caller (auth.uid() is NULL for anon, so today it'd just return zero
-- rows, but there's no reason to leave it callable at all).
revoke execute on function public.get_partner_pulse_positions() from public;
grant execute on function public.get_partner_pulse_positions() to authenticated;
