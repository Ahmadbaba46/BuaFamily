// deno test supabase/functions/push
import { accessToken, fcmBody, send, signedAssertion, type ServiceAccount } from "./fcm.ts";
import { naira, render } from "./texts.ts";

function assertEquals(actual: unknown, expected: unknown, msg = "") {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${msg}\n  actual:   ${a}\n  expected: ${e}`);
}

async function testAccount(): Promise<{ sa: ServiceAccount; publicKey: CryptoKey }> {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const b64 = btoa(String.fromCharCode(...der)).replace(/(.{64})/g, "$1\n");
  return {
    sa: {
      project_id: "bua-family",
      client_email: `push-${crypto.randomUUID()}@bua-family.iam.gserviceaccount.com`,
      private_key: `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`,
    },
    publicKey: pair.publicKey,
  };
}

function fromB64url(s: string): Uint8Array<ArrayBuffer> {
  const bin = atob(s.replace(/-/g, "+").replace(/_/g, "/"));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

Deno.test("texts follow the reader's language", () => {
  assertEquals(render("poll", { question: "Where?" }, "en", "Bua"), { title: "Bua Family", body: "New poll: Where?" });
  assertEquals(render("poll", { question: "Ina?" }, "ha", "Bua"), { title: "Iyalin Bua", body: "Sabuwar ƙuri'a: Ina?" });
  assertEquals(render("remembrance", { years: 1, name: "Ahmadu" }, "en", "Bua").body, "1 year since Ahmadu passed");
  assertEquals(render("remembrance", { years: 5, name: "Ahmadu" }, "en", "Bua").body, "5 years since Ahmadu passed");
  assertEquals(render("tagged", { photo_id: "x" }, "en", "Bua").body, "You were tagged in a photo");
  assertEquals(render("fund_confirmed", { amount: 20000 }, "en", "Bua").body,
    "Your contribution of ₦20,000 was confirmed. Thank you!");
  assertEquals(render("something_new", {}, "en", "Bua").body, "New notification");
  assertEquals(render("account_request", { name: "Musa" }, "en", "Bua").body, "New sign-up waiting for approval: Musa");
  assertEquals(render("comment", { name: "Aisha", body: "Lovely" }, "en", "Bua").body, "Aisha commented: “Lovely”");
  assertEquals(render("comment", { name: "Aisha", body: "Lovely", also: true }, "en", "Bua").body,
    "Aisha also commented: “Lovely”");
  assertEquals(render("comment", { body: "Lovely" }, "en", "Bua").body, "New comment: “Lovely”");
  assertEquals(render("change_request", { name: "Aisha", request_kind: "create_person", person: "Fatima" }, "en", "Bua").body,
    "Aisha suggested adding Fatima to the tree");
  assertEquals(render("request_reviewed", { approved: false, person: "Musa Bua" }, "ha", "Bua").body,
    "Ba a karɓi shawararka game da Musa Bua ba");
  assertEquals(render("announcement", { body: "x".repeat(400) }, "en", "Bua").body.length, 298);
  assertEquals(naira(1240000.5), "₦1,240,000.5");
});

Deno.test("the sign-in JWT is signed with the service account key", async () => {
  const { sa, publicKey } = await testAccount();
  const jwt = await signedAssertion(sa, 1_800_000_000);
  const [h, c, sig] = jwt.split(".");
  const claims = JSON.parse(new TextDecoder().decode(fromB64url(c)));
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.scope, "https://www.googleapis.com/auth/firebase.messaging");
  assertEquals(claims.exp - claims.iat, 3600);
  const ok = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", publicKey, fromB64url(sig), new TextEncoder().encode(`${h}.${c}`));
  assertEquals(ok, true, "signature verifies");
});

Deno.test("one Google sign-in serves many sends; dead devices are reported", async () => {
  const { sa } = await testAccount();
  let signIns = 0;
  const sentTo: string[] = [];
  const fake = (async (url: string | URL | Request, init?: RequestInit) => {
    const u = String(url);
    if (u.startsWith("https://oauth2.googleapis.com/token")) {
      signIns++;
      return new Response(JSON.stringify({ access_token: "ya29.test", expires_in: 3600 }));
    }
    const token = JSON.parse(String(init!.body)).message.token;
    sentTo.push(token);
    assertEquals(u, "https://fcm.googleapis.com/v1/projects/bua-family/messages:send");
    assertEquals((init!.headers as Record<string, string>).Authorization, "Bearer ya29.test");
    if (token === "gone") {
      return new Response(JSON.stringify({ error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] } }), { status: 404 });
    }
    if (token === "broken") return new Response(JSON.stringify({ error: { status: "INTERNAL" } }), { status: 500 });
    return new Response("{}");
  }) as typeof fetch;

  const msg = { title: "Bua Family", body: "Hi", kind: "poll", id: "n1", link: "/polls" };
  const results = await Promise.all(["a", "b", "gone", "broken"].map((token) => send(sa, { ...msg, token }, fake)));
  assertEquals(results.map((r) => r.result), ["sent", "sent", "dead", "failed"]);
  assertEquals(signIns, 1, "access token shared");
  assertEquals(sentTo.length, 4);
  assertEquals(await accessToken(sa, fake), "ya29.test");
  assertEquals(signIns, 1, "still cached");
});

Deno.test("the message opens the right page and blood requests are urgent", () => {
  const body = fcmBody({ token: "t", title: "T", body: "B", kind: "blood_request", id: "n1", link: "/blood", urgent: true });
  assertEquals(body.message.data, { kind: "blood_request", id: "n1", link: "/blood" });
  assertEquals(body.message.android.priority, "high");
  assertEquals(body.message.webpush.headers.Urgency, "high");
  assertEquals(fcmBody({ token: "t", title: "T", body: "B", kind: "poll", id: "n2" }).message.data, { kind: "poll", id: "n2" });
});
