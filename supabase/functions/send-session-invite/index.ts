// send-session-invite — Seg 8 (push) edge function.
// STATUS: UNVERIFIED / NOT DEPLOYED. Skeleton only. The APNs send is stubbed.
//
// What works here: validates the caller, looks up the partner's device tokens.
// What is YOURS to finish (needs an Apple Developer account; cannot be done here):
//   - Store APNs secrets as function secrets: APNS_KEY_ID, APNS_TEAM_ID,
//     APNS_AUTH_KEY (.p8 contents), APNS_TOPIC (the app bundle id), APNS_HOST
//     (api.sandbox.push.apple.com for dev, api.push.apple.com for prod).
//   - Implement sendAPNs(): build the provider JWT (ES256 over {iss:TEAM,iat} with
//     kid=KEY_ID), POST to https://${APNS_HOST}/3/device/${token} with the bearer
//     JWT + apns-topic header + JSON aps payload.
//   - Deploy: `supabase functions deploy send-session-invite`.

import { createClient } from "jsr:@supabase/supabase-js@2";

interface InvitePayload {
  sessionId: string;
  recipientUserId: string; // the partner to ping
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { sessionId, recipientUserId } = (await req.json()) as InvitePayload;
  if (!sessionId || !recipientUserId) {
    return new Response("Missing sessionId or recipientUserId", { status: 400 });
  }

  // Service-role client — sending pushes is never a client capability.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: tokens, error } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", recipientUserId);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "no tokens" }), { status: 200 });
  }

  let sent = 0;
  for (const { token } of tokens) {
    // TODO(Seg 8): replace with a real APNs send (provider JWT + POST). See header.
    const ok = await sendAPNs(token, {
      title: "Your partner is ready",
      body: "Tap to join the session.",
      sessionId,
    });
    if (ok) sent++;
  }

  return new Response(JSON.stringify({ sent }), {
    headers: { "Content-Type": "application/json" },
  });
});

// STUB — not a real APNs call. Returns false so nothing claims success until wired.
async function sendAPNs(
  _token: string,
  _payload: { title: string; body: string; sessionId: string },
): Promise<boolean> {
  // TODO(Seg 8): build ES256 provider JWT from APNS_* secrets and POST to APNs.
  return false;
}
