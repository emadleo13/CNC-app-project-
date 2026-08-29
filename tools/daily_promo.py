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


# Both alarm days (Mon, Thu) and both code days (Tue, Sat) advance on a WEEKLY
# counter, and are separated by an offset into the brand/group list. Driving them
# off the raw day number instead made the two code days collide every week --
# Tuesday's index and Saturday's index landed on the same entry.
def alarm_block(alarms, cycle, brand_offset=0):
    bslug, key, bname = BRANDS[(cycle + brand_offset) % len(BRANDS)]
    items = alarms.get(key) or []
    a = pick(items, cycle)
    url = f"{SITE}/alarms/{bslug}/{slug(a['code'])}.html"
    return bname, a, url


CODE_SETS = [("g_codes", "g-codes"), ("m_codes", "m-codes"),
             ("sinumerik_cycles", "sinumerik-cycles"), ("fanuc_codes", "fanuc-codes")]


def code_block(codes, cycle, group_offset=0):
    key, gslug = CODE_SETS[(cycle + group_offset) % len(CODE_SETS)]
    items = codes.get(key) or []
    c = pick(items, cycle)
    url = f"{SITE}/gcode/{gslug}/{slug(c['code'])}.html"
    return c, url



def sentence(text: str) -> str:
    """Guarantee terminal punctuation before another sentence is appended.

    The alarm/fix strings come from the app data and mostly have no full stop,
    so concatenating one straight onto the next line produced run-on sentences.
    """
    text = str(text or "").strip()
    return text if not text or text[-1] in ".!?:" else text + "."


def linkedin_block(*, headline_en, headline_ro, lead_en, bullets_en, close_en,
                   lead_ro, bullets_ro, close_ro, link):
    """LinkedIn is a different room from Facebook and TikTok.

    The audience there is shop owners, production engineers, quality people and
    instructors — not an operator scrolling next to the machine. So: no hashtag
    wall, no hook-bait, longer sentences, and the value framed as what it saves
    a shop rather than what it does. One link, at the end.
    """
    def block(headline, lead, bullets, close):
        return ["```", headline, "", lead, ""] + \
               [f"— {b}" for b in bullets] + \
               ["", close, "", link, "", "#cnc #manufacturing #machining #prelucrare", "```", ""]
    return (["## LinkedIn — English", ""] + block(headline_en, lead_en, bullets_en, close_en) +
            ["## LinkedIn — Română", ""] + block(headline_ro, lead_ro, bullets_ro, close_ro))


def youtube_block(*, title, summary, chapters, link, tags):
    """YouTube is a search engine; TikTok is a feed.

    TikTok needs a hook because the video is pushed at people who were not
    looking for it. YouTube needs an exact-match title because people type the
    problem into the search bar -- "haas alarm 102" gets searched on YouTube
    almost as much as on Google. Same vertical footage, different packaging.
    Unlike TikTok, links in a YouTube description are clickable, so the CTA
    lives there instead of in a bio.
    """
    return ["## YouTube — title, description, tags", "",
            "```",
            "TITLE (exact-match — this is the phrase people type, do not get clever):",
            title,
            "",
            "DESCRIPTION:",
            summary,
            ""] + list(chapters) + [
            "",
            f"Free written reference: {link}",
            f"Free Android app (offline, no ads): {PLAY.format(medium='youtube')}",
            "",
            f"TAGS: {tags}",
            "```",
            "",
            "Reuse the TikTok footage above — the same vertical clip works as a Short. Only the",
            "title and description change, because YouTube ranks on them and TikTok does not.",
            ""]

