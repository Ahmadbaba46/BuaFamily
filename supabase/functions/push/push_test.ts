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
  assertEquals(
    render("fund_contribution", { amount: 5000, online: true, name: "Aisha", cause: "Hospital bill" }, "en", "Bua").body,
    "Aisha paid ₦5,000 in the app for Hospital bill",
  );
  assertEquals(render("fund_contribution", { amount: 5000 }, "en", "Bua").body, "New contribution to confirm: ₦5,000");
  assertEquals(
    render("content_report", { reason: "child_safety" }, "en", "Bua").body,
    "URGENT: a child safety concern was reported. Please review it now.",
  );
  assertEquals(render("content_report", { reason: "spam" }, "ha", "Bua").body, "An kai rahoton wani abu ga shugabanni. Taɓa don dubawa.");
  assertEquals(
    render("khatm_reminder", { title: "Khatm for Kaka", juz: [1, 5] }, "en", "Bua").body,
    "Reminder: “Khatm for Kaka” is to be finished tomorrow (your juz: 1, 5).",
  );
  assertEquals(render("direct_message", { name: "Musa", message_kind: "voice", body: "" }, "en", "Bua").body, "Musa: 🎤 Voice note");
  assertEquals(render("direct_message", { name: "Musa", message_kind: "photo", body: "" }, "ha", "Bua").body, "Musa: 📷 Hoto");
  assertEquals(render("direct_message", { name: "Musa", message_kind: "reaction", body: "❤️" }, "en", "Bua").body,
    "Musa reacted ❤️ to your message");
  assertEquals(render("direct_message", { name: "Musa", message_kind: "reaction", body: "👍" }, "ha", "Bua").body,
    "Musa ya yi martanin 👍 ga saƙonka");
  assertEquals(render("group_message", { name: "Musa", group: "Cousins", body: "Salam" }, "en", "Bua").body,
    "Musa @ Cousins: “Salam”");
  assertEquals(render("group_message", { name: "Musa", group: "Cousins", body: "", message_kind: "voice" }, "ha", "Bua").body,
    "Musa @ Cousins: 🎤 Saƙon murya");
  assertEquals(render("group_message", { name: "Musa", group: "Cousins", body: "❤️", message_kind: "reaction" }, "en", "Bua")
    .body, "Musa reacted ❤️ to your message in “Cousins”");
  assertEquals(render("group_added", { name: "Aisha", group: "Cousins" }, "ha", "Bua").body,
    "Aisha ya saka ka a rukunin “Cousins”");
  assertEquals(render("event_gift", { name: "Musa", amount: 20000, title: "Naming of Fatima", status: "pledged" }, "en", "Bua")
    .body, "Musa pledged ₦20,000 for Naming of Fatima");
  assertEquals(render("event_gift", { name: "Musa", amount: null, item: "A ram", title: "Suna", status: "sent" }, "ha", "Bua")
    .body, "Musa ya aika A ram don Suna");
  assertEquals(render("event_gift_received", { name: "Aisha", title: "Naming of Fatima" }, "en", "Bua").body,
    "Aisha received your gift for Naming of Fatima. Thank you!");
  assertEquals(render("event_collection", { title: "Auren Musa" }, "ha", "Bua").body, "An buɗe gudummawa don Auren Musa");
  assertEquals(render("khatm", { title: "Sauka don Kaka" }, "ha", "Bua").body, "Sabuwar saukar Alƙur'ani: Sauka don Kaka. Ɗauki juz'i.");
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
  assertEquals(render("mentor_reply", { name: "Ibrahim", body: "Start with statics" }, "en", "Bua").body,
    "Ibrahim: “Start with statics”");
  assertEquals(render("mentor_request", { name: "Aisha", body: "Courses?" }, "ha", "Bua").body,
    "Aisha ya nemi jagorarka: “Courses?”");
  assertEquals(render("occasion", { occasion: "eid_al_fitr", eve: false }, "en", "Bua").body, "Eid Mubarak! Barka da Sallah.");
  assertEquals(render("occasion", { occasion: "ramadan", eve: true }, "ha", "Bua").body,
    "Ana sa ran fara azumin Ramadan gobe, idan an ga wata.");
  assertEquals(render("occasion", { occasion: "islamic_new_year", hijri_year: 1448 }, "en", "Bua").body,
    "Happy Islamic New Year 1448!");
  assertEquals(render("dues_reminder", { title: "Monthly dues", owed: 4000 }, "en", "Bua").body,
    "Monthly dues: you owe ₦4,000. Tap to pay.");
  assertEquals(render("claim_reviewed", { approved: true, person: "Musa Bua" }, "en", "Bua").body,
    "You're now linked to Musa Bua in the family tree.");
  assertEquals(render("claim_reviewed", { approved: false, person: "Musa Bua", reason: "Wrong branch" }, "ha", "Bua").body,
    "Ba a karɓi buƙatarka ta zama Musa Bua ba: “Wrong branch”");
  assertEquals(render("change_request", { name: "Aisha", request_kind: "create_person", person: "Fatima" }, "en", "Bua").body,
    "Aisha suggested adding Fatima to the tree");
  assertEquals(render("request_reviewed", { approved: false, person: "Musa Bua" }, "ha", "Bua").body,
    "Ba a karɓi shawararka game da Musa Bua ba");
  assertEquals(render("weekly_summary", { active: 12, moments: 5, photos: 30, money_in: 25000, waiting_suggestions: 2,
    waiting_accounts: 1 }, "en", "Bua").body, "This week: 12 active, 5 moments, 30 photos, ₦25,000 in. 3 waiting for you.");
  assertEquals(render("weekly_summary", { active: 4, moments: 0, photos: 0, money_in: 0 }, "ha", "Bua").body,
    "Wannan mako: mutum 4 sun shiga, labarai 0, hotuna 0, ₦0 sun shigo.");
  assertEquals(render("admin_alert", { alert: "blood_no_offer", blood_group: "O-", patient: "Hauwa", hours: 2 }, "en", "Bua").body,
    "No donor yet for O- blood for Hauwa (2 h). Please call around.");
  assertEquals(render("admin_alert", { alert: "fund_low", balance: 4000, threshold: 10000 }, "ha", "Bua").body,
    "Asusun taimako ya ragu zuwa ₦4,000, ƙasa da ₦10,000.");
  assertEquals(render("admin_alert", { alert: "waiting", suggestions: 2, accounts: 0 }, "en", "Bua").body,
    "Waiting over 3 days: 2 suggestions, 0 new accounts.");
  assertEquals(render("direct_message", { name: "Musa Bua", body: "Salam!" }, "en", "Bua").body, "Musa Bua: “Salam!”");
  assertEquals(render("direct_message", { body: "Salam!" }, "ha", "Bua").body, "Sabon saƙo: “Salam!”");
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
