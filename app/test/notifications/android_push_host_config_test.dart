/// Static contract checks for the native Android FCM host (task `11` / L06).
///
/// The Kotlin bridge cannot run in a host test, so this asserts the exact
/// channel names, manifest declarations and fail-closed build wiring that
/// `docs/notifications/ANDROID_PUSH_SETUP.md` §2–§4 requires. The dispatcher
/// FCM shaper is read too, so a channel rename on either side fails here.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final buildGradle = File('android/app/build.gradle').readAsStringSync();
  final settingsGradle = File('android/settings.gradle').readAsStringSync();
  final gitignore = File('.gitignore').readAsStringSync();
  final bridge = File(
    'android/app/src/main/kotlin/app/trainingarena/mobile/push/PushBridge.kt',
  ).readAsStringSync();
  final service = File(
    'android/app/src/main/kotlin/app/trainingarena/mobile/push/'
    'ArenaMessagingService.kt',
  ).readAsStringSync();
  final mainActivity = File(
    'android/app/src/main/kotlin/app/trainingarena/mobile/MainActivity.kt',
  ).readAsStringSync();
  final fcm = File(
    '../supabase/functions/arena-dispatcher/lib/fcm.ts',
  ).readAsStringSync();

  test('bridge implements every Dart channel and method of the contract', () {
    for (final channel in <String>[
      'app.trainingarena.mobile/push',
      'app.trainingarena.mobile/push/messages',
      'app.trainingarena.mobile/push/taps',
      'app.trainingarena.mobile/push/tokens',
    ]) {
      expect(bridge, contains(channel), reason: 'missing channel $channel');
    }
    for (final method in <String>[
      'permissionStatus',
      'requestPermission',
      'deviceToken',
      'initialTap',
      'dispose',
    ]) {
      expect(bridge, contains('"$method"'), reason: 'missing method $method');
    }
    expect(mainActivity, contains('PushBridge()'));
    expect(
      mainActivity,
      contains('flutterEngine.plugins.add(push)'),
      reason: 'the bridge is only reachable when MainActivity registers it',
    );
  });

  test('both channels match the dispatcher FCM shaper exactly', () {
    expect(fcm, contains('"arena_requests"'));
    expect(fcm, contains('"arena_matches"'));
    expect(bridge, contains('const val CHANNEL_REQUESTS = "arena_requests"'));
    expect(bridge, contains('const val CHANNEL_MATCHES = "arena_matches"'));
  });

  test('messaging service forwards tokens and messages without logging', () {
    expect(service, contains('onNewToken'));
    expect(service, contains('PushBridge.deliverToken(token)'));
    expect(service, contains('onMessageReceived'));
    expect(service, contains('PushBridge.deliverMessage(data)'));
    expect(service, contains('MainActivity::class.java'));
    expect(service, contains('PendingIntent'));
    for (final source in <String>[bridge, service, mainActivity]) {
      expect(
        source,
        isNot(contains('Log.')),
        reason: 'a token or payload must never reach the Android log',
      );
      expect(source, isNot(contains('println(')));
    }
  });

  test('manifest declares the service, both channels and the permission', () {
    expect(manifest, contains('.push.ArenaMessagingService'));
    expect(manifest, contains('com.google.firebase.MESSAGING_EVENT'));
    expect(manifest, contains('android:exported="false"'));
    expect(
      manifest,
      contains(
        'com.google.firebase.messaging.default_notification_channel_id',
      ),
    );
    expect(manifest, contains('android:value="arena_requests"'));
    expect(manifest, contains('POST_NOTIFICATIONS'));
    expect(
      manifest,
      contains('android:launchMode="singleTop"'),
      reason: 'warm taps must reuse the running activity',
    );
    expect(manifest, contains('flutter_deeplinking_enabled'));
    expect(manifest, contains('android:value="false"'));
  });

  test('Google Services plugin and credential are conditional and ignored',
      () {
    expect(
      buildGradle,
      contains('if (file("google-services.json").exists())'),
      reason: 'the repository must build without the owner credential',
    );
    expect(buildGradle, contains('apply plugin: "com.google.gms.google-services"'));
    expect(buildGradle, contains('com.google.firebase:firebase-messaging:25.1.3'));
    expect(settingsGradle, contains('com.google.gms.google-services'));
    expect(gitignore, contains('google-services.json'));
  });
}
