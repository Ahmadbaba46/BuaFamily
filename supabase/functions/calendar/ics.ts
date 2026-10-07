// The family calendar as an iCalendar (.ics) file, in the member's language.

export interface FeedEvent {
  id: string;
  title: string;
  category?: string;
  details?: string | null;
  starts_at: string;
  ends_at?: string | null;
  place?: string | null;
  address?: string | null;
  updated_at?: string | null;
  rsvp?: "going" | "maybe" | "no" | null;
}

export interface Feed {
  family_name: string;
  timezone: string;
  locale: string;
  events: FeedEvent[];
  birthdays: { person_id: string; name: string; birth_date: string }[];
  remembrance: { person_id: string; name: string; death_date: string }[];
}

const texts = {
  en: {
    calendar: (f: string) => `${f} Family`,
    birthday: (n: string) => `🎂 ${n}'s birthday`,
    birthdayNote: "Send a greeting in the app.",
    remembrance: (n: string) => `🕊️ Remembering ${n}`,
    passed: (d: string) => `Passed away on ${d}. May Allah have mercy on them.`,
    rsvp: { going: "Your answer: Going", maybe: "Your answer: Maybe", no: "Your answer: Not going" },
    tomorrow: (t: string) => `Tomorrow: ${t}`,
    open: "Open in the app:",
  },
  ha: {
    calendar: (f: string) => `Iyalin ${f}`,
    birthday: (n: string) => `🎂 Ranar haihuwar ${n}`,
    birthdayNote: "Aika gaisuwa a manhaja.",
    remembrance: (n: string) => `🕊️ Tunawa da ${n}`,
    passed: (d: string) => `Rasuwa: ${d}. Allah ya jiƙa.`,
    rsvp: { going: "Amsarka: Zan zo", maybe: "Amsarka: Wataƙila", no: "Amsarka: Ba zan zo ba" },
    tomorrow: (t: string) => `Gobe: ${t}`,
    open: "Buɗe a manhaja:",
  },
};

/** Text with \ ; , and new lines escaped. */
export function escapeText(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\r?\n/g, "\\n");
}

/** Lines longer than 75 bytes go on as lines starting with a space (never splitting a letter). */
export function fold(line: string): string {
  const enc = new TextEncoder();
  if (enc.encode(line).length <= 75) return line;
  const parts: string[] = [];
  let current = "";
  let bytes = 0;
  let limit = 75;
  for (const ch of line) {
    const n = enc.encode(ch).length;
    if (bytes + n > limit) {
      parts.push(current);
      current = "";
      bytes = 0;
      limit = 74; // the leading space counts
    }
    current += ch;
    bytes += n;
  }
  parts.push(current);
  return parts.join("\r\n ");
}

const pad = (n: number) => String(n).padStart(2, "0");

/** 20261107T093000Z */
export function utcStamp(d: Date): string {
  return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}T` +
    `${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}Z`;
}

/** 2026-11-07 → 20261107 */
const dateValue = (iso: string) => iso.slice(0, 10).replace(/-/g, "");

function nextDay(iso: string): string {
  const d = new Date(`${iso.slice(0, 10)}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}`;
}

/** Every year on the same day (29 February: the last day of February). */
function yearly(iso: string): string {
  return iso.slice(5, 10) === "02-29" ? "RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=-1" : "RRULE:FREQ=YEARLY";
}

export function buildCalendar(feed: Feed, siteUrl: string, now = new Date()): string {
  const t = feed.locale === "ha" ? texts.ha : texts.en;
  const stamp = utcStamp(now);
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Bua Family//Family calendar//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${escapeText(t.calendar(feed.family_name))}`,
    `X-WR-TIMEZONE:${feed.timezone}`,
    "REFRESH-INTERVAL;VALUE=DURATION:PT6H",
    "X-PUBLISHED-TTL:PT6H",
  ];

  for (const e of feed.events) {
    const start = new Date(e.starts_at);
    const end = e.ends_at ? new Date(e.ends_at) : new Date(start.getTime() + 2 * 3600_000);
    const link = `${siteUrl}/#/events/${e.id}`;
    const notes = [
      e.details?.trim(),
      e.rsvp ? t.rsvp[e.rsvp] : null,
      `${t.open} ${link}`,
    ].filter(Boolean).join("\n\n");
    lines.push(
      "BEGIN:VEVENT",
      `UID:event-${e.id}@buafamily`,
      `DTSTAMP:${stamp}`,
      ...(e.updated_at ? [`LAST-MODIFIED:${utcStamp(new Date(e.updated_at))}`] : []),
      `DTSTART:${utcStamp(start)}`,
      `DTEND:${utcStamp(end)}`,
      `SUMMARY:${escapeText(e.title)}`,
      `DESCRIPTION:${escapeText(notes)}`,
      ...([e.place, e.address].some((x) => x?.trim())
        ? [`LOCATION:${escapeText([e.place, e.address].filter((x) => x?.trim()).join(", "))}`]
        : []),
      `URL:${link}`,
      ...(e.category ? [`CATEGORIES:${escapeText(e.category)}`] : []),
      // Not going: shown as free time.
      ...(e.rsvp === "no" ? ["TRANSP:TRANSPARENT"] : []),
      "BEGIN:VALARM",
      "ACTION:DISPLAY",
      `DESCRIPTION:${escapeText(t.tomorrow(e.title))}`,
      "TRIGGER:-P1D",
      "END:VALARM",
      "END:VEVENT",
    );
  }

  for (const b of feed.birthdays) {
    lines.push(
      "BEGIN:VEVENT",
      `UID:birthday-${b.person_id}@buafamily`,
      `DTSTAMP:${stamp}`,
      `DTSTART;VALUE=DATE:${dateValue(b.birth_date)}`,
      `DTEND;VALUE=DATE:${nextDay(b.birth_date)}`,
      yearly(b.birth_date),
      `SUMMARY:${escapeText(t.birthday(b.name))}`,
      `DESCRIPTION:${escapeText(`${t.birthdayNote}\n${siteUrl}/#/person/${b.person_id}`)}`,
      "TRANSP:TRANSPARENT",
      "END:VEVENT",
    );
  }

  for (const r of feed.remembrance) {
    lines.push(
      "BEGIN:VEVENT",
      `UID:remembrance-${r.person_id}@buafamily`,
      `DTSTAMP:${stamp}`,
      `DTSTART;VALUE=DATE:${dateValue(r.death_date)}`,
      `DTEND;VALUE=DATE:${nextDay(r.death_date)}`,
      yearly(r.death_date),
      `SUMMARY:${escapeText(t.remembrance(r.name))}`,
      `DESCRIPTION:${escapeText(`${t.passed(r.death_date.slice(0, 10))}\n${siteUrl}/#/person/${r.person_id}/memorial`)}`,
      "TRANSP:TRANSPARENT",
      "END:VEVENT",
    );
  }

  lines.push("END:VCALENDAR");
  return lines.map(fold).join("\r\n") + "\r\n";
}
