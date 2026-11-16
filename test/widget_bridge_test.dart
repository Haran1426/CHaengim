import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/schedule_store.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/platform/widget_bridge.dart';
import 'schedule_store_test.dart' show MemoryStorage;

void main() {
  test('위젯은 최종 완료를 제외하고 기한순 3건만 전달한다', () {
    final schedules = List.generate(
      5,
      (i) => Schedule(
        id: '$i',
        title: '일정 $i',
        deadline: DateTime(2026, 12, 5 - i),
        stage: i == 4 ? ScheduleStage.completed : ScheduleStage.preparing,
        items: const [
          Preparation(title: '서류'),
          Preparation(title: '신청', done: true),
        ],
      ),
    );
    final snapshot = widgetSnapshot(schedules);
    expect(snapshot.map((s) => s['id']), ['3', '2', '1']);
    expect(snapshot.first['remaining'], 1);
    expect(snapshot.first['stage'], '준비 중');
    expect(widgetSnapshot([]), isEmpty);
  });
  test('위젯 갱신 실패는 일정 저장 성공을 취소하지 않으며 재시도 가능하다', () async {
    var fail = true;
    final store = ScheduleStore(
      MemoryStorage(),
      onChanged: (_) async {
        if (fail) throw Exception('bridge offline');
      },
    );
    await store.load();
    expect(store.loadError, null);
    await store.put(
      Schedule(id: 'a', title: '일정', deadline: DateTime(2026, 12, 1)),
    );
    expect(store.schedules, hasLength(1));
    expect(store.widgetError, isNotNull);
    fail = false;
    await store.syncWidget();
    expect(store.widgetError, null);
    store.dispose();
  });
  test('기존 데이터와 후속 일정 연결 정보를 함께 복원한다', () {
    final parent = Schedule(
      id: 'p',
      title: '접수',
      deadline: DateTime(2026, 12, 1),
    );
    final old = parent.toJson()..remove('parentId');
    expect(Schedule.fromJson(old).parentId, null);
    final child = Schedule(
      id: 'c',
      title: '결과 발표',
      deadline: DateTime(2026, 12, 7),
      parentId: 'p',
    );
    expect(Schedule.fromJson(child.toJson()).parentId, 'p');
  });
}
