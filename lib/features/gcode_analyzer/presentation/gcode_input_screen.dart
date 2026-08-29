import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/review/review_prompter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/help_card.dart';
import '../domain/cnc_dialect.dart';
import '../domain/gcode_line.dart';
import '../parsers/gcode_parser.dart';
import 'gcode_syntax.dart';

/// Runs in a background isolate (via [compute]) so parsing a large program
/// never blocks the UI thread.
List<GcodeLine> _parseGcodeIsolate(Map<String, dynamic> args) {
  final code    = args['code'] as String;
  final dialect = CncDialect.values[args['dialect'] as int];
  return GcodeParser.parse(code, dialect);
}

class GcodeInputScreen extends ConsumerStatefulWidget {
  const GcodeInputScreen({super.key});

  @override
  ConsumerState<GcodeInputScreen> createState() => _GcodeInputScreenState();
}

class _GcodeInputScreenState extends ConsumerState<GcodeInputScreen> {
  final _controller   = GcodeHighlightController();
  final _editorScroll = ScrollController();
  final _gutterScroll = ScrollController();
  late CncDialect _dialect;
  bool       _autoDetect   = true;
  bool       _isLoading    = false;
  bool       _isGenerating = false;
  Uint8List? _drawingBytes;
  // Cached auto-detected dialect so build()/keystrokes don't re-scan the whole
  // program every frame.
  CncDialect _detected = CncDialect.haas;
  // When a file too large to render in the editor is uploaded, we keep the full
  // text here and show only a preview in the TextField. Analysis still runs on
  // the full content. Cleared as soon as the user edits the editor by hand.
  String? _fullGcode;
  int      _fullLineCount = 0;

  // A live, editable TextField cannot hold a multi-MB program — Flutter lays out
  // the entire text and freezes the UI thread. Above this many characters we
  // load only a preview into the editor.
  static const int _editorPreviewLimit = 60000;

