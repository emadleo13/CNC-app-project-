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

`go_router` with a `ShellRoute` wrapping all three top-level screens inside `MainScaffold`. The result screen for G-code analysis (`/gcode/result`) is a child route that receives analysis data via `state.extra`.

### State management

Riverpod throughout. Providers are generated via `riverpod_generator` — add `@riverpod` annotations and run `build_runner`. No `ChangeNotifier` or `setState` in feature code.

### G-code parsing

`GcodeParser` is a factory that selects between `HaasParser` and `SinumerikParser` (both extend `BaseParser`). Auto-detection inspects the raw G-code string. `BaseParser.parse()` tokenizes lines and delegates validation to the dialect-specific subclass via `validateLine()`, `knownGCodes()`, and `knownMCodes()`.

### Feed/Speed calculator

`MillingCalculator.calculate()` in `domain/calculators/` takes a `CalculatorInput` + `MaterialSpec` and returns `CutParameters`. Material data is loaded lazily from `assets/data/materials.json` by `MaterialsRepository` (in-memory cache after first load). RPM formula: metric `(Vc×1000)/(π×D)`, imperial `(SFM×3.82)/D`.

### Backend (Supabase)

- Auth → auto-creates a `profiles` row via a DB trigger
- Edge Functions hold server-side secrets (Anthropic API key for Q&A, Pinecone for vector search) — these are **never** in the Flutter app
- RLS is enabled on all tables; every policy gates on `auth.uid()`
- Local offline storage uses Hive + `flutter_secure_storage`

## Environment setup

Copy `.env.example` to `.env` and fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`. The Anthropic and Pinecone keys live only in Supabase Dashboard → Edge Functions → Secrets.

## Code generation note

`freezed` and `json_serializable` models require generated `.freezed.dart` / `.g.dart` files. After adding or modifying annotated classes, always re-run `build_runner`.

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
- **`tools/post_social.py`** → posts the Facebook and LinkedIn blocks via API, run by
  `.github/workflows/daily-post.yml`. Credentials come from GitHub repository secrets and must
  never be committed. See `marketing/automation-setup.md`.
- **`tools/listing.py`** → prints one language's Play Console fields with live character counts
  against the 30 / 80 / 4000 limits. Source of truth is `docs/store-listing.md`.

A scheduled cloud agent runs `daily_promo.py` every morning, rewrites the draft into natural
prose, and pushes. It is told never to alter technical content — alarm codes, causes, fixes,
syntax and warnings are machine-safety information and are copied verbatim from the JSON.
Keep that constraint in any prompt that touches this content.
