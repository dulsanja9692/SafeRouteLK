package com.example.saferoute_lk

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.saferoute.lk/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchAppByName") {
                val appName = call.argument<String>("appName")
                if (appName != null) {
                    val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
                    var found = false
                    
                    for (appInfo in packages) {
                        val label = packageManager.getApplicationLabel(appInfo).toString()
                        if (label.equals(appName, ignoreCase = true)) {
                            val launchIntent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                                result.success(true)
                                found = true
                                break
                            }
                        }
                    }
                    
                    if (!found) {
                        result.error("UNAVAILABLE", "App not installed.", null)
                    }
                } else {
                    result.error("INVALID", "App name not provided.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
