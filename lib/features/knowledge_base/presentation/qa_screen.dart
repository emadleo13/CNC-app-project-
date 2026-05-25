import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../data/errors_repository.dart';
import '../data/usage_repository.dart';

final _errorsRepoQaProvider = Provider((_) => ErrorsRepository());

class QaScreen extends ConsumerStatefulWidget {
  const QaScreen({super.key});

  @override
  ConsumerState<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends ConsumerState<QaScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _messages    = <_Message>[];
  bool       _isLoading    = false;
  Uint8List? _attachedBytes;

  static const _quickQuestions = [
    'What is the difference between G00 and G01?',
    'How do I calculate tap feed rate?',
    'What does CYCLE83 do in Sinumerik?',
    'How to use G41/G42 cutter compensation?',
    'What is CSS (G96) in turning?',
    'Haas Alarm 101 — what does it mean?',
    'Sinumerik alarm 22010 — axis not homed',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file   = await picker.pickImage(
        source:       source,
        maxWidth:     1280,
        maxHeight:    960,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _attachedBytes = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(appStringsProvider).imgPickError),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  void _showImagePicker() {
    final s = ref.read(appStringsProvider);
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
              onTap:   () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title:   Text(s.imgPickGallery),
              onTap:   () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── PDF picker (Phase 5) ──────────────────────────────────────────────────

  Future<void> _pickAndSendPdf() async {
    final s = ref.read(appStringsProvider);
    try {
      final result = await FilePicker.platform.pickFiles(
        type:          FileType.custom,
        allowedExtensions: ['pdf'],
        withData:      true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.pdfTooLarge),
            backgroundColor: AppColors.errorRed,
          ));
        }
        return;
      }

      setState(() {
        _messages.add(_Message(text: '📄 ${result.files.single.name}', isUser: true));
        _isLoading = true;
      });
      _scrollToBottom();

