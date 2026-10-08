import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/l10n/app_strings.dart';
import '../domain/cut_parameters.dart';
import '../domain/material_spec.dart';

/// The setup sheet as a PDF in the app language.
///
/// The PDF standard fonts have no Persian or Arabic letters and not even
/// Romanian ș/ț, which printed as blanks. The bundled Vazirmatn covers all
/// four languages. Persian and Arabic sheets run right to left; values,
/// material names, notes and dates stay left to right unless they are in
/// Arabic script, so "Aluminum 6061" never turns into "6061 Aluminum".
Future<Uint8List> buildSetupSheetPdf({
  required PdfPageFormat format,
  required AppStrings s,
  required bool rtl,
  required CutParameters result,
  required MaterialSpec material,
  required double diameter,
  required int flutes,
  required UnitSystem units,
  required OperationType operation,
  DateTime? date,
}) async {
  final (regular, bold) = await _fonts();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final now = date ?? DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final unitLabel = units == UnitSystem.metric ? 'mm' : 'in';
  final opLabel = operation == OperationType.roughing
      ? s.operationRough
      : s.operationFinish;

  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CNC ASSIST',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      _text(
                        s.setupSheetTitle,
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.blueGrey600,
                        ),
                      ),
                    ],
                  ),
                  _labelled('${s.setupSheetDate}:', dateStr, 11),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Material & Operation
            _pdfSection(s.setupSheetSectionMaterial, [
              _pdfRow(s.selectMaterial, material.name),
              _pdfRow(s.labelOperation, opLabel),
              _pdfRow(s.labelDiameter, '$diameter $unitLabel'),
              _pdfRow(s.labelFlutes, '$flutes'),
            ]),
            pw.SizedBox(height: 16),

            // Cutting Parameters
            _pdfSection(s.setupSheetSectionCutting, [
              _pdfRow(s.resultRpm, result.rpmFormatted),
              _pdfRow(s.resultFeedRate, result.feedFormatted),
              _pdfRow(s.resultChipLoad, result.chipLoadFormatted),
              _pdfRow(s.resultCuttingSpeed, result.cuttingSpeedFormatted),
              _pdfRow(s.resultMrr, result.mrrFormatted),
              _pdfRow(
                s.resultCoolant,
                result.coolantRequired ? s.coolantRequired : s.coolantOptional,
              ),
            ]),

            if (result.materialNotes.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _pdfSection(s.setupSheetSectionNotes, [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  child: _text(
                    result.materialNotes,
                    textDirection: _directionOf(result.materialNotes),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                ),
              ]),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(color: PdfColors.blueGrey200),
            pw.SizedBox(height: 4),
            _labelled(
              '${s.setupSheetGeneratedBy} ·',
              dateStr,
              9,
              color: PdfColors.blueGrey400,
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

(pw.Font, pw.Font)? _loaded;

Future<(pw.Font, pw.Font)> _fonts() async => _loaded ??= (
  pw.Font.ttf(await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf')),
  pw.Font.ttf(await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf')),
);

final _arabicScript = RegExp(r'[\u0600-\u06FF]');

/// Text for the PDF. The PDF shaper ignores the zero-width non-joiner and
/// would join "تهیه‌شده" into one word; a space ("تهیه شده") is the usual
/// alternative in Persian.
pw.Text _text(
  String text, {
  pw.TextStyle? style,
  pw.TextDirection? textDirection,
}) => pw.Text(
  text.replaceAll('\u200C', ' '),
  style: style,
  textDirection: textDirection,
);

/// "label 2026-10-08" with the value in its own left-to-right run. Inside
/// right-to-left text the PDF reorders "2026-10-08" into "08-10-2026".
pw.Widget _labelled(
  String label,
  String value,
  double fontSize, {
  PdfColor color = PdfColors.blueGrey600,
}) {
  final style = pw.TextStyle(fontSize: fontSize, color: color);
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      _text(label, style: style),
      pw.SizedBox(width: fontSize / 3),
      pw.Text(value, style: style, textDirection: pw.TextDirection.ltr),
    ],
  );
}

/// Right to left only for text in Arabic script: values, units and English
/// names keep their order on a Persian or Arabic sheet.
pw.TextDirection _directionOf(String text) =>
    _arabicScript.hasMatch(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: PdfColors.blueGrey800,
        child: _text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            // Spacing letters apart breaks Arabic-script joining.
            letterSpacing: _arabicScript.hasMatch(title) ? 0 : 1.0,
          ),
        ),
      ),
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.blueGrey200),
            right: pw.BorderSide(color: PdfColors.blueGrey200),
            bottom: pw.BorderSide(color: PdfColors.blueGrey200),
          ),
        ),
        child: pw.Column(children: rows),
      ),
    ],
  );
}

pw.Widget _pdfRow(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey600),
        ),
        _text(
          value,
          textDirection: _directionOf(value),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}
