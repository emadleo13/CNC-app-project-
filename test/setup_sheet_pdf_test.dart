import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:cnc_assist/core/l10n/app_strings.dart';
import 'package:cnc_assist/core/l10n/strings_ar.dart';
import 'package:cnc_assist/core/l10n/strings_en.dart';
import 'package:cnc_assist/core/l10n/strings_fa.dart';
import 'package:cnc_assist/core/l10n/strings_ro.dart';
import 'package:cnc_assist/features/feed_speed/domain/cut_parameters.dart';
import 'package:cnc_assist/features/feed_speed/domain/material_spec.dart';
import 'package:cnc_assist/features/feed_speed/presentation/setup_sheet_pdf.dart';

final _material = MaterialSpec(
  code: 'steel_4140',
  name: '4140 Steel',
  nameFa: 'فولاد ۴۱۴۰',
  category: 'steel',
  hardnessBhn: 197,
  cuttingSpeedsMetric: const CuttingSpeedSet(
    hssRough: 20,
    hssFinish: 27,
    carbideRough: 80,
    carbideFinish: 110,
  ),
  cuttingSpeedsImperial: const CuttingSpeedSet(
    hssRough: 65,
    hssFinish: 90,
    carbideRough: 260,
    carbideFinish: 360,
  ),
  chipLoadFactors: const ChipLoadFactors(
    endMill2fl: 0.0015,
    endMill4fl: 0.0012,
    drill: 0.003,
    faceMill: 0.005,
  ),
  coolantRequired: true,
  notes: 'Pre-hardened. Reduce speeds 20% for hardened versions.',
);

const _result = CutParameters(
  rpm: 2546,
  feedRatePerMin: 509.2,
  chipLoad: 0.05,
  mrr: 5.09,
  cuttingSpeed: 80,
  units: UnitSystem.metric,
  materialNotes: 'Pre-hardened. Reduce speeds 20% for hardened versions.',
  coolantRequired: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (lang, AppStrings s, rtl) in [
    ('en', AppStringsEn(), false),
    ('ro', AppStringsRo(), false),
    ('fa', AppStringsFa(), true),
    ('ar', AppStringsAr(), true),
  ]) {
    test('setup sheet PDF builds in $lang with the bundled font', () async {
      final bytes = await buildSetupSheetPdf(
        format: PdfPageFormat.a4,
        s: s,
        rtl: rtl,
        result: _result,
        material: _material,
        diameter: 10,
        flutes: 4,
        units: UnitSystem.metric,
        operation: OperationType.roughing,
        date: DateTime(2026, 10, 8),
      );
      final pdf = latin1.decode(bytes);
      expect(pdf.startsWith('%PDF-'), isTrue);
      // The standard Helvetica has no Persian, Arabic or Romanian ș/ț
      // glyphs; the sheet must carry its own font.
      expect(pdf, contains('Vazirmatn'));
      expect(pdf, isNot(contains('/Helvetica')));
    });
  }
}
