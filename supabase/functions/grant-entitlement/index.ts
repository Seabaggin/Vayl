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
//      Verification is gated by APPLE_VERIFICATION_ENABLED and fails closed (returns null) until
//      the env (root certs, bundleId, appAppleId) is set — so it cannot bypass the paywall.
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

// Decode a JWS payload segment WITHOUT verifying — only to read the environment so we can build
// the verifier for the right environment. Trust still comes from the signature check that follows.
function decodeJwsPayload(jws: string): Record<string, unknown> {
  const seg = jws.split(".")[1] ?? ""
  const b64 = seg.replace(/-/g, "+").replace(/_/g, "/")
  const pad = b64.length % 4 ? "=".repeat(4 - (b64.length % 4)) : ""
  return JSON.parse(atob(b64 + pad))
}

function peekEnvironment(jws: string): "Production" | "Sandbox" {
  try {
    const p = decodeJwsPayload(jws) as { environment?: string }
    return p?.environment === "Production" ? "Production" : "Sandbox"
  } catch {
    return "Sandbox"
  }
}

// ── Apple StoreKit 2 JWS verification ──────────────────────────────────────────
// Verifies the client's signed transaction with Apple's app-store-server-library
// `SignedDataVerifier` (the SAME verifier appstore-notifications uses). Fail-closed: returns null
// unless APPLE_VERIFICATION_ENABLED=true AND the signature verifies AND the product matches. The
// library is imported lazily so it is never loaded while the flag is off. Env (supabase secrets):
//   APPLE_VERIFICATION_ENABLED=true
//   APPLE_ROOT_CERTS = comma-separated base64 DER of Apple's root cert(s) (AppleRootCA-G3)
//   APPLE_BUNDLE_ID  = com.bryanjorden.Vayl
//   APPLE_APP_APPLE_ID = 6785124476
async function verifyAppleTransaction(
  signedTransaction: string,
  expectedProductId: string,
): Promise<{ transactionId: string } | null> {
  if (Deno.env.get("APPLE_VERIFICATION_ENABLED") !== "true") return null
  try {
    const { SignedDataVerifier, Environment } = await import(
      "npm:@apple/app-store-server-library"
    )
    const { Buffer } = await import("node:buffer")

    const rootCerts = (Deno.env.get("APPLE_ROOT_CERTS") ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((b64) => Buffer.from(b64, "base64"))
    if (rootCerts.length === 0) {
      console.error("grant-entitlement: APPLE_ROOT_CERTS not set")
      return null
    }

    const bundleId = Deno.env.get("APPLE_BUNDLE_ID") ?? ""
    const appAppleId = Number(Deno.env.get("APPLE_APP_APPLE_ID") ?? "0") || undefined
    const env = peekEnvironment(signedTransaction) === "Production"
      ? Environment.PRODUCTION
      : Environment.SANDBOX

    const verifier = new SignedDataVerifier(rootCerts, true, env, bundleId, appAppleId)
    const tx = await verifier.verifyAndDecodeTransaction(signedTransaction)
    if (tx.productId !== expectedProductId) return null
    return { transactionId: tx.transactionId }
  } catch (e) {
    console.error("grant-entitlement: verification failed", e)
    return null
  }
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
      // Neither a verified Apple receipt nor an admin grant. The Apple path fails closed until
      // verification is enabled, so this refusal is what keeps the paywall intact.
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
