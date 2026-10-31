import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/solo/data/solo_result_store.dart';
import 'package:training_arena/solo/domain/solo_result.dart';

SoloSetResult result({
  int reps = 10,
  int durationSeconds = 30,
  SoloCountSource source = SoloCountSource.camera,
}) =>
    SoloSetResult(
      exercise: ArenaExercise.pushUps,
      reps: reps,
      durationSeconds: durationSeconds,
      completedAt: DateTime.utc(2026, 9, 23, 10),
      source: source,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JSON round-trips and rejects malformed entries', () {
    final original = result(reps: 42, source: SoloCountSource.manual);
    final decoded = SoloSetResult.tryFromJson(original.toJson());
    expect(decoded, original);
    expect(SoloSetResult.tryFromJson(null), isNull);
    expect(SoloSetResult.tryFromJson('nope'), isNull);
    expect(SoloSetResult.tryFromJson(<String, Object?>{'reps': 5}), isNull);
    expect(
      SoloSetResult.tryFromJson(<String, Object?>{
        'exercise': 'pushups',
        'reps': -1,
        'duration_seconds': 0,
        'completed_at': '2026-09-23T10:00:00Z',
        'source': 'manual',
      }),
      isNull,
    );
  });

  test('stats derive from the newest first', () {
    final stats = SoloStats.from(<SoloSetResult>[
      result(reps: 12),
      result(reps: 30),
      result(reps: 5),
    ]);
    expect(stats.sessions, 3);
    expect(stats.totalReps, 47);
    expect(stats.bestSetReps, 30);
    expect(stats.last?.reps, 12);
    expect(SoloStats.from(const <SoloSetResult>[]).bestSetReps, 0);
  });

  test('the store keeps the newest 100 entries', () async {
    final store = InMemorySoloResultStore();
    final many = List<SoloSetResult>.generate(
      120,
      (index) => result(reps: index),
    );
    await store.write(many);
    final stored = await store.read();
    expect(stored.length, soloResultHistoryLimit);
    expect(stored.first.reps, 0);
    expect(stored.last.reps, 99);
  });

  test('missing persistent storage cannot claim a durable save', () async {
    final store = SharedPreferencesSoloResultStore();
    await expectLater(
      store.write(<SoloSetResult>[result(reps: 7)]),
      throwsA(isA<StateError>()),
    );
  });

  test('shared-preferences store skips corrupt entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'arena.solo.results.v1': <String>[
        'not json',
        '{"exercise":"pushups","reps":5,"duration_seconds":30,'
            '"completed_at":"2026-09-23T10:00:00Z","source":"manual"}',
      ],
    });
    final store = SharedPreferencesSoloResultStore();
    final stored = await store.read();
    expect(stored.single.reps, 5);
    expect(stored.single.source, SoloCountSource.manual);
  });
}
