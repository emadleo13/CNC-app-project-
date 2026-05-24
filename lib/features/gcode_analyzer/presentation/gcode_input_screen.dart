import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _controller   = TextEditingController();
  late CncDialect _dialect;
  bool       _autoDetect   = true;
  bool       _isLoading    = false; // ignore: prefer_final_fields
  bool       _isGenerating = false;
  Uint8List? _drawingBytes;

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

  Future<void> _pickDrawing(AppStrings s) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(s.imgPickSource,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title:   Text(s.imgPickCamera),
              onTap:   () async {
                Navigator.pop(context);
                await _captureDrawing(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title:   Text(s.imgPickGallery),
              onTap:   () async {
                Navigator.pop(context);
                await _captureDrawing(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _captureDrawing(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file   = await picker.pickImage(
        source:       source,
        maxWidth:     1600,
        maxHeight:    1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _drawingBytes = bytes);
      final s = ref.read(appStringsProvider);
      await _generateFromDrawing(s);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(appStringsProvider).imgPickError),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  Future<void> _generateFromDrawing(AppStrings s) async {
    final bytes = _drawingBytes;
    if (bytes == null) return;
    setState(() => _isGenerating = true);
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
      }
      final dialect = _autoDetect ? 'haas' : _dialect.name;
      final body = <String, dynamic>{
        'imageBase64': base64Encode(bytes),
        'mediaType':   'image/jpeg',
        'mode':        'drawing_to_gcode',
        'dialect':     dialect,
      };
      final response = await supabase.functions.invoke('analyze-image', body: body);
      if (response.status != 200) {
        throw Exception((response.data as Map<String, dynamic>?)?['error'] ?? 'Error ${response.status}');
      }
      final gcode = (response.data as Map<String, dynamic>)['answer'] as String;
      setState(() {
        _controller.text = gcode;
        _drawingBytes    = null;
        _isGenerating    = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${s.gcodeFromDrawingError}: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
      setState(() { _drawingBytes = null; _isGenerating = false; });
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
            onPressed: (_isLoading || _isGenerating) ? null : () => _pickDrawing(s),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(s.gcodeFromDrawing),
          ),
          TextButton.icon(
            onPressed: (_isLoading || _isGenerating) ? null : () => _pickFile(s),
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

            if (_isGenerating)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(s.gcodeFromDrawingGenerating,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                ]),
              ),
            if (_isGenerating) const SizedBox(height: 12),

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
