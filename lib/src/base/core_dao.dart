// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/store/store.dart';

/// Base class for all cached data sources
abstract class CoreDao {
  const CoreDao();

  CoreStore<T> openStore<T extends BaseModel>({String? suffix, bool eternal = false});

  Future<void> runBatch();
}
