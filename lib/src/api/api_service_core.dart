// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/foundation/api_url_foundation.dart';
import 'package:corekit/src/foundation/url_prefix_foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:utils/utils.dart';

typedef OnApiError = F Function<F extends FailureFoundation>(Map<String, dynamic>);

abstract class ApiServiceCore {
  ApiServiceCore({
    required String baseUrl,
    List<Interceptor>? interceptors,
  }) {
    const timeout = Duration(minutes: 1);
    const receiveTimeout = Duration(minutes: 5);
    final baseOptions = BaseOptions(
      baseUrl: baseUrl,
      receiveTimeout: timeout,
      connectTimeout: receiveTimeout,
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    );
    _dio = Dio();

    if (interceptors.isNotNullAndNotEmpty) {
      _dio.interceptors.addAll(interceptors!);
    }

    _dio.options = baseOptions;
    cancelToken ??= CancelToken();
  }

  CancelToken? cancelToken;

  String get baseUrl => _dio.options.baseUrl;

  set baseUrl(String url) => _dio.options.baseUrl = url;

  late Dio _dio;

  /// To set independent scenarios for different api
  final Map<ApiUrlFoundation, String> _testScenarios = {};

  /// This field is exclusively for tests
  ///
  /// To set independent scenarios for different api
  ///
  /// In Mockoon, provide a header with key `s` and value from
  @visibleForTesting
  void setScenario({required ApiUrlFoundation url, required String scenario}) {
    _testScenarios[url] = scenario;
  }

  Future<Result<Response<Object?>, F>> request<T, F extends FailureFoundation>({
    required RestMethod method,
    required ApiUrlFoundation url,
    required Options options,
    String contentType = Headers.jsonContentType,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? pathParams,
    UrlPrefixFoundation? prefix,
    ProgressCallback? onSendProgress,
    bool isTest = false,
    OnApiError? onError,
  }) async {
    if (cancelToken?.isCancelled ?? false) cancelToken = CancelToken();

    final path = _updatePath(url, pathParams, prefix);
    try {
      final scenario = isTest ? _testScenarios[url] : null;
      _testScenarios.remove(url);
      final _options = options.copyWith(
        headers: {
          if (options.headers.isNotNullAndNotEmpty) ...options.headers!,
          if (scenario.isNotNullAndNotEmpty) 's': scenario,
        },
        method: method.name,
        contentType: contentType,
      );

      return Ok(
        await _dio.request<Object>(
          path,
          data: data,
          options: _options,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
        ),
      );
    } on DioException catch (e, s) {
      return Err(_mapDioException<F>(e, s, onError));
    }
  }

  F _mapDioException<F extends FailureFoundation>(
    DioException exception,
    StackTrace stackTrace,
    OnApiError? onError,
  ) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const FailureFoundation(
          'Connection Timeout',
          source: 'connectionTimeout',
          detail: 'There was a problem while completing your request. Please try again later.',
        ) as F;
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        if (statusCode == 500 || statusCode == 503) {
          return FailureFoundation(
            'Internal server error',
            detail: 'The server encountered an error & was unable to complete your request. Please try again later.',
            source: 'api',
            code: double.tryParse(statusCode?.toString() ?? '500'),
          ) as F;
        }

        final data = exception.response?.data;
        if (data == null || (statusCode == 404 && data == null)) {
          return const FailureFoundation(
            'No Data',
            detail: _genericErrorMessage,
            code: 404,
            source: 'api',
          ) as F;
        }

        if (data is String) {
          return FailureFoundation(
            exception.message ?? '',
            detail: data,
            source: 'api',
          ) as F;
        }

        if (data is Map<String, dynamic> && onError.isNotNull) return onError!(data);

        return const FailureFoundation(_genericErrorMessage, source: 'api') as F;

      case DioExceptionType.cancel:
        return const FailureFoundation('Request Cancelled', code: 100, source: 'cancel') as F;
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final _error = exception.error;

        return FailureFoundation(
          _error.toString(),
          detail: _error.toString(),
          stackTrace: stackTrace,
          source: 'network',
        ) as F;
    }
  }

  String _updatePath(
    ApiUrlFoundation url,
    Map<String, String>? pathParams,
    UrlPrefixFoundation? prefix,
  ) {
    final updatedPath = pathParams.isNullOrEmpty
        ? url.path
        : url.path.fillInUrl(
            keyValues: pathParams!,
          );

    final resolvedPrefix = prefix.isNull ? '' : '${prefix!.path}/';

    return Uri.parse(updatedPath).hasScheme ? updatedPath : '$resolvedPrefix$updatedPath';
  }
}

enum RestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const RestMethod(this.name);

  final String name;
}

const _genericErrorMessage = 'We were unable to complete your request. Please try again later.';
