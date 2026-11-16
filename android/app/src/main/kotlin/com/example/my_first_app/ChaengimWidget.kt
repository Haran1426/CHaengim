package com.example.my_first_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

class SmallWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { ChaengimWidget.render(context, manager, it, false) }
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        ChaengimWidget.render(context, manager, id, false)
    }
}
class MediumWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { ChaengimWidget.render(context, manager, it, true) }
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        ChaengimWidget.render(context, manager, id, true)
    }
}
// 날짜·시각·시간대 변경 시 Flutter를 실행하지 않고 D-day를 다시 계산합니다.
class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ChaengimWidget.updateAll(context)
        Reminders.restore(context)
    }
}

object ChaengimWidget {
    const val DATA_FILE = "chaengim_widget_v1"
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        manager.getAppWidgetIds(ComponentName(context, SmallWidgetProvider::class.java)).forEach { render(context, manager, it, false) }
        manager.getAppWidgetIds(ComponentName(context, MediumWidgetProvider::class.java)).forEach { render(context, manager, it, true) }
    }
    private fun open(context: Context, route: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.parse("chaengim://widget/${Uri.encode(route)}")
            putExtra("chaengim_route", route)
        }
        return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    private fun dayNumber(epoch: Long): Long {
        val local = Calendar.getInstance().apply { timeInMillis = epoch }
        return Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear(); set(local.get(Calendar.YEAR), local.get(Calendar.MONTH), local.get(Calendar.DAY_OF_MONTH))
        }.timeInMillis / 86400000L
    }
    fun render(context: Context, manager: AppWidgetManager, id: Int, medium: Boolean) {
        val options = manager.getAppWidgetOptions(id)
        val portrait = context.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        val width = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 250)
        val height = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
        val wide = medium && width >= 240
        val layout = if (wide) R.layout.widget_medium else R.layout.widget_small
        val views = RemoteViews(context.packageName, layout)
        val preferences = context.getSharedPreferences(DATA_FILE, Context.MODE_PRIVATE)
        val background = preferences.getInt("background", Color.parseColor("#244C3F"))
        val accent = preferences.getInt("accent", Color.parseColor("#E0EEAC"))
        val secondary = preferences.getInt("secondary", Color.parseColor("#C3D4C9"))
        val drawable = when (background) {
            Color.parseColor("#62503E") -> R.drawable.widget_background_sand
            Color.parseColor("#284C63") -> R.drawable.widget_background_ocean
            Color.parseColor("#56436E") -> R.drawable.widget_background_iris
            Color.parseColor("#7A4A42") -> R.drawable.widget_background_rose
            else -> R.drawable.widget_background
        }
        views.setInt(R.id.widget_root, "setBackgroundResource", drawable)
        views.setInt(R.id.widget_add, "setBackgroundResource", 0)
        views.setTextColor(R.id.widget_brand, accent)
        views.setTextColor(R.id.widget_add, accent)
        val raw = preferences.getString("schedules", "[]")
        val rows = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        views.setOnClickPendingIntent(R.id.widget_add, open(context, "add"))
        views.setOnClickPendingIntent(R.id.widget_root, open(context, "home"))
        val rowIds = if (wide) intArrayOf(R.id.row_one, R.id.row_two, R.id.row_three) else intArrayOf(R.id.row_one)
        val titleIds = intArrayOf(R.id.title_one, R.id.title_two, R.id.title_three)
        val dayIds = intArrayOf(R.id.day_one, R.id.day_two, R.id.day_three)
        val infoIds = intArrayOf(R.id.info_one, R.id.info_two, R.id.info_three)
        val maxRows = if (wide && height < 280) 2 else rowIds.size
        rowIds.forEachIndexed { index, rowId ->
            views.setTextColor(dayIds[index], accent)
            views.setTextColor(infoIds[index], secondary)
            if (index >= rows.length() || index >= maxRows) {
                views.setViewVisibility(rowId, if (index == 0) View.VISIBLE else View.GONE)
                if (index == 0) {
                    views.setTextViewText(titleIds[0], "다가오는 일정 없음")
                    views.setTextViewText(dayIds[0], "차근차근, 하나씩")
                    views.setTextViewText(infoIds[0], "+ 버튼으로 새 일정을 챙겨요")
                    views.setOnClickPendingIntent(rowId, open(context, "add"))
                }
            } else {
                val row: JSONObject = rows.getJSONObject(index)
                val days = dayNumber(row.getLong("deadline")) - dayNumber(System.currentTimeMillis())
                val expired = days < 0 || (row.optBoolean("hasTime", false) && System.currentTimeMillis() >= row.getLong("deadline"))
                val day = when { expired -> "기한 지남"; days == 0L -> "D-day"; else -> "D-$days" }
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(titleIds[index], row.getString("title"))
                views.setTextViewText(dayIds[index], day)
                views.setTextColor(dayIds[index], if (expired) Color.parseColor("#FFC2A3") else accent)
                views.setTextViewText(infoIds[index], "준비물 ${row.getInt("remaining")}개 남음 · ${row.getString("stage")}")
                views.setOnClickPendingIntent(rowId, open(context, "detail:${row.getString("id")}"))
            }
        }
        manager.updateAppWidget(id, views)
    }
}
