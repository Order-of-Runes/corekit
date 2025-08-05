// Copyright (c) 2024 EShare Authors. All rights reserved.

import 'package:corekit/src/api/api_service_core.dart';
import 'package:corekit/src/injector/core_injector.dart';
import 'package:flutter/foundation.dart';

/// Base class for all remote data sources
abstract class BaseRemote {
  const BaseRemote(this.injector);

  final InjectorCore injector;

  ApiServiceCore get api => injector.apiService;

  /// Cancels service requests.
  @protected
  void cancel([dynamic message]) => api.cancelToken?.cancel(message);
}
