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
  @override String get errRefFilterAll      => 'All';
  @override String get errRefFilterHaas     => 'Haas';
  @override String get errRefFilterSiemens  => 'Siemens';
  @override String get errRefNoResults      => 'No alarms found';
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
}
