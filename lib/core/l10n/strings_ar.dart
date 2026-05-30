import 'app_strings.dart';

class AppStringsAr implements AppStrings {
  @override String get navCalculator       => 'الحاسبة';
  @override String get navGcode            => 'الجي-كود';
  @override String get navKnowledge        => 'المعرفة';
  @override String get navSettings         => 'الإعدادات';

  @override String get calculatorTitle     => 'حاسبة التغذية والسرعة';
  @override String get sectionMaterial     => 'المادة';
  @override String get sectionTool         => 'الأداة';
  @override String get sectionCutParams    => 'معاملات القطع';
  @override String get selectMaterial      => 'اختر المادة';
  @override String get chooseDots          => 'اختر...';
  @override String get labelDiameter       => 'القطر';
  @override String get labelFlutes         => 'عدد الأسنان';
  @override String get labelDoc            => 'عمق القطع';
  @override String get labelWoc            => 'عرض القطع';
  @override String get labelToolMaterial   => 'مادة الأداة';
  @override String get labelOperation      => 'العملية';
  @override String get toolMaterialCarbide => 'كربيد';
  @override String get toolMaterialHss     => 'HSS';
  @override String get operationRough      => 'خشنة';
  @override String get operationFinish     => 'تشطيب';
  @override String get btnCalculate        => 'احسب';
  @override String get resultTitle         => 'النتائج';
  @override String get resultRpm           => 'دورة/دقيقة';
  @override String get resultFeedRate      => 'معدل التغذية';
  @override String get resultChipLoad      => 'حمل الرقائق';
  @override String get resultMrr           => 'معدل إزالة المادة';
  @override String get resultCuttingSpeed  => 'سرعة القطع';
  @override String get resultCoolant       => 'سائل التبريد';
  @override String get coolantRequired     => 'مطلوب';
  @override String get coolantOptional     => 'اختياري';
  @override String get unitMm              => 'mm';
  @override String get unitInch            => 'بوصة';

  @override String get gcodeTitle          => 'محلل الجي-كود';
  @override String get gcodeUpload         => 'رفع';
  @override String get gcodeController     => 'وحدة التحكم';
  @override String get gcodeAuto           => 'تلقائي';
  @override String get gcodeDetected       => 'تم الكشف';
  @override String get gcodeLabel          => 'الجي-كود';
  @override String get gcodeAnalyzeBtn     => 'تحليل الجي-كود';
  @override String get gcodeEmptySnack     => 'الرجاء إدخال أو رفع الجي-كود أولاً.';
  @override String get gcodeFileError      => 'فشل في قراءة الملف';
  @override String get gcodeViewTab        => 'عرض الجي-كود';
  @override String get gcodeSummaryTab     => 'الملخص';
  @override String get gcodeStatController => 'وحدة التحكم';
  @override String get gcodeStatStats      => 'الإحصائيات';
  @override String get gcodeStatErrors     => 'الأخطاء';
  @override String get gcodeStatWarnings   => 'التحذيرات';
  @override String get gcodeNoIssues       => 'لم يتم العثور على مشاكل';
  @override String get gcodeIssuesOnly     => 'المشاكل فقط';
  @override String get gcodeCopied         => 'تم نسخ الجي-كود';
  @override String get gcodeCopyTooltip    => 'نسخ الجي-كود';
  @override String get gcodeLines          => 'سطر';
  @override String get gcodeErrors         => 'أخطاء';
  @override String get gcodeWarnings       => 'تحذيرات';

  @override String get kbTitle             => 'قاعدة معرفة CNC';
  @override String get kbEmptyTitle        => 'اسأل أي سؤال عن CNC';
  @override String get kbEmptySubtitle     => 'الجي-كود، دورات سينومريك، التغذية والسرعة،\nاستكشاف الأخطاء وإصلاحها والمزيد.';
  @override String get kbInputHint         => 'اسأل سؤالاً عن CNC...';
  @override String get kbPlaceholderReply  =>
      'لتفعيل إجابات الذكاء الاصطناعي، أضف مفتاح Claude API في الإعدادات.\n\n'
      'قاعدة المعرفة تستخدم Claude للإجابة على أسئلة CNC حول الجي-كود، '
      'معاملات التشغيل الآلي، دورات سينومريك والمزيد.';

