#!/usr/bin/env python3
"""Generate the CNC Assist public reference site into docs/ (GitHub Pages).

The app ships ~275 controller alarms and ~250 G/M-codes inside the APK, where
no search engine can reach them. Machinists google "haas alarm 102" every day,
so this turns each of those entries into its own indexable page that funnels to
the Play Store listing.

Run:  python3 tools/build_site.py
Then: commit docs/ and push — GitHub Pages serves it.

docs/privacy-policy.html is NEVER touched: Play Console points at that exact URL.
"""
from __future__ import annotations

import html
import json
import re
import shutil
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data"
OUT = ROOT / "docs"

BASE_URL = "https://emadleo13.github.io/CNC-app-project-"
PLAY_ID = "com.cncassist.cnc_assist"

# Canonical profile URLs. Share links and utm/_t tails are stripped on purpose:
# these feed schema.org sameAs, where a redirect or a tracking tail weakens the
# signal that the site, the app and these profiles are one entity.
SOCIAL = {
    "Facebook": "https://www.facebook.com/cncassist13/",
    "TikTok":   "https://www.tiktok.com/@emadleo3",
    "LinkedIn": "https://www.linkedin.com/in/emadleo13-b42882236",
    "YouTube":  "https://www.youtube.com/@emadleo13",
}
SOCIAL_LINKS = " · ".join(
    f'<a href="{u}" rel="me" target="_blank">{n}</a>' for n, u in SOCIAL.items()
)
TODAY = date.today().isoformat()

# Files in docs/ that this generator must never delete or overwrite.
PROTECTED = {"privacy-policy.html", "store-listing.md", "store-assets", "CNAME", ".nojekyll"}

# Search-engine ownership proofs live at the site root and are re-checked
# periodically -- delete one and the property silently loses verification, taking
# the sitemap reporting with it. Matched by pattern because Google names the file
# after a token it generates.
PROTECTED_GLOBS = ("google*.html", "BingSiteAuth.xml", "yandex_*.html")

ALARM_BRANDS = [
    ("haas",       "haas_alarms",       "Haas"),
    ("fanuc",      "fanuc_alarms",      "Fanuc"),
    ("sinumerik",  "sinumerik_alarms",  "Siemens Sinumerik"),
    ("heidenhain", "heidenhain_alarms", "Heidenhain"),
    ("mazak",      "mazak_alarms",      "Mazak"),
]

CODE_GROUPS = [
    ("g-codes",          "g_codes",          "G-Code",           "G-Codes"),
    ("m-codes",          "m_codes",          "M-Code",           "M-Codes"),
    ("sinumerik-cycles", "sinumerik_cycles", "Sinumerik Cycle",  "Siemens Sinumerik Cycles"),
    ("fanuc-codes",      "fanuc_codes",      "Fanuc Code",       "Fanuc-Specific Codes"),
    ("heidenhain-codes", "heidenhain_codes", "Heidenhain Code",  "Heidenhain Codes"),
    ("mazak-codes",      "mazak_codes",      "Mazak Code",       "Mazak-Specific Codes"),
]


def play_url(medium: str) -> str:
    return (f"https://play.google.com/store/apps/details?id={PLAY_ID}"
            f"&utm_source=reference-site&utm_medium={medium}&utm_campaign=seo")


