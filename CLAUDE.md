# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**CNC Assist** — Flutter Android app for CNC machine operators. Provides a feed/speed calculator, G-code analyzer, and AI-powered knowledge base Q&A.

## Commands

```bash
# Run on Android device/emulator
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs

# Lint
flutter analyze

# Format
dart format lib/
```

## Architecture

Feature-based clean architecture. Each feature under `lib/features/<name>/` has three layers:

- `data/` — repositories that load from assets (JSON) or Supabase
- `domain/` — pure Dart business logic, models, calculators
- `presentation/` — screens and widgets (Riverpod consumers)

`lib/core/` holds shared infrastructure: routing (`go_router`), theme, and the `MainScaffold` bottom-nav shell.

### Navigation

`go_router` with a `StatefulShellRoute.indexedStack`: each bottom-nav tab (tools hub, G-code, knowledge base, history) is a branch with its own navigator, so switching tabs keeps each tab's state. `MainScaffold` gets the `StatefulNavigationShell`; don't wrap it in an `AnimatedSwitcher`, because the two children would share the shell's keyed Navigator (duplicate GlobalKey). Settings and Subscription are top-level routes outside the shell, always opened with `context.push`. The G-code result screen (`/gcode/result`) is a child route that receives analysis data via `state.extra`.

Persian and Arabic are right-to-left via `MaterialApp.locale` and the `flutter_localizations` delegates (`lib/app.dart`). A `Directionality` around `MaterialApp` has no effect. Code views (the G-code editor, analysis lines, generated programs) force `TextDirection.ltr`.

### State management

Riverpod (`flutter_riverpod` 2) with hand-written providers: `Provider`, `FutureProvider`, `StateProvider`, `StateNotifierProvider`. No code generation is in use: `riverpod_generator`, `freezed` and `json_serializable` are declared but unused. Screens keep local UI state in `setState`.

Numeric inputs use `DecimalInputFormatter` (`lib/core/widgets/`), which turns `,` `٫` and Persian/Arabic digits into a parseable number. Never filter characters out of a number field: dropping the comma turned "0,15" into 15.

### G-code parsing

`GcodeParser` picks `HaasParser`, `SinumerikParser` or `GenericParser` (Fanuc/ISO), all extending `BaseParser`; auto-detection inspects the raw text. `BlockReader` turns each line into a `Block` (G/M codes, address words, keywords) using the dialect's comment syntax: `()` on Haas/Fanuc, `;` on Sinumerik, where parentheses are code (`CYCLE83(…)`, `X=IC(5)`). `BaseParser.parse()` runs the dialect's per-line `checkBlock()`, then walks the program with the modal state (spindle, feed, canned cycle, cutter/length comp, units, work offset). State findings are reported once per situation and stop after a call or jump.

Findings are `LineIssue(severity, rule, args)`. Their text, a message plus a fix, lives in `GcodeRuleText` for all four languages; a test fails if a rule or placeholder is missing in any of them. Another test requires every code in `assets/data/gcode_reference.json` to be known to the matching parser, and real Haas mill, Haas lathe and Sinumerik programs to produce no findings. Add a rule = add it to a parser, to all four tables in `GcodeRuleText`, and a positive and a negative test.

The AI review (`analyze-gcode`) is a second opinion. It gets the numbered program, the app's own findings and the UI language, and returns at most 30 findings plus a summary (`AiReview`). Code from `GcodeGenerator` must pass the analyzer with zero findings (tested).

### Feed/Speed calculator

`MillingCalculator.calculate()` in `domain/calculators/` takes a `CalculatorInput` + `MaterialSpec` and returns `CutParameters`. Material data is loaded lazily from `assets/data/materials.json` by `MaterialsRepository` (in-memory cache after first load). RPM formula: metric `(Vc×1000)/(π×D)`, imperial `(SFM×3.82)/D`.

The chip loads in `materials.json` are the values for a ½" tool. `chipLoadScale()` scales them linearly below ½" and by `(D/½)^0.7` above; face mills are not scaled. Milling, turning and drilling take `maxRpm` (the machine limit from Settings, `maxRpmProvider`, 0 = none). Above it they cap RPM, keep chip load and feed per rev, and report `limitedFromRpm` for the note under the result.

### Backend (Supabase)

