#!/usr/bin/env python3
"""Post the day's copy to the Facebook Page and to LinkedIn.

Reads the block the daily generator already produced -- it never writes copy of
its own -- and pushes it to the two platforms that accept plain text through an
API. TikTok and YouTube are deliberately absent: posting there means uploading a
video file, and nothing here can hold a camera.

Credentials come from the environment, never from the repo:
    FB_PAGE_ID, FB_PAGE_TOKEN          Facebook Page
    LINKEDIN_URN, LINKEDIN_TOKEN       LinkedIn (urn:li:person:XXXX)
    POST_LANG                          "en" (default) or "ro"

With no credentials set it runs as a dry run: it prints what it would post and
exits 0, so the workflow is safe to enable before the tokens exist.

Usage:
    python3 tools/post_social.py                 # today
    python3 tools/post_social.py 2026-09-01
    python3 tools/post_social.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DAILY = ROOT / "marketing" / "daily"

FB_API = "https://graph.facebook.com/v21.0"
LI_API = "https://api.linkedin.com/v2/ugcPosts"


def extract(text: str, heading: str) -> str | None:
    """Pull the fenced block that follows '## <heading>'."""
    m = re.search(rf"^## {re.escape(heading)}\s*$\n+```\n(.*?)\n```", text, re.M | re.S)
    return m.group(1).strip() if m else None


def post_facebook(message: str, page_id: str, token: str) -> str:
    data = urllib.parse.urlencode({"message": message, "access_token": token}).encode()
    req = urllib.request.Request(f"{FB_API}/{page_id}/feed", data=data, method="POST")
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read()).get("id", "(no id)")


def post_linkedin(message: str, urn: str, token: str) -> str:
    body = {
        "author": urn,
        "lifecycleState": "PUBLISHED",
        "specificContent": {
            "com.linkedin.ugc.ShareContent": {
                "shareCommentary": {"text": message},
                "shareMediaCategory": "NONE",
            }
        },
        "visibility": {"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"},
    }
    req = urllib.request.Request(
        LI_API,
        data=json.dumps(body).encode(),
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Restli-Protocol-Version": "2.0.0",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.headers.get("x-restli-id") or "(posted)"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("day", nargs="?", help="YYYY-MM-DD (default: today)")
    ap.add_argument("--dry-run", action="store_true", help="print, never post")
    args = ap.parse_args()

    day = date.fromisoformat(args.day) if args.day else date.today()
    path = DAILY / f"{day.isoformat()}.md"
    if not path.exists():
        print(f"!! no content for {day} at {path.relative_to(ROOT)}", file=sys.stderr)
        print("   run: python3 tools/daily_promo.py", file=sys.stderr)
        return 1

    text = path.read_text(encoding="utf-8")
    lang = os.environ.get("POST_LANG", "en").lower()
    fb_heading = "Facebook — English" if lang == "en" else "Facebook — Română"
    li_heading = "LinkedIn — English" if lang == "en" else "LinkedIn — Română"

    fb_msg = extract(text, fb_heading)
    li_msg = extract(text, li_heading)

    fb_id, fb_token = os.environ.get("FB_PAGE_ID"), os.environ.get("FB_PAGE_TOKEN")
    li_urn, li_token = os.environ.get("LINKEDIN_URN"), os.environ.get("LINKEDIN_TOKEN")

    failures = 0

    for name, msg, creds, fn in (
        ("Facebook", fb_msg, (fb_id, fb_token), post_facebook),
        ("LinkedIn", li_msg, (li_urn, li_token), post_linkedin),
    ):
        print(f"\n=== {name} ({lang}) ===")
        if not msg:
            print(f"!! no block found for that platform in {path.name} — skipped")
            failures += 1
            continue
        if args.dry_run or not all(creds):
            why = "--dry-run" if args.dry_run else "credentials not set"
            print(f"[{why}] would post {len(msg)} chars:\n")
            print(msg[:600] + ("…" if len(msg) > 600 else ""))
            continue
        try:
            print(f"posted: {fn(msg, *creds)}")
        except urllib.error.HTTPError as e:
            # The body carries the real reason (expired token, missing scope).
            print(f"!! HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:400]}", file=sys.stderr)
            failures += 1
        except Exception as e:                                   # noqa: BLE001
            print(f"!! {type(e).__name__}: {e}", file=sys.stderr)
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
