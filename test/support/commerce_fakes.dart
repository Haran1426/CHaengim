import 'package:flutter/foundation.dart';
import 'package:my_first_app/data/appearance_store.dart';
import 'package:my_first_app/data/plus_store.dart';

class MemoryAppearanceStorage implements AppearanceStorage {
  String? id;
  bool fail = false;
  @override
  Future<String?> load() async => id;
  @override
  Future<void> save(String value) async {
    if (fail) throw StateError('disk unavailable');
    id = value;
  }
}

class FakePlusGateway implements PlusGateway {
  FakePlusGateway({this.configured = true});
  @override
  final bool configured;
  bool owned = false, pending = false;
  Object? failure;
  int purchases = 0;
  ValueChanged<bool>? listener;
  @override
  Future<void> initialize(ValueChanged<bool> onChanged) async {
    listener = onChanged;
  }

  @override
  Future<bool> refresh() async {
    if (failure != null) throw failure!;
    return owned;
  }

  @override
  Future<PlusOffer?> offer() async => const PlusOffer('₩7,900');
  @override
  Future<bool> buy() async {
    purchases++;
    if (failure != null) throw failure!;
    if (!pending) owned = true;
    return owned;
  }

  @override
  Future<bool> restore() async => refresh();
  void revoke() {
    owned = false;
    listener?.call(false);
  }

  @override
  void dispose() {
    listener = null;
  }
}
