import 'app_strings.dart';

class AppStringsRo implements AppStrings {
  @override String get navCalculator       => 'Calculator';
  @override String get navGcode            => 'G-Code';
  @override String get navKnowledge        => 'Cunoștințe';
  @override String get navSettings         => 'Setări';

  @override String get calculatorTitle     => 'Calculator Avans și Viteză';
  @override String get sectionMaterial     => 'MATERIAL';
  @override String get sectionTool         => 'SCULĂ';
  @override String get sectionCutParams    => 'PARAMETRI TĂIERE';
  @override String get selectMaterial      => 'Selectează materialul';
  @override String get chooseDots          => 'Alege...';
  @override String get labelDiameter       => 'Diametru';
  @override String get labelFlutes         => 'Nr. dinți';
  @override String get labelDoc            => 'Adâncime de tăiere';
  @override String get labelWoc            => 'Lățime de tăiere';
  @override String get labelToolMaterial   => 'Material sculă';
  @override String get labelOperation      => 'Operație';
  @override String get toolMaterialCarbide => 'Carbură';
  @override String get toolMaterialHss     => 'HSS';
  @override String get operationRough      => 'Degroșare';
  @override String get operationFinish     => 'Finisare';
  @override String get btnCalculate        => 'Calculează';
  @override String get resultTitle         => 'Rezultate';
  @override String get resultRpm           => 'RPM';
  @override String get resultFeedRate      => 'Avans';
  @override String get resultChipLoad      => 'Avans/Dinte';
  @override String get resultMrr           => 'RMM';
  @override String get resultCuttingSpeed  => 'Viteză de tăiere';
  @override String get resultCoolant       => 'Lichid răcire';
  @override String get coolantRequired     => 'Necesar';
  @override String get coolantOptional     => 'Opțional';
  @override String get unitMm              => 'mm';
  @override String get unitInch            => 'inch';

  @override String get gcodeTitle          => 'Analizor G-Code';
  @override String get gcodeUpload         => 'Încarcă';
  @override String get gcodeController     => 'CONTROLER';
  @override String get gcodeAuto           => 'Auto';
  @override String get gcodeDetected       => 'Detectat';
  @override String get gcodeLabel          => 'G-CODE';
  @override String get gcodeAnalyzeBtn     => 'Analizează G-Code';
  @override String get gcodeEmptySnack     => 'Introdu sau încarcă G-code mai întâi.';
  @override String get gcodeFileError      => 'Eroare la citirea fișierului';
  @override String get gcodeViewTab        => 'Vizualizare G-Code';
  @override String get gcodeSummaryTab     => 'Rezumat';
  @override String get gcodeStatController => 'Controler';
  @override String get gcodeStatStats      => 'Statistici';
  @override String get gcodeStatErrors     => 'Erori';
  @override String get gcodeStatWarnings   => 'Avertismente';
  @override String get gcodeNoIssues       => 'Nicio problemă găsită';
  @override String get gcodeIssuesOnly     => 'Doar probleme';
  @override String get gcodeCopied         => 'G-code copiat';
  @override String get gcodeCopyTooltip    => 'Copiază G-code';
  @override String get gcodeLines          => 'linii';
  @override String get gcodeErrors         => 'erori';
  @override String get gcodeWarnings       => 'avertismente';

  @override String get kbTitle             => 'Baza de Cunoștințe CNC';
  @override String get kbEmptyTitle        => 'Pune orice întrebare CNC';
  @override String get kbEmptySubtitle     => 'G-code, cicluri Sinumerik, avans și viteză,\ndepanare și multe altele.';
  @override String get kbInputHint         => 'Pune o întrebare CNC...';
  @override String get kbPlaceholderReply  =>
      'Pentru a activa răspunsurile AI, adaugă cheia API Claude în Setări.\n\n'
      'Baza de cunoștințe folosește Claude pentru a răspunde la întrebări CNC '
      'despre G-code, parametri de prelucrare, cicluri Sinumerik și mai mult.';

  @override String get errRefTitle          => 'Referință Erori';
  @override String get errRefSearchHint     => 'Caută cod alarmă sau cuvânt cheie...';
  @override String get errRefFilterAll        => 'Toate';
  @override String get errRefFilterHaas       => 'Haas';
  @override String get errRefFilterSiemens    => 'Siemens';
  @override String get errRefFilterFanuc      => 'FANUC';
  @override String get errRefFilterHeidenhain => 'Heidenhain';
  @override String get errRefNoResults        => 'Nicio alarmă găsită';
  @override String get errRefCauses         => 'Cauze posibile';
  @override String get errRefSolutions      => 'Soluții';
  @override String get errRefSeverityInfo     => 'INFO';
  @override String get errRefSeverityWarning  => 'AVERTISMENT';
  @override String get errRefSeverityError    => 'EROARE';
  @override String get errRefSeverityCritical => 'CRITIC';

