import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

/// Asks for a Play Store rating after the user has had a few wins — never before.
///
/// This uses Google's own in-app review dialog: it appears over the app, the
/// user never leaves, and Play itself caps how often it can be shown. On top of
/// that we gate on [_threshold] successful actions and ask at most once, so a
/// first-time user is never interrupted mid-task.
///
/// Ratings are the single biggest lever on Play search ranking for a new app,
/// and this is the only prompt in the app — there is no advertising.
class ReviewPrompter {
  const ReviewPrompter._();

  static const _storage    = FlutterSecureStorage();
  static const _kSuccesses = 'review_success_count';
  static const _kAsked     = 'review_asked';

  /// Successful actions (a calculation, a G-code analysis) before we ask.
  static const _threshold = 3;

  /// Record something the user considers a win. Safe to call from anywhere —
  /// it never throws and never blocks the caller.
  static Future<void> recordSuccess() async {
    try {
      if (await _storage.read(key: _kAsked) == 'true') return;

      final count = int.tryParse(await _storage.read(key: _kSuccesses) ?? '0') ?? 0;
      final next  = count + 1;
      await _storage.write(key: _kSuccesses, value: '$next');
      if (next < _threshold) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      // Mark as asked before requesting: if the dialog is throttled away by
      // Play we still don't want to retry on every subsequent calculation.
      await _storage.write(key: _kAsked, value: 'true');
      await review.requestReview();
    } catch (_) {
      // A rating prompt is never worth breaking a screen over.
    }
  }
}
