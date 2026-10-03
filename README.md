# Bua Family

A private app for the Bua family: browse the family tree, get to know relatives,
share moments and photos, plan family events, and keep everyone's details
(living and deceased) in one place. English and Hausa.

- **App:** Flutter (Android app and website from one codebase) in [`app/`](app)
- **Backend:** Supabase (PostgreSQL, auth, photo storage) in [`supabase/`](supabase)

## What's in the app

- **Family tree:** zoomable tree from the eldest ancestor down. Wives sit beside
  their husband and each child hangs from their own mother, so households with
  several wives stay readable. Tap anyone to open their profile; collapse or
  expand branches; start the tree from any person.
- **Profiles for everyone,** including people who have died and people who will
  never use the app: names, title (Alhaji, Hajiya, Dr…), nickname, dates
  (exact or approximate), places, burial place, branch, life story and photo.
- **"How are we related?"** Every profile shows how that person is related to
  you: uncle (baffa or kawu), cousin, half-brother through the father,
  co-wife (kishiya), in-laws, step-relations and more. Tap it (or More → How
  are we related?) to pick any two people and see the chain step by step,
  including the ancestor they share.
- **Memorial pages** for relatives who have died: dates, a prayer, their life
  story, photos they're tagged in, and prayers and memories from the family.
  Members can ask for a gentle reminder on the anniversary.
- **Education, work, skills, contact and health details.** Health (blood group,
  genotype, hereditary conditions) is private unless the person chooses to share it.
- **Admin approval:**
  - Admins add and edit directly.
  - Members can propose new relatives and corrections; an admin approves or
    rejects each one. Admins can switch member proposals on or off.
  - Members can always edit their own details, but changes to their own name,
    dates or life status still go to an admin.
- **Accounts are separate from people in the tree.** New sign-ups wait for an
  admin, who links them to their place in the tree.
- **Home feed:** today's birthdays and remembrances, pinned notices, and
  moments from relatives with photos, people tagged, "Ma sha Allah" and comments.
- **Albums:** shared family albums (weddings, Sallah, old photos), grouped by
  decade and filterable by who is in them, plus "Photos of you". Anyone can
  tag relatives in a photo and add memories. Photos are resized before upload.
- **Events and announcements:** naming ceremonies, weddings, meetings and more,
  with Going / Maybe / Can't go replies (and how many people you're bringing),
  wishes, add-to-calendar and directions. Only admins can pin to Home.
- **Notifications:** a bell on Home for new events and announcements, being
  tagged, comments on your posts, birthdays and event reminders (live, no refresh).
- **Phone notifications:** every notification can also pop up on members'
  phones and in their browsers, even when the app is closed (free, through
  Firebase Cloud Messaging), in each member's language. Members turn it on per
  device; tapping a notification opens the right page. Muted kinds are never
  sent, and urgent blood requests come through with sound.
- **SMS through [Termii](https://termii.com):** members add their phone number
  and choose birthday reminders and/or events. Every morning at 07:30 (Nigeria
  time) the family gets birthday texts, and people who said Going or Maybe get a
  reminder the day before an event. Admins can also text an event or
  announcement to the family. Texts go out in each member's language.
- **Who can help?** Search the family's work, studies and skills (health, law,
  trades, teaching, business, engineering, tech, Islamic studies), with a call
  button for relatives who share their number.
- **Blood donors:** relatives opt in from their health details and are listed
  with only their blood group and town. Anyone can post a blood request; donors
  with a compatible blood group are alerted in the app (and by SMS if they opted
  in), offer with one tap, and the person who asked is told.
- **Welfare fund:** the fund balance, open causes (school fees, hospital
  bills, reunions) with progress, and how to pay. Members pay the family
  account or the treasurer, record it in the app, and a treasurer confirms it.
  Amounts stay private to the contributor and the committee (admins and
  treasurers); everyone sees totals and the names of those who chose to be
  listed. Anyone can ask for support privately.
- **Mentors & scholarships:** relatives offer guidance in their field,
  students say what help they want, and anyone can share a scholarship or
  job. "Ask" sends a mentor a private note; students hear about new
  opportunities.
- **Polls:** any member can ask the family a question with a closing date.
  Ballots are secret: you see the results once you have voted or the poll has
  closed, and you can change your vote until then. Closed polls are kept as
  the family's decisions.
