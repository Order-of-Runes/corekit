// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';

mixin PaginationController {
  int _page = 1;
  int _totalPages = 1;

  Result<List<T>, F> unwrapPaginated<T extends BaseModel, F extends FailureFoundation>(
    Result<CoreListModel<T>, F> result,
  ) {
    return result.match(
      ok: (value) {
        _totalPages = value.total;
        return Ok(value.records);
      },
      err: (e) => Err(e),
    );
  }

  bool get canLoadMore => _totalPages >= _page;

  void bumpPage() {
    if (canLoadMore) _page += 1;
  }

  bool get isFirst => _page == 1;

  void reset() {
    _page = 1;
    _totalPages = 0;
  }

  Map<String, int> get paginationParams => {'page': _page};
}
