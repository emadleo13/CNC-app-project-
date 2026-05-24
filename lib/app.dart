import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class CncAssistApp extends ConsumerWidget {
  const CncAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    updateStrings(strings);
    return MaterialApp.router(
      title: 'CNC Assist',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
