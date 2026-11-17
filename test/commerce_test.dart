import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/appearance_store.dart';
import 'package:my_first_app/data/plus_store.dart';
import 'package:my_first_app/design/app_theme.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/platform/widget_bridge.dart';
import 'package:my_first_app/screens/plus_screen.dart';
import 'schedule_store_test.dart' show MemoryStorage;
import 'support/commerce_fakes.dart';

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  test('테마 저장 실패 시 기존 테마 유지, 구매 전 유료 적용 차단, 권한 회수 시 기본 복원', () async {
    final storage = MemoryAppearanceStorage();
    final snapshots = <AppPalette>[];
    final appearance = AppearanceStore(
      storage,
      syncWidget: (palette) async {
        snapshots.add(palette);
      },
    );
    await appearance.load();
    expect(await appearance.select(AppSkin.iris), isFalse);
    expect(storage.id, null);
    await appearance.select(AppSkin.sand);
    storage.fail = true;
    expect(await appearance.select(AppSkin.forest), isFalse);
    expect(appearance.active, AppSkin.sand);
    storage.fail = false;
    await appearance.setPlus(true);
    await appearance.select(AppSkin.iris);
    expect(snapshots.last, AppSkin.iris.palette);
    await appearance.setPlus(false);
    expect(appearance.active, AppSkin.forest);
    expect(snapshots.last, AppSkin.forest.palette);
    // 권한 복원 시 이전 취향을 잃지 않습니다.
    final restarted = AppearanceStore(storage);
    await restarted.load();
    expect(restarted.active, AppSkin.forest);
    await restarted.setPlus(true);
    expect(restarted.active, AppSkin.iris);
    appearance.dispose();
    restarted.dispose();
  });

  test('미설정 스토어는 결제를 시작하지 않고, 확인 전에는 광고를 숨긴다', () async {
    final gateway = FakePlusGateway(configured: false);
    final plus = PlusStore(gateway);
    expect(plus.showAds, isFalse);
    await plus.refresh();
    await plus.purchase();
    expect(plus.canBuy, isFalse);
    expect(gateway.purchases, 0);
    expect(plus.showAds, isTrue);
    plus.dispose();
  });

  test('보류·취소·실패로 권한을 열지 않으며 구매·복원·회수를 광고와 함께 반영한다', () async {
    final gateway = FakePlusGateway();
    final plus = PlusStore(gateway);
    await plus.refresh();
    gateway.pending = true;
    await plus.purchase();
    expect(plus.isPlus, isFalse);
    gateway.failure = PlatformException(code: '1');
    await plus.purchase();
    expect(plus.isPlus, isFalse);
    expect(plus.message, '결제가 취소됐어요.');
    gateway.failure = StateError('offline');
    await plus.purchase();
    expect(plus.isPlus, isFalse);
    gateway.failure = null;
    gateway.pending = false;
    await Future.wait([plus.purchase(), plus.purchase()]);
    expect(
      gateway.purchases,
      4,
    ); // pending, cancel, fail, single successful buy
    expect(plus.isPlus, isTrue);
    expect(plus.showAds, isFalse);
    gateway.revoke();
    expect(plus.showAds, isTrue);
    gateway.owned = true;
    await plus.restore();
    expect(plus.isPlus, isTrue);
    expect(plus.message, '플러스 구매를 복원했어요.');
    plus.dispose();
  });

  testWidgets('유료 테마 미리보기는 저장하지 않고 무료 테마는 전체 화면과 재시작에 반영된다', (tester) async {
    final appearance = MemoryAppearanceStorage();
    final schedules = MemoryStorage();
    await tester.pumpWidget(
      MyApp(storage: schedules, appearanceStorage: appearance),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('open-appearance')));
    await tester.tap(find.byKey(const ValueKey('open-appearance')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('skin-iris')));
    await tester.tap(find.byKey(const ValueKey('skin-iris')));
    await tester.pumpAndSettle();
    expect(appearance.id, null);
    await reveal(tester, find.byKey(const ValueKey('apply-theme')));
    await tester.tap(find.byKey(const ValueKey('apply-theme')));
    await tester.pumpAndSettle();
    expect(find.byType(PlusScreen), findsOneWidget);
    expect(appearance.id, null);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('skin-sand')), delta: -200);
    await tester.tap(find.byKey(const ValueKey('skin-sand')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('apply-theme')));
    await tester.tap(find.byKey(const ValueKey('apply-theme')));
    await tester.pumpAndSettle();
    expect(appearance.id, 'sand');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MyApp(storage: schedules, appearanceStorage: appearance),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .colorScheme
          .primary,
      AppSkin.sand.palette.forest,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('320px·글자 1.6배에서도 플러스 모든 테마와 결제 안내가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final plus = PlusStore(FakePlusGateway(configured: false));
    await plus.refresh();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PlusScreen(plus: plus),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    for (final skin in AppSkin.values) {
      await reveal(tester, find.byKey(ValueKey('skin-${skin.name}')));
      await tester.tap(find.byKey(ValueKey('skin-${skin.name}')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    }
    await reveal(tester, find.byKey(const ValueKey('buy-plus')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('buy-plus')))
          .onPressed,
      null,
    );
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    plus.dispose();
  });

  testWidgets('위젯으로 선택 팔레트의 ARGB 정수값을 전달한다', (tester) async {
    final previous = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = previous);
    MethodCall? received;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      WidgetBridge.channel,
      (call) async {
        received = call;
        return null;
      },
    );
    await WidgetBridge().syncAppearance(AppSkin.iris.palette);
    expect(received!.method, 'appearance');
    expect(received!.arguments['background'], 0xFF56436E);
    expect(received!.arguments['accent'], 0xFFE5D8F7);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      WidgetBridge.channel,
      null,
    );
    debugDefaultTargetPlatformOverride = previous;
  });
}
