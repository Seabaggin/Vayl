// supabase/functions/grant-entitlement/index.ts
//
// Slug: grant-entitlement
//
// The ONLY path that grants Core to a couple. Service-role so it can write the
// service-role-only `entitlements` ledger and flip `couples.access_tier` (neither table has a
// client write policy). One purchase covers BOTH partners — the entitlement is couple-level.
//
// Authorization (V1 / couple-core). Two server-authoritative paths converge on the SAME write;
// a caller can only ever grant THEIR OWN couple (couple_id is resolved from the caller's
// profile server-side, never read from the request body):
//
//   1. Apple receipt path (production): the client posts its StoreKit 2 signed transaction
//      (JWS). The server verifies Apple's signature + claims, then grants. This is what the
//      paywall doc means by "server-side receipt validation, never client-only."
//      ⚠️ M1 SEAM — the cryptographic JWS verification is wired in M2. It needs the App Store
//      Connect product, appAppleId, and Apple root certs, none of which exist yet. Until then
//      `verifyAppleTransaction` FAILS CLOSED (returns null) → the Apple path never grants, so
//      it cannot be used to bypass the paywall before M2 hardens it.
//
//   2. Admin / support path: a server-only secret (header x-grant-secret == ENTITLEMENT_GRANT_SECRET).
//      For support comps, founding-member grants, and M1 verification. Clients never hold the
//      secret, so this is not a bypass either.
//
// access_tier is server-authoritative — never client-set, or the paywall is bypassed.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-grant-secret",
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

// Product → tier. V1 couple-core has exactly one paid product.
const PRODUCT_TIER: Record<string, string> = {
  "com.vayl.core.lifetime": "core",
}

// ── Apple StoreKit 2 JWS verification ──────────────────────────────────────────
// M1 SEAM (fail-closed). M2 implements this with Apple's app-store-server-library
// `SignedDataVerifier`: verify the x5c chain to Apple's G3 root, verify the ES256 signature,
// then validate bundleId + productId + environment from the decoded payload, and return the
// verified transactionId. Until M2 wires the verifier + App Store Connect config (gated by the
// APPLE_VERIFICATION_ENABLED env flag), this returns null and the Apple path never grants.
async function verifyAppleTransaction(
  _signedTransaction: string,
  _expectedProductId: string,
): Promise<{ transactionId: string } | null> {
  const enabled = Deno.env.get("APPLE_VERIFICATION_ENABLED") === "true"
  if (!enabled) return null // fail closed — M2 turns this on with real verification
  // M2:
  //   const verifier = new SignedDataVerifier(appleRootCAs, true, environment, bundleId, appAppleId)
  //   const payload = await verifier.verifyAndDecodeTransaction(signedTransaction)
  //   if (payload.productId !== expectedProductId) return null
  //   return { transactionId: payload.transactionId }
  return null
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing authorization header" }, 401)

    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } },
    )
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) return json({ error: "Unauthorized" }, 401)

    // Caller's profile + couple. couple_id comes from the SERVER, never the request body —
    // a caller can only grant the couple they belong to.
    const { data: me, error: meErr } = await serviceClient
      .from("user_profiles")
      .select("id, couple_id")
      .eq("auth_id", user.id)
      .single()
    if (meErr || !me) return json({ error: "Profile not found" }, 404)
    if (!me.couple_id) return json({ error: "unpaired" }, 400)

    const body = await req.json().catch(() => ({}))
    const productId: string = typeof body.productId === "string" ? body.productId : "com.vayl.core.lifetime"
    const tier = PRODUCT_TIER[productId]
    if (!tier) return json({ error: "Unknown product" }, 400)

    // ── Authorize the grant (server-authoritative) ──
    let transactionId: string | null = null

    if (typeof body.signedTransaction === "string" && body.signedTransaction.length > 0) {
      const verified = await verifyAppleTransaction(body.signedTransaction, productId)
      if (verified) transactionId = verified.transactionId
    }

    const adminSecret = Deno.env.get("ENTITLEMENT_GRANT_SECRET")
    const adminAuthorized = !!adminSecret && req.headers.get("x-grant-secret") === adminSecret
    if (!transactionId && adminAuthorized) {
      transactionId = typeof body.transactionId === "string" && body.transactionId.length > 0
        ? body.transactionId
        : `admin-${me.couple_id}-${productId}`
    }

    if (!transactionId) {
      // Neither a verified Apple receipt nor an admin grant. The Apple path is the M2 seam and
      // fails closed, so this refusal is what keeps the paywall intact until M2.
      return json({ error: "Purchase could not be validated" }, 402)
    }

    // Founding-member is server-determined: in V1 (pre-Act-2) every Core buyer is a founding
    // member by definition. Flip FOUNDING_WINDOW_CLOSED=true to end the window later.
    const isFoundingMember = Deno.env.get("FOUNDING_WINDOW_CLOSED") !== "true"

    // ── Service-role write: ledger row (idempotent on transaction_id) ──
    const { error: insErr } = await serviceClient.from("entitlements").upsert({
      couple_id: me.couple_id,
      product_id: productId,
      transaction_id: transactionId,
      purchased_by: me.id,        // support only — never returned to either partner
      is_active: true,
      expires_at: null,           // Core is lifetime
      is_founding_member: isFoundingMember,
    }, { onConflict: "transaction_id" })
    if (insErr) return json({ error: "Could not record entitlement" }, 500)

    // ── Resolve + cache the couple's tier from the ledger (payer-portable + refund-aware).
    //    recompute_couple_entitlement derives access_tier / founding / unlocked-at from the
    //    entitlements rows — so this same path handles direct grants, portability, and refunds. ──
    const { data: resolvedTier, error: recErr } = await serviceClient
      .rpc("recompute_couple_entitlement", { p_couple_id: me.couple_id })
    if (recErr) return json({ error: "Could not unlock couple" }, 500)

    // Tier only — never echo purchased_by / transaction_id back to the client.
    return json({ tier: resolvedTier ?? tier, coupleId: me.couple_id }, 200)
  } catch (_err) {
    return json({ error: "Internal server error" }, 500)
  }
})
