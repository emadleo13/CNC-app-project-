-- 003_security_hardening.sql
--
-- Closes the ways an app user could grant themselves Pro or tamper with AI
-- usage, and adds the purchases table that Google Play verification writes.
--
-- Deploy the Edge Functions from the same commit BEFORE applying this: the
-- previous functions wrote qa_logs with the caller's own token, which this
-- migration forbids.

-- ── 1. profiles: read your own row, change only your preferences ───────────
-- "FOR ALL USING (auth.uid() = id)" let a user UPDATE every column of their
-- row, including subscription_tier, with the public anon key.
drop policy if exists "Users manage own profile" on public.profiles;
drop policy if exists "Users read own profile" on public.profiles;
drop policy if exists "Users update own preferences" on public.profiles;

create policy "Users read own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users update own preferences"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- RLS picks the rows; column privileges pick what can change in them.
-- Profiles are created by the handle_new_user trigger and deleted by the
-- delete-account function, so app users need neither INSERT nor DELETE.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, preferred_dialect, preferred_units, language, updated_at)
    on public.profiles to authenticated;

-- ── 2. qa_logs: written only by Edge Functions ─────────────────────────────
-- The old INSERT policy was WITH CHECK (true) for every role, so anyone could
-- insert rows for another user_id and use up that user's free quota.
drop policy if exists "Service role inserts qa_logs" on public.qa_logs;
revoke all on public.qa_logs from anon, authenticated;
grant select on public.qa_logs to authenticated;   -- "Users read own qa_logs" still applies

-- ── 3. purchases: verified Google Play subscriptions ───────────────────────
-- Source of truth for Pro. Filled only by verify-purchase and play-rtdn from
-- Google's own data; profiles.subscription_* is a cache derived from it.
create table if not exists public.purchases (
    purchase_token        text primary key,
    user_id               uuid not null references auth.users(id) on delete cascade,
    product_id            text not null,
    state                 text not null,
    expires_at            timestamptz,
    linked_purchase_token text,
    is_test               boolean not null default false,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now()
);

create index if not exists idx_purchases_user
    on public.purchases(user_id, expires_at desc);

alter table public.purchases enable row level security;
-- No policies on purpose: only the service role reads or writes purchases.
revoke all on public.purchases from anon, authenticated;

-- ── 4. Entitlements granted outside verification ───────────────────────────
-- The old verify-purchase never checked with Google and gave at most 31 days,
-- so a Pro row without an expiry, or expiring more than 32 days out, did not
-- come from it. Those rows are reset. Rows inside the window keep Pro until
-- their date. Their holders get it back for good when the app re-verifies
-- their Play purchase: automatically on start from 1.1.7, or with Restore.
update public.profiles
   set subscription_tier = 'free',
       subscription_expires_at = null,
       updated_at = now()
 where subscription_tier <> 'free'
   and (subscription_expires_at is null
        or subscription_expires_at > now() + interval '32 days');

-- ── 5. SECURITY DEFINER functions ──────────────────────────────────────────
-- Pin search_path so the definer's privileges cannot be redirected through
-- objects someone else creates in a schema on the path.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles (id, email)
    values (new.id, coalesce(new.email, ''))
    on conflict (id) do nothing;
    return new;
end;
$$;

-- Unused by the app, and callable by anyone through the API: it returned any
-- user's monthly usage count.
drop function if exists public.get_monthly_usage(uuid);
