/*
 * Copyright (c) 2023-2024. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:io';

import 'package:common/util/extensions/provider_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stringr/stringr.dart';
import 'package:talker_flutter/talker_flutter.dart';

late final Talker logger;

Future<void> setupLogger() async {
  var level = LogLevel.debug;
  var loggerSettings = TalkerLoggerSettings(level: level);
  logger = TalkerFlutter.init(
    logger: TalkerLogger(
      // filter: LogLevelFilter(LogLevel.verbose),
      settings: loggerSettings,
    ),
  );
}

bool _isolateLoggerAvailable = false;

Future<void> setupIsolateLogger() async {
  if (_isolateLoggerAvailable) return;
  _isolateLoggerAvailable = true;
  logger = TalkerFlutter.init();
}

Future<Directory> logFileDirectory() async {
  final temporaryDirectory = await getApplicationSupportDirectory();
  return Directory('${temporaryDirectory.path}/logs').create(recursive: true);
}

String _logFileTimestamp() {
  final now = DateTime.now();
  var format = DateFormat('yyyy-MM-ddTHH-mm-ss').format(now);
  return format;
}

class RiverPodLogger extends ProviderObserver {
  const RiverPodLogger();

  @override
  void providerDidFail(ProviderBase provider, Object error, StackTrace stackTrace, ProviderContainer container) {
    logger.error('[RiverPodLogger]::FAILED ${provider.toIdentityString()} failed with', error, stackTrace);
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (['toolheadInfoProvider'].contains(provider.name)) return;

    var familiy = provider.from?.toString() ?? '';
    logger.verbose('[RiverPodLogger]::DISPOSED: ${provider.toIdentityString()} $familiy');
    //
    // if (provider.name == 'klipperServiceProvider') {
    //   logger.verbose('RiverPod::klipperServiceProvider:  ${container}');
    // }
  }

  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    logger.verbose('[RiverPodLogger]::CREATED-> ${provider.toIdentityString()} WITH PARENT? ${container.depth}');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (![
      '_jsonRpcClientProvider',
      'jrpcClientProvider',
      'machineProvider',
      'klipperSelectedProvider',
      'selectedMachineProvider',
      '_jsonRpcStateProvider',
      // 'machinePrinterKlippySettingsProvider',
    ].contains(provider.name)) return;

    var familiy = provider.argument?.toString() ?? '';
    var providerStr = '${provider.name ?? provider.runtimeType}#${identityHashCode(provider)}$familiy';

    logger.verbose(
        '[RiverPodLogger]::UPDATE-old-> $providerStr ${identityHashCode(previousValue)}:${previousValue.toString().truncate(200)}');
    logger.verbose(
        '[RiverPodLogger]::UPDATE-new->$providerStr ${identityHashCode(newValue)}:${newValue.toString().truncate(200)}');
  }
}

class _JrpcLog extends TalkerLog {
  _JrpcLog(this.type, this.con, AnsiPen pen, LogLevel level, String message)
      : super(message, pen: pen, logLevel: level);

  final String type;
  final String con;

  /// Your custom log title
  @override
  String get title => '$type.jRPC@$con';
}

extension MobilerakerTalker on Talker {
  void jrpcInfo(String connectionInfo, String msg) {
    logTyped(_JrpcLog('I', connectionInfo, AnsiPen()..blue(), LogLevel.info, msg));
  }

  void jrpcWarning(String connectionInfo, String msg) {
    logTyped(_JrpcLog('W', connectionInfo, AnsiPen()..yellow(), LogLevel.warning, msg));
  }

  void jrpcError(String connectionInfo, String msg) {
    logTyped(_JrpcLog('E', connectionInfo, AnsiPen()..red(), LogLevel.error, msg));
  }

  void jrpcRequest(String connectionInfo, String msg) {
    logTyped(_JrpcLog('REQ', connectionInfo, AnsiPen()..cyan(), LogLevel.verbose, msg));
  }

  void jrpcReceive(String connectionInfo, String msg) {
    logTyped(_JrpcLog('RECV', connectionInfo, AnsiPen()..yellow(), LogLevel.verbose, msg));
  }
}
