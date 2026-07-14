// supabase/functions/delete-account/index.ts
//
// Slug: delete-account
//
// HARD-deletes the caller's account (App Store 5.1.1(v) requirement). Service-role so it
// can write cross-partner + delete the auth user. The caller is resolved from their JWT —
// a caller can only ever delete THEIR OWN account (never a target id from the body).
//
// Order of operations (why it is this order):
//   1. If in a couple: revert the OTHER member to unpaired/free (couple_id=null,
//      is_linked=false), then DELETE the `couples` row. Must happen while the caller's
//      profile still exists (couples.user_a/user_b are ON DELETE SET NULL → deleting the
//      profile first would leave a half-null couple). Deleting the couple cascades the
//      couple-scoped tables (desire_matches, desire_map_status, entitlements, card_progress,
//      couple_session_records, curated_sessions, …).
//   2. DELETE the caller's auth user. This is the AUTHORITATIVE step: user_profiles.auth_id
//      is ON DELETE CASCADE, so removing the auth user removes the profile in the same
//      operation, which in turn cascades every per-user row (desire_ratings, assessment_*,
//      pulse_entries, pairing_codes, path_* …). We rely on the cascade instead of deleting
//      the profile separately, so the profile can NEVER outlive the auth identity or vice
//      versa — the account is gone as one atomic unit or not at all.
//
// CRITICAL (do not regress): if the auth-user delete fails we return a NON-200 error and do
// NOT report success. A prior version swallowed this error and returned {deleted:true} while
// the auth identity (email/PII) survived — a partial deletion that fails App Store review.
// For that to succeed, EVERY foreign key into auth.users and user_profiles must be
// ON DELETE CASCADE or SET NULL (see migrations 20260714120000 / 20260714120100). Any new
// table referencing those with NO ACTION will re-break account deletion — add a cascade rule.

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

    // ── Caller's profile (id + couple), if one exists ─────────────────
    // maybeSingle: a caller with no profile row yet is valid — we still delete their auth user.
    const { data: me } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", callerAuthId)
      .maybeSingle()

    // ── Handle the couple (while the profile still exists) ────────────
    if (me?.couple_id) {
      const { data: couple } = await serviceClient
        .from("couples")
        .select("user_a, user_b")
        .eq("id", me.couple_id)
        .maybeSingle()

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

      const { error: coupleDelErr } = await serviceClient
        .from("couples")
        .delete()
        .eq("id", me.couple_id)
      if (coupleDelErr) {
        console.error("delete-account: couple delete failed:", coupleDelErr.message)
        return json({ error: "Could not dissolve couple. Please try again." }, 500)
      }
    }

    // ── Authoritative delete: the auth user (cascades the profile + all per-user rows) ──
    const { error: authDelErr } = await serviceClient.auth.admin.deleteUser(callerAuthId)
    if (authDelErr) {
      // Do NOT report success — the account (auth identity + email) must actually be gone.
      console.error("delete-account: auth user delete failed:", authDelErr.message)
      return json({ error: "Could not delete account. Please try again." }, 500)
    }

    return json({ deleted: true }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
