import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final int secondsRemaining;
  final int totalSeconds;
  final bool isActive;

  RestTimerState({
    this.secondsRemaining = 0,
    this.totalSeconds = 90,
    this.isActive = false,
  });

  RestTimerState copyWith({
    int? secondsRemaining,
    int? totalSeconds,
    bool? isActive,
  }) {
    return RestTimerState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isActive: isActive ?? this.isActive,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(RestTimerState());

  void startTimer({int durationSeconds = 90}) {
    _timer?.cancel();
    state = RestTimerState(
      secondsRemaining: durationSeconds,
      totalSeconds: durationSeconds,
      isActive: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        HapticFeedback.heavyImpact();
        stopTimer();
      }
    });
  }

  void addTime(int additionalSeconds) {
    if (!state.isActive) return;
    state = state.copyWith(
      secondsRemaining: state.secondsRemaining + additionalSeconds,
      totalSeconds: state.totalSeconds + additionalSeconds,
    );
  }

  void stopTimer() {
    _timer?.cancel();
    state = RestTimerState(secondsRemaining: 0, isActive: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});