  @override String get settingsTitle        => 'Setări';
  @override String get settingsLanguage     => 'Limbă';
  @override String get settingsLanguageEn   => 'English';
  @override String get settingsLanguageRo   => 'Română';
  @override String get settingsUnits        => 'Unități implicite';
  @override String get settingsUnitsMetric  => 'Metric (mm)';
  @override String get settingsUnitsImperial=> 'Imperial (inch)';
  @override String get settingsDialect      => 'Dialect CNC implicit';
  @override String get settingsApiKey       => 'Cheie API Claude';
  @override String get settingsApiKeyHint   => 'sk-ant-...';
  @override String get settingsApiKeyDesc   =>
      'Cheia ta este stocată în siguranță pe acest dispozitiv. '
      'Este utilizată doar pentru funcția Baza de Cunoștințe.';
  @override String get settingsSaved        => 'Setări salvate';
  @override String get settingsAbout        => 'Despre';
  @override String get settingsVersion      => 'Versiunea 1.0.0';
  @override String get settingsTheme        => 'Temă';
  @override String get settingsThemeDark    => 'Întunecat (Industrial)';

  @override String get navHistory            => 'Istoric';
  @override String get historyTitle          => 'Istoric';
  @override String get historyCalculations   => 'Calcule';
  @override String get historyAnalyses       => 'Analize';
  @override String get historyEmpty          => 'Niciun element salvat';
  @override String get historyEmptyDesc      => 'Salvează calcule și analize G-code\npentru a le accesa aici.';
  @override String get historySave           => 'Salvează';
  @override String get historySaved          => 'Salvat în istoric';
  @override String get historyDeleteAll      => 'Șterge tot';
  @override String get historyConfirmClear   => 'Aceasta va șterge toate elementele salvate din acest tab.';

  @override String get commonCancel         => 'Anulează';
  @override String get commonSave           => 'Salvează';
  @override String get commonClear          => 'Șterge';
  @override String get commonError          => 'Eroare';
  @override String get commonLoading        => 'Se încarcă...';

  @override String get imgPickSource             => 'Selectează sursa imaginii';
  @override String get imgPickCamera             => 'Cameră';
  @override String get imgPickGallery            => 'Galerie';
  @override String get imgAttached               => 'Imagine atașată';
  @override String get imgPickError              => 'Eroare la selectarea imaginii';

  @override String get gcodeFromDrawing          => 'Din desen';
  @override String get gcodeFromDrawingHint      => 'Încarcă un desen tehnic sau foto piesă pentru a genera G-code';
  @override String get gcodeFromDrawingGenerating => 'Analizez desenul...';
  @override String get gcodeFromDrawingError     => 'Eroare la generarea G-code din desen';

  // Phase 1 — Usage / Quota
  @override String get proFreeLabel        => 'Gratuit';
  @override String get proProLabel         => 'Pro';
  @override String get proQuestionsLeft    => 'întrebări rămase luna aceasta';
  @override String get proUnlimited        => 'Nelimitat';
  @override String get proLimitTitle       => 'Limită lunară atinsă';
  @override String get proLimitMsg         => 'Ai folosit toate cele 10 întrebări AI gratuite.\nUpgrade la Pro pentru acces nelimitat.';
  @override String get proUpgradeBtn       => 'Upgrade la Pro';
  @override String get proLaterBtn         => 'Nu acum';
  @override String get proUsageOf          => 'din';

  // Phase 2 — Subscription
  @override String get subTitle            => 'CNC Assist Pro';
  @override String get subSubtitle         => 'Deblochează accesul nelimitat';
  @override String get subMonthly          => '19\$ / lună';
  @override String get subFeatureUnlimited => 'Întrebări AI nelimitate';
  @override String get subFeatureSetup     => 'Generator fișă de lucru';
  @override String get subFeatureTooling   => 'Recomandări scule';
  @override String get subFeaturePdf       => 'Analizor desene PDF';
  @override String get subSubscribeBtn     => 'Abonează-te acum';
  @override String get subRestoreBtn       => 'Restaurează achiziția';
  @override String get subCurrentPlan      => 'Plan curent';
  @override String get subManageBtn        => 'Gestionează abonamentul';
  @override String get subLoading          => 'Se procesează...';
  @override String get subError            => 'Achiziție eșuată. Încearcă din nou.';
  @override String get subSuccess          => 'Bine ai venit la CNC Assist Pro!';
  @override String get subNotAvailable     => 'Achizițiile nu sunt disponibile pe acest dispozitiv.';

  // Phase 3 — Setup Sheet
  @override String get setupSheetTitle     => 'Fișă de lucru';
  @override String get setupSheetBtn       => 'Generează fișă de lucru';
  @override String get setupSheetShare     => 'Distribuie / Printează';
  @override String get setupSheetDate      => 'Data';
  @override String get setupSheetProOnly   => 'Funcție Pro — upgrade pentru fișe de lucru';

