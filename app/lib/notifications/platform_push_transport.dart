/// Production [PushTransport] backed by the native Android push bridge.
///
/// The native host (task `11` wires the live Firebase project) implements
/// these channels; the exact contract is documented in
/// `docs/notifications/ANDROID_PUSH_SETUP.md`:
///
/// ```text
/// MethodChannel  app.trainingarena.mobile/push
///   permissionStatus() -> "granted" | "denied" | "notDetermined"
///   requestPermission() -> "granted" | "denied" | "notDetermined"
///   deviceToken() -> String?                 (never passed back to Dart logs)
///   initialTap() -> Map?                     (cold-start tap payload)
///   dispose() -> null
///
/// EventChannel   app.trainingarena.mobile/push/messages  (foreground data)
/// EventChannel   app.trainingarena.mobile/push/taps      (warm taps)
/// EventChannel   app.trainingarena.mobile/push/tokens    (token rotation)
/// ```
///
/// Every platform failure degrades to "no push": permission stays
/// `notDetermined`, the token stays null and the streams stay empty. The
/// in-app request inbox is authoritative either way, so a missing native
/// bridge can never break the app.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'notification_models.dart';
import 'push_transport.dart';

/// Channel names owned by task `08`.
abstract final class PushChannels {
  static const String method = 'app.trainingarena.mobile/push';
  static const String messages = 'app.trainingarena.mobile/push/messages';
  static const String taps = 'app.trainingarena.mobile/push/taps';
  static const String tokens = 'app.trainingarena.mobile/push/tokens';
}

/// Native-scaffold implementation used by configured builds.
class PlatformPushTransport implements PushTransport {
  PlatformPushTransport({
    MethodChannel? methodChannel,
    EventChannel? messagesChannel,
    EventChannel? tapsChannel,
    EventChannel? tokensChannel,
  })  : _method = methodChannel ?? const MethodChannel(PushChannels.method),
        _messagesChannel =
            messagesChannel ?? const EventChannel(PushChannels.messages),
        _tapsChannel = tapsChannel ?? const EventChannel(PushChannels.taps),
        _tokensChannel =
            tokensChannel ?? const EventChannel(PushChannels.tokens);

  final MethodChannel _method;
  final EventChannel _messagesChannel;
  final EventChannel _tapsChannel;
  final EventChannel _tokensChannel;

  Stream<PushPayload>? _messages;
  Stream<PushTap>? _taps;
  Stream<String>? _tokens;
  bool _disposed = false;

  @override
  Future<PushPermissionStatus> permissionStatus() async =>
      PushPermissionStatus.fromWire(await _invoke<String>('permissionStatus'));

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.fromWire(await _invoke<String>('requestPermission'));

  @override
  Future<String?> deviceToken() => _invoke<String>('deviceToken');

  @override
  Stream<PushPayload> get foregroundMessages => _messages ??= _events(
        _messagesChannel,
        (raw) => raw is Map ? PushPayload.fromData(raw) : null,
      );

  @override
  Stream<PushTap> get notificationTaps => _taps ??= _events(
        _tapsChannel,
        (raw) => raw is Map ? PushTap(PushPayload.fromData(raw)) : null,
      );

  @override
  Stream<String> get tokenRefreshes => _tokens ??= _events(
        _tokensChannel,
        (raw) {
          final token = raw?.toString().trim();
          return token == null || token.isEmpty ? null : token;
        },
      );

  @override
  Future<PushTap?> initialTap() async {
    final raw = await _invoke<Map<Object?, Object?>>('initialTap');
    if (raw == null) {
      return null;
    }
    return PushTap(PushPayload.fromData(raw), coldStart: true);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      await _method.invokeMethod<void>('dispose');
    } on PlatformException {
      // Best effort: the engine may already be detaching.
    } on MissingPluginException {
      // No native bridge (tests or an unconfigured build).
    }
  }

  Stream<T> _events<T>(
    EventChannel channel,
    T? Function(Object? raw) parse,
  ) {
    if (_disposed) {
      return const Stream<Object?>.empty().cast<T>();
    }
    try {
      return channel
          .receiveBroadcastStream()
          .map(parse)
          .where((event) => event != null)
          .cast<T>()
          .handleError((Object _) {});
    } catch (_) {
      return const Stream<Object?>.empty().cast<T>();
    }
  }

  Future<T?> _invoke<T>(String method) async {
    if (_disposed) {
      return null;
    }
    try {
      return await _method.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
