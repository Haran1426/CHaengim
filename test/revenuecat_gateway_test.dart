import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/plus_store.dart';

Map<String, Object?> customer({
  bool owned = false,
  String verification = 'VERIFIED',
}) {
  final entitlement = <String, Object?>{
    'identifier': 'chaengim_plus',
    'isActive': true,
    'willRenew': false,
    'latestPurchaseDate': '2026-11-18T00:00:00Z',
    'originalPurchaseDate': '2026-11-18T00:00:00Z',
    'productIdentifier': 'chaengim_plus_lifetime',
    'isSandbox': true,
    'verification': verification,
  };
  return {
    'entitlements': {
      'all': {if (owned) 'chaengim_plus': entitlement},
      'active': {if (owned) 'chaengim_plus': entitlement},
      'verification': verification,
    },
    'allPurchaseDates': <String, Object?>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': [if (owned) 'chaengim_plus_lifetime'],
    'nonSubscriptionTransactions': <Object>[],
    'firstSeen': '2026-11-18T00:00:00Z',
    'originalAppUserId': 'test-anonymous',
    'allExpirationDates': <String, Object?>{},
    'requestDate': '2026-11-18T00:00:00Z',
  };
}

Map<String, Object?> offerings({
  String productId = 'chaengim_plus_lifetime',
  String category = 'NON_SUBSCRIPTION',
}) {
  final package = {
    'identifier': r'$rc_lifetime',
    'packageType': 'LIFETIME',
    'presentedOfferingContext': {'offeringIdentifier': 'default'},
    'product': {
      'identifier': productId,
      'description': '광고 제거와 테마',
      'title': '챙김 플러스',
      'price': 7900,
      'priceString': '₩7,900',
      'currencyCode': 'KRW',
      'productCategory': category,
    },
  };
  final offering = {
    'identifier': 'default',
    'serverDescription': 'default',
    'metadata': <String, Object?>{},
    'availablePackages': [package],
    'lifetime': package,
  };
  return {
    'current': offering,
    'all': {'default': offering},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var owned = false,
      verification = 'VERIFIED',
      productId = 'chaengim_plus_lifetime',
      category = 'NON_SUBSCRIPTION';
  setUp(() {
    calls.clear();
    owned = false;
    verification = 'VERIFIED';
    productId = 'chaengim_plus_lifetime';
    category = 'NON_SUBSCRIPTION';
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getCustomerInfo' || 'restorePurchases' => customer(
          owned: owned,
          verification: verification,
        ),
        'getOfferings' => offerings(productId: productId, category: category),
        'purchasePackage' => {
          'customerInfo': customer(owned: true),
          'transaction': {
            'transactionIdentifier': 'test-order',
            'productIdentifier': productId,
            'purchaseDate': '2026-11-18T00:00:00Z',
          },
        },
        _ => null,
      };
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('실제 SDK 채널로 일회성 상품과 가격을 읽고 lifetime 구매를 보낸다', () async {
    final gateway = RevenueCatGateway(androidKey: 'goog_testPublicKey');
    await gateway.initialize((_) {});
    expect(calls.first.method, 'setupPurchases');
    expect((await gateway.offer())!.price, '₩7,900');
    expect(await gateway.buy(), isTrue);
    final request = calls.singleWhere(
      (call) => call.method == 'purchasePackage',
    );
    expect(request.arguments['packageIdentifier'], r'$rc_lifetime');
    gateway.dispose();
  });

  test('이미 소유한 구매는 결제창을 다시 열지 않으며 복원은 권한을 확인한다', () async {
    final gateway = RevenueCatGateway(androidKey: 'goog_testPublicKey');
    await gateway.initialize((_) {});
    owned = true;
    expect(await gateway.buy(), isTrue);
    expect(calls.any((call) => call.method == 'purchasePackage'), isFalse);
    expect(await gateway.restore(), isTrue);
    gateway.dispose();
  });

  test('다른 상품·구독을 lifetime으로 잘못 설정해도 판매하지 않는다', () async {
    final gateway = RevenueCatGateway(androidKey: 'goog_testPublicKey');
    await gateway.initialize((_) {});
    expect(await gateway.offer(), isNotNull);
    category = 'SUBSCRIPTION';
    expect(await gateway.offer(), isNull);
    expect(gateway.buy(), throwsStateError);
    category = 'NON_SUBSCRIPTION';
    productId = 'other_product';
    expect(await gateway.offer(), isNull);
    gateway.dispose();
  });

  test('검증 실패 구매 응답은 복원으로 권한을 열지 않는다', () async {
    final gateway = RevenueCatGateway(androidKey: 'goog_testPublicKey');
    await gateway.initialize((_) {});
    owned = true;
    verification = 'FAILED';
    await expectLater(gateway.restore(), throwsStateError);
    gateway.dispose();
  });
}
