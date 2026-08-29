#!/usr/bin/env python3
"""Generate one day's ready-to-post promo content for Facebook and TikTok.

Draws from the app's own data — 273 controller alarms and 252 G/M-codes — and
rotates through a 7-day angle cycle so the feed never looks repetitive. The pick
is deterministic from the date, so the same day always yields the same topic and
a full cycle takes months to repeat.

Output: marketing/daily/YYYY-MM-DD.md  (Romanian + English, FB + TikTok)

Usage:
  python3 tools/daily_promo.py              # today
  python3 tools/daily_promo.py 2026-09-01   # a specific day
  python3 tools/daily_promo.py --days 7     # today plus the next 6
"""
from __future__ import annotations

import argparse
import json
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data"
OUT = ROOT / "marketing" / "daily"

SITE = "https://emadleo13.github.io/CNC-app-project-"
PLAY = ("https://play.google.com/store/apps/details?id=com.cncassist.cnc_assist"
        "&utm_source=social&utm_medium={medium}&utm_campaign=daily")

BRANDS = [("haas", "haas_alarms", "Haas"),
          ("fanuc", "fanuc_alarms", "Fanuc"),
          ("sinumerik", "sinumerik_alarms", "Sinumerik"),
          ("heidenhain", "heidenhain_alarms", "Heidenhain"),
          ("mazak", "mazak_alarms", "Mazak")]

HASHTAGS_EN = "#cnc #machinist #cncmachining #gcode #haascnc #fanuc #machineshop #manufacturing #toolmaker"
HASHTAGS_RO = "#cnc #strunjire #frezare #prelucrarecnc #gcode #atelier #scule #productie #romania"


def load():
    a = json.loads((DATA / "errors.json").read_text(encoding="utf-8"))
    g = json.loads((DATA / "gcode_reference.json").read_text(encoding="utf-8"))
    return a, g


def slug(v: str) -> str:
    import re
    return re.sub(r"[^a-zA-Z0-9]+", "-", str(v)).strip("-").lower()


def pick(seq, n):
    """Deterministic rotation through seq."""
    return seq[n % len(seq)] if seq else None


