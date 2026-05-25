import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/cut_parameters.dart';
import '../domain/material_spec.dart';
// OperationType + UnitSystem are defined in cut_parameters.dart (imported above)

class SetupSheetScreen extends ConsumerWidget {
  final CutParameters result;
  final MaterialSpec  material;
  final String        toolTypeCode;
  final double        diameter;
  final int           flutes;
  final UnitSystem    units;
  final OperationType operation;

  const SetupSheetScreen({
    super.key,
    required this.result,
    required this.material,
    required this.toolTypeCode,
    required this.diameter,
    required this.flutes,
    required this.units,
    required this.operation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.setupSheetTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.setupSheetShare,
            onPressed: () => _sharePdf(s),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _buildPdf(format, s),
        allowPrinting:   true,
        allowSharing:    true,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfPreviewPageDecoration: const BoxDecoration(
          color: AppColors.surface,
        ),
      ),
    );
  }

  Future<void> _sharePdf(AppStrings s) async {
    final bytes = await _buildPdf(PdfPageFormat.a4, s);
    await Printing.sharePdf(
      bytes:    bytes,
      filename: 'cnc_setup_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format, AppStrings s) async {
    final doc   = pw.Document();
    final now   = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final unitLabel = units == UnitSystem.metric ? 'mm' : 'in';
    final opLabel   = operation == OperationType.roughing ? s.operationRough : s.operationFinish;

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin:     const pw.EdgeInsets.all(32),
        build:      (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding:   const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('CNC ASSIST',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                      pw.SizedBox(height: 2),
                      pw.Text(s.setupSheetTitle,
                        style: pw.TextStyle(fontSize: 13, color: PdfColors.blueGrey600)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('${s.setupSheetDate}: $dateStr',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey600)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Material & Operation
              _pdfSection('MATERIAL & OPERATION', [
                _pdfRow(s.selectMaterial,  material.name),
                _pdfRow(s.labelOperation,  opLabel),
                _pdfRow(s.labelDiameter,   '$diameter $unitLabel'),
                _pdfRow(s.labelFlutes,     '$flutes'),
              ]),
              pw.SizedBox(height: 16),

              // Cutting Parameters
              _pdfSection('CUTTING PARAMETERS', [
                _pdfRow(s.resultRpm,          result.rpmFormatted),
                _pdfRow(s.resultFeedRate,      result.feedFormatted),
                _pdfRow(s.resultChipLoad,      result.chipLoadFormatted),
                _pdfRow(s.resultCuttingSpeed,  result.cuttingSpeedFormatted),
                _pdfRow(s.resultMrr,           result.mrrFormatted),
                _pdfRow(s.resultCoolant,
                    result.coolantRequired ? s.coolantRequired : s.coolantOptional),
              ]),

              if (result.materialNotes.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _pdfSection('NOTES', [
                  pw.Text(result.materialNotes,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey700)),
                ]),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.blueGrey200),
              pw.SizedBox(height: 4),
              pw.Text('Generated by CNC Assist · $dateStr',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400)),
            ],
          );
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  static pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width:   double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color:   PdfColors.blueGrey800,
          child:   pw.Text(title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
                color: PdfColors.white, letterSpacing: 1.0)),
        ),
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left:   pw.BorderSide(color: PdfColors.blueGrey200),
              right:  pw.BorderSide(color: PdfColors.blueGrey200),
              bottom: pw.BorderSide(color: PdfColors.blueGrey200),
            ),
          ),
          child: pw.Column(children: rows),
        ),
      ],
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey600)),
          pw.Text(value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
