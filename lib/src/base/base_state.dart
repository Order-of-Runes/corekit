// Copyright (c) 2024 Order of Runes Authors. All rights reserved.

// ignore_for_file: avoid_positional_boolean_parameters
import 'package:foundation/foundation.dart';

abstract class BaseState extends StateFoundation {
  const BaseState({
    super.failure,
    super.loading = Loading.inline,
    super.failureDisplay = FailureDisplay.inline,
    super.loadingTitle,
    super.loadingSubtitle,
    super.canDismissLoading = false,
  });
}
