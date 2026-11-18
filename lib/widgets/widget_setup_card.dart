import 'package:material_ui/material_ui.dart';

import '../design/app_theme.dart';
import '../models/schedule.dart';

class WidgetSetupCard extends StatelessWidget {
  const WidgetSetupCard({super.key, required this.onAdd, this.schedule});

  final VoidCallback onAdd;
  final Schedule? schedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final next = schedule;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('홈 화면에서도 챙김', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '위젯으로 마감과 준비물을 한눈에 확인해요.',
              style: TextStyle(color: colors.muted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: '위젯 미리보기',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.forest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '챙김',
                            style: TextStyle(color: colors.lime, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (next != null)
                          Text(
                            next.dDay(DateTime.now()),
                            style: TextStyle(
                              color: colors.lime,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Icon(Icons.add_rounded, color: colors.lime, size: 22),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      next?.title ?? '다가오는 일정 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next == null
                          ? '새 일정이 생기면 여기에 보여요.'
                          : '준비물 ${next.remaining}개 남음',
                      style: TextStyle(
                        color: colors.onForestMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('home-add-widget'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('위젯 추가'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '소형·중형 중에서 고를 수 있어요.',
              style: TextStyle(color: colors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
