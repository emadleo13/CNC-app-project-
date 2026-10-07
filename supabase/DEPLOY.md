# Deploying the backend

Verified Play purchases, locked-down RLS and server-side AI quota
(commit "Verify Play purchases with Google and lock down Pro and usage data").

Project ref: `colahcvziorjkqckqdlt`. Package name: `com.cncassist.cnc_assist`.

**Order matters.** Do the steps top to bottom. In particular:

- The service account must work (step 2) before the functions are deployed
  (step 4). The new `verify-purchase` refuses to grant Pro without it.
- The functions are deployed (step 4) before the migration runs (step 5).
  The old functions wrote usage rows with the user's own token, which the
  migration forbids.

App versions up to 1.1.6 keep working against the new backend. The request
formats are unchanged, and the error bodies still carry `quota_exceeded` and
`pro_required`.

---

## 1. Look at production first (read-only)

SQL Editor → run:

```sql
-- How many Pro rows exist, and how many have no expiry (cannot come from a real purchase)
select subscription_tier, subscription_expires_at is null as no_expiry,
       subscription_expires_at > now() + interval '32 days' as too_far, count(*)
from public.profiles group by 1, 2, 3 order by 1, 2, 3;

-- Current policies on the two tables this release changes
select tablename, policyname, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename in ('profiles', 'qa_logs');
```

Rows with `no_expiry` or `too_far` will be reset to free by the migration.

## 2. Google Play service account (one time)

1. **Google Cloud Console** (console.cloud.google.com). Pick a project; the
   Firebase project for this app is fine.
2. *APIs & Services → Library*: enable **Google Play Android Developer API**.
3. *IAM & Admin → Service Accounts → Create service account*, e.g.
   `play-verify`. It needs no Cloud roles.
4. Open it → *Keys → Add key → Create new key → JSON*. Treat the downloaded
   file as a password. Never commit it and never paste it into a chat.
5. **Play Console → Users and permissions → Invite new users**:
   - Email: the service account's address (`…@….iam.gserviceaccount.com`)
   - *App permissions → Add app → CNC Assist*, with:
     - View app information (read-only)
     - **View financial data, orders, and cancellation survey responses**
     - **Manage orders and subscriptions**
   - Invite. (If Play Console shows a *Setup → API access* page asking you to
     link a Cloud project, link the one from step 1.)
6. Check that the access works, on your own computer:

   ```bash
   npx deno run --allow-read --allow-env --allow-net \
     supabase/scripts/check_play_access.ts ~/Downloads/<key>.json
   ```

   `✓ Access works` means continue. `✗ … lacks permission` means the
   invitation has not applied yet; it can take up to 24 hours. Saving any edit
   to an in-app product in Play Console sometimes makes it apply sooner.

## 3. Secrets

Dashboard → *Edge Functions → Secrets* (or `npx supabase secrets set …`):

| Secret | Value |
|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` | The entire content of the JSON key file |
| `PLAY_RTDN_SECRET` | A long random string, e.g. `openssl rand -hex 32` (only needed for step 7) |
| `PLAY_PACKAGE_NAME` | Optional; defaults to `com.cncassist.cnc_assist` |

`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` and the AI keys already exist.

## 4. Deploy the Edge Functions

The functions share code in `_shared/`, so deploy with the CLI:

```bash
npx supabase login                  # opens the browser once
npx supabase functions deploy --project-ref colahcvziorjkqckqdlt
```

This deploys all eight functions. `play-rtdn` gets JWT verification turned off
from `supabase/config.toml`, because Pub/Sub cannot send a Supabase JWT.

## 5. Apply the migration

SQL Editor → paste all of `supabase/migrations/003_security_hardening.sql` →
*Run*. It can be run again safely.

(Avoid `supabase db push` unless 001 and 002 are recorded in the remote
migration history. If they were applied by hand, `db push` would try to re-run
them. Use `npx supabase migration repair --status applied 001 002` first.)

## 6. Verify

- Re-run the policies query from step 1. Expected for `profiles`:
  `Users read own profile` (SELECT) and `Users update own preferences`
  (UPDATE). Expected for `qa_logs`: only `Users read own qa_logs`.
- Make a purchase as a **license tester** (Play Console → *Settings → License
  testing*). Then:

  ```sql
  select purchase_token, user_id, state, expires_at, is_test from public.purchases;
  select id, subscription_tier, subscription_expires_at from public.profiles
  where subscription_tier <> 'free';
  ```

  Test subscriptions renew every few minutes. Watching `expires_at` move on
  later AI calls exercises the renewal check too.
- Logs: Dashboard → *Edge Functions → verify-purchase → Logs*.
- Cancel the test subscription in the Play Store. After it ends, the next AI
  call should treat the user as free.

## 7. Real-time developer notifications (recommended)

Without these, an expiry is noticed at the cached expiry date and a refund at
the next re-check. With them, both take effect immediately.

1. Cloud Console → *Pub/Sub → Topics → Create topic*: `play-rtdn`.
2. Topic → *Permissions → Add principal*
   `google-play-developer-notifications@system.gserviceaccount.com`, role
   **Pub/Sub Publisher**.
3. *Create subscription* on the topic. Delivery type: **Push**. Endpoint:
   `https://colahcvziorjkqckqdlt.supabase.co/functions/v1/play-rtdn?secret=<PLAY_RTDN_SECRET>`.
4. Play Console → *Monetize with Play → Monetization setup → Real-time
   developer notifications*. Set the topic to
   `projects/<cloud-project-id>/topics/play-rtdn` → *Send test notification*.
   The play-rtdn logs should show `test notification received`.

## Rolling back

- Functions: `git checkout <previous-commit> -- supabase/functions` and deploy
  again. Rolling back `verify-purchase` reopens free Pro, so prefer fixing
  forward.
- Migration: if a legitimate client write is now denied (`permission denied
  for table profiles`), add that column to the `grant update (…)` list. Do not
  restore the old `FOR ALL` policy.

## Tests

```bash
# Edge Function logic: entitlement states, JWT signing, Play API flow
npx deno test --allow-env supabase/functions/tests/

# Every migration on a real Postgres (PGlite), with each attack tried as a user
cd supabase/tests && npm install && npm test
```
