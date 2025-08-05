// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:sherlog/sherlog.dart';

// TODO (Ishwor) This seem redundant. Sherlog could be used directly
class Logcat {
  Logcat({
    Map<LogLevel, AnsiColor>? levelColors,
    int lineLength = 100,
    LogLevel level = LogLevel.trace,
  }) : _log = Sherlog(
         lineLength: lineLength,
         levelColors:
             levelColors ??
             {
               LogLevel.trace: AnsiColor.fg(ConsoleColor.green.code),
               LogLevel.debug: const AnsiColor.fg(13),
               LogLevel.info: AnsiColor.fg(ConsoleColor.blue.code),
               LogLevel.warning: AnsiColor.fg(ConsoleColor.orange.code),
               LogLevel.error: AnsiColor.fg(ConsoleColor.red.code),
               LogLevel.fatal: AnsiColor.fg(ConsoleColor.magenta.code),
             },
         level: level,
       );

  final Sherlog _log;

  void trace(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.trace(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void debug(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.debug(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void info(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.info(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void warning(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.warning(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void error(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.error(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void fatal(
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.fatal(message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }

  void log(
    LogLevel level,
    Object message, {
    List<Object> headers = const [],
    String? title,
    Object? detail,
    StackTrace? stackTrace,
    bool showSource = false,
  }) {
    _log.log(level, message, headers: headers, title: title, detail: detail, stackTrace: stackTrace, showSource: showSource);
  }
}
