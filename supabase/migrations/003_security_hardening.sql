-- 003_security_hardening.sql
--
-- READ FIRST: the live project (colahcvziorjkqckqdlt) is SHARED with another
-- app. That app owns public.profiles, the on_auth_user_created trigger and
-- public.handle_new_user(), plus its own tables (bookings, contacts,
-- documents, ...). 001/002 in this folder were the original CNC design and do
-- not match what is live: of them, only qa_logs and get_monthly_usage exist.
--
-- This migration touches CNC Assist objects only:
--   qa_logs                   lock down
--   get_monthly_usage(uuid)   drop
--   cnc_entitlements          new: cached Pro tier + expiry per user
--   cnc_purchases             new: verified Google Play subscriptions
-- It does not touch profiles, the sign-up trigger, or any other app's table.
--
-- Apply with:
--   npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
--     -f supabase/migrations/003_security_hardening.sql
-- NOT with `supabase db push`: the remote migration history belongs to the
-- other app. Safe to run more than once.

-- ── 1. qa_logs: written only by Edge Functions ─────────────────────────────
-- The INSERT policy was WITH CHECK (true) for every role, so anyone holding
-- the public anon key could insert rows for another user_id and use up that
-- user's free AI quota. The Edge Functions now write with the service role.
drop policy if exists "Service role inserts qa_logs" on public.qa_logs;
revoke all on public.qa_logs from anon, authenticated;
grant select on public.qa_logs to authenticated;   -- "Users read own qa_logs" still applies

-- ── 2. get_monthly_usage ───────────────────────────────────────────────────
-- SECURITY DEFINER without a search_path, callable by anyone through the API,
-- and it returned any user's monthly usage count. Nothing uses it.
drop function if exists public.get_monthly_usage(uuid);

-- ── 3. cnc_entitlements ────────────────────────────────────────────────────
-- What the app reads to show Pro. Written only by verify-purchase / play-rtdn
-- from Google's data; Pro needs tier 'pro' AND a future expires_at.
create table if not exists public.cnc_entitlements (
    user_id    uuid primary key references auth.users(id) on delete cascade,
    tier       text not null default 'free' check (tier in ('free', 'pro')),
    expires_at timestamptz,
    updated_at timestamptz not null default now()
);

alter table public.cnc_entitlements enable row level security;
drop policy if exists "Users read own entitlement" on public.cnc_entitlements;
create policy "Users read own entitlement"
    on public.cnc_entitlements for select
    using (auth.uid() = user_id);
revoke all on public.cnc_entitlements from anon, authenticated;
grant select on public.cnc_entitlements to authenticated;

-- ── 4. cnc_purchases ───────────────────────────────────────────────────────
-- Source of truth for Pro. No user access at all.
create table if not exists public.cnc_purchases (
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

create index if not exists idx_cnc_purchases_user
    on public.cnc_purchases(user_id, expires_at desc);

alter table public.cnc_purchases enable row level security;
-- No policies on purpose: only the service role reads or writes purchases.
revoke all on public.cnc_purchases from anon, authenticated;
