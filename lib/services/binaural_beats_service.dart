import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

enum BeatFrequency {
  alpha, // 10 Hz - calm focus (8-12 Hz range)
  theta, // 6 Hz - wind-down (4-8 Hz range)
}

class BinauralBeatsService {
  AudioPlayer? _player;
  bool _isPlaying = false;
  BeatFrequency? _currentFrequency;
  double _volume = 0.12; // 12% default - gentle and non-intrusive
  Timer? _fadeTimer;

  /// Configures audio session to mix with other audio (YouTube video)
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      debugPrint('Error configuring audio session: $e');
    }
  }

  /// Checks if headphones are connected (binaural beats only work with headphones)
  Future<bool> areHeadphonesConnected() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices();
      return devices.any((device) =>
          device.type == AudioDeviceType.wiredHeadphones ||
          device.type == AudioDeviceType.wiredHeadset ||
          device.type == AudioDeviceType.bluetoothA2dp ||
          device.type == AudioDeviceType.bluetoothSco ||
          device.type == AudioDeviceType.bluetoothLe);
    } catch (e) {
      // If we can't detect, assume headphones might be connected
      return true;
    }
  }

  /// Starts playing binaural beats with the specified frequency
  Future<bool> startBeats(BeatFrequency frequency, {bool requireHeadphones = true}) async {
    // Check if already playing the same frequency
    if (_isPlaying && _currentFrequency == frequency) {
      return true;
    }

    // Check for headphones if required
    if (requireHeadphones) {
      final hasHeadphones = await areHeadphonesConnected();
      if (!hasHeadphones) {
        debugPrint('Binaural beats require headphones - not playing');
        return false;
      }
    }

    // Stop any currently playing beats
    await stopBeats();

    try {
      // Configure audio session first
      await _configureAudioSession();

      // Create new player
      _player = AudioPlayer();

      // Select the appropriate audio file (supports both MP3 and WAV)
      final assetPath = frequency == BeatFrequency.theta
          ? 'assets/audio/theta_6hz.wav'
          : 'assets/audio/alpha_10hz.wav';

      // Load the audio
      await _player!.setAsset(assetPath);
      
      // Set to loop continuously
      await _player!.setLoopMode(LoopMode.one);
      
      // Start with volume at 0 for fade-in
      await _player!.setVolume(0);
      
      // Start playback
      await _player!.play();

      // Smooth fade-in over 2 seconds
      _fadeIn();

      _currentFrequency = frequency;
      _isPlaying = true;
      
      return true;
    } catch (e) {
      debugPrint('Error starting binaural beats: $e');
      _isPlaying = false;
      _currentFrequency = null;
      return false;
    }
  }

  /// Smoothly fades in the volume
  void _fadeIn() {
    const fadeDuration = Duration(seconds: 2);
    const steps = 20;
    final stepDuration = fadeDuration ~/ steps;
    final volumeStep = _volume / steps;
    var currentStep = 0;

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      final newVolume = (currentStep * volumeStep).clamp(0.0, _volume);

      if (_player != null) {
        _player!.setVolume(newVolume);
      }

      if (currentStep >= steps) {
        timer.cancel();
        // Ensure final volume is set
        if (_player != null) {
          _player!.setVolume(_volume);
        }
      }
    });
  }

  /// Smoothly fades out the volume
  Future<void> _fadeOut() async {
    if (_player == null) return;

    _fadeTimer?.cancel();

    const fadeDuration = Duration(milliseconds: 500);
    const steps = 10;
    final stepDuration = fadeDuration ~/ steps;

    try {
      final startVolume = _player!.volume;
      for (int i = steps; i >= 0; i--) {
        if (_player == null) break;
        final newVolume = (startVolume * i / steps).clamp(0.0, 1.0);
        await _player!.setVolume(newVolume);
        await Future.delayed(stepDuration);
      }
    } catch (e) {
      // Ignore errors during fade out
    }
  }

  /// Stops playing binaural beats
  Future<void> stopBeats() async {
    _fadeTimer?.cancel();
    _fadeTimer = null;

    if (_player != null) {
      try {
        // Fade out before stopping
        await _fadeOut();
        await _player!.stop();
        await _player!.dispose();
      } catch (e) {
        debugPrint('Error stopping binaural beats: $e');
      }
      _player = null;
    }

    _isPlaying = false;
    _currentFrequency = null;
  }

  /// Pauses the binaural beats (for break reminders)
  Future<void> pause() async {
    if (_player != null && _isPlaying) {
      await _player!.pause();
    }
  }

  /// Resumes the binaural beats
  Future<void> resume() async {
    if (_player != null && _isPlaying) {
      await _player!.play();
    }
  }

  /// Sets the volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_player != null && _isPlaying) {
      await _player!.setVolume(_volume);
    }
  }

  /// Gets current volume
  double get volume => _volume;

  /// Checks if beats are currently playing
  bool get isPlaying => _isPlaying;

  /// Gets current beat frequency
  BeatFrequency? get currentFrequency => _currentFrequency;

  /// Disposes resources
  void dispose() {
    _fadeTimer?.cancel();
    stopBeats();
  }
}

