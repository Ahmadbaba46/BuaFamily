-- =============================================================================
-- Admin metrics (see docs/admin-metrics.md)
--
-- Every countable thing in the app is described once, in
-- private.metric_events(): which metric, when, by whom, an amount, the
-- platform and the family branch. The functions below slice that one source
-- however the dashboard asks: any metrics, any date range, by day / week /
-- month, compared with the period before, filtered by platform or branch,
-- and broken down by branch, platform or member.
--
-- Adding a metric = one more "union all" below and one entry in the app's
-- metric catalogue. Admins only; members' individual amounts never leave
-- the committee (admins are on it).
-- =============================================================================

-- Fix: an account not linked to anyone in the tree got an empty name (the
-- person's name of "no person" is '', not null), e.g. in "… commented".
create or replace function private.member_name(p_user uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce(nullif(private.person_name(p), ''), nullif(a.display_name, ''), a.email)
  from public.profiles a left join public.persons p on p.id = a.person_id
  where a.id = p_user;
$$;

-- How a metric adds up: count rows, count distinct members, or sum amounts.
create function private.metric_kind(p_metric text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_metric in ('active_members', 'active_android', 'active_web', 'posting_members') then 'distinct'
    when p_metric in ('money_in', 'money_out') then 'sum'
    else 'count'
  end;
$$;

create function private.metric_events(p_from timestamptz, p_to timestamptz)
returns table (metric text, at timestamptz, user_id uuid, amount numeric, platform text, branch text)
language sql stable security definer set search_path = '' as $$
  -- People and accounts
  select 'signups', p.created_at, p.id, null::numeric, null::text, null::text
    from public.profiles p where p.created_at >= p_from and p.created_at < p_to
  union all
  -- Activity days are Nigerian calendar days; place them at that day's start.
  select case a.platform when 'android' then 'active_android' when 'web' then 'active_web' else 'active_other' end,
         a.day::timestamp at time zone 'Africa/Lagos', a.user_id, null, a.platform, null
    from public.activity_days a
    where a.day >= (p_from at time zone 'Africa/Lagos')::date and a.day < (p_to at time zone 'Africa/Lagos')::date
  union all
  select 'active_members', a.day::timestamp at time zone 'Africa/Lagos', a.user_id, null, a.platform, null
    from public.activity_days a
    where a.day >= (p_from at time zone 'Africa/Lagos')::date and a.day < (p_to at time zone 'Africa/Lagos')::date
  -- The tree
  union all
  select 'people_added', x.created_at, x.created_by, null, null, x.branch
    from public.persons x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'relationships_added', x.created_at, x.created_by, null, null, null
    from public.parent_child x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'relationships_added', x.created_at, x.created_by, null, null, null
    from public.unions x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'suggestions', x.created_at, x.requested_by, null, null, null
    from public.change_requests x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'suggestions_reviewed', x.reviewed_at, x.reviewed_by, null, null, null
    from public.change_requests x where x.reviewed_at >= p_from and x.reviewed_at < p_to
  -- Sharing
  union all
  select case when x.kind::text = 'announcement' then 'announcements' else 'moments' end,
         x.created_at, x.author_id, null, null, null
    from public.posts x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'posting_members', x.created_at, x.author_id, null, null, null
    from public.posts x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'photos', x.created_at, x.uploaded_by, null, null, null
    from public.photos x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'comments', x.created_at, x.author_id, null, null, null
    from public.comments x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'likes', x.created_at, x.user_id, null, null, null
    from public.likes x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'stories', x.created_at, x.added_by, null, null, null
    from public.stories x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'memories', x.created_at, x.author_id, null, null, null
    from public.memories x where x.created_at >= p_from and x.created_at < p_to
  -- Events and polls
  union all
  select 'events', x.created_at, x.created_by, null, null, null
    from public.events x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'rsvps', x.updated_at, x.user_id, null, null, null
    from public.event_rsvps x where x.updated_at >= p_from and x.updated_at < p_to
  union all
  select 'polls', x.created_at, x.created_by, null, null, null
    from public.polls x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'votes', x.updated_at, x.user_id, null, null, null
    from public.poll_votes x where x.updated_at >= p_from and x.updated_at < p_to
  -- Helping each other
  union all
  select 'blood_requests', x.created_at, x.requested_by, null, null, null
    from public.blood_requests x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'blood_offers', x.created_at, x.user_id, null, null, null
    from public.blood_offers x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'contributions', x.created_at, x.user_id, null, null, null
    from public.fund_contributions x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'money_in', coalesce(x.reviewed_at, x.created_at), x.user_id, x.amount, null, null
    from public.fund_contributions x
    where x.status::text = 'confirmed' and coalesce(x.reviewed_at, x.created_at) >= p_from
      and coalesce(x.reviewed_at, x.created_at) < p_to
  union all
  select 'money_out', x.created_at, x.recorded_by, x.amount, null, null
    from public.fund_payouts x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'causes', x.created_at, x.created_by, null, null, null
    from public.fund_causes x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'mentor_asks', x.created_at, null, null, null, null
    from public.mentor_asks x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'opportunities', x.created_at, x.posted_by, null, null, null
    from public.opportunities x where x.created_at >= p_from and x.created_at < p_to
  -- Reaching people
  union all
  select 'notifications', x.created_at, x.user_id, null, null, null
    from public.notifications x where x.created_at >= p_from and x.created_at < p_to
  union all
  select 'notifications_received', x.pushed_at, x.user_id, null, null, null
    from public.notifications x where x.pushed_at >= p_from and x.pushed_at < p_to
  union all
  select 'sms_sent', x.sent_at, x.user_id, null, null, null
    from private.sms_outbox x where x.status = 'sent' and x.sent_at >= p_from and x.sent_at < p_to;
$$;

-- The events, with each member's branch (from the person their account is
-- linked to) when the event itself has none, after the optional filters.
create function private.metric_rows(p_from timestamptz, p_to timestamptz, p_platform text, p_branch text)
returns table (metric text, at timestamptz, user_id uuid, amount numeric, platform text, branch text)
language sql stable security definer set search_path = '' as $$
  select e.metric, e.at, e.user_id, e.amount, e.platform, coalesce(e.branch, nullif(trim(pp.branch), '')) as branch
  from private.metric_events(p_from, p_to) e
  left join public.profiles pr on pr.id = e.user_id
  left join public.persons pp on pp.id = pr.person_id
  where (p_platform is null or e.platform is null or e.platform = p_platform)
    and (p_branch is null or coalesce(e.branch, nullif(trim(pp.branch), '')) = p_branch);
$$;

-- Admin: series and totals for any metrics.
--   p_bucket: 'day' | 'week' | 'month'. Dates are days in Nigerian time;
--   p_to is inclusive. "previous" is the same length of time just before.
create function public.admin_metrics(
  p_metrics text[], p_from date, p_to date, p_bucket text default 'day',
  p_platform text default null, p_branch text default null
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  bucket text := case when p_bucket in ('day', 'week', 'month') then p_bucket else 'day' end;
  tz text := 'Africa/Lagos';
  t0 timestamptz := (p_from::timestamp at time zone tz);
  t1 timestamptz := ((p_to + 1)::timestamp at time zone tz);
  span interval := t1 - t0;
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Only admins can see metrics' using errcode = '42501';
  end if;
  if p_to < p_from or p_to - p_from > 3660 then
    raise exception 'Choose a period of up to ten years' using errcode = '22023';
  end if;

  with rows as (
    select * from private.metric_rows(t0 - span, t1, p_platform, p_branch) where metric = any (p_metrics)
  ),
  buckets as (
    select generate_series(date_trunc(bucket, p_from::timestamp), p_to::timestamp, ('1 ' || bucket)::interval)::date as b
  ),
  per_bucket as (
    select r.metric, date_trunc(bucket, r.at at time zone tz)::date as b,
           case private.metric_kind(r.metric)
             when 'distinct' then count(distinct r.user_id)::numeric
             when 'sum' then coalesce(sum(r.amount), 0)
             else count(*)::numeric end as v
    from rows r where r.at >= t0
    group by 1, 2
  ),
  totals as (
    select m as metric,
           (select case private.metric_kind(m)
                     when 'distinct' then count(distinct r.user_id)::numeric
                     when 'sum' then coalesce(sum(r.amount), 0)
                     else count(*)::numeric end
            from rows r where r.metric = m and r.at >= t0) as now_v,
           (select case private.metric_kind(m)
                     when 'distinct' then count(distinct r.user_id)::numeric
                     when 'sum' then coalesce(sum(r.amount), 0)
                     else count(*)::numeric end
            from rows r where r.metric = m and r.at < t0) as before_v
    from unnest(p_metrics) m
  )
  select jsonb_build_object(
    'buckets', (select jsonb_agg(b order by b) from buckets),
    'series', (select jsonb_object_agg(t.metric, (
                 select jsonb_agg(coalesce(pb.v, 0) order by bk.b)
                 from buckets bk left join per_bucket pb on pb.metric = t.metric and pb.b = bk.b))
               from totals t),
    'totals', (select jsonb_object_agg(metric, now_v) from totals),
    'previous', (select jsonb_object_agg(metric, before_v) from totals)
  ) into result;
  return result;
end $$;

-- Admin: one metric split by 'branch', 'platform' or 'member' (top 20).
create function public.admin_metric_breakdown(
  p_metric text, p_from date, p_to date, p_by text,
  p_platform text default null, p_branch text default null
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  tz text := 'Africa/Lagos';
  t0 timestamptz := (p_from::timestamp at time zone tz);
  t1 timestamptz := ((p_to + 1)::timestamp at time zone tz);
begin
  if not public.is_admin() then
    raise exception 'Only admins can see metrics' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('key', k, 'label', label, 'value', v) order by v desc, label)
    from (
      select k, label, v from (
        select case p_by when 'branch' then coalesce(r.branch, '')
                         when 'platform' then coalesce(r.platform, '')
                         else coalesce(r.user_id::text, '') end as k,
               case p_by when 'member' then coalesce(private.member_name(r.user_id), '')
                         when 'branch' then coalesce(r.branch, '')
                         else coalesce(r.platform, '') end as label,
               case private.metric_kind(p_metric)
                 when 'distinct' then count(distinct r.user_id)::numeric
                 when 'sum' then coalesce(sum(r.amount), 0)
                 else count(*)::numeric end as v
        from private.metric_rows(t0, t1, p_platform, p_branch) r
        where r.metric = p_metric
        group by 1, 2
      ) g
      order by v desc
      limit 20
    ) s
  ), '[]'::jsonb);
end $$;

-- Admin: where the family stands today (not over a period).
create function public.admin_snapshot() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see metrics' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'accounts', (select count(*) from public.profiles),
    'approved', (select count(*) from public.profiles where status = 'active'),
    'waiting', (select count(*) from public.profiles where status = 'pending'),
    'linked', (select count(*) from public.profiles where status = 'active' and person_id is not null),
    'active_7d', (select count(distinct user_id) from public.activity_days
                  where day > (now() at time zone 'Africa/Lagos')::date - 7),
    'active_30d', (select count(distinct user_id) from public.activity_days
                   where day > (now() at time zone 'Africa/Lagos')::date - 30),
    'push_on', (select count(distinct t.user_id) from public.push_tokens t
                join public.profiles p on p.id = t.user_id and p.status = 'active'),
    'android_app', (select count(distinct t.user_id) from public.push_tokens t where t.platform = 'android'),
    'people', (select count(*) from public.persons),
    'living', (select count(*) from public.persons where is_living),
    'with_photo', (select count(*) from public.persons where photo_path is not null),
    'with_birth_date', (select count(*) from public.persons where birth_date is not null),
    'with_account', (select count(*) from public.profiles where person_id is not null),
    'branches', coalesce((select jsonb_agg(b order by b) from
                  (select distinct nullif(trim(branch), '') b from public.persons) x where b is not null), '[]'::jsonb),
    'fund_balance', (select coalesce(sum(amount), 0) from public.fund_contributions where status::text = 'confirmed')
                    - (select coalesce(sum(amount), 0) from public.fund_payouts),
    'open_blood_requests', (select count(*) from public.blood_requests where status::text = 'open'),
    'pending_suggestions', (select count(*) from public.change_requests where status = 'pending')
  );
end $$;

revoke execute on function private.metric_kind(text) from public, anon, authenticated;
revoke execute on function private.metric_events(timestamptz, timestamptz) from public, anon, authenticated;
revoke execute on function private.metric_rows(timestamptz, timestamptz, text, text) from public, anon, authenticated;
revoke execute on function public.admin_metrics(text[], date, date, text, text, text) from public, anon;
revoke execute on function public.admin_metric_breakdown(text, date, date, text, text, text) from public, anon;
revoke execute on function public.admin_snapshot() from public, anon;
