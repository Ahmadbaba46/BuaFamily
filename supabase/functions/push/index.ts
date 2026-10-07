// Sends push notifications for new in-app notifications.
//
// Called by the database (private.push_new_notifications) with
//   POST {"ids": [<notification id>, ...]} and the shared x-push-secret header.
// Deployed with verify_jwt = false: the shared secret is the check.

import { createClient } from "npm:@supabase/supabase-js@2";
import { send, type ServiceAccount } from "./fcm.ts";
import { render } from "./texts.ts";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });

  const { data: cfg, error: cfgError } = await supabase.rpc("push_config");
  if (cfgError) return json(500, { error: cfgError.message });
  if (!cfg?.secret || req.headers.get("x-push-secret") !== cfg.secret) return json(401, { error: "unauthorized" });
  const sa = cfg.service_account as ServiceAccount | null;
  if (!sa) return json(503, { error: "Push is not set up" });

  let ids: string[] = [];
  try {
    ids = ((await req.json()).ids ?? []).slice(0, 2000);
  } catch {
    return json(400, { error: "bad body" });
  }
  if (ids.length === 0) return json(200, { sent: 0 });

  const { data: rows, error } = await supabase.rpc("push_payloads", { p_ids: ids });
  if (error) return json(500, { error: error.message });

  const jobs: Promise<void>[] = [];
  const dead: string[] = [];
  let sent = 0;
  let lastError: string | undefined;

  for (const row of rows ?? []) {
    const { title, body } = render(row.kind, row.data, row.locale, cfg.family_name ?? "Bua");
    for (const device of row.tokens as { token: string; platform: string }[]) {
      jobs.push(
        send(sa, {
          token: device.token,
          title,
          body,
          link: row.link,
          kind: row.kind,
          id: row.id,
          urgent: row.kind === "blood_request" ||
            (row.kind === "admin_alert" && row.data?.alert === "blood_no_offer") ||
            (row.kind === "content_report" && row.data?.reason === "child_safety"),
        }).then((r) => {
          if (r.result === "sent") sent++;
          else if (r.result === "dead") dead.push(device.token);
          else lastError = r.error;
        }).catch((e) => {
          lastError = String(e?.message ?? e);
        }),
      );
    }
  }
  await Promise.all(jobs);

  if (dead.length) await supabase.from("push_tokens").delete().in("token", dead);
  await supabase.rpc("push_report", { p_sent: sent, p_error: lastError ?? null });
  return json(200, { sent, removed: dead.length, error: lastError ?? null });
});
