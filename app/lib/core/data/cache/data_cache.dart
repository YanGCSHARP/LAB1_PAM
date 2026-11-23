import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/api_config.dart';
import '../repository_exception.dart';

/// The last copy of the user's data that came from the server.
///
/// Every successful load is written here; when the server cannot be reached
/// the repositories answer from this copy instead, so the app opens with
/// data on a plane or in the metro. Writes still need the network. The copy
/// belongs to one user and is erased on sign-out.
abstract interface class DataCache {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> clear();
}

/// [DataCache] in `shared_preferences`: a few JSON strings, small enough for
/// a key-value store — personal finances are hundreds of rows, not millions.
class PrefsDataCache implements DataCache {
  PrefsDataCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String _prefix = 'walletmate.cache.';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString('$_prefix$key', value);

  @override
  Future<void> clear() async {
    final keys = await _prefs.getKeys();
    for (final key in keys.where((key) => key.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }
}

/// [DataCache] in memory — the mock backend and tests.
class MemoryDataCache implements DataCache {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> clear() async => _values.clear();
}

final dataCacheProvider = Provider<DataCache>(
  (ref) =>
      ref.watch(useMockBackendProvider) ? MemoryDataCache() : PrefsDataCache(),
);

/// Whether the screens show the saved copy because the server is out of
/// reach. Drives the "no connection" banner.
final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool offline}) {
    if (state != offline) {
      state = offline;
    }
  }
}

/// One cached collection: loads through the network, falls back to the saved
/// copy on a [NetworkException], and keeps the copy in step with every write
/// that succeeded on the server.
class CachedCollection<T> {
  CachedCollection({
    required this.cache,
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    required this.onSource,
  });

  final DataCache cache;
  final String key;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;

  /// Told after every load whether the data came from the saved copy.
  final void Function({required bool offline}) onSource;

  Future<List<T>> fetch(Future<List<T>> Function() remote) async {
    try {
      final items = await remote();
      await _save(items);
      onSource(offline: false);
      return items;
    } on NetworkException {
      final saved = await _load();
      if (saved == null) {
        rethrow;
      }
      onSource(offline: true);
      return saved;
    }
  }

  /// Puts a created or updated [item] into the saved copy.
  Future<T> upsert(T item) async {
    final items = await _load() ?? [];
    final index = items.indexWhere((other) => idOf(other) == idOf(item));
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _save(items);
    return item;
  }

  Future<void> remove(String id) async {
    final items = await _load();
    if (items == null) {
      return;
    }
    await _save(items.where((item) => idOf(item) != id).toList());
  }

  Future<List<T>?> _load() async {
    final raw = await cache.read(key);
    if (raw == null) {
      return null;
    }
    return (jsonDecode(raw) as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<T> items) =>
      cache.write(key, jsonEncode(items.map(toJson).toList()));
}