def build(day: date, alarms, codes) -> str:
    n = (day - date(2026, 1, 1)).days
    angle = n % 7
    cycle = n // 7   # advances once per week
    play_fb = PLAY.format(medium="facebook")
    play_tt = PLAY.format(medium="tiktok")
    out = [f"# Promo — {day.isoformat()}", ""]

    if angle in (0, 3):                      # Mon & Thu — alarm of the day
        bname, a, url = alarm_block(alarms, cycle, brand_offset=(0 if angle == 0 else 2))
        code, title = a["code"], a["title"]
        causes = a.get("possible_causes") or []
        fixes = a.get("solutions") or []
        top_fix = fixes[0] if fixes else "Check the machine documentation."
        li = linkedin_block(
            headline_en=f"{bname} alarm {code}: {title}",
            headline_ro=f"Alarma {bname} {code}: {title}",
            lead_en=("Unplanned downtime is rarely the alarm itself — it is the twenty minutes "
                     "spent working out what the alarm means."),
            bullets_en=causes[:3],
            close_en=(f"First check: {sentence(top_fix)} "
                      "We keep the full write-up free, no signup, because a machine down at "
                      "2am should not require a forum login."),
            lead_ro=("Timpul de oprire nu vine din alarmă, ci din cele douăzeci de minute în care "
                     "afli ce înseamnă alarma."),
            bullets_ro=causes[:3],
            close_ro=(f"Primul lucru de verificat: {sentence(top_fix)} "
                      "Explicația completă e gratuită și fără cont — o mașină oprită noaptea "
                      "nu ar trebui să ceară login pe un forum."),
            link=url)
        yt = youtube_block(
            title=f"{bname} Alarm {code} — {title} (What It Means and How to Clear It)",
            summary=(f"{a.get('description','')} Here is what usually causes {bname} alarm {code} "
                     f"and the first things to check before you call service."),
            chapters=["00:00 What the alarm means",
                      "00:20 Likely causes",
                      "00:50 How to clear it"],
            link=url,
            tags=f"{bname.lower()} alarm {code}, {bname.lower()} alarm codes, cnc alarm, "
                 f"{title.lower()}, cnc troubleshooting, machinist")
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
        c, url = code_block(codes, cycle, group_offset=(0 if angle == 1 else 2))
        warn = c.get("warning")
        li = linkedin_block(
            headline_en=f"{c['code']} — {c.get('name','')}",
            headline_ro=f"{c['code']} — {c.get('name','')}",
            lead_en="A code most programmers use daily and few could define precisely.",
            bullets_en=[c.get("description", "")] + ([f"Syntax: {c['syntax']}"] if c.get("syntax") else [])
                       + ([f"Watch out: {warn}"] if warn else []),
            close_en=("Small gaps like this are where scrap comes from. The full reference is "
                      "free and works offline."),
            lead_ro="Un cod folosit zilnic de aproape toți programatorii și definit corect de puțini.",
            bullets_ro=[c.get("description", "")] + ([f"Sintaxă: {c['syntax']}"] if c.get("syntax") else [])
                       + ([f"Atenție: {warn}"] if warn else []),
            close_ro=("Din astfel de goluri mici apare rebutul. Referința completă e gratuită "
                      "și funcționează offline."),
            link=url)
        yt = youtube_block(
            title=f"{c['code']} Explained — {c.get('name','')} (CNC Programming)",
            summary=(f"{c.get('description','')}"
                     + (f" Syntax: {c['syntax']}" if c.get('syntax') else "")
                     + (f" Watch out: {warn}" if warn else "")),
            chapters=["00:00 What it does",
                      "00:15 Syntax",
                      "00:35 The mistake to avoid"],
            link=url,
            tags=f"{c['code'].lower()}, {c.get('name','').lower()}, g code, gcode programming, "
                 f"cnc programming, machinist")
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
        m = pick(mats, cycle)
        name = m.get("name") or m.get("code", "")
        li = linkedin_block(
            headline_en=f"Four numbers decide whether a tool survives {name}",
            headline_ro=f"Patru numere decid dacă scula supraviețuiește la {name}",
            lead_en=("Tool cost is visible on the invoice. The unplanned stop when a cutter lets "
                     "go mid-cycle is not, and it is the larger number."),
            bullets_en=["Vc — surface speed, which sets RPM for the diameter actually in the spindle",
                        "fz — chip load per tooth; too low rubs and work-hardens, too high snaps the tool",
                        "ap / ae — depth and width, the pair that decides what the tool can take",
                        "MRR — what the machine is genuinely removing, not what the post says"],
            close_en=("Getting an apprentice to those four numbers in ten seconds is worth more "
                      "than another shelf of carbide."),
            lead_ro=("Costul sculei se vede pe factură. Oprirea neplanificată când o freză cedează "
                     "în mijlocul ciclului nu se vede — și e numărul mai mare."),
            bullets_ro=["Vc — viteza de așchiere, care dă turația pentru diametrul real din arbore",
                        "fz — avansul pe dinte; prea mic freacă și ecruisează, prea mare rupe scula",
                        "ap / ae — adâncimea și lățimea, perechea care decide cât duce scula",
                        "MRR — cât material scoți de fapt, nu cât spune postprocesorul"],
            close_ro=("Un ucenic care ajunge la aceste patru numere în zece secunde valorează mai "
                      "mult decât încă un raft de carbură."),
            link=PLAY.format(medium="linkedin"))
        yt = youtube_block(
            title=f"Speeds and Feeds for {name} — The 4 Numbers That Matter",
            summary=("Vc, chip load, depth/width of cut and MRR decide whether the tool survives. "
                     f"Here is how to get them right for {name}, in metric or imperial."),
            chapters=["00:00 Why tools break",
                      "00:15 The four numbers",
                      "00:45 Working it out in seconds"],
            link=f"{SITE}/",
            tags=f"speeds and feeds, {name.lower()}, chip load, cutting speed, feed rate, "
                 f"cnc milling, machinist calculator")
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
        c = pick(gs, cycle)
        url = f"{SITE}/gcode/g-codes/{slug(c['code'])}.html"
        li = linkedin_block(
            headline_en=f"The {c['code']} mistake that costs a part",
            headline_ro=f"Greșeala cu {c['code']} care te costă o piesă",
            lead_en=f"{c['code']} — {c.get('name','')}: {c.get('description','')}",
            bullets_en=[c["warning"]],
            close_en=("Most crashes are not exotic. They are a known trap meeting someone who "
                      "had not met it yet. Worth ten minutes in a toolbox talk."),
            lead_ro=f"{c['code']} — {c.get('name','')}: {c.get('description','')}",
            bullets_ro=[c["warning"]],
            close_ro=("Majoritatea coliziunilor nu sunt exotice. Sunt o capcană cunoscută care "
                      "întâlnește pe cineva care nu o știa încă. Merită zece minute de instructaj."),
            link=url)
        yt = youtube_block(
            title=f"The {c['code']} Mistake That Crashes Machines — {c.get('name','')}",
            summary=f"{c.get('description','')} The trap: {c['warning']}",
            chapters=["00:00 What the code does",
                      "00:20 Where it bites",
                      "00:40 How to stay out of trouble"],
            link=url,
            tags=f"{c['code'].lower()}, cnc crash, g code mistake, cnc programming, "
                 f"machinist, gcode")
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
        q = pick(qs, cycle)
        opts = q.get("options") or []
        qtext = q.get("q") or q.get("question") or ""
        ans = q.get("answer")
        ans_letter = chr(65 + ans) if isinstance(ans, int) and 0 <= ans < len(opts) else "?"
        li = linkedin_block(
            headline_en="A question worth asking your team on Monday",
            headline_ro="O întrebare de pus echipei luni dimineață",
            lead_en=qtext,
            bullets_en=[f"{chr(65+i)}) {o}" for i, o in enumerate(opts)],
            close_en=(f"Answer: {ans_letter}. If a majority of a shop gets this wrong, that is a "
                      "training gap, not a people problem."),
            lead_ro=qtext,
            bullets_ro=[f"{chr(65+i)}) {o}" for i, o in enumerate(opts)],
            close_ro=(f"Răspuns: {ans_letter}. Dacă majoritatea dintr-un atelier greșește, e o "
                      "problemă de instruire, nu de oameni."),
            link=PLAY.format(medium="linkedin"))
        yt = youtube_block(
            title=f"{qtext} (CNC Quiz)",
            summary=("A quick one most operators get wrong. Answer at the end — no googling. "
                     f"Correct answer: {ans_letter}."),
            chapters=["00:00 The question",
                      "00:08 Think about it",
                      "00:12 The answer"],
            link=f"{SITE}/",
            tags=f"cnc quiz, {q.get('category','cnc').lower()}, machinist test, "
                 f"cnc training, gcode")
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

    out += [""] + li + yt
    out += ["", "---", "",
            "**Posting checklist**",
            "- [ ] Facebook — post in the shop/machining groups you belong to (EN groups get EN, RO groups get RO)",
            "- [ ] TikTok — record the screen beats, keep it under 30s, put the link in bio (TikTok kills in-caption links)",
            "- [ ] LinkedIn — post as yourself, not as a page; tag no one; reply to every comment",
            "- [ ] YouTube — upload the same vertical clip as a Short; the TITLE is what ranks, so paste it exactly",
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
