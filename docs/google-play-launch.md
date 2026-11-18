# Google Play 출시 준비

2026-11-17 사용자가 정한 순서: **Google Play 먼저, Galaxy Store는 이후**.

현재 GitHub APK는 설치 테스트용입니다. 스토어에 제출한 상태가 아닙니다.

계정 심사 후 진행할 앱 등록·일회성 상품·RevenueCat·테스트 결제 순서는 [Google Play 결제 연결](play-billing-setup.md)에 정리했습니다. `tool/build_play_store.dart`로 로컬 설정 검사와 서명된 AAB 생성을 진행합니다. 최초 등록용 구매 비활성 빌드와 결제 연동 빌드를 구분합니다.

## 코드에 반영한 준비

- 스토어 빌드는 확정한 패키지 ID와 업로드 키를 요구합니다.
- `com.example.*`, 검수용 예시 데이터, 업로드 키 누락은 스토어 빌드에서 차단합니다.
- 로컬 테스트 APK는 기존 개발용 서명을 유지하므로 같은 테스트 앱에 업데이트할 수 있습니다.
- Google Play AAB를 만드는 `bundleRelease` 작업에는 스토어 검증을 자동 적용합니다.
- 일정은 로컬 저장하고, 위젯·알림 동기화 실패를 일정 저장 실패와 구분합니다.
- 결제 요청을 네트워크 오류 때문에 자동 반복하지 않습니다.

## 제출 전에 확정할 항목

1. **정식 패키지 ID**: 현재 테스트 앱은 `com.example.my_first_app`입니다. 다른 ID로 출시하면 별도 앱이므로 테스트 앱의 일정이 자동 이관되지는 않습니다. 정식 출시 전 확정하고, 필요한 일정의 이관 방법도 준비해야 합니다.
2. **업로드 키와 Play App Signing**: 비밀 키·비밀번호는 Git에 넣지 않습니다. 복구 가능한 별도 보관 방법이 필요합니다. [공식 앱 서명 안내](https://developer.android.com/studio/publish/app-signing).
3. **공개 개인정보처리방침 URL과 문의처**: 비공개 GitHub 문서는 일반 사용자가 읽을 수 있는 정책 URL이 아닙니다. 앱 내 안내도 연결해야 합니다.
4. **데이터 보안 및 광고 신고**: 일정이 로컬에 저장된다고 해서 앱 전체를 무조건 '수집 없음'으로 신고할 수는 없습니다. 포함된 SDK와 최종 활성 설정을 함께 확인합니다. [Google Play 데이터 보안 안내](https://support.google.com/googleplay/android-developer/answer/10787469).
5. **계정에 적용되는 테스트 요건**: 2023-11-13 이후 생성된 개인 개발자 계정에는 12명 이상이 연속 14일 참여하는 비공개 테스트 등의 프로덕션 접근 요건이 있습니다. 실제 계정의 Play Console에서 적용 여부와 최신 요건을 확인합니다. [공식 테스트 요건](https://support.google.com/googleplay/android-developer/answer/14151465).
6. **실기기 검수**: 갤럭시 와이드7을 포함한 기기에서 신규 설치·업데이트·오프라인 실행·알림 권한 거절·재부팅·앱 종료 후 위젯을 확인합니다. 에뮬레이터 결과와 실제 폰 결과는 구분합니다.
7. **스토어 자료**: 앱 설명, 스크린샷, 아이콘, 콘텐츠 등급, 대상 사용자와 실제 기능이 일치하는지 확인합니다. 제출 시점의 대상 API 요건은 Play Console에서 다시 확인합니다.

## 현재 데이터·SDK 현황

| 대상 | 현재 구현 | 출시 전 확인 |
| --- | --- | --- |
| 일정·메모·준비물 | `SharedPreferencesAsync`의 로컬 JSON | 삭제·백업·복원 안내, Android 시스템 백업 설정 |
| Android 위젯·알림 | 기기 내부 스냅샷과 예약 | 권한 거절·절전·재부팅·시간대 변경 |
| 광고 | Google Mobile Ads, 릴리스 실광고는 명시 설정 전 비활성 | 최종 SDK 데이터 처리·동의·광고 표시·AdMob 앱 등록 |
| 구매 | RevenueCat의 `goog_` 키로 Google Play 경로 구성 | 실제 상품·권한 검증·취소·대기·복원·스토어 테스트 계정 |
| 계정·서버 백업 | 앱 계정 및 자체 서버 백업 미구현 | 구현하지 않은 동기화·백업 기능을 스토어 설명에 약속하지 않기 |

현재 표는 코드 상태를 설명합니다. 데이터 보안 신고서를 대신 작성하거나, 아직 미연결인 광고·결제를 검증 완료한 것으로 취급하지 않습니다.

## 정식 서명 설정

Git에서 제외한 `android/key.properties`에 다음 항목을 설정합니다. `storeFile`의 상대 경로는 `android` 폴더 기준입니다. Windows 경로는 `/` 구분자를 사용할 수 있습니다.

```properties
storeFile=C:/private-keys/chaengim-upload.jks
storePassword=SET_LOCALLY
keyAlias=upload
keyPassword=SET_LOCALLY
```

확정한 패키지 ID를 넣고 실행합니다. 아래 `YOUR_APPLICATION_ID`는 반드시 실제 값으로 교체합니다.

```sh
flutter build appbundle --release --no-pub --android-project-arg=chaengimApplicationId=YOUR_APPLICATION_ID
```

스토어용 APK를 별도로 만들 때도 같은 검증과 업로드 서명을 적용합니다.

```sh
flutter build apk --release --no-pub --android-project-arg=chaengimStoreRelease=true --android-project-arg=chaengimApplicationId=YOUR_APPLICATION_ID
```

정식 패키지 ID·키가 없을 때 실패하는 것은 의도한 동작입니다. 현재 키를 새로 만들거나 Play Console에 제출하지는 않았습니다.

## Galaxy Store 후속 작업

일정 기능은 공유하되, 현재 구매 구현은 Google Play 경로입니다. Galaxy Store 등록만으로 구매·복원이 동작한다고 가정하지 않습니다. Galaxy Store 버전의 결제 연동과 권한 복원 방식을 별도로 설계·검증합니다.

참고: [Samsung 등록 절차](https://developer.samsung.com/galaxy-store/launch.html), [Samsung SDK 및 IAP 연동 안내](https://developer.samsung.com/galaxy-store/integrate.html).
