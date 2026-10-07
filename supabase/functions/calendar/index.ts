// The family calendar feed for calendar apps. See handler.ts.

import { createClient } from "npm:@supabase/supabase-js@2";
import { handle } from "./handler.ts";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve((req) =>
  handle(
    req,
    { feed: (token) => supabase.rpc("calendar_feed", { p_token: token }) as any },
    Deno.env.get("SITE_URL") ?? "https://buafamily.vercel.app",
  )
);
