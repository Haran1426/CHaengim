import 'support/commerce_fakes.dart' show MemoryAppearanceStorage;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/design/app_theme.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/widgets/schedule_card.dart';
import 'package:my_first_app/widgets/week_overview.dart';
import 'package:my_first_app/screens/schedule_editor.dart';
import 'package:my_first_app/data/schedule_store.dart';

import 'schedule_store_test.dart' show MemoryStorage;

void main() {
  testWidgets('휴대폰 하단 버튼 영역과 키보드가 저장 버튼을 덮지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 64);
    tester.view.padding = const FakeViewPadding(bottom: 64);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetPadding();
      tester.view.resetViewInsets();
    });
    final store = ScheduleStore(MemoryStorage());
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ScheduleEditor(store: store),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    expect(tester.getRect(list).bottom, lessThanOrEqualTo(780));
    await tester.drag(list, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('저장하기')).bottom, lessThan(780));
    tester.view.padding = const FakeViewPadding();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(list).bottom, lessThanOrEqualTo(544));
    expect(tester.getRect(find.text('저장하기')).bottom, lessThan(544));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
  setUpAll(() async {
    // 글꼴 교체로 달라지는 실제 한글 폭과 줄 높이도 검수합니다.
    final body = FontLoader('NotoSansKR');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      body.addFont(
        rootBundle.load('assets/fonts/notosanskr/NotoSansKR-$weight.ttf'),
      );
    }
    await body.load();
  });

  testWidgets('320px 화면과 큰 글씨에서 홈·일정·위젯 가이드가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final storage = MemoryStorage();
    await storage.save([
      Schedule(
        id: 'long',
        title: '서류 제출 전 확인해야 하는 긴 이름의 국가장학금 지원 신청',
        deadline: DateTime(2026, 12, 1),
        items: const [Preparation(title: '가구원 정보 제공 동의와 증명 서류 준비')],
      ),
    ]);
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.tap(find.text('일정'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('위젯 가이드'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MyApp(
        storage: MemoryStorage(),
        appearanceStorage: MemoryAppearanceStorage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quick-add-시험·자격증')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('홈 날짜로 미완료 마감을 찾고 날짜 필터를 해제한다', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final other = DateTime(
      now.year,
      now.month,
      now.day + (now.weekday == 7 ? -1 : 1),
    );
    final storage = MemoryStorage();
    await storage.save([
      Schedule(id: 'today', title: '선택한 날 일정', deadline: today),
      Schedule(id: 'other', title: '다른 날 일정', deadline: other),
      Schedule(
        id: 'completed',
        title: '완료된 일정',
        deadline: today,
        stage: ScheduleStage.completed,
      ),
    ]);
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('마감 2건'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('week-day-${now.year}-${now.month}-${now.day}')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('deadline-day-filter')), findsOneWidget);
    expect(find.text('선택한 날 일정'), findsOneWidget);
    expect(find.text('다른 날 일정'), findsNothing);
    expect(find.text('완료된 일정'), findsNothing);
    await tester.tap(find.byTooltip('날짜 필터 해제'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('deadline-day-filter')), findsNothing);
    expect(find.text('선택한 날 일정'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('다른 날 일정'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('다른 날 일정'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('주간 마감은 월 경계를 넘고 완료 일정과 다음 주를 제외한다', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: WeekOverview(
            today: DateTime(2026, 12, 1),
            schedules: [
              Schedule(
                id: 'monday',
                title: '월요일',
                deadline: DateTime(2026, 11, 30),
              ),
              Schedule(
                id: 'sunday',
                title: '일요일',
                deadline: DateTime(2026, 12, 6),
              ),
              Schedule(
                id: 'next',
                title: '다음 주',
                deadline: DateTime(2026, 12, 7),
              ),
              Schedule(
                id: 'done',
                title: '완료',
                deadline: DateTime(2026, 12, 1),
                stage: ScheduleStage.completed,
              ),
            ],
            onSelected: (day) => selected = day,
          ),
        ),
      ),
    );
    expect(find.text('마감 2건'), findsOneWidget);
    expect(find.byKey(const ValueKey('week-day-2026-11-30')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('week-day-2026-12-6')));
    expect(selected, DateTime(2026, 12, 6));
    expect(find.bySemanticsLabel('12월 6일 일요일, 미완료 마감 1건'), findsOneWidget);
  });

  testWidgets('빈 홈의 빠른 추가에서 선택한 카테고리로 저장한다', (tester) async {
    final storage = MemoryStorage();
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    final shortcut = find.byKey(const ValueKey('quick-add-시험·자격증'));
    await tester.scrollUntilVisible(
      shortcut,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, '시험·자격증');
    expect(await storage.load(), isEmpty);
    await tester.enterText(
      find.widgetWithText(TextFormField, '일정 제목'),
      '시험 접수',
    );
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    final saved = await storage.load();
    expect(saved, hasLength(1));
    expect(saved.single.category, '시험·자격증');
    expect(saved.single.title, '시험 접수');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('후속 일정을 연결해 저장하되 이전 일정의 상태를 자동 변경하지 않는다', (tester) async {
    final storage = MemoryStorage();
    await storage.save([
      Schedule(
        id: 'p',
        title: '장학금 신청',
        deadline: DateTime(2026, 12, 1),
        stage: ScheduleStage.submitted,
      ),
    ]);
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ScheduleCard));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.widgetWithText(TextButton, '추가'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '추가'));
    await tester.pumpAndSettle();
    expect(find.text('장학금 신청 결과 확인'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    final saved = await storage.load();
    expect(saved, hasLength(2));
    expect(saved.last.parentId, 'p');
    expect(saved.first.stage, ScheduleStage.submitted);
    await tester.pumpWidget(const SizedBox());
  });
}
