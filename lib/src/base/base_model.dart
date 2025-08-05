// Copyright (c) 2024 EShare Authors. All rights reserved.

import 'package:equatable/equatable.dart';

/// All the models in the project should inherit this class.
abstract class BaseModel extends Equatable {
  const BaseModel();

  String? get primaryKey;

  Map<String, dynamic> toJson();
}
