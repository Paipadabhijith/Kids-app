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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isPremium = subscription.isPremium;

    final badgeGradient = isPremium
        ? [const Color(0xFF8C63FF), const Color(0xFF5B3FD6)]
        : [const Color(0xFFFFB347), const Color(0xFFFF8C42)];
    final badgeShadowColor = (isPremium ? badgeGradient.first : badgeGradient.last).withOpacity(0.3);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showFullName ? 12 : 8,
        vertical: showFullName ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: badgeGradient),
        borderRadius: BorderRadius.circular(showFullName ? 18 : 12),
        boxShadow: [
          BoxShadow(
            color: badgeShadowColor,
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
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.6,
                letterSpacing: 0.3,
              ),
            ),
          ] else ...[
            const SizedBox(width: 4),
            Text(
              subscription.tierBadge,
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.5,
                letterSpacing: 0.2,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPremium = subscription.isPremium;
    final isCancelling = subscription.cancelAtPeriodEnd && isPremium;
    final accentColor = isPremium ? colorScheme.primary : colorScheme.secondary;
    final borderColor = accentColor.withOpacity(isDark ? 0.45 : 0.32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.auto_awesome : Icons.wb_sunny,
            color: accentColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re using ${subscription.tierName}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? (isCancelling
                          ? 'You keep Zen Kids until the end of your current billing cycle.'
                          : 'Unlimited access to all features.')
                      : 'Upgrade to Zen Kids for unlimited wellness.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.8),
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

