import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for the Android link configuration and the assetlinks
/// template. These files cannot be exercised by widget tests, so the test
/// asserts the exact configuration that App Links verification depends on.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final buildGradle = File('android/app/build.gradle').readAsStringSync();
  final kt = File(
    'android/app/src/main/kotlin/app/trainingarena/mobile/'
    'InstallReferrerBridge.kt',
  ).readAsStringSync();
  final activity = File(
    'android/app/src/main/kotlin/app/trainingarena/mobile/MainActivity.kt',
  ).readAsStringSync();
  final template = File(
    '../challenge-web/.well-known/assetlinks.json.template',
  ).readAsStringSync();

  test('manifest declares verified App Links for the configurable host', () {
    expect(manifest, contains('android:autoVerify="true"'));
    expect(manifest, contains(r'android:host="${arenaLinkHost}"'));
    expect(manifest, contains('android:scheme="https"'));
    expect(manifest, contains('android:pathPrefix="/c/"'));
  });

  test('manifest declares the trainingarena fallback and app_links routing',
      () {
    expect(manifest, contains('android:scheme="trainingarena"'));
    expect(manifest, contains('android:host="challenge"'));
    expect(manifest, contains('flutter_deeplinking_enabled'));
    expect(manifest, contains('android:value="false"'));
  });

  test('gradle keeps the placeholder host and Play referrer dependency', () {
    expect(manifest, contains(r'${arenaLinkHost}'));
    expect(buildGradle, contains('manifestPlaceholders["arenaLinkHost"]'));
    expect(buildGradle, contains('example.invalid'));
    expect(
      buildGradle,
      contains('com.android.installreferrer:installreferrer'),
    );
  });

  test('install referrer bridge uses the stable channel contract', () {
    expect(kt, contains('app.trainingarena.mobile/install_referrer'));
    expect(kt, contains('getInstallReferrer'));
    expect(kt, contains('InstallReferrerResponse.OK'));
    expect(
      activity,
      contains('InstallReferrerBridge'),
      reason: 'the channel is only reachable when MainActivity registers it',
    );
  });

  test('assetlinks template documents relation, package and fingerprint', () {
    expect(
      template,
      contains('delegate_permission/common.handle_all_urls'),
    );
    expect(template, contains('app.trainingarena.mobile'));
    expect(template, contains('sha256_cert_fingerprints'));
    expect(
      template,
      contains('REPLACE_WITH_RELEASE_CERT_SHA256_FINGERPRINT'),
      reason: 'the placeholder must be obvious until the real domain exists',
    );
  });

  test('Android backup is off so credentials cannot leave the device', () {
    expect(
      manifest,
      contains('android:allowBackup="false"'),
      reason: 'L03 moved sessions to the Keystore and disabled cloud backup',
    );
  });
}
