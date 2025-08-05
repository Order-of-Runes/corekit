// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/api/helper/header_resolver.dart';
import 'package:corekit/src/logcat/logcat.dart';
import 'package:corekit/src/logcat/remote_log.dart';
import 'package:dio/dio.dart';

class DioConsoleLogger extends Interceptor with HeaderResolver {
  DioConsoleLogger({this.logs = RemoteLogs.all}) : _logcat = Logcat();

  final Logcat _logcat;
  final RemoteLogs logs;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logs == RemoteLogs.all || logs == RemoteLogs.request) {
      _logcat.debug(options.uri.toString(), headers: ['Request', options.method]);

      final queryParams = options.queryParameters;
      if (queryParams.isNotEmpty) {
        _logcat.debug(_prepareMap(queryParams), headers: ['Query Parameters']);
      }

      _logcat.debug(_prepareMap(resolveRequestHeaders(options)), headers: ['Headers']);
      final extra = options.extra;
      if (extra.isNotEmpty) {
        _logcat.debug(_prepareMap(extra), headers: ['Extras']);
      }

      if (options.method != 'GET') {
        final data = options.data;
        if (data != null) {
          if (data is Map) {
            _logcat.debug(data);
          } else if (data is FormData) {
            final formDataMap = {}
              ..addEntries(data.fields)
              ..addEntries(data.files);
            if (formDataMap.isNotEmpty) {
              _logcat.debug(_prepareMap(formDataMap), headers: ['Form data', data.boundary]);
            }
          } else {
            _logcat.debug(data);
          }
        }
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logs == RemoteLogs.all || logs == RemoteLogs.response) {
      final uri = response.requestOptions.uri;
      final method = response.requestOptions.method;

      _logcat.warning(uri.toString(), headers: ['Response', method, 'Status [${response.statusCode} | ${response.statusMessage}]']);

      final responseHeaders = <String, String>{};
      response.headers.forEach((k, list) => responseHeaders[k] = list.toString());
      if (responseHeaders.isNotEmpty) {
        _logcat.warning(_prepareMap(responseHeaders), headers: ['Headers']);
      }

      _logcat.warning(response.data ?? 'No Response');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.badResponse) {
      final uri = err.response?.requestOptions.uri;

      _logcat.error(uri.toString(), headers: ['DioException', 'Status [${err.response?.statusCode} | ${err.response?.statusMessage}]']);

      if (err.response != null && err.response!.data != null) {
        _logcat.error(err.response?.data);
      }
    } else {
      _logcat.error(err.message ?? '', headers: ['DioException', err.type.toString()]);
    }
    handler.next(err);
  }

  String _prepareMap(Map<dynamic, dynamic> map) {
    final buffer = StringBuffer();
    for (final entry in map.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString().trimRight();
  }
}
