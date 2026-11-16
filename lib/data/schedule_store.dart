import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

abstract class ScheduleStorage {
  Future<List<Schedule>> load();
  Future<void> save(List<Schedule> schedules);
}

class LocalScheduleStorage implements ScheduleStorage {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'chaengim.schedules.v1';
  @override
  Future<List<Schedule>> load() async {
    final value = await _preferences.getString(_key);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .map(
          (entry) => Schedule.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  @override
  Future<void> save(List<Schedule> schedules) => _preferences.setString(
    _key,
    jsonEncode(schedules.map((schedule) => schedule.toJson()).toList()),
  );
}

// 저장에 성공한 데이터만 화면에 반영하고, 연결된 화면들에 알려줍니다.
class ScheduleStore extends ChangeNotifier {
  ScheduleStore(this.storage, {this.onChanged, this.onRemindersChanged});
  final ScheduleStorage storage;
  final Future<void> Function(List<Schedule>)? onChanged;
  final Future<void> Function(List<Schedule>)? onRemindersChanged;
  String? widgetError;
  String? reminderError;
  List<Schedule> _schedules = [];
  bool loading = true;
  bool saving = false;
  String? loadError;
  List<Schedule> get schedules => List.unmodifiable(_schedules);
  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      _schedules = await storage.load();
      await syncWidget();
      await syncReminders();
    } catch (_) {
      loadError = '일정을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> put(Schedule schedule) async {
    final next = [..._schedules];
    final index = next.indexWhere((item) => item.id == schedule.id);
    if (index < 0) {
      next.add(schedule);
    } else {
      next[index] = schedule;
    }
    await _commit(next);
  }

  Future<void> remove(String id) =>
      _commit(_schedules.where((item) => item.id != id).toList());
  Future<void> _commit(List<Schedule> next) async {
    if (loading || loadError != null || saving) {
      throw StateError('저장소가 준비되지 않았습니다.');
    }
    saving = true;
    notifyListeners();
    try {
      await storage.save(next);
      _schedules = next;
      await syncWidget();
      await syncReminders();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> syncWidget() async {
    widgetError = null;
    try {
      await onChanged?.call(schedules);
    } catch (_) {
      widgetError = '일정은 저장됐지만 위젯 갱신이 지연되고 있어요.';
    }
  }

  Future<void> syncReminders() async {
    reminderError = null;
    try {
      await onRemindersChanged?.call(schedules);
    } catch (_) {
      reminderError = '일정은 저장됐지만 알림 예약을 갱신하지 못했어요.';
    }
  }

  void refreshClock() => notifyListeners();
}
