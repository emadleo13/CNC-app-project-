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
  @override String get errRefNoResults      => 'آلارمی یافت نشد';
  @override String get errRefCauses         => 'دلایل احتمالی';
  @override String get errRefSolutions      => 'راه‌حل‌ها';
  @override String get errRefSeverityInfo   => 'اطلاعات';
  @override String get errRefSeverityWarning => 'هشدار';
  @override String get errRefSeverityError  => 'خطا';
  @override String get errRefSeverityCritical => 'بحرانی';

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
  @override String get historySave           => 'ذخیره';
  @override String get historySaved          => 'در تاریخچه ذخیره شد';
  @override String get historyDeleteAll      => 'حذف همه';
  @override String get historyConfirmClear   => 'تمام موارد ذخیره شده در این تب حذف خواهد شد.';

  @override String get commonCancel         => 'لغو';
  @override String get commonSave           => 'ذخیره';
  @override String get commonClear          => 'پاک کردن';
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
  @override String get subMonthly          => '۱۹ دلار / ماه';
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

  // G-code reference
  @override String get gcodeRefTitle       => 'مرجع G-Code';
  @override String get gcodeRefSearchHint  => 'جستجوی کد یا کلمه کلیدی…';
  @override String get gcodeRefFilterAll   => 'همه';
  @override String get gcodeRefNoResults   => 'کدی یافت نشد';
  @override String get gcodeRefSyntax      => 'نحو';
  @override String get gcodeRefCount       => 'کد';
}
