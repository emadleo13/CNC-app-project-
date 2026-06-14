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
  @override String get errRefFilterMazak      => 'Mazak';
  @override String get errRefNoResults        => 'No alarms found';
  @override String get errRefCauses         => 'Possible Causes';
  @override String get errRefSolutions      => 'Solutions';
  @override String get errRefSeverityInfo     => 'INFO';
  @override String get errRefSeverityWarning  => 'WARNING';
  @override String get errRefSeverityError    => 'ERROR';
  @override String get errRefSeverityCritical => 'CRITICAL';

  // Knowledge base — G-code program library
  @override String get progLibTitle         => 'G-Code Program Library';
  @override String get progLibSearchHint    => 'Search programs…';
  @override String get progLibFilterAll     => 'All';
  @override String get progLibNoResults     => 'No programs found';
  @override String get progLibCount         => 'programs';
  @override String get progLibCodeLabel     => 'G-CODE';
  @override String get progLibNotesLabel    => 'Tips';
  @override String get progLibCopy          => 'Copy code';
  @override String get progLibCopied        => 'Copied to clipboard';
  @override String get progLibBeginner      => 'Beginner';
  @override String get progLibIntermediate  => 'Intermediate';
  @override String get progLibAdvanced      => 'Advanced';
  @override String get progCatCircles       => 'Circles';
  @override String get progCatPockets       => 'Pockets';
  @override String get progCatDrilling      => 'Drilling';
  @override String get progCatSpirals       => 'Spirals';
  @override String get progCatEngraving     => 'Engraving';
  @override String get progCatContours      => 'Contours';
  @override String get progCatFacing        => 'Facing';
  @override String get progCatTurning       => 'Turning';

  // Knowledge base — CNC guides
  @override String get guidesTitle             => 'CNC Guides';
  @override String get guidesSearchHint        => 'Search guides…';
  @override String get guidesNoResults         => 'No guides found';
  @override String get guideCatMachineBasics   => 'Machine Basics';
  @override String get guideCatAxesCoordinates => 'Axes & Coordinates';
  @override String get guideCatTooling         => 'Tooling';
  @override String get guideCatWorkHolding     => 'Work Holding';
  @override String get guideCatGcodeBasics     => 'G-code Basics';
  @override String get guideCatSpeedsFeeds     => 'Speeds & Feeds';
  @override String get guideCatLatheBasics     => 'Lathe Basics';
  @override String get guideCatSafety          => 'Safety';

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
  @override String get historyEmptyCtaCalc     => 'Start your first calculation';
  @override String get historyEmptyCtaAnalysis => 'Analyze your first program';
  @override String get historySave           => 'Save';
  @override String get historySaved          => 'Saved to history';
  @override String get historyDeleteAll      => 'Clear all';
  @override String get historyConfirmClear   => 'This will delete all saved items in this tab.';

  @override String get commonCancel         => 'Cancel';
  @override String get commonSave           => 'Save';
  @override String get commonClear          => 'Clear';
  @override String get commonCopy           => 'Copy';
  @override String get commonRetry          => 'Retry';
  @override String get subProductUnavailable => 'Live store price unavailable. Check your connection or try again later.';
  @override String get subNeedsPlayStore => 'Purchases work only when the app is installed from Google Play (internal testing or higher) with a tester account. This build was installed via direct distribution.';
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
  @override String get subMonthly          => '\$4.99 / month';
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

  // Support & Contact
  @override String get supportTitle       => 'Support & Contact';
  @override String get supportSubtitle    => 'We are here to help you';
  @override String get supportEmail       => 'Email';
  @override String get supportTelegram    => 'Telegram';
  @override String get supportLinkedIn    => 'LinkedIn';
  @override String get support247         => '24/7 Support Available';
  @override String get supportDeveloper   => 'Developer & Admin';

  // Trust — Subscription
  @override String get subFreeTrial       => '7-Day Free Trial';
  @override String get subGuaranteeTitle  => 'Satisfaction Guaranteed';
  @override String get subGuaranteeMsg    => 'Cancel anytime. Refund within 48 hours if not satisfied.';
  @override String get subCancelAnytime   => 'Cancel anytime · No commitment';

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

  @override String get helpProgLibTitle => 'G-Code Program Library';
  @override List<String> get helpProgLibSteps => [
    'Browse ready-to-run sample programs — circles, pockets, drilling patterns, spirals, engraving, and more.',
    'Use the category chips to filter, or search by title or keyword.',
    'Tap any program to view the full G-code, copy it, and read tips for running it safely.',
  ];

  @override String get helpGuidesTitle => 'How CNC Machines Work';
  @override List<String> get helpGuidesSteps => [
    'Read short guides covering machine basics, axes, tooling, work holding, G-code, and safety.',
    'Use the category chips to jump to a topic, or search by keyword.',
    'Tap any guide to read the full article.',
  ];

  @override String get helpHistoryTitle => 'History';
  @override List<String> get helpHistorySteps => [
    'Your saved calculations and G-code analyses are stored here.',
    'After calculating, tap Save in the results panel to add an entry.',
    'After analyzing G-code, tap Save in the summary tab.',
    'Tap any entry to view full details; swipe left to delete.',
  ];

  // ── Tools Hub ──
  @override String get toolsHubTitle    => 'Machining Tools';
  @override String get quickAccess      => 'Quick access';
  @override String get toolComingSoon   => 'SOON';
  @override String get catMilling       => 'Milling';
  @override String get catTurning       => 'Turning';
  @override String get catDrilling      => 'Drilling & Tapping';
  @override String get catCoordinates   => 'Coordinates & Programs';
  @override String get catConverters    => 'Converters';
  @override String get catReference     => 'Precision & Reference';
  @override String get toolMilling          => 'Milling Feeds & Speeds';
  @override String get toolMillingSub       => 'RPM, feed, chip load, MRR';
  @override String get toolTurning          => 'Turning Feeds & Speeds';
  @override String get toolTurningSub       => 'RPM, feed, cut time';
  @override String get toolDrilling         => 'Drill & Tap';
  @override String get toolDrillingSub      => 'Speeds, cut time, tap drill';
  @override String get toolTaper            => 'Taper Coordinates';
  @override String get toolTaperSub         => 'X/Z with nose-R comp.';
  @override String get toolArc              => 'Arc / Radius';
  @override String get toolArcSub           => 'Tangent & endpoint coords';
  @override String get toolGcodeGen         => 'G-code Generators';
  @override String get toolGcodeGenSub      => 'G76 thread, drill cycles';
  @override String get toolConverters       => 'Speed / Feed Converters';
  @override String get toolConvertersSub    => 'SFM↔RPM, feed/rev↔min';
  @override String get toolHardness         => 'Hardness Conversion';
  @override String get toolHardnessSub      => 'HRC ↔ HB ↔ HV';
  @override String get toolTruePosition     => 'True Position';
  @override String get toolTruePositionSub  => 'GD&T with bonus tol.';
  @override String get toolWeight           => 'Material Weight';
  @override String get toolWeightSub        => '170 materials, 7 shapes';
  @override String get catLearn             => 'Learn & Reference';
  @override String get toolQuiz             => 'Machinist Test';
  @override String get toolQuizSub          => 'Quiz across 7 topics';
  @override String get toolWear             => 'Tool Wear Guide';
  @override String get toolWearSub          => 'Causes & solutions';
  @override String get quizScore            => 'Score';
  @override String get quizRestart          => 'Restart';
  @override String get quizNext             => 'Next';
  @override String get quizFinish           => 'Finish';
  @override String get wearCause            => 'Causes';
  @override String get wearSolution         => 'Solutions';
  @override String get secAdvanced          => 'Advanced (ball-nose)';
  @override String get resCusp              => 'Cusp Height';
  @override String get resChipThin          => 'Chip Thinning ×';
  @override String get labelStepover        => 'Stepover';

  // ── Shared calculator strings ──
  @override String get secInputs        => 'Inputs';
  @override String get sectionTapDrill  => 'Tap Drill';
  @override String get resCutTime       => 'Cut Time';
  @override String get resFeedPerMin    => 'Feed Rate';
  @override String get resTapDrill      => 'Tap Drill Ø';
  @override String get resPointLength   => 'Point Length';
  @override String get resCoordinates   => 'Coordinates';
  @override String get resDeviation     => 'Deviation';
  @override String get resProgram       => 'Program';
  @override String get btnCopy          => 'Copy';
  @override String get btnGenerate      => 'Generate';
  @override String get convTabSpeed     => 'Speed';
  @override String get convTabFeed      => 'Feed';
  @override String get hardEnterValue   => 'Enter a value in any scale';
  @override String get taperWarnNoseR   => 'Nose radius too large for this section — interference.';
  @override String get taperWarnLength  => 'Radius exceeds section length.';

  @override String get onboardSkip   => 'Skip';
  @override String get onboardNext   => 'Next';
  @override String get onboardStart  => 'Get started';
  @override String get onboard1Title => 'Feed & Speed Calculator';
  @override String get onboard1Body  => 'Get precise cutting parameters for any material and tool in seconds.';
  @override String get onboard2Title => 'G-code Analyzer';
  @override String get onboard2Body  => 'Paste or upload a program and spot errors and warnings line by line with color highlighting.';
  @override String get onboard3Title => 'Smart Knowledge Base';
  @override String get onboard3Body  => 'Ask any CNC question and browse a full G & M code reference.';

  @override String get heroHello         => 'Hello';
  @override String get greetingMorning   => 'Good morning 👋';
  @override String get greetingAfternoon => 'Good afternoon 👋';
  @override String get greetingEvening   => 'Good evening 👋';
  @override String get heroPrompt        => 'What do you want to calculate today?';
  @override String get statTools         => 'Tools';
  @override String get statGcodes        => 'G-codes';
  @override String get statErrors        => 'CNC errors';
  @override String get tipOfDayTitle     => 'CNC Tip of the Day';
  @override List<String> get cncTips => const [
    'G43 applies the tool length offset.',
    'G41 is cutter compensation left of the path; G42 is to the right.',
    'M03 spins the spindle clockwise; M04 counter-clockwise.',
    'G90 is absolute positioning; G91 is incremental.',
    'For mild steel, carbide cutting speed is usually 3–4× that of HSS.',
    'Always verify the tool number and its H offset before G43 to avoid a crash.',
    'G54–G59 are the programmable work coordinate systems.',
    'Lowering chip load on small diameters helps prevent tool breakage.',
  ];
  @override String get badgePopular => 'Popular';
  @override String get badgeNew     => 'New';
  @override String get badgePro     => 'Pro';
  @override String get popularQuestions => 'Popular questions';
  @override List<String> get popularQuestionsList => const [
    'What is the difference between G41 and G42?',
    'What is the difference between G90 and G91?',
    'What is the difference between M03 and M04?',
    'How is RPM calculated?',
  ];
  @override String get settingsName     => 'Your name';
  @override String get settingsNameHint => 'For the home greeting';
}
