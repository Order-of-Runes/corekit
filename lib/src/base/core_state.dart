// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

import 'package:foundation/foundation.dart';

abstract class CoreState<E extends Exception> extends StateFoundation {
  const CoreState({
    this.failure,
    this.loading = Loading.inline,
    this.failureDisplay = FailureDisplay.inline,
    String? loadingTitle,
    String? loadingSubtitle,
    this.canDismissLoading = false,
  }) : _loadingTitle = loadingTitle,
       _loadingSubtitle = loadingSubtitle;

  final E? failure;
  final Loading loading;
  final FailureDisplay failureDisplay;
  final String? _loadingTitle;
  final String? _loadingSubtitle;

  /// Can loading be dismissed by the user
  ///
  /// Only applies to [Loading.progressDialog]
  final bool canDismissLoading;

  CoreState setFailure(E failure);

  CoreState setFailureDisplay(FailureDisplay display);

  CoreState setLoading({
    Loading loading = Loading.inline,
    String? title,
    String? subtitle,
    bool canDismissLoading = false,
  });

  @override
  bool get hasFailed => failure != null;

  @override
  bool get isLoading => loading != Loading.none;

  @override
  String? get loadingTitle => _loadingTitle;

  @override
  String? get loadingSubtitle => _loadingSubtitle;
}

/// Dictates how loading should be shown in the UI
/// LoadingDisplay.inline
/// LoadingDisplay.top
enum Loading {
  /// Show loading in the page itself
  ///
  /// For cases when a page itself is not yet ready to display content
  inline,

  /// Show loading at the end of a list
  ///
  /// For cases when pagination is required for a list
  pagination,

  /// Use this for cases when the page is ready and is visible.
  /// If the page is not yet ready or the user needs to be shown that
  /// the page is building, go with [Loading.inline]
  dialog,

  /// No loading is to be shown
  none,
}

/// Dictates how a failure is to be displayed in the UI
/// FailureDisplay.inline
/// FailureDisplay.popup
/// FailureDisplay.snackBar
enum FailureDisplay {
  /// Show failure in a popup modal (Dialog)
  dialog,

  /// Show failure in the page itself
  inline,

  /// Show failure in a snack bar
  snackBar,
}