import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

/// Asks for a Play Store rating after the user has had a few wins — never before.
///
/// This uses Google's own in-app review dialog: it appears over the app, the
/// user never leaves, and Play itself caps how often it is really shown (a
/// request may show nothing). On top of that we ask only after
/// [firstAfterWins] successful actions, and again at most every
/// [repeatAfter], once the user has had that many wins again, so a
/// first-time user is never interrupted mid-task.
///
/// Ratings are the single biggest lever on Play search ranking for a new app,
/// and this is the only prompt in the app — there is no advertising. Settings
/// also has a permanent "Rate" entry ([openStorePage]).
class ReviewPrompter {
  const ReviewPrompter._();

  static const _storage    = FlutterSecureStorage();
  static const _kSuccesses = 'review_success_count'; // wins since the last ask
  static const _kLastAsked = 'review_last_asked';    // ms since epoch
  static const _kAskedOld  = 'review_asked';         // up to 1.3.2: asked once, ever

  /// Successful actions (a calculation, a G-code analysis, an AI answer)
  /// before each ask.
  static const firstAfterWins = 3;

  /// Least time between two asks.
  static const repeatAfter = Duration(days: 30);

  /// Whether to ask now, given the wins since the last ask.
  @visibleForTesting
  static bool due({required int wins, DateTime? lastAsked, required DateTime now}) =>
      wins >= firstAfterWins &&
      (lastAsked == null || now.difference(lastAsked) >= repeatAfter);

  /// Record something the user considers a win. Safe to call from anywhere —
  /// it never throws and never blocks the caller.
  static Future<void> recordSuccess() async {
    try {
      final now = DateTime.now();
      final lastMs = int.tryParse(await _storage.read(key: _kLastAsked) ?? '');
      if (lastMs == null && await _storage.read(key: _kAskedOld) == 'true') {
        // Asked once by an earlier version, when is unknown: count from now.
        await _remember(now);
        await _storage.delete(key: _kAskedOld);
        return;
      }
      final lastAsked = lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs);
      final wins = (int.tryParse(await _storage.read(key: _kSuccesses) ?? '') ?? 0) + 1;
      final review = InAppReview.instance;
      if (!due(wins: wins, lastAsked: lastAsked, now: now) || !await review.isAvailable()) {
        await _storage.write(key: _kSuccesses, value: '$wins');
        return;
      }
      // Remember the ask before requesting: if Play throttles the dialog away
      // we still wait the full interval before trying again.
      await _remember(now);
      await review.requestReview();
    } catch (_) {
      // A rating prompt is never worth breaking a screen over.
    }
  }

  /// Opens the app's Play Store page, where the user can rate and review it
  /// at any time (Settings → Rate).
  static Future<void> openStorePage() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {}
  }

  /// An ask at [asked]; wins count again from zero.
  static Future<void> _remember(DateTime asked) async {
    await _storage.write(key: _kLastAsked, value: '${asked.millisecondsSinceEpoch}');
    await _storage.write(key: _kSuccesses, value: '0');
  }
}
