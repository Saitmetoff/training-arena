/// Clock and timer port.
///
/// Tests inject a manual clock to drive countdown, queue windows and the
/// 10-second recovery window deterministically. Production uses wall time.
library;

import 'dart:async';

/// Cancellable timer handle.
abstract interface class BattleTimer {
  void cancel();

  bool get isActive;
}

/// Time source for the battle runtime.
abstract interface class BattleClock {
  /// Current local wall time.
  DateTime now();

  /// Runs [callback] once after [delay].
  BattleTimer schedule(Duration delay, void Function() callback);

  /// Runs [callback] every [interval].
  BattleTimer periodic(Duration interval, void Function() callback);
}

/// Timer backed by `dart:async`.
class SystemBattleTimer implements BattleTimer {
  SystemBattleTimer(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();

  @override
  bool get isActive => _timer.isActive;
}

/// Production clock.
class SystemBattleClock implements BattleClock {
  const SystemBattleClock();

  @override
  DateTime now() => DateTime.now();

  @override
  BattleTimer schedule(Duration delay, void Function() callback) {
    return SystemBattleTimer(Timer(delay, callback));
  }

  @override
  BattleTimer periodic(Duration interval, void Function() callback) {
    return SystemBattleTimer(Timer.periodic(interval, (_) => callback()));
  }
}
