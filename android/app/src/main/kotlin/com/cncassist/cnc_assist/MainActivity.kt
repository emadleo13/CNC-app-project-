package com.cncassist.cnc_assist

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app-scoped Android ID (per signing key, user and device since
        // Android 8). It survives uninstalling the app, so the server can
        // count the free AI quota per device. See lib/core/net/device_id.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cnc_assist/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "androidId" -> result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
