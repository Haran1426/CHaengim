import 'package:flutter/material.dart';
import '../design/app_theme.dart';
import '../platform/notification_bridge.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});
  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  final bridge = NotificationBridge();
  ReminderStatus? status;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    try {
      final current = await bridge.status();
      if (mounted) {
        setState(() {
          status = current;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '알림 상태를 확인하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      await refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 적용하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = status;
    return Scaffold(
      appBar: AppBar(title: const Text('마감 알림')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
            children: [
              Text(
                '잊기 전에,\n한 번 더 챙겨요.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                '알림 날짜와 시각은 각 일정의 수정 화면에서 선택할 수 있어요.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 28),
              if (error != null) ...[
                Text(error!),
                TextButton(onPressed: refresh, child: const Text('다시 시도')),
              ] else if (current == null)
                const Center(child: CircularProgressIndicator())
              else if (!current.supported)
                const Text('마감 알림은 Android 앱에서 사용할 수 있어요.')
              else ...[
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: const Text(
                      '마감 알림 받기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      '끄면 모든 예약 알림을 잠시 멈춰요.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: current.enabled,
                    onChanged: busy
                        ? null
                        : (value) => perform(() => bridge.setEnabled(value)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: current.allowed && current.enabled
                        ? AppColors.lime
                        : const Color(0xFFFFEBDD),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !current.enabled
                            ? '알림을 잠시 쉬고 있어요'
                            : current.allowed
                            ? '${current.pending}개의 알림이 예약되어 있어요'
                            : 'Android 알림이 꺼져 있어요',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        !current.enabled
                            ? '다시 켜면 아직 지나지 않은 알림을 예약해요.'
                            : current.allowed
                            ? '지난 알림은 보내지 않아요. 일정 수정·삭제·최종 완료 시 예약도 함께 갱신돼요.'
                            : '권한을 허용해야 예약한 알림을 받을 수 있어요. 일정과 위젯은 계속 사용할 수 있어요.',
                        style: const TextStyle(fontSize: 12, height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (!current.allowed)
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => perform(() async {
                            await bridge.requestPermission();
                          }),
                    child: const Text('알림 권한 허용'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => perform(bridge.openSettings),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Android 알림 설정 열기'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy || !current.allowed || !current.enabled
                      ? null
                      : () => perform(() async {
                          final sent = await bridge.testNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  sent
                                      ? '테스트 알림을 보냈어요. 알림창을 확인해 주세요.'
                                      : '알림을 보내지 못했어요. Android 설정을 확인해 주세요.',
                                ),
                              ),
                            );
                          }
                        }),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('테스트 알림 보내기'),
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                '알림을 받을 때',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                '• 새 일정은 1일 전 오전 9시 알림을 제안해요.\n• 당일·1·3·7일 전을 원하는 만큼 선택할 수 있어요.\n• 기존 일정에는 알림을 자동 추가하지 않아요.\n• 절전·강제 종료·제조사 설정에 따라 알림이 늦어지거나 제한될 수 있어요.\n• 마감 시각 이후로 늦어진 사전 알림은 보내지 않아요.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
