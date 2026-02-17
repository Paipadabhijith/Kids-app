import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/app_theme_service.dart';
import '../services/user_profile_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';
import '../widgets/tier_badge.dart';
import '../widgets/upgrade_dialog.dart';
import 'parental_settings_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ImagePicker _imagePicker = ImagePicker();
  String? _profilePhotoUrl;
  bool _isLoading = false;
  SubscriptionModel _subscription = SubscriptionModel();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final subscription = await _subscriptionService.getSubscription();
    if (mounted) {
      setState(() {
        _subscription = subscription;
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    final photoUrl = await _profileService.getProfilePhotoUrl();
    if (mounted) {
      setState(() {
        _profilePhotoUrl = photoUrl;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    // Check if user has premium access for custom profile pictures
    final canAccess = await _subscriptionService.canAccessFeature(
      PremiumFeature.customProfilePicture,
    );

    if (!canAccess && mounted) {
      UpgradeDialog.show(
        context,
        feature: 'Custom Profile Pictures',
        description: 'Upload custom profile pictures with Zen Kids premium!',
        onUpgrade: () async {
          await _subscriptionService.upgradeToPremium();
          await _loadSubscription();
        },
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      final file = File(image.path);
      final downloadUrl = await _profileService.uploadProfilePicture(file);

      if (mounted) {
        setState(() {
          _profilePhotoUrl = downloadUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _profileService.removeCustomProfilePicture();
                  await _loadProfilePhoto();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile picture removed'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error removing photo: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final displayName = _profileService.getDisplayName();
    final email = _profileService.getEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: _profilePhotoUrl != null
                            ? NetworkImage(_profilePhotoUrl!)
                            : null,
                        child: _profilePhotoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _isLoading ? null : _showImageSourceDialog,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName ?? 'User',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Subscription Tier Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TierIndicator(subscription: _subscription),
                  if (!_subscription.isPremium) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          UpgradeDialog.show(
                            context,
                            feature: 'Unlock All Features',
                            description: 'Get unlimited access to Calm Mode, Binaural Beats, all categories, and more!',
                            onUpgrade: () async {
                              await _subscriptionService.upgradeToPremium();
                              await _loadSubscription();
                            },
                          );
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Upgrade to Zen Kids'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDowngradeDialog(),
                        icon: Icon(Icons.arrow_downward, color: colorScheme.secondary),
                        label: Text(
                          'Switch to Basic Version',
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: colorScheme.secondary,
                            width: 1.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Account Details Section
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Display Name'),
              subtitle: Text(displayName ?? 'Not set'),
              trailing: const Icon(Icons.chevron_right),
            ),

            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(email ?? 'Not set'),
              trailing: const Icon(Icons.chevron_right),
            ),

            const Divider(height: 1),

            // Settings Section
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Parental Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentalSettingsScreen(),
                  ),
                );
              },
            ),

            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppThemeService.themeMode,
              builder: (context, themeMode, _) {
                final isDarkMode = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    isDarkMode ? 'On' : 'Off',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: isDarkMode,
                  onChanged: (enabled) async {
                    await AppThemeService.setThemeMode(
                      enabled ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                );
              },
            ),

            const Divider(height: 1),

            // Sign Out Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleSignOut,
                  icon: Icon(Icons.logout, color: colorScheme.error),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: colorScheme.error,
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: isDark ? colorScheme.error.withOpacity(0.08) : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showDowngradeDialog() async {
    if (!_subscription.isPremium) return;

    final expiry = _subscription.expiryDate;
    final expiryText = expiry != null
        ? '${expiry.day}/${expiry.month}/${expiry.year}'
        : 'the end of your current billing period';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Switch to Basic Version?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you switch to the Bright Kids (basic) plan:\n',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text('These premium features will be disabled after your current billing cycle:'),
              const SizedBox(height: 8),
              const _DowngradeFeatureBullet('Unlimited Calm Mode minutes'),
              const _DowngradeFeatureBullet('Binaural Beats'),
              const _DowngradeFeatureBullet('Break reminder games'),
              const _DowngradeFeatureBullet('Multiple child profiles'),
              const _DowngradeFeatureBullet('Channel whitelist / blacklist controls'),
              const _DowngradeFeatureBullet('Full usage dashboard & advanced stats'),
              const _DowngradeFeatureBullet('Custom profile pictures'),
              const SizedBox(height: 12),
              Text(
                'You will keep full Zen Kids premium access until $expiryText. '
                'After that, your plan will automatically move to the Bright Kids basic version.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Zen Kids'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              child: const Text('Confirm Switch'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _subscriptionService.scheduleDowngradeAtPeriodEnd();
      await _loadSubscription();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your plan will switch to Bright Kids at the end of the current billing cycle. '
              'You keep Zen Kids benefits until then.',
            ),
          ),
        );
      }
    }
  }
}

class _DowngradeFeatureBullet extends StatelessWidget {
  final String text;

  const _DowngradeFeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

