import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/widgets/calc_widgets.dart';
import 'package:cnc_assist/core/widgets/decimal_input_formatter.dart';

void main() {
  group('DecimalInputFormatter.normalize', () {
    test('decimal comma becomes a point instead of being dropped', () {
      expect(DecimalInputFormatter.normalize('0,15'), '0.15');
      expect(DecimalInputFormatter.parse('0,15'), 0.15);
    });

    test('Persian and Arabic-Indic digits and separators', () {
      expect(DecimalInputFormatter.normalize('۱۲٫۵'), '12.5');
      expect(DecimalInputFormatter.normalize('٣٫٧٥'), '3.75');
      expect(DecimalInputFormatter.normalize('۰،۰۸'), '0.08');
    });

    test('a second separator is rejected, not merged', () {
      expect(DecimalInputFormatter.normalize('1.2.3'), isNull);
      expect(DecimalInputFormatter.normalize('1,234.5'), isNull);
    });

    test('minus only when allowed and only in front', () {
      expect(DecimalInputFormatter.normalize('-25'), '25');
      expect(
        DecimalInputFormatter.normalize('-25', allowNegative: true),
        '-25',
      );
      expect(
        DecimalInputFormatter.normalize('−25', allowNegative: true),
        '-25',
      );
      expect(DecimalInputFormatter.normalize('2-5', allowNegative: true), '25');
    });

    test('letters and spaces are dropped', () {
      expect(DecimalInputFormatter.normalize(' 12 mm'), '12');
    });
  });

  group('CalcNumberField', () {
    Future<(TextEditingController, List<String>)> pump(
      WidgetTester tester, {
      bool allowNegative = false,
    }) async {
      final ctrl = TextEditingController();
      final changes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalcNumberField(
              label: 'Feed',
              controller: ctrl,
              allowNegative: allowNegative,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      return (ctrl, changes);
    }

    testWidgets('"0,15" reaches the calculator as 0.15', (tester) async {
      final (ctrl, changes) = await pump(tester);
      await tester.enterText(find.byType(TextField), '0,15');
      expect(ctrl.text, '0.15');
      expect(double.tryParse(changes.last), 0.15);
    });

    testWidgets('Persian keyboard input is accepted', (tester) async {
      final (ctrl, _) = await pump(tester);
      await tester.enterText(find.byType(TextField), '۱۲٫۵');
      expect(ctrl.text, '12.5');
    });

    testWidgets('typing a second separator keeps the previous value', (
      tester,
    ) async {
      final (ctrl, _) = await pump(tester);
      await tester.enterText(find.byType(TextField), '1.5');
      await tester.enterText(find.byType(TextField), '1.5,');
      expect(ctrl.text, '1.5');
    });

    testWidgets('negative values when allowed', (tester) async {
      final (ctrl, _) = await pump(tester, allowNegative: true);
      await tester.enterText(find.byType(TextField), '-25,5');
      expect(ctrl.text, '-25.5');
    });
  });
}