  // Monospace line metrics shared by the editor and its line-number gutter.
  static const double _editorFontSize = 13;
  static const double _editorLineHt   = 1.6;
  static const double _lineHeight      = _editorFontSize * _editorLineHt;
  static const double _editorTopPad    = 12;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(defaultDialectProvider);
    _dialect = switch (saved) {
      'sinumerik' => CncDialect.sinumerik,
      'generic'   => CncDialect.generic,
      _           => CncDialect.haas,
    };
    // Keep the gutter scroll position locked to the editor's.
    _editorScroll.addListener(() {
      if (!_gutterScroll.hasClients) return;
      final max = _gutterScroll.position.maxScrollExtent;
      _gutterScroll.jumpTo(_editorScroll.offset.clamp(0.0, max));
    });
  }

  Future<void> _pickFile(AppStrings s) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['nc', 'cnc', 'gcode', 'txt', 'mpf', 'spf'],
      );
      if (result != null && result.files.single.path != null) {
        final content = await File(result.files.single.path!).readAsString();
        final detected = GcodeParser.autoDetect(content);
        setState(() {
          _detected = detected;
          if (_autoDetect) _dialect = detected;
          if (content.length > _editorPreviewLimit) {
            // Keep the whole program for analysis; show only a preview so the
            // editor stays responsive.
            _fullGcode      = content;
            _fullLineCount  = '\n'.allMatches(content).length + 1;
            _controller.text = _previewOf(content);
          } else {
            _fullGcode       = null;
            _fullLineCount   = 0;
            _controller.text = content;
          }
        });
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

  // First chunk of a large program, cut at a line boundary so the preview never
  // ends mid-line.
  String _previewOf(String content) {
    var cut = content.lastIndexOf('\n', _editorPreviewLimit);
    if (cut <= 0) cut = _editorPreviewLimit;
    return content.substring(0, cut);
  }

  Future<void> _analyze(AppStrings s) async {
    // Analyse the full program even when the editor only shows a preview.
    final code = (_fullGcode ?? _controller.text).trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.gcodeEmptySnack),
          backgroundColor: AppColors.warningYellow,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final dialect = _autoDetect ? _detected : _dialect;
    setState(() => _isLoading = true);
    // Parse on a background isolate so a large file never blocks the UI thread.
    final lines = await compute(
      _parseGcodeIsolate,
      {'code': code, 'dialect': dialect.index},
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.go('/gcode/result', extra: {
      'gcode':   code,
      'dialect': dialect,
      'lines':   lines,
    });
    ReviewPrompter.recordSuccess();
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScroll.dispose();
    _gutterScroll.dispose();
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HelpCard(title: s.helpGcodeTitle, btnLabel: s.helpBtnLabel, steps: s.helpGcodeSteps),
            const SizedBox(height: 8),
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
                        onChanged: (v) => setState(() {
                          _autoDetect = v;
                          if (v) _detected = GcodeParser.autoDetect(_controller.text);
                        }),
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
                          '${s.gcodeDetected}: ${_detected.displayName}',
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

            if (_fullGcode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s.gcodeLargeFileNotice} ($_fullLineCount ${s.gcodeLines})',
                      style: const TextStyle(fontSize: 12, color: AppColors.infoBlue),
                    ),
                  ),
                ]),
              ),

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
                            onTap: () => setState(() {
                              _controller.clear();
                              _fullGcode     = null;
                              _fullLineCount = 0;
                            }),
                            child: const Icon(Icons.clear,
                                size: 16, color: AppColors.textMuted),
                          ),
                      ]),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LineNumberGutter(
                            scroll:     _gutterScroll,
                            lineCount:  lineCount < 1 ? 1 : lineCount,
                            lineHeight: _lineHeight,
                            topPad:     _editorTopPad,
                            fontSize:   _editorFontSize,
                          ),
                          const VerticalDivider(width: 1, thickness: 1),
                          Expanded(
                            child: TextField(
                              controller:      _controller,
                              scrollController: _editorScroll,
                              maxLines:   null,
                              expands:    true,
                              cursorColor: AppColors.primary,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize:   _editorFontSize,
                                color:      AppColors.textPrimary,
                                height:     _editorLineHt,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    '% \nO1000 (PROGRAM NAME)\nT1 M6\nG54 G90\nG43 H1 Z50.\nM3 S1000\nG0 X0 Y0\n...',
                                hintStyle: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize:   _editorFontSize,
                                  height:     _editorLineHt,
                                  color:      AppColors.textMuted,
                                ),
                                border:         InputBorder.none,
                                enabledBorder:  InputBorder.none,
                                focusedBorder:  InputBorder.none,
                                contentPadding: EdgeInsets.fromLTRB(12, _editorTopPad, 16, 12),
                              ),
                              onChanged: (v) => setState(() {
                                // Editing by hand replaces the preview — from now
                                // on the visible text is the source of truth.
                                _fullGcode     = null;
                                _fullLineCount = 0;
                                if (_autoDetect) _detected = GcodeParser.autoDetect(v);
                              }),
                            ),
                          ),
                        ],
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

/// Right-aligned line-number column that scrolls in lock-step with the editor.
class _LineNumberGutter extends StatelessWidget {
  final ScrollController scroll;
  final int    lineCount;
  final double lineHeight;
  final double topPad;
  final double fontSize;

  const _LineNumberGutter({
    required this.scroll,
    required this.lineCount,
    required this.lineHeight,
    required this.topPad,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Render every line number in a single Text (one render object) instead of
    // one widget per line. A real G-code program has thousands of lines; the
    // per-line Column laid them all out eagerly and froze the UI on upload.
    final numbers = StringBuffer();
    for (var i = 0; i < lineCount; i++) {
      if (i > 0) numbers.write('\n');
      numbers.write(i + 1);
    }
    return SizedBox(
      width: 44,
      child: SingleChildScrollView(
        controller: scroll,
        physics:    const NeverScrollableScrollPhysics(),
        padding:    EdgeInsets.only(top: topPad, bottom: 12),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            numbers.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize:   fontSize,
              height:     lineHeight / fontSize,
              color:      AppColors.gcodeN,
            ),
          ),
        ),
      ),
    );
  }
}
