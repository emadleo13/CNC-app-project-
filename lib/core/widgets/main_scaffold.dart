import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

class MainScaffold extends ConsumerWidget {
  /// The tab navigators, one per bottom-nav destination, kept in an
  /// IndexedStack by [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    // No AnimatedSwitcher here: it kept the outgoing and incoming child in the
    // tree at once, and both held the same keyed Navigator ("Duplicate
    // GlobalKey" on every tab switch).
    //
    // Back on a tab's first screen used to close the app without a word. The
    // tab's own navigator gets Back first, so inner screens (a calculator,
    // the G-code result) still just go back; only leaving the app is asked.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit(context, s)) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: null,
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: AppColors.surfaceContainerLow,
              indicatorColor: AppColors.primary.withValues(alpha: 0.18),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: 24,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              // Tapping the current tab again returns it to its root screen.
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
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
      ),
    );
  }

  /// Yes leaves the app; No, or dismissing the dialog, stays where the user was.
  static Future<bool> _confirmExit(BuildContext context, AppStrings s) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.exitAppTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.commonNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.commonYes),
          ),
        ],
      ),
    );
    return exit ?? false;
  }
}
