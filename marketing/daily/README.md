# Daily promo content

One file per day, named `YYYY-MM-DD.md`. Each contains ready-to-post copy for four platforms:

| Platform | Languages | Notes |
|---|---|---|
| Facebook | English + Romanian | Post inside groups as yourself, not as the Page |
| TikTok | script only | You record; the file gives the hook, the beats and the caption |
| LinkedIn | English + Romanian | Longer register, no hashtag wall |
| YouTube | title + description + tags | The title is exact-match for search — paste it unchanged |

Every block sits inside a fenced code block, so GitHub shows a **one-tap copy button** next to it on
mobile. Open the day's file, tap copy, paste.

## How a day gets here

```
08:00 Europe/Bucharest   Claude routine
                           ├─ python3 tools/daily_promo.py   (picks the topic, writes the draft)
                           ├─ rewrites the prose so it does not read like a template
                           ├─ commits and pushes
                           └─ sends a mobile push notification
```

The topic rotates on a 7-day cycle — alarm, code, speeds & feeds, alarm, trap, code, quiz — drawn
from the app's own 273 alarms and 252 G/M-codes, so a full pass takes months.

Routine: https://claude.ai/code/routines/trig_018PbN6LaRJCp68jrgQjug5o

## Getting it on your phone

**Email (most reliable).** Watch this repo — GitHub then emails you on every push, and the daily
commit is what triggers it. Repo → **Watch** → **Custom** → **Pushes**. Check that email delivery is
on at https://github.com/settings/notifications.

**Bookmark.** The URL is predictable, so a bookmark to this folder works with no setup at all:
`https://github.com/emadleo13/CNC-app-project-/tree/main/marketing/daily`

**Claude mobile app.** The routine also fires a push notification, which only arrives if the Claude
app is installed and signed in to the same account. Treat it as a bonus, not the delivery path.

## Editing a day by hand

Just edit the file. The generator **skips** any day that already exists, so your edit will not be
overwritten — and the routine reads the file before touching it and leaves polished copy alone.
Use `python3 tools/daily_promo.py <DATE> --force` only when you deliberately want the raw draft back.

## Generating more days ahead

```bash
python3 tools/daily_promo.py --days 30      # fills in the next 30 days, skipping any that exist
```
