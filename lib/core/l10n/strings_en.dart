import 'app_strings.dart';

class AppStringsEn implements AppStrings {
  @override String get navCalculator       => 'Calculator';
  @override String get navGcode            => 'G-Code';
  @override String get navKnowledge        => 'Knowledge';
  @override String get navSettings         => 'Settings';

  @override String get calculatorTitle     => 'Feed & Speed Calculator';
  @override String get sectionMaterial     => 'MATERIAL';
  @override String get sectionTool         => 'TOOL';
  @override String get sectionCutParams    => 'CUT PARAMETERS';
  @override String get selectMaterial      => 'Select material';
  @override String get chooseDots          => 'Choose...';
  @override String get labelDiameter       => 'Diameter';
  @override String get labelFlutes         => 'Flutes';
  @override String get labelDoc            => 'Depth of Cut';
  @override String get labelWoc            => 'Width of Cut';
  @override String get labelToolMaterial   => 'Material';
  @override String get labelOperation      => 'Operation';
  @override String get toolMaterialCarbide => 'Carbide';
  @override String get toolMaterialHss     => 'HSS';
  @override String get operationRough      => 'Rough';
  @override String get operationFinish     => 'Finish';
  @override String get btnCalculate        => 'Calculate';
  @override String get resultTitle         => 'Results';
  @override String get resultRpm           => 'RPM';
  @override String get resultFeedRate      => 'Feed Rate';
  @override String get resultChipLoad      => 'Chip Load';
  @override String get resultMrr           => 'MRR';
  @override String get resultCuttingSpeed  => 'Cutting Speed';
  @override String get resultCoolant       => 'Coolant';
  @override String get coolantRequired     => 'Required';
  @override String get coolantOptional     => 'Optional';
  @override String get unitMm              => 'mm';
  @override String get unitInch            => 'inch';

  @override String get gcodeTitle          => 'G-Code Analyzer';
  @override String get gcodeUpload         => 'Upload';
  @override String get gcodeController     => 'CONTROLLER';
  @override String get gcodeAuto           => 'Auto';
  @override String get gcodeDetected       => 'Detected';
  @override String get gcodeLabel          => 'G-CODE';
  @override String get gcodeAnalyzeBtn     => 'Analyze G-Code';
  @override String get gcodeEmptySnack     => 'Please enter or upload G-code first.';
  @override String get gcodeFileError      => 'Failed to read file';
  @override String get gcodeViewTab        => 'G-Code View';
  @override String get gcodeSummaryTab     => 'Summary';
  @override String get gcodeStatController => 'Controller';
  @override String get gcodeStatStats      => 'Statistics';
  @override String get gcodeStatErrors     => 'Errors';
  @override String get gcodeStatWarnings   => 'Warnings';
  @override String get gcodeNoIssues       => 'No issues found';
  @override String get gcodeIssuesOnly     => 'Issues only';
  @override String get gcodeCopied         => 'G-code copied';
  @override String get gcodeCopyTooltip    => 'Copy G-code';
  @override String get gcodeLines          => 'lines';
  @override String get gcodeErrors         => 'errors';
  @override String get gcodeWarnings       => 'warnings';

  @override String get kbTitle             => 'CNC Knowledge Base';
  @override String get kbEmptyTitle        => 'Ask any CNC question';
  @override String get kbEmptySubtitle     => 'G-code, Sinumerik cycles, feeds & speeds,\ntroubleshooting, and more.';
  @override String get kbInputHint         => 'Ask a CNC question...';
  @override String get kbPlaceholderReply  =>
      'To enable AI answers, add your Claude API key in Settings.\n\n'
      'The Knowledge Base uses Claude to answer CNC questions about G-code, '
      'machining parameters, Sinumerik cycles, and more.';

  @override String get errRefTitle          => 'Error Reference';
  @override String get errRefSearchHint     => 'Search alarm code or keyword...';
  @override String get errRefFilterAll        => 'All';
  @override String get errRefFilterHaas       => 'Haas';
  @override String get errRefFilterSiemens    => 'Siemens';
  @override String get errRefFilterFanuc      => 'FANUC';
  @override String get errRefFilterHeidenhain => 'Heidenhain';
  @override String get errRefNoResults        => 'No alarms found';
  @override String get errRefCauses         => 'Possible Causes';
  @override String get errRefSolutions      => 'Solutions';
  @override String get errRefSeverityInfo     => 'INFO';
  @override String get errRefSeverityWarning  => 'WARNING';
  @override String get errRefSeverityError    => 'ERROR';
  @override String get errRefSeverityCritical => 'CRITICAL';

