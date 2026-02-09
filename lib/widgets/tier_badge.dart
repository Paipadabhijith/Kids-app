import 'package:flutter/material.dart';
import '../models/subscription_model.dart';

class TierBadge extends StatelessWidget {
  final SubscriptionModel subscription;
  final bool showFullName;
  final double size;

  const TierBadge({
    super.key,
    required this.subscription,
    this.showFullName = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = subscription.isPremium;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showFullName ? 12 : 8,
        vertical: showFullName ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.deepPurple.shade600,
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.amber.shade600,
                ],
              ),
        borderRadius: BorderRadius.circular(showFullName ? 20 : 12),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? Colors.purple : Colors.orange).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.auto_awesome : Icons.wb_sunny,
            color: Colors.white,
            size: size,
          ),
          if (showFullName) ...[
            const SizedBox(width: 6),
            Text(
              subscription.tierName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.6,
              ),
            ),
          ] else ...[
            const SizedBox(width: 4),
            Text(
              subscription.tierBadge,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TierIndicator extends StatelessWidget {
  final SubscriptionModel subscription;

  const TierIndicator({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = subscription.isPremium;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isPremium ? Colors.purple : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPremium ? Colors.purple : Colors.orange).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.auto_awesome : Icons.wb_sunny,
            color: isPremium ? Colors.purple : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re using ${subscription.tierName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.purple.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? 'Unlimited access to all features'
                      : 'Upgrade to Zen Kids for unlimited wellness',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

