import 'dart:convert';
import 'package:flutter/services.dart';

class QuizQuestion {
  final String category;
  final String question;
  final List<String> options;
  final int answerIndex;

  const QuizQuestion({
    required this.category,
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        category: j['category'] as String,
        question: j['q'] as String,
        options: (j['options'] as List).cast<String>(),
        answerIndex: j['answer'] as int,
      );
}

class QuizRepository {
  List<QuizQuestion>? _cache;

  Future<List<QuizQuestion>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/quiz.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (data['questions'] as List)
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