  @override String get settingsTitle        => 'Settings';
  @override String get settingsLanguage     => 'Language';
  @override String get settingsLanguageEn   => 'English';
  @override String get settingsLanguageRo   => 'Română';
  @override String get settingsUnits        => 'Default Units';
  @override String get settingsUnitsMetric  => 'Metric (mm)';
  @override String get settingsUnitsImperial=> 'Imperial (inch)';
  @override String get settingsDialect      => 'Default CNC Dialect';
  @override String get settingsApiKey       => 'Claude API Key';
  @override String get settingsApiKeyHint   => 'sk-ant-...';
  @override String get settingsApiKeyDesc   =>
      'Your key is stored securely on this device only. '
      'It is used only for the Knowledge Base feature.';
  @override String get settingsSaved        => 'Settings saved';
  @override String get settingsAbout        => 'About';
  @override String get settingsVersion      => 'Version 1.0.0';
  @override String get settingsTheme        => 'Theme';
  @override String get settingsThemeDark    => 'Dark (Industrial)';

  @override String get navHistory            => 'History';
  @override String get historyTitle          => 'History';
  @override String get historyCalculations   => 'Calculations';
  @override String get historyAnalyses       => 'Analyses';
  @override String get historyEmpty          => 'No saved items yet';
  @override String get historyEmptyDesc      => 'Save calculations and G-code analyses\nto access them here.';
  @override String get historySave           => 'Save';
  @override String get historySaved          => 'Saved to history';
  @override String get historyDeleteAll      => 'Clear all';
  @override String get historyConfirmClear   => 'This will delete all saved items in this tab.';

  @override String get commonCancel         => 'Cancel';
  @override String get commonSave           => 'Save';
  @override String get commonClear          => 'Clear';
  @override String get commonError          => 'Error';
  @override String get commonLoading        => 'Loading...';

  @override String get imgPickSource             => 'Select Image Source';
  @override String get imgPickCamera             => 'Camera';
  @override String get imgPickGallery            => 'Gallery';
  @override String get imgAttached               => 'Image attached';
  @override String get imgPickError              => 'Failed to pick image';

  @override String get gcodeFromDrawing          => 'From Drawing';
  @override String get gcodeFromDrawingHint      => 'Upload a technical drawing or part photo to generate G-code';
  @override String get gcodeFromDrawingGenerating => 'Analyzing drawing...';
  @override String get gcodeFromDrawingError     => 'Failed to generate G-code from drawing';

  // Phase 1 — Usage / Quota
  @override String get proFreeLabel        => 'Free';
  @override String get proProLabel         => 'Pro';
  @override String get proQuestionsLeft    => 'questions left this month';
  @override String get proUnlimited        => 'Unlimited';
  @override String get proLimitTitle       => 'Monthly Limit Reached';
  @override String get proLimitMsg         => 'You\'ve used all 10 free AI questions this month.\nUpgrade to Pro for unlimited access.';
  @override String get proUpgradeBtn       => 'Upgrade to Pro';
  @override String get proLaterBtn         => 'Not Now';
  @override String get proUsageOf          => 'of';

  // Phase 2 — Subscription
  @override String get subTitle            => 'CNC Assist Pro';
  @override String get subSubtitle         => 'Unlock unlimited access';
  @override String get subMonthly          => '\$19 / month';
  @override String get subFeatureUnlimited => 'Unlimited AI questions';
  @override String get subFeatureSetup     => 'Setup Sheet Generator';
  @override String get subFeatureTooling   => 'Tooling Recommendations';
  @override String get subFeaturePdf       => 'PDF Drawing Analyzer';
  @override String get subSubscribeBtn     => 'Subscribe Now';
  @override String get subRestoreBtn       => 'Restore Purchase';
  @override String get subCurrentPlan      => 'Current Plan';
  @override String get subManageBtn        => 'Manage Subscription';
  @override String get subLoading          => 'Processing...';
  @override String get subError            => 'Purchase failed. Please try again.';
  @override String get subSuccess          => 'Welcome to CNC Assist Pro!';
  @override String get subNotAvailable     => 'Purchases not available on this device.';

  // Phase 3 — Setup Sheet
  @override String get setupSheetTitle     => 'Setup Sheet';
  @override String get setupSheetBtn       => 'Generate Setup Sheet';
  @override String get setupSheetShare     => 'Share / Print';
  @override String get setupSheetDate      => 'Date';
  @override String get setupSheetProOnly   => 'Pro feature — upgrade to generate setup sheets';