  @override String get errRefTitle          => 'مرجع الأخطاء';
  @override String get errRefSearchHint     => 'ابحث عن كود الإنذار أو كلمة مفتاحية...';
  @override String get errRefFilterAll      => 'الكل';
  @override String get errRefFilterHaas     => 'Haas';
  @override String get errRefFilterSiemens  => 'سيمنس';
  @override String get errRefFilterFanuc    => 'FANUC';
  @override String get errRefFilterHeidenhain => 'Heidenhain';
  @override String get errRefNoResults      => 'لم يتم العثور على إنذارات';
  @override String get errRefCauses         => 'الأسباب المحتملة';
  @override String get errRefSolutions      => 'الحلول';
  @override String get errRefSeverityInfo   => 'معلومات';
  @override String get errRefSeverityWarning => 'تحذير';
  @override String get errRefSeverityError  => 'خطأ';
  @override String get errRefSeverityCritical => 'حرج';

  @override String get settingsTitle        => 'الإعدادات';
  @override String get settingsLanguage     => 'اللغة';
  @override String get settingsLanguageEn   => 'English';
  @override String get settingsLanguageRo   => 'Română';
  @override String get settingsLanguageFa   => 'فارسی';
  @override String get settingsLanguageAr   => 'العربية';
  @override String get settingsUnits        => 'الوحدات الافتراضية';
  @override String get settingsUnitsMetric  => 'متري (mm)';
  @override String get settingsUnitsImperial=> 'إمبريالي (inch)';
  @override String get settingsDialect      => 'لهجة CNC الافتراضية';
  @override String get settingsApiKey       => 'مفتاح Claude API';
  @override String get settingsApiKeyHint   => 'sk-ant-...';
  @override String get settingsApiKeyDesc   =>
      'مفتاحك مخزن بشكل آمن على هذا الجهاز فقط. '
      'يستخدم فقط لميزة قاعدة المعرفة.';
  @override String get settingsSaved        => 'تم حفظ الإعدادات';
  @override String get settingsAbout        => 'حول';
  @override String get settingsVersion      => 'الإصدار 1.0.0';
  @override String get settingsTheme        => 'المظهر';
  @override String get settingsThemeDark    => 'داكن (صناعي)';

  @override String get navHistory            => 'السجل';
  @override String get historyTitle          => 'السجل';
  @override String get historyCalculations   => 'الحسابات';
  @override String get historyAnalyses       => 'التحليلات';
  @override String get historyEmpty          => 'لا توجد عناصر محفوظة';
  @override String get historyEmptyDesc      => 'احفظ الحسابات وتحليلات الجي-كود\nللوصول إليها هنا.';
  @override String get historySave           => 'حفظ';
  @override String get historySaved          => 'تم الحفظ في السجل';
  @override String get historyDeleteAll      => 'حذف الكل';
  @override String get historyConfirmClear   => 'سيتم حذف جميع العناصر المحفوظة في هذا التبويب.';

  @override String get commonCancel         => 'إلغاء';
  @override String get commonSave           => 'حفظ';
  @override String get commonClear          => 'مسح';
  @override String get commonError          => 'خطأ';
  @override String get commonLoading        => 'جارٍ التحميل...';

  @override String get imgPickSource        => 'اختر مصدر الصورة';
  @override String get imgPickCamera        => 'الكاميرا';
  @override String get imgPickGallery       => 'المعرض';
  @override String get imgAttached          => 'تم إرفاق الصورة';
  @override String get imgPickError         => 'فشل في اختيار الصورة';

  @override String get gcodeFromDrawing          => 'من الرسم';
  @override String get gcodeFromDrawingHint      => 'ارفع رسماً هندسياً أو صورة قطعة لتوليد الجي-كود';
  @override String get gcodeFromDrawingGenerating => 'جارٍ تحليل الرسم...';
  @override String get gcodeFromDrawingError     => 'فشل في توليد الجي-كود من الرسم';

