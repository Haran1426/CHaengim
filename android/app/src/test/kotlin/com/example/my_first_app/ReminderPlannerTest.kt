package com.example.my_first_app

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReminderPlannerTest {
    private val zone = TimeZone.getTimeZone("Asia/Seoul")
    private fun instant(day: Int, hour: Int = 0, minute: Int = 0) = Calendar.getInstance(zone).apply { clear(); set(2026, 10, day, hour, minute) }.timeInMillis
    private fun row(days: List<Int> = listOf(0, 1, 3, 7)) = ReminderInput("id", "신청", 2026, 11, 20, 18, 0, true, days, 9, 0, 2)
    @Test fun selectedDaysAreScheduledOnLocalCalendarDates() {
        val plans = ReminderPlanner.plan(listOf(row()), instant(10), zone)
        assertEquals(listOf(instant(13, 9), instant(17, 9), instant(19, 9), instant(20, 9)), plans.map { it.at })
        assertEquals(4, plans.map { it.key }.toSet().size)
    }
    @Test fun pastAndAtDeadlineAlarmsAreExcluded() {
        assertEquals(1, ReminderPlanner.plan(listOf(row()), instant(20, 8), zone).size)
        assertTrue(ReminderPlanner.plan(listOf(row()), instant(20, 9), zone).isEmpty())
        assertTrue(ReminderPlanner.plan(listOf(row(listOf(0)).copy(hour = 18)), instant(19), zone).isEmpty())
    }
    @Test fun duplicateAndUnknownLeadDaysDoNotCreateExtraAlarms() {
        assertEquals(1, ReminderPlanner.plan(listOf(row(listOf(1, 1, -2, 99))), instant(10), zone).size)
        assertTrue(ReminderPlanner.plan(emptyList(), instant(10), zone).isEmpty())
    }
    @Test fun dateOnlyDeadlineIncludesWholeDay() {
        val plan = ReminderPlanner.plan(listOf(row(listOf(0)).copy(hasTime = false, hour = 23, minute = 59)), instant(20), zone).single()
        assertEquals(instant(21), plan.expires)
    }
    @Test fun oldLeadDayNotificationsExpireAtTheEndOfThatDay() {
        val plan = ReminderPlanner.plan(listOf(row(listOf(7))), instant(10), zone).single()
        assertEquals(instant(14), plan.expires)
    }
    @Test fun appResumePreservesOnlyAlreadyArmedFreshDueNotifications() {
        val rows = listOf(row(listOf(0)))
        val old = ReminderPlanner.plan(rows, instant(19), zone).single()
        val armed = mapOf(old.token to old.at)
        assertEquals(1, ReminderPlanner.reconcile(rows, instant(20, 10), zone, armedTimes = armed, preserveDue = true).size)
        assertTrue(ReminderPlanner.reconcile(rows, instant(20, 10), zone, armedTimes = armed).isEmpty())
        assertTrue(ReminderPlanner.reconcile(rows, instant(20, 10), zone, preserveDue = true).isEmpty())
        assertTrue(ReminderPlanner.reconcile(rows, instant(20, 10), zone, fired = setOf(old.token), armedTimes = armed, preserveDue = true).isEmpty())
        assertTrue(ReminderPlanner.reconcile(rows, instant(20, 18), zone, armedTimes = armed, preserveDue = true).isEmpty())
        assertTrue(ReminderPlanner.reconcile(emptyList(), instant(20, 10), zone, armedTimes = armed, preserveDue = true).isEmpty())
    }
    @Test fun timezoneChangeKeepsLocalTimeAndDeduplicationToken() {
        val plans = ReminderPlanner.plan(listOf(row(listOf(1))), 0, zone)
        val other = ReminderPlanner.plan(listOf(row(listOf(1))), 0, TimeZone.getTimeZone("America/New_York"))
        assertNotEquals(plans.single().at, other.single().at)
        assertEquals(plans.single().token, other.single().token)
    }
    @Test fun dayOffsetSurvivesDaylightSavingTransition() {
        val dstZone = TimeZone.getTimeZone("America/New_York")
        val plan = ReminderPlanner.plan(listOf(row(listOf(1)).copy(year = 2026, month = 3, day = 9)), 0, dstZone).single()
        val local = Calendar.getInstance(dstZone).apply { timeInMillis = plan.at }
        assertEquals(8, local.get(Calendar.DAY_OF_MONTH))
        assertEquals(9, local.get(Calendar.HOUR_OF_DAY))
    }
}
