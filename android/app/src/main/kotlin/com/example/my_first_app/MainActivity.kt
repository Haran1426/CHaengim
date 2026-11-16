package com.example.my_first_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var permissionResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chaengim/widgets")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "appearance" -> {
                    val colors = call.arguments as? Map<*, *>
                    val background = (colors?.get("background") as? Number)?.toInt()
                    val accent = (colors?.get("accent") as? Number)?.toInt()
                    val secondary = (colors?.get("secondary") as? Number)?.toInt()
                    if (background == null || accent == null || secondary == null) result.error("invalid", "Missing palette", null)
                    else {
                        val saved = getSharedPreferences(ChaengimWidget.DATA_FILE, MODE_PRIVATE).edit()
                            .putInt("background", background).putInt("accent", accent).putInt("secondary", secondary).commit()
                        if (saved) { ChaengimWidget.updateAll(this); result.success(null) }
                        else result.error("save", "Widget theme storage failed", null)
                    }
                }
                "sync" -> {
                    val snapshot = call.arguments as? String
                    if (snapshot == null) result.error("invalid", "Missing snapshot", null)
                    else {
                        val saved = getSharedPreferences(ChaengimWidget.DATA_FILE, MODE_PRIVATE)
                            .edit().putString("schedules", snapshot).commit()
                        if (saved) { ChaengimWidget.updateAll(this); result.success(null) }
                        else result.error("save", "Widget storage failed", null)
                    }
                }
                "initialRoute" -> {
                    result.success(intent.getStringExtra("chaengim_route"))
                    intent.removeExtra("chaengim_route")
                }
                "pin" -> {
                    val manager = AppWidgetManager.getInstance(this)
                    if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported) {
                        val medium = call.argument<Boolean>("medium") == true
                        val provider = if (medium) MediumWidgetProvider::class.java else SmallWidgetProvider::class.java
                        result.success(manager.requestPinAppWidget(ComponentName(this, provider), null, null))
                    } else result.success(false)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chaengim/reminders").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "sync" -> { Reminders.sync(this, call.arguments as String); result.success(null) }
                    "status" -> result.success(Reminders.status(this))
                    "setEnabled" -> { Reminders.setEnabled(this, call.arguments == true); result.success(null) }
                    "requestPermission" -> {
                        if (permissionResult != null) result.error("busy", "권한 요청 중입니다.", null)
                        else {
                            Reminders.markAsked(this)
                            if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                permissionResult = result
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 902)
                            } else { Reminders.restore(this); result.success(Reminders.status(this)) }
                        }
                    }
                    "openSettings" -> {
                        val settings = if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        startActivity(settings); result.success(null)
                    }
                    "test" -> result.success(Reminders.test(this))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("reminders", e.message, null) }
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 902) {
            val result = permissionResult
            permissionResult = null
            try { Reminders.restore(this); result?.success(Reminders.status(this)) }
            catch (e: Exception) { result?.error("reminders", e.message, null) }
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra("chaengim_route")?.let {
            channel?.invokeMethod("openRoute", it)
            intent.removeExtra("chaengim_route")
        }
    }
}
