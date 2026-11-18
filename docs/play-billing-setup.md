# Google Play 결제 연결 순서

2026-11-18: 개발자 등록비 결제 완료, Play 개발자 계정 심사 중이라는 사용자 설명을 기준으로 작성했습니다. 앱·상품 등록과 RevenueCat 연결 완료 여부는 아직 확인하지 않았습니다.

## 판매할 상품

| 위치 | 값 |
| --- | --- |
| 앱 가격 | 무료 다운로드 |
| 인앱 상품 | 챙김 플러스 |
| 상품 ID | `chaengim_plus_lifetime` |
| 구매 형태 | 비소모성 일회성 구매, 구독 없음 |
| 혜택 | 광고 제거 + 바다·라일락·살구 앱/위젯 테마 |
| RevenueCat 권한 ID | `chaengim_plus` |
| RevenueCat offering | `default`를 현재 offering으로 지정 |
| offering의 패키지 | Lifetime (`$rc_lifetime`) |
| 가격 | 사용자가 Play Console에서 확정. 앱은 스토어의 현지화 가격 표시 |

상품 설명 예시: **배너 광고를 제거하고 바다·라일락·살구 테마로 앱과 홈 화면 위젯을 꾸며보세요. 한 번 구매로 계속 사용할 수 있습니다.**

일정·준비물·알림·기본 위젯은 무료입니다. Google Play 상품은 일회성 상품의 구매 옵션을 만들고 활성화합니다. RevenueCat에서도 해당 상품을 **non-consumable**로 구성합니다. 같은 entitlement에 별도의 소비성 상품을 연결하지 않습니다.

## 1. 계정 승인 후 앱과 패키지 확정

Play Console에서 무료 Android 앱을 생성합니다. AAB를 처음 올리기 전에 정식 패키지 ID를 확정합니다. 이후 Play 앱·RevenueCat Android 앱·빌드의 패키지 ID가 모두 같아야 합니다.

기존 `com.example.my_first_app`은 개발용입니다. 정식 ID 변경은 별도 앱 설치가 되며 테스트 앱의 개인 일정이 자동 이전되지는 않습니다. 현재 검수용 `*.preview` 앱은 결제 테스트용으로 쓰지 않습니다.

