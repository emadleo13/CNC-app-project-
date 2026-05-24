import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/cnc_dialect.dart';
import '../parsers/gcode_parser.dart';

class GcodeInputScreen extends ConsumerStatefulWidget {
  const GcodeInputScreen({super.key});

  @override
  ConsumerState<GcodeInputScreen> createState() => _GcodeInputScreenState();
}

class _GcodeInputScreenState extends ConsumerState<GcodeInputScreen> {
  final _controller = TextEditingController();
  late CncDialect _dialect;
  bool _autoDetect = true;
  // ignore: prefer_final_fields
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(defaultDialectProvider);
    _dialect = switch (saved) {
      'sinumerik' => CncDialect.sinumerik,
      'generic'   => CncDialect.generic,
      _           => CncDialect.haas,
    };
  }

  Future<void> _pickFile(AppStrings s) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['nc', 'cnc', 'gcode', 'txt', 'mpf', 'spf'],
      );
      if (result != null && result.files.single.path != null) {
        final content = await File(result.files.single.path!).readAsString();
        setState(() => _controller.text = content);
        if (_autoDetect) {
          setState(() => _dialect = GcodeParser.autoDetect(content));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.gcodeFileError}: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _analyze(AppStrings s) {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.gcodeEmptySnack),
          backgroundColor: AppColors.warningYellow,
        ),
      );
      return;
    }

    final dialect = _autoDetect ? GcodeParser.autoDetect(code) : _dialect;
    final lines   = GcodeParser.parse(code, dialect);

    context.go('/gcode/result', extra: {
      'gcode':   code,
      'dialect': dialect,
      'lines':   lines,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s         = ref.watch(appStringsProvider);
    final charCount = _controller.text.length;
    final lineCount = '\n'.allMatches(_controller.text).length +
        (_controller.text.isNotEmpty ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.gcodeTitle),
        actions: [
          TextButton.icon(
            onPressed: () => _pickFile(s),
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(s.gcodeUpload),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialect selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(s.gcodeController,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.1)),
                      const Spacer(),
                      Switch(
                        value:     _autoDetect,
                        onChanged: (v) => setState(() => _autoDetect = v),
                        activeThumbColor: AppColors.primary,
                      ),
                      Text(s.gcodeAuto,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                    if (!_autoDetect) ...[
                      const SizedBox(height: 8),
                      SegmentedButton<CncDialect>(
                        segments: const [
                          ButtonSegment(value: CncDialect.haas,      label: Text('Haas')),
                          ButtonSegment(value: CncDialect.sinumerik, label: Text('Sinumerik')),
                          ButtonSegment(value: CncDialect.generic,   label: Text('Generic')),
                        ],
                        selected: {_dialect},
                        onSelectionChanged: (v) =>
                            setState(() => _dialect = v.first),
                      ),
                    ],
                    if (_autoDetect && _controller.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.auto_awesome,
                            size: 13, color: AppColors.successGreen),
                        const SizedBox(width: 4),
                        Text(
                          '${s.gcodeDetected}: ${GcodeParser.autoDetect(_controller.text).displayName}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.successGreen),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // G-code input area
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(children: [
                        Text(s.gcodeLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.1)),
                        const Spacer(),
                        if (_controller.text.isNotEmpty)
                          Text('$lineCount lines · $charCount chars',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _controller.clear()),
                            child: const Icon(Icons.clear,
                                size: 16, color: AppColors.textMuted),
                          ),
                      ]),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines:   null,
                        expands:    true,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize:   13,
                          color:      AppColors.textPrimary,
                          height:     1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              '% \nO1000 (PROGRAM NAME)\nT1 M6\nG54 G90\nG43 H1 Z50.\nM3 S1000\nG0 X0 Y0\n...',
                          border:         InputBorder.none,
                          enabledBorder:  InputBorder.none,
                          focusedBorder:  InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : () => _analyze(s),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width:  20,
                      child:  CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, size: 18),
                          const SizedBox(width: 8),
                          Text(s.gcodeAnalyzeBtn,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
