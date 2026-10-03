# Bua Family

A private app for the Bua family: browse the family tree, get to know relatives,
share moments and photos, plan family events, and keep everyone's details
(living and deceased) in one place. English and Hausa.

- **App:** Flutter (Android, iOS and web from one codebase) in [`app/`](app)
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
  co-wife (kishiya), in-laws, step-relations and more.
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
- **English and Hausa,** switchable at any time.

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

### 2. Run the app

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
flutter build ipa --dart-define-from-file=config.json   # iOS (needs a Mac)
```

## Tests

```sh
cd app && flutter analyze && flutter test   # tree layout, relationships, screens in English and Hausa
supabase/tests/local/run.sh                 # migrations + permission tests on a throwaway Postgres (run as non-root)
```

Both suites run on every push via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Translations

All app text is in [`app/lib/l10n/app_en.arb`](app/lib/l10n/app_en.arb) and
[`app/lib/l10n/app_ha.arb`](app/lib/l10n/app_ha.arb). **The Hausa text,
especially the kinship terms, should be reviewed by a native speaker.** Edit
the `.arb` file and rebuild; no code changes are needed. The app bundles the
Noto Sans font so Hausa letters (Ɗ ɗ Ƙ ƙ Ƴ ƴ) display correctly on every phone.

## Roadmap

- **Next for sharing and events:** phone notifications and birthday reminders.
- **Phase 3, family knowledge:** "who can help?" skills directory, blood donor
  matching, memorial pages, birthday and anniversary reminders.
- **Phase 4:** welfare fund tracker, mentorship, oral-history voice notes,
  polls, GEDCOM import and export.
