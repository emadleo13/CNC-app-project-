import 'app_strings.dart';

class AppStringsFa implements AppStrings {
  @override String get navCalculator       => 'ماشین‌حساب';
  @override String get navGcode            => 'جی‌کد';
  @override String get navKnowledge        => 'دانش';
  @override String get navSettings         => 'تنظیمات';

  @override String get calculatorTitle     => 'ماشین‌حساب پیشروی و سرعت';
  @override String get sectionMaterial     => 'مواد';
  @override String get sectionTool         => 'ابزار';
  @override String get sectionCutParams    => 'پارامترهای برش';
  @override String get selectMaterial      => 'انتخاب ماده';
  @override String get chooseDots          => 'انتخاب کنید...';
  @override String get labelDiameter       => 'قطر';
  @override String get labelFlutes         => 'تعداد لبه';
  @override String get labelDoc            => 'عمق برش';
  @override String get labelWoc            => 'عرض برش';
  @override String get labelToolMaterial   => 'جنس ابزار';
  @override String get labelOperation      => 'عملیات';
  @override String get toolMaterialCarbide => 'کاربید';
  @override String get toolMaterialHss     => 'HSS';
  @override String get operationRough      => 'خشن‌کاری';
  @override String get operationFinish     => 'پرداخت';
  @override String get btnCalculate        => 'محاسبه';
  @override String get resultTitle         => 'نتایج';
  @override String get resultRpm           => 'دور/دقیقه';
  @override String get resultFeedRate      => 'نرخ پیشروی';
  @override String get resultChipLoad      => 'بار براده';
  @override String get resultMrr           => 'نرخ حذف ماده';
  @override String get resultCuttingSpeed  => 'سرعت برش';
  @override String get resultCoolant       => 'خنک‌کار';
  @override String get coolantRequired     => 'الزامی';
  @override String get coolantOptional     => 'اختیاری';
  @override String get unitMm              => 'mm';
  @override String get unitInch            => 'اینچ';

  @override String get gcodeTitle          => 'آنالیزور جی‌کد';
  @override String get gcodeUpload         => 'آپلود';
  @override String get gcodeController     => 'کنترلر';
  @override String get gcodeAuto           => 'خودکار';
  @override String get gcodeDetected       => 'شناسایی شد';
  @override String get gcodeLabel          => 'جی‌کد';
  @override String get gcodeAnalyzeBtn     => 'آنالیز جی‌کد';
  @override String get gcodeEmptySnack     => 'لطفاً ابتدا جی‌کد وارد کنید.';
  @override String get gcodeFileError      => 'خطا در خواندن فایل';
  @override String get gcodeViewTab        => 'نمایش جی‌کد';
  @override String get gcodeSummaryTab     => 'خلاصه';
  @override String get gcodeStatController => 'کنترلر';
  @override String get gcodeStatStats      => 'آمار';
  @override String get gcodeStatErrors     => 'خطاها';
  @override String get gcodeStatWarnings   => 'هشدارها';
  @override String get gcodeNoIssues       => 'مشکلی یافت نشد';
  @override String get gcodeIssuesOnly     => 'فقط مشکلات';
  @override String get gcodeCopied         => 'جی‌کد کپی شد';
  @override String get gcodeCopyTooltip    => 'کپی جی‌کد';
  @override String get gcodeLines          => 'خط';
  @override String get gcodeErrors         => 'خطا';
  @override String get gcodeWarnings       => 'هشدار';

  @override String get kbTitle             => 'پایگاه دانش CNC';
  @override String get kbEmptyTitle        => 'هر سوال CNC بپرسید';
  @override String get kbEmptySubtitle     => 'جی‌کد، سیکل‌های سینومریک، پیشروی و سرعت،\nعیب‌یابی و بیشتر.';
  @override String get kbInputHint         => 'سوال CNC بپرسید...';
  @override String get kbPlaceholderReply  =>
      'برای فعال‌سازی پاسخ‌های هوش مصنوعی، کلید API کلود را در تنظیمات اضافه کنید.\n\n'
      'پایگاه دانش از Claude برای پاسخ به سوالات CNC درباره جی‌کد، '
      'پارامترهای ماشین‌کاری، سیکل‌های سینومریک و بیشتر استفاده می‌کند.';

