package com.example.my_first_app

import java.util.Calendar
import java.util.TimeZone

data class ReminderInput(
    val id: String, val title: String, val year: Int, val month: Int, val day: Int,
    val dueHour: Int, val dueMinute: Int, val hasTime: Boolean,
    val days: List<Int>, val hour: Int, val minute: Int, val remaining: Int
)
data class ReminderEvent(
    val key: String, val scheduleId: String, val title: String, val at: Long,
    val expires: Long, val leadDays: Int, val remaining: Int, val token: String
)

object ReminderPlanner {
    fun reconcile(rows: List<ReminderInput>, now: Long, zone: TimeZone = TimeZone.getDefault(),
        fired: Set<String> = emptySet(), armedTimes: Map<String, Long> = emptyMap(), preserveDue: Boolean = false): List<ReminderEvent> {
        return plan(rows, Long.MIN_VALUE, zone).filter {
            it.token !in fired && (it.at > now ||
                (preserveDue && armedTimes[it.token] == it.at && now < it.expires))
        }
    }
    fun plan(rows: List<ReminderInput>, now: Long, zone: TimeZone = TimeZone.getDefault()): List<ReminderEvent> {
        return rows.flatMap { row ->
            fun date(hour: Int, minute: Int) = Calendar.getInstance(zone).apply {
                clear(); set(row.year, row.month - 1, row.day, hour, minute)
            }
            val expires = if (row.hasTime) date(row.dueHour, row.dueMinute).timeInMillis
                else date(0, 0).apply { add(Calendar.DAY_OF_MONTH, 1) }.timeInMillis
            row.days.distinct().filter { it in listOf(0, 1, 3, 7) }.mapNotNull { days ->
                val whenToFire = date(row.hour.coerceIn(0, 23), row.minute.coerceIn(0, 59)).apply { add(Calendar.DAY_OF_MONTH, -days) }
                val at = whenToFire.timeInMillis
                val endOfReminderDay = (whenToFire.clone() as Calendar).apply {
                    set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); add(Calendar.DAY_OF_MONTH, 1)
                }.timeInMillis
                if (at <= now || at >= expires) null else ReminderEvent(
                    "${row.id}:$days", row.id, row.title, at, minOf(expires, endOfReminderDay), days, row.remaining,
                    "${row.id}:$days@${whenToFire.get(Calendar.YEAR)}-${whenToFire.get(Calendar.MONTH)}-${whenToFire.get(Calendar.DAY_OF_MONTH)}T${row.hour}:${row.minute}"
                )
            }
        }.sortedBy { it.at }
    }
}
