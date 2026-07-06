const SUPABASE_URL = "https://ynhjlabjzauamntbyxdp.supabase.co";
const RESEND_URL = "https://api.resend.com";
const FROM = "hello@intothevayl.app";
const AUDIENCE_ID = "125ba3b9-bcc2-4943-a431-a04a8c8126e4";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

async function sendConfirmation(email, apiKey) {
  return fetch(`${RESEND_URL}/emails`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      from: FROM,
      to: [email],
      subject: "You're in. Vayl is coming.",
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:0 auto;color:#111;">
          <p>Hey,</p>
          <p>You're on the Vayl waitlist. We're building something new for couples who want to explore non-monogamy together — on their own terms, at their own pace.</p>
          <p>I'll reach out before launch with everything you need to know.</p>
          <p>Stay close.</p>
          <p>— Bryan, Vayl</p>
        </div>
      `,
    }),
  });
}

async function addContact(email, apiKey) {
  return fetch(`${RESEND_URL}/contacts`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      email,
      audience_id: AUDIENCE_ID,
      unsubscribed: false,
    }),
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }

    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname === "/submit") {
      const { email } = await request.json();

      const res = await fetch(`${SUPABASE_URL}/rest/v1/waitlist`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": env.SUPABASE_KEY,
          "Authorization": `Bearer ${env.SUPABASE_KEY}`,
          "Prefer": "return=minimal",
        },
        body: JSON.stringify({ email }),
      });

      if (res.status === 409) {
        return new Response(JSON.stringify({ error: "duplicate" }), {
          status: 409, headers: { "Content-Type": "application/json", ...CORS }
        });
      }
      if (!res.ok) {
        return new Response(JSON.stringify({ error: "failed" }), {
          status: 500, headers: { "Content-Type": "application/json", ...CORS }
        });
      }

      // Get count, send confirmation email, and add to Resend contacts in parallel
      const [countRes] = await Promise.all([
        fetch(`${SUPABASE_URL}/rest/v1/rpc/get_waitlist_count`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": env.SUPABASE_KEY,
            "Authorization": `Bearer ${env.SUPABASE_KEY}`,
          },
          body: "{}",
        }),
        sendConfirmation(email, env.RESEND_KEY),
        addContact(email, env.RESEND_KEY),
      ]);

      const count = countRes.ok ? await countRes.json() : null;

      return new Response(JSON.stringify({ ok: true, count }), {
        status: 200, headers: { "Content-Type": "application/json", ...CORS }
      });
    }

    return new Response("Not found", { status: 404 });
  }
};
