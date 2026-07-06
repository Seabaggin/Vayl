// supabase/functions/unlink-partner/index.ts
//
// Slug: unlink-partner
//
// Dissolves the caller's couple. Service-role so it can write cross-partner.
// The caller is resolved from their JWT — a caller can only ever unlink THEIR
// OWN couple (never a target id from the body). Idempotent: an unlinked caller
// gets { unlinked: true }.
//
// Semantics match delete-account's dissolve (Open Decision A, fable plan 04),
// minus any deletion of people:
//   • BOTH members are reverted to unpaired (couple_id=null, is_linked=false).
//   • The `couples` row is then DELETED — cascading the couple-scoped tables
//     (desire_matches, desire_map_status, desire_reveal_progress, entitlements,
//     card_progress, couple_session_records, curated_sessions).
//   • Each person's own per-user rows (desire_ratings, assessment_*) survive.
//   • Entitlement is payer-portable: the buyer's StoreKit ownership re-grants
//     Core on their next pairing via recompute_couple_entitlement.
// Profiles are reverted BEFORE the couple delete so the flow never depends on
// the user_profiles.couple_id FK delete rule.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing authorization header" }, 401)

    // Service client bypasses RLS for the cross-partner writes.
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } },
    )
    // User client validates the caller's identity from their JWT.
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) return json({ error: "Unauthorized" }, 401)

    // ── Caller's profile (id + couple) ────────────────────────────────
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", user.id)
      .single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ unlinked: true }, 200)   // already unlinked

    const coupleId = me.couple_id

    // ── Revert BOTH members to unpaired (before the couple delete) ────
    const { error: revertErr } = await serviceClient
      .from("user_profiles")
      .update({ couple_id: null, is_linked: false })
      .eq("couple_id", coupleId)
    if (revertErr) return json({ error: "Could not unlink members" }, 500)

    // ── Delete the couple — cascades all couple-scoped shared tables ──
    const { error: coupleDelErr } = await serviceClient
      .from("couples")
      .delete()
      .eq("id", coupleId)
    if (coupleDelErr) return json({ error: "Could not dissolve couple" }, 500)

    return json({ unlinked: true }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
