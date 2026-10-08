import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/widgets/ai_answer.dart';

const _persianAnswer = '''
برای فولاد ۴۱۴۰ با فرز **Ø10** و ۴ پر:

- **Vc**: 80 تا 100 m/min
- **دور**: RPM = (Vc × 1000) / (π × D)

برنامهٔ نمونه:
```
G01 Z-2. F200.
X50.
```
از `G43 H01` استفاده کنید.

![diagram](https://example.com/x.png)
''';

Widget _host(String locale, Widget child) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [
    Locale('en'),
    Locale('fa'),
    Locale('ar'),
    Locale('ro'),
  ],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360, 740) * 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('answerDirection', () {
    test('Persian full of Latin terms still reads right to left', () {
      expect(answerDirection(_persianAnswer), TextDirection.rtl);
    });
    test('English reads left to right, also in the Persian app', () {
      expect(
        answerDirection('Use **G43 H01** after the tool change.'),
        TextDirection.ltr,
      );
    });
    test('code alone decides nothing', () {
      expect(answerDirection('```\nG01 X10.\n```'), isNull);
    });
  });

  group('bidiSafe', () {
    test('inline code is isolated left to right', () {
      expect(
        bidiSafe('عمق `Z-2.` است', rtl: true),
        'عمق `\u2066Z-2.\u2069` است',
      );
    });
    test('number ranges keep their order in right-to-left answers', () {
      expect(
        bidiSafe('ae (شعاعی): 0.3-0.5 mm و ۸۰ - ۱۰۰ m/min، 10×20', rtl: true),
        'ae (شعاعی): \u20660.3-0.5\u2069 mm و \u2066۸۰ - ۱۰۰\u2069 m/min، \u206610×20\u2069',
      );
      expect(bidiSafe('Vc 80-100 m/min', rtl: false), 'Vc 80-100 m/min');
      expect(bidiSafe('فقط 2500 rpm', rtl: true), 'فقط 2500 rpm');
    });
    test('code blocks and inline code are left as they are', () {
      const block = '```\nG01 X10-5 `Z-2.`\n```';
      expect(bidiSafe(block, rtl: true), block);
      expect(bidiSafe('`X1-2`', rtl: true), '`\u2066X1-2\u2069`');
    });
  });

  // Measured on screen: before bidiSafe all four came out reversed
  // ("0.5-0.3", "30×50"), a wrong number in a machining answer.
  test('number ranges inside Persian text show in order', () {
    for (final (line, first, second) in [
      ('ae (شعاعی): 0.3-0.5 mm', '3', '5'),
      ('عمق برش ۰.۲ - ۰.۵ میلی‌متر', '۲', '۵'),
      ('ابعاد قطعه 50×30 است', '5', '3'),
      ('تاریخ: 2026-10-08', '6', '8'),
    ]) {
      final shown = bidiSafe(line, rtl: true);
      final p = TextPainter(
        text: TextSpan(text: shown, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.rtl,
      )..layout();
      double x(String ch) => p
          .getOffsetForCaret(TextPosition(offset: shown.indexOf(ch)), Rect.zero)
          .dx;
      expect(x(first) < x(second), isTrue, reason: line);
      p.dispose();
    }
  });

  for (final locale in ['fa', 'en']) {
    testWidgets('a Markdown answer renders on a small phone in $locale', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_host(locale, const AiAnswer(_persianAnswer)));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // The prose reads right to left, whatever the app language.
      final prose = tester.element(find.byType(AiAnswer));
      expect(
        Directionality.of(
          tester.element(
            find
                .descendant(
                  of: find.byWidget(prose.widget),
                  matching: find.byType(Directionality),
                )
                .first,
          ),
        ),
        TextDirection.rtl,
      );

      // G-code stays left to right and in order.
      final code = find.widgetWithText(CodeBlock, 'G01 Z-2. F200.\nX50.');
      expect(code, findsOneWidget);
      final codeText = tester.element(
        find.descendant(of: code, matching: find.byType(SelectableText)),
      );
      expect(Directionality.of(codeText), TextDirection.ltr);

      // The image is not fetched.
      expect(find.byType(Image), findsNothing);
    });
  }

  testWidgets('the copy button copies the code block alone', (tester) async {
    _phone(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var notified = false;
    await tester.pumpWidget(
      _host(
        'fa',
        AiAnswer(_persianAnswer, onCodeCopied: () => notified = true),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(CodeBlock),
        matching: find.byIcon(Icons.copy_outlined),
      ),
    );
    await tester.pump();
    expect(copied, 'G01 Z-2. F200.\nX50.');
    expect(notified, isTrue);
  });
}