- **The Supabase project is shared with another app** (bookings, contacts, documents). That app owns `public.profiles`, the `on_auth_user_created` trigger and `handle_new_user()`. Never change them from here. CNC Assist's objects are `qa_logs` and the `cnc_*` tables. Never run `supabase db push` from this repo (the remote migration history is the other app's); apply CNC migrations with `supabase db query -f`. `supabase/migrations/001`/`002` are historical and do not match what is live.
- Auth: anonymous sign-in.
- Edge Functions hold every server-side secret (AI provider keys, the Google Play service account). These are **never** in the Flutter app. Call them through `invokeEdgeFunction()` (`lib/core/net/`), which turns non-2xx responses into a typed `EdgeFunctionError`; `functions.invoke` throws on non-2xx, so checking `response.status` afterwards never works.
- Pro: `cnc_purchases`, written only from Google Play data by `verify-purchase` and `play-rtdn`, is the source of truth. `cnc_entitlements` (tier + expiry per user) is a cache of it that the app reads. Pro needs a future expiry (`entitlementGrantsPro` in the app, `isPro` in `_shared/entitlement.ts`). `PurchaseController` owns the Play purchase stream for the whole session.
- RLS: app users can read only their own `qa_logs` and `cnc_entitlements` rows and cannot write either; `cnc_purchases` is service-role only. Quota is counted in `_shared/quota.ts`. `supabase/tests/rls_test.mjs` applies `live_baseline.sql` (a snapshot of the live objects of both apps) plus 003 and checks both apps.
- Deploying the backend: `supabase/DEPLOY.md`
- Local offline storage uses Hive + `flutter_secure_storage`

## Environment setup

The Supabase URL and anon key are compiled in (`lib/core/config/supabase_config.dart`); the anon key is public by design, and RLS is what protects the data. Server secrets live only in Supabase Dashboard → Edge Functions → Secrets (see `supabase/DEPLOY.md`).

## Code generation note

No generated code is checked in or used today. If you add `freezed` / `json_serializable` / `@riverpod` annotations, run `build_runner` afterwards (the outputs are gitignored).

## Assets

Static data lives in `assets/data/`:
- `materials.json` — cutting speed tables and chip-load factors per material
- `tools.json` — tool geometry reference data
- `gcode_reference.json` — G/M-code descriptions for the knowledge base

Font family `JetBrainsMono` is used for all monospaced G-code display (app bar titles and code views).

## Growth tooling (`tools/`, `docs/`, `marketing/`)

These sit outside the Flutter app and never ship in the APK, but they read the same
`assets/data/*.json`, so changing that data changes them too.

- **`tools/build_site.py`** → regenerates `docs/`, the public reference site on GitHub Pages
  (~540 pages, one per controller alarm and per G/M-code, plus sitemap and robots.txt).
  It **wipes `docs/` first**, keeping only the names in `PROTECTED` and the patterns in
  `PROTECTED_GLOBS` — `privacy-policy.html` (Play Console points at that exact URL),
  `store-assets/`, and the search-engine verification files. Add anything else that must
  survive to those lists, or a rebuild will delete it. Re-run after editing `errors.json`
  or `gcode_reference.json`.
- **`tools/daily_promo.py`** → writes `marketing/daily/<date>.md`, a day's social copy for
  Facebook, TikTok, LinkedIn and YouTube in English and Romanian. It **skips a day whose file
  already exists** so it cannot clobber copy the daily agent rewrote; `--force` overrides.
- **`tools/post_social.py`** → posts the Facebook and LinkedIn blocks via API, meant to run from
  `.github/workflows/daily-post.yml`. That workflow file is **not in the repo yet**: pushing
  `.github/workflows` needs a GitHub token with the `workflow` scope (commit 2ee64b6), so
  nothing posts automatically until it is added. Credentials come from GitHub repository
  secrets and must never be committed. See `marketing/automation-setup.md`.
- **`tools/listing.py`** → prints one language's Play Console fields with live character counts
  against the 30 / 80 / 4000 limits. Source of truth is `docs/store-listing.md`.

A scheduled cloud agent runs `daily_promo.py` every morning, rewrites the draft into natural
prose, and pushes. It is told never to alter technical content — alarm codes, causes, fixes,
syntax and warnings are machine-safety information and are copied verbatim from the JSON.
Keep that constraint in any prompt that touches this content.
