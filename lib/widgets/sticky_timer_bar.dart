import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rest_timer_provider.dart';

class StickyTimerBar extends ConsumerWidget {
  const StickyTimerBar({Key? key}) : super(key: key);

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isActive) return const SizedBox.shrink();

    final progress = timerState.totalSeconds > 0
        ? timerState.secondsRemaining / timerState.totalSeconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
                Center(
                  child: const Icon(
                    Icons.timer,
                    color: Color(0xFF6C5CE7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REST TIMER',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                _formatTime(timerState.secondsRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Action Buttons
          OutlinedButton(
            onPressed: () {
              ref.read(restTimerProvider.notifier).addTime(30);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C5CE7)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('+30s',
                style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () {
              ref.read(restTimerProvider.notifier).stopTimer();
            },
          ),
        ],
      ),
    );
  }
}