      final answer = await _sendPdfToClaude(base64Encode(bytes));
      setState(() {
        _messages.add(_Message(text: answer, isUser: false));
        _isLoading = false;
      });
      ref.invalidate(usageProvider);
    } catch (e) {
      final errS = ref.read(appStringsProvider);
      setState(() {
        _messages.add(_Message(
          text: '${errS.pdfError}: $e',
          isUser: false, isPending: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _sendPdfToClaude(String pdfBase64) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
    final response = await supabase.functions.invoke('analyze-pdf', body: {
      'pdfBase64': pdfBase64,
    });

    if (response.status == 403) {
      final data = response.data as Map<String, dynamic>?;
      if (data?['pro_required'] == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.push(RouteNames.subscription);
        });
        return ref.read(appStringsProvider).pdfProOnly;
      }
    }

    if (response.status != 200) {
      final msg = (response.data as Map<String, dynamic>?)?['error'] ?? 'Error ${response.status}';
      throw Exception(msg);
    }
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }

  // ─── alarm lookup ──────────────────────────────────────────────────────────

  static final _alarmCodePattern = RegExp(
    r'(?:alarm|alarmă|error|eroare|fault|code|آلارم|خطا)[:\s#]*(\d{3,6})'
    r'|(?<!\d)(\d{3,6})(?!\d)',
    caseSensitive: false,
  );

  Future<String?> _lookupAlarmContext(String question) async {
    final matches = _alarmCodePattern.allMatches(question);
    final repo    = ref.read(_errorsRepoQaProvider);
    final buffer  = StringBuffer();
    for (final m in matches) {
      final code  = (m.group(1) ?? m.group(2))!;
      final alarm = await repo.findByCode(code);
      if (alarm != null) {
        buffer.writeln('[ALARM CONTEXT: ${alarm.machine.toUpperCase()} ${alarm.code}]');
        buffer.writeln('Title: ${alarm.title}');
        buffer.writeln('Description: ${alarm.description}');
        buffer.writeln('Possible causes: ${alarm.possibleCauses.join('; ')}');
        buffer.writeln('Solutions: ${alarm.solutions.join('; ')}');
        buffer.writeln();
      }
    }
    return buffer.isEmpty ? null : buffer.toString();
  }

  // ─── send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final bytes = _attachedBytes;
    if (text.trim().isEmpty && bytes == null) return;

    setState(() {
      _messages.add(_Message(
        text:       text.trim().isEmpty ? '' : text,
        isUser:     true,
        imageBytes: bytes,
      ));
      _controller.clear();
      _attachedBytes = null;
      _isLoading = true;
    });
    _scrollToBottom();

    final s = ref.read(appStringsProvider);
    try {
      String answer;
      if (bytes != null) {
        answer = await _askClaudeWithImage(text.trim(), bytes);
      } else {
        final alarmCtx = await _lookupAlarmContext(text);
        answer = await _askClaude(text, alarmCtx);
      }
      setState(() {
        _messages.add(_Message(text: answer, isUser: false));
        _isLoading = false;
      });
      // Refresh quota counter after successful call
      ref.invalidate(usageProvider);
    } catch (e) {
      final errText = e.toString();
      // 429 = quota exceeded
      if (errText.contains('quota_exceeded') || errText.contains('429')) {
        setState(() { _isLoading = false; });
        _showQuotaDialog();
        return;
      }
      setState(() {
        _messages.add(_Message(
          text: '${s.commonError}: $errText',
          isUser: false, isPending: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _showQuotaDialog() {
    final s = ref.read(appStringsProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.lock_outline, color: AppColors.warningYellow, size: 22),
          const SizedBox(width: 8),
          Text(s.proLimitTitle),
        ]),
        content: Text(s.proLimitMsg,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.proLaterBtn,
              style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.subscription);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(s.proUpgradeBtn),
          ),
        ],
      ),
    );
  }

  Future<String> _askClaudeWithImage(String question, Uint8List imageBytes) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
    final body = <String, dynamic>{
      'imageBase64': base64Encode(imageBytes),
      'mediaType':   'image/jpeg',
      'mode':        'error_diagnosis',
      if (question.isNotEmpty) 'question': question,
    };
    final response = await supabase.functions.invoke('analyze-image', body: body);
    if (response.status == 429) {
      throw Exception('quota_exceeded');
    }
    if (response.status != 200) {
      final msg = (response.data as Map<String, dynamic>?)?['error'] ?? 'Server error ${response.status}';
      throw Exception(msg);
    }
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }

  Future<String> _askClaude(String question, String? alarmContext) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
    final body = <String, dynamic>{'question': question};
    if (alarmContext != null) body['alarmContext'] = alarmContext;
    final response = await supabase.functions.invoke('ask-claude', body: body);
    if (response.status == 429) {
      throw Exception('quota_exceeded');
    }
    if (response.status != 200) {
      final msg = (response.data as Map<String, dynamic>?)?['error'] ?? 'Server error ${response.status}';
      throw Exception(msg);
    }
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s     = ref.watch(appStringsProvider);
    final usage = ref.watch(usageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.kbTitle),
        actions: [
          IconButton(
            icon:    const Icon(Icons.warning_amber_outlined, size: 20),
            tooltip: s.errRefTitle,
            onPressed: () => context.push(RouteNames.errorReference),
          ),
          IconButton(
            icon:    const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Usage quota bar
          usage.when(
            loading: () => const SizedBox.shrink(),
            error:   (e, st) => const SizedBox.shrink(),
            data: (u) => u.isPro
                ? const SizedBox.shrink()
                : _QuotaBar(status: u, s: s, onUpgrade: () => context.push(RouteNames.subscription)),
          ),

          if (_messages.isEmpty) _QuickQuestionsBar(
            questions: _quickQuestions,
            onTap:     _sendMessage,
          ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(s: s, onErrorRef: () => context.push(RouteNames.errorReference))
                : ListView.builder(
                    controller:  _scrollCtrl,
                    padding:     const EdgeInsets.all(16),
                    itemCount:   _messages.length,
                    itemBuilder: (ctx, i) => _MessageBubble(message: _messages[i]),
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(
            backgroundColor: AppColors.surface,
            valueColor:      AlwaysStoppedAnimation(AppColors.primary),
          ),
          if (_attachedBytes != null)
            Container(
              color:   AppColors.surface,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(_attachedBytes!, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s.imgAttached,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                IconButton(
                  icon:  const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => setState(() => _attachedBytes = null),
                ),
              ]),
            ),
          _InputBar(
            controller:  _controller,
            hint:        s.kbInputHint,
            onSend:      _sendMessage,
            isLoading:   _isLoading,
            onAttach:    _showImagePicker,
            onPdf:       _pickAndSendPdf,
            hasAttached: _attachedBytes != null,
          ),
        ],
      ),
    );
  }
}

