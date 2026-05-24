import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routing/route_names.dart';
import '../theme/app_colors.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RouteNames.gcodeAnalyzer)) return 1;
    if (location.startsWith(RouteNames.knowledgeBase)) return 2;
    if (location.startsWith(RouteNames.history))       return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: null,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) {
            switch (index) {
              case 0: context.go(RouteNames.calculator);
              case 1: context.go(RouteNames.gcodeAnalyzer);
              case 2: context.go(RouteNames.knowledgeBase);
              case 3: context.go(RouteNames.history);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.speed_outlined),
              activeIcon: const Icon(Icons.speed),
              label: s.navCalculator,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.code_outlined),
              activeIcon: const Icon(Icons.code),
              label: s.navGcode,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school),
              label: s.navKnowledge,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history),
              label: s.navHistory,
            ),
          ],
        ),
      ),
    );
  }
}
