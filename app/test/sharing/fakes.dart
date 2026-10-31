/// Deterministic doubles for result-sharing tests.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:training_arena/battle/ports/battle_challenge_sharer.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/sharing/result_share_challenge_sharer.dart';
import 'package:training_arena/sharing/result_share_models.dart';
import 'package:training_arena/sharing/result_share_service.dart';

import '../linking/fakes.dart';

/// Account source with an optional factual failure.
class FakeResultShareAccountSource implements ResultShareAccountSource {
  FakeResultShareAccountSource({
    ChallengeAccountSnapshot? snapshot,
    this.error,
  }) : snapshot = snapshot ??
            ChallengeAccountSnapshot(
              profile: fakeOwner(username: 'azizbek'),
              link: const ChallengeLinkInfo(
                token: fakeToken,
                code: fakeToken,
              ),
            );

  ChallengeAccountSnapshot snapshot;
  Object? error;
  int calls = 0;

  @override
  Future<ChallengeAccountSnapshot> load() async {
    calls += 1;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return snapshot;
  }
}

/// Records platform share calls instead of opening a share sheet.
class FakeResultShareLauncher implements ResultShareLauncher {
  final List<Uint8List> imageBytes = <Uint8List>[];
  final List<String> imageNames = <String>[];
  final List<String> imageTexts = <String>[];
  final List<String?> imageSubjects = <String?>[];
  final List<String> sharedTexts = <String>[];
  final List<String?> textSubjects = <String?>[];

  Object? imageError;
  Object? textError;

  @override
  Future<void> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String mimeType,
    required String text,
    String? subject,
  }) async {
    final failure = imageError;
    if (failure != null) {
      throw failure;
    }
    imageBytes.add(pngBytes);
    imageNames.add(fileName);
    imageTexts.add(text);
    imageSubjects.add(subject);
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    final failure = textError;
    if (failure != null) {
      throw failure;
    }
    sharedTexts.add(text);
    textSubjects.add(subject);
  }
}

/// Records clipboard writes.
class FakeResultShareClipboard implements ResultShareClipboard {
  final List<String> copied = <String>[];

  @override
  Future<void> copy(String text) async {
    copied.add(text);
  }
}

/// Returns fixed PNG bytes and records the requested export format.
class FakeResultShareCapture implements ResultShareCapture {
  FakeResultShareCapture({List<int>? bytes})
      : bytes = Uint8List.fromList(
          bytes ?? const <int>[137, 80, 78, 71, 1, 2, 3, 4],
        );

  final Uint8List bytes;
  final List<ResultShareFormat> formats = <ResultShareFormat>[];
  int calls = 0;
  Object? error;

  @override
  Future<Uint8List> capturePng({
    required GlobalKey boundaryKey,
    required ResultShareFormat format,
  }) async {
    calls += 1;
    formats.add(format);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return bytes;
  }
}

/// Never opens a route; records the preview requests it received.
class FakeResultSharePresenter implements ResultSharePresenter {
  final List<ResultSharePreviewRequest> requests =
      <ResultSharePreviewRequest>[];
  bool result = true;

  @override
  Future<bool> present(
    ResultSharePreviewRequest request,
    ResultShareService service,
  ) async {
    requests.add(request);
    return result;
  }
}

/// Fallback sharer recording forwarded invites.
class RecordingFallbackSharer implements BattleChallengeSharer {
  final List<BattleChallengeInvite> invites = <BattleChallengeInvite>[];
  String? message = 'fallback text share';

  @override
  Future<String?> shareChallenge(BattleChallengeInvite invite) async {
    invites.add(invite);
    return message;
  }
}
