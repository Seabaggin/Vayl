import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

serve(async (req) => {
  try {
    // Only allow POST
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Get the auth token from the request
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Parse the pairing code from the request body
    const { code } = await req.json()
    if (!code) {
      return new Response(JSON.stringify({ error: "Missing pairing code" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Create a Supabase client with the SERVICE ROLE key (server-side only)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Look up the pairing code
    const { data: pairingRecord, error: lookupError } = await supabase
      .from("pairing_codes")
      .select("code, user_id, expires_at, used")
      .eq("code", code.toUpperCase().trim())
      .eq("used", false)
      .single()

    if (lookupError || !pairingRecord) {
      return new Response(JSON.stringify({ error: "Invalid or expired code" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Check expiration
    const expiresAt = new Date(pairingRecord.expires_at)
    if (expiresAt < new Date()) {
      return new Response(JSON.stringify({ error: "Code has expired" }), {
        status: 410,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Get the profile name for display ("You're pairing with...")
    const { data: profile } = await supabase
      .from("user_profiles")
      .select("id, name, pronouns")
      .eq("id", pairingRecord.user_id)
      .single()

    return new Response(
      JSON.stringify({
        valid: true,
        partnerId: pairingRecord.user_id,
        partnerName: profile?.name || "Your partner",
        partnerPronouns: profile?.pronouns || "they/them",
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})