  // Phase 1 — Usage / Quota
  @override String get proFreeLabel        => 'مجاني';
  @override String get proProLabel         => 'Pro';
  @override String get proQuestionsLeft    => 'سؤال متبقٍ هذا الشهر';
  @override String get proUnlimited        => 'غير محدود';
  @override String get proLimitTitle       => 'تم الوصول للحد الشهري';
  @override String get proLimitMsg         => 'لقد استخدمت جميع الأسئلة الـ10 المجانية هذا الشهر.\nرقّ إلى Pro للوصول غير المحدود.';
  @override String get proUpgradeBtn       => 'الترقية إلى Pro';
  @override String get proLaterBtn         => 'ليس الآن';
  @override String get proUsageOf          => 'من';

  // Phase 2 — Subscription
  @override String get subTitle            => 'CNC Assist Pro';
  @override String get subSubtitle         => 'افتح الوصول غير المحدود';
  @override String get subMonthly          => '4.99\$ / شهر';
  @override String get subFeatureUnlimited => 'أسئلة AI غير محدودة';
  @override String get subFeatureSetup     => 'مولد ورقة الإعداد';
  @override String get subFeatureTooling   => 'توصيات الأدوات';
  @override String get subFeaturePdf       => 'محلل رسومات PDF';
  @override String get subSubscribeBtn     => 'اشترك الآن';
  @override String get subRestoreBtn       => 'استعادة الشراء';
  @override String get subCurrentPlan      => 'الخطة الحالية';
  @override String get subManageBtn        => 'إدارة الاشتراك';
  @override String get subLoading          => 'جارٍ المعالجة...';
  @override String get subError            => 'فشل الشراء. حاول مرة أخرى.';
  @override String get subSuccess          => 'مرحباً بك في CNC Assist Pro!';
  @override String get subNotAvailable     => 'المشتريات غير متاحة على هذا الجهاز.';

  // Phase 3 — Setup Sheet
  @override String get setupSheetTitle     => 'ورقة الإعداد';
  @override String get setupSheetBtn       => 'إنشاء ورقة الإعداد';
  @override String get setupSheetShare     => 'مشاركة / طباعة';
  @override String get setupSheetDate      => 'التاريخ';
  @override String get setupSheetProOnly   => 'ميزة Pro — رقّ لإنشاء ورقة الإعداد';

  // Phase 4 — Tooling Recs
  @override String get toolingTitle        => 'توصيات الأدوات';
  @override String get toolingBtn          => 'الحصول على توصيات الأدوات';
  @override String get toolingLoading      => 'جارٍ تحليل المعاملات...';
  @override String get toolingProOnly      => 'ميزة Pro — رقّ للحصول على توصيات الأدوات';

  // Phase 5 — PDF Analyzer
  @override String get pdfTitle            => 'محلل رسومات PDF';
  @override String get pdfBtn              => 'تحليل رسم PDF';
  @override String get pdfLoading          => 'جارٍ تحليل PDF...';
  @override String get pdfPickBtn          => 'اختر ملف PDF';
  @override String get pdfProOnly          => 'ميزة Pro — رقّ لتحليل رسومات PDF';
  @override String get pdfError            => 'فشل في تحليل PDF';
  @override String get pdfTooLarge         => 'ملف PDF كبير جداً (الحد الأقصى 10MB)';

  // Settings — Subscription
  @override String get settingsSubscription => 'الاشتراك';
  @override String get settingsFreePlan     => 'الخطة المجانية · 10 أسئلة AI/شهر';
  @override String get settingsProPlan      => 'خطة Pro · وصول غير محدود';
  @override String get settingsUpgradePro   => 'الترقية إلى Pro';

  // Support & Contact
  @override String get supportTitle       => 'الدعم والتواصل';
  @override String get supportSubtitle    => 'نحن هنا لمساعدتك';
  @override String get supportEmail       => 'البريد الإلكتروني';
  @override String get supportTelegram    => 'تيليجرام';
  @override String get supportLinkedIn    => 'لينكد إن';
  @override String get support247         => 'دعم متاح ٢٤/٧';
  @override String get supportDeveloper   => 'المطوّر والمسؤول';

