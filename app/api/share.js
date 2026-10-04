// Link cards for WhatsApp and other apps.
//
// /s/<kind>/<id>?l=en|ha (see vercel.json) answers with a small page whose
// preview tags give the link a title, a line of text and the family's
// picture, then sends the reader on to the app (/#/...).
//
// Family content is private, so cards never show it: an event or a moment
// only says what it is. Invites say who invited you (the person you got the
// link from already knows that).

const KINDS = {
  join: { path: (id) => `/join/${id}`, id: /^[a-z0-9]{4,32}$/i },
  event: { path: (id) => `/events/${id}`, id: /^[0-9a-f-]{36}$/i },
  post: { path: (id) => `/posts/${id}`, id: /^[0-9a-f-]{36}$/i },
  album: { path: (id) => `/albums/${id}`, id: /^[0-9a-f-]{36}$/i },
};

const TEXT = {
  en: {
    family: (f) => `${f} Family`,
    join: (f, by) => (by ? `${by} invited you to the ${f} Family app` : `You're invited to the ${f} Family app`),
    joinLine: "Our family tree, news, photos and events, in one private place. Tap to join.",
    event: (f) => `An event in the ${f} Family`,
    post: (f) => `A moment shared in the ${f} Family`,
    album: (f) => `Photos shared in the ${f} Family`,
    open: "Open the family app to see it. Only family members can.",
    home: "Our family tree, news, photos and events, in one private place.",
  },
  ha: {
    family: (f) => `Iyalin ${f}`,
    join: (f, by) => (by ? `${by} ya gayyace ka zuwa manhajar Iyalin ${f}` : `An gayyace ka zuwa manhajar Iyalin ${f}`),
    joinLine: "Bishiyar iyalinmu, labarai, hotuna da taruka, a wuri ɗaya na sirri. Taɓa don shiga.",
    event: (f) => `Taro a cikin Iyalin ${f}`,
    post: (f) => `Labari da aka raba a cikin Iyalin ${f}`,
    album: (f) => `Hotunan da aka raba a cikin Iyalin ${f}`,
    open: "Buɗe manhajar iyali don gani. ’Yan uwa ne kawai ke iya gani.",
    home: "Bishiyar iyalinmu, labarai, hotuna da taruka, a wuri ɗaya na sirri.",
  },
};

const escape = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

/** The page for one link. Pure, for tests. */
function render({ kind, id, lang, site, family, invitedBy }) {
  const k = KINDS[kind];
  const t = TEXT[lang === "ha" ? "ha" : "en"];
  const valid = k && k.id.test(id || "");
  const target = `${site}/#${valid ? k.path(id) : "/home"}`;
  const f = family || "Bua";
  const title = !valid ? t.family(f) : kind === "join" ? t.join(f, invitedBy) : t[kind](f);
  const line = !valid ? t.home : kind === "join" ? t.joinLine : t.open;
  const self = valid ? `${site}/s/${kind}/${id}` : site;
  return `<!doctype html>
<html lang="${lang === "ha" ? "ha" : "en"}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)}</title>
<meta name="description" content="${escape(line)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="${escape(t.family(f))}">
<meta property="og:title" content="${escape(title)}">
<meta property="og:description" content="${escape(line)}">
<meta property="og:url" content="${escape(self)}">
<meta property="og:image" content="${escape(site)}/og-card.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="${escape(t.family(f))}">
<meta name="twitter:card" content="summary_large_image">
<meta name="robots" content="noindex">
<meta http-equiv="refresh" content="0;url=${escape(target)}">
<link rel="canonical" href="${escape(target)}">
</head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding:48px 16px">
<p><a href="${escape(target)}">${escape(title)}</a></p>
<script>location.replace(${JSON.stringify(target)});</script>
</body>
</html>`;
}

async function rpc(name, params) {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return null;
  try {
    const res = await fetch(`${url}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: { apikey: key, "Content-Type": "application/json" },
      body: JSON.stringify(params),
      signal: AbortSignal.timeout(2500),
    });
    return res.ok ? await res.json() : null;
  } catch {
    return null;
  }
}

async function handler(req, res) {
  const q = req.query || {};
  const kind = String(q.kind || "");
  const id = String(q.id || "").toLowerCase();
  const lang = String(q.l || "en");
  const site = `https://${req.headers["x-forwarded-host"] || req.headers.host}`;
  const info = (await rpc("public_info", {})) || {};
  let invitedBy = null;
  if (kind === "join" && KINDS.join.id.test(id)) {
    const invite = await rpc("invite_info", { p_code: id });
    if (invite && invite.valid) invitedBy = invite.invited_by || null;
  }
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=600");
  res.status(200).send(render({ kind, id, lang, site, family: info.family_name, invitedBy }));
}

module.exports = handler;
module.exports.render = render;
