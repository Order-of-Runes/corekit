// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:corekit/src/foundation/routes_foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:utils/utils.dart';

class CoreRoute extends GoRoute {
  CoreRoute({
    required this.route,
    this.parent,
    super.pageBuilder,
    super.builder,
    super.routes,
    super.redirect,
  }) : super(
         path: route.path,
         name: parent.isNull ? route.path : '${parent!.path}.${route.path}',
       );

  final RoutesFoundation route;
  final RoutesFoundation? parent;
}
