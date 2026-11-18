# 개발 환경 설정

## SDK와 Android 빌드 도구

- Flutter 3.47.0 이상 / Dart 3.13.0 이상
- 개발 기준: Flutter 3.47.9 / Dart 3.13.7. CI에서는 Flutter 3.50.0도 함께 검사합니다.
- Gradle 9.5.0 (프로젝트의 Gradle Wrapper로 사용)
- Android Gradle Plugin 9.3.1 / Kotlin Gradle Plugin 2.4.20
- Android SDK와 JDK는 Android Studio에서 설치한 것을 사용할 수 있습니다.

Gradle·Android·Kotlin 버전은 Flutter 3.50 템플릿에 맞췄습니다. Flutter 버전을 올릴 때는 세 도구의 호환성도 함께 확인하세요.

## Android Studio에서 열기

`pubspec.yaml`이 있는 프로젝트 최상위 폴더를 엽니다. Flutter 플러그인을 설치하고 Flutter SDK 경로를 지정합니다. `android` 폴더만 열면 Flutter 화면과 실행 설정을 함께 다루기 어렵습니다.

`Settings → Languages & Frameworks → Flutter → Flutter SDK path`에서 실제 SDK 폴더를 선택합니다. 예를 들어 SDK를 `D:\Development\flutter`에 풀었다면 `bin`을 제외한 이 폴더를 지정합니다. Dart SDK는 같은 Flutter의 `bin/cache/dart-sdk`를 사용합니다. 터미널에서 새 Flutter를 실행해도 Android Studio가 예전 SDK 경로를 유지할 수 있으니 IDE 설정도 함께 확인하세요.

`The current Dart SDK version is 3.12.2`와 `version solving failed`가 나오면 Flutter 3.44 계열이 선택된 상태입니다. 프로젝트에서 사용하는 `material_ui`는 Dart 3.13 / Flutter 3.47 이상이 필요하므로 위의 지원 버전으로 연결한 뒤 `flutter pub get`을 실행합니다. Windows가 특정 SDK 실행을 차단하면 보안 설정을 끄지 말고 실행 가능한 공식 지원 버전을 사용하세요.

Flutter 버전을 바꾸면 SDK가 고정하는 테스트 의존성도 달라질 수 있습니다. `flutter pub get`으로 현재 SDK에 맞게 해석한 뒤 분석과 테스트를 실행합니다. CI 통과와 로컬 Android Studio의 실제 실행 성공은 별도로 확인합니다.

SDK를 바꾼 뒤에도 장치 연결이 끊기거나 예전 Flutter daemon이 남으면 프로젝트를 닫았다 다시 엽니다. 실행 장치를 `Medium Phone (mobile)` 같은 Android 기기로 다시 선택하세요. 실행 화면이 보이고 핫 리로드까지 성공하는지 확인합니다.

`android/local.properties`는 이 PC의 SDK 경로를 담는 로컬 파일입니다. Git에는 올리지 않습니다. Android Studio와 Flutter가 생성한 경로를 사용하세요.

```properties
flutter.sdk=C:\\develop\\flutter
sdk.dir=C:\\Users\\사용자이름\\AppData\\Local\\Android\\Sdk
```

## 검증과 APK 생성

