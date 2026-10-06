import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

/// Languages the app ships strings for. Setting [MaterialApp.locale] from this
/// list is what makes Persian and Arabic lay out right-to-left: MaterialApp's
/// own Localizations widget sets the Directionality for everything below it,
/// so a Directionality wrapped around the app has no effect.
const supportedAppLocales = [
  Locale('en'),
  Locale('ro'),
  Locale('fa'),
  Locale('ar'),
];

const _localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class CncAssistApp extends ConsumerWidget {
  const CncAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings        = ref.watch(appStringsProvider);
    final locale         = Locale(ref.watch(localeProvider));
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    updateStrings(strings);

    return onboardingSeen
        ? MaterialApp.router(
            title:        'CNC Assist',
            theme:        AppTheme.dark,
            themeMode:    ThemeMode.dark,
            locale:       locale,
            supportedLocales:       supportedAppLocales,
            localizationsDelegates: _localizationsDelegates,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          )
        : MaterialApp(
            title:     'CNC Assist',
            theme:     AppTheme.dark,
            themeMode: ThemeMode.dark,
            locale:    locale,
            supportedLocales:       supportedAppLocales,
            localizationsDelegates: _localizationsDelegates,
            debugShowCheckedModeBanner: false,
            home:      const OnboardingScreen(),
          );
  }
}
