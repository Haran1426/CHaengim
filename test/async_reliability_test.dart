import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/data/appearance_store.dart';
import 'package:my_first_app/data/plus_store.dart';
import 'package:my_first_app/data/schedule_store.dart';
import 'package:my_first_app/design/app_skin.dart';
import 'package:my_first_app/models/schedule.dart';

import 'schedule_store_test.dart' show MemoryStorage, example;
import 'support/commerce_fakes.dart';

class SlowStorage extends MemoryStorage {
  final read = Completer<List<Schedule>>();
  int reads = 0;
  @override
  Future<List<Schedule>> load() {
    reads++;
    return read.future;
  }
}

class SlowGateway extends FakePlusGateway {
  final response = Completer<bool>();
  int refreshes = 0;
  @override
  Future<bool> refresh() {
    refreshes++;
    return response.future;
  }
}

class SlowAppearance extends MemoryAppearanceStorage {
  final response = Completer<String?>();
  @override
  Future<String?> load() => response.future;
}

class WritingStorage extends MemoryStorage {
  final written = Completer<void>();
  bool writing = false, readDuringWrite = false;
  @override
  Future<List<Schedule>> load() {
    readDuringWrite |= writing;
    return super.load();
  }

  @override
  Future<void> save(List<Schedule> schedules) async {
    writing = true;
    await written.future;
    await super.save(schedules);
    writing = false;
  }
}

class ControlledStorage extends MemoryStorage {
  Future<List<Schedule>> Function()? read;
  @override
  Future<List<Schedule>> load() => read?.call() ?? super.load();
}

class ControlledGateway extends FakePlusGateway {
  Future<bool> Function()? read;
  int initializations = 0;
  @override
  Future<void> initialize(void Function(bool) onChanged) async {
    initializations++;
    await super.initialize(onChanged);
  }

  @override
  Future<bool> refresh() => read?.call() ?? super.refresh();
}

