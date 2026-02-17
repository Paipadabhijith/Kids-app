import 'dart:async';
import 'package:flutter/material.dart';

class BreakReminderScreen extends StatefulWidget {
  final int breakMinutes;
  final Future<void> Function() onBreakComplete;

  const BreakReminderScreen({
    super.key,
    required this.breakMinutes,
    required this.onBreakComplete,
  });

  @override
  State<BreakReminderScreen> createState() => _BreakReminderScreenState();
}

class _BreakReminderScreenState extends State<BreakReminderScreen> {
  Timer? _countdownTimer;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    final durationMinutes = widget.breakMinutes <= 0 ? 1 : widget.breakMinutes;
    _totalSeconds = durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCompleting) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _completeBreak();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  String _formatRemaining(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  double _progress() {
    if (_totalSeconds == 0) return 1;
    final elapsed = _totalSeconds - _remainingSeconds;
    return (elapsed / _totalSeconds).clamp(0, 1);
  }

  Future<void> _completeBreak() async {
    if (_isCompleting || !mounted) return;
    _isCompleting = true;
    _countdownTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Break complete! Great job 🌟'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await widget.onBreakComplete();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress();
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF7FF),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 520;
              final iconSize = isCompactHeight ? 44.0 : 68.0;
              final titleSize = isCompactHeight ? 24.0 : 32.0;
              final subtitleSize = isCompactHeight ? 14.0 : 17.0;
              final timerSize = isCompactHeight ? 170.0 : 240.0;
              final ringSize = isCompactHeight ? 145.0 : 206.0;
              final timeFontSize = isCompactHeight ? 32.0 : 44.0;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            size: iconSize,
                            color: const Color(0xFF5C6BFF),
                          ),
                          SizedBox(height: isCompactHeight ? 8 : 16),
                          Text(
                            'Break Time!',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF24324D),
                            ),
                          ),
                          SizedBox(height: isCompactHeight ? 4 : 8),
                          Text(
                            'Take a calm little pause. You\'ll be back soon!',
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: const Color(0xFF5E6F8D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isCompactHeight ? 16 : 32),
                          Container(
                            width: timerSize,
                            height: timerSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.16),
                                  blurRadius: 26,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: ringSize,
                                  height: ringSize,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: isCompactHeight ? 9 : 12,
                                    backgroundColor: const Color(0xFFDDE8FF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF5C6BFF),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Back In',
                                      style: TextStyle(
                                        fontSize: isCompactHeight ? 13 : 16,
                                        color: const Color(0xFF5E6F8D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: isCompactHeight ? 4 : 6),
                                    Text(
                                      _formatRemaining(_remainingSeconds),
                                      style: TextStyle(
                                        fontSize: timeFontSize,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF24324D),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isCompactHeight ? 14 : 28),
                          Text(
                            'Stretch, sip water, and blink your eyes.',
                            style: TextStyle(
                              fontSize: isCompactHeight ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5E6F8D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

