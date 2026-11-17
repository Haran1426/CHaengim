import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/app_skin.dart';
import 'snapshot_sync.dart';

abstract class AppearanceStorage {
  Future<String?> load();
  Future<void> save(String id);
}

class LocalAppearanceStorage implements AppearanceStorage {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'chaengim.appearance.v1';
  @override
  Future<String?> load() => _preferences.getString(_key);
  @override
  Future<void> save(String id) => _preferences.setString(_key, id);
}

class AppearanceStore extends ChangeNotifier {
  AppearanceStore(
    this.storage, {
    this.syncWidget,
    this.readTimeout = const Duration(seconds: 10),
    this.syncTimeout = const Duration(seconds: 8),
  });
  final AppearanceStorage storage;
  final Duration readTimeout, syncTimeout;
  final Future<void> Function(AppPalette)? syncWidget;
  AppSkin _selected = AppSkin.forest;
  bool _plus = false, loading = true, saving = false, _disposed = false;
  bool _loadFailed = false;
  int _revision = 0;
  Future<void>? _loadOperation;
  late final _widgetSync = SnapshotSync<AppPalette>(
    (value) async => syncWidget?.call(value),
    syncTimeout,
  );
  String? error;
  AppSkin get active =>
      _selected.premium && !_plus ? AppSkin.forest : _selected;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() {
    if (_disposed || saving) return Future<void>.value();
    return _loadOperation ??= _load().whenComplete(() => _loadOperation = null);
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    _loadFailed = false;
    _notify();
    try {
      _selected = AppSkin.fromId(await storage.load().timeout(readTimeout));
      _revision++;
    } catch (_) {
      _loadFailed = true;
      error = '테마를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    loading = false;
    if (!_loadFailed) await _sync();
    _notify();
  }

  Future<void> setPlus(bool value) async {
    if (_disposed || _plus == value) return;
    _plus = value;
    _revision++;
    _notify();
    if (!loading) await _sync();
  }

  Future<bool> select(AppSkin skin) async {
    if (_disposed || loading || saving || (skin.premium && !_plus)) {
      return false;
    }
    saving = true;
    error = null;
    _notify();
    try {
      await storage.save(skin.name);
      _selected = skin;
      _loadFailed = false;
      _revision++;
      await _sync();
      return true;
    } catch (_) {
      error = '테마를 저장하지 못했어요. 다시 시도해 주세요.';
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> _sync() async {
    if (loading || _loadFailed) return;
    final revision = _revision;
    void settled(Object? failure) {
      if (revision != _revision || _loadFailed) return;
      error = failure == null ? null : '앱 테마는 적용됐지만 위젯 갱신이 지연되고 있어요.';
      _notify();
    }

    try {
      await _widgetSync.run(revision, active.palette, settled);
    } catch (failure) {
      settled(failure);
    }
  }

  Future<void> retry() async {
    if (_disposed || saving) return;
    if (loading) {
      await _loadOperation;
      return;
    }
    if (_loadFailed) return load();
    error = null;
    await _sync();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