```sh
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

디버그 APK는 `build/app/outputs/flutter-apk/app-debug.apk`에 생성됩니다. 배포용 서명과 실제 광고·구매 설정은 별도 작업입니다.

휴대폰에 파일을 옮겨 설치할 때는 릴리스 APK로 확인합니다.

```sh
flutter build apk --release --no-pub
```

파일은 `build/app/outputs/flutter-apk/app-release.apk`에 생성됩니다. 현재 프로젝트는 로컬 설치 테스트를 위해 릴리스에도 개발용 서명 키를 사용합니다. Play 스토어 출시에 필요한 정식 서명 설정은 별도로 해야 합니다. 같은 키로 서명한 새 APK는 기존 앱 위에 업데이트로 설치합니다.

## Windows의 심볼릭 링크 안내

Windows 데스크톱 플러그인 설정 중 `Building with plugins requires symlink support`가 나오면 Windows의 개발자 모드 설정을 확인하세요. 이 설정은 자동으로 변경하지 않습니다.

Android 작업만 진행하면서 Windows 플러그인 준비 단계에 막힌 경우에는 `dart pub get`으로 의존성을 받은 뒤 위의 `--no-pub` 검증·Android 빌드 명령을 사용할 수 있습니다. 이 방법이 Windows 데스크톱 실행까지 준비해 주지는 않습니다.

## Material UI 이전

앱·테스트·미리보기에서 `package:material_ui/material_ui.dart`를 함께 사용합니다. 한국어 선택창의 delegate도 이 패키지의 `GlobalMaterialLocalizations.delegates`를 사용합니다. 예전 `flutter/material.dart`와 섞으면 서로 다른 Material 타입이 충돌할 수 있습니다.

참고: [Flutter 공식 이전 가이드](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

## 에뮬레이터를 실행할 수 없는 경우

Windows에서 `x86_64 emulation currently requires hardware acceleration`이 나오면 Android Emulator의 가속 환경을 확인해야 합니다. 2026-11-17 이 PC에서는 가속 드라이버 부재로 에뮬레이터 시작이 중단됐습니다. 이 상태에서 APK 생성 성공과 기기 실행 검증은 구분합니다.

설정 방법은 [Android 공식 가속 환경 안내](https://developer.android.com/studio/run/emulator-acceleration#vm-windows)를 참고하세요. 연결한 실제 Android 기기로도 실행을 확인할 수 있습니다.

## 2026-11-19 Windows 실행 복구

- Android Studio가 Flutter 3.44.6 / Dart 3.12.2를 계속 사용해 패키지 해석 단계에서 중단되는 것을 재현했습니다.
- `material_ui`가 지원하는 Flutter 3.47 / Dart 3.13부터 프로젝트를 사용할 수 있게 최소 SDK 조건을 맞추고, 개발 기준 버전 3.47.9로 의존성을 다시 해석했습니다.
- Flutter 3.47.9 / Dart 3.13.7에서 코드 검사 지적 사항 0건, Flutter 테스트 56개, Android 단위 테스트 8개를 통과했습니다. 테스트의 플랫폼 override는 Flutter 3.47의 종료 시점 검사 전에 복구하도록 수정했습니다.
- Android Studio의 SDK 경로를 변경하고 프로젝트를 다시 연 뒤 Android 16 / API 36 에뮬레이터에서 1.0.7+8 앱을 실행했습니다. 최신 홈·하단 위젯 카드 표시와 IDE 핫 리로드 성공을 확인했습니다.
- 일부 플러그인의 Java·Gradle 사용 중단 경고는 남아 있지만 디버그 APK 생성과 실행은 성공했습니다. 일반적인 커밋·푸시로 반영하며 별도 배포 릴리스는 만들지 않습니다.

## 2026-11-17 검증

- Windows / Flutter 3.50.0 / Dart 3.14.0에서 코드 검사 지적 사항 0건.
- Flutter 테스트 25개 통과. 한국어 날짜·시간 선택창 표시와 마감 시간 저장 검증 포함.
- Android 알림 계산 단위 테스트 8개 통과.
- 일반 앱 디버그 APK 생성 성공. 이번 작업에서는 기기에 설치해 실행하지 않았습니다.
- Android 빌드에는 일부 플러그인의 Java 및 Gradle 사용 중단 안내가 남아 있습니다. 현재 빌드를 막지는 않지만 Gradle 10으로 올리기 전 플러그인 호환성을 확인해야 합니다.

같은 날 일정 저장소의 종료 시점 오류를 수정한 뒤 Flutter 테스트 28개와 코드 검사를 통과했고 일반 앱 APK를 다시 생성했습니다. 로딩·저장 중 종료를 재현하는 테스트를 포함하며, 에뮬레이터 실행은 위의 가속 환경 문제로 확인하지 못했습니다.

## 1.0.1 시작 문제 점검

- 이후 실행 가능한 Android 17 에뮬레이터에서 기존 APK의 x86_64 홈 화면 표시를 확인했습니다.
- ARM64 변환 실행에서는 시작 중 광고 SDK가 불러오는 WebView의 `Chrome_InProcGp` 네이티브 SIGSEGV가 관찰됐습니다. 변환 환경의 결과이므로 갤럭시 와이드7의 종료 원인과 같다고 확정할 수 없습니다.
- 홈에서는 광고 SDK를 초기화하지 않고 실제 광고 영역이 만들어질 때 초기화하도록 바꿨습니다. 수정 후 ARM64 변환 실행에서도 홈 화면 표시와 프로세스 유지를 확인했습니다.
- 홈·일정 화면에서 광고 SDK를 시작하지 않는 검사와 광고 영역에서 초기화를 시도하는 검사를 추가했습니다. Flutter 테스트 30개와 코드 검사를 통과했습니다.
- 릴리스 APK 설치 테스트에서는 별도로 `InitializationProvider`가 `WorkDatabase`를 만들지 못해 시작 전에 종료되는 오류를 재현했습니다. 광고 SDK의 전이 의존성인 WorkManager 2.7.0을 2.11.2로 올렸습니다. [광고 SDK 공식 저장소의 같은 오류 보고](https://github.com/googleads/googleads-mobile-flutter/issues/1444)를 참고했습니다.
- 변경 후 릴리스 APK를 기존 앱 위에 업데이트 설치하고 Android 17 에뮬레이터의 ARM64 변환 실행에서 홈 표시와 프로세스 유지를 확인했습니다. [릴리스 실행 화면](screenshots/startup-1.0.1.png). 설치 파일은 `build/app/outputs/flutter-apk/chaengim-1.0.1.apk`로 복사했습니다.
- 갤럭시 와이드7 실기기의 오류 로그는 아직 확보하지 못했습니다. 새 APK로도 종료되면 USB 디버깅 연결 후 실제 기기의 로그를 확인해야 합니다.
