import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

/// Why an Edge Function call failed, as far as the UI needs to know.
enum EdgeErrorKind {
  /// Free monthly AI quota used up (HTTP 429).
  quotaExceeded,

  /// The feature needs Pro (HTTP 403 pro_required).
  proRequired,

  /// The upload was over the server's size limit.
  tooLarge,

  /// The model provider failed or is overloaded (HTTP 502/503).
  aiUnavailable,

  /// No connection, DNS failure, timeout or sign-in failure.
  network,

  /// Anything else the server rejected.
  server,
}

class EdgeFunctionError implements Exception {
  final EdgeErrorKind kind;
  final int? status;

  /// The server's stable error code (e.g. `invalid_purchase`), when it sent one.
  final String? code;

  const EdgeFunctionError(this.kind, {this.status, this.code});

  /// Maps a non-2xx response. Older deployments sent only `quota_exceeded` /
  /// `pro_required` flags, newer ones a `code`; both are understood.
  factory EdgeFunctionError.fromResponse(int status, Object? details) {
    final body = details is Map ? details : const {};
    final code = body['code'] as String?;
    final kind = switch ((status, code)) {
      (429, _) || (_, 'quota_exceeded') => EdgeErrorKind.quotaExceeded,
      (403, _) when body['pro_required'] == true || code == 'pro_required' =>
        EdgeErrorKind.proRequired,
      (_, 'too_large') || (413, _) => EdgeErrorKind.tooLarge,
      (502, _) ||
      (503, _) ||
      (_, 'ai_unavailable') => EdgeErrorKind.aiUnavailable,
      _ => EdgeErrorKind.server,
    };
    return EdgeFunctionError(kind, status: status, code: code);
  }

  /// A sentence for the user in their language. Never shows raw exception text.
  String message(AppStrings s) => switch (kind) {
    EdgeErrorKind.quotaExceeded => s.proLimitMsg,
    EdgeErrorKind.proRequired => s.pdfProOnly,
    EdgeErrorKind.tooLarge => s.errTooLarge,
    EdgeErrorKind.aiUnavailable => s.errAiBusy,
    EdgeErrorKind.network => s.errNetwork,
    EdgeErrorKind.server => s.errServer,
  };

  @override
  String toString() => 'EdgeFunctionError($kind, status: $status, code: $code)';
}

/// Calls the Supabase Edge Function [name] as the current user (signing in
/// anonymously first if needed) and returns its JSON body.
///
/// functions_client throws [FunctionException] for every non-2xx response, so
/// checking `response.status` afterwards never sees a 403 or 429. This turns
/// those, and transport failures, into an [EdgeFunctionError].
Future<Map<String, dynamic>> invokeEdgeFunction(
  String name, {
  Map<String, dynamic>? body,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final supabase = Supabase.instance.client;
  try {
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously().timeout(
        const Duration(seconds: 20),
      );
    }
    final response = await supabase.functions
        .invoke(name, body: body)
        .timeout(timeout);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw EdgeFunctionError(EdgeErrorKind.server, status: response.status);
  } on FunctionException catch (e) {
    throw EdgeFunctionError.fromResponse(e.status, e.details);
  } on EdgeFunctionError {
    rethrow;
  } on TimeoutException {
    throw const EdgeFunctionError(EdgeErrorKind.network);
  } on AuthException {
    throw const EdgeFunctionError(EdgeErrorKind.network);
  } catch (_) {
    // SocketException / http ClientException: the request never got an answer.
    throw const EdgeFunctionError(EdgeErrorKind.network);
  }
}

/// How long the app waits for an AI answer. Requests send it as
/// `clientTimeout`: the server fits its answer in this time, falling back
/// from Claude to the free models when it has to.
const kAiTimeout = Duration(seconds: 120);

typedef EdgeInvoker =
    Future<Map<String, dynamic>> Function(
      String name, {
      Map<String, dynamic>? body,
      Duration timeout,
    });

/// [invokeEdgeFunction], replaceable in widget tests.
final edgeInvokerProvider = Provider<EdgeInvoker>((ref) => invokeEdgeFunction);