  @override String get errRefTitle          => 'مرجع خطاها';
  @override String get errRefSearchHint     => 'جستجوی کد آلارم یا کلیدواژه...';
  @override String get errRefFilterAll      => 'همه';
  @override String get errRefFilterHaas     => 'Haas';
  @override String get errRefFilterSiemens  => 'زیمنس';
  @override String get errRefFilterFanuc    => 'FANUC';
  @override String get errRefFilterHeidenhain => 'Heidenhain';
  @override String get errRefFilterMazak      => 'Mazak';
  @override String get errRefNoResults      => 'آلارمی یافت نشد';
  @override String get errRefCauses         => 'دلایل احتمالی';
  @override String get errRefSolutions      => 'راه‌حل‌ها';
  @override String get errRefSeverityInfo   => 'اطلاعات';
  @override String get errRefSeverityWarning => 'هشدار';
  @override String get errRefSeverityError  => 'خطا';
  @override String get errRefSeverityCritical => 'بحرانی';

  // Knowledge base — G-code program library
  @override String get progLibTitle         => 'کتابخانه برنامه‌های جی‌کد';
  @override String get progLibSearchHint    => 'جستجوی برنامه‌ها…';
  @override String get progLibFilterAll     => 'همه';
  @override String get progLibNoResults     => 'برنامه‌ای یافت نشد';
  @override String get progLibCount         => 'برنامه';
  @override String get progLibCodeLabel     => 'جی‌کد';
  @override String get progLibNotesLabel    => 'نکات';
  @override String get progLibCopy          => 'کپی کد';
  @override String get progLibCopied        => 'در کلیپ‌بورد کپی شد';
  @override String get progLibBeginner      => 'مبتدی';
  @override String get progLibIntermediate  => 'متوسط';
  @override String get progLibAdvanced      => 'پیشرفته';
  @override String get progCatCircles       => 'دایره‌ها';
  @override String get progCatPockets       => 'حفره‌ها';
  @override String get progCatDrilling      => 'سوراخ‌کاری';
  @override String get progCatSpirals       => 'مارپیچ';
  @override String get progCatEngraving     => 'حکاکی';
  @override String get progCatContours      => 'پروفایل (کانتور)';
  @override String get progCatFacing        => 'صفحه‌تراشی';
  @override String get progCatTurning       => 'تراشکاری';

  // Knowledge base — CNC guides
  @override String get guidesTitle             => 'راهنمای دستگاه‌های CNC';
  @override String get guidesSearchHint        => 'جستجوی راهنماها…';
  @override String get guidesNoResults         => 'راهنمایی یافت نشد';
  @override String get guideCatMachineBasics   => 'اصول دستگاه';
  @override String get guideCatAxesCoordinates => 'محورها و مختصات';
  @override String get guideCatTooling         => 'ابزار';
  @override String get guideCatWorkHolding     => 'بستن قطعه کار';
  @override String get guideCatGcodeBasics     => 'اصول جی‌کد';
  @override String get guideCatSpeedsFeeds     => 'سرعت و فید';
  @override String get guideCatLatheBasics     => 'اصول تراش';
  @override String get guideCatSafety          => 'ایمنی';

  @override String get settingsTitle        => 'تنظیمات';
  @override String get settingsLanguage     => 'زبان';
  @override String get settingsLanguageEn   => 'English';
  @override String get settingsLanguageRo   => 'Română';
  @override String get settingsLanguageFa   => 'فارسی';
  @override String get settingsLanguageAr   => 'العربية';
  @override String get settingsUnits        => 'واحد پیش‌فرض';
  @override String get settingsUnitsMetric  => 'متریک (mm)';
  @override String get settingsUnitsImperial=> 'اینچی (inch)';
  @override String get settingsDialect      => 'دیالکت CNC پیش‌فرض';
  @override String get settingsApiKey       => 'کلید API کلود';
  @override String get settingsApiKeyHint   => 'sk-ant-...';
  @override String get settingsApiKeyDesc   =>
      'کلید شما به صورت امن در این دستگاه ذخیره می‌شود. '
      'فقط برای ویژگی پایگاه دانش استفاده می‌شود.';
  @override String get settingsSaved        => 'تنظیمات ذخیره شد';
  @override String get settingsAbout        => 'درباره';
  @override String get settingsVersion      => 'نسخه ۱.۰.۰';
  @override String get settingsTheme        => 'پوسته';
  @override String get settingsThemeDark    => 'تیره (صنعتی)';

