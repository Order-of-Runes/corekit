// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

import 'dart:async';

import 'package:corekit/src/base/base_state.dart';
import 'package:corekit/src/logcat/logcat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rusty_dart/rusty_dart.dart';
import 'package:utils/utils.dart';

abstract class CoreViewModel<S extends BaseState> extends AutoDisposeNotifier<S> {
  CoreViewModel({this.enableLog = false}) : logcat = Logcat();

  final Logcat logcat;
  final bool enableLog;

  /// Emit states
  @protected
  // ignore: use_setters_to_change_properties
  void emit(S state) {
    this.state = state;
    if (enableLog) {
      logcat.trace(this.state, headers: ['State', runtimeType]);
    }
  }

  /// Run code inside a guarded block
  ///
  /// Any exception thrown inside will be caught and failure would be raised
  ///
  /// If [onError] is provided [Failure] will not be raised
  ///
  /// If [suppress] is provided [Failure] will not be raised,
  /// [onError] will not be triggered
  @protected
  Future<void> runGuarded<E extends Exception>(
    FutureOr<void> Function() block, {
    void Function(E)? onError,
    bool suppress = false,
  }) async {
    try {
      await block();
    } on E catch (f) {
      if (!suppress) {
        if (onError.isNull) _raise(f);
        onError?.call(f);
      }
    }
  }

  /// Set how the raised failure needs to displayed
  @protected
  void setFailureDisplay(FailureDisplay display) {
    emit(state.setFailureDisplay(display) as S);
  }

  /// Emits a [Failure] state based on the condition
  @protected
  bool raise<E extends Exception>(
    E Function() failureBuilder,
    bool Function() block,
  ) {
    if (block()) {
      _raise(failureBuilder());
      return true;
    }
    return false;
  }

  /// Emits a [Failure] state based on the condition
  ///
  /// This is the asynchronous version of [raise]
  @protected
  Future<bool> raiseAsync<E extends Exception>(
    E Function() failureBuilder,
    Future<bool> Function() block,
  ) async {
    if (await block()) {
      _raise(failureBuilder());
      return true;
    }
    return false;
  }

  /// Raises a failure if the supplied [Result] has error
  ///
  /// Returns true if failure is successfully raised
  @protected
  bool raiseIfError<E extends Exception>(
    Result<dynamic, E> result,
  ) {
    return result.match(
      ok: (_) => false,
      err: (error) {
        _raise(error);
        return true;
      },
    );
  }

  /// Raises a failure if the supplied [Result]s hav error
  ///
  /// Returns true if failure is successfully raised
  @protected
  bool raiseIfErrors<E extends Exception>(
    List<Result<dynamic, E>> results,
    E Function(List<E>) onFailure,
  ) {
    final List<E> failures = [];

    for (final result in results) {
      if (result.isErr) {
        failures.add(result.err!);
      }
    }

    if (failures.isEmpty) return false;

    if (failures.length == 1) {
      _raise(failures.first);
    } else {
      _raise(onFailure(failures));
    }

    return failures.isNotEmpty;
  }

  /// Show dialog with loading indicator and label
  @protected
  void showLoadingDialog(String title, [String? subtitle]) {
    assert(title.isNotEmpty, 'Please pass a non empty label to show progress dialog');
    emit(state.setLoading(loading: Loading.dialog, title: title, subtitle: subtitle) as S);
  }

  /// Dismiss the loading
  @protected
  void dismissLoading() {
    emit(state.setLoading(loading: Loading.none) as S);
  }

  /// Register a callback for when
  /// the provider is disposed off
  ///
  /// Prefer disposing off only a single disposable inside this.
  /// Trigger multiple [deferred] for multiple disposables
  @protected
  void deferred(VoidCallback cb) {
    ref.onDispose(cb);
  }

  void _raise(Exception failure) {
    emit(state.setFailure(failure) as S);
  }
}
