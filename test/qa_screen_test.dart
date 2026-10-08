import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/app.dart';
import 'package:cnc_assist/core/l10n/app_strings.dart';
import 'package:cnc_assist/core/l10n/strings_fa.dart';
import 'package:cnc_assist/core/net/edge_functions.dart';
import 'package:cnc_assist/core/widgets/ai_answer.dart';
import 'package:cnc_assist/features/knowledge_base/data/usage_repository.dart';
import 'package:cnc_assist/features/knowledge_base/presentation/qa_screen.dart';

void main() {
  final s = AppStringsFa();
  late List<(String, Map<String, dynamic>)> calls;
  late List<Map<String, dynamic>> replies;

  setUp(() {
    calls = [];
    replies = [];
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(411, 891) * 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => 'fa'),
          usageProvider.overrideWith(
            (ref) async => const UsageStatus(used: 0, limit: 10, isPro: true),
          ),
          edgeInvokerProvider.overrideWithValue((
            String name, {
            Map<String, dynamic>? body,
            Duration timeout = const Duration(seconds: 90),
          }) async {
            calls.add((name, body ?? const {}));
            return replies.removeAt(0);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const QaScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> ask(WidgetTester tester, String question) async {
    final sent = calls.length;
    await tester.enterText(find.byType(TextField), question);
    await tester.tap(find.byIcon(Icons.send));
    for (var i = 0; i < 20 && calls.length == sent; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'follow-up questions carry the conversation; a new chat drops it',
    (tester) async {
      await pumpScreen(tester);

      replies.add({
        'answer': '**جواب اول**',
        'provider': 'free',
        'truncated': false,
      });
      await ask(tester, 'سؤال اول');
      final (name, first) = calls.single;
      expect(name, 'ask-claude');
      expect(first['language'], 'fa');
      expect(first['format'], 'markdown');
      expect(first['clientTimeout'], kAiTimeout.inSeconds);
      expect(first.containsKey('history'), isFalse);
      expect(
        tester.widget<AiAnswer>(find.byType(AiAnswer)).text,
        '**جواب اول**',
      );

      replies.add({'answer': 'جواب دوم', 'truncated': true});
      await ask(tester, 'و دومی؟');
      expect(calls[1].$2['history'], [
        {'role': 'user', 'content': 'سؤال اول'},
        {'role': 'assistant', 'content': '**جواب اول**'},
      ]);
      // A cut-off answer says so.
      expect(find.text(s.kbAnswerCutOff), findsOneWidget);

      await tester.tap(find.text(s.kbNewChat));
      await tester.pump();
      expect(find.byType(AiAnswer), findsNothing);

      replies.add({'answer': 'جواب سوم'});
      await ask(tester, 'موضوع تازه');
      expect(calls[2].$2.containsKey('history'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed answer is not sent back as conversation', (
    tester,
  ) async {
    await pumpScreen(tester);
    replies.add({
      'answer': '',
    }); // the screen treats an empty answer as "AI busy"
    await ask(tester, 'سؤال اول');
    expect(find.text(s.errAiBusy), findsOneWidget);

    replies.add({'answer': 'جواب'});
    await ask(tester, 'دوباره');
    // Only the earlier question: the error notice is not an answer.
    expect(calls[1].$2['history'], isNull);
  });
}