  @override String get navHistory            => 'تاریخچه';
  @override String get historyTitle          => 'تاریخچه';
  @override String get historyCalculations   => 'محاسبات';
  @override String get historyAnalyses       => 'تحلیل‌ها';
  @override String get historyEmpty          => 'هیچ موردی ذخیره نشده';
  @override String get historyEmptyDesc      => 'محاسبات و تحلیل‌های جی‌کد را ذخیره کنید\nتا اینجا دسترسی داشته باشید.';
  @override String get historyEmptyCtaCalc     => 'اولین محاسبه را شروع کن';
  @override String get historyEmptyCtaAnalysis => 'اولین برنامه را تحلیل کن';
  @override String get historySave           => 'ذخیره';
  @override String get historySaved          => 'در تاریخچه ذخیره شد';
  @override String get historyDeleteAll      => 'حذف همه';
  @override String get historyConfirmClear   => 'تمام موارد ذخیره شده در این تب حذف خواهد شد.';

  @override String get commonCancel         => 'لغو';
  @override String get commonSave           => 'ذخیره';
  @override String get commonClear          => 'پاک کردن';
  @override String get commonCopy           => 'کپی';
  @override String get commonRetry          => 'تلاش دوباره';
  @override String get subProductUnavailable => 'قیمت زنده از فروشگاه در دسترس نیست. اتصال اینترنت را بررسی کن یا بعداً دوباره امتحان کن.';
  @override String get commonError          => 'خطا';
  @override String get commonLoading        => 'در حال بارگذاری...';

  @override String get imgPickSource        => 'انتخاب منبع تصویر';
  @override String get imgPickCamera        => 'دوربین';
  @override String get imgPickGallery       => 'گالری';
  @override String get imgAttached          => 'تصویر ضمیمه شد';
  @override String get imgPickError         => 'خطا در انتخاب تصویر';

  @override String get gcodeFromDrawing          => 'از نقشه';
  @override String get gcodeFromDrawingHint      => 'نقشه فنی یا عکس قطعه را آپلود کنید تا جی‌کد تولید شود';
  @override String get gcodeFromDrawingGenerating => 'در حال تحلیل نقشه...';
  @override String get gcodeFromDrawingError     => 'خطا در تولید جی‌کد از نقشه';

  // Phase 1 — Usage / Quota
  @override String get proFreeLabel        => 'رایگان';
  @override String get proProLabel         => 'Pro';
  @override String get proQuestionsLeft    => 'سوال باقی‌مانده این ماه';
  @override String get proUnlimited        => 'نامحدود';
  @override String get proLimitTitle       => 'محدودیت ماهانه';
  @override String get proLimitMsg         => 'تمام ۱۰ سوال AI رایگان این ماه را استفاده کردید.\nبرای دسترسی نامحدود ارتقا دهید.';
  @override String get proUpgradeBtn       => 'ارتقا به Pro';
  @override String get proLaterBtn         => 'بعداً';
  @override String get proUsageOf          => 'از';

