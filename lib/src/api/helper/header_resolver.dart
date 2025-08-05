// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:dio/dio.dart';

mixin HeaderResolver on Interceptor {
  Map<String, dynamic> resolveRequestHeaders(RequestOptions options) {
    final requestHeaders = Map.of(options.headers);
    requestHeaders['contentType'] = options.contentType?.toString();
    requestHeaders['responseType'] = options.responseType.toString();
    requestHeaders['followRedirects'] = options.followRedirects;
    requestHeaders['connectTimeout'] = options.connectTimeout;
    requestHeaders['receiveTimeout'] = options.receiveTimeout;

    return requestHeaders;
  }
}
