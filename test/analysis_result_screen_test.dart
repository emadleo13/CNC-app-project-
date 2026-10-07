import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/app.dart';
import 'package:cnc_assist/core/l10n/app_strings.dart';
import 'package:cnc_assist/features/gcode_analyzer/domain/cnc_dialect.dart';
import 'package:cnc_assist/features/gcode_analyzer/parsers/gcode_parser.dart';
import 'package:cnc_assist/features/gcode_analyzer/presentation/analysis_result_screen.dart';

const _program = '''
G90 G21 G54
T1 M06
G00 X0. Y0.
G43 Z25. H01
G01 Z-1. F100.
M30
''';

Future<void> _pump(WidgetTester tester, String locale, {double width = 411}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width, 891) * 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [localeProvider.overrideWith((ref) => locale)],
    child: MaterialApp(
      locale: Locale(locale),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnalysisResultScreen(analysisData: {
        'gcode': _program,
        'dialect': CncDialect.haas,
        'lines': GcodeParser.parse(_program, CncDialect.haas),
      }),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a flagged line shows why and how to fix it, in Persian',
      (tester) async {
    await _pump(tester, 'fa');
    // Line 5 cuts with the spindle stopped (no M03 after the tool change).
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.text('حرکت برشی در حالی که اسپیندل خاموش است.'), findsOneWidget);
    expect(find.textContaining('M03 یا M04'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary lists the findings and offers the AI review', (tester) async {
    await _pump(tester, 'en');
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Review with AI'), findsOneWidget);
    expect(find.text('Cutting move with the spindle stopped.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['en', 'fa', 'ar', 'ro']) {
    testWidgets('both tabs lay out at 360 dp in $locale', (tester) async {
      await _pump(tester, locale, width: 360);
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
