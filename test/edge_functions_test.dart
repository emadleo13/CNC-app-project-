import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/l10n/strings_en.dart';
import 'package:cnc_assist/core/l10n/strings_fa.dart';
import 'package:cnc_assist/core/net/edge_functions.dart';

void main() {
  EdgeErrorKind kindOf(int status, Object? body) =>
      EdgeFunctionError.fromResponse(status, body).kind;

  group('EdgeFunctionError.fromResponse', () {
    test('quota: new code, old flag, or bare 429', () {
      expect(
        kindOf(429, {'code': 'quota_exceeded', 'quota_exceeded': true}),
        EdgeErrorKind.quotaExceeded,
      );
      expect(
        kindOf(429, {
          'error': 'Monthly quota exceeded',
          'quota_exceeded': true,
        }),
        EdgeErrorKind.quotaExceeded,
      );
      expect(kindOf(429, null), EdgeErrorKind.quotaExceeded);
    });

    test('Pro required: 403 with the code or the old flag', () {
      expect(
        kindOf(403, {'code': 'pro_required', 'pro_required': true}),
        EdgeErrorKind.proRequired,
      );
      expect(
        kindOf(403, {
          'error': 'Pro subscription required',
          'pro_required': true,
        }),
        EdgeErrorKind.proRequired,
      );
      // A 403 for any other reason is not a paywall.
      expect(kindOf(403, {'error': 'Forbidden'}), EdgeErrorKind.server);
    });

    test('model outages and oversize uploads', () {
      expect(
        kindOf(503, {'code': 'ai_unavailable'}),
        EdgeErrorKind.aiUnavailable,
      );
      expect(
        kindOf(502, {'code': 'ai_bad_response'}),
        EdgeErrorKind.aiUnavailable,
      );
      expect(kindOf(400, {'code': 'too_large'}), EdgeErrorKind.tooLarge);
      expect(kindOf(413, 'Payload Too Large'), EdgeErrorKind.tooLarge);
    });

    test('everything else is a server error and keeps the code', () {
      final e = EdgeFunctionError.fromResponse(402, {
        'code': 'invalid_purchase',
      });
      expect(e.kind, EdgeErrorKind.server);
      expect(e.code, 'invalid_purchase');
      expect(e.status, 402);
      expect(
        kindOf(500, {'error': 'Internal server error'}),
        EdgeErrorKind.server,
      );
      expect(kindOf(500, '<html>'), EdgeErrorKind.server);
    });
  });

  test('messages are translated sentences, never exception dumps', () {
    final en = AppStringsEn();
    final fa = AppStringsFa();
    for (final kind in EdgeErrorKind.values) {
      final e = EdgeFunctionError(kind, status: 500);
      expect(e.message(en), isNot(contains('Exception')));
      expect(e.message(en), isNot(contains('status')));
      expect(e.message(fa), isNot(equals(e.message(en))));
    }
    expect(
      const EdgeFunctionError(EdgeErrorKind.network).message(en),
      en.errNetwork,
    );
  });
}