  // Phase 2 — Subscription
  @override String get subTitle            => 'CNC Assist Pro';
  @override String get subSubtitle         => 'دسترسی نامحدود را باز کنید';
  @override String get subMonthly          => '۴٫۹۹ دلار / ماه';
  @override String get subFeatureUnlimited => 'سوالات AI نامحدود';
  @override String get subFeatureSetup     => 'تولید فرم تنظیم دستگاه';
  @override String get subFeatureTooling   => 'پیشنهاد ابزار';
  @override String get subFeaturePdf       => 'آنالیز نقشه PDF';
  @override String get subSubscribeBtn     => 'اشتراک بگیرید';
  @override String get subRestoreBtn       => 'بازیابی خرید';
  @override String get subCurrentPlan      => 'پلن فعلی';
  @override String get subManageBtn        => 'مدیریت اشتراک';
  @override String get subLoading          => 'در حال پردازش...';
  @override String get subError            => 'خرید ناموفق بود. دوباره امتحان کنید.';
  @override String get subSuccess          => 'به CNC Assist Pro خوش آمدید!';
  @override String get subNotAvailable     => 'خرید در این دستگاه در دسترس نیست.';

  // Phase 3 — Setup Sheet
  @override String get setupSheetTitle     => 'فرم تنظیم دستگاه';
  @override String get setupSheetBtn       => 'تولید فرم تنظیم';
  @override String get setupSheetShare     => 'اشتراک‌گذاری / چاپ';
  @override String get setupSheetDate      => 'تاریخ';
  @override String get setupSheetProOnly   => 'ویژگی Pro — برای تولید فرم ارتقا دهید';

  // Phase 4 — Tooling Recs
  @override String get toolingTitle        => 'پیشنهاد ابزار';
  @override String get toolingBtn          => 'دریافت پیشنهاد ابزار';
  @override String get toolingLoading      => 'در حال آنالیز پارامترها...';
  @override String get toolingProOnly      => 'ویژگی Pro — برای پیشنهاد ابزار ارتقا دهید';

  // Phase 5 — PDF Analyzer
  @override String get pdfTitle            => 'آنالیزور نقشه PDF';
  @override String get pdfBtn              => 'آنالیز نقشه PDF';
  @override String get pdfLoading          => 'در حال آنالیز PDF...';
  @override String get pdfPickBtn          => 'انتخاب فایل PDF';
  @override String get pdfProOnly          => 'ویژگی Pro — برای آنالیز نقشه PDF ارتقا دهید';
  @override String get pdfError            => 'خطا در آنالیز PDF';
  @override String get pdfTooLarge         => 'PDF خیلی بزرگ است (حداکثر ۱۰ مگابایت)';

  // Settings — Subscription
  @override String get settingsSubscription => 'اشتراک';
  @override String get settingsFreePlan     => 'پلن رایگان · ۱۰ سوال AI در ماه';
  @override String get settingsProPlan      => 'پلن Pro · دسترسی نامحدود';
  @override String get settingsUpgradePro   => 'ارتقا به Pro';

  // Support & Contact
  @override String get supportTitle       => 'پشتیبانی و تماس';
  @override String get supportSubtitle    => 'ما اینجاییم تا به شما کمک کنیم';
  @override String get supportEmail       => 'ایمیل';
  @override String get supportTelegram    => 'تلگرام';
  @override String get supportLinkedIn    => 'لینکدین';
  @override String get support247         => 'پشتیبانی ۲۴ ساعته · ۷ روز هفته';
  @override String get supportDeveloper   => 'توسعه‌دهنده و مدیر';

  // Trust — Subscription
  @override String get subFreeTrial       => '۷ روز دوره آزمایشی رایگان';
  @override String get subGuaranteeTitle  => 'ضمانت رضایت';
  @override String get subGuaranteeMsg    => 'هر زمان لغو کنید. بازگشت وجه ظرف ۴۸ ساعت در صورت عدم رضایت.';
  @override String get subCancelAnytime   => 'لغو در هر زمان · بدون تعهد';

  // G-code reference
  @override String get gcodeRefTitle       => 'مرجع G-Code';
  @override String get gcodeRefSearchHint  => 'جستجوی کد یا کلمه کلیدی…';
  @override String get gcodeRefFilterAll   => 'همه';
  @override String get gcodeRefNoResults   => 'کدی یافت نشد';
  @override String get gcodeRefSyntax      => 'نحو';
  @override String get gcodeRefCount       => 'کد';

  // Help
  @override String get helpBtnLabel => 'راهنما';

