import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/schedule_store.dart';
import 'package:my_first_app/models/schedule.dart';

class MemoryStorage implements ScheduleStorage {
  String? value;
  bool fail = false;
  @override
  Future<List<Schedule>> load() async => value == null
      ? []
      : (jsonDecode(value!) as List)
            .map(
              (item) =>
                  Schedule.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
  @override
  Future<void> save(List<Schedule> schedules) async {
    if (fail) throw Exception('Storage unavailable');
    value = jsonEncode(schedules.map((item) => item.toJson()).toList());
  }
}

Schedule example() => Schedule(
  id: '1',
  title: '장학금 신청',
  deadline: DateTime(2026, 12, 1),
  items: const [Preparation(title: '증명서')],
);

void main() {
  test('저장 후 새로운 저장소에서 준비물과 진행 단계를 복원한다', () async {
    final storage = MemoryStorage();
    final store = ScheduleStore(storage);
    await store.load();
    await store.put(example());
    await store.put(
      example().copyWith(items: const [Preparation(title: '증명서', done: true)]),
    );
    final reopened = ScheduleStore(storage);
    await reopened.load();
    expect(reopened.schedules.single.remaining, 0);
    expect(reopened.schedules.single.stage, ScheduleStage.preparing);
    await reopened.put(
      reopened.schedules.single.copyWith(stage: ScheduleStage.waiting),
    );
    await store.load();
    expect(store.schedules.single.stage, ScheduleStage.waiting);
    await store.remove('1');
    await reopened.load();
    expect(reopened.schedules, isEmpty);
    store.dispose();
    reopened.dispose();
  });
  test('저장 실패 시 기존 데이터를 유지하고 다시 저장할 수 있다', () async {
    final storage = MemoryStorage();
    final store = ScheduleStore(storage);
    await store.load();
    await store.put(example());
    storage.fail = true;
    await expectLater(store.remove('1'), throwsException);
    expect(store.schedules, hasLength(1));
    expect(store.saving, false);
    storage.fail = false;
    await store.remove('1');
    expect(store.schedules, isEmpty);
    store.dispose();
  });
  test('D-day는 달력 날짜로 계산하고 기한 경과는 완료로 바꾸지 않는다', () {
    final schedule = example();
    expect(schedule.dDay(DateTime(2026, 11, 30, 23, 59)), 'D-1');
    expect(schedule.dDay(DateTime(2026, 12, 1, 23)), 'D-day');
    expect(schedule.dDay(DateTime(2026, 12, 2)), '기한 지남');
    expect(schedule.isCompleted, false);
  });
}
