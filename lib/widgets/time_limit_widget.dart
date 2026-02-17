import 'package:flutter/material.dart';

class TimeLimitWidget extends StatelessWidget {
  final int remainingMinutes;
  final bool isLimitExceeded;
  final VoidCallback? onTap;

  const TimeLimitWidget({
    super.key,
    required this.remainingMinutes,
    this.isLimitExceeded = false,
    this.onTap,
  });

  String _formatTime(int minutes) {
    if (minutes < 0) return 'Unlimited';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (isLimitExceeded) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red;
      icon = Icons.warning;
    } else if (remainingMinutes < 30) {
      backgroundColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange;
      icon = Icons.access_time;
    } else {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green;
      icon = Icons.check_circle;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: textColor.withOpacity(0.3), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLimitExceeded ? 'Time limit reached' : 'Time remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(remainingMinutes),
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

