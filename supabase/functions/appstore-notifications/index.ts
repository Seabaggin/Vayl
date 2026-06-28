// supabase/functions/appstore-notifications/index.ts
//
// Slug: appstore-notifications
//
// Apple App Store Server Notifications V2 receiver. Apple POSTs a signed notification here when
// a purchase changes server-side (REFUND, REVOKE, etc.). For a refund/revocation of Core we flip
// the matching `entitlements` row inactive and recompute the couple's tier — which drops the
// couple (BOTH partners) back to `free`. This closes the leak where the non-paying partner keeps
// access after the buyer is refunded.
//
// The downgrade itself is already supported by the schema: `resolve_couple_access_tier` only
// counts ACTIVE entitlements, and `recompute_couple_entitlement` re-derives `couples.access_tier`
// from the ledger. So this function only has to (1) trust Apple, (2) deactivate the row,
// (3) recompute.
//
// SECURITY:
//  • Public endpoint — Apple calls it with no Supabase JWT. Deployed with `verify_jwt = false`.
//    The ONLY thing trusted is Apple's signature on the payload (verified below).
//  • Service-role client for the writes (entitlements has no client write policy).
//
// VERIFICATION (gated, fail-closed):
//  Uses Apple's app-store-server-library `SignedDataVerifier` — the SAME verifier the purchase
//  path (grant-entitlement) uses, so both behave identically. It is loaded lazily and ONLY when
//  APPLE_VERIFICATION_ENABLED=true, so while the flag is off the library is never imported and an
//  unverified call can never downgrade a couple. Env it reads (set via supabase secrets):
//    APPLE_VERIFICATION_ENABLED=true
//    APPLE_ROOT_CERTS = comma-separated base64 DER of Apple's root cert(s) (AppleRootCA-G3)
//    APPLE_BUNDLE_ID  = com.bryanjorden.Vayl
//    APPLE_APP_APPLE_ID = 6785124476

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

// Notification types we act on. For a one-time non-consumable, a refund or a Family-Sharing
// revocation are the only events that remove access. Everything else is acknowledged + ignored.
const DOWNGRADE_TYPES = new Set(["REFUND", "REVOKE"])

interface DecodedNotification {
  notificationType: string
  subtype: string | null
  transactionId: string | null
  originalTransactionId: string | null
  productId: string | null
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
    const p = decodeJwsPayload(jws) as { data?: { environment?: string }; environment?: string }
    return (p?.data?.environment ?? p?.environment) === "Production" ? "Production" : "Sandbox"
  } catch {
    return "Sandbox"
  }
}

// ── Apple App Store Server Notifications V2 verification ────────────────────────
// Fail-closed: returns null unless APPLE_VERIFICATION_ENABLED=true AND the signature verifies.
async function verifyAppleNotification(
  signedPayload: string,
): Promise<DecodedNotification | null> {
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
      console.error("appstore-notifications: APPLE_ROOT_CERTS not set")
      return null
    }

    const bundleId = Deno.env.get("APPLE_BUNDLE_ID") ?? ""
    const appAppleId = Number(Deno.env.get("APPLE_APP_APPLE_ID") ?? "0") || undefined
    const env = peekEnvironment(signedPayload) === "Production"
      ? Environment.PRODUCTION
      : Environment.SANDBOX

    // enableOnlineChecks=true → OCSP certificate-revocation checks (Apple-recommended).
    const verifier = new SignedDataVerifier(rootCerts, true, env, bundleId, appAppleId)
    const notification = await verifier.verifyAndDecodeNotification(signedPayload)
    const signedTx = notification.data?.signedTransactionInfo
    const tx = signedTx ? await verifier.verifyAndDecodeTransaction(signedTx) : null

    return {
      notificationType: notification.notificationType ?? "",
      subtype: notification.subtype ?? null,
      transactionId: tx?.transactionId ?? null,
      originalTransactionId: tx?.originalTransactionId ?? null,
      productId: tx?.productId ?? null,
    }
  } catch (e) {
    console.error("appstore-notifications: verification failed", e)
    return null
  }
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  try {
    const body = await req.json().catch(() => ({}))
    const signedPayload: string =
      typeof body.signedPayload === "string" ? body.signedPayload : ""
    if (!signedPayload) return json({ error: "Missing signedPayload" }, 400)

    const notification = await verifyAppleNotification(signedPayload)

    // Unverified (flag off, or a forged/misconfigured call). Acknowledge so Apple does not retry-
    // storm, but never act on an unverified payload.
    if (!notification) return json({ ok: true, acted: false, reason: "unverified" }, 200)

    // Only refunds / revocations remove access. Acknowledge everything else.
    if (!DOWNGRADE_TYPES.has(notification.notificationType)) {
      return json({ ok: true, acted: false, type: notification.notificationType }, 200)
    }

    const ids = [notification.transactionId, notification.originalTransactionId].filter(
      (v): v is string => typeof v === "string" && v.length > 0,
    )
    if (ids.length === 0) return json({ ok: true, acted: false, reason: "no transaction id" }, 200)

    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } },
    )

    // Deactivate the matching ledger row(s). Idempotent — a re-delivered notification just
    // re-sets is_active=false. Match on either id (for a non-consumable they are the same).
    const { data: deactivated, error: updErr } = await serviceClient
      .from("entitlements")
      .update({ is_active: false })
      .in("transaction_id", ids)
      .select("couple_id")
    if (updErr) {
      console.error("appstore-notifications: deactivate failed", updErr)
      return json({ error: "Could not deactivate entitlement" }, 500)
    }

    // Recompute each affected couple — drops access_tier back to free if no active entitlement
    // remains (payer-portable: a different active entitlement would keep them Core).
    const coupleIds = [...new Set((deactivated ?? []).map((r) => r.couple_id))]
    for (const coupleId of coupleIds) {
      const { error: recErr } = await serviceClient.rpc("recompute_couple_entitlement", {
        p_couple_id: coupleId,
      })
      if (recErr) {
        console.error("appstore-notifications: recompute failed", coupleId, recErr)
        return json({ error: "Could not recompute couple" }, 500)
      }
    }

    console.log(
      `appstore-notifications: ${notification.notificationType} — deactivated ${deactivated?.length ?? 0} row(s), recomputed ${coupleIds.length} couple(s)`,
    )
    return json({ ok: true, acted: true, couples: coupleIds.length }, 200)
  } catch (err) {
    console.error("appstore-notifications: error", err)
    return json({ error: "Internal server error" }, 500)
  }
})
