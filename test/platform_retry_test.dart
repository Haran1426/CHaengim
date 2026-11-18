import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_first_app/platform/ads_controller.dart';
import 'package:my_first_app/platform/notification_bridge.dart';
import 'package:my_first_app/screens/notification_settings.dart';

class EnabledAds extends AdsController {
  @override
  bool get configured => true;
}

void main() {
  testWidgets('광고 초기화 실패 후 재시도하되 동시에 중복 초기화하지 않는다', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/google_mobile_ads');
    var calls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'MobileAds#initialize') {
        calls++;
        throw PlatformException(code: 'offline');
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final ads = EnabledAds();
    await Future.wait([ads.initialize(), ads.initialize()]);
    expect(calls, 1);
    expect(ads.ready, isFalse);
    await ads.initialize();
    expect(calls, 2);
    ads.dispose();
  });

  testWidgets('늦은 알림 상태 응답이 앱 복귀 후 확인한 상태를 덮지 않는다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final first = Completer<Map<String, Object>>();
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      NotificationBridge.channel,
      (call) async {
        if (call.method != 'status') return null;
        reads++;
        return reads == 1
            ? first.future
            : {'allowed': true, 'enabled': true, 'asked': true, 'pending': 2};
      },
    );
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        NotificationBridge.channel,
        null,
      );
    });
    await tester.pumpWidget(const MaterialApp(home: NotificationSettings()));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('2개의 알림이 예약되어 있어요'), findsOneWidget);
    first.complete({
      'allowed': false,
      'enabled': true,
      'asked': false,
      'pending': 0,
    });
    await tester.pumpAndSettle();
    expect(find.text('2개의 알림이 예약되어 있어요'), findsOneWidget);
    expect(find.text('Android 알림이 꺼져 있어요'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    // Flutter 3.47 checks debug overrides before addTearDown callbacks run.
    debugDefaultTargetPlatformOverride = null;
  });
}
