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
  fund_contribution: (d) =>
    d.online === true
      ? `${s(d, "name") || "A member"} paid ${naira(n(d, "amount"))} in the app${s(d, "cause") ? ` for ${s(d, "cause")}` : ""}`
      : `New contribution to confirm: ${naira(n(d, "amount"))}`,
  fund_confirmed: (d) => `Your contribution of ${naira(n(d, "amount"))} was confirmed. Thank you!`,
  fund_request: (d) => `Support requested: ${s(d, "title")}`,
  mentor_request: (d) =>
    s(d, "name") ? `${s(d, "name")} asked for your guidance: “${s(d, "body")}”` : `Someone asked for your guidance: “${s(d, "body")}”`,
  mentor_reply: (d) => `${s(d, "name") || "Your mentorship"}: “${s(d, "body")}”`,
  direct_message: (d) =>
    s(d, "message_kind") === "photo"
      ? `${s(d, "name") || "New message"}: 📷 ${s(d, "body") || "Photo"}`
      : s(d, "message_kind") === "voice"
      ? `${s(d, "name") || "New message"}: 🎤 Voice note`
      : `${s(d, "name") || "New message"}: “${s(d, "body")}”`,
  content_report: (d) =>
    s(d, "reason") === "child_safety"
      ? "URGENT: a child safety concern was reported. Please review it now."
      : "Something was reported to the admins. Tap to review.",
  khatm: (d) => `New Quran khatm: ${s(d, "title")}. Take a juz.`,
  khatm_completed: (d) => `The khatm “${s(d, "title")}” is complete: all 30 juz read. May Allah accept it.`,
  khatm_reminder: (d) => {
    const juz = Array.isArray(d.juz) ? (d.juz as unknown[]).join(", ") : "";
    return `Reminder: “${s(d, "title")}” is to be finished tomorrow${juz ? ` (your juz: ${juz})` : ""}.`;
  },
  occasion: (d) => {
    const o = s(d, "occasion");
    if (d.eve === true) {
      return o === "ramadan"
        ? "Ramadan is expected to begin tomorrow, if the moon is sighted."
        : o === "eid_al_adha"
        ? "Eid al-Adha is expected tomorrow."
        : "Eid al-Fitr is expected tomorrow, if the moon is sighted.";
    }
    return o === "ramadan"
      ? "Ramadan Mubarak! May Allah accept our fasting."
      : o === "eid_al_fitr"
      ? "Eid Mubarak! Barka da Sallah."
      : o === "eid_al_adha"
      ? "Eid Mubarak! Barka da Babbar Sallah."
      : `Happy Islamic New Year ${n(d, "hijri_year")}!`;
  },
  dues_reminder: (d) => `${s(d, "title")}: you owe ${naira(n(d, "owed"))}. Tap to pay.`,
  weekly_summary: (d) => {
    const waiting = n(d, "waiting_suggestions") + n(d, "waiting_accounts");
    return `This week: ${n(d, "active")} active, ${n(d, "moments")} moments, ${n(d, "photos")} photos, ` +
      `${naira(n(d, "money_in"))} in.` + (waiting > 0 ? ` ${waiting} waiting for you.` : "");
  },
  admin_alert: (d) =>
    s(d, "alert") === "blood_no_offer"
      ? `No donor yet for ${s(d, "blood_group")} blood for ${s(d, "patient")} (${n(d, "hours")} h). Please call around.`
      : s(d, "alert") === "fund_low"
      ? `The welfare fund is down to ${naira(n(d, "balance"))}, below ${naira(n(d, "threshold"))}.`
      : `Waiting over 3 days: ${n(d, "suggestions")} suggestions, ${n(d, "accounts")} new accounts.`,
  claim_reviewed: (d) =>
    d.approved === true
      ? `You're now linked to ${s(d, "person")} in the family tree.`
      : s(d, "reason")
      ? `Your request to be linked to ${s(d, "person")} was declined: “${s(d, "reason")}”`
      : `Your request to be linked to ${s(d, "person")} was declined.`,
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
  app_update: (d) => `A new version of the app is ready (${s(d, "version")}). Tap to download.`,
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
  fund_contribution: (d) =>
    d.online === true
      ? `${s(d, "name") || "Wani ɗan uwa"} ya biya ${naira(n(d, "amount"))} a manhaja${s(d, "cause") ? ` don ${s(d, "cause")}` : ""}`
      : `Sabuwar gudummawa da za a tabbatar: ${naira(n(d, "amount"))}`,
  fund_confirmed: (d) => `An tabbatar da gudummawarka ta ${naira(n(d, "amount"))}. Na gode!`,
  fund_request: (d) => `An nemi taimako: ${s(d, "title")}`,
  mentor_request: (d) =>
    s(d, "name") ? `${s(d, "name")} ya nemi jagorarka: “${s(d, "body")}”` : `Wani ya nemi jagorarka: “${s(d, "body")}”`,
  mentor_reply: (d) => `${s(d, "name") || "Jagoranci"}: “${s(d, "body")}”`,
  direct_message: (d) =>
    s(d, "message_kind") === "photo"
      ? `${s(d, "name") || "Sabon saƙo"}: 📷 ${s(d, "body") || "Hoto"}`
      : s(d, "message_kind") === "voice"
      ? `${s(d, "name") || "Sabon saƙo"}: 🎤 Saƙon murya`
      : `${s(d, "name") || "Sabon saƙo"}: “${s(d, "body")}”`,
  content_report: (d) =>
    s(d, "reason") === "child_safety"
      ? "GAGGAWA: an kai rahoton damuwa kan lafiyar yara. Don Allah a duba yanzu."
      : "An kai rahoton wani abu ga shugabanni. Taɓa don dubawa.",
  khatm: (d) => `Sabuwar saukar Alƙur'ani: ${s(d, "title")}. Ɗauki juz'i.`,
  khatm_completed: (d) => `An kammala saukar Alƙur'ani “${s(d, "title")}”: an karanta juz'i 30 duka. Allah ya karɓa.`,
  khatm_reminder: (d) => {
    const juz = Array.isArray(d.juz) ? (d.juz as unknown[]).join(", ") : "";
    return `Tunatarwa: gobe za a kammala “${s(d, "title")}”${juz ? ` (juz'inka: ${juz})` : ""}.`;
  },
  occasion: (d) => {
    const o = s(d, "occasion");
    if (d.eve === true) {
      return o === "ramadan"
        ? "Ana sa ran fara azumin Ramadan gobe, idan an ga wata."
        : o === "eid_al_adha"
        ? "Ana sa ran Babbar Sallah gobe."
        : "Ana sa ran Karamar Sallah gobe, idan an ga wata.";
    }
    return o === "ramadan"
      ? "Barka da azumi! Allah ya karɓi ibadunmu."
      : o === "eid_al_fitr"
      ? "Barka da Sallah! Allah ya maimaita mana."
      : o === "eid_al_adha"
      ? "Barka da Babbar Sallah! Allah ya karɓi ibadunmu."
      : `Barka da sabuwar shekara ta ${n(d, "hijri_year")}!`;
  },
  dues_reminder: (d) => `${s(d, "title")}: ana binka ${naira(n(d, "owed"))}. Taɓa don biya.`,
  weekly_summary: (d) => {
    const waiting = n(d, "waiting_suggestions") + n(d, "waiting_accounts");
    return `Wannan mako: mutum ${n(d, "active")} sun shiga, labarai ${n(d, "moments")}, hotuna ${n(d, "photos")}, ` +
      `${naira(n(d, "money_in"))} sun shigo.` + (waiting > 0 ? ` ${waiting} na jiran ka.` : "");
  },
  admin_alert: (d) =>
    s(d, "alert") === "blood_no_offer"
      ? `Har yanzu babu mai ba da jinin ${s(d, "blood_group")} ga ${s(d, "patient")} (awa ${n(d, "hours")}). Don Allah a tuntuɓi mutane.`
      : s(d, "alert") === "fund_low"
      ? `Asusun taimako ya ragu zuwa ${naira(n(d, "balance"))}, ƙasa da ${naira(n(d, "threshold"))}.`
      : `Sun jira fiye da kwana 3: shawarwari ${n(d, "suggestions")}, sababbin asusu ${n(d, "accounts")}.`,
  claim_reviewed: (d) =>
    d.approved === true
      ? `An haɗa ka da ${s(d, "person")} a bishiyar iyali.`
      : s(d, "reason")
      ? `Ba a karɓi buƙatarka ta zama ${s(d, "person")} ba: “${s(d, "reason")}”`
      : `Ba a karɓi buƙatarka ta zama ${s(d, "person")} ba.`,
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
  app_update: (d) => `Sabon salo na manhajar ya fito (${s(d, "version")}). Taɓa don saukewa.`,
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
