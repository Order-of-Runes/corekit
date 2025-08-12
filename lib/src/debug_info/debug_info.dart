// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'package:basic_components/basic_components.dart';
import 'package:corekit/corekit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _small = 16;
const double _smallX = 12;
const double _smallXX = 8;
const double _smallXXX = 4;
const double _small4X = 2;
const double _medium = 20;
const double _mediumX = 24;

class DebugInfo extends StatefulWidget {
  const DebugInfo({
    required this.ref,
    required this.child,
    required this.bannerColor,
    required this.flavor,
    required this.bannerLabel,
    required this.router,
    required this.baseUrlResolver,
    required this.networkLogPageBuilder,
    this.shouldShow = false,
    this.isToggleable = false,
    this.isDevFlavor = false,
    this.showAddressBar = false,
  });

  final WidgetRef ref;
  final Widget child;
  final String flavor;
  final String bannerLabel;
  final Color bannerColor;
  final bool shouldShow;
  final bool isToggleable;
  final bool isDevFlavor;
  final bool showAddressBar;
  final RouterCore router;
  final String Function(String) baseUrlResolver;
  final WidgetBuilder networkLogPageBuilder;

  @override
  State<DebugInfo> createState() => _DebugInfoState();
}

class _DebugInfoState extends State<DebugInfo> {
  late bool isVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final color = theme.colorScheme;
    final showDebugInfo = widget.shouldShow;

    if (!showDebugInfo) return widget.child;

    final flavorTextStyle = textTheme.labelMedium!.copyWith(color: widget.bannerColor);
    final toggleable = widget.isToggleable;

    final flavorTextWidget = Text(widget.flavor, style: flavorTextStyle);

    final flavorBox = Material(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: widget.networkLogPageBuilder,
            ),
          );
        },
        borderRadius: BorderRadius.circular(_smallXX),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.bannerColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(_smallXX),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _smallXXX),
            child: widget.isDevFlavor
                ? Row(
                    children: [
                      flavorTextWidget,
                      SizedBox(
                        height: _medium,
                        child: VerticalDivider(
                          width: _smallXX,
                          thickness: _small4X,
                          color: color.surface,
                        ),
                      ),
                      Text(widget.bannerLabel, style: flavorTextStyle),
                    ],
                  )
                : flavorTextWidget,
          ),
        ),
      ),
    );

    final body = Column(
      children: [
        Expanded(child: widget.child),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          child: isVisible || !toggleable
              ? ColoredBox(
                  color: color.surface,
                  child: CoreRouteListener(
                    builder: (context, route) {
                      return Column(
                        children: [
                          Divider(
                            height: 1,
                            color: color.onSurfaceVariant.withValues(alpha: 0.03),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(_smallXXX),
                            child: Row(
                              children: [
                                const HorizontalGap(),
                                Expanded(
                                  child: Text(
                                    widget.baseUrlResolver(route),
                                    style: textTheme.labelMedium,
                                  ),
                                ),
                                const HorizontalGap(),
                                if (toggleable && !widget.showAddressBar)
                                  Padding(
                                    padding: const EdgeInsets.only(right: _smallX),
                                    child: flavorBox,
                                  )
                                else
                                  flavorBox,
                                const HorizontalGap(),
                              ],
                            ),
                          ),
                          if (widget.showAddressBar)
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(_small4X, 0, _small4X, _small4X),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color.onSurfaceVariant.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(_smallXXX),
                                  ),
                                  child: Padding(
                                    padding: toggleable
                                        ? const EdgeInsets.symmetric(
                                            vertical: _smallXXX,
                                            horizontal: _smallXX,
                                          )
                                        : const EdgeInsets.fromLTRB(
                                            _smallXX,
                                            _smallXXX,
                                            _small,
                                            _smallXXX,
                                          ),
                                    child: Text(route, style: textTheme.labelMedium),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    router: widget.router,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );

    if (!toggleable) return body;

    return Stack(
      children: [
        body,
        Positioned(
          right: -20,
          bottom: -20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: color.onSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_mediumX)),
            onPressed: () {
              setState(() {
                isVisible = !isVisible;
              });
            },
            child: Transform.translate(
              offset: const Offset(-7, -9),
              child: Icon(Icons.adb, color: color.surface, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
