// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';
import 'package:equatable/equatable.dart';

abstract class CoreListModel<T extends BaseModel> extends Equatable {
  const CoreListModel(this.records);

  final List<T> records;

  int get total;
}
