// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/api/api_service_core.dart';
import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:corekit/src/base/core_remote.dart';
import 'package:corekit/src/base/pagination_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';

abstract class RootRepository<A extends ApiServiceCore, R extends CoreRemote<A>> {
  const RootRepository(this.remote);

  final R remote;

  @protected
  Future<Result<T, F>> invoke<T, F extends FailureFoundation>({
    required Future<Result<T, F>> Function() onRemote,
  }) {
    return onRemote();
  }

  @protected
  Future<Result<List<T>, F>> invokePaginated<T extends BaseModel, F extends FailureFoundation>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, F>> Function(Map<String, int>) onRemote,
  }) async {
    final unwrapped = controller.unwrapPaginated(await onRemote(controller.paginationParams));
    controller.bumpPage();
    return unwrapped;
  }
}
