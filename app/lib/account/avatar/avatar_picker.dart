/// Avatar picking boundary.
///
/// The production implementation opens the Android document picker
/// (`ACTION_OPEN_DOCUMENT`) for a single image. It never opens the camera and
/// never requests a camera permission; camera frames are not an avatar
/// source. Picking is optional and can be deferred without blocking anything.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/account_models.dart';

/// A picker that only offers library/document images.
abstract interface class AvatarPicker {
  /// Returns null when the user cancels. Throws [AccountException] with an
  /// actionable message when picking is unavailable or the file cannot be
  /// read.
  Future<AvatarUpload?> pickFromLibrary();
}

/// Fail-closed picker for builds without the platform bridge.
class UnavailableAvatarPicker implements AvatarPicker {
  const UnavailableAvatarPicker();

  @override
  Future<AvatarUpload?> pickFromLibrary() async {
    throw const AccountException(
      'unavailable',
      'Picking a photo is unavailable in this build. You can add one later.',
    );
  }
}

/// Method-channel picker backed by `AccountAvatarPlugin` on Android.
class MethodChannelAvatarPicker implements AvatarPicker {
  const MethodChannelAvatarPicker({
    this.channel = const MethodChannel('app.trainingarena.mobile/avatar'),
  });

  final MethodChannel channel;

  @override
  Future<AvatarUpload?> pickFromLibrary() async {
    late final Map<Object?, Object?>? result;
    try {
      result = await channel.invokeMethod<Map<Object?, Object?>>(
        'pickFromLibrary',
      );
    } on PlatformException catch (error) {
      if (error.code == 'too_large') {
        throw const AccountException(
          'avatar_too_large',
          'That photo is larger than 2 MB. Choose a smaller one.',
        );
      }
      throw const AccountException(
        'unavailable',
        'The photo picker is unavailable right now. Try again.',
      );
    } on MissingPluginException {
      throw const AccountException(
        'unavailable',
        'Picking a photo is unavailable in this build. You can add one later.',
      );
    }
    if (result == null) {
      return null;
    }
    final path = result['path']?.toString();
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const AccountException(
          'avatar_invalid',
          'That file is empty. Choose a JPEG, PNG or WebP photo.',
        );
      }
      final mime =
          ArenaAvatarLimits.sniffMimeType(bytes) ?? 'application/octet-stream';
      return AvatarUpload(bytes: bytes, mimeType: mime);
    } on FileSystemException {
      throw const AccountException(
        'unavailable',
        'That photo could not be read. Try another one.',
      );
    } finally {
      unawaited(_deleteQuietly(file));
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {
      // The cache file is best-effort cleanup only.
    }
  }
}
