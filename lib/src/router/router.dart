// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:corekit/src/foundation/routes_foundation.dart';
import 'package:corekit/src/logcat/logcat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utils/utils.dart';

abstract class RouterCore {
  RouterCore({
    required this.routes,
    String? initialRoute,
    this.redirect,
    this.refreshListenable,
    bool enableLog = false,
  }) : _logcat = Logcat(),
       _initialRoute = initialRoute,
       _enableLog = enableLog;

  late final Logcat _logcat;
  late final GoRouter _goRouter;

  final ValueNotifier<String> routeNotifier = ValueNotifier('/');
  final String? _initialRoute;
  final bool _enableLog;
  final GoRouterRedirect? redirect;
  final Listenable? refreshListenable;
  final List<RouteBase> routes;

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  GoRouter get goRouter => _goRouter;

  bool get canPop => _goRouter.canPop();

  // This is a temporary workaround for returning result from pop
  // Once go_router correctly returns the result revert this change
  Object? _popResult;

  void init() {
    _goRouter =
        GoRouter(
            routes: routes,
            initialLocation: _initialRoute,
            navigatorKey: navKey,
            redirect: redirect,
            refreshListenable: refreshListenable,
          )
          ..routerDelegate.addListener(() {
            routeNotifier.value = location;
          });
  }

  void go(
    RoutesFoundation route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    _log(
      'Go',
      route: route,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    _goRouter.goNamed(
      route.path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  Future<T?> push<T>(
    RoutesFoundation route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    _log(
      'Push',
      route: route,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    await _goRouter.pushNamed(
      route.path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    final result = _popResult as T?;
    _popResult = null;

    return result;
  }

  Future<T?> replace<T>(
    RoutesFoundation route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    _log(
      'Replace',
      route: route,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    await _goRouter.pushReplacementNamed(
      route.path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    final result = _popResult as T?;
    _popResult = null;

    return result;
  }

  void pop<T extends Object?>([T? result]) {
    _log('Pop', result: result);

    _popResult = result;

    _goRouter.pop();
  }

  void addListener(ValueChanged<String> callback) {
    routeNotifier.addListener(() => callback(routeNotifier.value));
  }

  String get location {
    return _goRouter.state.fullPath ?? '/';
  }

  void _log(
    String method, {
    RoutesFoundation? route,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
    Object? result,
  }) {
    if (_enableLog) {
      const loggingName = 'Route';
      if (method.toLowerCase() == 'pop') {
        _logcat.fatal(result ?? '', headers: [loggingName, method]);
      } else {
        _logcat.fatal(route?.path ?? '', headers: [loggingName, method]);
        if (pathParameters.isNotNullAndNotEmpty) {
          _logcat.fatal(pathParameters!, title: 'Path parameters');
        }
        if (queryParameters.isNotNullAndNotEmpty) {
          _logcat.fatal(queryParameters!, title: 'Query parameters');
        }
        if (extra.isNotNull) {
          _logcat.fatal(extra!, title: 'Extra');
        }
      }
    }
  }
}
