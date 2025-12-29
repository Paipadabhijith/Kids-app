import 'package:flutter/material.dart';
import '../services/parental_control_service.dart';

class VideoFilterService {
  final ParentalControlService _parentalService = ParentalControlService();

  /// Research-backed preset profiles for calm mode
  /// Based on studies showing:
  /// - Saturation reduction reduces dopamine response and engagement
  /// - Contrast reduction makes visuals less striking
  /// - Warmth (reduced blue light) improves sleep and reduces stimulation
  /// - Brightness reduction creates calmer viewing experience
  static const Map<String, Map<String, double>> presets = {
    'calming': {
      'contrast': 0.85,
      'saturation': 0.8,
      'brightness': -0.05,
      'warmth': 0.1,
    },
    'reducing_anxiety': {
      'contrast': 0.75,
      'saturation': 0.6,
      'brightness': -0.1,
      'warmth': 0.15,
    },
    'very_calming': {
      'contrast': 0.65,
      'saturation': 0.4,
      'brightness': -0.15,
      'warmth': 0.2,
    },
    'minimal_stimulation': {
      'contrast': 0.7,
      'saturation': 0.0,
      'brightness': -0.1,
      'warmth': 0.0,
    },
    'night': {
      'contrast': 0.7,
      'saturation': 0.5,
      'brightness': -0.2,
      'warmth': 0.3,
    },
  };

  /// Preset descriptions for UI
  static const Map<String, String> presetDescriptions = {
    'calming': 'Gentle calming effect - good for longer viewing',
    'reducing_anxiety': 'Balanced settings to help reduce anxiety',
    'very_calming': 'Strong calming effect - best for hyper-stimulating content',
    'minimal_stimulation': 'Minimal visual stimulation - maximum calming effect',
    'night': 'Warm tones for evening viewing - reduces blue light',
  };

  /// Format preset name for display (replace underscores with spaces and capitalize)
  static String formatPresetName(String presetName) {
    return presetName
        .split('_')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Creates an enhanced ColorFilter matrix with warmth (color temperature)
  /// Based on research showing:
  /// - Saturation reduction reduces dopamine response
  /// - Contrast reduction makes visuals less striking
  /// - Warm tones reduce blue light exposure (better for sleep)
  /// - Brightness reduction creates calmer viewing
  ColorFilter createCalmModeFilter({
    required double contrast,
    required double saturation,
    required double brightness,
    double warmth = 0.0,
  }) {
    // Clamp values to valid ranges
    final sat = saturation.clamp(0.0, 1.0);
    final c = contrast.clamp(0.0, 1.0);
    final b = brightness.clamp(-1.0, 1.0);
    final w = warmth.clamp(0.0, 1.0);
    
    // Luminance weights (ITU-R BT.601 standard)
    const rWeight = 0.299;
    const gWeight = 0.587;
    const bWeight = 0.114;
    
    // Calculate saturation matrix values
    // When sat = 1.0: full color, when sat = 0.0: grayscale
    final rSat = rWeight * (1 - sat) + sat;
    final gSat = gWeight * (1 - sat) + sat;
    final bSat = bWeight * (1 - sat) + sat;
    
    // Apply contrast multiplier
    final rValue = rSat * c;
    final gValue = gSat * c;
    final bValue = bSat * c;
    
    // Warmth adjustments (reduce blue, slightly increase red)
    // Based on research on blue light reduction for better sleep
    final warmthRedBoost = w * 0.1;
    final warmthBlueReduce = w * 0.15;
    
    // Brightness offset (0-255 range)
    final brightnessOffset = b * 255;
    
    // Create color filter matrix
    // Format: [R, G, B, A, Offset] for each row (R, G, B, A channels)
    return ColorFilter.matrix([
      // Red channel - boost slightly for warmth
      (rValue + warmthRedBoost).clamp(0.0, 1.5),
      gWeight * (1 - sat) * c,
      bWeight * (1 - sat) * c,
      0,
      brightnessOffset,
      
      // Green channel
      rWeight * (1 - sat) * c,
      gValue,
      bWeight * (1 - sat) * c,
      0,
      brightnessOffset,
      
      // Blue channel - reduce for warmth (reduces blue light)
      rWeight * (1 - sat) * c,
      gWeight * (1 - sat) * c,
      (bValue - warmthBlueReduce).clamp(0.0, 1.0),
      0,
      brightnessOffset,
      
      // Alpha channel (unchanged)
      0, 0, 0, 1, 0,
    ]);
  }

  /// Get preset filter by name
  ColorFilter? getPresetFilter(String presetName) {
    final preset = presets[presetName];
    if (preset == null) return null;
    
    return createCalmModeFilter(
      contrast: preset['contrast']!,
      saturation: preset['saturation']!,
      brightness: preset['brightness']!,
      warmth: preset['warmth']!,
    );
  }

  /// Get preset values by name
  static Map<String, double>? getPresetValues(String presetName) {
    return presets[presetName];
  }

  /// Gets the current calm mode filter based on settings
  /// Cached to avoid repeated async calls
  Future<ColorFilter?> getCalmModeFilter() async {
    try {
      final settings = await _parentalService.getSettings();
      
      if (!settings.calmModeEnabled) {
        return null;
      }
      
      return createCalmModeFilter(
        contrast: settings.calmModeContrast,
        saturation: settings.calmModeSaturation,
        brightness: settings.calmModeBrightness,
        warmth: settings.calmModeWarmth,
      );
    } catch (e) {
      // Return null on error to prevent blocking
      return null;
    }
  }

  /// Wraps a widget with calm mode filter if enabled
  Future<Widget> applyCalmModeFilter(Widget child) async {
    final filter = await getCalmModeFilter();
    
    if (filter == null) {
      return child;
    }
    
    return ColorFiltered(
      colorFilter: filter,
      child: child,
    );
  }
}