// ─── Usage Quota Bar ──────────────────────────────────────────────────────────

class _QuotaBar extends StatelessWidget {
  final UsageStatus   status;
  final AppStrings    s;
  final VoidCallback  onUpgrade;
  const _QuotaBar({required this.status, required this.s, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final color = status.isLimitReached
        ? AppColors.errorRed
        : status.fraction > 0.7
            ? AppColors.warningYellow
            : AppColors.primary;

    return GestureDetector(
      onTap: status.isLimitReached ? onUpgrade : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: AppColors.surface,
        child: Row(children: [
          Icon(
            status.isLimitReached ? Icons.lock_outline : Icons.bolt_outlined,
            size:  14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status.isLimitReached
                ? s.proLimitTitle
                : '${status.remaining} ${s.proQuestionsLeft}',
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:           status.fraction,
                backgroundColor: AppColors.border,
                valueColor:      AlwaysStoppedAnimation(color),
                minHeight:       4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${status.used} ${s.proUsageOf} ${status.limit}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (status.isLimitReached) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s.proUpgradeBtn,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _Message {
  final String     text;
  final bool       isUser;
  final bool       isPending;
  final Uint8List? imageBytes;
  const _Message({
    required this.text, required this.isUser,
    this.isPending = false, this.imageBytes,
  });
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _QuickQuestionsBar extends StatelessWidget {
  final List<String>      questions;
  final ValueChanged<String> onTap;
  const _QuickQuestionsBar({required this.questions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color:  AppColors.surface,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount:        questions.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(questions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:        AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(questions[i],
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings   s;
  final VoidCallback onErrorRef;
  const _EmptyState({required this.s, required this.onErrorRef});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(s.kbEmptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.kbEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onErrorRef,
              icon:  const Icon(Icons.warning_amber_outlined, size: 16),
              label: Text(s.errRefTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:  message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width:  32, height: 32,
              decoration: BoxDecoration(
                color:        AppColors.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:  message.isUser ? AppColors.primaryDim : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: message.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 220, height: 160, fit: BoxFit.cover,
                      ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize:  14,
                        color:     message.isPending ? AppColors.textSecondary : AppColors.textPrimary,
                        fontStyle: message.isPending ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final String         hint;
  final ValueChanged<String> onSend;
  final bool           isLoading;
  final VoidCallback   onAttach;
  final VoidCallback   onPdf;
  final bool           hasAttached;
  const _InputBar({
    required this.controller, required this.hint,
    required this.onSend,     required this.isLoading,
    required this.onAttach,   required this.onPdf,
    required this.hasAttached,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 16),
      decoration: const BoxDecoration(
        color:  AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          IconButton(
            onPressed: isLoading ? null : onAttach,
            icon: Icon(
              Icons.camera_alt_outlined,
              color: hasAttached ? AppColors.primary : AppColors.textMuted,
            ),
            style: IconButton.styleFrom(
              backgroundColor: hasAttached ? AppColors.primaryDim : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : onPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textMuted),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            tooltip: 'PDF',
          ),
          Expanded(
            child: TextField(
              controller:      controller,
              maxLines:        4,
              minLines:        1,
              textInputAction: TextInputAction.send,
              onSubmitted:     isLoading ? null : onSend,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide:   BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isLoading ? null : () => onSend(controller.text),
            icon:  const Icon(Icons.send),
            color: AppColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryDim,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}
