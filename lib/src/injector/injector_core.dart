// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/api/api_service_core.dart';
import 'package:corekit/src/store/store.dart';
import 'package:foundation/foundation.dart';

abstract class InjectorCore {
  const InjectorCore();

  CoreDatabase get database;

  CoreDatabase get eternalDatabase;

  ApiServiceCore get apiService;

  NetworkInfoFoundation get network;
}
