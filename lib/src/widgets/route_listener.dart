// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:corekit/src/router/router.dart';
import 'package:flutter/material.dart';

class CoreRouteListener extends StatelessWidget {
  const CoreRouteListener({
    super.key,
    required this.builder,
    required this.router,
  });

  final Widget Function(BuildContext, String) builder;
  final RouterCore router;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: router.routeNotifier,
      builder: (context, value, _) {
        return builder(context, value);
      },
    );
  }
}
