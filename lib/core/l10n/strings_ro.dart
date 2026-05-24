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
  @override String get errRefFilterAll      => 'Toate';
  @override String get errRefFilterHaas     => 'Haas';
  @override String get errRefFilterSiemens  => 'Siemens';
  @override String get errRefNoResults      => 'Nicio alarmă găsită';
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
}
