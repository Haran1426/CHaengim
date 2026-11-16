import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsController extends ChangeNotifier {
  AdsController({this.enabled = true});
  final bool enabled;
  static const _liveBanner = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const _liveEnabled = bool.fromEnvironment('ADMOB_LIVE_ENABLED');
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  bool ready = false, privacyRequired = false, _disposed = false;
  int revision = 0;
  Future<void>? _initializing;
  bool get testMode => !kReleaseMode;
  bool get configured =>
      enabled &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (testMode ||
          (_liveEnabled &&
              _liveBanner.startsWith('ca-app-pub-') &&
              _liveBanner != _testBanner));
  String get bannerId => testMode ? _testBanner : _liveBanner;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!configured) return;
    try {
      if (!testMode) {
        final completed = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!completed.isCompleted) completed.complete();
          }),
          (_) {
            if (!completed.isCompleted) completed.complete();
          },
        );
        await completed.future;
        privacyRequired =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
        if (!await ConsentInformation.instance.canRequestAds()) {
          _notify();
          return;
        }
      }
      await MobileAds.instance.initialize();
      ready = true;
      _notify();
    } catch (_) {
      ready = false;
      _notify();
    }
  }

  Future<bool> privacyOptions() async {
    try {
      final completed = Completer<bool>();
      ConsentForm.showPrivacyOptionsForm((error) {
        if (!completed.isCompleted) completed.complete(error == null);
      });
      final success = await completed.future;
      ready = await ConsentInformation.instance.canRequestAds();
      if (ready) await MobileAds.instance.initialize();
      revision++;
      _notify();
      return success;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
