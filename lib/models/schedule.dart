enum ScheduleStage {
  preparing('준비 중'),
  submitted('제출·처리 완료'),
  waiting('결과 대기'),
  completed('최종 완료');

  const ScheduleStage(this.label);
  final String label;
}

class Preparation {
  const Preparation({required this.title, this.done = false});
  final String title;
  final bool done;
  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory Preparation.fromJson(Map<String, dynamic> json) =>
      Preparation(title: json['title'] as String, done: json['done'] as bool);
}

class Schedule {
  const Schedule({
    required this.id,
    required this.title,
    required this.deadline,
    this.hasTime = false,
    this.category = '기타',
    this.stage = ScheduleStage.preparing,
    this.items = const [],
    this.memo = '',
    this.link = '',
    this.parentId,
    this.reminderDays = const [1],
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });
  final String id;
  final String title;
  final DateTime deadline;
  final bool hasTime;
  final String category;
  final ScheduleStage stage;
  final List<Preparation> items;
  final String memo;
  final String link;
  final String? parentId;
  final List<int> reminderDays;
  final int reminderHour;
  final int reminderMinute;
  int get remaining => items.where((item) => !item.done).length;
  bool get isCompleted => stage == ScheduleStage.completed;
  int daysLeft(DateTime now) => DateTime.utc(
    deadline.year,
    deadline.month,
    deadline.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  String dDay(DateTime now) {
    final days = daysLeft(now);
    if (isExpired(now)) return '기한 지남';
    return days == 0 ? 'D-day' : 'D-$days';
  }

  bool isExpired(DateTime now) =>
      hasTime ? !now.isBefore(deadline) : daysLeft(now) < 0;

  Schedule copyWith({ScheduleStage? stage, List<Preparation>? items}) =>
      Schedule(
        id: id,
        title: title,
        deadline: deadline,
        hasTime: hasTime,
        category: category,
        stage: stage ?? this.stage,
        items: items ?? this.items,
        memo: memo,
        link: link,
        parentId: parentId,
        reminderDays: reminderDays,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'deadline': deadline.toIso8601String(),
    'hasTime': hasTime,
    'category': category,
    'stage': stage.name,
    'items': items.map((item) => item.toJson()).toList(),
    'memo': memo,
    'link': link,
    'parentId': parentId,
    'reminderDays': reminderDays,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };
  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    title: json['title'] as String,
    deadline: DateTime.parse(json['deadline'] as String),
    hasTime: json['hasTime'] as bool,
    category: json['category'] as String,
    stage: ScheduleStage.values.byName(json['stage'] as String),
    items: (json['items'] as List)
        .map(
          (item) =>
              Preparation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    memo: json['memo'] as String,
    link: json['link'] as String,
    parentId: json['parentId'] as String?,
    // 기존 일정에는 알림을 자동 추가하지 않습니다.
    reminderDays:
        ((json['reminderDays'] as List?) ?? [])
            .whereType<int>()
            .where((d) => [0, 1, 3, 7].contains(d))
            .toSet()
            .toList()
          ..sort(),
    reminderHour: (json['reminderHour'] as int? ?? 9).clamp(0, 23),
    reminderMinute: (json['reminderMinute'] as int? ?? 0).clamp(0, 59),
  );
}

const categories = ['지원·신청', '시험·자격증', '학교', '생활', '기타'];
String formatDeadline(Schedule schedule) {
  final date = schedule.deadline;
  final day =
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  return schedule.hasTime
      ? '$day ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
      : day;
}
