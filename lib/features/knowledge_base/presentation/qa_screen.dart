import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../data/errors_repository.dart';

final _errorsRepoQaProvider = Provider((_) => ErrorsRepository());

class QaScreen extends ConsumerStatefulWidget {
  const QaScreen({super.key});

  @override
  ConsumerState<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends ConsumerState<QaScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages   = <_Message>[];
  bool  _isLoading  = false;

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

  // Detects alarm/error codes in the user's question.
  // Matches patterns like: "alarm 101", "error 101", "Alarm: 101",
  // "10620", "380500", or plain 3-6 digit numbers typical of alarm codes.
  static final _alarmCodePattern = RegExp(
    r'(?:alarm|alarmă|error|eroare|fault|code)[:\s#]*(\d{3,6})'
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final s = ref.read(appStringsProvider);
    try {
      final alarmCtx = await _lookupAlarmContext(text);
      final answer   = await _askClaude(text, alarmCtx);
      setState(() {
        _messages.add(_Message(text: answer, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(
          text: '${s.commonError}: $e',
          isUser: false,
          isPending: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _askClaude(String question, String? alarmContext) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
    final body = <String, dynamic>{'question': question};
    if (alarmContext != null) body['alarmContext'] = alarmContext;
    final response = await supabase.functions.invoke('ask-claude', body: body);
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.kbTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, size: 20),
            tooltip: s.errRefTitle,
            onPressed: () => context.push(RouteNames.errorReference),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_messages.isEmpty) _QuickQuestionsBar(
            questions: _quickQuestions,
            onTap: _sendMessage,
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
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          _InputBar(
            controller: _controller,
            hint:       s.kbInputHint,
            onSend:     _sendMessage,
            isLoading:  _isLoading,
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final bool isPending;
  const _Message({required this.text, required this.isUser, this.isPending = false});
}

class _QuickQuestionsBar extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String> onTap;
  const _QuickQuestionsBar({required this.questions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount:        questions.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
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
  final AppStrings s;
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(s.kbEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onErrorRef,
              icon: const Icon(Icons.warning_amber_outlined, size: 16),
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
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32, height: 32,
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
                color: message.isUser ? AppColors.primaryDim : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: message.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isPending ? AppColors.textSecondary : AppColors.textPrimary,
                  fontStyle: message.isPending ? FontStyle.italic : FontStyle.normal,
                ),
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
  final String hint;
  final ValueChanged<String> onSend;
  final bool isLoading;
  const _InputBar({required this.controller, required this.hint, required this.onSend, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines:   4,
              minLines:   1,
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : onSend,
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
            icon: const Icon(Icons.send),
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
