import 'package:flutter/services.dart';

const _channel = MethodChannel('cnc_assist/device');

Future<String?>? _deviceId;

/// The app-scoped Android ID, sent to the Edge Functions as `x-device-id`.
///
/// The free AI quota is counted per device as well as per account: the
/// account is anonymous, so reinstalling the app (or deleting the account)
/// used to start a new one with ten fresh questions. This ID survives a
/// reinstall; only a factory reset changes it. The server stores only a hash.
///
/// Null when the platform cannot give one; the account alone is then counted.
Future<String?> deviceId() => _deviceId ??= _read();

Future<String?> _read() async {
  try {
    final id = await _channel.invokeMethod<String>('androidId');
    return (id == null || id.isEmpty) ? null : id;
  } catch (_) {
    return null;
  }
}
