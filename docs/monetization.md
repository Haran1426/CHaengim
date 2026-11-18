# 챙김 플러스: 꾸미기와 광고 제거

## 상품 범위

일정 수, 준비물 체크, 진행 단계, 마감 알림, 소형·중형 기본 위젯, 후속 일정과 검색은 무료입니다. 기능 제한이나 광고 시청을 조건으로 한 잠금은 없습니다.

| 구분 | 구성 |
| --- | --- |
| 무료 | 모든 일정 관리 기능, 숲·모래 테마 |
| 플러스 | 광고 제거, 바다·라일락·살구 테마, 해당 색상의 Android 위젯 |

플러스는 **비소모성 일회성 상품**입니다. 가격은 아직 확정하지 않았으며 화면은 스토어의 현지화된 가격만 표시합니다. 테스트 코드의 7,900원은 가짜 스토어 응답 예시입니다. 구독과 자동 갱신은 구현하지 않았습니다.

마이 → 테마 꾸미기에서 5개 색상을 미리 보고 무료 테마를 적용할 수 있습니다. 유료 테마 미리보기는 실제 선택이나 위젯을 변경하지 않습니다. 플러스 구매 후 같은 화면에서 적용합니다. 앱과 위젯의 테마는 함께 바뀝니다.

## 현재 작동 범위

- 테마 저장·복원, 앱 전체 팔레트, 네이티브 위젯 색상 동기화.
- 플러스 소개, 스토어 가격 표시, 구매·복원·취소·결제 대기·오류 상태 처리.
- RevenueCat SDK로 구매 검증 및 권한 갱신 연결. 직접 저장한 `isPro=true` 같은 플래그는 사용하지 않음.
- 마이 화면 끝에 AdMob 배너 한 곳. 홈·일정·등록·상세·위젯에는 광고 없음.
- 디버그/프로파일은 Google 테스트 광고 ID만 사용. 릴리스는 명시적 설정 전 광고 요청 안 함.
- 릴리스 광고 요청 전 UMP 동의 정보 갱신 및 필요한 동의 화면. 요청 가능 상태 확인, 필요한 경우 마이에 개인정보 설정 버튼 표시.
- 스토어 미설정 시 ‘출시 준비 중’, 결제·복원 버튼 비활성. 가짜 구매 성공을 보여주지 않음.

**실제 수익화 계정·상품 연결과 Google Play 테스트 구매는 아직 진행하지 않았습니다.** 지금 빌드의 광고는 테스트 광고이며 수익이 발생하지 않습니다. iOS 결제/광고 설정은 이번 범위 밖입니다.

## 스토어 연결

최신 단계별 절차와 빌드 명령은 [Google Play 결제 연결 순서](play-billing-setup.md)를 우선 확인하세요.

1. 정식 Android applicationId와 릴리스 서명을 정하고 Google Play Console에 앱을 등록합니다. 현재 `com.example.my_first_app` 및 debug 서명은 개발용입니다.
2. Play에 비소모성 상품 `chaengim_plus_lifetime`을 만들고 가격을 지정합니다.
3. RevenueCat에 Android 앱과 Google Play 서비스를 연결하고 해당 상품을 가져옵니다. entitlement `chaengim_plus`에 연결하고 현재 offering의 **lifetime** 패키지로 지정합니다. 앱은 상품 ID와 nonSubscription 유형이 일치할 때만 구매를 허용합니다.
4. Android 공개 SDK 키(`goog_…`)를 빌드의 `REVENUECAT_ANDROID_KEY`로 전달합니다. 비공개 서비스 계정 키는 앱이나 Git에 넣지 않고 RevenueCat 측에 설정합니다.
5. 동일 스토어 계정의 재설치/새 기기 복원이 동작하도록 RevenueCat의 restore/transfer 동작을 확인합니다. 자체 사용자 로그인은 아직 없습니다.
6. Play 내부 테스트에서 구매·취소·보류·복원·환불/권한 회수를 확인합니다.

