-- =============================================================================
-- Search everything from one box. Runs with the caller's own rights, so row
-- level security decides what each member can find (private conversations,
-- proposed causes, contributions… never show up for others).
-- People are searched in the app, from the tree it already has.
-- Hausa letters match their plain forms: "dan" finds "ɗan", "kasa" "ƙasa".
-- =============================================================================

create function public.search_fold(p text) returns text
language sql immutable parallel safe set search_path = '' as $$
  select lower(translate(coalesce(p, ''), 'ƁɓƊɗƘƙƳƴ’ʼ''', 'BbDdKkYy'));
$$;

-- ~140 characters of [p] around the first match of [q].
create function public.search_snippet(p text, q text) returns text
language sql immutable parallel safe set search_path = '' as $$
  select case
    when p is null then null
    when strpos(public.search_fold(p), public.search_fold(q)) > 60
      then '…' || btrim(substr(p, strpos(public.search_fold(p), public.search_fold(q)) - 40, 140))
           || case when length(p) > strpos(public.search_fold(p), public.search_fold(q)) + 100 then '…' else '' end
    else btrim(left(p, 140)) || case when length(p) > 140 then '…' else '' end
  end;
$$;

create function public.search_all(p_query text, p_limit int default 8)
returns table (kind text, id text, title text, snippet text, at timestamptz, link text)
language plpgsql stable security invoker set search_path = '' as $$
declare
  q text := btrim(coalesce(p_query, ''));
  pat text;
  n int := least(greatest(coalesce(p_limit, 8), 1), 30);
begin
  if length(q) < 2 or not public.is_active_member() then
    return;
  end if;
  pat := '%' || replace(replace(replace(public.search_fold(q), '\', '\\'), '%', '\%'), '_', '\_') || '%';

  return query
  (select 'post', x.id::text, null::text, public.search_snippet(x.body, q), x.created_at, '/posts/' || x.id
     from public.posts x where public.search_fold(x.body) like pat
     order by x.created_at desc limit n)
  union all
  (select 'event', x.id::text, x.title, public.search_snippet(coalesce(x.details, x.place), q), x.starts_at, '/events/' || x.id
     from public.events x
     where public.search_fold(x.title || ' ' || coalesce(x.details, '') || ' ' || coalesce(x.place, '') || ' '
                              || coalesce(x.address, '')) like pat
     order by x.starts_at desc limit n)
  union all
  (select 'album', x.id::text, x.title, public.search_snippet(x.description, q), x.created_at, '/albums/' || x.id
     from public.albums x where public.search_fold(x.title || ' ' || coalesce(x.description, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'photo', x.id::text, null, public.search_snippet(x.caption, q), x.created_at,
          '/photo/' || x.id || coalesce('?album=' || x.album_id, '?post=' || x.post_id, '')
     from public.photos x where public.search_fold(x.caption) like pat
     order by x.created_at desc limit n)
  union all
  (select 'story', x.id::text, x.title,
          public.search_snippet(coalesce(nullif(x.transcript, ''), x.speaker_name, x.source_note), q), x.created_at, '/stories'
     from public.stories x
     where public.search_fold(x.title || ' ' || coalesce(x.speaker_name, '') || ' ' || coalesce(x.transcript, '') || ' '
                              || coalesce(x.source_note, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'cause', x.id::text, x.title, public.search_snippet(x.description, q), x.created_at, '/fund/cause/' || x.id
     from public.fund_causes x where public.search_fold(x.title || ' ' || coalesce(x.description, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'poll', x.id::text, x.question, public.search_snippet(x.context, q), x.created_at, '/polls'
     from public.polls x where public.search_fold(x.question || ' ' || coalesce(x.context, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'opportunity', x.id::text, x.title, public.search_snippet(x.details, q), x.created_at, '/mentors?tab=opportunities'
     from public.opportunities x where public.search_fold(x.title || ' ' || coalesce(x.details, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'memory', x.id::text, null, public.search_snippet(x.body, q), x.created_at, '/person/' || x.person_id || '/memorial'
     from public.memories x where public.search_fold(x.body) like pat
     order by x.created_at desc limit n)
  union all
  (select 'skill', x.person_id::text, x.skill, public.search_snippet(x.notes, q), x.created_at, '/person/' || x.person_id
     from public.person_skills x where public.search_fold(x.skill || ' ' || coalesce(x.notes, '')) like pat
     order by x.created_at desc limit n)
  union all
  (select 'work', x.person_id::text, x.title,
          concat_ws(' · ', x.organization, x.industry, x.location), x.created_at, '/person/' || x.person_id
     from public.person_occupations x
     where public.search_fold(x.title || ' ' || coalesce(x.organization, '') || ' ' || coalesce(x.industry, '') || ' '
                              || coalesce(x.location, '')) like pat
     order by x.created_at desc limit n);
end $$;

revoke execute on function public.search_all(text, int) from public, anon;
grant execute on function public.search_fold(text) to authenticated;
grant execute on function public.search_snippet(text, text) to authenticated;
