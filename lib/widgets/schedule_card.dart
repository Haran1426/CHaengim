import 'package:material_ui/material_ui.dart';

import '../design/app_theme.dart';
import '../models/schedule.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onTap,
    this.featured = false,
  });
  final Schedule schedule;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    final ink = featured ? Colors.white : context.appColors.ink;
    final secondary = featured
        ? context.appColors.onForestMuted
        : context.appColors.muted;
    final urgent =
        !schedule.isCompleted && schedule.daysLeft(DateTime.now()) <= 3;
    return Material(
      color: featured ? context.appColors.forest : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: featured ? context.appColors.forest : context.appColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(featured ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      schedule.category,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: featured
                          ? context.appColors.lime
                          : urgent
                          ? const Color(0xFFFFE9DC)
                          : context.appColors.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      schedule.isCompleted
                          ? '완료'
                          : schedule.dDay(DateTime.now()),
                      style: TextStyle(
                        color: urgent && !featured
                            ? context.appColors.rust
                            : context.appColors.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: featured ? 18 : 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                schedule.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: featured ? 23 : 19,
                  height: 1.4,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatDeadline(schedule)} 마감',
                style: TextStyle(color: secondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: featured
                        ? context.appColors.lime
                        : context.appColors.forest,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      schedule.items.isEmpty
                          ? '준비물 없음'
                          : schedule.remaining == 0
                          ? '준비물 완료'
                          : '준비물 ${schedule.remaining}개 남음',
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (schedule.stage == ScheduleStage.submitted ||
                      schedule.stage == ScheduleStage.waiting)
                    Flexible(
                      child: Text(
                        schedule.stage == ScheduleStage.submitted
                            ? '제출 완료'
                            : '결과 대기',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: secondary, fontSize: 14),
                      ),
                    ),
                ],
              ),
              if (schedule.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    semanticsLabel:
                        '준비물 ${schedule.items.length}개 중 ${schedule.items.length - schedule.remaining}개 완료',
                    minHeight: 4,
                    color: featured
                        ? context.appColors.lime
                        : context.appColors.forest,
                    backgroundColor: featured
                        ? context.appColors.progressTrack
                        : context.appColors.line,
                    value:
                        (schedule.items.length - schedule.remaining) /
                        schedule.items.length,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
