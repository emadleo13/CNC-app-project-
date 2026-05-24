import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface:          AppColors.surface,
        primary:          AppColors.primary,
        error:            AppColors.errorRed,
        onSurface:        AppColors.textPrimary,
        onPrimary:        AppColors.background,
        surfaceContainerHighest: AppColors.surfaceAlt,
        outline:          AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: const CardThemeData(
        color:       AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color:      AppColors.textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrainsMono',
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:           Colors.transparent,
          statusBarIconBrightness:  Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:          AppColors.surface,
        selectedItemColor:        AppColors.primary,
        unselectedItemColor:      AppColors.textMuted,
        type:                     BottomNavigationBarType.fixed,
        elevation:                0,
        selectedLabelStyle:       TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:     TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 1,
        space:     1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AppColors.surfaceAlt,
        border:         OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.errorRed),
        ),
        labelStyle:  const TextStyle(color: AppColors.textSecondary),
        hintStyle:   const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  AppColors.primary,
          foregroundColor:  AppColors.background,
          elevation:        0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side:            const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor:    AppColors.surfaceAlt,
        labelStyle:         TextStyle(color: AppColors.textPrimary, fontSize: 13),
        side:               BorderSide(color: AppColors.border),
        shape:              StadiumBorder(),
        padding:            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge:     TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall:     TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge:      TextStyle(color: AppColors.textPrimary),
        bodyMedium:     TextStyle(color: AppColors.textPrimary),
        bodySmall:      TextStyle(color: AppColors.textSecondary),
        labelLarge:     TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelMedium:    TextStyle(color: AppColors.textSecondary),
        labelSmall:     TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}
