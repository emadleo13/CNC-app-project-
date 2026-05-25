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
  @override String get subMonthly          => '19\$ / شهر';
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

  // G-code reference
  @override String get gcodeRefTitle       => 'مرجع أكواد G';
  @override String get gcodeRefSearchHint  => 'ابحث عن كود أو كلمة مفتاحية…';
  @override String get gcodeRefFilterAll   => 'الكل';
  @override String get gcodeRefNoResults   => 'لم يتم العثور على أكواد';
  @override String get gcodeRefSyntax      => 'الصياغة';
  @override String get gcodeRefCount       => 'كود';
}
