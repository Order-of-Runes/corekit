// Copyright (c) 2025 EShare Authors. All rights reserved.

import 'dart:convert';

import 'package:better_components/better_components.dart';
import 'package:corekit/src/api/helper/network_log.dart';
import 'package:corekit/src/api/interceptors/dio_memory_logger.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

const double _small = 16;
const double _smallX = 12;
const double _smallXX = 8;
const double _smallXXX = 4;
const double _small4X = 2;
const double _medium = 20;
const double _mediumXXX = 40;

class NetworkLogPage extends StatelessWidget {
  const NetworkLogPage({
    super.key,
    required this.logger,
  });

  final DioMemoryLogger logger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final color = theme.colorScheme;
    final responses = logger.responses.reversed.toList(growable: false);

    return ListView.separated(
      itemBuilder: (context, index) {
        final response = responses[index];
        final request = logger.getRequest(response.uri?.toString() ?? '');
        return InkWell(
          onTap: () {
            if (response.isNotNull) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return _NetworkLogDetail(
                      request: request,
                      response: response,
                    );
                  },
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(_small),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_smallXXX),
                    border: Border.all(color: color.onSurface),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _smallXXX),
                    child: Text(response.method, style: textTheme.labelMedium),
                  ),
                ),
                const HorizontalGap(_medium),
                Expanded(child: Text(response.uri?.toString() ?? '', style: textTheme.bodyMedium)),
                const HorizontalGap(_medium),
                _Status(code: response.statusCode ?? 0),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return const Divider(height: 0);
      },
      itemCount: responses.length,
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.code, this.message});

  final int code;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(code);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(_small4X),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _smallXXX),
        child: Text(
          '$code${message.isNullOrEmpty ? '' : ' $message'}',
          style: textTheme.labelMedium!.copyWith(color: statusColor),
        ),
      ),
    );
  }

  Color getStatusColor(int code) {
    if (code >= 100 && code < 200) {
      return Colors.indigo;
    } else if (code >= 200 && code < 300) {
      return Colors.green.shade700;
    } else if (code >= 300 && code < 400) {
      return Colors.cyan;
    } else if (code >= 400 && code < 500) {
      return Colors.orange.shade700;
    } else if (code >= 500 && code < 600) {
      return Colors.red.shade600;
    } else {
      return Colors.black; // Unknown
    }
  }
}

class _NetworkLogDetail extends StatelessWidget {
  const _NetworkLogDetail({required this.request, required this.response});

  final RequestLog? request;
  final ResponseLog response;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(_mediumXXX),
            child: TabBar(
              tabs: [
                Tab(text: 'Request'),
                Tab(text: 'Response'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _RequestDetail(log: request),
            _ResponseDetail(log: response),
          ],
        ),
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.log});

  final RequestLog? log;

  @override
  Widget build(BuildContext context) {
    if (log.isNull) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(_small),
      children: [
        _Box(label: log!.method, child: Text(log!.uri.toString())),
        const VerticalGap(),
        _Box(
          label: 'Query Parameters',
          child: _Map(map: log!.queryParameters),
        ),
        const VerticalGap(),
        _Box(
          label: 'Headers',
          child: _Map(map: log!.headers),
        ),
        const VerticalGap(),
        _Box(
          label: 'Extras',
          child: _Map(map: log!.extras),
        ),
        const VerticalGap(),
        _Box(label: 'Payload', child: Text(_toJson(log!.payload))),
      ],
    );
  }
}

class _ResponseDetail extends StatelessWidget {
  const _ResponseDetail({required this.log});

  final ResponseLog log;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(_small),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _Status(code: log.statusCode ?? 0, message: log.statusMessage),
        ),
        const VerticalGap(),
        _Box(label: log.method, child: Text(log.uri.toString())),
        const VerticalGap(),
        _Box(
          label: 'Headers',
          child: _Map(map: log.headers),
        ),
        const VerticalGap(),
        _Box(label: 'Payload', child: Text(_toJson(log.payload))),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final color = theme.colorScheme;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_smallXXX),
              border: Border.all(color: color.onSurface),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_smallXX, _smallX, _smallXX, _smallXXX),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
        Positioned(
          left: _smallXX,
          child: ColoredBox(
            color: color.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _smallXXX),
              child: Text(label, style: textTheme.labelMedium),
            ),
          ),
        ),
      ],
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.map});

  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      spacing: _smallXX,
      children: map.entries
          .map((entry) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: Text('${entry.key}:', style: textTheme.bodyMedium)),
                const HorizontalGap(),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.value.toString(),
                    style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

String _toJson(Map<dynamic, dynamic> map) {
  return const JsonEncoder.withIndent(' ').convert(map);
}
