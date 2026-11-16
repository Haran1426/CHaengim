import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/platform/notification_bridge.dart';
import 'package:my_first_app/screens/notification_settings.dart';
import 'package:my_first_app/widgets/schedule_card.dart';
import 'schedule_store_test.dart' show MemoryStorage;

void main() {
  testWidgets('일정 수정에서 선택한 알림 날짜를 저장한다', (tester) async {
    final storage = MemoryStorage();
    await storage.save([
      Schedule(
        id: 'p',
        title: '신청',
        deadline: DateTime.now().add(const Duration(days: 20)),
      ),
    ]);
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ScheduleCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('일정 수정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, '3일 전'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '3일 전'));
    await tester.tap(find.widgetWithText(FilterChip, '7일 전'));
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
    expect((await storage.load()).single.reminderDays, [1, 3, 7]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('권한 거절 상태에서 안내하고 허용 후 전체 알림을 끌 수 있다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var allowed = false, enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationBridge.channel, (call) async {
          if (call.method == 'requestPermission') allowed = true;
          if (call.method == 'setEnabled') enabled = call.arguments as bool;
          return call.method == 'setEnabled'
              ? null
              : {
                  'allowed': allowed,
                  'enabled': enabled,
                  'asked': false,
                  'pending': allowed && enabled ? 2 : 0,
                };
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NotificationBridge.channel, null);
    });
    await tester.pumpWidget(const MaterialApp(home: NotificationSettings()));
    await tester.pumpAndSettle();
    expect(find.text('Android 알림이 꺼져 있어요'), findsOneWidget);
    await tester.tap(find.text('알림 권한 허용'));
    await tester.pumpAndSettle();
    expect(find.text('2개의 알림이 예약되어 있어요'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('알림을 잠시 쉬고 있어요'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
