// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:utils/utils.dart';

class CacheLifetime {
  const CacheLifetime({
    required this.key,
    this.eternal = false,
    this.duration = const Duration(days: 1),
  });

  /// Unique key to mark the cache lifetime
  ///
  /// Make sure this key is truly unique and does not clash with
  /// other [CacheLifetime]s' [key]
  final String key;

  /// Duration until when this cache should live
  ///
  /// This is an optional field, so when not explicitly supplied will
  /// default to 1 day
  final Duration duration;
  final bool eternal;

  /// Gives the current timestamp
  String get timeStamp => DateTime.now().toIso8601String();

  /// Gives whether cache has expired
  ///
  /// Here [cacheTimeStamp] is the time when cache was updated
  bool hasExpired(String? cacheTimeStamp) {
    if (cacheTimeStamp.isNullOrEmpty) return true;

    final now = DateTime.now();
    final cacheUpdateTime = DateTime.tryParse(cacheTimeStamp!);

    if (cacheUpdateTime.isNull) return false;

    return now.difference(cacheUpdateTime!) > duration;
  }
}
