// supabase/functions/consent-respond/index.ts
//
// Slug: consent-respond
//
// The PARTNER (never the asker) opens or declines a pending request. Service-role.
//   open    -> consent_requests.status = 'opened' (+ a neutral discussion card, the same
//              regardless of where either side landed, so it never telegraphs an answer).
//   decline -> insert consent_declines (decided_by = me) and LEAVE consent_requests at
//              'pending'. The asker keeps seeing 'pending', so a decline never discloses.
// The response is identical for open and decline (so even response shape does not leak).

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

    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    )
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) return json({ error: "Unauthorized" }, 401)

    const { item_id, decision } = await req.json()
    if (!item_id || (decision !== "open" && decision !== "decline")) {
      return json({ error: "Bad request" }, 400)
    }

    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles").select("id, couple_id").eq("auth_id", user.id).single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ status: "unpaired" }, 200)

    const { data: request } = await serviceClient
      .from("consent_requests").select("asker_id, status")
      .eq("couple_id", me.couple_id).eq("item_id", item_id).maybeSingle()

    // Only the partner responds, and only to a pending request. Return ok regardless so
    // the response never reveals state.
    if (!request || request.asker_id === me.id || request.status !== "pending") {
      return json({ ok: true }, 200)
    }

    if (decision === "open") {
      await serviceClient.from("consent_requests")
        .update({ status: "opened", opened_at: new Date().toISOString(), discussion_card_id: "neutral" })
        .eq("couple_id", me.couple_id).eq("item_id", item_id)
    } else {
      // decline: record it (decliner-readable only) and leave the request pending.
      await serviceClient.from("consent_declines")
        .insert({ couple_id: me.couple_id, item_id, decided_by: me.id })
    }
    return json({ ok: true }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