def alarm_block(alarms, day_index, brand_offset=0):
    bslug, key, bname = BRANDS[(day_index + brand_offset) % len(BRANDS)]
    items = alarms.get(key) or []
    a = pick(items, day_index // len(BRANDS) + brand_offset * 7)
    url = f"{SITE}/alarms/{bslug}/{slug(a['code'])}.html"
    return bname, a, url


def code_block(codes, day_index):
    groups = [("g_codes", "g-codes"), ("m_codes", "m-codes"),
              ("sinumerik_cycles", "sinumerik-cycles"), ("fanuc_codes", "fanuc-codes")]
    key, gslug = groups[day_index % len(groups)]
    items = codes.get(key) or []
    c = pick(items, day_index // len(groups))
    url = f"{SITE}/gcode/{gslug}/{slug(c['code'])}.html"
    return c, url


def build(day: date, alarms, codes) -> str:
    n = (day - date(2026, 1, 1)).days
    angle = n % 7
    play_fb = PLAY.format(medium="facebook")
    play_tt = PLAY.format(medium="tiktok")
    out = [f"# Promo — {day.isoformat()}", ""]

    if angle in (0, 3):                      # Mon & Thu — alarm of the day
        bname, a, url = alarm_block(alarms, n, brand_offset=(0 if angle == 0 else 2))
        code, title = a["code"], a["title"]
        causes = a.get("possible_causes") or []
        fixes = a.get("solutions") or []
        top_fix = fixes[0] if fixes else "Check the machine documentation."
        out += [
            f"**Angle:** Alarm of the day — {bname} {code}", "",
            "## Facebook — English", "",
            "```",
            f"{bname} alarm {code} — {title}",
            "",
            f"{a.get('description','')}",
            "",
            "Most common causes:",
            *[f"• {c}" for c in causes[:3]],
            "",
            f"First thing to try: {top_fix}",
            "",
            f"Full write-up (free, no signup): {url}",
            f"All {bname} alarms offline in the app: {play_fb}",
            "",
            HASHTAGS_EN,
            "```", "",
            "## Facebook — Română", "",
            "```",
            f"Alarma {bname} {code} — {title}",
            "",
            "Cauze frecvente:",
            *[f"• {c}" for c in causes[:3]],
            "",
            f"Primul lucru de verificat: {top_fix}",
            "",
            "(Textul alarmei rămâne în engleză — așa apare și pe comandă.)",
            "",
            f"Explicația completă, gratuit: {url}",
            f"Toate alarmele {bname}, offline în aplicație: {play_fb}",
            "",
            HASHTAGS_RO,
            "```", "",
            "## TikTok — script 25s", "",
            "```",
            f"HOOK (0-3s, text mare pe ecran): \"{bname.upper()} ALARM {code}\"",
            "  Voce/text: \"Machine down. Here's what it actually means.\"",
            "",
            f"BEAT 2 (3-10s): arată textul alarmei — \"{title}\"",
            f"  \"{a.get('description','')[:110]}\"",
            "",
            "BEAT 3 (10-20s): 3 cauze, una pe rând, text mare:",
            *[f"  {i+1}. {c}" for i, c in enumerate(causes[:3])],
            "",
            f"BEAT 4 (20-25s): \"Fix: {top_fix[:80]}\"",
            "  CTA pe ecran: \"Free app — link in bio\"",
            "",
            f"Caption: {bname} alarm {code}? Here's the 30-second version. Free app, no ads. {play_tt}",
            f"Hashtags: {HASHTAGS_EN}",
            "```",
        ]

    elif angle in (1, 5):                    # Tue & Sat — code of the day
        c, url = code_block(codes, n if angle == 1 else n + 3)
        warn = c.get("warning")
        out += [
            f"**Angle:** Code of the day — {c['code']}", "",
            "## Facebook — English", "",
            "```",
            f"{c['code']} — {c.get('name','')}",
            "",
            f"{c.get('description','')}",
            "",
            *( [f"Syntax:  {c['syntax']}", ""] if c.get("syntax") else [] ),
            *( [f"⚠ {warn}", ""] if warn else [] ),
            f"Full reference: {url}",
            f"Whole G/M-code library offline: {play_fb}",
            "",
            HASHTAGS_EN,
            "```", "",
            "## Facebook — Română", "",
            "```",
            f"{c['code']} — {c.get('name','')}",
            "",
            f"{c.get('description','')}",
            "",
            *( [f"Sintaxă:  {c['syntax']}", ""] if c.get("syntax") else [] ),
            *( [f"⚠ Atenție: {warn}", ""] if warn else [] ),
            f"Referința completă: {url}",
            f"Toată biblioteca de coduri, offline: {play_fb}",
            "",
            HASHTAGS_RO,
            "```", "",
            "## TikTok — script 20s", "",
            "```",
            f"HOOK (0-3s): text uriaș \"{c['code']}\" + \"do you actually know this one?\"",
            f"BEAT 2 (3-10s): \"{c.get('name','')}\" — {c.get('description','')[:100]}",
            *( [f"BEAT 3 (10-16s): arată sintaxa pe ecran: {c.get('syntax','')}"] if c.get("syntax") else [] ),
            *( [f"BEAT 4 (16-20s): \"The trap: {warn[:80]}\""] if warn else
               ["BEAT 4 (16-20s): \"Save this one.\""] ),
            "  CTA: \"250+ codes, free app, link in bio\"",
            "",
            f"Caption: {c['code']} explained in 20 seconds. {play_tt}",
            f"Hashtags: {HASHTAGS_EN}",
            "```",
        ]

    elif angle == 2:                         # Wed — speeds & feeds
        mats = json.loads((DATA / "materials.json").read_text(encoding="utf-8")).get("materials", [])
        m = pick(mats, n // 7)
        name = m.get("name") or m.get("code", "")
        out += [
            f"**Angle:** Speeds & feeds — {name}", "",
            "## Facebook — English", "",
            "```",
            f"Cutting {name}? Start here, then tune by sound and chip colour.",
            "",
            "Get the four numbers right and the tool lasts:",
            "• Vc (surface speed) — sets your RPM for the diameter you're actually using",
            "• fz (chip load per tooth) — too low rubs and work-hardens, too high snaps the tool",
            "• ap / ae (depth and width) — the pair that decides how much the tool can take",
            "• MRR — what the machine is really removing",
            "",
            "The calculator does all four from material + tool + operation, metric or imperial:",
            f"{play_fb}",
            "",
            "Free. No ads. Works offline at the machine.",
            "",
            HASHTAGS_EN,
            "```", "",
            "## Facebook — Română", "",
            "```",
            f"Prelucrezi {name}? Pornește de aici, apoi reglează după sunet și culoarea așchiei.",
            "",
            "Patru numere decid dacă scula rezistă:",
            "• Vc (viteza de așchiere) — îți dă turația pentru diametrul real",
            "• fz (avansul pe dinte) — prea mic freacă și ecruisează, prea mare rupe scula",
            "• ap / ae (adâncimea și lățimea) — perechea care decide cât poate duce scula",
            "• MRR — cât material scoți de fapt",
            "",
            "Calculatorul le scoate pe toate patru din material + sculă + operație, metric sau imperial:",
            f"{play_fb}",
            "",
            "Gratuit. Fără reclame. Funcționează offline, lângă mașină.",
            "",
            HASHTAGS_RO,
            "```", "",
            "## TikTok — script 25s", "",
            "```",
            "HOOK (0-3s): \"Your endmill didn't break. You broke it.\"",
            "BEAT 2 (3-9s): arată o sculă tocită/ruptă — \"chip load too low = rubbing = heat\"",
            f"BEAT 3 (9-18s): filmare de ecran — introduci {name}, diametru, nr. dinți → apar RPM/feed",
            "BEAT 4 (18-25s): \"Four numbers. Ten seconds. Free app.\"",
            "",
            f"Caption: Stop guessing speeds and feeds. {play_tt}",
            f"Hashtags: {HASHTAGS_EN}",
            "```",
        ]

    elif angle == 4:                         # Fri — the trap / gotcha
        gs = [c for c in (codes.get("g_codes") or []) if c.get("warning")]
        c = pick(gs, n // 7)
        url = f"{SITE}/gcode/g-codes/{slug(c['code'])}.html"
        out += [
            f"**Angle:** The trap — {c['code']}", "",
            "## Facebook — English", "",
            "```",
            f"The {c['code']} mistake that costs a part (or a spindle).",
            "",
            f"{c['code']} — {c.get('name','')}: {c.get('description','')}",
            "",
            f"⚠ {c['warning']}",
            "",
            "If you've been bitten by this one, you already know. If you haven't — now you won't be.",
            "",
            f"Full note: {url}",
            f"250+ codes with the traps, offline: {play_fb}",
            "",
            HASHTAGS_EN,
            "```", "",
            "## Facebook — Română", "",
            "```",
            f"Greșeala cu {c['code']} care te costă o piesă (sau un arbore principal).",
            "",
            f"{c['code']} — {c.get('name','')}: {c.get('description','')}",
            "",
            f"⚠ {c['warning']}",
            "",
            "Cine a pățit-o știe. Cine nu — de acum nu o mai pățește.",
            "",
            f"Nota completă: {url}",
            f"Peste 250 de coduri cu capcanele lor, offline: {play_fb}",
            "",
            HASHTAGS_RO,
            "```", "",
            "## TikTok — script 20s", "",
            "```",
            f"HOOK (0-3s): \"This one line crashed a machine.\" + text mare \"{c['code']}\"",
            f"BEAT 2 (3-10s): \"{c.get('name','')}\" — ce face de fapt",
            f"BEAT 3 (10-17s): text roșu pe ecran — \"{c['warning'][:90]}\"",
            "BEAT 4 (17-20s): \"Know the trap before the machine teaches you. Free app, link in bio.\"",
            "",
            f"Caption: The {c['code']} trap. {play_tt}",
            f"Hashtags: {HASHTAGS_EN}",
            "```",
        ]

    else:                                    # Sun — quiz
        qs = json.loads((DATA / "quiz.json").read_text(encoding="utf-8")).get("questions", [])
        q = pick(qs, n // 7)
        opts = q.get("options") or []
        qtext = q.get("q") or q.get("question") or ""
        ans = q.get("answer")
        ans_letter = chr(65 + ans) if isinstance(ans, int) and 0 <= ans < len(opts) else "?"
        out += [
            "**Angle:** Sunday quiz", "",
            "## Facebook — English", "",
            "```",
            "Sunday shop quiz 👇",
            "",
            qtext,
            "",
            *[f"{chr(65+i)}) {o}" for i, o in enumerate(opts)],
            "",
            "Answer in the comments before you scroll on. No googling.",
            "",
            f"(There's a whole practice quiz in the app — free: {play_fb})",
            "",
            HASHTAGS_EN,
            "```", "",
            "## Facebook — Română", "",
            "```",
            "Întrebarea de duminică 👇",
            "",
            qtext,
            "",
            *[f"{chr(65+i)}) {o}" for i, o in enumerate(opts)],
            "",
            "Răspunde în comentarii înainte să derulezi. Fără căutat pe net.",
            "",
            f"(Un test complet e în aplicație, gratuit: {play_fb})",
            "",
            HASHTAGS_RO,
            "```", "",
            "## TikTok — script 15s", "",
            "```",
            "HOOK (0-2s): \"90% of operators get this wrong.\"",
            f"BEAT 2 (2-8s): întrebarea pe ecran — {qtext}",
            "BEAT 3 (8-12s): countdown 3-2-1 cu opțiunile pe ecran",
            f"BEAT 4 (12-15s): răspunsul corect este {ans_letter} + \"Full quiz in the free app.\"",
            "",
            f"Caption: Comment your answer before the reveal. {play_tt}",
            f"Hashtags: {HASHTAGS_EN}",
            "```",
        ]

    out += ["", "---", "",
            "**Posting checklist**",
            "- [ ] Facebook — post in the shop/machining groups you belong to (EN groups get EN, RO groups get RO)",
            "- [ ] TikTok — record the screen beats, keep it under 30s, put the link in bio (TikTok kills in-caption links)",
            "- [ ] Reply to every comment in the first hour — it is the single biggest reach multiplier",
            "- [ ] Never drop a bare link in a group. Answer the question first, link second.",
            ""]
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("day", nargs="?", help="YYYY-MM-DD (default: today)")
    ap.add_argument("--days", type=int, default=1, help="how many consecutive days to generate")
    args = ap.parse_args()

    start = date.fromisoformat(args.day) if args.day else date.today()
    alarms, codes = load()
    OUT.mkdir(parents=True, exist_ok=True)

    for i in range(args.days):
        d = start + timedelta(days=i)
        path = OUT / f"{d.isoformat()}.md"
        path.write_text(build(d, alarms, codes), encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
