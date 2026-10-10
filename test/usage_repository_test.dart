import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/net/edge_functions.dart';
import 'package:cnc_assist/features/knowledge_base/data/usage_repository.dart';

UsageRepository _repo(Future<Map<String, dynamic>> Function(String name) answer) =>
    UsageRepository((name, {body, timeout = const Duration(seconds: 90)}) => answer(name));

void main() {
  test('after a reinstall the server count is shown: no free questions left', () async {
    final asked = <String>[];
    final status = await _repo((name) async {
      asked.add(name);
      return {'used': 10, 'limit': 10, 'pro': false};
    }).getMonthlyUsage();
    expect(asked, ['usage']);
    expect(status.isLimitReached, isTrue);
    expect(status.remaining, 0);
  });

  test('Pro from the server', () async {
    final status = await _repo((_) async => {'used': 40, 'limit': 10, 'pro': true})
        .getMonthlyUsage();
    expect(status.isPro, isTrue);
    expect(status.isLimitReached, isFalse);
  });

  test('backend without the usage function: falls back, does not throw', () async {
    final status = await _repo(
      (_) async => throw const EdgeFunctionError(EdgeErrorKind.server, status: 404),
    ).getMonthlyUsage();
    expect(status.isPro, isFalse);
    expect(status.limit, UsageStatus.freeLimit);
  });
}
