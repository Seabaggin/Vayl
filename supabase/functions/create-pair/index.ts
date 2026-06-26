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

    // Get the auth token
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Parse request body
    const { code, requesterId } = await req.json()
    if (!code || !requesterId) {
      return new Response(
        JSON.stringify({ error: "Missing code or requesterId" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    // Create a Supabase client with SERVICE ROLE key
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // 1. Verify the pairing code is valid
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

    // 2. Check expiration
    const expiresAt = new Date(pairingRecord.expires_at)
    if (expiresAt < new Date()) {
      return new Response(JSON.stringify({ error: "Code has expired" }), {
        status: 410,
        headers: { "Content-Type": "application/json" },
      })
    }

    // 3. Make sure they're not pairing with themselves
    const partnerId = pairingRecord.user_id
    if (partnerId === requesterId) {
      return new Response(
        JSON.stringify({ error: "You can't pair with yourself" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    // 4. Check neither user is already in a couple
    const { data: existingCouples } = await supabase
      .from("couples")
      .select("id")
      .or(`user_a.eq.${requesterId},user_b.eq.${requesterId},user_a.eq.${partnerId},user_b.eq.${partnerId}`)

    if (existingCouples && existingCouples.length > 0) {
      return new Response(
        JSON.stringify({ error: "One or both users are already paired" }),
        {
          status: 409,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    // 5. Create the Couple
    const { data: couple, error: coupleError } = await supabase
      .from("couples")
      .insert({
        user_a: requesterId,
        user_b: partnerId,
        shared_safe_word: "red",
      })
      .select()
      .single()

    if (coupleError) {
      return new Response(JSON.stringify({ error: coupleError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    // 6. Mark both profiles as linked
    await supabase
      .from("user_profiles")
      .update({ is_linked: true })
      .in("id", [requesterId, partnerId])

    // 7. Mark the pairing code as used
    await supabase
      .from("pairing_codes")
      .update({ used: true })
      .eq("code", code.toUpperCase().trim())

    // 8. Return the couple
    return new Response(
      JSON.stringify({
        success: true,
        coupleId: couple.id,
        userA: requesterId,
        userB: partnerId,
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