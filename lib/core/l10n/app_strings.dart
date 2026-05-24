import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'strings_en.dart';
import 'strings_ro.dart';

abstract class AppStrings {
  // Navigation
  String get navCalculator;
  String get navGcode;
  String get navKnowledge;
  String get navSettings;

  // Calculator screen
  String get calculatorTitle;
  String get sectionMaterial;
  String get sectionTool;
  String get sectionCutParams;
  String get selectMaterial;
  String get chooseDots;
  String get labelDiameter;
  String get labelFlutes;
  String get labelDoc;
  String get labelWoc;
  String get labelToolMaterial;
  String get labelOperation;
  String get toolMaterialCarbide;
  String get toolMaterialHss;
  String get operationRough;
  String get operationFinish;
  String get btnCalculate;
  String get resultTitle;
  String get resultRpm;
  String get resultFeedRate;
  String get resultChipLoad;
  String get resultMrr;
  String get resultCuttingSpeed;
  String get resultCoolant;
  String get coolantRequired;
  String get coolantOptional;
  String get unitMm;
  String get unitInch;

  // G-code analyzer
  String get gcodeTitle;
  String get gcodeUpload;
  String get gcodeController;
  String get gcodeAuto;
  String get gcodeDetected;
  String get gcodeLabel;
  String get gcodeAnalyzeBtn;
  String get gcodeEmptySnack;
  String get gcodeFileError;
  String get gcodeViewTab;
  String get gcodeSummaryTab;
  String get gcodeStatController;
  String get gcodeStatStats;
  String get gcodeStatErrors;
  String get gcodeStatWarnings;
  String get gcodeNoIssues;
  String get gcodeIssuesOnly;
  String get gcodeCopied;
  String get gcodeCopyTooltip;
  String get gcodeLines;
  String get gcodeErrors;
  String get gcodeWarnings;

  // Knowledge base — Q&A chat
  String get kbTitle;
  String get kbEmptyTitle;
  String get kbEmptySubtitle;
  String get kbInputHint;
  String get kbPlaceholderReply;

  // Knowledge base — Error reference
  String get errRefTitle;
  String get errRefSearchHint;
  String get errRefFilterAll;
  String get errRefFilterHaas;
  String get errRefFilterSiemens;
  String get errRefNoResults;
  String get errRefCauses;
  String get errRefSolutions;
  String get errRefSeverityInfo;
  String get errRefSeverityWarning;
  String get errRefSeverityError;
  String get errRefSeverityCritical;

  // Settings
  String get settingsTitle;
  String get settingsLanguage;
  String get settingsLanguageEn;
  String get settingsLanguageRo;
  String get settingsUnits;
  String get settingsUnitsMetric;
  String get settingsUnitsImperial;
  String get settingsDialect;
  String get settingsApiKey;
  String get settingsApiKeyHint;
  String get settingsApiKeyDesc;
  String get settingsSaved;
  String get settingsAbout;
  String get settingsVersion;
  String get settingsTheme;
  String get settingsThemeDark;

  // History
  String get navHistory;
  String get historyTitle;
  String get historyCalculations;
  String get historyAnalyses;
  String get historyEmpty;
  String get historyEmptyDesc;
  String get historySave;
  String get historySaved;
  String get historyDeleteAll;
  String get historyConfirmClear;

  // Common
  String get commonCancel;
  String get commonSave;
  String get commonClear;
  String get commonError;
  String get commonLoading;
}

// Locale provider
final localeProvider = StateProvider<String>((ref) => 'en');

// Default calculator units: 'metric' | 'imperial'
final defaultUnitsProvider = StateProvider<String>((ref) => 'metric');

// Default G-code dialect: 'haas' | 'sinumerik' | 'generic'
final defaultDialectProvider = StateProvider<String>((ref) => 'haas');

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return locale == 'ro' ? AppStringsRo() : AppStringsEn();
});

// BuildContext extension for convenience
extension AppStringsContext on BuildContext {
  AppStrings get s => _currentStrings;
}

AppStrings _currentStrings = AppStringsEn();

void updateStrings(AppStrings strings) {
  _currentStrings = strings;
}
