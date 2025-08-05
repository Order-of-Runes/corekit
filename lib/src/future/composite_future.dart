class CompositeFuture<K extends Enum> {
  final Map<K, Future<Object?>> _requestMap = {};

  /// Add the futures you want await
  ///
  /// Example:
  /// ```dart
  /// enum DKey {
  ///   f1,
  ///   f2,
  ///   f3,
  /// }
  ///
  /// final composite = CompositeFuture<DKey>()
  ///   ..add(DKey.f1, f1())
  ///   ..add(DKey.f2, f2())
  ///   ..add(DKey.f3, f3());
  /// ```
  void add<T extends Object?>(K key, Future<T> future) {
    _requestMap[key] = future;
  }

  /// Execute the futures added through [add]
  ///
  /// This returns an object of [CompositeFutureResult] which can be
  /// used to access the respective values of [key]
  ///
  /// If [eagerError] is true, the returned future completes with an error
  /// immediately on the first error from one of the futures. Otherwise all
  /// futures must complete before the returned future is completed (still with
  /// the first error; the remaining errors are silently dropped).
  ///
  /// Example:
  /// ```dart
  /// enum DKey {
  ///   f1,
  ///   f2,
  ///   f3,
  /// }
  ///
  /// final result = await composite.futures();
  /// ```
  Future<CompositeFutureResult<K>> futures({bool eagerError = true}) async {
    assert(_requestMap.isNotEmpty, 'You need to add the futures before you can wait them');

    final Map<K, Object?> resultMap = {};

    final results = await Future.wait(_requestMap.values, eagerError: eagerError);
    for (final (index, key) in _requestMap.keys.indexed) {
      resultMap[key] = results[index];
    }

    return CompositeFutureResult._(resultMap);
  }
}

class CompositeFutureResult<K extends Enum> {
  const CompositeFutureResult._(this._map);

  final Map<K, Object?> _map;

  /// Get the value contained within the passed future,
  /// accessed through [key]
  ///
  /// Example:
  /// ```dart
  /// final r1 = result.value<int>(DKey.f1);
  /// final r2 = result.value<int>(DKey.f2);
  /// final r3 = result.value<String>(DKey.f3);
  /// ```
  T value<T extends Object?>(K key) {
    final result = _map[key];

    assert(result is T, 'The result is not of type $T for the key "$key", but a ${result.runtimeType}.');

    return result as T;
  }
}
