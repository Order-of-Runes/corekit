// Copyright (c) 2024 EShare Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/injector/core_injector.dart';
import 'package:corekit/src/store/store.dart';

/// Base class for all cached data sources
abstract class BaseDao {
  const BaseDao(this.injector);

  final InjectorCore injector;

  CoreStore<T> openStore<T extends BaseModel>({String? suffix, bool eternal = false}) {
    final db = eternal ? injector.eternalDatabase : injector.database;
    return db.openStore<T>(suffix: suffix);
  }

  Future<void> runBatch() {
    return injector.database.runBatch();
  }
}
