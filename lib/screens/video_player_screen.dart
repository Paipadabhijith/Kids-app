import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';
import '../services/video_filter_service.dart';
import '../services/binaural_beats_service.dart';
import 'break_reminder_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel>? playlist;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.playlist,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final StorageService _storageService = StorageService();
  final ParentalControlService _parentalService = ParentalControlService();
  final VideoFilterService _filterService = VideoFilterService();
  final BinauralBeatsService _beatsService = BinauralBeatsService();
  DateTime? _startTime;
  bool _isInitialized = false;
  Timer? _breakCheckTimer;
  int _totalMinutesWatched = 0;
  bool _isOnBreak = false;
  ColorFilter? _calmModeFilter;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _startTime = DateTime.now();
    _startBreakCheckTimer();
    _loadCalmModeFilter();
    _startBinauralBeats();
  }

  /// Starts binaural beats based on settings
  Future<void> _startBinauralBeats() async {
    try {
      final settings = await _parentalService.getSettings();

      // Check if binaural beats are enabled (independent of calm mode)
      if (!settings.binauralBeatsEnabled) {
        return;
      }

      // Set volume from settings
      await _beatsService.setVolume(settings.binauralBeatsVolume);

      // Determine which mode to use
      if (settings.windDownModeEnabled) {
        // Use theta waves (4-8 Hz) for wind-down
        final success = await _beatsService.startBeats(BeatFrequency.theta);
        if (!success && mounted) {
          // Could show a snackbar about headphones if needed
          print('Binaural beats not started - headphones may be required');
        }
      } else if (settings.calmFocusModeEnabled) {
        // Use alpha waves (8-12 Hz) for calm focus
        final success = await _beatsService.startBeats(BeatFrequency.alpha);
        if (!success && mounted) {
          print('Binaural beats not started - headphones may be required');
        }
      }
      // If neither mode is enabled, don't play beats
    } catch (e) {
      print('Error starting binaural beats: $e');
      // Fail silently - don't interrupt video playback
    }
  }

  Future<void> _loadCalmModeFilter() async {
    // Load filter asynchronously without blocking UI
    final filter = await _filterService.getCalmModeFilter();
    if (mounted) {
      setState(() {
        _calmModeFilter = filter;
      });
    }
  }

  void _startBreakCheckTimer() {
    _breakCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_startTime != null && !_isOnBreak) {
        final watchDuration = DateTime.now().difference(_startTime!);
        final minutesWatched = watchDuration.inMinutes;
        
        if (minutesWatched > _totalMinutesWatched) {
          _totalMinutesWatched = minutesWatched;
          
          final shouldBreak = await _parentalService.shouldShowBreakReminder(
            _totalMinutesWatched,
          );
          
          if (shouldBreak && mounted) {
            _isOnBreak = true;
            _controller.pause();
            // Pause binaural beats during break
            await _beatsService.pause();
            
            // Use SchedulerBinding to ensure navigation happens after the current frame
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreakReminderScreen(
                      onBreakComplete: () async {
                        _isOnBreak = false;
                        _controller.play();
                        // Resume binaural beats after break
                        await _beatsService.resume();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              }
            });
          }
        }
      }
    });
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && !_isInitialized) {
        _isInitialized = true;
      }
      // Track fullscreen state
      final wasFullScreen = _isFullScreen;
      _isFullScreen = _controller.value.isFullScreen;
      if (wasFullScreen != _isFullScreen && mounted) {
        setState(() {});
      }
    });
  }


  @override
  void dispose() {
    _breakCheckTimer?.cancel();
    
    // Stop binaural beats
    _beatsService.dispose();
    
    // Record watch time and history asynchronously
    // Note: dispose() must be synchronous, so these operations run in background
    // They will complete but won't block disposal
    if (_startTime != null && !_isOnBreak) {
      final watchDuration = DateTime.now().difference(_startTime!);
      final minutesWatched = watchDuration.inMinutes;
      if (minutesWatched > 0) {
        unawaited(
          _parentalService.recordVideoWatch(minutesWatched).catchError((e) {
            debugPrint('Error recording watch time: $e');
          }),
        );
      }
    }

    // Add to watch history
    unawaited(
      _storageService.addToWatchHistory(widget.video).catchError((e) {
        debugPrint('Error adding to watch history: $e');
      }),
    );

    _controller.dispose();
    super.dispose();
  }

  Widget _buildPlayerWidget() {
    final playerWidget = YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Handle exit fullscreen
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      builder: (context, player) {
        return player;
      },
    );
    
    // Apply filter if available, otherwise show player directly
    if (_calmModeFilter != null) {
      return ColorFiltered(
        colorFilter: _calmModeFilter!,
        child: playerWidget,
      );
    }
    return playerWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isFullScreen ? Colors.black : null,
      body: _isFullScreen
          ? // Fullscreen mode - show only the player
          _buildPlayerWidget()
          : // Normal mode - show app bar, player, and description
          SafeArea(
              child: Column(
                children: [
                  // App bar with video info
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primary,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.video.channelTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Video player
                  Expanded(
                    child: Center(
                      child: _buildPlayerWidget(),
                    ),
                  ),

                  // Video description
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.video.description.isNotEmpty
                              ? widget.video.description
                              : 'No description available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

