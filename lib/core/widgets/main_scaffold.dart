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
      // Cross-fade + subtle scale when switching top-level tabs. Keyed by tab
      // index so navigating into a sub-route within a tab is left untouched
      // (those keep their own push transition).
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex(context)),
          child: child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surfaceContainerLow,
            indicatorColor:  AppColors.primary.withValues(alpha: 0.18),
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600 : FontWeight.normal,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary : AppColors.textMuted,
            )),
            iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary : AppColors.textMuted,
            )),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex(context),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              switch (index) {
                case 0: context.go(RouteNames.calculator);
                case 1: context.go(RouteNames.gcodeAnalyzer);
                case 2: context.go(RouteNames.knowledgeBase);
                case 3: context.go(RouteNames.history);
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.speed_outlined),
                selectedIcon: const Icon(Icons.speed),
                label: s.navCalculator,
              ),
              NavigationDestination(
                icon: const Icon(Icons.code_outlined),
                selectedIcon: const Icon(Icons.code),
                label: s.navGcode,
              ),
              NavigationDestination(
                icon: const Icon(Icons.school_outlined),
                selectedIcon: const Icon(Icons.school),
                label: s.navKnowledge,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: s.navHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
