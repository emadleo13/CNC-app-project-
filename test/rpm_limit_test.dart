import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/l10n/app_strings.dart';
import 'package:cnc_assist/core/widgets/calc_widgets.dart';
import 'package:cnc_assist/features/turning/presentation/turning_screen.dart';

void main() {
  Future<void> calculate(WidgetTester tester, int maxRpm) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(411, 891) * 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [maxRpmProvider.overrideWith((ref) => maxRpm)],
      child: const MaterialApp(home: TurningScreen()),
    ));
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
  }

  testWidgets('turning result says when the machine limit capped the RPM', (tester) async {
    // Defaults: Ø50 at 200 m/min → 1273 RPM.
    await calculate(tester, 1000);
    expect(find.byType(RpmLimitNote), findsOneWidget);
    expect(find.textContaining('1000 RPM'), findsOneWidget);
    expect(find.textContaining('1273 RPM'), findsOneWidget);
  });

  testWidgets('no note when the machine can reach the RPM', (tester) async {
    await calculate(tester, 0);
    expect(find.byType(RpmLimitNote), findsNothing);
  });
}
