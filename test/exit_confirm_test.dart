import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cnc_assist/core/widgets/main_scaffold.dart';

/// The app's shell layout: four tabs, each with an inner screen.
GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainScaffold(navigationShell: shell),
      branches: [
        for (final p in ['/a', '/b', '/c', '/d'])
          StatefulShellBranch(routes: [
            GoRoute(
              path: p,
              builder: (_, _) => Text('root $p'),
              routes: [GoRoute(path: 'inner', builder: (_, _) => Text('inner $p'))],
            ),
          ]),
      ],
    ),
  ],
);

/// The Android Back button, as the platform sends it.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<String> platformCalls;
  late GoRouter router;

  Future<void> start(WidgetTester tester) async {
    platformCalls = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call.method);
        return null;
      },
    );
    router = _router();
    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
  }

  testWidgets('Back on a tab\'s first screen asks; No stays on it', (tester) async {
    await start(tester);
    await _pressBack(tester);
    expect(find.text('Exit CNC Assist?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Exit CNC Assist?'), findsNothing);
    expect(find.text('root /a'), findsOneWidget);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('Yes closes the app', (tester) async {
    await start(tester);
    await _pressBack(tester);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(platformCalls, contains('SystemNavigator.pop'));
  });

  testWidgets('Back on an inner screen just goes back, without asking', (tester) async {
    await start(tester);
    router.go('/b/inner');
    await tester.pumpAndSettle();
    expect(find.text('inner /b'), findsOneWidget);

    await _pressBack(tester);
    expect(find.text('Exit CNC Assist?'), findsNothing);
    expect(find.text('root /b'), findsOneWidget);
  });
}
