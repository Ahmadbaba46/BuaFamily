-- =============================================================================
-- Push notifications (Firebase Cloud Messaging)
--
-- Every in-app notification also goes to the phones and browsers where the
-- member turned on notifications. Muted kinds are never created, so they are
-- never pushed either.
--
--   * push_tokens: one row per device; members manage their own.
--   * After notifications are inserted, one request per statement goes to the
--     'push' Edge Function with the new notification ids (pg_net, after commit).
--   * The Edge Function reads what to send through push_payloads() and the
--     Firebase credentials through push_config(), both only for service_role.
--   * An admin pastes the Firebase service account in the app
--     (admin_set_push); it is kept in Vault.
-- =============================================================================

alter type public.notification_kind add value if not exists 'test';

alter table public.app_settings add column push_enabled boolean not null default false;

create table public.push_tokens (
  token         text primary key check (length(token) between 20 and 4096),
  user_id       uuid not null default auth.uid() references auth.users on delete cascade,
  platform      text not null check (platform in ('android', 'ios', 'web')),
  created_at    timestamptz not null default now(),
  last_seen_at  timestamptz not null default now()
);
create index push_tokens_user_idx on public.push_tokens (user_id);

alter table public.push_tokens enable row level security;
create policy push_tokens_select on public.push_tokens for select to authenticated
  using (user_id = (select auth.uid()));
create policy push_tokens_delete on public.push_tokens for delete to authenticated
  using (user_id = (select auth.uid()));

