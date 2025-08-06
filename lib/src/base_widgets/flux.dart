// Copyright (c) 2025 EShare Authors. All rights reserved.

//ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';

typedef OnFluxDialog<S extends StateFoundation> = void Function(S, bool);
typedef OnFluxError<S extends StateFoundation> = void Function(S);

/// Wrap your page with Flux to handle your side effects
class FluxCore<VM extends ViewModelFoundation<S>, S extends StateFoundation> extends StatelessWidget {
  const FluxCore({
    super.key,
    required this.provider,
    required this.builder,
    required this.onDialog,
    required this.onError,
  });

  final AutoDisposeNotifierProvider<VM, S> provider;
  final WidgetBuilder builder;
  final OnFluxDialog<S> onDialog;
  final OnFluxError<S> onError;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(provider, (o, n) {
          _onListen(
            onDialog: onDialog,
            onError: onError,
            oldState: o,
            newState: n,
          );
        });
        return builder(context);
      },
    );
  }
}

class StickyFluxCore<VM extends StickyViewModelFoundation<S>, S extends StateFoundation> extends StatelessWidget {
  const StickyFluxCore({
    super.key,
    required this.provider,
    required this.builder,
    required this.onDialog,
    required this.onError,
  });

  final NotifierProvider<VM, S> provider;
  final WidgetBuilder builder;
  final OnFluxDialog<S> onDialog;
  final OnFluxError<S> onError;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(provider, (o, n) {
          _onListen(
            onDialog: onDialog,
            onError: onError,
            oldState: o,
            newState: n,
          );
        });
        return builder(context);
      },
    );
  }
}

void _onListen<S extends StateFoundation>({
  required OnFluxDialog<S> onDialog,
  required OnFluxError<S> onError,
  required S? oldState,
  required S newState,
}) {
  if (oldState != newState) {
    if (newState.loading == Loading.dialog) {
      onDialog(newState, true);
    } else {
      onDialog(newState, false);
    }

    if (newState.hasFailed) {
      onError(newState);
    }
  }
}
