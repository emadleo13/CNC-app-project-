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
