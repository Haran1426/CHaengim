import 'schedule.dart';

const reminderOptions = [0, 1, 3, 7];
String reminderLabel(int days) => days == 0 ? '당일' : '$days일 전';

List<DateTime> reminderTimes(Schedule schedule, DateTime now) {
  if (schedule.isCompleted || schedule.isExpired(now)) return [];
  final times =
      schedule.reminderDays
          .toSet()
          .where(reminderOptions.contains)
          .map(
            (days) => DateTime(
              schedule.deadline.year,
              schedule.deadline.month,
              schedule.deadline.day - days,
              schedule.reminderHour,
              schedule.reminderMinute,
            ),
          )
          .where((time) => time.isAfter(now) && !schedule.isExpired(time))
          .toList()
        ..sort();
  return times;
}

List<Map<String, Object>> reminderSnapshot(List<Schedule> schedules) =>
    schedules
        .where((s) => !s.isCompleted && s.reminderDays.isNotEmpty)
        .map(
          (s) => <String, Object>{
            'id': s.id,
            'title': s.title,
            'year': s.deadline.year,
            'month': s.deadline.month,
            'day': s.deadline.day,
            'dueHour': s.deadline.hour,
            'dueMinute': s.deadline.minute,
            'hasTime': s.hasTime,
            'days': s.reminderDays
                .toSet()
                .where(reminderOptions.contains)
                .toList(),
            'hour': s.reminderHour,
            'minute': s.reminderMinute,
            'remaining': s.remaining,
          },
        )
        .toList();
