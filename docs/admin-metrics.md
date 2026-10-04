# Admin metrics

How the family uses the app, for admins: who is active, what gets shared,
how the tree grows, and whether help reaches people. Open it from
**Admin → 📈**, **More → Family metrics**, or the sidebar.

## What it answers

- Are people using the app, and on which platform (Android app or web)?
- Is the tree growing, and is it complete enough (photos, birth dates, accounts)?
- What do people share and react to?
- Do blood requests get offers? Does money come into the welfare fund?
- Do notifications and SMS reach people?
- Which branch of the family, and which members, are most involved?

## The dashboard

| Part | What it shows |
|---|---|
| **Filters** (one row, top) | Period: 7 / 30 / 90 / 365 days or any custom range. Step: daily, weekly, monthly (picked for you from the period, changeable). Platform: all / Android / web. Branch: all / one branch of the family. |
| **Right now** | Accounts step by step (signed up → approved → in the tree → active in 30 days → notifications on → Android app), the tree's completeness, fund balance, open blood requests, suggestions waiting. Not affected by the filters. |
| **Tiles** | One per chosen metric: total for the period, change against the period before, a small trend. Tap a tile to chart it. **Choose metrics** (⚙) picks the tiles; kept on this device. |
| **Chart** | The selected metric over the period. Bars for counts, a line for "members" metrics. Switch on **Compare** for a dashed line of the period before (same length, same step). **Table** shows the same numbers as rows. |
| **Split by** | The selected metric for the period, by member, branch or platform (top 20). |
| **Export** (⬇) | CSV of every tile metric, one row per step, for spreadsheets. |

Dates are counted in Lagos time (Africa/Lagos). The end date is included.

## Metric catalogue

"Counts" add up events. "Members" count distinct people in each step
(and in the whole period for the total, so a weekly total isn't the sum of
its days). "Money" sums amounts in naira.

| Group | Metric | Kind | Counted from |
|---|---|---|---|
| People | Active members | members | days a signed-in member opened the app (`activity_days`) |
| | Active on Android / on the web | members | same, by platform |
| | Sign-ups | count | new accounts (`profiles.created_at`) |
| Tree | People added | count | `persons.created_at`; branch = the person's branch |
| | Relationships added | count | parent–child links + marriages |
| | Suggestions sent / reviewed | count | `change_requests` created / reviewed |
| Sharing | Moments, announcements | count | `posts` by kind |
| | Members who posted | members | distinct post authors |
| | Photos, comments, likes | count | `photos`, `comments`, `likes` |
| | Elders' stories, memories | count | `stories`, `memories` |
| Events | Events, RSVPs | count | `events`, `event_rsvps` (last answer) |
| | Polls, votes | count | `polls`, `poll_votes` |
| Helping | Blood requests, offers | count | `blood_requests`, `blood_offers` |
| | Contributions | count | `fund_contributions` |
| | Money confirmed in | money | confirmed contributions, on the day confirmed |
| | Money paid out | money | `fund_payouts` |
| | Causes, mentorship asks, opportunities | count | `fund_causes`, `mentor_asks`, `opportunities` |
| Reach | Notifications sent | count | `notifications` |
| | Notifications pushed | count | notifications delivered by push (`pushed_at`) |
| | SMS sent | count | `private.sms_outbox` sent |

"Who" for each event is the member who did it, and "branch" is the
branch of the person that member is linked to in the tree.

## How it's built

All in the database, admin-only (`security definer` with an admin check):

- `private.metric_events(from, to)` — one `union all` of every event as
  *(metric, at, user, amount, platform, branch)*.
- `private.metric_rows(...)` — adds the member's branch and applies the
  platform and branch filters.
- `admin_metrics(metrics[], from, to, bucket, platform, branch)` — series per
  step, totals, and the period before. Ranges up to 10 years.
- `admin_metric_breakdown(metric, from, to, by, platform, branch)` — top 20 by
  member, branch or platform.
- `admin_snapshot()` — the "Right now" numbers.

The app: `models/metrics.dart` (catalogue, query, results),
`ui/screens/metrics_screen.dart`, `ui/widgets/charts.dart`
(trend chart, sparkline, bars — one green for data, gray for the period
before, values on hover/tap).

### Adding a metric

1. Add one `union all select '<key>', <time>, <user>, <amount>, <platform>, <branch> from …`
   line to `private.metric_events` (new migration, `create or replace`).
   If it counts members or sums money, add it to `private.metric_kind`.
2. Add `MetricDef('<key>', MetricGroup.<group>)` to `metricCatalog`.
3. Add `m_<key>` to `app_en.arb` and `app_ha.arb`, and to `MetricLabels.metric`.

The dashboard, tiles, chart, split and CSV pick it up with no other change.

## Next (phase 2)

- **Saved views** — name a set of tiles + filters ("Fund", "Tree growth") and share it with other admins (stored in the database, not just on one device).
- **Weekly digest** — a Monday notification to admins: active members, new people, money in, anything unusual, against the week before.
- **Alerts** — thresholds that notify admins: a blood request with no offer after 2 hours, no one active for 7 days, suggestions waiting over 3 days, fund balance below a level.
- **Retention** — of members who joined in a month, how many are still active 1, 2 and 3 months later (cohort table).
- **Targets** — set a goal per metric ("every living person has a photo by Ramadan") and show progress on the tile.
- **Custom metric builder** — pick a table, a filter and count/sum/distinct from the app, without a migration (limited to a safe list of tables and columns).
- **Engagement per member** — a score from activity, posts and help given, on the Users page.
