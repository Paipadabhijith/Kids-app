import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/parental_control_service.dart';
import '../services/video_filter_service.dart';

class ParentalSettingsScreen extends StatefulWidget {
  const ParentalSettingsScreen({super.key});

  @override
  State<ParentalSettingsScreen> createState() => _ParentalSettingsScreenState();
}

class _ParentalSettingsScreenState extends State<ParentalSettingsScreen> {
  final ParentalControlService _parentalService = ParentalControlService();
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
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Parent Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter parent password',
          ),
          autofocus: true,
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
              Navigator.pop(context, verified);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveSettings() async {
    if (_settings.parentalControlsEnabled) {
      // Validate password if setting one
      if (_passwordController.text.isNotEmpty) {
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
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
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
            // Enable/Disable Parental Controls
            Card(
              child: SwitchListTile(
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Time Limit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parent Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set a password to protect settings. Leave empty to keep current password.',
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Blocked Keywords
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blocked Keywords',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

              // Break Reminders
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
            ],
          ],
        ),
      ),
    );
  }
}

