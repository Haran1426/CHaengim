import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/plus_store.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../tool/play_build_config.dart';
import 'support/commerce_fakes.dart';

class BillingGateway extends FakePlusGateway {
  Future<bool> Function()? restoring, buying;
  bool offerFails = false;
  @override
  Future<PlusOffer?> offer() async {
    if (offerFails) throw StateError('store offline');
    return super.offer();
  }

  @override
  Future<bool> restore() => restoring?.call() ?? super.restore();
  @override
  Future<bool> buy() => buying?.call() ?? super.buy();
}

void main() {
  test('대기 결제는 중복 구매를 막고 SDK 승인 통지로 혜택을 적용한다', () async {
    final gateway = BillingGateway();
    final plus = PlusStore(gateway);
    await plus.refresh();
    gateway.failure = PlatformException(
      code: '${PurchasesErrorCode.paymentPendingError.index}',
    );
    await plus.purchase();
    expect(plus.paymentPending, isTrue);
    expect(plus.canBuy, isFalse);
    expect(plus.isPlus, isFalse);
    await plus.purchase();
    expect(gateway.purchases, 1);
    gateway.failure = null;
    await plus.refresh();
    expect(plus.canBuy, isFalse); // 구매 조회 false는 대기 결제 취소를 뜻하지 않습니다.
    gateway.listener!(true);
    expect(plus.paymentPending, isFalse);
    expect(plus.isPlus, isTrue);
    expect(plus.showAds, isFalse);
    expect(plus.message, contains('승인'));
    plus.dispose();
  });

  test('상품 조회 실패 후 오래된 가격으로 구매하지 않고 복원은 허용한다', () async {
    final gateway = BillingGateway();
    final plus = PlusStore(gateway);
    await plus.refresh();
    expect(plus.canBuy, isTrue);
    gateway.offerFails = true;
    await plus.refresh();
    expect(plus.offer, isNull);
    expect(plus.canBuy, isFalse);
    expect(plus.canRestore, isTrue);
    gateway.owned = true;
    await plus.restore();
    expect(plus.isPlus, isTrue);
    plus.dispose();
  });

  test('복원 시간 초과 후 다시 조회하며 늦은 결과로 새 권한을 덮지 않는다', () async {
    final old = Completer<bool>();
    final gateway = BillingGateway()..restoring = () => old.future;
    final plus = PlusStore(
      gateway,
      requestTimeout: const Duration(milliseconds: 5),
    );
    await plus.refresh();
    await plus.restore();
    expect(plus.busy, isFalse);
    expect(plus.message, contains('늦어지고'));
    gateway.listener!(true);
    old.complete(false);
    await Future<void>.delayed(Duration.zero);
    expect(plus.isPlus, isTrue);
    plus.dispose();
  });

  test('구매창은 조회 제한 시간 후에도 유지하고 뒤늦은 결과보다 최신 통지가 우선한다', () async {
    final pending = Completer<bool>();
    final gateway = BillingGateway()..buying = () => pending.future;
    final plus = PlusStore(
      gateway,
      requestTimeout: const Duration(milliseconds: 5),
    );
    await plus.refresh();
    final purchase = plus.purchase();
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(plus.busy, isTrue);
    gateway.listener!(true);
    pending.complete(false);
    await purchase;
    expect(plus.isPlus, isTrue);
    expect(plus.message, contains('취향대로'));
    plus.dispose();
  });

  test('로컬 출시 설정은 데모 광고·다른 스토어 키·오타를 거부하고 bootstrap을 구분한다', () {
    final values = <String, Object?>{
      'APPLICATION_ID': 'io.github.example.chaengim',
      'REVENUECAT_ANDROID_KEY': 'goog_testPublicKey',
      'ADMOB_LIVE_ENABLED': false,
    };
    expect(PlayBuildConfig(values).errors, isEmpty);
    expect(
      PlayBuildConfig({...values, 'APPLICATION_ID': 'com.example.app'}).errors,
      isNotEmpty,
    );
    expect(
      PlayBuildConfig({...values, 'REVENUECAT_ANDROID_KEY': 'test_key'}).errors,
      isNotEmpty,
    );
    expect(
      PlayBuildConfig({...values, 'REVENUECAT_ANDROID_KEY': ''}).errors,
      isNotEmpty,
    );
    expect(
      PlayBuildConfig({
        ...values,
        'REVENUECAT_ANDROID_KEY': '',
      }, bootstrap: true).errors,
      isEmpty,
    );
    expect(PlayBuildConfig(values, bootstrap: true).errors, isNotEmpty);
    expect(
      PlayBuildConfig({
        ...values,
        'ADMOB_LIVE_ENABLED': true,
        'ADMOB_ANDROID_APP_ID': 'ca-app-pub-3940256099942544~3347511713',
        'ADMOB_ANDROID_BANNER_ID': 'ca-app-pub-3940256099942544/6300978111',
      }).errors,
      isNotEmpty,
    );
    expect(
      PlayBuildConfig({...values, 'PRIVATE_KEY': 'never allowed'}).errors,
      isNotEmpty,
    );
    expect(
      PlayBuildConfig(values).flutterArguments,
      contains('--android-project-arg=chaengimRequirePayments=true'),
    );
  });
}
