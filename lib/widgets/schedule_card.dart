import 'package:flutter/material.dart';
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
    final ink = featured ? Colors.white : AppColors.ink;
    final secondary = featured ? const Color(0xFFC3D4C9) : AppColors.muted;
    final urgent =
        !schedule.isCompleted && schedule.daysLeft(DateTime.now()) <= 3;
    return Material(
      color: featured ? AppColors.forest : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: featured ? AppColors.forest : AppColors.line),
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
                      featured ? '가장 먼저 챙겨요' : schedule.category,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
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
                          ? AppColors.lime
                          : urgent
                          ? const Color(0xFFFFE9DC)
                          : const Color(0xFFF0F2E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      schedule.isCompleted
                          ? '완료'
                          : schedule.dDay(DateTime.now()),
                      style: TextStyle(
                        color: urgent && !featured
                            ? AppColors.rust
                            : AppColors.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: featured ? 19 : 13,
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
                  fontSize: featured ? 24 : 18,
                  height: 1.4,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatDeadline(schedule)} 마감',
                style: TextStyle(color: secondary, fontSize: 12),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: featured ? AppColors.lime : AppColors.forest,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '준비물 ${schedule.remaining}개 남음',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    schedule.stage.label,
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                ],
              ),
              if (schedule.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: featured ? AppColors.lime : AppColors.forest,
                    backgroundColor: featured
                        ? const Color(0xFF416455)
                        : AppColors.line,
                    value:
                        (schedule.items.length - schedule.remaining) /
                        schedule.items.length,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '준비물 ${schedule.items.length - schedule.remaining}/${schedule.items.length} 완료 · ${schedule.remaining}개 남음',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