- **Elders' stories:** record an elder telling a story right in the app, or
  upload an old recording (a cassette transfer, a voice note), with who is
  speaking, the language and an optional transcript. Every member can listen;
  the family is told when a new story is added.
- **Import, export & backup (admins):** export the tree as GEDCOM (opens in
  other genealogy apps), a spreadsheet (CSV) or a poster-size printable PDF,
  optionally with contact and health details. Import a GEDCOM or CSV file:
  people already in the tree are matched, and an admin reviews the matches
  before anything is added. The database also keeps a weekly backup of all
  the family's data (the last eight weeks) that admins can download.
- **Restore from a backup (admins):** pick a stored backup or a downloaded
  backup file and the app first shows what would change (people and
  relationships to bring back, edits to undo). Restoring brings back what was
  deleted and, if chosen, changes later edits back; it never deletes anything
  added since, and sends no notifications. A copy of the data from just before
  is kept, so a restore can itself be undone.
- **Birthdays & remembrance:** today, this week and the coming month at a
  glance: birthdays, death anniversaries, wedding anniversaries and events,
  with a quick greeting or prayer.
- **Edit my details:** members update their nickname, story, phone, town,
  blood group, genotype and skills, and choose whether contact and health
  details are shared with the family or kept for admins only.
- **Settings:** language, data saver (load photos only when tapped, shrink
  uploads) and which notifications to receive. Urgent blood requests always
  come through.
- **English and Hausa,** switchable at any time.

## Screens

Design mockups for the app (sample data). The app follows these designs.

### Family tree & people

<table>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/main.png" alt="Sign in" width="180"><br><sub>Sign in</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/pending.png" alt="Waiting for approval" width="180"><br><sub>Waiting for approval</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/tree.png" alt="Family tree" width="180"><br><sub>Family tree</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/profile.png" alt="Profile" width="180"><br><sub>Profile</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/profile-hausa.png" alt="Deceased relative, in Hausa" width="180"><br><sub>Deceased relative, in Hausa</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/members.png" alt="Members" width="180"><br><sub>Members</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/add-relative.png" alt="Add a relative" width="180"><br><sub>Add a relative</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/my-requests.png" alt="My requests" width="180"><br><sub>My requests</sub></td>
  </tr>
</table>

### Sharing & events

<table>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/home.png" alt="Home feed" width="180"><br><sub>Home feed</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/new-moment.png" alt="Share a moment" width="180"><br><sub>Share a moment</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/albums.png" alt="Albums" width="180"><br><sub>Albums</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/album-detail.png" alt="Album" width="180"><br><sub>Album</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/photo-view.png" alt="Photo with people tagged" width="180"><br><sub>Photo with people tagged</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/events.png" alt="Events & announcements" width="180"><br><sub>Events & announcements</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/event-detail.png" alt="Event & replies" width="180"><br><sub>Event & replies</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/new-event.png" alt="New event or announcement" width="180"><br><sub>New event or announcement</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/notifications.png" alt="Notifications" width="180"><br><sub>Notifications</sub></td>
  </tr>
</table>

### Knowing and helping each other

<table>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/who-can-help.png" alt="Who can help?" width="180"><br><sub>Who can help?</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/blood-donors.png" alt="Blood donors" width="180"><br><sub>Blood donors</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/how-related.png" alt="How are we related?" width="180"><br><sub>How are we related?</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/memorial.png" alt="Memorial page" width="180"><br><sub>Memorial page</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/welfare-fund.png" alt="Welfare fund" width="180"><br><sub>Welfare fund</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/fund-cause.png" alt="Fund cause & contributions" width="180"><br><sub>Fund cause & contributions</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/mentorship.png" alt="Mentors & scholarships" width="180"><br><sub>Mentors & scholarships</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/polls.png" alt="Polls & family decisions" width="180"><br><sub>Polls & family decisions</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/oral-history.png" alt="Elders' stories" width="180"><br><sub>Elders' stories</sub></td>
  </tr>
</table>

### Admin & settings

<table>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/admin-requests.png" alt="Admin: requests" width="180"><br><sub>Admin: requests</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/admin-accounts.png" alt="Admin: accounts" width="180"><br><sub>Admin: accounts</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/admin-settings.png" alt="Admin: settings" width="180"><br><sub>Admin: settings</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/more.png" alt="More" width="180"><br><sub>More</sub></td>
  </tr>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/import-export.png" alt="Import, export & backup" width="180"><br><sub>Import, export & backup</sub></td>
  </tr>
</table>

