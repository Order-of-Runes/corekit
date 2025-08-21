// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:sembast/sembast.dart';
import 'package:utils/utils.dart';

typedef ModelResolver<T extends BaseModel, E extends Exception> = Result<T, E> Function(Map<String, dynamic>);

mixin ModelTransformation {
  /// Transform list of records from db into grouped list of models of type [T]
  Result<Map<String, List<T>>, E> transformMapToGroup<T extends BaseModel, E extends Exception>({
    required String groupBy,
    required List<RecordSnapshot<String, Map<String, Object?>>> records,
    required ModelResolver<T, E> resolver,
  }) {
    E? failure;
    final result = <String, List<T>>{};

    for (final record in records) {
      final rawModel = record.value;
      final String? groupByKey = rawModel[groupBy]?.toString();
      final model = resolver(rawModel);

      if (model.isErr) {
        failure = model.err!;
        break;
      }
      if (groupByKey != null) {
        final rawModels = result[groupByKey] ?? <T>[];
        result[groupByKey] = [...rawModels, model.ok!];
      }
    }

    if (failure.isNotNull) return Err(failure!);

    return Ok(result);
  }

  /// Transform list of models into grouped list of models of type [T]
  Result<Map<String, List<T>>, E> transformModelToGroup<T extends BaseModel, E extends Exception>({
    required String groupBy,
    required List<T> records,
  }) {
    final result = <String, List<T>>{};

    for (final record in records) {
      final String? groupByKey = record.toJson()[groupBy]?.toString();

      if (groupByKey != null) {
        final rawModels = result[groupByKey] ?? <T>[];
        result[groupByKey] = [...rawModels, record];
      }
    }

    return Ok(result);
  }
}
