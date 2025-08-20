// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/api/api_service_core.dart';
import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/cache_lifetime/cache_lifetime.dart';
import 'package:corekit/src/base/cache_lifetime/cache_lifetime_model.dart';
import 'package:corekit/src/base/core_dao.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:corekit/src/base/core_remote.dart';
import 'package:corekit/src/base/pagination_controller.dart';
import 'package:corekit/src/base/root_repository.dart';
import 'package:corekit/src/store/store.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:utils/utils.dart';

typedef RemoteTransformer<R, C> = C Function(R);

abstract class CoreRepository<A extends ApiServiceCore, R extends CoreRemote<A>, D extends CoreDao> extends RootRepository<A, R> {
  const CoreRepository(super.remote, this.dao);

  final D dao;

  CoreStore<CacheLifetimeModel> getCacheLTStore({bool eternal = false});

  @protected
  Future<Result<T, F>> resolve<T, F extends FailureFoundation>({
    required Future<Result<T, F>> Function() onRemote,
    FutureOr<void> Function(T)? onSave,
    FutureOr<Result<T, F>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
  }) {
    return resolveWithTransform<T, T, F>(
      onRemote: onRemote,
      onSave: onSave,
      onCache: onCache,
      preferCache: preferCache,
      cacheLifetime: cacheLifetime,
    );
  }

  @protected
  Future<Result<C, F>> resolveWithTransform<T, C, F extends FailureFoundation>({
    required Future<Result<T, F>> Function() onRemote,
    FutureOr<void> Function(T)? onSave,
    FutureOr<Result<C, F>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
    RemoteTransformer<T, C>? transformer,
  }) async {
    assert((onCache.isNotNull && onSave.isNotNull) || onCache.isNull, 'When [onCache] is passed, [onSave] needs to be passed as well');
    final _EagerCacheResult<T, C, F> eagerResult;

    if (preferCache) {
      eagerResult = await _onEagerCache<T, C, F>(onRemote, onCache);
    } else {
      final cacheModel = cacheLifetime.isNull
          ? null
          : (await getCacheLTStore(eternal: cacheLifetime!.eternal).fetchFirst(primaryKey: cacheLifetime.key)).ok;
      final hasCacheExpired = cacheLifetime?.hasExpired(cacheModel?.lifetime) ?? true;

      if (hasCacheExpired && isNetworkAvailable) {
        eagerResult = _EagerCacheResult.remote(await invoke(onRemote: onRemote));
      } else {
        eagerResult = await _onEagerCache<T, C, F>(onRemote, onCache);
      }
    }

    if (eagerResult.fromCache) return eagerResult.cache!;

    final remoteResult = eagerResult.remote!;

    return remoteResult.match(
      ok: (value) async {
        if (onSave.isNotNull) {
          await onSave!(value);
          if (cacheLifetime.isNotNull) {
            getCacheLTStore(
              eternal: cacheLifetime!.eternal,
            ).insert([CacheLifetimeModel(key: cacheLifetime.key, lifetime: cacheLifetime.timeStamp)]);
          }
        }

        if (onCache.isNull) {
          return Ok(_transformRemote(value, transformer));
        }

        return onCache!();
      },
      err: Err.new,
    );
  }

  @protected
  Future<Result<List<T>, F>> resolvedPaginated<T extends BaseModel, F extends FailureFoundation>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, F>> Function(Map<String, int> params) onRemote,
    FutureOr<void> Function(List<T>, {bool clear})? onSave,
    FutureOr<Result<List<T>, F>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
  }) {
    return resolve<List<T>, F>(
      onRemote: () async {
        final unwrapped = controller.unwrapPaginated<T, F>(await onRemote(controller.paginationParams));
        if (onSave.isNull) controller.bumpPage();
        return unwrapped;
      },
      onSave: onSave.isNull
          ? null
          : (results) async {
              await onSave!(results, clear: controller.isFirst);
              controller.bumpPage();
            },
      onCache: onCache,
      preferCache: preferCache,
      cacheLifetime: cacheLifetime,
    );
  }

  @protected
  Future<Result<List<C>, F>> resolvedPaginatedWithTransform<T extends BaseModel, C extends BaseModel, F extends FailureFoundation>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, F>> Function(Map<String, int> params) onRemote,
    FutureOr<void> Function(List<T>, {bool clear})? onSave,
    FutureOr<Result<List<C>, F>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
    RemoteTransformer<List<T>, List<C>>? transformer,
  }) {
    return resolveWithTransform<List<T>, List<C>, F>(
      onRemote: () async {
        final unwrapped = controller.unwrapPaginated<T, F>(await onRemote(controller.paginationParams));
        if (onSave.isNull) controller.bumpPage();
        return unwrapped;
      },
      onSave: onSave.isNull
          ? null
          : (results) async {
              await onSave!(results, clear: controller.isFirst);
              controller.bumpPage();
            },
      onCache: onCache,
      preferCache: preferCache,
      cacheLifetime: cacheLifetime,
      transformer: transformer,
    );
  }

  @protected
  bool get isNetworkAvailable;

  /// Tries with remote if cache does not have data
  Future<_EagerCacheResult<T, C, F>> _onEagerCache<T, C, F extends FailureFoundation>(
    Future<Result<T, F>> Function() onRemote,
    FutureOr<Result<C, F>> Function()? onCache,
  ) async {
    final cacheResult = onCache.isNull ? null : (await onCache!());
    final cache = cacheResult?.ok;

    if (cache.isNull) {
      return _EagerCacheResult.remote(
        isNetworkAvailable
            ? (await invoke(onRemote: onRemote))
            : Err(
                const FailureFoundation(
                      'No Internet detected. Please check your internet connection.',
                      source: 'network',
                    )
                    as F,
              ),
      );
    }

    return _EagerCacheResult.cache(Ok(cache!));
  }

  C _transformRemote<T, C>(T result, RemoteTransformer<T, C>? transformer) {
    if (T == C) {
      return result as C;
    }

    assert(transformer.isNotNull, 'A transformer needs to be supplied. Expected return type $C but found $T');

    return transformer!(result);
  }
}

class _EagerCacheResult<T, C, F extends FailureFoundation> {
  const _EagerCacheResult._({
    required this.remote,
    required this.cache,
  });

  factory _EagerCacheResult.remote(Result<T, F> result) {
    return _EagerCacheResult._(
      remote: result,
      cache: null,
    );
  }

  factory _EagerCacheResult.cache(Result<C, F> result) {
    return _EagerCacheResult._(
      remote: null,
      cache: result,
    );
  }

  final Result<T, F>? remote;
  final Result<C, F>? cache;

  bool get fromCache {
    assert(remote.isNotNull || cache.isNotNull, 'Result from either remote or cache should be provided');
    return cache.isNotNull;
  }
}