def slug(value: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", str(value)).strip("-").lower()
    return s or "x"


def esc(value) -> str:
    return html.escape(str(value or ""), quote=True)


def clip(text: str, limit: int = 155) -> str:
    text = re.sub(r"\s+", " ", str(text or "")).strip()
    return text if len(text) <= limit else text[: limit - 1].rsplit(" ", 1)[0] + "…"


# --------------------------------------------------------------------------- page shell

CSS = """
:root{--bg:#fff;--fg:#111827;--muted:#5b6472;--line:#e5e7eb;--card:#f8fafc;
--accent:#0b6bcb;--crit:#b42318;--warn:#b54708;--info:#175cd3;--radius:10px}
@media(prefers-color-scheme:dark){:root{--bg:#0c1421;--fg:#e6edf6;--muted:#9aa7b8;
--line:#1f2a3a;--card:#111c2c;--accent:#5aa9f7;--crit:#ff7b72;--warn:#e3b341;--info:#79c0ff}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 -apple-system,BlinkMacSystemFont,
"Segoe UI",Roboto,Helvetica,Arial,sans-serif;-webkit-text-size-adjust:100%}
.wrap{max-width:780px;margin:0 auto;padding:0 20px}
header.site{border-bottom:1px solid var(--line);padding:14px 0;position:sticky;top:0;
background:var(--bg);z-index:5}
header.site .wrap{display:flex;align-items:center;gap:14px;flex-wrap:wrap}
.brand{font-weight:700;text-decoration:none;color:var(--fg);font-size:17px}
header.site nav{margin-left:auto;display:flex;gap:16px}
header.site nav a{color:var(--muted);text-decoration:none;font-size:14px}
header.site nav a:hover{color:var(--accent)}
main{padding:28px 0 56px}
h1{font-size:26px;line-height:1.3;margin:0 0 6px}
h2{font-size:19px;margin:30px 0 10px}
.sub{color:var(--muted);margin:0 0 20px;font-size:15px}
.crumbs{font-size:13px;color:var(--muted);margin:0 0 14px}
.crumbs a{color:var(--muted)}
code,kbd,pre{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}
pre{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);
padding:12px 14px;overflow-x:auto;font-size:14px}
.badge{display:inline-block;font-size:12px;font-weight:600;letter-spacing:.03em;
text-transform:uppercase;padding:3px 9px;border-radius:999px;border:1px solid currentColor}
.b-critical{color:var(--crit)}.b-warning{color:var(--warn)}.b-info{color:var(--info)}
ul.clean{padding-left:20px;margin:0 0 8px}
ul.clean li{margin:5px 0}
.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);
padding:16px 18px;margin:0 0 16px}
.cta{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);
padding:20px;margin:32px 0 0;text-align:center}
.cta p{margin:0 0 14px;color:var(--muted);font-size:15px}
.btn{display:inline-block;background:var(--accent);color:#fff;text-decoration:none;
font-weight:600;padding:11px 22px;border-radius:8px}
.grid{display:grid;gap:10px;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));
padding:0;list-style:none;margin:0}
.grid a{display:block;border:1px solid var(--line);border-radius:var(--radius);padding:11px 13px;
text-decoration:none;color:var(--fg);background:var(--card)}
.grid a:hover{border-color:var(--accent)}
.grid .c{font-weight:700;font-family:ui-monospace,monospace}
.grid .n{display:block;color:var(--muted);font-size:13px;margin-top:2px}
.pager{display:flex;justify-content:space-between;gap:12px;margin-top:28px;font-size:14px}
.pager a{color:var(--accent);text-decoration:none}
footer.site{border-top:1px solid var(--line);padding:22px 0;color:var(--muted);font-size:13px}
footer.site a{color:var(--muted)}
.note{font-size:13px;color:var(--muted);border-left:3px solid var(--line);padding-left:12px;margin:22px 0 0}
"""


def page(*, title, description, canonical, body, jsonld=None, depth=1) -> str:
    up = "../" * depth
    ld = f'<script type="application/ld+json">{json.dumps(jsonld, ensure_ascii=False)}</script>' if jsonld else ""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{esc(canonical)}">
<meta property="og:type" content="article">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{esc(canonical)}">
<meta name="robots" content="index,follow">
<link rel="stylesheet" href="{up}assets/site.css">
{ld}
</head>
<body>
<header class="site"><div class="wrap">
<a class="brand" href="{up}">CNC Assist</a>
<nav>
  <a href="{up}alarms/">Alarm Codes</a>
  <a href="{up}gcode/">G &amp; M-Codes</a>
  <a href="{play_url('nav')}">Get the App</a>
</nav>
</div></header>
<main><div class="wrap">
{body}
</div></main>
<footer class="site"><div class="wrap">
<p>CNC Assist — free reference for CNC operators, programmers and setters.
Also available as a free Android app with a speeds &amp; feeds calculator and a G-code analyzer.</p>
<p><a href="{up}">Home</a> · <a href="{up}alarms/">Alarm codes</a> ·
<a href="{up}gcode/">G &amp; M-codes</a> · <a href="{up}privacy-policy.html">Privacy</a></p>
<p>{SOCIAL_LINKS}</p>
<p>Reference information only. Always verify against your machine's own documentation before acting on it.
Brand names are trademarks of their respective owners and are used here for identification only.</p>
</div></footer>
</body>
</html>
"""


def cta(medium: str, line: str) -> str:
    return f"""<div class="cta">
<p>{esc(line)}</p>
<a class="btn" href="{play_url(medium)}">Get CNC Assist — free on Google Play</a>
</div>"""


def write(rel: str, content: str) -> None:
    target = OUT / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


# --------------------------------------------------------------------------- builders

def build_alarm_pages(alarms_data, urls):
    for brand_slug, key, brand_name in ALARM_BRANDS:
        items = alarms_data.get(key) or []
        if not items:
            continue
        entries = []
        for a in items:
            entries.append((slug(a.get("code")), a))

        for idx, (code_slug, a) in enumerate(entries):
            code = a.get("code", "")
            titletext = a.get("title", "")
            sev = (a.get("severity") or "info").lower()
            causes = a.get("possible_causes") or []
            fixes = a.get("solutions") or []
            h1 = f"{brand_name} Alarm {code} — {titletext}"
            desc = clip(a.get("description") or f"{brand_name} alarm {code}: {titletext}.")
            url = f"{BASE_URL}/alarms/{brand_slug}/{code_slug}.html"

            faq = []
            if causes:
                faq.append({"@type": "Question",
                            "name": f"What causes {brand_name} alarm {code}?",
                            "acceptedAnswer": {"@type": "Answer", "text": " ".join(causes)}})
            if fixes:
                faq.append({"@type": "Question",
                            "name": f"How do you clear {brand_name} alarm {code}?",
                            "acceptedAnswer": {"@type": "Answer", "text": " ".join(fixes)}})
            jsonld = {"@context": "https://schema.org", "@type": "FAQPage",
                      "mainEntity": faq} if faq else None

            parts = [
                f'<p class="crumbs"><a href="../">Alarm codes</a> › '
                f'<a href="./">{esc(brand_name)}</a> › {esc(code)}</p>',
                f"<h1>{esc(h1)}</h1>",
                f'<p class="sub"><span class="badge b-{esc(sev)}">{esc(sev)}</span></p>',
                f'<div class="card"><p>{esc(a.get("description",""))}</p></div>',
            ]
            if causes:
                parts.append(f"<h2>Likely causes of {esc(brand_name)} alarm {esc(code)}</h2>")
                parts.append('<ul class="clean">' +
                             "".join(f"<li>{esc(c)}</li>" for c in causes) + "</ul>")
            if fixes:
                parts.append(f"<h2>How to clear alarm {esc(code)}</h2>")
                parts.append('<ol class="clean">' +
                             "".join(f"<li>{esc(s)}</li>" for s in fixes) + "</ol>")

            parts.append(cta("alarm-page",
                             f"All {len(items)} {brand_name} alarms — offline, in your pocket, next to a "
                             f"speeds & feeds calculator and a G-code analyzer."))

            prev_a = entries[idx - 1] if idx else None
            next_a = entries[idx + 1] if idx + 1 < len(entries) else None
            pager = ['<div class="pager">']
            pager.append(f'<a href="{prev_a[0]}.html">← {esc(brand_name)} alarm {esc(prev_a[1].get("code"))}</a>'
                         if prev_a else "<span></span>")
            pager.append(f'<a href="{next_a[0]}.html">{esc(brand_name)} alarm {esc(next_a[1].get("code"))} →</a>'
                         if next_a else "<span></span>")
            pager.append("</div>")
            parts.append("".join(pager))
            parts.append('<p class="note">Reference only — always confirm against the alarm text on your own '
                         'control and the machine builder\'s manual before working on the machine.</p>')

            write(f"alarms/{brand_slug}/{code_slug}.html",
                  page(title=f"{h1} | CNC Assist", description=desc, canonical=url,
                       body="\n".join(parts), jsonld=jsonld, depth=2))
            urls.append(url)

        # brand index
        cards = "".join(
            f'<li><a href="{cs}.html"><span class="c">{esc(a.get("code"))}</span>'
            f'<span class="n">{esc(a.get("title"))}</span></a></li>'
            for cs, a in entries)
        url = f"{BASE_URL}/alarms/{brand_slug}/"
        body = (f'<p class="crumbs"><a href="../">Alarm codes</a> › {esc(brand_name)}</p>'
                f"<h1>{esc(brand_name)} Alarm Codes</h1>"
                f'<p class="sub">All {len(entries)} {esc(brand_name)} alarms — what each one means, '
                f"the likely causes, and the first steps to clear it.</p>"
                f'<ul class="grid">{cards}</ul>'
                + cta("brand-index", f"Look up any {brand_name} alarm on the shop floor — offline, no ads."))
        write(f"alarms/{brand_slug}/index.html",
              page(title=f"{brand_name} Alarm Codes — Full List | CNC Assist",
                   description=clip(f"Complete list of {len(entries)} {brand_name} CNC alarm codes with "
                                    f"meanings, causes and fixes. Free reference."),
                   canonical=url, body=body, depth=2))
        urls.append(url)
        yield brand_slug, brand_name, len(entries)


def build_code_pages(codes_data, urls):
    for grp_slug, key, label, heading in CODE_GROUPS:
        items = codes_data.get(key) or []
        if not items:
            continue
        entries = [(slug(c.get("code")), c) for c in items]

        for idx, (code_slug, c) in enumerate(entries):
            code = c.get("code", "")
            name = c.get("name", "")
            h1 = f"{code} — {name}"
            desc = clip(c.get("description") or f"{code}: {name}.")
            url = f"{BASE_URL}/gcode/{grp_slug}/{code_slug}.html"
            dialects = c.get("dialects") or ([c["brand"]] if c.get("brand") else [])

            parts = [
                f'<p class="crumbs"><a href="../">G &amp; M-codes</a> › '
                f'<a href="./">{esc(heading)}</a> › {esc(code)}</p>',
                f"<h1>{esc(h1)}</h1>",
                f'<p class="sub">{esc(label)}'
                + (f" · {esc(', '.join(str(d).title() for d in dialects))}" if dialects else "")
                + "</p>",
                f'<div class="card"><p>{esc(c.get("description",""))}</p></div>',
            ]
            if c.get("syntax"):
                parts.append("<h2>Syntax</h2>")
                parts.append(f"<pre><code>{esc(c['syntax'])}</code></pre>")
            if c.get("warning"):
                parts.append("<h2>Watch out</h2>")
                parts.append(f'<div class="card"><p>{esc(c["warning"])}</p></div>')

            parts.append(cta("code-page",
                             "Check a whole program at once — the app's G-code analyzer flags errors "
                             "before you run it."))

            prev_c = entries[idx - 1] if idx else None
            next_c = entries[idx + 1] if idx + 1 < len(entries) else None
            pager = ['<div class="pager">']
            pager.append(f'<a href="{prev_c[0]}.html">← {esc(prev_c[1].get("code"))}</a>' if prev_c else "<span></span>")
            pager.append(f'<a href="{next_c[0]}.html">{esc(next_c[1].get("code"))} →</a>' if next_c else "<span></span>")
            pager.append("</div>")
            parts.append("".join(pager))

            write(f"gcode/{grp_slug}/{code_slug}.html",
                  page(title=f"{h1} | CNC Assist", description=desc, canonical=url,
                       body="\n".join(parts), depth=2))
            urls.append(url)

        cards = "".join(
            f'<li><a href="{cs}.html"><span class="c">{esc(c.get("code"))}</span>'
            f'<span class="n">{esc(c.get("name"))}</span></a></li>'
            for cs, c in entries)
        url = f"{BASE_URL}/gcode/{grp_slug}/"
        body = (f'<p class="crumbs"><a href="../">G &amp; M-codes</a> › {esc(heading)}</p>'
                f"<h1>{esc(heading)}</h1>"
                f'<p class="sub">All {len(entries)} entries, with syntax and the traps worth knowing.</p>'
                f'<ul class="grid">{cards}</ul>'
                + cta("code-index", "The whole reference works offline inside the app."))
        write(f"gcode/{grp_slug}/index.html",
              page(title=f"{heading} — Full List | CNC Assist",
                   description=clip(f"Complete {heading} reference: {len(entries)} codes with syntax, "
                                    f"meaning and warnings. Free."),
                   canonical=url, body=body, depth=2))
        urls.append(url)
        yield grp_slug, heading, len(entries)


def main() -> None:
    alarms_data = json.loads((DATA / "errors.json").read_text(encoding="utf-8"))
    codes_data = json.loads((DATA / "gcode_reference.json").read_text(encoding="utf-8"))

    # Clean only what we generate — never the privacy policy or store assets.
    for child in OUT.iterdir():
        if child.name in PROTECTED or any(child.match(g) for g in PROTECTED_GLOBS):
            continue
        shutil.rmtree(child) if child.is_dir() else child.unlink()

    write("assets/site.css", CSS)
    urls: list[str] = []

    alarm_sections = list(build_alarm_pages(alarms_data, urls))
    code_sections = list(build_code_pages(codes_data, urls))

    total_alarms = sum(n for _, _, n in alarm_sections)
    total_codes = sum(n for _, _, n in code_sections)

    # alarms hub
    cards = "".join(f'<li><a href="{s}/"><span class="c">{esc(n)}</span>'
                    f'<span class="n">{c} alarm codes</span></a></li>'
                    for s, n, c in alarm_sections)
    url = f"{BASE_URL}/alarms/"
    write("alarms/index.html", page(
        title="CNC Alarm Codes — Haas, Fanuc, Sinumerik, Heidenhain, Mazak | CNC Assist",
        description=clip(f"{total_alarms} CNC alarm codes across five controller brands, with meanings, "
                         f"likely causes and fixes. Free reference."),
        canonical=url,
        body=("<h1>CNC Alarm Codes</h1>"
              f'<p class="sub">{total_alarms} alarms across five controller families. Each page explains '
              "what the alarm means, what usually causes it, and the first steps to clear it.</p>"
              f'<ul class="grid">{cards}</ul>'
              + cta("alarms-hub", "Every one of these works offline in the free Android app.")),
        depth=1))
    urls.append(url)

    # gcode hub
    cards = "".join(f'<li><a href="{s}/"><span class="c">{esc(h)}</span>'
                    f'<span class="n">{c} entries</span></a></li>'
                    for s, h, c in code_sections)
    url = f"{BASE_URL}/gcode/"
    write("gcode/index.html", page(
        title="G-Code and M-Code Reference — Haas, Fanuc, Sinumerik | CNC Assist",
        description=clip(f"{total_codes} G-codes, M-codes and canned cycles explained, with syntax "
                         f"for Haas, Fanuc, Sinumerik, Heidenhain and Mazak. Free."),
        canonical=url,
        body=("<h1>G-Code &amp; M-Code Reference</h1>"
              f'<p class="sub">{total_codes} codes and cycles with syntax, plain-language meaning and the '
              "mistakes that bite.</p>"
              f'<ul class="grid">{cards}</ul>'
              + cta("gcode-hub", "Paste a whole program into the app and let it find the errors.")),
        depth=1))
    urls.append(url)

    # homepage
    url = f"{BASE_URL}/"
    home_ld = {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": "CNC Assist",
        "operatingSystem": "Android",
        "applicationCategory": "UtilitiesApplication",
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "url": f"{BASE_URL}/",
        "downloadUrl": f"https://play.google.com/store/apps/details?id={PLAY_ID}",
        "description": ("Free CNC reference and Android app: speeds and feeds calculator, "
                        "G-code analyzer, controller alarm codes and a G/M-code reference."),
        "sameAs": list(SOCIAL.values()),
    }
    write("index.html", page(
        jsonld=home_ld,
        title="CNC Assist — Alarm Codes, G-Code Reference & Speeds and Feeds",
        description=clip(f"Free CNC reference: {total_alarms} alarm codes for Haas, Fanuc, Sinumerik, "
                         f"Heidenhain and Mazak, plus {total_codes} G/M-codes. And a free Android app."),
        canonical=url,
        body=("<h1>CNC Assist</h1>"
              '<p class="sub">A free reference for CNC operators, programmers and setters — '
              "and a free Android app that carries the whole thing offline.</p>"
              '<ul class="grid">'
              f'<li><a href="alarms/"><span class="c">Alarm Codes</span>'
              f'<span class="n">{total_alarms} alarms · Haas, Fanuc, Sinumerik, Heidenhain, Mazak</span></a></li>'
              f'<li><a href="gcode/"><span class="c">G &amp; M-Codes</span>'
              f'<span class="n">{total_codes} codes, cycles and syntax</span></a></li>'
              "</ul>"
              "<h2>What the app adds</h2>"
              '<ul class="clean">'
              "<li><strong>Speeds and feeds calculator</strong> — RPM, feed, chip load and MRR for milling, "
              "turning and drilling, with a built-in material database.</li>"
              "<li><strong>G-code analyzer</strong> — paste a program and get errors and warnings before "
              "you run it, with automatic Haas / Sinumerik detection.</li>"
              "<li><strong>AI machining assistant</strong> — ask a question in plain language, or photograph "
              "an alarm screen or a drawing.</li>"
              "<li><strong>Offline</strong> — the whole reference travels with you. No ads.</li>"
              "</ul>"
              + cta("homepage", "Free on Google Play. No ads, works offline.")),
        depth=0))
    urls.append(url)

    # sitemap + robots
    body = "".join(f"<url><loc>{u}</loc><lastmod>{TODAY}</lastmod></url>" for u in sorted(set(urls)))
    write("sitemap.xml",
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + body + "</urlset>")
    write("robots.txt", f"User-agent: *\nAllow: /\nSitemap: {BASE_URL}/sitemap.xml\n")

    print(f"alarms : {total_alarms}")
    print(f"codes  : {total_codes}")
    print(f"pages  : {len(set(urls))} (sitemap entries)")
    print(f"output : {OUT}")


if __name__ == "__main__":
    main()
