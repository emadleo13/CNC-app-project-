import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cnc_assist/core/widgets/calc_widgets.dart';
import 'package:cnc_assist/features/drilling/presentation/drilling_screen.dart';
import 'package:cnc_assist/features/history/domain/saved_calculation.dart';
import 'package:cnc_assist/features/turning/presentation/turning_screen.dart';
import 'helpers/history_boxes.dart';

void main() {
  setUpAll(openHistoryBoxesInMemory);
  setUp(() => Hive.box<SavedCalculation>('calculations').clear());

  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(411, 891) * 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  }

  Future<void> calculate(WidgetTester tester) async {
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
  }

  List<SavedCalculation> saved() => Hive.box<SavedCalculation>('calculations').values.toList();

  testWidgets('a turning result is saved to History by itself, once', (tester) async {
    await open(tester, const TurningScreen());
    await calculate(tester);
    expect(find.byType(SavedToHistoryNote), findsOneWidget);
    expect(saved(), hasLength(1));
    expect(saved().single.kind, CalcKind.turning);
    expect(saved().single.rpm, 1273); // Ø50 at 200 m/min
    expect(saved().single.feedPerRev, 0.2);

    await calculate(tester);
    expect(saved(), hasLength(1), reason: 'the same result again is not a new entry');

    await tester.enterText(find.widgetWithText(TextField, '50'), '40');
    await calculate(tester);
    expect(saved(), hasLength(2));
  });

  testWidgets('a drilling result is saved to History by itself', (tester) async {
    await open(tester, const DrillingScreen());
    await calculate(tester);
    expect(find.byType(SavedToHistoryNote), findsOneWidget);
    expect(saved().single.kind, CalcKind.drilling);
    expect(saved().single.pointAngle, 118);
    expect(saved().single.depth, 30);
  });
}
