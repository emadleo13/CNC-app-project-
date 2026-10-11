import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/review/review_prompter.dart';

void main() {
  final now = DateTime(2026, 10, 11);
  bool due(int wins, [DateTime? lastAsked]) =>
      ReviewPrompter.due(wins: wins, lastAsked: lastAsked, now: now);

  test('first ask after three wins, not before', () {
    expect(due(2), isFalse);
    expect(due(3), isTrue);
  });

  test('again only after 30 days and three more wins', () {
    expect(due(10, now.subtract(const Duration(days: 29))), isFalse);
    expect(due(2, now.subtract(const Duration(days: 40))), isFalse);
    expect(due(3, now.subtract(const Duration(days: 30))), isTrue);
  });
}
