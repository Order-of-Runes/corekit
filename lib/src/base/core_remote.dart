// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/api/api_service_core.dart';
import 'package:flutter/foundation.dart';

/// Core class for all remote data sources
abstract class CoreRemote<A extends ApiServiceCore> {
  const CoreRemote();

  A get api;

  /// Cancels service requests.
  @protected
  void cancel([dynamic message]);
}