void main() {
  testWidgets('새로고침 실패 안내와 기존 일정을 함께 보여주고 다시 시도한다', (tester) async {
    final storage = ControlledStorage();
    await storage.save([example()]);
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    storage.read = () async => throw StateError('read failed');
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('새로 불러오지 못해 마지막으로 확인한 일정을 보여드려요.'), findsOneWidget);
    expect(find.text('장학금 신청'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
    storage.read = null;
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('다시 불러오기'), findsNothing);
    expect(find.text('장학금 신청'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('시간 초과한 옛 로딩 결과가 재시도 후 일정을 덮지 않는다', () async {
    final oldRead = Completer<List<Schedule>>();
    final storage = ControlledStorage()..read = () => oldRead.future;
    final store = ScheduleStore(
      storage,
      readTimeout: const Duration(milliseconds: 5),
    );
    await store.load();
    expect(store.loading, isFalse);
    expect(store.loadError, isNotNull);
    storage.read = () async => [example()];
    await store.load();
    oldRead.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(store.loadError, isNull);
    expect(store.schedules.single.id, '1');
    store.dispose();
  });

  test('새로고침 실패 때 마지막 일정과 저장된 원본을 유지한다', () async {
    final storage = ControlledStorage();
    final store = ScheduleStore(storage);
    await store.load();
    await store.put(example());
    storage.read = () async => throw StateError('read failed');
    await store.load();
    expect(store.hasLoaded, isTrue);
    expect(store.loadError, isNotNull);
    expect(store.canEdit, isFalse);
    expect(store.schedules.single.id, '1');
    storage.read = null;
    await store.load();
    expect(store.loadError, isNull);
    expect(store.canEdit, isTrue);
    expect(store.schedules.single.id, '1');
    store.dispose();
  });

  test('위젯 지연에도 저장은 끝나고 알림은 별도로 동기화한다', () async {
    final stuck = Completer<void>();
    final received = <List<Schedule>>[], reminders = <List<Schedule>>[];
    final store = ScheduleStore(
      MemoryStorage(),
      syncTimeout: const Duration(milliseconds: 5),
      onChanged: (value) async {
        received.add(value);
        if (value.isEmpty) await stuck.future;
      },
      onRemindersChanged: (value) async => reminders.add(value),
    );
    await store.load();
    await store.put(example());
    expect(store.saving, isFalse);
    expect(store.widgetError, isNotNull);
    expect(reminders.last.single.id, '1');
    expect(received, hasLength(1));
    final retry = store.syncWidget();
    stuck.complete();
    await retry;
    expect(received, hasLength(2));
    expect(received.last.single.id, '1');
    expect(store.widgetError, isNull);
    store.dispose();
  });

  test('중복 구매 상태 새로고침은 같은 조회 완료까지 기다린다', () async {
    final gateway = SlowGateway();
    final plus = PlusStore(gateway);
    final first = plus.refresh();
    var secondDone = false;
    final second = plus.refresh().then((_) => secondDone = true);
    await Future<void>.delayed(Duration.zero);
    expect(secondDone, isFalse);
    gateway.response.complete(true);
    await Future.wait([first, second]);
    expect(gateway.refreshes, 1);
    expect(plus.isPlus, isTrue);
    plus.dispose();
  });

  test('구매 조회 시간 초과 후 재시도가 되고 늦은 응답은 무시한다', () async {
    final oldRead = Completer<bool>();
    final gateway = ControlledGateway()..read = () => oldRead.future;
    final plus = PlusStore(
      gateway,
      requestTimeout: const Duration(milliseconds: 5),
    );
    await plus.refresh();
    expect(plus.loading, isFalse);
    expect(plus.message, contains('늦어지고'));
    expect(plus.resolved, isFalse);
    gateway.read = () async => true;
    await plus.refresh();
    oldRead.complete(false);
    await Future<void>.delayed(Duration.zero);
    expect(plus.isPlus, isTrue);
    expect(plus.message, isNull);
    expect(gateway.initializations, 1);
    plus.dispose();
  });

  test('동시에 요청한 일정 새로고침은 한 번만 읽는다', () async {
    final storage = SlowStorage();
    final store = ScheduleStore(storage);
    final first = store.load();
    final second = store.load();
    storage.read.complete([example()]);
    await Future.wait([first, second]);
    expect(storage.reads, 1);
    store.dispose();
  });

  test('첫 로딩 중 복귀 동기화가 Android에 빈 일정을 보내지 않는다', () async {
    final storage = SlowStorage();
    final widgets = <List<Schedule>>[], reminders = <List<Schedule>>[];
    final store = ScheduleStore(
      storage,
      onChanged: (value) async => widgets.add(value),
      onRemindersChanged: (value) async => reminders.add(value),
    );
    final loading = store.load();
    await Future.wait([store.syncWidget(), store.syncReminders()]);
    storage.read.complete([example()]);
    await loading;
    expect(widgets.map((value) => value.length), [1]);
    expect(reminders.map((value) => value.length), [1]);
    store.dispose();
  });

  test('새로고침은 진행 중인 로컬 저장이 끝난 뒤 읽는다', () async {
    final storage = WritingStorage();
    final store = ScheduleStore(storage);
    await store.load();
    final saving = store.put(example());
    final refreshing = store.load();
    await Future<void>.delayed(Duration.zero);
    storage.written.complete();
    await Future.wait([saving, refreshing]);
    expect(storage.readDuringWrite, isFalse);
    expect(store.schedules.single.id, '1');
    store.dispose();
  });

  test('늦게 도착한 구매 조회가 최신 스토어 알림을 덮지 않는다', () async {
    final gateway = SlowGateway();
    final plus = PlusStore(gateway);
    final loading = plus.refresh();
    await Future<void>.delayed(Duration.zero);
    gateway.listener!(true);
    gateway.response.complete(false);
    await loading;
    expect(plus.isPlus, isTrue);
    plus.dispose();
  });

  test('테마 로딩 중 복귀해도 기본 테마를 위젯에 덮어쓰지 않는다', () async {
    final storage = SlowAppearance();
    final palettes = <AppPalette>[];
    final appearance = AppearanceStore(
      storage,
      syncWidget: (value) async => palettes.add(value),
    );
    final loading = appearance.load();
    final retrying = appearance.retry();
    storage.response.complete('sand');
    await Future.wait([loading, retrying]);
    expect(palettes, [AppSkin.sand.palette]);
    appearance.dispose();
  });
}
