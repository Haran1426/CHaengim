import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/widgets/schedule_card.dart';
import 'schedule_store_test.dart' show MemoryStorage;

void main() {
  testWidgets('일정 추가, 준비물 체크, 홈 반영과 앱 재시작 복원', (tester) async {
    final storage = MemoryStorage();
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('지금 챙길 일정이 없어요'), findsOneWidget);
    await tester.tap(find.widgetWithText(FloatingActionButton, '일정 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '일정 제목'),
      '장학금 신청',
    );
    await tester.ensureVisible(find.widgetWithText(TextField, '준비물 추가'));
    await tester.enterText(find.widgetWithText(TextField, '준비물 추가'), '증명서');
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.text('장학금 신청'), findsWidgets);
    await tester.tap(find.byType(ScheduleCard).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(find.text('준비물 · 0개 남음'), findsOneWidget);
    expect(find.text('준비 중'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('준비물 1/1 완료 · 0개 남음'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('장학금 신청'), findsOneWidget);
    expect(find.text('준비물 1/1 완료 · 0개 남음'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('완료 일정은 홈에서 제외하고 완료 필터에서 확인한다', (tester) async {
    final storage = MemoryStorage();
    await storage.save([
      Schedule(
        id: 'done',
        title: '완료된 일정',
        deadline: DateTime(2026, 1, 1),
        stage: ScheduleStage.completed,
      ),
    ]);
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('완료된 일정'), findsNothing);
    await tester.tap(find.text('일정'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '완료'));
    await tester.pumpAndSettle();
    expect(find.text('완료된 일정'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
