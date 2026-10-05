// Talking to Korapay: start a checkout, and ask whether a payment went through.
// https://developers.korapay.com/docs/checkout-redirect

export const KORAPAY_API = "https://api.korapay.com/merchant/api/v1";

type Fetch = typeof fetch;

export interface Checkout {
  reference: string;
  amount: number;
  name: string;
  email: string;
  narration: string;
  redirectUrl: string;
  notificationUrl: string;
}

/** Starts a payment and returns Korapay's checkout page. The payer pays the fee. */
export async function initializeCharge(f: Fetch, secretKey: string, c: Checkout): Promise<string> {
  const res = await f(`${KORAPAY_API}/charges/initialize`, {
    method: "POST",
    headers: { Authorization: `Bearer ${secretKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      reference: c.reference,
      amount: c.amount,
      currency: "NGN",
      narration: c.narration.slice(0, 100),
      redirect_url: c.redirectUrl,
      notification_url: c.notificationUrl,
      channels: ["card", "bank_transfer"],
      merchant_bears_cost: false,
      customer: { name: c.name, email: c.email },
    }),
  });
  const body = await res.json().catch(() => ({}));
  const url = body?.data?.checkout_url;
  if (!res.ok || !body?.status || typeof url !== "string") {
    throw new Error(body?.message ?? `Korapay said ${res.status}`);
  }
  return url;
}

export type ChargeState =
  | { state: "paid"; amount: number; fee: number | null }
  | { state: "failed" }
  | { state: "waiting" };

/** Asks Korapay what happened to a payment. Only this is trusted, never a webhook alone. */
export async function verifyCharge(f: Fetch, secretKey: string, reference: string): Promise<ChargeState> {
  const res = await f(`${KORAPAY_API}/charges/${encodeURIComponent(reference)}`, {
    headers: { Authorization: `Bearer ${secretKey}` },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body?.status) {
    if (res.status === 404) return { state: "waiting" };
    throw new Error(body?.message ?? `Korapay said ${res.status}`);
  }
  const d = body.data ?? {};
  if (d.reference !== reference) return { state: "waiting" };
  if (d.status === "success" && d.currency === "NGN") {
    const fee = d.fee == null ? null : Number(d.fee);
    return { state: "paid", amount: Number(d.amount_paid ?? d.amount), fee: Number.isFinite(fee) ? fee : null };
  }
  if (d.status === "failed" || d.status === "expired" || d.status === "cancelled") return { state: "failed" };
  return { state: "waiting" };
}

/** x-korapay-signature: HMAC-SHA256 (hex) of the JSON of the webhook's "data", with the secret key. */
export async function webhookSignature(secretKey: string, data: unknown): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secretKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(JSON.stringify(data)));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
