import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/parental_control_service.dart';
import '../services/video_filter_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'usage_dashboard_screen.dart';
import 'child_profiles_screen.dart';

class ParentalSettingsScreen extends StatefulWidget {
  const ParentalSettingsScreen({super.key});

  @override
  State<ParentalSettingsScreen> createState() => _ParentalSettingsScreenState();
}

class _ParentalSettingsScreenState extends State<ParentalSettingsScreen> {
  final ParentalControlService _parentalService = ParentalControlService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;
  bool _showPassword = false;
  int? _selectedTimeLimit;
  int? _selectedBreakInterval;
  int? _selectedBreakDuration;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _parentalService.getSettings();
    
    // Check if password is required
    if (settings.requirePasswordForSettings && settings.parentPasswordHash != null) {
      // Show password dialog
      final verified = await _verifyPassword();
      if (!verified && mounted) {
        Navigator.pop(context);
        return;
      }
    }

    setState(() {
      _settings = settings;
      _selectedTimeLimit = settings.dailyTimeLimitMinutes;
      _selectedBreakInterval = settings.breakIntervalMinutes;
      _selectedBreakDuration = settings.breakDurationMinutes;
      _isLoading = false;
    });
  }

  Future<bool> _verifyPassword() async {
    final passwordController = TextEditingController();
    bool showPassword = false;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Parent Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter parent password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) async {
                  final verified = await _parentalService.checkPassword(
                    passwordController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context, verified);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                  await _showForgotPasswordDialog();
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final verified = await _parentalService.checkPassword(
                  passwordController.text,
                );
                if (mounted) {
                  Navigator.pop(context, verified);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final userEmail = _authService.email;
    
    if (userEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in with Google to use password reset via email'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password via Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A password reset link will be sent to:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: This will reset your Firebase account password, not the parental control password. You may need to set a new parental password after resetting.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.sendPasswordResetEmail(userEmail);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showOldPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: !showOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Old Password',
                    hintText: 'Enter current password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showOldPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showOldPassword = !showOldPassword;
                        });
                      },
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showNewPassword = !showNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    hintText: 'Confirm new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                if (newPasswordController.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New password cannot be empty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final success = await _parentalService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    // Reload settings to update UI
                    await _loadSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Old password is incorrect'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(String title, String message, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      onConfirm();
    }
  }

  void _showCalmModePreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade200,
                Colors.purple.shade200,
                Colors.pink.shade200,
              ],
            ),
          ),
          child: ColorFiltered(
            colorFilter: VideoFilterService().createCalmModeFilter(
              contrast: _settings.calmModeContrast,
              saturation: _settings.calmModeSaturation,
              brightness: _settings.calmModeBrightness,
              warmth: _settings.calmModeWarmth,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.palette, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Calm Mode Preview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'This is how videos will look with your current Calm Mode settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPreviewStat('Contrast', '${(_settings.calmModeContrast * 100).toInt()}%'),
                      _buildPreviewStat('Saturation', '${(_settings.calmModeSaturation * 100).toInt()}%'),
                      _buildPreviewStat('Brightness', '${(_settings.calmModeBrightness * 100).toInt()}%'),
                      _buildPreviewStat('Warmth', '${(_settings.calmModeWarmth * 100).toInt()}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                  ),
                  child: const Text('Close Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_settings.parentalControlsEnabled) {
      // Validate password if setting one for the first time
      if (_settings.parentPasswordHash == null && _passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passwords do not match'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await _parentalService.enableParentalControls(
        dailyTimeLimitMinutes: _selectedTimeLimit,
        blockedKeywords: _settings.blockedKeywords,
        blockedCategories: _settings.blockedCategories,
        password: (_settings.parentPasswordHash == null && _passwordController.text.isNotEmpty)
            ? _passwordController.text
            : null, // Don't change password if it already exists (use Change Password dialog instead)
        breakRemindersEnabled: _settings.breakRemindersEnabled,
        breakIntervalMinutes: _selectedBreakInterval,
        breakDurationMinutes: _selectedBreakDuration,
      );
      
      // Save calm mode settings
      await _parentalService.updateCalmModeSettings(
        enabled: _settings.calmModeEnabled,
        contrast: _settings.calmModeContrast,
        saturation: _settings.calmModeSaturation,
        brightness: _settings.calmModeBrightness,
        warmth: _settings.calmModeWarmth,
        preset: _settings.calmModePreset,
      );
    } else {
      await _parentalService.disableParentalControls();
      
      // Still save calm mode settings even if parental controls are disabled
      await _parentalService.updateCalmModeSettings(
        enabled: _settings.calmModeEnabled,
        contrast: _settings.calmModeContrast,
        saturation: _settings.calmModeSaturation,
        brightness: _settings.calmModeBrightness,
        warmth: _settings.calmModeWarmth,
        preset: _settings.calmModePreset,
      );
    }

    // Save binaural beats settings (works regardless of parental controls)
    await _parentalService.updateBinauralBeatsSettings(
      enabled: _settings.binauralBeatsEnabled,
      windDownModeEnabled: _settings.windDownModeEnabled,
      calmFocusModeEnabled: _settings.calmFocusModeEnabled,
      volume: _settings.binauralBeatsVolume,
    );

    // Reload settings if password was set for the first time
    if (_settings.parentPasswordHash == null && _passwordController.text.isNotEmpty) {
      await _loadSettings();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _addBlockedKeyword() {
    final keyword = _keywordController.text.trim().toLowerCase();
    if (keyword.isNotEmpty && !_settings.blockedKeywords.contains(keyword)) {
      setState(() {
        _settings = _settings.copyWith(
          blockedKeywords: [..._settings.blockedKeywords, keyword],
        );
        _keywordController.clear();
      });
    }
  }

  void _removeBlockedKeyword(String keyword) {
    setState(() {
      _settings = _settings.copyWith(
        blockedKeywords: _settings.blockedKeywords
            .where((k) => k != keyword)
            .toList(),
      );
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Widget _buildUsageStatisticsCard() {
    // Get today's usage from storage service
    return FutureBuilder<int>(
      future: _storageService.getTodayUsage(),
      builder: (context, snapshot) {
        final todayMinutes = snapshot.data ?? 0;
        final timeLimit = _selectedTimeLimit ?? _settings.dailyTimeLimitMinutes ?? 60;
        final percentUsed = (todayMinutes / timeLimit * 100).clamp(0, 100);
        
        Color statusColor;
        String statusText;
        IconData statusIcon;
        
        if (percentUsed < 50) {
          statusColor = Colors.green;
          statusText = 'Good';
          statusIcon = Icons.check_circle_outline;
        } else if (percentUsed < 80) {
          statusColor = Colors.orange;
          statusText = 'Moderate';
          statusIcon = Icons.warning_amber_outlined;
        } else {
          statusColor = Colors.red;
          statusText = 'High';
          statusIcon = Icons.error_outline;
        }
        
        return Card(
          elevation: 3,
          color: statusColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bar_chart, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Today\'s Usage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      avatar: Icon(statusIcon, size: 16, color: statusColor),
                      label: Text(statusText),
                      backgroundColor: statusColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$todayMinutes min',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'of $timeLimit min limit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: percentUsed / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                          Center(
                            child: Text(
                              '${percentUsed.toInt()}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentUsed / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Usage Statistics Card
            _buildUsageStatisticsCard(),
            
            const SizedBox(height: 8),
            
            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsageDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Dashboard'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChildProfilesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Profiles'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Enable/Disable Parental Controls
            Card(
              elevation: 2,
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _settings.parentalControlsEnabled 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: _settings.parentalControlsEnabled 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                ),
                title: const Text(
                  'Enable Parental Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Control time limits and content filtering'),
                value: _settings.parentalControlsEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(
                      parentalControlsEnabled: value,
                    );
                  });
                },
              ),
            ),

            if (_settings.parentalControlsEnabled) ...[
              const SizedBox(height: 16),

              // Time Limit
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.timer_outlined, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Daily Time Limit',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_selectedTimeLimit != null)
                            Chip(
                              label: Text('${_selectedTimeLimit}m'),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [30, 60, 90, 120, 180].map((minutes) {
                          final hours = minutes ~/ 60;
                          final mins = minutes % 60;
                          final label = hours > 0
                              ? '${hours}h ${mins > 0 ? '${mins}m' : ''}'
                              : '${mins}m';
                          
                          final isSelected = _selectedTimeLimit == minutes;
                          return FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTimeLimit = selected ? minutes : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Custom time limit (minutes)',
                          hintText: 'Enter custom limit',
                        ),
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            setState(() {
                              _selectedTimeLimit = minutes;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password Protection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_settings.parentPasswordHash != null 
                                  ? Colors.green 
                                  : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock_outlined,
                              color: _settings.parentPasswordHash != null 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Parent Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              _settings.parentPasswordHash != null ? 'Protected' : 'Not Set',
                            ),
                            backgroundColor: (_settings.parentPasswordHash != null 
                                ? Colors.green 
                                : Colors.orange).withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _settings.parentPasswordHash != null 
                                  ? Colors.green 
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Show different UI based on whether password exists
                      if (_settings.parentPasswordHash == null) ...[
                        // First time - Set Password
                        const Text(
                          'Set a password to protect settings.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            hintText: 'Enter new password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showPassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Confirm new password',
                          ),
                        ),
                      ] else ...[
                        // Password exists - Show Change Password button
                        const Text(
                          'Password is set. Click below to change it.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Blocked Keywords
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.block_outlined, color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Blocked Keywords',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_settings.blockedKeywords.isNotEmpty)
                            Chip(
                              label: Text('${_settings.blockedKeywords.length}'),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Videos containing these keywords will be blocked',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keywordController,
                              decoration: const InputDecoration(
                                labelText: 'Keyword',
                                hintText: 'Enter keyword to block',
                              ),
                              onSubmitted: (_) => _addBlockedKeyword(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addBlockedKeyword,
                            tooltip: 'Add Keyword',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_settings.blockedKeywords.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _settings.blockedKeywords.map((keyword) {
                            return Chip(
                              label: Text(keyword),
                              onDeleted: () => _removeBlockedKeyword(keyword),
                              deleteIcon: const Icon(Icons.close, size: 18),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Channel Whitelist/Blacklist
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.playlist_add_check, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Channel Control',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${_settings.whitelistedChannels.length + _settings.blacklistedChannels.length}',
                            ),
                            backgroundColor: Colors.deepPurple.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Control which channels are allowed or blocked',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // Whitelist section
                      ExpansionTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                        title: const Text('Allowed Channels Only'),
                        subtitle: Text(
                          _settings.whitelistedChannels.isEmpty 
                              ? 'All channels allowed' 
                              : '${_settings.whitelistedChannels.length} channels',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Only videos from these channels will be shown',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(),
                                        decoration: const InputDecoration(
                                          labelText: 'Channel Name',
                                          hintText: 'e.g., Sesame Street',
                                          isDense: true,
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            setState(() {
                                              _settings = _settings.copyWith(
                                                whitelistedChannels: [
                                                  ..._settings.whitelistedChannels,
                                                  value,
                                                ],
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.green),
                                      onPressed: () {
                                        // Add whitelist channel logic
                                      },
                                    ),
                                  ],
                                ),
                                if (_settings.whitelistedChannels.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _settings.whitelistedChannels.map((channel) {
                                      return Chip(
                                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        label: Text(channel),
                                        onDeleted: () {
                                          setState(() {
                                            _settings = _settings.copyWith(
                                              whitelistedChannels: _settings.whitelistedChannels
                                                  .where((c) => c != channel)
                                                  .toList(),
                                            );
                                          });
                                        },
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(),
                      
                      // Blacklist section
                      ExpansionTile(
                        leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                        title: const Text('Blocked Channels'),
                        subtitle: Text(
                          _settings.blacklistedChannels.isEmpty 
                              ? 'No channels blocked' 
                              : '${_settings.blacklistedChannels.length} channels',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Videos from these channels will be hidden',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(),
                                        decoration: const InputDecoration(
                                          labelText: 'Channel Name',
                                          hintText: 'Enter channel to block',
                                          isDense: true,
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            setState(() {
                                              _settings = _settings.copyWith(
                                                blacklistedChannels: [
                                                  ..._settings.blacklistedChannels,
                                                  value,
                                                ],
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.red),
                                      onPressed: () {
                                        // Add blacklist channel logic
                                      },
                                    ),
                                  ],
                                ),
                                if (_settings.blacklistedChannels.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _settings.blacklistedChannels.map((channel) {
                                      return Chip(
                                        avatar: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                        label: Text(channel),
                                        onDeleted: () {
                                          setState(() {
                                            _settings = _settings.copyWith(
                                              blacklistedChannels: _settings.blacklistedChannels
                                                  .where((c) => c != channel)
                                                  .toList(),
                                            );
                                          });
                                        },
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Break Reminders
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_settings.breakRemindersEnabled 
                                  ? Colors.purple 
                                  : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: _settings.breakRemindersEnabled 
                                  ? Colors.purple 
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Break Reminders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Interactive games during break times',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _settings.breakRemindersEnabled,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  breakRemindersEnabled: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      if (_settings.breakRemindersEnabled) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Break Interval (minutes)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [15, 30, 45, 60].map((minutes) {
                            final isSelected = _selectedBreakInterval == minutes;
                            return FilterChip(
                              label: Text('${minutes}m'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBreakInterval = selected ? minutes : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Break Duration (minutes)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [3, 5, 10, 15].map((minutes) {
                            final isSelected = _selectedBreakDuration == minutes;
                            return FilterChip(
                              label: Text('${minutes}m'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBreakDuration = selected ? minutes : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calm Mode
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_settings.calmModeEnabled 
                                  ? Colors.teal 
                                  : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.visibility_outlined,
                              color: _settings.calmModeEnabled 
                                  ? Colors.teal 
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Calm Mode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Reduce visual stimulation by lowering contrast and saturation',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _settings.calmModeEnabled,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  calmModeEnabled: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      if (_settings.calmModeEnabled) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Preset selection
                        const Text(
                          'Quick Presets (Research-Backed)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a preset or customize below',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: VideoFilterService.presets.keys.map((presetName) {
                            final isSelected = _settings.calmModePreset == presetName;
                            return FilterChip(
                              label: Text(VideoFilterService.formatPresetName(presetName)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  final preset = VideoFilterService.getPresetValues(presetName);
                                  if (preset != null) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        calmModePreset: presetName,
                                        calmModeContrast: preset['contrast'],
                                        calmModeSaturation: preset['saturation'],
                                        calmModeBrightness: preset['brightness'],
                                        calmModeWarmth: preset['warmth'],
                                      );
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _settings = _settings.copyWith(calmModePreset: null);
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        if (_settings.calmModePreset != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            VideoFilterService.presetDescriptions[_settings.calmModePreset] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Preview Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCalmModePreview(),
                            icon: const Icon(Icons.preview),
                            label: const Text('Preview Calm Mode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Custom Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contrast slider
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Contrast: ${(_settings.calmModeContrast * 100).toInt()}%'),
                          subtitle: Slider(
                            value: _settings.calmModeContrast,
                            min: 0.5,
                            max: 1.0,
                            divisions: 10,
                            label: '${(_settings.calmModeContrast * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  calmModeContrast: value,
                                  calmModePreset: null, // Clear preset when customizing
                                );
                              });
                            },
                          ),
                        ),
                        
                        // Saturation slider
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Saturation: ${(_settings.calmModeSaturation * 100).toInt()}%'),
                          subtitle: Slider(
                            value: _settings.calmModeSaturation,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(_settings.calmModeSaturation * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  calmModeSaturation: value,
                                  calmModePreset: null,
                                );
                              });
                            },
                          ),
                        ),
                        
                        // Brightness slider
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Brightness: ${(_settings.calmModeBrightness * 100).toInt()}%'),
                          subtitle: Slider(
                            value: _settings.calmModeBrightness,
                            min: -0.3,
                            max: 0.1,
                            divisions: 8,
                            label: '${(_settings.calmModeBrightness * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  calmModeBrightness: value,
                                  calmModePreset: null,
                                );
                              });
                            },
                          ),
                        ),
                        
                        // Warmth slider (new - research-backed for blue light reduction)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Text('Warmth: ${(_settings.calmModeWarmth * 100).toInt()}%'),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Reduces blue light - better for sleep',
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Slider(
                            value: _settings.calmModeWarmth,
                            min: 0.0,
                            max: 0.5,
                            divisions: 10,
                            label: '${(_settings.calmModeWarmth * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  calmModeWarmth: value,
                                  calmModePreset: null,
                                );
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Research info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.science_outlined, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'These settings are based on research showing reduced saturation and contrast can lower visual stimulation and dopamine response in children.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Binaural Beats
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_settings.binauralBeatsEnabled 
                                  ? Colors.indigo 
                                  : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.headset_outlined,
                              color: _settings.binauralBeatsEnabled 
                                  ? Colors.indigo 
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Binaural Beats',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gentle audio tones to encourage calm focus or relaxation',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _settings.binauralBeatsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  binauralBeatsEnabled: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      if (_settings.binauralBeatsEnabled) ...[
                        const SizedBox(height: 16),
                        
                        // Headphone warning
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.headphones, color: Colors.amber.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Binaural beats require stereo headphones to be effective. They will not work through speakers.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Wind-down Mode (Theta beats)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Wind-Down Mode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Theta waves (6 Hz) for bedtime and relaxation',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _settings.windDownModeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _settings = _settings.copyWith(
                                    windDownModeEnabled: value,
                                    // Disable calm focus if wind-down is enabled
                                    calmFocusModeEnabled: value ? false : _settings.calmFocusModeEnabled,
                                  );
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Calm Focus Mode (Alpha beats)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Calm Focus Mode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Alpha waves (10 Hz) for learning and focus',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _settings.calmFocusModeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _settings = _settings.copyWith(
                                    calmFocusModeEnabled: value,
                                    // Disable wind-down if calm focus is enabled
                                    windDownModeEnabled: value ? false : _settings.windDownModeEnabled,
                                  );
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Volume slider
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Text('Volume: ${(_settings.binauralBeatsVolume * 100).toInt()}%'),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Lower volume ensures beats are subtle and non-intrusive',
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Slider(
                            value: _settings.binauralBeatsVolume,
                            min: 0.05,
                            max: 0.30,
                            divisions: 25,
                            label: '${(_settings.binauralBeatsVolume * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  binauralBeatsVolume: value,
                                );
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.science_outlined, color: Colors.purple.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Binaural beats work by playing slightly different frequencies in each ear. The brain perceives a third tone that may promote relaxation or focus.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

