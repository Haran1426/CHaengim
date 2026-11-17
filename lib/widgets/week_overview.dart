import 'package:material_ui/material_ui.dart';

import '../design/app_theme.dart';
import '../models/schedule.dart';

class WeekOverview extends StatelessWidget {
  const WeekOverview({
    super.key,
    required this.today,
    required this.schedules,
    required this.onSelected,
  });

  final DateTime today;
  final List<Schedule> schedules;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day - today.weekday + 1 + index,
      ),
    );
    final counts = [
      for (final day in days)
        schedules
            .where(
              (s) => !s.isCompleted && DateUtils.isSameDay(s.deadline, day),
            )
            .length,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '이번 주',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '마감 ${counts.fold(0, (sum, count) => sum + count)}건',
                    style: TextStyle(fontSize: 14, color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var index = 0; index < days.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: _day(context, days[index], counts[index]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(BuildContext context, DateTime day, int count) {
    final colors = context.appColors;
    final isToday = DateUtils.isSameDay(day, today);
    final weekday = ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1];
    final label =
        '${day.month}월 ${day.day}일 $weekday요일${isToday ? ', 오늘' : ''}, 미완료 마감 $count건';
    return Semantics(
      label: label,
      button: true,
      onTap: () => onSelected(day),
      child: ExcludeSemantics(
        child: Material(
          color: isToday ? colors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('week-day-${day.year}-${day.month}-${day.day}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: isToday ? colors.onForestMuted : colors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? Colors.white : colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count == 0
                          ? Colors.transparent
                          : isToday
                          ? colors.lime
                          : colors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
