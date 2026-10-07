# Putting Bua Family on Google Play

Everything needed for the Play Console, in the order you'll meet it.

| What | Where |
|---|---|
| App bundle (.aab) | GitHub → Actions → **Android app** → latest run → Artifacts → `bua-family-play-1.0.N`. Built when the four `ANDROID_*` secrets are set. On Windows: `app\tool\build_android.ps1 -Play`. |
| App icon 512×512 | [`docs/brand/app-icon-512.png`](../brand/app-icon-512.png) |
| Feature graphic 1024×500 | [`feature-graphic.png`](feature-graphic.png) |
| Privacy policy URL | https://buafamily.vercel.app/privacy.html |
| Account deletion URL | https://buafamily.vercel.app/delete-account.html |
| Package name | `com.fuyoudhat.buafamily` |

The privacy and deletion pages show the developer's email and phone from
**Admin → Settings → About the app**. Fill those in first: Play wants a contact
email, and people without the app need someone to write to.

## 1. Before you start

- **Developer account.** Sign up at play.google.com/console (one-time US$25). A
  *personal* account made after November 2023 must run a **closed test with at
  least 12 testers for 14 days in a row** before it can publish to everyone.
  For a family app that's easy: add 12+ relatives' Gmail addresses as testers.
  An *organisation* account (for Fuyoudhat Tech Support, needs a D-U-N-S number)
  skips that rule.
- **The family signing key.** Keep `bua-family.jks` and its password safe; it's
  also Play's *upload key*.

## 2. Create the app

Play Console → **Create app**: name *Bua Family*, default language *English
(United Kingdom)*, App, Free. Accept the declarations.

## 3. App signing (do this on the first upload)

When you upload the first bundle, Play asks about the **app signing key**:

- **Recommended: use the family key** (*Use a different key* → *Export and
  upload a key from Java keystore*, follow Play's PEPK steps with
  `bua-family.jks`). Phones that installed the APK from the website then update
  straight from Play.
- If you let Google create a new key instead, phones with the website APK must
  uninstall it once before installing from Play (signed in again, nothing is
  lost: everything is on the server).

Build numbers count the commits, both on your computer (`build_android.ps1`)
and on GitHub, so the same commit gets the same number either way. Play
refuses a bundle whose number isn't higher than the last, so upload a bundle
from a newer commit each time.

## 4. Store listing

**App name:** Bua Family

**Short description** (80 characters max)

- English: `Our family tree, news, photos, events and support for each other.`
- Hausa: `Bishiyar iyalinmu, labarai, hotuna, taruka da taimakon juna.`

**Full description, English**

```
Bua Family keeps our family together in one private place, in English and Hausa.

• Family tree: see everyone from the forefathers down. Switch between the whole tree and the family line, one generation at a time, and find how any two relatives are related.
• Members: photos, dates, branches, education, work and skills, and who can help with what.
• Moments and photos: share news and pictures, tag relatives, like and comment.
• Events: weddings, naming ceremonies and meetings, with replies and reminders.
• Birthdays and remembrance: reminders for birthdays and for relatives who have passed, with Islamic dates and Eid greetings.
• Elders' stories: voice recordings of our elders, kept for the next generation.
• Welfare fund: causes, dues and contributions with receipts, clear reports for the committee, and a Pay now button to pay dues or a cause by card or bank transfer.
• Helping each other: blood donors, mentorship and opportunities.
• Polls and announcements for family decisions.

Only family members approved by a family admin can open the app. Health details stay private unless the person shares them. No ads.
```

**Full description, Hausa** (add it under *Manage translations* → Hausa)

```
Bua Family na haɗa iyalinmu wuri ɗaya na sirri, da Turanci da Hausa.

• Bishiyar iyali: ga kowa tun daga kakannin farko. Canza tsakanin bishiyar duka da zuriya, tsara ɗaya bayan ɗaya, kuma ka ga yadda kowane ’yan uwa biyu suke da dangantaka.
• ’Yan uwa: hotuna, ranaku, rassa, karatu, aiki da ƙwarewa, da wanda zai iya taimakawa da me.
• Labarai da hotuna: raba labarai da hotuna, saka sunayen ’yan uwa, so da sharhi.
• Taruka: aure, suna da taro, tare da amsoshi da tunatarwa.
• Ranakun haihuwa da tunawa: tunatarwa kan ranakun haihuwa da ’yan uwan da suka rasu, da kwanakin Musulunci da barka da Sallah.
• Labaran dattawa: naɗar muryar dattawanmu, don zuri’a mai zuwa.
• Asusun taimako: buƙatu, kuɗin wata-wata da gudummawa tare da rasidi, rahotanni ga kwamiti, da kuma biya ta kati ko tura kuɗi a manhaja.
• Taimakon juna: masu ba da jini, jagoranci da damammaki.
• Ƙuri’u da sanarwa don shawarwarin iyali.

Sai ’yan uwa da shugaban iyali ya amince da su ne kawai ke iya buɗe manhajar. Bayanan lafiya sirri ne sai mutum ya raba. Babu talla.
```

**Category:** Social. **Tags:** Family, Social. **Contact email:** the developer email.

