import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerState { idle, running, paused, expired }

/// Manages the rest-between-sets countdown timer for the active workout screen.
///
/// The timer runs in-process via [Timer.periodic]. When the countdown reaches
/// zero it fires [HapticFeedback.heavyImpact] and transitions to
/// [TimerState.expired]. Callers may add/remove time, pause, resume, or skip.
class RestTimerNotifier extends ChangeNotifier {
  TimerState state = TimerState.idle;
  int remainingSeconds = 0;
  int totalSeconds = 0;
  Timer? _timer;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Starts a new countdown for [seconds]. Cancels any previous timer.
  void start(int seconds) {
    _timer?.cancel();
    totalSeconds = seconds;
    remainingSeconds = seconds;
    state = TimerState.running;
    _tick();
    notifyListeners();
  }

  /// Adds (or subtracts if negative) [seconds] to the current countdown.
  void addTime(int seconds) {
    remainingSeconds = (remainingSeconds + seconds).clamp(0, 3600);
    notifyListeners();
  }

  /// Pauses a running timer.
  void pause() {
    if (state != TimerState.running) return;
    _timer?.cancel();
    state = TimerState.paused;
    notifyListeners();
  }

  /// Resumes a paused timer.
  void resume() {
    if (state != TimerState.paused) return;
    state = TimerState.running;
    _tick();
    notifyListeners();
  }

  /// Skips (dismisses) the rest timer entirely.
  void skip() {
    _timer?.cancel();
    state = TimerState.idle;
    remainingSeconds = 0;
    totalSeconds = 0;
    notifyListeners();
  }

  /// Manually sets remaining time without starting the timer (for picker dialog).
  void setTime(int seconds) {
    remainingSeconds = seconds.clamp(0, 3600);
    totalSeconds = seconds.clamp(0, 3600);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds <= 0) {
        _timer?.cancel();
        state = TimerState.expired;
        HapticFeedback.heavyImpact();
        notifyListeners();
        return;
      }
      remainingSeconds--;
      if (remainingSeconds <= 0) {
        _timer?.cancel();
        state = TimerState.expired;
        HapticFeedback.heavyImpact();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    ChangeNotifierProvider<RestTimerNotifier>((ref) => RestTimerNotifier());
