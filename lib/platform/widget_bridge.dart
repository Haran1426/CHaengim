import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/schedule.dart';

// Android가 앱 종료 후에도 읽을 수 있는 최소 표시 데이터만 전달합니다.
class WidgetBridge {
  static const channel = MethodChannel('chaengim/widgets');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<void> sync(List<Schedule> schedules) async {
    if (!supported) return;
    await channel.invokeMethod<void>(
      'sync',
      jsonEncode(widgetSnapshot(schedules)),
    );
  }

  Future<bool> pin({bool medium = false}) async {
    if (!supported) return false;
    return await channel.invokeMethod<bool>('pin', {'medium': medium}) ?? false;
  }

  Future<String?> initialRoute() async =>
      supported ? channel.invokeMethod<String>('initialRoute') : null;
  void listen(ValueChanged<String> onOpen) {
    if (!supported) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute' && call.arguments is String) {
        onOpen(call.arguments as String);
      }
    });
  }

  void dispose() {
    if (supported) channel.setMethodCallHandler(null);
  }
}

List<Map<String, Object>> widgetSnapshot(List<Schedule> schedules) {
  final active = schedules.where((s) => !s.isCompleted).toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));
  return active
      .take(3)
      .map(
        (s) => <String, Object>{
          'id': s.id,
          'title': s.title,
          'deadline': s.deadline.millisecondsSinceEpoch,
          'remaining': s.remaining,
          'total': s.items.length,
          'stage': s.stage.label,
          'hasTime': s.hasTime,
        },
      )
      .toList();
}