플러스 권한은 SDK의 CustomerInfo에서 가져오고 서명 검증 실패 응답은 거부합니다. SDK가 캐시한 구매 정보도 사용할 수 있습니다. 앱 재진입과 SDK 변경 통지로 갱신하므로 환불이 모든 오프라인 기기에 즉시 반영되지는 않습니다. 권한 회수 확인 시 무료 기본 테마로 표시하고 이전 유료 테마 선택은 남겨 구매 복원 후 다시 사용할 수 있게 합니다. 일정 데이터에는 영향이 없습니다.

## 광고 연결

1. AdMob의 앱 ID와 Android 배너 광고 단위를 생성합니다.
2. AdMob Privacy & messaging에서 필요한 동의 메시지를 구성합니다. 실제 배포의 개인정보 안내와 Play 데이터 공개도 사용 중인 SDK 설정에 맞춥니다.
3. 릴리스 빌드에 앱 ID, 배너 ID, 활성화 플래그를 함께 전달합니다. 기본값은 판매/실광고 미연결입니다.

```sh
flutter build appbundle --release --dart-define=REVENUECAT_ANDROID_KEY=goog_REPLACE_ME --dart-define=ADMOB_LIVE_ENABLED=true --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-REPLACE_ME/BANNER --android-project-arg=admobAppId=ca-app-pub-REPLACE_ME~APP
```

실제 공개 키와 ID를 사용해야 합니다. 기본 앱 ID는 Google 데모 ID이며 자체 앱 ID로 바꾸기 전 실광고 활성화 플래그를 사용하지 않습니다. AdMob SDK는 실패한 광고를 표시하지 않고 그 자리를 접습니다. 일정 작업은 광고 통신에 의존하지 않습니다.

구매 확인 전에는 광고를 숨기며 플러스가 확인되면 배너를 화면에서 제거하고 해제합니다.

## 코드와 확인

- `lib/design/app_skin.dart`: 팔레트와 무료/유료 테마 카탈로그.
- `lib/data/appearance_store.dart`: 선택 저장, 권한에 따른 적용, 위젯 동기화.
- `lib/data/plus_store.dart`: 스토어 연결, 구매/복원 상태. 테스트에서는 가짜 gateway 주입.
- `lib/platform/ads_controller.dart`, `lib/widgets/sponsor_banner.dart`: 동의와 배너 수명 관리.
- `test/commerce_test.dart`: 잠금·구매 상태·복원·테마 저장·작은 화면·위젯 전달 검증.
- `test/play_billing_test.dart`, `test/revenuecat_gateway_test.dart`: 대기 중 중복 구매 차단·복원 시간 초과·오래된 가격 차단·SDK 채널의 lifetime 상품/검증 응답.
- `tool/build_play_store.dart`, `config/play-store.example.json`: 로컬 설정 한 곳에서 최초 등록/결제 연동 AAB 생성. `*.local.json`은 Git에서 제외.

공식 참고: [RevenueCat Flutter](https://www.revenuecat.com/docs/getting-started/installation/flutter), [구매 권한](https://www.revenuecat.com/docs/getting-started/entitlements), [구매 복원](https://www.revenuecat.com/docs/getting-started/restoring-purchases), [AdMob 테스트 광고](https://developers.google.com/admob/flutter/test-ads), [배너](https://developers.google.com/admob/flutter/banner), [UMP](https://developers.google.com/admob/flutter/privacy).

## 검수 기록

- Flutter 분석 지적 없음, Flutter 테스트 24개와 Android JVM 테스트 8개 통과.
- 별도 preview 앱에서 무료 테마 적용, 강제 종료 후 복원, Android 런처의 모래색 소형 위젯 확인.
- 실제 Google 테스트 배너 수신과 마이 하단 표시 확인. 플러스 화면의 미설정 구매 버튼 비활성 확인.
- 320px 너비·1.6배 글자 크기에서 5개 테마 미리보기와 결제 안내에 오버플로 없음.
- 실스토어의 결제·복원·환불, 실제 광고 계정의 UMP 흐름은 계정 연결 후 추가 검수 필요. 가짜 gateway 테스트와 실제 구매 검수는 구분합니다.

화면: [플러스](screenshots/plus.png), [테마 적용](screenshots/theme-sand.png), [모래색 위젯](screenshots/widget-sand.png), [테스트 광고](screenshots/test-ad.png). 사용자 일정과 분리된 예시 데이터입니다.
