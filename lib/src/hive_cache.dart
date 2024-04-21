import 'hive_storage.dart';

abstract class HiveCache<State> {
  final _storage = HiveStorage.instance;

  State _state;

  State get state => _state;
  set state(State state) => _emit(state);

  HiveCache(State inital) : _state = inital {
    try {
      var stateJson = (_storage.read(storageToken) as Map?)?.cast<String, dynamic>();
      if (stateJson != null) {
        _state = fromJson(stateJson);
      } else {
        _state = inital;
        _storage.write(storageToken, toJson(inital));
      }
    } catch (error, stackTrace) {
      _state = inital;
      print('error: $error\n stackTrace: $stackTrace');
    }
  }

  void _emit(State state) {
    final oldState = _state;
    _state = state;
    _storage.write(storageToken, toJson(state)).catchError((error, stackTrace) {
      _state = oldState;
      print('Error: $error\nStackTrace: $stackTrace');
    });
  }

  /// [id] is used to uniquely identify multiple instances
  /// of the same [HiveCache] type.
  /// In most cases it is not necessary;
  /// however, if you wish to intentionally have multiple instances
  /// of the same [HiveCache], then you must override [id]
  /// and return a unique identifier for each [HiveCache] instance
  /// in order to keep the caches independent of each other.
  String get id => '';

  /// Storage prefix which can be overridden to provide a custom
  /// storage namespace.
  /// Defaults to [runtimeType] but should be overridden in cases
  /// where stored data should be resilient to obfuscation or persist
  /// between debug/release builds.
  String get storagePrefix => runtimeType.toString();

  /// `storageToken` is used as registration token for hydrated storage.
  /// Composed of [storagePrefix] and [id].
  String get storageToken => '$storagePrefix$id';

  /// [deleteCache] is used to wipe or invalidate the cache of a [HiveCache].
  /// Calling [deleteCache] will delete the cached state of the bloc
  /// but will not modify the current state of the bloc.
  Future<void> deleteCache() => _storage.delete(storageToken);

  /// Responsible for converting the `Map<String, dynamic>` representation
  /// of the bloc state into a concrete instance of the bloc state.
  State fromJson(Map<String, dynamic> json);

  /// Responsible for converting a concrete instance of the bloc state
  /// into the the `Map<String, dynamic>` representation.
  ///
  /// If [toJson] returns `null`, then no state changes will be persisted.
  Map<String, dynamic> toJson(State state);
}



// class Student extends HiveCache<String> {
//   Student(super.inital);

//   sleeping() {}

//   @override
//   fromJson(Map<String, dynamic> json) {
//     // TODO: implement fromJson
//     throw UnimplementedError();
//   }

//   @override
//   Map<String, dynamic>? toJson(state) {
//     // TODO: implement toJson
//     throw UnimplementedError();
//   }
// }
