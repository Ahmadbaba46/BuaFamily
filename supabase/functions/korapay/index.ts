// Pay dues and causes through Korapay. See handler.ts.

import { createClient } from "npm:@supabase/supabase-js@2";
import { handle } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabase = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve((req) =>
  handle(req, {
    rpc: (fn, args) => supabase.rpc(fn, args) as any,
    userFromToken: async (token) => (await supabase.auth.getUser(token)).data.user?.id ?? null,
    paymentOwner: async (reference) =>
      (await supabase.from("online_payments").select("user_id, status").eq("reference", reference).maybeSingle()).data,
  }, {
    supabaseUrl,
    siteUrl: Deno.env.get("SITE_URL") ?? "https://buafamily.vercel.app",
    fetch,
  })
);
