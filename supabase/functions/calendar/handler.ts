// The 'calendar' Edge Function.
//
//   GET ?token=<the member's calendar token>  →  text/calendar
//
// Deployed with verify_jwt = false: calendar apps can't sign in, so the long
// random token in the link is the key. A wrong or turned-off link gets 404.

import { buildCalendar, type Feed } from "./ics.ts";

export interface Db {
  feed(token: string): Promise<{ data: Feed | null; error: { message: string } | null }>;
}

export async function handle(req: Request, db: Db, siteUrl: string, now = new Date()): Promise<Response> {
  if (req.method !== "GET" && req.method !== "HEAD") return new Response("GET only", { status: 405 });
  // Some apps add ".ics" to the end; either way works.
  const token = (new URL(req.url).searchParams.get("token") ?? "").replace(/\.ics$/, "");
  if (!/^[0-9a-f]{32,128}$/.test(token)) return new Response("Not found", { status: 404 });
  const { data, error } = await db.feed(token);
  if (error) return new Response("Try again later", { status: 503 });
  if (!data) return new Response("Not found", { status: 404 });
  return new Response(req.method === "HEAD" ? null : buildCalendar(data, siteUrl, now), {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": 'inline; filename="family.ics"',
      "Cache-Control": "private, max-age=900",
    },
  });
}
