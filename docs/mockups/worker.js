const SUPABASE_URL = "https://ynhjlabjzauamntbyxdp.supabase.co";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }

    const url = new URL(request.url);

    // POST /submit — insert email
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

      // Get count via RPC
      const countRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_waitlist_count`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": env.SUPABASE_KEY,
          "Authorization": `Bearer ${env.SUPABASE_KEY}`,
        },
        body: "{}",
      });
      const count = countRes.ok ? await countRes.json() : null;

      return new Response(JSON.stringify({ ok: true, count }), {
        status: 200, headers: { "Content-Type": "application/json", ...CORS }
      });
    }

    return new Response("Not found", { status: 404 });
  }
};
