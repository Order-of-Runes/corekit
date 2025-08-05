// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';

class CacheLifetimeModel extends BaseModel {
  const CacheLifetimeModel({
    this.key,
    this.lifetime,
  });

  factory CacheLifetimeModel.fromJson(Map<String, dynamic> json) {
    return CacheLifetimeModel(
      key: json['key'] as String?,
      lifetime: json['lifetime'] as String?,
    );
  }

  final String? key;
  final String? lifetime;

  @override
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'lifetime': lifetime,
    };
  }

  CacheLifetimeModel copyWith({String? key, String? lifetime}) {
    return CacheLifetimeModel(
      key: key ?? this.key,
      lifetime: lifetime ?? this.lifetime,
    );
  }

  @override
  String? get primaryKey => key;

  @override
  List<Object?> get props {
    return [key, lifetime];
  }

  @override
  String toString() {
    return '''
CacheLifetimeModel {
 "key": "$key",
 "lifetime": "$lifetime"
}
          ''';
  }
}
