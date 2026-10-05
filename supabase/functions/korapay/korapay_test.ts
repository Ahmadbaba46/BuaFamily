// deno test supabase/functions/korapay
import { type Db, handle } from "./handler.ts";
import { KORAPAY_API, webhookSignature } from "./korapay.ts";

function assertEquals(actual: unknown, expected: unknown, msg = "") {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${msg}\n  actual:   ${a}\n  expected: ${e}`);
}

/** A pretend database and Korapay, recording what was asked of them. */
function world(opts: { key?: string | null; korapayStatus?: string; amountPaid?: number; initFails?: boolean } = {}) {
  const calls: { fn: string; args?: Record<string, unknown> }[] = [];
  const requests: { url: string; init?: RequestInit }[] = [];
  const payments: Record<string, { user_id: string; status: string }> = {};
  const db: Db = {
    rpc: (fn, args) => {
      calls.push({ fn, args });
      if (fn === "korapay_config") {
        return Promise.resolve({ data: { secret_key: opts.key === undefined ? "sk_test_k" : opts.key, family_name: "Bua" }, error: null });
      }
      if (fn === "online_payment_start") {
        if ((args!.p_amount as number) < 100) return Promise.resolve({ data: null, error: { message: "too small" } });
        payments["bua-1"] = { user_id: args!.p_user as string, status: "started" };
        return Promise.resolve({
          data: { reference: "bua-1", amount: args!.p_amount, name: "Aisha Bua", email: null, purpose: "Hospital bill" },
          error: null,
        });
      }
      if (fn === "online_payment_paid") payments[args!.p_reference as string].status = "paid";
      if (fn === "online_payment_failed" && payments[args!.p_reference as string]) {
        payments[args!.p_reference as string].status = "failed";
      }
      return Promise.resolve({ data: null, error: null });
    },
    userFromToken: (t) => Promise.resolve(t === "good-token" ? "user-1" : null),
    paymentOwner: (r) => Promise.resolve(payments[r] ?? null),
  };
  const fakeFetch = ((url: string, init?: RequestInit) => {
    requests.push({ url, init });
    if (url.endsWith("/charges/initialize")) {
      return Promise.resolve(opts.initFails
        ? new Response(JSON.stringify({ status: false, message: "Invalid key" }), { status: 401 })
        : new Response(JSON.stringify({ status: true, data: { checkout_url: "https://checkout.korapay.com/x", reference: "bua-1" } })));
    }
    return Promise.resolve(new Response(JSON.stringify({
      status: true,
      data: { reference: "bua-1", status: opts.korapayStatus ?? "success", currency: "NGN", amount: "5000.00",
              amount_paid: opts.amountPaid ?? 5000, fee: "75" },
    })));
  }) as typeof fetch;
  const env = { supabaseUrl: "https://x.supabase.co", siteUrl: "https://buafamily.vercel.app", fetch: fakeFetch };
  return { db, env, calls, requests, payments };
}

const post = (body: unknown, { token, path = "", headers = {} }: { token?: string; path?: string; headers?: Record<string, string> } = {}) =>
  new Request(`https://x.supabase.co/functions/v1/korapay${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}), ...headers },
    body: JSON.stringify(body),
  });

Deno.test("start: a signed-in member gets Korapay's checkout page", async () => {
  const w = world();
  const res = await handle(post({ action: "start", amount: 5000, cause_id: "c1" }, { token: "good-token" }), w.db, w.env);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { reference: "bua-1", checkout_url: "https://checkout.korapay.com/x" });
  const start = w.calls.find((c) => c.fn === "online_payment_start")!;
  assertEquals(start.args, { p_user: "user-1", p_amount: 5000, p_cause: "c1", p_plan: null, p_show_name: true });
  const init = w.requests[0];
  assertEquals(init.url, `${KORAPAY_API}/charges/initialize`);
  assertEquals((init.init!.headers as Record<string, string>).Authorization, "Bearer sk_test_k");
  const sent = JSON.parse(init.init!.body as string);
  assertEquals([sent.amount, sent.currency, sent.merchant_bears_cost, sent.narration],
    [5000, "NGN", false, "Bua Family: Hospital bill"], "the payer pays the fee");
  assertEquals(sent.redirect_url, "https://buafamily.vercel.app/#/fund/paid/bua-1");
  assertEquals(sent.notification_url, "https://x.supabase.co/functions/v1/korapay?webhook=1");
  assertEquals(sent.customer.email, "member-user-1@buafamily.vercel.app", "phone-only members get a stand-in email");
});

