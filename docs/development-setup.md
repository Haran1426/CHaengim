# 개발 환경 설정

## SDK와 Android 빌드 도구

- Flutter 3.50.0 이상 / Dart 3.14.0 이상
- Gradle 9.5.0 (프로젝트의 Gradle Wrapper로 사용)
- Android Gradle Plugin 9.3.1 / Kotlin Gradle Plugin 2.4.20
- Android SDK와 JDK는 Android Studio에서 설치한 것을 사용할 수 있습니다.

Gradle·Android·Kotlin 버전은 Flutter 3.50 템플릿에 맞췄습니다. Flutter 버전을 올릴 때는 세 도구의 호환성도 함께 확인하세요.

## Android Studio에서 열기

`pubspec.yaml`이 있는 프로젝트 최상위 폴더를 엽니다. Flutter 플러그인을 설치하고 Flutter SDK 경로를 지정합니다. `android` 폴더만 열면 Flutter 화면과 실행 설정을 함께 다루기 어렵습니다.

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

## Windows의 심볼릭 링크 안내

Windows 데스크톱 플러그인 설정 중 `Building with plugins requires symlink support`가 나오면 Windows의 개발자 모드 설정을 확인하세요. 이 설정은 자동으로 변경하지 않습니다.

Android 작업만 진행하면서 Windows 플러그인 준비 단계에 막힌 경우에는 `dart pub get`으로 의존성을 받은 뒤 위의 `--no-pub` 검증·Android 빌드 명령을 사용할 수 있습니다. 이 방법이 Windows 데스크톱 실행까지 준비해 주지는 않습니다.

## Material UI 이전

앱·테스트·미리보기에서 `package:material_ui/material_ui.dart`를 함께 사용합니다. 한국어 선택창의 delegate도 이 패키지의 `GlobalMaterialLocalizations.delegates`를 사용합니다. 예전 `flutter/material.dart`와 섞으면 서로 다른 Material 타입이 충돌할 수 있습니다.

참고: [Flutter 공식 이전 가이드](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

## 에뮬레이터를 실행할 수 없는 경우

Windows에서 `x86_64 emulation currently requires hardware acceleration`이 나오면 Android Emulator의 가속 환경을 확인해야 합니다. 2026-11-17 이 PC에서는 가속 드라이버 부재로 에뮬레이터 시작이 중단됐습니다. 이 상태에서 APK 생성 성공과 기기 실행 검증은 구분합니다.

설정 방법은 [Android 공식 가속 환경 안내](https://developer.android.com/studio/run/emulator-acceleration#vm-windows)를 참고하세요. 연결한 실제 Android 기기로도 실행을 확인할 수 있습니다.

## 2026-11-17 검증

- Windows / Flutter 3.50.0 / Dart 3.14.0에서 코드 검사 지적 사항 0건.
- Flutter 테스트 25개 통과. 한국어 날짜·시간 선택창 표시와 마감 시간 저장 검증 포함.
- Android 알림 계산 단위 테스트 8개 통과.
- 일반 앱 디버그 APK 생성 성공. 이번 작업에서는 기기에 설치해 실행하지 않았습니다.
- Android 빌드에는 일부 플러그인의 Java 및 Gradle 사용 중단 안내가 남아 있습니다. 현재 빌드를 막지는 않지만 Gradle 10으로 올리기 전 플러그인 호환성을 확인해야 합니다.

같은 날 일정 저장소의 종료 시점 오류를 수정한 뒤 Flutter 테스트 28개와 코드 검사를 통과했고 일반 앱 APK를 다시 생성했습니다. 로딩·저장 중 종료를 재현하는 테스트를 포함하며, 에뮬레이터 실행은 위의 가속 환경 문제로 확인하지 못했습니다.
