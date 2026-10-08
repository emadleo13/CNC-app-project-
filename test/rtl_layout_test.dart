import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/app.dart';
import 'package:cnc_assist/core/l10n/app_strings.dart';
import 'package:cnc_assist/features/converters/presentation/converters_screen.dart';
import 'package:cnc_assist/features/converters/presentation/hardness_screen.dart';
import 'package:cnc_assist/features/coordinates/presentation/arc_screen.dart';
import 'package:cnc_assist/features/coordinates/presentation/gcode_gen_screen.dart';
import 'package:cnc_assist/features/coordinates/presentation/taper_screen.dart';
import 'package:cnc_assist/features/drilling/presentation/drilling_screen.dart';
import 'package:cnc_assist/features/feed_speed/presentation/calculator_screen.dart';
import 'package:cnc_assist/features/gcode_analyzer/presentation/gcode_input_screen.dart';
import 'package:cnc_assist/features/precision/presentation/part_weight_screen.dart';
import 'package:cnc_assist/features/precision/presentation/true_position_screen.dart';
import 'package:cnc_assist/features/tools/presentation/tools_hub_screen.dart';
import 'package:cnc_assist/features/turning/presentation/turning_screen.dart';

/// Hosts [child] the way the app does: locale from [localeProvider], the
/// Flutter localization delegates, and a phone-sized surface.
Widget _host(String locale, Widget child) => ProviderScope(
  overrides: [localeProvider.overrideWith((ref) => locale)],
  child: MaterialApp(
    locale: Locale(locale),
    supportedLocales: supportedAppLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

/// Simulates a phone screen of [size] logical pixels. Unlike
/// `setSurfaceSize`, this also updates MediaQuery, which screens read to pick
/// a compact layout.
void _phone(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('app direction follows the chosen language', () {
    for (final (locale, expected) in [
      ('en', TextDirection.ltr),
      ('ro', TextDirection.ltr),
      ('fa', TextDirection.rtl),
      ('ar', TextDirection.rtl),
    ]) {
      testWidgets('$locale → ${expected.name}', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localeProvider.overrideWith((ref) => locale)],
            child: const CncAssistApp(),
          ),
        );
        await tester.pump();
        final ctx = tester.element(find.byType(Scaffold).first);
        expect(Directionality.of(ctx), expected);
      });
    }
  });

  testWidgets('G-code editor stays left-to-right in Persian', (tester) async {
    _phone(tester, const Size(411, 891));
    await tester.pumpWidget(_host('fa', const GcodeInputScreen()));
    await tester.pump();
    final screen = tester.element(find.byType(GcodeInputScreen));
    final editor = tester.element(find.byType(TextField));
    expect(Directionality.of(screen), TextDirection.rtl);
    expect(Directionality.of(editor), TextDirection.ltr);
  });

  // Every screen that needs no backend renders in each language on a small
  // phone without layout exceptions (overflow, unbounded constraints).
  final screens = <String, Widget>{
    'milling': const CalculatorScreen(),
    'turning': const TurningScreen(),
    'drilling': const DrillingScreen(),
    'converters': const ConvertersScreen(),
    'hardness': const HardnessScreen(),
    'taper': const TaperScreen(),
    'arc': const ArcScreen(),
    'gcode-gen': const GcodeGenScreen(),
    'true-position': const TruePositionScreen(),
    'weight': const PartWeightScreen(),
    'gcode-input': const GcodeInputScreen(),
  };
  for (final locale in ['en', 'fa', 'ar', 'ro']) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name renders in $locale', (tester) async {
        _phone(tester, const Size(360, 740));
        await tester.pumpWidget(_host(locale, screen));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Every tool card, not only the ones on screen first: which cards are laid
  // out depends on the greeting and the tip of the day, so a card that
  // overflowed only showed up at certain hours. Large system font included.
  for (final locale in ['en', 'fa', 'ar', 'ro']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('tools hub: every card fits in $locale at ${scale}x text', (
        tester,
      ) async {
        _phone(tester, const Size(360, 740));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(_host(locale, const ToolsHubScreen()));
        await tester.pumpAndSettle();
        for (var i = 0; i < 12; i++) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
