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
    final locale  = ref.watch(localeProvider);
    updateStrings(strings);

    // RTL for Persian and Arabic
    final textDir = (locale == 'fa' || locale == 'ar')
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDir,
      child: MaterialApp.router(
        title:       'CNC Assist',
        theme:       AppTheme.dark,
        themeMode:   ThemeMode.dark,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