  @override String get helpCalcTitle => 'ماشین‌حساب تغذیه و سرعت';
  @override List<String> get helpCalcSteps => [
    'یک ماده از لیست انتخاب کنید (فولاد، آلومینیوم، تیتانیوم و غیره).',
    'قطر ابزار و تعداد لبه‌ها را وارد کنید، سپس عمق و عرض برش را تنظیم کنید.',
    'جنس ابزار (کاربید یا HSS) و نوع عملیات (خشن‌کاری یا پرداخت) را انتخاب کنید.',
    'محاسبه را بزنید — دور در دقیقه، پیشروی، بار تراشه و MRR فوری نمایش داده می‌شوند.\nبرای ذخیره در تاریخچه «ذخیره» را بزنید.',
  ];

  @override String get helpGcodeTitle => 'آنالیزور G-Code';
  @override List<String> get helpGcodeSteps => [
    'G-code را در کادر متنی وارد کنید یا Upload را بزنید تا فایل .nc / .txt / .mpf بارگذاری شود.',
    'نوع کنترلر (Haas یا Sinumerik) را انتخاب کنید یا Auto را بگذارید — اپ خودکار تشخیص می‌دهد.',
    'آنالیز G-Code را بزنید تا بررسی انجام شود.',
    'سطرهای قرمز خطا دارند؛ سطرهای زرد هشدار دارند. روی هر سطر بزنید برای جزئیات.',
  ];

  @override String get helpKbTitle => 'پایگاه دانش CNC';
  @override List<String> get helpKbSteps => [
    'هر سوال CNC (G-code، سرعت، عیب‌یابی) را تایپ کرده و ارسال کنید.',
    'هوش مصنوعی (Claude) با دانش ماشین‌کاری CNC پاسخ می‌دهد.',
    'پلن رایگان: ۱۰ سوال در ماه. برای دسترسی نامحدود به Pro ارتقا دهید.',
    'آیکون کتاب را برای مرجع G-Code، یا آیکون زنگ خطر را برای مرجع خطاها بزنید.',
  ];

  @override String get helpGcodeRefTitle => 'مرجع G-Code';
  @override List<String> get helpGcodeRefSteps => [
    'بیش از ۲۷۰ کد G و M برای کنترلرهای Haas، زیمنس، FANUC و Heidenhain را مرور کنید.',
    'از فیلترهای برند برای نمایش کدهای هر کنترلر استفاده کنید.',
    'در کادر جستجو، کد یا کلمه کلیدی را تایپ کنید تا فوری پیدا شود.',
    'روی هر کد بزنید تا توضیح کامل، مثال نحو و هشدارهای ایمنی نمایش داده شود.',
  ];

  @override String get helpErrRefTitle => 'مرجع خطاها و آلارم‌ها';
  @override List<String> get helpErrRefSteps => [
    'با شماره آلارم یا کلمه کلیدی جستجو کنید (مثلاً "اسپیندل" یا "450").',
    'از فیلتر برند برای محدود کردن نتایج به کنترلر دستگاه خود استفاده کنید.',
    'روی هر آلارم بزنید تا دلایل احتمالی و راه‌حل‌های گام‌به‌گام ببینید.',
  ];

  @override String get helpProgLibTitle => 'کتابخانه برنامه‌های جی‌کد';
  @override List<String> get helpProgLibSteps => [
    'برنامه‌های نمونه آماده اجرا را مرور کنید — دایره، حفره، الگوهای سوراخ‌کاری، مارپیچ، حکاکی و موارد دیگر.',
    'برای فیلتر کردن از دسته‌بندی‌ها استفاده کنید یا با عنوان یا کلمه کلیدی جستجو کنید.',
    'روی هر برنامه ضربه بزنید تا کد کامل را ببینید، آن را کپی کنید و نکات اجرای ایمن آن را بخوانید.',
  ];

