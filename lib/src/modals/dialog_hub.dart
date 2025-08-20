// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

import 'package:animations/animations.dart';
import 'package:corekit/src/modals/bottom_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

typedef NavKey = GlobalKey<NavigatorState>;
typedef DialogBuilder = Widget Function(BuildContext, DialogHubCore);

abstract class DialogHubCore {
  DialogHubCore(NavKey navKey) : _navKey = navKey;

  final NavKey _navKey;

  bool _isDialogOpen = false;

  DialogType? _type;

  DialogType? get activeType => _type;

  bool get isDialogOpen => _isDialogOpen;

  Future<T?> show<T>(
    BuildContext context,
    DialogType type, {
    required DialogBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    VoidCallback? onDismiss,
  });

  Future<T?> showCore<T>(
    BuildContext context,
    DialogType type, {
    required DialogBuilder builder,
    required ModalBuilder onModalBuilder,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    VoidCallback? onDismiss,
  }) {
    if (_isDialogOpen) _dismiss();
    _isDialogOpen = true;
    _type = type;

    final config = FadeScaleTransitionConfiguration(
      barrierDismissible: barrierDismissible,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.75),
    );

    final barrierLabel = config.barrierDismissible && config.barrierLabel.isNull
        ? MaterialLocalizations.of(_navState.context).modalBarrierDismissLabel
        : null;

    return _navState.push<T>(
      _DialogRoute(
        parentBuildContext: context,
        onModalBuilder: onModalBuilder,
        dialogHub: this,
        barrierColor: config.barrierColor,
        barrierDismissible: config.barrierDismissible,
        barrierLabel: barrierLabel,
        transitionDuration: config.transitionDuration,
        reverseTransitionDuration: config.reverseTransitionDuration,
        builder: builder,
        transitionBuilder: config.transitionBuilder,
        onDismiss: onDismiss,
      ),
    );
  }

  void dismiss<T>(DialogType type, [T? value]) {
    if (_type == type) {
      _dismiss(value);
      _type = null;
    }
  }

  void _dismiss<T>([T? value]) {
    if (_isDialogOpen) {
      _navState.pop(value);
      _isDialogOpen = false;
      _type = null;
    }
  }

  NavigatorState get _navState {
    final navState = _navKey.currentState;

    assert(navState.isNotNull, 'Navigator not ready to push dialogs');

    return navState!;
  }
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    super.settings,
    super.filter,
    super.traversalEdgeBehavior,
    required this.parentBuildContext,
    required this.barrierColor,
    required this.barrierDismissible,
    required this.barrierLabel,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    required this.builder,
    required this.transitionBuilder,
    required this.onDismiss,
    required this.dialogHub,
    required this.onModalBuilder,
  });

  final BuildContext parentBuildContext;
  final DialogHubCore dialogHub;
  final DialogBuilder builder;
  final VoidCallback? onDismiss;
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) transitionBuilder;
  final ModalBuilder onModalBuilder;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return transitionBuilder(context, animation, secondaryAnimation, child);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> _, Animation<double> __) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (onDismiss.isNull) {
          dialogHub._dismiss();
        } else {
          onDismiss!();
        }
      },
      child: Theme(
        data: Theme.of(parentBuildContext),
        child: onModalBuilder(
          parentBuildContext,
          Center(
            child: builder(context, dialogHub),
          ),
        ),
      ),
    );
  }
}

enum DialogType { progress, normal }
