import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PlusOffer {
  const PlusOffer(this.price);
  final String price;
}

abstract class PlusGateway {
  bool get configured;
  Future<void> initialize(ValueChanged<bool> onChanged);
  Future<bool> refresh();
  Future<PlusOffer?> offer();
  Future<bool> buy();
  Future<bool> restore();
  void dispose();
}

// 구매 권한은 검증된 스토어 응답에서만 얻습니다. 로컬 bool로 판매하지 않습니다.
class RevenueCatGateway implements PlusGateway {
  static const apiKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const entitlement = 'chaengim_plus';
  static const productId = 'chaengim_plus_lifetime';
  Package? _package;
  ValueChanged<CustomerInfo>? _listener;
  @override
  bool get configured =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      apiKey.startsWith('goog_');

  bool _isPlus(CustomerInfo info) {
    if (info.entitlements.verification == VerificationResult.failed) {
      throw StateError('구매 정보 검증에 실패했습니다.');
    }
    return info.entitlements.active[entitlement]?.isActive == true;
  }

  @override
  Future<void> initialize(ValueChanged<bool> onChanged) async {
    final config = PurchasesConfiguration(apiKey)
      ..entitlementVerificationMode = EntitlementVerificationMode.informational
      ..automaticDeviceIdentifierCollectionEnabled = false;
    await Purchases.configure(config);
    _listener = (info) {
      // 검증 실패 때 기존 권한을 덮어쓰지 않고 다음 새로고침에서 재확인합니다.
      if (info.entitlements.verification != VerificationResult.failed) {
        onChanged(_isPlus(info));
      }
    };
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  @override
  Future<bool> refresh() async => _isPlus(await Purchases.getCustomerInfo());
  @override
  Future<PlusOffer?> offer() async {
    final package = (await Purchases.getOfferings()).current?.lifetime;
    // 원하지 않는 구독/다른 상품이 대시보드에 설정되어도 판매하지 않습니다.
    if (package == null ||
        package.storeProduct.identifier != productId ||
        package.storeProduct.productCategory !=
            ProductCategory.nonSubscription) {
      _package = null;
      return null;
    }
    _package = package;
    return PlusOffer(package.storeProduct.priceString);
  }

  @override
  Future<bool> buy() async {
    if (_package == null) throw StateError('상품이 준비되지 않았습니다.');
    return _isPlus(
      (await Purchases.purchase(PurchaseParams.package(_package!)))
          .customerInfo,
    );
  }

  @override
  Future<bool> restore() async => _isPlus(await Purchases.restorePurchases());
  @override
  void dispose() {
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
    }
  }
}

class PlusStore extends ChangeNotifier {
  PlusStore(this.gateway, {this.requestTimeout = const Duration(seconds: 15)});
  final PlusGateway gateway;
  final Duration requestTimeout;
  bool isPlus = false, loading = true, busy = false, resolved = false;
  bool _initialized = false, _disposed = false;
  Future<void>? _refreshOperation, _initialization;
  int _entitlementRevision = 0;
  PlusOffer? offer;
  String? message;
  bool get configured => gateway.configured;
  bool get canBuy =>
      configured && offer != null && !loading && !busy && !isPlus;
  bool get showAds => resolved && !isPlus;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _update(bool value) {
    if (_disposed) return;
    _entitlementRevision++;
    isPlus = value;
    resolved = true;
    _notify();
  }

  Future<void> refresh() {
    if (_disposed || busy) return Future<void>.value();
    return _refreshOperation ??= _refresh().whenComplete(
      () => _refreshOperation = null,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialization ??= gateway
        .initialize(_update)
        .then((_) {
          _initialized = true;
          if (_disposed) gateway.dispose();
        })
        .whenComplete(() => _initialization = null);
    await _initialization!.timeout(requestTimeout);
  }

  Future<void> _refresh() async {
    loading = true;
    message = null;
    _notify();
    try {
      if (!configured) {
        resolved = true;
        return;
      }
      await _ensureInitialized();
      if (_disposed) return;
      final revision = _entitlementRevision;
      final active = await gateway.refresh().timeout(requestTimeout);
      if (_disposed) return;
      if (revision == _entitlementRevision) _update(active);
      final fetchedOffer = await gateway.offer().timeout(requestTimeout);
      if (!_disposed) offer = fetchedOffer;
    } on TimeoutException {
      message = '스토어 응답이 늦어지고 있어요. 연결을 확인하고 다시 시도해 주세요.';
    } catch (_) {
      message = '스토어에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> purchase() => _transact(false);
  Future<void> restore() => _transact(true);
  Future<void> _transact(bool restore) async {
    if (_disposed || busy || loading || !configured || (!restore && !canBuy)) {
      return;
    }
    busy = true;
    message = null;
    _notify();
    try {
      if (!_initialized) {
        await gateway.initialize(_update);
        _initialized = true;
      }
      final active = restore ? await gateway.restore() : await gateway.buy();
      _update(active);
      message = active
          ? (restore ? '플러스 구매를 복원했어요.' : '플러스와 함께 취향대로 챙겨요.')
          : restore
          ? '이 스토어 계정에서 플러스 구매를 찾지 못했어요.'
          : '구매 상태를 확인하고 있어요. 잠시 후 다시 확인해 주세요.';
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      message = code == PurchasesErrorCode.purchaseCancelledError
          ? '결제가 취소됐어요.'
          : code == PurchasesErrorCode.paymentPendingError
          ? '결제 승인 대기 중이에요. 승인 후 플러스가 적용돼요.'
          : '구매를 확인하지 못했어요. 다시 시도하거나 구매 복원을 눌러 주세요.';
    } catch (_) {
      message = '구매를 확인하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    gateway.dispose();
    super.dispose();
  }
}