### Settings & personal

<table>
  <tr>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/reminders.png" alt="Birthdays & remembrance" width="180"><br><sub>Birthdays & remembrance</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/edit-profile.png" alt="Edit my details & privacy" width="180"><br><sub>Edit my details & privacy</sub></td>
    <td align="center" valign="top" width="25%"><img src="docs/mockups/app-settings.png" alt="Settings" width="180"><br><sub>Settings</sub></td>
  </tr>
</table>


## How the data is organised

| Table | Holds |
|---|---|
| `persons` | Everyone in the tree, living or deceased |
| `unions` | Marriages (any number per person, with status and order) |
| `parent_child` | Parent links: biological, adopted, foster or step |
| `person_education`, `person_occupations`, `person_skills` | Profile details |
| `person_contacts`, `person_health` | Private-by-choice details with a visibility setting |
| `profiles` | Sign-in accounts: role (admin/member), status, linked person |
| `change_requests` | Member proposals awaiting admin review |
| `app_settings` | Family name, member proposals on/off, default tree root |
| `posts`, `post_people` | Moments and announcements, and who they are about |
| `albums`, `photos`, `photo_people` | Shared albums, photos and who is in each photo |
| `events`, `event_rsvps` | Family events and each member's reply |
| `likes`, `comments` | "Ma sha Allah" and comments on posts, photos and events |
| `notifications` | Each member's in-app inbox |
| `push_tokens` | The phones and browsers each member turned notifications on for |
| `blood_requests`, `blood_offers` | Requests for blood and who offered to donate |
| `fund_causes`, `fund_contributions`, `fund_payouts`, `fund_settings` | Welfare fund causes, recorded contributions, support paid and the account details |
| `mentors`, `mentee_requests`, `mentor_asks`, `opportunities` | Who offers guidance, students looking for help, private asks, and shared scholarships or jobs |
| `stories` | Elders' recorded stories: who is speaking, language, transcript (audio in the private `stories` bucket) |
| `private.restore_points` | The family's data from just before the last restore, so it can be undone |
| `private.backups` | Weekly JSON snapshots of the family's data, eight rotating slots (not reachable from the app; admins download through `admin_backup`) |
| `polls`, `poll_options`, `poll_votes` | Family polls, their choices and each member's (secret) vote |
| `memories`, `remembrance_reminders` | Prayers and memories on memorial pages; who wants an anniversary reminder |
| `private.sms_outbox` | Text messages waiting to be sent, sent or failed (not reachable from the app) |

Permissions are enforced in the database with row-level security, so they hold
no matter which app or tool connects:

| | Pending account | Member | Admin |
|---|---|---|---|
| See the tree and profiles | ✗ | ✓ | ✓ |
| Edit own details, photo, education, work, skills | n/a | ✓ | ✓ |
| Change own name, dates or life status | n/a | via approval | ✓ |
| Add relatives or relationships | n/a | via approval, if switched on | ✓ |
| See private contact or health details | n/a | own only | ✓ |
| Post moments, photos, events, announcements; tag, like, comment | ✗ | ✓ | ✓ |
| Edit or delete a post, photo, event or comment | ✗ | own only | ✓ |
| Pin to Home | ✗ | ✗ | ✓ |
| Approve requests, manage accounts and settings | ✗ | ✗ | ✓ |

The database also refuses impossible family structures: a person can't become
their own ancestor or have two biological fathers.

## Setup

### 1. Create the backend (Supabase)

