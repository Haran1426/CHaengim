// Flutter를 실행하기 전에도 검사할 수 있도록 Dart 표준 라이브러리만 사용합니다.
class PlayBuildConfig {
  PlayBuildConfig(this.values, {this.bootstrap = false});
  final Map<String, Object?> values;
  final bool bootstrap;
  String value(String key) =>
      values[key] is String ? (values[key] as String).trim() : '';
  String get applicationId => value('APPLICATION_ID');
  String get revenueCatKey => value('REVENUECAT_ANDROID_KEY');
  bool get adsEnabled => values['ADMOB_LIVE_ENABLED'] == true;
  static final _package = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  List<String> get errors {
    final errors = <String>[];
    const allowed = {
      'APPLICATION_ID',
      'REVENUECAT_ANDROID_KEY',
      'ADMOB_LIVE_ENABLED',
      'ADMOB_ANDROID_APP_ID',
      'ADMOB_ANDROID_BANNER_ID',
    };
    if (values.keys.any((key) => !allowed.contains(key)))
      errors.add('설정 파일에 알 수 없는 항목이 있어요. example 파일의 항목만 사용하세요.');
    if (!_package.hasMatch(applicationId) ||
        applicationId.startsWith('com.example.') ||
        applicationId.endsWith('.preview')) {
      errors.add('Play Console에 등록할 정식 APPLICATION_ID가 필요해요.');
    }
    if (values['ADMOB_LIVE_ENABLED'] is! bool)
      errors.add('ADMOB_LIVE_ENABLED는 true 또는 false여야 해요.');
    if (bootstrap) {
      if (revenueCatKey.isNotEmpty || adsEnabled)
        errors.add('최초 등록용 빌드는 구매 키를 비우고 실광고를 꺼 주세요.');
    } else if (!RegExp(r'^goog_[A-Za-z0-9]+$').hasMatch(revenueCatKey) ||
        revenueCatKey.contains('REPLACE')) {
      errors.add('RevenueCat의 Android 공개 SDK 키(goog_…)가 필요해요.');
    }
    if (adsEnabled) {
      final appId = value('ADMOB_ANDROID_APP_ID'),
          bannerId = value('ADMOB_ANDROID_BANNER_ID');
      if (!RegExp(r'^ca-app-pub-\d{16}~\d{10}$').hasMatch(appId) ||
          appId.startsWith('ca-app-pub-3940256099942544')) {
        errors.add('자체 AdMob 앱 ID가 필요해요. Google 데모 ID는 사용할 수 없어요.');
      }
      if (!RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(bannerId) ||
          bannerId.startsWith('ca-app-pub-3940256099942544')) {
        errors.add('자체 AdMob 배너 ID가 필요해요. Google 데모 ID는 사용할 수 없어요.');
      }
      if (appId.split('~').first != bannerId.split('/').first)
        errors.add('AdMob 앱과 배너의 게시자 ID가 서로 달라요.');
    }
    return errors;
  }

  List<String> get flutterArguments => [
    'build',
    'appbundle',
    '--release',
    '--android-project-arg=chaengimStoreRelease=true',
    '--android-project-arg=chaengimApplicationId=$applicationId',
    '--android-project-arg=chaengimRequirePayments=${!bootstrap}',
    if (!bootstrap) '--dart-define=REVENUECAT_ANDROID_KEY=$revenueCatKey',
    '--dart-define=ADMOB_LIVE_ENABLED=$adsEnabled',
    if (adsEnabled) ...[
      '--dart-define=ADMOB_ANDROID_BANNER_ID=${value('ADMOB_ANDROID_BANNER_ID')}',
      '--android-project-arg=admobAppId=${value('ADMOB_ANDROID_APP_ID')}',
    ],
  ];
}
