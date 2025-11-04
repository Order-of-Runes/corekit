// Copyright (c) 2025 Order of Runes Authors. All rights reserved.

//ignore_for_file: avoid_positional_boolean_parameters

import 'package:corekit/src/base/core_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnFluxDialog<S extends CoreState> = void Function(S, bool);

/// Wrap your page with Flux to handle your side effects
class FluxCore<VM extends AutoDisposeNotifier<S>, S extends CoreState> extends ConsumerWidget {
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
  final void Function(AutoDisposeNotifier<S>, S) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(provider, (o, n) {
      _onListen(
        onDialog: onDialog,
        onError: (s) => onError(ref.read(provider.notifier), s),
        oldState: o,
        newState: n,
      );
    });

    return builder(context);
  }
}

class StickyFluxCore<VM extends Notifier<S>, S extends CoreState> extends ConsumerWidget {
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
  final void Function(Notifier<S>, S) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(provider, (o, n) {
      _onListen(
        onDialog: onDialog,
        onError: (s) => onError(ref.read(provider.notifier), s),
        oldState: o,
        newState: n,
      );
    });

    return builder(context);
  }
}

void _onListen<S extends CoreState>({
  required OnFluxDialog<S> onDialog,
  required void Function(S) onError,
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