1. Create a project at [supabase.com](https://supabase.com). The free plan is
   enough to start.
2. Apply the database migrations, using **one** of these options:
   - **SQL Editor:** open each file in [`supabase/migrations`](supabase/migrations)
     in order, paste it into the SQL editor, and run it.
   - **Supabase CLI:**
     ```sh
     supabase init                          # keeps the existing migrations
     supabase link --project-ref YOUR-PROJECT-REF
     supabase db push
     ```
3. Under **Authentication → Providers**, make sure Email is enabled. Under
   **Authentication → URL Configuration**, set the Site URL to wherever you host
   the web app.
4. **Sign up in the app right away.** The very first account becomes the admin
   automatically; every later account waits for approval.

### 2. Turn on SMS (optional)

SMS is sent from the database itself: `pg_cron` runs every minute and `pg_net`
posts queued messages to Termii, so there is no extra server.

1. In [Termii](https://termii.com), fund your account, copy your **API key**,
   and register a **Sender ID** (e.g. `BuaFamily`). Note the API base URL shown
   in your dashboard if it isn't `https://api.ng.termii.com`.
2. In the app, open **More → Admin → Settings → SMS**, save the API key (it is
   stored encrypted in Supabase Vault and never shown again), the Sender ID and
   the route. Choose **DND** only after Termii has activated it on your account;
   the generic route cannot reach numbers on Do-Not-Disturb.
3. Add your own number under **More → Notifications & SMS**, switch SMS on in
   the admin settings, and tap **Send a test SMS to me**.

Each member decides whether they want texts. Admin texts for events and
announcements are opt-in per post ("Also send SMS"). Hausa texts avoid the
hooked letters (ɗ ƙ ƴ) because they make an SMS cost twice as much.

### 3. Turn on phone notifications (optional)

Notifications go from the database to the `push` Edge Function
([`supabase/functions/push`](supabase/functions/push)), which sends them through
Firebase Cloud Messaging (free) using the family's Firebase project
**buafamily**. Members who don't turn them on still see everything under the bell.

Already done: the Firebase project with the Android and web apps
(`com.fuyoudhat.buafamily`), the web settings built into the app
(`app/lib/services/push.dart`), the database side and the deployed function.

Still to do:

1. **Firebase key for the sender:** in the
   [Firebase console](https://console.firebase.google.com/project/buafamily/settings/serviceaccounts/adminsdk)
   (Project settings → Service accounts), choose **Generate new private key**.
   In the app, open **More → Admin → Settings → Phone notifications**, tap
   **Firebase key** and choose that file. It is stored encrypted in Supabase
   Vault; delete the downloaded file afterwards. (The Android app's settings
   are already built in.)
2. Turn notifications on for your own phone (**More → Notifications & SMS**)
   and tap **Send me a test notification**.

For a different Firebase project, change the IDs at the top of
`app/lib/services/push.dart` and redeploy the function with
`supabase functions deploy push --no-verify-jwt`.

### 4. Run the app

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```sh
cd app
cp config.example.json config.json   # fill in your project URL and publishable key
flutter pub get
flutter run --dart-define-from-file=config.json
```

The URL and publishable key are under **Project Settings → API** in Supabase.
The publishable key is safe to ship in the app; the database permissions above
are what protect the data.

Release builds:

```sh
flutter build apk --dart-define-from-file=config.json   # Android
flutter build web --dart-define-from-file=config.json   # website (upload build/web to any static host)
```

**iPhone:** there is no iPhone app planned. Family members on iPhones use the
website; added to the Home Screen (Safari → Share → Add to Home Screen, iOS
16.4 or later) it opens like an app and can receive notifications.

### 5. Moving to a new Supabase project (from a backup)

1. Download the latest backup: **More → Import, export & backup → Download**.
2. Create the new project and apply the migrations (step 1), deploy the
   `push` function if you use notifications (step 3), then point the app at
   it (step 4).
3. Sign in first: the first account becomes the admin.
4. Open **More → Import, export & backup → Restore…**, choose **A backup
   file…**, check what will come back, and tap **Restore**.
5. Members sign in again and the admin links each account to its person, as
   when the app started. Photos, voice recordings and receipts are files, not
   part of the backup; copy the storage buckets separately if you need them.

## Tests

```sh
cd app && flutter analyze && flutter test   # tree layout, relationships, screens in English and Hausa
supabase/tests/local/run.sh                 # migrations + permission tests on a throwaway Postgres (run as non-root)
deno test supabase/functions/push           # push texts, Firebase sign-in and sending
```

Both suites run on every push via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Translations

All app text is in [`app/lib/l10n/app_en.arb`](app/lib/l10n/app_en.arb) and
[`app/lib/l10n/app_ha.arb`](app/lib/l10n/app_ha.arb). **The Hausa text,
especially the kinship terms, should be reviewed by a native speaker.** Edit
the `.arb` file and rebuild; no code changes are needed. The app bundles the
Noto Sans font so Hausa letters (Ɗ ɗ Ƙ ƙ Ƴ ƴ) display correctly on every phone.

## Roadmap

- **Play Store release:** app icon, signing, privacy policy and the store
  listing, so Android members can install the app. (No iPhone app is planned;
  iPhone users use the website.)
- **Restoring files:** backups hold the family's data but not photos, voice
  recordings or receipts, which are files in storage. A full copy of those
  would need a separate storage export.
