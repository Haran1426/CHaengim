import 'package:material_ui/material_ui.dart';
import '../data/schedule_store.dart';
import '../models/schedule.dart';
import 'schedule_editor.dart';
import '../design/app_theme.dart';
import '../models/reminder_plan.dart';

class ScheduleDetail extends StatelessWidget {
  const ScheduleDetail({super.key, required this.store, required this.id});
  final ScheduleStore store;
  final String id;

  Future<void> update(BuildContext context, Schedule schedule) async {
    try {
      await store.put(schedule);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('변경사항을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<void> delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 일정을 삭제할까요?'),
        content: const Text('준비물과 메모도 함께 삭제돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await store.remove(id);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final matching = store.schedules.where((s) => s.id == id);
      if (matching.isEmpty) {
        return const Scaffold(body: Center(child: Text('일정이 삭제되었어요.')));
      }
      final schedule = matching.first;
      final nextReminders = reminderTimes(schedule, DateTime.now());
      final children = store.schedules.where((s) => s.parentId == id).toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      final parents = store.schedules.where((s) => s.id == schedule.parentId);
      return Scaffold(
        appBar: AppBar(
          title: const Text('일정 상세'),
          actions: [
            IconButton(
              tooltip: '일정 수정',
              icon: const Icon(Icons.edit_outlined),
              onPressed: store.saving
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ScheduleEditor(store: store, initial: schedule),
                      ),
                    ),
            ),
            IconButton(
              tooltip: '일정 삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: store.saving ? null : () => delete(context),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${schedule.category} · ${schedule.isCompleted ? '완료' : schedule.dDay(DateTime.now())}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 17,
                      color: context.appColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '마감 ${formatDeadline(schedule)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.reminderDays.isEmpty
                                  ? '이 일정은 알림이 꺼져 있어요'
                                  : '${schedule.reminderDays.map(reminderLabel).join(' · ')} / ${schedule.reminderHour.toString().padLeft(2, '0')}:${schedule.reminderMinute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (schedule.reminderDays.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                schedule.isCompleted
                                    ? '최종 완료한 일정은 알림을 보내지 않아요.'
                                    : nextReminders.isEmpty
                                    ? '선택한 알림 시각이 지나 예약할 알림이 없어요.'
                                    : '알림 수신 상태는 마이 → 마감 알림에서 확인해요.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.appColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: ScheduleStage.values
                        .map(
                          (stage) => Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: stage.index <= schedule.stage.index
                                        ? context.appColors.forest
                                        : Colors.white,
                                  ),
                                  child: Icon(
                                    stage.index < schedule.stage.index
                                        ? Icons.check_rounded
                                        : stage == schedule.stage
                                        ? Icons.circle
                                        : Icons.circle_outlined,
                                    size: stage == schedule.stage ? 9 : 16,
                                    color: stage.index <= schedule.stage.index
                                        ? context.appColors.lime
                                        : context.appColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  [
                                    '준비',
                                    '제출·처리',
                                    '결과 대기',
                                    '최종 완료',
                                  ][stage.index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.appColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<ScheduleStage>(
                  key: ValueKey('${schedule.stage}:${store.saving}'),
                  initialValue: schedule.stage,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '진행 단계'),
                  items: ScheduleStage.values
                      .map(
                        (stage) => DropdownMenuItem(
                          value: stage,
                          child: Text(stage.label),
                        ),
                      )
                      .toList(),
                  onChanged: store.saving
                      ? null
                      : (stage) {
                          if (stage != null) {
                            update(context, schedule.copyWith(stage: stage));
                          }
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  '준비가 끝나면 실제 제출·처리도 확인해주세요.\n진행 단계는 직접 변경할 수 있어요.',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '준비물 · ${schedule.remaining}개 남음',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (schedule.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('아직 준비물이 없어요. 상단 수정 버튼으로 추가해보세요.'),
                  ),
                ...schedule.items.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          entry.value.title,
                          style: TextStyle(
                            decoration: entry.value.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        value: entry.value.done,
                        onChanged: store.saving
                            ? null
                            : (value) {
                                final items = [...schedule.items];
                                items[entry.key] = Preparation(
                                  title: entry.value.title,
                                  done: value ?? false,
                                );
                                update(
                                  context,
                                  schedule.copyWith(items: items),
                                );
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '이어서 챙길 일정',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: store.saving
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ScheduleEditor(
                                  store: store,
                                  followUpTo: schedule,
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('추가', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (children.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '결과 발표, 추가 서류 제출 같은\n다음 일정을 연결해보세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.muted,
                      ),
                    ),
                  ),
                ...children.map(
                  (child) => Card(
                    child: ListTile(
                      title: Text(
                        child.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${formatDeadline(child)} · ${child.stage.label}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ScheduleDetail(store: store, id: child.id),
                        ),
                      ),
                    ),
                  ),
                ),
                if (parents.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ScheduleDetail(store: store, id: parents.first.id),
                      ),
                    ),
                    icon: const Icon(Icons.subdirectory_arrow_left, size: 16),
                    label: Text(
                      '이전 일정 · ${parents.first.title}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (schedule.memo.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('메모', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(schedule.memo),
                ],
                if (schedule.link.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('참고 링크', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(schedule.link),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
