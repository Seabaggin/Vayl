// supabase/functions/consent-ask/index.ts
//
// Slug: consent-ask
//
// The asker requests to open a conversation about one desire item. Service-role so it can
// upsert consent_requests (no client write policy). Creates/refreshes a 'pending' request
// for (couple, item). If a prior decline exists this still returns ok and leaves it pending
// — the asker's view is identical either way (a decline never discloses). If the request is
// already 'opened', it is left untouched.

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

    const { item_id } = await req.json()
    if (!item_id || typeof item_id !== "string") return json({ error: "Missing item_id" }, 400)

    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles").select("id, couple_id").eq("auth_id", user.id).single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ status: "unpaired" }, 200)

    // Already opened? Leave it.
    const { data: existing } = await serviceClient
      .from("consent_requests").select("status")
      .eq("couple_id", me.couple_id).eq("item_id", item_id).maybeSingle()
    if (existing?.status === "opened") return json({ ok: true, status: "opened" }, 200)

    await serviceClient.from("consent_requests").upsert(
      { couple_id: me.couple_id, item_id, asker_id: me.id, status: "pending" },
      { onConflict: "couple_id,item_id" }
    )
    return json({ ok: true, status: "pending" }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
