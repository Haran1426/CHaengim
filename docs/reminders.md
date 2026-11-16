# 마감 알림

## 사용법

일정 등록·수정 화면에서 당일·1·3·7일 전을 여러 개 선택하고 알림 시각을 정합니다. 모두 선택 해제하면 해당 일정의 알림이 꺼집니다.

새 일정은 1일 전 오전 9시를 기본으로 제안합니다. 기존 데이터에 알림 필드가 없으면 선택하지 않은 상태로 복원합니다. 기존 일정에 임의로 알림을 추가하지 않습니다.

첫 유효한 알림을 저장할 때 Android 알림 권한을 요청합니다. 거절해도 일정 저장과 위젯은 정상 동작합니다. 다시 허용하거나 앱 전체 알림을 끄려면 **마이 → 마감 알림**을 사용합니다. Android 시스템이나 알림 채널에서 차단한 경우에도 상태를 표시합니다.

당일 알림 시각은 지정한 마감 시각보다 빨라야 합니다. 시간이 없는 일정은 선택한 날짜 전체를 마감일로 봅니다. 앱과 위젯에서 시간이 있는 일정은 마감 시각부터 '기한 지남'으로 표시합니다.

## 예약 규칙

- 제목·기한·준비물·알림 설정을 저장할 때 위젯과 독립적으로 알림 스냅샷을 동기화합니다.
- 선택한 날짜의 기기 현지 시각으로 계산합니다. 일 수를 24시간 밀리초로 빼지 않으므로 일광 절약 시간 전환도 처리합니다.
- 이미 지난 알림, 마감 이후 알림, 최종 완료 일정은 예약하지 않습니다.
- 앱 재진입 때는 Android가 아직 전달하지 않은 기존 예약을 보존합니다. 새로 선택한 과거 시각이나 전체 알림을 다시 켤 때의 지난 시각은 추가하지 않습니다.
- 수정·삭제·알림 해제·최종 완료 시 기존 PendingIntent를 취소하고 현재 유효한 알림만 다시 예약합니다.
- 알림은 일정 ID와 사전 일 수로 구분합니다. 오래된 예약의 수신 시각과 현재 예약이 일치하지 않으면 무시합니다.
- 발송 이력으로 중복 수신을 방지하고, Android 알림 카드도 동일한 ID·태그를 사용합니다.
- 지연 알림은 해당 알림 날짜가 끝나거나 일정 마감이 지나면 폐기하여 여러 날의 사전 알림이 한꺼번에 쌓이지 않게 합니다.
- 체크리스트 완료는 실제 제출 완료로 취급하지 않습니다. 준비 중·제출 처리 완료·결과 대기 상태는 선택한 알림을 유지하며, 최종 완료에서 해제합니다.
- 전체 알림을 끄면 예약과 표시된 알림을 제거합니다. 다시 켜면 아직 지나지 않은 알림만 복원합니다.
- 기기 재부팅·시각/시간대 변경·앱 업데이트 시 저장한 원본 설정으로 다시 계산합니다. 시간대가 바뀌어도 현지 시각을 유지하고 이미 발송한 같은 설정은 반복 발송하지 않습니다.
- 알림 예약 실패는 일정 저장 성공을 취소하지 않습니다. 홈에 재시도 안내를 표시합니다.

## Android 동작과 제한

추가 패키지 없이 `AlarmManager.setAndAllowWhileIdle`과 `NotificationChannel`을 사용합니다. 앱 프로세스가 없어도 Android가 Receiver를 실행합니다. 네트워크나 계속 실행되는 서비스는 필요하지 않습니다.

일반 예약 방식이므로 선택한 시각 이후에 전달되며 분 단위 정시 도착을 보장하지 않습니다. Android 12 이상에서는 절전 제한이 없을 때도 최대 약 1시간 범위로 전달될 수 있고, 절전·강제 종료·제조사 정책에 따라 더 늦거나 제한될 수 있습니다. 마감 시각 이후로 늦어진 사전 알림은 보내지 않습니다. 정확한 알람 권한과 별도 배터리 예외 권한은 요청하지 않습니다.

알림을 누르면 일정 상세로 연결됩니다. 여러 알림을 Android가 묶어 표시한 경우 개별 알림을 눌러야 해당 일정으로 이동합니다. 잠금 화면에서는 민감한 내용을 숨기는 `VISIBILITY_PRIVATE`를 사용합니다.

기준 문서: [Android 알람 예약](https://developer.android.com/develop/background-work/services/alarms), [알림 권한](https://developer.android.com/develop/ui/views/notifications/notification-permission).

## 구현과 확인

- Dart 데이터·미리 계산: `lib/models/reminder_plan.dart`
- Flutter/Android 통신: `lib/platform/notification_bridge.dart`
- Android 계산: `ReminderPlanner.kt` (Android 의존성이 없는 순수 계산)
- 저장·예약·발송·중복 방지: `Reminders.kt`
- 권한 요청과 상세 진입: `MainActivity.kt`

```sh
flutter analyze
flutter test
cd android
./gradlew :app:testDebugUnitTest
```

검수용 앱에 현재 시각 약 3분 뒤의 알림을 만들려면 별도 앱 ID와 함께 사용합니다. 재시작 시 검수용 데이터를 다시 만듭니다. 일반 APK에는 이 예시 일정이 들어가지 않습니다.

```sh
flutter build apk --debug -t tool/preview.dart --android-project-arg=chaengimPreview=true --dart-define=CHAENGIM_NOTIFICATION_QA=true
```

실물 휴대폰·제조사별 절전 정책은 추가 검증이 필요합니다.

검증: Flutter 테스트 18개, Android JVM 예약 계산 테스트 8개 통과. Android 16 에뮬레이터에서 권한 거절→허용, 전체 알림 끄기→켜기, 앱 프로세스가 없는 상태에서 실제 AlarmManager 예약 알림 수신을 확인했습니다. 과거 예약을 새로 만들지 않는 규칙과 이미 예약된 지연 알림 보존을 구분해 테스트합니다.

에뮬레이터를 재부팅한 후 앱을 열지 않고도 `BOOT_COMPLETED` 수신으로 향후 예약 3건이 다시 AlarmManager에 등록되는 것을 확인했습니다. 재부팅 중 시각이 지난 알림은 몰아서 보내지 않고 제외됩니다.

별도로 예약 시각이 지난 검수 이벤트를 앱 UID에서 Receiver에 전달해 지연 수신을 재현하고, 표시된 개별 알림을 눌렀을 때 새 Flutter 프로세스에서 해당 일정 상세가 열리는 것을 확인했습니다. [설정 화면](screenshots/notification-settings.png), [수신 알림](screenshots/notification-received.png), [알림으로 연 상세](screenshots/notification-detail.png)는 별도 검수용 앱의 예시 데이터입니다.
