import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/schedule_store.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/models/reminder_plan.dart';
import 'schedule_store_test.dart' show MemoryStorage;

void main() {
  Schedule example({
    bool hasTime = true,
    List<int> days = const [0, 1, 3, 7],
    ScheduleStage stage = ScheduleStage.preparing,
  }) => Schedule(
    id: 'a',
    title: '신청',
    deadline: DateTime(2026, 12, 20, 18),
    hasTime: hasTime,
    reminderDays: days,
    stage: stage,
  );
  test('달력 날짜 기준으로 선택한 0·1·3·7일 전 오전 9시만 예약한다', () {
    expect(reminderTimes(example(), DateTime(2026, 12, 1)), [
      DateTime(2026, 12, 13, 9),
      DateTime(2026, 12, 17, 9),
      DateTime(2026, 12, 19, 9),
      DateTime(2026, 12, 20, 9),
    ]);
  });
  test('지난 시각, 완료, 알림 해제, 중복과 알 수 없는 날짜를 제외한다', () {
    expect(reminderTimes(example(), DateTime(2026, 12, 20, 8)), [
      DateTime(2026, 12, 20, 9),
    ]);
    expect(reminderTimes(example(), DateTime(2026, 12, 20, 9)), isEmpty);
    expect(
      reminderTimes(
        example(stage: ScheduleStage.completed),
        DateTime(2026, 12, 1),
      ),
      isEmpty,
    );
    expect(reminderTimes(example(days: []), DateTime(2026, 12, 1)), isEmpty);
    expect(reminderTimes(example(days: [1, 1, 2, -1]), DateTime(2026, 12, 1)), [
      DateTime(2026, 12, 19, 9),
    ]);
  });
  test('당일이라도 마감 시각이 지났으면 기한 지남이고, 날짜 전용 일정은 하루 전체가 유효하다', () {
    expect(example().dDay(DateTime(2026, 12, 20, 18)), '기한 지남');
    expect(example().isCompleted, false);
    expect(
      example(hasTime: false).dDay(DateTime(2026, 12, 20, 23, 59)),
      'D-day',
    );
  });
  test('기존 데이터는 알림 없이 복원하고 새 설정은 준비물 변경 후에도 유지한다', () {
    final old = example().toJson()
      ..remove('reminderDays')
      ..remove('reminderHour')
      ..remove('reminderMinute');
    expect(Schedule.fromJson(old).reminderDays, isEmpty);
    final restored = Schedule.fromJson(
      example().copyWith(items: const [Preparation(title: '서류')]).toJson(),
    );
    expect(restored.reminderDays, [0, 1, 3, 7]);
    expect(restored.reminderHour, 9);
  });
  test('완료 일정은 Android 예약 스냅샷에서도 제외한다', () {
    final rows = reminderSnapshot([
      example(),
      example(stage: ScheduleStage.completed),
    ]);
    expect(rows, hasLength(1));
    expect(rows.single['days'], [0, 1, 3, 7]);
    expect(rows.single['year'], 2026);
  });
  test('알림 예약 실패는 저장 성공을 취소하지 않고 재시도한다', () async {
    var fail = true;
    final store = ScheduleStore(
      MemoryStorage(),
      onRemindersChanged: (_) async {
        if (fail) throw Exception('alarm unavailable');
      },
    );
    await store.load();
    expect(store.loadError, null);
    await store.put(example());
    expect(store.schedules, hasLength(1));
    expect(store.reminderError, isNotNull);
    fail = false;
    await store.syncReminders();
    expect(store.reminderError, null);
    store.dispose();
  });
}
