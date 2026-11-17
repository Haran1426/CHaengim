import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/schedule.dart';
import '../models/reminder_plan.dart';

class ReminderStatus {
  const ReminderStatus({
    this.supported = false,
    this.allowed = false,
    this.enabled = true,
    this.asked = false,
    this.pending = 0,
  });
  final bool supported, allowed, enabled, asked;
  final int pending;
  factory ReminderStatus.fromMap(Map<Object?, Object?> map) => ReminderStatus(
    supported: true,
    allowed: map['allowed'] == true,
    enabled: map['enabled'] == true,
    asked: map['asked'] == true,
    pending: (map['pending'] as num?)?.toInt() ?? 0,
  );
}

class NotificationBridge {
  static const channel = MethodChannel('chaengim/reminders');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<void> sync(List<Schedule> schedules) async {
    if (supported) {
      await channel.invokeMethod<void>(
        'sync',
        jsonEncode(reminderSnapshot(schedules)),
      );
    }
  }

  Future<ReminderStatus> status() async => !supported
      ? const ReminderStatus()
      : ReminderStatus.fromMap(
          await channel
                  .invokeMapMethod<Object?, Object?>('status')
                  .timeout(const Duration(seconds: 8)) ??
              {},
        );
  Future<ReminderStatus> requestPermission({bool onlyFirstTime = false}) async {
    final current = await status();
    if (!current.supported ||
        current.allowed ||
        (onlyFirstTime && current.asked)) {
      return current;
    }
    return ReminderStatus.fromMap(
      await channel.invokeMapMethod<Object?, Object?>('requestPermission') ??
          {},
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (supported) await channel.invokeMethod<void>('setEnabled', enabled);
  }

  Future<void> openSettings() async {
    if (supported) await channel.invokeMethod<void>('openSettings');
  }

  Future<bool> testNotification() async =>
      supported && await channel.invokeMethod<bool>('test') == true;
}
