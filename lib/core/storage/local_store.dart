import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/history/domain/saved_analysis.dart';
import '../../features/history/domain/saved_calculation.dart';

/// Opens the app's local Hive boxes.
///
/// Records are versioned by appending: an adapter may add fields only at the
/// end of its layout and reads them only when the record still has bytes
/// left, so records saved by any earlier version keep loading. See
/// SavedCalculationAdapter.
Future<void> openLocalStore() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SavedCalculationAdapter());
  Hive.registerAdapter(SavedAnalysisAdapter());
  final dir = (await getApplicationDocumentsDirectory()).path;
  await openBoxSafely<SavedCalculation>('calculations', dir);
  await openBoxSafely<SavedAnalysis>('analyses', dir);
}

/// Opens box [name] stored in [dir]. A box that cannot be read (a damaged
/// file, or a record an adapter cannot decode) would otherwise make the app
/// crash on every start: it is copied to `<name>.hive.broken` and replaced by
/// an empty box. Losing the history beats an app that no longer opens.
Future<Box<T>> openBoxSafely<T>(String name, String dir) async {
  try {
    return await _guarded(() => Hive.openBox<T>(name, path: dir));
  } catch (e) {
    debugPrint('Local box "$name" is unreadable, starting it empty: $e');
    final file = File('$dir/${name.toLowerCase()}.hive');
    try {
      if (file.existsSync()) await file.copy('${file.path}.broken');
    } catch (_) {
      // Best effort: the copy is only for a later rescue attempt.
    }
    await Hive.deleteBoxFromDisk(name, path: dir);
    return Hive.openBox<T>(name, path: dir);
  }
}

/// Runs [body], returning its result or error. Hive also hands a failed open
/// to an internal future that nobody listens to; that second copy of the
/// error lands in this zone instead of surfacing as an uncaught error.
Future<R> _guarded<R>(Future<R> Function() body) {
  final done = Completer<R>();
  runZonedGuarded(
    () async {
      try {
        done.complete(await body());
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    },
    (e, s) {
      // After the open: Hive's copy of an error already returned, or an
      // error from work the box started. Logged, never silently dropped.
      if (done.isCompleted) {
        debugPrint('Local store: $e');
      } else {
        done.completeError(e, s);
      }
    },
  );
  return done.future;
}
