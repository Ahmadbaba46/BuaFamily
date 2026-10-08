// The 'korapay' Edge Function.
//
//   POST {action: "start", amount, cause_id?, dues_plan_id?, show_name?}  (signed in)
//     → {reference, checkout_url}
//   POST {action: "start", amount, event_id, anonymous?, note?}              (signed in)
//     → the same, for a wedding or naming gift (held for the host)
//   POST {action: "check", reference}                                      (signed in)
//     → {status: "paid" | "failed" | "waiting"}
//   POST ?webhook=1  {event, data: {reference, ...}}                       (from Korapay)
//
// Deployed with verify_jwt = false so Korapay can reach the webhook; "start"
// and "check" check the member's sign-in themselves. A payment only counts once
// Korapay itself says it was paid (verifyCharge), whoever asked.

import { type ChargeState, initializeCharge, verifyCharge, webhookSignature } from "./korapay.ts";

export interface Db {
  rpc(fn: string, args?: Record<string, unknown>): Promise<{ data: any; error: { message: string } | null }>;
  userFromToken(token: string): Promise<string | null>;
  paymentOwner(reference: string): Promise<{ user_id: string; status: string } | null>;
}

export interface Env {
  supabaseUrl: string;
  siteUrl: string;
  fetch: typeof fetch;
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", ...cors } });

export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

async function settle(db: Db, env: Env, key: string, reference: string): Promise<ChargeState["state"]> {
  const state = await verifyCharge(env.fetch, key, reference);
  if (state.state === "paid") {
    const { error } = await db.rpc("online_payment_paid", {
      p_reference: reference,
      p_amount: state.amount,
      p_fee: state.fee,
    });
    if (error) throw new Error(error.message);
  } else if (state.state === "failed") {
    await db.rpc("online_payment_failed", { p_reference: reference });
  }
  return state.state;
}

export async function handle(req: Request, db: Db, env: Env): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "POST only" });

  const { data: cfg, error: cfgError } = await db.rpc("korapay_config");
  if (cfgError) return json(500, { error: cfgError.message });
  const key = cfg?.secret_key as string | null;

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "bad body" });
  }

  // Korapay telling us about a payment: check with Korapay, then record it.
  if (new URL(req.url).searchParams.has("webhook")) {
    const reference = body?.data?.reference;
    if (!key || typeof reference !== "string" || !reference.startsWith("bua-")) return json(200, { ignored: true });
    const signed = req.headers.get("x-korapay-signature");
    if (signed && signed !== await webhookSignature(key, body.data)) {
      console.warn(`korapay webhook signature mismatch for ${reference}; verifying with Korapay anyway`);
    }
    try {
      return json(200, { status: await settle(db, env, key, reference) });
    } catch (e) {
      return json(500, { error: String((e as Error).message ?? e) });
    }
  }

  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  const userId = token ? await db.userFromToken(token) : null;
  if (!userId) return json(401, { error: "Please sign in again." });
  if (!key) return json(503, { error: "Paying in the app is not set up yet." });

  if (body?.action === "start") {
    const forEvent = typeof body.event_id === "string" && body.event_id.length > 0;
    const { data: p, error } = forEvent
      ? await db.rpc("online_payment_start_event", {
        p_user: userId,
        p_amount: Number(body.amount),
        p_event: body.event_id,
        p_anonymous: body.anonymous === true,
        p_note: typeof body.note === "string" ? body.note : null,
      })
      : await db.rpc("online_payment_start", {
        p_user: userId,
        p_amount: Number(body.amount),
        p_cause: body.cause_id ?? null,
        p_plan: body.dues_plan_id ?? null,
        p_show_name: body.show_name ?? true,
      });
    if (error) return json(400, { error: error.message });
    const family = cfg?.family_name ?? "Bua";
    try {
      const checkoutUrl = await initializeCharge(env.fetch, key, {
        reference: p.reference,
        amount: Number(p.amount),
        name: p.name || "Family member",
        // Korapay needs an email; members who sign in by phone have none.
        email: p.email || `member-${userId.slice(0, 8)}@buafamily.vercel.app`,
        narration: [`${family} Family`, p.purpose].filter(Boolean).join(": "),
        redirectUrl: `${env.siteUrl}/#/fund/paid/${p.reference}${forEvent ? `?event=${p.event_id}` : ""}`,
        notificationUrl: `${env.supabaseUrl}/functions/v1/korapay?webhook=1`,
      });
      return json(200, { reference: p.reference, checkout_url: checkoutUrl });
    } catch (e) {
      await db.rpc("online_payment_failed", { p_reference: p.reference });
      return json(502, { error: String((e as Error).message ?? e) });
    }
  }

  if (body?.action === "check") {
    const reference = String(body.reference ?? "");
    const owner = await db.paymentOwner(reference);
    if (!owner || owner.user_id !== userId) return json(404, { error: "Payment not found" });
    if (owner.status !== "started") return json(200, { status: owner.status });
    try {
      return json(200, { status: await settle(db, env, key, reference) });
    } catch (e) {
      return json(502, { error: String((e as Error).message ?? e) });
    }
  }

  return json(400, { error: "unknown action" });
}
