import 'support/commerce_fakes.dart' show MemoryAppearanceStorage;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/widgets/schedule_card.dart';
import 'schedule_store_test.dart' show MemoryStorage;

void main() {
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