  // Phase 4 — Tooling Recs
  @override String get toolingTitle        => 'Tooling Recommendations';
  @override String get toolingBtn          => 'Get Tooling Recommendations';
  @override String get toolingLoading      => 'Analyzing parameters...';
  @override String get toolingProOnly      => 'Pro feature — upgrade to get tooling recommendations';

  // Phase 5 — PDF Analyzer
  @override String get pdfTitle            => 'PDF Drawing Analyzer';
  @override String get pdfBtn              => 'Analyze PDF Drawing';
  @override String get pdfLoading          => 'Analyzing PDF...';
  @override String get pdfPickBtn          => 'Select PDF File';
  @override String get pdfProOnly          => 'Pro feature — upgrade to analyze PDF drawings';
  @override String get pdfError            => 'Failed to analyze PDF';
  @override String get pdfTooLarge         => 'PDF is too large (max 10MB)';

  // Settings — Subscription
  @override String get settingsSubscription => 'Subscription';
  @override String get settingsFreePlan     => 'Free Plan · 10 AI questions/month';
  @override String get settingsProPlan      => 'Pro Plan · Unlimited access';
  @override String get settingsUpgradePro   => 'Upgrade to Pro';

  // Language names
  @override String get settingsLanguageFa  => 'فارسی';
  @override String get settingsLanguageAr  => 'العربية';

  // G-code reference
  @override String get gcodeRefTitle       => 'G-Code Reference';
  @override String get gcodeRefSearchHint  => 'Search code or keyword…';
  @override String get gcodeRefFilterAll   => 'All';
  @override String get gcodeRefNoResults   => 'No codes found';
  @override String get gcodeRefSyntax      => 'Syntax';
  @override String get gcodeRefCount       => 'codes';

  // Help
  @override String get helpBtnLabel => 'How to use?';

  @override String get helpCalcTitle => 'Feed & Speed Calculator';
  @override List<String> get helpCalcSteps => [
    'Select a material from the list (steel, aluminum, titanium, etc.).',
    'Enter tool diameter and number of flutes, then set depth of cut and width of cut.',
    'Choose tool material (Carbide or HSS) and operation type (Roughing or Finishing).',
    'Tap Calculate — RPM, Feed Rate, Chip Load, and MRR are shown instantly.\nTap Save to store the result in History.',
  ];

  @override String get helpGcodeTitle => 'G-Code Analyzer';
  @override List<String> get helpGcodeSteps => [
    'Paste G-code into the text box, or tap Upload to load a .nc / .txt / .mpf file.',
    'Select controller type (Haas or Sinumerik) or leave on Auto — the app detects it automatically.',
    'Tap Analyze G-Code to run the check.',
    'Lines highlighted in red have errors; yellow lines have warnings. Tap any line for details.',
  ];

  @override String get helpKbTitle => 'CNC Knowledge Base';
  @override List<String> get helpKbSteps => [
    'Type any CNC question (G-code, speeds, machining troubleshooting) and send.',
    'The AI (Claude) answers using CNC machining knowledge.',
    'Free plan: 10 questions per month. Upgrade to Pro for unlimited access.',
    'Tap the book icon for the G-Code Reference, or the alarm icon for the Error Reference.',
  ];

  @override String get helpGcodeRefTitle => 'G-Code Reference';
  @override List<String> get helpGcodeRefSteps => [
    'Browse 270+ G and M codes for Haas, Siemens, FANUC, and Heidenhain controllers.',
    'Use the brand chips (Haas / Siemens / FANUC / Heidenhain) to filter by controller.',
    'Type in the search box to find a code or keyword instantly.',
    'Tap any code to see the full description, syntax example, and safety warnings.',
  ];

  @override String get helpErrRefTitle => 'Alarm & Error Reference';
  @override List<String> get helpErrRefSteps => [
    'Search by alarm number or keyword (e.g. "spindle" or "450").',
    'Use the brand filter to narrow results to your machine controller.',
    'Tap any alarm to see possible causes and step-by-step solutions.',
  ];

  @override String get helpHistoryTitle => 'History';
  @override List<String> get helpHistorySteps => [
    'Your saved calculations and G-code analyses are stored here.',
    'After calculating, tap Save in the results panel to add an entry.',
    'After analyzing G-code, tap Save in the summary tab.',
    'Tap any entry to view full details; swipe left to delete.',
  ];
}
