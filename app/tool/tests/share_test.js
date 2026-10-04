// node --test app/tool/tests/share_test.js
const test = require("node:test");
const assert = require("node:assert");
const { render } = require("../../api/share.js");

const site = "https://buafamily.vercel.app";

test("an invite says who invited you and opens the join page", () => {
  const html = render({ kind: "join", id: "abc123", lang: "en", site, family: "Bua", invitedBy: "Musa Bua" });
  assert.match(html, /<meta property="og:title" content="Musa Bua invited you to the Bua Family app">/);
  assert.match(html, /og:image" content="https:\/\/buafamily.vercel.app\/og-card.png"/);
  assert.match(html, /location.replace\("https:\/\/buafamily.vercel.app\/#\/join\/abc123"\)/);
});

test("events and moments never show their content", () => {
  const id = "0b7a7d1e-2c1e-4c36-9a43-6a4f0e7c9f11";
  const html = render({ kind: "event", id, lang: "ha", site, family: "Bua" });
  assert.match(html, /og:title" content="Taro a cikin Iyalin Bua"/);
  assert.match(html, /#\/events\/0b7a7d1e/);
  assert.match(render({ kind: "post", id, lang: "en", site }), /A moment shared in the Bua Family/);
});

test("anything odd goes to Home, and names are escaped", () => {
  const html = render({ kind: "event", id: '"><script>alert(1)</script>', lang: "en", site, family: "Bua" });
  assert.match(html, /#\/home/);
  assert.doesNotMatch(html, /<script>alert/);
  const named = render({ kind: "join", id: "abc123", lang: "en", site, family: "Bua", invitedBy: '<b>"X"</b>' });
  assert.match(named, /&lt;b&gt;&quot;X&quot;&lt;\/b&gt; invited you/);
});
