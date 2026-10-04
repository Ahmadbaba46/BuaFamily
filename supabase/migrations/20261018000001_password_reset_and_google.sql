-- =============================================================================
-- Forgot your password? Get a code by SMS (through Termii, like every other
-- text) and choose a new one. Works without Supabase's phone provider.
--
-- The phone must be the one on the member's profile. Codes are 6 digits,
-- valid 10 minutes, 5 tries; at most 3 codes per number per hour.
-- =============================================================================

create table private.password_resets (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users on delete cascade,
  phone       text not null,
  code_hash   text not null,
  attempts    smallint not null default 0,
  expires_at  timestamptz not null default now() + interval '10 minutes',
  used_at     timestamptz,
  created_at  timestamptz not null default now()
);
create index password_resets_phone_idx on private.password_resets (phone, created_at desc);

-- Always answers the same way whether or not the number belongs to someone,
-- so it can't be used to find out who is a member.
create function public.request_password_reset_sms(p_phone text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_phone text := private.normalize_phone(p_phone);
  s public.app_settings;
  who record;
  code text;
begin
  select * into s from public.app_settings;
  if not coalesce(s.sms_enabled, false) or s.sms_sender_id is null then
    return jsonb_build_object('ok', false, 'reason', 'sms_off');
  end if;
  if v_phone is null then
    return jsonb_build_object('ok', false, 'reason', 'bad_phone');
  end if;
  if (select count(*) from private.password_resets r
      where r.phone = v_phone and r.created_at > now() - interval '1 hour') >= 3
     or exists (select 1 from private.password_resets r
                where r.phone = v_phone and r.created_at > now() - interval '60 seconds') then
    return jsonb_build_object('ok', false, 'reason', 'too_many');
  end if;

  select p.id, p.locale into who
  from public.profiles p join auth.users u on u.id = p.id
  where p.phone = v_phone and p.status in ('active', 'pending') and u.email is not null
  order by p.status = 'active' desc, p.created_at
  limit 1;
  if who.id is null then
    return jsonb_build_object('ok', true);
  end if;

  code := lpad(((('x' || encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint) % 1000000)::text, 6, '0');
  insert into private.password_resets (user_id, phone, code_hash)
  values (who.id, v_phone, extensions.crypt(code, extensions.gen_salt('bf')));
  insert into private.sms_outbox (user_id, phone, message)
  values (who.id, v_phone, case when who.locale = 'ha'
    then 'Lambar sabunta kalmar sirri ta ' || s.family_name || ' Family: ' || code || '. Kada ka ba kowa.'
    else s.family_name || ' Family password reset code: ' || code || '. Do not share it.' end);
  perform private.flush_sms(10);
  return jsonb_build_object('ok', true);
end $$;

-- Checks the code and sets the new password. Returns the account's email so
-- the app can sign straight in.
create function public.reset_password_with_sms(p_phone text, p_code text, p_password text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_phone text := private.normalize_phone(p_phone);
  r private.password_resets;
  v_email text;
begin
  if length(coalesce(p_password, '')) < 8 then
    return jsonb_build_object('ok', false, 'reason', 'weak_password');
  end if;
  select * into r from private.password_resets x
  where x.phone = v_phone and x.used_at is null and x.expires_at > now()
  order by x.created_at desc limit 1
  for update;
  if r.id is null or r.attempts >= 5 then
    return jsonb_build_object('ok', false, 'reason', 'expired');
  end if;
  if r.code_hash <> extensions.crypt(btrim(coalesce(p_code, '')), r.code_hash) then
    update private.password_resets set attempts = attempts + 1 where id = r.id;
    return jsonb_build_object('ok', false, 'reason', case when r.attempts + 1 >= 5 then 'expired' else 'wrong_code' end);
  end if;

  update private.password_resets set used_at = now() where id = r.id;
  update auth.users
     set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')), updated_at = now()
   where id = r.user_id
  returning auth.users.email into v_email;
  return jsonb_build_object('ok', true, 'email', v_email);
end $$;

revoke execute on function public.request_password_reset_sms(text) from public;
revoke execute on function public.reset_password_with_sms(text, text, text) from public;
grant execute on function public.request_password_reset_sms(text) to anon, authenticated;
grant execute on function public.reset_password_with_sms(text, text, text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- Google sign-in: use the name Google gives ("full_name" / "name").
-- -----------------------------------------------------------------------------
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
             nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
             nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
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
