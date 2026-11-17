import 'package:material_ui/material_ui.dart';

import '../data/schedule_store.dart';
import '../models/schedule.dart';
import '../models/reminder_plan.dart';
import '../platform/notification_bridge.dart';
import '../design/app_theme.dart';

class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    super.key,
    required this.store,
    this.initial,
    this.followUpTo,
    this.initialCategory,
  });
  final ScheduleStore store;
  final Schedule? initial;
  final Schedule? followUpTo;
  final String? initialCategory;
  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController memo;
  late final TextEditingController link;
  final preparation = TextEditingController();
  late DateTime date;
  TimeOfDay? time;
  late String category;
  late List<Preparation> items;
  late Set<int> reminderDays;
  late TimeOfDay reminderTime;
  String? reminderError;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    title = TextEditingController(
      text:
          initial?.title ??
          (widget.followUpTo == null
              ? ''
              : '${widget.followUpTo!.title} 결과 확인'),
    );
    memo = TextEditingController(text: initial?.memo);
    link = TextEditingController(text: initial?.link);
    date = initial?.deadline ?? DateTime.now();
    time = initial?.hasTime == true ? TimeOfDay.fromDateTime(date) : null;
    category =
        initial?.category ??
        widget.followUpTo?.category ??
        (categories.contains(widget.initialCategory)
            ? widget.initialCategory!
            : categories.first);
    items = [...?initial?.items];
    reminderDays = (initial?.reminderDays ?? [1]).toSet();
    reminderTime = TimeOfDay(
      hour: initial?.reminderHour ?? 9,
      minute: initial?.reminderMinute ?? 0,
    );
  }

  @override
  void dispose() {
    title.dispose();
    memo.dispose();
    link.dispose();
    preparation.dispose();
    super.dispose();
  }

  void addItem() {
    final value = preparation.text.trim();
    if (value.isEmpty) return;
    setState(() {
      items.add(Preparation(title: value));
      preparation.clear();
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (reminderDays.contains(0) &&
        time != null &&
        reminderTime.hour * 60 + reminderTime.minute >=
            time!.hour * 60 + time!.minute) {
      setState(() => reminderError = '당일 알림은 마감 시간보다 이르게 설정해 주세요.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reminderError!)));
      return;
    }
    FocusScope.of(context).unfocus();
    // 입력 중인 준비물도 저장해서 '+'를 놓쳐도 내용이 사라지지 않게 합니다.
    addItem();
    setState(() => busy = true);
    final schedule = Schedule(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.text.trim(),
      deadline: DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      ),
      hasTime: time != null,
      category: category,
      stage: widget.initial?.stage ?? ScheduleStage.preparing,
      items: List.of(items),
      memo: memo.text.trim(),
      link: link.text.trim(),
      parentId: widget.initial?.parentId ?? widget.followUpTo?.id,
      reminderDays: reminderDays.toList()..sort(),
      reminderHour: reminderTime.hour,
      reminderMinute: reminderTime.minute,
    );
    try {
      await widget.store.put(schedule);
      if (!mounted) return;
      String? message;
      if (reminderTimes(schedule, DateTime.now()).isNotEmpty) {
        try {
          final status = await NotificationBridge().requestPermission(
            onlyFirstTime: true,
          );
          if (status.supported && (!status.allowed || !status.enabled)) {
            message = '일정은 저장했어요. 마이 → 마감 알림에서 알림을 켜주세요.';
          }
        } catch (_) {
          message = '일정은 저장했어요. 알림 상태는 마이에서 확인해 주세요.';
        }
      } else if (reminderDays.isNotEmpty && !schedule.isCompleted) {
        message = '일정은 저장했어요. 선택한 알림 시각은 이미 지나 예약하지 않았어요.';
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        if (message != null) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial != null
              ? '일정 수정'
              : widget.followUpTo != null
              ? '후속 일정'
              : '새 일정',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.followUpTo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        '연결된 일정 · ${widget.followUpTo!.title}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: title,
                    enabled: !busy,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: '일정 제목',
                      hintText: '예: 국가장학금 신청',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '일정 제목을 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('마감일'),
                          subtitle: Text(
                            '${date.year}년 ${date.month}월 ${date.day}일',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: busy
                              ? null
                              : () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100, 12, 31),
                                  );
                                  if (selected != null && mounted) {
                                    setState(() => date = selected);
                                  }
                                },
                        ),
                        ListTile(
                          leading: const Icon(Icons.schedule),
                          title: const Text('마감 시간'),
                          subtitle: Text(time?.format(context) ?? '시간 지정 안 함'),
                          trailing: time == null
                              ? const Icon(Icons.chevron_right)
                              : IconButton(
                                  tooltip: '시간 지정 해제',
                                  onPressed: busy
                                      ? null
                                      : () => setState(() => time = null),
                                  icon: const Icon(Icons.close),
                                ),
                          onTap: busy
                              ? null
                              : () async {
                                  final selected = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        time ??
                                        const TimeOfDay(hour: 18, minute: 0),
                                  );
                                  if (selected != null && mounted) {
                                    setState(() => time = selected);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: categories
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) => setState(() => category = value!),
                  ),
                  const SizedBox(height: 24),
                  Text('준비물', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...items.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.value.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(entry.value.title),
                      trailing: IconButton(
                        tooltip: '준비물 삭제',
                        onPressed: busy
                            ? null
                            : () => setState(() => items.removeAt(entry.key)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: preparation,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: '준비물 추가',
                            hintText: '예: 재학증명서 발급',
                          ),
                          onSubmitted: (_) => addItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: busy ? null : addItem,
                        tooltip: '준비물 추가',
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('알림', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: reminderOptions
                        .map(
                          (days) => FilterChip(
                            label: Text(reminderLabel(days)),
                            selected: reminderDays.contains(days),
                            onSelected: busy
                                ? null
                                : (selected) => setState(() {
                                    reminderError = null;
                                    selected
                                        ? reminderDays.add(days)
                                        : reminderDays.remove(days);
                                  }),
                          ),
                        )
                        .toList(),
                  ),
                  if (reminderDays.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_none_rounded),
                      title: const Text(
                        '알림 시각',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(reminderTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: busy
                          ? null
                          : () async {
                              final selected = await showTimePicker(
                                context: context,
                                initialTime: reminderTime,
                              );
                              if (selected != null && mounted) {
                                setState(() {
                                  reminderTime = selected;
                                  reminderError = null;
                                });
                              }
                            },
                    ),
                  if (reminderError != null)
                    Text(
                      reminderError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    '절전 상태에서는 알림이 늦어질 수 있어요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: memo,
                    enabled: !busy,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '메모 (선택)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: link,
                    enabled: !busy,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: '참고 링크 (선택)',
                      hintText: 'https://',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final uri = Uri.tryParse(value.trim());
                      return uri != null &&
                              ['http', 'https'].contains(uri.scheme) &&
                              uri.host.isNotEmpty
                          ? null
                          : 'http:// 또는 https://로 시작하는 링크를 입력해 주세요.';
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: busy ? null : save,
                    icon: const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(busy ? '저장 중…' : '저장하기'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
