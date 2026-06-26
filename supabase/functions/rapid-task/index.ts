// supabase/functions/rapid-task/index.ts
//
// Display name: "create-couple".  Slug: rapid-task  (the iOS app invokes this slug).
//
// Claims a pairing code and creates the couple.
//
// FIX (2026-06): couples.user_a / user_b are FOREIGN KEYS to user_profiles.id
// (PROFILE ids). The previous version inserted AUTH ids (created_by + the caller's
// JWT id), which FK-violated, so a couple was never actually created. We now resolve
// profile ids from the auth ids before inserting. Profile linkage still keys on auth_id.

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

    // Service client bypasses RLS for server-side writes.
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

    const { code } = await req.json()
    if (!code || typeof code !== "string") return json({ error: "Missing or invalid code" }, 400)
    const normalizedCode = code.trim().toUpperCase()

    // ── Fetch the unclaimed pairing code ──────────────────────────────
    const { data: pairingRow, error: fetchError } = await serviceClient
      .from("pairing_codes")
      .select("*")
      .eq("code", normalizedCode)
      .is("claimed_by", null)
      .single()
    if (fetchError || !pairingRow) return json({ error: "Code not found or already used" }, 404)

    if (new Date(pairingRow.expires_at) < new Date()) return json({ error: "Code has expired" }, 410)

    const creatorAuthId = pairingRow.created_by as string
    if (creatorAuthId === callerAuthId) return json({ error: "Cannot link with yourself" }, 400)

    // ── Resolve PROFILE ids from auth ids (couples.user_a/user_b → user_profiles.id) ──
    const { data: profiles, error: profErr } = await serviceClient
      .from("user_profiles")
      .select("id, auth_id")
      .in("auth_id", [creatorAuthId, callerAuthId])
    if (profErr || !profiles || profiles.length < 2) {
      return json({ error: "Both partners must have a profile before linking" }, 409)
    }
    const profileA = profiles.find((p) => p.auth_id === creatorAuthId)?.id
    const profileB = profiles.find((p) => p.auth_id === callerAuthId)?.id
    if (!profileA || !profileB) return json({ error: "Profile lookup failed" }, 409)

    // ── Guard: neither profile already in a couple ────────────────────
    const { data: existing } = await serviceClient
      .from("couples")
      .select("id")
      .or(`user_a.eq.${profileA},user_b.eq.${profileA},user_a.eq.${profileB},user_b.eq.${profileB}`)
    if (existing && existing.length > 0) return json({ error: "One or both users are already paired" }, 409)

    // ── Create the couple with PROFILE ids ────────────────────────────
    const { data: couple, error: coupleError } = await serviceClient
      .from("couples")
      .insert({
        user_a: profileA,
        user_b: profileB,
        shared_safe_word: "red",
        created_at: new Date().toISOString(),
      })
      .select()
      .single()
    if (coupleError || !couple) return json({ error: coupleError?.message ?? "Failed to create couple" }, 500)

    const coupleId = couple.id
    const linkedAt = new Date().toISOString()

    // ── Link both profiles (matched by auth_id) ───────────────────────
    const { error: updErr } = await serviceClient
      .from("user_profiles")
      .update({ couple_id: coupleId, is_linked: true, linked_at: linkedAt })
      .in("auth_id", [creatorAuthId, callerAuthId])
    if (updErr) return json({ error: "Failed to link profiles" }, 500)

    // ── Payer-portable entitlement: a new couple inherits Core if a member already bought
    //    (the buyer's lifetime follows them into a new connection). No-op when neither member
    //    holds an entitlement. Non-fatal — pairing must never fail on this. ──
    const { error: recErr } = await serviceClient
      .rpc("recompute_couple_entitlement", { p_couple_id: coupleId })
    if (recErr) console.error("recompute_couple_entitlement failed (non-fatal):", recErr.message)

    // ── Delete the single-use pairing code ────────────────────────────
    await serviceClient.from("pairing_codes").delete().eq("code", normalizedCode)

    return json({ couple_id: coupleId }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
