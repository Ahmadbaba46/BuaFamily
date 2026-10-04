-- =============================================================================
-- Sign in with a phone number, and invite links
--
-- Phone sign-in: Supabase Auth sends a one-time code by SMS through the
-- "Send SMS" auth hook below, which uses the family's Termii account (the
-- same one as SMS notifications). Turn it on once in the Supabase dashboard:
--   Authentication → Sign In / Providers → Phone: enable
--   Authentication → Hooks → Send SMS → Postgres → public.send_sms_hook
--
-- Invites: an admin creates a link (optionally for a person in the tree) and
-- shares it, e.g. on WhatsApp. Whoever signs up through it is approved at
-- once and linked to that person.
-- =============================================================================

-- New accounts made with a phone number have no email: use the number.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  first_user boolean;
begin
  perform pg_advisory_xact_lock(hashtext('buafamily_first_admin'));
  select not exists (select 1 from public.profiles where role = 'admin') into first_user;

  insert into public.profiles (id, display_name, email, phone, role, status, locale)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
             nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
             '+' || nullif(regexp_replace(coalesce(new.phone, ''), '\D', '', 'g'), ''),
             ''),
    new.email,
    nullif(new.phone, ''),
    case when first_user then 'admin'::public.app_role else 'member'::public.app_role end,
    case when first_user then 'active'::public.account_status else 'pending'::public.account_status end,
    case when new.raw_user_meta_data ->> 'locale' = 'ha' then 'ha' else 'en' end
  );
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Send SMS auth hook: the sign-in code goes out through Termii.
-- -----------------------------------------------------------------------------
create function public.send_sms_hook(event jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  phone text := regexp_replace(coalesce(event #>> '{user,phone}', ''), '\D', '', 'g');
  otp text := event #>> '{sms,otp}';
  hausa boolean := coalesce(event #>> '{user,user_metadata,locale}', '') = 'ha';
  s public.app_settings;
begin
  select * into s from public.app_settings;
  if not coalesce(s.sms_enabled, false) or s.sms_sender_id is null then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 503, 'message', 'Text messages are not set up yet. Sign in with your email instead.'));
  end if;
  if phone = '' or otp is null then
    return jsonb_build_object('error', jsonb_build_object('http_code', 400, 'message', 'A phone number is needed.'));
  end if;

  insert into private.sms_outbox (phone, message)
  values (phone, case when hausa
    then 'Lambar shiga ' || s.family_name || ' Family: ' || otp || '. Kada ka ba kowa.'
    else 'Your ' || s.family_name || ' Family sign-in code is ' || otp || '. Do not share it.' end);
  -- Send now rather than at the next minute's run.
  perform private.flush_sms(10);
  return '{}'::jsonb;
end $$;
revoke execute on function public.send_sms_hook(jsonb) from public, anon, authenticated;
grant execute on function public.send_sms_hook(jsonb) to supabase_auth_admin;

-- -----------------------------------------------------------------------------
-- Invites
-- -----------------------------------------------------------------------------
create table public.invites (
  code        text primary key default lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  person_id   uuid references public.persons on delete set null,
  note        text,
  created_by  uuid default auth.uid() references auth.users on delete set null,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default now() + interval '30 days',
  used_by     uuid references auth.users on delete set null,
  used_at     timestamptz
);
alter table public.invites enable row level security;
create policy invites_admin on public.invites for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- What the invite page shows before signing in.
create function public.invite_info(p_code text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'valid', i.used_at is null and i.expires_at > now(),
    'person', (select private.person_name(p) from public.persons p where p.id = i.person_id),
    'invited_by', private.member_name(i.created_by),
    'family', (select family_name from public.app_settings)
  )
  from public.invites i where i.code = lower(trim(p_code));
$$;
grant execute on function public.invite_info(text) to anon, authenticated;

-- The signed-in user accepts an invite: approved, and linked to the person
-- if the invite names one that no other account has.
create function public.redeem_invite(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  i public.invites;
  me public.profiles;
  link uuid;
begin
  select * into i from public.invites where code = lower(trim(p_code)) for update;
  if not found then
    raise exception 'This invite link is not valid' using errcode = 'P0002';
  end if;
  select * into me from public.profiles where id = auth.uid();
  if not found then
    raise exception 'Sign in first' using errcode = '42501';
  end if;
  if i.used_by = me.id then
    return jsonb_build_object('status', me.status);
  end if;
  if i.used_at is not null or i.expires_at <= now() then
    raise exception 'This invite link has already been used or has expired' using errcode = '55000';
  end if;
  if me.status = 'suspended' then
    raise exception 'This account is suspended' using errcode = '42501';
  end if;

  link := case when me.person_id is null and i.person_id is not null
                    and not exists (select 1 from public.profiles where person_id = i.person_id)
               then i.person_id end;
  update public.profiles
     set status = 'active',
         person_id = coalesce(link, person_id),
         requested_person_id = case when link is not null then null else requested_person_id end
   where id = me.id;
  update public.invites set used_by = me.id, used_at = now() where code = i.code;
  return jsonb_build_object('status', 'active', 'person_id', link);
end $$;
revoke execute on function public.redeem_invite(text) from public, anon;
grant execute on function public.redeem_invite(text) to authenticated;
