// supabase/functions/delete-account/index.ts
//
// Slug: delete-account
//
// HARD-deletes the caller's account (App Store requirement). Service-role so it can
// write cross-partner + delete the auth user. The caller is resolved from their JWT —
// a caller can only ever delete THEIR OWN account (never a target id from the body).
//
// What it touches (verified against prod FKs, project ynhjlabjzauamntbyxdp):
//   • If in a couple: the OTHER member is reverted to unpaired/free (couple_id=null,
//     is_linked=false), then the `couples` row is DELETED. That delete cascades the
//     couple-scoped tables (desire_matches, desire_map_status, desire_reveal_progress,
//     entitlements, card_progress, couple_session_records, curated_sessions).
//   • The caller's `user_profiles` row is DELETED — cascades their own per-user rows
//     (desire_ratings, assessment_responses, assessment_results, desire_reveal_progress).
//   • The caller's auth user is deleted so the same Apple ID re-onboards clean.
// The partner's own artifacts (their desire_ratings, assessment_*) survive.

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

    // Service client bypasses RLS for the cross-partner + delete writes.
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
    const callerAuthId = user.id

    // ── Caller's profile (id + couple) ────────────────────────────────
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", callerAuthId)
      .single()
    // No profile row yet? Still delete the auth user so the account is gone.
    if (meErr || !me) {
      await serviceClient.auth.admin.deleteUser(callerAuthId).catch(() => {})
      return json({ deleted: true }, 200)
    }

    // ── Handle the couple (if any) ────────────────────────────────────
    if (me.couple_id) {
      const { data: couple } = await serviceClient
        .from("couples")
        .select("user_a, user_b")
        .eq("id", me.couple_id)
        .single()

      if (couple) {
        const partnerProfileId = couple.user_a === me.id ? couple.user_b : couple.user_a
        if (partnerProfileId) {
          // Revert the partner to unpaired/free. Their own rows are untouched.
          await serviceClient
            .from("user_profiles")
            .update({ couple_id: null, is_linked: false })
            .eq("id", partnerProfileId)
        }
      }

      // Delete the couple BEFORE the profile (user_a/user_b are ON DELETE SET NULL,
      // so deleting the profile first would leave a half-null couple). This cascades
      // all couple-scoped tables.
      const { error: coupleDelErr } = await serviceClient
        .from("couples")
        .delete()
        .eq("id", me.couple_id)
      if (coupleDelErr) return json({ error: "Could not dissolve couple" }, 500)
    }

    // ── Delete the caller's profile (cascades their own per-user rows) ─
    const { error: profileDelErr } = await serviceClient
      .from("user_profiles")
      .delete()
      .eq("id", me.id)
    if (profileDelErr) return json({ error: "Could not delete profile" }, 500)

    // ── Delete the auth user so the same Apple ID re-onboards clean ────
    const { error: authDelErr } = await serviceClient.auth.admin.deleteUser(callerAuthId)
    if (authDelErr) {
      // Profile is already gone; a lingering auth user with no profile is recoverable
      // (ensureRemoteProfile recreates one). Log server-side, still report success.
      console.error("delete-account: auth user delete failed:", authDelErr.message)
    }

    return json({ deleted: true }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
