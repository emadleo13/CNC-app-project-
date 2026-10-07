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

`GcodeParser` is a factory that selects between `HaasParser` and `SinumerikParser` (both extend `BaseParser`). Auto-detection inspects the raw G-code string. `BaseParser.parse()` tokenizes lines and delegates validation to the dialect-specific subclass via `validateLine()`, `knownGCodes()`, and `knownMCodes()`.

### Feed/Speed calculator

`MillingCalculator.calculate()` in `domain/calculators/` takes a `CalculatorInput` + `MaterialSpec` and returns `CutParameters`. Material data is loaded lazily from `assets/data/materials.json` by `MaterialsRepository` (in-memory cache after first load). RPM formula: metric `(Vc×1000)/(π×D)`, imperial `(SFM×3.82)/D`.

### Backend (Supabase)

- Auth: anonymous sign-in; a DB trigger creates the `profiles` row
- Edge Functions hold every server-side secret (AI provider keys, the Google Play service account). These are **never** in the Flutter app. Call them through `invokeEdgeFunction()` (`lib/core/net/`), which turns non-2xx responses into a typed `EdgeFunctionError`; `functions.invoke` throws on non-2xx, so checking `response.status` afterwards never works.
- Pro: `public.purchases`, written only from Google Play data by `verify-purchase` and `play-rtdn`, is the source of truth. `profiles.subscription_tier` / `subscription_expires_at` are a cache of it; Pro needs a future expiry (`profileGrantsPro` in the app, `isPro` in `_shared/entitlement.ts`). `PurchaseController` owns the Play purchase stream for the whole session.
- RLS is on for all tables. App users may only update preference columns of their own profile; `qa_logs` and `purchases` are written by the service role only (quota is counted in `_shared/quota.ts`). `supabase/tests/rls_test.mjs` checks this against every migration.
- Deploying the backend: `supabase/DEPLOY.md` (order matters)
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
