import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/net/edge_functions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_answer.dart';
import '../../../core/widgets/help_card.dart';
import '../../../core/widgets/quota_dialog.dart';
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
      if (!mounted) return;
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
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type:          FileType.custom,
        allowedExtensions: ['pdf'],
        withData:      true,
      );
    } catch (_) {
      _showError(s.pdfError);
      return;
    }
    final bytes = result?.files.single.bytes;
    if (result == null || bytes == null || !mounted) return;
    if (bytes.length > 10 * 1024 * 1024) {
      _showError(s.pdfTooLarge);
      return;
    }

    setState(() {
      _messages.add(_Message(text: '📄 ${result!.files.single.name}', isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();
    await _runAiCall(
      () => _answerOf('analyze-pdf', {'pdfBase64': base64Encode(bytes)}),
    );
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: AppColors.errorRed,
    ));
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
    // What was said before this question, for a follow-up.
    final history = _history();

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

    if (bytes != null) {
      await _runAiCall(() => _answerOf('analyze-image', {
            'imageBase64': base64Encode(bytes),
            'mediaType':   'image/jpeg',
            'mode':        'error_diagnosis',
            if (text.trim().isNotEmpty) 'question': text.trim(),
          }));
    } else {
      await _runAiCall(() async {
        final alarmCtx = await _lookupAlarmContext(text);
        return _answerOf('ask-claude', {
          'question': text,
          'alarmContext': ?alarmCtx,
          if (history.isNotEmpty) 'history': history,
        });
      });
    }
  }

  /// The conversation so far, oldest first: each question (or what was
  /// attached) and each answer, without error notices. The server keeps the
  /// last few that fit.
  List<Map<String, String>> _history() {
    final turns = <Map<String, String>>[];
    for (final m in _messages) {
      if (m.isPending) continue;
      final text = m.isUser && m.text.isEmpty && m.imageBytes != null
          ? '[photo of a machine screen]'
          : m.text;
      if (text.isEmpty) continue;
      turns.add({'role': m.isUser ? 'user' : 'assistant', 'content': text});
    }
    // A last question that got no answer is not context.
    while (turns.isNotEmpty && turns.last['role'] == 'user') {
      turns.removeLast();
    }
    return turns.length > 8 ? turns.sublist(turns.length - 8) : turns;
  }

  void _newChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.clear();
      _attachedBytes = null;
    });
  }

  /// Calls an AI Edge Function and returns its answer. Every request says
  /// the app language, that this app renders Markdown, and how long it waits.
  Future<_Reply> _answerOf(String function, Map<String, dynamic> body) async {
    final data = await ref.read(edgeInvokerProvider)(
      function,
      body: {
        ...body,
        'language': ref.read(localeProvider),
        'format': 'markdown',
        'clientTimeout': kAiTimeout.inSeconds,
      },
      timeout: kAiTimeout,
    );
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const EdgeFunctionError(EdgeErrorKind.aiUnavailable);
    }
    return (text: answer, truncated: data['truncated'] == true);
  }

  /// Runs one AI request and puts its answer, or a readable error, in the
  /// chat. Quota and Pro limits open the upgrade paths instead.
  Future<void> _runAiCall(Future<_Reply> Function() call) async {
    final s = ref.read(appStringsProvider);
    _Reply? answer;
    EdgeFunctionError? failure;
    try {
      answer = await call();
    } on EdgeFunctionError catch (e) {
      failure = e;
    } catch (_) {
      failure = const EdgeFunctionError(EdgeErrorKind.server);
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (answer != null) {
        _messages.add(_Message(
          text:      answer.text,
          isUser:    false,
          truncated: answer.truncated,
        ));
      } else if (failure!.kind == EdgeErrorKind.proRequired) {
        _messages.add(_Message(text: s.pdfProOnly, isUser: false, isPending: true));
      } else if (failure.kind != EdgeErrorKind.quotaExceeded) {
        _messages.add(_Message(text: failure.message(s), isUser: false, isPending: true));
      }
    });
    _scrollToBottom();
    // The server counts every call, answered or refused.
    ref.invalidate(usageProvider);

    switch (failure?.kind) {
      case EdgeErrorKind.quotaExceeded:
        showQuotaDialog(context, s);
      case EdgeErrorKind.proRequired:
        context.push(RouteNames.subscription);
      default:
        break;
    }
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
            icon:    const Icon(Icons.code, size: 20),
            tooltip: s.gcodeRefTitle,
            onPressed: () => context.push(RouteNames.gcodeReference),
          ),
          IconButton(
            icon:    const Icon(Icons.warning_amber_outlined, size: 20),
            tooltip: s.errRefTitle,
            onPressed: () => context.push(RouteNames.errorReference),
          ),
          IconButton(
            icon:    const Icon(Icons.auto_awesome_motion_outlined, size: 20),
            tooltip: s.progLibTitle,
            onPressed: () => context.push(RouteNames.gcodeProgramLibrary),
          ),
          IconButton(
            icon:    const Icon(Icons.menu_book_outlined, size: 20),
            tooltip: s.guidesTitle,
            onPressed: () => context.push(RouteNames.cncGuides),
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

          if (_messages.isEmpty) HelpCard(
            title:    s.helpKbTitle,
            btnLabel: s.helpBtnLabel,
            steps:    s.helpKbSteps,
          ),
          if (_messages.isEmpty) _QuickQuestionsBar(
            questions: _quickQuestions,
            onTap:     _sendMessage,
          ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(s: s,
                    onErrorRef:   () => context.push(RouteNames.errorReference),
                    onGcodeRef:   () => context.push(RouteNames.gcodeReference),
                    onAsk:        _sendMessage,
                  )
                : ListView.builder(
                    controller:  _scrollCtrl,
                    padding:     const EdgeInsets.all(16),
                    itemCount:   _messages.length + 1,
                    itemBuilder: (ctx, i) => i == 0
                        ? Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _newChat,
                              icon:  const Icon(Icons.add_comment_outlined, size: 16),
                              label: Text(s.kbNewChat, style: const TextStyle(fontSize: 12)),
                            ),
                          )
                        : _MessageBubble(message: _messages[i - 1], s: s),
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
                  child: Image.memory(_attachedBytes!, width: 56, height: 56, fit: BoxFit.cover,
                    // A thumbnail of a photo up to 1280 px; twice the box so
                    // `cover` never has to enlarge it.
                    cacheWidth: (112 * MediaQuery.devicePixelRatioOf(context)).round()),
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

typedef _Reply = ({String text, bool truncated});

class _Message {
  final String     text;
  final bool       isUser;
  final bool       isPending;
  final Uint8List? imageBytes;

  /// The answer hit the server's length limit.
  final bool       truncated;
  const _Message({
    required this.text, required this.isUser,
    this.isPending = false, this.imageBytes, this.truncated = false,
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
  final VoidCallback onGcodeRef;
  final ValueChanged<String> onAsk;
  const _EmptyState({
    required this.s,
    required this.onErrorRef,
    required this.onGcodeRef,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 104, height: 104,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Image.asset(
                  'assets/images/emad_owl.png',
                  fit: BoxFit.contain,
                  // Decoded at the size shown (76 dp), not its 732 px.
                  cacheWidth: (76 * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
              ),
              const SizedBox(height: 18),
              Text(s.kbEmptyTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(s.kbEmptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 🔥 Popular questions
        Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(s.popularQuestions,
            style: const TextStyle(
              fontSize: 11, letterSpacing: 1.1,
              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),
        ...s.popularQuestionsList.map((q) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onAsk(q),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.help_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q, style: const TextStyle(fontSize: 13))),
                  const Icon(Icons.north_east, size: 14, color: AppColors.textMuted),
                ]),
              ),
            ),
          ),
        )),
        const SizedBox(height: 20),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onGcodeRef,
              icon:  const Icon(Icons.code, size: 16),
              label: Text(s.gcodeRefTitle),
            ),
            OutlinedButton.icon(
              onPressed: onErrorRef,
              icon:  const Icon(Icons.warning_amber_outlined, size: 16),
              label: Text(s.errRefTitle),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final AppStrings s;
  const _MessageBubble({required this.message, required this.s});

  bool get _canCopy =>
      !message.isUser && !message.isPending && message.text.isNotEmpty;

  void _copy(BuildContext context) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.progLibCopied), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Asymmetric corner on the "tail" side gives a more modern bubble shape.
    final radius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14), bottomRight: Radius.circular(4))
        : const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(14));

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
            child: Column(
              crossAxisAlignment:
                  message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:  message.isUser ? AppColors.primaryDim : AppColors.surface,
                    borderRadius: radius,
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
                            // Wide enough to cover 220 × 160 dp even for 16:9.
                            cacheWidth: (300 * MediaQuery.devicePixelRatioOf(context)).round(),
                          ),
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.text.isNotEmpty && !message.isUser && !message.isPending)
                        AiAnswer(
                          message.text,
                          onCodeCopied: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.progLibCopied), duration: const Duration(seconds: 1)),
                          ),
                        )
                      else if (message.text.isNotEmpty)
                        // A question in English reads left to right in the
                        // Persian app; "0.3-0.5" stays in order.
                        AiText(
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
                if (message.truncated)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text(s.kbAnswerCutOff,
                      style: const TextStyle(
                        fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                  ),
                if (_canCopy)
                  InkWell(
                    onTap: () => _copy(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(s.commonCopy,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
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
