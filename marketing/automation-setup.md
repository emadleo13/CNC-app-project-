# Auto-posting setup — Facebook Page and LinkedIn

Two platforms out of four can be automated. This explains why, and exactly what to do.

## What is automated and what is not

| Platform | Automated | Why |
|---|---|---|
| Facebook **Page** | yes | Graph API accepts plain text |
| Facebook **groups** | **no** | Meta shut down the Groups API in 2024. Groups are where your readers actually are, so this stays manual — and that is fine: a person answering a question is welcome in a group, a Page broadcasting is not. |
| LinkedIn | yes | UGC Posts API accepts plain text |
| TikTok | **no** | Posting means uploading a *video*. Nothing here can hold a camera. |
| YouTube | **no** | Same. The generator writes the title, description and script; you record. |

## How the pieces fit

```
08:00  Claude routine  →  generates + rewrites  →  commits marketing/daily/<today>.md
08:15  GitHub Action   →  reads that file       →  posts to FB Page + LinkedIn
```

The Action is plain Python on GitHub's free runners. **Tokens live in GitHub repository
secrets** — never in the repo, never in a model prompt, never in a chat message. That is the
reason the posting step is a GitHub Action and not part of the Claude routine.

Until the secrets exist, the workflow is a safe dry run: it prints what it would post and exits 0.

---

## 1. Facebook Page token

1. https://developers.facebook.com → **My Apps** → **Create App** → type **Business**.
2. In the app, add the **Facebook Login** product (you never build a login screen; it just
   unlocks the token tools).
3. Open the **Graph API Explorer**: https://developers.facebook.com/tools/explorer
4. Top right: pick your app, then **User Token**, and add these permissions:
   `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`
5. **Generate Access Token** → approve → you now hold a *short-lived user* token.
6. Get the Page token and its id:
   ```
   GET /me/accounts
   ```
   Run that in the Explorer. Find the entry whose `name` is **CNC Assist**. Copy its
   `id` (that is `FB_PAGE_ID`) and its `access_token`.
7. Make it long-lived. Page tokens derived from a long-lived user token do not expire, so first
   exchange the user token:
   ```
   https://graph.facebook.com/v21.0/oauth/access_token
     ?grant_type=fb_exchange_token
     &client_id=<APP_ID>
     &client_secret=<APP_SECRET>
     &fb_exchange_token=<SHORT_LIVED_USER_TOKEN>
   ```
   Then repeat step 6 with the long-lived user token. The Page token you get back is the one to
   store as `FB_PAGE_TOKEN`.
8. Check it at https://developers.facebook.com/tools/debug/accesstoken — it should say
   **Expires: Never** and list `pages_manage_posts`.

**App Review is not needed** to post to a Page you administer yourself. You only need review to
post on behalf of *other people's* Pages.

## 2. LinkedIn token

1. https://developer.linkedin.com/ → **Create app**. It must be attached to a LinkedIn *Page*;
   if you do not have a company Page, create a minimal one — it is only the app's owner.
2. **Products** tab → request **Share on LinkedIn** and **Sign In with LinkedIn using OpenID
   Connect**. Approval is usually automatic but can take a day.
3. **Auth** tab → add a redirect URL. `http://localhost:8080/callback` is fine.
4. Get a token with scopes `openid profile w_member_social`. The Auth tab has a token generator;
   use it rather than building an OAuth flow.
5. Find your member id:
   ```
   curl -H "Authorization: Bearer <TOKEN>" https://api.linkedin.com/v2/userinfo
   ```
   Take the `sub` field. `LINKEDIN_URN` is `urn:li:person:<sub>`.

⚠️ LinkedIn access tokens expire after **60 days** and there is no non-expiring equivalent. Put a
calendar reminder to regenerate. If posts stop appearing, this is the first thing to check — the
workflow log will show `HTTP 401`.

## 3. Store the secrets

GitHub → your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository
secret**, once per value:

| Secret | Value |
|---|---|
| `FB_PAGE_ID` | the Page's numeric id from `/me/accounts` |
| `FB_PAGE_TOKEN` | the long-lived Page token |
| `LINKEDIN_URN` | `urn:li:person:XXXXXXXX` |
| `LINKEDIN_TOKEN` | the LinkedIn access token |

Optional, under the **Variables** tab rather than Secrets:

| Variable | Value |
|---|---|
| `POST_LANG` | `en` (default) or `ro` |

English reaches further and the Page is new; Romanian copy is better spent in Romanian groups,
posted by hand.

## 4. Test before trusting it

1. Repo → **Actions** → **Daily social post** → **Run workflow** → leave *dry run* ticked.
   It should print both blocks and pass.
2. Run it again with *dry run* unticked. Check the Page and your LinkedIn feed.
3. If it fails, the log prints the API's own error body — usually an expired token or a missing
   scope, both of which name themselves.

After that it runs by itself at 08:15 Europe/Bucharest.

⚠️ GitHub cron is UTC and ignores daylight saving, so from late October the job runs at 07:15
local until the clocks change back. Harmless, but do not be surprised.

## Revoking

Delete the secret in GitHub and the token stops being used immediately. To kill it at the source:
Facebook → Page → Settings → Business Integrations; LinkedIn → Settings → Data privacy →
Permitted services.
