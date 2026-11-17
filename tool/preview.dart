// 실제 앱 데이터와 분리된 시각 검수용 진입점입니다.
// 반드시 --android-project-arg=chaengimPreview=true 로 빌드합니다.
import 'package:material_ui/material_ui.dart';
import 'package:my_first_app/data/schedule_store.dart';
import 'package:my_first_app/models/schedule.dart';
import 'package:my_first_app/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.now();
  DateTime due(int days) => DateTime(now.year, now.month, now.day + days, 18);
  final alarmTime = now.add(
    const Duration(
      minutes: int.fromEnvironment('CHAENGIM_QA_LEAD_MINUTES', defaultValue: 3),
    ),
  );
  await LocalScheduleStorage().save([
    if (const bool.fromEnvironment('CHAENGIM_NOTIFICATION_QA'))
      Schedule(
        id: 'preview-reminder',
        title: '마감 알림 동작 확인',
        deadline: now.add(const Duration(hours: 2)),
        hasTime: true,
        reminderDays: const [0],
        reminderHour: alarmTime.hour,
        reminderMinute: alarmTime.minute,
        items: const [Preparation(title: '알림 수신 확인')],
      ),
    Schedule(
      id: 'preview-1',
      title: '국가장학금 2차 신청',
      deadline: due(3),
      category: '지원·신청',
      hasTime: true,
      items: const [
        Preparation(title: '재학증명서 발급받기'),
        Preparation(title: '가구원 정보 제공 동의'),
        Preparation(title: '신청 자격 확인', done: true),
      ],
      memo: '신청을 마친 뒤 접수 내역도 확인하기.',
    ),
    Schedule(
      id: 'preview-2',
      title: '한국사능력검정시험 접수',
      deadline: due(7),
      category: '시험·자격증',
      items: const [
        Preparation(title: '증명사진 준비'),
        Preparation(title: '시험장 확인'),
      ],
    ),
    Schedule(
      id: 'preview-3',
      title: '여권 갱신 서류 제출',
      deadline: due(12),
      category: '생활',
      items: const [Preparation(title: '여권용 사진 촬영')],
    ),
    Schedule(
      id: 'preview-done',
      title: '지난 학기 등록',
      deadline: due(-1),
      stage: ScheduleStage.completed,
    ),
  ]);
  app.main();
}
