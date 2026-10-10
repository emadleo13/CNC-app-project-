-- 004_device_quota.sql
--
-- The free AI quota was counted per anonymous account only. Reinstalling the
-- app (or "Delete account") creates a new anonymous account, so every
-- reinstall gave ten more free questions. Each usage row now also carries a
-- SHA-256 hash of the device's app-scoped Android ID (computed by the Edge
-- Functions; the raw ID is never stored), and the quota counts the account's
-- rows OR the device's rows.
--
-- Touches qa_logs only (CNC Assist). The table-level grants from 003 still
-- apply: app users read their own rows and write nothing.
--
-- Apply BEFORE deploying the functions that write device_hash:
--   npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
--     -f supabase/migrations/004_device_quota.sql
-- Safe to run more than once.

alter table public.qa_logs add column if not exists device_hash text;

create index if not exists idx_qa_logs_device_month
    on public.qa_logs(device_hash, created_at desc)
    where device_hash is not null;
