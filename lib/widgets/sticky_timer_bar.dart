import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rest_timer_provider.dart';

class StickyTimerBar extends ConsumerStatefulWidget {
  const StickyTimerBar({Key? key}) : super(key: key);

  @override
  ConsumerState<StickyTimerBar> createState() => _StickyTimerBarState();
}

class _StickyTimerBarState extends ConsumerState<StickyTimerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updatePulseAnimation(int secondsRemaining, bool isActive) {
    if (isActive && secondsRemaining <= 5 && secondsRemaining > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isActive || timerState.secondsRemaining <= 0) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
      return const SizedBox.shrink();
    }

    _updatePulseAnimation(timerState.secondsRemaining, timerState.isActive);

    final isPulsing = timerState.secondsRemaining <= 5;
    final progress = timerState.totalSeconds > 0
        ? (timerState.secondsRemaining / timerState.totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toInt();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isPulsing
                        ? const Color(0xFFE74C3C).withOpacity(0.35)
                        : const Color(0xFF1E1E2E).withOpacity(0.80),
                    isPulsing
                        ? const Color(0xFFC0392B).withOpacity(0.25)
                        : const Color(0xFF2A2A3D).withOpacity(0.70),
                  ],
                ),
                border: Border.all(
                  color: isPulsing
                      ? const Color(0xFFFF4757).withOpacity(0.8)
                      : const Color(0xFF6C5CE7).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPulsing
                        ? const Color(0xFFFF4757).withOpacity(0.3)
                        : Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isPulsing
                                    ? const Color(0xFFFF4757)
                                    : const Color(0xFF6C5CE7),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.timer,
                                color: isPulsing
                                    ? const Color(0xFFFF4757)
                                    : const Color(0xFF6C5CE7),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'REST TIMER',
                                  style: TextStyle(
                                    color: isPulsing
                                        ? const Color(0xFFFF4757)
                                        : Colors.grey.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPulsing
                                        ? const Color(0xFFFF4757).withOpacity(0.2)
                                        : const Color(0xFF6C5CE7).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      color: isPulsing
                                          ? const Color(0xFFFF4757)
                                          : const Color(0xFFA29BFE),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(timerState.secondsRemaining),
                              style: TextStyle(
                                color: isPulsing ? const Color(0xFFFF4757) : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      OutlinedButton(
                        onPressed: () {
                          ref.read(restTimerProvider.notifier).addTime(30);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isPulsing
                                ? const Color(0xFFFF4757)
                                : const Color(0xFF6C5CE7),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '+30s',
                          style: TextStyle(
                            color: isPulsing
                                ? const Color(0xFFFF4757)
                                : const Color(0xFF6C5CE7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          ref.read(restTimerProvider.notifier).stopTimer();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar showing time remaining as a percentage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPulsing
                            ? const Color(0xFFFF4757)
                            : const Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