**Screenshots** (2–8 phone screenshots, portrait). Take them on a phone with
the app (Power + Volume down) on: Home, Tree (family line), a member's page,
Events, Welfare fund, and one screen in Hausa. They show real family
information, so use screens where that's fine to show the world, or blur names
and faces first.

## 5. App content (Policy → App content)

- **Privacy policy:** https://buafamily.vercel.app/privacy.html
- **App access:** *All or some functionality is restricted.* Reviewers need a
  sign-in. Create an account for them (e.g. email + password), approve it in
  Admin → Accounts, and give those details here, with the note: "New accounts
  need a family admin's approval; this one is approved." Reviewers will see the
  family's information while it's active: remove the account after review if
  you prefer.
- **Ads:** No ads.
- **Content rating:** answer the questionnaire. Category *Social / Communication*.
  Users interact and share content: yes. No violence, gambling and so on.
  Expect *Everyone* / PEGI 3 with "Users Interact".
- **Target audience:** 18 and over (or 13+). Don't include under-13 age groups:
  that brings in the Families policy.
- **News app:** No. **Government app:** No.
- **Financial features:** *Other*. The app no longer only records payments made
  outside it: members may pay dues or contribute to a cause through Korapay, a
  licensed Nigerian payment gateway (card or bank transfer). The money goes into
  the family's own welfare fund, and payouts are made from Korapay's dashboard.
  Paying unlocks no feature or content, so this is a real-world payment and
  **not an in-app purchase** — Google Play Billing must not be used for it, and
  must not be introduced unless that changes. See the declaration text below.
- **Health apps:** No (blood group is just a detail on someone's profile).
- **Data safety:** see below.
- **Account deletion:** *Yes, users can request deletion.* In the app: More →
  Delete my account. Web link: https://buafamily.vercel.app/delete-account.html

### Data safety answers

Does the app collect or share user data? **Yes, collects.** Is it all encrypted
in transit? **Yes.** Can users ask for deletion? **Yes.**
Shared with third parties: **No.** The services the app uses (Supabase, Firebase,
Termii, and Korapay for payments) process data on its behalf, which Play doesn't
count as sharing.

| Data type | Collected | Required? | Why |
|---|---|---|---|
| Personal info → Name | Yes | Required | App functionality, Account management |
| Personal info → Email address | Yes | Optional (phone works too) | Account management |
| Personal info → Phone number | Yes | Optional | Account management, App functionality (SMS) |
| Personal info → User IDs | Yes | Required | Account management |
| Personal info → Other info (dates, places, family relations, education, work) | Yes | Optional | App functionality |
| Health and fitness → Health info (blood group, genotype) | Yes | Optional | App functionality |
| Financial info → Other financial info (dues and cause contributions paid through Korapay: amount, reference, gateway fee) | Yes | Optional | App functionality |
| Messages → Other in-app messages (comments, private messages with photos and voice notes, mentorship) | Yes | Optional | App functionality |
| Photos and videos → Photos | Yes | Optional | App functionality |
| Audio → Voice or sound recordings (elders' stories, voice notes in messages) | Yes | Optional | App functionality |
| App activity → App interactions (pages opened) | Yes | Required | Analytics (admins see who is active) |
| App activity → Other user-generated content | Yes | Optional | App functionality |
| Device or other IDs (notification token) | Yes | Optional | App functionality |

Not collected: location, contacts, calendar, files, web history, crash logs,
advertising ID.

Card and bank details are entered on Korapay's own checkout and never reach the
app's database, so they are not declared.

### Financial features declaration

Tick **Other**, not *Crowdfunding and chit funds*: a chit fund is a licensed
financial product in several jurisdictions, and ticking it invites a licensing
request a private family app can't satisfy. Paste this if Play asks you to
describe it:

```
Private, invitation-only family app. Family members may optionally pay their
monthly welfare dues or contribute to family welfare causes (school fees,
hospital bills, reunions) through a licensed Nigerian payment gateway (Korapay),
by card or bank transfer. Funds are collected into the family's own welfare fund
account; payouts are made by the family committee from the gateway's dashboard.
The app does not lend, does not extend credit, does not sell or trade
investments, cryptocurrencies or other financial products, does not transmit
money between unrelated users, and charges no fee of its own. Paying does not
unlock any app feature or content.
```

This declaration is two steps, and step 2 asks for documentation. Expect a
request for supporting material — that is normal review routing, not a
rejection.

The exemption above depends on paying unlocking nothing. If a contribution ever
gates content or a feature, it becomes an in-app purchase of digital content and
Google Play Billing becomes mandatory.

## 6. Test, then release

1. **Testing → Closed testing** → create a track, add testers (an email list),
   upload the `.aab`, write release notes, roll out. Share the opt-in link in the
   family WhatsApp group.
2. After the 14 days (personal accounts), **Production** → *Apply for production*
   → create a release with the same bundle.
3. Once it's live, copy the app's Play link into **Admin → Settings → Android
   app → Google Play link**. The website's download page then sends people to
   Play, and the website APK can stop being the main way in.

## 7. Updates

Every push to `master` builds a new bundle (Actions → Artifacts). Upload it as a
new release on the track you use. The Play build of the app shows "Update on
Google Play" when an admin publishes a newer build number (Admin → Settings →
Android app → Publish), or Play updates it on its own.
