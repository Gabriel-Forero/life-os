package com.lifeos.life_os

import android.app.AlarmManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "life_os/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getNextAlarm") {
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val alarmInfo = alarmManager.nextAlarmClock
                    if (alarmInfo != null) {
                        result.success(alarmInfo.triggerTime)
                    } else {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
