// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

class CorekitException implements Exception {
  const CorekitException(
    this.message, {
    this.detail,
    this.stackTrace,
    this.code,
  });

  final String message;
  final String? detail;
  final StackTrace? stackTrace;
  final int? code;
}
