// Firebase Cloud Messaging (HTTP v1) with a service account.

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

export interface Message {
  token: string;
  title: string;
  body: string;
  link?: string | null;
  kind: string;
  id: string;
  urgent?: boolean;
}

const b64url = (bytes: Uint8Array | string) => {
  const raw = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let s = "";
  for (const b of raw) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const bin = atob(pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s+/g, ""));
  const der = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i);
  return der;
}

/** A signed JWT asking Google for a messaging access token. */
export async function signedAssertion(sa: ServiceAccount, nowSeconds = Math.floor(Date.now() / 1000)) {
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`));
  return `${header}.${claims}.${b64url(new Uint8Array(sig))}`;
}

let cached: { token: Promise<string>; expires: number; email: string } | null = null;

/** A messaging access token, shared by all sends while it is valid. */
export function accessToken(sa: ServiceAccount, fetcher: typeof fetch = fetch): Promise<string> {
  if (cached && cached.email === sa.client_email && cached.expires > Date.now() + 60_000) return cached.token;
  const token = (async () => {
    const res = await fetcher("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: await signedAssertion(sa),
      }),
    });
    if (!res.ok) throw new Error(`Google sign-in failed (${res.status}): ${await res.text()}`);
    return (await res.json()).access_token as string;
  })();
  cached = { token, expires: Date.now() + 3300_000, email: sa.client_email };
  token.catch(() => (cached = null));
  return token;
}

/** The FCM request body for one device. */
export function fcmBody(m: Message) {
  const data: Record<string, string> = { kind: m.kind, id: m.id };
  if (m.link) data.link = m.link;
  return {
    message: {
      token: m.token,
      notification: { title: m.title, body: m.body },
      data,
      android: {
        priority: "high",
        notification: { tag: m.id, ...(m.urgent ? { default_sound: true, notification_priority: "PRIORITY_MAX" } : {}) },
      },
      apns: { payload: { aps: { sound: "default", "thread-id": m.kind } } },
      webpush: { headers: { Urgency: m.urgent ? "high" : "normal" } },
    },
  };
}

export type SendResult = "sent" | "dead" | "failed";

/** Sends one message. "dead" means the device is gone and its token can be forgotten. */
export async function send(
  sa: ServiceAccount,
  m: Message,
  fetcher: typeof fetch = fetch,
): Promise<{ result: SendResult; error?: string }> {
  const res = await fetcher(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${await accessToken(sa, fetcher)}` },
    body: JSON.stringify(fcmBody(m)),
  });
  if (res.ok) return { result: "sent" };
  const text = await res.text();
  let code = "";
  try {
    const err = JSON.parse(text).error;
    code = (err?.details ?? []).map((d: { errorCode?: string }) => d.errorCode).find(Boolean) ?? err?.status ?? "";
  } catch { /* not JSON */ }
  // Only clear errors mean the device is gone; a bad request might be our bug.
  if (res.status === 404 || code === "UNREGISTERED" || code === "SENDER_ID_MISMATCH") {
    return { result: "dead", error: code || String(res.status) };
  }
  return { result: "failed", error: `${res.status} ${code || text.slice(0, 200)}` };
}