  @override String get helpGuidesTitle => 'نحوه کارکرد دستگاه‌های CNC';
  @override List<String> get helpGuidesSteps => [
    'راهنماهای کوتاهی درباره اصول دستگاه، محورها، ابزار، بستن قطعه کار، جی‌کد و ایمنی بخوانید.',
    'برای رفتن به یک موضوع از دسته‌بندی‌ها استفاده کنید یا با کلمه کلیدی جستجو کنید.',
    'روی هر راهنما ضربه بزنید تا مقاله کامل را بخوانید.',
  ];

  @override String get helpHistoryTitle => 'تاریخچه';
  @override List<String> get helpHistorySteps => [
    'محاسبات و تحلیل‌های G-code ذخیره‌شده اینجا نگهداری می‌شوند.',
    'بعد از محاسبه، «ذخیره» را در پنل نتایج بزنید تا یک آیتم اضافه شود.',
    'بعد از آنالیز G-code، در تب خلاصه «ذخیره» را بزنید.',
    'روی هر آیتم بزنید برای مشاهده جزئیات؛ به چپ بکشید برای حذف.',
  ];

  // ── ابزارهای ماشینکاری ──
  @override String get toolsHubTitle    => 'ابزارهای ماشینکاری';
  @override String get quickAccess      => 'دسترسی سریع';
  @override String get toolComingSoon   => 'به‌زودی';
  @override String get catMilling       => 'فرزکاری';
  @override String get catTurning       => 'تراشکاری';
  @override String get catDrilling      => 'سوراخکاری و قلاویز';
  @override String get catCoordinates   => 'مختصات و برنامه';
  @override String get catConverters    => 'مبدل‌ها';
  @override String get catReference     => 'دقت و مرجع';
  @override String get toolMilling          => 'پیشروی و سرعت فرز';
  @override String get toolMillingSub       => 'دور، پیشروی، بار براده، MRR';
  @override String get toolTurning          => 'پیشروی و سرعت تراش';
  @override String get toolTurningSub       => 'دور، پیشروی، زمان برش';
  @override String get toolDrilling         => 'مته و قلاویز';
  @override String get toolDrillingSub      => 'سرعت، زمان، مته قلاویز';
  @override String get toolTaper            => 'مختصات شیب (تیپر)';
  @override String get toolTaperSub         => 'X/Z با جبران شعاع نوک';
  @override String get toolArc              => 'قوس / شعاع';
  @override String get toolArcSub           => 'مختصات مماس و انتها';
  @override String get toolGcodeGen         => 'مولد جی‌کد';
  @override String get toolGcodeGenSub      => 'رزوه G76، چرخه سوراخ';
  @override String get toolConverters       => 'مبدل سرعت/پیشروی';
  @override String get toolConvertersSub    => 'SFM↔RPM، پیشروی دور↔دقیقه';
  @override String get toolHardness         => 'تبدیل سختی';
  @override String get toolHardnessSub      => 'HRC ↔ HB ↔ HV';
  @override String get toolTruePosition     => 'موقعیت واقعی';
  @override String get toolTruePositionSub  => 'GD&T با تلرانس بونوس';
  @override String get toolWeight           => 'وزن قطعه';
  @override String get toolWeightSub        => 'مواد و اشکال مختلف';
  @override String get catLearn             => 'آموزش و مرجع';
  @override String get toolQuiz             => 'آزمون ماشینکار';
  @override String get toolQuizSub          => 'کوییز در ۷ موضوع';
  @override String get toolWear             => 'راهنمای سایش ابزار';
  @override String get toolWearSub          => 'علت‌ها و راه‌حل‌ها';
  @override String get quizScore            => 'امتیاز';
  @override String get quizRestart          => 'شروع مجدد';
  @override String get quizNext             => 'بعدی';
  @override String get quizFinish           => 'پایان';
  @override String get wearCause            => 'علت‌ها';
  @override String get wearSolution         => 'راه‌حل‌ها';
  @override String get secAdvanced          => 'پیشرفته (سرکروی)';
  @override String get resCusp              => 'ارتفاع پله';
  @override String get resChipThin          => 'ضریب نازک‌شدن براده';
  @override String get labelStepover        => 'گام جانبی';

