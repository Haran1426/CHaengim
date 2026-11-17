import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule.dart';
import 'snapshot_sync.dart';

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
  ScheduleStore(
    this.storage, {
    this.onChanged,
    this.onRemindersChanged,
    this.readTimeout = const Duration(seconds: 10),
    this.syncTimeout = const Duration(seconds: 8),
  });
  final ScheduleStorage storage;
  final Duration readTimeout, syncTimeout;
  final Future<void> Function(List<Schedule>)? onChanged;
  final Future<void> Function(List<Schedule>)? onRemindersChanged;
  String? widgetError;
  String? reminderError;
  List<Schedule> _schedules = [];
  bool loading = true;
  bool saving = false;
  bool _disposed = false;
  bool _hasLoaded = false;
  int _revision = 0;
  Future<void>? _loadOperation, _saveOperation;
  late final _widgetSync = SnapshotSync<List<Schedule>>(
    (value) async => onChanged?.call(value),
    syncTimeout,
  );
  late final _reminderSync = SnapshotSync<List<Schedule>>(
    (value) async => onRemindersChanged?.call(value),
    syncTimeout,
  );
  String? loadError;
  bool get hasLoaded => _hasLoaded;
  bool get canEdit => _hasLoaded && !loading && !saving && loadError == null;
  List<Schedule> get schedules => List.unmodifiable(_schedules);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() {
    if (_disposed) return Future<void>.value();
    return _loadOperation ??= _load().whenComplete(() => _loadOperation = null);
  }

  Future<void> _load() async {
    loading = true;
    loadError = null;
    _notify();
    try {
      final saving = _saveOperation;
      if (saving != null) {
        try {
          await saving;
        } catch (_) {
          // 저장 실패는 저장 요청자가 처리하고, 새로고침은 저장된 값을 읽습니다.
        }
      }
      _schedules = await storage.load().timeout(readTimeout);
      _hasLoaded = true;
      _revision++;
      await Future.wait([syncWidget(), syncReminders()]);
    } catch (_) {
      loadError = '일정을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    loading = false;
    _notify();
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
  Future<void> _commit(List<Schedule> next) {
    if (_disposed || loading || loadError != null || saving) {
      throw StateError('저장소가 준비되지 않았습니다.');
    }
    saving = true;
    _notify();
    final operation = _write(next);
    _saveOperation = operation;
    return operation.whenComplete(() {
      if (identical(_saveOperation, operation)) _saveOperation = null;
    });
  }

  Future<void> _write(List<Schedule> next) async {
    try {
      // 화면이 종료돼도 시작한 저장과 Android 동기화는 끝까지 마칩니다.
      await storage.save(next);
      _schedules = next;
      _revision++;
      await Future.wait([syncWidget(), syncReminders()]);
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> syncWidget() => _sync(true);

  Future<void> syncReminders() => _sync(false);

  Future<void> _sync(bool widget) async {
    if (!_hasLoaded || loadError != null) return;
    final revision = _revision;
    void settled(Object? error) {
      if (revision != _revision) return;
      if (widget) {
        widgetError = error == null ? null : '일정은 저장됐지만 위젯 갱신이 지연되고 있어요.';
      } else {
        reminderError = error == null ? null : '일정은 저장됐지만 알림 예약을 갱신하지 못했어요.';
      }
      _notify();
    }

    try {
      await (widget ? _widgetSync : _reminderSync).run(
        revision,
        schedules,
        settled,
      );
    } catch (error) {
      settled(error);
    }
  }

  void refreshClock() => _notify();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
