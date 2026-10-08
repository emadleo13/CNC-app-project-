import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/cut_parameters.dart';
import '../domain/material_spec.dart';
import 'setup_sheet_pdf.dart';
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
    final rtl = const {'fa', 'ar'}.contains(ref.watch(localeProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.setupSheetTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.setupSheetShare,
            onPressed: () => _sharePdf(s, rtl),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _buildPdf(format, s, rtl),
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

  Future<void> _sharePdf(AppStrings s, bool rtl) async {
    final bytes = await _buildPdf(PdfPageFormat.a4, s, rtl);
    await Printing.sharePdf(
      bytes:    bytes,
      filename: 'cnc_setup_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format, AppStrings s, bool rtl) =>
      buildSetupSheetPdf(
        format:    format,
        s:         s,
        rtl:       rtl,
        result:    result,
        material:  material,
        diameter:  diameter,
        flutes:    flutes,
        units:     units,
        operation: operation,
      );
}
