import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_first_app/main.dart';

import 'schedule_store_test.dart' show MemoryStorage;
import 'support/commerce_fakes.dart' show MemoryAppearanceStorage;

void main() {
  testWidgets('한국어 날짜·시간 선택창을 열고 마감 시간을 저장한다', (tester) async {
    final storage = MemoryStorage();
    await tester.pumpWidget(
      MyApp(storage: storage, appearanceStorage: MemoryAppearanceStorage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, '일정 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '일정 제목'),
      '한국어 선택창 확인',
    );
    await tester.tap(find.text('마감일'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(DatePickerDialog))),
      const Locale('ko'),
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('마감 시간'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장하기'));
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    final saved = (await storage.load()).single;
    expect(saved.hasTime, isTrue);
    expect(saved.deadline.hour, 18);
    expect(saved.deadline.minute, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
