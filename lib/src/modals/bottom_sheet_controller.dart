// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

typedef ModalBuilder = Widget Function(BuildContext, Widget);

Future<T?> showModalSheetCore<T>(
  BuildContext baseContext, {
  required WidgetBuilder builder,
  required ModalBuilder onModalBuilder,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
}) {
  return _showSheet<T>(
    baseContext,
    onModalBuilder: onModalBuilder,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    isScrolledControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    builder: builder,
    draggableBuilder: null,
    isDraggable: false,
    initialChildSize: 1,
    minChildSize: 0,
    maxChildSize: 1,
    expandDraggableSheet: false,
    snapDraggableSheet: false,
    shouldCloseDraggableSheetOnMinExtent: false,
    draggableSheetSnapSizes: null,
    draggableSheetSnapAnimationDuration: null,
    controller: null,
    elevation: elevation,
  );
}

Future<T?> showDraggableSheetCore<T>(
  BuildContext baseContext, {
  required ScrollableWidgetBuilder builder,
  required ModalBuilder onModalBuilder,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool isScrolledControlled = true,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 1.0,
  bool expand = false,
  bool snap = false,
  List<double>? snapSizes,
  DraggableScrollableController? controller,
  bool shouldCloseOnMinExtent = true,
  Duration? snapAnimationDuration,
  double? elevation,
}) {
  return _showSheet<T>(
    baseContext,
    onModalBuilder: onModalBuilder,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    isScrolledControlled: isScrolledControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    builder: null,
    draggableBuilder: builder,
    isDraggable: true,
    initialChildSize: initialChildSize,
    minChildSize: minChildSize,
    maxChildSize: maxChildSize,
    expandDraggableSheet: expand,
    controller: controller,
    draggableSheetSnapAnimationDuration: snapAnimationDuration,
    draggableSheetSnapSizes: snapSizes,
    shouldCloseDraggableSheetOnMinExtent: shouldCloseOnMinExtent,
    snapDraggableSheet: snap,
    elevation: elevation,
  );
}

Future<T?> _showSheet<T>(
  BuildContext baseContext, {
  required ModalBuilder onModalBuilder,
  required bool showDragHandle,
  required bool isDismissible,
  required bool isScrolledControlled,
  required bool useRootNavigator,
  required bool useSafeArea,
  required bool enableDrag,
  required Color? backgroundColor,
  required WidgetBuilder? builder,
  required ScrollableWidgetBuilder? draggableBuilder,
  required bool isDraggable,
  required double initialChildSize,
  required double minChildSize,
  required double maxChildSize,
  required bool expandDraggableSheet,
  required bool snapDraggableSheet,
  required List<double>? draggableSheetSnapSizes,
  required DraggableScrollableController? controller,
  required shouldCloseDraggableSheetOnMinExtent,
  required Duration? draggableSheetSnapAnimationDuration,
  required double? elevation,
}) {
  return showModalBottomSheet<T>(
    context: baseContext,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrolledControlled,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    enableDrag: enableDrag,
    elevation: elevation,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(baseContext),
      duration: const Duration(milliseconds: 300),
    )..forward(),
    builder: (context) {
      assert(builder.isNotNull || draggableBuilder.isNotNull);

      return onModalBuilder(
        baseContext,
        AnimatedBuilder(
          animation: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeInOut,
          ),
          builder: (context, _) {
            final body = isDraggable
                ? DraggableScrollableSheet(
                    expand: expandDraggableSheet,
                    initialChildSize: initialChildSize,
                    minChildSize: minChildSize,
                    maxChildSize: maxChildSize,
                    builder: draggableBuilder!,
                    snap: snapDraggableSheet,
                    controller: controller,
                    snapSizes: draggableSheetSnapSizes,
                    shouldCloseOnMinExtent: shouldCloseDraggableSheetOnMinExtent,
                    snapAnimationDuration: draggableSheetSnapAnimationDuration,
                  )
                : builder!(context);

            final child = SafeArea(
              bottom: useSafeArea,
              child: SizedBox(width: double.infinity, child: body),
            );

            if (backgroundColor.isNull) return child;

            return ColoredBox(color: backgroundColor!, child: child);
          },
        ),
      );
    },
  );
}
