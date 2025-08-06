// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/base_remote.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:corekit/src/base/pagination_controller.dart';
import 'package:corekit/src/injector/injector_core.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';

abstract class CoreRepository<R extends BaseRemote> {
  CoreRepository(this.injector, this.remote);

  final InjectorCore injector;
  final R remote;

  @protected
  Future<Result<T, FailureFoundation>> invoke<T>({
    required Future<Result<T, FailureFoundation>> Function() onRemote,
  }) {
    return onRemote();
  }

  @protected
  Future<Result<List<T>, FailureFoundation>> invokePaginated<T extends BaseModel>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, FailureFoundation>> Function(Map<String, int>) onRemote,
  }) async {
    final unwrapped = controller.unwrapPaginated(await onRemote(controller.paginationParams));
    controller.bumpPage();
    return unwrapped;
  }
}
