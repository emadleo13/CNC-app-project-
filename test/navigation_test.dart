import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/routing/app_router.dart';
import 'package:cnc_assist/features/gcode_analyzer/presentation/gcode_input_screen.dart';
import 'package:cnc_assist/features/tools/presentation/tools_hub_screen.dart';

void main() {
  testWidgets('switching tabs keeps each tab and raises no errors',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(411, 891) * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: appRouter)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ToolsHubScreen), findsOneWidget);

    // Open the G-code tab and type a program.
    await tester.tap(find.text('G-Code'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final editor = find.descendant(
      of: find.byType(GcodeInputScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(editor, 'G0 X0 Y0\nG1 Z-1. F100.');
    await tester.pump();

    // Leave for the tools tab and come back: the program is still there.
    await tester.tap(find.text('Calculator'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('G-Code'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<TextField>(editor).controller!.text,
      'G0 X0 Y0\nG1 Z-1. F100.',
    );
  });
}
