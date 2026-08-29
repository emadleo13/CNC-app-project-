#!/usr/bin/env python3
"""Print one language's Play Console fields, ready to copy.

  python3 tools/listing.py            # list the languages
  python3 tools/listing.py en         # English fields
  python3 tools/listing.py ro fa ar   # several at once
"""
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "docs" / "store-listing.md"
CODES = {"en": "English", "ro": "Romanian", "fa": "Persian", "ar": "Arabic"}
LIMITS = {"Title": 30, "Short description": 80, "Full description": 4000}


def sections(text):
    parts = re.split(r"^## ", text, flags=re.M)[1:]
    return {p.split("\n", 1)[0].strip(): p for p in parts}


def main():
    text = SRC.read_text(encoding="utf-8")
    secs = sections(text)
    wanted = [a.lower() for a in sys.argv[1:]]
    if not wanted:
        print("Languages available:")
        for c, n in CODES.items():
            print(f"  {c}  {n}")
        print("\nUsage: python3 tools/listing.py en")
        return

    for code in wanted:
        name = CODES.get(code)
        if not name:
            print(f"!! unknown language '{code}' (try: {', '.join(CODES)})")
            continue
        key = next((k for k in secs if name.lower() in k.lower()), None)
        if not key:
            print(f"!! no section for {name}")
            continue
        body = secs[key]
        print("=" * 72)
        print(f"  {name}  —  paste into Play Console")
        print("=" * 72)
        for field, limit in LIMITS.items():
            m = re.search(rf"\*\*{field}\*\*[^\n]*\n```\n(.*?)\n```", body, re.S)
            if not m:
                continue
            val = m.group(1)
            flag = "OK" if len(val) <= limit else "OVER LIMIT"
            print(f"\n--- {field}  ({len(val)}/{limit} {flag}) ---")
            print(val)
        print()


if __name__ == "__main__":
    main()
