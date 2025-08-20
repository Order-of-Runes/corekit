// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/api/helper/header_resolver.dart';
import 'package:corekit/src/api/helper/network_log.dart';
import 'package:dio/dio.dart';

class DioMemoryLogger extends Interceptor with HeaderResolver {
  final Map<String, RequestLog> _requestLogs = {};
  final Map<String, ResponseLog> _responseLogs = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method;
    final uri = options.uri;
    final queryParams = options.queryParameters;
    final headers = resolveRequestHeaders(options);
    final extras = options.extra;
    final Map payload = {};

    if (options.method != 'GET') {
      final data = options.data;
      if (data != null) {
        if (data is Map) {
          payload.addAll(data);
        } else if (data is FormData) {
          final formDataMap = {}
            ..addEntries(data.fields)
            ..addEntries(data.files);

          payload.addAll(formDataMap);
        } else {
          payload['resolvedResponse'] = data.toString();
        }
      }
    }
    _requestLogs.remove(uri.toString());
    _requestLogs[uri.toString()] = RequestLog(
      headers: headers,
      uri: uri,
      method: method,
      payload: payload,
      extras: extras,
      queryParameters: queryParams,
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final uri = response.requestOptions.uri;
    final Map payload = {};

    final responseHeaders = <String, String>{};
    response.headers.forEach((k, list) => responseHeaders[k] = list.toString());

    if (response.data != null) {
      if (response.data is Map) {
        payload.addAll(response.data);
      } else {
        payload['resolvedResponse'] = response.data.toString();
      }
    } else {
      payload['resolvedResponse'] = 'No Response';
    }
    _responseLogs.remove(uri.toString());
    _responseLogs[uri.toString()] = ResponseLog(
      headers: responseHeaders,
      uri: uri,
      method: response.requestOptions.method,
      payload: payload,
      isError: false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = err.response?.requestOptions.uri;
    final Map payload = {};

    if (err.response != null && err.response!.data != null) {
      if (err.response!.data is Map) {
        payload.addAll(err.response!.data);
      } else {
        payload['resolvedResponse'] = err.response!.data.toString();
      }
    }

    _responseLogs.remove(uri?.toString());
    _responseLogs[uri?.toString() ?? ''] = ResponseLog(
      headers: {},
      uri: uri,
      method: err.requestOptions.method,
      payload: payload,
      isError: true,
      statusMessage: err.response?.statusMessage,
      statusCode: err.response?.statusCode,
    );

    handler.next(err);
  }

  List<ResponseLog> get responses => _responseLogs.values.toList(growable: false);

  RequestLog? getRequest(String url) => _requestLogs[url];

  ResponseLog? getResponse(String url) => _responseLogs[url];

  void clear() {
    _requestLogs.clear();
    _responseLogs.clear();
  }
}