업로드 키와 `android/key.properties`는 [출시 준비 문서](google-play-launch.md#정식-서명-설정)를 따라 로컬에 준비하고 별도로 백업합니다. 비밀번호와 서비스 계정 JSON은 Git이나 채팅에 올리지 않습니다.

## 2. 첫 AAB가 필요할 때

`config/play-store.example.json`을 `config/play-store.local.json`으로 복사합니다. `APPLICATION_ID`에 확정한 ID를 넣고 구매 키는 비워 둡니다. 광고는 false로 둡니다. local 파일은 Git에서 제외됩니다.

```sh
dart tool/build_play_store.dart --check --bootstrap
dart tool/build_play_store.dart --bootstrap
```

이 빌드는 앱·패키지와 서명을 Play에 처음 등록하기 위한 **구매 비활성** 빌드입니다. 생성 파일은 `build/app/outputs/bundle/release/app-release.aab`입니다. Play Console 내부 테스트에 업로드한 뒤 상품 등록을 이어갑니다. 프로덕션 결제 완료 버전으로 취급하지 않습니다.

## 3. Play 상품과 RevenueCat 연결

1. Play Console에서 결제 프로필을 준비하고 일회성 상품 `chaengim_plus_lifetime`을 생성합니다. 구매 옵션·가격·판매 국가를 설정하고 활성화합니다.
2. RevenueCat 계정과 프로젝트를 만들고 Google Play Android 앱을 추가합니다. Play와 같은 패키지 ID를 입력합니다.
3. [공식 서비스 계정 연결 절차](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials)에 따라 RevenueCat이 Play 구매를 검증하도록 연결합니다. 서비스 계정 JSON은 RevenueCat 대시보드에 설정하고 앱 안에 포함하지 않습니다. 권한 반영에 시간이 걸릴 수 있으므로 대시보드의 자격 증명 검증 결과를 확인합니다.
4. 상품을 가져와 non-consumable로 지정하고 권한 `chaengim_plus`에 연결합니다. 현재 offering `default`의 Lifetime 패키지에 이 상품을 넣습니다.
5. RevenueCat의 Android **공개 SDK 키**(`goog_…`)를 local 설정의 `REVENUECAT_ANDROID_KEY`에 입력합니다. `test_` Test Store 키나 서버용 비밀 키는 사용하지 않습니다.
6. [Platform Server Notifications](https://www.revenuecat.com/docs/platform-resources/server-notifications/google-server-notifications)를 구성해 환불·권한 회수도 RevenueCat에 전달되도록 합니다. 앱의 권한 조회만으로 모든 오프라인 기기에 환불이 즉시 반영되는 것은 아닙니다.

앱은 lifetime 패키지의 상품 ID와 nonSubscription 유형이 모두 맞을 때만 구매 버튼을 엽니다. 다른 상품이나 구독을 연결하면 판매하지 않습니다. 권한은 로컬 플래그 대신 CustomerInfo에서 얻으며 검증 실패 응답을 거부합니다.

## 4. 결제 연동 AAB 생성

```sh
dart tool/build_play_store.dart --check
dart tool/build_play_store.dart
```

Flutter가 PATH에 없으면 `--flutter=C:/SDK/flutter/bin/flutter.bat`처럼 전체 경로를 지정합니다. Flutter 3.47 이상이 필요하며 개발 기준 버전은 3.47.9입니다.

로컬 설정 검사에서 패키지 ID·공개 키 형식·서명 파일 유무·광고 설정을 확인합니다. 실제 키 비밀번호, 스토어 연결, 상품 활성화 여부는 빌드/콘솔/실제 기기에서 별도로 확인합니다. AAB 파일명은 같으므로 새 업로드마다 pubspec의 build number를 이전 Play 업로드보다 높여야 합니다. 앱 설명·개인정보 URL 등의 제출 준비도 [출시 문서](google-play-launch.md)에 남아 있습니다.

## 5. 내부 테스트에서 실제 흐름 확인

Play 테스트 참여 계정과 **라이선스 테스트 계정**은 별개로 등록합니다. 테스트 계정으로 참여 링크를 수락하고 Play에서 설치합니다. 결제창에서 테스트 결제수단이 표시되는지 확인합니다. 라이선스 테스터가 아니면 내부 테스트 앱에서도 인앱 구매에 실제 비용이 청구될 수 있습니다.

| 상황 | 기대 결과 |
| --- | --- |
| 최초 구매 승인 | 광고 제거, 유료 테마 적용 가능, RevenueCat에 권한 표시 |
| 결제창 취소 | 권한 없음, 다시 시도 가능 |
| 느린 테스트 결제 승인 | 대기 중 추가 결제 차단, 승인 통지/다시 확인 후 권한 적용 |
| 느린 테스트 결제 거절 | 권한 없음. 대기 표시가 남으면 앱을 다시 시작해 스토어 상태 재조회 |
| 상품 조회 오류/오프라인 | 이전 가격으로 결제 시작하지 않음, 재조회·구매 복원 제공 |
| 이미 구매한 계정 | 결제창을 다시 열기 전에 권한 조회. 복원 가능 |
| 앱 재설치·새 기기 | 같은 Play 계정으로 구매 복원, 광고 제거/테마 권한 복구 |
| 환불 후 권한 회수 | 서버 알림 반영과 앱 재조회 후 무료 상태. 일정 데이터 유지 |
| 구매 도중 앱 종료 | 다시 실행해 스토어 권한 조회/복원으로 확인, 추가 결제 자동 요청 없음 |

실제 결제 성공을 확인하기 전에는 앱의 구매 연동이 검증됐다고 표시하지 않습니다. 단위 테스트와 CI의 임시 서명 AAB는 실제 Play 결제 테스트를 대체하지 않습니다.

새 개인 개발자 계정은 프로덕션 접근에 별도 비공개 테스트 요건이 적용될 수 있습니다. 내부 결제 테스트와 프로덕션 심사 요건을 구분하고 [Play Console의 현재 계정 요건](https://support.google.com/googleplay/android-developer/answer/14151465)을 확인합니다.

## 광고는 별도 활성화

결제부터 시험할 때 `ADMOB_LIVE_ENABLED`를 false로 둬도 됩니다. 실광고를 켤 때 자체 `ADMOB_ANDROID_APP_ID`와 `ADMOB_ANDROID_BANNER_ID`를 입력하고 true로 바꿉니다. Google 데모 ID나 게시자가 다른 두 ID는 사전 검사에서 차단됩니다. 동의 메시지·공개 개인정보 안내·Play 신고도 최종 SDK 설정과 맞춰야 합니다.

참고: [Play Billing 테스트](https://developer.android.com/google/play/billing/test), [RevenueCat Play 테스트](https://www.revenuecat.com/docs/test-and-launch/sandbox/google-play-store), [비소모성 상품](https://www.revenuecat.com/docs/platform-resources/non-subscriptions), [구매 검증](https://www.revenuecat.com/docs/customers/trusted-entitlements).

## 2026-11-18 검증

[GitHub Actions 검증 기록](https://github.com/Haran1426/CHaengim/actions/runs/44315503838)에서 Flutter 3.50.0 / Dart 3.14.0 분석 지적 없음, Flutter 테스트 56개 및 Android 단위 테스트 8개 통과, 임시 서명으로 최초 등록용 AAB 생성(74.9MB)을 확인했습니다. CI 전용 패키지와 폐기용 키로 확인했으며 실제 제출 파일로 배포하지 않았습니다. 실제 Play 테스트 구매·복원·환불은 계정/상품 연결 후 확인해야 합니다.
