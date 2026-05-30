import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/quiz_repository.dart';

final _quizProvider = FutureProvider((ref) => QuizRepository().getAll());

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;

  void _select(int i, QuizQuestion q) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == q.answerIndex) _score++;
    });
  }

  void _next(int total) {
    setState(() {
      if (_index < total - 1) {
        _index++;
        _selected = null;
        _answered = false;
      } else {
        _index = total; // finished marker
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final async = ref.watch(_quizProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.toolQuiz)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (questions) {
          if (_index >= questions.length) {
            return _Results(
                score: _score, total: questions.length, onRestart: _restart);
          }
          final q = questions[_index];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Text('${_index + 1} / ${questions.length}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                Chip(
                  label: Text(q.category,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surfaceAlt,
                  side: const BorderSide(color: AppColors.border),
                ),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_index + 1) / questions.length,
                backgroundColor: AppColors.surfaceAlt,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(q.question,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ...List.generate(q.options.length, (i) {
                Color border = AppColors.border;
                Color bg = AppColors.surface;
                if (_answered) {
                  if (i == q.answerIndex) {
                    border = AppColors.successGreen;
                    bg = AppColors.successGreen.withValues(alpha: 0.12);
                  } else if (i == _selected) {
                    border = AppColors.errorRed;
                    bg = AppColors.errorRed.withValues(alpha: 0.12);
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _select(i, q),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(children: [
                        Text(String.fromCharCode(65 + i),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q.options[i])),
                        if (_answered && i == q.answerIndex)
                          const Icon(Icons.check_circle,
                              color: AppColors.successGreen, size: 18),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              if (_answered)
                ElevatedButton(
                  onPressed: () => _next(questions.length),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                        _index < questions.length - 1
                            ? s.quizNext
                            : s.quizFinish,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;
  const _Results(
      {required this.score, required this.total, required this.onRestart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final pct = total == 0 ? 0 : (score / total * 100).round();
    final good = pct >= 60;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(good ? Icons.emoji_events : Icons.school,
              size: 64,
              color: good ? AppColors.successGreen : AppColors.warningYellow),
          const SizedBox(height: 16),
          Text('${s.quizScore}: $score / $total',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$pct%',
              style: const TextStyle(
                  fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(s.quizRestart),
          ),
        ],
      ),
    );
  }
}