-- A device moves to whoever signs in on it last.
create function public.register_push_token(p_token text, p_platform text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_active_member() then
    raise exception 'Only active members get notifications' using errcode = '42501';
  end if;
  insert into public.push_tokens (token, user_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, last_seen_at = now();
end $$;

-- -----------------------------------------------------------------------------
-- Setup (admins)
-- -----------------------------------------------------------------------------
create table private.push_stats (
  id               boolean primary key default true check (id),
  last_sent_at     timestamptz,
  sent_7d_start    timestamptz not null default now(),
  sent_7d          int not null default 0,
  last_error       text,
  last_error_at    timestamptz
);
insert into private.push_stats default values;

create function private.vault_put(p_name text, p_value text, p_description text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  existing uuid := (select id from vault.secrets where name = p_name);
begin
  if existing is null then
    perform vault.create_secret(p_value, p_name, p_description);
  else
    perform vault.update_secret(existing, p_value);
  end if;
end $$;

create function private.vault_get(p_name text) returns text
language sql stable security definer set search_path = '' as $$
  select decrypted_secret from vault.decrypted_secrets where name = p_name;
$$;

-- p_service_account: the JSON key file from Firebase (Project settings →
-- Service accounts → Generate new private key). p_function_url: where the
-- 'push' Edge Function lives, e.g. https://<ref>.supabase.co/functions/v1/push.
create function public.admin_set_push(p_service_account text default null, p_function_url text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  sa jsonb;
begin
  if not public.is_admin() then
    raise exception 'Only admins can set up notifications' using errcode = '42501';
  end if;
  if nullif(btrim(p_service_account), '') is not null then
    begin
      sa := p_service_account::jsonb;
    exception when others then
      raise exception 'That is not a Firebase service account file' using errcode = '22023';
    end;
    if sa ->> 'type' is distinct from 'service_account' or sa ->> 'project_id' is null
       or sa ->> 'client_email' is null or sa ->> 'private_key' is null then
      raise exception 'That is not a Firebase service account file' using errcode = '22023';
    end if;
    perform private.vault_put('fcm_service_account', sa::text, 'Firebase service account for push notifications');
  end if;
  if nullif(btrim(p_function_url), '') is not null then
    if btrim(p_function_url) !~ '^https://' then
      raise exception 'The function address must start with https://' using errcode = '22023';
    end if;
    perform private.vault_put('push_function_url', btrim(p_function_url), 'Address of the push Edge Function');
  end if;
  if private.vault_get('push_webhook_secret') is null then
    perform private.vault_put('push_webhook_secret', replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
                              'Shared secret between the database and the push Edge Function');
  end if;
  update public.app_settings set push_enabled = true
  where private.vault_get('fcm_service_account') is not null and private.vault_get('push_function_url') is not null;
end $$;

create function public.push_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  s private.push_stats := (select x from private.push_stats x);
begin
  if not public.is_admin() then
    raise exception 'Only admins can see this' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'enabled', (select push_enabled from public.app_settings),
    'project_id', private.vault_get('fcm_service_account')::jsonb ->> 'project_id',
    'function_url', private.vault_get('push_function_url'),
    'devices', (select count(*) from public.push_tokens),
    'members', (select count(distinct user_id) from public.push_tokens),
    'sent_7d', case when s.sent_7d_start > now() - interval '7 days' then s.sent_7d else 0 end,
    'last_sent_at', s.last_sent_at,
    'last_error', s.last_error,
    'last_error_at', s.last_error_at
  );
end $$;

-- Sends the admin a test notification (on every device they turned on).
create function public.send_test_push() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can send a test' using errcode = '42501';
  end if;
  insert into public.notifications (user_id, kind, data, link)
  values (auth.uid(), 'test', '{}', '/notifications');
end $$;

-- -----------------------------------------------------------------------------
-- Hand new notifications to the Edge Function
-- -----------------------------------------------------------------------------
create function private.push_new_notifications() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  ids  uuid[];
  url  text;
begin
  if not coalesce((select push_enabled from public.app_settings), false) then
    return null;
  end if;
  select array_agg(n.id) into ids
  from added n
  where exists (select 1 from public.push_tokens t where t.user_id = n.user_id);
  url := private.vault_get('push_function_url');
  if ids is null or url is null then
    return null;
  end if;
  perform net.http_post(
    url := url,
    body := jsonb_build_object('ids', to_jsonb(ids)),
    headers := jsonb_build_object('Content-Type', 'application/json',
                                  'x-push-secret', private.vault_get('push_webhook_secret')),
    timeout_milliseconds := 10000
  );
  return null;
end $$;
create trigger notifications_push after insert on public.notifications
  referencing new table as added
  for each statement execute function private.push_new_notifications();

-- -----------------------------------------------------------------------------
-- For the Edge Function only (service_role)
-- -----------------------------------------------------------------------------
create function public.push_config() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'secret', private.vault_get('push_webhook_secret'),
    'service_account', private.vault_get('fcm_service_account')::jsonb,
    'family_name', (select family_name from public.app_settings)
  );
$$;

-- What to send: each notification with the reader's language and devices.
create function public.push_payloads(p_ids uuid[])
returns table (id uuid, kind text, data jsonb, link text, locale text, tokens jsonb)
language sql stable security definer set search_path = '' as $$
  select n.id, n.kind::text, n.data, n.link, coalesce(p.locale, 'en'),
         jsonb_agg(jsonb_build_object('token', t.token, 'platform', t.platform))
  from public.notifications n
  join public.profiles p on p.id = n.user_id and p.status = 'active'
  join public.push_tokens t on t.user_id = n.user_id
  where n.id = any (p_ids) and n.read_at is null
  group by n.id, p.locale;
$$;

-- The Edge Function reports what happened, for the admin status card.
create function public.push_report(p_sent int, p_error text default null) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update private.push_stats set
    sent_7d       = case when sent_7d_start > now() - interval '7 days' then sent_7d + p_sent else p_sent end,
    sent_7d_start = case when sent_7d_start > now() - interval '7 days' then sent_7d_start else now() end,
    last_sent_at  = case when p_sent > 0 then now() else last_sent_at end,
    last_error    = coalesce(left(p_error, 500), last_error),
    last_error_at = case when p_error is not null then now() else last_error_at end;
end $$;

revoke execute on function private.vault_put(text, text, text) from public, anon, authenticated;
revoke execute on function private.vault_get(text) from public, anon, authenticated;
revoke execute on function private.push_new_notifications() from public, anon, authenticated;
revoke execute on function public.register_push_token(text, text) from public, anon;
revoke execute on function public.admin_set_push(text, text) from public, anon;
revoke execute on function public.push_status() from public, anon;
revoke execute on function public.send_test_push() from public, anon;
revoke execute on function public.push_config() from public, anon, authenticated;
revoke execute on function public.push_payloads(uuid[]) from public, anon, authenticated;
revoke execute on function public.push_report(int, text) from public, anon, authenticated;
grant execute on function public.push_config() to service_role;
grant execute on function public.push_payloads(uuid[]) to service_role;
grant execute on function public.push_report(int, text) to service_role;
