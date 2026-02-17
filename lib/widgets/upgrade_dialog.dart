import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class UpgradeDialog extends StatelessWidget {
  final String feature;
  final String description;
  final VoidCallback? onUpgrade;

  const UpgradeDialog({
    super.key,
    required this.feature,
    required this.description,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Upgrade to Zen Kids',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Feature description
            Text(
              feature,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Premium features list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zen Kids includes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeature('Unlimited Calm Mode'),
                  _buildFeature('Binaural Beats'),
                  _buildFeature('All 16 Categories'),
                  _buildFeature('Unlimited Search & Playlists'),
                  _buildFeature('Break Reminder Games'),
                  _buildFeature('Multiple Child Profiles'),
                  _buildFeature('Channel Control'),
                  _buildFeature('Custom Profile Pictures'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pricing
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 1.6,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$4.99/month',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'or',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$39.99/year',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onUpgrade != null) {
                        onUpgrade!();
                      } else {
                        _showUpgradeComingSoon(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.purple.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade400,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String feature,
    required String description,
    VoidCallback? onUpgrade,
  }) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        feature: feature,
        description: description,
        onUpgrade: onUpgrade,
      ),
    );
  }

  static void _showUpgradeComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('In-app purchases coming soon! For now, enjoy exploring all features.'),
        backgroundColor: Colors.purple,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

