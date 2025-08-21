// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/api/api_service_core.dart';
import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:corekit/src/base/core_remote.dart';
import 'package:corekit/src/base/pagination_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';

abstract class RootRepository<A extends ApiServiceCore, R extends CoreRemote<A>, E extends Exception> {
  const RootRepository(this.remote);

  final R remote;

  @protected
  Future<Result<T, E>> invoke<T>({
    required Future<Result<T, E>> Function() onRemote,
  }) {
    return onRemote();
  }

  @protected
  Future<Result<List<T>, E>> invokePaginated<T extends BaseModel>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, E>> Function(Map<String, int>) onRemote,
  }) async {
    final unwrapped = controller.unwrapPaginated<T, E>(await onRemote(controller.paginationParams));
    controller.bumpPage();
    return unwrapped;
  }
}