  // Trust — Subscription
  @override String get subFreeTrial       => '٧ أيام تجربة مجانية';
  @override String get subGuaranteeTitle  => 'ضمان الرضا';
  @override String get subGuaranteeMsg    => 'إلغاء في أي وقت. استرداد خلال ٤٨ ساعة إذا لم تكن راضياً.';
  @override String get subCancelAnytime   => 'إلغاء في أي وقت · بدون التزام';

  // G-code reference
  @override String get gcodeRefTitle       => 'مرجع أكواد G';
  @override String get gcodeRefSearchHint  => 'ابحث عن كود أو كلمة مفتاحية…';
  @override String get gcodeRefFilterAll   => 'الكل';
  @override String get gcodeRefNoResults   => 'لم يتم العثور على أكواد';
  @override String get gcodeRefSyntax      => 'الصياغة';
  @override String get gcodeRefCount       => 'كود';

  // Help
  @override String get helpBtnLabel => 'دليل الاستخدام';

  @override String get helpCalcTitle => 'حاسبة التغذية والسرعة';
  @override List<String> get helpCalcSteps => [
    'اختر مادة من القائمة (فولاذ، ألومنيوم، تيتانيوم، إلخ).',
    'أدخل قطر الأداة وعدد الأسنان، ثم حدد عمق القطع وعرض القطع.',
    'اختر مادة الأداة (كربيد أو HSS) ونوع العملية (خشنة أو تشطيب).',
    'اضغط احسب — تظهر RPM ومعدل التغذية وحمل الرقائق و MRR فوراً.\nاضغط حفظ لتخزين النتيجة في السجل.',
  ];

  @override String get helpGcodeTitle => 'محلل G-Code';
  @override List<String> get helpGcodeSteps => [
    'الصق الجي-كود في مربع النص، أو اضغط رفع لتحميل ملف .nc / .txt / .mpf.',
    'اختر نوع وحدة التحكم (Haas أو Sinumerik) أو اتركه على تلقائي — التطبيق يكتشفه تلقائياً.',
    'اضغط تحليل الجي-كود لإجراء الفحص.',
    'الأسطر الحمراء تحتوي على أخطاء؛ الأسطر الصفراء تحتوي على تحذيرات. اضغط أي سطر للتفاصيل.',
  ];

  @override String get helpKbTitle => 'قاعدة معرفة CNC';
  @override List<String> get helpKbSteps => [
    'اكتب أي سؤال CNC (جي-كود، سرعات، استكشاف أخطاء) وأرسله.',
    'يجيب الذكاء الاصطناعي (Claude) بناءً على معرفة التشغيل الآلي CNC.',
    'الخطة المجانية: 10 أسئلة شهرياً. رقّ إلى Pro للوصول غير المحدود.',
    'اضغط أيقونة الكتاب لمرجع أكواد G، أو أيقونة الإنذار لمرجع الأخطاء.',
  ];

  @override String get helpGcodeRefTitle => 'مرجع أكواد G';
  @override List<String> get helpGcodeRefSteps => [
    'تصفح أكثر من 270 كود G و M لوحدات تحكم Haas وSiemens وFANUC وHeidenhain.',
    'استخدم فلاتر الشركات المصنعة لعرض أكواد كل وحدة تحكم.',
    'اكتب في مربع البحث للعثور على كود أو كلمة مفتاحية فوراً.',
    'اضغط أي كود لرؤية الوصف الكامل ومثال الصياغة والتحذيرات.',
  ];

  @override String get helpErrRefTitle => 'مرجع الإنذارات والأخطاء';
  @override List<String> get helpErrRefSteps => [
    'ابحث برقم الإنذار أو كلمة مفتاحية (مثل "مغزل" أو "450").',
    'استخدم فلتر الشركة المصنعة لتضييق النتائج حسب وحدة التحكم.',
    'اضغط أي إنذار لرؤية الأسباب المحتملة والحلول خطوة بخطوة.',
  ];

  @override String get helpHistoryTitle => 'السجل';
  @override List<String> get helpHistorySteps => [
    'الحسابات وتحليلات الجي-كود المحفوظة تُخزن هنا.',
    'بعد الحساب، اضغط حفظ في لوحة النتائج لإضافة إدخال.',
    'بعد تحليل الجي-كود، اضغط حفظ في تبويب الملخص.',
    'اضغط أي إدخال لعرض التفاصيل الكاملة؛ اسحب يساراً للحذف.',
  ];

