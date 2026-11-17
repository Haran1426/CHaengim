import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/platform/ads_controller.dart';
import 'package:my_first_app/widgets/sponsor_banner.dart';

import 'schedule_store_test.dart' show MemoryStorage;
import 'support/commerce_fakes.dart';

class TrackingAds extends AdsController {
  int initializations = 0;
  @override
  bool get configured => true;
  @override
  Future<void> initialize() async {
    initializations++;
  }
}

void main() {
  testWidgets('광고 영역이 표시될 때 SDK 초기화를 시도한다', (tester) async {
    final ads = TrackingAds();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SponsorBanner(ads: ads))),
    );
    await tester.pumpAndSettle();
    expect(ads.initializations, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ads.dispose();
  });

  testWidgets('홈 시작에는 광고 SDK를 초기화하지 않는다', (tester) async {
    final ads = TrackingAds();
    await tester.pumpWidget(
      MyApp(
        storage: MemoryStorage(),
        appearanceStorage: MemoryAppearanceStorage(),
        plusGateway: FakePlusGateway(configured: false),
        adsController: ads,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('지금 챙길 일정이 없어요'), findsOneWidget);
    expect(ads.initializations, 0);
    await tester.tap(find.text('일정'));
    await tester.pumpAndSettle();
    expect(ads.initializations, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
