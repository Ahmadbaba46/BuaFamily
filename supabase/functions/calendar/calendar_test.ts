// deno test supabase/functions/calendar
import { type Db, handle } from "./handler.ts";
import { buildCalendar, escapeText, type Feed, fold } from "./ics.ts";

function assertEquals(actual: unknown, expected: unknown, msg = "") {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${msg}\n  actual:   ${a}\n  expected: ${e}`);
}
function assert(ok: boolean, msg: string) {
  if (!ok) throw new Error(msg);
}

const feed: Feed = {
  family_name: "Bua",
  timezone: "Africa/Lagos",
  locale: "en",
  events: [{
    id: "e1",
    title: "Naming of Fatima, daughter of Musa",
    category: "naming",
    details: "Bring your family; lunch after.",
    starts_at: "2026-11-07T09:30:00+01:00",
    ends_at: null,
    place: "Family house",
    address: "12 Bua Road, Kano",
    updated_at: "2026-10-01T10:00:00Z",
    rsvp: "going",
  }],
  birthdays: [
    { person_id: "p1", name: "Aisha Bua", birth_date: "1990-03-14" },
    { person_id: "p2", name: "Leap Bua", birth_date: "2000-02-29" },
  ],
  remembrance: [{ person_id: "p3", name: "Kaka Bua", death_date: "2015-06-01" }],
};
const now = new Date("2026-10-07T12:00:00Z");

/** The calendar with folded lines joined back. */
const unfold = (ics: string) => ics.replace(/\r\n /g, "");

Deno.test("escaping and folding follow the iCalendar rules", () => {
  assertEquals(escapeText("a, b; c\\d\nnext"), "a\\, b\\; c\\\\d\\nnext");
  const long = "DESCRIPTION:" + "ɗ".repeat(60);
  const folded = fold(long);
  for (const line of folded.split("\r\n")) {
    assert(new TextEncoder().encode(line).length <= 75, `line too long: ${line}`);
  }
  assertEquals(folded.replace(/\r\n /g, ""), long, "nothing lost, no letter split");
});

Deno.test("events, birthdays and remembrance days, in English", () => {
  const ics = buildCalendar(feed, "https://bua.example", now);
  assert(ics.endsWith("END:VCALENDAR\r\n"), "ends properly with CRLF");
  assert(!/[^\r]\n/.test(ics), "every line ends with CRLF");
  const u = unfold(ics);
  assert(u.includes("X-WR-CALNAME:Bua Family"), "the calendar's name");
  assert(u.includes("UID:event-e1@buafamily"), "a steady id per event");
  assert(u.includes("DTSTART:20261107T083000Z"), "the start in UTC");
  assert(u.includes("DTEND:20261107T103000Z"), "two hours when no end is given");
  assert(u.includes("SUMMARY:Naming of Fatima\\, daughter of Musa"), "title escaped");
  assert(u.includes("LOCATION:Family house\\, 12 Bua Road\\, Kano"), "place and address");
  assert(u.includes("Your answer: Going"), "my answer");
  assert(u.includes("URL:https://bua.example/#/events/e1"), "a link to the event");
  assert(u.includes("TRIGGER:-P1D"), "a reminder the day before");
  assert(u.includes("DTSTART;VALUE=DATE:19900314") && u.includes("DTEND;VALUE=DATE:19900315"), "birthday, all day");
  assert(u.includes("SUMMARY:🎂 Aisha Bua's birthday"), "birthday title");
  assert(u.includes("RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=-1"), "29 February: the end of February each year");
  assert(u.includes("SUMMARY:🕊️ Remembering Kaka Bua"), "remembrance");
  assert(u.includes("https://bua.example/#/person/p3/memorial"), "a link to the memorial page");
});

Deno.test("in Hausa; not going shows as free time", () => {
  const ics = unfold(buildCalendar(
    { ...feed, locale: "ha", events: [{ ...feed.events[0], rsvp: "no" }] },
    "https://bua.example",
    now,
  ));
  assert(ics.includes("X-WR-CALNAME:Iyalin Bua"), "Hausa name");
  assert(ics.includes("Ranar haihuwar Aisha Bua"), "Hausa birthday");
  assert(ics.includes("Amsarka: Ba zan zo ba"), "Hausa answer");
  assert(ics.includes("TRANSP:TRANSPARENT"), "free time");
});

Deno.test("the link: right token gets the calendar, others get 404", async () => {
  const token = "a".repeat(64);
  const asked: string[] = [];
  const db: Db = {
    feed: (t) => {
      asked.push(t);
      return Promise.resolve({ data: t === token ? feed : null, error: null });
    },
  };
  const ok = await handle(new Request(`https://x/calendar?token=${token}`), db, "https://bua.example", now);
  assertEquals(ok.status, 200);
  assertEquals(ok.headers.get("Content-Type"), "text/calendar; charset=utf-8");
  assert((await ok.text()).startsWith("BEGIN:VCALENDAR"), "a calendar");
  assertEquals((await handle(new Request(`https://x/calendar?token=${token}.ics`), db, "s", now)).status, 200,
    ".ics at the end is fine");
  assertEquals((await handle(new Request(`https://x/calendar?token=${"b".repeat(64)}`), db, "s", now)).status, 404);
  assertEquals((await handle(new Request("https://x/calendar?token=x'; drop"), db, "s", now)).status, 404,
    "junk never reaches the database");
  assertEquals(asked.length, 3);
  assertEquals((await handle(new Request(`https://x/calendar?token=${token}`, { method: "POST" }), db, "s", now)).status,
    405);
});