Deno.test("start: not signed in, not set up, or refused", async () => {
  let w = world();
  assertEquals((await handle(post({ action: "start", amount: 5000 }), w.db, w.env)).status, 401);
  assertEquals((await handle(post({ action: "start", amount: 5000 }, { token: "bad" }), w.db, w.env)).status, 401);
  w = world({ key: null });
  assertEquals((await handle(post({ action: "start", amount: 5000 }, { token: "good-token" }), w.db, w.env)).status, 503);
  w = world();
  const small = await handle(post({ action: "start", amount: 50 }, { token: "good-token" }), w.db, w.env);
  assertEquals([small.status, (await small.json()).error], [400, "too small"]);
  w = world({ initFails: true });
  const bad = await handle(post({ action: "start", amount: 5000 }, { token: "good-token" }), w.db, w.env);
  assertEquals([bad.status, (await bad.json()).error], [502, "Invalid key"]);
  assertEquals(w.payments["bua-1"].status, "failed", "a payment Korapay refused is marked failed");
});

Deno.test("webhook: recorded only once Korapay confirms it", async () => {
  const w = world();
  await handle(post({ action: "start", amount: 5000 }, { token: "good-token" }), w.db, w.env);
  const data = { reference: "bua-1", status: "success", amount: 5000 };
  const res = await handle(
    post({ event: "charge.success", data }, { path: "?webhook=1", headers: { "x-korapay-signature": await webhookSignature("sk_test_k", data) } }),
    w.db, w.env,
  );
  assertEquals(await res.json(), { status: "paid" });
  assertEquals(w.requests.at(-1)!.url, `${KORAPAY_API}/charges/bua-1`, "asked Korapay itself");
  assertEquals(w.calls.find((c) => c.fn === "online_payment_paid")!.args, { p_reference: "bua-1", p_amount: 5000, p_fee: 75 });
});

Deno.test("webhook: a fake 'paid' message records nothing when Korapay says otherwise", async () => {
  const w = world({ korapayStatus: "processing" });
  await handle(post({ action: "start", amount: 5000 }, { token: "good-token" }), w.db, w.env);
  const res = await handle(post({ event: "charge.success", data: { reference: "bua-1" } }, { path: "?webhook=1" }), w.db, w.env);
  assertEquals(await res.json(), { status: "waiting" });
  assertEquals(w.calls.some((c) => c.fn === "online_payment_paid"), false);
  const other = await handle(post({ event: "charge.success", data: { reference: "someone-else" } }, { path: "?webhook=1" }), w.db, w.env);
  assertEquals(await other.json(), { ignored: true }, "payments that aren't ours are ignored");
});

Deno.test("check: the payer asks after paying; only their own payments", async () => {
  const w = world({ korapayStatus: "failed" });
  await handle(post({ action: "start", amount: 5000 }, { token: "good-token" }), w.db, w.env);
  const res = await handle(post({ action: "check", reference: "bua-1" }, { token: "good-token" }), w.db, w.env);
  assertEquals(await res.json(), { status: "failed" });
  assertEquals(w.payments["bua-1"].status, "failed");
  const again = await handle(post({ action: "check", reference: "bua-1" }, { token: "good-token" }), w.db, w.env);
  assertEquals(await again.json(), { status: "failed" }, "settled payments aren't asked about again");
  w.payments["bua-2"] = { user_id: "user-2", status: "started" };
  assertEquals((await handle(post({ action: "check", reference: "bua-2" }, { token: "good-token" }), w.db, w.env)).status, 404);
});

Deno.test("webhook signature matches Korapay's recipe", async () => {
  // HMAC-SHA256 of JSON.stringify(data) with the secret key, as hex (checked with openssl).
  assertEquals(
    await webhookSignature("key", { reference: "bua-1" }),
    "bd561ffb5450bbc9c07b666e34c0e8ed6020cd39b39902c2573ba73a63efc534",
  );
});
