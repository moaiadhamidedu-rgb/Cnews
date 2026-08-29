package com.example.mpcurrencytracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.mpcurrencytracker/app_share",
        ).setMethodCallHandler { call, result ->
            if (call.method != "prepareInstalledApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            Thread {
                try {
                    val shareDirectory = File(cacheDir, "shared_app").apply { mkdirs() }
                    val shareFile = File(shareDirectory, "CNews.apk")
                    File(applicationInfo.sourceDir).copyTo(shareFile, overwrite = true)
                    runOnUiThread { result.success(shareFile.absolutePath) }
                } catch (error: Exception) {
                    runOnUiThread {
                        result.error("APK_SHARE_FAILED", error.message, null)
                    }
                }
            }.start()
        }
    }
}
