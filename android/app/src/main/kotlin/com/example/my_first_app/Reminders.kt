package com.example.my_first_app

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Reminders.deliver(context, intent.getStringExtra("key") ?: return, intent.getLongExtra("at", -1))
    }
}

object Reminders {
    private const val FILE = "chaengim_reminders_v1"
    private const val CHANNEL = "deadlines_v1"
    private fun prefs(context: Context) = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            manager(context).createNotificationChannel(NotificationChannel(CHANNEL, "마감 사전 알림", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "선택한 날짜와 시각에 일정과 남은 준비물을 알려드려요."
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            })
        }
    }
    fun allowed(context: Context): Boolean {
        ensureChannel(context)
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        if (!manager(context).areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 26 || manager(context).getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
    }
    private fun events(context: Context): JSONArray = JSONArray(prefs(context).getString("events", "[]"))
    private fun alarmIntent(context: Context, key: String, at: Long): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            data = Uri.parse("chaengim://alarm/${Uri.encode(key)}")
            putExtra("key", key); putExtra("at", at)
        }
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    private fun readRows(raw: String): List<ReminderInput> {
        val json = JSONArray(raw)
        return (0 until json.length()).map { i ->
            val row = json.getJSONObject(i)
            val days = row.getJSONArray("days")
            ReminderInput(row.getString("id"), row.getString("title"), row.getInt("year"), row.getInt("month"), row.getInt("day"),
                row.getInt("dueHour"), row.getInt("dueMinute"), row.getBoolean("hasTime"),
                (0 until days.length()).map { days.getInt(it) }, row.getInt("hour"), row.getInt("minute"), row.getInt("remaining"))
        }
    }
    fun sync(context: Context, raw: String) {
        val rows = readRows(raw) // 먼저 검증하여 잘못된 입력으로 기존 예약을 지우지 않습니다.
        val old = JSONArray(prefs(context).getString("snapshot", "[]"))
        val current = JSONArray(raw)
        val currentById = (0 until current.length()).associate { val r = current.getJSONObject(it); r.getString("id") to r.toString() }
        for (i in 0 until old.length()) {
            val row = old.getJSONObject(i)
            if (currentById[row.getString("id")] != row.toString()) {
                listOf(0, 1, 3, 7).forEach { manager(context).cancel(row.getString("id"), it) }
            }
        }
        check(prefs(context).edit().putString("snapshot", raw).commit()) { "알림 정보를 저장하지 못했습니다." }
        replan(context, rows, preserveDue = true)
    }
    fun restore(context: Context) {
        replan(context, readRows(prefs(context).getString("snapshot", "[]") ?: "[]"))
    }
    private fun replan(context: Context, rows: List<ReminderInput>, preserveDue: Boolean = false) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val oldEvents = events(context)
        val armed = prefs(context).getStringSet("armed", emptySet())!!.toSet()
        val oldTimes = (0 until oldEvents.length()).associate {
            val row = oldEvents.getJSONObject(it); row.getString("token") to row.getLong("at")
        }
        for (i in 0 until oldEvents.length()) {
            val old = oldEvents.getJSONObject(i)
            val pending = alarmIntent(context, old.getString("key"), old.getLong("at"))
            alarms.cancel(pending); pending.cancel()
        }
        val fired = prefs(context).getStringSet("fired", emptySet())!!.toSet()
        val now = System.currentTimeMillis()
        // 새로 선택한 과거 시각은 건너뛰되, 이미 예약되어 Android 전달을 기다리는 알림은 보존합니다.
        val planned = ReminderPlanner.reconcile(rows, now, fired = fired,
            armedTimes = oldTimes.filterKeys { it in armed }, preserveDue = preserveDue)
        val json = JSONArray()
        planned.forEach { event -> json.put(JSONObject().apply {
            put("key", event.key); put("id", event.scheduleId); put("title", event.title)
            put("at", event.at); put("expires", event.expires); put("days", event.leadDays)
            put("remaining", event.remaining); put("token", event.token)
        }) }
        check(prefs(context).edit().putString("events", json.toString()).commit()) { "알림 예약을 저장하지 못했습니다." }
        val shouldArm = prefs(context).getBoolean("enabled", true) && allowed(context)
        if (shouldArm) {
            planned.forEach { alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, it.at, alarmIntent(context, it.key, it.at)) }
        }
        check(prefs(context).edit().putStringSet("armed", if (shouldArm) planned.map { it.token }.toSet() else emptySet()).commit())
    }
    fun status(context: Context): Map<String, Any> {
        val canNotify = allowed(context)
        val enabled = prefs(context).getBoolean("enabled", true)
        val fired = prefs(context).getStringSet("fired", emptySet())!!
        val rows = events(context)
        val count = if (!canNotify || !enabled) 0 else (0 until rows.length()).count {
            val row = rows.getJSONObject(it)
            row.getLong("at") > System.currentTimeMillis() && row.getString("token") !in fired
        }
        return mapOf("allowed" to canNotify, "enabled" to enabled, "asked" to prefs(context).getBoolean("asked", false), "pending" to count)
    }
    fun markAsked(context: Context) { prefs(context).edit().putBoolean("asked", true).apply() }
    fun setEnabled(context: Context, enabled: Boolean) {
        check(prefs(context).edit().putBoolean("enabled", enabled).commit())
        if (!enabled) manager(context).cancelAll()
        restore(context)
    }
    fun deliver(context: Context, key: String, at: Long) {
        if (!prefs(context).getBoolean("enabled", true) || !allowed(context)) return
        val rows = events(context)
        val event = (0 until rows.length()).map { rows.getJSONObject(it) }.firstOrNull { it.getString("key") == key && it.getLong("at") == at } ?: return
        val now = System.currentTimeMillis()
        if (now < at) { restore(context); return }
        if (now >= event.getLong("expires")) return
        val token = event.getString("token")
        val fired = prefs(context).getStringSet("fired", emptySet())!!.toMutableSet()
        if (token in fired) return
        val days = event.getInt("days")
        val lead = if (days == 0) "오늘 마감" else "마감 ${days}일 전"
        val body = "$lead · 준비물 ${event.getInt("remaining")}개 남음"
        try {
            manager(context).notify(event.getString("id"), days, notification(context, event.getString("title"), body, "detail:${event.getString("id")}"))
            fired.add(token)
            // 최근 기록만 남겨 중복 수신을 막습니다. 표시 ID도 같아서 재수신 시 새 카드가 쌓이지 않습니다.
            prefs(context).edit().putStringSet("fired", fired.toList().takeLast(1000).toSet()).commit()
        } catch (_: SecurityException) { /* 전송 직전 권한이 바뀌어도 앱은 계속 사용할 수 있습니다. */ }
    }
    private fun notification(context: Context, title: String, body: String, route: String): Notification {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.parse("chaengim://notification/${Uri.encode(route)}"); putExtra("chaengim_route", route)
        }
        val content = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
        return builder.setSmallIcon(R.drawable.ic_notification).setColor(Color.parseColor("#244C3F"))
            .setContentTitle(title).setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(content).setAutoCancel(true).setOnlyAlertOnce(true).setShowWhen(true)
            .setCategory(Notification.CATEGORY_REMINDER).setVisibility(Notification.VISIBILITY_PRIVATE).build()
    }
    fun test(context: Context): Boolean {
        if (!allowed(context) || !prefs(context).getBoolean("enabled", true)) return false
        manager(context).notify("chaengim-test", 0, notification(context, "챙김 알림이 준비됐어요", "이렇게 마감일과 남은 준비물을 알려드릴게요.", "home"))
        return true
    }
}
