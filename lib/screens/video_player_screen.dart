import 'dart:async' show Timer, unawaited, StreamSubscription;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';
import '../services/video_filter_service.dart';
import '../services/binaural_beats_service.dart';
import '../services/youtube_service.dart';
import 'break_reminder_screen.dart';
import 'shorts_player_screen.dart';

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
  late Widget _playerCore;
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
  late VideoModel _currentVideo;
  StreamSubscription? _settingsSubscription;
  bool _showPlaybackFeedback = false;
  IconData _playbackFeedbackIcon = Icons.play_arrow_rounded;
  Timer? _playbackFeedbackTimer;

  bool _redirectedToShorts = false;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initializePlayer();
    _startTime = DateTime.now();
    _startBreakCheckTimer();
    _loadCalmModeFilter();
    _startBinauralBeats();
    _settingsSubscription = _parentalService.settingsChanges.listen((_) {
      unawaited(_loadCalmModeFilter());
    });

    // If already detected as Short (e.g. from title heuristic), redirect
    if (widget.video.isShort) {
      _redirectToShorts();
    } else {
      // Fetch details to check if it's a Short (duration-based detection)
      _fetchVideoDetails();
    }

    // Keep screen portrait in normal mode; fullscreen will temporarily switch to landscape.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Redirect to ShortsPlayerScreen for Short videos
  void _redirectToShorts() {
    if (_redirectedToShorts) return;
    _redirectedToShorts = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ShortsPlayerScreen(
              initialVideo: widget.video,
              relatedVideos: widget.playlist,
            ),
          ),
        );
      }
    });
  }

  /// Fetch full video details (including duration) to detect Shorts
  Future<void> _fetchVideoDetails() async {
    try {
      final youtubeService = YouTubeService();
      final details = await youtubeService.getVideoDetails(widget.video.id);
      
      if (details != null && mounted) {
        final updatedVideo = widget.video.copyWith(
          duration: details.duration,
          viewCount: details.viewCount,
          description: details.description.isNotEmpty 
              ? details.description 
              : widget.video.description,
        );
        
        // If it turns out to be a Short, redirect
        if (updatedVideo.isShort) {
          _redirectToShorts();
          return;
        }
        
        setState(() {
          _currentVideo = updatedVideo;
        });
      }
    } catch (e) {
      debugPrint('Error fetching video details: $e');
    }
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
                final breakMinutes = await _parentalService.getBreakDurationMinutes();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreakReminderScreen(
                      breakMinutes: breakMinutes,
                      onBreakComplete: () async {
                        _isOnBreak = false;
                        _controller.play();
                        // Resume binaural beats after break - ensure this completes before navigation
                        await _beatsService.resume();
                        // Pop navigation after all async operations complete
                        if (mounted) {
                          Navigator.pop(context);
                        }
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
        enableCaption: false,
        controlsVisibleAtStart: false,
        // Disable comments and related videos
        hideControls: true,
        disableDragSeek: true,
        loop: false,
        isLive: false,
        startAt: 0,
      ),
    );

    // Keep a single player widget instance to avoid unnecessary platform-view rebuilds.
    _playerCore = RepaintBoundary(
      child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: false,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
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
        unawaited(_syncOrientationWithFullscreen(_isFullScreen));
        setState(() {});
      }
    });
  }

  Future<void> _syncOrientationWithFullscreen(bool isFullscreen) async {
    if (isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }


  @override
  void dispose() {
    _breakCheckTimer?.cancel();
    _playbackFeedbackTimer?.cancel();
    _settingsSubscription?.cancel();
    
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
      _addToHistoryForActiveProfile(_currentVideo).catchError((e) {
        debugPrint('Error adding to watch history: $e');
      }),
    );

    // Stop binaural beats when leaving video player
    unawaited(_beatsService.stopBeats());

    // Restore portrait lock for the app interface.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isOnBreak) return;
    final isPlaying = _controller.value.isPlaying;
    if (isPlaying) {
      _controller.pause();
      _playbackFeedbackIcon = Icons.pause_rounded;
    } else {
      _controller.play();
      _playbackFeedbackIcon = Icons.play_arrow_rounded;
    }

    setState(() {
      _showPlaybackFeedback = true;
    });

    _playbackFeedbackTimer?.cancel();
    _playbackFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _showPlaybackFeedback = false;
        });
      }
    });
  }

  Widget _withPlaybackOverlay(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showPlaybackFeedback ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 140),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playbackFeedbackIcon,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToHistoryForActiveProfile(VideoModel video) async {
    final activeProfile = await _storageService.getActiveProfile();
    await _storageService.addToWatchHistory(video, profileId: activeProfile?.id);
  }

  Widget _buildYoutubePlayerCore() {
    return _playerCore;
  }

  Widget _buildPlayerWidget() {
    Widget result = Hero(
      tag: 'video-${widget.video.id}',
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _withPlaybackOverlay(_buildYoutubePlayerCore()),
      ),
    );

    if (_calmModeFilter != null) {
      result = ColorFiltered(
        colorFilter: _calmModeFilter!,
        child: result,
      );
    }
    return result;
  }

  Widget _buildFullscreenPlayer() {
    final size = MediaQuery.of(context).size;
    final baseWidth = size.width;
    final baseHeight = baseWidth * 9 / 16;

    Widget player = SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: baseWidth,
            height: baseHeight,
            child: _withPlaybackOverlay(_buildYoutubePlayerCore()),
          ),
        ),
      ),
    );

    if (_calmModeFilter != null) {
      player = ColorFiltered(
        colorFilter: _calmModeFilter!,
        child: player,
      );
    }

    return player;
  }

  @override
  Widget build(BuildContext context) {
    // If redirecting to Shorts player, show loading
    if (_redirectedToShorts) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Regular videos use the standard layout
    return Scaffold(
      backgroundColor: _isFullScreen ? Colors.black : null,
      body: _isFullScreen
          ? // Fullscreen mode - show only the player
          _buildFullscreenPlayer()
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
                                _currentVideo.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentVideo.channelTitle,
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
                          _currentVideo.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentVideo.description.isNotEmpty
                              ? _currentVideo.description
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

