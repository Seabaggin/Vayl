// supabase/functions/get-partner/index.ts
//
// Slug: get-partner
//
// Returns ONLY the linked partner's display identity (name + pronouns +
// gender_identity, the composition-derivation input) for the
// calling user's couple. Why a function: user_profiles SELECT RLS is
// `auth_id = auth.uid()` (no cross-partner read), and RLS can't restrict
// columns — so this service-role function is how a partner's name reaches the
// client without exposing the rest of their row. Returns { partner: null } when
// the caller isn't linked or the partner hasn't set a name yet.

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

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing authorization header" }, 401)

    // Service client bypasses RLS for the column-scoped read below.
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    )
    // User client validates the caller's identity from their JWT.
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) return json({ error: "Unauthorized" }, 401)
    const callerAuthId = user.id

    // ── Caller's profile id + couple ──────────────────────────────────
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", callerAuthId)
      .single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ partner: null }, 200)   // not linked yet

    // ── The couple → the two member profile ids ───────────────────────
    const { data: couple, error: coupleErr } = await serviceClient
      .from("couples")
      .select("user_a, user_b")
      .eq("id", me.couple_id)
      .single()
    if (coupleErr || !couple) return json({ partner: null }, 200)

    const partnerProfileId = couple.user_a === me.id ? couple.user_b : couple.user_a
    if (!partnerProfileId) return json({ partner: null }, 200)

    // ── ONLY the partner's display identity — nothing else ────────────
    const { data: partner, error: partnerErr } = await serviceClient
      .from("user_profiles")
      .select("name, pronouns, gender_identity")
      .eq("id", partnerProfileId)
      .single()
    if (partnerErr || !partner) return json({ partner: null }, 200)

    return json(
      {
        partner: {
          name: partner.name ?? null,
          pronouns: partner.pronouns ?? null,
          gender: partner.gender_identity ?? null,
        },
      },
      200
    )
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
