// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

class RequestLog extends NetworkLog {
  const RequestLog({
    required super.headers,
    required super.uri,
    required super.method,
    required super.payload,
    this.queryParameters = const {},
    this.extras = const {},
  });

  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> extras;
}

class ResponseLog extends NetworkLog {
  const ResponseLog({
    required super.headers,
    required super.uri,
    required super.method,
    required super.payload,
    this.statusCode,
    this.statusMessage,
    this.isError = false,
  });

  final int? statusCode;
  final String? statusMessage;
  final bool isError;
}

class NetworkLog {
  const NetworkLog({
    required this.headers,
    required this.uri,
    required this.method,
    required this.payload,
  });

  final Uri? uri;
  final String method;
  final Map<String, dynamic> headers;
  final Map payload;
}