  // ── رشته‌های مشترک ماشین‌حساب ──
  @override String get secInputs        => 'ورودی‌ها';
  @override String get sectionTapDrill  => 'مته قلاویز';
  @override String get resCutTime       => 'زمان برش';
  @override String get resFeedPerMin    => 'نرخ پیشروی';
  @override String get resTapDrill      => 'قطر مته قلاویز';
  @override String get resPointLength   => 'طول نوک مته';
  @override String get resCoordinates   => 'مختصات';
  @override String get resDeviation     => 'انحراف';
  @override String get resProgram       => 'برنامه';
  @override String get btnCopy          => 'کپی';
  @override String get btnGenerate      => 'تولید';
  @override String get convTabSpeed     => 'سرعت';
  @override String get convTabFeed      => 'پیشروی';
  @override String get hardEnterValue   => 'مقدار را در هر مقیاسی وارد کنید';
  @override String get taperWarnNoseR   => 'شعاع نوک برای این مقطع خیلی بزرگ است — تداخل.';
  @override String get taperWarnLength  => 'شعاع از طول مقطع بیشتر است.';

  @override String get onboardSkip   => 'رد کردن';
  @override String get onboardNext   => 'بعدی';
  @override String get onboardStart  => 'شروع کنیم';
  @override String get onboard1Title => 'محاسبه‌گر فید و سرعت';
  @override String get onboard1Body  => 'پارامترهای برش دقیق برای هر متریال و ابزار را در چند ثانیه به‌دست بیاور.';
  @override String get onboard2Title => 'آنالیزور جی‌کد';
  @override String get onboard2Body  => 'برنامه را الصاق یا آپلود کن؛ خطاها و هشدارها را با هایلایت رنگی خط‌به‌خط ببین.';
  @override String get onboard3Title => 'پایگاه دانش هوشمند';
  @override String get onboard3Body  => 'هر سؤال CNC را بپرس و به مرجع کامل کدهای G و M دسترسی داشته باش.';

  @override String get heroHello         => 'سلام';
  @override String get greetingMorning   => 'صبح بخیر 👋';
  @override String get greetingAfternoon => 'ظهر بخیر 👋';
  @override String get greetingEvening   => 'عصر بخیر 👋';
  @override String get heroPrompt        => 'امروز چه چیزی محاسبه می‌کنید؟';
  @override String get statTools         => 'ابزار';
  @override String get statGcodes        => 'کد G';
  @override String get statErrors        => 'خطای CNC';
  @override String get tipOfDayTitle     => 'نکتهٔ امروز CNC';
  @override List<String> get cncTips => const [
    'G43 برای اعمال جبران طول ابزار (Tool Length Offset) استفاده می‌شود.',
    'G41 جبران شعاع ابزار از سمت چپ مسیر و G42 از سمت راست است.',
    'M03 دوک را ساعت‌گرد و M04 پادساعت‌گرد می‌چرخاند.',
    'G90 مختصات مطلق و G91 مختصات نسبی (افزایشی) است.',
    'برای فولاد نرم، سرعت برش کاربید معمولاً ۳ تا ۴ برابر HSS است.',
    'همیشه قبل از G43 شمارهٔ ابزار و H آن را بررسی کن تا تصادف رخ ندهد.',
    'G54 تا G59 سیستم‌های مختصات کاری قابل‌برنامه‌ریزی هستند.',
    'کاهش بار براده در قطرهای کوچک از شکستن ابزار جلوگیری می‌کند.',
  ];
  @override String get badgePopular => 'پرکاربرد';
  @override String get badgeNew     => 'جدید';
  @override String get badgePro     => 'حرفه‌ای';
  @override String get popularQuestions => 'سوالات پرطرفدار';
  @override List<String> get popularQuestionsList => const [
    'تفاوت G41 و G42 چیست؟',
    'تفاوت G90 و G91 چیست؟',
    'تفاوت M03 و M04 چیست؟',
    'RPM چطور محاسبه می‌شود؟',
  ];
  @override String get settingsName     => 'نام شما';
  @override String get settingsNameHint => 'برای خوش‌آمدگویی در صفحهٔ اصلی';
}
