// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/base/base_dao.dart';
import 'package:corekit/src/base/base_model.dart';
import 'package:corekit/src/base/base_remote.dart';
import 'package:corekit/src/base/cache_lifetime/cache_lifetime.dart';
import 'package:corekit/src/base/cache_lifetime/cache_lifetime_model.dart';
import 'package:corekit/src/base/core_list_model.dart';
import 'package:corekit/src/base/core_repository.dart';
import 'package:corekit/src/base/pagination_controller.dart';
import 'package:corekit/src/store/store.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:utils/utils.dart';

typedef RemoteTransformer<R, C> = C Function(R);

class BaseRepository<R extends BaseRemote, D extends CoreDao> extends CoreRepository<R> {
  BaseRepository(super.injector, super.remote, this.dao);

  final D dao;

  CoreStore<CacheLifetimeModel> _cacheLTStore({bool eternal = false}) {
    return eternal ? injector.eternalDatabase.openStore() : injector.database.openStore();
  }

  @protected
  Future<Result<T, FailureFoundation>> resolve<T>({
    required Future<Result<T, FailureFoundation>> Function() onRemote,
    FutureOr<void> Function(T)? onSave,
    FutureOr<Result<T, FailureFoundation>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
  }) {
    return resolveWithTransform(
      onRemote: onRemote,
      onSave: onSave,
      onCache: onCache,
      preferCache: preferCache,
      cacheLifetime: cacheLifetime,
    );
  }

  @protected
  Future<Result<C, FailureFoundation>> resolveWithTransform<T, C>({
    required Future<Result<T, FailureFoundation>> Function() onRemote,
    FutureOr<void> Function(T)? onSave,
    FutureOr<Result<C, FailureFoundation>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
    RemoteTransformer<T, C>? transformer,
  }) async {
    assert((onCache.isNotNull && onSave.isNotNull) || onCache.isNull, 'When [onCache] is passed, [onSave] needs to be passed as well');
    final _EagerCacheResult<T, C> eagerResult;

    if (preferCache) {
      eagerResult = await _onEagerCache<T, C>(onRemote, onCache);
    } else {
      final cacheModel = cacheLifetime.isNull
          ? null
          : (await _cacheLTStore(eternal: cacheLifetime!.eternal).fetchFirst(primaryKey: cacheLifetime.key)).ok;
      final hasCacheExpired = cacheLifetime?.hasExpired(cacheModel?.lifetime) ?? true;

      if (hasCacheExpired && injector.network.isAvailable) {
        eagerResult = _EagerCacheResult.remote(await invoke(onRemote: onRemote));
      } else {
        eagerResult = await _onEagerCache<T, C>(onRemote, onCache);
      }
    }

    if (eagerResult.fromCache) return eagerResult.cache!;

    final remoteResult = eagerResult.remote!;

    return remoteResult.match(
      ok: (value) async {
        if (onSave.isNotNull) {
          await onSave!(value);
          if (cacheLifetime.isNotNull) {
            _cacheLTStore(
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
  Future<Result<List<T>, FailureFoundation>> resolvedPaginated<T extends BaseModel>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, FailureFoundation>> Function(Map<String, int> params) onRemote,
    FutureOr<void> Function(List<T>, {bool clear})? onSave,
    FutureOr<Result<List<T>, FailureFoundation>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
  }) {
    return resolve<List<T>>(
      onRemote: () async {
        final unwrapped = controller.unwrapPaginated(await onRemote(controller.paginationParams));
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
  Future<Result<List<C>, FailureFoundation>> resolvedPaginatedWithTransform<T extends BaseModel, C extends BaseModel>({
    required PaginationController controller,
    required Future<Result<CoreListModel<T>, FailureFoundation>> Function(Map<String, int> params) onRemote,
    FutureOr<void> Function(List<T>, {bool clear})? onSave,
    FutureOr<Result<List<C>, FailureFoundation>> Function()? onCache,
    bool preferCache = false,
    CacheLifetime? cacheLifetime,
    RemoteTransformer<List<T>, List<C>>? transformer,
  }) {
    return resolveWithTransform<List<T>, List<C>>(
      onRemote: () async {
        final unwrapped = controller.unwrapPaginated(await onRemote(controller.paginationParams));
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

  /// Tries with remote if cache does not have data
  Future<_EagerCacheResult<T, C>> _onEagerCache<T, C>(
    Future<Result<T, FailureFoundation>> Function() onRemote,
    FutureOr<Result<C, FailureFoundation>> Function()? onCache,
  ) async {
    final cacheResult = onCache.isNull ? null : (await onCache!());
    final cache = cacheResult?.ok;

    if (cache.isNull) {
      final hasNetwork = injector.network.isAvailable;

      return _EagerCacheResult.remote(
        hasNetwork
            ? (await invoke(onRemote: onRemote))
            : Err(
                const FailureFoundation(
                  'No Internet detected. Please check your internet connection.',
                  source: 'network',
                ),
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

class _EagerCacheResult<T, C> {
  const _EagerCacheResult._({required this.remote, required this.cache});

  factory _EagerCacheResult.remote(Result<T, FailureFoundation> result) {
    return _EagerCacheResult._(remote: result, cache: null);
  }

  factory _EagerCacheResult.cache(Result<C, FailureFoundation> result) {
    return _EagerCacheResult._(remote: null, cache: result);
  }

  final Result<T, FailureFoundation>? remote;
  final Result<C, FailureFoundation>? cache;

  bool get fromCache {
    assert(remote.isNotNull || cache.isNotNull, 'Result from either remote or cache should be provided');
    return cache.isNotNull;
  }
}
