// supabase/functions/compute-desire-matches/index.ts
//
// Slug: compute-desire-matches
//
// Invoked by a partner when they finish their Desire Map. Service-role so it can read
// BOTH partners' raw desire_ratings (RLS is own-profile only) and write desire_matches +
// desire_map_status (no client write policy on either). Flow:
//   1. Mark the caller's side complete in desire_map_status.
//   2. Track is the V1 "curious" superset for everyone (see the track comment below).
//   3. If BOTH partners are complete, compute positive matches over items they BOTH rated,
//      EXCLUDING any item where either said notForMe (boundary → obscured from the partner),
//      write desire_matches (recomputed fresh, free reveal PINNED across recomputes), and
//      flag exactly one is_free_reveal with its locked-stub category denormalized.
//   isFreeReveal is server-authoritative — never client-set, or the paywall is bypassed.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { computeMatches, freeRevealIndex, stubCategory } from "./match-logic.ts"

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

    // ── Caller's profile + couple ─────────────────────────────────────
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id, nm_stage")
      .eq("auth_id", user.id)
      .single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ status: "unpaired" }, 200)

    const { data: couple, error: coupleErr } = await serviceClient
      .from("couples")
      .select("id, user_a, user_b")
      .eq("id", me.couple_id)
      .single()
    if (coupleErr || !couple) return json({ error: "Couple not found" }, 404)

    const callerIsA = couple.user_a === me.id

    // ── Couple track ──────────────────────────────────────────────────
    // V1 ships ONE curious-superset track for everyone (decision 2026-06-25, re-ratified in
    // the 2026-07-09 review): the client rater shows the curious set regardless of nm_stage,
    // so matching must too — the old either-curious rule let an established/established
    // couple land on a 12-item track the rater never actually used, silently shrinking the
    // both-rated intersection. Stage-based resolution returns with the V1.1 established copy.
    const track = "curious"

    // ── Mark the caller complete in desire_map_status (preserve partner's flag) ──
    const { data: existingStatus } = await serviceClient
      .from("desire_map_status")
      .select("*")
      .eq("couple_id", couple.id)
      .maybeSingle()

    const now = new Date().toISOString()
    const status = {
      couple_id: couple.id,
      track,
      partner_a_complete: existingStatus?.partner_a_complete ?? false,
      partner_b_complete: existingStatus?.partner_b_complete ?? false,
      partner_a_completed_at: existingStatus?.partner_a_completed_at ?? null,
      partner_b_completed_at: existingStatus?.partner_b_completed_at ?? null,
      waiting_state_since: existingStatus?.waiting_state_since ?? now,
    }
    if (callerIsA) { status.partner_a_complete = true; status.partner_a_completed_at = now }
    else { status.partner_b_complete = true; status.partner_b_completed_at = now }

    await serviceClient.from("desire_map_status").upsert(status, { onConflict: "couple_id" })

    const bothComplete = status.partner_a_complete && status.partner_b_complete
    if (!bothComplete) return json({ status: "waiting", track }, 200)

    // ── Both complete → compute matches over BOTH partners' ratings ───
    const { data: ratings, error: ratingsErr } = await serviceClient
      .from("desire_ratings")
      .select("user_id, desire_item_id, rating")
      .in("user_id", [couple.user_a, couple.user_b])
    if (ratingsErr) return json({ error: "Could not read ratings" }, 500)

    const byA: Record<string, string> = {}
    const byB: Record<string, string> = {}
    for (const r of ratings ?? []) {
      if (r.user_id === couple.user_a) byA[r.desire_item_id] = r.rating
      else if (r.user_id === couple.user_b) byB[r.desire_item_id] = r.rating
    }

    // The currently-pinned free reveal, read BEFORE the recompute wipes the table —
    // freeRevealIndex keeps it on the same item while it still matches (pinning rule).
    const { data: prevFree } = await serviceClient
      .from("desire_matches")
      .select("desire_item_id")
      .eq("couple_id", couple.id)
      .eq("is_free_reveal", true)
      .maybeSingle()

    // Pure computation (see match-logic.ts): positive matches over items BOTH rated,
    // notForMe excluded, alignment-only output. `category` is the LOCKED-STUB category
    // (small categories pre-collapsed to null) — safe to hand to un-entitled clients.
    const computed = computeMatches(byA, byB)
    const rows: Record<string, unknown>[] = computed.map((m) => ({
      couple_id: couple.id,
      desire_item_id: m.desire_item_id,
      alignment_level: m.alignment_level,  // mutual / adjacent — the shareable signal
      bridge_card_id: null,                // companion-card stub — populated later
      is_free_reveal: false,
      category: stubCategory(m.desire_item_id),
      created_at: now,
    }))

    // Exactly one free reveal — the pinned item while it still matches, else prefer a
    // mutual, else the first adjacent.
    const freeIdx = freeRevealIndex(computed, prevFree?.desire_item_id ?? null)
    if (freeIdx >= 0) rows[freeIdx].is_free_reveal = true

    // Recompute fresh: clear prior matches for this couple, then insert.
    await serviceClient.from("desire_matches").delete().eq("couple_id", couple.id)
    if (rows.length > 0) {
      const { error: insErr } = await serviceClient.from("desire_matches").insert(rows)
      if (insErr) return json({ error: "Could not write matches" }, 500)
    }

    return json({ status: "computed", track, matchCount: rows.length }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
