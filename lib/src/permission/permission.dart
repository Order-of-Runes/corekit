import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rusty_dart/rusty_dart.dart';

/// Requests the permission.
Future<void> requestPermissionCore<E extends Exception>({
  required BuildContext context,
  required Future<Result<bool, E>> Function() onPermission,
  required VoidCallback onGranted,
  required String title,
  required String description,
  VoidCallback? onDenied,
  ValueChanged<E>? onError,
}) async {
  final permissionResult = await onPermission();

  permissionResult.match(
    ok: (status) {
      if (status) return onGranted();

      onDenied?.call();
    },
    err: (failure) => onError?.call(failure),
  );
}