  // ── أدوات التصنيع ──
  @override String get toolsHubTitle    => 'أدوات التصنيع';
  @override String get toolComingSoon   => 'قريباً';
  @override String get catMilling       => 'التفريز';
  @override String get catTurning       => 'الخراطة';
  @override String get catDrilling      => 'الثقب واللولبة';
  @override String get catCoordinates   => 'الإحداثيات والبرامج';
  @override String get catConverters    => 'المحوّلات';
  @override String get catReference     => 'الدقة والمراجع';
  @override String get toolMilling          => 'تغذية وسرعة التفريز';
  @override String get toolMillingSub       => 'دوران، تغذية، حمل، MRR';
  @override String get toolTurning          => 'تغذية وسرعة الخراطة';
  @override String get toolTurningSub       => 'دوران، تغذية، زمن القطع';
  @override String get toolDrilling         => 'الثقب واللولبة';
  @override String get toolDrillingSub      => 'سرعات، زمن، ثقب اللولب';
  @override String get toolTaper            => 'إحداثيات المخروط';
  @override String get toolTaperSub         => 'X/Z مع تعويض نصف القطر';
  @override String get toolArc              => 'القوس / نصف القطر';
  @override String get toolArcSub           => 'إحداثيات المماس والنهاية';
  @override String get toolGcodeGen         => 'مولّدات الجي-كود';
  @override String get toolGcodeGenSub      => 'لولب G76، دورات الثقب';
  @override String get toolConverters       => 'محوّلات السرعة/التغذية';
  @override String get toolConvertersSub    => 'SFM↔RPM، تغذية/دورة↔دقيقة';
  @override String get toolHardness         => 'تحويل الصلادة';
  @override String get toolHardnessSub      => 'HRC ↔ HB ↔ HV';
  @override String get toolTruePosition     => 'الموضع الحقيقي';
  @override String get toolTruePositionSub  => 'GD&T مع تفاوت إضافي';
  @override String get toolWeight           => 'وزن القطعة';
  @override String get toolWeightSub        => 'مواد وأشكال متعددة';
  @override String get catLearn             => 'تعلّم ومراجع';
  @override String get toolQuiz             => 'اختبار المشغّل';
  @override String get toolQuizSub          => 'أسئلة في 7 مواضيع';
  @override String get toolWear             => 'دليل تآكل الأداة';
  @override String get toolWearSub          => 'الأسباب والحلول';
  @override String get quizScore            => 'النتيجة';
  @override String get quizRestart          => 'إعادة';
  @override String get quizNext             => 'التالي';
  @override String get quizFinish           => 'إنهاء';
  @override String get wearCause            => 'الأسباب';
  @override String get wearSolution         => 'الحلول';
  @override String get secAdvanced          => 'متقدّم (رأس كروي)';
  @override String get resCusp              => 'ارتفاع القمة';
  @override String get resChipThin          => 'معامل ترقيق الرايش';
  @override String get labelStepover        => 'الخطوة الجانبية';

  // ── سلاسل الحاسبة المشتركة ──
  @override String get secInputs        => 'المدخلات';
  @override String get sectionTapDrill  => 'ثقب اللولب';
  @override String get resCutTime       => 'زمن القطع';
  @override String get resFeedPerMin    => 'معدل التغذية';
  @override String get resTapDrill      => 'قطر ثقب اللولب';
  @override String get resPointLength   => 'طول رأس المثقاب';
  @override String get resCoordinates   => 'الإحداثيات';
  @override String get resDeviation     => 'الانحراف';
  @override String get resProgram       => 'البرنامج';
  @override String get btnCopy          => 'نسخ';
  @override String get btnGenerate      => 'توليد';
  @override String get convTabSpeed     => 'السرعة';
  @override String get convTabFeed      => 'التغذية';
  @override String get hardEnterValue   => 'أدخل قيمة بأي مقياس';
  @override String get taperWarnNoseR   => 'نصف قطر الرأس كبير جداً لهذا المقطع — تداخل.';
  @override String get taperWarnLength  => 'نصف القطر يتجاوز طول المقطع.';
}
