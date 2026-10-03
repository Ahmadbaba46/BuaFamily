// What a push notification says, in the reader's language. Mirrors the app's
// notification inbox (app/lib/l10n/app_*.arb, notif* strings).

export type Data = Record<string, unknown>;

const s = (d: Data, k: string) => (typeof d[k] === "string" ? (d[k] as string) : "");
const n = (d: Data, k: string) => (typeof d[k] === "number" ? (d[k] as number) : Number(d[k] ?? 0) || 0);

export function naira(amount: number): string {
  const whole = Math.round(amount * 100) / 100;
  const [int, dec] = whole.toString().split(".");
  return "₦" + int.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + (dec ? "." + dec : "");
}

type Texts = Record<string, (d: Data) => string>;

const en: Texts = {
  event: (d) => `New event: ${s(d, "title")}`,
  announcement: (d) => s(d, "body") || "Announcement",
  birthday: (d) => `${s(d, "name")}'s birthday today (${n(d, "age")})`,
  event_reminder: (d) => `Tomorrow: ${s(d, "title")}`,
  tagged: (d) => ("photo_id" in d ? "You were tagged in a photo" : "You were tagged in a moment"),
  comment: (d) =>
    !s(d, "name")
      ? `New comment: “${s(d, "body")}”`
      : d.also === true
      ? `${s(d, "name")} also commented: “${s(d, "body")}”`
      : `${s(d, "name")} commented: “${s(d, "body")}”`,
  blood_request: (d) => `${s(d, "blood_group")} blood needed for ${s(d, "patient")} at ${s(d, "hospital")}`,
  blood_offer: (d) => `A relative can donate blood (${s(d, "blood_group")})`,
  remembrance: (d) =>
    n(d, "years") === 1 ? `1 year since ${s(d, "name")} passed` : `${n(d, "years")} years since ${s(d, "name")} passed`,
  memory: (d) => `New memory of ${s(d, "name")}: “${s(d, "body")}”`,
  fund_contribution: (d) => `New contribution to confirm: ${naira(n(d, "amount"))}`,
  fund_confirmed: (d) => `Your contribution of ${naira(n(d, "amount"))} was confirmed. Thank you!`,
  fund_request: (d) => `Support requested: ${s(d, "title")}`,
  mentor_request: (d) => `Someone asked for your guidance: “${s(d, "body")}”`,
  opportunity: (d) => `New opportunity: ${s(d, "title")}`,
  poll: (d) => `New poll: ${s(d, "question")}`,
  story: (d) => `New story from ${s(d, "speaker")}: ${s(d, "title")}`,
  test: () => "Test notification: notifications are working on this device.",
  account_request: (d) =>
    s(d, "person")
      ? `${s(d, "name")} says they are ${s(d, "person")} in the tree`
      : s(d, "note")
      ? `${s(d, "name")} says: “${s(d, "note")}”`
      : `New sign-up waiting for approval: ${s(d, "name")}`,
  change_request: (d) =>
    s(d, "request_kind") === "create_person"
      ? `${s(d, "name")} suggested adding ${s(d, "person") || "someone"} to the tree`
      : `${s(d, "name")} suggested a change to ${s(d, "person") || "the tree"}`,
  account_approved: () => "Welcome! Your account has been approved.",
  request_reviewed: (d) =>
    d.approved === true
      ? `Your suggestion about ${s(d, "person") || "the tree"} was approved`
      : `Your suggestion about ${s(d, "person") || "the tree"} was not accepted`,
};

const ha: Texts = {
  event: (d) => `Sabon taro: ${s(d, "title")}`,
  announcement: (d) => s(d, "body") || "Sanarwa",
  birthday: (d) => `Ranar haihuwar ${s(d, "name")} yau (${n(d, "age")})`,
  event_reminder: (d) => `Gobe: ${s(d, "title")}`,
  tagged: (d) => ("photo_id" in d ? "An saka ka a hoto" : "An saka ka a wani rubutu"),
  comment: (d) =>
    !s(d, "name")
      ? `Sabon sharhi: “${s(d, "body")}”`
      : d.also === true
      ? `Sabon sharhi daga ${s(d, "name")} a inda ka yi sharhi: “${s(d, "body")}”`
      : `Sharhi daga ${s(d, "name")}: “${s(d, "body")}”`,
  blood_request: (d) => `Ana buƙatar jini ${s(d, "blood_group")} don ${s(d, "patient")} a ${s(d, "hospital")}`,
  blood_offer: (d) => `Wani ɗan uwa zai iya ba da jini (${s(d, "blood_group")})`,
  remembrance: (d) => `Shekara ${n(d, "years")} da rasuwar ${s(d, "name")}`,
  memory: (d) => `Sabon tunawa da ${s(d, "name")}: “${s(d, "body")}”`,
  fund_contribution: (d) => `Sabuwar gudummawa da za a tabbatar: ${naira(n(d, "amount"))}`,
  fund_confirmed: (d) => `An tabbatar da gudummawarka ta ${naira(n(d, "amount"))}. Na gode!`,
  fund_request: (d) => `An nemi taimako: ${s(d, "title")}`,
  mentor_request: (d) => `Wani ya nemi jagorarka: “${s(d, "body")}”`,
  opportunity: (d) => `Sabuwar dama: ${s(d, "title")}`,
  poll: (d) => `Sabuwar ƙuri'a: ${s(d, "question")}`,
  story: (d) => `Sabon labari daga ${s(d, "speaker")}: ${s(d, "title")}`,
  test: () => "Gwajin sanarwa: sanarwa na aiki a wannan na'ura.",
  account_request: (d) =>
    s(d, "person")
      ? `${s(d, "name")}: “Ni ne ${s(d, "person")}” a bishiyar iyali`
      : s(d, "note")
      ? `Bayani daga ${s(d, "name")}: “${s(d, "note")}”`
      : `Sabon rajista na jiran amincewa: ${s(d, "name")}`,
  change_request: (d) =>
    s(d, "request_kind") === "create_person"
      ? `Shawara daga ${s(d, "name")}: a ƙara ${s(d, "person") || "wani"} a bishiyar iyali`
      : `Shawara daga ${s(d, "name")}: gyara bayanin ${s(d, "person") || "bishiyar iyali"}`,
  account_approved: () => "Barka da zuwa! An amince da asusunka.",
  request_reviewed: (d) =>
    d.approved === true
      ? `An amince da shawararka game da ${s(d, "person") || "bishiyar iyali"}`
      : `Ba a karɓi shawararka game da ${s(d, "person") || "bishiyar iyali"} ba`,
};

/** Title and body for one notification. */
export function render(kind: string, data: Data, locale: string, familyName: string) {
  const ha_ = locale === "ha";
  const texts = ha_ ? ha : en;
  const title = ha_ ? `Iyalin ${familyName}` : `${familyName} Family`;
  const body = (texts[kind] ?? (() => (ha_ ? "Sabon saƙo" : "New notification")))(data ?? {});
  return { title, body: body.length > 300 ? body.slice(0, 297) + "…" : body };
}