  // Phase 4 — Tooling Recs
  @override String get toolingTitle        => 'Recomandări scule';
  @override String get toolingBtn          => 'Obține recomandări scule';
  @override String get toolingLoading      => 'Analizez parametrii...';
  @override String get toolingProOnly      => 'Funcție Pro — upgrade pentru recomandări scule';

  // Phase 5 — PDF Analyzer
  @override String get pdfTitle            => 'Analizor desene PDF';
  @override String get pdfBtn              => 'Analizează desen PDF';
  @override String get pdfLoading          => 'Analizez PDF...';
  @override String get pdfPickBtn          => 'Selectează fișier PDF';
  @override String get pdfProOnly          => 'Funcție Pro — upgrade pentru a analiza desene PDF';
  @override String get pdfError            => 'Eroare la analizarea PDF';
  @override String get pdfTooLarge         => 'PDF prea mare (max 10MB)';

  // Settings — Subscription
  @override String get settingsSubscription => 'Abonament';
  @override String get settingsFreePlan     => 'Plan Gratuit · 10 întrebări AI/lună';
  @override String get settingsProPlan      => 'Plan Pro · Acces nelimitat';
  @override String get settingsUpgradePro   => 'Upgrade la Pro';

  // Language names
  @override String get settingsLanguageFa  => 'فارسی';
  @override String get settingsLanguageAr  => 'العربية';

  // G-code reference
  @override String get gcodeRefTitle       => 'Referință G-Code';
  @override String get gcodeRefSearchHint  => 'Caută cod sau cuvânt cheie…';
  @override String get gcodeRefFilterAll   => 'Toate';
  @override String get gcodeRefNoResults   => 'Niciun cod găsit';
  @override String get gcodeRefSyntax      => 'Sintaxă';
  @override String get gcodeRefCount       => 'coduri';

  // Help
  @override String get helpBtnLabel => 'Cum se utilizează?';

  @override String get helpCalcTitle => 'Calculator Avans & Viteză';
  @override List<String> get helpCalcSteps => [
    'Selectați un material din listă (oțel, aluminiu, titan, etc.).',
    'Introduceți diametrul sculei și numărul de tăișuri, apoi setați adâncimea și lățimea de tăiere.',
    'Alegeți materialul sculei (Carbură sau HSS) și tipul operației (Degroșare sau Finisare).',
    'Apăsați Calculează — RPM, Avans, Sarcina pe tăiș și MRR sunt afișate instant.\nApăsați Salvează pentru a stoca rezultatul în Istoric.',
  ];

  @override String get helpGcodeTitle => 'Analizor G-Code';
  @override List<String> get helpGcodeSteps => [
    'Lipiți G-code în câmpul text sau apăsați Încărcare pentru a deschide un fișier .nc / .txt / .mpf.',
    'Selectați tipul de controler (Haas sau Sinumerik) sau lăsați pe Auto — aplicația detectează automat.',
    'Apăsați Analizează G-Code pentru a rula verificarea.',
    'Liniile roșii conțin erori; liniile galbene conțin avertismente. Apăsați orice linie pentru detalii.',
  ];

  @override String get helpKbTitle => 'Baza de cunoștințe CNC';
  @override List<String> get helpKbSteps => [
    'Tastați orice întrebare CNC (G-code, viteze, depanare) și trimiteți.',
    'AI-ul (Claude) răspunde pe baza cunoștințelor de prelucrare CNC.',
    'Plan Gratuit: 10 întrebări pe lună. Faceți upgrade la Pro pentru acces nelimitat.',
    'Apăsați iconița carte pentru Referința G-Code sau iconița alarmă pentru Referința Erorilor.',
  ];

  @override String get helpGcodeRefTitle => 'Referință G-Code';
  @override List<String> get helpGcodeRefSteps => [
    'Răsfoiți peste 270 de coduri G și M pentru Haas, Siemens, FANUC și Heidenhain.',
    'Folosiți filtrele de marcă pentru a afișa codurile fiecărui controler.',
    'Tastați în câmpul de căutare pentru a găsi instant un cod sau cuvânt cheie.',
    'Apăsați orice cod pentru descriere completă, exemplu de sintaxă și avertismente.',
  ];

  @override String get helpErrRefTitle => 'Referință Alarme & Erori';
  @override List<String> get helpErrRefSteps => [
    'Căutați după numărul alarmei sau cuvânt cheie (ex: "arbore" sau "450").',
    'Folosiți filtrul de marcă pentru a restrânge rezultatele la controlerul dvs.',
    'Apăsați orice alarmă pentru cauzele posibile și soluții pas cu pas.',
  ];

  @override String get helpHistoryTitle => 'Istoric';
  @override List<String> get helpHistorySteps => [
    'Calculele și analizele G-code salvate sunt stocate aici.',
    'După calcul, apăsați Salvează în panoul de rezultate pentru a adăuga o înregistrare.',
    'După analiza G-code, apăsați Salvează în fila Rezumat.',
    'Apăsați orice înregistrare pentru detalii complete; glisați la stânga pentru a șterge.',
  ];
}
