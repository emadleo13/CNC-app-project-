# Deploying the backend

Verified Play purchases, locked-down usage data and server-side AI quota.

Project ref: `colahcvziorjkqckqdlt`. Package name: `com.cncassist.cnc_assist`.

## Read this first: the project is shared

The live Supabase project also serves **another app** (bookings, contacts,
documents, …). That app owns `public.profiles`, the `on_auth_user_created`
trigger and `public.handle_new_user()`. CNC Assist must never change them.

CNC Assist's own objects are `qa_logs` and the `cnc_*` tables
(`cnc_entitlements`, `cnc_purchases`, created by migration 003).
`001_initial_schema.sql` and `002_usage_tracking.sql` are the original design.
They do not match what is live and must not be applied.

- **Never run `supabase db push` from this repo.** The remote migration
  history belongs to the other app. Apply CNC migrations with
  `supabase db query -f` (step 4).
- `supabase/tests/live_baseline.sql` is a snapshot of the relevant live
  objects of both apps. `supabase/tests/rls_test.mjs` applies it plus 003 and
  checks that the CNC holes are closed and the other app still works.

## Order

1. Read-only checks (step 1)
2. Deploy the functions (step 3)
3. Run the migration (step 4)
4. Verify (step 5)

Steps 2 and 6 (Google Play service account, notifications) can happen before
or after. Until the service account is set, `verify-purchase` refuses every
purchase (503). That is safe: the app keeps the purchase unacknowledged and
re-verifies on every start, and Google refunds it after three days if it is
never confirmed. The function it replaces reported success without granting
anything.

App versions up to 1.1.6 keep working against the new functions. They read Pro
from a column that does not exist, so they always see free, as before.

All commands below assume the CLI is logged in (`npx supabase login`, with the
account that owns the project).

---

## 1. Look at production first (read-only)

```bash
npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
  "select tablename, policyname, cmd, qual, with_check from pg_policies where schemaname = 'public' order by 1, 2;"
npx supabase functions list --project-ref colahcvziorjkqckqdlt
npx supabase secrets list   --project-ref colahcvziorjkqckqdlt   # names only
```

## 2. Google Play service account (one time; can take a day to apply)

1. **Google Cloud Console**: enable **Google Play Android Developer API** in
   any project you own.
2. *IAM & Admin → Service Accounts → Create service account* (e.g.
   `play-verify`; it needs no Cloud roles). Then *Keys → Add key → JSON*.
   Treat the file as a password. Never commit it and never paste it into a
   chat.
3. **Play Console → Users and permissions → Invite new users**: enter the
   service account's email. Under *App permissions → CNC Assist*, grant
   **View financial data, orders, and cancellation survey responses** and
   **Manage orders and subscriptions**.
4. Check the access on your own computer:

   ```bash
   npx deno run --allow-read --allow-env --allow-net \
     supabase/scripts/check_play_access.ts ~/Downloads/<key>.json
   ```

   `✓ Access works`: continue. `✗ … lacks permission`: the invitation has not
   applied yet; it can take up to 24 hours.
5. Store the key as a secret, without printing it:

   ```bash
   npx supabase secrets set --project-ref colahcvziorjkqckqdlt \
     GOOGLE_PLAY_SERVICE_ACCOUNT_KEY="$(cat ~/Downloads/<key>.json)"
   ```

## 3. Deploy the Edge Functions

```bash
npx supabase functions deploy --use-api --project-ref colahcvziorjkqckqdlt
```

`--use-api` bundles on Supabase's side, so Docker is not needed. This deploys
all eight functions. `play-rtdn` gets JWT verification turned off from
`supabase/config.toml` (Pub/Sub cannot send a Supabase JWT). Until
`PLAY_RTDN_SECRET` is set it rejects every request.

The new functions treat a missing `cnc_*` table as "not Pro", so the minutes
before step 4 cause no errors.

## 4. Apply the migration

```bash
npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
  -f supabase/migrations/003_security_hardening.sql
```

It touches only CNC objects (qa_logs, get_monthly_usage, the cnc_* tables) and
can be run again safely.

## 5. Verify

```bash
npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
  "select tablename, policyname, cmd from pg_policies where tablename in ('qa_logs','cnc_entitlements','cnc_purchases','profiles') order by 1, 2;"
```

- Expected for `qa_logs`: only `Users read own qa_logs`.
- Expected for `cnc_entitlements`: `Users read own entitlement`.
- Expected for `cnc_purchases`: none.
- `profiles` must be unchanged (`profiles self insert/read/update`).

Then, once step 2 is done, make a purchase as a **license tester** (Play
Console → *Settings → License testing*) and check:

```bash
npx supabase db query --linked --project-ref colahcvziorjkqckqdlt \
  "select user_id, state, expires_at, is_test from public.cnc_purchases;
   select user_id, tier, expires_at from public.cnc_entitlements where tier = 'pro';"
```

Test subscriptions renew every few minutes, so `expires_at` moving on later AI
calls exercises the renewal check. Logs: Dashboard → *Edge Functions →
verify-purchase → Logs*.

## 6. Real-time developer notifications (recommended)

1. Cloud Console → *Pub/Sub → Topics → Create topic*: `play-rtdn`.
2. Topic → *Permissions → Add principal*
   `google-play-developer-notifications@system.gserviceaccount.com`, role
   **Pub/Sub Publisher**.
3. Generate a secret and store it:
   `npx supabase secrets set --project-ref colahcvziorjkqckqdlt PLAY_RTDN_SECRET="$(openssl rand -hex 32)"`.
   Note the value; the next step needs it.
4. *Create subscription* on the topic. Delivery type **Push**, endpoint
   `https://colahcvziorjkqckqdlt.supabase.co/functions/v1/play-rtdn?secret=<PLAY_RTDN_SECRET>`.
5. Play Console → *Monetize with Play → Monetization setup → Real-time
   developer notifications*. Set the topic to
   `projects/<cloud-project-id>/topics/play-rtdn` → *Send test notification*.
   The play-rtdn logs should show `test notification received`.

## Rolling back

- Functions: `git checkout <previous-commit> -- supabase/functions`, then
  deploy again. The previous `verify-purchase` reports success without granting
  anything, so prefer fixing forward.
- Migration: the cnc_* tables can be dropped
  (`drop table public.cnc_purchases, public.cnc_entitlements;`). Do not
  re-create the qa_logs INSERT policy.

## Tests

```bash
# Edge Function logic: entitlement states, JWT signing, Play API flow, isPro
npx deno test --allow-env supabase/functions/tests/

# Live baseline + 003 on a real Postgres (PGlite), both apps checked
cd supabase/tests && npm install && npm test
node rls_test.mjs --before   # shows the holes in the baseline (expected to fail)
```
