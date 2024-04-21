import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:synchronized/synchronized.dart';

/// Interface which is used to persist and retrieve state changes.
abstract class Storage<V> {
  /// Returns value for key
  dynamic read(String key);

  /// Persists key value pair
  Future<void> write(String key, dynamic value);

  /// Deletes key value pair
  Future<void> delete(String key);

  /// Clears all key value pairs from storage
  Future<void> clear();

  /// Clears all key value pairs from storage
  Future<void> close();

  bool containsKey(String key);

  /// Flushes all pending changes of the box to disk.
  Future<void> flush();
}

class StorageNotFound implements Exception {
  /// {@macro storage_not_found}
  const StorageNotFound();

  @override
  String toString() {
    return 'Storage was accessed before it was initialized.\n'
        'Please ensure that storage has been initialized.\n\n'
        'For example:\n\n'
        'HydratedBloc.storage = await HydratedStorage.build();';
  }
}

class HiveStorage implements Storage {
  HiveStorage._(this.box);

  static HiveStorage? _instance;

  final Box<dynamic> box;

  static HiveStorage get instance {
    if (_instance == null) throw const StorageNotFound();
    return _instance!;
  }

  static final webStorageDirectory = Directory('');

  static final _lock = Lock();

  static Future<void> build({
    String? name,
    required Directory storageDirectory,
    HiveCipher? encryptionCipher,
  }) {
    return _lock.synchronized(() async {
      if (_instance != null) return;
      var name0 = name?.toLowerCase() ?? 'hive_storage';
      Box<dynamic> box;
      if (storageDirectory == webStorageDirectory) {
        box = await Hive.openBox<dynamic>(
          name0,
          encryptionCipher: encryptionCipher,
        );
      } else {
        Hive.init(storageDirectory.path);
        box = await Hive.openBox<dynamic>(
          name0,
          encryptionCipher: encryptionCipher,
        );
        await _migrate(name0, storageDirectory, box);
      }

      _instance = HiveStorage._(box);
    });
  }

  static Future<dynamic> _migrate(String name, Directory directory, Box<dynamic> box) async {
    final file = File('${directory.path}/.$name.json');
    if (file.existsSync()) {
      try {
        final dynamic storageJson = json.decode(await file.readAsString());
        final cache = (storageJson as Map).cast<String, String>();
        for (final key in cache.keys) {
          try {
            final string = cache[key];
            final dynamic object = json.decode(string ?? '');
            await box.put(key, object);
          } catch (_) {}
        }
      } catch (_) {}
      await file.delete();
    }
  }

  @override
  bool containsKey(String key) => box.containsKey(key);

  @override
  Future<void> flush() async {
    if (box.isOpen) {
      return _lock.synchronized(() => box.flush());
    }
  }

  @override
  dynamic read(String key) => box.isOpen ? box.get(key) : null;

  @override
  Future<void> write(String key, dynamic value) async {
    if (box.isOpen) {
      return _lock.synchronized(() => box.put(key, value));
    }
  }

  @override
  Future<void> delete(String key) async {
    if (box.isOpen) {
      return _lock.synchronized(() => box.delete(key));
    }
  }

  @override
  Future<void> clear() async {
    if (box.isOpen) {
      _instance = null;
      return _lock.synchronized(box.clear);
    }
  }

  @override
  Future<void> close() async {
    if (box.isOpen) {
      _instance = null;
      return _lock.synchronized(box.close);
    }
  }
}
